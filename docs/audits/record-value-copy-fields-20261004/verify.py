"""Independent full copied field/source/stage reader, never final-kind coercion."""
import argparse
import copy
import hashlib
import json
import subprocess
from collections import Counter
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
for name in ('omit-field', 'swap-source-role', 'trust-private-product', 'swap-malformed-model'):
    parser.add_argument('--' + name, action='store_true')
args = parser.parse_args()
manifest_path = BASE / 'manifest.json'
if manifest_path.exists():
    manifest = json.loads(manifest_path.read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, identity in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == identity['bytes'] and hashlib.sha256(raw).hexdigest() == identity['sha256'], name
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == '19c49b7ab382d8d5246f5a26448a1ea468048112'
for path, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert raw.decode() == row['body'] and len(raw) == row['bytes']
    assert hashlib.sha256(raw).hexdigest() == row['sha256']
    if path != 'docs/knowledge/isf-aggregate-port-request-baseline.md':
        assert raw == Path(path).read_bytes(), 'selected current source drift: ' + path
for archive in ('record-value-runtime-20261004', 'record-value-fields-20261004'):
    directory = Path('docs/audits') / archive
    manifest = json.loads((directory / 'manifest.json').read_text())
    assert {p.name for p in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (directory / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
native_path = Path('docs/audits/record-value-runtime-20261004/ordinary.json')
native = json.loads(native_path.read_text())
data = json.loads((BASE / 'fields.json').read_text())
assert len(native['copies']) == len(data['rows']) == 697
assert data['native_input'] == {'bytes': native_path.stat().st_size,
    'sha256': hashlib.sha256(native_path.read_bytes()).hexdigest()}
models = json.loads((BASE / 'source-models.json').read_text())
if (BASE / 'doc-updates.json').exists():
    updates = json.loads((BASE / 'doc-updates.json').read_text())
    assert {row['path'] for row in updates} == {'docs/knowledge/isf-aggregate-port-request-baseline.md',
        'docs/book/src/13k-isf-feature-support-matrix.md'}
    for row in updates:
        assert subprocess.check_output(['git', 'show', binding['revision'] + ':' + row['path']]).decode() == row['before']
        transformed = row['before']
        for old, new in row['replacements']:
            assert transformed.count(old) == 1
            transformed = transformed.replace(old, new)
        assert transformed == row['after'] == Path(row['path']).read_text(), 'selected current document drift: ' + row['path']
    assert (BASE / 'card-after.txt').read_text() == updates[0]['after']

def exact(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return set(a) == set(b) and all(exact(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(exact(x, y) for x, y in zip(a, b))
    return a == b

# Independently reconstruct the entire candidate domain from the sealed authored
# oracle and exact original source mutations, not from the producer's registry.
authored = json.loads(Path('docs/audits/record-value-fields-20261004/authored-models.json').read_text())
expected_roots = {'authored:' + name: copy.deepcopy(spec) for name, spec in authored['types'].items()}
expected_roots.update({'imported:shared.frame': copy.deepcopy(authored['imported']['shared.frame']),
    'source:scalar': copy.deepcopy(authored['scalar']),
    'source:first-touch-frame': copy.deepcopy(authored['types']['frame']),
    'source:refused-output-frame': {'kind': 'record', 'width': 1, 'signed': 0,
        'member_order': ['flag'], 'members': {'flag': {'kind': 'bit', 'width': 1, 'signed': 0}}},
    'generated:scalar-index': {'kind': 'bit', 'width': 1, 'signed': 0},
    'generated:scalar-slice': {'kind': 'bits', 'width': 3, 'signed': 0}})
source = binding['sources']['t/1986-isf-record-port-value-gates.t']['body']
mutations = [
    ('unknown key', ['extra'], 1, "$_[0]{extra} = 1"),
    ('bad root width', ['width'], 9, "$_[0]{width} = 9"),
    ('bad scalar signed', ['members', 'data', 'signed'], 2, "$_[0]{members}{data}{signed} = 2"),
    ('missing signed', ['members', 'data', 'signed'], None, "delete $_[0]{members}{data}{signed}"),
    ('aggregate signed', ['signed'], 1, "$_[0]{signed} = 1"),
    ('aggregate state', ['state_model'], 'two_state', "$_[0]{state_model} = 'two_state'"),
    ('bad state', ['members', 'data', 'state_model'], 'unknown', "$_[0]{members}{data}{state_model} = 'unknown'"),
    ('duplicate order', ['member_order'], ['flag', 'flag'], "$_[0]{member_order} = [qw(flag flag)]"),
    ('unlisted member', ['members', 'extra'], authored['scalar'], "$_[0]{members}{extra} = dclone($scalar)"),
    ('cyclic member', ['members', 'data'], {'$reference': '.'}, "$_[0]{members}{data} = $_[0]"),
    ('deferred kind', ['kind'], 'deferred_imported_alias', "$_[0]{kind} = 'deferred_imported_alias'"),
]
for name, keys, replacement, literal in mutations:
    assert "['" + name + "', sub { " + literal + " }" in source
    spec = copy.deepcopy(authored['types']['frame'])
    target = spec
    for key in keys[:-1]:
        target = target[key]
    if replacement is None:
        del target[keys[-1]]
    else:
        target[keys[-1]] = copy.deepcopy(replacement)
    expected_roots['malformed:' + name] = spec
swapped = copy.deepcopy(authored['types']['nested'])
lanes = swapped['members']['body']['members']['lanes']['items']
lanes[:] = lanes[::-1]
expected_roots['source:swapped-nested-list'] = swapped
assert 'reverse @{$swapped->{members}{body}{members}{lanes}{items}}' in source
assert '(actor refused (types (type frame (record (flag bit)))' in source
assert "'{\"kind\":\"record\",\"width\":\"8\",\"signed\":0,\"member_order\":[\"flag\",\"data\"],'" in source
value_source = binding['sources']['perl/FSM/Support/ISFRecordPortValues.pm']['body']
assert "return {kind => 'record', width => $spec->{width}, signed => 0,\n        member_order => ['value'], members => {value => $spec}};" in value_source
assert "$path_text = '.value' . $path;" in value_source
range_source = binding['sources']['perl/FSM/Package/AggregatePathSupport.pm']['body']
assert 'scalar_type_spec_from_width(1)' in range_source
assert '$slice_high - $slice_low + 1' in range_source
if args.swap_malformed_model:
    models['roots']['malformed:bad scalar signed']['members']['data']['signed'] = 0
assert exact(models['roots'], expected_roots), 'complete source-declared candidate domain, including signed2 mutation'
expected_nodes = {}
pending = [(name + ':', spec) for name, spec in expected_roots.items()]
while pending:
    name, spec = pending.pop()
    if 'kind' not in spec or 'width' not in spec:
        continue
    expected_nodes[name] = copy.deepcopy(spec)
    pending.extend((name + '/members/' + child_name, child) for child_name, child in spec.get('members', {}).items())
    pending.extend((name + '/items/' + str(index), child) for index, child in enumerate(spec.get('items', [])))
for name, spec in list(expected_nodes.items()):
    if '$reference' not in json.dumps(spec):
        expected_nodes['wrapper:' + name] = {'kind': 'record', 'width': spec['width'], 'signed': 0,
            'member_order': ['value'], 'members': {'value': copy.deepcopy(spec)}}
assert exact(models['nodes'], expected_nodes), 'complete independently reconstructed source/virtual/wrapper nodes'

def integer(value):
    if type(value) is int:
        return value
    assert type(value) is str and value.isascii() and value.isdecimal()
    return int(value)

def meaning(value, key=None):
    if isinstance(value, dict):
        return {name: meaning(child, name) for name, child in value.items()}
    if isinstance(value, list):
        return [meaning(child) for child in value]
    return integer(value) if key in ('width', 'signed') else value

def raw_shape(value, base):
    if not isinstance(value, list):
        return value
    tag, body = value
    if tag == 'reference':
        return {'$reference': '.' if body == base else body}
    if tag == 'array':
        return [raw_shape(child, base) for child in body]
    assert tag == 'hash'
    return {key: raw_shape(child, base) for key, child in body.items()}

def width_nodes(graph, path='', parents=None):
    if not isinstance(graph, list) or graph[0] == 'reference':
        return []
    tag, body = graph
    parents = [] if parents is None else parents
    rows = []
    if tag == 'hash':
        context = parents + [(path, body)]
        if 'width' in body and not isinstance(body['width'], list):
            rows.append((path + '/width', body['width'], path, body, context))
        pairs = sorted(body.items())
    else:
        assert tag == 'array'
        context = parents
        pairs = enumerate(body)
    for key, child in pairs:
        escaped = str(key).replace('~', '~0').replace('/', '~1')
        rows.extend(width_nodes(child, path + '/' + escaped, context))
    return rows

def compatible(actual):
    interpreted = meaning(actual)
    return sorted(name for name, spec in models['nodes'].items() if exact(interpreted, spec))

def expected_fields(spec, prefix='', lsb=0):
    if spec['kind'] in ('bit', 'bits'):
        signed = spec.get('signed', 0)
        assert signed in (0, 1)
        width = spec['width']
        row = {'path': prefix, 'lsb': lsb, 'msb': lsb + width - 1,
            'width': width, 'signed': signed}
        if 'state_model' in spec:
            assert spec['state_model'] in ('two_state', 'four_state')
            row['state_model'] = spec['state_model']
        return [row]
    assert spec['kind'] in ('record', 'list')
    if spec['kind'] == 'record':
        order = spec['member_order']
        assert len(order) == len(set(order)) and set(order) == set(spec['members'])
        children = [(prefix + ('.' if prefix else '') + name, spec['members'][name]) for name in order]
    else:
        children = [(prefix + '[' + str(index) + ']', child) for index, child in enumerate(spec['items'])]
    assert sum(child['width'] for _, child in children) == spec['width']
    remaining = spec['width']
    result = []
    for name, child in children:
        remaining -= child['width']
        result += expected_fields(child, name, lsb + remaining)
    return result

metadata_candidates = {}
for name, spec in models['nodes'].items():
    try:
        descriptor = {'width': spec['width'], 'type_kind': spec['kind']}
        checked = expected_fields(spec)
        if spec['kind'] in ('record', 'list'):
            descriptor['fields'] = checked
        signature = json.dumps(descriptor, sort_keys=True, separators=(',', ':'))
        metadata_candidates.setdefault(signature, []).append(name)
    except (AssertionError, KeyError):
        pass

totals = Counter()
site_totals = Counter()
contradictions = []
for index, (recorded, original) in enumerate(zip(data['rows'], native['copies'])):
    assert recorded['index'] == index and recorded['caller'] == original['caller']
    assert recorded['copy_kind'] == original['kind']
    assert recorded['api_index'] == original['api'] and recorded['helper_index'] == original['helper']
    assert recorded['parse_index'] == original['parse']
    if original['api'] is not None:
        assert recorded['api_kind'] == native['api'][original['api']]['kind']
    if original['helper'] is not None:
        assert recorded['helper_label'] == native['helpers'][original['helper']]['label']
    path = original['caller'][1].removeprefix('./')
    assert 'dclone(' in binding['sources'][path]['body'].splitlines()[original['caller'][2] - 1]
    for side, raw_graph in [('before', original['before']), ('after', original['copy'])]:
        actual_nodes = width_nodes(raw_graph)
        candidate = copy.deepcopy(recorded[side])
        if args.omit_field and index == 80 and side == 'before':
            candidate.pop()
        if args.swap_source_role and index == 80 and side == 'before':
            default = next(fact for fact in candidate if fact['path'] == '/interface/inputs/0/width')
            # Preserve the width/count while promoting an actual untyped start
            # carrier to a physically compatible authored bit declaration.
            default['default_port'] = None
            default['type_kind'] = 'bit'
        assert [fact['path'] for fact in candidate] == [node[0] for node in actual_nodes], 'complete original copied width membership'
        for fact, (field_path, value, object_path, body, parents) in zip(candidate, actual_nodes):
            assert exact(fact['value'], value) and fact['primitive_kind'] == type(value).__name__
            source_ids = []
            embedded_info = None
            default_info = None
            resolved = body.get('kind') in ('bit', 'bits', 'record', 'list', 'deferred_imported_alias')
            if resolved:
                raw = raw_shape(['hash', body], object_path)
                assert exact(fact['type_shape'], raw)
                source_ids = compatible(raw)
                assert source_ids and source_ids == fact['source_nodes']
                role = 'resolved-source-node'
            elif 'type_spec' in body:
                embedded = raw_shape(body['type_spec'], object_path + '/type_spec')
                source_ids = compatible(embedded)
                assert source_ids and source_ids == fact['embedded_type']['source_nodes']
                assert exact(embedded, fact['embedded_type']['type_shape'])
                same_width = integer(value) == integer(embedded['width'])
                assert same_width == fact['embedded_type']['same_declared_width']
                embedded_info = {'path': object_path + '/type_spec', 'type_shape': embedded,
                    'source_nodes': source_ids, 'same_declared_width': same_width}
                if not same_width and side == 'before':
                    contradictions.append((index, recorded['helper_label'], field_path))
                if body.get('kind') == 'var':
                    assert index == 80 and body['name'] in list('abcdefghijk')
                    names = ['frame', 'alias', 'renamed', 'reordered', 'signed_data', 'four', 'two', 'bit_kind', 'nested', 'flat', 'lanes']
                    name = names[list('abcdefghijk').index(body['name'])]
                    assert body['type'] == name and exact(meaning(embedded), models['roots']['authored:' + name])
                role = 'carrier-embedded-type'
            else:
                descriptor_parent = next(((p, b) for p, b in reversed(parents) if 'type_kind' in b), None)
                if descriptor_parent:
                    parent_path, parent_body = descriptor_parent
                    descriptor = raw_shape(['hash', parent_body], parent_path)
                    projected = {'width': integer(descriptor['width']), 'type_kind': descriptor['type_kind']}
                    if 'fields' in descriptor:
                        projected['fields'] = [{key: integer(child) if key in ('width', 'signed', 'lsb', 'msb') else child
                            for key, child in row.items()} for row in descriptor['fields']]
                    signature = json.dumps(projected, sort_keys=True, separators=(',', ':'))
                    source_ids = sorted(metadata_candidates.get(signature, []))
                    assert source_ids and source_ids == fact['metadata_ancestor']['source_nodes']
                    assert exact(projected, fact['metadata_ancestor']['descriptor'])
                    role = 'metadata-packed-projection'
                else:
                    assert set(body) in ({'name', 'width'}, {'name', 'width', 'direction'})
                    assert body['name'] in ('start', 'done') and integer(value) == 1
                    expected = {'source_name': body['name'], 'width': 1,
                        'direction': 'input' if body['name'] == 'start' else 'output'}
                    assert exact(expected, fact['default_port'])
                    default_info = expected
                    if 'direction' in body:
                        assert body['direction'] == expected['direction']
                    role = 'source-default-bit-port'
            type_parent = next(((p, b) for p, b in reversed(parents)
                if b.get('kind') in ('bit', 'bits', 'record', 'list', 'deferred_imported_alias')), None)
            type_context = None
            if type_parent:
                parent_path, parent_body = type_parent
                type_context = {'path': parent_path,
                    'source_nodes': compatible(raw_shape(['hash', parent_body], parent_path))}
            metadata_parent = next(((p, b) for p, b in reversed(parents)
                if 'type_kind' in b and 'width' in b), None)
            metadata_context = None
            if metadata_parent:
                parent_path, parent_body = metadata_parent
                descriptor = raw_shape(['hash', parent_body], parent_path)
                projected = {'width': integer(descriptor['width']), 'type_kind': descriptor['type_kind']}
                if 'fields' in descriptor:
                    projected['fields'] = [{key: integer(child) if key in ('width', 'signed', 'lsb', 'msb') else child
                        for key, child in row.items()} for row in descriptor['fields']]
                signature = json.dumps(projected, sort_keys=True, separators=(',', ':'))
                metadata_context = {'path': parent_path, 'descriptor': projected,
                    'source_nodes': sorted(metadata_candidates.get(signature, []))}
            expected_fact = {'path': field_path, 'value': value, 'primitive_kind': type(value).__name__,
                'type_shape': raw_shape(['hash', body], object_path) if resolved else None,
                'source_nodes': compatible(raw_shape(['hash', body], object_path)) if resolved else [],
                'type_ancestor': type_context, 'type_kind': body.get('kind') if resolved else None,
                'carrier_kind': body.get('kind') if not resolved else None,
                'embedded_type': embedded_info, 'metadata_ancestor': metadata_context,
                'default_port': default_info, 'metadata_type_kind': body.get('type_kind')}
            assert exact(fact, expected_fact), 'whole field-role record and ancestor/source allocation'
            totals[(side, role)] += 1
            site_totals[(side, original['kind'])] += 1
assert contradictions == [(642, 'contradictory copy descriptor', '/width')]
expected_roles = {'resolved-source-node': 1606, 'carrier-embedded-type': 289,
    'metadata-packed-projection': 635, 'source-default-bit-port': 10}
assert totals == Counter({(side, role): count for side in ('before', 'after') for role, count in expected_roles.items()})
assert site_totals == Counter({(side, kind): count for side in ('before', 'after')
    for kind, count in {'test': 194, 'metadata-private': 1581, 'value-private': 765}.items()})
if args.trust_private_product:
    actual = native['copies'][80]
    assert exact(actual['before'], actual['copy']), 'actual original actor baseline copy loses numeric width kinds'
print('PASS every original697 copied graph joins all2540 before/after width facts and complete '
    'recursive type/property/packed/default/carrier source-stage roles. Compatible physical '
    'identities retain origin sets; actual storage/default carriers remain distinct. Raw kinds '
    'and the one source-forged descriptor width remain intact; stage meaning is not final '
    'product or copy safety. Whole product/native assurance remains successor-owned.')
