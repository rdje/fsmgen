"""Whole source/reference/stage/strict-identity copy product reader."""
import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path
from model import helpers, source_reference
from source_calls import graph_source, recipes

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
for option in ('omit-product', 'omit-stage', 'swap-role', 'wrong-zero', 'trust-payload', 'numeric-caller-width'):
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
assert binding['revision'] == '347de70015a8e65fead9b5a16d0acc4e4e766a8f' and len(binding['sources']) == 21
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
        assert text == row['after'] == Path(row['path']).read_text(), 'exact current copy document transform'
else:
    assert all(binding['sources'][path]['body'] == Path(path).read_text() for path in mutable)
for archive in ('record-value-runtime-20261004', 'record-value-fields-20261004', 'record-value-copy-fields-20261004',
        'record-value-field-join-20261004', 'record-value-actors-20261004', 'record-value-replay-portability-20261004',
        'record-value-scopes-20261004', 'record-value-references-20261004'):
    directory = Path('docs/audits') / archive
    manifest = json.loads((directory / 'manifest.json').read_text())
    assert {p.name for p in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert identity((directory / name).read_bytes()) == row, archive + '/' + name
    capture = json.loads((directory / ('join.json' if archive == 'record-value-field-join-20261004' else 'binding.json')).read_text())
    for path, row in capture['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
owners = json.loads((BASE / 'owners.json').read_text())
assert len(owners) == 2
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
for task in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()):
    for owner in owners:
        start = task.index('- ID: `' + owner['owner'] + '`')
        end = task.index('\n- ID:', start + 1)
        assert task[start:end] == owner['node'] and 'Status: `done`' in owner['node']
assert exact(recipes(), json.loads((BASE / 'source-recipes.json').read_text()))
source = binding['sources']['t/1986-isf-record-port-value-gates.t']['body']
for text in ("qw(renamed reordered signed_data four two bit_kind)", "context => 'forged write'", "context => 'literal'", "context => 'expression'", "context => 'hostile'", "$value->{width} = 9", "copy($scope, 'old', 'held')", "copy($scope, 'scalar', 'scalar')"):
    assert text in source, 'whole exact original source control recipe: ' + text
data = json.loads((BASE / 'copy-products.json').read_text())
raw = Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_bytes()
assert identity(raw) == data['native_input']
native = json.loads(raw)
selected = [(i, row) for i, row in enumerate(native['api']) if row['kind'] == 'copy']
rows = copy.deepcopy(data['rows'])
if args.omit_product:
    rows.pop()
if args.omit_stage:
    rows[-1]['private_stages'].pop()
assert len(rows) == len(selected) == len(recipes()) == 22, 'whole original copy call/product/source membership'
assert sum(len(row['private_stages']) for row in rows) == 41, 'every conditional own source/target private clone stage'
control = json.loads((BASE / 'payload-control.json').read_text())
assert exact(control['whole_original_payload'], native['api'][control['payload_index']])
payload_arguments = helpers.thaw(control['whole_original_payload']['before'])
assert exact(graph_source(helpers.source_projection(payload_arguments[1])), control['source_type'])
assert exact(graph_source(helpers.source_projection(payload_arguments[2])), control['target_type'])
assert control['whole_original_payload']['accepted'] == 1 and exact(control['whole_original_payload']['result'], 1)
success_labels = {'first-touch', 'input-storage-alias', 'storage-output-alias', 'input-output-alias', 'imported-local'}
zero_labels = {'storage-prior-contract', 'scalar-prior-contract', 'literal-prior-contract'}
for position, ((index, original), row, recipe) in enumerate(zip(selected, rows, recipes())):
    assert row['index'] == index and row['position'] == position and exact(row['recipe'], recipe)
    bound = copy.deepcopy(original)
    if args.numeric_caller_width and row['recipe']['label'] == 'first-touch':
        value = helpers.thaw(bound['before']); value[1]['width'] = 8; bound['before'] = graph_source(value)
    assert exact(row['original'], bound), 'entire original caller/first-touch/operation record authority'
    assert exact(original['before'], original['after']) and original['warnings'] == []
    assert original['caller'] == recipe['caller'] and original['helper'] == recipe['helper']
    values = helpers.thaw(original['before']); arguments = dict(zip(values[::2], values[1::2]))
    assert set(arguments) == {'source', 'target', 'context'}
    projected = ['source', source_reference(arguments['source']), 'target', source_reference(arguments['target']), 'context', arguments['context']]
    assert exact(graph_source(projected), recipe['arguments']), 'complete source/type/property/role/reference descriptor identity'
    stage_plan = [(name, line) for name, line in (('source', 101), ('target', 102)) if arguments[name] is not None]
    assert len(row['private_stages']) == len(stage_plan)
    for (name, line), stage in zip(stage_plan, row['private_stages']):
        clone = stage['copy']
        assert stage['name'] == name and exact({key: value for key, value in clone.items() if key != 'index'}, native['copies'][clone['index']])
        assert clone['api'] == index and clone['kind'] == 'value-private' and clone['caller'] == ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', line]
        assert exact(clone['before'], graph_source(arguments[name]))
        assert exact(source_reference(helpers.thaw(clone['copy'])), source_reference(arguments[name])), 'full private stage source meanings and raw body authority'
    end = next((i for i in range(index + 1, len(native['api'])) if native['api'][i]['kind'] in ('scope', 'reference', 'copy')), len(native['api']))
    assert exact(row['operation_span'], [{'index': i, 'record': native['api'][i]} for i in range(index + 1, end)])
    intended = {'accepted': 1, 'product': 1} if recipe['label'] in success_labels else {'accepted': 1, 'product': 0} if recipe['label'] in zero_labels else {'accepted': 0, 'product': None}
    assert exact({key: row['meaning'][key] for key in intended}, intended), 'separate source-owned success/zero/refusal classification'
    source_ref, target_ref = projected[1], projected[3]
    if recipe['label'] in success_labels:
        assert source_ref['type_spec'] == target_ref['type_spec'] and source_ref['type_spec']['kind'] == 'record'
        assert target_ref['role'] != 'input' and source_ref['path_text'] == target_ref['path_text'] == ''
    if recipe['label'].startswith('identity:') or recipe['label'] in ('explicit-state', 'nested-flat', 'nested-list-order'):
        assert source_ref['type_spec']['width'] == target_ref['type_spec']['width'] == 8
        assert source_ref['type_spec'] != target_ref['type_spec'], 'whole recursive source identity must distinguish equal widths'
    if recipe['label'] == 'contradictory-width':
        assert source_ref['width'] == 9 and source_ref['type_spec']['width'] == 8
    candidate = {'accepted': original['accepted'], 'product': original['result']}
    if args.swap_role and recipe['label'] == 'input-target':
        candidate = {'accepted': 1, 'product': 1}
    if args.wrong_zero and recipe['label'] == 'storage-prior-contract':
        candidate['product'] = 1
    if args.trust_payload and index == control['copy_index']:
        assert exact(row['meaning'], control['required_copy'])
        candidate = control['candidate']
    assert exact(candidate, intended), 'entire strict copy product/refusal/prior-contract truth with exact primitive kinds'
assert sum(row['meaning']['accepted'] for row in rows) == 8
assert sum(row['meaning']['product'] == 1 for row in rows) == 5 and sum(row['meaning']['product'] == 0 for row in rows) == 3
run = subprocess.run(['python3', '-B', str(BASE / 'replay_references.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS all22 full original source/caller/reference/conditional41 private-stage/strict-copy products: five same-resolved-record successes, three scalar/storage/literal zeros, fourteen refusals. Caller kinds preserve, equal-width source identities stay distinct, actual narrower payload truth cannot copy. Completed scope/reference owners and exact full semantic/control replays conserve; core API and native copy/cause assurance remain owned.')
