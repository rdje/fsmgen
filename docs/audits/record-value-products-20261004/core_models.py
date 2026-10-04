"""Complete completed-child products and source/private/field link protocol."""
from source_roots import read, digest

FAMILIES = [
    ('captures', 'capture-products.json', ('capture',)),
    ('snapshots', 'snapshot-products.json', ('snapshot',)),
    ('ranges', 'range-products.json', ('range',)),
    ('clone-join', 'join-products.json', ('structured-clone',)),
    ('identities', 'identity-products.json', ('identity', 'payload')),
]


def children():
    return {name: read(name, filename)['rows'] for name, filename, _ in FAMILIES}


def product(family, model):
    if family in ('captures', 'snapshots', 'ranges'):
        return model['expected_product']
    if family == 'clone-join':
        return model['source_product']['result']
    return model['expected_result']


def links(family, model):
    if family in ('captures', 'snapshots'):
        result = {'private': [model['private']], 'fields': [model['whole_field_record']]}
        if family == 'snapshots':
            result['capture_index'] = model['capture_index']
            result['whole_capture_model'] = model['whole_capture_model']
        else:
            result['source_interface'] = model['source_interface']
            result['source_origins'] = model['source_origins']
            result['expected_refusal'] = model['expected_refusal']
        return result
    if family == 'ranges':
        return {'source_recipe': model['source_recipe'], 'type_stage': model['type_stage']}
    if family == 'clone-join':
        return {key: model[key] for key in ('root_index', 'source_path', 'parent_index', 'whole_source_root', 'joint', 'referents')}
    return {key: model[key] for key in ('source_parent_index', 'whole_source_parent', 'source_recipe', 'witnesses')}


def records(native):
    result = []
    for family, models in children().items():
        for model in models:
            index = model['index']
            result.append({'index': index, 'kind': native['api'][index]['kind'],
                'family': family, 'child_index': index,
                'whole_child_model': digest(model), 'whole_native': native['api'][index],
                'expected_product': product(family, model), 'links': links(family, model)})
    return sorted(result, key=lambda row: row['index'])
