"""Independent fixed source/control-flow witnesses; no HDL or spent replay."""
import copy
import hashlib
import json
import subprocess
from functools import lru_cache
from pathlib import Path

BASE = Path(__file__).resolve().parent
BASELINE = '9bf0bd4c8af8c8aab5ab6865e66f6729d9583b3c'
KINDS = {'check', 'semantic', 'schedule'}
PRODUCERS = {'bin/fsmgen', 'bin/fsmgen-mcp',
    'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm', 'perl/FSM/VIAL/Tool.pm'}
FAMILIES = ['select', 'min', 'max', 'when_bit', 'unless_bit', 'when_field', 'unless_field', 'cond']
SAMPLE_FAMILIES = FAMILIES[3:]
REFUSED = set('first_' + f for f in FAMILIES) | {
    'first_proc_select', 'first_proc_when_bit', 'first_select_zero',
    'domain_first_select', 'first_generated_select'}
PROC_REFUSED = {'first_proc_cond', 'later_proc_cond'}
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
    assert value['source'] == (BASE / 'sources' / (name + '.isf')).read_text()
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


def verify():
    assert len(NAMES) == 43 and len(REFUSED) == 13 and len(PROC_REFUSED) == 2 and len(UNSAFE) == 7
    assert {c['name'] for c in load('cases.json')} == NAMES
    assert {p.stem for p in (BASE / 'current').glob('*.json')} == NAMES
    assert {p.stem for p in (BASE / 'sources').glob('*.isf')} == NAMES
    for name in sorted(NAMES):
        validate(name, load('current/' + name + '.json'))
    for receipt, expected in [('current.tap', 'Files=1, Tests=44'),
                              ('macros-qualified.tap', 'Files=6, Tests=28'),
                              ('activation-qualified.tap', 'Files=1, Tests=22'),
                              ('docs.tap', 'Files=6, Tests=622')]:
        raw = (BASE / receipt).read_text()
        assert expected in raw and 'Result: PASS' in raw
    red = (BASE / 'desired-intent.tap').read_text()
    assert 'Tests: 7 Failed: 7' in red and 'Failed tests:  1-7' in red and 'Result: FAIL' in red
    assert 'Result: FAIL' in (BASE / 'focused.tap').read_text()
    failed = (BASE / 'focused.tap').read_text()
    assert all(w in failed for w in ['isf_port_inc_into_in', 'isf_port_inc_into_r', 'main_sample_3'])
    assert sha((BASE / 'procedures-baseline.t').read_bytes()) == baseline_sha('t/1390-isf-procedures.t')
    assert 'scoped callee formal' in (BASE / 'procedures-current.t').read_text()
    assert 'host memory 89.0% reached cutoff 88%' in (BASE / 'drafts/focused-host-cutoff-guard.txt').read_text()
    assert 'unknown option: --log' in (BASE / 'drafts/focused-invalid-guard-option.txt').read_text()
    assert 'HTML book written' in (BASE / 'book.txt').read_text()
    roots = {'select': 'b6204f00bef9bf5b37cb4f1df661bfb528e48ff1',
        'cond': '368c42812ff7849a7c6aff78b9a2bec527e58ae9',
        'bit': 'b5a6799818b69e0f47821b9c58696e99c5d38612',
        'field': '38ba879ea659718d46ea770fdb63d39dad187fd7',
        'proc': 'e680f9670257c6d6e9ad0c46d222e96697ea2304'}
    for kind, revision in roots.items():
        assert revision in (BASE / ('history-' + kind + '.txt')).read_text()
    inventory = load('production-inventory.json')
    assert inventory['baseline'] == BASELINE and inventory['changed_existing'] == [] and inventory['added'] == []
    listing = subprocess.check_output(['git', 'ls-tree', '-r', '-z', BASELINE, '--', 'bin', 'perl'])
    assert listing == (BASE / 'production-inventory.zlist').read_bytes()
    assert set(inventory['members']) == {e.split(b'\t')[1].decode() for e in listing.split(b'\0') if e}
    for path, data in inventory['members'].items():
        assert sha(subprocess.check_output(['git', 'cat-file', 'blob', data['blob']])) == data['sha256']
    parents = load('immutable-parents.json')
    listing = subprocess.check_output(['git', 'ls-tree', '-r', '-z', BASELINE, '--'] + parents['roots'])
    assert listing == (BASE / 'immutable-parents.zlist').read_bytes()
    assert set(parents['members']) == {e.split(b'\t')[1].decode() for e in listing.split(b'\0') if e}
    for path, data in parents['members'].items():
        assert sha(Path(path).read_bytes()) == data['sha256']
    controls = []
    for mode in ['sample_omission', 'write_omission', 'predicate_change', 'width_kind', 'fabricated_intent']:
        name = 'later_select' if mode == 'write_omission' else 'first_when_bit_sample'
        value = copy.deepcopy(load('current/' + name + '.json'))
        if mode == 'width_kind':
            next(p for p in value['actor']['interface']['inputs'] if p['name'] == 'datain')['width'] = 3
        elif mode == 'fabricated_intent':
            selected(name, value)['states'][0]['kind'] = 'branch'
        elif mode == 'predicate_change':
            selected(name, value)['states'][0]['guard']['expr_ast'][0] = '=='
        else:
            for state in selected(name, value)['states']:
                state['assignments'] = [a for a in state.get('assignments', [])
                    if a.get('source_kind') != ('set' if mode == 'write_omission' else 'sample_capture')]
        try:
            validate(name, value)
        except AssertionError:
            controls.append(mode)
        else:
            raise AssertionError('shared corruption escaped independent source witness: ' + mode)
    manifest = BASE / 'manifest.json'
    if manifest.exists():
        entries = load('manifest.json')['entries']
        assert set(entries) == {str(p.relative_to(BASE)) for p in BASE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
        for path, data in entries.items():
            raw = (BASE / path).read_bytes()
            assert len(raw) == data['bytes'] and sha(raw) == data['sha256'], path
    print('PASS fixed 43 sources: 13 entry refusals, 2 proc-cond refusals, 7 unsafe sample entries, 2 authored entries, 19 later contexts')
    print('PASS complete literal/private/native/API/newline/carrier products; genuine desired-intent RED; unchanged production and immutable predecessors')
    print('PASS independent shared corruptions: ' + ', '.join(controls))


if __name__ == '__main__':
    verify()
