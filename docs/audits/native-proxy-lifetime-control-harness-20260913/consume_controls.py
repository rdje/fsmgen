"""Independent data-only reader of the selected interruption-control journal."""
from __future__ import annotations
import copy
from support_controls import CONSUME as C, COMMON, MODEL, ORACLE, digest, stable
from resources import resources, opened_identities


def stream(case):
    result=[('case-intent',None)]
    result += [('stage',name) for name in ('create_owned_roots','prepare_private_wrappers',
        'acquire_runtime_target','acquire_runtime_other','acquire_observation_a','acquire_observation_b')]
    result.append(('case-initial',None));completed=set()
    for event in case['prefix']:
        for name in ('a','b'):
            if 'retire_target' not in completed and 'release_'+name not in completed:
                result.append(('stage','reuse_'+name+'_before_'+event))
        result.extend([('stage',event),('prefix-verified',None)]);completed.add(event)
    if case['mutation']=='unknown_reference':result.append(('stage','create_unknown_reference'))
    result.append(('stage','selected_control'))
    if case['followup_maintenance'] is not None:result.append(('stage','followup_maintenance'))
    result.extend([('case-primary',None),('cleanup-admission',None),('stage','owned_cleanup'),('case-final',None)])
    return result


def input_for(case,context,seed):
    event=case['event'];value=copy.deepcopy(seed)
    if case['mutation']=='unreaped_runtime':value['runtimes']['target']['cleanup'][2][0]['cleanup']['leader_reaped']=0
    if case['mutation']=='unsettled_work':value['observers']['a']['settlement']['receipts'][0]['cleanup']['group_gone']=0
    if case['mutation']=='unsealed_work':value['observers']['a']['settlement']['selection_sealed']=0
    if event.startswith('release_'):value['observers'][event[-1]].setdefault('archive',None)
    return C.event_input(event,context,value)


def diagnostic(case):
    if case['fault'] is not None:return 'INJECTED_LIFETIME_AFTER_EFFECT:'+case['name']+'\n'
    if case['event']=='maintain_target':
        return ('expected explicit reference schema' if case['mutation']=='unknown_reference'
                else 'selected image is retained by an unresolved reference')+'\n'
    if case['mutation']=='unreaped_runtime':return 'complete compiler, outer and inner cleanup is unproved\n'
    if case['mutation']=='unsettled_work':return 'selected work cleanup is incomplete\n'
    if case['mutation']=='unsealed_work':return 'selected work is not sealed\n'
    if case['event']=='reuse_a':return 'observation runtime reference is absent\n'
    return ('expected closed record fields' if not case['prefix']
            else 'original observation hold is absent or changed')+'\n'


def removals(context,effect,before):
    if effect in ('private_root','runtime_global'):
        root=context['paths']['target'];result={path for path in before if path==root or path.startswith(root+'/')}
        if effect=='runtime_global':result.add(context['runtimes']['target']['reference']['global']['identity']['path'])
        return result
    if effect=='observation_hold':return {context['observations']['b']['observation_reference']['source']['identity']['path']}
    if effect=='maintenance':
        root=context['paths']['store']+'/images/'+context['runtimes']['target']['image']['key']
        return {path for path in before if path==root or path.startswith(root+'/')}
    assert effect is None;return set()


def control(row,case,context,seed,before,after):
    trace=row['operation'];following=row['name']=='followup_maintenance'
    event='maintain_target' if following else case['event']
    inputs=C.event_input(event,context,seed) if following else input_for(case,context,seed)
    assert row['input_before']==row['input_after']==inputs
    successful=following and case['followup_maintenance']
    error='selected image is retained by an unresolved reference\n' if following else diagnostic(case)
    if not following and event.startswith('release_'):
        assert trace['returned']==1 and trace['error_hex']==''
        assert trace['result']==dict(schema='fsmgen.inactive_observation_release_attempt.v1',runtime_authorized=0,
            executable=None,success=0,error=error,release=None,**case['release_effect'])
    elif successful:
        assert trace['returned']==1 and trace['error_hex']==''
        C.event_result('maintain_target',trace['result'],context,seed,before)
    else:
        assert trace['returned']==0 and trace['result'] is None and bytes.fromhex(trace['error_hex']).decode()==error
    role=None if following else case['fault']
    selector=None;hits=[]
    if role is not None:
        operation='rmdir' if role=='private_root' else 'unlink'
        path=(context['paths']['target'] if role=='private_root' else
              context['runtimes']['target']['reference']['global']['identity']['path'] if role=='runtime_global' else
              context['observations']['b']['observation_reference']['source']['identity']['path'])
        selector=dict(role=role,operation=operation,path=path,error=error)
        for ordinal,call in enumerate(trace['calls']):
            if call['operation']==operation and call['returned']==1 and (call.get('path')==path or call.get('paths')==[path]):
                hits.append(dict(ordinal=ordinal,call=call))
        assert len(hits)==1
    assert row['control']==dict(event=event,selector=selector,hits=hits)
    effect='maintenance' if successful else role
    removed=removals(context,effect,before)
    assert set(removed)<=set(before) and after=={path:node for path,node in before.items() if path not in removed}
    if role=='private_root':
        assert context['runtimes']['target']['reference']['global']['identity']['path'] in after
    if role in ('runtime_global','observation_hold'):
        image_root=context['paths']['store']+'/images/'+context['runtimes']['target']['image']['key']
        assert image_root in after


def setup_membership(stages,context,payloads,selection):
    nodes=context['initial']['nodes'];paths=context['paths'];expected=set(paths.values())
    additions=[{root+'/'+suffix for root in (paths['target'],paths['other']) for suffix in ('rust-tools','rust-tool-resolution')}]
    for name in ('target','other'):
        runtime=context['runtimes'][name];root=paths['store']+'/images/'+runtime['image']['key']
        additions.append({paths['store']+'/'+part for part in ('images','references','coordination.lock')}|{root}
            |{item['identity']['path'] for item in runtime['image']['snapshots']}
            |{runtime['reference'][kind]['identity']['path'] for kind in ('private','global')})
    additions += [{context['observations'][name]['observation_reference']['source']['identity']['path']} for name in ('a','b')]
    for index,row in enumerate(stages[:6]):
        if index:expected.update(additions[index-1])
        assert stable(row['after']['result']['nodes'])==stable({path:nodes[path] for path in expected})
        if index==0:inputs=dict(roots=paths);assert row['operation']['result']==context['directories']
        elif index==1:
            inputs=dict(roots=paths,wrapper_hex=payloads['wrapper'].hex());assert row['operation']['result']==dict(private_wrappers_only=1)
        elif index in (2,3):
            name='target' if index==2 else 'other'
            inputs=dict(store=paths['store'],workspace=context['directories'][name],c_hex=payloads['c'].hex(),image_hex=payloads['image'].hex())
            assert row['operation']['result']==context['runtimes'][name]
        else:
            name='a' if index==4 else 'b';inputs=dict(store=paths['store'],request=context['requests'][name])
            assert row['operation']['result']==context['observations'][name]
        assert row['input_before']==row['input_after']==inputs
    assert expected==set(nodes)


def verify(records,selection,payloads):
    assert records[0]['kind']=='run-started' and records[-1]['kind']=='run-final'
    start=records[0]['value'];final=records[-1]['value'];uid=start['normal_uid'];flags=start['admission']['native_open_flags']
    assert type(uid) is int and uid>0 and start['runtime_qualification']==0 and start['synthetic_ownership_only']==1
    assert set(flags)=={'O_WRONLY','O_RDWR','O_CREAT','O_TRUNC','O_EXCL'} and all(type(v) is int and v>0 for v in flags.values())
    assert final['success']==1 and final['forbidden_process_attempts']==0 and final['runtime_qualification']==0
    assert 0<=final['elapsed_ns']<=selection['bounds']['total_wall_seconds']*1_000_000_000
    for index,record in enumerate(records):
        assert set(record)=={'schema','sequence','kind','monotonic_ns','value'}
        assert record['schema']=='fsmgen.inactive_lifetime_controls_event.v1' and record['sequence']==index
        assert type(record['monotonic_ns']) is int and (index==0 or record['monotonic_ns']>=records[index-1]['monotonic_ns'])
    cursor=1;summaries=[]
    for case in selection['cases']:
        expected=stream(case);rows=records[cursor:cursor+len(expected)];cursor+=len(expected)
        assert len(rows)==len(expected)
        for row,(kind,name) in zip(rows,expected):
            assert row['kind']==kind
            if name is not None:assert row['value']['name']==name
        assert rows[0]['value']==dict(case=case,synthetic_ownership_only=1,roots_absent_before_creation=[case['roots'][name] for name in ('store','target','other','evidence')])
        context=next(row['value'] for row in rows if row['kind']=='case-initial')
        assert context['name']==case['name'] and context['paths']==case['roots'] and context['profile']==case['profile']=='same_image'
        roots=[case['roots'][name] for name in ('store','target','other','evidence')]
        assert context['roots']==roots and context['initial']==context['current']
        device=context['directories']['store']['device'];C.snapshot(context['initial'],roots,selection['bounds'],uid,device)
        seed=C.initial(context,payloads,bytes.fromhex(selection['payload_source']['different_image_suffix_hex']))
        stages=[row['value'] for row in rows if row['kind']=='stage'];setup_membership(stages,context,payloads,selection)
        objects=copy.deepcopy(context['initial']['nodes'])
        for name in ('a','b'):
            archived=next((row for row in stages if row['name']=='archive_'+name),None)
            if archived is None:continue
            value=seed['observers'][name];receipt=archived['operation']['result'];COMMON.archive.validate(value,receipt)
            spec=COMMON.archive.specification(value);nodes=archived['after']['result']['nodes']
            value['directory']=nodes[spec['archive_directory']]['identity']
            value['snapshots']=[dict(identity=nodes[item['path']]['identity'],bytes_hex=nodes[item['path']]['bytes_hex']) for item in spec['files']]
            value['archive']=COMMON.archive.from_snapshots(value);assert value['archive']==receipt
            for path in {spec['archive_directory']}|{item['path'] for item in spec['files']}:
                if path in objects:assert stable({path:objects[path]})==stable({path:nodes[path]})
                objects[path]=nodes[path]
        cleanup=next(row['value'] for row in rows if row['kind']=='cleanup-admission')
        state=MODEL.initial(seed);owned={};previous={};prefix=[]
        declarations=[row['value'] for row in rows if row['kind']=='prefix-verified']
        for index,row in enumerate(stages):
            name=row['name'];operation=row['operation'];assert row['case']==case['name'] and row['input_before']==row['input_after']
            assert type(row['started_monotonic_ns']) is int and row['started_monotonic_ns']<=row['ended_monotonic_ns']
            created=resources(operation,roots,selection['trace_limits'],native_flags=flags)
            before=C.probe(row['before'],roots,selection,uid,device,flags)
            after=C.probe(row['after'],roots,selection,uid,device,flags);assert before==previous
            opened_identities(operation,row['before']['result']['nodes'],row['after']['result']['nodes'],uid,device,flags)
            removed=[]
            for call in operation['calls']:
                if call['operation']=='unlink':assert call['returned']==len(call['paths']);removed+=call['paths']
                elif call['operation']=='rmdir':assert call['returned']==1;removed.append(call['path'])
            assert len(removed)==len(set(removed)) and set(removed)==set(before)-set(after)
            for path,identity in created.items():assert path not in owned or owned[path]==identity;owned[path]=identity
            for path,node in after.items():assert owned[path]==dict(path=path,device=node['identity']['device'],inode=node['identity']['inode'],kind=node['kind'])
            if name in ('selected_control','followup_maintenance'):
                control(row,case,context,seed,before,after)
            else:
                assert operation['returned']==1 and operation['error_hex']=='' and 'control' not in row
                if index<6:pass
                elif name.startswith('reuse_'):
                    observer=name.split('_')[1];assert row['input_before']==C.event_input(name,context,seed)
                    assert MODEL.live_matches(seed,state,observer,True) and operation['result']==context['observations'][observer] and before==after
                elif name=='create_unknown_reference':
                    path=case['roots']['store']+'/references/'+'f'*64+'.json';assert path not in before
                    assert row['input_before']==dict(path=path,bytes_hex=b'{}\n'.hex(),mode=0o400)
                    assert operation['result']==dict(created_unknown_reference=path)
                    assert {p:n for p,n in after.items() if p!=path}==before
                    assert after[path]['kind']=='file' and after[path]['mode']==0o400 and after[path]['bytes_hex']==b'{}\n'.hex()
                elif name=='owned_cleanup':
                    assert after=={} and operation['result']['absent_roots']==roots
                    assert len(operation['result']['removed'])==len(before) and set(operation['result']['removed'])==set(before)
                    assert row['input_before']==dict(roots=roots,expected=cleanup['observed']['result'])
                else:
                    assert name==case['prefix'][len(prefix)] and row['input_before']==C.event_input(name,context,seed)
                    C.event_result(name,operation['result'],context,seed,before)
                    if name.startswith('retire_'):assert removed[-1]==context['runtimes'][name.removeprefix('retire_')]['reference']['global']['identity']['path']
                    assert MODEL.transition(seed,state,name)['returned']
                    projected=stable(ORACLE.physical_projection(seed,state,objects));assert after==projected
                    prefix.append(name);assert declarations[len(prefix)-1]==dict(case=case['name'],completed=sorted(prefix),stable_state_sha256=digest(projected))
            previous=after
        assert prefix==case['prefix']
        cleanup=next(row['value'] for row in rows if row['kind']=='cleanup-admission')
        assert cleanup['case']==case['name'] and cleanup['created_identities']==owned
        assert C.probe(cleanup['observed'],roots,selection,uid,device,flags)==stable(stages[-1]['before']['result']['nodes'])
        primary=next(row['value'] for row in rows if row['kind']=='case-primary');assert primary==dict(case=case['name'],returned=1,error_hex='')
        result=rows[-1]['value'];assert result==dict(case=case['name'],primary_returned=1,error_hex='',cleanup_returned=1,cleanup_error_hex='',cleanup=stages[-1]['operation']['result'])
        assert result==final['cases'][len(summaries)]
        assert 0<=rows[-1]['monotonic_ns']-rows[0]['monotonic_ns']<=(selection['bounds']['case_wall_seconds']+selection['bounds']['cleanup_wall_seconds'])*1_000_000_000
        summaries.append(dict(case=case['name'],stages=len(stages),prefixes=len(prefix),roots=roots))
    assert cursor==len(records)-1 and len(final['cases'])==len(summaries)
    return dict(cases=summaries,stages=sum(r['stages'] for r in summaries),journal_records=len(records),
        synchronous_after_effect_controls=sum(case['fault'] is not None for case in selection['cases']),
        runtime_qualification=False,native_process_authentication=False)
