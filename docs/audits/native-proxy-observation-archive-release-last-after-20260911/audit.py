"""Independent streamed last-observation after-call matrix and custody audit.

Use --verify-saved to read the committed result bodies without rewriting them.
Neither mode invokes a qualifier, fixture, compiler or native executable.
"""
from collections import Counter
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
SELECTION = BASE.parent / 'native-proxy-release-call-selection-20260911'
REVISION = '612aa2052eabec11b446742918f8c87ac71ae05b'


def load(path): return json.loads(path.read_bytes())
def signature(value): return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path); value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value); return value


PREDECESSOR = BASE.with_name('native-proxy-observation-archive-release-last-before-20260911')
PREVIOUS = module('last_after_predecessor_oracle', PREDECESSOR / 'audit.py')
ORIGINAL_BEFORE = PREVIOUS.ORIGINAL_BEFORE
ORIGINAL_AFTER = PREVIOUS.ORIGINAL_AFTER
EQUAL_BEFORE = PREVIOUS.EQUAL_BEFORE
EQUAL_AFTER = PREVIOUS.EQUAL_AFTER
ACTIVE_BEFORE = PREVIOUS.ACTIVE_BEFORE
ACTIVE_AFTER = PREVIOUS.PREVIOUS
SELECT = PREVIOUS.SELECT
PRIOR = SELECT.PRIOR
OLD = PRIOR.OLD
TRACE = ORIGINAL_AFTER.TRACE


def rejects(action):
    try: action()
    except (AssertionError, KeyError, TypeError, ValueError, IndexError): return True
    return False


def domain(plan):
    source = load(SELECTION / 'plan.json'); partition = source['partitions'][7]
    assert plan['schema'] == 'fsmgen.release_last_after_plan.v1'
    assert plan['source_revision'] == REVISION and plan['component'] == BASE.name
    assert plan['owner'] == partition['owner'] and plan['partition'] == partition['id'] == 'ordinary_retired_last_observation:after'
    assert plan['profile_id'] == partition['profile_id'] and plan['selection'] == partition['selection']
    assert plan['source_boundaries'] == load(PRIOR.BASE / 'plan.json')['source_boundaries']
    assert plan['sealed_symbols'] == source['sealed_symbols'] and plan['failure_contract'] == source['failure_contract']
    expected = [dict(index=0, name='healthy:last-observation', selector=None)]
    expected.extend(dict(index=i, name=c['address'], selector=c) for i, c in enumerate(partition['cases'], 1))
    assert plan['cases'] == expected and len(expected) == 430


def authenticate(plan):
    pins = load(BASE / 'preflight-pins.json')
    names = ['plan.json', 'prepare.py', 'qualify.t', 'audit.py',
             'trace-preflight.py', 'trace-preflight-pins.json', 'result/trace-preflight.json',
             'result/trace-preflight.stdout', 'result/trace-preflight.exit']
    assert [p['path'] for p in pins] == [str((BASE / n).relative_to(ROOT)) for n in names]
    source = load(PREDECESSOR / 'plan.json')
    expected = {p['path'] for p in source['inputs']} | {str(p.relative_to(ROOT)) for p in PREDECESSOR.rglob('*') if p.is_file()}
    assert [p['path'] for p in plan['inputs']] == sorted(expected)
    for pin in pins + plan['inputs'] + load(BASE / 'trace-preflight-pins.json'):
        path = ROOT / pin['path']; raw = path.read_bytes()
        assert path.stat().st_dev == ROOT.stat().st_dev
        for ancestor in [path, *path.parents]:
            if ancestor == ROOT: break
            assert not ancestor.is_symlink()
        assert pin == dict(path=pin['path'], size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
        if pin in plan['inputs']: assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + pin['path']], cwd=ROOT)
    PREVIOUS.authenticate(source)
    return pins


def tap(path, assertions):
    raw = path.read_text()
    assert re.findall(r'^ok ([0-9]+) - ', raw, re.M) == [str(i) for i in range(1, assertions + 1)]
    assert re.findall(r'^1\.\.([0-9]+)$', raw, re.M) == [str(assertions)]
    assert not re.search(r'^(not ok|Bail out!)|#\s*(skip|todo)\b', raw, re.M | re.I)


def trace_preflight(plan):
    report = load(BASE / 'result/trace-preflight.json')
    assert set(report) == {'schema', 'success', 'prospective_pins', 'allocated', 'cases', 'first_unexpected'}
    assert report['schema'] == 'fsmgen.release_last_after_trace_preflight.v1' and report['success'] is True
    assert report['allocated'] == [] and report['first_unexpected'] is None
    assert report['prospective_pins'] == load(BASE / 'trace-preflight-pins.json')
    assert [p['path'] for p in report['prospective_pins']] == [str((BASE / n).relative_to(ROOT))
        for n in ('plan.json', 'prepare.py', 'trace-preflight.py')]
    old_plan = load(PREDECESSOR / 'plan.json'); saved = load(PREDECESSOR / 'result/qualification.json')
    row = PREVIOUS.read_case(PREDECESSOR / 'result', saved['case_files'][0])
    PREVIOUS.verify_row(old_plan, old_plan['cases'][0], row)
    assert row['profile_id'] == plan['profile_id'] and row['selection'] == plan['selection']
    spec, _ = OLD.setup(row); calls = PRIOR.FLOW.derive(row['context'], row['operation']['before'], spec)
    expected = []
    for selected in plan['cases'][1:]:
        fault = selected['selector']; ident = [c['id'] for c in calls if c['name'] == fault['symbol']][fault['occurrence']]
        resolved = dict(address=fault['address'], call_id=ident, symbol=fault['symbol'], occurrence=fault['occurrence'], phase='after')
        trace = TRACE.derive(calls, row['context'], plan['sealed_symbols'], resolved)
        expected.append(dict(address=fault['address'], resolved=resolved, events=len(trace['events']), handles=len(trace['handles']),
                             calls=len(trace['calls']), unlinked=trace['unlinked'], event_sha256=signature(trace['events'])))
    assert report['cases'] == expected and len(expected) == 429
    assert (BASE / 'result/trace-preflight.exit').read_bytes() == b'0\n'
    assert load(BASE / 'result/trace-preflight.stdout') == dict(success=True, cases=429, allocated=0)
    return dict(cases=len(expected), new_fixture_allocations=0, basis='saved last-observation healthy event projection')


def caller_controls(plan, controls):
    assert len(controls) == 6 and {c['name'] for c in controls} == set(plan['sealed_symbols'])
    diagnostics = {
        TRACE.RELEASE + '::_coordinator_request': 'release admission requires the fixed coordinator',
        TRACE.RELEASE + '::_admit_locked': 'release ownership admission requires the fixed coordinator',
        TRACE.RELEASE + '::_release_locked': 'exact release requires the fixed coordinator',
        TRACE.RELEASE + '::_finish_locked': 'release closure requires the fixed coordinator',
        TRACE.RELEASE + '::_unlink_exact': 'exact unlink requires the release owner',
        TRACE.CENSUS + '::_inspect_locked': 'reference inspection requires the sealed coordinator',
    }
    for c in controls:
        assert c['baseline_returned'] == c['instrumented_returned'] == 0
        assert c['baseline_error'] == c['instrumented_error'] == diagnostics[c['name']] + '\n'
        assert c['events'] == ['call:0:before'] and c['interrupted_boundary_ids'] == [0] and len(c['calls']) == 1
        frame = c['calls'][0]
        assert {k: v for k, v in frame.items() if k != 'depth'} == dict(id=0, name=c['name'], occurrence=0,
            caller='NativeProxyReleaseCallFaultTrace', parent=None, tail=1)
        assert type(frame['depth']) is int and 0 < frame['depth'] <= 128


def header(plan, report):
    assert report['schema'] == 'fsmgen.release_last_after_qualification.v1' and report['success'] is True
    assert report['prospective_pins'] == load(BASE / 'preflight-pins.json')
    assert report['cases'] == [] and report['current_case'] is None and report['forbidden_process_attempts'] == 0
    caller_controls(plan, report['caller_controls'])
    assert len(report['case_files']) == len(plan['cases'])
    for selected, receipt in zip(plan['cases'], report['case_files'], strict=True):
        assert set(receipt) == {'index', 'name', 'path', 'size_bytes', 'sha256'}
        assert receipt['index'] == selected['index'] and receipt['name'] == selected['name']
        assert receipt['path'] == '.artifacts/logs/' + BASE.name + '/cases/case-%04d.json' % selected['index']
        assert type(receipt['size_bytes']) is int and receipt['size_bytes'] > 0 and re.fullmatch('[0-9a-f]{64}', receipt['sha256'])


def read_case(storage, receipt):
    path = storage / 'cases' / ('case-%04d.json' % receipt['index'])
    for ancestor in [path, *path.parents]:
        if ancestor == ROOT: break
        assert not ancestor.is_symlink() and ancestor.stat().st_dev == ROOT.stat().st_dev
    assert path.is_file()
    raw = path.read_bytes()
    assert len(raw) == receipt['size_bytes'] and hashlib.sha256(raw).hexdigest() == receipt['sha256']
    return json.loads(raw)


def verify_row(plan, selected, row):
    assert set(row) == set('matrix_case profile_id name selection context setup_before work_selection work_settlement retirement controlled_setup_removed_hold before_archive archive_receipt before_mutation mutation arguments operation prospective input_fingerprint_before input_fingerprint_after inputs_unchanged roots_absent'.split())
    assert row['matrix_case'] == selected and row['profile_id'] == plan['profile_id']
    assert row['name'] == plan['selection']['name'] and row['selection'] == plan['selection']
    assert row['roots_absent'] is True and row['inputs_unchanged'] == 1
    assert re.fullmatch('[0-9a-f]{64}', row['input_fingerprint_before'])
    assert row['input_fingerprint_before'] == row['input_fingerprint_after']
    OLD.work_records(row); spec, _ = OLD.setup(row); assert OLD.mutation(row) == 0
    op = row['operation']; calls = PRIOR.FLOW.derive(row['context'], op['before'], spec)
    fault = selected['selector']; resolved = None
    if fault is not None:
        matches = [c for c in calls if c['name'] == fault['symbol']]
        target = matches[fault['occurrence']]
        resolved = dict(address=fault['address'], call_id=target['id'], symbol=fault['symbol'], occurrence=fault['occurrence'], phase=fault['phase'])
    assert row['prospective'] == dict(error='', resolved=resolved, flow_calls=len(calls), flow_sha256=signature(calls))
    expected = TRACE.derive(calls, row['context'], plan['sealed_symbols'], resolved)
    assert op['events'] == expected['events']
    assert len(op['boundary_calls']) == len(expected['calls'])
    for actual, required in zip(op['boundary_calls'], expected['calls'], strict=True):
        assert {k: v for k, v in actual.items() if k != 'depth'} == required
        assert type(actual['depth']) is int and 0 < actual['depth'] <= 128
        if actual['parent'] is not None: assert actual['depth'] > op['boundary_calls'][actual['parent']]['depth']
    assert op['interrupted_boundary_ids'] == expected['interrupted_boundary_ids'] and op['injected_hits'] == expected['injected_hits']
    counts = OLD.trace(row, spec)
    assert len(op['handles']) == len(expected['handles'])
    for actual, required in zip(op['handles'], expected['handles'], strict=True):
        assert {k: actual[k] for k in required if k != 'source_call'} == {k: v for k, v in required.items() if k != 'source_call'}
    source_calls = [calls[h['source_call']] for h in expected['handles'] if h['kind'] == 'source']
    assert op['source_requests'] == [{k: c[k] for k in ('path', 'mode', 'limit')} for c in source_calls]
    assert op['reads'] == [c['path'] for c in source_calls]
    assert op['returned'] == 1 and op['error'] == '' and op['modeled_close_hits'] == 0
    assert all('modeled_close_errno' not in h for h in op['handles'])
    if expected['unlinked']:
        assert op['unlinks'] == [dict(paths=[op['expected_hold']], actual_count=1, actual_errno=0)]
    else: assert op['unlinks'] == []
    physical = copy.deepcopy(op['before'])
    if expected['unlinked']:
        del physical['store'][op['expected_hold'][len(row['context']['store']['path']) + 1:]]
    assert op['after'] == physical
    if fault is None: OLD.attempt(row, spec)
    else:
        effects = next(v['effects'] for v in SELECT.expected(calls, plan['sealed_symbols']) if v['address'] == fault['address'])
        assert effects == fault['baseline_effects'] and effects['unlink_completed'] == int(expected['unlinked'])
        assert op['result'] == dict(schema='fsmgen.inactive_observation_release_attempt.v1', runtime_authorized=0, executable=None,
            success=0, error='injected release call: ' + fault['address'] + '\n', release=None, **effects)
        for field in ('runtime_authorized', 'success', 'unlink_attempted', 'unlink_completed', 'reference_absence_verified'):
            assert type(op['result'][field]) is int
    roots = [dict(kind=k, **row['context'][k]) for k in ('store', 'workspace', 'other_workspace', 'evidence')]
    return dict(counts, calls=len(op['boundary_calls']), unlinks=int(expected['unlinked']), faults=int(fault is not None), healthy=int(fault is None)), roots


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'])
    saved = bool(sys.argv[1:]); storage = BASE / 'result' if saved else LOG
    plan = load(BASE / 'plan.json'); domain(plan); pins = authenticate(plan); preflight = trace_preflight(plan); inherited_flow = ORIGINAL_BEFORE.pure_flow()
    report = load(storage / 'qualification.json'); header(plan, report)
    totals = Counter(); roots = []; examples = {}
    for selected, receipt in zip(plan['cases'], report['case_files'], strict=True):
        row = read_case(storage, receipt); counts, allocated = verify_row(plan, selected, row)
        totals.update(counts); roots.extend(allocated)
        # Keep only the bounded rows needed for independent rejection controls.
        if selected['selector'] is None: examples['healthy'] = (selected, row)
        elif selected['selector']['symbol'] == TRACE.RELEASE + '::_assert_absent' and selected['selector']['occurrence'] == 0: examples['late'] = (selected, row)
        elif selected['selector']['symbol'] == TRACE.RECHECK and selected['selector']['occurrence'] == 0: examples['early'] = (selected, row)
    assert report['allocated'] == roots and len({r['path'] for r in roots}) == len(roots)
    assert [json.loads(line) for line in (storage / 'admission.jsonl').read_text().splitlines()] == roots
    previous = load(PRIOR.BASE / 'result/qualification.json')['allocated'] + load(PREDECESSOR / 'result/qualification.json')['allocated'] + load(ORIGINAL_BEFORE.BASE / 'result/qualification.json')['allocated'] + load(ORIGINAL_AFTER.BASE / 'result/qualification.json')['allocated'] + load(EQUAL_BEFORE.BASE / 'result/qualification.json')['allocated'] + load(EQUAL_AFTER.BASE / 'result/qualification.json')['allocated'] + load(ACTIVE_BEFORE.BASE / 'result/qualification.json')['allocated'] + load(ACTIVE_AFTER.BASE / 'result/qualification.json')['allocated']
    old_paths = {r['path'] for r in previous}
    assert not old_paths & {r['path'] for r in roots}
    for path in old_paths | {r['path'] for r in roots}: assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
    assert {p.name for p in (storage / 'cases').iterdir()} == {'case-%04d.json' % c['index'] for c in plan['cases']}
    assertions = 24 + len(plan['cases']) * 10 + 1
    tap(storage / 'qualify.tap', assertions); assert (storage / 'qualify.exit').read_bytes() == b'0\n'
    def op(r): return r['operation']
    def handle(r, kind): return next(h for h in op(r)['handles'] if h['kind'] == kind)
    def remove_selected_image(row):
        prefix = 'images/' + row['context']['runtime']['image']['key']
        op(row)['after']['store'] = {p: v for p, v in op(row)['after']['store'].items()
                                     if p != prefix and not p.startswith(prefix + '/')}
    changes = [
        ('lost actual unlink', 'late', lambda r: op(r)['result'].update(unlink_completed=0)),
        ('invented early unlink', 'early', lambda r: op(r)['result'].update(unlink_completed=1)),
        ('lost primary error', 'late', lambda r: op(r)['result'].update(error='')),
        ('false success', 'late', lambda r: op(r)['result'].update(success=1)),
        ('false native authority', 'late', lambda r: op(r)['result'].update(runtime_authorized=1)),
        ('lost prior absence', 'late', lambda r: op(r)['result'].update(reference_absence_verified=0)),
        ('wrong current resolution', 'late', lambda r: r['prospective']['resolved'].update(call_id=0)),
        ('missing call', 'healthy', lambda r: op(r)['boundary_calls'].pop()),
        ('wrong caller', 'healthy', lambda r: op(r)['boundary_calls'][0].update(caller='Foreign')),
        ('lost continuation', 'healthy', lambda r: next(c for c in op(r)['boundary_calls'] if c.get('completion') == 'caller_continuation').update(continuation='Foreign')),
        ('wrong source alias', 'healthy', lambda r: next(c for c in op(r)['boundary_calls'] if 'source_handle' in c).update(source_handle='source:1')),
        ('lost prefix event', 'late', lambda r: op(r)['events'].pop(1)),
        ('extra post-fault call', 'late', lambda r: op(r)['events'].insert(-1, 'call:999:before')),
        ('lost interrupted frame', 'late', lambda r: op(r)['interrupted_boundary_ids'].clear()),
        ('missing fault hit', 'late', lambda r: op(r).update(injected_hits=0)),
        ('unclosed source', 'healthy', lambda r: handle(r, 'source').update(closed_at_return=0)),
        ('unclosed directory', 'healthy', lambda r: handle(r, 'directory').update(closed_at_return=0)),
        ('unclosed lock', 'healthy', lambda r: handle(r, 'lock').update(closed_at_return=0)),
        ('wrong cleanup owner', 'healthy', lambda r: handle(r, 'source').update(close_caller='Foreign')),
        ('wrong read limit', 'healthy', lambda r: op(r)['source_requests'][0].update(limit=4096)),
        ('changed archive receipt', 'healthy', lambda r: op(r)['result']['release']['archive']['source_bindings'][0]['archive'].update(inode=7)),
        ('lost other-owner state', 'late', lambda r: op(r)['after']['store'].pop('coordination.lock')),
        ('changed input flags', 'healthy', lambda r: r.update(inputs_unchanged=0)),
        ('changed fingerprint', 'healthy', lambda r: r.update(input_fingerprint_after='0' * 64)),
        ('unproved root cleanup', 'healthy', lambda r: r.update(roots_absent=False)),
        ('missing runtime retirement', 'healthy', lambda r: r.pop('retirement')),
        ('retained retired workspace', 'healthy', lambda r: r['before_archive'].update(
            workspace=copy.deepcopy(r['setup_before']['workspace']))),
        ('missing controlled setup removal', 'healthy', lambda r: r.pop('controlled_setup_removed_hold')),
        ('wrong controlled setup target', 'healthy', lambda r: r.update(controlled_setup_removed_hold=op(r)['expected_hold'])),
        ('lost unreferenced selected image', 'healthy', remove_selected_image),
    ]
    for name, example, change in changes:
        selected, original = examples[example]; altered = copy.deepcopy(original); change(altered)
        assert rejects(lambda: verify_row(plan, selected, altered)), name
    manifest_changes = [
        ('missing case receipt', lambda r: r['case_files'].pop()),
        ('reordered cases', lambda r: r['case_files'].reverse()),
        ('unfinished current case', lambda r: r.update(current_case=plan['cases'][0])),
        ('hidden process', lambda r: r.update(forbidden_process_attempts=1)),
        ('caller guard bypass', lambda r: r['caller_controls'][0].update(instrumented_returned=1)),
        ('foreign case path', lambda r: r['case_files'][0].update(path='foreign')),
    ]
    for name, change in manifest_changes:
        altered = copy.deepcopy(report); change(altered); assert rejects(lambda: header(plan, altered)), name
    byte_controls = []
    for name in ('wrong case size', 'wrong case digest'):
        altered = copy.deepcopy(report['case_files'][0])
        if name == 'wrong case size': altered['size_bytes'] += 1
        else: altered['sha256'] = '0' * 64
        assert rejects(lambda: read_case(storage, altered)), name
        byte_controls.append(name)
    domains = []
    for name in ('missing selector', 'unsafe source after', 'stale numeric target'):
        altered = copy.deepcopy(plan)
        if name == 'missing selector': altered['cases'].pop()
        elif name == 'unsafe source after': altered['cases'][1]['selector'].update(symbol=TRACE.SOURCE, occurrence=0, phase='after', address=TRACE.SOURCE + '#0:after')
        else: altered['cases'][1]['selector']['runtime_call_id'] = 0
        assert rejects(lambda: domain(altered)), name; domains.append(name)
    result = dict(schema='fsmgen.release_last_after_audit.v1', success=True, **dict(totals), cases=len(plan['cases']), roots=len(roots),
        assertions=assertions, trace_preflight=preflight, inherited_pure_flow=inherited_flow, previous_roots=len(old_paths), caller_controls=6, prospective_pins=len(pins), unchanged_inputs=len(plan['inputs']),
        row_falsifiers=[n for n, _, _ in changes], manifest_falsifiers=[n for n, _ in manifest_changes],
        byte_falsifiers=byte_controls, domain_falsifiers=domains,
        case_bytes=sum(r['size_bytes'] for r in report['case_files']), scope=plan['scope'])
    if not saved: (LOG / 'audit.json').write_text(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__': main()
