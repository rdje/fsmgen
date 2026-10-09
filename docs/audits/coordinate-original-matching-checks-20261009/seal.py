"""Seal the complete qualified diagnosis and publish its fixed-seal reader."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/coordinate-original-mismatch-20261009')
CHECKS = Path('docs/audits/coordinate-original-matching-checks-20261009')


def pin(raw):
    return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}


def main():
    names = {'verify-initial.py', 'verify.py', 'public.json', 'public.py', 'caller-pattern-shift.pl', 'public-first.py', 'guard-message-shift.pl', 'caller-fixture.pl', 'caller-label-shift.pl', 'guard-live.json', 'guard-live-message-shift.pl', 'guard_live.py', 'scope.txt', 'guard-live-fixture.pl', 'guard-fixture.pl', 'guard-live-operand-shift.pl', 'guard-expression-shift.pl', 'census.json', 'census.py'}
    if {p.name for p in BASE.iterdir()} != names or (CHECKS/'verify_diagnosis.py').exists():
        raise ValueError('complete first qualified diagnosis seal only')
    seal = {name:pin((BASE/name).read_bytes()) for name in sorted(names)}
    raw = (json.dumps(seal,sort_keys=True,indent=2)+'\n').encode()
    (BASE/'seal.json').write_bytes(raw)
    template = '''"""Read the complete dated diagnosis only after authenticating its original seal."""
import hashlib
import json
import runpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-original-mismatch-20261009')
SEAL = __SEAL__


def pin(raw):
    return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}


def authenticate(folder):
    directory = ROOT / folder
    if directory.resolve() != directory or not directory.is_dir() or directory.stat().st_dev != ROOT.stat().st_dev:
        raise ValueError('fixed diagnosis plain same-volume root')
    for parent in directory.parents:
        if parent == ROOT:
            break
        if parent.is_symlink() or (parent/'.git').exists():
            raise ValueError('fixed diagnosis own regular parents')
    path = directory/'seal.json'
    if not path.is_file() or path.is_symlink() or pin(path.read_bytes()) != SEAL:
        raise ValueError('fixed complete diagnosis seal identity')
    members = json.loads(path.read_bytes())
    if {p.name for p in directory.iterdir()} != set(members) | {'seal.json'}:
        raise ValueError('fixed complete diagnosis member domain')
    for name,expected in members.items():
        path = directory/name
        if not path.is_file() or path.is_symlink() or path.stat().st_dev != ROOT.stat().st_dev or pin(path.read_bytes()) != expected:
            raise ValueError('fixed complete diagnosis member bytes')


def main():
    if Path.cwd().resolve() != ROOT:
        raise ValueError('invoke published diagnosis from repository root')
    authenticate(BASE)
    runpy.run_path(str(BASE/'verify.py'))['main']()
    authenticate(BASE)


if __name__ == '__main__':
    main()
'''
    (CHECKS/'verify_diagnosis.py').write_text(template.replace('__SEAL__',repr(pin(raw))))
    print(json.dumps({'result':'PASS complete fixed diagnosis seal and published reader','seal':pin(raw)},sort_keys=True))


if __name__ == '__main__':
    main()
