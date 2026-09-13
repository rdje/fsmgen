"""Independently consume the first control journal; never replay its producer."""
import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
FINAL=ROOT/'docs/audits/native-proxy-lifetime-controls-final-admission-20260913'
sys.path.insert(0,str(FINAL))
from support_final_corrected import H,M,C,reader,pin,read,write
from support_controls import canonical,digest
from admit_execution import absent


def closed_pairs(pairs):
    value={}
    for key,item in pairs:
        assert key not in value,'duplicate journal key';value[key]=item
    return value


def retained(row):
    body=(ROOT/row['retained']['path']).read_bytes()
    assert pin(ROOT/row['retained']['path'])==row['retained']
    assert all(row['retained'][key]==row['source'][key] for key in ('size_bytes','sha256'))
    return body


def effect_order(records):
    witnesses=[]
    for record in records:
        if record['kind']!='stage':continue
        value=record['value']
        if value['name']!='selected_control' or value['control']['selector'] is None:continue
        selector=value['control']['selector'];hits=value['control']['hits'];calls=value['operation']['calls']
        assert len(hits)==1;ordinal=hits[0]['ordinal']
        assert calls[ordinal]==hits[0]['call']
        assert all(call['operation'] in ('close','closedir') for call in calls[ordinal+1:])
        if selector['role']=='runtime_global':
            workspace=value['input_before']['acquired']['reference']['record']['workspace']
            private=[i for i,call in enumerate(calls) if call['operation']=='rmdir' and call['path']==workspace]
            assert len(private)==1 and private[0]<ordinal
        witnesses.append(dict(case=value['case'],record=record['sequence'],role=selector['role'],
            hit_ordinal=ordinal,after_hit_close_calls=len(calls)-ordinal-1))
    assert len(witnesses)==3
    return witnesses


def qualify(records,selection,payloads):
    result=reader.verify(records,selection,payloads)
    effect_order(records)
    return result


def countermodels(records,selection,payloads):
    def stage(rows,name,case=None):
        return next(row['value'] for row in rows if row['kind']=='stage' and row['value']['name']==name
                    and (case is None or row['value']['case']==case))
    def rejections(label,change):
        altered=copy.deepcopy(records);change(altered)
        try:qualify(altered,selection,payloads)
        except (AssertionError,KeyError,IndexError,ValueError,TypeError):return label
        raise AssertionError('accepted altered actual journal: '+label)
    changes=[
        ('missing_record',lambda rows:rows.pop(2)),
        ('open_primary',lambda rows:stage(rows,'acquire_runtime_target')['operation']['handles'][0].update(closed_at_return=0)),
        ('lost_primary_error',lambda rows:stage(rows,'selected_control','runtime_pins')['operation'].update(error_hex='')),
        ('promoted_release_completion',lambda rows:stage(rows,'selected_control','after_last_observation_unlink')['operation']['result'].update(unlink_completed=1)),
        ('lost_after_effect_hit',lambda rows:stage(rows,'selected_control','after_global_unlink')['control'].update(hits=[])),
        ('fault_before_effect',lambda rows:stage(rows,'selected_control','after_global_unlink')['control']['hits'][0]['call'].update(returned=0)),
        ('caller_input_changed',lambda rows:stage(rows,'selected_control','unreaped_runtime').update(input_after={})),
        ('unknown_owner_promoted',lambda rows:stage(rows,'selected_control','unknown_reference')['operation'].update(returned=1)),
        ('native_authority',lambda rows:rows[-1]['value'].update(runtime_qualification=1)),
        ('cleanup_incomplete',lambda rows:rows[-1]['value']['cases'][0].update(cleanup_returned=0)),
    ]
    result=[rejections(label,change) for label,change in changes]
    def move_global_before_private(rows):
        value=stage(rows,'selected_control','after_global_unlink');calls=value['operation']['calls']
        hit=value['control']['hits'][0];late=hit['ordinal']
        workspace=value['input_before']['acquired']['reference']['record']['workspace']
        early=next(i for i,call in enumerate(calls) if call['operation']=='rmdir' and call['path']==workspace)
        calls[early],calls[late]=calls[late],calls[early]
        # Preserve internally consistent hit data; reject the actual order,
        # rather than only an ordinal or copied-call mismatch.
        hit.update(ordinal=early,call=copy.deepcopy(calls[early]))
    result.append(rejections('coherent_global_before_private',move_global_before_private))
    return result


def verify():
    plan=read(BASE/'capture-plan.json');capture=read(BASE/'capture.json');selection=read(M/'selection.json')
    pins=read(H/'final-preflight-pins.json')
    for row in plan['sources']+read(BASE/'audit-pins.json')+pins:assert pin(ROOT/row['path'])==row
    for row in pins+[row for row in plan['sources'] if not row['path'].startswith(BASE.relative_to(ROOT).as_posix()+'/')]:
        body=subprocess.check_output(['git','show',plan['admission_commit']+':'+row['path']],cwd=ROOT)
        assert len(body)==row['size_bytes'] and hashlib.sha256(body).hexdigest()==row['sha256']
    final=read(FINAL/'review.json');assert final['owner']==read(FINAL/'plan.json')['owner']
    assert final['actual_fixture_operations']==final['actual_permits_written']==0 and final['execution_requires_committed_admission']
    assert capture['owner']==plan['owner'] and capture['admission_commit']==plan['admission_commit']
    assert capture['first_exit']==0 and capture['independently_qualified'] is False and capture['journal_absent'] is False
    records=[];total=0
    for index,row in enumerate(capture['records']):
        assert row['retained']['path']==(BASE/'records'/('event-%06d.json'%index)).relative_to(ROOT).as_posix()
        body=retained(row);total+=len(body)
        assert len(body)<=selection['bounds']['record_bytes'] and total<=selection['bounds']['total_record_bytes']
        value=json.loads(body,object_pairs_hook=closed_pairs);assert canonical(value)+b'\n'==body;records.append(value)
    assert len(records)==capture['record_count']==plan['maximum_journal_records']==351
    assert total==capture['record_bytes']
    assert sorted(p.name for p in (BASE/'records').iterdir())==['event-%06d.json'%i for i in range(len(records))]
    outputs={row['retained']['path'].rsplit('/',1)[1]:retained(row) for row in capture['first_outputs']}
    assert len(outputs)==6 and outputs['first-run.exit']==outputs['execution-permit.exit']==b'0\n'
    permit=json.loads(retained(capture['execution_admission']));task=retained(capture['task_at_execution'])
    assert hashlib.sha256(task).hexdigest()==permit['task_sha256']
    assert permit['admission_commit']==plan['admission_commit'] and permit['execution_owner']==plan['owner']
    assert permit['plan_sha256']==pin(H/'harness-plan.json')['sha256']
    assert permit['preflight_sha256']==pin(H/'final-preflight-pins.json')['sha256']
    assert 'Status: `active`' in task.decode().split('- ID: `'+plan['owner']+'`\n')[1].split('- ID: `',1)[0]
    assert records[0]['value']['admission']==permit and records[0]['value']['selection_sha256']==pin(M/'selection.json')['sha256']
    model=read(ROOT/selection['payload_source']['path']);sources=model['seeds']['same_image']['observers']['a']['acquired']['target_sources']
    payloads={name:bytes.fromhex(sources[index]['bytes_hex']) for name,index in selection['payload_source']['target_sources'].items()}
    original=digest(records);result=qualify(records,selection,payloads);assert digest(records)==original
    falsifiers=countermodels(records,selection,payloads);assert digest(records)==original
    assert json.loads(outputs['first-run.stdout'])==dict(cases=14,forbidden_process_attempts=0,journal_bytes=total,
        journal_records=len(records),runtime_qualification=0,success=1)
    traces=[]
    for record in records:
        if record['kind']=='stage':traces.extend(record['value'][name] for name in ('before','operation','after'))
        elif record['kind']=='cleanup-admission':traces.append(record['value']['observed'])
    handles=[handle for trace in traces for handle in trace['handles']]
    observers=[observer for trace in traces for observer in trace['metadata_observers']]
    assert all(h['closed_at_return']==1 for h in handles+observers) and all(trace['recovery']==[] for trace in traces)
    roots=[case['roots'][key] for case in selection['cases'] for key in ('store','target','other','evidence')]
    assert len(roots)==len(set(roots))==56 and all(absent(path) for path in roots)
    return dict(schema='fsmgen.inactive_lifetime_actual_controls_review.v1',owner=plan['owner'],admission_commit=plan['admission_commit'],
        final_preflight_inputs=len(pins),first_journal_records=len(records),first_journal_bytes=total,
        independent_reader=result,after_effect_witnesses=effect_order(records),rejected_countermodels=falsifiers,
        trace_count=len(traces),primary_handles=len(handles),file_handles=sum(h['kind']=='file' for h in handles),
        directory_handles=sum(h['kind']=='directory' for h in handles),metadata_observers=len(observers),
        recorded_source_calls=sum(len(trace['calls']) for trace in traces),separate_recoveries=0,
        roots_absent=roots,first_results_unchanged=True,original_execution_replayed=False,
        runtime_qualification=False,native_process_authentication=False)


def main():
    parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    result=verify()
    if args.retain:write(BASE/'review.json',result)
    else:assert read(BASE/'review.json')==result
    print(json.dumps(dict(success=True,cases=len(result['independent_reader']['cases']),records=result['first_journal_records'],
        countermodels=len(result['rejected_countermodels']),native_process_authentication=False),sort_keys=True))


if __name__=='__main__':main()
