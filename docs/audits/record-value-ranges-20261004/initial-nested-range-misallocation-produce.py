"""Complete range call source recipes and model products, never native outputs."""
import copy
import hashlib
import importlib.util
import json
import re
from pathlib import Path
from model import prepared, resolve

BASE = Path(__file__).parent
spec = importlib.util.spec_from_file_location('bound_capture_graph', 'docs/audits/record-value-captures-20261004/model.py')
helpers = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helpers)
graph, thaw, meaning = helpers.graph, helpers.thaw, helpers.type_meaning
native = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
captures = json.loads(Path('docs/audits/record-value-captures-20261004/capture-products.json').read_text())['rows']
references = json.loads(Path('docs/audits/record-value-references-20261004/reference-products.json').read_text())
source_scopes = {row['label']: thaw(row['scope']) for row in references['source_scopes']}

def identity(value):
    raw = json.dumps(value, sort_keys=True, separators=(',', ':')).encode()
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}

recipes = {}
for capture in captures:
    interface = thaw(capture['source_interface'])
    expected = thaw(capture['expected_product'])
    if expected is None:
        continue
    paths = [(port['type_spec'], '.' + field['path']) for port, entry in zip(interface['inputs'] + interface['outputs'], expected) for field in entry.get('fields', [])]
    end = next((row['index'] for row in captures if row['index'] > capture['index']), len(native['api']))
    actual_indices = [i for i in range(capture['index'] + 1, end) if native['api'][i]['kind'] == 'range'
        and native['api'][i]['caller'] == ['FSM::Support::ISFInterfacePortMetadata', 'perl/FSM/Support/ISFInterfacePortMetadata.pm', 121]]
    assert len(paths) == len(actual_indices)
    for index, (root, path) in zip(actual_indices, paths):
        recipes[index] = {'source_root': graph(root), 'path_text': path, 'parent_kind': 'capture',
            'parent_index': capture['index'], 'whole_source_parent': identity(capture)}
for reference in references['rows']:
    source_call = reference['source_call']
    token_root, path = re.fullmatch(r'([A-Za-z_]\w*)(.*)', source_call['token'], re.S).groups()
    for operation in reference['operation_span']:
        if operation['record']['kind'] != 'range':
            continue
        scope = source_scopes[reference['source_scope_matches'][0]]
        root = copy.deepcopy(scope[token_root]['type_spec'])
        assert path and root is not None
        checked = path
        if root['kind'] not in ('record', 'list'):
            root = {'kind': 'record', 'width': root['width'], 'signed': 0, 'member_order': ['value'], 'members': {'value': root}}
            checked = '.value' + path
        index = operation['index']
        assert index not in recipes
        recipes[index] = {'source_root': graph(root), 'path_text': checked, 'parent_kind': 'reference',
            'parent_index': reference['index'], 'whole_source_parent': identity(reference), 'whole_source_call': source_call}
selected = [i for i, row in enumerate(native['api']) if row['kind'] == 'range']
assert sorted(recipes) == selected and len(selected) == 437
stages, last_range = {}, None
for index, row in enumerate(native['api']):
    if row['kind'] == 'range':
        last_range = index
    if row['kind'] == 'structured-clone' and row['caller'] == ['FSM::Package::AggregatePathSupport', 'perl/FSM/Package/AggregatePathSupport.pm', 295]:
        assert last_range is not None and last_range not in stages
        stages[last_range] = {'index': index, 'record': row}
rows = []
for index in selected:
    original = native['api'][index]
    recipe = recipes[index]
    args = thaw(original['before'])
    assert args[0:2] == ['FSM::Package::AggregatePathSupport', 'root_type_spec'] and args[3:] == ['path_text', recipe['path_text']]
    source = thaw(recipe['source_root'])
    assert graph(meaning(args[2])) == graph(source)
    expected = resolve(source, recipe['path_text'])
    stage = stages.get(index)
    if expected['ok']:
        assert stage is not None
        stage_args = thaw(stage['record']['before'])
        assert stage_args[0] == 'FSM::Package::AggregatePathSupport'
        expected['type_spec'] = prepared(expected['type_spec'], stage_args[1])
    else:
        assert stage is None
    rows.append({'index': index, 'original': original, 'source_recipe': recipe,
        'type_stage': stage, 'expected_product': graph(expected)})
assert len(stages) == 431
(BASE / 'range-products.json').write_text(json.dumps({'rows': rows}, sort_keys=True, indent=2) + '\n')
print('PASS complete original437 source-call/root/path/private-type range models:417 source-declared metadata leaf calls and20 source/reference calls. All431 own final type-clone inputs bind; six full returned failure maps retain. Native product comparison remains separate.')
