"""Qualify a complete dated checkout; never execute a semantic reader here."""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess

import execute
import prepare

REVISION = '1a40a1da89216f4761ef73e67cefb029c78e8f94'
FOLDER = Path('.artifacts/original-join-historical-checkout-20261018')
MANIFEST = execute.AUDIT / 'historical-checkout-manifest.json.gz'
RESULT = execute.AUDIT / 'historical-checkout-prepared.json.gz'
MAX_BYTES = 16 * 1024 ** 3
MAX_FILES = 65536


def manifest():
    raw = execute.command(['git', '--no-replace-objects', 'ls-tree', '-r', '-l', '-z', REVISION])
    members = {}
    for entry in raw.split(b'\0'):
        if not entry:
            continue
        header, encoded = entry.split(b'\t', 1)
        mode, kind, oid, size = header.decode().split()
        name = encoded.decode()
        path = Path(name)
        assert not path.is_absolute() and '..' not in path.parts and '.git' not in path.parts
        assert str(path) == name and name not in members
        assert kind == 'blob' and mode in ('100644', '100755', '120000'), 'no Gitlink implementation is admitted'
        members[name] = dict(mode=mode, oid=oid, bytes=int(size))
    assert len(members) <= MAX_FILES and sum(row['bytes'] for row in members.values()) <= MAX_BYTES
    parent = execute.command(['git', '--no-replace-objects', 'rev-parse',
                              'a0561d999b0354ed261289f66657bf8704c75ec9^']).decode().strip()
    assert parent == REVISION, 'exact epoch immediately before legitimate publication'
    return dict(schema='fsmgen.original_historical_checkout.v1', revision=REVISION,
                folder=str(FOLDER), tree=prepare.blob(raw), members=members,
                scope='Complete dated source/runtime checkout for historical saved readers only. '
                      'Original guards and disk bytes are unmodified. Current publication remains in the primary checkout; '
                      'no semantic replay, original producer, native/private or independent qualification is implied.')


def inspect(root, members, metadata=frozenset()):
    """Independently census all physical members, modes, content and directories."""
    root = Path(root)
    assert root.is_dir() and not root.is_symlink() and root.stat().st_dev == execute.ROOT.stat().st_dev
    names, directories, actual = set(), set(), {}
    expected_directories = {str(parent) for name in members for parent in Path(name).parents if str(parent) != '.'}
    for folder, dirs, files in os.walk(root, followlinks=False):
        parent = Path(folder)
        assert parent.stat().st_dev == root.stat().st_dev
        for child in dirs[:]:
            path = parent / child
            name = str(path.relative_to(root))
            if path.is_symlink():
                dirs.remove(child)
                files.append(child)
            else:
                assert path.stat().st_dev == root.stat().st_dev
                assert name in expected_directories, 'unexpected directory boundary'
                assert not (path / '.git').exists() and not (path / '.git').is_symlink(), 'no nested repository traversal'
                directories.add(name)
        for child in files:
            path = parent / child
            name = str(path.relative_to(root))
            if name in metadata:
                assert stat.S_ISREG(path.lstat().st_mode) and path.stat().st_dev == root.stat().st_dev
                continue
            assert name in members and name not in names, 'unexpected historical member: ' + name
            names.add(name)
            wanted = members[name]
            before = path.lstat()
            assert before.st_dev == root.stat().st_dev
            if wanted['mode'] == '120000':
                assert stat.S_ISLNK(before.st_mode)
                body = os.fsencode(os.readlink(path))
                target = os.fsdecode(body)
                assert not Path(target).is_absolute()
                endpoint = os.path.normpath(str(Path(name).parent / target))
                assert endpoint in members and members[endpoint]['mode'] in ('100644', '100755'), 'own regular relative source endpoint'
                size = len(body)
                sha1 = hashlib.sha1(b'blob ' + str(size).encode() + b'\0' + body).hexdigest()
                sha256 = hashlib.sha256(body).hexdigest()
            else:
                assert stat.S_ISREG(before.st_mode) and bool(before.st_mode & 0o111) == (wanted['mode'] == '100755')
                size = before.st_size
                one, two = hashlib.sha1(b'blob ' + str(size).encode() + b'\0'), hashlib.sha256()
                with path.open('rb') as stream:
                    assert (os.fstat(stream.fileno()).st_dev, os.fstat(stream.fileno()).st_ino) == (before.st_dev, before.st_ino)
                    while block := stream.read(1024 * 1024):
                        one.update(block)
                        two.update(block)
                sha1, sha256 = one.hexdigest(), two.hexdigest()
            after = path.lstat()
            assert (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns, before.st_mode) == (
                after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns, after.st_mode), 'source conservation during read'
            assert size == wanted['bytes'] and sha1 == wanted['oid'], 'whole historical file identity: ' + name
            actual[name] = dict(wanted, sha256=sha256)
    assert names == members.keys() and directories == expected_directories, 'complete historical file/directory membership'
    return actual


def git_state():
    prefix = ['git', '--no-replace-objects', '-C', str(FOLDER)]
    revision = execute.command([*prefix, 'rev-parse', 'HEAD']).decode().strip()
    common = execute.command([*prefix, 'rev-parse', '--path-format=relative', '--git-common-dir']).decode().strip()
    assert revision == REVISION and not Path(common).is_absolute()
    assert (execute.ROOT / FOLDER / common).resolve(strict=True) == execute.ROOT / '.git', 'same project Git repository'
    pointer = (execute.ROOT / FOLDER / '.git').read_text()
    assert pointer.startswith('gitdir: ') and not Path(pointer[8:].strip()).is_absolute(), 'relocatable linked checkout'
    git_directory = (execute.ROOT / FOLDER / pointer[8:].strip()).resolve(strict=True)
    assert git_directory.is_relative_to(execute.ROOT / '.git/worktrees')
    backlink = (git_directory / 'gitdir').read_text().strip()
    assert not Path(backlink).is_absolute() and (git_directory / backlink).resolve(strict=True) == execute.ROOT / FOLDER / '.git'
    entries = execute.command([*prefix, 'ls-files', '--stage', '-z'])
    return dict(revision=revision, common_directory=common, pointer=pointer, entries=prepare.blob(entries))


def verify():
    image = json.loads(gzip.decompress(execute.read(MANIFEST)))
    assert image == manifest()
    assert all(type(row['bytes']) is int and row['bytes'] >= 0 for row in image['members'].values())
    state = git_state()
    indexed = {}
    for entry in prepare.unblob(state['entries']).split(b'\0'):
        if not entry:
            continue
        header, name = entry.split(b'\t', 1)
        mode, oid, stage = header.decode().split()
        assert stage == '0' and name.decode() not in indexed
        indexed[name.decode()] = (mode, oid)
    assert indexed == {name: (row['mode'], row['oid']) for name, row in image['members'].items()}
    actual = inspect(execute.ROOT / FOLDER, image['members'], {'.git'})
    return dict(git=state, members=actual)


def create():
    image = manifest()
    assert not execute.safe(FOLDER).exists()
    assert os.statvfs(execute.ROOT).f_bavail * os.statvfs(execute.ROOT).f_frsize > MAX_BYTES * 2
    execute.save(MANIFEST, image)
    before = execute.git_state()
    command = ['git', '--no-replace-objects', 'worktree', 'add', '--detach', '--relative-paths',
               '--lock', '--reason', 'Owned historical saved-reader source fixture', str(FOLDER), REVISION]
    execute.save(execute.AUDIT / 'historical-checkout-started.json.gz', dict(command=command, primary_before=before))
    native = subprocess.run(command, cwd=execute.ROOT, capture_output=True)
    outcome = dict(command=command, status=native.returncode, stdout=prepare.blob(native.stdout),
                   stderr=prepare.blob(native.stderr), primary_before=before, primary_after=execute.git_state())
    # Preserve checkout failure before qualification, without deleting partial evidence.
    execute.save(execute.AUDIT / 'historical-checkout-native.json.gz', outcome)
    assert type(native.returncode) is int and native.returncode == 0
    assert outcome['primary_after']['head'] == before['head'] and outcome['primary_after']['entries'] == before['entries']
    actual = verify()
    execute.save(RESULT, actual)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare', action='store_true')
    args = parser.parse_args()
    if args.prepare:
        create()
    else:
        assert verify() == json.loads(gzip.decompress(execute.read(RESULT)))
    print('Complete dated Git/runtime checkout and independent whole physical source/mode/member/index qualification pass; no semantic reader executes.')
