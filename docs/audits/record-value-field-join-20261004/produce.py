"""Full committed source/owner and native-to-field identity join."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
REVISION = 'e6fa1550b507ce2895cf9b557c34b95933c27c69'
prefix = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.2.1'
paths = set(json.loads(Path('docs/audits/record-value-copy-fields-20261004/binding.json').read_text())['sources'])
paths.add('docs/book/src/13k-isf-feature-support-matrix.md')
sources = {}
for path in sorted(paths):
    raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
    assert raw == Path(path).read_bytes()
    sources[path] = {'body': raw.decode(), 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
task = subprocess.check_output(['git', 'show', REVISION + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md']).decode()
children = []
for suffix, archive in [('.1', 'record-value-fields-20261004'), ('.2', 'record-value-copy-fields-20261004')]:
    owner = prefix + suffix
    start = task.index('- ID: `' + owner + '`')
    end = task.find('\n- ID:', start + 1)
    node = task[start:end]
    assert 'Status: `done`' in node and 'Verification: `pending`' not in node
    raw = Path('docs/audits', archive, 'manifest.json').read_bytes()
    children.append({'owner': owner, 'archive': archive, 'node': node,
        'manifest': {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}})
native_path = Path('docs/audits/record-value-runtime-20261004/ordinary.json')
native = json.loads(native_path.read_text())
fields = json.loads(Path('docs/audits/record-value-copy-fields-20261004/fields.json').read_text())
authored = json.loads(Path('docs/audits/record-value-fields-20261004/authored-models.json').read_text())

def identity(value):
    raw = json.dumps(value, sort_keys=True, separators=(',', ':')).encode()
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}

copies = []
for index, (row, field) in enumerate(zip(native['copies'], fields['rows'])):
    copies.append({'index': index, 'kind': row['kind'], 'caller': row['caller'],
        'api': row['api'], 'helper': row['helper'], 'parse': row['parse'],
        'before': identity(row['before']), 'after': identity(row['copy']),
        'whole_field_record': identity(field),
        'before_paths': [fact['path'] for fact in field['before']],
        'after_paths': [fact['path'] for fact in field['after']]})
assert len(copies) == len(native['copies']) == len(fields['rows']) == 697
(BASE / 'join.json').write_text(json.dumps({'revision': REVISION, 'sources': sources,
    'children': children, 'native_input': {'bytes': native_path.stat().st_size,
        'sha256': hashlib.sha256(native_path.read_bytes()).hexdigest()},
    'authored_root_models': authored['types'], 'copies': copies}, sort_keys=True, indent=2) + '\n')
print('PASS complete committed20-source/two-completed-owner and original697 native/field identities derived; independent semantic/control join remains required.')
