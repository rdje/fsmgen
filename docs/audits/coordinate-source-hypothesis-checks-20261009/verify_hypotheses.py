"""Published whole source-hypothesis reader: authenticate the fixed complete seal first."""
import hashlib
import json
import runpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-source-hypotheses-20261009')
SEAL = {'bytes': 503, 'sha256': 'bd4e233645ef0cec6870d89294701bd6ba727efbedba00cd6570a1247e17b7cf'}


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def authenticate(folder):
    directory = ROOT / folder
    if (directory.resolve() != directory or not directory.is_dir()
            or directory.stat().st_dev != ROOT.stat().st_dev):
        raise ValueError('fixed hypothesis plain same-volume root')
    seal_path = directory / 'seal.json'
    if not seal_path.is_file() or seal_path.is_symlink() or pin(seal_path.read_bytes()) != SEAL:
        raise ValueError('fixed complete hypothesis seal identity')
    seal = json.loads(seal_path.read_bytes())
    if {p.name for p in directory.iterdir()} != set(seal) | {'seal.json'}:
        raise ValueError('fixed complete hypothesis member domain')
    for name, identity in seal.items():
        path = directory / name
        if (not path.is_file() or path.is_symlink() or path.stat().st_dev != ROOT.stat().st_dev
                or pin(path.read_bytes()) != identity):
            raise ValueError('fixed complete hypothesis member bytes')


def main():
    if Path.cwd().resolve() != ROOT:
        raise ValueError('invoke published hypothesis reader from repository root')
    authenticate(BASE)
    reader = runpy.run_path(str(BASE / 'verify.py'))
    reader['main']()
    authenticate(BASE)


if __name__ == '__main__':
    main()
