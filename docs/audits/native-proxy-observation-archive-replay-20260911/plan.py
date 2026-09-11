"""Pin the closed saved-archive audit set and its tracked recovery inputs."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '698f99da3ca3dfe47b89fc17db142b3784f37907'
MATRICES = {
    'records': 'native-proxy-observation-archive-records-20260911',
    'files': 'native-proxy-observation-archive-20260911',
    'boundaries': 'native-proxy-observation-archive-boundaries-20260911',
    'ordinary-fresh': 'native-proxy-observation-archive-fresh-calls-20260911',
    'ordinary-existing': 'native-proxy-observation-archive-existing-calls-20260911',
    'equal-fresh': 'native-proxy-observation-archive-equal-fresh-calls-20260911',
    'equal-existing': 'native-proxy-observation-archive-equal-existing-calls-20260911',
}
MAX_FILE_BYTES = 64 * 1024 * 1024
MAX_SOURCE_FILES = 256
MAX_SOURCE_BYTES = 256 * 1024 * 1024


def pin(path):
    relative = str(path.relative_to(ROOT))
    raw = path.read_bytes()
    assert len(raw) <= MAX_FILE_BYTES, relative
    size = subprocess.check_output(['git', 'cat-file', '-s', REVISION + ':' + relative], cwd=ROOT)
    assert int(size) == len(raw)
    assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + relative], cwd=ROOT)
    return dict(path=relative, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def build():
    inputs = {}
    matrices = {}
    for name, component in MATRICES.items():
        directory = ROOT / 'docs/audits' / component
        manifest_path = directory / 'result/recovery-copies.json'
        manifest = json.loads(manifest_path.read_bytes())
        plan_path = directory / 'plan.json'
        plan = json.loads(plan_path.read_bytes())
        pins_path = directory / 'result/preflight-pins.json'
        prospective = json.loads(pins_path.read_bytes())
        paths = {row['path'] for row in plan['inputs'] + prospective}
        paths.update(str(path.relative_to(ROOT)) for path in
                     (manifest_path, plan_path, pins_path, directory / 'audit.py'))
        saved = {}
        assert manifest['all_copies_byte_exact'] is True
        for row in manifest['files']:
            destination = Path(row['destination'])
            assert destination.parent == Path('docs/audits') / component / 'result'
            assert row['source'] == '.artifacts/logs/' + component + '/' + destination.name
            assert destination.name not in saved
            saved[destination.name] = dict(path=row['destination'], size_bytes=row['size_bytes'], sha256=row['sha256'])
            paths.add(row['destination'])
        seed_names = ['preflight-pins.json', 'qualification.json', 'qualify.tap', 'qualify.exit']
        if name != 'records':
            seed_names.append('admission.jsonl')
        assert {'audit.json', 'audit.exit', *seed_names} <= saved.keys()
        assert (ROOT / saved['audit.exit']['path']).read_text().strip() == '0'
        assert (ROOT / saved['qualify.exit']['path']).read_text().strip() == '0'
        for path in sorted(paths):
            current = pin(ROOT / path)
            assert path not in inputs or inputs[path] == current
            inputs[path] = current
        for row in saved.values():
            assert row == inputs[row['path']]
        matrices[name] = dict(component=component,
            audit=str((directory / 'audit.py').relative_to(ROOT)),
            source_paths=sorted(paths), seed=[saved[name] for name in seed_names],
            expected_audit=saved['audit.json'], historical_log='.artifacts/logs/' + component)
    assert len(inputs) <= MAX_SOURCE_FILES
    assert sum(row['size_bytes'] for row in inputs.values()) <= MAX_SOURCE_BYTES
    return dict(schema='fsmgen.inactive_archive_saved_replay_plan.v1', source_revision=REVISION,
        owner='HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.5',
        matrices=matrices, inputs=[inputs[path] for path in sorted(inputs)],
        limits=dict(file_bytes=MAX_FILE_BYTES, source_files=MAX_SOURCE_FILES,
                    source_bytes=MAX_SOURCE_BYTES, captured_stream_bytes=1024 * 1024),
        contract='Revalidate the saved qualification through its unchanged independent audit, not through qualify.t. Reconstruct every LOG input only from tracked recovery copies; pin selected dependencies to this exact Git tree and retain each audit\'s own earlier version checks. Allocate a fresh direct same-volume private output namespace per invocation. Preserve original source/recovery/log bytes. Compare each regenerated audit byte-for-byte with its tracked expected audit. A missing/changed source, seed or result is a failure, not permission to rerun a historical producer. No compiler, native experiment, original fixture or release authority is created.',
        controls=['missing tracked input', 'altered tracked input', 'missing catalogue dependency',
                  'wrong seed digest', 'wrong expected audit', 'unknown matrix', 'duplicate matrix',
                  'symlink output parent', 'auditor failure', 'altered audit result',
                  'legacy-log content access forbidden', 'non-root caller working directory',
                  'repeated invocation uses a distinct output', 'original evidence remains unchanged'])


if __name__ == '__main__':
    plan = build()
    (BASE / 'plan.json').write_text(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(matrices=len(plan['matrices']), inputs=len(plan['inputs']),
        input_bytes=sum(row['size_bytes'] for row in plan['inputs']),
        largest_input_bytes=max(row['size_bytes'] for row in plan['inputs'])), sort_keys=True))
