"""Verify the current canonical core with every selected ignored view absent."""
import json
import os
from pathlib import Path
import subprocess
from capture import BASE, save

plan = json.loads((BASE / 'plan.json').read_bytes())
before = {row['path']: os.path.lexists(row['path']) for row in plan['copies']}
assert not any(before.values())
command = ['python3', '-B', 'docs/audits/raw-canonical-publication-20261011/verify.py', '--core']
result = subprocess.run(command, capture_output=True, text=True)
after = {row['path']: os.path.lexists(row['path']) for row in plan['copies']}
save('post-core-result.json', dict(command=command, status=result.returncode, stdout=result.stdout,
                                  stderr=result.stderr, before=before, after=after,
                                  condition='Actual verification with every declared ignored checkpoint copy absent. This records a dated observation; later legitimate reconstruction is permitted.'))
assert type(result.returncode) is int and result.returncode == 0 and result.stderr == ''
assert result.stdout == 'PASS complete finite raw admission and current canonical core; delivery remains separate.\n'
assert before == after and not any(after.values())
print('PASS current canonical core without any selected ignored view; original source/native evidence remains qualified.')
