"""Bind complete committed done source cohorts for the context join."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-context-join-20261006')
namespace = {'__name__': 'prepare_context_join'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), namespace)
assert not (BASE / 'binding.json').exists() and not (BASE / 'manifest.json').exists()
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
task = subprocess.check_output(['git', 'show', namespace['REVISION'] + ':' + task_path])
text = task.decode()
owners = namespace['owners']()
bodies = {}
for owner in owners.values():
    start = text.index('- ID: `' + owner + '`')
    end = text.index('\n- ID:', start + 1)
    body = text[start:end]
    assert '\n  Status: `done`\n' in body
    bodies[owner] = body
archives = {directory: {path: namespace['identity'](raw) for path, raw in
                       namespace['argument']['prior']['committed_members'](namespace['REVISION'], directory).items()}
            for directory in owners}
(BASE / 'binding.json').write_text(json.dumps({'revision': namespace['REVISION'],
    'task_path': task_path, 'task_identity': namespace['identity'](task),
    'owners': owners, 'owner_bodies': bodies, 'archives': archives}, sort_keys=True, indent=2) + '\n')
