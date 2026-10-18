"""Separate later full source verification; never erase the native-after observation gap."""
import argparse
from datetime import datetime, timezone
import gzip
import hashlib
import json
import os
from pathlib import Path
import stat

import execute
import historical_checkout as checkout
import prepare

PATH = execute.AUDIT / 'snapshot-postrun-sources.json.gz'
RUNTIME_DIRECTORIES = {'.artifacts', '.artifacts/build', '.artifacts/cache', '.artifacts/logs', '.artifacts/tmp'}


def verify():
    image = json.loads(gzip.decompress(execute.read(checkout.MANIFEST)))
    prepared = json.loads(gzip.decompress(execute.read(checkout.RESULT)))
    root = execute.ROOT / checkout.FOLDER
    expected = prepared['members']
    directories = {str(parent) for name in expected for parent in Path(name).parents if str(parent) != '.'}
    seen, seen_directories, actual = set(), set(), {}
    for folder, dirs, files in os.walk(root, followlinks=False):
        parent = Path(folder)
        assert parent.stat().st_dev == execute.ROOT.stat().st_dev
        for child in dirs[:]:
            path = parent / child
            name = str(path.relative_to(root))
            if path.is_symlink():
                dirs.remove(child)
                files.append(child)
            else:
                assert name in directories | RUNTIME_DIRECTORIES
                assert not (path / '.git').exists() and not (path / '.git').is_symlink()
                assert path.stat().st_dev == root.stat().st_dev
                seen_directories.add(name)
        for child in files:
            path = parent / child
            name = str(path.relative_to(root))
            if name == '.git':
                assert stat.S_ISREG(path.lstat().st_mode)
                continue
            assert name in expected and name not in seen
            seen.add(name)
            wanted, info = expected[name], path.lstat()
            assert info.st_dev == root.stat().st_dev
            if wanted['mode'] == '120000':
                assert stat.S_ISLNK(info.st_mode)
                body = os.fsencode(os.readlink(path))
                size = len(body)
                one = hashlib.sha1(b'blob ' + str(size).encode() + b'\0' + body).hexdigest()
                two = hashlib.sha256(body).hexdigest()
            else:
                assert stat.S_ISREG(info.st_mode) and bool(info.st_mode & 0o111) == (wanted['mode'] == '100755')
                size = info.st_size
                sha1, sha256 = hashlib.sha1(b'blob ' + str(size).encode() + b'\0'), hashlib.sha256()
                with path.open('rb') as stream:
                    assert os.fstat(stream.fileno()).st_ino == info.st_ino
                    while block := stream.read(1024 * 1024):
                        sha1.update(block)
                        sha256.update(block)
                one, two = sha1.hexdigest(), sha256.hexdigest()
            after = path.lstat()
            assert (info.st_dev, info.st_ino, info.st_mode, info.st_size, info.st_mtime_ns) == (
                after.st_dev, after.st_ino, after.st_mode, after.st_size, after.st_mtime_ns)
            assert (size, one, two) == (wanted['bytes'], wanted['oid'], wanted['sha256'])
            actual[name] = dict(wanted)
    assert seen == expected.keys() and seen_directories == directories | RUNTIME_DIRECTORIES
    assert checkout.git_state() == prepared['git']
    env_name = 'scripts/project_data_locality_env.sh'
    env = (root / env_name).read_bytes()
    assert env == execute.command(['git', '--no-replace-objects', 'show', checkout.REVISION + ':' + env_name])
    return dict(schema='fsmgen.later_snapshot_source_verification.v1', timestamp=datetime.now(timezone.utc).isoformat(),
                revision=image['revision'], members=actual, runtime_directories=sorted(RUNTIME_DIRECTORIES),
                locality_programme=prepare.blob(env),
                scope='Separate later complete physical source/mode/member/link/index verification. The five runtime directories '
                      'are exactly empty and are declared by the unchanged guard locality bootstrap. '
                      'The original native-after observer gap stays unqualified; no semantic or native success is implied.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    if args.write:
        execute.save(PATH, verify())
    else:
        saved = json.loads(gzip.decompress(execute.read(PATH)))
        current = verify()
        current['timestamp'] = saved['timestamp']
        assert current == saved
    print('Separate later complete tracked-source verification passes with exactly empty declared locality directories; the original after-observation gap remains.')
