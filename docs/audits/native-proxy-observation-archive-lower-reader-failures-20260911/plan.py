"""Prospectively select bounded lower-reader pre-handoff failures."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '05957842d584b6b3f434e2b2d20c65316e16e39c'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.4.2.3.2'
CLOSE = BASE.parent / 'native-proxy-observation-archive-close-reports-20260911'


def build():
    prior = json.loads((CLOSE / 'plan.json').read_bytes())
    paths = {row['path'] for row in prior['inputs']}
    paths.update(str((CLOSE / name).relative_to(ROOT)) for name in ('plan.json', 'audit.py'))
    seam = BASE.parent / 'native-proxy-observation-archive-lower-reader-seam-20260911'
    paths.update(str((seam / name).relative_to(ROOT)) for name in
        ('plan.py', 'plan.json', 'LowerReaderTrace.pm', 'qualify.t', 'audit.py', 'toolchain-reference.json',
         'preflight-pins.json', 'result/qualification.json', 'result/audit.json', 'result/recovery-copies.json'))
    inputs = []
    for path in sorted(paths):
        raw = (ROOT / path).read_bytes()
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)
        inputs.append(dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    cases = []
    for name, profile, control in [('empty', 'empty', 'none'), ('binary', 'binary', 'none'),
        ('maximum', 'maximum', 'none'), ('directory', 'directory', 'none'),
        ('oversized', 'oversized', 'none'), ('first-eio', 'binary', 'first-eio'),
        ('partial-eio', 'binary', 'partial-eio'), ('early-eof', 'binary', 'early-eof'),
        ('named-replacement', 'binary', 'named-replacement')]:
        cases.append(dict(name=name, profile=profile, control=control, keep_open=1,
                          fail_read=control == 'first-eio', strong_alias=False))
    return dict(schema='fsmgen.inactive_archive_lower_reader_failures_plan.v1',
        source_revision=REVISION, owner=OWNER, inputs=inputs, cases=cases,
        contract='Invoke the unchanged lower reader with keep-open ownership on fresh direct-helper sources. Reuse the exact qualified weak observer. A separately pinned read-control adapter tail-calls the original hook with preserved caller identity; it records caller requests and controlled requests/returns independently. Actual directory and oversized inputs fail after opening; selected read failures include first EIO, one actual byte then EIO, premature EOF and byte-identical named replacement before the final read. Retain displaced originals and all before/after state; prove actual descriptors closed before failed handoff.',
        limits='Finite direct-helper failure domain. No new full archive operation, native fixture execution, asynchronous race or arbitrary reader error is qualified. The observer source and product size limit remain unchanged. Broader archive coverage requires the separately owned source/custody composition.')


if __name__ == '__main__':
    plan = build()
    (BASE / 'plan.json').write_text(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(cases=len(plan['cases']), unchanged_inputs=len(plan['inputs'])), sort_keys=True))
