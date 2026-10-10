"""Independent direct-source traversal and whole boundary/value reconstruction."""
from common import CENSUS,PREDICATE,SCALAR,REGEX,PUBLIC,RAW,SCOPE,canonical,need,pin,same


def traverse(source):
    pending=[(source['modes'],['modes'])];operands=[];loads=[]
    while pending:
        node,path=pending.pop()
        if isinstance(node,list):
            pending.extend((node[i],path+[i]) for i in reversed(range(len(node))))
        elif isinstance(node,dict):
            if 'role' in node and ('kind' in node or 'expression' in node):
                schema=node.get('kind')
                if schema is None:
                    schema='context_scalar' if 'source_value' in node else 'context_reference'
                operands.append(dict(path=path,input=node,schema=schema))
            if 'load' in node:
                loads.append(dict(path=path+['load'],marker=node['load'],source_operator='do',
                    meaning='diagnostic require marker does not change source do operator'))
            pending.extend((node[k],path+[k]) for k in sorted(node,reverse=True))
    return operands,loads


def source_expected(source,predicate,scalar,regex,regex_plan):
    original,loads=traverse(source)
    pred_by_path={tuple(r['path']):(i,r) for i,r in enumerate(predicate['rows'])}
    scalar_by_path={tuple(r['path']):(i,r) for i,r in enumerate(scalar['members'])}
    regex_by_path={tuple(r['path']):(i,r) for i,r in enumerate(regex['members'])}
    helpers={r['helper']:r for r in regex['authored']}
    operands=[];obligations={};phases=[]
    for m in range(len(source['modes'])):
        mode=source['modes'][m]
        for c in range(len(mode['cases'])):
            case=mode['cases'][c]
            for p in range(len(case['phases'])):
                phase=case['phases'][p];public=phase['public'];path=['modes',m,'cases',c,'phases',p]
                need(public['historical_profile']=='unmeasured' and public['source_operator']=='do'
                     and public['load']==phase['own']['load']=='require ./t/1986-isf-record-port-value-gates.t',
                     'independent original profile and do/require roles')
                phases.append(dict(path=path,mode=mode['mode'],domain=case['domain'],index=case['index'],phase=p,
                    source_public=public,source_phase={k:phase[k] for k in phase if k not in {'own','public'}},
                    original_settings_formatter='unmeasured',receiver_contents_class_identity='unmeasured',
                    private_framework_eval_meaning='unmeasured',diagnostic_marker_changes_source_operator=False))
                for name in ('original_display_profile','opaque_framework_interval','load_source_operator_vs_diagnostic_marker',
                             'public_receiver_original_token'):
                    obligations.setdefault(name,[]).append(dict(path=path,resolution_kind='phase',resolution_index=len(phases)-1))
    for index,row in enumerate(original):
        path,schema,operand=row['path'],row['schema'],row['input']
        need(schema in ('scalar','context_scalar','false_predicate','regex_source','reference','context_reference'),
             'independent closed source operand schema')
        names=[]
        if schema in ('scalar','context_scalar'):
            names.append('source_scalar_constructor_encoding')
            if operand['role']=='entire_context_and_inner_error':
                names.append('inherited_serialized_operand')
            if schema=='context_scalar' and operand['role']=='guard predicate':
                names.append('false_scalar_representation')
        elif schema=='false_predicate':
            names.append('false_scalar_representation')
        elif schema=='regex_source':
            names.append('regex_constructor_flags_encoding')
        else:
            names.append('reference_role_vs_original_identity')
        if tuple(path) in pred_by_path:
            i,value=pred_by_path[tuple(path)]
            need(same(value['input'],operand),'independent whole guard/source operand association')
            qualification=dict(kind='qualified whole guard construction',source_row=i,source_row_identity=pin(canonical(value)),
                defined=value['defined'],string_value=value['string_value'],numeric_value=value['numeric_value'],
                source_expression=value['source_expression'],original_native_scalar_flags=value['original_native_scalar_flags'],
                meaning='Source guard determines the value; a declared logical zero field is not an encoded-token oracle.')
        elif schema in {'scalar','context_scalar'}:
            i,member=scalar_by_path[tuple(path)]
            need(same(member['operand'],operand) and member['schema']==schema,'independent whole scalar member/type/source association')
            value=scalar['values'][member['value']]
            qualification=dict(kind='qualified complete scalar value',source_member=i,value_id=member['value'],
                value=value['value'],constructor=value['constructor'],evidence_role=member['evidence_role'],
                original_native_scalar_flags='not measured')
        elif schema=='regex_source':
            i,member=regex_by_path[tuple(path)]
            need(same(member['operand'],operand),'independent whole regex member/role/source association')
            helper=helpers[member['helper']]
            qualification=dict(kind='qualified whole authored regex',source_member=i,helper=member['helper'],authored=helper,
                current_cases=list(filter(lambda r:r['body']==helper['body'],regex_plan['cases'])),
                original_native_flags_encoding='not measured',original_regexp_provider_identity='not measured')
        else:
            qualification=dict(kind='source reference role and kind only',reference_kind=operand['reference_kind'],
                original_address_identity_flags_referent='not measured',current_fixture_borrowing='forbidden')
        operands.append(dict(path=path,schema=schema,input=operand,qualification=qualification))
        for name in names:
            obligations.setdefault(name,[]).append(dict(path=path,resolution_kind='operand',resolution_index=index))
    return dict(scope=SCOPE,operands=operands,phases=phases,obligations=obligations,loads=loads,
        source_scope=source['scope'],historical_scope=source['frame_model']['historical'],
        predicate_public_profile=predicate['current_profile'],predicate_original_settings=predicate['original_observer_settings'],
        regex_public_profile=regex_plan['profile'],dependencies={str(path):pin(path.read_bytes()) for path in
            (CENSUS/'source-models.json',CENSUS/'census.json',PREDICATE/'predicate-values-qualified.json',
             SCALAR/'scalars.json',REGEX/'regexes.json',REGEX/'plan.json')})


def verify_source(source,predicate,scalar,regex,regex_plan,product):
    need(product['scope']==SCOPE,'unchanged source/profile/native scope')
    wanted=source_expected(source,predicate,scalar,regex,regex_plan)
    need(set(product)==set(wanted),'closed whole boundary product')
    for field in wanted:
        need(same(product[field],wanted[field]),'whole independent source/profile field: '+field)
    return dict(source=pin(canonical(wanted)),scope=SCOPE)


def verify_opaque(source,public,raw,product):
    need(product['scope']==SCOPE,'unchanged inherited original-evidence scope')
    public_modes={m['mode']:m for m in public['observations']['modes']}
    raw_modes={m['mode']:m for m in raw['inventories']}
    phases=[];records={}
    for mi,mode in enumerate(source['modes']):
        for ci,case in enumerate(mode['cases']):
            matches=[c for c in public_modes[mode['mode']]['cases'] if c['domain']==case['domain'] and c['index']==case['index']]
            observations=[r for r in raw_modes[mode['mode']]['domains'][case['domain']]['nonempty'] if r['index']==case['index']]
            need(len(matches)==len(observations)==1,'independent unique original case/body/public allocation')
            public_case,record=matches[0],observations[0]
            need(same(public_case['original_body'],record['body_identity']) and pin(record['body'].encode())==record['body_identity'],
                 'independent complete inherited body byte custody')
            key=[mode['mode'],case['domain'],case['index']];identifier=pin(canonical(key))['sha256']
            records[identifier]=dict(key=key,record=record,
                meaning='Whole inherited original body/record custody only; no new semantic header, identity or private-meaning oracle.')
            need(len(public_case['phases'])==len(case['phases']),'independent complete original opaque phase allocation')
            for pi,phase in enumerate(case['phases']):
                original=public_case['phases'][pi]
                need(original['phase']==pi and original['source_operator']==phase['public']['source_operator']=='do',
                     'independent original phase/source do role')
                phases.append(dict(path=['modes',mi,'cases',ci,'phases',pi],body=identifier,original_public_boundary=original,
                    original_public_case={k:public_case[k] for k in public_case if k!='phases'},
                    meaning='Every original receiver token, private framework/eval interval and full raw body retains as dated opaque evidence; native identity/settings/private semantics remain unmeasured.'))
    wanted=dict(scope=SCOPE,phases=phases,original_records=records,inputs={str(p):pin(p.read_bytes()) for p in (PUBLIC,RAW)},
        public_scope=public['observations']['scope'],raw_scope=raw['scope'])
    need(set(product)==set(wanted),'closed whole opaque evidence product')
    for field in wanted:
        need(same(product[field],wanted[field]),'whole independent original opaque field: '+field)
    return dict(opaque=pin(canonical(wanted)),scope=SCOPE)
