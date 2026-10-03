import hashlib,json
from pathlib import Path
B=Path('docs/audits/prepared-reservation-snapshot-repair-20261003')
assert not (B/'manifest.json').exists()
rows={str(p.relative_to(B)):{'bytes':len(p.read_bytes()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(B.rglob('*')) if p.is_file()}
(B/'manifest.json').write_text(json.dumps({'baseline':'9c6b6191de86218abae3f29d292373bf935aac1f','members':rows},sort_keys=True,indent=2)+'\n')
print('Sealed completed snapshot repair:',len(rows),'members.')
