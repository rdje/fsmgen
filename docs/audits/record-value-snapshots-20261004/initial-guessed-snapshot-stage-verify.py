"""Independent whole source/private-stage/native metadata product reader."""
import argparse
import hashlib
import json
import subprocess
import re
from pathlib import Path
import importlib.util
_spec = importlib.util.spec_from_file_location("bound_capture_graph", "docs/audits/record-value-captures-20261004/model.py")
_helpers = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_helpers)
graph, thaw = _helpers.graph, _helpers.thaw

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
for flag in ('omit-product', 'omit-stage', 'wrong-role', 'private-numerics', 'swapped-capture'):
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
assert binding['revision'] == 'e439fe4e8309285ea7ebc4ec097be047a1001ba2' and len(binding['sources']) == 21
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
        assert text == row['after'] == Path(row['path']).read_text(), 'exact current snapshot document transform'
else:
    assert all(binding['sources'][path]['body'] == Path(path).read_text() for path in mutable)
for archive in ('record-value-runtime-20261004', 'record-value-fields-20261004', 'record-value-copy-fields-20261004',
        'record-value-field-join-20261004', 'record-value-actors-20261004', 'record-value-replay-portability-20261004',
        'record-value-scopes-20261004', 'record-value-references-20261004', 'record-value-copies-20261004',
        'record-value-api-join-20261004', 'record-value-captures-20261004'):
    directory = Path('docs/audits') / archive
    manifest = json.loads((directory / 'manifest.json').read_text())
    assert {p.name for p in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert file_identity((directory / name).read_bytes()) == row, archive + '/' + name
    prior = json.loads((directory / ('join.json' if archive == 'record-value-field-join-20261004' else 'binding.json')).read_text())
    for path, row in prior['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
owner = json.loads((BASE / 'capture-owner.json').read_text())
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
for task in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()):
    start = task.index('- ID: `' + owner['owner'] + '`')
    end = task.index('\n- ID:', start + 1)
    assert task[start:end] == owner['node'] and 'Status: `done`' in owner['node'], 'exact completed whole capture product owner'

def identity(value):
    return file_identity(json.dumps(value, sort_keys=True, separators=(',', ':')).encode())

def natural(value, positive=False):
    assert type(value) in (int, str)
    assert re.fullmatch(r'[1-9][0-9]*' if positive else r'(?:0|[1-9][0-9]*)', str(value))
    return int(value)

def rebuild(private):
    """Independent closed schema and contiguous packed-field reconstruction."""
    assert isinstance(private, list)
    seen, result, output = set(), [], False
    for port in private:
        assert isinstance(port, dict)
        assert {'name', 'direction', 'width'} <= set(port) <= {'name', 'direction', 'width', 'type', 'type_kind', 'domain', 'fields'}
        name, direction = port['name'], port['direction']
        assert isinstance(name, str) and name and name not in seen
        seen.add(name)
        assert direction in ('input', 'output') and not (output and direction == 'input')
        output = output or direction == 'output'
        value = {'name': name, 'direction': direction, 'width': natural(port['width'], True)}
        if 'domain' in port:
            assert isinstance(port['domain'], str) and re.fullmatch(r'[A-Za-z_]\w*', port['domain'])
            value['domain'] = port['domain']
        if 'type' in port:
            assert isinstance(port['type'], str) and re.fullmatch(r'[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?', port['type'])
            assert port['type_kind'] in ('bit', 'bits', 'record')
            assert port['type_kind'] != 'bit' or value['width'] == 1
            value.update(type=port['type'], type_kind=port['type_kind'])
        else:
            assert 'type_kind' not in port and 'fields' not in port
        if port.get('type_kind') == 'record':
            assert isinstance(port['fields'], list) and port['fields']
            paths, packed, next_high = set(), [], value['width'] - 1
            for field in port['fields']:
                assert isinstance(field, dict) and {'path', 'width', 'lsb', 'msb', 'signed'} <= set(field) <= {'path', 'width', 'lsb', 'msb', 'signed', 'state_model'}
                path = field['path']
                assert isinstance(path, str) and re.fullmatch(r'[A-Za-z_]\w*(?:(?:\.[A-Za-z_]\w*)|(?:\[[0-9]+\]))*', path) and path not in paths
                paths.add(path)
                width, low, high = natural(field['width'], True), natural(field['lsb']), natural(field['msb'])
                signed = natural(field['signed'])
                assert signed in (0, 1) and high == next_high and high - low + 1 == width
                next_high = low - 1
                row = {'path': path, 'width': width, 'lsb': low, 'msb': high, 'signed': signed}
                if 'state_model' in field:
                    assert field['state_model'] in ('two_state', 'four_state')
                    row['state_model'] = field['state_model']
                packed.append(row)
            assert next_high == -1
            value['fields'] = packed
        else:
            assert 'fields' not in port
        result.append(value)
    return result

native = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
captures = json.loads(Path('docs/audits/record-value-captures-20261004/capture-products.json').read_text())
fields = json.loads(Path('docs/audits/record-value-copy-fields-20261004/fields.json').read_text())
by_index = {row['index']: row for row in captures['rows']}
data = json.loads((BASE / 'snapshot-products.json').read_text())
rows = data['rows'][:-1] if args.omit_product else data['rows']
assert [row['index'] for row in rows] == [i for i, row in enumerate(native['api']) if row['kind'] == 'snapshot'], 'every original whole snapshot product membership'
assert len(rows) == 220
stages_seen, parents_seen, reached = [], [], False
for row in rows:
    index = row['index']
    original = native['api'][index]
    assert exact(row['original'], original) and exact(original['before'], original['after'])
    assert original['caller'] == ['FSM::Support::ISFInterfacePortMetadata', 'perl/FSM/Support/ISFInterfacePortMetadata.pm', 74]
    assert original['accepted'] == 1 and not original['error'] and not original['primary'] and not original['warnings']
    parent_index = max(i for i in by_index if i < index)
    assert parent_index == row['capture_index'], 'original snapshot exact nearest complete capture allocation'
    parent = by_index[parent_index]
    if args.swapped_capture and index == 30:
        reached = True
        parent = by_index[0]
    assert row['whole_capture_model'] == identity(parent), 'complete independently source-built capture model allocation'
    assert parent['expected_refusal'] is None
    parents_seen.append(parent_index)
    prepared = thaw(parent['private']['copy'])
    source_product = thaw(parent['expected_product'])
    handoff = thaw(row['expected_handoff'])
    ports = prepared['inputs'] + prepared['outputs']
    assert len(ports) == len(source_product) == len(handoff)
    for actual, source, private in zip(handoff, source_product, ports):
        assert set(actual) == set(source) and set(actual) - {'width'} == set(source) - {'width'}
        assert all(exact(actual[key], source[key]) for key in source if key != 'width')
        assert type(source['width']) is int and source['width'] == int(private['width'])
        assert exact(actual['width'], private['width'])
    assert exact(original['before'], graph([handoff])), 'whole source-directed raw capture handoff and caller kinds'
    stages = [dict(value, index=i) for i, value in enumerate(native['copies']) if value['api'] == index]
    if args.omit_stage and not stages_seen:
        stages = []
    assert len(stages) == 1 and exact(stages[0], row['private']), 'every own whole original snapshot-private stage membership'
    stage = stages[0]
    assert stage['caller'] == ['FSM::Support::ISFInterfacePortMetadata', 'perl/FSM/Support/ISFInterfacePortMetadata.pm', 140]
    assert stage['kind'] == 'metadata-private' and stage['accepted'] == 1 and not stage['error'] and stage['shared_with_original'] == 0
    assert exact(stage['before'], stage['after']) and exact(stage['before'], row['expected_handoff'])
    assert exact(row['whole_field_record'], fields['rows'][stage['index']])
    stages_seen.append(stage['index'])
    private = thaw(stage['copy'])
    model = rebuild(private)
    assert exact(graph(rebuild(handoff)), parent['expected_product']), 'complete closed source fields and numeric capture authority'
    if args.wrong_role and index == 30:
        reached = True
        model[0]['direction'] = 'output'
    if args.private_numerics and index == 30:
        reached = True
        actual_width = private[0]['fields'][1]['width']
        assert type(actual_width) is str and type(model[0]['fields'][1]['width']) is int
        model[0]['fields'][1]['width'] = actual_width
    assert exact(graph(model), parent['expected_product']) and exact(row['expected_product'], parent['expected_product']), 'independent whole schema/source/private/final numeric snapshot product'
    assert exact(row['expected_product'], original['result']), 'every whole original native snapshot field/property/kind product'
assert not (args.wrong_role or args.private_numerics or args.swapped_capture) or reached, 'requested genuine snapshot control must execute'
assert len(parents_seen) == len(set(parents_seen)) == 220
assert set(parents_seen) == {i for i, row in by_index.items() if row['expected_refusal'] is None}
assert stages_seen == [i for i, row in enumerate(native['copies']) if row['api'] is not None and native['api'][row['api']]['kind'] == 'snapshot']
if (BASE / 'capture-replays.json').exists():
    run = subprocess.run(['python3', '-B', str(BASE / 'replay_captures.py'), '--check'], text=True, capture_output=True)
    assert run.returncode == 0, run.stdout + run.stderr
print('PASS every original220 snapshot/source-built capture/handoff/own private stage/full-field/native product. Complete closed ordered schemas, numeric widths/ranges/signed/state and raw callers retain. Later core APIs and native assurance remain separate.')
