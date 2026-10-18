"""Verify committed complete-census recovery without rerunning semantic cohorts."""
import argparse
import copy
import gzip
import json

import execute
import prepare
import qualify_bounded_inventory as qualifier
import verify_inventory_memory as memory

REVISION = '1fe2cbc655dfafdb60b206fd0b142ec6af6563f6'
PATH = execute.AUDIT / 'runtime-inventory-delivery-qualified.json.gz'


def validate(row, started):
    memory.custody(row, started, qualifier.NAMES)
    memory.positive(row)
    assert row['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
                              str(execute.AUDIT / 'bounded_runtime_inventory.py')]
    assert row['primary']['head'] == REVISION
    for name, blob in row['sources'].items():
        assert prepare.unblob(blob) == memory.bounded.original.epoch.read(REVISION, str(execute.AUDIT / name))
    tree = execute.command(['git', '--no-replace-objects', 'ls-tree', '-r', '-z', REVISION])
    entries = []
    for entry in tree.split(b'\0'):
        if entry:
            header, name = entry.split(b'\t', 1)
            mode, kind, oid = header.split()
            assert kind == b'blob'
            entries.append(mode + b' ' + oid + b' 0\t' + name + b'\0')
    assert prepare.unblob(row['primary']['entries']) == b''.join(entries)
    return True


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    row = memory.load('runtime-inventory-bounded-recovery-actual.json.gz')
    started = memory.load('runtime-inventory-bounded-recovery-started.json.gz')
    assert validate(row, started)
    outcomes = []
    for label in ('status', 'kind', 'epoch', 'command', 'source', 'index', 'after', 'stdout'):
        bad, before = copy.deepcopy(row), copy.deepcopy(started)
        if label == 'status': bad['status'] = 137
        elif label == 'kind': bad['status'] = False
        elif label == 'epoch': bad['primary']['head'] = '0' * 40
        elif label == 'command': bad['command'].append('--write')
        elif label == 'source': bad['sources']['bounded_runtime_inventory.py'] = prepare.blob(b'borrowed source')
        elif label == 'index': bad['primary']['entries'] = prepare.blob(b'borrowed entries')
        elif label == 'after': bad['primary_after']['error'] = 'lost after observation'
        else: bad['stdout'] = prepare.blob(b'borrowed success')
        try:
            validate(bad, before)
        except AssertionError:
            outcomes.append(label)
        else:
            raise AssertionError('invalid committed census recovery admitted: ' + label)
    if args.write:
        inputs = ('runtime-inventory-bounded-recovery-actual.json.gz', 'runtime-inventory-bounded-recovery-started.json.gz',
                  'runtime-source-inventory-bounded.json.gz', 'runtime-source-inventory-bounded-controls.json.gz')
        execute.save(PATH, dict(inputs={name: prepare.identity(execute.read(execute.AUDIT / name)) for name in inputs},
                                programme=prepare.blob(execute.read(execute.AUDIT / 'verify_inventory_delivery.py')),
                                outcomes=outcomes, revision=REVISION,
                                scope='Actual committed-source native recovery reconstructs all fixed-source/site/role fields and '
                                      'original independent AST coverage and strict controls. Saved custody/epoch/index controls only. '
                                      'Expanded dynamic code and runtime execution/data roles remain unresolved; no semantic cohort, '
                                      'new checkout, cache producer or runtime permission is inferred.'))
    print('Committed complete static-inventory recovery and genuine native/source/index controls pass; runtime roles remain open.')
