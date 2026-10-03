"""Independent whole-source, native stream and actual contextual controls reader."""
import argparse
import collections
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--trust-location', action='store_true')
parser.add_argument('--trust-primary-fragment', action='store_true')
parser.add_argument('--omit-copy', action='store_true')
args = parser.parse_args()
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
binding = json.loads((BASE / 'binding.json').read_text())
contract = json.loads(Path('docs/audits/interface-metadata-helper-contract-20261003/contracts.json').read_text())
for name, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + name])
    assert raw.decode() == row['body'] and len(raw) == row['bytes']
    assert hashlib.sha256(raw).hexdigest() == row['sha256']
    if name in contract['sources']: assert row['body'] == contract['sources'][name]['body']
source = binding['sources']['t/1983-isf-interface-port-metadata.t']['body']
record_values = binding['sources']['perl/FSM/Support/ISFRecordPortValues.pm']['body']
assert 'capture_interface_port_metadata({inputs =>' in record_values
assert "use FSM::Support::ISFInterfacePortMetadata qw(capture_interface_port_metadata);" in record_values
data = json.loads((BASE / 'ordinary.json').read_text())
expected = json.loads((BASE / 'expected-causes.json').read_text())
assert len(data['helpers']) == len(expected['snapshot']) + len(expected['capture']) == 44
assert len(data['api']) == 105 and len(data['consumers']) == 166 and len(data['parses']) == 3
assert collections.Counter((r['kind'], r['accepted']) for r in data['api']) == {
    ('capture', 1): 28, ('capture', 0): 14, ('snapshot', 1): 31, ('snapshot', 0): 32}
assert collections.Counter(r['kind'] for r in data['consumers']) == {
    'ok': 47, 'like': 47, 'is': 11, 'is_deeply': 61}
assert all(r['passed'] for r in data['consumers'])
assert len(re.findall(r'^    ok \d+ ', (BASE / 'ordinary.txt').read_text(), re.M)) == len(data['consumers'])
assert binding['membership']['helper_labels'] == [r['label'] for r in data['helpers']]
assert binding['membership']['api_callers'] == [r['caller'] for r in data['api']]
assert binding['membership']['copy_callers'] == [r['caller'] for r in data['copies']]
assert binding['membership']['consumer_labels'] == [r['label'] for r in data['consumers']]
assert all(r['before'] == r['after'] and r['warnings'] == [] for r in data['api'])
assert all(r['before'] == r['after'] for r in data['parses'])
offset = 0
for kind in ('snapshot', 'capture'):
    for ordinal, cause in enumerate(expected[kind]):
        index = offset + ordinal
        helper = data['helpers'][index]
        assert helper['label'] == (f'malformed snapshot {ordinal}' if kind == 'snapshot' else 'invalid producer input')
        calls = data['api'][helper['api_start']:helper['api_end']]
        assert len(calls) == 1 and calls[0]['kind'] == kind and calls[0]['helper'] == index
        assert not calls[0]['accepted'] and calls[0]['error'].splitlines()[0] == 'Invalid ISF interface port metadata: ' + cause
        consumers = data['consumers'][helper['consumer_start']:helper['consumer_end']]
        assert [r['kind'] for r in consumers] == ['ok', 'like', 'is_deeply']
        assert all(r['helper'] == index for r in consumers)
        assert consumers[1]['actual'] == calls[0]['error'] and consumers[2]['actual'] == ['array', []]
        if kind == 'snapshot': assert helper['supplied_value'] == calls[0]['before'][1][0]
    offset += len(expected[kind])
adjacent = [r for r in data['consumers'] if r['kind'] == 'like' and r['helper'] is None]
assert len(adjacent) == 3
assert [r['actual'].splitlines()[0] for r in adjacent[:2]] == expected['adjacent'][:2]
assert expected['adjacent'][2] in adjacent[2]['actual'].splitlines()[0]
copies = data['copies'][:-1] if args.omit_copy else data['copies']
test_copies = [r for r in copies if r['kind'] == 'test']
provider_copies = [r for r in copies if r['kind'] == 'provider']
assert len(test_copies) == 43 and len(provider_copies) == 102, 'complete native copy population'
snapshot_mutations = source[source.index('    for my $change ('):source.index('    push @bad, [{name')]
producer_start = source.index("subtest 'producer rejects")
producer_mutations = source[source.index('    for my $change (', producer_start):source.index('    my $cycle =')]
assert snapshot_mutations.count('sub {') == 25 and producer_mutations.count('sub {') == 10
assert collections.Counter(r['caller'][2] for r in test_copies) == {
    41: 1, 47: 1, 91: 2, 99: 2, 116: 1, 184: 1, 186: 25, 212: 10}
assert set(r['caller'][2] for r in test_copies) == {r['line'] for r in contract['copies']}
for r in copies:
    assert r['before'] == r['after'] and r['shared_with_original'] == 0
    assert r['original_reference_count'] == r['copy_reference_count'] > 0
def first_argument_graph(node):
    # The saved API graph is rooted at the argument array; its first input
    # referents use /0. A private copy is rooted at that input itself.
    # Preserve complete scalar kinds, topology and all original captures.
    if not isinstance(node, list): return node
    kind, body = node
    if kind == 'reference':
        assert body == '/0' or body.startswith('/0/')
        return [kind, body[2:]]
    if kind == 'hash': return [kind, {k: first_argument_graph(v) for k, v in body.items()}]
    assert kind == 'array'
    return [kind, [first_argument_graph(v) for v in body]]

for index, api in enumerate(data['api']):
    selected = [r for r in provider_copies if r['api'] == index]
    first = api['before'][1][0]
    has_copy = first is not None and first[0] == ('hash' if api['kind'] == 'capture' else 'array')
    assert len(selected) == int(has_copy), 'every private copy joins its actual API invocation'
    if has_copy:
        assert selected[0]['before'] == first_argument_graph(first) and selected[0]['caller'][2] == (40 if api['kind'] == 'capture' else 142)
assert all(r['api'] is None for r in test_copies)
assert sum(r['caller'][0] == 'FSM::Support::ISFRecordPortValues' for r in data['api']) == 17
assert sum(r['caller'][0] == 'FSM::Adapter::ISF::Parser' for r in data['api']) == 2
controls = json.loads((BASE / 'controls.json').read_text())
assert controls['helper'] == contract['helper'] and controls['loaded_module'] == 'perl/FSM/Support/ISFInterfacePortMetadata.pm'
assert [r['consumer']['matched'] for r in controls['rows']] == [1, 0, 0, 0]
assert all(not r['native']['accepted'] and r['native']['error'] == r['consumer']['error'] for r in controls['rows'])
assert all(r['native']['error'].startswith("Can't store CODE items at ") for r in controls['rows'][1:])
projection = json.loads((BASE / 'primary-location-binding.json').read_text())
raw = binding['sources'][projection['original']]['body'].encode()
assert len(raw) == projection['bytes'] and hashlib.sha256(raw).hexdigest() == projection['sha256']
location = json.loads((BASE / 'primary-location.json').read_text())
assert location['helper'] == contract['helper'] and location['loaded_module'] == projection['projection']
row = location['rows'][0]
assert not row['native']['accepted'] and row['consumer']['matched'] == 1
assert row['native']['error'] == row['consumer']['error']
assert row['native']['error'].startswith("Can't store CODE items at " + projection['projection'])
classified = row['consumer']['first_line_classified']
if args.trust_location: classified = row['consumer']['matched']
assert classified == 0, 'native location echo cannot establish metadata primary context'
adjacent_controls = json.loads((BASE / 'adjacent-controls.json').read_text())
assert adjacent_controls['consumer'] in source
assert [r['consumer']['matched'] for r in adjacent_controls['rows']] == [1, 0, 1]
assert all(not r['accepted'] and r['saved_error'] == r['consumer']['error'] for r in adjacent_controls['rows'])
assert adjacent_controls['rows'][0]['saved_error'].splitlines()[0] == adjacent[2]['actual'].splitlines()[0]
echo = adjacent_controls['rows'][2]
assert echo['saved_error'].splitlines()[0] == "Error: no (actor ...) root found in '" + echo['filename'] + "'"
safe = echo['saved_error'].splitlines()[0] == adjacent[2]['actual'].splitlines()[0]
if args.trust_primary_fragment: safe = bool(echo['consumer']['matched'])
assert not safe, 'actual filename phrase cannot establish complete output-writer cause'
for name, status in {'baseline': 0, 'ordinary': 0, 'controls': 3, 'primary-location': 0, 'adjacent-controls': 1}.items():
    assert int((BASE / (name + '.status')).read_text()) == status
assert 'Files=1, Tests=7' in (BASE / 'baseline.txt').read_text() and 'Result: PASS' in (BASE / 'baseline.txt').read_text()
print('PASS complete native helper/adjacent/API/private/test-copy/assertion populations and independent ordinary causes bind immutable source; actual Storable location and parser primary-filename echoes expose two owned contextual false positives. Field/copy semantics remain .3-owned before .5 repairs and .4 join.')
