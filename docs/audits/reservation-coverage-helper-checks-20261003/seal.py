import hashlib
import json
from pathlib import Path

base = Path('docs/audits/reservation-coverage-helper-causes-20261003')
records = {}
for path in sorted(base.iterdir()):
    if path.name == 'manifest.json':
        continue
    assert path.is_file(), path
    raw = path.read_bytes()
    records[path.name] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
(base / 'manifest.json').write_text(json.dumps(records, sort_keys=True, indent=2) + '\n')
print('PASS bounded profile envelope sealed; reproduce into a task-owned sibling.')
