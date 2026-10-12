"""Read-only fixed namespaces and isolated qualified consumer-meaning readers."""
import contextlib
import importlib
import stat
from parent_common import *


def namespace(root):
    entries = {}
    listing = git('ls-tree', '-r', '-z', PLAN['revision'], '--', root).rstrip(b'\0').split(b'\0')
    for row in listing:
        header, raw_name = row.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        name = raw_name.decode()
        need(Path(name).parent == Path(root) and kind == 'blob' and mode in ('100644', '100755')
             and name not in entries, 'complete flat ordinary committed canonical prerequisite')
        entries[name] = dict(mode=mode, oid=oid)
    census = subprocess.run(['rg', '--files', '--hidden', '--no-ignore', '--', root], capture_output=True, text=True)
    need(census.returncode == 0 and census.stderr == '' and sorted(census.stdout.splitlines()) == sorted(entries),
         'whole independent canonical prerequisite membership')
    bodies = fixed(entries)
    for name, body in bodies.items():
        info = Path(name).lstat()
        need(stat.S_ISREG(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev
             and bool(info.st_mode & 0o111) == (entries[name]['mode'] == '100755')
             and Path(name).read_bytes() == body, 'whole same-volume committed canonical prerequisite body/mode')
    return {name: dict(**entries[name], **pin(body)) for name, body in bodies.items()}


def public():
    retained = json.loads((BASE / 'integration-contract.json').read_bytes())['retained_dependencies']
    bodies = fixed(retained)
    need(all(pin(body) == retained[name] and Path(name).read_bytes() == body for name, body in bodies.items()),
         'all twelve maintained helper and source interfaces retain')
    name = 'scripts/check_record_value_publication.py'
    body = fixed([name])[name]
    need(Path(name).read_bytes() == body, 'whole unchanged maintained canonical factory')
    result = {'__name__': 'fixed_consumer_canonical_factory', '__file__': name}
    previous = sys.path[:]
    try:
        sys.path.insert(0, 'scripts')
        exec(compile(body, name, 'exec'), result)
    finally:
        sys.path[:] = previous
    return result


@contextlib.contextmanager
def isolated_meaning():
    root = PLAN['meaning']
    namespace(root)
    old_plan = json.loads(fixed([root + '/plan.json'])[root + '/plan.json'])
    roots = (root, *(old_plan[role] for role in ('helper', 'remaining', 'join')))
    names = {path.stem for folder in roots for path in Path(folder).glob('*.py')} | {'capture'}
    previous = {name: sys.modules[name] for name in names if name in sys.modules}
    previous_path = sys.path[:]
    try:
        for name in names:
            sys.modules.pop(name, None)
        sys.path.insert(0, root)
        yield importlib.import_module('reader'), importlib.import_module('controls')
    finally:
        sys.path[:] = previous_path
        for name in names:
            sys.modules.pop(name, None)
        sys.modules.update(previous)


def meanings(candidate=None):
    with isolated_meaning() as (reader, controls):
        original = reader.load_product('candidate.json.gz')
        actual = original if candidate is None else candidate
        qualification = reader.check(actual)
        if candidate is None:
            name = PLAN['meaning'] + '/qualification.json'
            need(same(qualification, json.loads(fixed([name])[name])), 'whole freshly rederived original complete consumer meanings')
    return dict(candidate=actual, qualification=qualification)


@contextlib.contextmanager
def isolated_source():
    root = PLAN['source_contract']
    namespace(root)
    names = {path.stem for path in Path(root).glob('*.py')} | {'capture'}
    previous = {name: sys.modules[name] for name in names if name in sys.modules}
    previous_path = sys.path[:]
    try:
        for name in names:
            sys.modules.pop(name, None)
        sys.path.insert(0, root)
        yield importlib.import_module('reader'), importlib.import_module('controls')
    finally:
        sys.path[:] = previous_path
        for name in names:
            sys.modules.pop(name, None)
        sys.modules.update(previous)


def source_contracts(candidate=None):
    with isolated_source() as (reader, controls):
        original = reader.load_product('candidate.json.gz')
        actual = original if candidate is None else candidate
        qualified = reader.check(actual)
        name = PLAN['source_contract'] + '/qualification.json'
        need(same(qualified, json.loads(fixed([name])[name])), 'whole freshly rederived complete original source contracts')
    return dict(candidate=actual, qualification=qualified)


def contracts():
    before_body = fixed([TASK])[TASK]
    active_body = gzip.decompress((BASE / 'activation-task.gz').read_bytes())
    before, active = nodes(before_body), nodes(active_body)
    owner, parent = PLAN['owner'], PLAN['parent']
    need(before.keys() == active.keys() and field(before[owner], 'Status') == 'pending'
         and field(active[owner], 'Status') == field(active[parent], 'Status') == 'active',
         'exact unchanged original consumer acceptance activation')
    wanted = before_body.replace(before[owner], before[owner].replace(b'  Status: `pending`', b'  Status: `active`', 1), 1)
    need(wanted == active_body, 'whole original consumer activation changes only the existing leaf status')
    direct = [parent + '.' + str(i) for i in range(1, 5)]
    descendants = {name: block.decode() for name, block in active.items() if name.startswith(parent + '.')}
    need(field(active[parent], 'Children') == ', '.join(direct)
         and all(field(active[name], 'Status') == 'done' for name in descendants if name != owner),
         'every complete unchanged original consumer descendant contract')
    need(field(active[PLAN['next_join']], 'Status') == field(active[PLAN['full_alias']], 'Status') == 'pending',
         'higher context cause coordinate join and full alias remain separately open')
    return dict(parent=active[parent].decode(), descendants=descendants,
                higher_join=active[PLAN['next_join']].decode(), full_alias=active[PLAN['full_alias']].decode(), condition=PLAN['condition'])
