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

BASE = Path('docs/audits/record-value-core-join-20261004')
parser = argparse.ArgumentParser()
for flag in ('omit-call', 'same-model', 'wrong-family', 'numeric-product', 'omit-private'):
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
assert binding['revision'] == '3b00150fd1d4899144b18aac1daf930616a2b744' and len(binding['sources']) == 21
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
for name in ('runtime', 'fields', 'copy-fields', 'field-join', 'actors', 'replay-portability', 'scopes', 'references', 'copies', 'api-join', 'captures', 'snapshots', 'ranges', 'structured-clones', 'clones', 'clone-roots', 'clone-paths', 'clone-root', 'clone-tree', 'clone-join', 'identities'):
    directory = Path('docs/audits/record-value-' + name + '-20261004')
    sealed(directory)
    prior = json.loads((directory / ('join.json' if name == 'field-join' else 'binding.json')).read_text())
    for path, row in prior['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
owners = json.loads((BASE / 'owners.json').read_text())
assert len(owners) == 14
for owner in owners:
    for task in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()):
        start = task.index('- ID: `' + owner['owner'] + '`'); end = task.index('\n- ID:', start + 1)
        assert task[start:end] == owner['node'] and 'Status: `done`' in owner['node']

previous = Path('docs/audits/record-value-identities-20261004')
prefix = json.loads((BASE / 'reader-prefix.json').read_text())
assert prefix['before'] == (previous / 'verify.py').read_text().split('\nfrom source_roots import native_graph', 1)[0]
expected_prefix = prefix['before'].replace('record-value-identities-20261004', 'record-value-core-join-20261004').replace("('omit-call', 'trust-width', 'strict-payload', 'same-source', 'numeric-kind')", "('omit-call', 'same-model', 'wrong-family', 'numeric-product', 'omit-private')").replace('cd7d0a951d9bd792ef82bf6f171c59481d62c264', binding['revision']).replace("'clone-tree', 'clone-join')", "'clone-tree', 'clone-join', 'identities')").replace('len(owners) == 11', 'len(owners) == 14')
assert prefix['after'] == expected_prefix and (BASE / 'verify.py').read_text().startswith(prefix['after'])
assert (BASE / 'source_roots.py').read_bytes() == (previous / 'source_roots.py').read_bytes()
native = read('runtime', 'ordinary.json')
specifications = {
    'capture': ('captures', 'capture-products.json'),
    'snapshot': ('snapshots', 'snapshot-products.json'),
    'range': ('ranges', 'range-products.json'),
    'structured-clone': ('clone-join', 'join-products.json'),
    'identity': ('identities', 'identity-products.json'),
    'payload': ('identities', 'identity-products.json'),
}
models = {}
for family, filename in set(specifications.values()):
    data = read(family, filename)['rows']
    models[family] = {row['index']: row for row in data}
    assert len(models[family]) == len(data)
rows = copy.deepcopy(json.loads((BASE / 'core-products.json').read_text())['rows'])
indices = [i for i, row in enumerate(native['api']) if row['kind'] in specifications]
assert sorted(i for family in models.values() for i in family) == indices
if args.omit_call:
    rows.pop()
assert [row['index'] for row in rows] == indices, 'complete original core joined membership'
if args.same_model:
    seen = {}
    for row in rows:
        key = (row['family'], json.dumps(row['whole_native'], sort_keys=True, separators=(',', ':')))
        if key in seen:
            first = seen[key]
            first['child_index'], row['child_index'] = row['child_index'], first['child_index']
            first['whole_child_model'], row['whole_child_model'] = row['whole_child_model'], first['whole_child_model']
            break
        seen[key] = row
    else:
        raise AssertionError('actual identical whole native core records required')
    assert sorted(row['child_index'] for row in rows) == indices
if args.wrong_family:
    rows[0]['family'] = 'identities'
if args.numeric_product:
    first = rows[0]['expected_product'][1][0][1]
    assert type(first['width']) is int
    first['width'] = str(first['width'])
if args.omit_private:
    rows[0]['links']['private'] = []

private, fields, snapshot_links, range_links, clone_links, identity_links = [], [], [], [], [], []
for row in rows:
    index = row['index']; actual = native['api'][index]
    family, _ = specifications[actual['kind']]
    assert row['kind'] == actual['kind'] and row['family'] == family, 'exact native core role/completed source model family'
    model = models[family][index]
    assert row['child_index'] == index and row['whole_child_model'] == digest(model), 'exact own core source model despite identical whole native values'
    if family in ('captures', 'snapshots', 'ranges'):
        expected_product = model['expected_product']
        assert exact(actual, model['original'])
    elif family == 'clone-join':
        expected_product = model['source_product']['result']
        assert exact(actual, model['source_product'])
    else:
        expected_product = model['expected_result']
        assert exact(actual['before'], model['expected_arguments']) and exact(actual['after'], model['expected_arguments'])
        assert actual['caller'] == model['caller'] and actual['helper'] == model['helper'] and actual['parse'] == model['parse']
    assert exact(row['whole_native'], actual), 'whole original core native context/input/output/kind/error observation retains'
    assert exact(row['expected_product'], expected_product) and exact(expected_product, actual['result']), 'complete core source-modeled product primitive kinds'
    if family in ('captures', 'snapshots'):
        stage = model['private']; field = model['whole_field_record']
        expected_links = {'private': [stage], 'fields': [field]}
        assert stage['api'] == index and field['api_index'] == index and stage['index'] == field['index']
        assert exact({k: v for k, v in stage.items() if k != 'index'}, native['copies'][stage['index']])
        assert stage['kind'] == 'metadata-private' and stage['shared_with_original'] == 0
        private.append(stage['index']); fields.append(field['index'])
        if family == 'snapshots':
            capture = models['captures'][model['capture_index']]
            assert digest(capture) == model['whole_capture_model']
            expected_links.update(capture_index=model['capture_index'], whole_capture_model=model['whole_capture_model'])
            snapshot_links.append((index, model['capture_index']))
        else:
            expected_links.update(source_interface=model['source_interface'], source_origins=model['source_origins'], expected_refusal=model['expected_refusal'])
            assert actual['accepted'] == int(model['expected_refusal'] is None)
    elif family == 'ranges':
        expected_links = {'source_recipe': model['source_recipe'], 'type_stage': model['type_stage']}
        if model['type_stage'] is not None:
            stage = model['type_stage']; assert stage['index'] in models['clone-join']
            assert exact(stage['record'], native['api'][stage['index']])
            range_links.append((index, stage['index']))
    elif family == 'clone-join':
        expected_links = {key: model[key] for key in ('root_index', 'source_path', 'parent_index', 'whole_source_root', 'joint', 'referents')}
        clone_links.append(index)
    else:
        expected_links = {key: model[key] for key in ('source_parent_index', 'whole_source_parent', 'source_recipe', 'witnesses')}
        identity_links.append(index)
    assert exact(row['links'], expected_links), 'all own core source/private/field/handoff/stage links retain'
    assert set(row) == {'index', 'kind', 'family', 'child_index', 'whole_child_model', 'whole_native', 'expected_product', 'links'}
assert Counter(row['kind'] for row in rows) == {'capture': 227, 'snapshot': 220, 'range': 437, 'structured-clone': 8251, 'identity': 14, 'payload': 4}
assert len(indices) == 9153 and len(snapshot_links) == 220 and len(range_links) == 431 and len(clone_links) == 8251 and len(identity_links) == 18
assert sorted(private) == sorted(fields) == [i for i, row in enumerate(native['copies']) if row['kind'] == 'metadata-private'] and len(private) == 447
if (BASE / 'controls.json').exists() and not any(vars(args).values()):
    controls = json.loads((BASE / 'controls.json').read_text())
    assert [row['command'][-1] for row in controls] == ['--' + flag for flag in ('omit-call', 'same-model', 'wrong-family', 'numeric-product', 'omit-private')]
    for row in controls:
        assert row['command'][:3] == ['python3', '-B', str(BASE / 'verify.py')] and row['status'] == 1 and row['working_directory'] == '.'
        assert row['output'].rstrip().endswith('AssertionError: ' + row['expected_failure'])
run = subprocess.run(['python3', '-B', str(BASE / 'replay_core.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS all 9153 original whole core native/source/model/context/product joins: 227 captures/220 snapshots/437 ranges/8251 structured clones/14 strict/four payload calls. All 447 metadata-private clone/field records, 220 source capture handoffs, 431 final type stages and complete clone/identity source paths retain. Source-model allocation/role/primitive/private controls reject, with complete dated child ordinary/RED/native proofs. Only core product parent closes before all actor/API/semantic/helper/consumer/cause assurance.')
