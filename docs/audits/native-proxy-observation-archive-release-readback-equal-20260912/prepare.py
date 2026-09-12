"""Pin the equal-reference readback partition before any fixture allocation."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
ORDINARY = BASE.with_name('native-proxy-observation-archive-release-readback-ordinary-20260911')
REVISION = 'de1e17c8cbdef50ce19e96eaa9eb95fb63fc56f2'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.3.10.3'


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
    old = load(ORDINARY / 'plan.json')
    paths = {p['path'] for p in old['inputs']}
    for name in ('preflight-pins.json', 'audit-correction-pins.json'):
        paths.update(p['path'] for p in load(ORDINARY / name))
    paths.update(str((ORDINARY / name).relative_to(ROOT)) for name in (
        'plan.json', 'preflight-pins.json', 'audit-correction-pins.json',
        'result/qualification.json', 'result/audit.json', 'result/cases/case-0482.json'))
    reports = old['previous_root_reports'] + [str((ORDINARY / 'result/qualification.json').relative_to(ROOT))]
    paths.update(reports)
    inputs = []
    for name in sorted(paths):
        path = ROOT / name
        assert path.read_bytes() == subprocess.check_output(['git', 'show', REVISION + ':' + name], cwd=ROOT)
        inputs.append(pin(path))
    original = load(BASE.with_name('native-proxy-release-readback-selection-20260911') / 'plan.json')['profiles'][1]
    corrected = load(BASE.with_name('native-proxy-release-readback-applicability-20260911') / 'applicability.json')['profiles'][1]
    assert original['id'] == corrected['id'] == 'equal_reference_retired_other_observation'
    assert original['owner'] == corrected['execution_owner'] == OWNER
    final = dict(unlink_attempted=1, unlink_completed=1, reference_absence_verified=1,
                 last_reference_check=dict(phase='finish', state='absent'))
    cases = []

    def append(name, selector, success, effects):
        cases.append(dict(index=len(cases), name=name, selector=selector, role='primary',
                          expected_success=int(success), expected_effects=copy.deepcopy(effects)))

    append('healthy:equal-reference', None, True, final)
    append('first-source-one-byte-then-normal', dict(control='one-byte', occurrence=0, strong_alias=0), True, final)
    for source, body in zip(original['sources'], corrected['body_xor'], strict=True):
        assert source['occurrence'] == body['occurrence']
        for mode in original['source_modes']:
            success = mode == 'body-xor' and body['expected_success']
            append('source#' + str(source['occurrence']) + ':' + mode,
                   dict(control=mode, occurrence=source['occurrence'], strong_alias=0), success,
                   final if success else source['effects_before_source'])
    assert len(cases) == corrected['source_case_count'] == 462
    assert sum(c['expected_success'] for c in cases) == corrected['expected_source_case_successes'] == 10
    return dict(schema='fsmgen.release_readback_equal_plan.v1', owner=OWNER, source_revision=REVISION,
        component=BASE.name, profile_id=original['id'], selection=original['selection'],
        source_boundaries=old['source_boundaries'], sealed_symbols=old['sealed_symbols'],
        inputs=inputs, previous_root_reports=reports, cases=cases, publication=old['publication'],
        primary_cases=462, primary_successes=10, primary_rejections=452, seam_counterexamples=0,
        scope='Equal-reference retired Source-read controls using unchanged qualified instrumentation. '
              'Equal wrapper/private/global bytes retain distinct original identities and shared archive identity. '
              'Actual reads and reported controls stay separate; no original producer, compiler, native execution, '
              'other profile or syscall-report domain. The prior strong-alias counterexample is authenticated, not repeated or counted here.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as output:
        output.write(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(cases=len(plan['cases']), primary=plan['primary_cases'],
                         counterexamples=plan['seam_counterexamples'], inputs=len(plan['inputs'])), sort_keys=True))
