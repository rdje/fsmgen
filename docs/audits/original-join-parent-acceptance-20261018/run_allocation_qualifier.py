"""Prepare and retain one fixed dependent qualifier, including partial records."""
import argparse
import gzip
import json
import os
from pathlib import Path
import subprocess
import tempfile

import bounded_runtime_inventory as bounded
import execute
import prepare
import prerequisite_inputs as prerequisite
import run_complete_reader_sequence as collector
import saved_reader_sources as source

ROOT, AUDIT, TASK = collector.ROOT, collector.AUDIT, collector.TASK
PRIMARY = '4d27e7c1bd9db436b5d382c0aaf719af4357bf45'
SELF = AUDIT + 'run_allocation_qualifier.py'
TARGET = AUDIT + 'qualify_operand_allocation.py'
SOURCES = (TARGET, AUDIT + 'operand_allocation.py', AUDIT + 'saved_reader_sources.py',
           AUDIT + 'prerequisite_inputs.py', collector.SELF, 'scripts/run_with_ram_guard.sh')
PROOFS = tuple(AUDIT + name for name in
               ('operand-allocation-qualified.json.gz', 'operand-allocation-data-control-qualified.json.gz'))
PREPARED = AUDIT + 'allocation-qualifier-collector-prepared.json.gz'
SCOPE = ('Dated native source/proof and collector preparation only. The fixed target '
         'command is data; preparation never launches it. Historical source/proof '
         'bodies remain data. Actual default collection requires committed collector '
         'source, the exact task-only declaration and fresh native before/after '
         'boundaries under unchanged limits. No qualifier outcome, metadata repair, '
         'source-role admission, complete helper or original semantic/model/recipe/'
         'cohort/runtime/private/HIAL/full-CI qualification follows.')


def equal(left, right):
    return bounded.strict_equal(left, right)


def command():
    return ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', TARGET]


def premises(*, current):
    sources, proofs = {}, {}
    for name in SOURCES:
        reference = prerequisite.file_reference(PRIMARY, name)
        raw = prerequisite.read_reference(reference)
        if current:
            equal(execute.read(name), raw)
        sources[name] = dict(reference=reference, body=prepare.blob(raw))
    for name in PROOFS:
        reference = prerequisite.file_reference(PRIMARY, name)
        original = prerequisite.file_reference(source.REVISION, name)
        raw = prerequisite.read_reference(reference)
        equal(prerequisite.read_reference(original), raw)
        if current:
            equal(execute.read(name), raw)
        proofs[name] = dict(reference=reference, original=original, identity=prepare.identity(raw))
    return dict(sources=sources, proofs=proofs)


def prepared(*, current):
    return dict(schema='fsmgen.allocation_qualifier_collector_preparation.v1', scope=SCOPE,
                primary=PRIMARY, original_revision=source.REVISION, command=command(),
                programme=prepare.blob(execute.read(SELF)), premises=premises(current=current))


def review_prepared(value):
    equal(value, prepared(current=False))
    equal(command(), ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', TARGET])
    return True


def boundary():
    revision = collector.native('rev-parse', 'HEAD').decode().strip()
    assert collector.native('diff', '--cached', '--name-only') == b''
    assert collector.native('diff', '--name-only').decode().splitlines() == [TASK]
    status = collector.native('status', '--porcelain=v1', '--untracked-files=all').decode().splitlines()
    equal(status, [' M ' + TASK])
    programme = execute.read(SELF)
    equal(programme, collector.native('show', revision + ':' + SELF))
    return dict(revision=revision, native_tree=prepare.blob(
                    collector.native('ls-tree', '--full-tree', '-r', '-z', revision)),
                native_index=prepare.blob(collector.native('ls-files', '--stage', '-z')),
                status=status, task=prepare.blob(execute.read(TASK)),
                programme=prepare.blob(programme), cwd='.', premises=premises(current=True))


def collect():
    review_prepared(json.loads(gzip.decompress(execute.read(PREPARED))))
    parent = ROOT / '.artifacts/tmp/tests'
    # The shared same-volume/no-symlink/no-foreign-repository policy checks all parents.
    execute.safe(parent / 'allocation-qualifier-directory-check')
    directory = Path(tempfile.mkdtemp(prefix='allocation-qualifier-', dir=parent))
    print(str(directory.relative_to(ROOT)), flush=True)
    before = boundary()
    collector.publish(directory, 'started.json', before)
    argv = command()
    with (directory / 'stdout.bin').open('xb', buffering=0) as stdout, (directory / 'stderr.bin').open('xb', buffering=0) as stderr:
        result = subprocess.run(argv, cwd=ROOT, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr)
        os.fsync(stdout.fileno())
        os.fsync(stderr.fileno())
    collector.publish(directory, 'finished.json', dict(command=argv, status=result.returncode))
    try:
        after = boundary()
        equal(after, before)
    except Exception as error:
        collector.publish(directory, 'after.json', dict(value=None, error_type=type(error).__name__, error=str(error)))
        raise
    collector.publish(directory, 'after.json', dict(value=after, error_type=None, error=None))
    print('Dependent qualifier status:', result.returncode, flush=True)
    raise SystemExit(result.returncode)


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--prepare', action='store_true')
    modes.add_argument('--check-prepared', action='store_true')
    args = parser.parse_args()
    if args.prepare:
        value = prepared(current=True)
        assert review_prepared(value)
        execute.save(PREPARED, value)
        print('Native source/proof and fixed collector preparation qualify; the dependent qualifier has not run.')
    elif args.check_prepared:
        assert review_prepared(json.loads(gzip.decompress(execute.read(PREPARED))))
        print('Saved native collector preparation qualifies; no target or historical programme executes.')
    else:
        collect()
