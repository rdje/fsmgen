"""Replay pure source derivations, never producer main or capture execution."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/coordinate-refusal-path-inputs-20261009')
CHECKS = Path('docs/audits/coordinate-refusal-path-input-checks-20261009')


def load(name):
    path = BASE / name
    raw = path.read_bytes()
    namespace = {'__name__': 'pure_saved_derivation', '__file__': str(path.resolve())}
    exec(compile(raw, str(path), 'exec'), namespace)
    return namespace, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    checks = json.loads((CHECKS / 'checks.json').read_bytes())
    outcomes = []
    for filename, receipt, kind, message in (
        ('first-paths.py.txt', 'path-inputs', ValueError, 'unique source-authored callback statement'),
        ('first-indexed-paths.py.txt', 'path-inputs-indexed', KeyError, "'parses'"),
    ):
        programme, identity = load(filename)
        assert checks[receipt]['instruments'][str(BASE / 'paths.py')] == identity
        assert checks[receipt]['status'] == 1 and message in checks[receipt]['stderr']
        try:
            programme['derive'](*programme['inputs']())
        except Exception as error:
            assert type(error) is kind and str(error) == message
            outcomes.append({'programme': filename, 'identity': identity,
                             'failure_type': type(error).__name__, 'message': str(error)})
        else:
            raise ValueError('first source derivation no longer reproduces its exact failure')
    corrected, identity = load('paths.py')
    actual = corrected['derive'](*corrected['inputs']())
    assert json.dumps(actual, sort_keys=True) == json.dumps(json.loads((BASE / 'paths.json').read_bytes()), sort_keys=True)
    assert checks['path-inputs-domain']['status'] == 0
    assert checks['path-inputs-domain']['instruments'][str(BASE / 'paths.py')] == identity
    print(json.dumps({'status': 0, 'first_failures': outcomes,
                      'corrected_identity': identity, 'scope': 'Pure source-only allocation repairs; no sealed producer main or capture runs.'}, sort_keys=True))


if __name__ == '__main__':
    main()
