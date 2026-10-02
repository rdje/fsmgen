"""One-time exact membership seal. Never append after this succeeds."""
import hashlib
import json
from pathlib import Path

base = Path(__file__).parent
assert not (base / 'manifest.json').exists()
members = {}
for path in sorted(p for p in base.rglob('*') if p.is_file()):
    assert not path.is_symlink()
    raw = path.read_bytes()
    members[str(path.relative_to(base))] = {
        'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
(base / 'manifest.json').write_text(json.dumps({
    'schema_version': 1,
    'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.1',
    'baseline': '828691e567f2f8d7b7541566303c195e63ffbf90',
    'members': members}, sort_keys=True, indent=2) + '\n')
print('PASS exact local formal origin member byte/hash census sealed')
