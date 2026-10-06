"""Bind a completed source slice before producing finite path models."""
from pathlib import Path
import json
import subprocess

ns = {'__name__': 'prepare_parser_path_models'}
base = Path('docs/audits/record-value-parser-path-models-20261006')
exec(compile((base / 'verify.py').read_bytes(), str(base / 'verify.py'), 'exec'), ns)
assert not (base / 'binding.json').exists() and not (base / 'manifest.json').exists()
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
task = subprocess.check_output(['git', 'show', ns['REVISION'] + ':' + task_path])
text = task.decode(); start = text.index('- ID: `' + ns['OWNER'] + '`'); end = text.index('\n- ID:', start + 1)
archives = {str(root): {p.name: ns['identity'](p.read_bytes()) for p in root.iterdir()}
            for root in [ns['SOURCE'], ns['PUBLICATION']]}
receipts = {p: ns['identity'](Path(p).read_bytes()) for p in [
    'docs/audits/parser-source-checks-20261005/superseding-sealed-reader.json',
    'docs/audits/parser-source-checks-20261005/verify_superseding_receipt.py']}
(base / 'binding.json').write_text(json.dumps({'revision': ns['REVISION'], 'owner': ns['OWNER'],
    'task_path': task_path, 'task_identity': ns['identity'](task), 'owner_body': text[start:end],
    'archives': archives, 'receipts': receipts}, sort_keys=True, indent=2) + '\n')
