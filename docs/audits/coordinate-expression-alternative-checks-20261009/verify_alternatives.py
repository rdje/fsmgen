"""Read the complete dated expression only after authenticating its original seal."""
import hashlib
import json
import runpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-expression-alternatives-20261009')
SEAL = {'bytes': 503, 'sha256': 'f127d2339f05c655164fb0e314ece296b14f370e9f8aa9706a48c589863cfa6c'}


def pin(raw):
    return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}


def authenticate(folder):
    directory = ROOT / folder
    if directory.resolve() != directory or not directory.is_dir() or directory.stat().st_dev != ROOT.stat().st_dev:
        raise ValueError('fixed expression plain same-volume root')
    for parent in directory.parents:
        if parent == ROOT:
            break
        if parent.is_symlink() or (parent/'.git').exists():
            raise ValueError('fixed expression own regular parents')
    path = directory/'seal.json'
    if not path.is_file() or path.is_symlink() or pin(path.read_bytes()) != SEAL:
        raise ValueError('fixed complete expression seal identity')
    members = json.loads(path.read_bytes())
    if {p.name for p in directory.iterdir()} != set(members) | {'seal.json'}:
        raise ValueError('fixed complete expression member domain')
    for name,expected in members.items():
        path = directory/name
        if not path.is_file() or path.is_symlink() or path.stat().st_dev != ROOT.stat().st_dev or pin(path.read_bytes()) != expected:
            raise ValueError('fixed complete expression member bytes')


def main():
    if Path.cwd().resolve() != ROOT:
        raise ValueError('invoke published expression from repository root')
    authenticate(BASE)
    runpy.run_path(str(BASE/'verify.py'))['main']()
    authenticate(BASE)


if __name__ == '__main__':
    main()
