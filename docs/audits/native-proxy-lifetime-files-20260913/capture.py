"""Retain the first actual lifetime journal before independent classification."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-lifetime-files-20260913'
ADMISSION = ROOT / 'docs/audits/native-proxy-lifetime-files-admission-20260913'
DEVICE = ROOT.stat().st_dev
UID = os.getuid()


def read(path, limit):
    relative = path.relative_to(ROOT); current = ROOT
    for component in relative.parts[:-1]:
        current /= component; metadata = os.lstat(current)
        assert stat.S_ISDIR(metadata.st_mode) and metadata.st_dev == DEVICE and metadata.st_uid == UID
    named = os.lstat(path)
    assert stat.S_ISREG(named.st_mode) and named.st_dev == DEVICE and named.st_uid == UID
    assert named.st_nlink == 1 and named.st_size <= limit
    descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        opened = os.fstat(descriptor)
        assert opened.st_dev == named.st_dev and opened.st_ino == named.st_ino
        pieces, total = [], 0
        while True:
            piece = os.read(descriptor, min(65536, limit + 1 - total))
            if not piece: break
            pieces.append(piece); total += len(piece); assert total <= limit
        after = os.fstat(descriptor); current = os.lstat(path)
        fields = ('st_dev', 'st_ino', 'st_mode', 'st_uid', 'st_nlink', 'st_size', 'st_mtime_ns', 'st_ctime_ns')
        assert all(getattr(named, field) == getattr(opened, field) == getattr(after, field) == getattr(current, field)
                   for field in fields)
        raw = b''.join(pieces); assert len(raw) == named.st_size
        return raw
    finally:
        os.close(descriptor)


def pin(path, body):
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest())


def copy(source, destination, limit):
    raw = read(source, limit)
    with destination.open('xb') as handle: handle.write(raw)
    assert read(destination, limit) == raw
    return dict(source=pin(source, raw), retained=pin(destination, raw))


def main():
    assert UID > 0 and UID == os.geteuid()
    plan = json.loads(read(BASE / 'capture-plan.json', 65536))
    for row in plan['sources']:
        assert pin(ROOT / row['path'], read(ROOT / row['path'], row['size_bytes'])) == row
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip()
    assert revision == plan['admission_commit']
    permit_bytes = read(LOG / 'execution-admission.json', 65536); permit = json.loads(permit_bytes)
    assert permit['admission_commit'] == revision and permit['execution_owner'] == plan['owner']
    task = ROOT / 'docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md'
    task_bytes = read(task, 2 * 1024 * 1024)
    assert hashlib.sha256(task_bytes).hexdigest() == permit['task_sha256']
    selection = json.loads(read(ADMISSION / 'selection.json', 65536))
    record_directory = LOG / 'records'
    expected_limit = plan['maximum_journal_records']
    names = sorted(os.listdir(record_directory))
    assert names == ['event-%06d.json' % index for index in range(len(names))]
    assert len(names) <= expected_limit
    target = BASE / 'records'; target.mkdir()
    copies, total = [], 0
    for name in names:
        row = copy(record_directory / name, target / name, selection['bounds']['record_bytes'])
        total += row['source']['size_bytes']; assert total <= selection['bounds']['total_record_bytes']
        copies.append(row)
    assert sorted(os.listdir(record_directory)) == names
    output = BASE / 'first-output'; output.mkdir()
    outputs = [copy(LOG / ('first-run.' + suffix), output / ('first-run.' + suffix), 4 * 1024 * 1024)
               for suffix in ('stdout', 'stderr', 'exit')]
    permit_copy = copy(LOG / 'execution-admission.json', BASE / 'execution-admission.json', 65536)
    task_copy = copy(task, BASE / 'task-at-execution.md.source', 2 * 1024 * 1024)
    permit_log = ROOT / '.artifacts/logs/native-proxy-lifetime-files-admission-20260913'
    outputs.extend(copy(permit_log / ('execution-permit.' + suffix), output / ('execution-permit.' + suffix), 4 * 1024 * 1024)
                   for suffix in ('stdout', 'stderr', 'exit'))
    value = dict(schema='fsmgen.inactive_lifetime_first_execution_capture.v1', owner=plan['owner'],
        admission_commit=revision, records=copies, record_count=len(copies), record_bytes=total,
        first_outputs=outputs, execution_admission=permit_copy, task_at_execution=task_copy,
        first_exit=int(read(output / 'first-run.exit', 64)), independently_qualified=False,
        original_outputs_deleted=False, fixture_operations_performed_by_capture=False)
    with (BASE / 'capture.json').open('xb') as handle:
        handle.write(json.dumps(value, sort_keys=True, indent=2).encode() + b'\n')
    print('first lifetime evidence retained: records=%d bytes=%d exit=%d; independent qualification pending' %
          (value['record_count'], total, value['first_exit']))


if __name__ == '__main__':
    main()
