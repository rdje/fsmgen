"""Real old-reader false RED at another complete root-local replay coordinate."""
import hashlib
import json
import os
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
ROOT = Path.cwd()
legacy = Path('docs/audits/record-value-field-join-20261004')
data = json.loads((legacy / 'join.json').read_text())
fixture = Path('.artifacts/record-value-portability-root-20261004')
fixture.mkdir(parents=True, exist_ok=True)
for path, row in data['sources'].items():
    target = fixture / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(row['body'])
for row in json.loads((legacy / 'doc-updates.json').read_text()):
    (fixture / row['path']).write_text(row['after'])
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
(fixture / task_path).parent.mkdir(parents=True, exist_ok=True)
(fixture / task_path).write_bytes(Path(task_path).read_bytes())
link = fixture / 'docs/audits'
expected_link = os.path.relpath(ROOT / 'docs/audits', ROOT / fixture / 'docs')
if link.is_symlink():
    assert os.readlink(link) == expected_link
else:
    assert not link.exists()
    link.symlink_to(expected_link, target_is_directory=True)
inputs = {}
for path in data['sources']:
    raw = (fixture / path).read_bytes()
    inputs[path] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
command = ['python3', '-B', str(legacy / 'verify.py')]
run = subprocess.run(command, cwd=fixture, text=True, capture_output=True)
raw_output = run.stdout + run.stderr
assert run.returncode == 1 and 'complete reader/control replay identity and outcomes' in raw_output, raw_output
(BASE / 'old-reader-relocated.json').write_text(json.dumps({'command': command,
    'working_directory': str(fixture), 'source_inputs': inputs,
    'status': run.returncode, 'output': raw_output}, sort_keys=True, indent=2) + '\n')
print('PASS real old reader rejects at a second working root only after both ordinary semantic readers and all seven controls pass; complete program/input bytes retained. Portable repair remains required.')
