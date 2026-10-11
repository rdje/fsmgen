"""Independent recursive census and full byte reconstruction."""
import hashlib
import stat
from pathlib import Path


def reconstruct(root, declared):
    observed={};directories=set()
    for path in root.rglob('*'):
        relative=str(path.relative_to(root))
        if path.is_symlink():raise ValueError('ordinary same-volume observer namespace member')
        if path.is_dir():directories.add(relative);continue
        if not stat.S_ISREG(path.stat().st_mode) or path.stat().st_dev!=root.stat().st_dev:
            raise ValueError('ordinary same-volume observer namespace member')
        observed[relative]=path.read_bytes()
    allowed={str(p) for name in declared for p in Path(name).parents if str(p)!='.'}
    if directories!=allowed:raise ValueError('declared observer namespace directory graph')
    if set(observed)!=set(declared):raise ValueError('complete observer namespace member graph')
    for name,raw in observed.items():
        expected=declared[name]
        if expected is not None and dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())!=expected:
            raise ValueError('whole observer namespace member bytes')
    return {name:None if declared[name] is None else dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
            for name,raw in observed.items()}
