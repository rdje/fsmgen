"""Independent publication payload, cleanup trace and descriptor custody oracle."""
from __future__ import annotations

from collections import Counter
import copy
import errno
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT/'.artifacts/logs/native-proxy-observation-publication-cuts-20260910'
PLAN_SHA = '53a9a87fcbbabcb4cc420c4a4605db817fa6761e4127c49f9b61515076b56c44'


def module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name,path)
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


PLAN = module('observation_publication_plan',BASE/'plan.py')
SNAPSHOT = module('observation_publication_snapshot_oracle',BASE.parent/'native-proxy-observation-snapshot-cuts-20260910/audit.py')
FRESH = SNAPSHOT.FRESH


def equal(a,b) -> None:
    assert FRESH.canonical(a) == FRESH.canonical(b)


def source_counts(row: dict, spec: dict) -> Counter:
    if spec['returns']:
        return SNAPSHOT.expected_sources(row,None)
    # This last acquisition directory event follows every initial/source read,
    # but precedes publication and the post-publication census. No source read
    # is lost by choosing its entry for the shared snapshot count model.
    expected = SNAPSHOT.expected_sources(row,'acquire:directory:image')
    assert sum(expected.values()) == 44
    if 'publication:readcheck' in spec['trace']:
        expected[SNAPSHOT.path_roles(row['context'])['hold']] += 1
    return expected


def custody(row: dict, spec: dict, mutant: bool = False) -> None:
    context = row['context']
    handles = row['handles']
    selected = {kind:[h for h in handles if h['kind']==kind] for kind in ('source','lock','writer')}
    assert len(handles) == sum(map(len,selected.values()))
    assert Counter(h['path'] for h in selected['source']) == source_counts(row,spec),(row['id'],'source counts differ')
    assert len(selected['lock']) == 1
    assert selected['lock'][0]['path'] == context['store']['path']+'/coordination.lock'
    writers = int(row['route']=='fresh' and spec['fault']!='before_open')
    assert len(selected['writer']) == writers
    hold = SNAPSHOT.path_roles(context)['hold']
    if writers: assert selected['writer'][0]['path']==hold
    values = SNAPSHOT.all_bytes(context)
    opened = []
    for entry in handles:
        assert type(entry['descriptor']) is int and entry['descriptor'] >= 0
        node = FRESH.node_for(row['after'],context,entry['path'])
        FRESH.native(entry['identity'])
        wanted = {key:node[key] for key in ('device','inode','mode','links','uid')}
        wanted['size_bytes'] = 0 if entry['kind']=='writer' else node['bytes']
        equal(entry['identity'],wanted)
        if entry['kind']=='source':
            assert type(entry['cloexec']) is int and entry['cloexec']==1
            FRESH.observed_source(entry['snapshot'],entry['path'],values[entry['path']],node['mode'],row['after'],context)
        else:
            assert 'snapshot' not in entry and 'cloexec' not in entry
        assert type(entry['closed_before_recovery']) is int and entry['closed_before_recovery'] in (0,1)
        assert type(entry['closed_after_recovery']) is int and entry['closed_after_recovery']==1
        if entry['closed_before_recovery']:
            assert entry['recovery_close_ok'] is None
            assert 'current_identity' not in entry and 'open_cloexec' not in entry
        else:
            assert mutant
            assert type(entry['recovery_close_ok']) is int and entry['recovery_close_ok']==1
            assert type(entry['open_cloexec']) is int and entry['open_cloexec']==1
            equal(entry['current_identity'],dict(wanted,size_bytes=node['bytes']))
            opened.append(entry)
    if mutant:
        assert len(opened)==1 and opened[0]['path']==hold
        expected_kind = 'writer' if spec['fault']=='omit_writer_close' else 'source'
        assert opened[0]['kind']==expected_kind
    else:
        assert opened==[]


def row_valid(row: dict, spec: dict, allocations: dict, mutant: bool) -> None:
    assert row['id']==spec['id'] and row['route']==spec['route']
    SNAPSHOT.context_valid(row,allocations)
    equal(row['trace'],spec['trace'])
    assert type(row['publication_calls']) is int and row['publication_calls']==int(row['route']=='fresh')
    assert type(row['returned']) is int and row['returned']==int(spec['returns'])
    diagnostic = spec['diagnostic']
    if not diagnostic:
        assert row['error']==''
    elif diagnostic.startswith('injected '):
        assert row['error']==diagnostic+'\n'
    else:
        assert row['error']==diagnostic+': '+os.strerror(errno.EIO)+'\n'
    context = row['context']
    record = FRESH.expected_observation(context)
    path = 'references/'+record['reference_key']+'.json'
    expected = copy.deepcopy(row['before'])
    if row['route']=='fresh':
        assert path not in expected['store']
        state = spec['hold']
        if state!='absent':
            payload = FRESH.canonical(record)
            if state=='empty': payload=b''
            elif state=='partial': payload=payload[:8]
            else: assert state=='complete'
            node = row['after']['store'][path]
            SNAPSHOT.file_node(node,payload,0o400)
            expected['store'][path]=node
    equal(expected,row['after'])
    if spec['returns']:
        FRESH.check_success(dict(row,name='fresh acquisition'))
        if row['route']=='reuse':equal(row['result'],context['previous'])
    else:
        assert 'result' not in row
    custody(row,spec,mutant)
    if mutant:
        try:
            custody(row,spec)
        except AssertionError:
            pass
        else:
            raise AssertionError('strict publication custody accepted omitted close')


def validate(result: dict, plan: dict) -> None:
    assert result['schema']=='fsmgen.inactive_observation_publication_cuts_qualification.v1'
    assert result['success'] is True and 'first_failure' not in result and 'unexpected_error' not in result
    assert type(result['forbidden_process_attempts']) is int and result['forbidden_process_attempts']==0
    ledger=[json.loads(line) for line in (LOG/'admission.jsonl').read_text().splitlines()]
    equal(result['allocated'],ledger)
    allocations={r['path']:r for r in ledger}
    assert len(allocations)==len(ledger)==4*(len(plan['cases'])+len(plan['mutants']))
    for path,entry in allocations.items():
        assert set(entry)=={'kind','path','device','inode'}
        prefix={'store':'.artifacts/tmp/native-proxy-image-custody/cases/',
            'workspace':'.artifacts/tmp/process-supervisor-tests/',
            'evidence':'.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/'}[entry['kind']]
        assert re.fullmatch(re.escape(prefix)+r'fsmgen-[A-Za-z0-9_]+',path)
        FRESH.native(entry)
        assert not (ROOT/path).exists() and not (ROOT/path).is_symlink()
    used=[]
    for category in ('cases','mutants'):
        assert [r['id'] for r in result[category]]==[s['id'] for s in plan[category]]
        for row,spec in zip(result[category],plan[category]):
            row_valid(row,spec,allocations,category=='mutants')
            used.extend(row['context'][kind]['path'] for kind in SNAPSHOT.KINDS)
    assert len(used)==len(set(used)) and set(used)==set(allocations)


def main() -> None:
    raw=(BASE/'plan.json').read_bytes()
    assert hashlib.sha256(raw).hexdigest()==PLAN_SHA
    plan=json.loads(raw);equal(plan,PLAN.build())
    result=json.loads((LOG/'qualification.json').read_bytes());validate(result,plan)
    rows=[json.loads(line) for line in (LOG/'rows.jsonl').read_text().splitlines()]
    equal(rows,[dict(category=c,row=r) for c in ('cases','mutants') for r in result[c]])
    equal(json.loads((LOG/'progress.json').read_bytes()),dict(schema='fsmgen.inactive_publication_cut_progress.v1',
        success=True,allocations=len(result['allocated']),cases=len(result['cases']),mutants=len(result['mutants']),forbidden_process_attempts=0))
    assertions=FRESH.RUNTIME.tap_count((LOG/'qualify.tap').read_text())
    assert assertions==2*(len(plan['cases'])+len(plan['mutants']))+1
    falsifiers=[]

    def case(data,identity):
        return next(row for row in data['cases'] if row['id']==identity)

    def remove_hold(data,identity):
        row=case(data,identity)
        row['after']['store'].pop('references/'+FRESH.expected_observation(row['context'])['reference_key']+'.json')

    for name,change in [
        ('hidden failure',lambda x:x.update(success=False)),
        ('lost publication case',lambda x:x['cases'].pop()),
        ('lost cleanup call',lambda x:x['cases'][0]['trace'].pop()),
        ('lost reader handle',lambda x:x['cases'][0]['handles'].pop()),
        ('masked open writer',lambda x:x['cases'][0]['handles'][0].update(closed_before_recovery=0)),
        ('forged handle identity',lambda x:x['cases'][0]['handles'][1]['identity'].update(inode=1)),
        ('lost partial payload',lambda x:remove_hold(x,'fresh:partial_write')),
        ('lost empty payload',lambda x:remove_hold(x,'fresh:byte_mode')),
        ('lost complete failed payload',lambda x:remove_hold(x,'fresh:after_return')),
        ('cleanup masks primary failure',lambda x:case(x,'fresh:write_and_close_error').update(error='cannot close canonical writer: '+os.strerror(errno.EIO)+'\n')),
        ('lost unrelated observation owner',lambda x:x['cases'][0]['after']['store'].pop('references/'+x['cases'][0]['context']['seeded_record']['reference_key']+'.json')),
        ('reuse publishes',lambda x:case(x,'reuse:complete').update(publication_calls=1)),
        ('authority type changed',lambda x:x['cases'][0]['result'].update(runtime_authorized=False)),
        ('lost omitted-close evidence',lambda x:x['mutants'].pop()),
        ('lost allocation',lambda x:x['allocated'].pop()),
        ('forbidden process',lambda x:x.update(forbidden_process_attempts=1)),
    ]:
        changed=copy.deepcopy(result);change(changed)
        try:
            validate(changed,plan)
        except (AssertionError,KeyError):
            falsifiers.append(name)
        else:
            raise AssertionError('publication oracle missed falsifier: '+name)
    report=dict(schema='fsmgen.inactive_observation_publication_cuts_audit.v1',success=True,
        assertions=assertions,cases=len(plan['cases']),allocations=len(result['allocated']),
        mutants=[r['id'] for r in result['mutants']],falsifiers=falsifiers,limits=plan['limits'])
    (LOG/'audit.json').write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print(json.dumps(report,sort_keys=True))


if __name__=='__main__':
    main()
