"""Independent bounded inert fixture census, allocation and exact cleanup."""
import hashlib
import json
import os
from pathlib import Path
import stat
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PLAN = json.loads((BASE / 'plan.json').read_bytes())
LOG = ROOT / '.artifacts/logs' / BASE.name
DEVICE = ROOT.stat().st_dev


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def save(path, value):
    with path.open('x') as stream:
        json.dump(value, stream, sort_keys=True, indent=2)
        stream.write('\n')


def direct(path):
    assert path.is_relative_to(ROOT)
    for parent in reversed(path.parents):
        if parent == ROOT or parent.is_relative_to(ROOT):
            s = parent.lstat()
            assert stat.S_ISDIR(s.st_mode) and s.st_dev == DEVICE and s.st_uid == os.getuid()


def node(relative):
    path = ROOT / relative
    direct(path)
    s = path.lstat()
    assert s.st_dev == DEVICE and s.st_uid == os.getuid()
    result = dict(device=s.st_dev, inode=s.st_ino, uid=s.st_uid, mode=stat.S_IMODE(s.st_mode))
    if stat.S_ISDIR(s.st_mode):
        assert result['mode'] == 0o700
        result['kind'] = 'directory'
    else:
        assert stat.S_ISREG(s.st_mode) and s.st_size <= PLAN['limits']['fixture_file_bytes']
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        try:
            stable = lambda v: (v.st_dev, v.st_ino, v.st_mode, v.st_nlink, v.st_uid,
                                v.st_size, v.st_mtime_ns, v.st_ctime_ns)
            assert stable(os.fstat(fd)) == stable(s)
            chunks = []
            remaining = PLAN['limits']['fixture_file_bytes'] + 1
            while remaining:
                part = os.read(fd, remaining)
                if not part:
                    break
                chunks.append(part)
                remaining -= len(part)
            raw = b''.join(chunks)
            assert stable(os.fstat(fd)) == stable(s) == stable(path.lstat()) and len(raw) == s.st_size
        finally:
            os.close(fd)
        result.update(kind='file', links=s.st_nlink, size_bytes=len(raw), sha256=digest(raw))
    return result


def roots():
    return [row['root'] for row in PLAN['cases']] + [PLAN['workspace'], PLAN['store']]


def census():
    nodes = {}
    def walk(path, depth):
        assert depth <= PLAN['limits']['depth'] and len(nodes) < PLAN['limits']['nodes']
        entry = node(path)
        nodes[path] = entry
        if entry['kind'] == 'directory':
            names = sorted(os.listdir(ROOT / path))
            assert len(names) <= PLAN['limits']['nodes']
            for name in names:
                walk(path + '/' + name, depth + 1)
            assert node(path) == entry
    absent = []
    for path in roots():
        direct(ROOT / path)
        try:
            (ROOT / path).lstat()
        except FileNotFoundError:
            absent.append(path)
        else:
            walk(path, 0)
    assert sum(x.get('size_bytes', 0) for x in nodes.values()) <= PLAN['limits']['total_fixture_bytes']
    return dict(nodes=nodes, absent=absent)


def journal(event, **fields):
    path = LOG / 'allocation.jsonl'
    assert path.stat().st_size < PLAN['limits']['journal_bytes']
    with path.open('a') as stream:
        stream.write(json.dumps(dict(event=event, **fields), sort_keys=True) + '\n')
        stream.flush()
        os.fsync(stream.fileno())


def create(path, raw=None, mode=0o700, link=None):
    target = ROOT / path
    direct(target)
    assert not os.path.lexists(target)
    journal('intent', path=path, mode=mode, link=link,
            size_bytes=None if raw is None else len(raw), sha256=None if raw is None else digest(raw))
    if link:
        os.link(ROOT / link, target, follow_symlinks=False)
    elif raw is None:
        target.mkdir(mode=mode)
    else:
        fd = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
        with os.fdopen(fd, 'wb') as stream:
            stream.write(raw)
            stream.flush()
            os.fchmod(stream.fileno(), mode)
            os.fsync(stream.fileno())
    journal('created', path=path, node=node(path))


def prepare():
    assert all(not os.path.lexists(ROOT / p) for p in roots())
    assert len(roots()) == PLAN['limits']['roots']
    verify_pins()
    (LOG / 'allocation.jsonl').open('x').close()
    for case in PLAN['cases']:
        create(case['root'])
        parent = str(Path(case['path']).parent)
        if parent != case['root']:
            create(parent)
        create(case['path'], b'w' * case['size'], case['mode'])
        if case['hardlink']:
            create(case['root'] + '/alias', link=case['path'], mode=case['mode'])
    store, work = PLAN['store'], PLAN['workspace']
    for p in [store, store + '/images', store + '/references', work,
              work + '/rust-tools', work + '/rust-tools/compiler-cache', work + '/rust-tools/compiler-temp']:
        create(p)
    create(store + '/coordination.lock', b'', 0o600)
    vectors = json.loads((BASE.parent / 'native-proxy-image-custody-20260910/vectors.json').read_bytes())
    for name, raw, mode in [('rust-tool-resolution', b'inert wrapper; never executed', 0o755),
            ('rust-tools/rustup.c', bytes.fromhex(vectors['generated_c_hex']), 0o400),
            ('rust-tools/rustup', bytes.fromhex(vectors['image_hex']), 0o500),
            ('rust-tools/compiler-cache/cache.dat', b'inert cache', 0o400),
            ('rust-tools/compiler-temp/scratch.dat', b'inert scratch', 0o600)]:
        create(work + '/' + name, raw, mode)
    save(LOG / 'prepared.json', census())
    print('Fresh bounded inert fixtures prepared; no executable was launched.')


def verify_pins():
    for row in json.loads((BASE / 'source-pins.json').read_bytes()):
        raw = (ROOT / row['path']).read_bytes()
        assert len(raw) == row['size_bytes'] and digest(raw) == row['sha256'], row['path']


if __name__ == '__main__':
    assert sys.argv[1:] == ['--prepare']
    prepare()
