"""Strict whole-namespace authentication for the original observer publication."""
import hashlib
import json
import os
import stat
from pathlib import Path

ORIGINAL = Path('docs/audits/observer-current-publication-20261011')
MANIFEST_IDENTITY = {'bytes': 13124, 'sha256': 'd57161c99bb799db3a2a4161145a1c5f616e5b2ce370be5e00228cc8327071a0'}


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def encoded(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True, allow_nan=False)+'\n').encode()


def declaration():
    raw=(ORIGINAL/'manifest.json').read_bytes()
    require(identity(raw)==MANIFEST_IDENTITY,'fixed whole original observer namespace authority')
    declared=json.loads(raw)
    declared['manifest.json']=MANIFEST_IDENTITY
    # Mutable external gate receipts are an explicit separate member role.
    declared['checks.json']=None
    return declared


def check_tree(root, declared):
    require(type(declared) is dict and bool(declared),'closed original observer namespace declaration')
    for name, expected in declared.items():
        require(type(name) is str and not Path(name).is_absolute() and not {'.','..','.git'}.intersection(Path(name).parts),
                'closed original observer namespace path')
        require(expected is None and name=='checks.json' or type(expected) is dict and set(expected)=={'bytes','sha256'}
                and type(expected['bytes']) is int and expected['bytes']>=0 and type(expected['sha256']) is str
                and len(expected['sha256'])==64,'closed original observer namespace identity')
    require(not root.is_symlink() and root.is_dir() and root.stat().st_dev==Path.cwd().stat().st_dev,
            'ordinary same-volume observer namespace root')
    allowed_dirs={str(parent) for name in declared for parent in Path(name).parents if str(parent)!='.'}
    observed={}
    for directory, children, files in os.walk(root, followlinks=False):
        base=Path(directory)
        for name in children:
            path=base/name
            require(not path.is_symlink() and str(path.relative_to(root)) in allowed_dirs
                    and path.stat().st_dev==root.stat().st_dev and not (path/'.git').exists(),
                    'declared observer namespace directory graph')
        for name in files:
            path=base/name
            require(not path.is_symlink() and stat.S_ISREG(path.lstat().st_mode)
                    and path.stat().st_dev==root.stat().st_dev,'ordinary same-volume observer namespace member')
            observed[str(path.relative_to(root))]=path
    require(set(observed)==set(declared),'complete observer namespace member graph')
    for name,path in observed.items():
        expected=declared[name]
        if expected is None:continue
        before=path.stat();digest=hashlib.sha256();total=0
        require(before.st_size==expected['bytes'],'whole observer namespace member bytes')
        with path.open('rb') as stream:
            while True:
                chunk=stream.read(min(1048576,expected['bytes']-total+1))
                if not chunk:break
                total+=len(chunk)
                require(total<=expected['bytes'],'whole observer namespace member bytes')
                digest.update(chunk)
        after=path.stat()
        require((before.st_dev,before.st_ino,before.st_size,before.st_mtime_ns)==
                (after.st_dev,after.st_ino,after.st_size,after.st_mtime_ns) and
                dict(bytes=total,sha256=digest.hexdigest())==expected,'whole observer namespace member bytes')
    return declared


def authenticate_original():
    declared=declaration();check_tree(ORIGINAL,declared)
    proof=json.loads((ORIGINAL/'proof.json').read_bytes());checks=json.loads((ORIGINAL/'checks.json').read_bytes())
    require(type(checks) is dict,'closed original observer external receipt collection')
    for row in checks.values():
        require(type(row) is dict and set(row)=={'command','status','stdout','stderr','inputs'}
                and type(row['status']) is int and type(row['stdout']) is str and type(row['stderr']) is str
                and type(row['command']) is list and all(type(word) is str for word in row['command'])
                and type(row['inputs']) is dict,'closed original observer typed external receipt')
    for name,expected in proof['final_checks'].items():
        require(name in checks and type(checks[name]['status']) is int and checks[name]['status']==0
                and identity(encoded(checks[name]))==expected,'complete original observer final actual qualification')
    return declared
