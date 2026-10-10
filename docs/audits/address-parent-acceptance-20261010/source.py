"""Bind complete committed prerequisites and unchanged parent contracts."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-parent-acceptance-20261010')
REVISION = '556b9d5f9cd09b981a462619701d9032e5c0657e'
ROOT = Path('docs/audits')
NAMESPACES = ('address-raw-admission-20261010', 'address-raw-operands-20261010',
              'address-raw-join-20261010', 'address-numeric-join-20261010')
READERS = dict(zip(('admission', 'operands', 'holders', 'numerical'), NAMESPACES))
TASK = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def read(path):
    path = Path(path); root = Path.cwd().resolve(); full = root / path
    need(not path.is_absolute() and '..' not in path.parts and '.git' not in path.parts
         and full.resolve() == full and full.is_file() and full.stat().st_dev == root.stat().st_dev,
         'plain own same-volume parent input')
    for parent in full.parents:
        if parent == root:
            break
        need(not (parent / '.git').exists(), 'parent input repository boundary')
    return full.read_bytes()


def block(text, owner):
    start = text.index('- ID: `' + owner + '`\n')
    end = text.find('\n- ID: `', start + 1)
    need(end >= 0, 'complete parent task boundary')
    return text[start:end]


def contract(text):
    return dict(re.findall(r'^  (Goal|Acceptance|Children): `([^\n]+)`$', text, re.M))


def rebuild():
    old_task = subprocess.check_output(['git', '--no-replace-objects', 'show', REVISION + ':' + str(TASK)]).decode()
    current_task = TASK.read_text(); owner = (BASE / 'scope.txt').read_text().strip()
    numerical_parent = owner.rsplit('.', 1)[0]; raw_parent = numerical_parent.rsplit('.', 1)[0]
    contracts = {}
    for key in (raw_parent, numerical_parent, owner):
        original = block(old_task, key)
        need(contract(original) == contract(block(current_task, key)), 'complete unchanged parent acceptance contract')
        contracts[key] = {'whole_committed_node': original, 'contract': contract(original)}
    leaves = (raw_parent + '.1', raw_parent + '.2', numerical_parent + '.1', numerical_parent + '.2')
    completed = {}
    for key in leaves:
        original = block(old_task, key)
        need('  Status: `done`\n' in original and contract(original) == contract(block(current_task, key)),
             'complete committed prerequisite leaf acceptance')
        completed[key] = original
    spec = json.loads(read(ROOT / NAMESPACES[-1] / 'inputs.json'))
    for name, folder, filename in (
            ('admission', NAMESPACES[0], 'admission.json'), ('admission_proof', NAMESPACES[0], 'proof.json'),
            ('operand_proof', NAMESPACES[1], 'final-proof.json'), ('holder_proof', NAMESPACES[2], 'proof.json'),
            ('numerical', NAMESPACES[3], 'joining.json'), ('numerical_proof', NAMESPACES[3], 'proof.json')):
        path = ROOT / folder / filename
        spec[name] = {'path': str(path), 'identity': pin(read(path))}
    admission = json.loads(read(ROOT / NAMESPACES[0] / 'admission.json'))
    for index, (path, identity) in enumerate(sorted(admission['allocation']['products'].items())):
        need(pin(read(path)) == identity, 'whole admitted semantic prerequisite product')
        spec['admitted_product_' + str(index)] = {'path': path, 'identity': identity}
    paths = {Path(s['path']) for s in spec.values()}
    for folder in NAMESPACES:
        prefix = ROOT / folder
        current = sorted(str(p) for p in prefix.rglob('*') if p.is_file() or p.is_symlink())
        original = subprocess.check_output(['git', '--no-replace-objects', 'ls-tree', '-r', '--name-only', REVISION, '--', str(prefix)], text=True).splitlines()
        need(current == original, 'whole committed parent prerequisite namespace')
        paths.update(map(Path, current))
    members = {}
    for path in sorted(paths):
        raw = read(path)
        fixed = subprocess.check_output(['git', '--no-replace-objects', 'cat-file', 'blob', REVISION + ':' + str(path)])
        need(raw == fixed, 'whole fixed parent input: ' + str(path))
        members[str(path)] = pin(raw)
    need(all(s['identity'] == members[s['path']] for s in spec.values()), 'whole parent input registry')
    return spec, {'revision': REVISION, 'members': members, 'contracts': contracts, 'completed': completed,
                  'scope': 'Whole unchanged raw/numerical parent acceptance and fixed complete prerequisite namespaces; no native recapture or publication.'}


def main():
    spec, binding = rebuild()
    for name, value in (('inputs.json', spec), ('binding.json', binding)):
        path = BASE / name
        if path.exists():
            need(json.loads(path.read_bytes()) == value, 'whole immutable parent input binding')
        else:
            path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    print('PASS whole fixed parent prerequisite namespaces and unchanged complete acceptance contracts; parent qualification remains required.')


if __name__ == '__main__':
    main()
