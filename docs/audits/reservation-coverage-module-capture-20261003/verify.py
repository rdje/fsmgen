import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-module-capture-20261003')
PROFILE = Path('docs/audits/reservation-coverage-helper-causes-20261003')
parser = argparse.ArgumentParser()
parser.add_argument('--trust-storable', action='store_true')
options = parser.parse_args()

def same(left, right):
    if type(left) is not type(right):
        return False
    if isinstance(left, dict):
        return left.keys() == right.keys() and all(same(left[k], right[k]) for k in left)
    if isinstance(left, list):
        return len(left) == len(right) and all(same(a, b) for a, b in zip(left, right))
    return left == right

def authenticate(directory):
    manifest = json.loads((directory / 'manifest.json').read_text())
    assert {p.name for p in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, evidence in manifest.items():
        raw = (directory / name).read_bytes()
        assert len(raw) == evidence['bytes'] and hashlib.sha256(raw).hexdigest() == evidence['sha256'], name

def walk_delta(left, right):
    # A separate stack traversal re-derives the full per-instance field set;
    # it never imports the producer's classifier or comparison function.
    stack = [('', left, right)]
    out = []
    while stack:
        path, a, b = stack.pop()
        if type(a) is not type(b):
            out.append([path, type(a).__name__, type(b).__name__, a, b])
        elif isinstance(a, dict):
            assert a.keys() == b.keys(), ('changed keys', path)
            for key in a:
                stack.append((path + '/' + key, a[key], b[key]))
        elif isinstance(a, list):
            assert len(a) == len(b), ('changed length', path)
            for i, (x, y) in enumerate(zip(a, b)):
                stack.append((path + '/' + str(i), x, y))
        else:
            assert a == b, ('changed value', path)
    return sorted(out, key=lambda row: row[0])

authenticate(PROFILE)
if (BASE / 'manifest.json').exists():
    authenticate(BASE)
binding = json.loads((BASE / 'bindings.json').read_text())
members = {}
for entry in subprocess.check_output(['git', 'ls-tree', '-r', '-z', binding['revision'], '--', 'bin', 'perl', 't', 'scripts', 'isf']).split(b'\0'):
    if not entry:
        continue
    header, name = entry.split(b'\t', 1)
    members[name.decode()] = header.decode().split()[2]
assert members.keys() == binding['metadata'].keys()
with subprocess.Popen(['git', 'cat-file', '--batch'], stdin=subprocess.PIPE, stdout=subprocess.PIPE) as objects:
    for name, evidence in binding['metadata'].items():
        objects.stdin.write((members[name] + '\n').encode())
        objects.stdin.flush()
        assert objects.stdout.readline().decode().split() == [members[name], 'blob', str(evidence['bytes'])]
        raw = objects.stdout.read(evidence['bytes'])
        assert objects.stdout.read(1) == b'\n'
        assert members[name] == evidence['blob']
        assert len(raw) == evidence['bytes'] and hashlib.sha256(raw).hexdigest() == evidence['sha256'], name
    objects.stdin.close()
    assert objects.wait() == 0
for name, body in binding['sources'].items():
    assert body.encode() == subprocess.check_output(['git', 'cat-file', 'blob', members[name]]), name

ordinary = json.loads((BASE / 'ordinary.json').read_text())
pure = json.loads((BASE / 'pure.json').read_text())
profile = json.loads((PROFILE / 'initial-observations-unqualified.json').read_text())
old = [row for row in profile['clones'] if row['line'] == 50]
roster = json.loads((BASE / 'field-roster.json').read_text())
parent = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.2.4.3.3'
names = ['coverage', 'coverage', 'coverage', 'fifo_library_use', 'storage_fields',
         'atl_resolved_child_pipeline', 'atl_two_child_vector_data_pipeline',
         'atl_two_child_trigger_batch_pipeline', 'rule_coverage', 'monitor_coverage']
owners = [parent + suffix for suffix in ('.3', '.3', '.3', '.4', '.4', '.5', '.5', '.5', '.3', '.3')]
source_lines = binding['sources']['t/1960-isf-formal-reservation-coverage.t'].splitlines()
sites = {str(i): 'captured_module' for i, line in enumerate(source_lines, 1)
         if line == '            $modules{$ir->{actor_name}} = dclone($ir);'}
assert len(sites) == 1 and len(roster) == len(old) == len(names)
task = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md').read_text()
assert all('- ID: `' + owner + '`\n' in task for owner in set(owners))

coordinates = json.loads((BASE / 'coordinates.json').read_text())
def find_coordinates(value, path='', key=None):
    if isinstance(value, dict):
        return [p for name, child in value.items() for p in find_coordinates(child, path + '/' + name, name)]
    if isinstance(value, list):
        return [p for i, child in enumerate(value) for p in find_coordinates(child, path + '/' + str(i))]
    if isinstance(value, str) and '${REPO_ROOT}' in value:
        assert key == 'library_source' and value == '${REPO_ROOT}/isf/common/fifo.isf', path
        return [path]
    return []

for mode, data in (('ordinary', ordinary), ('pure', pure)):
    assert set(data) == {'mode', 'sites', 'copies', 'preparations', 'lowerings', 'coverage'}
    assert data['mode'] == mode and data['sites'] == sites
    assert len(data['copies']) == 10 and len(data['preparations']) == 12
    assert len(data['lowerings']) == 10 and len(data['coverage']) == 23
    assert sorted(find_coordinates(data)) == sorted(coordinates[mode])
    for index, row in enumerate(data['copies']):
        assert row['site'] == 'captured_module' and sites[str(row['line'])] == row['site']
        assert row['before'][1]['actor_name'] == names[index]
        assert same(row['before'], row['after']), (mode, index, 'original mutation')
        assert row['shared_with_original'] == 0
        assert type(row['original_reference_count']) is int and row['original_reference_count'] > 0
        assert row['copy_reference_count'] == row['original_reference_count']
        if mode == 'pure' or options.trust_storable:
            assert same(row['before'], row['copy']), ('module-copy primitive-kind preservation', mode, index)
    for family in ('preparations', 'lowerings', 'coverage'):
        for row in data[family]:
            assert same(row['before'], row['after']), (mode, family, 'caller mutation')
    assert (BASE / (mode + '.status')).read_text().strip() == '0'
    receipt = (BASE / (mode + '.txt')).read_text()
    assert 'All tests successful.' in receipt and 'Files=1, Tests=5,' in receipt

expected = []
for index, (a, b, prior) in enumerate(zip(ordinary['copies'], pure['copies'], old)):
    assert same(a['before'], b['before'])
    assert same(a['before'], prior['before']) and same(a['copy'], prior['clone'])
    expected.append({'ordinal': index, 'actor': names[index], 'field_owner': owners[index],
                     'differences': walk_delta(a['before'], a['copy'])})
assert same(roster, expected), 'complete field-instance roster drift'
for family in ('preparations', 'lowerings', 'coverage'):
    for i, (a, b) in enumerate(zip(ordinary[family], pure[family])):
        if family != 'coverage':
            assert same(a['before'], b['before'])
        else:
            # Only the captured module operand can differ between modes. The
            # preparation and allocation inputs retain their complete graphs.
            assert same(a['before'][1][:2], b['before'][1][:2])
            assert all(row[0].startswith('/1/2/') for row in walk_delta(a['before'], b['before']))
        assert same(a['result'], b['result']), (family, i, 'whole result changed')
        if family == 'coverage':
            assert a['accepted'] == b['accepted'] == profile['api'][i]['accepted']
            assert same(a['result'], profile['api'][i]['result'])
            if not a['accepted']:
                assert a['error'].splitlines()[0] == b['error'].splitlines()[0] == profile['api'][i]['error'].splitlines()[0]

# Known-bad controls exercise the complete observed-roster contract; they do
# not pretend to falsify the separately owned field-meaning hypotheses.
bad = copy.deepcopy(roster); bad[0]['differences'].pop()
assert not same(bad, expected)
bad = copy.deepcopy(roster); bad[0]['field_owner'] = parent + '.4'
assert not same(bad, expected)
bad = copy.deepcopy(pure['copies'][0]['copy'])
bad[1]['actor_name'] = 'wrong_module'
assert not same(bad, pure['copies'][0]['copy'])
assert not same(ordinary['copies'][0]['copy'], pure['copies'][0]['copy'])
assert (BASE / 'trust-storable.status').read_text().strip() == '1'
assert (BASE / 'trust-storable.txt').read_text().splitlines()[-1] == "AssertionError: ('module-copy primitive-kind preservation', 'ordinary', 0)"
print('PASS immutable complete source/prior membership, exact current module captures and typed field-instance roster with per-family owners.')
print('PASS original/caller kind/topology/deep-isolation conservation, genuine pure module copies and complete preparation/lowering/carrier/scope result equality.')
print('PASS actual lossy module-copy kind counterfactual and roster omission/owner/identity corruptions reject.')
print('OPEN: generated/reusable/ATL field meanings, actor-only preparation propagation and snapshot assurance remain .3-.6/.4-owned; constructors/controllers/moved-root stay cold.')
