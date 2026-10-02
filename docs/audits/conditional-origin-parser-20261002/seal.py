"""One-time exact member seal; never append after this succeeds."""
import hashlib
import json
from pathlib import Path
base = Path('docs/audits/conditional-origin-parser-20261002')
assert not (base / 'manifest.json').exists()
members = {}
for path in sorted(p for p in base.rglob('*') if p.is_file()):
    assert not path.is_symlink()
    raw = path.read_bytes()
    members[str(path.relative_to(base))] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
(base / 'manifest.json').write_text(json.dumps({
    'schema_version': 1, 'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.1',
    'baseline': '985e5e9707cd987a7b70a878f0c686ad36e191d6', 'members': members,
}, sort_keys=True, indent=2) + '\n')
print('PASS exact member census sealed; archive is now immutable')
