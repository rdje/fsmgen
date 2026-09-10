"""Independent inert admission checks. Never execute the admitted experiment."""
import copy
import errno
import inspect
import json
import os
from pathlib import Path
import runpy
import struct
import tempfile
import textwrap
from types import SimpleNamespace
from unittest.mock import patch

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
assert os.environ.get('FSMGEN_RAM_GUARD_ACTIVE') == '1'
ns = runpy.run_path(str(BASE / 'run.py'), run_name='inert_definitions')
g = ns['load_plan'].__globals__
E = ns['Experiment']
plan, plan_pin = ns['load_plan']()
ns['verify_inputs'](plan)
live_out, live_workspaces = ns['OUT'], ns['WORKSPACES']
assert not live_out.exists() and all(not p.exists() for p in live_workspaces.values())
expected_bounds = {'preparation_owner_seconds':40, 'native_owner_seconds':10,
    'owner_output_bytes_per_file':65536, 'native_control_limit':2,
    'preparation_owner_limit':1, 'collector_limit':1, 'original_limit':0,
    'ready_seconds':10, 'reap_seconds':2, 'compiler_seconds':10,
    'compiler_capture_bytes':4096, 'collector_start_seconds':10,
    'collector_seconds':240, 'collector_reap_seconds':2,
    'collector_output_bytes_per_file':16777216,
    'native_path_observation_seconds':5, 'held_body_seconds':1}
assert plan['bounds'] == expected_bounds
rejected, qualified = [], []


def rejects(label, operation, kind=ValueError):
    try:
        operation()
    except kind:
        rejected.append(label)
    else:
        raise AssertionError('did not reject ' + label)


def record(_name, _value):
    pass


with patch.object(os, 'fork', side_effect=AssertionError('real fork forbidden')) as fork, \
        patch.object(ns['subprocess'], 'Popen', side_effect=AssertionError('real subprocess forbidden')) as process, \
        patch.object(ns['observer'], 'Processes', side_effect=AssertionError('real process observer forbidden')) as native_constructor, \
        patch.object(ns['launch'], 'GatedTest', side_effect=AssertionError('real owner forbidden')) as owner_constructor, \
        patch.object(ns['launch'].policy_log, 'PolicyLog', side_effect=AssertionError('real collector forbidden')) as collector_constructor, \
        tempfile.TemporaryDirectory(prefix='inert-', dir=BASE) as temporary:
    tmp = Path(temporary)
    # Closed admission and exact input/toolchain changes reject before any owner.
    for label, modify in [
        ('extra_key', lambda p:p.update(extra=True)),
        ('scope', lambda p:p.update(scope='execution_context')),
        ('role_order', lambda p:p.update(roles=['prepare','b','a'])),
        ('original_limit', lambda p:p['bounds'].update(original_limit=1)),
        ('boolean_limit', lambda p:p['bounds'].update(collector_limit=True)),
        ('compiler_wall', lambda p:p['bounds'].update(compiler_seconds=11)),
        ('producer', lambda p:p['producers']['held.c'].update(sha256='0'*64)),
        ('workspace', lambda p:p['workspaces'].update(a='elsewhere')),
        ('control_kind', lambda p:p.update(control='original')),
        ('scope_claim', lambda p:p['limitations'].update(scan_avoidance='proved')),
    ]:
        changed = copy.deepcopy(plan)
        modify(changed)
        original_read = ns['read']
        def changed_read(path, limit=ns['SOURCE_LIMIT']):
            return json.dumps(changed).encode() if path == BASE / 'admission.json' else original_read(path, limit)
        with patch.dict(g, read=changed_read):
            rejects(label, ns['load_plan'])
    with patch.dict(g, source_pins=lambda:plan['source_pins'], selection_context=lambda:plan['selection_context']):
        for label in ('source', 'compiler', 'sdk'):
            changed = copy.deepcopy(plan)
            if label == 'source':
                changed['source_pins'][next(iter(changed['source_pins']))]['sha256'] = '0'*64
            elif label == 'compiler':
                changed['selection_context']['compiler']['sha256'] = '0'*64
            else:
                changed['selection_context']['sdk']['inode'] += 1
            rejects('changed_' + label, lambda:ns['verify_inputs'](changed))
    rejects('scratch_execution', ns['verify_committed'])
    saved = {name:(BASE / name).read_bytes() for name in (*ns['PRODUCERS'], 'admission.json')}
    durable = ROOT / ns['DURABLE']
    def git_read(argv, **_kwargs):
        assert argv[:2] == [ns['GIT'], 'show'] and argv[2].startswith('HEAD:' + ns['DURABLE'] + '/')
        return saved[argv[2].rsplit('/', 1)[-1]]
    def disk_read(path, _limit=ns['SOURCE_LIMIT']):
        assert path.parent == durable
        return (BASE / path.name).read_bytes()
    with patch.dict(g, BASE=durable, read=disk_read), patch.object(ns['subprocess'], 'check_output', side_effect=git_read):
        ns['verify_committed']()
        saved['held.c'] += b' '
        rejects('changed_committed_control', ns['verify_committed'])
    qualified.append('closed_plan_and_committed_byte_witness')

    # Real local files and hard links, containing inert model bytes only.
    spaces = {name:tmp / name for name in ('base','a','b')}
    with patch.dict(g, WORKSPACES=spaces):
        exp = E(plan, None, record)
        base = exp.workspace('base')
        tools = base / 'rust-tools'
        tools.mkdir(mode=0o700)
        (tools / 'compiler-temp').mkdir(mode=0o700)
        (tools / 'compiler-cache').mkdir(mode=0o700)
        c_file, executable = tools / 'rustup.c', tools / 'rustup'
        c_file.write_bytes(b'#define PROXY_NONZERO 1\n' + (BASE / 'held.c').read_bytes())
        c_file.chmod(0o400)
        executable.write_bytes(struct.pack('<IIII',0xfeedfacf,0x0100000c,0,2) + b'INERT MODEL ONLY!')
        executable.chmod(0o500)
        c_id = ns['source_identity'](c_file,0o400)[0]
        b_id = ns['source_identity'](executable,0o500)[0]
        ctx = plan['selection_context']
        prepared = {'schema':'fsmgen.test.rust_proxy_fixture.v1','ok':1,'implementation':'native',
            'status':'success','failure_stage':None,'sources':[c_id,b_id],
            'executable':ns['relative'](executable),
            'compilation_argv':[ctx['compiler']['path'],'--no-default-config','-isysroot',ctx['sdk']['path'],
                '-arch','arm64','-mmacosx-version-min=11.0','-O2','-Wall','-Wextra','-Werror',
                '-fno-builtin','-fno-modules',ns['relative'](c_file),'-o',ns['relative'](executable)],
            'compilation':{'schema':'fsmgen.test.rust_proxy_compilation.v1','status':'success',
                'ok':1,'exit_code':0,'signal':0,'timed_out':0,'output_limited':0,
                'exec_failed':0,'exec_error':None,'timeout_seconds':10,'capture_limit_bytes':4096,
                'cleanup':{'leader_started':1,'leader_reaped':1,'group_gone':1,
                    'containment':'rust_proxy_compiler_group','surviving_descendants':0}}}
        envelope = {'schema':'fsmgen.hardlink_control_preparation.v1','control':'held_path_observation_only',
            'prepared':prepared,'original_source_sha256':ns['pin']((ROOT / 't/fixtures/rust-tool-proxy.c').read_bytes())['sha256'],
            'control_source_sha256':ns['pin']((BASE / 'held.c').read_bytes())['sha256']}
        exp.sources = ns['validate_preparation'](envelope,base,ctx)
        for label, modify in [
            ('incomplete_cleanup',lambda p:p['compilation']['cleanup'].update(group_gone=0)),
            ('boolean_cleanup',lambda p:p['compilation']['cleanup'].update(leader_reaped=True)),
            ('compiler_arguments',lambda p:p['compilation_argv'].append('-DCHANGED')),
            ('source_inode',lambda p:p['sources'][0].update(inode=0)),
            ('compile_timeout',lambda p:p['compilation'].update(timed_out=1)),
            ('compiler_descendant',lambda p:p['compilation']['cleanup'].update(surviving_descendants=1)),
        ]:
            changed = copy.deepcopy(envelope)
            modify(changed['prepared'])
            rejects(label, lambda:ns['validate_preparation'](changed,base,ctx))
        executable.chmod(0o700)
        rejects('changed_permissions', lambda:ns['validate_preparation'](envelope,base,ctx))
        executable.chmod(0o500)
        good_source = c_file.read_bytes()
        c_file.chmod(0o600)
        c_file.write_bytes(good_source.replace(b'sleep(1)',b'sleep(2)'))
        c_file.chmod(0o400)
        rejects('changed_held_body', lambda:ns['validate_preparation'](envelope,base,ctx))
        c_file.chmod(0o600)
        c_file.write_bytes(good_source)
        c_file.chmod(0o400)
        exp.bin_directories['base'] = ns['directory_identity'](tools)
        exp.compiler_settled = True
        exp.alias('a')
        exp.alias('b')
        assert executable.stat().st_nlink == 3
        # Native path oracle must reject even another valid link to the same inode.
        identity = {'pid':101,'test':'modeled_birth'}
        owner = SimpleNamespace(pid=101,identity=identity,poll=lambda:None)
        native = SimpleNamespace(identity=lambda _pid:identity,executable=lambda _pid:spaces['a']/'rust-tools/rustup')
        exp.native = native
        exp.observe_path('a',owner,'modeled-path')
        native.executable = lambda _pid:spaces['b']/'rust-tools/rustup'
        rejects('same_inode_wrong_native_path',lambda:exp.observe_path('a',owner,'wrong-path'))
        fragment = textwrap.dedent(inspect.getsource(E.observe_path))
        assert fragment.count('if executable != expected:') == 1
        mutant_globals = dict(g)
        exec(compile(fragment.replace('if executable != expected:', 'if False:'), '<inert-path-mutant>', 'exec'), mutant_globals)
        rejects('removed_native_path_guard',lambda:rejects('mutant_wrong_path',
            lambda:mutant_globals['observe_path'](exp,'a',owner,'mutant-path')),AssertionError)
        native.executable = lambda _pid:spaces['a']/'rust-tools/rustup'
        native.identity = lambda _pid:dict(identity,test='changed_birth')
        rejects('changed_native_birth',lambda:exp.observe_path('a',owner,'wrong-birth'))
        exp.results = {'a':{'leader_reaped':True},'b':{'leader_reaped':True}}
        exp.retire_alias('a')
        exp.verify_alias('b')
        assert executable.stat().st_nlink == 2
        exp.retire_alias('b')
        exp.retire_base()
        assert all(not p.exists() for p in spaces.values())
    qualified.append('inert_preparation_custody_alias_lifetime_and_native_path_oracle')

    class FakeGate:
        code = None
        constructor_failure = False
        def __init__(self, _native, _root, directory):
            self.pid, self.identity, self.status, self.released = 101, {'pid':101}, None, False
            self.deadline = 1
            self.cancelled = None
            self.argv = ns['launch'].TEST_ARGV
            self.expected = 0 if self.role == 'prepare' else 9
            assert ns['launch'].TEST_SECONDS == (40 if self.role == 'prepare' else 10)
            assert ns['launch'].OUTPUT_BYTES == 65536
            assert len(self.argv) == (2 if self.role == 'prepare' else 3)
            assert 't/1669-task-acceptance-fixture-runtime.t' not in self.argv
            (directory/'test.tap').write_bytes(b'{}' if self.role == 'prepare' else b'CONTROL_READY\n')
            (directory/'test.stderr').write_bytes(b'')
            if self.constructor_failure:
                raise ValueError('modeled constructor failed after ownership')
        def release(self, prepare):
            result = prepare()
            self.released = True
            return {'ready_ns':result,'modeled_only':True}
        def finish(self,cancel=False):
            self.cancelled = cancel
            code = self.expected if self.code is None else self.code
            self.status = code << 8
            return {'returncode':code,'native_wait_status':self.status,'timeout':False,
                'leader_reaped':True,'released':self.released}

    original_constants = (ns['launch'].TEST_ARGV,ns['launch'].TEST_SECONDS,ns['launch'].OUTPUT_BYTES)
    for scenario in ('success','changed_release','wrong_exit','constructor_failure','observation_failure'):
        out = tmp/scenario
        out.mkdir(mode=0o700)
        records = []
        exp = E(plan,None,lambda n,v:records.append(n))
        exp.collection = SimpleNamespace(check=lambda:None)
        exp.verify_alias = lambda _role:None
        def check(_plan):
            if scenario == 'changed_release':
                raise ValueError('inputs changed before release')
        with patch.dict(g,OUT=out,verify_inputs=check), patch.object(ns['launch'],'GatedTest',FakeGate), \
                patch.object(ns['observer'],'still_live',return_value=False), \
                patch.object(FakeGate,'code',7 if scenario == 'wrong_exit' else None), \
                patch.object(FakeGate,'constructor_failure',scenario == 'constructor_failure'):
            if scenario == 'success':
                for role in ('prepare','a','b'):
                    exp.run_owner(role)
                rejects('fourth_owner',lambda:exp.run_owner('b'))
            else:
                def observation(_owner,_directory):
                    raise ValueError('modeled observation failure')
                rejects(scenario,lambda:exp.run_owner('prepare',observation if scenario=='observation_failure' else None))
                assert len(exp.owners) == 1 and exp.owners[0].status is not None
                rejects(scenario+'_closes_admission',lambda:exp.run_owner('a'))
                assert len(exp.owners) == 1
                if scenario in ('changed_release','constructor_failure'):
                    assert exp.owners[0].cancelled is True and not exp.owners[0].released
                if scenario == 'constructor_failure':
                    assert 'owner-prepare-deferred-cleanup.json' in records
        assert (ns['launch'].TEST_ARGV,ns['launch'].TEST_SECONDS,ns['launch'].OUTPUT_BYTES) == original_constants
    qualified.append('actual_owner_wrapper_sequence_failure_latch_and_partial_constructor_cleanup')
    fragment = textwrap.dedent(inspect.getsource(E.ready))
    assert fragment.count('verify_inputs(self.plan)') == 1
    mutant_globals = dict(g)
    exec(compile(fragment.replace('verify_inputs(self.plan)', 'pass'), '<inert-release-mutant>', 'exec'), mutant_globals)
    def changed_inputs(_plan):
        raise ValueError('changed admitted input')
    exp = E(plan,None,record)
    with patch.dict(g,verify_inputs=changed_inputs):
        rejects('actual_release_rechecks_input',lambda:exp.ready('prepare'))
    rejects('removed_release_input_guard',lambda:rejects('mutant_changed_input',
        lambda:mutant_globals['ready'](exp,'prepare')),AssertionError)
    qualified.append('removed_release_and_native_path_checks_fail_independent_oracles')

    # Whole sequence: inject each first failure, require an exact executed prefix.
    sequence = ['prepare','collector_constructor','collector_prepare','readiness_record',
                'run_a','retire_a','verify_b','run_b','retire_b']
    for failure in [None,*sequence]:
        events=[]
        def step(name):
            events.append(name)
            if name == failure:
                raise ValueError('modeled first failure '+name)
        class FakePolicy:
            def __init__(self,*args,**kwargs):
                assert kwargs == {'scope':'daemon_context'}
                step('collector_constructor')
            def prepare(self):
                step('collector_prepare')
                return {'scope':'daemon_context'}
        exp = SimpleNamespace(native=None,prepare=lambda:step('prepare'),
            record=lambda n,v:step('readiness_record'),
            run_owner=lambda role,callback:step('run_'+role),
            retire_alias=lambda role:step('retire_'+role),
            verify_alias=lambda role:step('verify_'+role))
        out=tmp/('sequence-'+str(failure))
        out.mkdir(mode=0o700)
        with patch.dict(g,OUT=out),patch.object(ns['launch'].policy_log,'PolicyLog',FakePolicy):
            if failure is None:
                ns['execute_controls'](exp)
                assert events == sequence
            else:
                rejects('sequence_'+failure,lambda:ns['execute_controls'](exp))
                assert events == sequence[:sequence.index(failure)+1]
    qualified.append('first_failure_stops_all_later_sequence_steps')
    fork.assert_not_called()
    process.assert_not_called()
    native_constructor.assert_not_called()
    owner_constructor.assert_not_called()
    collector_constructor.assert_not_called()

ns['verify_inputs'](plan)
assert not live_out.exists() and all(not p.exists() for p in live_workspaces.values())
report = {'schema':'fsmgen.native_hardlink_preflight.v1','plan':plan_pin,
    'producers':plan['producers'],'source_count':len(plan['source_pins']),
    'bounds_match_independent_literals':True,'qualified_controls':qualified,
    'rejected_controls':rejected,'real_fork_attempts':0,'real_subprocess_attempts_in_controls':0,
    'original_invocations':0,'native_control_invocations':0,'collector_invocations':0,
    'compiler_invocations':0,'live_capsule_and_workspaces_absent':True,
    'committed_byte_verification':'modeled here; actual Git read required after commit',
    'native_hardlink_behavior':'unqualified; model files and native observations were inert'}
(BASE/'preflight.json').write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
print(json.dumps(report,sort_keys=True))
