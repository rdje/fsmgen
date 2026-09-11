"""Read-only verification of a prospective domain; never invoke a producer."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '1db83632112c1b452c3c3e2f98a13cfeed5647f9'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.3.10.1'
HEALTHY = 'docs/audits/native-proxy-observation-archive-release-boundaries-20260911/result/qualification.json'
MODES = ['first-eio', 'partial-eio', 'early-eof', 'body-xor']
SOURCE = 'NativeProxyImageCustody::_source'
RELEASE = 'NativeProxyObservationRelease'


def load(path):
    return json.loads(path.read_bytes())


def receipt(path):
    raw = path.read_bytes()
    assert path.stat().st_dev == ROOT.stat().st_dev
    for ancestor in [path, *path.parents]:
        if ancestor == ROOT:
            break
        assert not ancestor.is_symlink()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw),
                sha256=hashlib.sha256(raw).hexdigest())


def authenticate(plan):
    previous = ROOT / 'docs/audits/native-proxy-release-call-selection-20260911/plan.json'
    expected = {p['path'] for p in load(previous)['inputs']} | {str(previous.relative_to(ROOT))}
    for name in ('native-proxy-observation-archive-lower-reader-seam-20260911',
                 'native-proxy-observation-archive-lower-reader-failures-20260911'):
        expected.update(str(p.relative_to(ROOT)) for p in (BASE.parent / name).rglob('*') if p.is_file())
    assert [p['path'] for p in plan['inputs']] == sorted(expected)
    pins = load(BASE / 'preflight-pins.json')
    assert [p['path'] for p in pins] == [str((BASE / n).relative_to(ROOT))
                                       for n in ('contract.md', 'prepare.py', 'audit.py', 'plan.json')]
    for item in pins + plan['inputs']:
        path = ROOT / item['path']
        assert item == receipt(path)
        if item in plan['inputs']:
            assert path.read_bytes() == subprocess.check_output(['git', 'show', REVISION + ':' + item['path']], cwd=ROOT)
    return pins


def domain(plan, healthy):
    assert set(plan) == {'schema', 'owner', 'source_revision', 'inputs', 'healthy_input',
        'profiles', 'syscall_owner', 'syscall_reports', 'syscall_healthy_profiles',
        'execution_qualified', 'runtime_authorized', 'selection', 'contract'}
    assert plan['schema'] == 'fsmgen.release_readback_selection.v1'
    assert plan['owner'] == OWNER and plan['source_revision'] == REVISION
    assert plan['healthy_input'] == HEALTHY
    assert plan['contract'] == str((BASE / 'contract.md').relative_to(ROOT))
    assert plan['execution_qualified'] is False and plan['runtime_authorized'] is False
    assert plan['selection'] == 'Resolve symbol and occurrence from each current-input flow; baseline IDs are provenance only.'
    assert healthy['success'] is True and healthy['forbidden_process_attempts'] == 0
    assert len(plan['profiles']) == len(healthy['cases']) == 4
    ids = ['ordinary_retired_other_observation', 'equal_reference_retired_other_observation',
           'ordinary_active_runtime', 'ordinary_retired_last_observation']
    counts = []
    for index, (profile, row) in enumerate(zip(plan['profiles'], healthy['cases'])):
        op = row['operation']
        calls = op['boundary_calls']
        assert [c['id'] for c in calls] == list(range(len(calls)))
        assert row['profile_id'] == ids[index]
        assert op['result']['success'] == 1 and op['result']['runtime_authorized'] == 0
        assert op['all_observed_handles_closed'] == 1
        assert len(op['unlinks']) == 1 and op['unlinks'][0]['actual_count'] == 1
        sources = [c for c in calls if c['name'] == SOURCE]
        handles = [h for h in op['handles'] if h['kind'] == 'source']
        assert len(sources) == len(handles)
        unlink, = [c['id'] for c in calls if c['name'] == RELEASE + '::_unlink_exact']
        absences = [c for c in calls if c['name'] == RELEASE + '::_assert_absent']
        assert [c['phase'] for c in absences] == ['after_unlink', 'finish']
        intervals = []
        for absence in absences:
            descendants = {absence['id']}
            for call in calls[absence['id'] + 1:]:
                if call['parent'] in descendants:
                    descendants.add(call['id'])
            intervals.append((max(descendants), absence['phase']))
        expected_sources = []
        for occurrence, (call, handle) in enumerate(zip(sources, handles)):
            assert call['occurrence'] == occurrence
            assert call['path'] == handle['path'] and handle['label'] == 'source:' + str(occurrence)
            assert 0 < handle['size_bytes'] <= call['limit']
            assert handle['actual_close_ok'] == handle['closed_at_return'] == 1
            # An absence helper has no nested source; its completed subtree
            # interval, rather than the event walker, determines prior truth.
            assert all(not (a['id'] < call['id'] <= end)
                       for a, (end, _) in zip(absences, intervals))
            completed = [phase for end, phase in intervals if end < call['id']]
            unlinked = int(call['id'] > unlink)
            effects = dict(unlink_attempted=unlinked, unlink_completed=unlinked,
                reference_absence_verified=int(bool(completed)),
                last_reference_check=dict(phase=completed[-1], state='absent') if completed else None)
            expected_sources.append(dict(symbol=SOURCE, occurrence=occurrence,
                baseline=dict(call_id=call['id'], path=call['path'], mode=call['mode'],
                    limit=call['limit'], size_bytes=handle['size_bytes'], sha256=handle['sha256'],
                    parent=calls[call['parent']]['name']), effects_before_source=effects))
        expected_profile = dict(id=ids[index], baseline_index=index, owner=OWNER[:-1] + str(index + 2),
            selection=row['selection'], sources=expected_sources, source_modes=MODES,
            positive_controls=['healthy', 'first-source-one-byte-then-normal'],
            proposed_cases=len(sources) * 4 + 2)
        assert json.dumps(profile, sort_keys=True) == json.dumps(expected_profile, sort_keys=True)
        counts.append(len(sources))
    expected_reports = []
    for profile in ids:
        expected_reports.append(dict(profile=profile, control='unlink-eacces', phase=None,
            actual_hold='present', attempted=1, completed=0, historical=0, latest=None))
        for phase in ('after_unlink', 'finish'):
            for control in ('absence-eio', 'absence-present'):
                expected_reports.append(dict(profile=profile, control=control, phase=phase,
                    actual_hold='absent', attempted=1, completed=1,
                    historical=int(phase == 'finish'),
                    latest=dict(phase=phase, state='unknown' if control == 'absence-eio' else 'present')))
    assert plan['syscall_owner'] == OWNER[:-1] + '6'
    assert json.dumps(plan['syscall_reports'], sort_keys=True) == json.dumps(expected_reports, sort_keys=True)
    assert plan['syscall_healthy_profiles'] == ids
    return counts


def falsify(plan, healthy):
    controls = [
        ('missing profile', lambda p: p['profiles'].pop()),
        ('duplicated profile', lambda p: p['profiles'].__setitem__(1, copy.deepcopy(p['profiles'][0]))),
        ('reordered profiles', lambda p: p['profiles'].reverse()),
        ('missing source', lambda p: p['profiles'][0]['sources'].pop()),
        ('duplicated source', lambda p: p['profiles'][0]['sources'].append(copy.deepcopy(p['profiles'][0]['sources'][0]))),
        ('reordered modes', lambda p: p['profiles'][0]['source_modes'].reverse()),
        ('wrong occurrence', lambda p: p['profiles'][0]['sources'][0].__setitem__('occurrence', 1)),
        ('wrong path', lambda p: p['profiles'][0]['sources'][0]['baseline'].__setitem__('path', 'foreign')),
        ('wrong digest', lambda p: p['profiles'][0]['sources'][0]['baseline'].__setitem__('sha256', '0' * 64)),
        ('wrong mode', lambda p: p['profiles'][0]['sources'][0]['baseline'].__setitem__('mode', 0)),
        ('wrong parent', lambda p: p['profiles'][0]['sources'][0]['baseline'].__setitem__('parent', 'foreign')),
        ('stale id', lambda p: p['profiles'][0]['sources'][0]['baseline'].__setitem__('call_id', -1)),
        ('invented unlink', lambda p: p['profiles'][0]['sources'][0]['effects_before_source'].__setitem__('unlink_completed', 1)),
        ('wrong count', lambda p: p['profiles'][0].__setitem__('proposed_cases', 1)),
        ('invented execution', lambda p: p.__setitem__('execution_qualified', True)),
        ('invented authority', lambda p: p.__setitem__('runtime_authorized', True)),
        ('false physical presence', lambda p: p['syscall_reports'][1].__setitem__('actual_hold', 'present')),
        ('false history', lambda p: p['syscall_reports'][1].__setitem__('historical', 1)),
        ('false latest state', lambda p: p['syscall_reports'][1]['latest'].__setitem__('state', 'absent')),
        ('missing syscall report', lambda p: p['syscall_reports'].pop()),
        ('boolean count', lambda p: p['profiles'][0]['sources'][0].__setitem__('occurrence', False)),
    ]
    for name, mutate in controls:
        changed = copy.deepcopy(plan)
        mutate(changed)
        try:
            domain(changed, healthy)
        except (AssertionError, KeyError, TypeError, ValueError, IndexError):
            continue
        raise AssertionError('accepted corrupt domain: ' + name)
    return [name for name, _ in controls]


def main():
    assert not sys.argv[1:], 'read-only audit accepts no execution option'
    plan = load(BASE / 'plan.json')
    pins = authenticate(plan)
    healthy = load(ROOT / HEALTHY)
    counts = domain(plan, healthy)
    controls = falsify(plan, healthy)
    roots = [entry['path'] for entry in healthy['allocated']]
    assert len(roots) == len(set(roots)) == 16
    for name in roots:
        assert not (ROOT / name).exists() and not (ROOT / name).is_symlink()
    print(json.dumps(dict(schema='fsmgen.release_readback_selection_audit.v1', success=True,
        inputs=len(plan['inputs']), prospective_pins=len(pins), source_occurrences=counts,
        source_faults=sum(counts) * 4, source_positive_controls=8,
        syscall_report_faults=len(plan['syscall_reports']), syscall_positive_controls=4,
        proposed_cases=sum(p['proposed_cases'] for p in plan['profiles']) + 24,
        rejected_controls=controls, checked_previous_roots_absent=len(roots),
        executed_fixtures=0, execution_qualified=False, runtime_authorized=False), sort_keys=True))


if __name__ == '__main__':
    main()
