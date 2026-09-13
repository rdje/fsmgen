"""Read-only installed interpreter identities; project paths stay root-relative."""

import hashlib
import os
from pathlib import Path
import shutil
import stat
import sys


def binary_pin(path):
    path = Path(path).resolve(strict=True)
    named = path.stat()
    if not stat.S_ISREG(named.st_mode) or named.st_size > 64 * 1024 * 1024:
        raise ValueError('installed interpreter is not a bounded regular binary')
    digest = hashlib.sha256()
    count = 0
    with path.open('rb') as source:
        before = os.fstat(source.fileno())
        while True:
            block = source.read(65536)
            if not block:
                break
            count += len(block)
            if count > 64 * 1024 * 1024:
                raise ValueError('installed interpreter exceeds byte bound')
            digest.update(block)
        after = os.fstat(source.fileno())
    fields = ('st_dev', 'st_ino', 'st_size', 'st_mode', 'st_mtime_ns', 'st_ctime_ns')
    if len({tuple(getattr(value, key) for key in fields) for value in (named, before, after, path.stat())}) != 1:
        raise ValueError('installed interpreter changed during read')
    return dict(size_bytes=count, sha256=digest.hexdigest())


def entry_paths():
    perl = shutil.which('perl')
    if perl is None:
        raise FileNotFoundError('required installed Perl interpreter')
    return dict(python=Path(sys.executable).resolve(strict=True), perl=Path(perl).resolve(strict=True))


def native_candidate(invocation, kind):
    """Select only the admitted fixed layout, never a basename or process claim."""
    if kind == 'same_binary':
        return invocation
    if kind == 'python_framework':
        if invocation.parent.name != 'bin':
            raise ValueError('Python framework invocation lacks the selected bin layout')
        return invocation.parent.parent / 'Resources/Python.app/Contents/MacOS/Python'
    raise ValueError('unknown native interpreter layout')


def resolve(plan):
    entries = entry_paths()
    result = {}
    for language, entry in entries.items():
        selected = plan['toolchains'][language]
        name = selected['selected_sibling_basename']
        if Path(name).name != name or name in ('', '.', '..'):
            raise ValueError('invalid interpreter selection')
        actual = entry.parent / name
        if binary_pin(entry) != selected['invocation_binary'] or binary_pin(actual) != selected['selected_binary']:
            raise ValueError('installed interpreter differs from admitted bytes')
        actual = actual.resolve(strict=True)
        native = native_candidate(actual, selected['native_image']['kind'])
        if native.resolve(strict=True) != native:
            raise ValueError('native interpreter image is not the direct selected object')
        if binary_pin(native) != selected['native_image']['binary']:
            raise ValueError('native interpreter bytes differ from admission')
        result[language] = dict(invocation=str(actual), native_image=str(native),
                                native_binary=selected['native_image']['binary'])
    return result
