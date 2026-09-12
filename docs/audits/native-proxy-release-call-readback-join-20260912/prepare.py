"""Pin the complete retained safe-call, readback and syscall evidence closure."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'accc2c3f32a57365450ba57546485aca784f6820'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.3.11'
READBACK = ['native-proxy-observation-archive-release-readback-' + profile + date
            for profile, date in [('ordinary', '-20260911'), ('equal', '-20260912'),
                                  ('active', '-20260912'), ('last', '-20260912')]]
SYSCALL = 'native-proxy-observation-archive-release-syscall-20260912'
SELECTION = 'native-proxy-release-readback-selection-20260911'
APPLICABILITY = 'native-proxy-release-readback-applicability-20260911'
BINDING = 'native-proxy-release-readback-ordinary-20260911'
CALL_SELECTION = 'native-proxy-release-call-selection-20260911'
CALLS = ['native-proxy-observation-archive-release-' + profile + '-' + phase + '-20260911'
         for profile in ('ordinary', 'equal', 'active', 'last') for phase in ('before', 'after')]
JOIN = 'native-proxy-release-readback-join-20260912'
DIRECTORIES = [CALL_SELECTION, *CALLS, SELECTION, APPLICABILITY, BINDING, *READBACK, SYSCALL, JOIN]



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
    for directory in DIRECTORIES:
        prefix = 'docs/audits/' + directory + '/'
        paths.update(name for name in version if name.startswith(prefix))
    for directory in [CALL_SELECTION, *CALLS, SELECTION, APPLICABILITY, *READBACK, SYSCALL, JOIN]:
        source = BASE.parent / directory / ('applicability.json' if directory == APPLICABILITY else 'plan.json')
        paths.update(row['path'] for row in load(source)['inputs'])
    return sorted(paths)


def build():
    assert load(BASE / 'prepare-pins.json') == [pin(BASE / 'prepare.py')]
    version = tree()
    inputs = []
    for relative in input_paths(version):
        info = version[relative]
        assert info['kind'] == 'blob' and info['mode'] in ('100644', '100755')
        path = ROOT / relative
        raw = safe_bytes(path)
        # Git's object identity authenticates the bytes at the exact revision;
        # SHA-256 also pins their complete raw representation for this join.
        oid = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
        assert oid == info['oid'], relative
        inputs.append(dict(path=relative, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest(), git_blob=oid))
    partitions = []
    for directory in [*CALLS, *READBACK, SYSCALL]:
        path = BASE.parent / directory
        plan = load(path / 'plan.json')
        partitions.append(dict(directory=str(path.relative_to(ROOT)),
            domain='call' if directory in CALLS else 'syscall' if directory == SYSCALL else 'readback',
            audit='audit-corrected.py' if directory in (READBACK[0], SYSCALL) else 'audit.py',
            owner=plan['owner']))
    return dict(schema='fsmgen.release_call_readback_join_plan.v1', owner=OWNER, source_revision=REVISION,
        component=BASE.name, partitions=partitions, inputs=inputs,
        scope='Revalidate retained selected safe-call, release-readback and syscall-report cases. '
              'Primary coverage and the strong-observer counterexample are disjoint. '
              'No fixture, old main, original producer, native process or new test root. '
              'Close-error/omission composition, complete release applicability and native lifetime remain separate.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as output:
        output.write(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(inputs=len(plan['inputs']), input_bytes=sum(r['size_bytes'] for r in plan['inputs']),
                         partitions=len(plan['partitions'])), sort_keys=True))
