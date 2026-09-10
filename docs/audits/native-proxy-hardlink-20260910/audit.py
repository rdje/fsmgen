"""Audit the retained first hard-link counterexample; never execute a fixture."""
import copy
import errno
import hashlib
import json
import os
from pathlib import Path
import re
import runpy
import stat
import struct
import sys

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / '.artifacts/logs/native-proxy-hardlink-20260910'
DURABLE = ROOT / 'docs/audits/native-proxy-hardlink-20260910'
sys.path.insert(0,str(ROOT/'scripts'))
import fixture_kernel_sampler as sampler


def pin(raw):
    return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}


def read(path,limit=65536):
    assert path.resolve() == path and ROOT in path.parents
    with os.fdopen(os.open(path,os.O_RDONLY|os.O_NOFOLLOW|os.O_NONBLOCK),'rb') as stream:
        before=os.fstat(stream.fileno())
        assert stat.S_ISREG(before.st_mode) and before.st_uid==os.getuid() and before.st_dev==ROOT.stat().st_dev
        raw=stream.read(limit+1)
        after=os.fstat(stream.fileno())
    assert len(raw)<=limit
    assert all(getattr(before,k)==getattr(after,k) for k in ('st_dev','st_ino','st_size','st_mtime_ns','st_ctime_ns'))
    assert path.lstat().st_ino==before.st_ino
    return raw


def load(name):
    return json.loads(read(OUT/name))


def absent(native,identity):
    try:
        current=native.identity(identity['pid'])
    except OSError as error:
        if error.errno in (errno.ESRCH,errno.ENOENT):
            return True
        raise
    keys=('pid','ppid','uid','ruid','start_sec','start_usec')
    return any(current[key]!=identity[key] for key in keys)


def path_counterexample(first,changed,alias,prepared):
    assert first['identity']==changed['identity']
    assert first['executable']==changed['expected']
    assert changed['observed']==alias['sources']['binary']['path']
    assert changed['expected']!=changed['observed']
    assert changed['expected'].endswith('/fsmgen-HardlinkA20260910/rust-tools/rustup')
    assert changed['observed'].endswith('/fsmgen-HardlinkB20260910/rust-tools/rustup')
    for key in ('c','binary'):
        expected=prepared['c' if key=='c' else 'binary']
        assert first['source_identity'][key]==dict(expected,path=first['source_identity'][key]['path'])
        assert alias['sources'][key]==dict(expected,path=alias['sources'][key]['path'])


def result_sequence(outcome):
    assert outcome['roles_reserved']==['prepare','a']
    assert set(outcome['results'])=={'prepare','a'}
    assert outcome['completed_sequence'] is False and outcome['original_invocations']==0
    assert outcome['errors']==[
        {'role':'a','operation':{'type':'ValueError','message':'native executable path differs from the invoked private alias','message_truncated':False}},
        {'experiment':{'type':'ValueError','message':'native executable path differs from the invoked private alias','message_truncated':False}}]
    for role,code in [('prepare',0),('a',9)]:
        result=outcome['results'][role]
        assert result['returncode']==code and result['native_wait_status']==code<<8
        assert result['timeout'] is False and result['released'] is True and result['leader_reaped'] is True


assert os.environ.get('FSMGEN_RAM_GUARD_ACTIVE')=='1'
definitions=runpy.run_path(str(DURABLE/'run.py'),run_name='read_only_admission_definitions')
definitions['verify_committed']()
plan,plan_pin=definitions['load_plan']()
definitions['verify_inputs'](plan)
assert pin(read(DURABLE/'admission.json'))=={'bytes':6939,'sha256':'8e01756dc4797e28ab889ded1e051f16f3e7ff6eaf621d3d7771d85433b3caaa'}
outcome=load('outcome.json')
result_sequence(outcome)
assert not (OUT/'b').exists() and not (OUT/'owner-b-attempt.json').exists()
assert read(OUT/'a/test.tap')==b'CONTROL_READY\n' and read(OUT/'a/test.stderr')==b''
assert read(OUT/'prepare/test.stderr')==b''
envelope=load('preparation.json')
assert json.loads(read(OUT/'prepare/test.tap'))==envelope
prepared=envelope['prepared']
assert prepared['ok']==1 and prepared['implementation']=='native'
assert prepared['selection_reason']=='darwin_arm64_command_line_tools'
compiler=prepared['compilation']
assert compiler['ok']==1 and compiler['status']=='success' and compiler['exit_code']==compiler['signal']==0
assert compiler['exec_failed']==compiler['timed_out']==compiler['output_limited']==0
assert compiler['timeout_seconds']==10 and compiler['capture_limit_bytes']==4096
assert compiler['cleanup']=={'containment':'rust_proxy_compiler_group','group_gone':1,'kill_sent':0,
    'leader_reaped':1,'leader_started':1,'surviving_descendants':0,'term_sent':0}
sources=load('source-archive.json')
assert prepared['sources']==[sources['c'],sources['binary']]
archives={key:read(OUT/'sources'/(value['sha256']+'.source')) for key,value in sources.items()}
for key,raw in archives.items():
    assert pin(raw)=={'bytes':sources[key]['size_bytes'],'sha256':sources[key]['sha256']}
assert archives['c']==b'#define PROXY_NONZERO 1\n'+read(DURABLE/'held.c')
assert struct.unpack('<IIII',archives['binary'][:16])==(0xfeedfacf,0x0100000c,0,2)
first,changed,alias=load('a-exec.json'),load('a-after-alias-b-access-unexpected.json'),load('alias-b.json')
path_counterexample(first,changed,alias,sources)
identity=load('owner-a-identity.json')
assert first['identity']==identity==load('a-main-entry.json')['identity']
assert first['monotonic_ns']<load('a-main-entry.json')['observed_monotonic_ns']
assert load('a-main-entry.json')['marker']=='CONTROL_READY\n'
for role in ('prepare','a'):
    result=load('owner-'+role+'-result.json')
    assert result==outcome['results'][role]
    release=load('owner-'+role+'-release.json')
    assert release['pid']==result['pid']==load('owner-'+role+'-identity.json')['pid']
    assert 0<release['ready_ns']<=release['child_release_ns']
    if role=='a':assert release['child_release_ns']<=first['monotonic_ns']

# Counterfactual copies must not satisfy the retained-evidence oracle.
rejected=[]
def rejects(label,call):
    try:call()
    except AssertionError:rejected.append(label)
    else:raise AssertionError('counterfactual was accepted: '+label)

for label,modify in [('wrong_status',lambda o:o['results']['a'].update(returncode=0)),
    ('missing_reap',lambda o:o['results']['a'].update(leader_reaped=False)),
    ('hidden_second_invocation',lambda o:o['roles_reserved'].append('b'))]:
    altered=copy.deepcopy(outcome);modify(altered)
    rejects(label,lambda:result_sequence(altered))
for label,modify in [('unchanged_path',lambda c:c.update(observed=c['expected'])),
    ('changed_birth',lambda c:c['identity'].update(start_usec=0))]:
    altered=copy.deepcopy(changed);modify(altered)
    rejects(label,lambda:path_counterexample(first,altered,alias,sources))
altered=copy.deepcopy(alias);altered['sources']['binary']['inode']+=1
rejects('different_inode',lambda:path_counterexample(first,changed,altered,sources))
def archived_bytes(raw):assert pin(raw)=={'bytes':50040,'sha256':'1c5f4010ca29a66de933b98429407055ba714854d77ff6c8276b2926392e3e2b'}
archived_bytes(archives['binary'])
rejects('changed_archived_image',lambda:archived_bytes(archives['binary']+b'x'))

native=sampler.NativeProcesses()
identities=[load('owner-'+role+'-identity.json') for role in ('prepare','a')]
policy=load('policy/policy-result.json')
assert policy==outcome['collector_result']
identities.append(policy['identity'])
assert identities==outcome['independently_absent_identities']
assert all(absent(native,item) for item in identities)
assert policy['command']==['/usr/bin/log','stream','--style','ndjson','--level','debug','--timeout','240','--predicate','process == "syspolicyd"']
assert policy['scope']=='daemon_context' and policy['failures']=={} and policy['returncode']==0
assert policy['leader_reaped'] is True and policy['forced_kill'] is False
assert 0<policy['started_ns']<=policy['prepared_ns']<=policy['finished_ns']
raw=read(OUT/'policy/policy.stdout',16777216)
assert pin(raw)=={'bytes':2758960,'sha256':'23671c6610a3632561b916c74709f56dba2f28ab46d1a48a0d6623a31541537b'}
for name in ('stdout','stderr'):
    value=policy['outputs'][name];body=read(OUT/'policy'/('policy.'+name),16777216)
    assert pin(body)=={'bytes':value['bytes'],'sha256':value['sha256']}
    assert value['hash_complete'] is True and value['path_identity_matches'] is True
assert read(OUT/'policy/policy.stderr')==b''
rows,joins=[],[]
for number,line in enumerate(raw.splitlines(keepends=True)[1:],2):
    if not line.strip():continue
    row=json.loads(line);assert isinstance(row,dict);rows.append(row)
    message=row.get('eventMessage','')
    for role in ('a','b'):
        relative=plan['workspaces'][role]+'/rust-tools/rustup'
        if str(ROOT/relative) in message:
            joins.append({'line':number,'raw_line':pin(line),'path':relative,
                'tokens':sorted({t.zfill(16) for t in re.findall(r'PST: \(path: ([0-9a-f]{1,16})\)',message)}),
                'timestamp':row.get('timestamp')})

workspaces={}
for role in ('base','a','b'):
    receipt=load('workspace-'+role+'.json');path=ROOT/receipt['path'];info=path.lstat()
    assert path.resolve()==path and stat.S_ISDIR(info.st_mode) and stat.S_IMODE(info.st_mode)==0o700
    assert info.st_dev==receipt['device']==ROOT.stat().st_dev and info.st_ino==receipt['inode'] and info.st_uid==os.getuid()
    assert {item.name for item in path.iterdir()}=={'rust-tools'}
    expected={'rustup','rustup.c'}|({'compiler-temp','compiler-cache'} if role=='base' else set())
    assert {item.name for item in (path/'rust-tools').iterdir()}==expected
    entries=[]
    for item in path.rglob('*'):
        meta=item.lstat();assert not item.is_symlink() and meta.st_dev==info.st_dev and meta.st_uid==os.getuid()
        assert stat.S_ISREG(meta.st_mode) or stat.S_ISDIR(meta.st_mode)
        entries.append({'path':str(item.relative_to(ROOT)),'device':meta.st_dev,'inode':meta.st_ino,
            'mode':stat.S_IMODE(meta.st_mode),'directory':item.is_dir(),'bytes':meta.st_size if item.is_file() else None})
    assert len(entries)==(5 if role=='base' else 3)
    for key,name,mode in [('c','rustup.c',0o400),('binary','rustup',0o500)]:
        item=path/'rust-tools'/name;meta=item.stat();assert stat.S_IMODE(meta.st_mode)==mode
        assert meta.st_ino==sources[key]['inode'] and meta.st_dev==sources[key]['device']
        assert read(item)==archives[key] and meta.st_nlink==3
    workspaces[role]={'identity':receipt,'entries':entries}

definitions['verify_inputs'](plan)
manifest={str(p.relative_to(OUT)):pin(read(p,16777216 if p.name=='policy.stdout' else 65536))
    for p in OUT.rglob('*') if p.is_file()}
report={'schema':'fsmgen.native_hardlink_independent_audit.v1','admission_commit':'f323894fc1cbc91498434bbeb600cc922140124c',
    'plan':plan_pin,'outcome':outcome,'first_native_path':first,'changed_native_path':changed,
    'same_inode_sources':sources,'independently_absent_identities':identities,
    'compiler_group_cleanup':'successful retained compiler result; compiler birth not independently sampled',
    'held_native_invocations':1,'reuse_invocations':0,'original_invocations':0,
    'first_failure_stopped_sequence':True,'rejected_counterfactuals':rejected,
    'policy_rows':len(rows),'literal_policy_path_rows':joins,'retained_manifest':manifest,
    'remaining_owned_workspaces':workspaces,'cleanup':'requires separate exact retirement after this audit',
    'interpretation':{'stable_private_native_path':'refuted by this admitted held control',
        'kernel_internal_path_cache_mechanism':'not_established','reuse_execution':'not_attempted after first failure',
        'policy_delivery':'unproved','scan_avoidance':'not_claimed','cold_host_state':'unproved',
        'historical_startup_repair':'unproved','loaded_image_attestation':'not_provided',
        'cross_clock_conversion':'not_performed','raw_policy_durability':'private ignored bytes; exact pin retained'}}
body=(json.dumps(report,sort_keys=True,indent=2)+'\n').encode()
assert len(body)<=65536
with (OUT/'independent-audit.json').open('xb') as stream:stream.write(body)
print(json.dumps({'report':pin(body),'path_counterexample':changed,'policy_rows':len(rows),
    'literal_policy_path_rows':joins,'rejected_counterfactuals':rejected,'independent_absence':len(identities)},sort_keys=True))
