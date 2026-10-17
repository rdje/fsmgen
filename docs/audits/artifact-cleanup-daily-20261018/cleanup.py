"""Fixed no-removal artifact sweep and receipt replay; no caller-selected paths."""
from pathlib import Path
from datetime import datetime, timezone
import copy
import base64
import gzip
import hashlib
import json
import os
import stat
import subprocess
import sys

if not __debug__:
    raise SystemExit('Cleanup assertions must be enabled.')

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
TARGET = '.artifacts/index-observer-host-correlation-20261018/book'
PEER = 'docs/book/book'
RESULT = HERE / 'result.json.gz'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def identity(info):
    # Reading is allowed to update access time. Content and node identity are
    # guarded independently; a whole stat_result comparison rejects that read.
    return [info.st_dev, info.st_ino, info.st_mode, info.st_nlink,
            info.st_size, info.st_mtime_ns, info.st_ctime_ns]


def census(relative):
    assert relative in (TARGET, PEER)
    path = ROOT / relative
    assert path.is_dir() and not path.is_symlink()
    for parent in (path, *path.parents):
        if parent == ROOT:
            break
        assert not parent.is_symlink() and not (parent / '.git').exists()
    files, nodes = {}, {}
    for directory, children, names in os.walk(path, followlinks=False):
        assert '.git' not in children and '.git' not in names
        for item in (Path(directory), *[Path(directory) / name for name in names]):
            before = item.lstat()
            assert before.st_dev == ROOT.stat().st_dev
            assert stat.S_ISDIR(before.st_mode) or stat.S_ISREG(before.st_mode)
            key = str(item.relative_to(path))
            nodes[key] = identity(before)
            if stat.S_ISREG(before.st_mode):
                assert before.st_nlink == 1 and before.st_size <= 33554432
                assert item.suffix not in ('.log', '.bin'), 'retain native/log artifacts'
                raw = item.read_bytes()
                assert identity(item.lstat()) == identity(before)
                files[key] = {'bytes': len(raw), 'sha256': sha(raw)}
        assert all(not (Path(directory) / child).is_symlink() for child in children)
        assert len(files) <= 4096 and len(nodes) <= 8192
    assert not subprocess.check_output(['git', 'ls-files', '--', relative], cwd=ROOT)
    ignored = subprocess.run(['git', 'check-ignore', '-q', relative], cwd=ROOT, check=False)
    assert ignored.returncode == 0
    independent = subprocess.check_output(
        ['rg', '--files', '--hidden', '--no-ignore', relative], cwd=ROOT, text=True).splitlines()
    assert sorted(independent) == sorted(relative + '/' + name for name in files)
    return {'path': relative, 'files': files, 'nodes': nodes,
            'independent_membership': sorted(name[len(relative) + 1:] for name in independent)}


def matching(target, peer):
    assert target['path'] == TARGET and peer['path'] == PEER
    assert target['files'] and target['files'] == peer['files']
    for tree in (target, peer):
        assert sorted(tree['files']) == tree['independent_membership']
    return True


def protected():
    paths = {ROOT / '.git' / name for name in ('index', 'HEAD', 'config')}
    for relative in ('docs/audits/task-acceptance-index-observer-20261017',
                     'docs/audits/index-observer-host-correlation-20261018',
                     '.artifacts/task-acceptance-index-observer-20261017'):
        for directory, children, names in os.walk(ROOT / relative, followlinks=False):
            assert '.git' not in children and '.git' not in names
            assert all(not (Path(directory) / child).is_symlink() for child in children)
            paths.update(Path(directory) / name for name in names)
    result = {}
    for path in sorted(paths):
        assert path.is_file() and not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
        raw = path.read_bytes()
        result[str(path.relative_to(ROOT))] = {'bytes': len(raw), 'sha256': sha(raw)}
    return result


def artifact_census():
    rows = {'root_strays': sorted(str(path.relative_to(ROOT)) for pattern in ('*.log', '*.bin')
                                  for path in ROOT.glob(pattern)), 'rust': []}
    for base in ('target', 'rust/target'):
        for suffix in ('release', 'debug/incremental', 'debug/deps'):
            relative = base + '/' + suffix
            path = ROOT / relative
            row = {'path': relative, 'exists': path.exists(), 'retained': []}
            if path.exists():
                for parent in (path, *path.parents):
                    if parent == ROOT:
                        break
                    assert not parent.is_symlink() and not (parent / '.git').exists()
                for directory, children, names in os.walk(path, followlinks=False):
                    assert Path(directory).stat().st_dev == ROOT.stat().st_dev
                    assert '.git' not in children and '.git' not in names
                    assert all(not (Path(directory) / child).is_symlink() for child in children)
                    row['retained'].extend(str((Path(directory) / name).relative_to(ROOT))
                                           for name in names if name.endswith(('.log', '.bin')))
                    assert len(row['retained']) <= 10000
                row['retained'].sort()
            rows['rust'].append(row)
    return rows


def replay(record):
    assert record['owner'] == 'TASK-ACCEPTANCE-CHECKLIST-BODY-BOUNDARY.3'
    assert record['source_sha256'] == sha(Path(__file__).read_bytes())
    assert record['target_before']['path'] == TARGET and record['peer_before']['path'] == PEER
    assert record['target_before'] == record['target_after']
    assert record['peer_before'] == record['peer_after']
    assert record['protected_before'] and record['protected_before'] == record['protected_after']
    assert record['removed'] == [] and record['target_present'] is True
    for tree in (record['target_before'], record['peer_before']):
        assert sorted(tree['files']) == tree['independent_membership']
    target, peer = record['target_before']['files'], record['peer_before']['files']
    assert set(target) == set(peer)
    changed = sorted(name for name in target if target[name] != peer[name])
    assert changed == record['difference_paths'] == [
        'reference-source/MEMORY.markdown.source.txt',
        'reference-source/docs/TASK_TREE.markdown.source.txt']
    try:
        matching(record['target_before'], record['peer_before'])
    except AssertionError:
        pass
    else:
        raise AssertionError('non-identical historical render admitted as a duplicate')
    return True


def first_inspection():
    first = json.loads(gzip.decompress((HERE / 'first-inspection.json.gz').read_bytes()))
    body = base64.b64decode(first['source']['body_base64'], validate=True)
    assert sha(body) == first['source']['sha256'] and len(body) == first['source']['bytes']
    assert b'assert item.lstat() == before' in body
    assert first['first_exit_code'] == 1 and first['deletion_occurred'] is False
    row, = first['subsequent_field_discriminator']
    assert set(row['changes']) == {'st_atime_ns'} and row['whole_stat_equal'] is False
    old, new = row['changes']['st_atime_ns']
    assert old != new
    # An actual read supplies the access-time discriminator; field controls
    # additionally prove that excluding it keeps every guarded field active.
    from types import SimpleNamespace
    fields = ('st_dev', 'st_ino', 'st_mode', 'st_nlink', 'st_size', 'st_mtime_ns', 'st_ctime_ns')
    native = {name: index for index, name in enumerate(fields)}
    assert identity(SimpleNamespace(**native, st_atime_ns=old)) == identity(SimpleNamespace(**native, st_atime_ns=new))
    for field in fields:
        changed = dict(native)
        changed[field] += 1
        assert identity(SimpleNamespace(**native)) != identity(SimpleNamespace(**changed))


def main():
    assert Path.cwd().resolve() == ROOT
    assert sys.argv[1:] in (['--record'], ['--verify'])
    if sys.argv[1:] == ['--record']:
        assert not RESULT.exists(), 'sweep already recorded'
        target, peer = census(TARGET), census(PEER)
        old = (ROOT / 'docs/ARTIFACT_CLEANUP.md').read_text().splitlines()[2].split(' — ', 1)[0]
        now = datetime.now(timezone.utc)
        assert (now - datetime.fromisoformat(old)).total_seconds() > 86400
        retained, artifacts = protected(), artifact_census()
        record = {'owner': 'TASK-ACCEPTANCE-CHECKLIST-BODY-BOUNDARY.3',
                  'utc': now.isoformat(), 'prior_utc': old,
                  'source_sha256': sha(Path(__file__).read_bytes()),
                  'revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                  'target_before': target, 'peer_before': peer,
                  'target_after': census(TARGET), 'peer_after': census(PEER),
                  'protected_before': retained, 'protected_after': protected(),
                  'artifact_census': artifacts, 'target_present': (ROOT / TARGET).is_dir(), 'removed': [],
                  'difference_paths': sorted(name for name in set(target['files']) | set(peer['files'])
                                             if target['files'].get(name) != peer['files'].get(name)),
                  'claim_legs': {'rederive': 'Complete os.walk hashes and independent raw rg membership compare the fixed render and retained peer; root and six exact Rust locations are censused.',
                                 'falsify': 'Actual differing copied live-source files refuse duplicate admission; access-time and every guarded identity-field control qualify the inspection. False-duplicate, false-removal and protected-byte mutations reject.',
                                 'durability': 'Tracked driver, first sources/failures, complete compressed manifests and before/after preservation retain this dated sweep. Future regenerated book bytes are not promised.'}}
        replay(record)
        with RESULT.open('xb') as stream:
            stream.write(gzip.compress(json.dumps(record, sort_keys=True).encode(), mtime=0))
        (ROOT / 'docs/ARTIFACT_CLEANUP.md').write_text(
            '# Latest artifact cleanup\n\n' + now.isoformat() +
            ' — No removal: render source views differ; both books and native evidence retained. Root and Rust log/bin locations censused with no disposable candidates.\n')
    record = json.loads(gzip.decompress(RESULT.read_bytes()))
    replay(record)
    first_inspection()
    mismatch = json.loads(gzip.decompress((HERE / 'mismatched-inspection.json.gz').read_bytes()))
    body = base64.b64decode(mismatch['source']['body_base64'], validate=True)
    assert sha(body) == mismatch['source']['sha256'] and len(body) == mismatch['source']['bytes']
    assert mismatch['first_exit_code'] == 1 and mismatch['deletion_occurred'] is False
    assert mismatch['changed'] == record['difference_paths']
    for mutation in ('duplicate', 'removal', 'protection'):
        candidate = copy.deepcopy(record)
        if mutation == 'duplicate':
            candidate['target_before']['files'] = copy.deepcopy(candidate['peer_before']['files'])
            candidate['target_after'] = copy.deepcopy(candidate['target_before'])
        elif mutation == 'removal':
            candidate['removed'] = [TARGET]
        else:
            next(iter(candidate['protected_after'].values()))['sha256'] = '0' * 64
        try:
            replay(candidate)
        except AssertionError:
            continue
        raise AssertionError('corrupt sweep receipt admitted: ' + mutation)
    print('Dated no-removal sweep, differing source views and preserved native/Git bytes verify.')


if __name__ == '__main__':
    main()
