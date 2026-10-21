"""Qualify collector preparation with actual Git-only entrypoints and changed records."""
import argparse
import contextlib
import copy
import gzip
import io
import json
import runpy
import subprocess
import sys

import run_allocation_qualifier as producer

SELF = producer.AUDIT + 'qualify_allocation_collector.py'
PATH = producer.AUDIT + 'allocation-collector-preflight-controls.json.gz'
LINES = {
    '--prepare': 'Native source/proof and fixed collector preparation qualify; the dependent qualifier has not run.\n',
    '--check-prepared': 'Saved native collector preparation qualifies; no target or historical programme executes.\n',
}
SCOPE = ('Actual collector preparation and saved-preparation entrypoints only. '
         'Subprocess permission is restricted to read-only native Git throughout; '
         'the dependent qualifier and every historical programme remain unexecuted. '
         'Complete native source/proof premises and genuine member/source/type/'
         'command candidates qualify. No actual target outcome, runtime boundary '
         'or source-role permission follows.')


def actual(mode):
    previous, previous_argv = subprocess.run, sys.argv
    calls, stdout, stderr = [], io.StringIO(), io.StringIO()

    def git_only(argv, *args, **kwargs):
        assert type(argv) is list and argv[0] == 'git', 'preparation cannot launch a target'
        assert any(word in ('ls-tree', 'show', 'cat-file') for word in argv[1:]), 'read-only native Git only'
        calls.append(list(argv))
        return previous(argv, *args, **kwargs)

    try:
        subprocess.run = git_only
        sys.argv = [producer.SELF, mode]
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            runpy.run_path(producer.SELF, run_name='__main__')
    finally:
        subprocess.run, sys.argv = previous, previous_argv
    return dict(entrypoint_argv=[producer.SELF, mode], completed=True,
                invocation='in-process runpy.run_path with sys.argv and a read-only Git subprocess allowlist',
                stdout=stdout.getvalue(), stderr=stderr.getvalue(), native_calls=calls)


def controls(value):
    outcomes = []
    proof = producer.PROOFS[0]
    cases = (
        ('changed-target-command', ('command', -1), producer.AUDIT + 'execute.py'),
        ('changed-native', ('primary',), '0' * 40),
        ('omitted-proof', ('premises', 'proofs', proof), None),
        ('changed-source', ('premises', 'sources', producer.TARGET, 'body'), producer.prepare.blob(b'changed source\n')),
        ('changed-collector', ('programme',), producer.prepare.blob(b'changed collector\n')),
        ('boolean-proof-size', ('premises', 'proofs', proof, 'identity', 'bytes'), True),
        ('float-proof-size', ('premises', 'proofs', proof, 'identity', 'bytes'), float(value['premises']['proofs'][proof]['identity']['bytes'])),
    )
    for label, path, replacement in cases:
        bad = copy.deepcopy(value)
        parent = bad
        for name in path[:-1]:
            parent = parent[name]
        if label == 'omitted-proof':
            del parent[path[-1]]
        else:
            parent[path[-1]] = replacement
        try:
            producer.review_prepared(bad)
        except AssertionError as error:
            if label in ('boolean-proof-size', 'float-proof-size'):
                assert str(error) == 'JSON value kind'
            outcomes.append(dict(label=label, candidate=bad, refusal=str(error)))
        else:
            raise AssertionError('changed collector preparation admitted: ' + label)
    return outcomes


def review_actual(rows):
    assert type(rows) is list and len(rows) == len(LINES)
    for row, mode in zip(rows, LINES):
        assert set(row) == {'entrypoint_argv', 'completed', 'invocation', 'stdout', 'stderr', 'native_calls'}
        producer.equal(row['entrypoint_argv'], [producer.SELF, mode])
        producer.equal(row['completed'], True)
        producer.equal(row['invocation'], 'in-process runpy.run_path with sys.argv and a read-only Git subprocess allowlist')
        producer.equal(row['stdout'], LINES[mode])
        producer.equal(row['stderr'], '')
        assert row['native_calls'], 'actual native receipts retained'
        for argv in row['native_calls']:
            assert type(argv) is list and argv[0] == 'git'
            assert any(word in ('ls-tree', 'show', 'cat-file') for word in argv[1:])


def fixed():
    raw = producer.execute.read(producer.PREPARED)
    value = json.loads(gzip.decompress(raw))
    assert producer.review_prepared(value)
    return dict(schema='fsmgen.allocation_collector_preflight_controls.v1', scope=SCOPE,
        input=producer.prepare.blob(raw), controls=controls(value),
        programmes={name: producer.prepare.blob(producer.execute.read(name))
                    for name in (SELF, producer.SELF)})


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    if args.write:
        rows = [actual(mode) for mode in LINES]
        review_actual(rows)
        value = dict(fixed(), actual=rows)
        producer.execute.save(PATH, value)
    else:
        value = json.loads(gzip.decompress(producer.execute.read(PATH)))
        assert set(value) == set(fixed()) | {'actual'}
        producer.equal({key: row for key, row in value.items() if key != 'actual'}, fixed())
        review_actual(value['actual'])
    print('Actual preparation/replay entrypoints use only read-only native Git; genuine source/proof/command/member/type candidates refuse. No dependent qualifier runs.')
