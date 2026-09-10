"""Read-only and modeled admission checks; no original or collector is allowed."""
import ast
import copy
import json
import os
from pathlib import Path
import runpy
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[3]
assert os.environ.get('FSMGEN_RAM_GUARD_ACTIVE')=='1'
BASE=ROOT/'.artifacts/tmp/native-proxy-daemon-original-20260910'
ns=runpy.run_path(str(BASE/'run.py'),run_name='admission_definition')
function_globals=ns['load_plan'].__globals__
plan,plan_identity=ns['load_plan']()
expected_bounds={'original_seconds':200,'original_output_bytes_per_file':16777216,
    'ready_seconds':10,'exec_seconds':5,'original_reap_seconds':2,
    'collector_start_seconds':10,'collector_seconds':240,'collector_reap_seconds':2,
    'collector_output_bytes_per_file':16777216,'fixture_settle_seconds':12,
    'journal_events':4096,'journal_event_bytes':16384,'journal_bytes':16777216,
    'source_files':64,'source_bytes':4194304}
assert plan['bounds']==expected_bounds
source=(BASE/'run.py').read_text(); tree=ast.parse(source)
main=next(node for node in tree.body if isinstance(node,ast.FunctionDef) and node.name=='main')
main_calls=[node for node in ast.walk(main) if isinstance(node,ast.Call)]
assert sum(isinstance(node.func,ast.Attribute) and node.func.attr=='run_path' for node in main_calls)==1
assert any(isinstance(node.func,ast.Name) and node.func.id=='verify_committed_plan' for node in main_calls)
rejected=[]

def rejects(label, operation, kind=ValueError):
    try:
        operation()
    except kind:
        rejected.append(label)
    else:
        raise AssertionError('control failed to reject '+label)


class FakeGate:
    constructions=0
    def __init__(self,*args,**kwargs):
        type(self).constructions+=1
        self.pid=101
        self.identity={'pid':101,'identity_kind':'modeled_only'}
        self.released=False
    def release(self,prepare):
        ready=prepare()
        self.released=True
        return {'pid':self.pid,'ready_ns':ready,'execution':'modeled_only'}


def changed_release(factory):
    changing={'changed':False}; receipts=[]; callbacks=[]
    def check():
        if changing['changed']:
            raise ValueError('admitted inputs changed')
    gate,state=factory(FakeGate,check,lambda name,value:receipts.append((name,value)))
    child=gate(None,ROOT,BASE)
    changing['changed']=True
    rejects('changed_inputs_before_release',lambda:child.release(lambda:callbacks.append('prepare') or 7))
    assert not child.released and not callbacks
    assert [name for name,_ in receipts]==['original-reservation-attempt.json','original-identity.json']
    assert state['constructor_attempts']==state['release_attempts']==1


with patch.object(ns['launch'],'GatedTest',side_effect=AssertionError('real original forbidden')) as original, \
        patch.object(ns['launch'].policy_log,'PolicyLog',side_effect=AssertionError('real collector forbidden')) as collector, \
        patch.object(ns['observer'],'Evidence',side_effect=AssertionError('real evidence forbidden')) as evidence:
    ns['verify_inputs'](plan)
    for label,modify in [
        ('driver_digest',lambda p:p['driver'].update(sha256='0'*64)),
        ('scope',lambda p:p.update(scope='execution_context')),
        ('count',lambda p:p.update(original_limit=2)),
        ('boolean_count',lambda p:p.update(original_limit=True)),
        ('bounds',lambda p:p['bounds'].update(original_seconds=201)),
        ('entrypoint',lambda p:p.update(entrypoint='scripts/run_fixture_startup_policy_observation.py')),
    ]:
        changed=copy.deepcopy(plan);modify(changed)
        path=BASE/(label+'-plan.json')
        with path.open('x') as stream:json.dump(changed,stream)
        function_globals['PLAN_PATH']=path
        rejects(label,ns['load_plan'])
    function_globals['PLAN_PATH']=BASE/'admission.json'
    for label in ('source_pin','machine','compiler_digest','sdk_inode'):
        changed=copy.deepcopy(plan)
        if label=='source_pin':
            changed['source_pins'][next(iter(changed['source_pins']))]['sha256']='0'*64
        elif label=='machine':changed['host_selection_inputs']['machine']='unqualified'
        elif label=='compiler_digest':changed['host_selection_inputs']['compiler']['sha256']='0'*64
        else:changed['host_selection_inputs']['sdk']['inode']=0
        rejects(label,lambda:ns['verify_inputs'](changed))
    saved={'run.py':(BASE/'run.py').read_bytes(),'admission.json':(BASE/'admission.json').read_bytes()}
    def committed(argv,**kwargs):
        assert argv[:2]==['git','show'] and argv[2].startswith('HEAD:'+ns['DURABLE']+'/')
        return saved[argv[2].rsplit('/',1)[-1]]
    with patch.object(ns['subprocess'],'check_output',side_effect=committed):
        ns['verify_committed_plan']()
        saved['admission.json']+=b' '
        rejects('changed_committed_plan',ns['verify_committed_plan'])
    events=[]
    gate,state=ns['make_gate'](FakeGate,lambda:events.append('check'),lambda n,v:events.append(n))
    child=gate(None,ROOT,BASE)
    witness=child.release(lambda:events.append('prepare') or 7)
    assert witness=={'pid':101,'ready_ns':7,'execution':'modeled_only'}
    assert events==['original-reservation-attempt.json','check','original-identity.json','check',
                    'prepare','release-admitted.json','release.json']
    rejects('second_constructor',lambda:gate(None,ROOT,BASE))
    rejects('second_release',lambda:child.release(lambda:8))
    assert state['constructor_attempts']==state['release_attempts']==1
    changed_release(ns['make_gate'])
    factory=next(node for node in tree.body if isinstance(node,ast.FunctionDef) and node.name=='make_gate')
    fragment=ast.get_source_segment(source,factory)
    needle='                check()\n                ready = prepare()'
    assert fragment.count(needle)==1
    mutant={}
    exec(compile(fragment.replace(needle,'                ready = prepare()'),str(BASE/'run.py'),'exec'),mutant)
    rejects('removed_release_check',lambda:changed_release(mutant['make_gate']),AssertionError)
    # Shared no-follow reader plus metadata checks preserve repository locality.
    local=BASE/'bounded-control';local.write_bytes(b'abcd')
    assert ns['bounded_bytes'](local,4)==b'abcd'
    rejects('oversized_local_input',lambda:ns['bounded_bytes'](local,3))
    link=BASE/'bounded-link';link.symlink_to(local.name)
    rejects('symlink_local_input',lambda:ns['bounded_bytes'](link,4))
    link.unlink();local.unlink()
    ns['verify_inputs'](plan)
    original.assert_not_called();collector.assert_not_called();evidence.assert_not_called()
assert not ns['OUT'].exists()
report={'schema':'fsmgen.native_proxy_daemon_admission_preflight.v1','plan':plan_identity,
        'driver':plan['driver'],'source_count':len(plan['source_pins']),'bounds_equal_fixed_literals':True,
        'rejected_controls':rejected,'modeled_constructor_and_release':True,
        'committed_checkpoint_test':'modeled read before commit; real read required after commit and by driver',
        'actual_capsule_absent':True,'original_launched':False,'collector_launched':False,
        'compiler_launched':False,'helper_launched':False}
(ROOT/'.artifacts/logs/native-proxy-daemon-admission-20260910/preflight.json').write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
print(json.dumps(report,sort_keys=True))
