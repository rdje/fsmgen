"""Independent source width/layout/numeric projection and full native model."""
import argparse
import collections
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--omit-field', action='store_true')
parser.add_argument('--wrong-order', action='store_true')
parser.add_argument('--private-as-product', action='store_true')
args = parser.parse_args()
subprocess.run(['python3', '-B', 'docs/audits/interface-metadata-runtime-20261004/verify.py'], check=True)
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
facts = json.loads((BASE / 'fields.json').read_text())
data = json.loads((BASE / 'ordinary.json').read_text())
original = json.loads(Path('docs/audits/interface-metadata-runtime-20261004/ordinary.json').read_text())
for name, row in facts['sources'].items():
    raw = subprocess.check_output(['git', 'show', facts['revision'] + ':' + name])
    assert raw.decode() == row['body'] and len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
source = facts['sources']['t/1983-isf-interface-port-metadata.t']['body']
assert '(subtype (bits 4))' in source and '(count (signed (four_state (bits 3))))' in source
assert '(lanes (list (two_state bit) (bits 2)))' in source
assert "(type packet_t (record (code (bits 2)) (flag bit)))" in source

def unpack(node):
    if not isinstance(node, list): return node
    kind, body = node
    assert kind in ('hash', 'array'), 'only finite acyclic ordinary source models'
    return {k: unpack(v) for k, v in body.items()} if kind == 'hash' else [unpack(v) for v in body]

def numeric(value):
    assert type(value) in (int, str) and re.fullmatch(r'0|[1-9][0-9]*', str(value))
    return int(value)

def typed_equal(a, b):
    if type(a) is not type(b): return False
    if isinstance(a, dict): return a.keys() == b.keys() and all(typed_equal(a[k], b[k]) for k in a)
    if isinstance(a, list): return len(a) == len(b) and all(typed_equal(x, y) for x, y in zip(a, b))
    return a == b

# These complete source models are authored from the literal declarations,
# never copied from native products or the projection helper.
def bits(width, signed=0, state=None, kind='bits'):
    result = {'kind': kind, 'width': width, 'signed': signed}
    if state is not None: result['state_model'] = state
    return result

def record(order, members):
    return {'kind': 'record', 'signed': 0, 'width': sum(members[k]['width'] for k in order),
        'member_order': order, 'members': members}

lanes = {'kind': 'list', 'signed': 0, 'width': 3,
    'items': [bits(1, state='two_state', kind='bit'), bits(2)]}
payload = record(['count', 'lanes'], {'count': bits(3, signed=1, state='four_state'), 'lanes': lanes})
frame = record(['subtype', 'payload'], {'subtype': bits(4), 'payload': payload})
packet = record(['code', 'flag'], {'code': bits(2), 'flag': bits(1, kind='bit')})
single = record(['flag'], {'flag': bits(1, kind='bit')})
assert frame['width'] == 10 and packet['width'] == 3

def canonical_type(node):
    result = {}
    for name, value in node.items():
        if name in ('width', 'signed'): result[name] = numeric(value)
        elif isinstance(value, dict): result[name] = canonical_type(value)
        elif isinstance(value, list): result[name] = [canonical_type(v) if isinstance(v, dict) else v for v in value]
        else: result[name] = value
    return result

def layout(spec):
    leaves = []
    pending = [('', spec)]
    while pending:
        path, node = pending.pop(0)
        kind = node['kind']
        if kind == 'record':
            pending[0:0] = [(path + ('.' if path else '') + name, node['members'][name]) for name in node['member_order']]
        elif kind == 'list':
            pending[0:0] = [(path + '[' + str(i) + ']', child) for i, child in enumerate(node['items'])]
        else:
            assert kind in ('bit', 'bits') and (kind != 'bit' or numeric(node['width']) == 1)
            leaves.append((path, node))
    widths = [numeric(v['width']) for _, v in leaves]
    assert sum(widths) == numeric(spec['width'])
    result = []
    for index, (path, node) in enumerate(leaves):
        # Derive each interval from the suffix sum of authored leaf widths.
        low = sum(widths[index + 1:]); width = widths[index]
        field = {'path': path, 'width': width, 'lsb': low, 'msb': low + width - 1,
            'signed': numeric(node.get('signed', 0))}
        if 'state_model' in node: field['state_model'] = node['state_model']
        result.append(field)
    return result

expected_fields = [
    {'path': 'subtype', 'width': 4, 'lsb': 6, 'msb': 9, 'signed': 0},
    {'path': 'payload.count', 'width': 3, 'lsb': 3, 'msb': 5, 'signed': 1, 'state_model': 'four_state'},
    {'path': 'payload.lanes[0]', 'width': 1, 'lsb': 2, 'msb': 2, 'signed': 0, 'state_model': 'two_state'},
    {'path': 'payload.lanes[1]', 'width': 2, 'lsb': 0, 'msb': 1, 'signed': 0},
]
if args.wrong_order: frame['member_order'] = list(reversed(frame['member_order']))
assert typed_equal(layout(frame), expected_fields), 'authored packed leaf order and ranges'

def capture_model(inputs):
    interface = inputs[0]
    if interface is None: return None
    result = []
    for plural, direction in (('inputs', 'input'), ('outputs', 'output')):
        for port in interface[plural]:
            entry = {'name': port['name'], 'direction': direction, 'width': numeric(port['width'])}
            domain = port.get('domain', inputs[1] if len(inputs) > 1 else None)
            if domain is not None: entry['domain'] = domain
            if 'type' in port:
                spec = canonical_type(port['type_spec'])
                assert any(typed_equal(spec, known) for known in (bits(8), bits(1), frame, packet, single)), 'complete source type model'
                assert entry['width'] == spec['width']
                entry.update(type=port['type'], type_kind=spec['kind'])
                if spec['kind'] == 'record': entry['fields'] = layout(spec)
            result.append(entry)
    return result

def snapshot_model(value):
    if value is None: return None
    result = copy.deepcopy(value)
    for port in result:
        port['width'] = numeric(port['width'])
        for field in port.get('fields', []):
            for name in ('width', 'lsb', 'msb', 'signed'): field[name] = numeric(field[name])
    return result

modeled = {}
for index, api in enumerate(data['api']):
    assert all(typed_equal(api[k], original['api'][index][k]) for k in ('before', 'after', 'result'))
    assert api['before'] == api['after'] and api['warnings'] == []
    assert api['error'].splitlines()[:1] == original['api'][index]['error'].splitlines()[:1]
    if not api['accepted']: continue
    inputs = unpack(api['before'])
    expected = capture_model(inputs) if api['kind'] == 'capture' else snapshot_model(inputs[0])
    if api['kind'] == 'snapshot' and api['caller'][0] == 'FSM::Support::ISFInterfacePortMetadata':
        assert data['api'][index - 1]['kind'] == 'capture' and index - 1 in modeled
        assert typed_equal(expected, modeled[index - 1]), 'nested private snapshot joins original declaration model'
    actual = unpack(api['result'])
    if args.private_as_product and index == 1:
        actual = unpack(next(r['copy'] for r in data['copies'] if r['kind'] == 'provider' and r['api'] == index))
    assert typed_equal(actual, expected), 'private copied kinds cannot replace final numeric metadata product'
    modeled[index] = expected
assert len(modeled) == 59
assert sum(v is None for v in modeled.values()) == 2 and sum(v == [] for v in modeled.values()) == 3

actor = unpack(data['parses'][0]['result']); imported = unpack(data['parses'][2]['result'])
assert actor['actor_name'] == 'port_metadata' and imported['actor_name'] == 'imported'
actor_interface = {
    'inputs': [{'name': 'start', 'width': 1},
        {'name': 'data', 'width': 8, 'type': 'byte', 'type_spec': bits(8)}],
    'outputs': [{'name': 'unused', 'width': '2'}, {'name': 'done', 'width': 1}],
}
imported_interface = {
    'inputs': [{'name': 'data', 'width': 8, 'type': 'shared.byte', 'type_spec': bits(8)}],
    'outputs': [{'name': 'done', 'width': 1}],
}
assert typed_equal(actor['interface'], actor_interface) and typed_equal(imported['interface'], imported_interface)
assert typed_equal(actor['type_symbols'], {'local': {'byte': bits(8), 'frame_t': frame}, 'packages': {}})
assert typed_equal(imported['type_symbols'], {'local': {}, 'packages': {'shared': {'byte': bits(8), 'packet_t': packet}}})
for actual, name, spec in ((actor, 'frame', frame), (imported, 'packet', packet)):
    storage = actual['storage'][0]
    assert storage['name'] == name and storage['kind'] == 'var'
    assert typed_equal(storage['type_spec'], spec) and typed_equal(storage['signals'][0]['type_spec'], spec)
    assert storage['width'] == spec['width'] == storage['signals'][0]['width']
assert actor['interface']['outputs'][0] == {'name': 'unused', 'width': '2'}
assert [p['name'] for p in actor['interface']['inputs']] == ['start', 'data']
assert imported['interface']['inputs'][0]['type'] == 'shared.byte'
assert typed_equal(actor['interface_port_metadata'], capture_model([actor['interface']]))
assert typed_equal(imported['interface_port_metadata'], capture_model([imported['interface']]))
docs = data['parses'][2]
assert docs['documents_before'] == docs['documents_after'] and len(docs['documents_before']) == 2
expected_documents = {
    'shared.fsm': '(?pkg:shared (+types (type byte (bits 8)) (type packet_t (record (code (bits 2)) (flag bit)))))',
    'imported.isf': '(actor imported (imports (package shared)) (clock clk) (reset rst) (interface (input data (type shared.byte)) (output done)) (storage (var packet (type shared.packet_t))) (transaction main (complete done)))',
}
assert {Path(k).name: v for k, v in docs['documents_before'].items()} == expected_documents
assert all(k.startswith('${REPO_ROOT}/.artifacts/tmp/tests/') for k in docs['documents_before'])

def differences(left, right, path=''):
    if type(left) is not type(right): return [(path, type(left).__name__, left, type(right).__name__, right)]
    if isinstance(left, list):
        assert len(left) == len(right)
        return [r for i, (a, b) in enumerate(zip(left, right)) for r in differences(a, b, path + '/' + str(i))]
    if isinstance(left, dict):
        assert left.keys() == right.keys()
        return [r for k in left for r in differences(left[k], right[k], path + '/' + k.replace('~', '~0').replace('/', '~1'))]
    return [] if left == right else [(path, type(left).__name__, left, type(right).__name__, right)]

rows = facts['rows'][:-1] if args.omit_field else facts['rows']
derived = []
unchanged = []
for ordinal, copied in enumerate(data['copies']):
    assert copied == original['copies'][ordinal] and copied['before'] == copied['after']
    deltas = differences(copied['before'], copied['copy'])
    if not deltas: unchanged.append(ordinal)
    for path, before_kind, before_value, after_kind, after_value in deltas:
        # The typed graph inserts /1 between a container tag and its content;
        # project those syntax coordinates to the original value's field path.
        parts = path.split('/')[1:]; semantic = []; node = copied['before']; cursor = 0
        while cursor < len(parts):
            assert isinstance(node, list) and parts[cursor] == '1'
            tag, body = node; key = parts[cursor + 1]; semantic.append(key)
            node = body[key.replace('~1', '/').replace('~0', '~')] if tag == 'hash' else body[int(key)]
            cursor += 2
        semantic_path = '/' + '/'.join(semantic)
        assert semantic_path.endswith('/width') and before_kind == 'int' and after_kind == 'str'
        assert before_value == numeric(after_value) > 0
        if copied['kind'] == 'test':
            leaf = semantic_path.removesuffix('/width')
            expected_width = 4 if leaf.endswith('/subtype') else 3 if leaf.endswith('/count') else 1 if leaf.endswith('/items/0') else 2 if leaf.endswith('/items/1') else None
            assert before_value == expected_width, 'authored frame leaf source width'
        else:
            api = data['api'][copied['api']]
            assert api['accepted'] and copied['api'] in modeled
            if api['kind'] == 'snapshot':
                port_index = int(semantic_path.split('/')[1])
                assert before_value == modeled[copied['api']][port_index]['width']
            else:
                assert before_value in (1, 2, 3, 4) and api['caller'][2] in (117, 146)
                assert typed_equal(canonical_type(unpack(copied['before'])['inputs'][0]['type_spec']), frame if api['caller'][2] == 117 else packet)
        derived.append({'copy': ordinal, 'kind': copied['kind'], 'line': copied['caller'][2], 'api': copied['api'],
            'path': semantic_path, 'original': {'kind': before_kind, 'value': before_value},
            'copied': {'kind': after_kind, 'value': after_value},
            'role': 'test source/baseline fixture' if copied['kind'] == 'test' else 'private numeric validation input'})
assert derived == rows and unchanged == facts['unchanged_copy_ordinals'], 'complete original width field and unchanged-control membership'
assert len(rows) == 94 and len(unchanged) == 113 and len({r['copy'] for r in rows}) == 32
assert collections.Counter(r['kind'] for r in rows) == {'test': 64, 'provider': 30}
assert all(r['passed'] for r in data['consumers']) and len(data['consumers']) == 166
assert int((BASE / 'ordinary.status').read_text()) == 0
print('PASS complete original94 width fields/32 changed copies/113 unchanged controls independently bind authored local/imported/validator source meanings. All59 accepted whole metadata products match typed numeric/source/leaf-range/alias/domain/null/empty models; actual fixture bytes conserve. Private validation copies are not final product or test-copy kind authority; actual candidate/assurance controls remain successor-owned.')
