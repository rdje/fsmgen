"""Retain a real fresh-index witness and qualify portable index observations."""
import argparse
import copy
import gzip
import json
import os
from pathlib import Path
import subprocess
import tempfile

import execute
import prepare
import selected_checkout as checkout

PATH = execute.AUDIT / 'selected-index-portability-inputs.json.gz'


def fresh_witness():
    expected = json.loads(gzip.decompress(execute.read(checkout.RESULT)))
    original_source = execute.read(execute.AUDIT / 'selected_checkout.py')
    with tempfile.TemporaryDirectory(prefix='selected-fresh-index-', dir=execute.ROOT / '.artifacts/tmp') as folder:
        path = Path(folder) / 'index'
        environment = dict(os.environ, GIT_INDEX_FILE=str(path))
        commands = [
            ['git', '--no-replace-objects', '-C', str(checkout.FOLDER), 'read-tree', checkout.constraints.REVISION],
            ['git', '--no-replace-objects', '-C', str(checkout.FOLDER), 'ls-files', '--stage', '-z'],
        ]
        native = []
        for command in commands:
            row = subprocess.run(command, cwd=execute.ROOT, env=environment, capture_output=True)
            native.append(dict(command=command, status=row.returncode,
                               stdout=prepare.blob(row.stdout), stderr=prepare.blob(row.stderr)))
            assert type(row.returncode) is int and row.returncode == 0 and not row.stderr
        raw = path.read_bytes()
    assert prepare.unblob(native[-1]['stdout']) == prepare.unblob(expected['git']['entries'])
    assert raw != prepare.unblob(expected['git']['index'])
    candidate = copy.deepcopy(expected)
    candidate['git']['index'] = prepare.blob(raw)
    assert candidate != expected, 'the original complete prepared-state equality rejects a fresh equivalent index'
    return dict(schema='fsmgen.selected_index_portability_witness.v1',
                original_programme=prepare.blob(original_source),
                prepared=prepare.identity(execute.read(checkout.RESULT)), native=native,
                fresh_index=prepare.blob(raw), logical_entries=expected['git']['entries'],
                original_complete_equality=False,
                scope='A real same-project alternate Git index reconstructed from the selected tree has '
                      'identical complete stage entries and different raw cache bytes. The original whole '
                      'prepared-state equality rejects this inert equivalent observation. No selected or '
                      'primary index is mutated, no new checkout or semantic reader runs, and the original '
                      'native0 qualification remains valid only for its dated local index observation.')


def verify():
    witness = json.loads(gzip.decompress(execute.read(PATH)))
    expected = json.loads(gzip.decompress(execute.read(checkout.RESULT)))
    assert witness['prepared'] == prepare.identity(execute.read(checkout.RESULT))
    assert all(type(row['status']) is int and row['status'] == 0
               and prepare.unblob(row['stderr']) == b'' for row in witness['native'])
    assert witness['logical_entries'] == expected['git']['entries']
    assert prepare.unblob(witness['native'][-1]['stdout']) == prepare.unblob(witness['logical_entries'])
    candidate = copy.deepcopy(expected)
    candidate['git']['index'] = witness['fresh_index']
    assert candidate != expected and witness['original_complete_equality'] is False
    assert checkout.matches_prepared(candidate, expected)
    assert checkout.matches_prepared(checkout.verify(), expected)
    for label in ('malformed_index', 'wrong_entries', 'source_mode', 'runtime_file'):
        bad = copy.deepcopy(candidate)
        if label == 'malformed_index':
            bad['git']['index'] = prepare.blob(b'not a Git index')
        elif label == 'wrong_entries':
            bad['git']['entries'] = prepare.blob(b'wrong complete index entries')
        elif label == 'source_mode':
            first = next(iter(bad['members']))
            bad['members'][first]['mode'] = 'wrong'
        else:
            bad['runtime_files'] = ['.artifacts/tmp/undeclared']
        try:
            checkout.matches_prepared(bad, expected)
        except AssertionError:
            continue
        raise AssertionError('invalid portable source/index observation admitted: ' + label)
    return True


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture', action='store_true')
    args = parser.parse_args()
    if args.capture:
        execute.save(PATH, fresh_witness())
        print('Real fresh Git index preserves every logical entry while the original raw-index equality refuses; original local qualification retains.')
    else:
        assert verify()
        print('Portable selected index observations pass public Git validation; malformed index, wrong entries, source and runtime controls refuse.')
