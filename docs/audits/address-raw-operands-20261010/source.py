"""Bind the whole qualified admission and selected complete operand inputs."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-raw-operands-20261010')
PRIOR = Path('docs/audits/address-raw-admission-20261010')
REVISION = 'b58aa218a437c543d46d68457b04f3c4f249545e'
A = Path('docs/audits')
PATHS = {
    'raw': A / 'record-value-class-frame-join-20261006/raw-product.json',
    'classes': A / 'record-value-class-frame-join-20261006/source-models.json',
    'frames': A / 'record-value-class-frame-join-20261006/proofs.json',
    'source': A / 'address-source-integration-20261010/hypotheses.json',
    'coordinates': A / 'coordinate-original-matching-qualified-20261009/matching.json',
    'original_ordinary': A / 'record-value-original-candidate-20261004/ordinary.json',
    'original_storable': A / 'record-value-original-candidate-20261004/storable.json',
    'original_controls': A / 'record-value-original-candidate-20261004/controls.json',
    'raw_grammar': A / 'record-value-original-raw-20261005/trace_inventory.py',
    'helper_grammar': A / 'record-value-original-callback-paths-20261005/verify.py',
    'parser_grammar': A / 'record-value-parser-argument-roles-20261006/verify.py',
}
SUCCESS = ('PASS complete independent original/raw/source prerequisite admission; '
           'operand parsing and numeric role/lifetime meanings remain open.\n')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def read(path):
    path, root = Path(path), Path.cwd().resolve()
    full = root / path
    if (path.is_absolute() or '..' in path.parts or '.git' in path.parts or full.resolve() != full
            or not full.is_file() or full.stat().st_dev != root.stat().st_dev):
        raise ValueError('plain own same-volume operand input')
    for parent in full.parents:
        if parent == root:
            break
        if (parent / '.git').exists():
            raise ValueError('operand input repository boundary')
    return full.read_bytes()


def rebuild():
    actual = json.loads(read(BASE / 'checks.json'))['prerequisite']
    expected = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(PRIOR / 'verify.py')]
    if (type(actual['status']) is not int or actual['status'] != 0 or actual['command'] != expected
            or actual['stdout'] != SUCCESS or actual['instruments'][str(PRIOR / 'verify.py')] != pin(read(PRIOR / 'verify.py'))):
        raise ValueError('actual complete operand prerequisite admission')
    programme = json.loads(read(PRIOR / 'proof.json'))['programmes']
    if any(pin(read(PRIOR / p)) != identity for p, identity in programme.items()):
        raise ValueError('complete corrected admission programmes')
    prior_paths = sorted(p for p in PRIOR.rglob('*') if p.is_file() or p.is_symlink())
    tree = subprocess.run(['git', '--no-replace-objects', 'ls-tree', '-r', '--name-only', REVISION, '--', str(PRIOR)],
                          capture_output=True, text=True)
    if tree.returncode or tree.stderr or tree.stdout.splitlines() != list(map(str, prior_paths)):
        raise ValueError('whole committed admission namespace')
    paths = sorted(set(prior_paths) | set(PATHS.values()))
    members = {}
    for path in paths:
        raw = read(path)
        old = subprocess.run(['git', '--no-replace-objects', 'cat-file', 'blob', REVISION + ':' + str(path)], capture_output=True)
        if old.returncode or old.stderr or old.stdout != raw:
            raise ValueError('whole fixed committed operand input: ' + str(path))
        members[str(path)] = pin(raw)
    spec = {name: {'path': str(path), 'identity': members[str(path)]} for name, path in PATHS.items()}
    return spec, {'revision': REVISION, 'members': members, 'prerequisite': pin(read(PRIOR / 'proof.json')),
                  'actual_prerequisite': actual,
                  'scope': 'Complete dated admission and whole original/raw/source/class/frame/coordinate products; no original recapture or numeric identity interpretation.'}


def main():
    spec, binding = rebuild()
    for name, value in (('inputs.json', spec), ('binding.json', binding)):
        path = BASE / name
        if path.exists():
            raise ValueError('retain first complete operand source intake')
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    print('PASS complete admitted original/raw/source operand inputs; lossless grammar and numeric meanings remain unqualified.')


if __name__ == '__main__':
    main()
