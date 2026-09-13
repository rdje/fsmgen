"""Prepare inert control carriers; synthetic paths are never opened or allocated."""
import copy
import json
from support_controls import BASE, ROOT, COMMON, MODEL, ORACLE, CONSUME, digest
from consume_controls import input_for, diagnostic, removals


def main():
    selection=json.loads((ROOT/'docs/audits/native-proxy-lifetime-controls-admission-20260913/selection.json').read_bytes())
    original=json.loads((ROOT/'docs/audits/native-proxy-lifetime-model-20260913/prepared.json').read_bytes())['seeds']['same_image']
    objects=ORACLE.catalog(original);base=ORACLE.context(original,objects)
    payloads={key:bytes.fromhex(original['observers']['a']['acquired']['target_sources'][index]['bytes_hex'])
        for key,index in selection['payload_source']['target_sources'].items()}
    cases=[]
    for case in selection['cases']:
        context=copy.deepcopy(base);state=MODEL.initial(original)
        for event in case['prefix']:assert MODEL.transition(original,state,event)['returned']
        context['completed']={event:1 for event in case['prefix']}
        context['archives']={name:copy.deepcopy(original['observers'][name]['archive']) for name in state['archives']}
        before=ORACLE.physical_projection(original,state,objects)
        if case['mutation']=='unknown_reference':
            path=context['paths']['store']+'/references/'+'f'*64+'.json'
            before[path]=ORACLE.file_node(ORACLE.snapshot(path,9001,b'{}\n'),0o400)
        context['current']=ORACLE.snapshot_document(before,context['roots'])
        seed=CONSUME.initial(context,payloads,bytes.fromhex(selection['payload_source']['different_image_suffix_hex']))
        for name,archive in context['archives'].items():seed['observers'][name]['archive']=archive
        inputs=input_for(case,context,seed);error=diagnostic(case)
        stable_before=ORACLE.stable(before);deleted=removals(context,case['fault'],stable_before)
        after={path:node for path,node in stable_before.items() if path not in deleted}
        selector=None;call=None
        if case['fault']:
            operation='rmdir' if case['fault']=='private_root' else 'unlink'
            path=context['paths']['target'] if case['fault']=='private_root' else (
                context['runtimes']['target']['reference']['global']['identity']['path'] if case['fault']=='runtime_global'
                else context['observations']['b']['observation_reference']['source']['identity']['path'])
            selector=dict(role=case['fault'],operation=operation,path=path,error=error)
            call=dict(operation=operation,returned=1,errno=2)
            call.update(path=path) if operation=='rmdir' else call.update(paths=[path])
        cases.append(dict(case=case,context=context,expected_inputs=inputs,expected_error=error,selector=selector,
            inert_successful_call=call,before=stable_before,expected_after=after,expected_after_sha256=digest(after)))
    value=dict(schema='fsmgen.inactive_lifetime_control_data.v1',identity_origin='synthetic_only',actual_fixture_operations=0,
        payloads={key+'_hex':value.hex() for key,value in payloads.items()},cases=cases)
    with (BASE/'prepared.json').open('xb') as stream:stream.write(json.dumps(value,sort_keys=True,indent=2).encode()+b'\n')
    print(json.dumps(dict(cases=len(cases),actual_fixture_operations=0,synthetic_only=True),sort_keys=True))


if __name__=='__main__':main()
