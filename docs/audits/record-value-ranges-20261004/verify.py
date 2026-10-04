"""Independent whole source/private-stage/native range product reader."""
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
for flag in ('omit-product', 'omit-stage', 'swap-range', 'wrong-refusal', 'numeric-type', 'erase-caller-change'):
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
assert binding['revision'] == '0c02f701e0e683e56a6c6aa64b446d56e281c6bf' and len(binding['sources']) == 21
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
        assert text == row['after'] == Path(row['path']).read_text(), 'exact current range document transform'
else:
    assert all(binding['sources'][path]['body'] == Path(path).read_text() for path in mutable)
for archive in ('record-value-runtime-20261004', 'record-value-fields-20261004', 'record-value-copy-fields-20261004',
        'record-value-field-join-20261004', 'record-value-actors-20261004', 'record-value-replay-portability-20261004',
        'record-value-scopes-20261004', 'record-value-references-20261004', 'record-value-copies-20261004',
        'record-value-api-join-20261004', 'record-value-captures-20261004', 'record-value-snapshots-20261004'):
    directory = Path('docs/audits') / archive
    manifest = json.loads((directory / 'manifest.json').read_text())
    assert {p.name for p in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert file_identity((directory / name).read_bytes()) == row, archive + '/' + name
    prior = json.loads((directory / ('join.json' if archive == 'record-value-field-join-20261004' else 'binding.json')).read_text())
    for path, row in prior['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
owners = json.loads((BASE / 'owners.json').read_text())
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
for owner in owners:
    for task in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()):
        start = task.index('- ID: `' + owner['owner'] + '`')
        end = task.index('\n- ID:', start + 1)
        assert task[start:end] == owner['node'] and 'Status: `done`' in owner['node'], 'exact completed source/capture/snapshot/reference owner'

def identity(value):
    return file_identity(json.dumps(value, sort_keys=True, separators=(',', ':')).encode())

def inventory(spec, path='', low=0):
    """Every source subtree interval via reverse low-first packed traversal."""
    result = {path: {'low': low, 'high': low + spec['width'] - 1, 'width': spec['width'], 'type_spec': spec}}
    if spec['kind'] == 'record':
        children = [(path + '.' + name, spec['members'][name]) for name in spec['member_order']]
    elif spec['kind'] == 'list':
        children = [(path + '[' + str(i) + ']', child) for i, child in enumerate(spec['items'])]
    else:
        return result
    cursor = low
    for name, child in reversed(children):
        result.update(inventory(child, name, cursor))
        cursor += child['width']
    assert cursor == low + spec['width']
    return result

def source_witness(root, path):
    intervals = inventory(root)
    if path in intervals:
        return dict(intervals[path], ok=1)
    bracket = re.fullmatch(r'(.*)\[([0-9]+)(?::([0-9]+))?\]', path)
    if bracket and bracket[1] in intervals:
        parent = intervals[bracket[1]]
        spec = parent['type_spec']
        if spec['kind'] in ('bit', 'bits'):
            first, second = int(bracket[2]), int(bracket[3]) if bracket[3] is not None else int(bracket[2])
            low, high = sorted((first, second))
            if high < parent['width']:
                width = high - low + 1
                return {'ok': 1, 'low': parent['low'] + low, 'high': parent['low'] + high, 'width': width,
                    'type_spec': {'kind': 'bit' if width == 1 else 'bits', 'width': width, 'signed': 0}}
    # These six literal source-call witnesses are independently owned original
    # controls. Resolve their exact named facts, rather than trusting a model's
    # failure classification or treating a returned map as an exception.
    if path in ('.unknown', '.data'):
        name = path[1:]
        assert root['kind'] == 'record' and name not in root['members']
        return {'ok': 0, 'code': 'unknown_member', 'known_members': root['member_order'], 'member_name': name}
    if path == '.body.lanes[2]':
        assert root['members']['body']['members']['lanes']['kind'] == 'list'
        count = len(root['members']['body']['members']['lanes']['items'])
        assert count == 2
        return {'ok': 0, 'code': 'list_index_out_of_range', 'index': 2, 'max_index': count - 1}
    if path == '.body.count[3]':
        scalar = root['members']['body']['members']['count']
        assert scalar['kind'] == 'bits' and scalar['width'] == 3
        return {'ok': 0, 'code': 'scalar_index_out_of_range', 'index': 3, 'scalar_width': scalar['width']}
    if path == '..count':
        assert root['kind'] == 'record'
        return {'ok': 0, 'code': 'parse_error', 'remaining': path}
    if path == '.value.data':
        scalar = root['members']['value']
        assert scalar == {'kind': 'bits', 'width': 7, 'signed': 0}
        return {'ok': 0, 'code': 'member_on_non_record', 'member_name': 'data', 'current_type_label': 'bits[7]'}
    raise AssertionError('unowned original source path witness: ' + path)

def differences(before, after, path=''):
    if type(before) is type(after) and isinstance(before, dict):
        assert set(before) == set(after)
        return [delta for key in sorted(before) for delta in differences(before[key], after[key], path + '/' + key)]
    if type(before) is type(after) and isinstance(before, list):
        assert len(before) == len(after)
        return [delta for i, (a, b) in enumerate(zip(before, after)) for delta in differences(a, b, path + '/' + str(i))]
    return [] if exact(before, after) else [{'path': path, 'before': before, 'after': after, 'before_kind': type(before).__name__, 'after_kind': type(after).__name__}]

native = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
captures = json.loads(Path('docs/audits/record-value-captures-20261004/capture-products.json').read_text())['rows']
references = json.loads(Path('docs/audits/record-value-references-20261004/reference-products.json').read_text())
source_scopes = {row['label']: thaw(row['scope']) for row in references['source_scopes']}
metadata, value_calls = {}, {}
for capture in captures:
    if capture['expected_refusal'] is not None:
        continue
    source = thaw(capture['source_interface'])
    products = thaw(capture['expected_product'])
    paths = [(port['type_spec'], '.' + field['path']) for port, output in zip(source['inputs'] + source['outputs'], products) for field in output.get('fields', [])]
    end = next((row['index'] for row in captures if row['index'] > capture['index']), len(native['api']))
    selected = [i for i in range(capture['index'] + 1, end) if native['api'][i]['kind'] == 'range' and native['api'][i]['caller'][0] == 'FSM::Support::ISFInterfacePortMetadata']
    assert len(paths) == len(selected)
    for index, (root, path) in zip(selected, paths):
        metadata[index] = (capture, root, path)
for reference in references['rows']:
    for operation in reference['operation_span']:
        row = operation['record']
        if row['kind'] != 'range' or row['caller'][0] != 'FSM::Support::ISFRecordPortValues':
            continue
        token = reference['source_call']['token']
        match = re.fullmatch(r'([A-Za-z_]\w*)(.*)', token, re.S)
        root = source_scopes[reference['source_scope_matches'][0]][match[1]]['type_spec']
        path = match[2]
        if root['kind'] not in ('record', 'list'):
            root = {'kind': 'record', 'width': root['width'], 'signed': 0, 'member_order': ['value'], 'members': {'value': root}}
            path = '.value' + path
        value_calls[operation['index']] = (reference, root, path)
assert len(metadata) == 417 and len(value_calls) == 20 and not set(metadata) & set(value_calls)
data = json.loads((BASE / 'range-products.json').read_text())
rows = data['rows'][:-1] if args.omit_product else data['rows']
assert [row['index'] for row in rows] == [i for i, row in enumerate(native['api']) if row['kind'] == 'range'], 'every whole original range call/source/product membership'
assert set(metadata) | set(value_calls) == {row['index'] for row in rows}
stages, last_range = {}, None
for i, record in enumerate(native['api']):
    if record['kind'] == 'range':
        last_range = i
    elif record['kind'] == 'structured-clone' and record['caller'] == ['FSM::Package::AggregatePathSupport', 'perl/FSM/Package/AggregatePathSupport.pm', 295]:
        assert last_range not in stages
        stages[last_range] = {'index': i, 'record': record}
contrast = json.loads((BASE / 'caller-change.json').read_text())
assert contrast['range'] == next(row for row in rows if row['index'] == 4825)
changed, succeeded, failed, stages_seen, reached = [], [], [], [], False
for row in rows:
    index = row['index']
    original = native['api'][index]
    assert exact(row['original'], original)
    assert original['accepted'] == 1 and not original['error'] and not original['primary'] and not original['warnings']
    parent, root, path = (metadata if index in metadata else value_calls)[index]
    kind = 'capture' if index in metadata else 'reference'
    recipe = row['source_recipe']
    assert recipe['parent_kind'] == kind and recipe['parent_index'] == parent['index'] and recipe['whole_source_parent'] == identity(parent)
    assert exact(recipe['source_root'], graph(root)) and recipe['path_text'] == path
    if kind == 'reference':
        assert recipe['whole_source_call'] == parent['source_call']
    arguments = thaw(original['before'])
    assert arguments[0:2] == ['FSM::Package::AggregatePathSupport', 'root_type_spec'] and arguments[3:] == ['path_text', path]
    assert exact(graph(_helpers.type_meaning(arguments[2])), graph(root)), 'whole source/private preparation root identity'
    after = thaw(original['after'])
    if args.erase_caller_change and index == 4825:
        reached = True
        after = arguments
    delta = differences(arguments, after)
    if index == 4825:
        assert delta == [{'path': '/2/members/body/members/lanes/items/1/width', 'before': '2', 'after': 2, 'before_kind': 'str', 'after_kind': 'int'}], 'sole complete actual private sibling-width caller kind change'
        assert root['members']['body']['members']['lanes']['items'][1]['width'] == 2 and path == '.body.lanes[0]'
        assert contrast['reference_index'] == parent['index'] == 4751 and exact(contrast['whole_reference_caller'], parent['original'])
        assert exact(contrast['whole_private_roots'], parent['private_root_copies']) and parent['private_root_copies'][0]['index'] == 313
        assert exact(parent['original']['before'], parent['original']['after']), 'original reference caller is distinct from private range caller'
        changed.append(index)
    else:
        assert not delta, 'every other original range raw caller graph retains'
    expected = source_witness(root, path)
    stage = stages.get(index)
    if args.omit_stage and index == 4:
        reached = True
        stage = None
    if expected['ok']:
        assert stage is not None and exact(row['type_stage'], stage), 'every own complete range-final type stage membership'
        stage_row = stage['record']
        assert stage_row['accepted'] == 1 and not stage_row['error'] and not stage_row['warnings'] and exact(stage_row['before'], stage_row['after'])
        stage_args = thaw(stage_row['before'])
        assert stage_args[0] == 'FSM::Package::AggregatePathSupport'
        raw_type = stage_args[1]
        assert exact(graph(_helpers.type_meaning(raw_type)), graph(expected['type_spec'])), 'independent subtree/index/slice full source property identity'
        expected['type_spec'] = raw_type
        stages_seen.append(stage['index'])
        succeeded.append(index)
    else:
        assert stage is None and row['type_stage'] is None
        failed.append(index)
    if args.swap_range and index == 4:
        reached = True
        expected['low'] = expected['high'] = 0
    if args.wrong_refusal and index == 5421:
        reached = True
        expected['ok'] = 1
    if args.numeric_type and index == 76:
        reached = True
        assert type(expected['type_spec']['width']) is str
        expected['type_spec']['width'] = int(expected['type_spec']['width'])
    assert exact(graph(expected), row['expected_product']), 'independent whole source interval/failure/private-type primitive product'
    assert exact(row['expected_product'], original['result']), 'every whole original numeric range/source/type/native result'
assert len(succeeded) == len(stages_seen) == 431 and len(failed) == 6 and changed == [4825]
assert stages_seen == [i for i, row in enumerate(native['api']) if row['kind'] == 'structured-clone' and row['caller'] == ['FSM::Package::AggregatePathSupport', 'perl/FSM/Package/AggregatePathSupport.pm', 295]]
assert not any((args.omit_stage, args.swap_range, args.wrong_refusal, args.numeric_type, args.erase_caller_change)) or reached, 'requested genuine range control must execute'
run = subprocess.run(['python3', '-B', str(BASE / 'replay_snapshots.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS all437 whole original source/private-type range products:431 successes and six returned failure maps; every431 own final type stage,417 metadata/20 value source-call roles and sole private sibling width-kind change retain. Original reference callers preserve. Later core/native assurance remains open.')
