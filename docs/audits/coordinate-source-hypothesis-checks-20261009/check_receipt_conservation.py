"""Verify every completed named result survived overlapping check completion."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/coordinate-source-hypothesis-checks-20261009')
FIRST_PATH = 'docs/audits/coordinate-source-hypotheses-20261009/verify.py'


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    checks = json.loads((BASE / 'checks.json').read_bytes())
    required = {'source-publication', 'independent-preseal', 'archive-repair', 'independent-repaired',
                'fixed-seal-controls', 'published-sealed', 'actual-results', 'focused'}
    if not required <= set(checks):
        raise ValueError('complete completed source-publication receipt domain')
    retained = {name: checks[name] for name in sorted(required)}
    for name, row in retained.items():
        expected = 1 if name == 'independent-preseal' else 0
        if type(row['status']) is not int or row['status'] != expected:
            raise ValueError('complete actual successful and preserved first-failure statuses')
        for path, identity in row['instruments'].items():
            source = BASE / 'first-verify.py.txt' if name == 'independent-preseal' and path == FIRST_PATH else Path(path)
            if pin(source.read_bytes()) != identity:
                raise ValueError('whole current or retained-first actual instrument identity')
    if 'All tests successful.' not in retained['focused']['stdout'] or 'PASS complete actual source-only hypothesis producer/reader results' not in retained['actual-results']['stdout']:
        raise ValueError('both overlapping complete actual success streams retained')
    original = json.dumps(retained, sort_keys=True, indent=2).encode() + b'\n'
    print(json.dumps({'result': 'PASS complete receipt conservation; no completed result lost',
        'reconstructible_first_checks': pin(original),
        'receipts': {name: pin(json.dumps(row, sort_keys=True).encode()) for name, row in retained.items()}}, sort_keys=True))


if __name__ == '__main__':
    main()
