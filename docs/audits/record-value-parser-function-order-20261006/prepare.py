"""Capture only exact committed intake identities before first replay."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-function-order-20261006')
ns = {'__name__': 'prepare_function_order'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
assert not (BASE / 'binding.json').exists() and not (BASE / 'manifest.json').exists()
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
task = subprocess.check_output(['git', 'show', ns['REVISION'] + ':' + task_path])
owners = {}
for owner in ns['PREREQUISITES'].values():
    start = task.decode().index('- ID: `' + owner + '`')
    end = task.decode().index('\n- ID:', start + 1)
    owners[owner] = task.decode()[start:end]
archives = {directory: {path: ns['identity'](raw) for path, raw in
                       ns['committed_members'](ns['REVISION'], directory).items()}
            for directory in ns['PREREQUISITES']}
(BASE / 'binding.json').write_text(json.dumps({'revision': ns['REVISION'],
    'task_path': task_path, 'task_identity': ns['identity'](task),
    'owners': owners, 'archives': archives}, sort_keys=True, indent=2) + '\n')
