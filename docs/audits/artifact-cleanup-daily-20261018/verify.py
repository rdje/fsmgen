"""Authenticate the complete dated sweep before replaying its fixed reader."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys

if not __debug__:
    raise SystemExit('Verification assertions must be enabled.')

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
manifest = json.loads((HERE / 'manifest.json').read_bytes())
assert manifest['owner'] == 'TASK-ACCEPTANCE-CHECKLIST-BODY-BOUNDARY.3'
assert set(manifest['sha256']) == {'cleanup.py', 'verify.py', 'result.json.gz',
                                 'first-inspection.json.gz', 'mismatched-inspection.json.gz'}
for name, digest in manifest['sha256'].items():
    assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == digest
subprocess.run([sys.executable, '-B', str(HERE / 'cleanup.py'), '--verify'],
               cwd=ROOT, check=True, timeout=30)
print('Complete sweep source, first failures and retained receipt identities authenticate.')
