"""Independent fixed source/control-flow witnesses; no HDL or spent replay."""
import copy
import hashlib
import json
import subprocess
from functools import lru_cache
from pathlib import Path

BASE = Path(__file__).resolve().parent
BASELINE = '518d99d288b6b1cf4fd2f8f38518d684d37740a6'
KINDS = {'check', 'semantic', 'schedule'}
PRODUCERS = {'bin/fsmgen', 'bin/fsmgen-mcp',
    'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm', 'perl/FSM/VIAL/Tool.pm'}
FAMILIES = ['select', 'min', 'max', 'when_bit', 'unless_bit', 'when_field', 'unless_field', 'cond']
SAMPLE_FAMILIES = FAMILIES[3:]
REFUSED = set('first_' + f for f in FAMILIES) | {
    'first_proc_select', 'first_proc_when_bit', 'first_proc_cond', 'first_select_zero',
    'domain_first_select', 'first_generated_select'}
PROC_REFUSED = set()
UNSAFE = set('first_' + f + '_sample' for f in SAMPLE_FAMILIES) | {
    'first_bit_sample_zero', 'domain_first_sample'}
AUTHORED = {'first_when_sample', 'first_proc_when_sample'}
NAMES = {p + f for p in ['first_', 'later_'] for f in FAMILIES}
NAMES |= {p + f + '_sample' for p in ['first_', 'later_'] for f in SAMPLE_FAMILIES}
NAMES |= {p + f for p in ['first_proc_', 'later_proc_'] for f in ['select', 'when_bit', 'cond']}
NAMES |= AUTHORED | {'first_select_zero', 'first_bit_sample_zero', 'initialized_select',
    'nested_select', 'domain_first_select', 'domain_later_select', 'domain_first_sample',
    'first_generated_select', 'later_generated_select'}
PREDICATES = {
    'when_bit': ['!=', ['&', 'datain', "3'd2"], "3'd0"],
    'unless_bit': ['==', ['&', 'datain', "3'd2"], "3'd0"],
    'when_field': ['==', ['&', 'datain', "3'd6"], "3'd2"],
    'unless_field': ['!=', ['&', 'datain', "3'd6"], "3'd2"],
    'select': 'allow', 'cond': 'allow', 'authored_when': 'allow',
    'min': ['<=', 'datain', 'other'], 'max': ['>=', 'datain', 'other'],
}


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def load(path):
    return json.loads((BASE / path).read_text())


def exact(value):
    # Primitive kinds, array order, absence and complete opaque fields matter.
    return json.dumps(value, sort_keys=True, separators=(',', ':'))


@lru_cache(maxsize=None)
def baseline_sha(path):
    return sha(subprocess.check_output(['git', 'show', BASELINE + ':' + path]))


def family(name):
    special = {'domain_first_sample': 'when_field', 'first_bit_sample_zero': 'when_bit'}
    if name in special:
        return special[name]
    if name in AUTHORED:
        return 'authored_when'
    return next(f for f in sorted(FAMILIES, key=len, reverse=True) if f in name)


def selected(name, value):
    return value['private_ir']['children']['worker'] if '_generated_' in name else value['private_ir']


def queries(value, reason):
    assert set(value['queries']) == KINDS
    refuse = reason is not None
    for kind, q in value['queries'].items():
        native, report, api = q['native'], q['native_report'], q['api']
        assert native['signal'] == 0
        assert native['exit_code'] == ((255 if kind == 'schedule' else 1) if refuse else 0)
        assert q['stdio']['exit_code'] == 0 and q['stdio']['signal'] == 0
        assert exact(json.loads(q['stdio']['stdout'])) == exact(q['stdio_response']) == exact(api)
        assert set(q['producer_before']) == PRODUCERS
        assert q['producer_before'] == q['producer_after']
        for path, fingerprint in q['producer_before'].items():
            assert fingerprint == baseline_sha(path)
        if refuse:
            assert reason in native['stdout'] + native['stderr']
        if refuse and kind == 'schedule':
            assert native['stdout'] == '' and report is None
            assert api == {'jsonrpc': '2.0', 'id': 1, 'error': {'code': -32000,
                'message': 'FSMGen command failed without a matching public failure report'}}
        else:
            assert isinstance(report, dict) and exact(json.loads(native['stdout'])) == exact(report)
            assert 'error' not in api and api['result']['isError'] is refuse
            assert exact(api['result']['structuredContent']['report']) == exact(report)
            if kind != 'schedule':
                assert report['success'] is (not refuse)
            else:
                assert 'success' not in report


def validate(name, value):
    assert name in NAMES
    assert value['source'] == (BASE / 'macro-sources' / (name + '.isf')).read_text()
    datain = next(p for p in value['actor']['interface']['inputs'] if p['name'] == 'datain')
    assert type(datain['width']) is str and datain['width'] == '3'
    assert value['unsafe_macro_entry'] is (name in UNSAFE)
    reason = ("unsupported '(cond ...)' clause in transaction body" if name in PROC_REFUSED else
              "when activation body supports only '(sample port as name)' clauses" if name in REFUSED else None)
    queries(value, reason)
    if reason:
        assert value['lowered'] is None and value['private_ir'] is None
        assert reason in value['lower_error'] and reason in value['private_error']
        assert value['carrier_checks'] == []
        if name in PROC_REFUSED:
            tx = next(t for t in value['actor']['transactions'] if t['name'] == 'main')
            assert any(c[0] == 'cond' for c in tx['clauses'])
        return
    assert value['lower_error'] is None and value['private_error'] is None
    ir = selected(name, value)
    assignments = [a for state in ir['states'] for a in state.get('assignments', [])]
    fam = family(name)
    sample = name.endswith('_sample') or name in {'first_bit_sample_zero', 'domain_first_sample'}
    expected_samples = (['captured', 'saved'] if fam == 'cond' else ['captured']) if sample else []
    captures = [a for a in assignments if a.get('source_kind') == 'sample_capture']
    assert sorted(a['lhs'] for a in captures) == sorted(expected_samples)
    for a in captures:
        assert a['op'] == '<='
        assert a['rhs'] == ('datain' if fam == 'cond' and a['lhs'] == 'captured' else 'other')
    writes = [a for a in assignments if a.get('source_kind') == 'set']
    expected_writes = [] if sample else ['seen'] * (2 if fam in {'select', 'min', 'max', 'cond'} else 1)
    if name == 'later_generated_select':
        expected_writes = ['result', 'result']
    if name == 'initialized_select':
        expected_writes.insert(0, 'temp')
    assert [a['lhs'] for a in writes] == expected_writes
    expected_rhs = [] if sample else (['datain', 'other'] if fam in {'select', 'min', 'max', 'cond'} else ['other'])
    if name == 'later_generated_select':
        expected_rhs = ['payload', 'other']
    if name == 'initialized_select':
        expected_rhs.insert(0, 1)
    assert exact([a['rhs'] for a in writes]) == exact(expected_rhs)
    assert all(a['op'] == '<-' for a in writes)
    branches = [s for s in ir['states'] if s['kind'] == 'branch']
    expected_count = (1 if name == 'first_cond_sample' else 0) if name in UNSAFE | AUTHORED else (
        3 if name == 'nested_select' else 2 if fam in {'select', 'min', 'max', 'cond'} else 1)
    assert len(branches) == expected_count
    if name in UNSAFE | AUTHORED:
        assert ir['states'][0]['kind'] == 'entry'
        guard = ir['states'][0]['guard']
        assert exact(guard.get('expr_ast', guard.get('port'))) == exact(PREDICATES[fam])
    else:
        assert exact(branches[0]['condition']) == exact(PREDICATES[fam])
    if fam in {'select', 'min', 'max', 'cond'} and name not in UNSAFE:
        assert exact(branches[-1]['condition']) == exact(['!', PREDICATES[fam]])
    if name == 'initialized_select':
        assert not any(s['kind'] == 'entry' for s in ir['states'])
    if name == 'later_generated_select':
        assert ir['states'][0]['guard']['expr'] == '(& start (! isf_child_start_seen))'
        worker = next(t for t in value['actor']['transactions'] if t['name'] == 'worker')
        payload = next(p for p in worker['ports']['inputs'] if p['name'] == 'payload')
        assert type(payload['width']) is int and payload['width'] == 3
    carriers = value['lowered']['files']
    assert sorted(c['file'] for c in value['carrier_checks']) == sorted(carriers)
    for c in value['carrier_checks']:
        capture = c['capture']
        assert capture['exit_code'] == 0 and capture['signal'] == 0
        assert json.loads(capture['stdout'])['success'] is True and carriers[c['file']]


