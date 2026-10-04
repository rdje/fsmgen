"""Superseding exact source/owner/native/field/actor semantic join."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
binding = json.loads((BASE / 'binding.json').read_text())
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
task = subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode()
field_parent = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.2.1'
owners = [(field_parent + '.1', 'record-value-fields-20261004'),
    (field_parent + '.2', 'record-value-copy-fields-20261004'),
    (field_parent.rsplit('.', 1)[0] + '.2.1', 'record-value-actors-20261004')]

def identity(value):
    raw = json.dumps(value, sort_keys=True, separators=(',', ':')).encode()
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}

children = []
for owner, archive in owners:
    start = task.index('- ID: `' + owner + '`')
    end = task.find('\n- ID:', start + 1)
    node = task[start:end]
    assert 'Status: `done`' in node
    raw = Path('docs/audits', archive, 'manifest.json').read_bytes()
    children.append({'owner': owner, 'archive': archive, 'node': node,
        'manifest': {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}})
native_path = Path('docs/audits/record-value-runtime-20261004/ordinary.json')
native = json.loads(native_path.read_text())
fields = json.loads(Path('docs/audits/record-value-copy-fields-20261004/fields.json').read_text())
authored = json.loads(Path('docs/audits/record-value-fields-20261004/authored-models.json').read_text())
copies = []
for index, (row, field) in enumerate(zip(native['copies'], fields['rows'])):
    copies.append({'index': index, 'kind': row['kind'], 'caller': row['caller'], 'api': row['api'],
        'helper': row['helper'], 'parse': row['parse'], 'before': identity(row['before']),
        'after': identity(row['copy']), 'whole_field_record': identity(field),
        'before_paths': [fact['path'] for fact in field['before']],
        'after_paths': [fact['path'] for fact in field['after']]})
assert len(copies) == len(native['copies']) == len(fields['rows']) == 697
actors = json.loads(Path('docs/audits/record-value-actors-20261004/actor-models.json').read_text())
(BASE / 'join.json').write_text(json.dumps({'children': children, 'copies': copies,
    'authored_root_models': authored['types'], 'native_input': {'bytes': native_path.stat().st_size,
        'sha256': hashlib.sha256(native_path.read_bytes()).hexdigest()},
    'whole_actor_models': identity(actors), 'whole_parse_products': identity(native['parses'])}, sort_keys=True, indent=2) + '\n')
print('PASS full three-completed-owner/current20-source/original697-copy and whole actor-product join produced; portable semantic/control reader remains required.')
