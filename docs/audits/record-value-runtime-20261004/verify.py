"""Independent full stream, source-site, typed-delta and native-role reader."""
import argparse
import copy
import hashlib
import json
import re
import subprocess
from collections import Counter
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
for name in ('omit-helper', 'omit-copy', 'trust-copy-kinds', 'trust-synthetic-native'):
    parser.add_argument('--' + name, action='store_true')
args = parser.parse_args()
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == '40fe7eb00feadfde0388327796ca3bc2d1e0e55e'
assert len(binding['sources']) == 19
for path, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert raw.decode() == row['body'] and len(raw) == row['bytes']
    assert hashlib.sha256(raw).hexdigest() == row['sha256'], path
    if path != 'docs/knowledge/isf-aggregate-port-request-baseline.md':
        assert Path(path).read_bytes() == raw, 'selected current source drift: ' + path
if (BASE / 'card-after.txt').exists():
    assert Path('docs/knowledge/isf-aggregate-port-request-baseline.md').read_bytes() == (BASE / 'card-after.txt').read_bytes()
    card = binding['sources']['docs/knowledge/isf-aggregate-port-request-baseline.md']['body']
    for old, new in json.loads((BASE / 'card-changes.json').read_text()):
        assert card.count(old) == 1, old
        card = card.replace(old, new)
    assert card == (BASE / 'card-after.txt').read_text(), 'complete fact-preserving current-profile update'
data = json.loads((BASE / 'ordinary.json').read_text())
profile = json.loads((BASE / 'profile.json').read_text())
for name, row in profile['inputs'].items():
    raw = (BASE / name).read_bytes()
    assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
assert data['host'] == profile['host'] == {'perl': 'v5.34.1', 'storable': '3.23', 'json_pp': '4.06'}
expected_counts = {'api': 9283, 'copies': 697, 'helpers': 43, 'consumers': 125, 'parses': 4, 'warnings': 0}
assert {key: len(data[key]) for key in expected_counts} == profile['counts'] == expected_counts
assert dict(Counter(row['kind'] for row in data['api'])) == profile['api_kinds'] == {
    'scope': 40, 'reference': 68, 'copy': 22, 'capture': 227, 'snapshot': 220,
    'range': 437, 'structured-clone': 8251, 'identity': 14, 'payload': 4}
assert dict(Counter(row['kind'] for row in data['copies'])) == profile['copy_kinds'] == {
    'test': 17, 'metadata-private': 447, 'value-private': 233}
assert dict(Counter(row['kind'] for row in data['consumers'])) == profile['consumer_kinds'] == {
    'ok': 52, 'like': 44, 'unlike': 1, 'is': 24, 'is_deeply': 4}

def equal(left, right):
    if type(left) is not type(right):
        return False
    if isinstance(left, dict):
        return set(left) == set(right) and all(equal(left[k], right[k]) for k in left)
    if isinstance(left, list):
        return len(left) == len(right) and all(equal(a, b) for a, b in zip(left, right))
    return left == right

def walk_delta(left, right, path=''):
    if type(left) is not type(right) or not isinstance(left, (dict, list)):
        return [] if equal(left, right) else [{'path': path, 'before': left, 'after': right,
            'before_kind': type(left).__name__, 'after_kind': type(right).__name__}]
    assert (set(left) == set(right)) if isinstance(left, dict) else len(left) == len(right)
    keys = sorted(left) if isinstance(left, dict) else range(len(left))
    return [row for key in keys for row in walk_delta(left[key], right[key], path + '/' + str(key))]

def references(value, path='', seen=None):
    seen = {} if seen is None else seen
    if not isinstance(value, list):
        return seen
    assert len(value) == 2 and value[0] in ('hash', 'array', 'reference'), path
    kind, body = value
    if kind == 'reference':
        assert body in seen, 'native referent path must already have been observed'
        return seen
    assert path not in seen
    seen[path] = kind
    pairs = sorted(body.items()) if kind == 'hash' else enumerate(body)
    for key, child in pairs:
        escaped = str(key).replace('~', '~0').replace('/', '~1')
        references(child, path + '/' + escaped, seen)
    return seen

def cyclic(value, path=''):
    if not isinstance(value, list):
        return False
    kind, body = value
    if kind == 'reference':
        return path.startswith(body + '/')
    pairs = body.items() if kind == 'hash' else enumerate(body)
    return any(cyclic(child, path + '/' + str(key).replace('~', '~0').replace('/', '~1')) for key, child in pairs)

source = binding['sources']['t/1986-isf-record-port-value-gates.t']['body']
original = json.loads(Path('docs/audits/record-value-helper-contract-20261004/contracts.json').read_text())
assert source == original['sources']['t/1986-isf-record-port-value-gates.t']['body']
labels = [
    'copy independently enforces target role', 'whole input target', 'scalar input target',
    *[name + ' copy identity' for name in ('renamed', 'reordered', 'signed_data', 'four', 'two', 'bit_kind')],
    'explicit state-model difference', 'nested shape cannot be flattened for copy identity',
    'nested list item order retains type identity', 'packet', 'packet.body', 'packet.body.lanes',
    'packet.unknown', 'packet.body.lanes[2]', 'packet.body.count[3]', 'packet..count',
    'whole-value permission does not allow subaggregate writes', 'formal does not borrow an outer member',
    'scalar local cannot borrow an outer record', 'an unresolved type cannot erase a known input role',
    'equal/unequal scalar carrier is not a record copy',
    'record target cannot treat an expression as a same-type root', 'root list is not a same-type record copy',
    'unknown key', 'bad root width', 'bad scalar signed', 'missing signed', 'aggregate signed',
    'aggregate state', 'bad state', 'duplicate order', 'unlisted member', 'cyclic member', 'deferred kind',
    'unknown role', 'unknown scope argument', 'nonbinary whole-value permission',
    'contradictory copy descriptor', 'output frame source', 'input lanes source']
helpers = data['helpers'][:-1] if args.omit_helper else data['helpers']
assert [row['label'] for row in helpers] == labels, 'complete actual helper/source-loop membership'
for index, row in enumerate(helpers):
    assert row['caller'][0:2] == ['main', './t/1986-isf-record-port-value-gates.t']
    assert row['consumer_end'] - row['consumer_start'] == 2
    consumers = data['consumers'][row['consumer_start']:row['consumer_end']]
    assert [c['kind'] for c in consumers] == ['ok', 'like']
    assert [c['helper'] for c in consumers] == [index, index]
    assert [c['caller'][2] for c in consumers] == [89, 90]
    assert all(c['passed'] == 1 for c in consumers)
    failed = [a for a in data['api'][row['api_start']:row['api_end']]
        if a['kind'] in ('scope', 'reference', 'copy') and not a['accepted']]
    if index < 41:
        assert len(failed) == 1 and failed[0]['helper'] == index
        assert consumers[1]['actual'] == failed[0]['primary'] == failed[0]['error'].split('\n')[0]
    else:
        parses = data['parses'][row['parse_start']:row['parse_end']]
        assert len(parses) == 1 and parses[0]['accepted'] == 0
        assert consumers[1]['actual'] == parses[0]['primary'] == parses[0]['error'].split('\n')[0]

copies = data['copies'][:-1] if args.omit_copy else data['copies']
sites = Counter((r['kind'], r['caller'][1], r['caller'][2]) for r in copies)
assert sites == Counter({
    ('test', './t/1986-isf-record-port-value-gates.t', 59): 1,
    ('test', './t/1986-isf-record-port-value-gates.t', 122): 1,
    ('test', './t/1986-isf-record-port-value-gates.t', 146): 1,
    ('test', './t/1986-isf-record-port-value-gates.t', 223): 1,
    ('test', './t/1986-isf-record-port-value-gates.t', 233): 1,
    ('test', './t/1986-isf-record-port-value-gates.t', 261): 1,
    ('test', './t/1986-isf-record-port-value-gates.t', 265): 11,
    ('metadata-private', 'perl/FSM/Support/ISFInterfacePortMetadata.pm', 40): 227,
    ('metadata-private', 'perl/FSM/Support/ISFInterfacePortMetadata.pm', 142): 220,
    ('value-private', 'perl/FSM/Support/ISFRecordPortValues.pm', 29): 127,
    ('value-private', 'perl/FSM/Support/ISFRecordPortValues.pm', 60): 65,
    ('value-private', 'perl/FSM/Support/ISFRecordPortValues.pm', 101): 20,
    ('value-private', 'perl/FSM/Support/ISFRecordPortValues.pm', 102): 21}), 'complete actual native copy sites'
for row in copies:
    assert row['accepted'] == 1 and row['error'] == '' and row['shared_with_original'] == 0
    assert equal(row['before'], row['after']), 'copy must preserve caller graph/kinds'
    assert len(references(row['before'])) == row['original_reference_count']
    assert len(references(row['copy'])) == row['copy_reference_count']
    assert row['original_reference_count'] == row['copy_reference_count']
    path = row['caller'][1].removeprefix('./')
    assert 'dclone(' in binding['sources'][path]['body'].splitlines()[row['caller'][2] - 1]
test_copies = [row for row in copies if row['kind'] == 'test']
if args.trust_copy_kinds:
    assert all(equal(row['before'], row['copy']) for row in test_copies), \
        'actual Storable test-copy width-kind losses cannot be promoted to kind-preserving copies'
api_changes = [{'index': i, 'kind': row['kind'], 'caller': row['caller'],
    'changes': walk_delta(row['before'], row['after'])} for i, row in enumerate(data['api'])
    if not equal(row['before'], row['after'])]
copy_changes = [{'index': i, 'kind': row['kind'], 'caller': row['caller'],
    'changes': walk_delta(row['before'], row['copy'])} for i, row in enumerate(data['copies'])
    if not equal(row['before'], row['copy'])]
assert equal(api_changes, profile['api_argument_changes'])
assert equal(copy_changes, profile['copy_changes'])
assert all(not row['warnings'] for row in data['api']) and data['warnings'] == []
for api_index, row in enumerate(data['api']):
    references(row['before']); references(row['after'])
    if row['accepted']:
        assert row['error'] == row['primary'] == ''
        references(row['result'])
    else:
        assert row['result'] is None and row['primary'] == row['error'].split('\n')[0]
    if row['helper'] is not None:
        owner = data['helpers'][row['helper']]
        assert owner['api_start'] <= api_index < owner['api_end']
assert [(p['caller'][2], p['accepted']) for p in data['parses']] == [(17, 1), (244, 1), (293, 0), (293, 0)]
for row in data['parses']:
    assert equal(row['before'], row['after'])
    references(row['before']); references(row['result'])
cycle_index = labels.index('cyclic member')
cycles = [row for row in copies if row['helper'] == cycle_index and cyclic(row['before'])]
assert [(row['kind'], row['caller'][2]) for row in cycles] == [('value-private', 29), ('metadata-private', 40)]
assert all(cyclic(row['copy']) for row in cycles), 'actual native cyclic candidate/copies'
assert 'cyclic resolved type' in data['consumers'][helpers[cycle_index]['consumer_end'] - 1]['actual']
synthetic = [row for row in data['consumers'] if row['label'] == 'known bad full trace contains the caller pattern']
assert len(synthetic) == 1 and synthetic[0]['helper'] is None and synthetic[0]['kind'] == 'like'
if args.trust_synthetic_native:
    assert synthetic[0]['helper'] is not None, 'artificial stack check is not a genuine native helper producer'
tap = (BASE / 'ordinary.txt').read_text()
leaf = re.findall(r'^    (not )?ok \d+ - (.*)$', tap, re.M)
assert len(leaf) == 125 and all(not status for status, _ in leaf)
assert [label for _, label in leaf] == [row['label'] for row in data['consumers']]
assert all(row['passed'] == 1 for row in data['consumers'])
assert (BASE / 'ordinary.status').read_text() == '0\n'
print('PASS complete original T1986 native profile: 9283 selected APIs (recursive clone/range included), '
    '697 copies, 43 real helper callbacks, 125 leaf consumers, four parser operations and no warnings. '
    'Whole sources/graphs/native errors/actual cycle bind; actual copy-kind changes are retained, '
    'not erased or promoted to safety. Intended causes/source-field-products and genuine assurance '
    'controls remain successor-owned.')
