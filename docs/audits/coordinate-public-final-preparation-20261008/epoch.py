"""Stream exact committed sources into a plain same-volume filesystem fixture."""
import hashlib
import os
import posixpath
import shutil
import subprocess
import tarfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).parent
REVISION = 'a2840582fc1722c29da808713d6f3c06bd42cd78'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def git(*args, input=None, environment=None):
    result = subprocess.run(['git', '--no-replace-objects', '-C', str(ROOT), *args],
                            input=input, env=environment, capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'complete successful native Git result')
    return result.stdout


def scope(names):
    need(type(names) in (list, tuple) and names and len(names) == len(set(names)),
         'explicit nonempty unique recovery scope')
    for name in names:
        safe_path(name)
    return sorted(names)


def metadata(names):
    names = scope(names)
    raw = git('--literal-pathspecs', 'ls-tree', '-r', '--full-tree', '-z', REVISION, '--', *names)
    need(raw.endswith(b'\0'), 'complete native source framing')
    rows = {}
    for record in raw.split(b'\0')[:-1]:
        header, name = record.split(b'\t', 1)
        mode, kind, oid = header.decode().split(' ')
        path = name.decode()
        need(kind == 'blob' and mode in ('100644', '100755', '120000'),
             'only declared project blobs; no gitlink implementation recovery')
        safe_path(path)
        need(path not in rows, 'unique native source path')
        rows[path] = {'mode': mode, 'oid': oid}
    need(rows and all(any(path == name or path.startswith(name + '/') for name in names)
                     for path in rows), 'exact declared recovery namespaces')
    need(all(any(path == name or path.startswith(name + '/') for path in rows)
             for name in names), 'every declared recovery namespace exists')
    return raw, rows


def safe_path(path):
    parts = PurePosixPath(path).parts
    need(path and parts and '\0' not in path and not path.startswith('/') and str(PurePosixPath(path)) == path
         and all(part not in ('.', '..', '.git') for part in parts), 'contained canonical source path')


def alias_target(path, target):
    need(target and not target.startswith('/'), 'contained relative source alias')
    normalized = posixpath.normpath(posixpath.join(posixpath.dirname(path), target))
    safe_path(normalized)
    return normalized


def restore(member, stream, root, expected):
    safe_path(member.name)
    row = expected.get(member.name)
    need(row is not None, 'archive source membership')
    target = root / member.name
    target.parent.mkdir(parents=True, exist_ok=True)
    for parent in target.parents:
        if parent == root:
            break
        need(not parent.is_symlink() and parent.stat().st_dev == ROOT.stat().st_dev,
             'plain same-volume source parent')
    need(not target.exists() and not target.is_symlink(), 'unique recovered source endpoint')
    if member.issym():
        need(row['mode'] == '120000', 'source alias mode')
        alias_target(member.name, member.linkname)
        raw = member.linkname.encode()
        oid = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
        need(oid == row['oid'], 'whole source blob identity')
        target.symlink_to(member.linkname)
    else:
        need(member.isfile() and row['mode'] in ('100644', '100755'), 'regular source mode')
        digest = hashlib.sha1(b'blob ' + str(member.size).encode() + b'\0')
        count = 0
        with target.open('xb') as output:
            while block := stream.read(1_048_576):
                output.write(block)
                digest.update(block)
                count += len(block)
        need(count == member.size and digest.hexdigest() == row['oid'], 'whole source blob identity')
        target.chmod(0o755 if row['mode'] == '100755' else 0o644)


def recover(root, rows, names):
    need(root.is_dir() and not root.is_symlink() and root.stat().st_dev == ROOT.stat().st_dev
         and root == root.resolve() and root.is_relative_to(ROOT / '.artifacts') and not list(root.iterdir()),
         'empty plain owned same-volume fixture root')
    names = scope(names)
    selected = dict(rows)
    need(selected and all(any(path == name or path.startswith(name + '/') for name in names)
                         for path in selected), 'exact declared recovery namespaces')
    for path, row in selected.items():
        safe_path(path)
        need(row['mode'] in ('100644', '100755', '120000'), 'declared recovery source kind')
    command = ['git', '--no-replace-objects', '--literal-pathspecs', '-C', str(ROOT),
               'archive', '--format=tar', REVISION, '--', *names]
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    observed = set()
    try:
        with tarfile.open(fileobj=process.stdout, mode='r|') as archive:
            for member in archive:
                if member.isdir():
                    safe_path(member.name.rstrip('/'))
                    continue
                need(member.name not in observed, 'unique archive source member')
                restore(member, archive.extractfile(member) if member.isfile() else None, root, selected)
                observed.add(member.name)
        error = process.stderr.read()
        need(process.wait() == 0 and not error, 'complete successful source archive')
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
        process.stdout.close()
        process.stderr.close()
    need(observed == set(selected), 'complete recovered source population')
    for path, row in selected.items():
        if row['mode'] == '120000':
            endpoint = alias_target(path, os.readlink(root / path))
            need(endpoint in selected and selected[endpoint]['mode'] in ('100644', '100755'),
                 'source alias joins an owned regular canonical source')
    return selected


def environment(root):
    need(root.is_dir() and root == root.resolve() and root.is_relative_to(ROOT / '.artifacts')
         and root.stat().st_dev == ROOT.stat().st_dev, 'plain owned same-volume Git fixture root')
    directory = root / '.artifacts'
    need(not directory.exists() and not directory.is_symlink(), 'fresh plain fixture metadata directory')
    directory.mkdir()
    index = directory / 'epoch.index'
    metadata_root = git('rev-parse', '--absolute-git-dir').decode().strip()
    env = dict(os.environ, GIT_DIR=metadata_root, GIT_WORK_TREE=str(root),
               GIT_INDEX_FILE=str(index), GIT_OPTIONAL_LOCKS='0', GIT_NO_LAZY_FETCH='1',
               PYTHONDONTWRITEBYTECODE='1')
    # This writes only the explicitly owned alternative index. Original refs,
    # configuration, objects and the primary index remain read-only.
    git('read-tree', REVISION, environment=env)
    binary = shutil.which('git')
    need(binary is not None, 'installed Git executable')
    wrapper = directory / 'readonly-bin'
    wrapper.mkdir()
    shutil.copyfile(BASE / 'git_readonly.py', wrapper / 'git')
    (wrapper / 'git').chmod(0o755)
    env.update(FSMGEN_EPOCH_ROOT=str(root), FSMGEN_EPOCH_GIT_BINARY=binary,
               PATH=str(wrapper) + os.pathsep + env['PATH'])
    return env
