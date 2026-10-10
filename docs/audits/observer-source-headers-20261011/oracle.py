"""Independent direct-source frame/operand traversal and full expression reconstruction."""
import json
from common import CENSUS, VALUES, DISPLAY, PREDICATE, SCALAR, REGEX, SCOPE, canonical, inputs, need, pin, read, same


def nodes(source):
    pending=[(['modes'],source['modes'])];result=[]
    while pending:
        path,node=pending.pop()
        if isinstance(node,dict):
            result.append((path,node))
            pending.extend((path+[key],node[key]) for key in sorted(node,reverse=True))
        elif isinstance(node,list):
            pending.extend((path+[index],node[index]) for index in reversed(range(len(node))))
    return result


def expected():
    source=read(CENSUS/'source-models.json');parent=read(VALUES/'product-qualified.json')
    original=parent['source_values'];visited=nodes(source)
    direct=[]
    for path,node in visited:
        if 'role' in node and ('kind' in node or 'expression' in node):
            schema=node.get('kind', 'context_scalar' if 'source_value' in node else 'context_reference')
            direct.append(dict(path=path,input=node,schema=schema))
    need(same(direct,[{k:row[k] for k in ('path','input','schema')} for row in original['operands']]),
         'independent complete direct-source operand/schema/order allocation')
    table={};ordered=[]
    for kind,directory in [('scalar',SCALAR),('regex',REGEX)]:
        for row in read(directory/'plan.json')['cases']:
            identifier=kind+':'+row['id'];ordered.append(identifier)
            table[identifier]=dict(kind=kind,case=row,
                meaning='Dated qualified source-neutral current construction only; no original flags/settings/identity attribution.')
    for row in read(PREDICATE/'fixture-plan-qualified.json')['fixtures']:
        identifier='predicate:'+row['name'];ordered.append(identifier)
        table[identifier]=dict(kind='predicate',case=row,
            meaning='Dated qualified source guard construction only; a logical-zero source field is not an encoded-token oracle.')
    need(len(table)==len(ordered),'whole unique ordered current construction population')
    guards={tuple(r['path']):r for r in read(PREDICATE/'predicate-values-qualified.json')['rows']}
    scalars={tuple(r['path']):r for r in read(SCALAR/'scalars.json')['members']}
    regexes={tuple(r['path']):r for r in read(REGEX/'regexes.json')['members']}
    authored={r['helper']:r for r in read(REGEX/'regexes.json')['authored']}
    bindings={};paths={}
    for row in original['operands']:
        path=tuple(row['path']);schema=row['schema'];selected=[]
        if path in guards:
            selected=[identifier for identifier in ordered if table[identifier]['kind']=='predicate'
                      and table[identifier]['case']['value_class']==guards[path]['value_class']]
        elif schema in ('scalar','context_scalar'):
            value_id=scalars[path]['value']
            selected=[identifier for identifier in ordered if table[identifier]['kind']=='scalar'
                      and table[identifier]['case']['value_id']==value_id]
        elif schema=='regex_source':
            body=authored[regexes[path]['helper']]['body']
            selected=[identifier for identifier in ordered if table[identifier]['kind']=='regex'
                      and table[identifier]['case']['body']==body]
        else:
            need(schema in ('reference','context_reference'),'independent closed original reference schema')
        identifier=pin(canonical(list(path)))['sha256'];paths[path]=identifier
        bindings[identifier]=dict(source=row,current_construction_cases=selected,
            original_token=dict(state='unmeasured original token',
                qualification='complete known source value/role retained; original settings/flags/identity are not selected',
                substitute_scalar_prefix_wildcard=False))
    profile=dict(MaxArgLen=64,MaxArgNums=8,MaxEvalLen=0,RefArgFormatter=None)
    unknown=dict(settings_formatter='unmeasured',scalar_flags_encoding='unmeasured',
        regexp_flags_encoding_provider_identity='unmeasured',reference_referent_receiver_identity='unmeasured',
        private_framework_eval_meanings='unmeasured',encoded_original_header_equality='not compared in this source-selected slice')
    headers=[];lookup={};used=set()
    for path,node in visited:
        if not {'function','arguments'}<=set(node):
            continue
        need(type(node['function']) is str and type(node['arguments']) is list,'independent closed source frame/argument schema')
        identifiers=[]
        for index,argument in enumerate(node['arguments']):
            identifier=paths[tuple(path+['arguments',index])]
            need(same(bindings[identifier]['source']['input'],argument),'independent whole source argument/header association')
            identifiers.append(identifier);used.add(identifier)
        kind='block_eval_source_marker' if node['function']=='eval {...}' else 'source_call_header_expression'
        identifier=pin(canonical(path))['sha256'];lookup[tuple(path)]=identifier
        slots=[]
        for binding in identifiers[:profile['MaxArgNums']]:
            active=[case for case in bindings[binding]['current_construction_cases']
                    if table[case]['kind']=='predicate' or table[case]['case']['limit']==profile['MaxArgLen']]
            slots.append(dict(argument_id=binding,cases=active,
                unresolved_reference_token=bindings[binding]['source']['qualification']['kind']=='source reference role and kind only'))
        headers.append(dict(id=identifier,path=path,source_metadata={key:node[key] for key in node if key!='arguments'},
            source_argument_ids=identifiers,
            expression=dict(kind=kind,function=node['function'],opening='(' if kind=='source_call_header_expression' else '',
                argument_ids=identifiers,separator=', ',closing=')' if kind=='source_call_header_expression' else '',
                original_profile_parameter=unknown),
            current_conditional_form=dict(profile=profile,visible_argument_ids=identifiers[:8],hidden_argument_ids=identifiers[8:],
                remaining_arguments=len(identifiers)>8,slots=slots,
                qualification='Complete source-selected expression under the dated public grammar; no original encoded-header equality or reference token is asserted.')))
    # Restore each frame from its exact source metadata and complete argument
    # bindings. This preserves every non-frame phase/group/evidence field too.
    def allocate(node,path):
        if tuple(path) in lookup:
            return {'source_header':lookup[tuple(path)]}
        if isinstance(node,list):
            return [allocate(value,path+[index]) for index,value in enumerate(node)]
        if isinstance(node,dict):
            return {key:allocate(node[key],path+[key]) for key in node}
        return node
    loads=[]
    for path,node in visited:
        if 'load' in node:
            loads.append(dict(path=path+['load'],source_operator='do',diagnostic_marker=node['load'],
                diagnostic_marker_is_source_operator=False,
                qualification='Whole inherited source/public diagnostic boundary; source do is not rewritten to require.'))
    return dict(scope=SCOPE,original_unmeasured=unknown,current_profile=profile,operands=bindings,
        current_construction_cases=table,headers=headers,source_allocation=allocate(source['modes'],['modes']),loads=loads,
        unframed_operand_ids=[identifier for identifier in bindings if identifier not in used],
        source_frame_contracts=pin(canonical(source['frame_model'])),source_scope=source['scope'],source_value_scope=original['scope'],
        display_contract_scope=read(DISPLAY/'repaired-catalogue.json')['role'],inputs={str(p):pin(p.read_bytes()) for p in inputs()},
        raw_comparison='not performed; every whole hypothesis is selected before own original raw-header comparison')


def conditional(expected):
    rows=[];table=expected['current_construction_cases']
    for header in expected['headers']:
        form=header['current_conditional_form'];unresolved=[];tokens=[]
        for slot in form['slots']:
            alternatives=[]
            for identifier in slot['cases']:
                item=table[identifier]
                spelling=item['case']['display_token'] if item['kind']=='predicate' else item['case']['display']['token']
                if spelling not in alternatives:
                    alternatives.append(spelling)
            if not slot['unresolved_reference_token'] and len(alternatives)==1:
                tokens+=alternatives
            else:
                unresolved.append(dict(argument_id=slot['argument_id'],qualified_current_alternatives=alternatives,
                    reference_token_unmeasured=slot['unresolved_reference_token']))
        marker=header['expression']['kind']=='block_eval_source_marker'
        if not unresolved and not marker:
            all_tokens=tokens+(['...'] if form['remaining_arguments'] else [])
            text=header['source_metadata']['function']+'('+', '.join(all_tokens)+')'
        else:
            text=None
        rows.append(dict(header_id=header['id'],path=header['path'],profile=form['profile'],known_conditional_header=text,
            unresolved_slots=unresolved,source_eval_marker=marker,complete_source_argument_ids=header['source_argument_ids'],
            hidden_argument_ids=form['hidden_argument_ids'],
            meaning='Source-selected conditional public-grammar hypothesis only; unresolved slots are typed evidence boundaries and supply no encoded token or wildcard matcher.'))
    return dict(scope=SCOPE,headers=rows,
        role='Generated known conditional header text and complete unresolved slot allocation only; no original or new native-header capture/comparison.')


def validate(product,current):
    need(product['scope']==SCOPE,'unchanged complete source-header qualification scope')
    wanted=expected()
    need(set(product)==set(wanted),'closed complete source-header product schema')
    for field,value in wanted.items():
        need(same(product[field],value),'entire independent source-header field: '+field)
    headers={row['id']:row for row in product['headers']}
    def restore(node):
        if isinstance(node,dict) and set(node)=={'source_header'}:
            header=headers[node['source_header']]
            return dict(header['source_metadata'],arguments=[product['operands'][identifier]['source']['input']
                for identifier in header['source_argument_ids']])
        if isinstance(node,dict):
            return {key:restore(value) for key,value in node.items()}
        if isinstance(node,list):
            return [restore(value) for value in node]
        return node
    need(same(restore(product['source_allocation']),read(CENSUS/'source-models.json')['modes']),
         'whole original source modes reconstruct from complete header expressions and unframed evidence')
    wanted_current=conditional(wanted)
    need(same(current,wanted_current),'entire independent known conditional header/unresolved/hidden allocation')
    return dict(source_headers=pin(canonical(wanted)),conditional_headers=pin(canonical(wanted_current)),
        restored_modes=pin(canonical(restore(product['source_allocation']))),scope=SCOPE)


def public_contract():
    namespace={'__name__':'header_qualified_public_oracle'}
    programme=DISPLAY/'oracle_repaired.py'
    exec(compile(programme.read_bytes(),str(programme),'exec'),namespace)
    result=namespace['validate'](catalogue=read(DISPLAY/'repaired-catalogue.json'),
        hypotheses=read(DISPLAY/'repaired-hypotheses.json'),wire=json.loads(read(DISPLAY/'repaired-native.json')['stdout']),
        products=read(DISPLAY/'repaired-joined.json')['products'])
    parent=read(VALUES/'product-qualified.json')['public_constructions']
    for kind,directory in [('predicate',PREDICATE),('scalar',SCALAR),('regex',REGEX)]:
        fixture=parent[kind];native=fixture['native'];plan=pin(canonical(fixture['plan']));driver=pin(fixture['driver'].encode())
        need(type(native['status']) is int and native['status']==0 and native['stderr']=='','actual typed full inherited public construction success')
        if kind=='predicate':
            need(native['plan']==plan and native['driver']==driver,'whole inherited actual predicate plan/driver binding')
        else:
            need(native['inputs'][str(directory/'plan.json')]==plan
                 and native['inputs'][str(directory/'native.pl')]==driver,'whole inherited actual scalar/regex plan/driver binding')
    return dict(programme=pin(programme.read_bytes()),whole_public_products=pin(canonical(result)),
        meaning='Complete dated public grammar and whole constructor receipt binding only; original formatter/settings/native identities remain unmeasured.')
