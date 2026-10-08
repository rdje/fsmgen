"""Published immutable-bank reader; pre-seal setup cannot earn qualification."""
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-source-sites-checks-20261008')
BANK = Path('docs/audits/coordinate-source-sites-20261008')


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def authenticate(bank=BANK):
    root = ROOT / bank
    need(not bank.is_absolute() and '..' not in bank.parts and root.resolve() == root
         and root.is_dir() and root.stat().st_dev == ROOT.stat().st_dev,
         'own plain same-volume source-site bank')
    binding = json.loads((ROOT / BASE / 'bank-binding.json').read_bytes())
    seal = root / 'seal.json'
    need(seal.is_file() and not seal.is_symlink(), 'immutable source-site seal is required')
    need(pin(seal.read_bytes()) == binding['seal'], 'exact original immutable source-site seal identity')
    need(all(path.is_file() and not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
             for path in root.iterdir()), 'complete plain same-volume source-site members')
    members = {path.name: pin(path.read_bytes()) for path in sorted(root.iterdir()) if path.name != 'seal.json'}
    need(json.dumps(members, sort_keys=True) == json.dumps(json.loads(seal.read_bytes()), sort_keys=True),
         'whole immutable source-site member population and bytes')
    need(binding['path'] == str(BANK) and binding['owner'] == (root / 'scope.txt').read_text().strip(),
         'exact immutable source-site path and owning scope')


def main():
    need(Path.cwd().resolve() == ROOT, 'invoke published site reader from repository root')
    authenticate()
    result = subprocess.run(['python3', '-B', str(BANK / 'verify.py')], cwd=ROOT, capture_output=True, text=True)
    need(type(result.returncode) is int and result.returncode == 0 and result.stderr == ''
         and result.stdout == 'PASS complete independent binary source-site allocation and genuine controls; lexical extents do not predict original coordinates.\n',
         'whole unchanged independent source-site qualification result')
    authenticate()
    print('PASS complete immutable source-site seal, membership and independent qualification; per-refusal composition and original coordinates remain pending.')


if __name__ == '__main__':
    main()
