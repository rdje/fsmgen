import argparse
import copy
import hashlib
import json
import subprocess
from collections import Counter
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-snapshot-capture-20261003')
PROFILE = Path('docs/audits/reservation-coverage-helper-causes-20261003')
MODULE = Path('docs/audits/reservation-coverage-module-capture-20261003')
parser = argparse.ArgumentParser()
parser.add_argument('--trust-storable', action='store_true')
options = parser.parse_args()
selected = {'success_snapshot', 'refusal_snapshot', 'unexpected_module_seed',
            'module_mutation_seed', 'allocation_mutation_seed'}
counts = {'authored_actor': 6, 'physical_actor': 10, 'captured_module': 10,
          'success_snapshot': 10, 'refusal_snapshot': 13, 'module_mutation_seed': 11,
          'unexpected_module_seed': 1, 'allocation_mutation_seed': 1}
old_sites = {29: 'authored_actor', 33: 'physical_actor', 50: 'captured_module',
             55: 'success_snapshot', 94: 'refusal_snapshot', 114: 'module_mutation_seed',
             105: 'unexpected_module_seed', 117: 'allocation_mutation_seed'}


def same(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b


def differences(a, b):
    out, pending = [], [('', a, b)]
    while pending:
        path, x, y = pending.pop()
        if type(x) is not type(y):
            assert {type(x), type(y)} == {int, str} and str(x) == str(y), ('unexpected kind/value', path)
            out.append([path, type(x).__name__, type(y).__name__, x, y])
        elif isinstance(x, dict):
            assert x.keys() == y.keys(), path
            pending.extend((path + '/' + k, x[k], y[k]) for k in x)
        elif isinstance(x, list):
            assert len(x) == len(y), path
            pending.extend((path + '/' + str(i), xx, yy) for i, (xx, yy) in enumerate(zip(x, y)))
        else:
            assert x == y, path
    return sorted(out, key=lambda row: row[0])


def authenticate(base):
    manifest = json.loads((base / 'manifest.json').read_text())
    assert {p.name for p in base.iterdir()} == set(manifest) | {'manifest.json'}
    for name, r in manifest.items():
        raw = (base / name).read_bytes()
        assert len(raw) == r['bytes'] and hashlib.sha256(raw).hexdigest() == r['sha256'], name


if (BASE / 'manifest.json').exists():
    authenticate(BASE)
subprocess.run(['python3', '-B', 'docs/audits/reservation-coverage-module-join-20261003/verify.py'], check=True)
binding = json.loads((BASE / 'bindings.json').read_text())
for path, r in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert raw.decode() == r['body'] and len(raw) == r['bytes'] and hashlib.sha256(raw).hexdigest() == r['sha256']
prior_binding = json.loads((MODULE / 'bindings.json').read_text())
# Public source closure is retained in the authenticated module corpus. Compare
# complete Git tree membership/object identities, without submodule traversal.
args = ['--', 'bin', 'perl', 't', 'scripts', 'isf']
assert subprocess.check_output(['git', 'ls-tree', '-r', '-z', binding['revision'], *args]) == subprocess.check_output(['git', 'ls-tree', '-r', '-z', prior_binding['revision'], *args])
source = binding['sources']['t/1960-isf-formal-reservation-coverage.t']['body'].splitlines()
patterns = {
    "    my $actor = ref($source) eq 'HASH' ? dclone($source)": 'authored_actor',
    '    my $physical = dclone($p->{actor});': 'physical_actor',
    '            $modules{$ir->{actor_name}} = dclone($ir);': 'captured_module',
    '    my $before = dclone([$p, $plan, \\%modules]);': 'success_snapshot',
    '    my $before = dclone([$p, $allocation, $actual]);': 'refusal_snapshot',
    '        [sub {$_[0]{extra} = dclone($_[0]{coverage})},': 'unexpected_module_seed',
    '        my $actual = dclone($modules); $case->[0]->($actual);': 'module_mutation_seed',
    "    my $bad_plan = dclone($plan); $bad_plan->{formals}{main}{payload}{physical_name} = 'isf_port_main_payload';": 'allocation_mutation_seed',
}
sites = {str(i): patterns[line] for i, line in enumerate(source, 1) if line in patterns}
assert len(sites) == len(patterns) == 8
ordinary = json.loads((BASE / 'ordinary.json').read_text())
pure = json.loads((BASE / 'pure.json').read_text())
profile = json.loads((PROFILE / 'initial-observations-unqualified.json').read_text())
coordinates = json.loads((BASE / 'coordinates.json').read_text())


def coordinate_paths(value, path='', key=None):
    if isinstance(value, dict):
        return [p for k, v in value.items() for p in coordinate_paths(v, path + '/' + k, k)]
    if isinstance(value, list):
        return [p for i, v in enumerate(value) for p in coordinate_paths(v, path + '/' + str(i))]
    if isinstance(value, str) and '${REPO_ROOT}' in value:
        assert key == 'library_source' and value == '${REPO_ROOT}/isf/common/fifo.isf', path
        return [path]
    return []


for mode, data in (('ordinary', ordinary), ('pure', pure)):
    assert data['mode'] == mode and same(data['sites'], sites)
    assert len(data['copies']) == len(profile['clones']) == 62
    assert Counter(row['site'] for row in data['copies']) == counts
    assert len(data['preparations']) == 12 and len(data['lowerings']) == 10 and len(data['coverage']) == 23
    assert sorted(coordinate_paths(data)) == sorted(coordinates[mode])
    for i, row in enumerate(data['copies']):
        assert sites[str(row['line'])] == row['site']
        assert same(row['before'], row['after']), ('original mutated', mode, i)
        assert row['shared_with_original'] == 0
        assert type(row['original_reference_count']) is int and row['original_reference_count'] > 0
        assert row['original_reference_count'] == row['copy_reference_count']
        if row['site'] in selected and (mode == 'pure' or options.trust_storable):
            assert same(row['before'], row['copy']), ('snapshot/seed primitive-kind authority', mode, i)
    for family in ('preparations', 'lowerings', 'coverage'):
        for i, row in enumerate(data[family]):
            assert same(row['before'], row['after']), ('caller mutated', mode, family, i)
    assert (BASE / (mode + '.status')).read_text().strip() == '0'
    assert 'All tests successful.' in (BASE / (mode + '.txt')).read_text()
    assert 'Files=1, Tests=5,' in (BASE / (mode + '.txt')).read_text()
expected = []
for i, (a, b, old) in enumerate(zip(ordinary['copies'], pure['copies'], profile['clones'])):
    assert old_sites[old['line']] == a['site'] == b['site']
    assert same(a['before'], old['before']) and same(a['copy'], old['clone']), ('original complete copy bridge', i)
    if a['site'] in selected:
        expected.append({'ordinal': i, 'site': a['site'], 'line': a['line'],
                         'differences': differences(a['before'], a['copy']),
                         'pure_differences': differences(b['before'], b['copy'])})
    else:
        assert same(a, b), ('unselected copy changed', i)
roster = json.loads((BASE / 'field-roster.json').read_text())
assert same(roster, expected), 'complete remaining field roster'
assert len(expected) == 36 and sum(bool(r['differences']) for r in expected) == 30
assert sum(len(r['differences']) for r in expected) == 392
for family in ('preparations', 'lowerings', 'coverage'):
    for i, (a, b) in enumerate(zip(ordinary[family], pure[family])):
        if family != 'coverage':
            assert same(a, b), (family, i)
        else:
            # The genuine seed control may change only primitive kinds in the
            # module operand. Snapshot copies never replace API operands.
            assert same(a['before'][1][:2], b['before'][1][:2])
            assert all(r[0].startswith('/1/2/') for r in differences(a['before'], b['before']))
            assert a['accepted'] == b['accepted'] == profile['api'][i]['accepted']
            assert same(a['result'], b['result']) and same(a['result'], profile['api'][i]['result'])
            if not a['accepted']:
                assert a['error'].splitlines()[0] == b['error'].splitlines()[0] == profile['api'][i]['error'].splitlines()[0]
for bad in (copy.deepcopy(roster[:-1]), copy.deepcopy(roster)):
    if len(bad) == len(roster):
        bad[0]['differences'].pop()
    assert not same(roster, bad), 'omitted site/field falsely accepted'
changed = copy.deepcopy(ordinary)
changed['coverage'][0]['after'][1][0][1]['actor'][1]['actor_name'] = 'wrong_owner'
assert not same(ordinary['coverage'][0]['before'], changed['coverage'][0]['after']), 'caller corruption falsely accepted'
print('PASS complete initial/current copy-site closure and independently derived remaining snapshot/seed typed roster.')
print('PASS actual originals/API callers, pure copies, plain topology/deep isolation and whole ordinary lowering/carrier/scope/cause conservation.')
print('PASS omitted site/field and caller corruptions reject; field meanings and real value-only assertions remain separately owned, not promoted by this capture.')

if not options.trust_storable:
    assert (BASE / 'trust-storable.status').read_text().strip() == '1'
    assert (BASE / 'trust-storable.txt').read_text().splitlines()[-1] == "AssertionError: ('snapshot/seed primitive-kind authority', 'ordinary', 2)"
