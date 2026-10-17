"""Inert source-join and final-control-stop checks; no selected tests execute."""
from pathlib import Path
import copy
import gzip
import importlib.util
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
AUDIT = Path('docs/audits/task-acceptance-index-prospective-20261018')
ORIGINAL = Path('docs/audits/task-acceptance-index-observer-20261017')
sys.path.insert(0, str(ROOT / ORIGINAL))
from verify import verify, unblob, qualified_sources
from verify_failure import validate_failure

spec = importlib.util.spec_from_file_location('prospective_runner', ROOT / AUDIT / 'run.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)

record = json.loads(gzip.decompress((ROOT / ORIGINAL / 'pre-source-join-controls.json.gz').read_bytes()))
assert verify(record)
rows = record['rows'][:-1]
assert runner.ready_for_reuse(rows)
bad = copy.deepcopy(rows)
bad[-1]['stdout'] = runner.original.blob(b'not ok 1 - unexpected native failure\n1..167\n')
assert len(bad) == 6 and not runner.ready_for_reuse(bad)
assert not runner.ready_for_reuse(rows[:-1])

current = runner.original.sources()
assert str(ORIGINAL / 'verify_failure.py') in current
assert qualified_sources({'sources_after': current}, current)
for kind in ('changed', 'missing'):
    bad = copy.deepcopy(current)
    name = str(AUDIT / 'run.py')
    if kind == 'changed':
        bad[name] = runner.original.blob(unblob(bad[name]) + b'\n# self-consistent source substitution\n')
    else:
        del bad[name]
    try:
        qualified_sources({'sources_after': current}, bad)
    except AssertionError:
        continue
    raise AssertionError('source substitution admitted')

original = (ROOT / ORIGINAL / 'observe.pl').read_bytes()
added = (b"use lib 'docs/audits/task-acceptance-index-prospective-20261018';\n"
         b'use ProspectiveIndexObserver;\n\n')
expected = original.replace(b'my $selector = shift @ARGV;', added + b'my $selector = shift @ARGV;')
expected = expected.replace(b'die "selected test error: $test_error\\n" if $test_error;',
                            b'ProspectiveIndexObserver::stop_harness($observer);\n'
                            b'die "selected test error: $test_error\\n" if $test_error;')
assert (ROOT / AUDIT / 'observe.pl').read_bytes() == expected
for name in current:
    if name.startswith(str(ORIGINAL) + '/'):
        assert subprocess.check_output(['git', 'show', 'HEAD:' + name], timeout=30) == (ROOT / name).read_bytes()
failed = json.loads(gzip.decompress((ROOT / ORIGINAL / 'controls.json.gz').read_bytes()))
assert validate_failure(failed)
print('Inert source closure, unchanged original inputs, final-row stop and historical failure custody pass.')
