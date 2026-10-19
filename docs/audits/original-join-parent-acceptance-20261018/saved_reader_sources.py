"""Recover original audit source metadata without executing its source."""
import hashlib
from pathlib import Path

import execute
import prepare

REVISION = 'd5ea1fc9ed7e3fc502bcf4aeaf4b0da89226281a'
AUDIT = execute.AUDIT


def source_name(name):
    """Limit reads to regular source members of one fixed audit directory."""
    assert type(name) is str and name and '\0' not in name
    assert Path(name).name == name and not Path(name).is_absolute()
    assert name.endswith(('.py', '.py.source')), 'original audit source suffix'
    return str(AUDIT / name)


def original(name):
    path = source_name(name)
    entry = execute.command(['git', '--no-replace-objects', 'ls-tree', '--full-tree',
                             '-l', '-z', REVISION, '--', path])
    assert entry.count(b'\0') == 1, 'one original audit source'
    header, actual_path = entry[:-1].split(b'\t')
    mode, kind, oid, size = header.decode().split()
    assert mode in ('100644', '100755') and kind == 'blob' and actual_path.decode() == path
    assert size.isdecimal()
    raw = execute.command(['git', '--no-replace-objects', 'show', REVISION + ':' + path])
    assert len(raw) == int(size)
    assert raw == execute.command(['git', '--no-replace-objects', 'cat-file', 'blob', oid])
    assert hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest() == oid
    return dict(revision=REVISION, path=path, mode=mode, oid=oid, body=prepare.blob(raw),
                retention_contract='fsmgen_required_history')


def body(name, *, current=False):
    assert type(current) is bool, 'explicit source role'
    path = source_name(name)
    return execute.read(Path(path)) if current else prepare.unblob(original(name)['body'])
