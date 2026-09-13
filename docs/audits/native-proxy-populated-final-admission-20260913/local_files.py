"""Bounded direct same-volume I/O for the fixed populated-worker admission."""
import hashlib
import os
from pathlib import Path
import re
import stat

from contract import ROOT, OUTPUT, canonical


def relative(path):
    if not isinstance(path, str) or not path or re.search(r'[\x00-\x1f\x7f\\]', path) or any(part in ('', '.', '..') for part in path.split('/')):
        raise ValueError('project path must be canonical and root-relative')
    return path


def direct(path, absent_ok=False):
    parts = relative(path).split('/')
    current = ROOT
    device, uid = ROOT.stat().st_dev, os.getuid()
    for index, part in enumerate(parts):
        current /= part
        try:
            metadata = current.lstat()
        except FileNotFoundError:
            if absent_ok:
                return None
            raise
        if metadata.st_dev != device or metadata.st_uid != uid or stat.S_ISLNK(metadata.st_mode):
            raise ValueError('project object has foreign ownership, volume or indirection')
        if index < len(parts) - 1 and not stat.S_ISDIR(metadata.st_mode):
            raise ValueError('project ancestor is not a directory')
    return metadata


def identity(metadata):
    return tuple(getattr(metadata, field) for field in (
        'st_dev', 'st_ino', 'st_mode', 'st_uid', 'st_nlink', 'st_size', 'st_mtime_ns', 'st_ctime_ns'))


def close_descriptor(descriptor, primary=None):
    try:
        os.close(descriptor)
    except OSError as error:
        if primary is None:
            raise
        primary.add_note('Additional descriptor-close failure: ' + str(error))


def read_bytes(path, limit, mode=None):
    if type(limit) is not int or limit < 0:
        raise ValueError('input byte limit must be a nonnegative integer')
    named = direct(path)
    if not stat.S_ISREG(named.st_mode) or named.st_nlink != 1 or named.st_size > limit:
        raise ValueError('input must be a bounded unshared regular file')
    if mode is not None and stat.S_IMODE(named.st_mode) != mode:
        raise ValueError('input mode differs from its seal')
    descriptor = os.open(ROOT / path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC)
    primary = None
    try:
        before = os.fstat(descriptor)
        if identity(named) != identity(before):
            raise ValueError('opened input differs from its admitted name')
        body = bytearray()
        while len(body) <= limit:
            part = os.read(descriptor, min(65536, limit + 1 - len(body)))
            if not part:
                break
            body.extend(part)
        if len(body) != before.st_size or len(body) > limit or any(
                identity(before) != identity(current) for current in (os.fstat(descriptor), direct(path))):
            raise ValueError('input changed during its bounded read')
        return bytes(body)
    except BaseException as error:
        primary = error
        raise
    finally:
        close_descriptor(descriptor, primary)


def pin(path, limit=4 * 1024 * 1024):
    body = read_bytes(path, limit)
    return dict(path=path, size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest())


def directory_identity(path):
    metadata = direct(path)
    if not stat.S_ISDIR(metadata.st_mode) or stat.S_IMODE(metadata.st_mode) != 0o700:
        raise ValueError('owned directory is not private')
    return dict(path=path, device=metadata.st_dev, inode=metadata.st_ino)


def make_directory(path):
    """Create this single directory exclusively; ancestors must already exist."""
    relative(path)
    direct(str(Path(path).parent))
    if direct(path, absent_ok=True) is not None:
        raise FileExistsError(path)
    os.mkdir(ROOT / path, 0o700)
    return directory_identity(path)


def write_all(descriptor, body):
    offset = 0
    while offset < len(body):
        count = os.write(descriptor, memoryview(body)[offset:])
        if count <= 0 or count > len(body) - offset:
            raise OSError('exclusive write made invalid progress')
        offset += count


def write_bytes(path, body, mode, limit):
    relative(path)
    if type(limit) is not int or limit < 0 or not isinstance(body, bytes) or len(body) > limit or mode not in (0o400, 0o600, 0o700):
        raise ValueError('exclusive output bytes or mode are outside the fixed contract')
    direct(str(Path(path).parent))
    descriptor = os.open(ROOT / path, os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC, 0o600)
    primary = None
    try:
        before = os.fstat(descriptor)
        write_all(descriptor, body)
        os.fchmod(descriptor, mode)
        after = os.fstat(descriptor)
        if (before.st_dev, before.st_ino) != (after.st_dev, after.st_ino) or identity(after) != identity(direct(path)):
            raise ValueError('exclusive output identity changed during sealing')
        if read_bytes(path, limit, mode) != body:
            raise ValueError('exclusive output bytes differ after sealing')
        return dict(path=path, size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest())
    except BaseException as error:
        primary = error
        raise
    finally:
        close_descriptor(descriptor, primary)


def write_document(path, value, limit):
    if not relative(path).startswith(OUTPUT + '/'):
        raise ValueError('document must remain in the fixed execution output')
    return write_bytes(path, canonical(value), 0o400, limit)
