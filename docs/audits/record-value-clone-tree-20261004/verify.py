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

BASE = Path('docs/audits/record-value-clone-tree-20261004')
parser = argparse.ArgumentParser()
for flag in ('omit-call', 'omit-key', 'array-order', 'dfs-order', 'wrong-caller', 'same-source', 'numeric-kind', 'alias-result'):
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
assert binding['revision'] == '84f5fbb7bda6aa42258c1bf0043f4e85dd500a15' and len(binding['sources']) == 21
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
for name in ('runtime', 'fields', 'copy-fields', 'field-join', 'actors', 'replay-portability', 'scopes', 'references', 'copies', 'api-join', 'captures', 'snapshots', 'ranges', 'structured-clones', 'clones', 'clone-roots', 'clone-paths', 'clone-root'):
    directory = Path('docs/audits/record-value-' + name + '-20261004')
    sealed(directory)
    prior = json.loads((directory / ('join.json' if name == 'field-join' else 'binding.json')).read_text())
    for path, row in prior['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
owners = json.loads((BASE / 'owners.json').read_text())
assert len(owners) == 6
for owner in owners:
    for task in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()):
        start = task.index('- ID: `' + owner['owner'] + '`'); end = task.index('\n- ID:', start + 1)
        assert task[start:end] == owner['node'] and 'Status: `done`' in owner['node']

from source_roots import native_graph


def inventory(encoded):
    """Enumerate encoded source nodes breadth-first, rebuild bottom-up.

    Tagged path ordering independently determines preorder: every prefix sorts
    before its descendants, hash keys sort lexically, array indexes numerically.
    No production clone or producer recursion supplies this reconstruction.
    """
    pending = [((), encoded)]
    nodes = {}
    while pending:
        path, value = pending.pop(0)
        assert path not in nodes
        if type(value) is not list:
            assert value is None or type(value) in (str, int, float)
            nodes[path] = {'kind': 'scalar', 'value': value}
            continue
        assert len(value) == 2 and value[0] in ('hash', 'array'), 'finite source roots have no reference markers/cycles'
        kind, body = value
        assert type(body) is (dict if kind == 'hash' else list)
        keys = sorted(body) if kind == 'hash' else list(range(len(body)))
        nodes[path] = {'kind': kind, 'keys': keys}
        pending.extend((path + (key,), body[key]) for key in keys)
    rebuilt = {}
    for path in sorted(nodes, key=len, reverse=True):
        node = nodes[path]
        if node['kind'] == 'scalar':
            rebuilt[path] = node['value']
        elif node['kind'] == 'hash':
            rebuilt[path] = ['hash', {key: rebuilt[path + (key,)] for key in node['keys']}]
        else:
            rebuilt[path] = ['array', [rebuilt[path + (i,)] for i in node['keys']]]
    order = sorted(nodes, key=lambda path: tuple((0, key) if type(key) is str else (1, key) for key in path))
    assert order[0] == () and exact(rebuilt[()], encoded), 'full independent source path reconstruction retains every key/order/primitive kind'
    return nodes, rebuilt, order


old = Path('docs/audits/record-value-clone-root-20261004')
prefix = json.loads((BASE / 'reader-prefix.json').read_text())
assert prefix['before'] == (old / 'verify.py').read_text().split('\ndef paths(', 1)[0]
expected_prefix = prefix['before'].replace('record-value-clone-root-20261004', 'record-value-clone-tree-20261004').replace("('omit-root', 'wrong-role', 'same-type-source', 'numeric-preparation')", "('omit-call', 'omit-key', 'array-order', 'dfs-order', 'wrong-caller', 'same-source', 'numeric-kind', 'alias-result')").replace('fec3af8947145f5e4dfaa92eb48baa529d6f5a31', binding['revision']).replace("'clone-roots', 'clone-paths')", "'clone-roots', 'clone-paths', 'clone-root')").replace('len(owners) == 5', 'len(owners) == 6')
assert prefix['after'] == expected_prefix and (BASE / 'verify.py').read_text().startswith(prefix['after'])
assert (BASE / 'source_roots.py').read_bytes() == (old / 'source_roots.py').read_bytes()
ordinary = json.loads(Path('docs/audits/record-value-structured-clones-20261004/ordinary.json').read_text())
bad = json.loads(Path('docs/audits/record-value-structured-clones-20261004/alias-result.json').read_text())
native = bad if args.alias_result else ordinary
roots = json.loads((old / 'root-recipes.json').read_text())['rows']
rows = copy.deepcopy(json.loads((BASE / 'tree-products.json').read_text())['rows'])
root_lookup = {root['index']: root for root in roots}
if args.omit_call:
    rows.pop()
indices = [i for i, row in enumerate(ordinary['api']) if row['kind'] == 'structured-clone']
assert [row['index'] for row in rows] == indices, 'every original recursive clone operation membership'
if args.omit_key:
    target = next(row for row in rows if type(row['record']['result']) is list and row['record']['result'][0] == 'hash' and row['record']['result'][1])
    target['record']['result'][1].pop(next(iter(target['record']['result'][1])))
if args.array_order:
    target = next(row for row in rows if type(row['record']['result']) is list and row['record']['result'][0] == 'array' and len(row['record']['result'][1]) >= 2 and not exact(row['record']['result'][1][0], row['record']['result'][1][1]))
    target['record']['result'][1].reverse()
if args.dfs_order:
    siblings = next((a, b) for a, b in zip(rows, rows[1:]) if a['parent_index'] is not None and a['parent_index'] == b['parent_index'])
    siblings[0]['source_path'], siblings[1]['source_path'] = siblings[1]['source_path'], siblings[0]['source_path']
if args.wrong_caller:
    target = next(row for row in rows if row['parent_index'] is not None and row['record']['caller'][2] == 428)
    target['record']['caller'][2] = 433
if args.same_source:
    peers = next((a, b) for a in rows for b in rows if a['index'] < b['index'] and a['root_index'] != b['root_index'] and exact(a['record']['result'], b['record']['result']))
    peers[0]['whole_source_root'] = peers[1]['whole_source_root']
if args.numeric_kind:
    target = next(row for row in rows if row['source_path'] and row['source_path'][-1] == 'width' and type(row['record']['result']) is str)
    target['record']['result'] = int(target['record']['result'])

CLASS = 'FSM::Package::AggregatePathSupport'
FILE = 'perl/FSM/Package/AggregatePathSupport.pm'
expected = {}
categories = Counter()
root_for_operation = {}
for root in roots:
    nodes, rebuilt, order = inventory(root['expected_input'])
    allocation = {path: root['index'] + position for position, path in enumerate(order)}
    for path in order:
        index = allocation[path]
        assert index not in expected
        parent = allocation[path[:-1]] if path else None
        caller = root['caller'] if not path else [CLASS, FILE, 428 if nodes[path[:-1]]['kind'] == 'hash' else 433]
        value = rebuilt[path]
        arguments = ['array', [CLASS, value]]
        expected[index] = {'root_index': root['index'], 'source_path': list(path),
            'whole_source_root': digest(root), 'parent_index': parent,
            'record': {'kind': 'structured-clone', 'accepted': 1, 'error': '', 'primary': '', 'warnings': [],
                'caller': caller, 'helper': root['helper'], 'parse': root['parse'],
                'before': arguments, 'after': arguments, 'result': value},
            'joint': ['hash', {'input': value, 'result': value}]}
        categories[nodes[path]['kind']] += 1
        root_for_operation[index] = root['index']
assert sorted(expected) == indices and len(roots) == 1448 and len(indices) == 8251
referents = {}
for row in rows:
    index = row['index']; source = expected[index]
    assert set(row) == set(source) | {'index'}
    assert row['root_index'] == source['root_index'] and exact(row['whole_source_root'], source['whole_source_root']), 'exact recursive own source root despite equal values'
    assert exact(row['source_path'], source['source_path']) and row['parent_index'] == source['parent_index'], 'independent full source path parent and DFS allocation'
    assert row['record']['caller'] == source['record']['caller'], 'exact root versus hash/array recursive caller'
    assert exact(row['record'], source['record']), 'whole recursive clone source product keys/order/primitive kinds/context'
    assert exact(row['joint'], source['joint']), 'whole source-modeled joint detached tree topology'
    actual = native['api'][index]
    assert exact(native_graph.base(actual), source['record']), 'every complete actual recursive clone matches own whole source product'
    referents[index] = native_graph.check_joint(actual)
    assert exact(actual['joint_input_result'], source['joint']), 'actual joint topology matches independent complete source trees'
assert sum(categories.values()) == 8251 and categories['scalar'] == 5623 and categories['hash'] + categories['array'] == 2628, 'exact finite source node branch partition'
assert sum(bool(row['source_path']) for row in rows) == 6803
assert sum(row['record']['caller'][2] == 428 for row in rows) == 5911
assert sum(row['record']['caller'][2] == 433 for row in rows) == 892
assert all(not row['shared'] for row in referents.values())
if (BASE / 'controls.json').exists() and not any(vars(args).values()):
    controls = json.loads((BASE / 'controls.json').read_text())
    assert [row['command'][-1] for row in controls] == ['--' + flag for flag in ('omit-call', 'omit-key', 'array-order', 'dfs-order', 'wrong-caller', 'same-source', 'numeric-kind', 'alias-result')]
    for row in controls:
        assert row['command'][:3] == ['python3', '-B', str(BASE / 'verify.py')] and row['status'] == 1 and row['working_directory'] == '.'
        assert row['output'].rstrip().endswith('AssertionError: ' + row['expected_failure'])
run = subprocess.run(['python3', '-B', str(BASE / 'replay_roots.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS every8251 original recursive clone from all1448 complete source roots:6803 source-owned children,5911 hash/892 array caller edges,2628 containers/5623 scalars. Independent path inventory/bottom-up whole products preserve every key/order/primitive kind/source/context; actual joint referents are detached. Genuine alias provider and semantic allocation controls reject. Whole helper/consumer/full-cause qualification remains open.')
