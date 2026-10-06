"""Pin only the completed committed function-order slice and actual receipts."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-argument-roles-20261006')
ns = {'__name__': 'prepare_parser_argument_roles'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
assert not (BASE / 'binding.json').exists() and not (BASE / 'manifest.json').exists()
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
task = subprocess.check_output(['git', 'show', ns['REVISION'] + ':' + task_path])
text = task.decode(); start = text.index('- ID: `' + ns['OWNER'] + '`'); end = text.index('\n- ID:', start + 1)
archives = {str(root): {path: ns['identity'](raw) for path, raw in
                       ns['prior']['committed_members'](ns['REVISION'], str(root)).items()}
            for root in [ns['ORDER'], ns['CHECKS']]}
(BASE / 'binding.json').write_text(json.dumps({'revision': ns['REVISION'], 'owner': ns['OWNER'],
    'task_path': task_path, 'task_identity': ns['identity'](task), 'owner_body': text[start:end],
    'archives': archives}, sort_keys=True, indent=2) + '\n')
