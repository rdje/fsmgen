"""Retain the static census guard refusal without treating it as a complete census."""
import argparse
import copy
import gzip
import json
import re

import execute
import prepare
import qualify_runtime_inventory as qualifier
import runtime_inventory

PATH = execute.AUDIT / 'runtime-inventory-resource-controls.json.gz'


def failed(row, started):
    assert all(row[key] == value for key, value in started.items())
    assert set(started) == {'command', 'sources', 'tools', 'primary', 'scope'}
    assert set(row) == set(started) | {'status', 'stdout', 'stderr', 'sources_after', 'tools_after', 'primary_after'}
    assert row['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
                              str(execute.AUDIT / 'runtime_inventory.py'), '--write']
    assert type(row['status']) is int and row['status'] == 137
    assert prepare.unblob(row['stdout']) == b''
    stderr = prepare.unblob(row['stderr'])
    assert re.match(rb'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', stderr)
    assert re.search(rb'RSS [0-9.]+ MiB reached cutoff 4096 MiB:', stderr)
    assert b'ram-guard: terminating PID tree:' in stderr
    assert set(row['sources']) == set(qualifier.NAMES)
    for name, blob in row['sources'].items():
        assert prepare.unblob(blob)
    assert row['sources_after'] == dict(value=row['sources'], error=None)
    assert row['tools_after'] == dict(value=row['tools'], error=None)
    assert row['primary_after']['error'] is None
    assert all(row['primary_after']['value'][key] == row['primary'][key] for key in ('head', 'entries'))
    for state in (row['primary'], row['primary_after']['value']):
        assert set(state) == {'head', 'entries', 'index'}
        assert re.fullmatch('[0-9a-f]{40}', state['head'])
        prepare.unblob(state['entries'])
        prepare.unblob(state['index'])
    return True


def controls(row, started):
    outcomes = []
    for label in ('promotion', 'status_kind', 'guard_limit', 'missing_source', 'source_gap', 'tool_drift', 'index_drift', 'stdout'):
        bad = copy.deepcopy(row)
        if label == 'promotion': bad['status'] = 0
        elif label == 'status_kind': bad['status'] = 137.0
        elif label == 'guard_limit': bad['stderr'] = prepare.blob(prepare.unblob(bad['stderr']).replace(b'4096 MiB', b'8192 MiB'))
        elif label == 'missing_source': del bad['sources']['runtime_inventory.py']
        elif label == 'source_gap': bad['sources_after']['error'] = 'missing after observation'
        elif label == 'tool_drift': bad['tools_after']['value']['git']['sha256'] = '0' * 64
        elif label == 'index_drift': bad['primary_after']['value']['entries'] = prepare.blob(b'wrong entries')
        else: bad['stdout'] = prepare.blob(b'borrowed completed inventory')
        try:
            failed(bad, started)
        except (AssertionError, KeyError, ValueError):
            outcomes.append(label)
        else:
            raise AssertionError('invalid resource-failure custody admitted: ' + label)
    return outcomes


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    row = json.loads(gzip.decompress(execute.read(execute.AUDIT / 'runtime-inventory-first-actual.json.gz')))
    started = json.loads(gzip.decompress(execute.read(execute.AUDIT / 'runtime-inventory-first-started.json.gz')))
    assert failed(row, started)
    outcomes = controls(row, started)
    # No completed population is inferred from the failed producer. The fixed
    # Git code-projection size is a separate input census, never an allocation claim.
    raw_tree, members = runtime_inventory.epoch.tree(runtime_inventory.epoch.REVISION)
    names = runtime_inventory.code_members(members)
    assert not execute.safe(runtime_inventory.PATH).exists()
    assert not execute.safe(runtime_inventory.CONTROLS).exists()
    if args.write:
        execute.save(PATH, dict(inputs={name: prepare.identity(execute.read(execute.AUDIT / name))
                                      for name in ('runtime-inventory-first-started.json.gz', 'runtime-inventory-first-actual.json.gz')},
                                programme=prepare.blob(execute.read(execute.AUDIT / 'verify_runtime_inventory_failed.py')),
                                outcomes=outcomes, tree=prepare.blob(raw_tree), code_members=names,
                                code_bytes=sum(members[name]['bytes'] for name in names),
                                inventory_complete=False, allocation_phase=None,
                                scope='Exact failed native/resource/source/tool/index custody and fixed input size only. '
                                      'Whole-corpus retention/copy/serialization is an unqualified allocation hypothesis; '
                                      'phase attribution and complete bounded production remain owned gaps.'))
    print('Static inventory native137 and unchanged guard/source/tool/index custody qualify as failure; no completed inventory or allocation cause is inferred.')
