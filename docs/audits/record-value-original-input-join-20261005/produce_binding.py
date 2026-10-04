"""Retain exact complete graph/field owners and their committed evidence."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-input-join-20261005')
namespace = {'__name__': 'original_input_join_binding'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), namespace)
revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
task = subprocess.check_output(['git', 'show', revision + ':' + namespace['TASK']], text=True)
owners = []
for id in (namespace['PREFIX'] + '1', namespace['PREFIX'] + '2'):
    start = task.index('- ID: `' + id + '`'); end = task.index('\n- ID:', start + 1); body = task[start:end]
    assert '\n  Status: `done`\n' in body
    owners.append(dict(id=id, body=body))
archives = set(namespace['load'](namespace['FIELDS'] / 'binding.json')['archives']) | {str(namespace['FIELDS'])}
checks = {}
for path in namespace['CHECKS']:
    members = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', revision, '--', path], text=True).splitlines()
    assert members and all(Path(p).parent == Path(path) for p in members)
    checks[path] = {Path(p).name: namespace['identity'](subprocess.check_output(['git', 'show', revision + ':' + p])) for p in members}
destination = BASE / 'binding.json'; assert not destination.exists()
destination.write_text(json.dumps(dict(revision=revision, task_path=namespace['TASK'], task_body=task,
    owners=owners, archives={p: namespace['sealed'](Path(p)) for p in sorted(archives)}, checks=checks), sort_keys=True, indent=2) + '\n')
print('Captured exact done graph/field owners and every whole committed prerequisite/check member.')
