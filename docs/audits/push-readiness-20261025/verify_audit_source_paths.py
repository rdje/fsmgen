#!/usr/bin/env python3
"""Verify the finite publication source-path repair and relocated readback."""
from pathlib import Path, PurePosixPath
import copy
import gzip
import hashlib
import json
import shutil
import tempfile

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/push-readiness-20261025')
CASES = (
    ('full11-preflight-source-20261102.json.gz', ('instruments', 2),
     '.artifacts/push-readiness-20261025/full11-preflight-docs-20261102.py'),
    ('full11-outcome-source-20261102.json.gz', ('instrument',),
     '.artifacts/push-readiness-20261025/full11-outcome-20261102.py'),
    ('full12-admission-blocker-source-20261102.json.gz', ('instrument',),
     '.artifacts/push-readiness-20261025/full12-admission-blocker-20261102.py'),
    ('full12-outcome-source-20261103.json.gz', ('instrument',),
     '.artifacts/push-readiness-20261025/full12-outcome-20261103.py'),
    ('full12-preflight-source-20261102.json.gz', ('instrument',),
     '.artifacts/push-readiness-20261025/full12-preflight-20261102.py'),
)


def source_record(value, trail):
    for key in trail:
        value = value[key]
    return value


def validate(record, expected):
    value = record['path']
    path = PurePosixPath(value)
    assert value == expected, 'producer path differs from the relative source address'
    assert not path.is_absolute() and '..' not in path.parts
    assert path.as_posix() == value and '\\' not in value
    source = record['text'].encode()
    digest = hashlib.sha256(source).hexdigest()
    if 'sha256' in record:
        assert record['sha256'] == digest, 'original producer source hash changed'
    if 'bytes' in record:
        assert record['bytes'] == len(source), 'original producer size changed'
    return digest


def verify_at(root):
    results = []
    for name, trail, expected in CASES:
        value = json.loads(gzip.decompress((root / BASE / name).read_bytes()))
        record = source_record(value, trail)
        digest = validate(record, expected)
        for bad in ('/outside/producer.py', '<repository>/' + expected,
                    '../' + expected, expected + '.different'):
            altered = copy.deepcopy(record)
            altered['path'] = bad
            try:
                validate(altered, expected)
            except AssertionError:
                pass
            else:
                raise AssertionError('invalid producer address was accepted')
        results.append({'packet': (BASE / name).as_posix(), 'path': expected,
                        'source_sha256': digest})
    return results


def main():
    original = verify_at(ROOT)
    scratch = ROOT / '.artifacts' / 'tmp'
    scratch.mkdir(parents=True, exist_ok=True)
    assert scratch.stat().st_dev == ROOT.stat().st_dev
    with tempfile.TemporaryDirectory(prefix='audit-source-relocation-', dir=scratch) as directory:
        moved = Path(directory)
        (moved / BASE).mkdir(parents=True)
        for name, _, _ in CASES:
            shutil.copyfile(ROOT / BASE / name, moved / BASE / name)
        assert verify_at(moved) == original, 'relocated packet readback changed'
    print(json.dumps({'status': 'audit-source-paths: OK', 'packets': original,
                      'relocated_readback_equal': True, 'negative_controls_rejected': True}))


if __name__ == '__main__':
    main()
