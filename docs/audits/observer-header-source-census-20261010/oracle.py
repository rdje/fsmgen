"""Independently reconstruct explicit qualified groups and operand obligations."""
from common import BASE, ROLE, SOURCE, canonical, need, pin, same


def qualification(arg):
    keys = frozenset(arg)
    shapes = {
        frozenset(('kind','role','value')): 'scalar',
        frozenset(('kind','role','reference_kind')): 'reference',
        frozenset(('kind','role')): 'false_predicate',
        frozenset(('kind','role','source_pattern','display_body')): 'regex_source',
        frozenset(('expression','match','native_scalar_encoding','position','role','source_value')): 'context_scalar',
        frozenset(('display_class','expression','match','native_identity','position','reference_kind','referent_contents','role')): 'context_reference',
    }
    need(keys in shapes, 'closed independent operand schema')
    schema = shapes[keys]
    need(('kind' not in arg or arg['kind'] == schema) and type(arg['role']) is str and arg['role'],
         'independent source kind and role')
    if schema == 'scalar' or schema == 'context_scalar':
        value = arg['value'] if schema == 'scalar' else arg['source_value']
        need(value is None or type(value) in (str, int), 'independent typed scalar value')
        knowledge = 'declared ' + type(value).__name__ + ' value; original flags/constructor spelling not inferred'
        pending = ['source_scalar_constructor_encoding']
        if arg['role'] == 'entire_context_and_inner_error':
            knowledge = 'entire inherited serialized inner evidence; no new semantic header oracle'
            pending.append('inherited_serialized_operand')
        if schema == 'context_scalar':
            need(arg['native_scalar_encoding'] == 'not measured', 'independent unmeasured context encoding')
            if arg['role'] == 'guard predicate':
                pending.append('false_scalar_representation')
    elif schema == 'false_predicate':
        knowledge = 'logical false only; no literal zero, empty string or undef selected'
        pending = ['false_scalar_representation']
    elif schema == 'regex_source':
        need(all(type(arg[k]) is str for k in ('source_pattern','display_body')), 'independent complete regex declaration')
        knowledge = 'whole qualified source pattern/body; exact constructor flags and encoding still require qualification'
        pending = ['regex_constructor_flags_encoding']
    else:
        need(type(arg['reference_kind']) is str, 'independent source reference kind')
        knowledge = 'source reference role/kind only; original address, flags, referent and identity unmeasured'
        pending = ['reference_role_vs_original_identity']
    return dict(schema=schema, value_knowledge=knowledge, obligations=pending)


def reconstruct(source, source_bytes):
    cases, phases, groups, frames, operands, loads = [], [], [], [], [], []
    obligations = {}

    def mark(name, location):
        obligations.setdefault(name, []).append(location)

    def group(location, members, is_frames=True):
        need(type(members) is list, 'independent ordered source group')
        groups.append(dict(path=location, members=[location + [i] for i in range(len(members))]))
        if is_frames:
            for f, frame in enumerate(members):
                need(set(frame) in ({'arguments','function','role'}, {'arguments','function','call_site'},
                                   {'arguments','function','parameters','whole_source_body'}),
                     'independent closed full source frame')
                need(type(frame['arguments']) is list and type(frame['function']) is str,
                     'independent ordered source frame arguments')
                fp = location + [f]
                frames.append(dict(path=fp, input=frame))
                operands.extend(dict(path=fp + ['arguments', a], input=arg, **qualification(arg))
                                for a, arg in enumerate(frame['arguments']))

    for m in range(len(source['modes'])):
        mode = source['modes'][m]
        need(set(mode) == {'mode','cases'}, 'independent complete mode schema')
        for c in range(len(mode['cases'])):
            case = mode['cases'][c]
            need(set(case) == {'caller','domain','exception','helper','index','kind','phases','subtest'},
                 'independent complete source case schema')
            cp = ['modes', m, 'cases', c]
            cases.append(dict(path=cp, mode=mode['mode'], input={k:case[k] for k in case if k != 'phases'}))
            for p in range(len(case['phases'])):
                phase = case['phases'][p]
                need(set(phase) == {'family','guard_source','inferred_class','native_class','own','phase','public'},
                     'independent complete source phase schema')
                pp = cp + ['phases',p]
                own, public = phase['own'], phase['public']
                need(set(own) == {'body','core','entry','helper','load','operations','phase'}, 'independent complete own group schema')
                need(set(public) == {'body','callback','entry','historical_profile','load','own_eval_boundaries','phase',
                      'public_name','public_path','receiver','relationship','source_operator'}, 'independent complete public group schema')
                phases.append(dict(path=pp,
                    input={k:phase[k] for k in ('family','guard_source','inferred_class','native_class','phase')},
                    own={k:own[k] for k in ('load','phase')},
                    operations=[{k:v for k,v in op.items() if k != 'frames'} for op in own['operations']],
                    public={k:public[k] for k in public if k not in ('body','entry','own_eval_boundaries','public_path')}))
                for name in ('original_display_profile','opaque_framework_interval',
                             'load_source_operator_vs_diagnostic_marker','public_receiver_original_token'):
                    mark(name, pp)
                for key in ('core','helper','body','entry'):
                    group(pp + ['own',key], own[key])
                group(pp + ['own','operations'], own['operations'], False)
                for n, operation in enumerate(own['operations']):
                    need(set(operation) in ({'argument_role_bridge','frames','kind','operation_lookup'},
                         {'argument_role_bridge','frames','kind','operation_lookup','role_bridge_authority'}),
                         'independent complete observer operation metadata')
                    group(pp + ['own','operations',n,'frames'], operation['frames'])
                for key in ('body','entry'):
                    group(pp + ['public',key], public[key])
                group(pp + ['public','own_eval_boundaries'], public['own_eval_boundaries'], False)
                for n, boundary in enumerate(public['own_eval_boundaries']):
                    # The outer group already names these lists; their complete
                    # ordered frames share its path and are not a second group.
                    for f, frame in enumerate(boundary):
                        fp = pp + ['public','own_eval_boundaries',n,f]
                        need(type(frame['arguments']) is list and type(frame['function']) is str,
                             'independent complete public own-eval frame')
                        frames.append(dict(path=fp, input=frame))
                        operands.extend(dict(path=fp + ['arguments',a], input=arg, **qualification(arg))
                                        for a,arg in enumerate(frame['arguments']))
                group(pp + ['public','public_path'], public['public_path'], False)
                for key in ('callback','public_name'):
                    arg = public[key]
                    operands.append(dict(path=pp + ['public',key], input=arg, **qualification(arg)))
                need(public['source_operator'] == 'do' and public['historical_profile'] == 'unmeasured',
                     'independent original source do and historical profile scope')
                for origin, value in (('own',own),('public',public)):
                    loads.append(dict(path=pp + [origin,'load'], marker=value['load'], source_operator='do',
                        meaning='diagnostic require marker does not change source do operator'))
    for collection in (groups, frames, operands, loads):
        collection.sort(key=lambda r: r['path'])
    for arg in operands:
        for name in arg['obligations']:
            mark(name, arg['path'])
    return dict(role=ROLE, source=dict(path=str(BASE / 'source-models.json'), identity=pin(source_bytes),
                  qualified_source=dict(path=str(SOURCE / 'source-models.json'), identity=pin((SOURCE / 'source-models.json').read_bytes())),
                scope=source['scope'], historical=source['frame_model']['historical']),
                cases=cases, phases=phases, groups=groups, frames=frames, operands=operands, loads=loads, obligations=obligations)


def validate(candidate, source, source_bytes):
    expected = reconstruct(source, source_bytes)
    need(set(candidate) == set(expected), 'closed complete census product; no premature header claim')
    for key in expected:
        need(same(candidate[key], expected[key]), 'complete independent source census: ' + key)
    return dict(source=pin(source_bytes), product=pin(canonical(candidate)),
        counts={k:len(expected[k]) for k in ('cases','phases','groups','frames','operands','loads')},
        obligation_members={k:len(v) for k,v in expected['obligations'].items()}, role=ROLE)
