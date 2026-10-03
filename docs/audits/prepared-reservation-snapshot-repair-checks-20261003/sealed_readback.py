import hashlib,json
from pathlib import Path
base=Path('docs/audits/prepared-reservation-snapshot-repair-20261003')
manifest=json.loads((base/'manifest.json').read_text())
assert manifest['baseline']=='9c6b6191de86218abae3f29d292373bf935aac1f'
actual={str(p.relative_to(base)) for p in base.rglob('*') if p.is_file() and p.name!='manifest.json'}
assert actual==set(manifest['members'])
for name,declared in manifest['members'].items():
    path=base/name
    assert '..' not in Path(name).parts and not Path(name).is_absolute()
    raw=path.read_bytes()
    assert len(raw)==declared['bytes'] and hashlib.sha256(raw).hexdigest()==declared['sha256'],name
print('PASS independent sealed repair membership, byte counts and hashes; no member rewritten.')
