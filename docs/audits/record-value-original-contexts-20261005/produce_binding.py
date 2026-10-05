"""Whole committed context/source prerequisites, never context inference."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-contexts-20261005')
namespace = {'__name__': 'original_context_binding'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), namespace)
revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
task_path = namespace['join_reader']['TASK']; task = subprocess.check_output(['git', 'show', revision + ':' + task_path], text=True)
id = namespace['join_reader']['PREFIX'] + '3'; start = task.index('- ID: `' + id + '`'); end = task.index('\n- ID:', start + 1); body = task[start:end]
assert '\n  Status: `done`\n' in body
archives = set(namespace['load'](namespace['JOIN'] / 'binding.json')['archives']) | {str(namespace[k]) for k in ('JOIN', 'SEMANTICS', 'ACTORS')}
destination = BASE / 'binding.json'; assert not destination.exists()
destination.write_text(json.dumps(dict(revision=revision, task_path=task_path, task_body=task,
    owners=[dict(id=id,body=body)], archives={p:namespace['sealed'](Path(p)) for p in sorted(archives)}),sort_keys=True,indent=2)+'\n')
print('Captured whole committed context/source/operation prerequisite authority.')
