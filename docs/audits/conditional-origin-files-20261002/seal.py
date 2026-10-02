import hashlib
import json
from pathlib import Path

root = Path('docs/audits/conditional-origin-files-20261002')
manifest = root / 'manifest.json'
assert not manifest.exists(), 'immutable seal must never be rewritten'
files = {str(p.relative_to(root)): {'bytes': p.stat().st_size,
         'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
         for p in sorted(root.rglob('*')) if p.is_file()}
manifest.write_text(json.dumps({'files': files}, sort_keys=True, indent=2) + '\n')
print('PASS complete immutable archive member/byte/hash seal')
