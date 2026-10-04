"""Full source/stage/numeric-kind/native scope product reader and falsification."""
import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path
from model import source_projection, thaw
from source_recipes import graph, recipes

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
for option in ('omit-product', 'swap-role', 'swap-mask', 'numeric-private-width', 'trust-private-product'):
    parser.add_argument('--' + option, action='store_true')
args = parser.parse_args()

def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}

def exact(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return set(a) == set(b) and all(exact(a[key], b[key]) for key in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(exact(x, y) for x, y in zip(a, b))
    return a == b

if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert identity((BASE / name).read_bytes()) == row, name
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == 'd79e5e19f05cf2eeda97cee384e98371f153e80c' and len(binding['sources']) == 21
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
        for old, new in row['replacements']:
            assert text.count(old) == 1
            text = text.replace(old, new)
        assert text == row['after'] == Path(row['path']).read_text(), 'exact current scope document transform'
else:
    assert all(binding['sources'][path]['body'] == Path(path).read_text() for path in mutable)
for archive in ('record-value-runtime-20261004', 'record-value-fields-20261004',
        'record-value-copy-fields-20261004', 'record-value-actors-20261004', 'record-value-field-join-20261004',
        'record-value-replay-portability-20261004'):
    directory = Path('docs/audits') / archive
    manifest = json.loads((directory / 'manifest.json').read_text())
    assert {p.name for p in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert identity((directory / name).read_bytes()) == row, archive + '/' + name
    capture = json.loads((directory / ('join.json' if archive == 'record-value-field-join-20261004' else 'binding.json')).read_text())
    for path, row in capture['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body'], 'whole original/current implementation continuity'
history = json.loads((BASE / 'scope-source-history.json').read_text())
raw = subprocess.check_output(['git', 'show', history['revision'] + ':' + history['path']])
assert identity(raw) == {'bytes': history['bytes'], 'sha256': history['sha256']}
assert raw.decode() == history['body'] == binding['sources'][history['path']]['body']
source = binding['sources']['t/1986-isf-record-port-value-gates.t']['body']
for token in ('outer => {', 'local => $local || {}', "packet => {role => 'local', type_spec => undef}",
        "packet => {role => 'output', type_spec => $types{nested}}", "packet => {role => 'input', type_spec => undef}",
        "['cyclic member'", "['duplicate order'", "surprise => 1", "role => 'inout'", '(set value.flag 1)'):
    assert token in source, 'source-owned complete declaration/control recipe: ' + token
assert exact(recipes(), json.loads((BASE / 'source-recipes.json').read_text()))
data = json.loads((BASE / 'scope-products.json').read_text())
raw = Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_bytes()
assert identity(raw) == data['native_input']
native = json.loads(raw)
control = json.loads((BASE / 'private-control.json').read_text())
assert exact(control['original_private_copy'], native['copies'][control['copy_index']])
assert control['original_private_copy']['kind'] == 'metadata-private'
candidate = thaw(control['original_private_copy']['copy'])
for segment in control['copy_path']:
    candidate = candidate[segment]
assert exact(graph(candidate), control['candidate'])
assert exact(graph(source_projection(candidate)), graph(source_projection(thaw(control['expected_scope_type']))))
assert not exact(control['candidate'], control['expected_scope_type'])
selected = [(i, row) for i, row in enumerate(native['api']) if row['kind'] == 'scope']
rows = data['rows'][:-1] if args.omit_product else data['rows']
assert len(rows) == len(selected) == 40, 'every original scope caller/argument/product outcome membership'

def check_spelling(source, private, product):
    assert set(source) == set(private) == set(product)
    for key, child in source.items():
        if key in ('width', 'signed'):
            assert int(private[key]) == child
            required = child if key == 'signed' and source['kind'] in ('record', 'list') else private[key]
            assert exact(product[key], required), 'exact preparation kinds and explicit aggregate numerical signed fact'
        elif key == 'members':
            assert set(child) == set(private[key]) == set(product[key])
            for name in child:
                check_spelling(child[name], private[key][name], product[key][name])
        elif key == 'items':
            assert len(child) == len(private[key]) == len(product[key])
            for a, b, c in zip(child, private[key], product[key]):
                check_spelling(a, b, c)
        else:
            assert exact(child, private[key]) and exact(child, product[key])

for (index, original), row, recipe in zip(selected, rows, recipes()):
    assert row['index'] == index and exact(row['original'], original) and exact(row['recipe'], recipe)
    assert exact(original['before'], original['after']), 'whole scope caller first-touch kinds/references stay unchanged'
    assert original['warnings'] == [] and original['accepted'] == recipe['accepted']
    assert exact(graph(source_projection(thaw(original['before']))), recipe['arguments'])
    private = [dict(value, index=i) for i, value in enumerate(native['copies']) if value['api'] == index
        and value['kind'] == 'value-private' and value['caller'] == ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', 29]]
    assert exact(row['private'], private), 'all own original per-root native copy stages'
    actual = copy.deepcopy(original['result'])
    if recipe['accepted']:
        values = thaw(recipe['arguments']); inputs = dict(zip(values[::2], values[1::2]))
        effective = {**inputs['outer'], **inputs['local']}
        product = thaw(row['expected_product'])
        assert exact(source_projection(product), effective), 'whole detached source identity/nearest masks/roles/order/properties'
        stages = [(layer, name) for layer in ('outer', 'local') for name in sorted(inputs[layer])]
        assert len(stages) == len(private) == len(row['stages'])
        for (layer, name), stage, receipt in zip(stages, private, row['stages']):
            assert receipt == {'layer': layer, 'name': name, 'copy_index': stage['index']}
            binding_source = inputs[layer][name]
            assert exact(stage['before'], graph(thaw(original['before'])[1 if layer == 'outer' else 3][name]))
            raw_binding = thaw(stage['copy'])
            assert exact(graph(source_projection(raw_binding)), graph(binding_source))
            if layer == 'outer' and name in inputs['local']:
                continue
            assert set(product[name]) == {'role', 'type_spec'} and product[name]['role'] == binding_source['role']
            if binding_source['type_spec'] is None:
                assert product[name]['type_spec'] is None
            else:
                check_spelling(binding_source['type_spec'], raw_binding['type_spec'], product[name]['type_spec'])
        changed = thaw(actual)
        if args.swap_role and row['label'] == 'resolved-alias':
            changed['output']['role'] = 'input'
        if args.swap_mask and row['label'] == 'local-unresolved':
            changed['packet'] = copy.deepcopy(thaw(native['api'][147]['result'])['packet'])
        if args.numeric_private_width and row['label'] == 'resolved-alias':
            changed['held']['type_spec']['members']['data']['width'] = 7
        if args.trust_private_product and row['label'] == 'resolved-alias':
            assert exact(graph(changed['held']['type_spec']), control['expected_scope_type'])
            changed['held']['type_spec'] = copy.deepcopy(candidate)
        actual = graph(changed)
    else:
        assert row['expected_product'] is None and original['result'] is None
    assert exact(actual, row['expected_product']), 'whole original source/stage scope product and exact primitive kinds: ' + row['label']
run = subprocess.run(['python3', '-B', 'docs/audits/record-value-replay-portability-20261004/portable_replay.py', '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS every original forty complete scope source/caller/argument/private-stage/product graph: twenty-seven preparations/thirteen refusals, nearest masks/roles, recursive source identities and exact private width/signed kinds. All caller graphs preserve. All prior three semantic readers/twelve RED controls conserve. Native cause/copy assurance and reference/copy/core products remain owned.')
