import hashlib
import json
from pathlib import Path

root = Path('docs/audits/conditional-origin-library-20261002')
assert not (root / 'manifest.json').exists()
files = {str(p.relative_to(root)): {'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
    for p in sorted(root.rglob('*')) if p.is_file()}
(root / 'manifest.json').write_text(json.dumps({
    'owner':'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.2.1',
    'baseline':'e95955e704c452e41277e3c402ce832912d700f5','files':files}, indent=2, sort_keys=True) + '\n')
print('PASS exact immutable source/recipe/product/member/byte/hash seal')
