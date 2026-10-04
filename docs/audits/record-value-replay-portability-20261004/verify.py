"""Full portable current/source/owner/field/actor join, with semantic replays."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--omit-copy', action='store_true')
parser.add_argument('--omit-actor', action='store_true')
args = parser.parse_args()
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {path.name for path in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == 'ade53b92169636989d2d0c8ed48a222396b91b3f' and len(binding['sources']) == 20
mutable = {'docs/knowledge/isf-aggregate-port-request-baseline.md', 'docs/book/src/13k-isf-feature-support-matrix.md'}
for path, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert raw.decode() == row['body'] and len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
    if path not in mutable:
        assert raw == Path(path).read_bytes(), 'current selected source drift: ' + path
if (BASE / 'doc-updates.json').exists():
    updates = json.loads((BASE / 'doc-updates.json').read_text())
    assert {row['path'] for row in updates} == mutable
    for row in updates:
        assert row['before'] == binding['sources'][row['path']]['body']
        body = row['before']
        for old, new in row['replacements']:
            assert body.count(old) == 1
            body = body.replace(old, new)
        assert body == row['after'] == Path(row['path']).read_text(), 'current portable document drift: ' + row['path']
else:
    assert all(binding['sources'][path]['body'] == Path(path).read_text() for path in mutable)
data = json.loads((BASE / 'join.json').read_text())
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
task = subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode()
current_task = Path(task_path).read_text()
assert [row['archive'] for row in data['children']] == ['record-value-fields-20261004',
    'record-value-copy-fields-20261004', 'record-value-actors-20261004']
for child in data['children']:
    marker = '- ID: `' + child['owner'] + '`'
    for text in (task, current_task):
        start = text.index(marker)
        end = text.find('\n- ID:', start + 1)
        assert text[start:end] == child['node'] and 'Status: `done`' in child['node'], 'exact complete owner authority'
for archive in ('record-value-runtime-20261004', 'record-value-field-join-20261004') + tuple(row['archive'] for row in data['children']):
    directory = Path('docs/audits') / archive
    raw = (directory / 'manifest.json').read_bytes()
    manifest = json.loads(raw)
    assert {path.name for path in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        member = (directory / name).read_bytes()
        assert len(member) == row['bytes'] and hashlib.sha256(member).hexdigest() == row['sha256'], name
    if archive in [row['archive'] for row in data['children']]:
        child = next(row for row in data['children'] if row['archive'] == archive)
        assert child['manifest'] == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
    older = json.loads((directory / ('join.json' if archive == 'record-value-field-join-20261004' else 'binding.json')).read_text())
    for path, source in older['sources'].items():
        if path not in mutable:
            assert source['body'] == binding['sources'][path]['body'], 'whole original/current source continuity'

def identity(value):
    raw = json.dumps(value, sort_keys=True, separators=(',', ':')).encode()
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}

def exact(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return set(a) == set(b) and all(exact(a[key], b[key]) for key in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(exact(x, y) for x, y in zip(a, b))
    return a == b

native_path = Path('docs/audits/record-value-runtime-20261004/ordinary.json')
raw = native_path.read_bytes()
assert data['native_input'] == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
native = json.loads(raw)
fields = json.loads(Path('docs/audits/record-value-copy-fields-20261004/fields.json').read_text())
authored = json.loads(Path('docs/audits/record-value-fields-20261004/authored-models.json').read_text())
source_models = json.loads(Path('docs/audits/record-value-copy-fields-20261004/source-models.json').read_text())
assert exact(data['authored_root_models'], authored['types'])
for name, spec in authored['types'].items():
    assert exact(spec, source_models['roots']['authored:' + name])
copies = data['copies'][:-1] if args.omit_copy else data['copies']
assert len(copies) == len(native['copies']) == len(fields['rows']) == 697, 'whole native copied-field membership'
for index, (join, original, field) in enumerate(zip(copies, native['copies'], fields['rows'])):
    expected = {'index': index, 'kind': original['kind'], 'caller': original['caller'], 'api': original['api'],
        'helper': original['helper'], 'parse': original['parse'], 'before': identity(original['before']),
        'after': identity(original['copy']), 'whole_field_record': identity(field),
        'before_paths': [fact['path'] for fact in field['before']], 'after_paths': [fact['path'] for fact in field['after']]}
    assert exact(join, expected), 'every whole graph/field/native/source identity'
actors = json.loads(Path('docs/audits/record-value-actors-20261004/actor-models.json').read_text())
if args.omit_actor:
    del actors['actors']['imported']
assert data['whole_actor_models'] == identity(actors), 'complete actor/source/type/property/kind products'
assert data['whole_parse_products'] == identity(native['parses'])
proof = json.loads((BASE / 'old-reader-relocated.json').read_text())
legacy_directory = Path('docs/audits/record-value-field-join-20261004')
legacy_boundary = json.loads((legacy_directory / 'join.json').read_text())
legacy_docs = {row['path']: row['after'] for row in json.loads((legacy_directory / 'doc-updates.json').read_text())}
assert proof['command'] == ['python3', '-B', str(legacy_directory / 'verify.py')]
assert proof['working_directory'] == '.artifacts/record-value-portability-root-20261004'
assert set(proof['source_inputs']) == set(legacy_boundary['sources'])
for path, source in legacy_boundary['sources'].items():
    raw = legacy_docs.get(path, source['body']).encode()
    assert proof['source_inputs'][path] == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, 'whole old relocated source/input identity'
assert proof['status'] == 1 and 'complete reader/control replay identity and outcomes' in proof['output']
assert proof['output'].count(' ordinary 0') == 0  # Legacy labels use archive-ordinary.
assert proof['output'].count('-ordinary 0') == 2 and proof['output'].count(' 1\n') == 7
for script, flags in [('verify_coordinates.py', []), ('portable_replay.py', ['--check'])]:
    run = subprocess.run(['python3', '-B', str(BASE / script)] + flags, text=True, capture_output=True)
    assert run.returncode == 0, run.stdout + run.stderr
packet = json.loads((BASE / 'portable-replays.json').read_text())
assert len(packet['receipts']) == 15 and sum(row['status'] == 0 for row in packet['receipts']) == 3
print('PASS complete current20-source/three-completed-owner/original697 native field/whole actor join and all fifteen semantic replays; old relocated false RED and exact filename-only repair are independently qualified. Changed lines/messages/argument roots stay different. P2 replay coordinate defect closes for the bound interpreter/input profile; remaining value/core API products and native copy/cause assurance remain owned.')
