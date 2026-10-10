"""Authenticate complete original source domains and fresh published readers."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/observer-display-contract-20261010')
PRIOR = Path('docs/audits/observer-join-prerequisite-20261010')
REVISION = '4b170801ddceb148da52df769f7a53b4dda93d05'
READERS = {
    'observer-diagnosis': str(PRIOR / 'verify.py'),
    'public-documentation': 'docs/audits/record-value-public-framework-profile-20261006/verify.py',
    'public-native-fixtures': 'docs/audits/record-value-public-native-fixtures-20261006/verify.py',
}


def module(path):
    ns = {'__name__': 'observer_display_prerequisite', '__file__': str(path)}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    destination = BASE / 'prerequisites.json'
    assert not destination.exists(), 'retain first prerequisite epoch'
    before = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
    assert before == REVISION, 'fixed prerequisite revision before replay'
    previous = json.loads((PRIOR / 'binding.json').read_bytes())
    selected = set(previous['custody']['roots']) | {str(PRIOR)}
    roots = sorted(p for p in selected if not any(p.startswith(q + '/') for q in selected if q != p))
    admitted = module(Path('docs/audits/address-raw-admission-20261010/admit.py'))
    admitted['REVISION'] = REVISION
    admitted['roots'] = lambda: roots
    custody = admitted['custody']()
    outcomes = {}
    for name, programme in READERS.items():
        command = ['python3', '-B', programme]
        source = Path(programme).read_bytes()
        r = subprocess.run(command, capture_output=True)
        outcomes[name] = {'command': command, 'status': r.returncode,
                          'stdout': r.stdout.decode(), 'stderr': r.stderr.decode(),
                          'programme': pin(source)}
        assert r.returncode == 0 and source == Path(programme).read_bytes(), (name, outcomes[name])
    assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip() == REVISION
    record = {'revision': REVISION, 'custody': custody, 'actual_readers': outcomes,
              'role': 'Fresh full published semantic/source/saved-native prerequisite readers; original/native fixture captures are retained, not recaptured.',
              'locality': 'Required installed Perl/public Carp/Scalar::Util/overload/JSON interfaces are read-only toolchain dependencies. Own fixtures and every output remain repository-local; no provider implementation or external repository is inspected or changed.'}
    destination.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    print('PASS complete fixed source and observer/public prerequisite readers; original execution and formatter/settings identity remain unmeasured.')


if __name__ == '__main__':
    main()
