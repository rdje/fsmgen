"""Reproduce the fixed-revision gate failure and complete canonical allocation."""
import hashlib
import json
import subprocess
import sys
import types
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'scripts'))
import decision_store_git as current

REVISION = 'e0620dd2ffb04c340b91693a04f5885c8abb6595'
SOURCE = 'scripts/decision_store_git.py'


def git(*args):
    return subprocess.check_output(['git', '--no-replace-objects', '-C', str(ROOT), *args])


def main():
    before = git('show', REVISION + ':' + SOURCE)
    original = types.ModuleType('original_decision_store_git')
    exec(compile(before, REVISION + ':' + SOURCE, 'exec'), original.__dict__)
    try:
        original.GitSnapshot(ROOT, REVISION)
    except ValueError as error:
        assert str(error) == 'Git output exceeds selected snapshot bound', str(error)
        refusal = str(error)
    else:
        raise AssertionError('old producer accepted the known overflow')
    wire = git('ls-tree', '-r', '--full-tree', '-z', REVISION)
    assert len(wire) > current.MAX_INVENTORY_BYTES
    expected, canonical = {}, bytearray()
    for record in wire.split(b'\0')[:-1]:
        header, path_bytes = record.split(b'\t', 1)
        mode, kind, object_id = header.split(b' ')
        assert kind in (b'blob', b'commit')
        path = path_bytes.decode('utf-8')
        assert path not in expected
        expected[path] = (mode.decode(), object_id.decode())
        canonical.extend(mode + b' ' + object_id + b' 0\t' + path_bytes + b'\0')
    assert len(canonical) <= current.MAX_INVENTORY_BYTES == original.MAX_INVENTORY_BYTES
    snapshot = current.GitSnapshot(ROOT, REVISION)
    assert snapshot.objects == expected, 'every path/mode/object allocation must agree'
    source = git('show', REVISION + ':docs/decisions/INDEX.md')
    assert snapshot.read('docs/decisions/INDEX.md') == source
    assert snapshot.revision == REVISION
    with __import__('unittest.mock', fromlist=['patch']).patch.object(
            current, 'MAX_INVENTORY_BYTES', len(canonical) - 1):
        try:
            current.GitSnapshot(ROOT, REVISION)
        except ValueError as error:
            assert str(error) == refusal
        else:
            raise AssertionError('canonical byte overflow was accepted')
    result = {
        'status': 0, 'revision': REVISION, 'source': SOURCE,
        'old_source_sha256': hashlib.sha256(before).hexdigest(),
        'current_source_sha256': hashlib.sha256((ROOT / SOURCE).read_bytes()).hexdigest(),
        'git_version': git('--version').decode().strip(),
        'oracle_command': ['git', '--no-replace-objects', 'ls-tree', '-r', '--full-tree', '-z', REVISION],
        'members': len(expected), 'wire_bytes': len(wire), 'wire_sha256': hashlib.sha256(wire).hexdigest(),
        'canonical_bytes': len(canonical), 'canonical_sha256': hashlib.sha256(canonical).hexdigest(),
        'old_refusal': refusal, 'canonical_overflow_refusal': refusal,
        'scope': 'Complete fixed-revision root path/mode/object allocation and selected decision-index bytes. No submodule recursion or native historical/capture qualification.'}
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
