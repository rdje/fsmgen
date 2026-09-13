"""Pin original finite release domains and their source applicability at one revision."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'b1cf7dae0ad9185ec10b1ea2a989e0377742ff8b'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.6'
JOINS = ['native-proxy-release-call-readback-join-20260912',
         'native-proxy-release-close-join-20260913',
         'native-proxy-release-omission-join-20260913']
RELEASE = 'native-proxy-observation-archive-release-20260911'
CONTRACT = 'native-proxy-release-interruption-contract-20260911'
BOUNDARY = 'native-proxy-observation-archive-release-boundaries-20260911'
LOWER = 'native-proxy-observation-archive-lower-reader-join-20260911'
DIRECTORIES = [RELEASE, CONTRACT, BOUNDARY, LOWER, *JOINS]
SCOPE = ('Complete the declared finite inactive release qualification from original retained evidence. '
         'Keep symbolic effects, original release, healthy boundaries, independent call/readback/absence faults, '
         'selected close reports/compositions and representative genuine omissions distinct. '
         'Conditional lower-reader composition does not assert every-site reachability. '
         'Combined lifetimes, compatibility, native authentication/transport, actual OS close failures, '
         'arbitrary-writer atomicity and historical startup/parent/full CI/push remain separate gates.')


def load(path):
    return json.loads(path.read_bytes())


def safe_bytes(path):
    assert path.is_relative_to(ROOT)
    for node in [path, *path.parents]:
        if node == ROOT:
            break
        assert not node.is_symlink() and node.stat().st_dev == ROOT.stat().st_dev
    assert path.is_file()
    return path.read_bytes()


def pin(path):
    raw = safe_bytes(path)
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def tree(revision=REVISION):
    assert subprocess.check_output(['git', 'rev-parse', '--show-object-format'], cwd=ROOT).strip() == b'sha1'
    rows = subprocess.check_output(['git', 'ls-tree', '-r', '-z', revision], cwd=ROOT).split(b'\0')
    result = {}
    for row in rows:
        if not row:
            continue
        metadata, name = row.split(b'\t', 1)
        mode, kind, oid = metadata.split()
        result[name.decode()] = dict(mode=mode.decode(), kind=kind.decode(), oid=oid.decode())
    return result


def input_paths(version):
    paths = set()
    for name in DIRECTORIES:
        directory = BASE.parent / name
        prefix = str(directory.relative_to(ROOT)) + '/'
        paths.update(path for path in version if path.startswith(prefix))
        manifest = ('contract.json' if name == CONTRACT else
                    'result/source-inventory.json' if name == LOWER else 'plan.json')
        paths.update(record['path'] for record in load(directory / manifest)['inputs'])
    return sorted(paths)


def build():
    assert load(BASE / 'prepare-pins.json') == [pin(BASE / 'prepare.py')]
    version = tree()
    inputs = []
    for relative in input_paths(version):
        info = version[relative]
        assert info['kind'] == 'blob' and info['mode'] in ('100644', '100755')
        raw = safe_bytes(ROOT / relative)
        oid = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
        assert oid == info['oid'], relative
        inputs.append(dict(path=relative, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest(), git_blob=oid))
    return dict(schema='fsmgen.release_final_join_plan.v1', owner=OWNER, source_revision=REVISION,
        component=BASE.name, inputs=inputs,
        joins=[str((BASE.parent / name).relative_to(ROOT)) for name in JOINS], scope=SCOPE)


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as stream:
        stream.write(json.dumps(plan, sort_keys=True, indent=2) + '\n')
    print(json.dumps(dict(success=True, inputs=len(plan['inputs']),
        input_bytes=sum(row['size_bytes'] for row in plan['inputs'])), sort_keys=True))
