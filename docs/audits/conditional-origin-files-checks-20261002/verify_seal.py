import hashlib
import json
from pathlib import Path
root = Path('docs/audits/conditional-origin-files-20261002')
manifest = json.loads((root / 'manifest.json').read_text())['files']
actual = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and p != root / 'manifest.json'}
assert actual == set(manifest), 'archive membership changed'
for name, identity in manifest.items():
    data = (root / name).read_bytes()
    assert len(data) == identity['bytes'] and hashlib.sha256(data).hexdigest() == identity['sha256'], name
print('PASS complete file-origin archive membership/bytes/hashes remain sealed')
