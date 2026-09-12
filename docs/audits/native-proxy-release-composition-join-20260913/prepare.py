"""Pin all retained bounded release-composition profiles at one Git revision."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '5361f8818cbbaf247fd5a34aa0884624257fce11'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.4.6.6'
SELECTION = 'native-proxy-release-close-composition-selection-20260912'
PROFILES = ['native-proxy-observation-archive-release-composition-' + name + '-20260912'
            for name in ('ordinary', 'equal', 'active', 'last')]
DIRECTORIES = [SELECTION, *PROFILES]


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
        paths.update(record['path'] for record in load(directory / 'plan.json')['inputs'])
    return sorted(paths)


def build():
    assert load(BASE / 'prepare-pins.json') == [pin(BASE / 'prepare.py')]
    version = tree(REVISION)
    inputs = []
    for relative in input_paths(version):
        info = version[relative]
        assert info['kind'] == 'blob' and info['mode'] in ('100644', '100755')
        raw = safe_bytes(ROOT / relative)
        # Verify Git's exact version object independently of the SHA-256 receipt.
        oid = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
        assert oid == info['oid'], relative
        inputs.append(dict(path=relative, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest(), git_blob=oid))
    partitions = []
    for name in PROFILES:
        directory = BASE.parent / name
        current = load(directory / 'plan.json')
        partitions.append(dict(directory=str(directory.relative_to(ROOT)),
            profile_id=current['profile_id'], owner=current['owner'], source_revision=current['source_revision']))
    return dict(schema='fsmgen.release_composition_join_plan.v1', owner=OWNER,
        source_revision=REVISION, component=BASE.name, inputs=inputs, partitions=partitions,
        scope='Join the complete selected bounded composition domain from original retained rows. '
              'Revalidate source epochs, physical closure, primary precedence, declaration reversal, '
              'profile state and recovery without fixture replay, old main calls or native execution. '
              'This is finite representative coverage, not all Cartesian error combinations. '
              'Single-report join, genuine omissions, final release, native/lifetime and historical '
              'startup/parent/full CI/push remain separate.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as stream:
        stream.write(json.dumps(plan, sort_keys=True, indent=2) + '\n')
    print(json.dumps(dict(success=True, inputs=len(plan['inputs']),
        input_bytes=sum(r['size_bytes'] for r in plan['inputs']), partitions=len(plan['partitions'])), sort_keys=True))
