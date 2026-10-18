"""Dispose only fixed regular cache-test copies with complete committed authority."""
import argparse
from datetime import datetime, timezone
import gzip
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys

sys.path.insert(0, 'docs/audits/original-join-parent-acceptance-20261018')
import execute
import prepare
import runtime_cache_producer as producer

BASE = Path('docs/audits/artifact-cleanup-daily-20261019')
RESULT = BASE / 'result.json.gz'
REVISION = 'f36dedf0932a82f95a8b41e69a4657ccb9e6e5bd'
AUTHORITY = 'b919b7f8ec74627ecb83fb80cb9d8b2f74c7f45d'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.86'
LABELS = tuple(label for label in producer.LABELS if label != 'symlink')
TARGETS = tuple(str(producer.ROOT / label) for label in LABELS)


def canonical(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), allow_nan=False) + '\n').encode()


def exact(left, right):
    return canonical(left) == canonical(right)


def git_file(revision, path):
    return execute.command(['git', '--no-replace-objects', 'show', revision + ':' + str(path)])


def identity(node):
    return [node.st_dev, node.st_ino, node.st_mode, node.st_nlink, node.st_uid,
            node.st_size, node.st_mtime_ns, node.st_ctime_ns]


def snapshot(relative):
    assert relative in TARGETS or relative == str(producer.ROOT / 'symlink')
    folder = execute.safe(relative)
    assert folder.is_dir() and not folder.is_symlink()
    files, directories, identities = {}, [], {}
    for directory, children, names in os.walk(folder, followlinks=False):
        parent = Path(directory)
        assert '.git' not in children and '.git' not in names
        info = parent.lstat()
        assert stat.S_ISDIR(info.st_mode) and info.st_dev == execute.ROOT.stat().st_dev
        assert info.st_uid == execute.ROOT.stat().st_uid
        identities[str(parent.relative_to(folder))] = identity(info)
        for child in children:
            assert not (parent / child).is_symlink()
            directories.append(str((parent / child).relative_to(folder)))
        for name in names:
            path = parent / name
            node = path.lstat()
            assert stat.S_ISREG(node.st_mode) and node.st_dev == execute.ROOT.stat().st_dev
            assert node.st_uid == execute.ROOT.stat().st_uid and node.st_nlink == 1
            raw = path.read_bytes()
            assert identity(path.lstat()) == identity(node)
            key = str(path.relative_to(folder))
            identities[key] = identity(node)
            files[key] = dict(kind='file', mode=stat.S_IMODE(node.st_mode), uid=node.st_uid,
                              inode=node.st_ino, links=node.st_nlink, mtime_ns=node.st_mtime_ns,
                              ctime_ns=node.st_ctime_ns, **prepare.blob(raw))
    native = subprocess.run(['rg', '--files', '--hidden', '--no-ignore', '--', relative],
                            cwd=execute.ROOT, capture_output=True)
    assert native.returncode == 0 and native.stderr == b''
    assert sorted(native.stdout.decode().splitlines()) == sorted(relative + '/' + name for name in files)
    return dict(state=dict(files=files, directories=sorted(directories)), identities=identities,
                rg=dict(command=['rg', '--files', '--hidden', '--no-ignore', '--', relative],
                        status=native.returncode, stdout=prepare.blob(native.stdout), stderr=prepare.blob(native.stderr)))


def authority(label):
    assert label in LABELS
    path = Path(str(producer.PREFIX) + '-' + label + '.json.gz')
    raw = git_file(AUTHORITY, path)
    assert execute.read(path) == raw
    value = json.loads(gzip.decompress(raw))
    assert value['label'] == label and value['working_directory'] == str(producer.ROOT / label)
    return value['after']


def admit(relative, expected):
    assert relative in TARGETS, 'only the fixed private regular fixture population is disposable'
    tracked = execute.command(['git', '--no-replace-objects', 'ls-files', '-z', '--', relative])
    ignored = subprocess.run(['git', 'check-ignore', '-q', relative], cwd=execute.ROOT)
    assert tracked == b'' and ignored.returncode == 0
    observed = snapshot(relative)
    assert exact(observed['state'], expected), 'whole committed file/body/mode/node/member authority'
    return observed


def protected():
    result = {}
    for path in sorted((execute.ROOT / 'docs/book/book').rglob('*')):
        if path.is_file():
            assert not path.is_symlink() and path.stat().st_dev == execute.ROOT.stat().st_dev
            result[str(path.relative_to(execute.ROOT))] = prepare.identity(path.read_bytes())
    for name in ('.git/index', '.git/HEAD', '.git/config'):
        path = execute.ROOT / name
        assert path.is_file() and not path.is_symlink()
        result[name] = prepare.identity(path.read_bytes())
    result['primary_and_spent_cache'] = producer.protected_cache()
    # The intentional symlink control is retained, not admitted for disposal.
    result['retained_symlink_fixture'] = producer.snapshot(producer.ROOT / 'symlink')
    return result


def artifact_census():
    rows, boundaries = {}, []
    root = execute.ROOT
    for directory, children, names in os.walk(root, topdown=True, followlinks=False):
        parent = Path(directory)
        if parent != root and ('.git' in children or '.git' in names
                               or ('HEAD' in names and 'objects' in children)):
            boundaries.append(dict(path=str(parent.relative_to(root)), kind='git'))
            children[:] = []
            continue
        for child in children[:]:
            path = parent / child
            node = path.lstat()
            if child == '.git' or stat.S_ISLNK(node.st_mode) or node.st_dev != root.stat().st_dev:
                boundaries.append(dict(path=str(path.relative_to(root)), kind='git' if child == '.git' else 'symlink_or_volume'))
                children.remove(child)
        for name in names:
            path = parent / name
            if path.suffix not in ('.log', '.bin', '.pyc', '.stdout', '.stderr') and name not in ('stdout.txt', 'stderr.txt'):
                continue
            node = path.lstat()
            if not stat.S_ISREG(node.st_mode) or node.st_dev != root.stat().st_dev:
                continue
            rows[str(path.relative_to(root))] = identity(node)
    rust = []
    for base in ('target', 'rust/target'):
        for suffix in ('release', 'debug/incremental', 'debug/deps'):
            name = base + '/' + suffix
            path = execute.safe(name)
            rust.append(dict(path=name, exists=path.exists(),
                             retained=sorted(key for key in rows if key.startswith(name + '/') and key.endswith(('.log', '.bin')))))
    return dict(candidates=rows, boundaries=sorted(boundaries, key=lambda row: row['path']), rust=rust,
                root_strays=sorted(key for key in rows if '/' not in key))


def replay(value):
    assert value['owner'] == OWNER and value['revision'] == REVISION and value['authority'] == AUTHORITY
    assert (datetime.fromisoformat(value['utc']) - datetime.fromisoformat(value['prior_utc'])).total_seconds() > 86400
    assert set(value['before']) == set(value['outcomes']) == set(TARGETS)
    for label, relative in zip(LABELS, TARGETS):
        assert exact(value['before'][relative]['state'], authority(label))
        assert value['outcomes'][relative] == dict(removed=True, absent_after=True)
    assert exact(value['protected_before'], value['protected_after'])
    assert exact(value['census_before'], value['census_after'])
    assert value['residue'] == [str(producer.ROOT / 'symlink')]
    native = value['post_saved_reader']
    assert type(native['status']) is int and native['status'] == 0
    assert prepare.unblob(native['stdout']) == b'Full unchanged public cache matrix and closed fixed derived-output evidence pass; permissive consumer shapes and default roles stay explicit.\n'
    assert b'ram-guard: terminating PID tree' not in prepare.unblob(native['stderr'])
    return True


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--record', action='store_true')
    args = parser.parse_args()
    assert Path.cwd().resolve() == execute.ROOT
    if args.record:
        assert not execute.safe(RESULT).exists()
        assert execute.git_state()['head'] == REVISION
        prior = (execute.ROOT / 'docs/ARTIFACT_CLEANUP.md').read_text().splitlines()[2].split(' — ', 1)[0]
        assert git_file(REVISION, 'docs/ARTIFACT_CLEANUP.md') == execute.read('docs/ARTIFACT_CLEANUP.md')
        now = datetime.now(timezone.utc)
        assert (now - datetime.fromisoformat(prior)).total_seconds() > 86400
        value = dict(owner=OWNER, revision=REVISION, authority=AUTHORITY, utc=now.isoformat(), prior_utc=prior,
                     programme=prepare.blob(Path(__file__).read_bytes()), before={}, outcomes={},
                     protected_before=protected(), census_before=artifact_census())
        for label, relative in zip(LABELS, TARGETS):
            value['before'][relative] = admit(relative, authority(label))
        # A real extra filesystem member must refuse before any removal.
        marker = execute.safe(Path(TARGETS[0]) / 'cleanup-control.marker')
        with marker.open('xb') as stream:
            stream.write(b'Owned cleanup completeness control\n')
        marker_id = identity(marker.lstat())
        try:
            admit(TARGETS[0], authority(LABELS[0]))
        except AssertionError as error:
            value['extra_member_control'] = dict(refused=True, diagnostic=str(error), marker=prepare.blob(marker.read_bytes()))
        else:
            raise AssertionError('actual extra member admitted')
        assert identity(marker.lstat()) == marker_id
        marker.unlink()
        try:
            admit(str(producer.selected_postrun.checkout.FOLDER), authority(LABELS[0]))
        except AssertionError as error:
            value['protected_path_control'] = dict(refused=True, diagnostic=str(error))
        else:
            raise AssertionError('spent source path admitted')
        # All authorities qualify before deletion; recheck immediately per target.
        for label, relative in zip(LABELS, TARGETS):
            current = admit(relative, authority(label))
            shutil.rmtree(execute.safe(relative))
            outcome = dict(removed=True, absent_after=not execute.safe(relative).exists())
            value['outcomes'][relative] = outcome
            execute.save(BASE / ('removed-' + label + '.json.gz'), dict(before=current, outcome=outcome))
            assert outcome['absent_after']
        value['residue'] = sorted(str(path.relative_to(execute.ROOT)) for path in execute.safe(producer.ROOT).iterdir())
        command = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
                   'docs/audits/original-join-parent-acceptance-20261018/verify_runtime_cache.py']
        native = subprocess.run(command, cwd=execute.ROOT, capture_output=True)
        value['post_saved_reader'] = dict(command=command, status=native.returncode,
                                          stdout=prepare.blob(native.stdout), stderr=prepare.blob(native.stderr))
        value['protected_after'], value['census_after'] = protected(), artifact_census()
        execute.save(RESULT, value)
        assert replay(value)
        (execute.ROOT / 'docs/ARTIFACT_CLEANUP.md').write_text('# Latest artifact cleanup\n\n' + now.isoformat() +
            ' — Removed authenticated regular private cache-test copies; intentional symlink control, books, primary/spent caches and native/compiler/audit evidence retained. Root/Rust and stray-artifact census complete.\n')
    value = json.loads(gzip.decompress(execute.read(RESULT)))
    assert prepare.unblob(value['programme']) == Path(__file__).read_bytes()
    assert replay(value)
    print('Authenticated regular cache-fixture disposal and dated residue/source/protection evidence pass; saved verification repeats no deletion.')
