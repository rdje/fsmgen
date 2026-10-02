"""Independent saved-product checks; no HDL execution or spent input replay."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path
from functools import lru_cache

BASE = Path(__file__).resolve().parent
BASELINE = '43dcfae199ca7d93a88fe047f886fdcc6522c2ec'
REASON = "when activation body supports only '(sample port as name)' clauses"
NEGATIVES = ['negative_set', 'negative_update', 'negative_wait', 'negative_complete',
    'negative_drive', 'negative_nested', 'negative_repeat', 'negative_mixed',
    'negative_metadata', 'negative_domain', 'negative_generated']
# Independent literal witnesses, not expectations read from cases.json or the test.
POSITIVES = {
    'positive_on_label': (['captured'], ['seen'], 'request'),
    'positive_when_zero': (['captured'], ['seen'], '0'),
    'positive_when_one': (['captured'], ['seen'], '1'),
    'positive_when_expr': (['captured', 'saved'], ['seen'], '(& request allow)'),
    'positive_metadata': (['captured'], ['seen'], 'allow'),
    'positive_wait_zero': (['captured'], ['seen'], 'allow'),
    'positive_branch_on': ([], ['seen'], 'request'),
    'positive_branch_wait': ([], ['seen'], None),
    'positive_branch_local_init': ([], ['temp', 'seen'], None),
    'positive_generated': (['captured'], ['result'], '(& start (! isf_child_start_seen))'),
    'positive_domain': (['captured'], ['seen'], 'allow'),
}
KINDS = ['check', 'semantic', 'schedule']
PRODUCERS = ['bin/fsmgen', 'bin/fsmgen-mcp',
    'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm', 'perl/FSM/VIAL/Tool.pm']


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def load(path):
    return json.loads((BASE / path).read_text())


def exact(value):
    # Python equality alone conflates booleans and integers. JSON text retains
    # primitive kinds, complete member absence, array order and opaque values.
    return json.dumps(value, sort_keys=True, separators=(',', ':'))


@lru_cache(maxsize=None)
def baseline_sha(path):
    return sha(subprocess.check_output(['git', 'show', BASELINE + ':' + path]))


def selected(name, value):
    ir = value['private_ir']
    return ir['children']['worker'] if name.endswith('_generated') else ir


def queries(name, value, refuse):
    assert set(value['queries']) == set(KINDS)
    for kind, query in value['queries'].items():
        native, report, api = query['native'], query['native_report'], query['api']
        assert native['signal'] == 0
        assert native['exit_code'] == (255 if kind == 'schedule' else 1) if refuse else native['exit_code'] == 0
        assert query['stdio']['exit_code'] == 0 and query['stdio']['signal'] == 0
        assert exact(json.loads(query['stdio']['stdout'])) == exact(query['stdio_response']) == exact(api)
        assert set(query['producer_before']) == set(PRODUCERS)
        assert query['producer_before'] == query['producer_after']
        for path, fingerprint in query['producer_before'].items():
            assert fingerprint == baseline_sha(path)
        if refuse:
            assert REASON in native['stdout'] + native['stderr']
        if refuse and kind == 'schedule':
            assert native['stdout'] == '' and report is None
            assert api == {'jsonrpc': '2.0', 'id': 1, 'error': {'code': -32000,
                'message': 'FSMGen command failed without a matching public failure report'}}
        else:
            assert isinstance(report, dict) and exact(json.loads(native['stdout'])) == exact(report)
            assert api.get('error') is None and api['result']['isError'] is refuse
            assert exact(api['result']['structuredContent']['report']) == exact(report)
            if kind != 'schedule':
                assert report['success'] is (not refuse)
            else:
                assert 'success' not in report


def validate_pair(name, before, after):
    assert exact(before['actor']) == exact(after['actor']) and before['source'] == after['source']
    ports = before['actor']['interface']['inputs']
    datain = next(p for p in ports if p['name'] == 'datain')
    assert type(datain['width']) is str and datain['width'] == '3'
    assert before['lower_error'] is None and before['private_error'] is None
    assert isinstance(before['lowered'], dict) and isinstance(before['private_ir'], dict)
    queries(name, before, False)
    if name in NEGATIVES:
        assert after['lowered'] is None and after['private_ir'] is None
        assert REASON in after['lower_error'] and REASON in after['private_error']
        queries(name, after, True)
        ir = selected(name, before)
        assert [s['kind'] for s in ir['states']] == ['entry', 'terminal']
        assignments = [a for s in ir['states'] for a in s.get('assignments', [])]
        assert not any(a.get('source_kind') == 'set' for a in assignments)
        tx = next(t for t in before['actor']['transactions'] if t['name'] == ('worker' if name.endswith('_generated') else 'main'))
        entry = next(c for c in tx['clauses'] if c[0] == 'when')
        assert any(c[0] != 'sample' for c in entry[2:]), name + ' actual parsed action witness'
        assert after['carrier_checks'] == []
        return
    assert name in POSITIVES
    assert set(after) == set(before) | {'carrier_checks'}
    for key in before:
        assert exact(before[key]) == exact(after[key]), name + ' entire unchanged positive ' + key
    queries(name, after, False)
    ir = selected(name, after)
    assignments = [a for state in ir['states'] for a in state.get('assignments', [])]
    samples, writes, guard = POSITIVES[name]
    captures = [a for a in assignments if a.get('source_kind') == 'sample_capture']
    assert sorted(a['lhs'] for a in captures) == sorted(samples)
    assert [a['lhs'] for a in assignments if a.get('source_kind') == 'set'] == writes
    for assignment in captures:
        assert assignment['op'] == '<='
        assert assignment['rhs'] == ('payload' if name.endswith('_generated') else 'datain')
    if guard is not None:
        entry = next(s for s in ir['states'] if s['kind'] == 'entry')
        assert entry['guard'].get('expr', entry['guard'].get('port')) == guard
    else:
        assert not any(s['kind'] == 'entry' for s in ir['states'])
    assert sum(s['kind'] == 'branch' for s in ir['states']) == (1 if name.startswith('positive_branch_') else 0)
    carriers = after['lowered']['files']
    assert sorted(c['file'] for c in after['carrier_checks']) == sorted(carriers)
    for checked in after['carrier_checks']:
        capture = checked['capture']
        assert capture['exit_code'] == 0 and capture['signal'] == 0
        report = json.loads(capture['stdout'])
        assert report['success'] is True
        assert checked['file'] in carriers and carriers[checked['file']]


def verify():
    names = set(NEGATIVES) | set(POSITIVES)
    cases = load('cases.json')
    assert len(cases) == len(names) == 22 and {c['name'] for c in cases} == names
    assert {c['name'] for c in cases if c['refuse']} == set(NEGATIVES)
    for cohort in ['baseline-qualified', 'final-complete']:
        assert {p.stem for p in (BASE / cohort).glob('*.json')} == names
    for name in sorted(names):
        before, after = load('baseline-qualified/' + name + '.json'), load('final-complete/' + name + '.json')
        assert before['source'] == (BASE / 'sources' / (name + '.isf')).read_text()
        validate_pair(name, before, after)
    red = (BASE / 'baseline-qualified.tap').read_text()
    assert 'Tests: 22 Failed: 11' in red and 'Failed tests:  1-10, 20' in red and 'Result: FAIL' in red
    green = (BASE / 'final-complete.tap').read_text()
    assert 'Files=1, Tests=22' in green and 'Result: PASS' in green
    focused = (BASE / 'focused.tap').read_text()
    assert 'Files=4, Tests=49' in focused and 'Result: PASS' in focused
    docs = (BASE / 'docs.tap').read_text()
    assert 'Files=6, Tests=622' in docs and '115 complete fixtures lowered cleanly' in docs and 'Result: PASS' in docs
    assert 'HTML book written' in (BASE / 'book.txt').read_text()
    for receipt in ['draft-first/baseline.tap', 'draft-complete/baseline-complete.tap']:
        assert 'Result: FAIL' in (BASE / receipt).read_text(), 'failed drafts remain failed'
    assert '2ca15577c3cc07f38ba49a15efc8955529f39d8b' in (BASE / 'pickaxe.txt').read_text()
    original = (BASE / 'LoweringIR-baseline.pm').read_bytes()
    after = (BASE / 'LoweringIR-final.pm').read_bytes()
    guard = b'''    for my $body_clause (@{$cl}[2 .. $#$cl]) {
        confess "Transaction '$tn': when activation body supports only '(sample port as name)' clauses; "
            . "put actions after the entry guard or use '(on PORT)' followed by a branching '(when ...)'\\n"
            unless ref($body_clause) eq 'ARRAY' && @$body_clause
                && defined($body_clause->[0]) && !ref($body_clause->[0])
                && $body_clause->[0] eq 'sample';
    }
'''
    assert after.count(guard) == 1 and after.replace(guard, b'', 1) == original
    assert original == subprocess.check_output(['git', 'show', BASELINE + ':perl/FSM/Scheduler/ISF/LoweringIR.pm'])
    inventory = load('production-inventory.json')
    assert inventory['baseline'] == BASELINE and inventory['added'] == []
    assert inventory['changed_existing'] == ['perl/FSM/Scheduler/ISF/LoweringIR.pm']
    listing = subprocess.check_output(['git', 'ls-tree', '-r', '-z', BASELINE, '--', 'bin', 'perl'])
    assert listing == (BASE / 'production-inventory.zlist').read_bytes()
    paths = {entry.split(b'\t')[1].decode() for entry in listing.split(b'\0') if entry}
    assert set(inventory['members']) == paths
    for path, data in inventory['members'].items():
        assert data['before_sha256'] == sha(subprocess.check_output(['git', 'cat-file', 'blob', data['blob']]))
        assert data['after_sha256'] == (sha(after) if path.endswith('/LoweringIR.pm') else data['before_sha256'])
    parents = load('immutable-parents.json')
    listing = subprocess.check_output(['git', 'ls-tree', '-r', '-z', BASELINE, '--'] + parents['roots'])
    assert listing == (BASE / 'immutable-parents.zlist').read_bytes()
    assert set(parents['members']) == {e.split(b'\t')[1].decode() for e in listing.split(b'\0') if e}
    for path, data in parents['members'].items():
        assert sha(Path(path).read_bytes()) == data['sha256']
    select = load('first-select-private.json')
    source = (BASE / 'drafts/first-select.isf').read_text()
    assert source == (BASE / 'first-select.isf').read_text()
    clauses = select['actor']['transactions'][0]['clauses']
    assert clauses[:2] == [['when', 'allow', ['set', 'seen', 'datain']], ['when', ['!', 'allow'], ['set', 'seen', '0']]]
    writes = [a for s in select['ir']['states'] for a in s.get('assignments', []) if a.get('source_kind') == 'set']
    assert len(writes) == 1 and writes[0]['lhs'] == 'seen' and writes[0]['rhs'] == '0'
    assert set(load('first-select-public.json')) == set(KINDS)
    for kind, query in load('first-select-public.json').items():
        native, api, wire = query['native'], query['adapter_result'], query['stdio']
        assert native['exit_code'] == 0 and native['signal'] == 0
        assert wire['exit_code'] == 0 and wire['signal'] == 0
        assert exact(json.loads(native['stdout'])) == exact(native['report'])
        assert api['isError'] is False
        assert exact(api['structuredContent']['report']) == exact(native['report'])
        assert exact(json.loads(wire['stdout'])) == exact(wire['response'])
        assert exact(wire['response']['result']) == exact(api)
        assert query['source_sha256_before'] == query['source_sha256_after'] == sha(source.encode())
        assert query['producer_sha256_before'] == query['producer_sha256_after']
        assert set(query['producer_sha256_before']) == set(PRODUCERS)
        for path, fingerprint in query['producer_sha256_before'].items():
            assert fingerprint == baseline_sha(path)
    closed = load('first-select-closed.json')
    assert set(closed) == set(KINDS)
    for kind, query in closed.items():
        native, api, wire = query['native'], query['api'], query['wire']
        assert native['signal'] == 0 and native['exit_code'] == (255 if kind == 'schedule' else 1)
        assert REASON in native['stdout'] + native['stderr']
        assert wire['exit_code'] == 0 and wire['signal'] == 0
        assert exact(json.loads(wire['stdout'])) == exact(api)
        if kind == 'schedule':
            assert native['stdout'] == '' and 'result' not in api and api['error']['code'] == -32000
        else:
            report = json.loads(native['stdout'])
            assert report['success'] is False and api['result']['isError'] is True
            assert exact(api['result']['structuredContent']['report']) == exact(report)
    # Falsify shared parity: identical corruption of both products must fail
    # a source/literal/admission witness instead of hiding behind equality.
    controls = {}
    for mode in ['sample_omission', 'write_omission', 'guard_change', 'width_kind', 'false_admission']:
        name = 'negative_set' if mode == 'false_admission' else 'positive_on_label'
        before = load('baseline-qualified/' + name + '.json')
        after = load('final-complete/' + name + '.json')
        if mode == 'false_admission':
            after = copy.deepcopy(before)
            after['carrier_checks'] = []
        else:
            for value in [before, after]:
                if mode == 'width_kind':
                    next(p for p in value['actor']['interface']['inputs'] if p['name'] == 'datain')['width'] = 3
                elif mode == 'guard_change':
                    selected(name, value)['states'][0]['guard'] = {'port': 'allow'}
                else:
                    for state in selected(name, value)['states']:
                        state['assignments'] = [a for a in state.get('assignments', [])
                            if a.get('source_kind') != ('sample_capture' if mode == 'sample_omission' else 'set')]
        try:
            validate_pair(name, before, after)
        except AssertionError:
            controls[mode] = 'rejected'
        else:
            raise AssertionError('shared corruption escaped independent witness: ' + mode)
    manifest_path = BASE / 'manifest.json'
    if manifest_path.exists():
        manifest = load('manifest.json')
        members = {str(p.relative_to(BASE)) for p in BASE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
        assert set(manifest['entries']) == members
        for path, data in manifest['entries'].items():
            raw = (BASE / path).read_bytes()
            assert len(raw) == data['bytes'] and sha(raw) == data['sha256'], path
    print('PASS fixed 22-case membership; eleven genuine RED admissions become precise refusals; eleven full positive products unchanged')
    print('PASS strict carrier receipts, phase-specific complete native/API/newline products, exact sole production delta and immutable parents')
    print('PASS independent shared corruptions: ' + ', '.join(controls))


if __name__ == '__main__':
    verify()
