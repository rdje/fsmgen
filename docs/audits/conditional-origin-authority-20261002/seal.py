import hashlib
import json
from pathlib import Path

root = Path('docs/audits/conditional-origin-authority-20261002')
assert not (root / 'manifest.json').exists()
files = {str(p.relative_to(root)): {'bytes': p.stat().st_size,
    'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
    for p in sorted(root.rglob('*')) if p.is_file()}
manifest = {'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.1',
    'baseline': 'cb2a156df5a3c8169ad9ca1cfaa9c05046e33bf8',
    'scope': 'Immutable complete local-source authority proof; broader confirmatory regression is separately consumed.',
    'files': files}
(root / 'manifest.json').write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
print('PASS immutable exact member/byte/hash seal')
