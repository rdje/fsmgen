"""Prepare and verify the selected whole source image, including its output dirs."""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile

import epoch_constraints as constraints
import execute
import prepare

SELECTION_COMMIT = '38af0291b23cafd4ce41f4a82e37b99a373cf916'
FOLDER = Path('.artifacts/original-join-selected-checkout-20261018')
MANIFEST = execute.AUDIT / 'selected-checkout-manifest.json.gz'
RESULT = execute.AUDIT / 'selected-checkout-prepared.json.gz'
REASON = 'Owned conjunctively selected historical saved-reader source fixture'
MAX_BYTES = 16 * 1024 ** 3
MAX_FILES = 65536


def selection():
    raw = execute.read(constraints.PATH)
    assert raw == constraints.read(SELECTION_COMMIT, str(constraints.PATH))
    instrument = str(execute.AUDIT / 'epoch_constraints.py')
    assert execute.read(instrument) == constraints.read(SELECTION_COMMIT, instrument)
    value = json.loads(gzip.decompress(raw))
    assert value['revision'] == constraints.REVISION
    return value


def manifest():
    selected = selection()
    raw, members = constraints.tree(selected['revision'])
    assert raw == prepare.unblob(selected['tree'])
    assert len(members) <= MAX_FILES and sum(row['bytes'] for row in members.values()) <= MAX_BYTES
    assert all(members[name] == row for name, row in selected['required_members'].items())
    return dict(schema='fsmgen.selected_historical_checkout.v1', revision=selected['revision'],
                folder=str(FOLDER), members=members, tree=prepare.blob(raw),
                selection=prepare.identity(execute.read(constraints.PATH)),
                runtime_directories=selected['locality']['directories'], runtime_files=[],
                scope='Complete selected historical physical source only. Predeclared empty locality '
                      'directories are output namespaces, never source members. Current publication stays '
                      'primary; no semantic reader, producer or failed/unused intake runs.')


def inspect(root, members, runtime=(), metadata=frozenset()):
    """Census actual files, directories, modes and bytes without Git's index cache."""
    root = Path(root)
    assert root.is_dir() and not root.is_symlink()
    device = root.stat().st_dev
    assert device == execute.ROOT.stat().st_dev
    expected_directories = {str(parent) for name in members for parent in Path(name).parents if str(parent) != '.'}
    assert not (expected_directories & set(runtime)), 'runtime and source directories have distinct roles'
    expected_directories.update(runtime)
    names, directories, actual = set(), set(), {}
    for folder, dirs, files in os.walk(root, followlinks=False):
        parent = Path(folder)
        assert parent.stat().st_dev == device
        for child in dirs[:]:
            path = parent / child
            name = str(path.relative_to(root))
            if path.is_symlink():
                dirs.remove(child)
                files.append(child)
            else:
                assert path.stat().st_dev == device and name in expected_directories, 'unexpected directory'
                assert not (path / '.git').exists() and not (path / '.git').is_symlink()
                directories.add(name)
        for child in files:
            path = parent / child
            name = str(path.relative_to(root))
            before = path.lstat()
            assert before.st_dev == device
            if name in metadata:
                assert stat.S_ISREG(before.st_mode)
                continue
            assert name in members and name not in names, 'unexpected source/runtime file: ' + name
            names.add(name)
            wanted = members[name]
            if wanted['mode'] == '120000':
                assert stat.S_ISLNK(before.st_mode)
                body = os.fsencode(os.readlink(path))
                target = os.fsdecode(body)
                assert not Path(target).is_absolute()
                endpoint = os.path.normpath(str(Path(name).parent / target))
                assert endpoint in members and members[endpoint]['mode'] in ('100644', '100755')
                size = len(body)
                one = hashlib.sha1(b'blob ' + str(size).encode() + b'\0' + body).hexdigest()
                two = hashlib.sha256(body).hexdigest()
            else:
                assert stat.S_ISREG(before.st_mode)
                assert bool(before.st_mode & 0o111) == (wanted['mode'] == '100755'), 'source mode'
                size = before.st_size
                sha1 = hashlib.sha1(b'blob ' + str(size).encode() + b'\0')
                sha256 = hashlib.sha256()
                with path.open('rb') as stream:
                    opened = os.fstat(stream.fileno())
                    assert (opened.st_dev, opened.st_ino) == (before.st_dev, before.st_ino)
                    while block := stream.read(1024 * 1024):
                        sha1.update(block)
                        sha256.update(block)
                one, two = sha1.hexdigest(), sha256.hexdigest()
            after = path.lstat()
            fields = ('st_dev', 'st_ino', 'st_size', 'st_mtime_ns', 'st_mode')
            assert all(getattr(before, key) == getattr(after, key) for key in fields), 'read conservation'
            assert size == wanted['bytes'] and one == wanted['oid'], 'whole source identity: ' + name
            actual[name] = dict(wanted, sha256=two)
    assert names == members.keys() and directories == expected_directories, 'whole source/directory membership'
    return actual


def git_state():
    prefix = ['git', '--no-replace-objects', '-C', str(FOLDER)]
    revision = execute.command([*prefix, 'rev-parse', 'HEAD']).decode().strip()
    assert revision == constraints.REVISION
    common = execute.command([*prefix, 'rev-parse', '--path-format=relative', '--git-common-dir']).decode().strip()
    assert not Path(common).is_absolute()
    assert (execute.ROOT / FOLDER / common).resolve(strict=True) == execute.ROOT / '.git'
    pointer = (execute.ROOT / FOLDER / '.git').read_text()
    assert pointer.startswith('gitdir: ') and not Path(pointer[8:].strip()).is_absolute()
    directory = (execute.ROOT / FOLDER / pointer[8:].strip()).resolve(strict=True)
    assert directory.is_relative_to(execute.ROOT / '.git/worktrees')
    backlink = (directory / 'gitdir').read_text().strip()
    assert not Path(backlink).is_absolute()
    assert (directory / backlink).resolve(strict=True) == execute.ROOT / FOLDER / '.git'
    assert (directory / 'locked').read_text().strip() == REASON
    return dict(revision=revision, common_directory=common, pointer=pointer, backlink=backlink,
                entries=prepare.blob(execute.command([*prefix, 'ls-files', '--stage', '-z'])),
                index=prepare.blob((directory / 'index').read_bytes()))


def verify():
    image = json.loads(gzip.decompress(execute.read(MANIFEST)))
    assert image == manifest()
    state = git_state()
    entries = {}
    for row in prepare.unblob(state['entries']).split(b'\0'):
        if not row:
            continue
        header, name = row.split(b'\t', 1)
        mode, oid, stage = header.decode().split()
        assert stage == '0' and name.decode() not in entries
        entries[name.decode()] = (mode, oid)
    assert entries == {name: (row['mode'], row['oid']) for name, row in image['members'].items()}
    actual = inspect(execute.ROOT / FOLDER, image['members'], image['runtime_directories'], {'.git'})
    assert git_state() == state, 'whole checkout index and metadata conserve during physical qualification'
    return dict(git=state, members=actual, runtime_directories=image['runtime_directories'], runtime_files=[])


def validate_index(value):
    """Ask Git to decode each retained index; its stat cache is not source truth."""
    index = value['git']['index']
    assert type(index['bytes']) is int and index['bytes'] > 0
    raw = prepare.unblob(index)
    expected = prepare.unblob(value['git']['entries'])
    with tempfile.TemporaryDirectory(prefix='selected-index-reader-', dir=execute.ROOT / '.artifacts/tmp') as folder:
        path = Path(folder) / 'index'
        path.write_bytes(raw)
        environment = dict(os.environ, GIT_INDEX_FILE=str(path))
        result = subprocess.run(['git', '--no-replace-objects', '-C', str(FOLDER), 'ls-files', '--stage', '-z'],
                                cwd=execute.ROOT, env=environment, capture_output=True)
        assert result.returncode == 0 and result.stderr == b'' and result.stdout == expected, 'public Git index/entry validation'


def matches_prepared(candidate, expected):
    # A fresh checkout has different inode/time cache bytes. Authenticate and
    # publicly decode both raw observations, then require exact logical entries,
    # physical sources, modes, links, namespaces and relative Git metadata.
    validate_index(candidate)
    validate_index(expected)
    comparable = []
    for value in (candidate, expected):
        comparable.append(dict(value, git={key: row for key, row in value['git'].items() if key != 'index'}))
    assert comparable[0] == comparable[1], 'whole portable physical/index source qualification'
    return True


def sources():
    names = ('selected_checkout.py', 'epoch_constraints.py', 'execute.py', 'prepare.py',
             'conjunctive-epoch-constraints-qualified.json.gz')
    return {str(execute.AUDIT / name): prepare.blob(execute.read(execute.AUDIT / name)) for name in names}


def create():
    image = manifest()
    assert not execute.safe(FOLDER).exists()
    filesystem = os.statvfs(execute.ROOT)
    assert filesystem.f_bavail * filesystem.f_frsize > MAX_BYTES * 2
    execute.save(MANIFEST, image)
    before, instruments, tools = execute.git_state(), sources(), execute.tools()
    command = ['git', '--no-replace-objects', 'worktree', 'add', '--detach', '--relative-paths', '--lock',
               '--reason', REASON, str(FOLDER), constraints.REVISION]
    started = dict(command=command, primary_before=before, source_before=instruments, tools_before=tools,
                   runtime_directories=image['runtime_directories'], runtime_files=[])
    execute.save(execute.AUDIT / 'selected-checkout-started.json.gz', started)
    native = subprocess.run(command, cwd=execute.ROOT, capture_output=True)
    actual = dict(started, status=native.returncode, stdout=prepare.blob(native.stdout),
                  stderr=prepare.blob(native.stderr), primary_after=execute.observe(execute.git_state),
                  source_after=execute.observe(sources), tools_after=execute.observe(execute.tools))
    execute.save(execute.AUDIT / 'selected-checkout-native.json.gz', actual)
    assert type(native.returncode) is int and native.returncode == 0
    assert actual['primary_after']['error'] is None
    assert all(actual['primary_after']['value'][key] == before[key] for key in ('head', 'entries'))
    assert actual['source_after'] == dict(value=instruments, error=None)
    assert actual['tools_after'] == dict(value=tools, error=None)
    # Admit these exact output namespaces before any physical before/after
    # observation. They contain no added runtime files and are never ignored.
    for name in image['runtime_directories']:
        (execute.ROOT / FOLDER / name).mkdir(exist_ok=False)
    execute.save(RESULT, verify())


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare', action='store_true')
    args = parser.parse_args()
    if args.prepare:
        create()
    else:
        assert matches_prepared(verify(), json.loads(gzip.decompress(execute.read(RESULT))))
    print('Complete selected checkout physical source/member/mode/link/index custody passes with declared empty locality directories; no semantic reader executes.')
