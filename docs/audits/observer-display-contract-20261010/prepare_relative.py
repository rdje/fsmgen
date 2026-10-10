"""Bind unchanged first hypotheses to a fresh repository-relative capture driver."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/observer-display-contract-20261010')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    first = json.loads((BASE / 'pre-native.json').read_bytes())
    assert first['inputs'] == {name: pin((BASE / name).read_bytes()) for name in first['inputs']}
    path = BASE / 'relative-pre-native.json'
    assert not path.exists() and not (BASE / 'relative-native.json').exists()
    names = [*first['inputs'], 'capture_relative.py', 'prepare_relative.py', 'pre-native.json']
    record = {'inputs': {name: pin((BASE / name).read_bytes()) for name in names},
              'role': 'Unchanged complete first pre-observation source hypotheses. Fresh capture repairs only absolute driver source keys; it does not learn formatting from the first native output.'}
    path.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    print('PASS unchanged first source hypotheses bound before fresh relative-path capture.')


if __name__ == '__main__':
    main()
