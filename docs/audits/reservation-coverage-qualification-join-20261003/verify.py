"""Independent complete copy membership, field/cohort owner and repair handoff."""
import argparse
import copy
import hashlib
import json
import re
import subprocess
from collections import Counter
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-qualification-join-20261003')
AUDITS = Path('docs/audits')
PREFIX = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.2.4.3'
parser = argparse.ArgumentParser()
parser.add_argument('--trust-storable', action='store_true')
options = parser.parse_args()


def load(name): return json.loads(Path(name).read_text())


def same(a, b):
    if type(a) is not type(b): return False
    if isinstance(a, dict): return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list): return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b


def fields(a, b):
    found, pending = [], [('', a, b)]
    while pending:
        path, x, y = pending.pop()
        if type(x) is not type(y):
            assert type(x) is int and type(y) is str and str(x) == y, ('unexpected kind/value drift', path)
            found.append([path, 'int', 'str', x, y])
        elif isinstance(x, dict):
            assert x.keys() == y.keys(), ('key drift', path)
            pending.extend((path + '/' + k, x[k], y[k]) for k in x)
        elif isinstance(x, list):
            assert len(x) == len(y), ('length drift', path)
            pending.extend((path + '/' + str(i), xx, yy) for i, (xx, yy) in enumerate(zip(x, y)))
        else: assert x == y, ('value drift', path)
    return sorted(found)


def sites(source):
    # Independent expression-level mapping accommodates the old single-line
    # refusal layout, while requiring closure of every actual clone call.
    patterns = [
        (r"my \$actor = ref\(\$source\) eq 'HASH' \? dclone\(\$source\)", 'authored_actor'),
        (r'my \$physical = dclone\(\$p->\{actor\}\);', 'physical_actor'),
        (r'\$modules\{\$ir->\{actor_name\}\} = dclone\(\$ir\);', 'captured_module'),
        (r'my \$before = dclone\(\[\$p, \$plan, \\%modules\]\);', 'success_snapshot'),
        (r'my \$before = dclone\(\[\$p, \$allocation, \$actual\]\);', 'refusal_snapshot'),
        (r'\$_\[0\]\{extra\} = dclone\(\$_\[0\]\{coverage\}\)', 'unexpected_module_seed'),
        (r'my \$actual = dclone\(\$modules\);', 'module_mutation_seed'),
        (r'my \$bad_plan = dclone\(\$plan\);', 'allocation_mutation_seed'),
    ]
    result = {}
    for line, body in enumerate(source.splitlines(), 1):
        if not re.search(r'\bdclone\(', body): continue
        matched = [site for pattern, site in patterns if re.search(pattern, body)]
        assert len(matched) == 1, ('unowned/ambiguous source copy', line)
        result[str(line)] = matched[0]
    assert len(result) == len(set(result.values())) == 8
    return result


if (BASE / 'manifest.json').exists():
    manifest = load(BASE / 'manifest.json')
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
subprocess.run(['python3', '-B', 'docs/audits/reservation-coverage-snapshot-native-join-20261003/verify.py'], check=True)
binding = load(BASE / 'bindings.json')
for label, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', row['revision'] + ':t/1960-isf-formal-reservation-coverage.t'])
    assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'] and raw.decode() == row['body'], label
raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['task_path']])
assert len(raw) == binding['task_bytes'] and hashlib.sha256(raw).hexdigest() == binding['task_sha256']
task = raw.decode()
assert set(binding['owners']) == {PREFIX + s for s in ('.1', '.2', '.3', '.3.6', '.4', '.4.3.2.2')}
for identity, body in binding['owners'].items():
    start = task.index('- ID: `' + identity + '`'); end = task.index('\n- ID:', start + 1)
    assert body == task[start:end] and 'Status: `done`' in body and 'Verification: `pending`' not in body
handoff = load(BASE / 'handoff.json')
assert handoff['sites'] == {label: sites(row['body']) for label, row in binding['sources'].items()}
source = load(AUDITS / 'reservation-coverage-source-copies-20261003/ordinary.json')
module = load(AUDITS / 'reservation-coverage-module-capture-20261003/ordinary.json')
snapshot = load(AUDITS / 'reservation-coverage-snapshot-capture-20261003/ordinary.json')
initial = load(AUDITS / 'reservation-coverage-helper-causes-20261003/initial-observations-unqualified.json')
module_fields = load(AUDITS / 'reservation-coverage-module-capture-20261003/field-roster.json')
snapshot_fields = load(AUDITS / 'reservation-coverage-snapshot-capture-20261003/field-roster.json')
actor_sites = {'authored_actor', 'physical_actor'}
snapshot_sites = {'success_snapshot', 'refusal_snapshot', 'unexpected_module_seed', 'module_mutation_seed', 'allocation_mutation_seed'}
expected_counts = {'authored_actor': 6, 'physical_actor': 10, 'captured_module': 10, 'success_snapshot': 10,
    'refusal_snapshot': 13, 'unexpected_module_seed': 1, 'module_mutation_seed': 11, 'allocation_mutation_seed': 1}


def close(rows):
    assert len(rows) == len(snapshot['copies']) == len(initial['clones']) == 62
    assert [r['ordinal'] for r in rows] == list(range(62))
    assert Counter(r['site'] for r in rows) == expected_counts
    family_index = Counter()
    for ordinal, (row, now, old) in enumerate(zip(rows, snapshot['copies'], initial['clones'])):
        site = row['site']; family = 'actor' if site in actor_sites else 'module' if site == 'captured_module' else 'snapshot'
        owner = PREFIX + { 'actor': '.2', 'module': '.3', 'snapshot': '.4'}[family]
        assert row['owner'] == owner and owner in binding['owners'], ('unqualified/wrong cohort owner', ordinal)
        assert row['current_line'] == now['line'] and row['initial_line'] == old['line']
        assert handoff['sites']['current'][str(now['line'])] == handoff['sites']['initial'][str(old['line'])] == now['site'] == site
        for x, y in ((old['before'], now['before']), (old['after'], now['after']), (old['clone'], now['copy']), (now['before'], now['after'])):
            assert same(x, y), ('whole original/current caller-copy drift', ordinal)
        assert row['differences'] == fields(now['before'], now['copy']), ('complete field roster drift', ordinal)
        assert now['original_reference_count'] == now['copy_reference_count'] > 0 and now['shared_with_original'] == 0
        if family == 'actor':
            qualified = source['copies'][family_index[family]]
            assert same(now, qualified), ('actor qualification association drift', ordinal)
        elif family == 'module':
            qualified = module['copies'][family_index[family]]
            assert same(now, qualified)
            assert row['differences'] == module_fields[family_index[family]]['differences']
        else:
            qualified = snapshot_fields[family_index[family]]
            assert qualified['ordinal'] == ordinal and qualified['site'] == site
            assert row['differences'] == qualified['differences'] and qualified['pure_differences'] == []
        family_index[family] += 1
    assert family_index == {'actor': 16, 'module': 10, 'snapshot': 36}
    assert sum(bool(r['differences']) for r in rows) == 41
    assert sum(len(r['differences']) for r in rows) == 548
    assert {family: sum(len(r['differences']) for r in rows if r['owner'] == PREFIX + suffix)
        for family, suffix in (('actor', '.2'), ('module', '.3'), ('snapshot', '.4'))} == {'actor': 7, 'module': 149, 'snapshot': 392}
    return rows


close(handoff['copies'])
if options.trust_storable:
    row = next(r for r in handoff['copies'] if r['differences'])
    actual = snapshot['copies'][row['ordinal']]
    assert same(actual['before'], actual['copy']), ('actual complete Storable authority loses declared primitive kinds', row['ordinal'])
for defect in ('copy omission', 'field omission', 'unchanged allocation omission', 'wrong owner'):
    bad = copy.deepcopy(handoff['copies'])
    if defect == 'copy omission': bad.pop(0)
    elif defect == 'field omission': next(r for r in bad if r['differences'])['differences'].pop()
    elif defect == 'unchanged allocation omission': bad = [r for r in bad if r['site'] != 'allocation_mutation_seed']
    else: bad[0]['owner'] = PREFIX + '.5'
    try: close(bad)
    except AssertionError: pass
    else: raise AssertionError(('handoff control accepted', defect))
print('PASS complete initial/current Git/source and done semantic/control owners; every8 copy site and all62 observations close across actor16/module10/snapshot36 cohorts, including unchanged and empty seeds.')
print('PASS every actual primitive-kind difference joins source-owned semantics: changed41 observations/548 ordinal-field pairs (actor7/module149/snapshot392), never distinct production defects; whole callers/ordinary products/causes and cold limits remain authenticated.')
print('PASS genuine Storable unsafe authority and copy/field/empty-seed/owner controls; complete cause, value-only kind, alias/cycle/isolation/native controls qualify the finite prospective helper. P2 .13 is the immediate test-copy/snapshot repair; arbitrary native/constructor/controller/moved-root meanings remain cold.')
if not options.trust_storable:
    assert (BASE / 'trust-storable.status').read_text().strip() == '1'
    assert (BASE / 'trust-storable.txt').read_text().splitlines()[-1] == "AssertionError: ('actual complete Storable authority loses declared primitive kinds', 1)"
