"""Qualify pure control reading and resource joins using retained inert evidence."""
from __future__ import annotations
import argparse
import copy
import hashlib
import json
from support_controls import BASE, ROOT, CONSUME, COMMON, MODEL, ORACLE, digest
from consume_controls import control, stream
from resources import resources, opened_identities


def read(path):return json.loads(path.read_bytes())
def sha(body):return hashlib.sha256(body).hexdigest()
def reject(action):
    try:action()
    except (AssertionError,KeyError,ValueError,TypeError):return
    raise AssertionError('altered evidence was accepted')


def row_for(value):
    case=value['case'];release=case['event'].startswith('release_')
    result=dict(schema='fsmgen.inactive_observation_release_attempt.v1',runtime_authorized=0,executable=None,
        success=0,error=value['expected_error'],release=None,**case['release_effect']) if release else None
    calls=[value['inert_successful_call']] if case['fault'] else []
    return dict(name='selected_control',input_before=value['expected_inputs'],input_after=value['expected_inputs'],
        operation=dict(returned=int(release),error_hex='' if release else value['expected_error'].encode().hex(),result=result,calls=calls),
        control=dict(event=case['event'],selector=value['selector'],hits=[dict(ordinal=0,call=calls[0])] if calls else []))


def verify():
    data=read(BASE/'prepared.json');assert data['identity_origin']=='synthetic_only' and data['actual_fixture_operations']==0
    original=read(ROOT/'docs/audits/native-proxy-lifetime-model-20260913/prepared.json')['seeds']['same_image']
    payloads={name:bytes.fromhex(data['payloads'][name+'_hex']) for name in ('wrapper','c','image')}
    results=[];negative=[]
    for value in data['cases']:
        case=value['case'];context=value['context'];seed=CONSUME.initial(context,payloads,b'\0lifetime-other')
        for name,archive in context['archives'].items():seed['observers'][name]['archive']=archive
        row=row_for(value)
        control(row,case,context,seed,value['before'],value['expected_after'])
        assert digest(value['expected_after'])==value['expected_after_sha256']
        changed=copy.deepcopy(row);changed['operation']['returned']=1-changed['operation']['returned']
        reject(lambda:control(changed,case,context,seed,value['before'],value['expected_after']));negative.append(case['name']+':return-channel')
        changed=copy.deepcopy(row);changed['input_after']['store']+='_wrong'
        reject(lambda:control(changed,case,context,seed,value['before'],value['expected_after']));negative.append(case['name']+':input-mutation')
        if case['fault']:
            changed=copy.deepcopy(row);changed['control']['hits']=[]
            reject(lambda:control(changed,case,context,seed,value['before'],value['expected_after']));negative.append(case['name']+':missing-hit')
            reject(lambda:control(row,case,context,seed,value['before'],value['before']));negative.append(case['name']+':rollback')
            if case['release_effect'] is not None:
                changed=copy.deepcopy(row);changed['operation']['result']['unlink_completed']=1
                reject(lambda:control(changed,case,context,seed,value['before'],value['expected_after']));negative.append(case['name']+':promoted-flag')
        expected_stream=stream(case)
        assert expected_stream.count(('stage','selected_control'))==1
        assert expected_stream[-4:]==[('case-primary',None),('cleanup-admission',None),('stage','owned_cleanup'),('case-final',None)]
        assert sum(kind=='prefix-verified' for kind,name in expected_stream)==len(case['prefix'])
        results.append(dict(case=case['name'],stream_records=len(expected_stream),effect_sha256=digest(value['expected_after'])))
    witness_paths=sorted({row['record']['path'] for row in read(ROOT/'docs/audits/native-proxy-lifetime-controls-admission-20260913/call-witnesses.json')})
    permit=read(ROOT/'docs/audits/native-proxy-lifetime-files-20260913/execution-admission.json');flags=permit['native_open_flags']
    selection=read(ROOT/'docs/audits/native-proxy-lifetime-files-admission-20260913/selection.json');resource_results=[]
    for path in witness_paths:
        value=read(ROOT/path)['value'];case=next(c for c in selection['cases'] if c['name']==value['case']);roots=[case['roots'][key] for key in ('store','target','other','evidence')]
        before=value['before']['result']['nodes'];after=value['after']['result']['nodes'];trace=value['operation']
        node=next(iter(before.values()));uid=node['uid'];device=node['identity']['device']
        resources(trace,roots,selection['trace_limits'],native_flags=flags);opened_identities(trace,before,after,uid,device,flags)
        changed=copy.deepcopy(trace);changed['handles'][0]['native_at_open'][4]+=1
        reject(lambda:opened_identities(changed,before,after,uid,device,flags));negative.append(path+':wrong-open-uid')
        changed=copy.deepcopy(trace);changed['handles'][0]['native_at_open'][1]+=999999
        reject(lambda:opened_identities(changed,before,after,uid,device,flags));negative.append(path+':wrong-open-inode')
        changed=copy.deepcopy(trace);changed['handles'][0]['closed_at_return']=0
        reject(lambda:resources(changed,roots,selection['trace_limits'],native_flags=flags));negative.append(path+':open-primary')
        resource_results.append(dict(retained_record=path,handles=len(trace['handles']),calls=len(trace['calls']),original_interruption=False))
    first=read(BASE/'data-qualification.json');corrected=read(BASE/'corrected-data-qualification.json')
    assert first['fixture_attempts']==first['process_attempts']==corrected['fixture_attempts']==corrected['process_attempts']==0
    failed=[row['name'] for row in first['checks'] if not row['passed']]
    assert failed==['release_before_archive original context unchanged']
    assert len(first['checks'])==len(corrected['checks'])==96 and all(row['passed']==1 for row in corrected['checks'])
    assert [row['name'] for row in first['checks']]==[row['name'] for row in corrected['checks']]
    return dict(schema='fsmgen.inactive_lifetime_control_reader_data_review.v1',cases=results,retained_healthy_resource_traces=resource_results,
        rejected_countermodels=negative,original_inert_failure_preserved=failed,corrected_perl_checks=96,
        actual_fixture_operations=0,full_actual_journal_not_executed=True,runtime_qualification=False)


def main():
    parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    result=verify()
    if args.retain:
        with (BASE/'data-review.json').open('xb') as stream:stream.write(json.dumps(result,sort_keys=True,indent=2).encode()+b'\n')
    else:assert read(BASE/'data-review.json')==result
    print(json.dumps(dict(cases=len(result['cases']),countermodels=len(result['rejected_countermodels']),
        corrected_perl_checks=result['corrected_perl_checks'],actual_fixture_operations=0,success=True),sort_keys=True))


if __name__=='__main__':main()
