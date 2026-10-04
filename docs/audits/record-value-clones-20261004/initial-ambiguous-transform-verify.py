"""Independent complete original native joint referent qualification reader."""
import argparse
import copy
import json
import subprocess
from pathlib import Path
from native import JOINT, base, check_joint, conserved, exact, identity

BASE = Path(__file__).parent
NATIVE = Path('docs/audits/record-value-structured-clones-20261004')
parser = argparse.ArgumentParser()
for flag in ('omit-call', 'alias-result', 'false-zero', 'joint-swap', 'wrong-kind'):
    parser.add_argument('--' + flag, action='store_true')
args = parser.parse_args()


def sealed(directory):
    manifest = json.loads((directory / 'manifest.json').read_text())
    assert {path.name for path in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert identity((directory / name).read_bytes()) == row, str(directory / name)


if (BASE / 'manifest.json').exists():
    sealed(BASE)
sealed(NATIVE)
binding = json.loads((BASE / 'binding.json').read_text())
assert binding == json.loads((NATIVE / 'binding.json').read_text())
assert binding['revision'] == '721e997ec6ccdf9851f2eef3b07fb7b8e098c63e' and len(binding['sources']) == 21
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
        assert text == row['after'] == Path(row['path']).read_text(), 'exact current clone-native document transform'
else:
    assert all(binding['sources'][path]['body'] == Path(path).read_text() for path in mutable)
archives = ('runtime', 'fields', 'copy-fields', 'field-join', 'actors', 'replay-portability', 'scopes', 'references', 'copies', 'api-join', 'captures', 'snapshots', 'ranges')
for name in archives:
    directory = Path('docs/audits/record-value-' + name + '-20261004')
    sealed(directory)
    prior = json.loads((directory / ('join.json' if name == 'field-join' else 'binding.json')).read_text())
    for path, row in prior['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
owners = json.loads((BASE / 'owners.json').read_text())
assert owners == json.loads((NATIVE / 'owners.json').read_text()) and len(owners) == 3
for owner in owners:
    for task in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()):
        start = task.index('- ID: `' + owner['owner'] + '`')
        end = task.index('\n- ID:', start + 1)
        assert task[start:end] == owner['node'] and 'Status: `done`' in owner['node'], 'exact completed range/scope/reference owner'
transform = json.loads((BASE / 'observer-transform.json').read_text())
original = Path('docs/audits/record-value-runtime-20261004/observe.pl').read_text()
for before, after in transform:
    assert original.count(before) == 1
    original = original.replace(before, after)
assert original == (NATIVE / 'observe.pl').read_text(), 'full original observer changes only declared joint/provider/output instrumentation'
old = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
ordinary = json.loads((NATIVE / 'ordinary.json').read_text())
bad = json.loads((NATIVE / 'alias-result.json').read_text())
conservation = conserved(old, ordinary, True)
assert conservation == json.loads((BASE / 'legacy-conservation.json').read_text()), 'full retained native raw difference ledger'
assert len([row for row in conservation if row['section'] == 'api']) == 48
conserved(ordinary, bad, False)
indices = [i for i, row in enumerate(old['api']) if row['kind'] == 'structured-clone']
ordinary_nodes, alias_nodes = [], []
for i in indices:
    left, right = ordinary['api'][i], bad['api'][i]
    assert set(left) == set(right) == set(old['api'][i]) | JOINT
    assert exact(base(left), old['api'][i]) and exact(base(right), base(left)), 'every complete legacy clone property/caller/kind/value agrees'
    assert left['accepted'] == right['accepted'] == 1 and left['error'] == right['error'] == ''
    normal = check_joint(left)
    alias = check_joint(right, require_detached=False)
    assert normal['container'] == alias['container']
    if alias['container']:
        assert alias['input'] == alias['result'] == alias['shared'] and alias['shared']
        assert right['joint_input_result'][1]['result'] == ['reference', '/input'], 'genuine shared result is the actual entire input container'
    else:
        assert not alias['input'] and not alias['result'] and not alias['shared']
    ordinary_nodes.append({'index': i, **normal})
    alias_nodes.append({'index': i, **alias})
assert len(indices) == 8251 and sum(row['container'] for row in ordinary_nodes) == 2628
packet = {'ordinary': ordinary_nodes, 'alias_result': alias_nodes}
assert packet == json.loads((BASE / 'referents.json').read_text()), 'complete independently reconstructed per-call reachable referent populations'
selected = copy.deepcopy(bad if args.alias_result or args.false_zero else ordinary)
calls = [(i, selected['api'][i]) for i in indices]
if args.omit_call:
    calls.pop()
assert [i for i, _ in calls] == indices, 'every whole original structured clone call membership'
reached = False
container_index = next(row['index'] for row in ordinary_nodes if row['container'])
string_index = next(i for i in indices if type(ordinary['api'][i]['joint_input_result'][1]['input']) is str and ordinary['api'][i]['joint_input_result'][1]['input'].isdigit())
for i, row in calls:
    if args.false_zero and i == container_index:
        reached = True
        row['shared_with_input'] = 0
    if args.joint_swap and i == container_index:
        reached = True
        row['joint_input_result'][1]['result'] = ['reference', '/input']
    if args.wrong_kind and i == string_index:
        reached = True
        row['joint_input_result'][1]['input'] = int(row['joint_input_result'][1]['input'])
    check_joint(row)
assert not any((args.false_zero, args.joint_swap, args.wrong_kind)) or reached
run = subprocess.run(['python3', '-B', str(BASE / 'replay_native.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS all8251 complete original native clone values/callers/kinds plus independent joint referent graphs:2628 containers detached,5623 scalars. Genuine shared-result provider preserves all8251 separate records and125 original passing consumers yet all2628 containers alias. Joint controls reject; full native reexecution retains. Source/tree semantic models and permanent consumer assurance remain open.')
