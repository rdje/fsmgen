"""Independent complete value API/source/owner/native clone/field join."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
for option in ('omit-api', 'omit-copy', 'incomplete-owner', 'swap-field'):
    parser.add_argument('--' + option, action='store_true')
args = parser.parse_args()

def file_identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}

def identity(value):
    return file_identity(json.dumps(value, sort_keys=True, separators=(',', ':')).encode())

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
        assert file_identity((BASE / name).read_bytes()) == row, name
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == '7c2f1f40b1b376c75a43e7b272309dd9ba3bb4ef' and len(binding['sources']) == 21
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
        for old, new in row['replacements']:
            assert text.count(old) == 1
            text = text.replace(old, new)
        assert text == row['after'] == Path(row['path']).read_text(), 'exact current value-join doc transform'
else:
    assert all(binding['sources'][path]['body'] == Path(path).read_text() for path in mutable)
data = json.loads((BASE / 'join.json').read_text())
assert data['revision'] == binding['revision']
assert [child['archive'] for child in data['children']] == ['record-value-scopes-20261004', 'record-value-references-20261004', 'record-value-copies-20261004']
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
tasks = [subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()]
if args.incomplete_owner:
    tasks[-1] = tasks[-1].replace(data['children'][0]['node'], data['children'][0]['node'].replace('Status: `done`', 'Status: `pending`'))
for child in data['children']:
    for task in tasks:
        start = task.index('- ID: `' + child['owner'] + '`')
        end = task.index('\n- ID:', start + 1)
        assert task[start:end] == child['node'] and 'Status: `done`' in child['node'], 'exact completed whole value semantic owner'
for archive in ('record-value-runtime-20261004', 'record-value-fields-20261004', 'record-value-copy-fields-20261004',
        'record-value-field-join-20261004', 'record-value-actors-20261004', 'record-value-replay-portability-20261004',
        'record-value-scopes-20261004', 'record-value-references-20261004', 'record-value-copies-20261004'):
    directory = Path('docs/audits') / archive
    raw = (directory / 'manifest.json').read_bytes()
    manifest = json.loads(raw)
    assert {p.name for p in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert file_identity((directory / name).read_bytes()) == row, archive + '/' + name
    capture = json.loads((directory / ('join.json' if archive == 'record-value-field-join-20261004' else 'binding.json')).read_text())
    for path, row in capture['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
    for child in data['children']:
        if child['archive'] == archive:
            assert file_identity(raw) == child['manifest']
            assert file_identity((directory / child['product_file']).read_bytes()) == child['whole_product_ledger']
support = {'native': ('record-value-runtime-20261004', 'ordinary.json'),
    'source_models': ('record-value-copy-fields-20261004', 'source-models.json'),
    'all_original_fields': ('record-value-copy-fields-20261004', 'fields.json'),
    'authored_types_layouts': ('record-value-fields-20261004', 'authored-models.json'),
    'whole_actors': ('record-value-actors-20261004', 'actor-models.json'),
    'portable_field_actor_join': ('record-value-replay-portability-20261004', 'join.json')}
assert set(data['support']) == set(support)
for name, (directory, file) in support.items():
    assert data['support'][name] == file_identity((Path('docs/audits') / directory / file).read_bytes())
native = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
fields = json.loads(Path('docs/audits/record-value-copy-fields-20261004/fields.json').read_text())
apis = data['apis'][:-1] if args.omit_api else data['apis']
copies = data['copies'][:-1] if args.omit_copy else data['copies']
assert [row['index'] for row in apis] == [i for i, row in enumerate(native['api']) if row['kind'] in ('scope', 'reference', 'copy')], 'every whole original value API record/model/product membership'
assert len(apis) == len({row['index'] for row in apis}) == 130
assert [row['index'] for row in copies] == [i for i, row in enumerate(native['copies']) if row['kind'] == 'value-private'], 'every whole original value-private clone/field membership'
assert len(copies) == len({row['index'] for row in copies}) == 233
api_models, copy_models = {}, {}
for child in data['children']:
    model = json.loads((Path('docs/audits') / child['archive'] / child['product_file']).read_text())
    for row in model['rows']:
        api_models[row['index']] = (child['archive'], row)
        private = row['private'] if child['archive'] == 'record-value-scopes-20261004' else row['private_root_copies'] if child['archive'] == 'record-value-references-20261004' else [stage['copy'] for stage in row['private_stages']]
        for clone in private:
            copy_models[clone['index']] = (child['archive'], row['index'], clone)
for row in apis:
    archive, model = api_models[row['index']]
    assert row['archive'] == archive and row['original'] == identity(native['api'][row['index']])
    assert exact(model['original'], native['api'][row['index']])
    assert row['whole_source_stage_model'] == identity(model), 'whole source/type/property/kind/stage/outcome semantics'
for position, row in enumerate(copies):
    archive, api, model = copy_models[row['index']]
    original = native['copies'][row['index']]
    field = fields['rows'][row['index']]
    if args.swap_field and position == 0:
        field = fields['rows'][row['index'] + 1]
    assert exact(model, dict(original, index=row['index'])), 'whole original clone/current model graph/kind/source identity'
    expected = {'index': row['index'], 'archive': archive, 'api': api, 'whole_model_copy': identity(model),
        'whole_original_copy': identity(original), 'whole_source_field_record': identity(field),
        'before_graph': identity(original['before']), 'copy_graph': identity(original['copy']),
        'kind': original['kind'], 'caller': original['caller'], 'helper': original['helper'], 'parse': original['parse']}
    assert exact(row, expected), 'complete source/private-field/native graph/site/model allocation'
run = subprocess.run(['python3', '-B', str(BASE / 'replay_copy.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS complete current21/three-completed-owner/original130 value API/model/product and233 value-private graph/field join. Complete copy ordinary/six RED replays conserve, with all nested reference/scope/field/actor semantics and exact process-only portability. Only value API product parent closes; core operations and native copy/cause assurance remain owned.')
