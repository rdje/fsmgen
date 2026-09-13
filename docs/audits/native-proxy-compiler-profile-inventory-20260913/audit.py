"""Read-only inventory of retained compiler receipts and their missing profile proof."""
import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PLAN = json.loads((BASE/'plan.json').read_bytes())
BUILDER = '.artifacts/logs/native-proxy-builder-20260910/'
DAEMON = 'docs/audits/native-proxy-daemon-original-20260910/'
HARDLINK = 'docs/audits/native-proxy-hardlink-20260910/'


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def save(path, value):
    with path.open('x') as stream:
        json.dump(value, stream, sort_keys=True, indent=2)
        stream.write('\n')


def bounded_read(path):
    for parent in [path, *path.parents]:
        if parent == ROOT:
            break
        metadata = parent.lstat()
        assert not stat.S_ISLNK(metadata.st_mode) and metadata.st_dev == ROOT.stat().st_dev
        assert metadata.st_uid == os.getuid()
    before = path.lstat()
    assert stat.S_ISREG(before.st_mode) and before.st_size <= PLAN['bounds']['input_bytes_each']
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        stable = lambda s:(s.st_dev,s.st_ino,s.st_mode,s.st_nlink,s.st_uid,s.st_size,s.st_mtime_ns,s.st_ctime_ns)
        assert stable(os.fstat(fd)) == stable(before)
        with os.fdopen(fd, 'rb', closefd=False) as stream:
            raw = stream.read(PLAN['bounds']['input_bytes_each']+1)
        assert stable(os.fstat(fd)) == stable(before) == stable(path.lstat())
        assert len(raw) == before.st_size
    finally:
        os.close(fd)
    return raw


def inputs(saved=None):
    retained = {} if saved is None else saved
    values = {}
    for pin in PLAN['inputs']:
        path = pin['path']
        if pin['durability'] == 'git':
            raw = subprocess.check_output(['git','show',PLAN['source_revision']+':'+path],cwd=ROOT)
            assert (ROOT/path).read_bytes() == raw, 'current applicability: '+path
        elif saved is None:
            raw = bounded_read(ROOT/path)
            retained[path] = dict(size_bytes=len(raw),sha256=digest(raw),bytes_hex=raw.hex())
        else:
            row = retained[path]; raw = bytes.fromhex(row['bytes_hex'])
            assert row['size_bytes']==len(raw) and row['sha256']==digest(raw)
        assert len(raw)==pin['size_bytes'] and digest(raw)==pin['sha256'], path
        values[path] = raw
    assert len(values)<=PLAN['bounds']['input_files']
    assert sum(map(len,values.values()))<=PLAN['bounds']['total_input_bytes']
    assert set(retained)=={p['path'] for p in PLAN['inputs'] if p['durability']!='git'}
    return values,retained


def evaluate(values):
    load = lambda p: json.loads(values[p])
    source = values['t/lib/FSM/Test/RustProxyFixture.pm'].decode()
    assert "schema => 'fsmgen.test.rust_proxy_fixture.v1'" in source
    assert "my $cache = File::Spec->catdir($bin, 'compiler-cache');" in source
    assert "my $temporary = File::Spec->catdir($bin, 'compiler-temp');" in source
    assert 'push @{$result->{sources}}, $source_identity;' in source
    assert 'push @{$result->{sources}}, _seal_executable($proxy, $selection->{implementation});' in source
    assert not re.search(r'\b(?:opendir|readdir)\b',source)
    assert 'local %ENV = (' in source and 'XDG_CACHE_HOME => $cache' in source
    assert "'-fno-builtin', '-fno-modules', $input, '-o', $proxy" in source
    retirement = values['docs/audits/native-proxy-runtime-retirement-20260910/PrivateWorkspace.pm'].decode()
    limits = {name:int(raw.replace('_','')) for name,raw in re.findall(r'my \$(NODE_LIMIT|DEPTH_LIMIT|TOTAL_LIMIT) = ([0-9_]+);',retirement)}
    assert limits == dict(NODE_LIMIT=256,DEPTH_LIMIT=8,TOTAL_LIMIT=4194304)
    assert '_source("$ROOT/$path", $mode, 65_536)' in retirement
    limits['FILE_LIMIT']=65536
    assert 'Inactive qualification ceilings, not measured compiler-workspace capacity.' in retirement
    profiles=[]

    def profile(label,prepared,archive,workspace=None):
        assert prepared['schema']=='fsmgen.test.rust_proxy_fixture.v1'
        assert prepared['ok']==1 and prepared['implementation']=='native' and prepared['status']=='success'
        assert prepared['failure_stage'] is None and prepared['selection_reason']=='darwin_arm64_command_line_tools'
        compiler=prepared['compilation']
        assert compiler['schema']=='fsmgen.test.rust_proxy_compilation.v1'
        assert compiler['ok']==1 and compiler['exit_code']==compiler['signal']==0
        assert compiler['timed_out']==compiler['output_limited']==0
        assert compiler['timeout_seconds']==10 and compiler['capture_limit_bytes']==4096
        assert all(compiler['cleanup'][k]==1 for k in ['leader_started','leader_reaped','group_gone'])
        selected=prepared['sources']; assert len(selected)==2
        assert [Path(s['path']).name for s in selected]==['rustup.c','rustup']
        assert prepared['executable']==selected[1]['path']
        root=str(Path(selected[1]['path']).parents[1])
        assert re.fullmatch(r'\.artifacts/tmp/process-supervisor-tests/fsmgen-[A-Za-z0-9_]+',root)
        if workspace is not None:
            assert set(workspace)=={'path','device','inode'} and workspace['path']==root
        for s in selected:
            assert set(s)=={'path','device','inode','size_bytes','sha256'}
            raw=archive(s)
            assert len(raw)==s['size_bytes'] and digest(raw)==s['sha256']
            assert s['device']>0 and s['inode']>0
        if 'compilation_argv' in prepared:
            argv=prepared['compilation_argv']
            assert len(argv)==16 and argv[-3:]==[selected[0]['path'],'-o',selected[1]['path']]
        assert not any(k in prepared for k in ['nodes','workspace_census','file_bytes','max_depth'])
        profiles.append(dict(label=label,workspace=root,selected_sources=selected,
            selected_file_bytes=sum(s['size_bytes'] for s in selected),
            source_pair_within_file_bound=all(s['size_bytes']<=limits['FILE_LIMIT'] for s in selected),
            complete_membership=False,all_node_modes=False,max_depth=None,
            max_regular_file_bytes=None,aggregate_regular_file_bytes=None,
            compilation_arguments_retained='compilation_argv' in prepared))
        return root

    for epoch in ['native','native-final']:
        for mode in ['proxy_nonzero','proxy_decoy']:
            prefix=BUILDER+epoch+'/'+mode+'/'
            preparation=load(prefix+'preparation.json')
            root=profile('builder/'+epoch+'/'+mode,preparation,
                lambda s:values[prefix+Path(s['path']).name],load(prefix+'workspace.json'))
            qualification=load(prefix+'qualification.json')
            assert qualification['sources']==preparation['sources'] and qualification['workspace_removed'] is True
            assert qualification['original_T1669'] is False
    original_stderr=values[DAEMON+'test.stderr']
    original_audit=load(DAEMON+'independent-audit.json')
    assert original_audit['stderr']==dict(bytes=len(original_stderr),sha256=digest(original_stderr))
    preparations=[json.loads(line.split(b'Rust proxy preparation: ',1)[1])
                  for line in original_stderr.splitlines() if b'Rust proxy preparation: ' in line]
    assert [p['mode'] for p in preparations]==['proxy_nonzero','proxy_decoy']
    observations=[json.loads(line) for line in values[DAEMON+'observations.jsonl'].splitlines()]
    candidates=[r['evidence'] for r in observations if r['event']=='candidate' and r['evidence'].get('target_role')=='rust-proxy']
    assert len(candidates)==2
    for p in preparations:
        prepared=p['prepared']
        profile('daemon-original/'+p['mode'],prepared,lambda s:values[DAEMON+s['sha256']+'.source'])
        candidate=next(c for c in candidates if c['fixture']==prepared['executable'])
        observed={s['path']:s for s in candidate['sources']}
        assert len(observed)==3
        assert all(observed[s['path']]==s for s in prepared['sources'])
        assert candidate['ancestor']==original_audit['original_identity']
        assert candidate['child']['ppid']==candidate['parent']['pid']
    held=load(HARDLINK+'result/preparation.json')
    assert held['control']=='held_path_observation_only'
    profile('hardlink-held-control',held['prepared'],lambda s:values[HARDLINK+'result/sources/'+s['sha256']+'.source'],load(HARDLINK+'result/workspace-base.json'))
    # The earlier builder pin identifies the current producer, but its receipt
    # still projects only selected files. No compiler run is needed to show this.
    original_inputs=load(BUILDER+'native-final/inputs.json')
    builder_pin=original_inputs['t/lib/FSM/Test/RustProxyFixture.pm']
    assert builder_pin==dict(bytes=len(source.encode()),sha256=digest(source.encode()))
    driver=values['.artifacts/tmp/native-proxy-builder-20260910/native-final.py'].decode()
    assert "for identity in prepared['sources']:" in driver
    assert 'shutil.rmtree(path)' in driver and "'workspace_removed': True" in driver
    assert 'max_depth' not in driver and 'file_bytes' not in driver
    # Pure-data indistinguishability witnesses: each selected-source projection
    # is unchanged if unrecorded compiler storage violates a retirement rule.
    witnesses=[]
    selected=profiles[2]['selected_sources']
    for label,extra in [
        ('unrecorded_mode',dict(path='rust-tools/compiler-cache/extra',mode=0o644,size_bytes=1)),
        ('unrecorded_file_bound',dict(path='rust-tools/compiler-temp/extra',mode=0o600,size_bytes=limits['FILE_LIMIT']+1)),
        ('unrecorded_depth',dict(path='rust-tools/'+'nested/'*limits['DEPTH_LIMIT']+'extra',mode=0o600,size_bytes=1)),
        ('unrecorded_membership',dict(path='rust-tools/compiler-cache/extra',mode=0o600,size_bytes=1,count=limits['NODE_LIMIT']+1)),
        ('unrecorded_aggregate',dict(path='rust-tools/compiler-cache/extra',mode=0o600,size_bytes=limits['FILE_LIMIT'],count=limits['TOTAL_LIMIT']//limits['FILE_LIMIT']+1))]:
        assert extra['path'] not in {s['path'] for s in selected}
        projected=[node for node in [*selected,extra] if node['path'] in {s['path'] for s in selected}]
        assert projected==selected
        violations=dict(
            unrecorded_mode=extra['mode'] not in [0o400,0o500,0o600,0o700],
            unrecorded_file_bound=extra['size_bytes']>limits['FILE_LIMIT'],
            unrecorded_depth=len(Path(extra['path']).parts)>limits['DEPTH_LIMIT'],
            unrecorded_membership=extra.get('count',1)+len(selected)>limits['NODE_LIMIT'],
            unrecorded_aggregate=extra['size_bytes']*extra.get('count',1)+sum(s['size_bytes'] for s in selected)>limits['TOTAL_LIMIT'])
        assert violations[label]
        witnesses.append(dict(label=label,unrecorded_node=extra,selected_projection_sha256=digest(json.dumps(selected,sort_keys=True).encode()),
                              meaning='Hypothetical data only; not observed compiler behavior.'))
    return dict(source_revision=PLAN['source_revision'],profiles=profiles,limits=limits,
        incomplete_projection_witnesses=witnesses,producer_has_complete_census_transport=False,
        authentic_complete_workspace_profile_found=False,scope=PLAN['search_scope'],
        fresh_compiler_admission_required=True,new_execution=False)


def controls(values,result):
    rejected=[]
    path=BUILDER+'native-final/proxy_nonzero/preparation.json'
    for label,mutation in [
        ('missing_selected_source',lambda p:p['sources'].pop()),
        ('promoted_census_field',lambda p:p.update(workspace_census={})),
        ('unsettled_compiler',lambda p:p['compilation']['cleanup'].update(group_gone=0)),
        ('synthetic_implementation',lambda p:p.update(implementation='perl'))]:
        changed=dict(values); data=json.loads(changed[path]);mutation(data);changed[path]=json.dumps(data).encode()
        try: evaluate(changed)
        except (AssertionError,KeyError,IndexError):rejected.append(label)
        else:raise AssertionError('accepted altered evidence: '+label)
    for label,path,body in [
        ('changed_archived_image',BUILDER+'native-final/proxy_nonzero/rustup',b'changed'),
        ('widened_retirement_limit','docs/audits/native-proxy-runtime-retirement-20260910/PrivateWorkspace.pm',None)]:
        changed=dict(values)
        changed[path]=body if body is not None else changed[path].replace(b'$NODE_LIMIT = 256;',b'$NODE_LIMIT = 257;')
        try:evaluate(changed)
        except (AssertionError,KeyError,IndexError):rejected.append(label)
        else:raise AssertionError('accepted altered evidence: '+label)
    for field in ['authentic_complete_workspace_profile_found','producer_has_complete_census_transport','new_execution']:
        changed=copy.deepcopy(result);changed[field]=True
        assert changed!=evaluate(values)
        rejected.append('promoted_'+field)
    return rejected


def main():
    parser=argparse.ArgumentParser()
    group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true')
    args=parser.parse_args()
    values,retained=inputs(None if args.retain else json.loads((BASE/'retained-inputs.json').read_bytes()))
    if args.retain:
        save(BASE/'retained-inputs.json',retained)
    result=evaluate(values)
    rejected=controls(values,result)
    report=dict(owner=PLAN['owner'],input_files=len(values),input_bytes=sum(map(len,values.values())),
        retained_only_inputs=len(retained),retained_input_sha256=digest((BASE/'retained-inputs.json').read_bytes()),
        result=result,rejected_controls=rejected)
    if args.retain:save(BASE/'review.json',report)
    else:assert report==json.loads((BASE/'review.json').read_bytes())
    print(json.dumps(dict(profiles=len(result['profiles']),complete_workspace_profiles=0,
        hypothetical_missing_profile_witnesses=len(result['incomplete_projection_witnesses']),
        rejected_controls=len(rejected),fresh_compiler_admission_required=True,new_execution=False),sort_keys=True))


if __name__=='__main__':
    main()
