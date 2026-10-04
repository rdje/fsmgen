"""Independent whole source/private-stage/native metadata product reader."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path
from model import graph, hydrate, thaw

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
for flag in ('omit-product', 'omit-stage', 'swap-layout', 'private-width', 'strict-value-authority'):
    parser.add_argument('--' + flag, action='store_true')
args = parser.parse_args()

def file_identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}

def exact(left, right):
    if type(left) is not type(right):
        return False
    if isinstance(left, dict):
        return set(left) == set(right) and all(exact(left[key], right[key]) for key in left)
    if isinstance(left, list):
        return len(left) == len(right) and all(exact(a, b) for a, b in zip(left, right))
    return left == right

if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert file_identity((BASE / name).read_bytes()) == row, name
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == '8ad89be8b96421a6d53cc524ab274fbe176eb721' and len(binding['sources']) == 21
mutable = {'docs/knowledge/isf-aggregate-port-request-baseline.md', 'docs/book/src/13k-isf-feature-support-matrix.md'}
for path, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert file_identity(raw) == {'bytes': row['bytes'], 'sha256': row['sha256']} and raw.decode() == row['body']
    if path not in mutable:
        assert raw == Path(path).read_bytes(), 'current selected source drift: ' + path
if (BASE / 'doc-updates.json').exists():
    updates = json.loads((BASE / 'doc-updates.json').read_text())
    assert {row['path'] for row in updates} == mutable
    for row in updates:
        assert row['before'] == binding['sources'][row['path']]['body']
        text = row['before']
        for before, after in row['replacements']:
            assert text.count(before) == 1
            text = text.replace(before, after)
        assert text == row['after'] == Path(row['path']).read_text(), 'exact current capture document transform'
else:
    assert all(binding['sources'][path]['body'] == Path(path).read_text() for path in mutable)
for archive in ('record-value-runtime-20261004', 'record-value-fields-20261004', 'record-value-copy-fields-20261004',
        'record-value-field-join-20261004', 'record-value-actors-20261004', 'record-value-replay-portability-20261004',
        'record-value-scopes-20261004', 'record-value-references-20261004', 'record-value-copies-20261004',
        'record-value-api-join-20261004'):
    directory = Path('docs/audits') / archive
    manifest = json.loads((directory / 'manifest.json').read_text())
    assert {p.name for p in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert file_identity((directory / name).read_bytes()) == row, archive + '/' + name
    prior = json.loads((directory / ('join.json' if archive == 'record-value-field-join-20261004' else 'binding.json')).read_text())
    for path, row in prior['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
owner = json.loads((BASE / 'value-owner.json').read_text())
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
for task in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()):
    start = task.index('- ID: `' + owner['owner'] + '`')
    end = task.index('\n- ID:', start + 1)
    assert task[start:end] == owner['node'] and 'Status: `done`' in owner['node'], 'exact completed whole value product owner'

def leaves_from_low(spec, prefix='', ancestors=()):
    """Reverse ordered traversal independently assigns packed low offsets."""
    if id(spec) in ancestors:
        return None, 'cyclic resolved type'
    width = spec.get('width')
    assert type(width) is int and width > 0
    kind = spec.get('kind')
    if kind in ('bit', 'bits'):
        assert kind != 'bit' or width == 1
        if spec.get('signed', 0) not in (0, 1):
            return None, 'invalid resolved signed property'
        if spec.get('state_model', 'two_state') not in ('two_state', 'four_state'):
            return None, 'invalid resolved state model'
        field = {'path': prefix, 'width': width, 'lsb': 0, 'msb': width - 1, 'signed': spec.get('signed', 0)}
        if 'state_model' in spec:
            field['state_model'] = spec['state_model']
        return [field], None
    if kind == 'record':
        order, members = spec['member_order'], spec['members']
        if len(order) != len(members):
            return None, 'record member inventory disagrees'
        if len(set(order)) != len(order) or set(order) != set(members):
            return None, 'invalid or duplicate record member'
        children = [(prefix + ('.' if prefix else '') + name, members[name]) for name in order]
    elif kind == 'list':
        assert prefix and spec['items']
        children = [(prefix + '[' + str(i) + ']', child) for i, child in enumerate(spec['items'])]
    else:
        return None, 'unsupported resolved type kind'
    cursor, low_first = 0, []
    for path, child in reversed(children):
        fields, error = leaves_from_low(child, path, ancestors + (id(spec),))
        if error:
            return None, error
        low_first.extend(dict(field, lsb=cursor + field['lsb'], msb=cursor + field['msb']) for field in reversed(fields))
        cursor += child['width']
    if cursor != width:
        return None, 'resolved aggregate width disagrees with members'
    return list(reversed(low_first)), None

def source_numeric_equal(actual, expected, ancestors=()):
    assert isinstance(actual, dict) and isinstance(expected, dict) and set(actual) == set(expected)
    if id(expected) in ancestors:
        assert id(actual) == dict((b, a) for a, b in source_numeric_equal.stack)[id(expected)], 'source ancestor cycle is exact actual ancestor cycle'
        return
    source_numeric_equal.stack.append((id(actual), id(expected)))
    for key in expected:
        if key in ('width', 'signed'):
            assert type(actual[key]) in (int, str) and int(actual[key]) == expected[key]
        elif key == 'members':
            assert set(actual[key]) == set(expected[key])
            for name in expected[key]:
                source_numeric_equal(actual[key][name], expected[key][name], ancestors + (id(expected),))
        elif key == 'items':
            assert len(actual[key]) == len(expected[key])
            for a, b in zip(actual[key], expected[key]):
                source_numeric_equal(a, b, ancestors + (id(expected),))
        else:
            assert exact(actual[key], expected[key])
    source_numeric_equal.stack.pop()
source_numeric_equal.stack = []

native = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
fields = json.loads(Path('docs/audits/record-value-copy-fields-20261004/fields.json').read_text())
sources = json.loads(Path('docs/audits/record-value-copy-fields-20261004/source-models.json').read_text())
actors = json.loads(Path('docs/audits/record-value-actors-20261004/actor-models.json').read_text())
contrast = json.loads((BASE / 'strict-value-counterexample.json').read_text())
assert contrast['capture_index'] == 8019 and exact(contrast['capture'], native['api'][8019])
assert exact(contrast['capture_private'], dict(native['copies'][555], index=555))
strict = contrast['strict_outer_scope']
assert exact(strict, dict(native['api'][strict['index']], index=strict['index']))
assert strict['kind'] == 'scope' and strict['helper'] == contrast['capture']['helper'] == 29
assert strict['accepted'] == 0 and contrast['capture']['accepted'] == 1
data = json.loads((BASE / 'capture-products.json').read_text())
rows = data['rows'][:-1] if args.omit_product else data['rows']
assert [row['index'] for row in rows] == [i for i, row in enumerate(native['api']) if row['kind'] == 'capture'], 'every original whole capture product membership'
assert len(rows) == 227
seen_stages, refused, accepted = [], [], []
control_reached = False
for row in rows:
    index = row['index']
    original = native['api'][index]
    assert exact(row['original'], original) and exact(original['before'], original['after'])
    stages = [dict(value, index=i) for i, value in enumerate(native['copies']) if value['api'] == index]
    if args.omit_stage and not seen_stages:
        stages = []
    assert len(stages) == 1 and exact(row['private'], stages[0]), 'own complete original capture-private stage membership'
    stage = stages[0]
    assert stage['caller'] == ['FSM::Support::ISFInterfacePortMetadata', 'perl/FSM/Support/ISFInterfacePortMetadata.pm', 40]
    assert stage['kind'] == 'metadata-private' and stage['accepted'] == 1 and not stage['error'] and stage['shared_with_original'] == 0
    assert exact(row['whole_field_record'], fields['rows'][stage['index']])
    seen_stages.append(stage['index'])
    arguments = thaw(original['before'])
    assert len(arguments) == (2 if original['caller'][0] == 'FSM::Adapter::ISF::Parser' else 1)
    actual_interface = arguments[0]
    assert graph(actual_interface) == stage['before'] == stage['after']
    source_interface = thaw(row['source_interface'])
    private_interface = thaw(stage['copy'])
    assert set(actual_interface) == set(source_interface) == set(private_interface) == {'inputs', 'outputs'}
    if original['caller'][0] == 'FSM::Adapter::ISF::Parser':
        actor = 'local' if original['parse'] == 0 else 'imported'
        assert exact(graph(actors['actors'][actor]['interface']), row['source_interface'])
    else:
        assert original['caller'] == ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', 147]
        assert not source_interface['outputs'] and len(source_interface['inputs']) == 1
        source_type = source_interface['inputs'][0]['type_spec']
        origin = row['source_origins'][0]
        assert origin['path'] == '/inputs/0/type_spec' and exact(origin['whole_source_type'], graph(source_type))
        matches = []
        for group in ('roots', 'nodes'):
            for name, model in sources[group].items():
                if exact(graph(hydrate(model)), graph(source_type)):
                    matches.append(group + ':' + name)
        assert matches == origin['source_nodes'] and matches, 'full independently declared source type membership'
    product, error = [], None
    for group, direction in [('inputs', 'input'), ('outputs', 'output')]:
        assert len(actual_interface[group]) == len(private_interface[group]) == len(source_interface[group])
        for actual, private, source in zip(actual_interface[group], private_interface[group], source_interface[group]):
            assert set(actual) == set(private) == set(source)
            for key in source:
                if key == 'type_spec':
                    source_numeric_equal(actual[key], source[key])
                    source_numeric_equal(private[key], source[key])
                elif key == 'width':
                    assert type(actual[key]) in (int, str) and type(private[key]) in (int, str)
                    assert int(actual[key]) == int(private[key]) == source[key]
                else:
                    assert exact(actual[key], source[key]) and exact(private[key], source[key])
            entry = {'name': source['name'], 'direction': direction, 'width': source['width']}
            if 'type' in source:
                spec = source['type_spec']
                leaves, error = leaves_from_low(spec)
                if error:
                    break
                assert spec['width'] == source['width']
                entry.update(type=source['type'], type_kind=spec['kind'])
                if spec['kind'] == 'record':
                    entry['fields'] = leaves
            product.append(entry)
        if error:
            break
    model_product = row['expected_product']
    if args.swap_layout and index == 3:
        control_reached = True
        product[0]['fields'][0]['lsb'] = 0
        product[0]['fields'][0]['msb'] = 0
    if args.private_width and index == 3:
        control_reached = True
        assert type(private_interface['inputs'][0]['width']) is str
        product[0]['width'] = private_interface['inputs'][0]['width']
    if args.strict_value_authority and index == 8019:
        control_reached = True
        assert error is None and 'signed' not in source_interface['inputs'][0]['type_spec']['members']['data']
        error = 'strict value requires signed'
    assert error == row['expected_refusal'], 'independent metadata versus strict-value source refusal relation'
    if error:
        refused.append(index)
        assert model_product is None and original['accepted'] == 0 and original['result'] is None
        assert original['primary'] == 'Invalid ISF interface port metadata: ' + error and original['error'].startswith(original['primary'] + '\n')
    else:
        accepted.append(index)
        assert exact(graph(product), model_product), 'independent complete source packed-field/numeric metadata projection'
        assert original['accepted'] == 1 and not original['error'] and not original['primary']
        assert exact(model_product, original['result']), 'whole original capture source/private-stage/native product'
    assert not original['warnings']
assert len(accepted) == 220 and len(refused) == 7
assert not (args.swap_layout or args.private_width or args.strict_value_authority) or control_reached, 'requested genuine control must execute'
assert seen_stages == [i for i, row in enumerate(native['copies']) if row['api'] is not None and native['api'][row['api']]['kind'] == 'capture']
run = subprocess.run(['python3', '-B', str(BASE / 'replay_values.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS all original227 metadata captures:220 complete source-directed numeric products/seven source-owned refusals, every227 detached stage/full field record, whole raw caller/source/kind boundaries and independent reverse packed layouts. Snapshot/core/native assurance remain separate.')
