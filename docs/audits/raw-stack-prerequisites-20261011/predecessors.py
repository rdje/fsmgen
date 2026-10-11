"""Join full class/phase authority to every complete observer header role."""
import copy
import json
import re
from pathlib import Path
from common import BASE, CLASS, OBSERVER, RAW, REVISION, SCOPE, canonical, load, need, pin, save
from intake import git

AUDITS=Path('docs/audits')
TASK=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')


def read(name):return json.loads((AUDITS/name).read_bytes())


def blocks(text):
    matches=list(re.finditer(r'^- ID: `([^`]+)`\n.*?(?=^- ID: |\Z)',text,re.M|re.S))
    result={m[1]:m[0] for m in matches}
    need(len(result)==len(matches),'unique complete original predecessor task identities')
    return result


def fields(body):
    return {key:re.search(r'^  '+key+r': `(.*)`$',body,re.M)[1]
            for key in ('Goal','Acceptance','Children') if re.search(r'^  '+key+':',body,re.M)}


def contracts():
    fixed=git('show',REVISION+':'+str(TASK));nodes=blocks(fixed.decode());pending=[CLASS];forest={}
    while pending:
        key=pending.pop();need(key not in forest,'acyclic full predecessor forest')
        forest[key]=nodes[key]
        pending.extend(re.findall(r'SEMANTIC-INTROSPECTION-MCP-FRONTIER[.0-9]*',fields(nodes[key]).get('Children','')))
    need(all('  Status: `done`\n' in body for key,body in forest.items() if key not in (CLASS,OBSERVER)),
         'every original observer/class-frame child completed before predecessor closure')
    return dict(revision=REVISION,task=pin(fixed),forest=forest,
                raw_containers={key:nodes[key] for key in (RAW,RAW+'.5')},scope=SCOPE)


def qualify_contracts(candidate,current):
    expected=contracts()
    need(canonical(candidate)==canonical(expected),'whole unchanged original predecessor/raw acceptance and child contracts')
    nodes=blocks(current)
    for key,body in expected['forest'].items():
        need(fields(nodes[key])==fields(body),'complete live predecessor goal acceptance and children conserve')
        status=re.search(r'^  Status: `(.*)`$',nodes[key],re.M)[1]
        need(status=='done' if key not in (CLASS,OBSERVER) else status in ('active','done'),
             'every complete predecessor child remains done')
    for key,body in expected['raw_containers'].items():
        wanted=fields(body);actual=fields(nodes[key])
        if key==RAW+'.5':
            # This slice owns the explicit three-stage decomposition, which
            # changes no original goal or acceptance requirement.
            actual.pop('Children',None)
        need(actual==wanted,'whole unchanged raw-container original goal and acceptance')


def inputs():
    return (read('record-value-class-frame-join-20261006/source-models.json'),
            read('record-value-class-frame-join-20261006/proofs.json'),
            read('record-value-class-frame-join-20261006/raw-product.json')['inventories'],
            read('observer-original-header-join-20261011/joined.json'),
            read('observer-source-headers-20261011/headers.json'))


def derive(source,qualified,native,headers,expressions):
    records={(mode['mode'],domain,row['index']):row for mode in native
             for domain,values in mode['domains'].items() for row in values['nonempty']}
    cases={(mode['mode'],case['domain'],case['index']):case for mode in source['modes'] for case in mode['cases']}
    joined={(mode['mode'],case['domain'],case['index']):case for mode in qualified['modes'] for case in mode['cases']}
    need(set(records)==set(cases)==set(joined),'complete source/class/frame/original refusal member population')
    declared={tuple(row['allocation']['source_path']):row for row in headers['source_headers']}
    need(len(declared)==len(headers['source_headers']),'unique complete observer source/header role allocation')
    expected_paths=set();result=[]
    for mi,mode in enumerate(source['modes']):
        for ci,case in enumerate(mode['cases']):
            key=mode['mode'],case['domain'],case['index'];record=records[key];proof=joined[key]
            need(proof['exception']==case['exception'],'whole source-inferred exception class and first-cause membership')
            need(record['body'].startswith(case['exception']['primary']+'\n'),'exact complete source first cause before full raw body')
            need(type(record['body']) is str and pin(record['body'].encode())==record['body_identity']==proof['original_whole_body']
                 and ''.join(s['raw'] for s in record['segments'])==record['body'],'whole reversible original class/header raw body')
            frames=[s for s in record['segments'] if s['kind']=='frame'];phases=[]
            need(len(case['phases'])==len(proof['phases']),'complete source and qualified throw-phase population')
            for pi,phase in enumerate(case['phases']):
                prior=proof['phases'][pi];positions=prior['complete_own_positions'];base=('modes',mi,'cases',ci,'phases',pi)
                need(type(phase['phase']) is int and phase['phase']==prior['phase']==pi
                     and phase['family']==prior['family'] and phase['guard_source']==prior['guard_source']
                     and phase['inferred_class']==prior['inferred_class']=='unblessed_nonreference_scalar'
                     and prior['native_class']=='not measured; qualified source/publisher inference only',
                     'whole ordered source guard/family/class phase without native promotion')
                allocations=[]
                for role in ('core','helper','body','entry'):
                    need(len(phase['own'][role])==len(positions[role+'_positions']),'whole own frame role population')
                    allocations.extend((base+('own',role,fi),frame,positions[role+'_positions'][fi])
                                       for fi,frame in enumerate(phase['own'][role]))
                for oi,operation in enumerate(phase['own']['operations']):
                    need(len(operation['frames'])==len(positions['operations'][oi]),'whole operation frame role population')
                    allocations.extend((base+('own','operations',oi,'frames',fi),frame,positions['operations'][oi][fi])
                                       for fi,frame in enumerate(operation['frames']))
                for role in ('body','entry'):
                    allocations.extend((base+('public',role,fi),frame,positions[role+'_positions'][fi])
                                       for fi,frame in enumerate(phase['public'][role]))
                for oi,operation in enumerate(phase['public']['own_eval_boundaries']):
                    allocations.extend((base+('public','own_eval_boundaries',oi,fi),frame,positions['operations'][oi][fi])
                                       for fi,frame in enumerate(operation))
                roles=[]
                for path,frame,position in allocations:
                    expected_paths.add(path)
                    need(path in declared,'every complete own/public source role has a full header')
                    actual=declared[path];allocation=actual['allocation'];header=actual['source_header']
                    need(allocation['record']==list(key) and type(allocation['phase']) is int and allocation['phase']==pi
                         and type(allocation['frame_position']) is int and allocation['frame_position']==position,
                         'exact complete source caller phase and frame allocation')
                    need(actual['original_frame']==frames[position],'whole original header frame belongs to its caller')
                    need(header['expression']['function']==frame['function']==actual['joined']['function'],
                         'complete source function and original full header role')
                    arguments=[expressions['operands'][identifier]['source']['input'] for identifier in header['source_argument_ids']]
                    need(arguments==frame['arguments'],'whole source argument membership order and role')
                    if frame['function']!='eval {...}':
                        need(actual['joined']['complete_call']==frames[position]['call'],
                             'whole original encoded header without prefix normalization')
                    roles.append(dict(source_path=list(path),frame_position=position,function=frame['function'],
                                      source_arguments=arguments,whole_frame=pin(canonical(actual['original_frame'])),
                                      complete_header=pin(canonical(actual))))
                phases.append(dict(phase=pi,family=phase['family'],inferred_class=phase['inferred_class'],
                                   guard=phase['guard_source'],roles=roles))
            need(case['exception']['source_family']==case['phases'][-1]['family'],
                 'final source first cause belongs to final own throw phase')
            result.append(dict(record=list(key),exception=case['exception'],whole_body=record['body_identity'],
                               phases=phases,whole_forwarding=proof['forwarded']))
    need(expected_paths==set(declared),'complete observer header role population without borrowed extra roles')
    need(headers['full_original_raw_domain']==pin(canonical(native)),
         'entire original raw domain remains source-bound')
    need(headers['original_unknowns']==expressions['original_unmeasured'],
         'every original typed observer/native/settings/private uncertainty remains')
    return dict(scope=SCOPE,rows=result,all_original_headers=pin(canonical(headers)),
                unknowns=headers['original_unknowns'],entire_raw_domain=pin(canonical(native)),
                public_load_and_opaque= {key:pin(canonical(headers[key])) for key in ('public_headers','loads','complete_opaque_allocation')},
                independence='Cross-product source/class/phase/role association oracle shares qualified source models and raw catalog with earlier readers. Complete quoting/truncation falsification is the separate original-header lexical reader; no universal language or native identity oracle is asserted.')


def controls(original,product):
    results=[]
    def reject(name,mutate,cause):
        candidate=copy.deepcopy(original);mutate(candidate)
        need(canonical(candidate)!=canonical(original),'genuine complete predecessor intervention')
        try:derive(*candidate)
        except ValueError as error:
            need(str(error)==cause,'intended predecessor association refusal: '+name+': '+str(error))
            results.append(dict(name=name,candidate=pin(canonical(candidate)),status=1,cause=cause))
        else:raise ValueError('false-green predecessor association: '+name)
    reject('missing-source-case',lambda x:x[0]['modes'][0]['cases'].pop(),'complete source/class/frame/original refusal member population')
    reject('native-class-promotion',lambda x:x[0]['modes'][0]['cases'][0]['phases'][0].update(inferred_class='native_blessed'),
           'whole ordered source guard/family/class phase without native promotion')
    reject('first-cause',lambda x:x[2][0]['domains']['api']['nonempty'][0].update(body='Unrelated first cause\n'+x[2][0]['domains']['api']['nonempty'][0]['body']),
           'exact complete source first cause before full raw body')
    reject('wrong-caller',lambda x:x[3]['source_headers'][0]['allocation'].update(frame_position=-1),
           'exact complete source caller phase and frame allocation')
    reject('borrowed-whole-frame',lambda x:x[3]['source_headers'][0].update(original_frame=x[3]['source_headers'][-1]['original_frame']),
           'whole original header frame belongs to its caller')
    reject('missing-full-header',lambda x:x[3]['source_headers'].pop(),
           'every complete own/public source role has a full header')
    reject('wrong-source-argument-role',lambda x:x[0]['modes'][0]['cases'][0]['phases'][0]['own']['core'][0]['arguments'][0].update(role='borrowed_role'),
           'whole source argument membership order and role')
    return results


def main():
    original=inputs();product=derive(*original);task=contracts();qualify_contracts(task,TASK.read_text())
    proof=dict(contracts=task,associations=product,controls=controls(original,product))
    for name,mutate in (
        ('narrowed-observer-acceptance',lambda c:c['forest'].update({OBSERVER:c['forest'][OBSERVER].replace('Derive every wrapper','Derive one wrapper',1)})),
        ('missing-child-contract',lambda c:c['forest'].pop(OBSERVER+'.1'))):
        candidate=copy.deepcopy(task);mutate(candidate);need(candidate!=task,'genuine full task intervention')
        try:qualify_contracts(candidate,TASK.read_text())
        except ValueError as error:
            need(str(error)=='whole unchanged original predecessor/raw acceptance and child contracts','intended full task refusal')
            proof['controls'].append(dict(name=name,candidate=pin(canonical(candidate)),status=1,cause=str(error)))
        else:raise ValueError('false-green original predecessor contract')
    if (BASE/'predecessors.json').exists():need(load('predecessors.json')==proof,'entire unchanged complete predecessor acceptance proof')
    else:save('predecessors.json',proof)
    print('PASS complete unchanged observer/class-frame predecessor acceptance and all child contracts; whole source/class/phase/header/argument/raw membership and genuine controls qualify without native promotion.')


if __name__=='__main__':main()
