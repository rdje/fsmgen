"""Join complete qualified values and explicit boundaries before opaque intake."""
from common import BASE,CENSUS,PREDICATE,SCALAR,REGEX,SCOPE,canonical,load,need,pin,read,save


def key(path):
    return tuple(path)


def source_product(source,census,predicate,scalar,regex,regex_plan):
    predicates={key(r['path']):i for i,r in enumerate(predicate['rows'])}
    scalars={key(r['path']):i for i,r in enumerate(scalar['members'])}
    regexes={key(r['path']):i for i,r in enumerate(regex['members'])}
    authored={r['helper']:r for r in regex['authored']}
    operands=[]
    for row in census['operands']:
        path,operand,schema=row['path'],row['input'],row['schema']
        if key(path) in predicates:
            index=predicates[key(path)]; value=predicate['rows'][index]
            need(value['input']==operand,'complete original predicate/source operand join')
            qualification=dict(kind='qualified whole guard construction',source_row=index,
                source_row_identity=pin(canonical(value)),defined=value['defined'],string_value=value['string_value'],
                numeric_value=value['numeric_value'],source_expression=value['source_expression'],
                original_native_scalar_flags=value['original_native_scalar_flags'],
                meaning='Source guard determines the value; a declared logical zero field is not an encoded-token oracle.')
        elif schema in ('scalar','context_scalar'):
            index=scalars[key(path)]; member=scalar['members'][index]
            need(member['operand']==operand and member['schema']==schema,'whole scalar member/source/schema join')
            value=scalar['values'][member['value']]
            qualification=dict(kind='qualified complete scalar value',source_member=index,
                value_id=member['value'],value=value['value'],constructor=value['constructor'],
                evidence_role=member['evidence_role'],original_native_scalar_flags='not measured')
        elif schema=='regex_source':
            index=regexes[key(path)]; member=regex['members'][index]
            need(member['operand']==operand,'whole regex member/source role join')
            recipe=authored[member['helper']]
            qualification=dict(kind='qualified whole authored regex',source_member=index,helper=member['helper'],
                authored=recipe,current_cases=[r for r in regex_plan['cases'] if r['body']==recipe['body']],
                original_native_flags_encoding='not measured',original_regexp_provider_identity='not measured')
        else:
            need(schema in ('reference','context_reference'),'closed remaining reference boundary schema')
            qualification=dict(kind='source reference role and kind only',reference_kind=operand['reference_kind'],
                original_address_identity_flags_referent='not measured',current_fixture_borrowing='forbidden')
        operands.append(dict(path=path,schema=schema,input=operand,qualification=qualification))
    phases=[]
    for m,mode in enumerate(source['modes']):
        for c,case in enumerate(mode['cases']):
            for p,phase in enumerate(case['phases']):
                public=phase['public']
                need(public['historical_profile']=='unmeasured' and public['source_operator']=='do',
                     'whole original profile and source do boundary')
                need(public['load']=='require ./t/1986-isf-record-port-value-gates.t'
                     and phase['own']['load']==public['load'],'source do versus whole diagnostic require marker')
                phases.append(dict(path=['modes',m,'cases',c,'phases',p],mode=mode['mode'],domain=case['domain'],
                    index=case['index'],phase=p,source_public=public,source_phase={k:v for k,v in phase.items() if k not in ('own','public')},
                    original_settings_formatter='unmeasured',receiver_contents_class_identity='unmeasured',
                    private_framework_eval_meaning='unmeasured',diagnostic_marker_changes_source_operator=False))
    operand_positions={key(r['path']):i for i,r in enumerate(operands)}
    phase_positions={key(r['path']):i for i,r in enumerate(phases)}
    obligations={}
    for name,paths in census['obligations'].items():
        obligations[name]=[dict(path=path,resolution_kind='operand' if key(path) in operand_positions else 'phase',
            resolution_index=(operand_positions if key(path) in operand_positions else phase_positions)[key(path)]) for path in paths]
    return dict(scope=SCOPE,operands=operands,phases=phases,obligations=obligations,loads=census['loads'],
        source_scope=source['scope'],historical_scope=source['frame_model']['historical'],
        predicate_public_profile=predicate['current_profile'],predicate_original_settings=predicate['original_observer_settings'],
        regex_public_profile=regex_plan['profile'],
        dependencies={str(path):pin(path.read_bytes()) for path in [CENSUS/'source-models.json',CENSUS/'census.json',
            PREDICATE/'predicate-values-qualified.json',SCALAR/'scalars.json',REGEX/'regexes.json',REGEX/'plan.json']})


def main():
    product=source_product(read(CENSUS/'source-models.json'),read(CENSUS/'census.json'),
        read(PREDICATE/'predicate-values-qualified.json'),read(SCALAR/'scalars.json'),read(REGEX/'regexes.json'),read(REGEX/'plan.json'))
    need(not (BASE/'opaque-evidence.json').exists(),'complete source hypotheses before own opaque-evidence attachment')
    save('source-products.json',product)
    save('source-selection.json',dict(scope=SCOPE,opaque_evidence_present=False,
        product=pin(canonical(product)),programs={str(p):pin(p.read_bytes()) for p in sorted(BASE.glob('*.py'))}))
    print('PASS complete qualified source values, original obligation allocation and explicit opaque/profile boundaries before own opaque attachment.')


if __name__=='__main__':
    main()
