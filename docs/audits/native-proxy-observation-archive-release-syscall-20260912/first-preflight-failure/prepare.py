"""Pin the syscall-report domain before any fixture allocation."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PREVIOUS = BASE.with_name('native-proxy-observation-archive-release-readback-last-20260912')
REVISION = 'b6d957ca33c99956ccc7559764fa863e9f89567a'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.3.10.6'


def load(path):
    return json.loads(path.read_bytes())


def pin(path):
    for ancestor in [path, *path.parents]:
        if ancestor == ROOT:
            break
        assert not ancestor.is_symlink() and ancestor.stat().st_dev == ROOT.stat().st_dev
    raw = path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def build():
    assert load(BASE / 'prepare-pins.json') == [pin(BASE / 'prepare.py')]
    old = load(PREVIOUS / 'plan.json')
    paths = {p['path'] for p in old['inputs']}
    for name in ('preflight-pins.json',):
        paths.update(p['path'] for p in load(PREVIOUS / name))
    paths.update(str((PREVIOUS / name).relative_to(ROOT)) for name in (
        'plan.json', 'preflight-pins.json', 'oracle-preflight-result-pins.json',
        'result/oracle-preflight/oracle-preflight.json', 'result/oracle-preflight/oracle-preflight.stdout',
        'result/oracle-preflight/oracle-preflight.stderr', 'result/oracle-preflight/oracle-preflight.exit',
        'result/qualification.json', 'result/audit.json'))
    reports = old['previous_root_reports'] + [str((PREVIOUS / 'result/qualification.json').relative_to(ROOT))]
    paths.update(reports)
    paths.add('docs/audits/native-proxy-observation-archive-release-last-before-20260911/qualify.t')
    inputs = []
    for name in sorted(paths):
        path = ROOT / name
        assert path.read_bytes() == subprocess.check_output(['git', 'show', REVISION + ':' + name], cwd=ROOT)
        inputs.append(pin(path))
    original = load(BASE.with_name('native-proxy-release-readback-selection-20260911') / 'plan.json')
    assert original['syscall_owner'] == OWNER
    profiles = [p for p in original['profiles'] if p['id'] in original['syscall_healthy_profiles']]
    cases = []
    for profile in profiles:
        for report in [None] + [r for r in original['syscall_reports'] if r['profile'] == profile['id']]:
            effects = dict(unlink_attempted=1, unlink_completed=1, reference_absence_verified=1,
                           last_reference_check=dict(phase='finish', state='absent'))
            if report:
                effects = dict(unlink_attempted=report['attempted'], unlink_completed=report['completed'],
                    reference_absence_verified=report['historical'], last_reference_check=report['latest'])
            cases.append(dict(index=len(cases), name=profile['id'] + ':' +
                ('healthy' if report is None else report['control'] + ':' + str(report['phase'])),
                profile_id=profile['id'], selection=profile['selection'], selector=report,
                expected_success=int(report is None), expected_effects=effects))
    assert len(cases) == 24
    return dict(schema='fsmgen.release_syscall_plan.v1', owner=OWNER, source_revision=REVISION,
        component=BASE.name, source_boundaries=old['source_boundaries'], sealed_symbols=old['sealed_symbols'],
        inputs=inputs, previous_root_reports=reports, cases=cases, publication=old['publication'],
        scope='Selected healthy profiles and modeled unlink/absence reports only. Actual syscalls, '
              'reported results and physical snapshots are separate. No native execution, OS-failure '
              'guarantee, concurrent-writer atomicity, close-error composition or reader-control cross product.')



if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as output:
        output.write(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(cases=len(plan['cases']), inputs=len(plan['inputs'])), sort_keys=True))
