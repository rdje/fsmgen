import hashlib,json
from pathlib import Path
base=Path('docs/audits/prepared-reservation-snapshot-diagnosis-20261003')
manifest=json.loads((base/'manifest.json').read_text())
assert manifest['baseline']=='3193b92c3669daec5d0a6f2053ed471e015087b0'
actual={str(p.relative_to(base)) for p in base.rglob('*') if p.is_file() and p.name!='manifest.json'}
assert actual==set(manifest['members'])
for name,declared in manifest['members'].items():
    path=base/name
    assert '..' not in Path(name).parts and not Path(name).is_absolute()
    raw=path.read_bytes()
    assert len(raw)==declared['bytes'] and hashlib.sha256(raw).hexdigest()==declared['sha256'],name
print('PASS independent sealed diagnosis membership, byte counts and hashes; no member rewritten.')
