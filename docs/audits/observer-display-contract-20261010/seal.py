"""Seal the complete fixed audit namespace before independent replay."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/observer-display-contract-20261010')
EXCLUDED = {'checks.json', 'proof.json', 'publication.json', 'native.html.txt', 'native-proof.json', 'manifest.json'}


def main():
    path = BASE / 'manifest.json'
    assert not path.exists()
    result = {}
    for p in BASE.rglob('*'):
        assert not p.is_symlink()
        name = str(p.relative_to(BASE))
        if p.is_file() and name not in EXCLUDED:
            raw = p.read_bytes()
            result[name] = dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
    path.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS whole fixed public-display namespace sealed; later actual receipts and separately checked book/native proof stay explicit.')


if __name__ == '__main__':
    main()
