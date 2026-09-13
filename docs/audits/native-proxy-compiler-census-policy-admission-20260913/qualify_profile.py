"""Pure data and mocked filesystem controls; never allocates a profile workspace."""
import ast
import copy
import hashlib
import json
import os
from pathlib import Path
from unittest.mock import patch

import admission
import profile_files as files
import review_profile as review
import source_contract

PLAN = admission.PLAN


def model():
    rows = [dict(event='start', selection=PLAN['selection'], compiler_invocations=0)]
    independent = {}
    for index, case in enumerate(PLAN['cases']):
        root = case['workspace']
        nodes = []
        def node(suffix, kind, mode, raw=None, target=None):
            row = dict(kind=kind, identity=dict(path=root+suffix, device=17, inode=100+len(nodes), mode=mode, uid=501))
            if raw is not None: row['bytes'] = raw.decode('latin1')
            if target is not None: row['target'] = target
            nodes.append(row)
        node('', 'directory', 0o700)
        node('/rust-tools', 'directory', 0o700)
        node('/rust-tools/compiler-cache', 'directory', 0o700)
        node('/rust-tools/compiler-temp', 'directory', 0o700)
        node('/rust-tools/rustup.c', 'file', 0o400, bytes.fromhex(case['generated_c']['bytes_hex']))
        before = copy.deepcopy(nodes)
        node('/rust-tools/rustup', 'file', 0o500, b'in-memory image placeholder; never native evidence')
        native = copy.deepcopy(nodes)
        node('/rust-tool-resolution', 'file', 0o755, bytes.fromhex(PLAN['wrapper']['bytes_hex']))
        node('/rust-tools/cargo', 'symlink', 0o755, target='rustup')
        current = {}
        for item in nodes:
            p = item['identity']['path']
            row = dict(kind=item['kind'], links=1, **{k:v for k,v in item['identity'].items() if k!='path'})
            if item['kind'] == 'file':
                raw = item['bytes'].encode('latin1'); row.update(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
            if item['kind'] == 'symlink': row['target'] = item['target']
            if item['kind'] == 'directory': row['links'] = 2
            current[p] = row
        independent[root] = current
        result = dict(schema='fsmgen.test.rust_proxy_compilation.v1', stage='compile_proxy', ok=1, status='success',
            exit_code=0, signal=0, timeout_seconds=10, capture_limit_bytes=4096, timed_out=0, output_limited=0,
            exec_failed=0, started_monotonic_ns=1, exec_handoff_monotonic_ns=2, finished_monotonic_ns=3,
            stdout='', stdout_bytes=0, stderr='', stderr_bytes=0,
            cleanup=dict(containment='rust_proxy_compiler_group',leader_started=1,leader_reaped=1,group_gone=1,surviving_descendants=0))
        receipt = dict(state_observed=1,settled=1,leader_reaped=1,original_result_equal=1,raw_result_equal=1,
            phase='finished',pid=73+index,native_wait_status=0,result=result)
        prepared = dict(ok=1,status='success',implementation='native',selection_reason=PLAN['selection']['reason'],
            compilation=result,executable=root+'/rust-tools/rustup',sources=[dict(path=p,**{k:current[p][k]
            for k in ['device','inode','size_bytes','sha256']}) for p in [root+'/rust-tools/rustup.c',root+'/rust-tools/rustup']],
            compilation_argv=[PLAN['selection']['compiler'],'--no-default-config','-isysroot',PLAN['selection']['sdk'],
                '-arch','arm64','-mmacosx-version-min=11.0','-O2','-Wall','-Wextra','-Werror','-fno-builtin','-fno-modules',
                root+'/rust-tools/rustup.c','-o',root+'/rust-tools/rustup'])
        total = lambda ns: sum(len(n['bytes'].encode('latin1')) for n in ns if n['kind']=='file')
        rows.extend([dict(event='workspace_intent',workspace=root,mode=case['mode']),
            dict(event='workspace_owned',workspace=root,node=nodes[0]),
            dict(event='before_compiler',workspace=root,capture=dict(ok=1,error='',nodes=before,file_bytes=total(before))),
            dict(event='compiler_settled',workspace=root,receipt=receipt),
            dict(event='prepared',workspace=root,result=prepared),
            dict(event='compiler_profile',workspace=root,ok=1,error='',nodes_count=len(native),
                nodes_sha256=admission.digest(json.dumps(review.projection(native),sort_keys=True,
                    ensure_ascii=True,separators=(',', ':')).encode()),file_bytes=total(native)),
            dict(event='controlled_roles_intent',workspace=root),
            dict(event='complete_profile',workspace=root,capture=dict(ok=1,error='',nodes=nodes,file_bytes=total(nodes)))])
    rows.append(dict(event='finished',compiler_invocations=2,proxy_invocations=0,wrapper_invocations=0))
    for i,row in enumerate(rows,1):row['sequence']=i
    return rows, independent


def rejects(name, call, results):
    try: call()
    except (AssertionError, ValueError, KeyError, FileNotFoundError): results.append(name)
    else: raise AssertionError('accepted altered model: '+name)


def qualify():
    rows, independent = model()
    assert review.validate(rows, independent)['compiler_invocations'] == 2
    rejected=[]; root=PLAN['cases'][0]['workspace']
    for name, mutate in [
        ('missing_event',lambda r,n:r.pop(3)),
        ('reordered_event',lambda r,n:r.reverse()),
        ('unsettled',lambda r,n:r[4]['receipt'].update(settled=0)),
        ('wait_mismatch',lambda r,n:r[4]['receipt'].update(native_wait_status=2304)),
        ('capture_overflow',lambda r,n:r[4]['receipt']['result'].update(output_limited=1)),
        ('compiler_wall_changed',lambda r,n:r[4]['receipt']['result'].update(timeout_seconds=11)),
        ('native_invocation_promoted',lambda r,n:r[-1].update(proxy_invocations=1)),
        ('wrapper_invocation_promoted',lambda r,n:r[-1].update(wrapper_invocations=1)),
        ('compiler_argv_changed',lambda r,n:r[5]['result']['compilation_argv'].append('-changed')),
        ('missing_membership',lambda r,n:n[root].pop(root+'/rust-tools/compiler-cache')),
        ('changed_identity',lambda r,n:n[root][root+'/rust-tools/rustup'].update(inode=999)),
        ('changed_mode',lambda r,n:n[root][root+'/rust-tools/rustup'].update(mode=0o755)),
        ('changed_file_bytes',lambda r,n:r[8]['capture']['nodes'][5].update(bytes='changed')),
        ('file_alias',lambda r,n:n[root][root+'/rust-tools/rustup'].update(links=2)),
        ('link_target_changed',lambda r,n:n[root][root+'/rust-tools/cargo'].update(target='elsewhere')),
        ('partial_capture',lambda r,n:r[8]['capture'].update(ok=0)),
        ('aggregate_changed',lambda r,n:r[8]['capture'].update(file_bytes=0)),
        ('compiler_omitted_node',lambda r,n:r[6].update(nodes_count=0)),
        ('compiler_membership_hash',lambda r,n:r[6].update(nodes_sha256='0'*64)),
    ]:
        r,n=copy.deepcopy((rows,independent));mutate(r,n)
        rejects(name,lambda:review.validate(r,n),rejected)
    permit=admission.expected_permit('a'*40,'b'*64)
    admission.validate_permit(copy.deepcopy(permit),permit)
    for key,value in [('admission_revision','c'*40),('implementation_pins_sha256','d'*64),
        ('plan_sha256','e'*64),('uid',0),('device',0),('reusable',True),('native_proxy_execution',True),
        ('wrapper_execution',True),('cases',[]),('compiler',{}),('output','elsewhere')]:
        changed=copy.deepcopy(permit);changed[key]=value
        rejects('permit_'+key,lambda:admission.validate_permit(changed,permit),rejected)
    changed=dict(permit,extra_authority=True)
    rejects('permit_extra_field',lambda:admission.validate_permit(changed,permit),rejected)
    virtual=copy.deepcopy(independent[root])
    names=lambda path:sorted(Path(p).name for p in virtual if str(Path(p).parent)==path)
    assert files.walk(root,get_node=lambda p:copy.deepcopy(virtual[p]),list_names=names)==virtual
    rejects('duplicate_membership',lambda:files.walk(root,get_node=lambda p:virtual[p],list_names=lambda p:['x','x']),rejected)
    rejects('escape_membership',lambda:files.walk(root,get_node=lambda p:virtual[p],list_names=lambda p:['..']),rejected)
    rejects('other_root',lambda:files.walk(root+'_extra',get_node=lambda p:virtual[p],list_names=names),rejected)
    directory=dict(kind='directory',device=17,inode=100,mode=0o700,uid=501,links=2)
    rejects('depth_ceiling',lambda:files.walk(root,get_node=lambda p:directory,list_names=lambda p:['deeper']),rejected)
    rejects('node_ceiling',lambda:files.walk(root,get_node=lambda p:directory,
        list_names=lambda p:sorted(str(i) for i in range(256)) if p==root else []),rejected)
    oversized=dict(kind='file',device=17,inode=101,mode=0o400,uid=501,links=1,
        size_bytes=PLAN['evidence_limits']['total_file_bytes']+1,sha256='0'*64)
    rejects('per_file_ceiling',lambda:files.walk(root,get_node=lambda p:directory if p==root else oversized,
        list_names=lambda p:['large']),rejected)
    rejects('aggregate_ceiling',lambda:files.walk(root,get_node=lambda p:directory if p==root else dict(oversized,size_bytes=65536),
        list_names=lambda p:sorted(str(i) for i in range(65))),rejected)
    reads=[]
    def changing_names(path):
        reads.append(path)
        return [] if len(reads)==1 else ['appeared']
    rejects('membership_changes_during_walk',lambda:files.walk(root,get_node=lambda p:directory,
        list_names=changing_names),rejected)
    events=[]
    def remove(path,kind):
        assert path in virtual and not any(p.startswith(path+'/') for p in virtual)
        del virtual[path]
        # Model the expected directory link-count changes without relaxing any
        # inode, owner, mode, file identity or remaining membership requirement.
        for n in virtual.values():
            if n['kind']=='directory':n['links']+=1
    assert review.remove_exact(root,independent[root],capture=lambda p:copy.deepcopy(virtual),remove=remove,record=events.append)==8
    assert not virtual and len(events)==16
    virtual=copy.deepcopy(independent[root]);virtual[root+'/rust-tools/rustup']['inode']+=1
    calls=[]
    rejects('replaced_before_cleanup',lambda:review.remove_exact(root,independent[root],capture=lambda p:virtual,
            remove=lambda *args:calls.append(args),record=events.append),rejected)
    assert not calls
    virtual=copy.deepcopy(independent[root]);calls=[]
    def add_after_removal(path,kind):
        calls.append(path);del virtual[path]
        virtual[root+'/unexpected']=dict(oversized,size_bytes=1)
    rejects('addition_during_cleanup',lambda:review.remove_exact(root,independent[root],
        capture=lambda p:copy.deepcopy(virtual),remove=add_after_removal,record=events.append),rejected)
    assert len(calls)==1
    # Before any admission commit, the actual source gate must reject using
    # saved task data. Git is mocked; this creates no permit or subprocess.
    with patch.object(admission,'git',side_effect=lambda *args: b'a'*40 if args[0]=='log' else
         ('- ID: `'+PLAN['owner']+'`\n  Status: `active`\n').encode()), \
         patch.object(admission,'local_file',return_value=b'[]'):
        rejects('admission_still_active',admission.sources,rejected)
    # Compare the actual predecessor function with the repaired command builder,
    # trapping subprocess execution and supplying an unrelated caller Git env.
    previous=admission.BASE.parent/'native-proxy-compiler-census-admission-20260913/admission.py'
    function=next(n for n in ast.parse(previous.read_bytes()).body if isinstance(n,ast.FunctionDef) and n.name=='git')
    namespace=dict(ROOT=admission.ROOT,subprocess=admission.subprocess)
    exec(compile(ast.Module(body=[function],type_ignores=[]),str(previous),'exec'),namespace)
    calls=[]
    def record(*args,**kwargs):
        calls.append((copy.deepcopy(args),copy.deepcopy(kwargs)))
        return b'model git output'
    args=['status','--porcelain=v1','-z']
    with patch.object(admission.subprocess,'check_output',side_effect=record), \
         patch.dict(os.environ,{'GIT_DIR':'.artifacts/model-wrong-repository',
                                'GIT_CONFIG_GLOBAL':'.artifacts/model-personal-config'}):
        assert namespace['git'](*args)==admission.git(*args)==b'model git output'
    expected=(([ '/usr/bin/git','-c','core.excludesFile=.gitignore',*args],),dict(cwd=admission.ROOT,
        env=dict(PATH='/usr/bin:/bin',LC_ALL='C',LANG='C',TMPDIR=str(admission.ROOT/'.artifacts/tmp'))))
    assert len(calls)==2 and calls[0]!=expected and calls[1]==expected
    rejected.append('original_ambient_git_request')
    for name, mutate in [
        ('git_binary_changed',lambda v:v[0][0].__setitem__(0,'git')),
        ('git_personal_ignore',lambda v:v[0][0].__setitem__(2,'core.excludesFile=.artifacts/model-personal-ignore')),
        ('git_ambient_override',lambda v:v[1]['env'].update(GIT_DIR='.artifacts/model-wrong-repository')),
        ('git_temporary_fallback',lambda v:v[1]['env'].pop('TMPDIR')),
        ('git_other_repository',lambda v:v[1].update(cwd=admission.ROOT/'.artifacts/model-wrong-repository')),
    ]:
        changed=copy.deepcopy(calls[1]);mutate(changed)
        assert changed!=expected
        rejected.append(name)
    source=source_contract.qualify((admission.ROOT/'t/1669-task-acceptance-fixture-runtime.t').read_bytes())
    return dict(scope='in-memory and mocked I/O only; no actual compiler profile or capacity proof',
        model_events=len(rows),successful_model_cleanup_events=16,all_model_cleanup_events=len(events),
        rejected_controls=rejected,wrapper_source=source,git_request_model_calls=2,
        compiler_invocations=0,fixture_allocations=0)


if __name__=='__main__':
    # Any accidental runtime call must fail even if the model would otherwise
    # accept it. Source reads and stdout are the only real I/O used here.
    with patch('os.mkdir',side_effect=AssertionError('forbidden real mkdir')), \
         patch('os.unlink',side_effect=AssertionError('forbidden real unlink')), \
         patch('os.rmdir',side_effect=AssertionError('forbidden real rmdir')), \
         patch('os.kill',side_effect=AssertionError('forbidden real signal')), \
         patch('subprocess.Popen',side_effect=AssertionError('forbidden real subprocess')):
        print(json.dumps(qualify(),sort_keys=True,indent=2))
