import hashlib,json
from pathlib import Path
B=Path('docs/audits/atl-source-width-kind-repair-20261003');assert not (B/'manifest.json').exists()
rows={str(p.relative_to(B)):{'bytes':len(p.read_bytes()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(B.rglob('*')) if p.is_file()}
(B/'manifest.json').write_text(json.dumps({'baseline':'b30ed324e63549180f50c3d624d386258fba7405','members':rows},sort_keys=True,indent=2)+'\n');print('Sealed',len(rows),'members after completed verification.')
