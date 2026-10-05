"""Bind complete committed historical programmes and qualified source authority."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-helper-reader-role-adapter-20261005')
REVISION = 'ebd3df0c21d2e8383e179cf88a81f0c780568e14'
ARCHIVES = ('docs/audits/book-source-plane-20261005',
            'docs/audits/record-value-current-helper-reader-20261005',
            'docs/audits/record-value-own-subtest-boundaries-20261005')

target = BASE / 'binding.json'
assert not target.exists()
archives = {}
for directory in ARCHIVES:
    members = {}
    for path in sorted(Path(directory).iterdir()):
        raw = path.read_bytes()
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + str(path)])
        members[path.name] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
    assert 'manifest.json' in members
    archives[directory] = members
target.write_text(json.dumps({'revision': REVISION, 'archives': archives}, sort_keys=True, indent=2) + '\n')
print('PASS whole committed historical plane/helper and qualified own-source archive domains bound.')
