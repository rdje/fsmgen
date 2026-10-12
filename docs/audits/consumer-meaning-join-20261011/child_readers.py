"""Isolate and execute committed source-meaning readers through their own interfaces."""
import contextlib
import importlib
import stat
from join_common import *

ROLES = {'helper': (PLAN['helper'], 'candidate.json.gz'),
         'remaining': (PLAN['remaining'], 'candidate-v2.json.gz')}


def authenticate(role):
    root, _ = ROLES[role]
    names = git('ls-tree', '-r', '--name-only', PLAN['revision'], '--', root).decode().splitlines()
    need(names and all(Path(name).parent == Path(root) for name in names), 'complete flat committed child source namespace')
    census = subprocess.run(['rg', '--files', '--hidden', '--no-ignore', '--', root], capture_output=True, text=True)
    need(census.returncode == 0 and census.stderr == '' and sorted(census.stdout.splitlines()) == names,
         'whole independent child namespace membership')
    bodies = fixed(names)
    for name, body in bodies.items():
        info = Path(name).lstat()
        need(stat.S_ISREG(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev
             and Path(name).read_bytes() == body, 'whole regular same-volume committed child source')
    return {name: pin(body) for name, body in bodies.items()}


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


def admit(role, probes=()):
    custody = authenticate(role)
    root, product = ROLES[role]
    with isolated(role) as reader:
        own_common = sys.modules['helper_common' if role == 'helper' else 'remaining_common']
        candidate = own_common.load_product(product)
        qualification = reader.check(candidate)
        need(own_common.same(qualification, json.loads(Path(root, 'qualification.json').read_bytes())),
             'whole independently rederived committed child qualification')
        # Probe supplied native comparisons before the parent join's source or
        # observation custody checks; child source meanings remain unchanged.
        truths = [reader.comparison.observed(native) for native in probes]
    return dict(candidate=candidate, qualification=qualification, custody=custody, truths=truths)
