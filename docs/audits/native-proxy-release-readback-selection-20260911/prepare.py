"""Prepare a finite prospective domain from retained healthy events only."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '1db83632112c1b452c3c3e2f98a13cfeed5647f9'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.3.10.1'
HEALTHY = 'docs/audits/native-proxy-observation-archive-release-boundaries-20260911/result/qualification.json'
PREVIOUS = ROOT / 'docs/audits/native-proxy-release-call-selection-20260911/plan.json'
MODES = ['first-eio', 'partial-eio', 'early-eof', 'body-xor']
SOURCE = 'NativeProxyImageCustody::_source'
RELEASE = 'NativeProxyObservationRelease'


def load(path):
    return json.loads(path.read_bytes())


def pin(path):
    raw = path.read_bytes()
    assert path.stat().st_dev == ROOT.stat().st_dev
    for ancestor in [path, *path.parents]:
        if ancestor == ROOT:
            break
        assert not ancestor.is_symlink()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw),
                sha256=hashlib.sha256(raw).hexdigest())


def input_paths():
    paths = {item['path'] for item in load(PREVIOUS)['inputs']}
    paths.add(str(PREVIOUS.relative_to(ROOT)))
    for name in ('native-proxy-observation-archive-lower-reader-seam-20260911',
                 'native-proxy-observation-archive-lower-reader-failures-20260911'):
        paths.update(str(p.relative_to(ROOT)) for p in (BASE.parent / name).rglob('*') if p.is_file())
    return sorted(paths)


def source_domain(row):
    op = row['operation']
    calls = {c['id']: c for c in op['boundary_calls']}
    handles = [h for h in op['handles'] if h['kind'] == 'source']
    result = []
    effects = dict(unlink_attempted=0, unlink_completed=0,
                   reference_absence_verified=0, last_reference_check=None)
    for event in op['events']:
        if event == 'unlink:0:before':
            effects['unlink_attempted'] = 1
        elif event == 'unlink:0:after':
            effects['unlink_completed'] = 1
        elif event.startswith('call:'):
            _, ident, phase = event.split(':')
            call = calls[int(ident)]
            if call['name'] == RELEASE + '::_assert_absent' and phase == 'after':
                effects['reference_absence_verified'] = 1
                effects['last_reference_check'] = dict(phase=call['phase'], state='absent')
            if call['name'] != SOURCE or phase != 'before':
                continue
            occurrence = len(result)
            assert call['occurrence'] == occurrence
            handle = handles[occurrence]
            assert handle['path'] == call['path'] and 0 < handle['size_bytes'] <= call['limit']
            result.append(dict(symbol=SOURCE, occurrence=occurrence,
                baseline=dict(call_id=call['id'], path=call['path'], mode=call['mode'],
                    limit=call['limit'], size_bytes=handle['size_bytes'], sha256=handle['sha256'],
                    parent=calls[call['parent']]['name']),
                effects_before_source=json.loads(json.dumps(effects))))
    return result


def create_plan(inputs):
    healthy = load(ROOT / HEALTHY)
    assert healthy['success'] is True and healthy['forbidden_process_attempts'] == 0
    profiles = []
    for index, row in enumerate(healthy['cases']):
        domain = source_domain(row)
        profiles.append(dict(id=row['profile_id'], baseline_index=index,
            owner=OWNER[:-1] + str(index + 2), selection=row['selection'],
            sources=domain, source_modes=MODES,
            positive_controls=['healthy', 'first-source-one-byte-then-normal'],
            proposed_cases=len(domain) * len(MODES) + 2))
    reports = []
    for profile in profiles:
        reports.append(dict(profile=profile['id'], control='unlink-eacces', phase=None,
                            actual_hold='present', attempted=1, completed=0, historical=0, latest=None))
        for index, phase in enumerate(('after_unlink', 'finish')):
            for control, state in [('absence-eio', 'unknown'), ('absence-present', 'present')]:
                reports.append(dict(profile=profile['id'], control=control, phase=phase,
                    actual_hold='absent', attempted=1, completed=1, historical=index,
                    latest=dict(phase=phase, state=state)))
    return dict(schema='fsmgen.release_readback_selection.v1', owner=OWNER,
        source_revision=REVISION, inputs=inputs, healthy_input=HEALTHY,
        profiles=profiles, syscall_owner=OWNER[:-1] + '6', syscall_reports=reports,
        syscall_healthy_profiles=[p['id'] for p in profiles],
        execution_qualified=False, runtime_authorized=False,
        selection='Resolve symbol and occurrence from each current-input flow; baseline IDs are provenance only.',
        contract=str((BASE / 'contract.md').relative_to(ROOT)))


def main():
    assert not (BASE / 'plan.json').exists(), 'never overwrite a prepared domain'
    inputs = []
    for name in input_paths():
        path = ROOT / name
        assert path.read_bytes() == subprocess.check_output(['git', 'show', REVISION + ':' + name], cwd=ROOT)
        inputs.append(pin(path))
    plan = create_plan(inputs)
    with (BASE / 'plan.json').open('x') as output:
        output.write(json.dumps(plan, sort_keys=True, indent=2) + '\n')
    print(json.dumps(dict(success=True, inputs=len(inputs),
        source_occurrences=sum(len(p['sources']) for p in plan['profiles']),
        proposed_cases=sum(p['proposed_cases'] for p in plan['profiles'])
            + len(plan['syscall_reports']) + len(plan['syscall_healthy_profiles']),
        executed_fixtures=0), sort_keys=True))


if __name__ == '__main__':
    main()
