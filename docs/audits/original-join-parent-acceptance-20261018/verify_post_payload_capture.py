"""Read the dated complete-helper capture; never launch its saved commands."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import sys

import bounded_runtime_inventory as bounded
import epoch_constraints as epoch
import execute
import frozen_operand_route as frozen
import prepare
import run_complete_reader_sequence as collector

sys.path.insert(0, 'docs/audits/task-terminal-rollover-20261011')
import common

REVISION = '5e824c9c7d4aeff3265839cf0595bc43b8066b6d'
PARENT = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.4.3.3.2.2.3.3.2.3.3.2.1.3.2.1.2.3.5.3.3.2.3.3.4.5.5.5.2.3.6.2.5'
PATH = execute.AUDIT / 'complete-reader-post-payload-20261021.json.gz'
CAPTURE_SHA256 = '454056b5c423dcb2f078f8b89c9435815e96584c0db52a5c32c94012f7bdd70d'
NAMES = ('after.json', 'finished.json', 'listing.json', 'started.json', 'stderr.bin', 'stdout.bin')
NORMALIZER = 'Literal repository root becomes .; raw identities identify original bytes without reconstructing private raw paths.'
SCOPE = 'Dated actual complete helper succeeds through every listed reader and qualifier, including payload closure and the terminal current native route. Complete native/listing/source/task before/after and normalized streams retain. Integer status0 and unchanged RAM limits qualify this ordered reader sequence only. No original semantic/model/recipe/cohort execution or source/data/default/effect/runtime/custody/private/HIAL/full-CI qualification follows; eligible route-container closure is separately owned after capture commit.'


def equal(a, b):
    return bounded.strict_equal(a, b)


def unblob(row):
    raw = prepare.unblob(row)
    equal(row, prepare.blob(raw))
    return raw


def encoded(value):
    return (json.dumps(value, sort_keys=True) + '\n').encode()


def decoded(raw):
    value = json.loads(raw)
    assert encoded(value) == raw, 'whole canonical producer JSON bytes'
    return value


def review(value):
    assert set(value) == {'schema', 'revision', 'normalizer', 'scope', 'files'}
    equal(value['schema'], 'fsmgen.complete_reader_post_payload.v1')
    equal(value['revision'], REVISION)
    equal(value['normalizer'], NORMALIZER)
    equal(value['scope'], SCOPE)
    assert set(value['files']) == set(NAMES), 'complete captured file population'
    files = {}
    for name, row in value['files'].items():
        assert set(row) == {'normalized', 'raw_identity'}
        files[name] = unblob(row['normalized'])
        identity = row['raw_identity']
        assert set(identity) == {'bytes', 'sha256'}
        assert type(identity['bytes']) is int and identity['bytes'] >= len(files[name])
        assert type(identity['sha256']) is str and re.fullmatch('[0-9a-f]{64}', identity['sha256'])
    started, after, finished, listing = (decoded(files[name]) for name in
                                       ('started.json', 'after.json', 'finished.json', 'listing.json'))
    assert set(started) == {'revision', 'native_tree', 'status', 'task', 'programme', 'route_sources'}
    assert set(after) == {'value', 'error_type', 'error'}
    equal(after, dict(value=started, error_type=None, error=None))
    equal(started['revision'], REVISION)
    equal(started['status'], [' M ' + collector.TASK])
    equal(unblob(started['native_tree']), collector.native('ls-tree', '--full-tree', '-r', '-z', REVISION))
    expected_routes = {collector.HELPER, collector.AUDIT + 'live_operand_route.py',
                       collector.AUDIT + 'frozen_operand_route.py', collector.AUDIT + 'rollover_source_card.py'}
    assert type(started['route_sources']) is dict and set(started['route_sources']) == expected_routes
    names = [collector.SELF, collector.TASK, *started['route_sources']]
    native = epoch.batch(REVISION, names)
    equal(unblob(started['programme']), native[collector.SELF])
    for name, row in started['route_sources'].items():
        equal(unblob(row), native[name])
    task = unblob(started['task'])
    old, declared = common.nodes(native[collector.TASK]), common.nodes(task)
    assert set(declared) == set(old) | {PARENT + '.1', PARENT + '.2'}
    assert all(declared[name] == raw for name, raw in old.items() if name != PARENT)
    for field in ('Goal', 'Acceptance', 'Verification', 'Commit'):
        equal(common.field(declared[PARENT], field), common.field(old[PARENT], field))
    equal(common.field(declared[PARENT], 'Status'), 'active')
    equal(common.field(declared[PARENT], 'Children'), PARENT + '.1, ' + PARENT + '.2')
    equal(common.field(declared[PARENT + '.1'], 'Status'), 'active')
    equal(common.field(declared[PARENT + '.2'], 'Status'), 'pending')
    restored = task.replace(declared[PARENT], old[PARENT], 1)
    for name in (PARENT + '.1', PARENT + '.2'):
        restored = restored.replace(declared[name], b'', 1)
    equal(restored, native[collector.TASK])
    assert set(listing) == {'command', 'status', 'stdout', 'stderr', 'commands'}
    equal(listing['command'], ['bash', collector.HELPER, '--list'])
    equal(listing['status'], 0)
    equal(unblob(listing['stderr']), b'')
    commands = frozen.helper_commands(native[collector.HELPER])
    equal(listing['commands'], commands)
    import shlex
    equal([shlex.split(line) for line in unblob(listing['stdout']).decode().splitlines()], commands)
    equal(finished, dict(command=['scripts/run_with_ram_guard.sh', '--', 'bash', collector.HELPER], status=0))
    assert files['stdout.bin'].endswith(b'Current card/archive/query and admitted ordered reader routes qualify; whole sequence remains separately gated.\n')
    assert b'Reconstructed lexical payload boundaries, stdlib-name declarations, namespace/export source contracts and discarded-result input-only exclusions qualify; token/serialized-tree checks and genuine controls agree. Original loader/callable/namespace values and source/default/effect/runtime authority remain open.\n' in files['stdout.bin'], 'actual payload reader pass'
    assert b'Native saved metadata and complete original proof qualify for payload_closure.py; current metadata and disabled assertions refuse.\n' in files['stdout.bin']
    assert re.fullmatch(rb'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', files['stderr.bin']), 'whole successful guard stream and unchanged limits'
    return True


def captured(raw):
    assert hashlib.sha256(raw).hexdigest() == CAPTURE_SHA256, 'complete immutable capture identity'
    return json.loads(gzip.decompress(raw))


def controls(value):
    for name in ('missing-file','wrong-native-revision','changed-native-source','float-status',
                 'boolean-status','failure-substitution','lost-terminal-pass','lost-payload-pass','changed-guard-header'):
        bad = copy.deepcopy(value)
        if name == 'missing-file':
            del bad['files']['stderr.bin']
        elif name == 'wrong-native-revision':
            bad['revision'] = '0' * 40
        elif name == 'changed-native-source':
            started = decoded(unblob(bad['files']['started.json']['normalized']))
            started['route_sources'][collector.HELPER] = prepare.blob(b'changed native helper\n')
            for key, row in (('started.json', started), ('after.json', dict(value=started,error_type=None,error=None))):
                wire = encoded(row)
                bad['files'][key] = dict(normalized=prepare.blob(wire),raw_identity=prepare.identity(wire))
        elif name in ('float-status','boolean-status','failure-substitution'):
            row = decoded(unblob(bad['files']['finished.json']['normalized']))
            row['status'] = 0.0 if name == 'float-status' else False if name == 'boolean-status' else 1
            wire = encoded(row)
            bad['files']['finished.json'] = dict(normalized=prepare.blob(wire),raw_identity=prepare.identity(wire))
        else:
            key = 'stderr.bin' if name == 'changed-guard-header' else 'stdout.bin'
            original = unblob(bad['files'][key]['normalized'])
            if name == 'lost-terminal-pass': wire = b''.join(original.splitlines(keepends=True)[:-1])
            elif name == 'lost-payload-pass':
                wire = b''.join(line for line in original.splitlines(keepends=True)
                                if not line.startswith(b'Reconstructed lexical payload boundaries,'))
            else: wire = original.replace(b'host cutoff 88%',b'host cutoff 89%')
            assert wire != original, 'genuine complete stream control'
            bad['files'][key] = dict(normalized=prepare.blob(wire),raw_identity=prepare.identity(wire))
        try:
            review(bad)
        except AssertionError as error:
            if name in ('float-status','boolean-status'): assert str(error) == 'JSON value kind'
        else:
            raise AssertionError('changed complete-helper success admitted: '+name)
    altered = copy.deepcopy(value)
    altered['files']['stderr.bin']['raw_identity']['sha256'] = '0' * 64
    try:
        captured(gzip.compress(prepare.encoded(altered),mtime=0))
    except AssertionError as error:
        assert str(error) == 'complete immutable capture identity'
    else:
        raise AssertionError('changed raw stream identifier admitted')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()
    value = captured(execute.read(PATH))
    review(value)
    controls(value)
    print('Complete dated ordered helper succeeds through every reader, qualifier and terminal route. Full native/source/tree/listing/task, typed result and stream controls qualify without repeating the helper; original runtime authority remains separate.')
