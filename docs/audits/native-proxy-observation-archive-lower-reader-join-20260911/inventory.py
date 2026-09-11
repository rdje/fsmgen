"""Authenticate bounded committed inputs for the saved lower-reader join."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-lower-reader-join-20260911'
SAFE_PATH = 'docs/audits/native-proxy-observation-archive-close-join-20260911/inventory.py'
_spec = importlib.util.spec_from_file_location('lower_join_safe_reads', ROOT / SAFE_PATH)
SAFE = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(SAFE)
read, historical = SAFE.read, SAFE.historical


def decoded(path):
    return json.loads(read(path)[0])


def digest(raw):
    return dict(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def paths_for(plan):
    paths = set(plan['infrastructure'])
    for matrix in plan['matrices']:
        child = decoded(matrix['source'] + '/plan.json')
        paths.update(pin['path'] for pin in child['inputs'])
        paths.update(matrix['sources'] + matrix['receipts'] + [matrix['pins'],
                     matrix['source'] + '/result/recovery-copies.json'])
    handoff = plan['handoff']
    paths.update(handoff['sources'] + handoff['receipts'] +
                 [handoff['source'] + '/result/recovery-copies.json',
                  'docs/audits/native-proxy-image-custody-20260910/vectors.json'])
    return sorted(paths)


def census(plan):
    paths = paths_for(plan)
    assert len(paths) <= plan['input_limits']['files']
    records = []
    for path in paths:
        raw, identity = read(path, plan['input_limits']['file_bytes'])
        assert raw == historical(plan['source_revision'], path)
        records.append(dict(path=path, **identity))
    assert sum(row['size_bytes'] for row in records) <= plan['input_limits']['total_bytes']
    epochs = []
    for matrix in plan['matrices']:
        child = decoded(matrix['source'] + '/plan.json')
        assert child['source_revision'] == matrix['source_epoch']
        for pin in child['inputs']:
            raw = read(pin['path'])[0]
            assert digest(raw) == {key: pin[key] for key in ('size_bytes', 'sha256')}
            assert raw == historical(matrix['source_epoch'], pin['path'])
            epochs.append(dict(matrix=matrix['name'], source_epoch=matrix['source_epoch'],
                               path=pin['path'], **digest(raw)))
    for matrix in [*plan['matrices'], plan['handoff']]:
        members = set(matrix['sources'] + matrix['receipts'] +
                      [matrix['source'] + '/result/recovery-copies.json'])
        if 'pins' in matrix:
            members.add(matrix['pins'])
            pins = decoded(matrix['pins'])
            assert [pin['path'] for pin in pins] == matrix['sources']
            for pin in pins:
                assert digest(read(pin['path'])[0]) == {key: pin[key] for key in ('size_bytes', 'sha256')}
        for path in sorted(members):
            assert read(path)[0] == historical(matrix['completed_revision'], path)
    return dict(schema='fsmgen.inactive_archive_lower_reader_join_inventory.v1',
                source_revision=plan['source_revision'], inputs=records, applicability=epochs,
                source_files=len(records), total_bytes=sum(row['size_bytes'] for row in records),
                epoch_comparisons=len(epochs))


def authenticate_pins():
    pins = decoded(str((BASE / 'preflight-pins.json').relative_to(ROOT)))
    assert [pin['path'] for pin in pins] == [str((BASE / name).relative_to(ROOT))
                                           for name in ['plan.json', 'inventory.py', 'audit.py']]
    for pin in pins:
        assert digest(read(pin['path'])[0]) == {key: pin[key] for key in ('size_bytes', 'sha256')}
    return pins


if __name__ == '__main__':
    authenticate_pins()
    plan = decoded(str((BASE / 'plan.json').relative_to(ROOT)))
    assert LOG.is_dir() and not LOG.is_symlink() and LOG.stat().st_dev == ROOT.stat().st_dev
    result = census(plan)
    with (LOG / 'source-inventory.json').open('x') as stream:
        stream.write(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps({key: result[key] for key in ['source_files', 'total_bytes', 'epoch_comparisons']}, sort_keys=True))
