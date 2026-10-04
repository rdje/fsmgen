"""Pin the complete original semantic source/task/runtime context from Git."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-replay-20261004')
PRIOR = Path('docs/audits/record-value-semantic-join-20261004')
REVISION = '0da4675ac61460451f030001adad075157a6efb4'
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'


def captured(path):
    raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
    return {'body': raw.decode(), 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


old = json.loads((PRIOR / 'binding.json').read_text())
sources = {path: captured(path) for path in old['sources']}
task = captured(TASK)
owners = [row['owner'] for row in json.loads((PRIOR / 'owners.json').read_text())]
parent = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.2'
owners += [parent, parent + '.3']
nodes = []
for owner in owners:
    start = task['body'].index('- ID: `' + owner + '`')
    end = task['body'].index('\n- ID:', start + 1)
    node = task['body'][start:end]
    assert 'Status: `done`' in node
    nodes.append({'owner': owner, 'node': node})
runtime = json.loads(Path('docs/audits/record-value-clone-paths-20261004/runtime-support.json').read_text())
for path, row in runtime.items():
    raw = Path(path).read_bytes()
    assert row == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, path
(BASE / 'binding.json').write_text(json.dumps({'revision': REVISION, 'sources': sources,
    'task_path': TASK, 'task_context': task, 'owners': nodes, 'runtime': runtime}, sort_keys=True, indent=2) + '\n')
print('Captured complete original21 source bodies, full committed task context,29 done owners and complete own public runtime identity.')
