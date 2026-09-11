"""Prospectively select lower-reader weak observation and caller-owned cleanup."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '94ba98609063049d44a46f1dddd19fd065e130cd'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.4.2.3.1'
CLOSE = BASE.parent / 'native-proxy-observation-archive-close-reports-20260911'


def build():
    prior = json.loads((CLOSE / 'plan.json').read_bytes())
    paths = {row['path'] for row in prior['inputs']}
    paths.update(str((CLOSE / name).relative_to(ROOT)) for name in ('plan.json', 'audit.py'))
    inputs = []
    for path in sorted(paths):
        raw = (ROOT / path).read_bytes()
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)
        inputs.append(dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    cases = [dict(name=profile + ':' + str(keep), profile=profile, keep_open=keep,
                  fail_read=False, strong_alias=False)
             for profile in ('empty', 'binary', 'maximum') for keep in (0, 1)]
    cases += [dict(name='read-failure:' + ('strong-counterexample' if strong else 'weak'),
                   profile='binary', keep_open=1, fail_read=True, strong_alias=strong)
              for strong in (False, True)]
    return dict(schema='fsmgen.inactive_archive_lower_reader_seam_plan.v1',
        source_revision=REVISION, owner=OWNER, inputs=inputs, cases=cases,
        contract='Invoke the unchanged bounded lower reader directly on fresh inert regular files. Observe actual opens, reads and explicit reader closes. Ordinary instrumentation retains weak GLOB aliases only. An actual POSIX dup probe distinguishes an open observed descriptor from EBADF, closes only its own duplicates immediately, and binds native metadata. The caller closes successful keep-open results. Paired first-read EIO controls compare weak observation with a deliberately strong observer alias; preserve the original reader failure and pre-recovery liveness, then explicitly close only the retained control handle.',
        limits='Direct lower-helper observer qualification, not a new full archive operation or native fixture execution. Deliberate strong retention is observer bias, not a demonstrated runtime leak. Directory/size/read-admission failure coverage and composition with archive cleanup are separately owned. No probe closes an original numeric descriptor.')


if __name__ == '__main__':
    plan = build()
    (BASE / 'plan.json').write_text(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(cases=len(plan['cases']), unchanged_inputs=len(plan['inputs'])), sort_keys=True))
