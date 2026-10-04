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

BASE = Path('docs/audits/record-value-clone-join-20261004')
parser = argparse.ArgumentParser()
for flag in ('omit-call', 'same-native', 'wrong-root', 'numeric-kind', 'alias-result'):
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
assert binding['revision'] == '5429120ed9a22bce069562dd4f35e749c4d3383f' and len(binding['sources']) == 21
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
for name in ('runtime', 'fields', 'copy-fields', 'field-join', 'actors', 'replay-portability', 'scopes', 'references', 'copies', 'api-join', 'captures', 'snapshots', 'ranges', 'structured-clones', 'clones', 'clone-roots', 'clone-paths', 'clone-root', 'clone-tree'):
    directory = Path('docs/audits/record-value-' + name + '-20261004')
    sealed(directory)
    prior = json.loads((directory / ('join.json' if name == 'field-join' else 'binding.json')).read_text())
    for path, row in prior['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
owners = json.loads((BASE / 'owners.json').read_text())
assert len(owners) == 8
for owner in owners:
    for task in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()):
        start = task.index('- ID: `' + owner['owner'] + '`'); end = task.index('\n- ID:', start + 1)
        assert task[start:end] == owner['node'] and 'Status: `done`' in owner['node']

from source_roots import native_graph

old_tree = Path('docs/audits/record-value-clone-tree-20261004')
prefix = json.loads((BASE / 'reader-prefix.json').read_text())
assert prefix['before'] == (old_tree / 'verify.py').read_text().split('\nfrom source_roots import native_graph', 1)[0]
expected_prefix = prefix['before'].replace('record-value-clone-tree-20261004', 'record-value-clone-join-20261004').replace("('omit-call', 'omit-key', 'array-order', 'dfs-order', 'wrong-caller', 'same-source', 'numeric-kind', 'alias-result')", "('omit-call', 'same-native', 'wrong-root', 'numeric-kind', 'alias-result')").replace('84f5fbb7bda6aa42258c1bf0043f4e85dd500a15', binding['revision']).replace("'clone-paths', 'clone-root')", "'clone-paths', 'clone-root', 'clone-tree')").replace('len(owners) == 6', 'len(owners) == 8')
assert prefix['after'] == expected_prefix and (BASE / 'verify.py').read_text().startswith(prefix['after'])
assert (BASE / 'source_roots.py').read_bytes() == (old_tree / 'source_roots.py').read_bytes()
legacy = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
ordinary = json.loads(Path('docs/audits/record-value-structured-clones-20261004/ordinary.json').read_text())
bad = json.loads(Path('docs/audits/record-value-structured-clones-20261004/alias-result.json').read_text())
native = bad if args.alias_result else ordinary
source_rows = json.loads((old_tree / 'tree-products.json').read_text())['rows']
source = {row['index']: row for row in source_rows}
roots = {row['index']: row for row in json.loads(Path('docs/audits/record-value-clone-root-20261004/root-recipes.json').read_text())['rows']}
original_referents = json.loads(Path('docs/audits/record-value-clones-20261004/referents.json').read_text())['ordinary']
referents = {row['index']: row for row in original_referents}
rows = copy.deepcopy(json.loads((BASE / 'join-products.json').read_text())['rows'])
indices = [i for i, row in enumerate(legacy['api']) if row['kind'] == 'structured-clone']
assert [i for i, row in enumerate(ordinary['api']) if row['kind'] == 'structured-clone'] == indices
assert [row['index'] for row in source_rows] == [row['index'] for row in original_referents] == indices
if args.omit_call:
    rows.pop()
assert [row['index'] for row in rows] == indices, 'complete original clone joined membership'
if args.same_native:
    seen = {}
    for row in rows:
        record = ordinary['api'][row['index']]
        key = json.dumps(record, sort_keys=True, separators=(',', ':'))
        if key in seen:
            first = seen[key]
            assert exact(ordinary['api'][first['index']], record)
            first['native_index'], row['native_index'] = row['native_index'], first['native_index']
            break
        seen[key] = row
    else:
        raise AssertionError('actual complete identical native records required for allocation control')
    assert sorted(row['native_index'] for row in rows) == indices, 'control preserves native membership and every complete native value'
if args.wrong_root:
    first, second = next((a, b) for a in source_rows for b in source_rows if a['index'] < b['index'] and a['root_index'] != b['root_index'] and exact(a['record']['result'], b['record']['result']))
    rows[indices.index(first['index'])]['root_index'] = second['root_index']
if args.numeric_kind:
    target = next(row for row in rows if row['source_path'] and row['source_path'][-1] == 'width' and type(row['source_product']['result']) is str)
    target['source_product']['result'] = int(target['source_product']['result'])

joined = []
for row in rows:
    index = row['index']; model = source[index]; actual = native['api'][index]
    assert row['source_index'] == row['native_index'] == row['legacy_index'] == index, 'exact own original native/source slot despite identical full records'
    root = roots[model['root_index']]
    assert row['root_index'] == model['root_index'] and exact(row['whole_source_root'], digest(root)), 'exact own complete source root and parent allocation'
    assert exact(row['source_path'], model['source_path']) and row['parent_index'] == model['parent_index'], 'complete original recursive source path/parent allocation'
    assert exact(row['source_product'], model['record']), 'whole joined source product primitive kinds and every field'
    assert exact(legacy['api'][index], model['record']) and exact(native_graph.base(actual), model['record']), 'complete original/new native products match whole source tree'
    reached = {'index': index, **native_graph.check_joint(actual)}
    assert exact(reached, referents[index]) and exact(row['referents'], reached), 'whole actual reachable referents join completed native proof'
    assert exact(row['joint'], model['joint']) and exact(actual['joint_input_result'], model['joint']), 'whole joined source/native detached joint topology'
    assert row['whole_tree_record'] == digest(model) and row['whole_native_record'] == digest(actual) and row['whole_legacy_record'] == digest(legacy['api'][index]), 'all whole original/source/native record identities'
    assert set(row) == {'index', 'source_index', 'native_index', 'legacy_index', 'root_index', 'source_path', 'parent_index', 'whole_source_root', 'whole_tree_record', 'whole_native_record', 'whole_legacy_record', 'source_product', 'joint', 'referents'}
    joined.append(index)
assert joined == indices and len(indices) == 8251 and len(roots) == 1448
conservation = native_graph.conserved(legacy, ordinary, True)
assert exact(conservation, json.loads((BASE / 'native-conservation.json').read_text()))
assert exact(conservation, json.loads(Path('docs/audits/record-value-clones-20261004/legacy-conservation.json').read_text())), 'full complete original native conservation/raw difference inventory retains'
assert Counter(row['kind'] for row in ordinary['api']) == {'scope': 40, 'reference': 68, 'copy': 22, 'capture': 227, 'snapshot': 220, 'range': 437, 'structured-clone': 8251, 'identity': 14, 'payload': 4}
assert not ordinary['warnings'] and len(ordinary['copies']) == 697 and len(ordinary['helpers']) == 43 and len(ordinary['consumers']) == 125 and len(ordinary['parses']) == 4
if (BASE / 'controls.json').exists() and not any(vars(args).values()):
    controls = json.loads((BASE / 'controls.json').read_text())
    assert [row['command'][-1] for row in controls] == ['--' + flag for flag in ('omit-call', 'same-native', 'wrong-root', 'numeric-kind', 'alias-result')]
    for row in controls:
        assert row['command'][:3] == ['python3', '-B', str(BASE / 'verify.py')] and row['status'] == 1 and row['working_directory'] == '.'
        assert row['output'].rstrip().endswith('AssertionError: ' + row['expected_failure'])
run = subprocess.run(['python3', '-B', str(BASE / 'replay_trees.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS complete original8251 clone native/source-tree/joint/referent join from1448 source roots, with exact whole record/source/caller/primitive-kind/parent/slot identity and full9283-call native conservation. Identical-record native permutation and genuine alias provider reject. Whole dated source-tree/native ordinary/RED proofs retain; only structured clone product parent closes before strict identity/payload/core/helper/consumer/cause assurance.')
