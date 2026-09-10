"""Retire only the exact, independently audited failed experiment's workspaces."""
import errno
import hashlib
import json
import os
from pathlib import Path
import stat
import sys

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'.artifacts/logs/native-proxy-hardlink-20260910'
sys.path.insert(0,str(ROOT/'scripts'))
import fixture_kernel_sampler as sampler


def read(path,limit=65536):
    assert path.resolve()==path and ROOT in path.parents
    with os.fdopen(os.open(path,os.O_RDONLY|os.O_NOFOLLOW|os.O_NONBLOCK),'rb') as stream:
        info=os.fstat(stream.fileno())
        assert stat.S_ISREG(info.st_mode) and info.st_dev==ROOT.stat().st_dev and info.st_uid==os.getuid()
        raw=stream.read(limit+1)
    assert len(raw)<=limit
    return raw


assert len(sys.argv)==1 and os.environ.get('FSMGEN_RAM_GUARD_ACTIVE')=='1'
raw=read(OUT/'independent-audit.json')
assert len(raw)==18784 and hashlib.sha256(raw).hexdigest()=='183bed83b0bfabb20665f0a4be3a8dd15e4f68cf32b36a3479323ec9148fb3cf'
audit=json.loads(raw)
native=sampler.NativeProcesses()


def require_absence():
    for identity in audit['independently_absent_identities']:
        try:current=native.identity(identity['pid'])
        except OSError as error:
            if error.errno in (errno.ESRCH,errno.ENOENT):continue
            raise
        assert any(current[k]!=identity[k] for k in ('pid','ppid','uid','ruid','start_sec','start_usec'))


def verify(role,links):
    item=audit['remaining_owned_workspaces'][role]
    identity=item['identity'];path=ROOT/identity['path'];info=path.lstat()
    assert path.resolve()==path and stat.S_ISDIR(info.st_mode) and stat.S_IMODE(info.st_mode)==0o700
    assert info.st_dev==identity['device']==ROOT.stat().st_dev and info.st_ino==identity['inode'] and info.st_uid==os.getuid()
    assert {str(p.relative_to(ROOT)) for p in path.rglob('*')}=={e['path'] for e in item['entries']}
    for expected in item['entries']:
        p=ROOT/expected['path'];meta=p.lstat()
        assert p.resolve()==p and not p.is_symlink() and meta.st_uid==os.getuid()
        assert meta.st_dev==expected['device'] and meta.st_ino==expected['inode']
        assert stat.S_IMODE(meta.st_mode)==expected['mode']
        if expected['directory']:
            assert stat.S_ISDIR(meta.st_mode)
        else:
            assert stat.S_ISREG(meta.st_mode) and meta.st_size==expected['bytes'] and meta.st_nlink==links
            key='c' if p.name=='rustup.c' else 'binary'
            source=audit['same_inode_sources'][key]
            body=read(p)
            assert len(body)==source['size_bytes'] and hashlib.sha256(body).hexdigest()==source['sha256']
    return path


require_absence()
for role in ('a','b','base'):verify(role,3)
with (OUT/'retirement-attempt.json').open('x') as stream:
    json.dump({'audit_sha256':hashlib.sha256(raw).hexdigest(),'roles':['a','b','base'],
        'owned_births_independently_absent':True,'all_workspace_identities_and_bytes_match':True},stream,sort_keys=True)
retired=[]
for role,links in [('a',3),('b',2),('base',1)]:
    require_absence()
    path=verify(role,links)
    if role=='base':
        # rmdir refuses any unexpected compiler residue; recursive deletion is unnecessary.
        (path/'rust-tools/compiler-temp').rmdir()
        (path/'rust-tools/compiler-cache').rmdir()
    for name in ('rustup','rustup.c'):(path/'rust-tools'/name).unlink()
    (path/'rust-tools').rmdir()
    path.rmdir()
    assert not path.exists() and not path.is_symlink()
    retired.append(str(path.relative_to(ROOT)))
    for survivor in (['b','base'] if role=='a' else ['base'] if role=='b' else []):
        verify(survivor,links-1)
require_absence()
assert all(not (ROOT/p).exists() and not (ROOT/p).is_symlink() for p in retired)
report={'schema':'fsmgen.native_hardlink_retirement.v1','audit_sha256':hashlib.sha256(raw).hexdigest(),
    'retired_workspaces':retired,'remaining_workspaces':[],
    'independently_absent_identities':audit['independently_absent_identities'],
    'surviving_link_bytes_verified_after_each_retirement':True,'new_fixture_invocations':0}
body=(json.dumps(report,sort_keys=True,indent=2)+'\n').encode()
with (OUT/'retirement.json').open('xb') as stream:stream.write(body)
print(json.dumps({'retirement_bytes':len(body),'retirement_sha256':hashlib.sha256(body).hexdigest(),
    'remaining_workspaces':[],'independently_absent_births':len(report['independently_absent_identities'])},sort_keys=True))
