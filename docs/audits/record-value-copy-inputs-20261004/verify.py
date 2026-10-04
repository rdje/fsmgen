"""Independent source/whole population/field/legacy-kind contract reader."""
import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-copy-inputs-20261004')
parser = argparse.ArgumentParser()
for flag in ('omit-copy', 'legacy-authority', 'wrong-model', 'wrong-recipe'):
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
for name in ('runtime', 'copy-fields', 'field-join', 'clones', 'semantic-join', 'original-replay'):
    sealed(Path('docs/audits/record-value-' + name + '-20261004'))
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == 'b63195f3ae231555850de96b5d2412c74b6e4272'
pin = json.loads(Path('docs/audits/record-value-original-replay-20261004/binding.json').read_text())
recipe_path = 't/1960-isf-formal-reservation-coverage.t'
assert set(binding['sources']) == set(pin['sources']) | {recipe_path} and len(binding['sources']) == 22
for path, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert row == {'body': raw.decode(), **identity(raw)}, path
    if path.startswith(('perl/', 't/')):
        assert Path(path).read_bytes() == raw, 'unchanged selected current source: ' + path
updates = json.loads((BASE / 'doc-updates.json').read_text())
assert len(updates) == 1 and updates[0]['path'] == 'docs/book/src/13k-isf-feature-support-matrix.md'
for row in updates:
    assert row['before'] == binding['sources'][row['path']]['body']
    text = row['before']
    for before, after in row['replacements']:
        assert text.count(before) == 1
        text = text.replace(before, after)
    assert text == row['after'], 'exact archived source-contract documentation transformation'
assert len(binding['owners']) == 30
for text in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['task_path']]).decode(), Path(binding['task_path']).read_text()):
    for row in binding['owners']:
        start = text.index('- ID: `' + row['owner'] + '`')
        end = text.index('\n- ID:', start + 1)
        assert text[start:end] == row['node'] and 'Status: `done`' in row['node']
native = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
semantic = json.loads(Path('docs/audits/record-value-semantic-join-20261004/semantics.json').read_text())
fields = json.loads(Path('docs/audits/record-value-copy-fields-20261004/fields.json').read_text())['rows']
data = copy.deepcopy(json.loads((BASE / 'inputs.json').read_text()))
if args.omit_copy:
    data['rows'].pop()
if args.wrong_model:
    data['rows'][0]['semantic'] = copy.deepcopy(data['rows'][1]['semantic'])
expected_indices = [index for index, row in enumerate(native['copies']) if row['kind'] == 'test']
assert [row['index'] for row in data['rows']] == expected_indices and len(expected_indices) == 17, 'every original whole test-copy input/source/field record retains'
assert data['source_models'] == semantic['source_models'], 'complete authenticated authored/source model domains retain'
source = binding['sources']['t/1986-isf-record-port-value-gates.t']['body'].splitlines()
from sys import path as module_path
module_path.insert(0, 'docs/audits/record-value-clones-20261004')
from native import topology, exact
changed = []
widths = {'before': 0, 'after': 0}
for row in data['rows']:
    index = row['index']
    assert exact(row['native'], native['copies'][index])
    assert exact(row['semantic'], semantic['copies'][index]), 'whole own source/field/native semantic assignment retains'
    assert exact(row['semantic']['whole_field'], fields[index])
    caller = row['native']['caller']
    assert caller[:2] == ['main', './t/1986-isf-record-port-value-gates.t'] and 'dclone(' in source[caller[2] - 1]
    before, before_reachable = topology(row['native']['before'])
    after, after_reachable = topology(row['native']['after'])
    legacy, legacy_reachable = topology(row['native']['copy'])
    assert exact(row['native']['before'], row['native']['after'])
    assert before_reachable(row['native']['before'], '') == after_reachable(row['native']['after'], '')
    assert len(before_reachable(row['native']['before'], '')) == row['native']['original_reference_count']
    assert len(legacy_reachable(row['native']['copy'], '')) == row['native']['copy_reference_count']
    assert row['native']['shared_with_original'] == 0 and row['native']['accepted'] == 1
    pending = [row['native']['before']]
    while pending:
        node = pending.pop()
        if type(node) is not list:
            continue
        assert node[0] in ('hash', 'array'), 'original test-copy inputs are declared plain trees; supplementary cycle/sharing probes remain necessary'
        pending.extend(node[1].values() if node[0] == 'hash' else node[1])
    for stage in widths:
        widths[stage] += len(row['semantic']['whole_field'][stage])
    if not exact(row['native']['before'], row['native']['copy']):
        changed.append(index)
    if args.legacy_authority:
        assert exact(row['native']['before'], row['native']['copy']), 'actual original Storable copy cannot be kind-preserving baseline authority'
recipes = copy.deepcopy(json.loads((BASE / 'recipes.json').read_text()))
if args.wrong_recipe:
    recipes[0]['body'] = recipes[1]['body']
expected_names = ['source_value_copy', 'snapshot_graph', 'input_snapshot', 'source_references', 'source_copy']
assert [row['name'] for row in recipes] == expected_names
recipe_source = binding['sources'][recipe_path]['body'].splitlines(keepends=True)
for row in recipes:
    body = ''.join(recipe_source[row['start_line'] - 1:row['end_line']])
    assert row['source_path'] == recipe_path and row['body'] == body, 'exact named existing plain copy/snapshot/identity recipe source authority'
    assert identity(body.encode()) == {key: row[key] for key in ('bytes', 'sha256')}
if (BASE / 'controls.json').exists() and not any(vars(args).values()):
    controls = json.loads((BASE / 'controls.json').read_text())
    assert [row['command'] for row in controls] == [['python3', '-B', str(BASE / 'verify.py'), '--' + flag] for flag in ('omit-copy', 'legacy-authority', 'wrong-model', 'wrong-recipe')]
    for row in controls:
        assert row['working_directory'] == '.' and row['status'] == 1
        assert row['output'].rstrip().endswith('AssertionError: ' + row['expected_failure'])
print('PASS complete original17 test-copy input/source/field/recipe contract; actual legacy kind-changing indices=' + str(changed) + '; width occurrences=' + str(widths) + '. Candidate topology/native/actual-copy execution and permanent hot repairs remain open.')
