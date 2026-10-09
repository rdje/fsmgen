"""Seal the complete qualified observer and publish its fixed-seal reader."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/coordinate-observer-caller-20261009')
CHECKS = Path('docs/audits/coordinate-observer-caller-checks-20261009')


def pin(raw):
    return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}


def main():
    names = {'derive.py','verify.py','scope.txt','association.json','first-match.py.txt','second-match.py.txt','unexecuted-verify.py.txt','first-result.json','second-result.json','matching-scope.txt','first-checks.py.txt','first-checks.json','caller.pl','caller-inner-shift.pl','caller-outer-shift.pl','first-derive.py.txt','first-source-result.json'}
    if {p.name for p in BASE.iterdir()} != names or (CHECKS/'verify_callers.py').exists():
        raise ValueError('complete first qualified observer seal only')
    seal = {name:pin((BASE/name).read_bytes()) for name in sorted(names)}
    raw = (json.dumps(seal,sort_keys=True,indent=2)+'\n').encode()
    (BASE/'seal.json').write_bytes(raw)
    template = '''"""Read the complete dated observer only after authenticating its original seal."""
import hashlib
import json
import runpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-observer-caller-20261009')
SEAL = __SEAL__


def pin(raw):
    return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}


def authenticate(folder):
    directory = ROOT / folder
    if directory.resolve() != directory or not directory.is_dir() or directory.stat().st_dev != ROOT.stat().st_dev:
        raise ValueError('fixed observer plain same-volume root')
    for parent in directory.parents:
        if parent == ROOT:
            break
        if parent.is_symlink() or (parent/'.git').exists():
            raise ValueError('fixed observer own regular parents')
    path = directory/'seal.json'
    if not path.is_file() or path.is_symlink() or pin(path.read_bytes()) != SEAL:
        raise ValueError('fixed complete observer seal identity')
    members = json.loads(path.read_bytes())
    if {p.name for p in directory.iterdir()} != set(members) | {'seal.json'}:
        raise ValueError('fixed complete observer member domain')
    for name,expected in members.items():
        path = directory/name
        if not path.is_file() or path.is_symlink() or path.stat().st_dev != ROOT.stat().st_dev or pin(path.read_bytes()) != expected:
            raise ValueError('fixed complete observer member bytes')


def main():
    if Path.cwd().resolve() != ROOT:
        raise ValueError('invoke published observer from repository root')
    authenticate(BASE)
    runpy.run_path(str(BASE/'verify.py'))['main']()
    authenticate(BASE)


if __name__ == '__main__':
    main()
'''
    (CHECKS/'verify_callers.py').write_text(template.replace('__SEAL__',repr(pin(raw))))
    print(json.dumps({'result':'PASS complete fixed observer seal and published reader','seal':pin(raw)},sort_keys=True))


if __name__ == '__main__':
    main()
