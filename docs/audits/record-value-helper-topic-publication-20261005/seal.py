"""Seal the complete admitted publication evidence once."""
import hashlib
import json
from pathlib import Path

base = Path('docs/audits/record-value-helper-topic-publication-20261005')
manifest = base / 'manifest.json'
assert not manifest.exists(), 'immutable first seal'
pins = {str(path): {'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
        for path in sorted(base.iterdir()) if path.is_file() and path != manifest}
manifest.write_text(json.dumps(pins, sort_keys=True, indent=2) + '\n')
