"""Bind the completed publication frontier before original parser inventory."""
import json
import subprocess
from pathlib import Path
import importlib.util

BASE = Path('docs/audits/record-value-original-parser-sources-20261005')
spec = importlib.util.spec_from_file_location('parser_source_intake', BASE / 'verify.py')
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
task = subprocess.check_output(['git', 'show', reader.REVISION + ':' + task_path], text=True)
start = task.index('- ID: `' + reader.OWNER + '`')
end = task.index('\n- ID:', start + 1)
owner = task[start:end]
assert '\n  Status: `done`\n' in owner
receipts = ('docs/audits/own-boundary-publication-checks-20261005/sealed-reader.json',
            'docs/audits/own-boundary-publication-checks-20261005/verify_receipt.py')
target = BASE / 'binding.json'
assert not target.exists()
target.write_text(json.dumps({'revision': reader.REVISION, 'owner': reader.OWNER,
    'task_path': task_path, 'task_body': task, 'owner_body': owner,
    'archives': {str(reader.PRIOR): {p.name: reader.identity(p.read_bytes()) for p in reader.PRIOR.iterdir()}},
    'receipts': {path: reader.identity(Path(path).read_bytes()) for path in receipts}}, sort_keys=True, indent=2) + '\n')
print('PASS whole committed completed own-source publication and actual successful receipt intake.')
