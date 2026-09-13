"""Bounded same-volume evidence I/O and exact empty-store ownership."""

import hashlib
import json
import os
from pathlib import Path
import stat

from contract import ROOT


def direct(relative, absent_ok=False):
    if (not isinstance(relative, str) or not relative
            or any(part in ('', '.', '..') for part in relative.split('/'))):
        raise ValueError('noncanonical project path')
    current = ROOT
    parts = relative.split('/')
    for index, part in enumerate(parts):
        current /= part
        try:
            metadata = current.lstat()
        except FileNotFoundError:
            if absent_ok:
                return None
            raise
        if (metadata.st_dev != ROOT.stat().st_dev or metadata.st_uid != os.getuid()
                or stat.S_ISLNK(metadata.st_mode)):
            raise ValueError('indirect or foreign project object')
        if index < len(parts) - 1 and not stat.S_ISDIR(metadata.st_mode):
            raise ValueError('nondirectory project ancestor')
    return metadata


def identity(relative):
    metadata = direct(relative)
    if stat.S_ISDIR(metadata.st_mode):
        if stat.S_IMODE(metadata.st_mode) != 0o700:
            raise ValueError('fixture directory must remain private')
        kind = 'directory'
    elif (stat.S_ISREG(metadata.st_mode) and stat.S_IMODE(metadata.st_mode) == 0o600
          and metadata.st_nlink == 1 and metadata.st_size == 0):
        kind = 'file'
    else:
        raise ValueError('fixture object is not an exact empty owned object')
    return dict(path=relative, device=metadata.st_dev, inode=metadata.st_ino,
                mode=stat.S_IMODE(metadata.st_mode), uid=metadata.st_uid, kind=kind)


def read_bytes(relative, limit):
    named = direct(relative)
    if not stat.S_ISREG(named.st_mode) or named.st_nlink != 1 or named.st_size > limit:
        raise ValueError('input is not a bounded direct regular file')
    descriptor = os.open(ROOT / relative, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        before = os.fstat(descriptor)
        fields = ('st_dev', 'st_ino', 'st_mode', 'st_uid', 'st_nlink', 'st_size', 'st_mtime_ns', 'st_ctime_ns')
        if tuple(getattr(named, key) for key in fields) != tuple(getattr(before, key) for key in fields):
            raise ValueError('opened input differs from admitted regular file')
        data = bytearray()
        while len(data) <= limit:
            block = os.read(descriptor, min(65536, limit + 1 - len(data)))
            if not block:
                break
            data.extend(block)
        after = os.fstat(descriptor)
        current = direct(relative)
        values = [tuple(getattr(row, key) for key in fields) for row in (named, before, after, current)]
        if len(set(values)) != 1 or len(data) != before.st_size or len(data) > limit:
            raise ValueError('input changed during bounded read')
        return bytes(data)
    finally:
        os.close(descriptor)


def pin(relative, limit=4 * 1024 * 1024):
    body = read_bytes(relative, limit)
    return dict(path=relative, size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest())


def write_all(descriptor, data):
    offset = 0
    while offset < len(data):
        count = os.write(descriptor, data[offset:])
        if count <= 0:
            raise OSError('exclusive evidence write made no progress')
        offset += count


def exclusive(relative):
    if direct(relative, absent_ok=True) is not None:
        raise FileExistsError(relative)
    direct(str(Path(relative).parent))
    return os.open(ROOT / relative, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)


def write_json(relative, value):
    body = (json.dumps(value, sort_keys=True, indent=2) + '\n').encode()
    descriptor = exclusive(relative)
    try:
        write_all(descriptor, body)
    finally:
        os.close(descriptor)


def private_directory(relative):
    current = ''
    for part in relative.split('/'):
        if part in ('', '.', '..'):
            raise ValueError('noncanonical directory')
        current = current + '/' + part if current else part
        if direct(current, absent_ok=True) is None:
            os.mkdir(ROOT / current, 0o700)
        metadata = direct(current)
        if not stat.S_ISDIR(metadata.st_mode):
            raise ValueError('private output ancestor is not a directory')
    if stat.S_IMODE(metadata.st_mode) != 0o700:
        raise ValueError('output directory is not private')


class Store:
    """Only exact objects created by this run may be removed by this owner."""

    def __init__(self, case, journal):
        self.case = case
        self.journal = journal
        self.owned = {}

    def create(self):
        for relative, kind in ((self.case['store'], 'directory'),
                               (self.case['store'] + '/images', 'directory'),
                               (self.case['store'] + '/references', 'directory'),
                               (self.case['store'] + '/coordination.lock', 'file')):
            if direct(relative, absent_ok=True) is not None:
                raise FileExistsError(relative)
            self.journal('allocation_intent', path=relative, kind=kind)
            if kind == 'directory':
                os.mkdir(ROOT / relative, 0o700)
            else:
                descriptor = exclusive(relative)
                os.close(descriptor)
            self.owned[relative] = identity(relative)
            self.journal('allocated', object=self.owned[relative])
        return self.snapshot()

    def snapshot(self):
        store = self.case['store']
        observed = {relative: identity(relative) for relative in self.owned}
        if observed != self.owned:
            raise ValueError('owned fixture identity changed')
        names = sorted(os.listdir(ROOT / store))
        if names != ['coordination.lock', 'images', 'references']:
            raise ValueError('unexpected store membership')
        for name in ('images', 'references'):
            if os.listdir(ROOT / store / name):
                raise ValueError('unexpected namespace content')
        return observed

    def replace_lock(self):
        self.snapshot()
        source = self.case['store'] + '/coordination.lock'
        destination = self.case['retired_lock']
        if not destination or direct(destination, absent_ok=True) is not None:
            raise ValueError('replacement destination is not admitted and absent')
        original = self.owned[source]
        self.journal('replacement_intent', original=original, destination=destination)
        os.rename(ROOT / source, ROOT / destination)
        moved = dict(original, path=destination)
        if identity(destination) != moved:
            raise ValueError('retired lock identity changed')
        del self.owned[source]
        self.owned[destination] = moved
        descriptor = exclusive(source)
        os.close(descriptor)
        self.owned[source] = identity(source)
        if self.owned[source]['inode'] == original['inode']:
            raise ValueError('replacement reused original inode')
        self.journal('replaced', original=moved, replacement=self.owned[source])
        return self.snapshot()

    def cleanup(self):
        # Processes must already be settled; callers never infer that from files.
        if not self.owned:
            return []
        removed = []
        for relative in sorted(self.owned, key=lambda value: (value.count('/'), value), reverse=True):
            expected = self.owned[relative]
            if identity(relative) != expected:
                raise ValueError('refusing cleanup of a changed object')
            if expected['kind'] == 'directory':
                if os.listdir(ROOT / relative):
                    raise ValueError('refusing cleanup of a nonempty directory')
                os.rmdir(ROOT / relative)
            else:
                os.unlink(ROOT / relative)
            if direct(relative, absent_ok=True) is not None:
                raise ValueError('exact removal did not establish absence')
            self.journal('removed', object=expected)
            removed.append(relative)
        return removed
