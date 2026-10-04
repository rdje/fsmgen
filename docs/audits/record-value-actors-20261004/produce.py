"""Retain every whole original source parse without generating expectations."""
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).parent
path = Path('docs/audits/record-value-runtime-20261004/ordinary.json')
raw = path.read_bytes()
native = json.loads(raw)
(BASE / 'parses.json').write_text(json.dumps({'native_input': {'bytes': len(raw),
    'sha256': hashlib.sha256(raw).hexdigest()}, 'rows': native['parses']}, sort_keys=True, indent=2) + '\n')
print('PASS all four original whole source/parser/caller/typed product/outcome records retained; source-model reader remains required.')
