"""Select complete source header expressions before any own original raw intake."""
from common import BASE, CENSUS, VALUES, DISPLAY, PREDICATE, SCALAR, REGEX, SCOPE, canonical, inputs, load, need, pin, read, same, save

PROFILE={'MaxArgLen':64,'MaxArgNums':8,'MaxEvalLen':0,'RefArgFormatter':None}
ORIGINAL={
    'settings_formatter':'unmeasured',
    'scalar_flags_encoding':'unmeasured',
    'regexp_flags_encoding_provider_identity':'unmeasured',
    'reference_referent_receiver_identity':'unmeasured',
    'private_framework_eval_meanings':'unmeasured',
    'encoded_original_header_equality':'not compared in this source-selected slice',
}


def cases():
    result={}
    for kind,directory in [('scalar',SCALAR),('regex',REGEX)]:
        for row in read(directory/'plan.json')['cases']:
            identifier=kind+':'+row['id']
            need(identifier not in result,'unique complete current constructor case')
            result[identifier]=dict(kind=kind,case=row,
                meaning='Dated qualified source-neutral current construction only; no original flags/settings/identity attribution.')
    for fixture in read(PREDICATE/'fixture-plan-qualified.json')['fixtures']:
        identifier='predicate:'+fixture['name']
        need(identifier not in result,'unique whole predicate fixture')
        result[identifier]=dict(kind='predicate',case=fixture,
            meaning='Dated qualified source guard construction only; a logical-zero source field is not an encoded-token oracle.')
    return result


def bindings(qualified,case_table):
    predicate={tuple(r['path']):r for r in read(PREDICATE/'predicate-values-qualified.json')['rows']}
    result={}
    for row in qualified['operands']:
        path=row['path'];value=row['qualification'];kind=value['kind'];key=pin(canonical(path))['sha256']
        selected=[]
        if kind=='qualified whole guard construction':
            source=predicate[tuple(path)]
            selected=[identifier for identifier,item in case_table.items() if item['kind']=='predicate'
                      and item['case']['value_class']==source['value_class']]
        elif kind=='qualified complete scalar value':
            selected=[identifier for identifier,item in case_table.items() if item['kind']=='scalar'
                      and item['case']['value_id']==value['value_id']]
        elif kind=='qualified whole authored regex':
            selected=[identifier for identifier,item in case_table.items() if item['kind']=='regex'
                      and item['case']['body']==value['authored']['body']]
        else:
            need(kind=='source reference role and kind only','closed complete source-header operand qualification')
        need(bool(selected) or kind=='source reference role and kind only','every known complete value has qualified construction evidence')
        need(key not in result,'unique whole source operand path')
        result[key]=dict(source=row,current_construction_cases=selected,
            original_token=dict(state='unmeasured original token',qualification='complete known source value/role retained; original settings/flags/identity are not selected',
                substitute_scalar_prefix_wildcard=False))
    return result


def walk(node,path):
    if isinstance(node,dict):
        yield path,node
        for field in sorted(node):
            yield from walk(node[field],path+[field])
    elif isinstance(node,list):
        for index,member in enumerate(node):
            yield from walk(member,path+[index])


def active_cases(binding,case_table):
    return [identifier for identifier in binding['current_construction_cases']
            if case_table[identifier]['kind']=='predicate' or case_table[identifier]['case']['limit']==64]


def product():
    source=read(CENSUS/'source-models.json')
    qualified=read(VALUES/'product-qualified.json')['source_values']
    table=cases();operands=bindings(qualified,table)
    by_path={tuple(v['source']['path']):identifier for identifier,v in operands.items()}
    headers=[];header_paths={};used=set()
    for path,node in walk(source['modes'],['modes']):
        if 'function' not in node or 'arguments' not in node:
            continue
        need(type(node['function']) is str and type(node['arguments']) is list,'closed source call/header schema')
        argument_ids=[]
        for index,argument in enumerate(node['arguments']):
            arg_path=tuple(path+['arguments',index])
            identifier=by_path[arg_path]
            need(same(operands[identifier]['source']['input'],argument),'whole source/header operand association')
            argument_ids.append(identifier);used.add(identifier)
        visible=argument_ids[:8]
        header_id=pin(canonical(path))['sha256'];header_paths[tuple(path)]=header_id
        kind='block_eval_source_marker' if node['function']=='eval {...}' else 'source_call_header_expression'
        headers.append(dict(id=header_id,path=path,source_metadata={k:v for k,v in node.items() if k!='arguments'},
            source_argument_ids=argument_ids,
            expression=dict(kind=kind,function=node['function'],opening='' if kind=='block_eval_source_marker' else '(',
                argument_ids=argument_ids,separator=', ',closing='' if kind=='block_eval_source_marker' else ')',
                original_profile_parameter=ORIGINAL),
            current_conditional_form=dict(profile=PROFILE,visible_argument_ids=visible,hidden_argument_ids=argument_ids[8:],
                remaining_arguments=len(argument_ids)>8,
                slots=[dict(argument_id=identifier,cases=active_cases(operands[identifier],table),
                    unresolved_reference_token=operands[identifier]['source']['qualification']['kind']=='source reference role and kind only')
                    for identifier in visible],
                qualification='Complete source-selected expression under the dated public grammar; no original encoded-header equality or reference token is asserted.')))
    def skeleton(node,path):
        if tuple(path) in header_paths:
            return dict(source_header=header_paths[tuple(path)])
        if isinstance(node,dict):
            return {key:skeleton(value,path+[key]) for key,value in node.items()}
        if isinstance(node,list):
            return [skeleton(value,path+[index]) for index,value in enumerate(node)]
        return node
    allocation=skeleton(source['modes'],['modes'])
    loads=[dict(path=path+['load'],source_operator='do',diagnostic_marker=node['load'],
                diagnostic_marker_is_source_operator=False,
                qualification='Whole inherited source/public diagnostic boundary; source do is not rewritten to require.')
           for path,node in walk(source['modes'],['modes']) if 'load' in node]
    return dict(scope=SCOPE,original_unmeasured=ORIGINAL,current_profile=PROFILE,
        operands=operands,current_construction_cases=table,headers=headers,source_allocation=allocation,loads=loads,
        unframed_operand_ids=[identifier for identifier in operands if identifier not in used],
        source_frame_contracts=pin(canonical(source['frame_model'])),
        source_scope=source['scope'],source_value_scope=qualified['scope'],
        display_contract_scope=read(DISPLAY/'repaired-catalogue.json')['role'],
        inputs={str(path):pin(path.read_bytes()) for path in inputs()},
        raw_comparison='not performed; every whole hypothesis is selected before own original raw-header comparison')


if __name__=='__main__':
    need(not (BASE/'original-raw-intake.json').exists(),'complete source hypotheses before own original raw intake')
    selected=product()
    save('headers.json',selected)
    save('selection.json',dict(scope=SCOPE,product=pin(canonical(selected)),original_raw_intake_present=False,
        programmes={str(p):pin(p.read_bytes()) for p in sorted(BASE.glob('*.py'))}))
    print('PASS complete source-selected header expressions, full argument/value/order/role and conditional public grammar, typed original uncertainties and do/diagnostic roles before raw comparison.')
