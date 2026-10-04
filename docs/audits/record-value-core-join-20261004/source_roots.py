"""Whole clone-root recipes from qualified declaration/path models, not results."""
import hashlib
import importlib.util
import json
import re
from pathlib import Path


def module(label, path):
    spec = importlib.util.spec_from_file_location(label, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


scope_model = module('bound_source_scope', 'docs/audits/record-value-scopes-20261004/model.py')
native_graph = module('bound_native_graph', 'docs/audits/record-value-clones-20261004/native.py')
graph, exact = native_graph.graph, native_graph.exact


def thaw(value):
    return native_graph.topology(value)[0]


def digest(value):
    raw = json.dumps(value, sort_keys=True, separators=(',', ':')).encode()
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def read(name, product):
    return json.loads((Path('docs/audits/record-value-' + name + '-20261004') / product).read_text())


def path_source(root, text):
    """Tokenize the source path and select the original complete prepared leaf."""
    current, remaining, segments = root, text, []
    while remaining:
        member = re.match(r'\.([A-Za-z_]\w*)', remaining)
        index = re.match(r'\[([0-9]+)(?::([0-9]+))?\]', remaining)
        if member:
            assert current['kind'] == 'record' and member[1] in current['members']
            segments.append({'kind': 'member', 'name': member[1]})
            current = current['members'][member[1]]
            remaining = remaining[member.end():]
        else:
            assert index is not None
            first = int(index[1]); second = int(index[2]) if index[2] is not None else None
            if current['kind'] == 'list':
                assert second is None and first < len(current['items'])
                segments.append({'kind': 'item', 'index': first})
                current = current['items'][first]
            else:
                assert current['kind'] in ('bit', 'bits') and max(first, first if second is None else second) < int(current['width'])
                if second is None:
                    segments.append({'kind': 'bit_index', 'index': first})
                    width = 1
                else:
                    high, low = max(first, second), min(first, second)
                    segments.append({'kind': 'bit_slice', 'high': high, 'low': low})
                    width = high - low + 1
                current = {'kind': 'bit' if width == 1 else 'bits', 'width': width, 'signed': 0}
            remaining = remaining[index.end():]
    return segments, current


def recipes(native):
    scopes = read('scopes', 'scope-products.json')['rows']
    references = read('references', 'reference-products.json')
    ranges = read('ranges', 'range-products.json')['rows']
    source_scopes = {row['label']: thaw(row['scope']) for row in references['source_scopes']}
    roots = [i for i, row in enumerate(native['api']) if row['kind'] == 'structured-clone' and row['caller'][2] not in (428, 433)]
    allocated = {}

    def put(index, source, role, parent, parent_kind, ingredients):
        assert index not in allocated
        actual = native['api'][index]
        allocated[index] = {'index': index, 'source_role': role, 'source_parent_kind': parent_kind,
            'source_parent_index': parent['index'], 'whole_source_parent': digest(parent),
            'ingredients': ingredients, 'expected_input': graph(source),
            'caller': actual['caller'], 'helper': actual['helper'], 'parse': actual['parse']}

    for position, scope in enumerate(scopes):
        end = scopes[position + 1]['index'] if position + 1 < len(scopes) else len(native['api'])
        selected = [i for i in roots if scope['index'] < i < end and native['api'][i]['caller'] == ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', 35]]
        arguments = thaw(scope['recipe']['arguments'])
        source = dict(zip(arguments[::2], arguments[1::2]))
        expected = []
        for stage in scope['stages']:
            declaration = source[stage['layer']][stage['name']]
            spec = declaration['type_spec']
            if declaration['role'] not in ('input', 'output', 'storage', 'local') or (spec is not None and not scope_model.type_valid(spec)):
                continue
            private = next(row for row in scope['private'] if row['index'] == stage['copy_index'])
            raw = thaw(private['copy'])
            prepared = None if spec is None else scope_model.prepared_type(spec, raw['type_spec'])
            expected.append((prepared, {'declaration': graph(declaration), 'layer': stage['layer'], 'name': stage['name'], 'whole_private_copy': digest(private)}))
        assert len(selected) == len(expected), 'every source-valid scope declaration has exactly its own root clone'
        for index, (spec, ingredients) in zip(selected, expected):
            put(index, spec, 'scope-type', scope, 'scope', ingredients)

    for reference in references['rows']:
        stage = reference['type_stage']
        if stage is None or stage['record']['caller'][2] != 71:
            continue
        call = reference['source_call']; token = call['token']
        assert re.fullmatch(r'[A-Za-z_]\w*', token)
        product = thaw(reference['expected_product'])
        source = source_scopes[reference['source_scope_matches'][0]][token]
        assert product['path_text'] == '' and product['root'] == token and source['role'] == product['role']
        assert exact(graph(scope_model.source_projection(product['type_spec'])), graph(source['type_spec']))
        assert source['role'] != 'input' or call['access'] == 'read'
        assert call['allow_whole'] or source['type_spec']['kind'] not in ('record', 'list')
        put(stage['index'], product['type_spec'], 'whole-reference-type', reference, 'reference', {'whole_source_call': call, 'source_binding': graph(source), 'private_root_copies': reference['private_root_copies']})

    for position, packed in enumerate(ranges):
        end = ranges[position + 1]['index'] if position + 1 < len(ranges) else len(native['api'])
        selected = [i for i in roots if packed['index'] < i < end and native['api'][i]['caller'][0] == 'FSM::Package::AggregatePathSupport' and native['api'][i]['caller'][2] in (132, 295)]
        product = thaw(packed['expected_product'])
        if not product['ok']:
            assert not selected
            continue
        assert len(selected) == 3
        arguments = thaw(packed['original']['before'])
        assert arguments[1] == 'root_type_spec' and arguments[3] == 'path_text'
        root, text = arguments[2], arguments[4]
        assert exact(graph(scope_model.source_projection(root)), packed['source_recipe']['source_root'])
        assert text == packed['source_recipe']['path_text']
        segments, leaf = path_source(root, text)
        assert exact(graph(scope_model.source_projection(leaf)), graph(scope_model.source_projection(product['type_spec'])))
        for index, spec, role, line in zip(selected, (segments, leaf, leaf), ('path-segments', 'path-leaf-type', 'range-final-type'), (132, 132, 295)):
            assert native['api'][index]['caller'] == ['FSM::Package::AggregatePathSupport', 'perl/FSM/Package/AggregatePathSupport.pm', line]
            put(index, spec, role, packed, 'range', {'whole_source_recipe': packed['source_recipe'], 'complete_prepared_root': graph(root), 'path_text': text})
    assert sorted(allocated) == roots, 'complete original root source allocation has no omission/duplicate/orphan'
    return [allocated[index] for index in roots]
