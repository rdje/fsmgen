"""Independent authored type/source/layout reader, prior to copy-field joins."""
import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
for option in ('omit-type', 'swap-order', 'trust-private-product'):
    parser.add_argument('--' + option, action='store_true')
args = parser.parse_args()
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == '90e196e8ad1ef1392e4275d40d5768724074eb55'
assert len(binding['sources']) == 19
for path, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert raw.decode() == row['body'] and len(raw) == row['bytes']
    assert hashlib.sha256(raw).hexdigest() == row['sha256'], path
    if path != 'docs/knowledge/isf-aggregate-port-request-baseline.md':
        assert raw == Path(path).read_bytes(), 'current selected source drift: ' + path
if (BASE / 'card-after.txt').exists():
    card = binding['sources']['docs/knowledge/isf-aggregate-port-request-baseline.md']['body']
    for old, new in json.loads((BASE / 'card-changes.json').read_text()):
        assert card.count(old) == 1, old
        card = card.replace(old, new)
    assert card == (BASE / 'card-after.txt').read_text()
    assert Path('docs/knowledge/isf-aggregate-port-request-baseline.md').read_text() == card
# The native profile is immutable dated evidence. Its document watcher captures
# the prior card; this exact superseding card update changes no native producer.
prior_base = Path('docs/audits/record-value-runtime-20261004')
prior_manifest = json.loads((prior_base / 'manifest.json').read_text())
assert {p.name for p in prior_base.iterdir()} == set(prior_manifest) | {'manifest.json'}
for name, row in prior_manifest.items():
    raw = (prior_base / name).read_bytes()
    assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name

def equal(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return set(a) == set(b) and all(equal(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(equal(x, y) for x, y in zip(a, b))
    return a == b

def plain(value):
    if not isinstance(value, list):
        return value
    kind, body = value
    assert kind in ('hash', 'array'), 'selected complete type products must not hide references'
    return {k: plain(v) for k, v in body.items()} if kind == 'hash' else [plain(v) for v in body]

def layout(spec, path='', base=0):
    assert type(spec['width']) is int and spec['width'] > 0
    assert type(spec['signed']) is int and spec['signed'] in (0, 1)
    if spec['kind'] in ('bit', 'bits'):
        assert set(spec) in ({'kind', 'width', 'signed'}, {'kind', 'width', 'signed', 'state_model'})
        if spec['kind'] == 'bit':
            assert spec['width'] == 1
        if 'state_model' in spec:
            assert spec['state_model'] in ('two_state', 'four_state')
        return [[path, spec['width'], base, base + spec['width'] - 1,
            spec['signed'], spec.get('state_model'), spec['kind']]]
    assert spec['kind'] in ('record', 'list') and spec['signed'] == 0
    if spec['kind'] == 'record':
        assert set(spec) == {'kind', 'width', 'signed', 'members', 'member_order'}
        names = spec['member_order']
        assert len(names) == len(set(names)) and set(names) == set(spec['members'])
        children = [(path + ('.' if path else '') + name, spec['members'][name]) for name in names]
    else:
        assert set(spec) == {'kind', 'width', 'signed', 'items'}
        children = [(path + '[' + str(i) + ']', child) for i, child in enumerate(spec['items'])]
    assert sum(child['width'] for _, child in children) == spec['width']
    cursor = base + spec['width']
    result = []
    for child_path, child in children:
        cursor -= child['width']
        result.extend(layout(child, child_path, cursor))
    assert cursor == base
    return result

models = json.loads((BASE / 'authored-models.json').read_text())
types = copy.deepcopy(models['types'])
if args.omit_type:
    del types['bit_kind']
if args.swap_order:
    types['nested']['members']['body']['member_order'].reverse()
assert set(types) == {'frame', 'alias', 'renamed', 'reordered', 'signed_data', 'four',
    'two', 'bit_kind', 'nested', 'flat', 'lanes'}, 'complete authored local type membership'
native = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
local = plain(native['parses'][0]['result'])
imported = plain(native['parses'][1]['result'])
assert equal(local['type_symbols'], {'local': types, 'packages': {}}), 'complete original authored recursive identities/kinds'
assert equal(imported['type_symbols'], {'local': {}, 'packages': {'shared': {'frame': models['imported']['shared.frame']}}})
assert equal(types['frame'], types['alias']) and equal(types['frame'], models['imported']['shared.frame'])
for name, spec in types.items():
    assert equal(layout(spec), models['layouts'][name]), 'independent ordered packed range/property model: ' + name
assert equal(models['scalar'], {'kind': 'bits', 'width': 7, 'signed': 0})
source = binding['sources']['t/1986-isf-record-port-value-gates.t']['body']
assert '(type alias frame)' in source and '(type bit_kind (record (flag (bits 1)) (data (bits 7))))' in source
assert '(body (record (count (signed (four_state (bits 3))))' in source
assert '(lanes (list (two_state bit) (bits 2)))' in source
assert '(?pkg:shared (+types (type frame (record (flag bit) (data (bits 7))))))' in source
storage_names = list('abcdefghijk')
storage_types = ['frame', 'alias', 'renamed', 'reordered', 'signed_data', 'four', 'two', 'bit_kind', 'nested', 'flat', 'lanes']
assert [(row['name'], row['type']) for row in local['storage']] == list(zip(storage_names, storage_types))
for row in local['storage']:
    assert equal(row['type_spec'], types[row['type']])
    assert equal(row['signals'][0]['type_spec'], types[row['type']])
    assert type(row['width']) is int and row['width'] == types[row['type']]['width']
assert equal(imported['storage'][0]['type_spec'], models['imported']['shared.frame'])
private = next(row for row in native['copies'] if row['kind'] == 'test' and row['caller'][2] == 146)
assert equal(plain(private['before']), types['nested'])
if args.trust_private_product:
    assert equal(plain(private['copy']), types['nested']), 'actual kind-changing fixture copy cannot be final numeric type authority'
print('PASS complete authored local11/imported frame/scalar recursive type identities, '
    'member/list order, signed/state presence and independently packed leaf layouts match '
    'whole original parser type/storage products with strict primitive kinds. Whole actor/API '
    'products and all-copy source/private-field joins remain separately owned.')
