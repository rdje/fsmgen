"""Bind the completed whole helper-join frontier before own-boundary modeling."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-own-subtest-boundaries-20261005')
PRIOR = Path('docs/audits/record-value-original-helper-join-20261005')
REVISION = 'eaf93f672d437da104dc4e5ebac23713be9592a2'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.3.3'
namespace = {'__name__': 'owned_subtest_intake'}
exec(compile((PRIOR / 'verify.py').read_bytes(), str(PRIOR / 'verify.py'), 'exec'), namespace)
binding = json.loads((PRIOR / 'binding.json').read_text())
task_path = binding['task_path']
task = subprocess.check_output(['git', 'show', REVISION + ':' + task_path], text=True)
start = task.index('- ID: `' + OWNER + '`')
end = task.index('\n- ID:', start + 1)
owner = task[start:end]
assert '\n  Status: `done`\n' in owner
archives = {**binding['archives'], str(PRIOR): namespace['sealed'](PRIOR)}
target = BASE / 'binding.json'
assert not target.exists()
target.write_text(json.dumps({'revision': REVISION, 'owner': OWNER, 'task_path': task_path, 'task_body': task,
                              'owner_body': owner, 'archives': archives,
                              'auxiliary_receipts': binding['auxiliary_receipts']}, sort_keys=True, indent=2) + '\n')
print('PASS whole completed helper-join task, archive domain and inherited receipt intake bound.')
