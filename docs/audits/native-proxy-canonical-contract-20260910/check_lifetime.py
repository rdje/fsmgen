"""Finite lifetime-model check; no native, compiler, collector or filesystem lease runs."""
from collections import deque
import hashlib
import json
from pathlib import Path

BASE=Path(__file__).resolve().parent
FIELDS=('image','runtime_reference','runtime','observation_reference','observation','snapshot','workspace')
INITIAL=(True,False,'new',False,'new',False,True)


def successors(state,mutation):
    current=dict(zip(FIELDS,state))
    def changed(name,**values):
        result=dict(current,**values)
        return name,tuple(result[key] for key in FIELDS)
    if current['image'] and current['runtime']=='new':
        yield changed('prepare',runtime_reference=True,runtime='ready')
    if current['runtime']=='ready':
        yield changed('launch',runtime='live')
    if current['runtime']=='live':
        yield changed('runtime_finished',runtime='settled')
        if current['observation']=='new':
            yield changed('observation_admitted',observation='capturing',
                observation_reference=mutation!='missing_observation_reference',
                snapshot=mutation!='missing_source_snapshot')
    if current['runtime']=='settled' and current['runtime_reference']:
        yield changed('runtime_retired',runtime='retired',runtime_reference=False,workspace=False)
    if current['observation']=='capturing':
        yield changed('source_archived',observation='archived')
    if current['observation']=='archived':
        yield changed('capture_settled',observation='settled')
    if current['observation_reference'] and (current['observation']=='settled' or mutation=='early_observation_release'):
        yield changed('observation_reference_released',observation_reference=False)
    if current['image'] and not current['runtime_reference'] and (
            not current['observation_reference'] or mutation=='maintenance_ignores_observation'):
        yield changed('image_retired',image=False)


def violated(state):
    value=dict(zip(FIELDS,state))
    if value['runtime'] in ('ready','live') and not value['image']:
        return 'runtime lost its selected image'
    if value['observation'] in ('capturing','archived') and not value['image']:
        return 'unsettled observation lost its selected image'
    if value['observation'] in ('capturing','archived') and not value['workspace'] and not value['snapshot']:
        return 'private source retirement stranded observation custody'
    return None


def explore(mutation=None):
    queue=deque([(INITIAL,[])])
    seen={INITIAL}
    edges=0
    while queue:
        state,trace=queue.popleft()
        failure=violated(state)
        if failure:
            return {'failure':failure,'trace':trace,'state':dict(zip(FIELDS,state)),
                    'states_seen':len(seen),'transitions_examined':edges}
        for event,next_state in successors(state,mutation):
            edges+=1
            if next_state not in seen:
                seen.add(next_state)
                queue.append((next_state,trace+[event]))
    return {'failure':None,'states_seen':len(seen),'transitions_examined':edges}


contract_raw=(BASE/'contract.json').read_bytes()
contract=json.loads(contract_raw)
assert len(contract['observation_lifetime'])==5
assert contract['bounds']['image_entries']==32 and contract['bounds']['reference_entries']==128
assert contract['bounds']['compiler_seconds']==10 and contract['bounds']['compiler_capture_bytes']==4096
assert contract['bounds']['coordination_wait_seconds']==2
assert contract['bounds']['coordination_poll_seconds']==0.005
positive=explore()
assert positive['failure'] is None
mutants={name:explore(name) for name in ('missing_observation_reference',
    'maintenance_ignores_observation','missing_source_snapshot','early_observation_release')}
assert all(result['failure'] and result['trace'] for result in mutants.values())
# The concrete reported hazard must be reachable without a second runtime launch.
for name in ('missing_observation_reference','maintenance_ignores_observation'):
    assert mutants[name]['trace']==['prepare','launch','observation_admitted','runtime_finished',
        'runtime_retired','image_retired']
report={'schema':'fsmgen.canonical_image_lifetime_model.v1',
    'contract':{'bytes':len(contract_raw),'sha256':hashlib.sha256(contract_raw).hexdigest()},
    'positive':positive,'rejected_mutants':mutants,
    'semantics':'Finite single-runtime/single-observer ownership interleavings; event names model actions, never execute them.',
    'limitations':['No implementation refinement proof.','No file-lock, crash-durability, capacity workload or native path qualification.',
        'No policy scan or startup improvement claim.'],'native_compiler_original_collector_invocations':0}
raw=(json.dumps(report,sort_keys=True,indent=2)+'\n').encode()
(BASE/'lifetime-model.json').write_bytes(raw)
print(json.dumps({'report_bytes':len(raw),'report_sha256':hashlib.sha256(raw).hexdigest(),
    'positive':positive,'rejected_mutants':list(mutants)},sort_keys=True))
