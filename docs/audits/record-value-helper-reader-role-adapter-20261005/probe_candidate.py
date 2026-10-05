"""Prove historical replay remains valid with the complete retained live extension."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-helper-reader-role-adapter-20261005')
target = BASE / 'candidate-adapter.json'
assert not target.exists()
coupling = json.loads((BASE / 'coupling.json').read_text())
topic = Path(coupling['topic'])
before = topic.read_bytes()
assert before.decode() == coupling['before']
try:
    topic.write_text(coupling['candidate'])
    command = ['python3', '-B', str(BASE / 'adapter.py'), '--snapshot']
    result = subprocess.run(command, capture_output=True, text=True)
finally:
    topic.write_bytes(before)
record = {'candidate': coupling['candidate'], 'command': command, 'status': result.returncode, 'stdout': result.stdout,
          'stderr': result.stderr, 'restored': topic.read_bytes() == before,
          'scope': 'Actual historical replay with relevant live progress succeeds; this is not a current semantic qualification.'}
target.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
assert result.returncode == 0 and record['restored']
print('PASS actual complete source-qualified candidate no longer obstructs historical replay; original live bytes restored.')
