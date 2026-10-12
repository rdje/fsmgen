"""Fresh isolated committed meaning readers; their algorithms are shared premises."""
import contextlib
import importlib
import stat
from acceptance_common import *

ROLES = {'helper': (PLAN['helper'], 'candidate.json.gz'),
         'remaining': (PLAN['remaining'], 'candidate-v2.json.gz'),
         'join': (PLAN['join'], 'candidate.json.gz')}


def authenticate(role):
    root, _ = ROLES[role]
    listing = git('ls-tree', '-r', '-z', PLAN['revision'], '--', root).rstrip(b'\0').split(b'\0')
    entries = {}
    for record in listing:
        header, raw_name = record.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        name = raw_name.decode()
        need(Path(name).parent == Path(root) and kind == 'blob' and mode in ('100644', '100755')
             and name not in entries, 'complete flat ordinary committed child namespace')
        entries[name] = dict(mode=mode, oid=oid)
    census = subprocess.run(['rg', '--files', '--hidden', '--no-ignore', '--', root], capture_output=True, text=True)
    need(census.returncode == 0 and census.stderr == '' and sorted(census.stdout.splitlines()) == sorted(entries),
         'whole independently censused committed meaning namespace')
    bodies = fixed(entries)
    for name, body in bodies.items():
        info = Path(name).lstat()
        need(stat.S_ISREG(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev
             and bool(info.st_mode & 0o111) == (entries[name]['mode'] == '100755')
             and Path(name).read_bytes() == body, 'whole same-volume current committed meaning source/mode')
    return {name: dict(**entries[name], **pin(body)) for name, body in bodies.items()}


@contextlib.contextmanager
def isolated(role):
    root, _ = ROLES[role]
    names = {path.stem for child, _ in ROLES.values() for path in Path(child).glob('*.py')}
    names.add('capture')
    previous = {name: sys.modules[name] for name in names if name in sys.modules}
    previous_path = sys.path[:]
    try:
        for name in names:
            sys.modules.pop(name, None)
        sys.path.insert(0, root)
        yield importlib.import_module('reader')
    finally:
        sys.path[:] = previous_path
        for name in names:
            sys.modules.pop(name, None)
        sys.modules.update(previous)


def admit(role, candidate=None):
    custody = authenticate(role)
    root, product = ROLES[role]
    with isolated(role) as reader:
        common_name = {'helper': 'helper_common', 'remaining': 'remaining_common', 'join': 'join_common'}[role]
        common = sys.modules[common_name]
        original = common.load_product(product)
        actual = original if candidate is None else candidate
        qualification = reader.check(actual)
        if candidate is None:
            need(common.same(qualification, json.loads(Path(root, 'qualification.json').read_bytes())),
                 'whole fresh independent committed meaning qualification')
    return dict(candidate=actual, original=original, qualification=qualification, custody=custody)
