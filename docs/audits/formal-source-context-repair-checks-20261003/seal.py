import hashlib,json
from pathlib import Path
B=Path('docs/audits/formal-source-context-cause-repair-20261003');assert not (B/'manifest.json').exists()
rows={str(p.relative_to(B)):{'bytes':len(p.read_bytes()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(B.rglob('*')) if p.is_file()}
(B/'manifest.json').write_text(json.dumps({'baseline':'4ed8478c149cf632238dd120570756c96c717dcb','members':rows},sort_keys=True,indent=2)+'\n');print('Sealed',len(rows),'members after completed final verification.')
