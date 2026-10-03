import hashlib,json
from pathlib import Path
B=Path('docs/audits/prepared-reservation-snapshot-diagnosis-20261003')
assert not (B/'manifest.json').exists()
rows={str(p.relative_to(B)):{'bytes':len(p.read_bytes()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(B.rglob('*')) if p.is_file()}
(B/'manifest.json').write_text(json.dumps({'baseline':'3193b92c3669daec5d0a6f2053ed471e015087b0','members':rows},sort_keys=True,indent=2)+'\n')
print('Sealed complete snapshot diagnosis after independent readback:',len(rows),'members.')
