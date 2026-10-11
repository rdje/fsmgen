#!/usr/bin/env python3
"""Restore missing audit gate streams from explicit, unchanged committed receipts."""
import argparse
import contextlib
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import secrets
import stat
import subprocess

REPO = Path(__file__).resolve().parents[1]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def relative(value, allow_dot=False):
    require(type(value) is str and value and '\\' not in value and '\x00' not in value
            and '\n' not in value and '\r' not in value, 'ordinary relative path text')
    path = PurePosixPath(value)
    require(not path.is_absolute() and not {'..', '.git'}.intersection(path.parts)
            and path.as_posix() == value and (value != '.' or allow_dot),
            'canonical repository-relative path')
    return Path(value)


def local(path):
    """Read-only preflight; never create a directory or follow a link."""
    current = REPO
    device = REPO.stat().st_dev
    for index, part in enumerate(path.parts):
        current = current / part
        require(not current.is_symlink(), 'symlink boundary refused')
        if current.exists():
            info = current.lstat()
            require(info.st_dev == device, 'same-volume boundary required')
            require(index == len(path.parts) - 1 or stat.S_ISDIR(info.st_mode),
                    'ordinary directory ancestor required')
            if stat.S_ISDIR(info.st_mode):
                require(not os.path.lexists(current / '.git'), 'nested Git boundary refused')
    return current


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, 'duplicate receipt object key')
        result[key] = value
    return result


def committed_receipts(names):
    result = []
    for name in names:
        path = relative(name)
        require(len(path.parts) == 4 and path.parts[:2] == ('docs', 'audits')
                and path.name == 'checks.json', 'explicit audit checks receipt required')
        descriptor = os.open(local(path), os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(descriptor, 'rb') as stream:
            before = os.fstat(stream.fileno())
            require(stat.S_ISREG(before.st_mode) and before.st_dev == REPO.stat().st_dev,
                    'ordinary same-volume committed receipt file required')
            raw = stream.read()
            after = os.fstat(stream.fileno())
            require((before.st_ino, before.st_dev, before.st_size, before.st_mtime_ns) ==
                    (after.st_ino, after.st_dev, after.st_size, after.st_mtime_ns)
                    and len(raw) == before.st_size, 'complete stable committed receipt read')
        native = subprocess.run(['git', '-C', str(REPO), '--no-replace-objects',
                                 'show', 'HEAD:' + name], capture_output=True)
        require(type(native.returncode) is int and native.returncode == 0
                and native.stderr == b'' and native.stdout == raw,
                'complete receipt must match committed HEAD bytes')
        records = json.loads(raw, object_pairs_hook=unique_object)
        require(type(records) is dict and records, 'complete named gate receipt object')
        result.append((name, records))
    return result


def plan(receipts, root='.'):
    """Validate every source, target and existing body before any filesystem write."""
    root_path = relative(root, allow_dot=True)
    require(local(root_path).is_dir(), 'existing ordinary destination root required')
    targets = {}
    for name, records in receipts:
        source = relative(name)
        require(len(source.parts) == 4 and source.parts[:2] == ('docs', 'audits')
                and source.name == 'checks.json', 'explicit audit checks receipt required')
        namespace = source.parts[2]
        require(re.fullmatch(r'[A-Za-z0-9-]+', namespace) is not None,
                'ordinary audit namespace required')
        require(type(records) is dict and records, 'complete named gate receipt object')
        for label, row in records.items():
            require(type(label) is str and re.fullmatch(r'[A-Za-z0-9-]+', label) is not None
                    and type(row) is dict and type(row.get('status')) is int,
                    'complete typed terminal gate required')
            for stream in ('stdout', 'stderr'):
                require(type(row.get(stream)) is str and type(row.get(stream + '_path')) is str,
                        'complete stream text and path required')
                path = relative(row[stream + '_path'])
                expected = Path('.artifacts') / namespace / 'checks' / label / (stream + '.txt')
                require(path == expected, 'stream path must match its declared audit gate')
                body = row[stream].encode('utf-8')
                target = root_path / path
                key = target.as_posix()
                if key in targets:
                    require(targets[key]['body'] == body, 'contradictory duplicate stream target')
                else:
                    targets[key] = dict(path=target, body=body)
    for row in targets.values():
        target = local(row['path'])
        row['present'] = target.exists()
        if row['present']:
            info = target.lstat()
            require(stat.S_ISREG(info.st_mode) and info.st_nlink == 1,
                    'existing stream must be an ordinary unshared file')
            require(target.read_bytes() == row['body'], 'existing stream bytes conflict')
    return [targets[name] for name in sorted(targets)]


@contextlib.contextmanager
def parent_directory(path):
    """Open each directory without following links, including during installation."""
    flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
    descriptors = [os.open(REPO, flags)]
    device = os.fstat(descriptors[0]).st_dev
    try:
        for part in path.parts:
            parent = descriptors[-1]
            try:
                child = os.open(part, flags, dir_fd=parent)
            except FileNotFoundError:
                os.mkdir(part, mode=0o700, dir_fd=parent)
                child = os.open(part, flags, dir_fd=parent)
            descriptors.append(child)
            require(os.fstat(child).st_dev == device, 'same-volume directory required at installation')
            try:
                os.stat('.git', dir_fd=child, follow_symlinks=False)
            except FileNotFoundError:
                pass
            else:
                raise ValueError('nested Git boundary refused at installation')
        yield descriptors[-1]
    finally:
        for descriptor in reversed(descriptors):
            os.close(descriptor)


def install(rows):
    created = []
    for row in rows:
        if row['present']:
            continue
        path, body = row['path'], row['body']
        with parent_directory(path.parent) as directory:
            temporary = '.restore-stream-' + secrets.token_hex(16)
            descriptor = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                                 0o600, dir_fd=directory)
            try:
                with os.fdopen(descriptor, 'wb') as stream:
                    stream.write(body)
                    stream.flush()
                    os.fsync(stream.fileno())
                # A complete body becomes visible atomically; an existing target is never replaced.
                os.link(temporary, path.name, src_dir_fd=directory, dst_dir_fd=directory,
                        follow_symlinks=False)
                created.append(path.as_posix())
            finally:
                os.unlink(temporary, dir_fd=directory)
    return created


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--receipts', nargs='+', required=True,
                        help='explicit committed docs/audits/NAMESPACE/checks.json sources')
    parser.add_argument('--root', default='.', help='existing ordinary repository-relative destination root')
    parser.add_argument('--check', action='store_true', help='require all exact streams without writing')
    args = parser.parse_args()
    receipts = committed_receipts(args.receipts)
    rows = plan(receipts, args.root)
    if args.check:
        require(all(row['present'] for row in rows), 'complete streams not yet materialized')
        created = []
    else:
        created = install(rows)
    after = plan(receipts, args.root)
    require(all(row['present'] for row in after), 'complete exact stream installation required')
    print(json.dumps(dict(root=args.root, sources=args.receipts, created=created,
        streams=[dict(path=row['path'].as_posix(), bytes=len(row['body']),
                      sha256=hashlib.sha256(row['body']).hexdigest()) for row in after],
        condition='Exact committed text only; no reader execution, status reinterpretation or native/private qualification.'),
        sort_keys=True, separators=(',', ':')))


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, json.JSONDecodeError) as error:
        raise SystemExit('gate-stream-recovery: ' + str(error))
