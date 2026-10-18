"""Inert component/source and real retained before/after boundary controls."""
from pathlib import Path
import copy
import gzip
import hashlib
import importlib.util
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[3]
AUDIT = Path('docs/audits/task-acceptance-committed-boundary-20261018')
BASE = Path('docs/audits/task-acceptance-index-observer-20261017')
HISTORY = Path('docs/audits/task-acceptance-box-boundary-20261017')
sys.path.insert(0, str(ROOT / BASE))
from verify import unblob


def module(name, file):
    spec = importlib.util.spec_from_file_location(name, ROOT / AUDIT / file)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


runner = module('boundary_runner', 'run.py')
reader = module('boundary_reader', 'verify.py')
current = runner.core.sources()
qualified = json.loads(gzip.decompress((ROOT / runner.QUALIFIED).read_bytes()))
assert runner.verify(qualified) and runner.component_join(qualified, current)
assert runner.core.perl('print $IndexObserver::WORK') == str(runner.WORK).encode()
for mutation in ('changed', 'missing'):
    bad = copy.deepcopy(current)
    name = next(iter(qualified['sources_after']))
    if mutation == 'changed':
        bad[name] = runner.core.blob(unblob(bad[name]) + b'\n# self-consistent changed component\n')
    else:
        del bad[name]
    try:
        runner.component_join(qualified, bad)
    except (AssertionError, KeyError):
        continue
    raise AssertionError('changed/missing qualified component admitted')


def historical(action):
    record = json.loads(gzip.decompress((ROOT / HISTORY / (action + '-actual.json.gz')).read_bytes()))
    stderr = unblob(record['streams']['stderr'])
    cases = [json.loads(row) for row in re.findall(rb'box boundary case: (\{[^\n]+\})', stderr)]
    return record, cases


after, cases = historical('after')
assert after['status'] == 0 and after['source_conserved'] and after['git_conserved']
assert len(cases) == 9 and sum(len(row['stages']) for row in cases) == 90
assert sum(row['checker'] is not None for row in cases) == 9
assert [row['case'] for row in cases] == [name for name, _ in reader.CASES]
for row, (name, code) in zip(cases, reader.CASES):
    assert reader.case_oracle(row, name, code)
source_file = ROOT / after['sources_after']['path']
assert hashlib.sha256(source_file.read_bytes()).hexdigest() == after['sources_after']['sha256']
sources = json.loads(gzip.decompress(source_file.read_bytes()))
for name in ('scripts/check_task_acceptance.sh', 't/lib/FSM/Test/TaskAcceptanceIndexRuntime.pm', runner.TARGET):
    assert unblob(sources[name]) == (ROOT / name).read_bytes()

before, bad_cases = historical('before')
assert before['status'] != 0
indexed = {row['case']: row for row in bad_cases}
for name in ('box_root_sibling', 'box_regression_sibling'):
    bad = indexed[name]
    assert bad['status'] == 'checker_returned' and bad['checker']['exit_code'] == 0
    try:
        reader.case_oracle(bad, name, 1)
    except AssertionError:
        continue
    raise AssertionError('real retained false green admitted')
print('Inert complete component joins, closed source admission, unchanged producer populations and real native-before RED/native-after GREEN boundary oracles pass.')
