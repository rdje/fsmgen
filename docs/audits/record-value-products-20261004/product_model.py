"""Protocol for all completed actor/value/core source product relationships."""
from source_roots import read, digest, graph
from core_models import children, product, links

VALUE = {
    'scope': ('scopes', 'scope-products.json'),
    'reference': ('references', 'reference-products.json'),
    'copy': ('copies', 'copy-products.json'),
}
CORE = {
    'capture': 'captures', 'snapshot': 'snapshots', 'range': 'ranges',
    'structured-clone': 'clone-join', 'identity': 'identities', 'payload': 'identities',
}


def source_models():
    models = children()
    models.update({name: read(name, filename)['rows'] for name, filename in VALUE.values()})
    return {name: {row['index']: row for row in rows} for name, rows in models.items()}


def value_copies(kind, model):
    if kind == 'scope':
        return model['private']
    if kind == 'reference':
        return model['private_root_copies']
    return [stage['copy'] for stage in model['private_stages']]


def actors(native):
    source = read('actors', 'actor-models.json')
    result = []
    for index, actual in enumerate(native['parses']):
        name = ('local', 'imported')[index] if index < 2 else None
        recipe = source['sources'][name] if name else source['refused_sources'][index - 2]
        model = source['actors'][name] if name else None
        result.append({'index': index, 'source': recipe, 'source_actor': model,
            'expected_product': graph(model), 'whole_native': actual})
    return result


def records(native):
    models = source_models()
    actor_rows = actors(native)
    core_join = {row['index']: row for row in read('core-join', 'core-products.json')['rows']}
    value_join = {row['index']: row for row in read('api-join', 'join.json')['apis']}
    fields = read('copy-fields', 'fields.json')['rows']
    result, private = [], []
    for index, actual in enumerate(native['api']):
        kind = actual['kind']
        family = VALUE[kind][0] if kind in VALUE else CORE[kind]
        model = models[family][index]
        if kind in VALUE:
            expected = model['meaning']['product'] if kind == 'copy' else model['expected_product']
            stages = value_copies(kind, model)
            source_links = {'recipe': model['recipe']} if kind in ('scope', 'copy') else {key: model[key] for key in ('source_call', 'source_scope_matches', 'type_stage', 'operation_span')}
            completed = value_join[index]
        else:
            expected = product(family, model)
            stages = [model['private']] if kind in ('capture', 'snapshot') else []
            source_links = links(family, model)
            completed = core_join[index]
        for stage in stages:
            copy_index = stage['index']
            private.append({'index': copy_index, 'api': index, 'family': family,
                'whole_model': stage, 'whole_native': native['copies'][copy_index],
                'whole_field': fields[copy_index]})
        parse_index = actual['parse']
        parse_link = None if parse_index is None else {'index': parse_index,
            'whole_source_parse': digest(actor_rows[parse_index]),
            'bounds': [native['parses'][parse_index]['api_start'], native['parses'][parse_index]['api_end']]}
        result.append({'index': index, 'kind': kind, 'family': family, 'source_index': index,
            'whole_source_model': digest(model), 'whole_completed_join': digest(completed),
            'whole_native': actual, 'expected_product': expected, 'source_links': source_links,
            'private_indices': [stage['index'] for stage in stages], 'parse_link': parse_link})
    return {'actors': actor_rows, 'apis': result, 'private': sorted(private, key=lambda row: row['index'])}
