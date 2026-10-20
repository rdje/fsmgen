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

REVISION = '912025a6521838b62499c51ce3ad1a7f37d14845'
PARENT = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.4.3.3.2.2.3.3.2.3.3.2.1.3.2.1.2.3.5.3.3.2.3.3.4'
PATH = execute.AUDIT / 'complete-reader-post-operand-20261020.json.gz'
CAPTURE_SHA256 = '4596cf82447fc054718588f3938f6335f25dc50ef82b3ec4242ba371b6adf5d9'
NAMES = ('after.json', 'finished.json', 'listing.json', 'started.json', 'stderr.bin', 'stdout.bin')
NORMALIZER = 'Literal repository root becomes .; raw identities identify original bytes without reconstructing private raw paths.'
SCOPE = ('Dated actual full helper passes operand inventory then stops at ast_model_inputs.py:353 '
         'full saved comparison. Complete native/listing/source/task before/after and normalized '
         'streams retain. No RAM cutoff is reported. Exact differing proof fields and root attribution '
         'remain owned by the next diagnosis. No helper success, original semantic/model/recipe/cohort, '
         'source/data/default/effect/runtime/custody/private/HIAL/full-CI qualification follows.')


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
    equal(value['schema'], 'fsmgen.complete_reader_post_operand.v1')
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
    equal(finished, dict(command=['scripts/run_with_ram_guard.sh', '--', 'bash', collector.HELPER], status=1))
    assert files['stdout.bin'].endswith(b'Complete compile/exec syntax operands, token allocation and saved rejection candidates agree; source/data bindings and runtime remain unqualified.\n')
    assert b'/ast_model_inputs.py", line 353, in <module>' in files['stderr.bin']
    assert files['stderr.bin'].endswith(b'AssertionError: exact scalar\n')
    assert b'ram-guard: host memory' not in files['stderr.bin'] and b'ram-guard: descendant' not in files['stderr.bin']
    return True


def captured(raw):
    assert hashlib.sha256(raw).hexdigest() == CAPTURE_SHA256, 'complete immutable capture identity'
    return json.loads(gzip.decompress(raw))


def controls(value):
    for name in ('missing-file', 'wrong-native-revision', 'changed-native-source', 'float-status', 'boolean-status', 'success-promotion', 'lost-operand-pass', 'changed-error'):
        bad = copy.deepcopy(value)
        if name == 'missing-file':
            del bad['files']['stderr.bin']
        elif name == 'wrong-native-revision':
            bad['revision'] = '0' * 40
        elif name == 'changed-native-source':
            started = decoded(unblob(bad['files']['started.json']['normalized']))
            started['route_sources'][collector.HELPER] = prepare.blob(b'changed native helper\n')
            for key, row in (('started.json', started), ('after.json', dict(value=started, error_type=None, error=None))):
                wire = encoded(row)
                bad['files'][key] = dict(normalized=prepare.blob(wire), raw_identity=prepare.identity(wire))
        elif name in ('float-status', 'boolean-status', 'success-promotion'):
            row = decoded(unblob(bad['files']['finished.json']['normalized']))
            row['status'] = 1.0 if name == 'float-status' else True if name == 'boolean-status' else 0
            wire = encoded(row)
            bad['files']['finished.json'] = dict(normalized=prepare.blob(wire), raw_identity=prepare.identity(wire))
        else:
            key = 'stdout.bin' if name == 'lost-operand-pass' else 'stderr.bin'
            original = unblob(bad['files'][key]['normalized'])
            wire = b''.join(original.splitlines(keepends=True)[:-1]) if name == 'lost-operand-pass' else original.replace(b'AssertionError: exact scalar\n', b'AssertionError: another cause\n')
            assert wire != original
            bad['files'][key] = dict(normalized=prepare.blob(wire), raw_identity=prepare.identity(wire))
        try:
            review(bad)
        except AssertionError as error:
            if name in ('float-status', 'boolean-status'):
                assert str(error) == 'JSON value kind'
        else:
            raise AssertionError('changed complete-helper capture admitted: ' + name)

    altered = copy.deepcopy(value)
    altered['files']['stderr.bin']['raw_identity']['sha256'] = '0' * 64
    try:
        captured(gzip.compress(prepare.encoded(altered), mtime=0))
    except AssertionError as error:
        assert str(error) == 'complete immutable capture identity'
    else:
        raise AssertionError('changed raw stream identifier admitted')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture', help='read the completed original collector directory; never rerun it')
    args = parser.parse_args()
    if args.capture:
        directory = Path(args.capture)
        assert directory.parent == Path('.artifacts/tmp/tests') and directory.name.startswith('complete-reader-sequence-')
        execute.safe(directory / 'started.json')
        equal(sorted(p.name for p in directory.iterdir()), sorted(NAMES))
        files = {}
        for name in NAMES:
            raw = execute.read(directory / name)
            files[name] = dict(normalized=prepare.blob(raw.replace(str(prepare.ROOT).encode(), b'.')),
                               raw_identity=prepare.identity(raw))
        value = dict(schema='fsmgen.complete_reader_post_operand.v1', revision=REVISION,
                     normalizer=NORMALIZER, scope=SCOPE, files=files)
    else:
        value = captured(execute.read(PATH))
    review(value)
    controls(value)
    if args.capture:
        execute.save(PATH, value)
        captured(execute.read(PATH))
    print('Dated native source/task/listing boundary and complete helper refusal retain; genuine record controls reject.')
