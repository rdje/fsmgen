"""Prepare a corrected ordinary readback domain without allocating a fixture."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'efadb9148c14391fde011851e766a72b84bcfda8'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.3.10.2.2'
PREVIOUS = ['ordinary-before', 'ordinary-after', 'equal-before', 'equal-after',
            'active-before', 'active-after', 'last-before', 'last-after']


def load(path):
    return json.loads(path.read_bytes())


def pin(path):
    raw = path.read_bytes()
    for ancestor in [path, *path.parents]:
        if ancestor == ROOT:
            break
        assert not ancestor.is_symlink() and ancestor.stat().st_dev == ROOT.stat().st_dev
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def build():
    assert load(BASE / 'prepare-pins.json') == [pin(BASE / 'prepare.py')]
    preflight = load(BASE / 'oracle-preflight-plan.json')
    paths = {p['path'] for p in preflight['inputs']}
    before = BASE.with_name('native-proxy-observation-archive-release-ordinary-before-20260911')
    paths.update(str((before / n).relative_to(ROOT)) for n in ('plan.json', 'qualify.t', 'CallPlan.pm', 'CallFaultTrace.pm'))
    old_reports = ['docs/audits/native-proxy-observation-archive-release-boundaries-20260911/result/qualification.json']
    old_reports.extend('docs/audits/native-proxy-observation-archive-release-' + p + '-20260911/result/qualification.json'
                       for p in PREVIOUS)
    paths.update(old_reports)
    inputs = []
    for name in sorted(paths):
        path = ROOT / name
        assert path.read_bytes() == subprocess.check_output(['git', 'show', REVISION + ':' + name], cwd=ROOT)
        inputs.append(pin(path))
    original = load(BASE.with_name('native-proxy-release-readback-selection-20260911') / 'plan.json')
    corrected = load(BASE.with_name('native-proxy-release-readback-applicability-20260911') / 'applicability.json')
    profile = original['profiles'][0]
    correction = corrected['profiles'][0]
    assert profile['id'] == correction['id'] == 'ordinary_retired_other_observation'
    assert correction['execution_owner'] == OWNER
    final = dict(unlink_attempted=1, unlink_completed=1, reference_absence_verified=1,
                 last_reference_check=dict(phase='finish', state='absent'))
    cases = []

    def append(name, selector, success, effects, role='primary'):
        cases.append(dict(index=len(cases), name=name, selector=selector, role=role,
                          expected_success=int(success), expected_effects=copy.deepcopy(effects)))

    append('healthy:ordinary', None, True, final)
    append('first-source-one-byte-then-normal', dict(control='one-byte', occurrence=0, strong_alias=0), True, final)
    for source, body in zip(profile['sources'], correction['body_xor'], strict=True):
        assert source['occurrence'] == body['occurrence']
        for mode in profile['source_modes']:
            success = mode == 'body-xor' and body['expected_success']
            append('source#' + str(source['occurrence']) + ':' + mode,
                   dict(control=mode, occurrence=source['occurrence'], strong_alias=0), success,
                   final if success else source['effects_before_source'])
    assert len(cases) == correction['source_case_count'] == 482
    assert sum(c['expected_success'] for c in cases) == correction['expected_source_case_successes'] == 10
    append('strong-alias:first-source-eio', dict(control='first-eio', occurrence=0, strong_alias=1),
           False, profile['sources'][0]['effects_before_source'], 'seam_counterexample')
    boundary = load(before / 'plan.json')
    return dict(schema='fsmgen.release_readback_ordinary_plan.v1', owner=OWNER, source_revision=REVISION,
        component=BASE.name, profile_id=profile['id'], selection=profile['selection'],
        source_boundaries=boundary['source_boundaries'], sealed_symbols=boundary['sealed_symbols'],
        inputs=inputs, previous_root_reports=old_reports, cases=cases, publication=boundary['publication'],
        primary_cases=482, primary_successes=10, primary_rejections=472, seam_counterexamples=1,
        scope='Corrected ordinary retired primary Source-read domain plus one separately counted strong-alias seam counterexample. Real opened files and reads; controlled errno, EOF and buffer reports; unchanged original consumers and cleanup. No prior producer, compiler, native execution, other profile or syscall-report domain.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as output:
        output.write(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(cases=len(plan['cases']), primary=plan['primary_cases'],
                         counterexamples=plan['seam_counterexamples'], inputs=len(plan['inputs'])), sort_keys=True))
