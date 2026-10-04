"""Capture complete committed prerequisites; never derives semantic results."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-products-20261005')
namespace = {'__name__': 'source_product_reader_binding'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), namespace)
revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
task = subprocess.check_output(['git', 'show', revision + ':' + task_path], text=True)
owner_ids = [row['owner'] for row in namespace['load'](namespace['PRODUCTS'] / 'owners.json')]
owner_ids += [row['owner'] for row in namespace['load'](Path('docs/audits/record-value-semantic-join-20261004/owners.json'))]
owner_ids += ['SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.1']
owner_ids = sorted(set(owner_ids))
owners = []
for id in owner_ids:
    start = task.index('- ID: `' + id + '`'); end = task.index('\n- ID:', start + 1)
    body = task[start:end]
    assert '\n  Status: `done`\n' in body
    owners.append({'id': id, 'body': body})
archives = {str(namespace[key]) for key in ('CAPTURE', 'COPY', 'PRODUCTS')}
archives |= {'docs/audits/record-value-' + name + '-20261004' for name in
             ('semantic-join', 'actors', 'api-join', 'core-join')}
archives |= {'docs/audits/record-value-' + family + '-20261004'
             for family, filename in namespace['FAMILIES'].values()}
binding = {'revision': revision, 'task_path': task_path, 'task_body': task,
           'owners': owners, 'archives': {p: namespace['sealed'](Path(p)) for p in sorted(archives)}}
destination = BASE / 'binding.json'
assert not destination.exists(), 'never overwrite original whole source authority'
destination.write_text(json.dumps(binding, sort_keys=True, indent=2) + '\n')
print('Captured complete committed source/model/copy/capture owners and archive authority; no results generated.')
