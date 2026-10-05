"""Freeze whole committed source-context authority before primary modelling."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-primary-20261005')
namespace = {'__name__': 'original_primary_binding'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), namespace)
revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
task = subprocess.check_output(['git', 'show', revision + ':' + task_path], text=True)
owner = namespace['OWNER']; start = task.index('- ID: `' + owner + '`'); end = task.index('\n- ID:', start + 1)
body = task[start:end]; assert '\n  Status: `done`\n' in body
context = namespace['CONTEXT']; archives = set(namespace['load'](context / 'binding.json')['archives']) | {str(context)}
path = BASE / 'binding.json'; assert not path.exists()
path.write_text(json.dumps(dict(revision=revision, task_path=task_path, task_body=task,
    owners=[dict(id=owner, body=body)], archives={p: namespace['sealed'](Path(p)) for p in sorted(archives)}), sort_keys=True, indent=2) + '\n')
print('Captured entire committed primary/source/context prerequisite authority.')
