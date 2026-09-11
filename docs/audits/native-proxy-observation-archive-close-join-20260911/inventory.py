"""Inventory exact committed sources and retained evidence without fixture replay."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-close-join-20260911'
RAW_NAMES = ['plan.stdout', 'plan.stderr', 'plan.exit', 'syntax.stdout', 'syntax.stderr', 'syntax.exit',
             'preflight-pins.json', 'qualification.json', 'admission.jsonl', 'qualify.tap', 'qualify.stderr',
             'qualify.exit', 'audit.json', 'audit.stdout', 'audit.stderr', 'audit.exit']


def read(path, limit=33554432):
    assert isinstance(path, str) and path and not path.startswith('/')
    assert all(part not in ('', '.', '..') for part in path.split('/'))
    current = ROOT
    for part in path.split('/')[:-1]:
        current = current / part
        native = current.lstat()
        assert stat.S_ISDIR(native.st_mode) and native.st_dev == ROOT.stat().st_dev
    target = ROOT / path
    named = target.lstat()
    assert stat.S_ISREG(named.st_mode) and named.st_dev == ROOT.stat().st_dev
    assert 0 <= named.st_size <= limit
    descriptor = os.open(target, os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC)
    try:
        before = os.fstat(descriptor)
        seal = lambda value: (value.st_dev, value.st_ino, value.st_mode, value.st_nlink,
                              value.st_uid, value.st_gid, value.st_size, value.st_mtime_ns, value.st_ctime_ns)
        assert seal(before) == seal(named)
        with os.fdopen(descriptor, 'rb', closefd=False) as stream:
            raw = stream.read(limit + 1)
        assert len(raw) == before.st_size <= limit
        assert seal(os.fstat(descriptor)) == seal(before) == seal(target.lstat())
    finally:
        os.close(descriptor)
    return raw, dict(device=before.st_dev, inode=before.st_ino, mode=stat.S_IMODE(before.st_mode),
                     links=before.st_nlink, uid=before.st_uid, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def historical(revision, path):
    assert re.fullmatch(r'[0-9a-f]{40}', revision)
    return subprocess.check_output(['git', 'show', revision + ':' + path], cwd=ROOT)


def catalogue(plan):
    paths = set()
    for matrix in plan['matrices']:
        base = matrix['source']
        child = json.loads(read(base + '/plan.json')[0])
        paths.update(pin['path'] for pin in child['inputs'])
        paths.update(base + '/' + name for name in ['plan.py', 'plan.json', matrix['adapter'], 'qualify.t', 'audit.py', 'preflight-pins.json'])
        paths.update(base + '/result/' + name for name in RAW_NAMES + ['recovery-copies.json'])
    assert len(paths) <= plan['input_limits']['files']
    records = []
    for path in sorted(paths):
        raw, identity = read(path, plan['input_limits']['file_bytes'])
        assert raw == historical(plan['source_revision'], path)
        records.append(dict(path=path, **identity))
    assert sum(row['size_bytes'] for row in records) <= plan['input_limits']['total_bytes']
    return records


def applicability(plan, records):
    inventory = {row['path']: row for row in records}
    rows = []
    for matrix in plan['matrices']:
        base = matrix['source']; child = json.loads(read(base + '/plan.json')[0])
        assert child['source_revision'] == matrix['source_epoch']
        for pin in child['inputs']:
            current = inventory[pin['path']]
            assert all(current[key] == pin[key] for key in ('size_bytes', 'sha256'))
            raw = read(pin['path'])[0]
            assert raw == historical(matrix['source_epoch'], pin['path'])
            rows.append(dict(matrix=matrix['name'], source_epoch=matrix['source_epoch'], path=pin['path'],
                             size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest(), status='exact'))
        for path in [row['path'] for row in records if row['path'].startswith(base + '/')]:
            assert read(path)[0] == historical(matrix['completed_revision'], path)
    return rows


def main():
    plan = json.loads((BASE / 'plan.json').read_bytes())
    pins = json.loads((BASE / 'preflight-pins.json').read_bytes())
    for pin in pins:
        raw = read(pin['path'])[0]
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    assert LOG.is_dir() and not LOG.is_symlink() and LOG.stat().st_dev == ROOT.stat().st_dev
    assert not (LOG / 'source-inventory.json').exists(), 'preserve the first inventory'
    records = catalogue(plan)
    epoch_rows = applicability(plan, records)
    result = dict(schema='fsmgen.inactive_archive_close_join_inventory.v1', source_revision=plan['source_revision'],
        inputs=records, applicability=epoch_rows, total_bytes=sum(row['size_bytes'] for row in records),
        source_files=len(records), epoch_comparisons=len(epoch_rows))
    (LOG / 'source-inventory.json').write_text(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps({key: result[key] for key in ('source_files', 'total_bytes', 'epoch_comparisons')}, sort_keys=True))


if __name__ == '__main__':
    main()
