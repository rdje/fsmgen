"""Prospective actual-file release cases and exact source applicability inputs."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '79b43fd019387acdf1fc3280b3f88847125fbb60'
WORK = 'docs/audits/native-proxy-observation-work-records-20260911'
BOUNDARY = 'docs/audits/native-proxy-observation-archive-boundaries-20260911'
COORDINATOR = 'docs/audits/native-proxy-image-coordination-20260910/Coordination.pm'


def build():
    contract = json.loads((BASE / 'contract.json').read_bytes())
    cases = []
    def add(name, *, wrapper='ordinary', runtime='retired', last=False, cleanup='mixed', mutation='none',
            control='none', argument_change=None, success=False, unlinked=False, returned=True, error='.+'):
        cases.append(dict(name=name, wrapper=wrapper, runtime=runtime, last_observation=last, cleanup=cleanup,
                          mutation=mutation, control=control, argument_change=argument_change,
                          expected_success=success, expected_unlinked=unlinked, expected_public_return=returned,
                          expected_error=error))
    for wrapper in ['ordinary', 'binary', 'empty', 'maximum', 'equal_reference']:
        add('healthy:' + wrapper, wrapper=wrapper, success=True, unlinked=True, error='')
    add('healthy:runtime-still-active', runtime='active', success=True, unlinked=True, error='')
    add('healthy:last-observation', last=True, success=True, unlinked=True, error='')
    add('healthy:never-started-cancelled-helper', cleanup='never-started', success=True, unlinked=True, error='')
    for mutation, error in [
        ('unsealed', 'selected work is not sealed'), ('missing-receipt', 'every selected work receipt'),
        ('wrong-owner', 'changes selected ownership'), ('unreaped', 'cleanup is incomplete'),
        ('surviving-group', 'cleanup is incomplete'), ('legacy-helper-event', 'every selected work receipt'),
        ('foreign-archive-receipt', 'archive observation reference differs'),
        ('foreign-selection', 'work selection differs from original observation key')]:
        add('rejected:' + mutation, mutation=mutation, error=error)
    for mutation in ['missing-archive', 'partial-archive', 'changed-archive', 'replaced-archive-file',
                     'archive-mode', 'replaced-evidence', 'missing-hold', 'changed-hold', 'replaced-hold',
                     'missing-lock', 'replaced-lock', 'lock-mode', 'changed-image', 'replaced-image']:
        add('rejected:' + mutation, mutation=mutation)
    for control, error in [('direct-coordinator', 'unknown inactive transaction'), ('direct-unlink', 'exact unlink requires the release owner')]:
        add('rejected:' + control, control=control, returned=False, error=error)
    for change in ['drop', 'append']:
        add('rejected:arity-' + change, argument_change=change, returned=False, error='expected store, request, acquisition, archive')
    for control, error in [('before-finish', 'controlled failure after exact unlink'),
                           ('source-close-after-unlink', 'cannot close retained release descriptor'),
                           ('lock-close-after-unlink', 'cannot close permanent lock'),
                           ('primary-and-source-close', 'controlled failure after exact unlink')]:
        add('post-unlink:' + control, control=control, unlinked=True, error=error)
    assert len({case['name'] for case in cases}) == len(cases)
    paths = set()
    for component in [WORK, BOUNDARY]:
        source = json.loads((ROOT / component / 'plan.json').read_bytes())
        paths.update(pin['path'] for pin in source['inputs'])
    paths.update([WORK + '/' + name for name in ['WorkRecord.pm', 'plan.json', 'audit.py', 'result/qualification.json', 'result/audit.json', 'preflight-pins.json']])
    paths.update([BOUNDARY + '/' + name for name in ['ArchiveFixture.pm', 'ArchiveTrace.pm', 'plan.json', 'audit.py', 'result/qualification.json']])
    paths.update(['docs/audits/native-proxy-observation-archive-20260911/ObservationArchive.pm',
                  'docs/audits/native-proxy-runtime-retirement-20260910/PrivateWorkspace.pm'])
    inputs = []
    for path in sorted(paths):
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)
        if path != COORDINATOR: assert (ROOT / path).read_bytes() == raw
        inputs.append(dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest(),
                           applicability='exact_reverse_extension' if path == COORDINATOR else 'unchanged_current_source'))
    return dict(schema='fsmgen.inactive_observation_release_qualification_plan.v1', owner=contract['owner'],
                source_revision=REVISION, contract='contract.json', cases=cases, inputs=inputs,
                component=BASE.name, effect_fields=['unlink_attempted', 'unlink_completed', 'reference_absence_verified', 'last_reference_check'],
                limits='Only declared inert actual-file release cases. Outcomes and preselected owner records are synthetic. Deliberate setup changes are captured before the observed release, and relocated original files are retained in owned fixture roots until cleanup. Actual and modeled close returns remain separate. No original matrix, native process, arbitrary callback under lock, original-byte reconstruction, OS close ambiguity or asynchronous crash/race claim. The following leaf owns complete selected interruption/close/applicability closure.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as stream: stream.write(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(cases=len(plan['cases']), inputs=len(plan['inputs']), successful_cases=sum(row['expected_success'] for row in plan['cases']),
                         post_unlink_failures=sum(row['expected_unlinked'] and not row['expected_success'] for row in plan['cases'])), sort_keys=True))
