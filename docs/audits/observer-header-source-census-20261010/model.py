"""Enumerate source declarations without rendering any original header token."""
from common import BASE, ROLE, SOURCE, need, pin

SCHEMAS = {
    'scalar': {'kind', 'role', 'value'},
    'reference': {'kind', 'role', 'reference_kind'},
    'false_predicate': {'kind', 'role'},
    'regex_source': {'kind', 'role', 'source_pattern', 'display_body'},
    'context_scalar': {'expression', 'match', 'native_scalar_encoding', 'position', 'role', 'source_value'},
    'context_reference': {'display_class', 'expression', 'match', 'native_identity', 'position',
                          'reference_kind', 'referent_contents', 'role'},
}
GROUPS = {'body', 'core', 'entry', 'helper', 'operations', 'frames', 'own_eval_boundaries', 'public_path'}


def classify(value):
    category = value.get('kind')
    if category is None:
        category = 'context_scalar' if 'source_value' in value else 'context_reference'
    need(category in SCHEMAS and set(value) == SCHEMAS[category], 'closed qualified operand schema')
    need(type(value['role']) is str and bool(value['role']), 'declared source operand role')
    obligations = []
    if category in ('scalar', 'context_scalar'):
        scalar = value['value' if category == 'scalar' else 'source_value']
        need(scalar is None or type(scalar) in (str, int), 'typed complete declared source scalar')
        knowledge = 'declared ' + type(scalar).__name__ + ' value; original flags/constructor spelling not inferred'
        obligations.append('source_scalar_constructor_encoding')
        if value['role'] == 'entire_context_and_inner_error':
            knowledge = 'entire inherited serialized inner evidence; no new semantic header oracle'
            obligations.append('inherited_serialized_operand')
        if category == 'context_scalar':
            need(value['native_scalar_encoding'] == 'not measured', 'context scalar encoding remains unmeasured')
            if value['role'] == 'guard predicate':
                obligations.append('false_scalar_representation')
    elif category == 'false_predicate':
        knowledge = 'logical false only; no literal zero, empty string or undef selected'
        obligations.append('false_scalar_representation')
    elif category == 'regex_source':
        need(type(value['source_pattern']) is str and type(value['display_body']) is str,
             'whole declared regex pattern and body')
        knowledge = 'whole qualified source pattern/body; exact constructor flags and encoding still require qualification'
        obligations.append('regex_constructor_flags_encoding')
    else:
        need(type(value['reference_kind']) is str, 'declared source reference kind')
        knowledge = 'source reference role/kind only; original address, flags, referent and identity unmeasured'
        obligations.append('reference_role_vs_original_identity')
    return dict(schema=category, value_knowledge=knowledge, obligations=obligations)


def derive(source, source_bytes):
    result = dict(role=ROLE, source=dict(path=str(BASE / 'source-models.json'), identity=pin(source_bytes),
                  qualified_source=dict(path=str(SOURCE / 'source-models.json'), identity=pin((SOURCE / 'source-models.json').read_bytes())),
                  scope=source['scope'], historical=source['frame_model']['historical']),
                  cases=[], phases=[], groups=[], frames=[], operands=[], loads=[], obligations={})

    def obligation(name, path):
        result['obligations'].setdefault(name, []).append(path)

    def walk(value, path):
        if isinstance(value, dict):
            if 'arguments' in value:
                need(type(value['arguments']) is list and type(value.get('function')) is str,
                     'complete source frame with ordered arguments')
                result['frames'].append(dict(path=path, input=value))
            if 'role' in value and ('kind' in value or 'expression' in value):
                analysis = classify(value)
                result['operands'].append(dict(path=path, input=value, **analysis))
                for name in analysis['obligations']:
                    obligation(name, path)
            for key in sorted(value):
                child = value[key]
                if key in GROUPS and type(child) is list:
                    result['groups'].append(dict(path=path + [key], members=[path + [key, i] for i in range(len(child))]))
                if key == 'load':
                    result['loads'].append(dict(path=path + [key], marker=child,
                        source_operator='do', meaning='diagnostic require marker does not change source do operator'))
                walk(child, path + [key])
        elif isinstance(value, list):
            for index, child in enumerate(value):
                walk(child, path + [index])

    for m, mode in enumerate(source['modes']):
        for c, case in enumerate(mode['cases']):
            case_path = ['modes', m, 'cases', c]
            result['cases'].append(dict(path=case_path, mode=mode['mode'], input={k:v for k,v in case.items() if k != 'phases'}))
            for p, phase in enumerate(case['phases']):
                path = case_path + ['phases', p]
                own, public = phase['own'], phase['public']
                result['phases'].append(dict(path=path, input={k:v for k,v in phase.items() if k not in ('own', 'public')},
                    own={k:v for k,v in own.items() if k not in GROUPS},
                    operations=[{k:v for k,v in op.items() if k != 'frames'} for op in own['operations']],
                    public={k:v for k,v in public.items() if k not in GROUPS}))
                for name in ('original_display_profile', 'opaque_framework_interval',
                             'load_source_operator_vs_diagnostic_marker', 'public_receiver_original_token'):
                    obligation(name, path)
    walk(source['modes'], ['modes'])
    return result
