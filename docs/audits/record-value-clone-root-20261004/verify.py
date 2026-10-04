"""Independent whole clone-root source/context/raw-preparation reader."""
import argparse
import copy
import hashlib
import json
import re
import subprocess
from collections import Counter
from pathlib import Path
from source_roots import graph, thaw, exact, digest, read, scope_model

BASE = Path('docs/audits/record-value-clone-root-20261004')
parser = argparse.ArgumentParser()
for flag in ('omit-root', 'wrong-role', 'same-type-source', 'numeric-preparation'):
    parser.add_argument('--' + flag, action='store_true')
args = parser.parse_args()


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def sealed(directory):
    manifest = json.loads((directory / 'manifest.json').read_text())
    assert {path.name for path in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert identity((directory / name).read_bytes()) == row, str(directory / name)


if (BASE / 'manifest.json').exists():
    sealed(BASE)
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == 'fec3af8947145f5e4dfaa92eb48baa529d6f5a31' and len(binding['sources']) == 21
mutable = {'docs/knowledge/isf-aggregate-port-request-baseline.md', 'docs/book/src/13k-isf-feature-support-matrix.md'}
for path, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert identity(raw) == {'bytes': row['bytes'], 'sha256': row['sha256']} and raw.decode() == row['body']
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
        assert text == row['after'] == Path(row['path']).read_text()
else:
    assert all(Path(path).read_text() == binding['sources'][path]['body'] for path in mutable)
for name in ('runtime', 'fields', 'copy-fields', 'field-join', 'actors', 'replay-portability', 'scopes', 'references', 'copies', 'api-join', 'captures', 'snapshots', 'ranges', 'structured-clones', 'clones', 'clone-roots', 'clone-paths'):
    directory = Path('docs/audits/record-value-' + name + '-20261004')
    sealed(directory)
    prior = json.loads((directory / ('join.json' if name == 'field-join' else 'binding.json')).read_text())
    for path, row in prior['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
owners = json.loads((BASE / 'owners.json').read_text())
assert len(owners) == 5
for owner in owners:
    for task in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()):
        start = task.index('- ID: `' + owner['owner'] + '`'); end = task.index('\n- ID:', start + 1)
        assert task[start:end] == owner['node'] and 'Status: `done`' in owner['node']


def paths(spec, text='', segments=None):
    """Independent full declared subtree-path inventory; no producer tokenizer."""
    segments = [] if segments is None else segments
    result = {text: (segments, spec)}
    if spec['kind'] == 'record':
        for name in spec['member_order']:
            result.update(paths(spec['members'][name], text + '.' + name, segments + [{'kind': 'member', 'name': name}]))
    elif spec['kind'] == 'list':
        for i, child in enumerate(spec['items']):
            result.update(paths(child, text + '[' + str(i) + ']', segments + [{'kind': 'item', 'index': i}]))
    return result


def source_path(root, text):
    inventory = paths(root)
    if text in inventory:
        return inventory[text]
    match = re.fullmatch(r'(.*)\[([0-9]+)(?::([0-9]+))?\]', text)
    assert match and match[1] in inventory
    segments, scalar = inventory[match[1]]
    assert scalar['kind'] in ('bit', 'bits')
    first = int(match[2]); second = int(match[3]) if match[3] is not None else None
    high, low = max(first, first if second is None else second), min(first, first if second is None else second)
    assert high < int(scalar['width'])
    segment = {'kind': 'bit_index', 'index': first} if second is None else {'kind': 'bit_slice', 'high': high, 'low': low}
    width = high - low + 1
    return segments + [segment], {'kind': 'bit' if width == 1 else 'bits', 'width': width, 'signed': 0}


native = json.loads(Path('docs/audits/record-value-structured-clones-20261004/ordinary.json').read_text())
scopes = read('scopes', 'scope-products.json')['rows']
reference_data = read('references', 'reference-products.json')
references = reference_data['rows']
reference_scopes = {row['label']: thaw(row['scope']) for row in reference_data['source_scopes']}
ranges = read('ranges', 'range-products.json')['rows']
root_indices = [i for i, row in enumerate(native['api']) if row['kind'] == 'structured-clone' and row['caller'][2] not in (428, 433)]
rows = copy.deepcopy(json.loads((BASE / 'root-recipes.json').read_text())['rows'])
assert (BASE / 'root-recipes.json').read_bytes() == Path('docs/audits/record-value-clone-roots-20261004/root-recipes.json').read_bytes(), 'complete first source-root prototype recipe identity after separate native replay repair'
if (BASE / 'controls.json').exists() and not any(vars(args).values()):
    controls = json.loads((BASE / 'controls.json').read_text())
    assert [row['command'][-1] for row in controls] == ['--omit-root', '--wrong-role', '--same-type-source', '--numeric-preparation']
    for row in controls:
        assert row['command'][:3] == ['python3', '-B', str(BASE / 'verify.py')] and row['status'] == 1 and row['working_directory'] == '.'
        assert row['output'].rstrip().endswith('AssertionError: ' + row['expected_failure'])
if args.omit_root:
    rows.pop()
assert [row['index'] for row in rows] == root_indices, 'every complete original root membership'
expected = {}
# Completed scope validation/copy stages supply only raw preparation spelling;
# their full declared properties and per-layer root identities are source owned.
for scope in scopes:
    values = thaw(scope['recipe']['arguments']); layers = dict(zip(values[::2], values[1::2]))
    selected = [i for i in root_indices if native['api'][i]['caller'][2] == 35 and max(row['index'] for row in scopes if row['index'] < i) == scope['index']]
    stages = []
    for stage in scope['stages']:
        declaration = layers[stage['layer']][stage['name']]
        spec = declaration['type_spec']
        if declaration['role'] in ('input', 'output', 'storage', 'local') and (spec is None or scope_model.type_valid(spec)):
            private = next(row for row in scope['private'] if row['index'] == stage['copy_index'])
            raw = thaw(private['copy'])
            # Existing qualified scope preparation is a closed prerequisite;
            # no structured-clone result participates in this root oracle.
            prepared = None if spec is None else scope_model.prepared_type(spec, raw['type_spec'])
            stages.append((prepared, {'declaration': graph(declaration), 'layer': stage['layer'], 'name': stage['name'], 'whole_private_copy': digest(private)}))
    assert len(selected) == len(stages)
    for index, (prepared, ingredients) in zip(selected, stages):
        expected[index] = (scope, 'scope', 'scope-type', prepared, ingredients, ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', 35])
for reference in references:
    stage = reference['type_stage']
    if stage is not None and stage['record']['caller'][2] == 71:
        product = thaw(reference['expected_product'])
        assert product['path_text'] == ''
        source_binding = reference_scopes[reference['source_scope_matches'][0]][product['root']]
        expected[stage['index']] = (reference, 'reference', 'whole-reference-type', product['type_spec'], {'whole_source_call': reference['source_call'], 'source_binding': graph(source_binding), 'private_root_copies': reference['private_root_copies']}, ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', 71])
for packed in ranges:
    selected = [i for i in root_indices if native['api'][i]['caller'][0] == 'FSM::Package::AggregatePathSupport' and max(row['index'] for row in ranges if row['index'] < i) == packed['index']]
    product = thaw(packed['expected_product'])
    if not product['ok']:
        assert not selected
        continue
    arguments = thaw(packed['original']['before']); root, text = arguments[2], arguments[4]
    segments, leaf = source_path(root, text)
    assert len(selected) == 3
    for index, source, role, line in zip(selected, (segments, leaf, leaf), ('path-segments', 'path-leaf-type', 'range-final-type'), (132, 132, 295)):
        expected[index] = (packed, 'range', role, source, {'whole_source_recipe': packed['source_recipe'], 'complete_prepared_root': graph(root), 'path_text': text}, ['FSM::Package::AggregatePathSupport', 'perl/FSM/Package/AggregatePathSupport.pm', line])
assert set(expected) == set(root_indices)
same_type = next((a, b) for a in rows for b in rows if a['source_role'] == b['source_role'] == 'path-leaf-type' and a['index'] < b['index'] and exact(a['expected_input'], b['expected_input']) and a['source_parent_index'] != b['source_parent_index'])
string_root = next(row['index'] for row in rows if isinstance(row['expected_input'], list) and row['expected_input'][0] == 'hash' and type(row['expected_input'][1].get('width')) is str)
reached = False
for row in rows:
    index = row['index']; parent, parent_kind, role, source, ingredients, caller = expected[index]
    if args.wrong_role and index == rows[0]['index']:
        reached = True; row['source_role'] = 'path-leaf-type'
    if args.same_type_source and index == same_type[0]['index']:
        reached = True; row['source_parent_index'] = same_type[1]['source_parent_index']; row['whole_source_parent'] = same_type[1]['whole_source_parent']
    if args.numeric_preparation and index == string_root:
        reached = True; row['expected_input'][1]['width'] = int(row['expected_input'][1]['width'])
    assert row['source_role'] == role and row['source_parent_kind'] == parent_kind, 'independent complete root source role'
    assert row['source_parent_index'] == parent['index'] and row['whole_source_parent'] == digest(parent), 'exact own source parent despite identical type values'
    assert exact(row['ingredients'], ingredients), 'whole declaration/private/source-call/root ingredients'
    assert exact(row['expected_input'], graph(source)), 'whole source root raw preparation primitive kinds'
    actual = native['api'][index]
    assert row['caller'] == actual['caller'] == caller
    assert row['helper'] == actual['helper'] == parent['original']['helper'] and row['parse'] == actual['parse'] == parent['original']['parse']
    arguments = thaw(actual['before'])
    assert len(arguments) == 2 and arguments[0] == 'FSM::Package::AggregatePathSupport' and exact(graph(arguments[1]), row['expected_input']), 'whole own original root input/source identity'
assert Counter(row['source_role'] for row in rows) == {'scope-type': 115, 'whole-reference-type': 40, 'path-segments': 431, 'path-leaf-type': 431, 'range-final-type': 431}
assert sum(row['expected_input'] is None for row in rows) == 2
assert not any((args.wrong_role, args.same_type_source, args.numeric_preparation)) or reached
run = subprocess.run(['python3', '-B', str(BASE / 'replay_paths.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS all1448 whole original source/private-preparation roots:115 scope types including two nulls,40 whole references,431 paths each with segments/leaf/final type. Independent subtree inventory and exact own source/context/primitive kind allocation retain; identical-type wrong-source controls reject. Full8251 recursive tree modeling remains open.')
