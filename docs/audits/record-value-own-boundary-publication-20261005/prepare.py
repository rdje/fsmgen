"""Bind complete committed publication dependencies before extending live facts."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-own-boundary-publication-20261005')
REVISION = '73f87035c69ea3fd7d53b64ab88501e049da2af8'
ARCHIVES = ('docs/audits/record-value-current-helper-reader-20261005',
            'docs/audits/book-source-plane-20261005',
            'docs/audits/record-value-own-subtest-boundaries-20261005',
            'docs/audits/record-value-helper-reader-role-adapter-20261005',
            'docs/audits/helper-reader-role-rendered-20261005')
RECEIPTS = ('docs/audits/record-value-own-subtest-checks-20261005/sealed-reader.json',
            'docs/audits/record-value-own-subtest-checks-20261005/verify_receipt.py',
            'docs/audits/helper-reader-role-adapter-checks-20261005/sealed-reader.json',
            'docs/audits/helper-reader-role-adapter-checks-20261005/verify_receipt.py')
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
receipts = {}
for path in RECEIPTS:
    raw = Path(path).read_bytes()
    assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + path])
    receipts[path] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
target.write_text(json.dumps({'revision': REVISION, 'archives': archives, 'receipts': receipts}, sort_keys=True, indent=2) + '\n')
print('PASS whole committed original/current-source/snapshot-adapter/rendered dependency and actual receipt domains bound.')
