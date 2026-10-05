"""Retrieve a complete authenticated predecessor by one bounded catalog ID."""
import hashlib
import json
import sys
from pathlib import Path

BASE = Path('docs/audits/knowledge-card-rollover-selection-20261005')


def read(name):
    source = json.loads((BASE / 'source.json').read_text())['sources']
    if name not in source:
        raise ValueError('unknown archived card ID')
    row = source[name]
    path = Path(row['locator'])
    if path.is_absolute() or '..' in path.parts or path.is_symlink() or not path.is_file():
        raise ValueError('unsafe or missing archive')
    raw = path.read_bytes()
    if len(raw) != row['bytes'] or hashlib.sha256(raw).hexdigest() != row['sha256']:
        raise ValueError('archive identity mismatch')
    return raw


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit('usage: python3 -B .../read_source.py <card-id> (repository root)')
    try:
        sys.stdout.buffer.write(read(sys.argv[1]))
    except ValueError as error:
        raise SystemExit(str(error))
