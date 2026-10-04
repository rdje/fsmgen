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

BASE = Path('docs/audits/record-value-identities-20261004')
parser = argparse.ArgumentParser()
for flag in ('omit-call', 'trust-width', 'strict-payload', 'same-source', 'numeric-kind'):
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
assert binding['revision'] == 'cd7d0a951d9bd792ef82bf6f171c59481d62c264' and len(binding['sources']) == 21
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
for name in ('runtime', 'fields', 'copy-fields', 'field-join', 'actors', 'replay-portability', 'scopes', 'references', 'copies', 'api-join', 'captures', 'snapshots', 'ranges', 'structured-clones', 'clones', 'clone-roots', 'clone-paths', 'clone-root', 'clone-tree', 'clone-join'):
    directory = Path('docs/audits/record-value-' + name + '-20261004')
    sealed(directory)
    prior = json.loads((directory / ('join.json' if name == 'field-join' else 'binding.json')).read_text())
    for path, row in prior['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
owners = json.loads((BASE / 'owners.json').read_text())
assert len(owners) == 11
for owner in owners:
    for task in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()):
        start = task.index('- ID: `' + owner['owner'] + '`'); end = task.index('\n- ID:', start + 1)
        assert task[start:end] == owner['node'] and 'Status: `done`' in owner['node']

from source_roots import native_graph


def inventory(value):
    pending, nodes = [((), value)], {}
    while pending:
        path, node = pending.pop(0)
        if type(node) is dict:
            nodes[path] = ('hash', tuple(sorted(node)))
            pending.extend((path + (key,), node[key]) for key in sorted(node))
        elif type(node) is list:
            nodes[path] = ('array', len(node))
            pending.extend((path + (i,), child) for i, child in enumerate(node))
        else:
            assert node is None or type(node) in (int, str, float)
            nodes[path] = ('scalar', type(node).__name__, node)
    return nodes


def at(value, path):
    for key in path:
        value = value[key]
    return value


def preparation(source, raw):
    """Independent full source/property inventory and literal read locations."""
    a, b = inventory(source), inventory(raw)
    assert set(a) == set(b)
    result = copy.deepcopy(raw)
    for path in a:
        numeric = bool(path) and path[-1] in ('width', 'signed') and type(at(source, path[:-1])) is dict and 'kind' in at(source, path[:-1])
        if numeric:
            assert a[path][0] == b[path][0] == 'scalar' and type(at(raw, path)) in (str, int) and int(at(raw, path)) == at(source, path)
            if path[-1] == 'signed' and at(source, path[:-1])['kind'] in ('record', 'list'):
                at(result, path[:-1])[path[-1]] = at(source, path)
        else:
            assert a[path] == b[path], 'whole source declaration properties and container order'
    result['width'] = source['width']
    return result


def shape(value):
    """Separate aggregate/ordered-leaf witness for the narrower public relation."""
    pending, result = [((), value)], {}
    while pending:
        path, spec = pending.pop(0)
        if spec['kind'] == 'record':
            names = spec['member_order']
            result[path] = ('record', tuple(names))
            pending.extend((path + (name,), spec['members'][name]) for name in names)
        elif spec['kind'] == 'list':
            result[path] = ('list', len(spec['items']))
            pending.extend((path + (i,), child) for i, child in enumerate(spec['items']))
        else:
            assert spec['kind'] in ('bit', 'bits')
            result[path] = ('scalar', spec['width'])
    return result


previous = Path('docs/audits/record-value-clone-join-20261004')
prefix = json.loads((BASE / 'reader-prefix.json').read_text())
assert prefix['before'] == (previous / 'verify.py').read_text().split('\nfrom source_roots import native_graph', 1)[0]
expected_prefix = prefix['before'].replace('record-value-clone-join-20261004', 'record-value-identities-20261004').replace("('omit-call', 'same-native', 'wrong-root', 'numeric-kind', 'alias-result')", "('omit-call', 'trust-width', 'strict-payload', 'same-source', 'numeric-kind')").replace('5429120ed9a22bce069562dd4f35e749c4d3383f', binding['revision']).replace("'clone-root', 'clone-tree')", "'clone-root', 'clone-tree', 'clone-join')").replace('len(owners) == 8', 'len(owners) == 11')
assert prefix['after'] == expected_prefix and (BASE / 'verify.py').read_text().startswith(prefix['after'])
assert (BASE / 'source_roots.py').read_bytes() == (previous / 'source_roots.py').read_bytes()
native = read('runtime', 'ordinary.json')
parents = read('copies', 'copy-products.json')['rows']
roots = read('copy-fields', 'source-models.json')['roots']
rows = copy.deepcopy(json.loads((BASE / 'identity-products.json').read_text())['rows'])
indices = [i for i, row in enumerate(native['api']) if row['kind'] in ('identity', 'payload')]
if args.omit_call:
    rows.pop()
assert [row['index'] for row in rows] == indices, 'all original strict identity/payload membership'
if args.trust_width:
    target = next(row for row in rows if row['kind'] == 'identity' and row['expected_result'] == 1)
    target['expected_result'] = 0
if args.strict_payload:
    next(row for row in rows if row['kind'] == 'payload')['expected_result'] = 0
if args.same_source:
    a, b = next((a, b) for a in rows for b in rows if a['kind'] == b['kind'] == 'identity' and a['index'] < b['index'] and exact(a['expected_arguments'], b['expected_arguments']) and a['source_parent_index'] != b['source_parent_index'])
    a['source_parent_index'], a['whole_source_parent'], a['source_recipe'] = b['source_parent_index'], b['whole_source_parent'], b['source_recipe']
if args.numeric_kind:
    target = next(row for row in rows if row['kind'] == 'identity')
    leaf = target['expected_arguments'][1][1][1]['members'][1]['data'][1]
    assert type(leaf['width']) is str
    leaf['width'] = int(leaf['width'])
expected = {}
for parent in parents:
    selected = [row for row in parent['operation_span'] if row['record']['kind'] == 'identity']
    if not selected:
        continue
    assert len(selected) == 1
    values = thaw(parent['recipe']['arguments']); source = dict(zip(values[::2], values[1::2]))
    specs, witnesses = [], []
    for name in ('source', 'target'):
        spec = source[name]['type_spec']
        private = next(row['copy'] for row in parent['private_stages'] if row['name'] == name)
        prepared = preparation(spec, thaw(private['copy'])['type_spec'])
        specs.append(prepared)
        witnesses.append({'name': name, 'source_type': graph(spec), 'whole_private_clone': digest(private), 'prepared_type': graph(prepared)})
    conflict = int(inventory(source['source']['type_spec']) != inventory(source['target']['type_spec']))
    assert source['source']['type_spec']['width'] == source['target']['type_spec']['width'] == 8
    index = selected[0]['index']
    expected[index] = {'index': index, 'kind': 'identity', 'source_parent_index': parent['index'], 'whole_source_parent': digest(parent), 'source_recipe': parent['recipe'], 'witnesses': witnesses,
        'expected_arguments': graph(['FSM::Composition::InterfacePortBuilder', *specs]), 'expected_result': conflict,
        'caller': ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', 110], 'helper': parent['original']['helper'], 'parse': parent['original']['parse']}
payload_indices = [i for i in indices if native['api'][i]['kind'] == 'payload']
text = binding['sources']['t/1986-isf-record-port-value-gates.t']['body']
loop = "for my $name (qw(signed_data four two bit_kind)) {\n        ok(FSM::Package::PayloadTypeSupport->payload_compatible_with_type_spec($types{frame}, $types{$name}),"
assert text.count(loop) == 1
for index, name in zip(payload_indices, ('signed_data', 'four', 'two', 'bit_kind')):
    a, b = roots['authored:frame'], roots['authored:' + name]
    assert inventory(a) != inventory(b) and shape(a) == shape(b)
    expected[index] = {'index': index, 'kind': 'payload', 'source_parent_index': None, 'whole_source_parent': None,
        'source_recipe': {'file': 't/1986-isf-record-port-value-gates.t', 'loop_members': ['signed_data', 'four', 'two', 'bit_kind'], 'source': 'authored:frame', 'target': 'authored:' + name},
        'witnesses': [{'source_type': graph(a), 'target_type': graph(b)}], 'expected_arguments': graph(['FSM::Package::PayloadTypeSupport', a, b]), 'expected_result': int(shape(a) == shape(b)),
        'caller': ['main', './t/1986-isf-record-port-value-gates.t', 138], 'helper': None, 'parse': None}
assert sorted(expected) == indices and len(payload_indices) == 4 and len(indices) == 18
for row in rows:
    source = expected[row['index']]
    assert row['source_parent_index'] == source['source_parent_index'] and exact(row['whole_source_parent'], source['whole_source_parent']) and exact(row['source_recipe'], source['source_recipe']), 'exact own source/copy parent despite identical type arguments'
    assert exact(row['expected_result'], source['expected_result']), 'independent complete type identity versus narrower payload product'
    assert exact(row['expected_arguments'], source['expected_arguments']), 'whole original source/private argument primitive kinds'
    assert exact(row, source), 'every complete original strict/payload source/context/property witness'
    actual = native['api'][row['index']]
    assert actual['kind'] == row['kind'] and actual['caller'] == row['caller'] and actual['helper'] == row['helper'] and actual['parse'] == row['parse']
    assert exact(actual['before'], row['expected_arguments']) and exact(actual['after'], row['expected_arguments'])
    assert actual['accepted'] == 1 and actual['error'] == actual['primary'] == '' and actual['warnings'] == [] and exact(actual['result'], row['expected_result'])
assert Counter(row['expected_result'] for row in rows if row['kind'] == 'identity') == {0: 5, 1: 9}
cases = json.loads((BASE / 'payload-control-inputs.json').read_text())
captures = json.loads((BASE / 'payload-control-native.json').read_text())
assert len(cases) == len(captures) == 8
assert [(case['source'], case['target']) for case in cases] == [('authored:frame', 'authored:' + name) for name in ('signed_data', 'four', 'two', 'bit_kind', 'renamed', 'reordered')] + [('authored:nested', 'authored:flat'), ('authored:nested', 'source:swapped-nested-list')]
for i, (case, capture) in enumerate(zip(cases, captures)):
    a, b = roots[case['source']], roots[case['target']]
    assert exact(case['arguments'], ['FSM::Package::PayloadTypeSupport', a, b]) and a['width'] == b['width'] == 8
    assert case['label'] == capture['label']
    assert exact(json.loads(capture['before']), case['arguments']) and capture['before'] == capture['after']
    assert capture['accepted'] == 1 and capture['error'] == '' and capture['warnings'] == []
    assert capture['result'] == int(shape(a) == shape(b)) == int(i < 4), 'genuine narrower payload accepts properties but refuses same-width wrong shape/order'
if (BASE / 'controls.json').exists() and not any(vars(args).values()):
    controls = json.loads((BASE / 'controls.json').read_text())
    assert [row['command'][-1] for row in controls] == ['--' + flag for flag in ('omit-call', 'trust-width', 'strict-payload', 'same-source', 'numeric-kind')]
    for row in controls:
        assert row['command'][:3] == ['python3', '-B', str(BASE / 'verify.py')] and row['status'] == 1 and row['working_directory'] == '.'
        assert row['output'].rstrip().endswith('AssertionError: ' + row['expected_failure'])
run = subprocess.run(['python3', '-B', str(BASE / 'replay_clones.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS every original14 strict identity/four payload whole source/private/caller/primitive-kind/context product:five equal/nine conflicting complete types and four narrower payload accepts. Independent full property/path and ordered shape witnesses retain; eight genuine same-width public payload controls accept sign/state/unit-kind but refuse wrong member/order/nested/list shape. Complete original arguments stay unchanged; helper/consumer/native causes remain open.')
