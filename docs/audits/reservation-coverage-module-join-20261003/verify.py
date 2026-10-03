import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-module-join-20261003')
MODULE = Path('docs/audits/reservation-coverage-module-capture-20261003')
SOURCE = Path('docs/audits/reservation-coverage-source-copies-20261003')
parser = argparse.ArgumentParser()
parser.add_argument('--trust-storable', action='store_true')
options = parser.parse_args()


def same(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b


def fields(a, b):
    paths, pending = set(), [('', a, b)]
    while pending:
        path, x, y = pending.pop()
        if type(x) is not type(y):
            assert type(x) is int and type(y) is str and str(x) == y, ('unexpected delta', path)
            paths.add(path)
        elif isinstance(x, dict):
            assert x.keys() == y.keys(), path
            pending.extend((path + '/' + k, x[k], y[k]) for k in x)
        elif isinstance(x, list):
            assert len(x) == len(y), path
            pending.extend((path + '/' + str(i), p, q) for i, (p, q) in enumerate(zip(x, y)))
        else:
            assert x == y, path
    return sorted(paths)


if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, record in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == record['bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256'], name
ownership = json.loads((BASE / 'ownership.json').read_text())
raw = subprocess.check_output(['git', 'show', ownership['revision'] + ':' + ownership['task_path']])
assert len(raw) == ownership['task_bytes'] and hashlib.sha256(raw).hexdigest() == ownership['task_sha256']
task = raw.decode()
expected_names = ['generated', 'reusable', 'atl']
expected_modules = [[0, 1, 2, 8, 9], [3, 4], [5, 6, 7]]
expected_preparations = [[], [4], [7]]
expected_directories = [
    'docs/audits/reservation-coverage-generated-module-fields-20261003',
    'docs/audits/reservation-coverage-reusable-module-fields-20261003',
    'docs/audits/reservation-coverage-atl-module-fields-20261003',
]
parent = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.2.4.3.3'
assert len(ownership['cohorts']) == 3
for i, row in enumerate(ownership['cohorts']):
    assert row['name'] == expected_names[i]
    assert row['directory'] == expected_directories[i]
    assert row['module_ordinals'] == expected_modules[i] and row['preparation_ordinals'] == expected_preparations[i]
    assert row['owner'] == parent + '.' + str(i + 3)
    block = task.split('- ID: `' + row['owner'] + '`\n', 1)[1].split('\n- ID: ', 1)[0]
    assert 'Status: `done`\n' in block and 'Commit: `this commit`\n' in block
    subprocess.run(['python3', '-B', str(Path(row['directory']) / 'verify.py')], check=True)

ordinary = json.loads((MODULE / 'ordinary.json').read_text())
pure = json.loads((MODULE / 'pure.json').read_text())
source_before = json.loads((SOURCE / 'pure.json').read_text())
source_after = json.loads((SOURCE / 'ordinary.json').read_text())
roster = json.loads((MODULE / 'field-roster.json').read_text())
assert len(ordinary['copies']) == len(pure['copies']) == len(roster) == 10
assert len(source_before['preparations']) == len(source_after['preparations']) == 12
expected = {'modules': [], 'preparations': []}
for i, (a, b) in enumerate(zip(ordinary['copies'], pure['copies'])):
    if options.trust_storable:
        assert same(a['before'], a['copy']), ('actual module copy kind authority', i)
    assert same(a['before'], a['after']) and same(a['before'], b['before'])
    assert same(b['before'], b['copy']) and same(b['before'], b['after'])
    cohort = next(j for j, ordinals in enumerate(expected_modules) if i in ordinals)
    paths = fields(a['before'], a['copy'])
    assert paths == sorted(row[0] for row in roster[i]['differences'])
    assert roster[i]['field_owner'] == parent + '.' + str(cohort + 3)
    expected['modules'].append({'ordinal': i, 'cohort': expected_names[cohort], 'paths': paths})
for i, (a, b) in enumerate(zip(source_before['preparations'], source_after['preparations'])):
    paths = fields(a['result'], b['result'])
    assert bool(paths) == (i in (4, 7)), ('unowned preparation field', i)
    cohort = None if not paths else 'reusable' if i == 4 else 'atl'
    expected['preparations'].append({'ordinal': i, 'cohort': cohort, 'paths': paths})
reusable = Path(ownership['cohorts'][1]['directory'])
atl = Path(ownership['cohorts'][2]['directory'])
reusable_fields = json.loads((reusable / 'qualified-fields.json').read_text())
atl_fields = json.loads((atl / 'qualified-fields.json').read_text())
assert reusable_fields['preparation'] == {'ordinal': 4, 'paths': expected['preparations'][4]['paths']}
assert atl_fields['preparation'] == {'ordinal': 7, 'paths': expected['preparations'][7]['paths']}
assert reusable_fields['module'] == {'ordinal': 4, 'paths': expected['modules'][4]['paths']}
assert atl_fields['modules'] == [{'ordinal': i, 'paths': expected['modules'][i]['paths']} for i in (5, 6, 7)]
assert same(json.loads((BASE / 'joined-fields.json').read_text()), expected), 'incomplete or wrong-owner join'
for label, mutate in (
        ('module omission', lambda d: d['modules'].pop()),
        ('field omission', lambda d: d['modules'][0]['paths'].pop()),
        ('wrong owner', lambda d: d['modules'][0].update(cohort='atl')),
        ('preparation omission', lambda d: d['preparations'][7]['paths'].pop())):
    bad = copy.deepcopy(expected)
    mutate(bad)
    assert not same(bad, expected), ('bad join accepted', label)
assert (BASE / 'trust-storable.status').read_text().strip() == '1'
assert (BASE / 'trust-storable.txt').read_text().splitlines()[-1] == "AssertionError: ('actual module copy kind authority', 0)"
print('PASS full source-bound original/current module membership and every field contract through independently completed generated/reusable/ATL readers.')
print('PASS complete actor-only preparation difference set reconciles only to qualified FIFO and vector paths; original/pure graph and ordinary product conservation remains authenticated.')
print('PASS module/field/preparation omissions and wrong owners reject; actual lossy Storable kind authority remains a real competing model.')
print('OPEN: successful/refused snapshots, mutation seeds and final coverage join precede P2 repair; wider controllers/constructors/native/moved-root stay cold.')
