"""Authenticate the sealed prior evidence actually used by this repair."""
import hashlib
import json
import subprocess
from pathlib import Path
old = Path('docs/audits/reusable-cause-repair-20261003')
rev = '48b2380d79e44de815587c093a88ede6a244d34d'
manifest = old / 'manifest.json'
assert manifest.read_bytes() == subprocess.check_output(['git', 'show', rev + ':' + str(manifest)])
members = json.loads(manifest.read_text())['members']
assert set(members) == {str(p.relative_to(old)) for p in old.rglob('*') if p.is_file() and p.name != 'manifest.json'}
for name, row in members.items():
    raw = (old / name).read_bytes()
    assert row == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
for name in ('ordinary.pl', 'products.json', 'models.py', 'bindings.json'):
    path = old / name
    assert path.read_bytes() == subprocess.check_output(['git', 'show', rev + ':' + str(path)])
print('PASS whole sealed prior archive/member closure and exact Git-bound cause/model/producer inputs.')
