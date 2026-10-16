"""Remove one fixed, completely authenticated duplicate generated book render."""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import base64
import gzip
import hashlib
import json
import os
import shutil
import stat
import subprocess

BASE = Path('docs/audits/artifact-cleanup-20261016')
TARGET = '.artifacts/specforge-feature-intake-20260926/book-final'
PEER = '.artifacts/specforge-feature-intake-20260926/book-verified'
CURRENT = '.artifacts/ghdl-test-policy-20261012/book'
ROOT = Path(__file__).resolve().parents[3]
INSPECTION = 'inspection-repaired.json.gz'


def save(name, value):
    with (BASE / name).open('xb') as stream:
        stream.write(gzip.compress(json.dumps(value, sort_keys=True).encode(), mtime=0))


def load(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def command(argv, statuses=(0,)):
    result = subprocess.run(argv, capture_output=True, timeout=30,
                            env=dict(os.environ, GIT_OPTIONAL_LOCKS='0'))
    assert result.returncode in statuses, (argv, result.returncode, result.stderr[:1000])
    return dict(argv=argv, status=result.returncode,
                stdout_base64=base64.b64encode(result.stdout).decode(),
                stderr_base64=base64.b64encode(result.stderr).decode())


def digest(body):
    return hashlib.sha256(body).hexdigest()


def metadata(path):
    info = path.lstat()
    assert info.st_dev == ROOT.stat().st_dev
    assert stat.S_ISREG(info.st_mode) or stat.S_ISDIR(info.st_mode)
    if stat.S_ISREG(info.st_mode):
        assert info.st_nlink == 1
    return dict(device=info.st_dev, inode=info.st_ino, mode=info.st_mode,
                nlink=info.st_nlink, size=info.st_size, mtime_ns=info.st_mtime_ns)


def foreign(path):
    return (path / '.git').exists() or (path / '.git').is_symlink() or (
        (path / 'HEAD').exists() and any((path / name).exists()
                                      for name in ['objects', 'refs', 'packed-refs']))


def tree(relative):
    assert relative in (TARGET, PEER, CURRENT)
    directory = ROOT / relative
    assert directory.is_dir()
    for parent in [directory, *directory.parents]:
        if parent == ROOT:
            break
        metadata(parent)
        assert not foreign(parent), 'nested Git boundary'
    nodes, files = {}, {}
    for folder, children, names in os.walk(directory, followlinks=False):
        parent = Path(folder)
        assert not foreign(parent), 'nested Git boundary'
        for path in [parent, *[parent / name for name in [*children, *names]]]:
            key = path.relative_to(ROOT).as_posix()
            before = metadata(path)
            if stat.S_ISREG(before['mode']):
                body = path.read_bytes()
                assert metadata(path) == before
                files[path.relative_to(directory).as_posix()] = dict(bytes=len(body), sha256=digest(body))
            nodes[key] = before
        assert len(nodes) <= 4096
    assert len(files) <= 2048 and sum(x['bytes'] for x in files.values()) <= 128 * 1024 * 1024
    indexed = command(['git', 'ls-files', '-z', '--', relative])
    assert not base64.b64decode(indexed['stdout_base64']), 'tracked cleanup member'
    independent = command(['rg', '--files', '--hidden', '--no-ignore', relative])
    observed = base64.b64decode(independent['stdout_base64']).decode().splitlines()
    assert sorted(observed) == sorted(relative + '/' + name for name in files)
    assert 'index.html' in files and any(name.startswith('book-') and name.endswith('.js') for name in files)
    assert not any(name.endswith(('.log', '.bin')) for name in files)
    return dict(path=relative, files=files, nodes=nodes, independent=independent,
                tracked_check=indexed, bytes_total=sum(x['bytes'] for x in files.values()))


def census_evidence():
    """Retain native log/bin identities; skip foreign repositories entirely."""
    records, skipped = {}, []
    roots = ['.artifacts', 'target/release', 'target/debug/incremental', 'target/debug/deps',
             'rust/target/release', 'rust/target/debug/incremental', 'rust/target/debug/deps']
    states = {}
    for relative in roots:
        start = ROOT / relative
        if not start.exists():
            states[relative] = 'absent'
            continue
        assert not start.is_symlink() and start.is_dir()
        metadata(start)
        states[relative] = 'censused'
        for folder, children, names in os.walk(start, followlinks=False):
            parent = Path(folder)
            if foreign(parent):
                skipped.append(parent.relative_to(ROOT).as_posix())
                children[:] = []
                continue
            children[:] = [name for name in children if not (parent / name).is_symlink()]
            for name in names:
                path = parent / name
                if path.suffix not in ('.log', '.bin') or path.is_symlink():
                    continue
                before = metadata(path)
                assert stat.S_ISREG(before['mode'])
                body = path.read_bytes()
                assert metadata(path) == before
                records[path.relative_to(ROOT).as_posix()] = dict(**before, sha256=digest(body))
    return dict(roots=states, retained=records, skipped_foreign=sorted(set(skipped)))


def protected():
    return dict(peer=tree(PEER), current=tree(CURRENT),
                evidence=census_evidence(),
                primary_git={name: digest((ROOT / '.git' / name).read_bytes())
                             for name in ['HEAD', 'index', 'config']},
                source_diff=command(['git', 'diff', '--raw', '-z']))


def tree_identity(observation):
    """File enumeration order is observation data, not a member identity."""
    result = {name: observation[name] for name in ['path', 'files', 'nodes', 'bytes_total']}
    independent = observation['independent']
    indexed = observation['tracked_check']
    assert independent['status'] == indexed['status'] == 0
    assert not base64.b64decode(indexed['stdout_base64'])
    result['independent_membership'] = sorted(
        base64.b64decode(independent['stdout_base64']).decode().splitlines())
    result['independent_stderr'] = independent['stderr_base64']
    result['tracked_check'] = indexed
    return result


def protected_identity(observation):
    return dict(observation, peer=tree_identity(observation['peer']),
                current=tree_identity(observation['current']))


def verify(args):
    result = load('result.json.gz')
    inspected = load(INSPECTION)
    removed = dict(result['removed']['files'])
    if args.omit_member:
        removed.pop(next(iter(removed)))
    if args.alter_byte:
        name = next(iter(removed))
        removed[name] = dict(removed[name], sha256='0' * 64)
    assert result['owner'] == 'ARTIFACT-CLEANUP-20261016.1'
    assert result['removed'] == inspected['candidate']
    assert removed == inspected['peer']['files'], 'complete duplicate membership/bytes'
    assert sum(x['bytes'] for x in removed.values()) == result['removed']['bytes_total']
    assert result['residue'] is False and result['peer_exists'] and result['current_exists']
    if args.alter_protection:
        result['after']['primary_git']['index'] = '0' * 64
    assert protected_identity(result['before']) == protected_identity(result['after']), 'protected render/evidence/source/Git conservation'
    previous = datetime.fromisoformat(result['previous_record'].splitlines()[2].split(' — ', 1)[0])
    assert (datetime.fromisoformat(result['utc']) - previous).total_seconds() > 86400
    assert result['shutil_rmtree_avoids_symlink_attacks']
    print('PASS saved dated cleanup: complete duplicate bytes, residue and protected identities; no deletion repeated')


def main():
    assert Path.cwd().resolve() == ROOT, 'run from the repository root'
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['inspect', 'apply', 'verify'])
    parser.add_argument('--omit-member', action='store_true')
    parser.add_argument('--alter-byte', action='store_true')
    parser.add_argument('--alter-protection', action='store_true')
    args = parser.parse_args()
    assert not any([args.omit_member, args.alter_byte, args.alter_protection]) or args.action == 'verify'
    if args.action == 'verify':
        verify(args)
        return
    if args.action == 'inspect':
        candidate, peer = tree(TARGET), tree(PEER)
        assert candidate['files'] == peer['files'], 'not a complete byte-identical duplicate'
        save(INSPECTION, dict(owner='ARTIFACT-CLEANUP-20261016.1',
             candidate=candidate, peer=peer, programme=Path(__file__).read_text()))
        print('PASS fixed duplicate inspection:', len(candidate['files']), 'members,', candidate['bytes_total'], 'bytes')
        return
    inspected = load(INSPECTION)
    assert inspected['programme'] == Path(__file__).read_text()
    assert tree_identity(tree(TARGET)) == tree_identity(inspected['candidate'])
    assert tree_identity(tree(PEER)) == tree_identity(inspected['peer'])
    previous = Path('docs/ARTIFACT_CLEANUP.md').read_text()
    previous_date = datetime.fromisoformat(previous.splitlines()[2].split(' — ', 1)[0])
    now = datetime.now(timezone.utc)
    assert (now - previous_date).total_seconds() > 86400
    assert shutil.rmtree.avoids_symlink_attacks, 'require symlink-safe native removal'
    before = protected()
    # All exact candidate/peer identities must still match immediately before removal.
    candidate, peer = tree(TARGET), tree(PEER)
    assert tree_identity(candidate) == tree_identity(inspected['candidate'])
    assert tree_identity(peer) == tree_identity(inspected['peer'])
    save('pre-removal.json.gz', dict(before=before, candidate=candidate, peer=peer,
         utc=datetime.now(timezone.utc).isoformat(),
         comparison='Exact nodes/bytes/native status and sorted complete rg membership; raw observations retain'))
    shutil.rmtree(ROOT / TARGET)
    residue = os.path.lexists(ROOT / TARGET)
    assert not residue
    after = protected()
    assert protected_identity(before) == protected_identity(after), 'protected native/source/Git data changed'
    result = dict(owner='ARTIFACT-CLEANUP-20261016.1', utc=now.isoformat(),
                  previous_record=previous, removed=inspected['candidate'], residue=residue,
                  peer_exists=(ROOT / PEER).is_dir(), current_exists=(ROOT / CURRENT).is_dir(),
                  before=before, after=after, shutil_rmtree_avoids_symlink_attacks=True,
                  scope='Only the fixed redundant historical generated render. All peer/current '
                        'bytes and censused log/bin identities conserve; foreign Git trees are skipped. '
                        'This is dated removal evidence; later legitimate builds may recreate the path.')
    save('result.json.gz', result)
    Path('docs/ARTIFACT_CLEANUP.md').write_text('# Latest artifact cleanup\n\n' + now.isoformat() +
        ' — Removed one authenticated byte-identical redundant historical book render; retained its complete peer, the current book and original native/compiler evidence. Rust log/bin paths censused.\n')
    print('PASS exact duplicate removed; residue absent; retained/current/native/source/Git identities conserve')


if __name__ == '__main__':
    main()
