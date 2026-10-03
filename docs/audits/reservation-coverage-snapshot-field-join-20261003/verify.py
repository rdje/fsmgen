import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-snapshot-field-join-20261003')
CAPTURE = Path('docs/audits/reservation-coverage-snapshot-capture-20261003')
parser = argparse.ArgumentParser()
parser.add_argument('--trust-storable', action='store_true')
options = parser.parse_args()


def same(a, b):
    if type(a) is not type(b): return False
    if isinstance(a, dict): return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list): return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b


def fields(a, b):
    out, pending = set(), [('', a, b)]
    while pending:
        path, x, y = pending.pop()
        if type(x) is not type(y):
            assert type(x) is int and type(y) is str and str(x) == y, path
            out.add(path)
        elif isinstance(x, dict):
            assert x.keys() == y.keys(), path
            pending.extend((path + '/' + k, x[k], y[k]) for k in x)
        elif isinstance(x, list):
            assert len(x) == len(y), path
            pending.extend((path + '/' + str(i), xx, yy) for i, (xx, yy) in enumerate(zip(x, y)))
        else:
            assert x == y, path
    return sorted(out)


if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, r in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == r['bytes'] and hashlib.sha256(raw).hexdigest() == r['sha256'], name
ownership = json.loads((BASE / 'ownership.json').read_text())
raw = subprocess.check_output(['git', 'show', ownership['revision'] + ':' + ownership['task_path']])
assert len(raw) == ownership['task_bytes'] and hashlib.sha256(raw).hexdigest() == ownership['task_sha256']
task = raw.decode()
expected_names = ['normal', 'producer_removal']
expected_directories = ['docs/audits/reservation-coverage-snapshot-normal-fields-20261003', 'docs/audits/reservation-coverage-producer-removal-fields-20261003']
parent = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.2.4.3.4.2'
qualified = {}
for index, row in enumerate(ownership['cohorts']):
    assert row == {'name': expected_names[index], 'directory': expected_directories[index], 'owner': parent + '.' + str(index + 1)}
    start = task.index('- ID: `' + row['owner'] + '`')
    end = task.index('\n- ID:', start + 5)
    assert 'Status: `done`' in task[start:end] and 'Commit: `this commit`' in task[start:end]
    directory = Path(row['directory'])
    subprocess.run(['python3', '-B', str(directory / 'verify.py')], check=True)
    qualified[row['name']] = json.loads((directory / 'qualified-fields.json').read_text())
assert len(ownership['cohorts']) == 2
ordinary = json.loads((CAPTURE / 'ordinary.json').read_text())
pure = json.loads((CAPTURE / 'pure.json').read_text())
selected = {'success_snapshot', 'refusal_snapshot', 'module_mutation_seed', 'unexpected_module_seed', 'allocation_mutation_seed'}
expected = []
for i, (a, b) in enumerate(zip(ordinary['copies'], pure['copies'])):
    if a['site'] not in selected: continue
    if options.trust_storable:
        assert same(a['before'], a['copy']), ('actual snapshot/seed kind authority', i)
    assert same(a['before'], a['after']) and same(b['before'], b['after']) and same(b['before'], b['copy'])
    assert a['shared_with_original'] == b['shared_with_original'] == 0
    expected.append({'ordinal': i, 'site': a['site'], 'cohort': 'producer_removal' if i == 35 else 'normal', 'paths': fields(a['before'], a['copy'])})
for name in expected_names:
    rows = [{k: v for k, v in r.items() if k != 'cohort'} for r in expected if r['cohort'] == name]
    assert same(rows, qualified[name]), ('incomplete cohort', name)
assert same(expected, json.loads((BASE / 'joined-fields.json').read_text())), 'incomplete joined roster'
assert len(expected) == 36 and sum(bool(r['paths']) for r in expected) == 30
assert sum(len(r['paths']) for r in expected) == 392
for label, mutation in (
    ('copy omission', lambda x: x.pop()),
    ('field omission', lambda x: x[0]['paths'].pop()),
    ('wrong owner', lambda x: x[0].update(cohort='producer_removal')),
    ('empty allocation omission', lambda x: x.pop(next(i for i, r in enumerate(x) if r['site'] == 'allocation_mutation_seed'))),
):
    bad = copy.deepcopy(expected); mutation(bad)
    assert not same(bad, expected), ('corrupted join accepted', label)
print('PASS complete snapshot/seed membership, every semantic field and unchanged-copy control reconcile with authenticated completed cohorts.')
print('PASS independent whole typed paths, pure/original topology/deep-isolation and ordinary source/product/cause/carrier conservation through immutable readers.')
print('PASS omitted copy/field/empty allocation and wrong-owner controls reject; actual Storable authority remains a genuine counterfactual.')
print('OPEN: real value-only assertion and native-marker controls, then final coverage join, precede P2 repair; wider constructor/controller/moved-root and visual QA remain cold.')

if not options.trust_storable:
    assert (BASE / 'trust-storable.status').read_text().strip() == '1'
    assert (BASE / 'trust-storable.txt').read_text().splitlines()[-1] == "AssertionError: ('actual snapshot/seed kind authority', 2)"
