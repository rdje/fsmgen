"""Retain complete input/source/stage authority; never generates graph models."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-input-graphs-20261005')
namespace = {'__name__': 'original_input_graph_binding'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), namespace)
prior = namespace['load'](namespace['RESULTS'] / 'binding.json')
revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
task_path = prior['task_path']; task = subprocess.check_output(['git', 'show', revision + ':' + task_path], text=True)
ids = [r['id'] for r in prior['owners']]
ids += ['SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.1']
owners = []
for id in sorted(ids):
    start = task.index('- ID: `' + id + '`'); end = task.index('\n- ID:', start + 1); body = task[start:end]
    assert '\n  Status: `done`\n' in body
    owners.append({'id': id, 'body': body})
archives = set(prior['archives']) | {str(namespace[k]) for k in ('RESULTS', 'INPUTS', 'FIELDS', 'FINITE', 'AUTHOR')}
destination = BASE / 'binding.json'; assert not destination.exists(), 'never replace original source authority'
destination.write_text(json.dumps(dict(revision=revision,task_path=task_path,task_body=task,
    owners=owners,archives={p:namespace['sealed'](Path(p)) for p in sorted(archives)}),sort_keys=True,indent=2)+'\n')
print('Captured complete committed original source/input/stage/result/graph owner and archive authority.')
