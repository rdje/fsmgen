"""Retain the first completed worker run without invoking any producer."""
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
ADMISSION = 'docs/audits/native-proxy-populated-final-admission-20260913'
REVISION = '266e8a99f407b0cc1649c5791ee8c5c4edc3b50c'
sys.path.insert(0, str(ROOT / ADMISSION))
import review_run
import contract


def save(path, value):
    with path.open('x') as stream:
        json.dump(value, stream, sort_keys=True, indent=2)
        stream.write('\n')


def pin(path, body):
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(body),
                sha256=hashlib.sha256(body).hexdigest())


def retain():
    assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip() == REVISION
    reviewed = review_run.verify(saved=True)
    outputs = review_run.read_outputs(True)
    assert reviewed['admission_commit'] == REVISION
    assert len(outputs) == 47
    destination = BASE / 'first-results'
    assert BASE.stat().st_dev == ROOT.stat().st_dev and not BASE.is_symlink()
    destination.mkdir(mode=0o700)
    retained = []
    for name, body in sorted(outputs.items()):
        original = ROOT / contract.OUTPUT / name
        before = original.lstat()
        assert stat.S_ISREG(before.st_mode) and before.st_nlink == 1
        assert before.st_uid == os.getuid() and before.st_dev == ROOT.stat().st_dev
        target = destination / name
        with target.open('xb') as stream:
            assert stream.write(body) == len(body)
        assert target.read_bytes() == body == original.read_bytes()
        after = original.lstat()
        assert (before.st_dev, before.st_ino, before.st_mode, before.st_size,
                before.st_mtime_ns, before.st_ctime_ns) == (
                after.st_dev, after.st_ino, after.st_mode, after.st_size,
                after.st_mtime_ns, after.st_ctime_ns)
        retained.append(dict(original=str(original.relative_to(ROOT)), copy=pin(target, body),
            original_device=before.st_dev, original_inode=before.st_ino,
            original_mode=stat.S_IMODE(before.st_mode), original_uid=before.st_uid))
    log = ROOT / '.artifacts/logs' / BASE.name
    raw = {name: {ext: (log / (name + '.' + ext)).read_text()
                 for ext in ('stdout', 'stderr', 'exit')}
           for name in ('issuer-first', 'driver-first', 'reviewer-first')}
    assert all(row['exit'] == '0\n' for row in raw.values())
    driver = json.loads(raw['driver-first']['stdout'])
    assert driver == dict(success=True, cases=6, output=contract.OUTPUT)
    scope = dict(owner=contract.EXECUTION_OWNER,
        next_owner=contract.EXECUTION_OWNER.rsplit('.', 1)[0] + '.3',
        admission_commit=REVISION, admission_directory=ADMISSION,
        original_output=contract.OUTPUT, first_results=retained, raw_outputs=raw,
        producer_reusable=False, original_outputs_preserved=True,
        synthetic_retirement_and_work_records=True, compiler_execution=False,
        proxy_execution=False, live_collector_execution=False,
        final_cross_boundary_join_open=True, native_live_startup_qualification_open=True)
    save(BASE / 'first-results.json', scope)
    current = ROOT / ADMISSION / 'execution-source-pins.json'
    selected = json.loads(current.read_bytes())
    for name in ('execution-source-pins.json', 'plan.json', 'qualification.json', 'review.json'):
        path = ROOT / ADMISSION / name
        selected.append(pin(path, path.read_bytes()))
    assert len({row['path'] for row in selected}) == len(selected)
    save(BASE / 'source-pins.json', sorted(selected, key=lambda row: row['path']))
    print(json.dumps(dict(retained_files=len(retained), retained_bytes=sum(len(body) for body in outputs.values()),
        same_volume_verified=True, original_bytes_unchanged=True,
        actual_cases=len(reviewed['join']['cases']), actual_workers=len(reviewed['join']['workers']),
        producer_invoked=False), sort_keys=True))


if __name__ == '__main__':
    retain()
