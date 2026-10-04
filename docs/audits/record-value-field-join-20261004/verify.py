"""Independent source/owner/whole graph/field/model and child-control join."""
import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
for flag in ('omit-copy', 'swap-model', 'promote-owner'):
    parser.add_argument('--' + flag, action='store_true')
args = parser.parse_args()
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {path.name for path in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
data = json.loads((BASE / 'join.json').read_text())
assert data['revision'] == 'e6fa1550b507ce2895cf9b557c34b95933c27c69'
assert len(data['sources']) == 20
mutable = {'docs/knowledge/isf-aggregate-port-request-baseline.md', 'docs/book/src/13k-isf-feature-support-matrix.md'}
for path, row in data['sources'].items():
    raw = subprocess.check_output(['git', 'show', data['revision'] + ':' + path])
    assert raw.decode() == row['body'] and len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
    if path not in mutable:
        assert raw == Path(path).read_bytes(), 'selected current source drift: ' + path
if (BASE / 'doc-updates.json').exists():
    updates = json.loads((BASE / 'doc-updates.json').read_text())
    assert {row['path'] for row in updates} == mutable
    for row in updates:
        assert row['before'] == data['sources'][row['path']]['body']
        body = row['before']
        for old, new in row['replacements']:
            assert body.count(old) == 1
            body = body.replace(old, new)
        assert body == row['after'] == Path(row['path']).read_text(), 'current joined document drift: ' + row['path']
else:
    for path in mutable:
        assert data['sources'][path]['body'] == Path(path).read_text()
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
task = subprocess.check_output(['git', 'show', data['revision'] + ':' + task_path]).decode()
current_task = Path(task_path).read_text()
children = copy.deepcopy(data['children'])
if args.promote_owner:
    children[0]['node'] = children[0]['node'].replace('Status: `done`', 'Status: `pending`', 1)
expected_owners = ['SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.2.1.' + suffix for suffix in ('1', '2')]
assert [row['owner'] for row in children] == expected_owners
assert [row['archive'] for row in children] == ['record-value-fields-20261004', 'record-value-copy-fields-20261004']
for child in children:
    marker = '- ID: `' + child['owner'] + '`'
    start = task.index(marker)
    end = task.find('\n- ID:', start + 1)
    assert child['node'] == task[start:end] and 'Status: `done`' in child['node'], 'exact completed child authority'
    start = current_task.index(marker)
    end = current_task.find('\n- ID:', start + 1)
    assert child['node'] == current_task[start:end], 'current completed owner changed'
for archive in ['record-value-runtime-20261004'] + [row['archive'] for row in children]:
    directory = Path('docs/audits') / archive
    raw = (directory / 'manifest.json').read_bytes()
    manifest = json.loads(raw)
    assert {path.name for path in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        member = (directory / name).read_bytes()
        assert len(member) == row['bytes'] and hashlib.sha256(member).hexdigest() == row['sha256'], name
    if archive != 'record-value-runtime-20261004':
        child = next(row for row in children if row['archive'] == archive)
        assert child['manifest'] == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
native_path = Path('docs/audits/record-value-runtime-20261004/ordinary.json')
raw = native_path.read_bytes()
assert data['native_input'] == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
native = json.loads(raw)
fields = json.loads(Path('docs/audits/record-value-copy-fields-20261004/fields.json').read_text())
authored = json.loads(Path('docs/audits/record-value-fields-20261004/authored-models.json').read_text())
source_models = json.loads(Path('docs/audits/record-value-copy-fields-20261004/source-models.json').read_text())

def exact(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return set(a) == set(b) and all(exact(a[key], b[key]) for key in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(exact(x, y) for x, y in zip(a, b))
    return a == b

def identity(value):
    body = json.dumps(value, sort_keys=True, separators=(',', ':')).encode()
    return {'bytes': len(body), 'sha256': hashlib.sha256(body).hexdigest()}

models = copy.deepcopy(data['authored_root_models'])
if args.swap_model:
    models['frame']['members']['data']['signed'] = 1
assert exact(models, authored['types']), 'complete recursive source/model join, including same-width signed identity'
for name, spec in models.items():
    assert exact(spec, source_models['roots']['authored:' + name]), 'authored and copied-field source roots'
assert exact(authored['imported']['shared.frame'], source_models['roots']['imported:shared.frame'])
assert exact(authored['scalar'], source_models['roots']['source:scalar'])
for archive in [row['archive'] for row in children] + ['record-value-runtime-20261004']:
    binding = json.loads(Path('docs/audits', archive, 'binding.json').read_text())
    for path, row in binding['sources'].items():
        if path not in mutable:
            assert row['body'] == data['sources'][path]['body'], 'whole unchanged original/current source: ' + path
copies = data['copies'][:-1] if args.omit_copy else data['copies']
assert len(copies) == len(native['copies']) == len(fields['rows']) == 697, 'complete original copied graph/field membership'
for index, (join, original, field) in enumerate(zip(copies, native['copies'], fields['rows'])):
    expected = {'index': index, 'kind': original['kind'], 'caller': original['caller'],
        'api': original['api'], 'helper': original['helper'], 'parse': original['parse'],
        'before': identity(original['before']), 'after': identity(original['copy']),
        'whole_field_record': identity(field), 'before_paths': [fact['path'] for fact in field['before']],
        'after_paths': [fact['path'] for fact in field['after']]}
    assert exact(join, expected), 'every complete native graph/source/field identity'
replays = json.loads((BASE / 'child-replays.json').read_text())
assert len(replays) == 9
run = subprocess.run(['python3', '-B', str(BASE / 'replay_children.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
assert all(row['status'] == row['expected_status'] for row in replays)
print('PASS full current20-source/two-completed-owner and original697 graph/field/model join; both semantic readers and all seven child RED controls reexecute at exact historical document boundaries. Raw kinds, whole properties/orders, carrier/stage source roles and ancestor cycles retain authority. Only field parent closes; whole actor/API products and native copy/cause assurance remain owned.')
