import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-source-copies-20261003')
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

def differences(left, right, path=''):
    if type(left) is not type(right):
        return [(path, left, right)]
    if isinstance(left, dict):
        assert left.keys() == right.keys(), ('key drift', path)
        return [delta for key in sorted(left) for delta in differences(left[key], right[key], path + '/' + key)]
    if isinstance(left, list):
        assert len(left) == len(right), ('length drift', path)
        return [delta for i, (a, b) in enumerate(zip(left, right)) for delta in differences(a, b, path + '/' + str(i))]
    assert left == right, ('value drift', path)
    return []

def authenticate(directory):
    manifest = json.loads((directory / 'manifest.json').read_text())
    assert {p.name for p in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, evidence in manifest.items():
        raw = (directory / name).read_bytes()
        assert len(raw) == evidence['bytes'] and hashlib.sha256(raw).hexdigest() == evidence['sha256'], name

authenticate(PROFILE)
if (BASE / 'manifest.json').exists():
    authenticate(BASE)
binding = json.loads((BASE / 'bindings.json').read_text())
revision = binding['revision']
members = {}
for entry in subprocess.check_output(['git', 'ls-tree', '-r', '-z', revision, '--', 'bin', 'perl', 't', 'scripts', 'isf']).split(b'\0'):
    if not entry:
        continue
    header, name = entry.split(b'\t', 1)
    members[name.decode()] = header.decode().split()[2]
assert members.keys() == binding['metadata'].keys()
with subprocess.Popen(['git', 'cat-file', '--batch'], stdin=subprocess.PIPE, stdout=subprocess.PIPE) as objects:
    for name, evidence in binding['metadata'].items():
        objects.stdin.write((members[name] + '\n').encode())
        objects.stdin.flush()
        header = objects.stdout.readline().decode().split()
        assert header == [members[name], 'blob', str(evidence['bytes'])], name
        raw = objects.stdout.read(evidence['bytes'])
        assert objects.stdout.read(1) == b'\n', name
        assert members[name] == evidence['blob']
        assert len(raw) == evidence['bytes'] and hashlib.sha256(raw).hexdigest() == evidence['sha256'], name
    objects.stdin.close()
    assert objects.wait() == 0
for name, source in binding['sources'].items():
    assert source.encode() == subprocess.check_output(['git', 'cat-file', 'blob', members[name]]), name

# Independent literal source facts establish the meanings of every changed
# actor field. These do not model the full parser or any controller behavior.
sources = binding['sources']
fifo = sources['isf/common/fifo.isf']
assert '(bank data (width 8) (depth 4))' in fifo
assert '(input data_in (width 8))' in fifo and '(output data_out (width 8))' in fifo
use = sources['isf/fifo_library_use.isf']
assert '(input data_in data_in)' in use and '(output data_out data_out)' in use
vector = sources['isf/atl_two_child_vector_data_pipeline.isf']
assert '(writer.payload reader.payload)' in vector
assert '(output payload (width 8))' in vector and '(input payload (width 8))' in vector
source_test = sources['t/1960-isf-formal-reservation-coverage.t']
source_lines = source_test.splitlines()
expected_sites = {}
for i, line in enumerate(source_lines, 1):
    if line == "    my $actor = ref($source) eq 'HASH' ? dclone($source)":
        expected_sites[str(i)] = 'authored_actor'
    if line == '    my $physical = dclone($p->{actor});':
        expected_sites[str(i)] = 'physical_actor'
assert len(expected_sites) == 2

ordinary = json.loads((BASE / 'ordinary.json').read_text())
pure = json.loads((BASE / 'pure.json').read_text())
profile = json.loads((PROFILE / 'initial-observations-unqualified.json').read_text())
coordinates = json.loads((BASE / 'coordinates.json').read_text())
def root_coordinates(value, path='', key=None):
    if isinstance(value, dict):
        return [p for name, child in value.items() for p in root_coordinates(child, path + '/' + name, name)]
    if isinstance(value, list):
        return [p for i, child in enumerate(value) for p in root_coordinates(child, path + '/' + str(i))]
    if isinstance(value, str) and '${REPO_ROOT}' in value:
        assert key == 'library_source' and value == '${REPO_ROOT}/isf/common/fifo.isf', path
        return [path]
    return []
for mode, data in (('ordinary', ordinary), ('pure', pure)):
    assert sorted(root_coordinates(data)) == sorted(coordinates[mode]), mode
old_actor_copies = [row for row in profile['clones'] if row['line'] in (29, 33)]
identities = [
    ('physical_actor', 'coverage'), ('physical_actor', 'coverage'),
    ('authored_actor', 'coverage'), ('physical_actor', 'coverage'),
    ('authored_actor', 'fifo_library_use'), ('physical_actor', 'fifo_library_use'),
    ('authored_actor', 'storage_fields'), ('physical_actor', 'storage_fields'),
    ('authored_actor', 'atl_resolved_child_pipeline'), ('physical_actor', 'atl_resolved_child_pipeline'),
    ('authored_actor', 'atl_two_child_vector_data_pipeline'), ('physical_actor', 'atl_two_child_vector_data_pipeline'),
    ('authored_actor', 'atl_two_child_trigger_batch_pipeline'), ('physical_actor', 'atl_two_child_trigger_batch_pipeline'),
    ('physical_actor', 'rule_coverage'), ('physical_actor', 'monitor_coverage'),
]

def actor_field_contract(graph, actor):
    assert graph[0] == 'hash'
    obj = graph[1]
    assert obj['actor_name'] == actor
    if actor == 'fifo_library_use':
        library = obj['library_uses'][1][0][1]
        assert library['library'] == 'common.fifo' and library['export'] == 'fifo'
        assert library['instance'] == 'u_fifo' and library['module'] == 'fifo_library_use__u_fifo'
        bank = library['actor'][1]['storage'][1][3][1]
        assert bank['name'] == 'data' and str(bank['width']) == '8' and str(bank['depth']) == '4'
        slots = bank['signals'][1]
        assert len(slots) == 4
        for i, slot in enumerate(slots):
            item = slot[1]
            assert item['name'] == 'data_' + str(i) and str(item['width']) == '8'
            assert type(item['index']) is int and item['index'] == i, ('numeric FIFO slot', i)
        bindings = library['bindings'][1]
        assert len(bindings) == 8
        for index, name, role in ((3, 'data_in', 'input'), (7, 'data_out', 'output')):
            port = bindings[index][1]
            assert port['library_name'] == name and port['parent_name'] == name and port['role'] == role
            assert type(port['width']) is int and port['width'] == 8, ('numeric FIFO binding', name)
    if actor == 'atl_two_child_vector_data_pipeline':
        routes = obj['actor_network'][1]['data_movements'][1]
        assert len(routes) == 1
        route = routes[0][1]
        assert route['kind'] == 'vector_actor_handoff' and route['drive'] == 'forward_payload'
        assert route['source_instance'] == 'reader' and route['source_endpoint'] == 'payload'
        assert route['sink_instance'] == 'writer' and route['sink_endpoint'] == 'payload'
        assert route['width_source'] == 'resolved_child_endpoint_exact_width'
        assert type(route['width']) is int and route['width'] == 8, 'numeric resolved route'

assert len(old_actor_copies) == len(identities)
ledger = []
for mode, data in (('ordinary', ordinary), ('pure', pure)):
    assert set(data) == {'mode', 'sites', 'copies', 'preparations', 'lowerings', 'coverage'}
    assert data['mode'] == mode and data['sites'] == expected_sites
    assert len(data['copies']) == len(identities)
    assert len(data['preparations']) == 12 and len(data['lowerings']) == 10 and len(data['coverage']) == 23
    for row, (site, actor) in zip(data['copies'], identities):
        assert set(row) == {'site', 'line', 'before', 'after', 'copy', 'original_reference_count', 'copy_reference_count', 'shared_with_original'}
        assert row['site'] == site and expected_sites[str(row['line'])] == site
        assert same(row['before'], row['after']), (mode, site, actor, 'caller mutation')
        assert row['shared_with_original'] == 0
        assert type(row['original_reference_count']) is int and row['original_reference_count'] > 0
        assert row['copy_reference_count'] == row['original_reference_count']
        if mode == 'pure':
            assert same(row['before'], row['copy']), (site, actor, 'pure kind drift')
            actor_field_contract(row['copy'], actor)
        elif options.trust_storable:
            actor_field_contract(row['copy'], actor)
    for family in ('preparations', 'lowerings', 'coverage'):
        for row in data[family]:
            assert same(row['before'], row['after']), (mode, family, 'actual caller drift')
    assert (BASE / (mode + '.status')).read_text().strip() == '0'
    receipt = (BASE / (mode + '.txt')).read_text()
    assert 'All tests successful.' in receipt and 'Files=1, Tests=5,' in receipt

for i, (row, old, counterpart, identity) in enumerate(zip(ordinary['copies'], old_actor_copies, pure['copies'], identities)):
    assert same(row['before'], old['before']) and same(row['copy'], old['clone']), ('original profile drift', i)
    delta = differences(row['before'], row['copy'])
    if delta:
        assert identity[0] == 'authored_actor'
        ledger.append({'actor': identity[1], 'site': identity[0], 'index': i, 'fields': delta})
    if identity[0] == 'authored_actor':
        assert same(row['before'], counterpart['before']), ('authored mode input drift', i)
        actor_field_contract(row['before'], identity[1])

assert [(r['actor'], len(r['fields'])) for r in ledger] == [('fifo_library_use', 6), ('atl_two_child_vector_data_pipeline', 1)]
for index, actor in ((4, 'fifo_library_use'), (10, 'atl_two_child_vector_data_pipeline')):
    try:
        actor_field_contract(ordinary['copies'][index]['copy'], actor)
    except AssertionError:
        pass
    else:
        raise AssertionError('actual Storable source authority escaped: ' + actor)
for i, (a, b) in enumerate(zip(ordinary['lowerings'], pure['lowerings'])):
    assert same(a['result'], b['result']), ('whole ordinary lowering result changed', i)
for i, (a, b, prior) in enumerate(zip(ordinary['coverage'], pure['coverage'], profile['api'])):
    assert a['accepted'] == b['accepted'] == prior['accepted']
    assert same(a['result'], b['result']) and same(a['result'], prior['result']), ('scope result drift', i)
    if not a['accepted']:
        assert a['error'].splitlines()[0] == b['error'].splitlines()[0] == prior['error'].splitlines()[0]

# Replay actual lossy copies as the competing source authority; they fail the
# independently named changed-field contracts. Also calibrate whole graph,
# primitive-kind and actual deep-isolation checks against corrupt retained data.
bad = copy.deepcopy(pure['copies'][4]['copy'])
bad[1]['library_uses'][1][0][1]['actor'][1]['storage'][1][3][1]['signals'][1][0][1]['index'] = '0'
try:
    actor_field_contract(bad, 'fifo_library_use')
except AssertionError:
    pass
else:
    raise AssertionError('kind-only corruption escaped')
bad = copy.deepcopy(pure['copies'][10]['copy'])
bad[1]['actor_network'][1]['data_movements'][1][0][1]['sink_instance'] = 'reader'
try:
    actor_field_contract(bad, 'atl_two_child_vector_data_pipeline')
except AssertionError:
    pass
else:
    raise AssertionError('route identity corruption escaped')
bad = copy.deepcopy(pure['copies'][0]['copy'])
bad[1]['actor_name'] = 'corrupt_actor'
assert not same(bad, pure['copies'][0]['copy'])
assert not same(ordinary['copies'][4]['copy'], pure['copies'][4]['copy'])
assert not same(ordinary['copies'][10]['copy'], pure['copies'][10]['copy'])
assert (BASE / 'trust-storable.status').read_text().strip() == '1'
assert (BASE / 'trust-storable.txt').read_text().splitlines()[-1] == "AssertionError: ('numeric FIFO slot', 0)"
print('PASS authenticated complete source actors and original profile; all authored/physical copy sites retained.')
print('PASS independent FIFO bank/binding and ATL route field contracts, genuine pure-copy preservation/deep isolation and exact ordinary lowering/carrier/scope results.')
print('PASS real Storable competing authority and retained kind/value/route corruptions reject.')
print('OPEN: preparation/internal module propagation semantics, snapshot/mutation seed assurance, full constructors/controllers and moved-root qualification remain owned successors.')
