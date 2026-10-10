"""Retain the first whole independent source/product reconstruction result."""
import hashlib
import json
import traceback
from pathlib import Path
import oracle_repaired as oracle

BASE = oracle.BASE


def main():
    path = BASE / 'repaired-independent.json'
    assert not path.exists()
    files = ['oracle_repaired.py', 'check_oracle_repaired.py', 'repaired-catalogue.json', 'repaired-hypotheses.json',
             'fixtures.pl', 'repaired-native.json', 'repaired-joined.json']
    inputs = {}
    for name in files:
        raw = (BASE / name).read_bytes()
        inputs[name] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
    result = {'inputs': inputs, 'role': 'Independent complete finite source/token/header/body/loss reconstruction. No producer renderer is imported; unselected engine flags, cross-call identity and original settings remain unmeasured.'}
    try:
        catalogue = json.loads((BASE / 'repaired-catalogue.json').read_bytes())
        hypotheses = json.loads((BASE / 'repaired-hypotheses.json').read_bytes())
        native = json.loads((BASE / 'repaired-native.json').read_bytes())
        joined = json.loads((BASE / 'repaired-joined.json').read_bytes())
        assert type(joined['status']) is int and joined['status'] == 0 and joined['error'] == ''
        result['products'] = oracle.validate(catalogue, hypotheses, json.loads(native['stdout']), joined['products'])
        result['status'] = 0
        result['error'] = ''
    except Exception:
        result['status'] = 1
        result['error'] = traceback.format_exc()
    path.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(result['error'] if result['status'] else 'PASS independent entire finite source hypotheses, full public bodies and loss/holder products reconstruct.')
    raise SystemExit(result['status'])


if __name__ == '__main__':
    main()
