"""Read the dated dependent-qualifier capture without launching its command."""
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
import prepare
import run_allocation_qualifier as producer

sys.path.insert(0, 'docs/audits/task-terminal-rollover-20261011')
import common

BASE = '1576146bbd4da6f63b47c85022714d8775acb8eb'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.4.3.3.2.2.3.3.2.3.3.2.1.3.2.1.2.3.5.3.3.2.3.3.4.5.5.5.2.3.2.2'
PATH = execute.AUDIT / 'allocation-data-qualifier-first-result-20261021.json.gz'
CAPTURE_SHA256 = '5970e6aac7c3e53161b0f5460b37315ddae5c2f395980ab861b69478038a3c13'
NAMES = ('after.json', 'finished.json', 'started.json', 'stderr.bin', 'stdout.bin')
NORMALIZER = 'Literal repository root becomes .; raw identities identify original bytes without reconstructing private raw paths.'
SCOPE = ('Dated actual unchanged dependent qualifier reaches its final saved-product '
         'comparison at qualify_operand_allocation.py:72 and returns status1. '
         'Complete native source/tree/index/proof/task before/after and normalized '
         'streams retain; no RAM cutoff is reported. Exact differing fields and '
         'cause remain owned by the next diagnosis. No whole helper success or '
         'original semantic/model/recipe/cohort/source-role/native/runtime/private/'
         'HIAL/full-CI qualification follows. Current decoder/Git/byte semantics '
         'remain shared premises; historical bodies stay data.')


def equal(left, right):
    return bounded.strict_equal(left, right)


def unblob(row):
    raw = prepare.unblob(row)
    equal(row, prepare.blob(raw))
    return raw


def encoded(value):
    return (json.dumps(value, sort_keys=True) + '\n').encode()


def decoded(raw):
    value = json.loads(raw)
    equal(encoded(value), raw)
    return value


def native_index(tree):
    rows = {}
    assert tree.endswith(b'\0')
    for row in tree[:-1].split(b'\0'):
        header, name = row.split(b'\t', 1)
        mode, kind, oid = header.split()
        assert kind in (b'blob', b'commit') and name not in rows
        rows[name] = mode + b' ' + oid + b' 0\t' + name + b'\0'
    return b''.join(rows[name] for name in sorted(rows))


def review(value):
    assert set(value) == {'schema', 'revision', 'normalizer', 'scope', 'files'}
    equal(value['schema'], 'fsmgen.allocation_data_qualifier_first_result.v1')
    equal(value['revision'], BASE)
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
    started, after, finished = (decoded(files[name]) for name in ('started.json', 'after.json', 'finished.json'))
    assert set(started) == {'revision', 'native_tree', 'native_index', 'status', 'task', 'programme', 'cwd', 'premises'}
    equal(after, dict(value=started, error_type=None, error=None))
    equal(started['revision'], BASE)
    equal(started['status'], [' M ' + producer.TASK])
    equal(started['cwd'], '.')
    tree = epoch.read(BASE, producer.SELF)
    equal(execute.read(producer.SELF), tree)
    equal(unblob(started['programme']), tree)
    native_tree = producer.collector.native('ls-tree', '--full-tree', '-r', '-z', BASE)
    equal(unblob(started['native_tree']), native_tree)
    equal(unblob(started['native_index']), native_index(native_tree))
    prepared = json.loads(gzip.decompress(epoch.read(BASE, producer.PREPARED)))
    assert producer.review_prepared(prepared)
    equal(started['premises'], prepared['premises'])
    task = unblob(started['task'])
    original = epoch.read(BASE, producer.TASK)
    old, declared = common.nodes(original), common.nodes(task)
    assert set(old) == set(declared)
    equal(common.field(old[OWNER], 'Status'), 'pending')
    active = old[OWNER].replace(b'  Status: `pending`', b'  Status: `active`', 1)
    equal(declared[OWNER], active)
    equal(task, original.replace(old[OWNER], active, 1))
    equal(finished, dict(command=producer.command(), status=1))
    equal(files['stdout.bin'], b'')
    stderr = files['stderr.bin']
    assert re.match(rb'ram-guard: PID [1-9][0-9]*; host [0-9]+\.[0-9]%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', stderr)
    assert b'/qualify_operand_allocation.py", line 72, in <module>' in stderr
    assert stderr.endswith(b'AssertionError: exact scalar\n')
    assert b'ram-guard: host memory' not in stderr and b'ram-guard: descendant PID' not in stderr
    assert b'ram-guard: terminating PID tree:' not in stderr
    return True


def captured(raw):
    assert hashlib.sha256(raw).hexdigest() == CAPTURE_SHA256, 'complete immutable capture identity'
    return json.loads(gzip.decompress(raw))


def rewrite_file(value, name, raw):
    value['files'][name] = dict(normalized=prepare.blob(raw), raw_identity=prepare.identity(raw))


def controls(value):
    for label in ('missing-file', 'wrong-native', 'changed-producer', 'changed-source',
                  'omitted-proof', 'changed-proof', 'missing-index-entry', 'wrong-cwd',
                  'float-status', 'boolean-status', 'success-promotion', 'changed-command',
                  'injected-stdout', 'changed-error', 'changed-guard-limit'):
        bad = copy.deepcopy(value)
        if label == 'missing-file':
            del bad['files']['stderr.bin']
        elif label == 'wrong-native':
            bad['revision'] = '0' * 40
        elif label in ('float-status', 'boolean-status', 'success-promotion', 'changed-command'):
            row = decoded(unblob(bad['files']['finished.json']['normalized']))
            if label == 'changed-command':
                row['command'][-1] = producer.AUDIT + 'execute.py'
            else:
                row['status'] = 1.0 if label == 'float-status' else True if label == 'boolean-status' else 0
            rewrite_file(bad, 'finished.json', encoded(row))
        elif label in ('injected-stdout', 'changed-error', 'changed-guard-limit'):
            if label == 'injected-stdout':
                name, raw = 'stdout.bin', b'promoted success\n'
            else:
                name = 'stderr.bin'
                original = unblob(bad['files'][name]['normalized'])
                raw = original.replace(b'AssertionError: exact scalar\n', b'AssertionError: another cause\n') if label == 'changed-error' else original.replace(b'host cutoff 88%', b'host cutoff 99%')
                assert raw != original
            rewrite_file(bad, name, raw)
        else:
            row = decoded(unblob(bad['files']['started.json']['normalized']))
            if label == 'changed-producer':
                row['programme'] = prepare.blob(b'changed producer\n')
            elif label == 'changed-source':
                row['premises']['sources'][producer.TARGET]['body'] = prepare.blob(b'changed source\n')
            elif label == 'omitted-proof':
                del row['premises']['proofs'][producer.PROOFS[0]]
            elif label == 'changed-proof':
                row['premises']['proofs'][producer.PROOFS[0]]['reference']['oid'] = '0' * 40
            elif label == 'wrong-cwd':
                row['cwd'] = 'another-root'
            else:
                index = unblob(row['native_index'])
                row['native_index'] = prepare.blob(b'\0'.join(index.split(b'\0')[1:]))
            rewrite_file(bad, 'started.json', encoded(row))
            rewrite_file(bad, 'after.json', encoded(dict(value=row, error_type=None, error=None)))
        try:
            review(bad)
        except AssertionError as error:
            if label in ('float-status', 'boolean-status'):
                assert str(error) == 'JSON value kind'
        else:
            raise AssertionError('changed complete qualifier capture admitted: ' + label)
    bad = copy.deepcopy(value)
    bad['files']['stderr.bin']['raw_identity']['sha256'] = '0' * 64
    try:
        captured(gzip.compress(prepare.encoded(bad), mtime=0))
    except AssertionError as error:
        assert str(error) == 'complete immutable capture identity'
    else:
        raise AssertionError('changed raw stream identity admitted')


def collect(directory):
    assert directory.parent == Path('.artifacts/tmp/tests') and directory.name.startswith('allocation-qualifier-')
    execute.safe(directory / 'started.json')
    equal(sorted(path.name for path in directory.iterdir()), sorted(NAMES))
    files = {}
    for name in NAMES:
        raw = execute.read(directory / name)
        files[name] = dict(normalized=prepare.blob(raw.replace(str(prepare.ROOT).encode(), b'.')),
                           raw_identity=prepare.identity(raw))
    return dict(schema='fsmgen.allocation_data_qualifier_first_result.v1', revision=BASE,
                normalizer=NORMALIZER, scope=SCOPE, files=files)


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture', help='read the completed original directory; never rerun its target')
    args = parser.parse_args()
    if args.capture:
        value = collect(Path(args.capture))
        # Preserve the entire first actual observation before reader/control review.
        execute.save(PATH, value)
        captured(execute.read(PATH))
    else:
        value = captured(execute.read(PATH))
    assert review(value)
    controls(value)
    print('Dated native source/tree/index/proof/task and full qualifier refusal retain; genuine complete-record controls reject without rerunning the target.')
