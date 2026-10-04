"""Source-copy intervention models for complete unchanged-input API/private graphs.

Existing original source/stage/model and typed graph algorithms are prerequisites.
No current candidate output supplies an expected input, primitive kind or edge.
"""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-input-graphs-20261005')
RESULTS = Path('docs/audits/record-value-original-products-20261005')
INPUTS = Path('docs/audits/record-value-copy-inputs-20261004')
FIELDS = Path('docs/audits/record-value-copy-fields-20261004')
FINITE = Path('docs/audits/record-value-copy-reader-20261004')
AUTHOR = Path('docs/audits/record-value-fields-20261004')


def module(path):
    namespace = {'__name__': 'original_input_graph_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


result_reader = module(RESULTS / 'verify.py')
require, load, same, digest, sealed = (result_reader[k] for k in ('require', 'load', 'same', 'digest', 'sealed'))


def authenticate():
    binding = load(BASE / 'binding.json')
    task = subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'complete committed input-graph owner context')
    expected = set(load(RESULTS / 'binding.json')['archives']) | {str(RESULTS), str(INPUTS), str(FIELDS), str(FINITE), str(AUTHOR)}
    require(set(binding['archives']) == expected, 'complete input/source/stage/graph prerequisite archive domain')
    ids = [r['id'] for r in load(RESULTS / 'binding.json')['owners']]
    ids += ['SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.1']
    require([r['id'] for r in binding['owners']] == sorted(ids), 'complete exact done source/result prerequisites')
    for owner in binding['owners']:
        start = task.index('- ID: `' + owner['id'] + '`'); end = task.index('\n- ID:', start + 1)
        require(task[start:end] == owner['body'] and '\n  Status: `done`\n' in owner['body'], 'exact done source/result owner body')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole source/stage/archive seal')
        for name in (*manifest, 'manifest.json'):
            raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + str(Path(path) / name)])
            require(raw == (Path(path) / name).read_bytes(), 'whole committed source/stage body')
    result_reader['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def thaw(value, seen=None, path=''):
    """Model-graph interpreter; current observed graphs are never model inputs."""
    if type(value) in (type(None), int, str):
        return value
    require(type(value) is list and len(value) == 2, 'source model graph grammar')
    kind, body = value
    seen = {} if seen is None else seen
    if kind == 'reference':
        require(body in seen, 'source model prior reference')
        return seen[body]
    require(kind in ('hash', 'array'), 'source model container kind')
    require(type(body) is (dict if kind == 'hash' else list), 'source model container shape')
    result = {} if kind == 'hash' else []
    seen[path] = result
    for key, child in (body.items() if kind == 'hash' else enumerate(body)):
        segment = str(key).replace('~', '~0').replace('/', '~1')
        item = thaw(child, seen, path + '/' + segment)
        if kind == 'hash':
            result[key] = item
        else:
            result.append(item)
    return result


def typed(value, Node, seen=None):
    if type(value) in (type(None), int, str):
        return value
    require(type(value) in (dict, list), 'typed source value domain')
    seen = {} if seen is None else seen
    if id(value) in seen:
        return seen[id(value)]
    result = Node('hash' if type(value) is dict else 'array', {})
    seen[id(value)] = result
    for key, child in (value.items() if type(value) is dict else enumerate(value)):
        result.edges[str(key)] = typed(child, Node, seen)
    return result


def source_interventions():
    inputs = {r['index']: r for r in load(INPUTS / 'inputs.json')['rows']}
    source = load(INPUTS / 'binding.json')['sources']['t/1986-isf-record-port-value-gates.t']['body']
    authored = load(AUTHOR / 'authored-models.json')
    scopes = load(Path('docs/audits/record-value-scopes-20261004/scope-products.json'))['rows']
    references = load(Path('docs/audits/record-value-references-20261004/reference-products.json'))['rows']
    scopes_by_label = {r['label']: r for r in scopes}
    require(len(scopes_by_label) == len(scopes), 'unique original source scope labels')
    mutations = [
        ('unknown key', ['extra'], 1, '$_[0]{extra} = 1'),
        ('bad root width', ['width'], 9, '$_[0]{width} = 9'),
        ('bad scalar signed', ['members', 'data', 'signed'], 2, '$_[0]{members}{data}{signed} = 2'),
        ('missing signed', ['members', 'data', 'signed'], None, 'delete $_[0]{members}{data}{signed}'),
        ('aggregate signed', ['signed'], 1, '$_[0]{signed} = 1'),
        ('aggregate state', ['state_model'], 'two_state', "$_[0]{state_model} = 'two_state'"),
        ('bad state', ['members', 'data', 'state_model'], 'unknown', "$_[0]{members}{data}{state_model} = 'unknown'"),
        ('duplicate order', ['member_order'], ['flag', 'flag'], '$_[0]{member_order} = [qw(flag flag)]'),
        ('unlisted member', ['members', 'extra'], authored['scalar'], '$_[0]{members}{extra} = dclone($scalar)'),
        ('cyclic member', ['members', 'data'], '$root', '$_[0]{members}{data} = $_[0]'),
        ('deferred kind', ['kind'], 'deferred_imported_alias', "$_[0]{kind} = 'deferred_imported_alias'"),
    ]
    expected_api, expected_private, ingredients = {}, {}, []

    def put_scope(row, arguments, source_copy, change):
        index = row['index']; expected_api[index] = arguments
        named = dict(zip(arguments[::2], arguments[1::2]))
        for stage in row['stages']:
            expected_private[stage['copy_index']] = named[stage['layer']][stage['name']]
        ingredients.append({'kind': 'scope', 'index': index, 'label': row['label'],
                            'source_copy': source_copy, 'authored_change': change,
                            'private_indices': [s['copy_index'] for s in row['stages']]})

    nested = copy.deepcopy(thaw(inputs[273]['native']['before']))
    require(same(nested, authored['types']['nested']), 'original source-copy nested input meaning and kinds')
    require('reverse @{$swapped->{members}{body}{members}{lanes}{items}}' in source, 'exact authored list reorder')
    nested['members']['body']['members']['lanes']['items'].reverse()
    row = scopes_by_label['nested-list-order']; arguments = thaw(row['recipe']['arguments'])
    arguments[1]['held']['type_spec'] = arguments[1]['output']['type_spec'] = nested
    put_scope(row, arguments, 273, 'reverse nested list items')
    original_frame = authored['types']['frame']
    copies = [r for r in inputs.values() if r['native']['caller'][2] == 265]
    require(len(copies) == len(mutations), 'complete original malformed source-copy membership')
    for original, (name, path, value, literal) in zip(copies, mutations):
        require("['" + name + "', sub { " + literal + ' }' in source, 'complete own authored malformed mutation')
        spec = copy.deepcopy(thaw(original['native']['before']))
        require(same(spec, original_frame), 'complete own original frame source-copy input')
        target = spec
        for key in path[:-1]:
            target = target[key]
        if value is None:
            del target[path[-1]]
        else:
            target[path[-1]] = spec if value == '$root' else copy.deepcopy(value)
        row = scopes_by_label['malformed:' + name]; arguments = thaw(row['recipe']['arguments'])
        arguments[1]['packet']['type_spec'] = spec
        put_scope(row, arguments, original['index'], literal)
    require('$scope->{old} = {role' in source and 'type_spec => dclone($types{frame})' in source,
            'exact old-root source insertion')
    require('$scope->{lanes} = {role' in source and 'type_spec => dclone($types{lanes})' in source,
            'exact lanes-root source insertion')
    inserted = {'old': thaw(inputs[434]['native']['before']), 'lanes': thaw(inputs[477]['native']['before'])}
    require(same(inserted['old'], original_frame) and same(inserted['lanes'], authored['types']['lanes']), 'complete original inserted source-copy inputs')
    for row in references:
        labels = row['source_scope_matches']
        if labels not in (['storage-only+old'], ['storage-only+old+lanes']):
            continue
        arguments = thaw(row['original']['before']); named = dict(zip(arguments[::2], arguments[1::2])); scope = named['scope']
        require('old' in scope, 'whole source-added old root allocation')
        scope['old']['type_spec'] = copy.deepcopy(inserted['old'])
        if labels == ['storage-only+old+lanes']:
            require('lanes' in scope, 'whole source-added lanes root allocation')
            scope['lanes']['type_spec'] = copy.deepcopy(inserted['lanes'])
        expected_api[row['index']] = arguments
        for stage in row['private_root_copies']:
            original = thaw(stage['before'])
            # Every reached stage belongs to the requested root, not another
            # physically identical declaration. The source token selects it.
            root = row['source_call']['token'].split('.')[0].split('[')[0]
            require(root in scope and same(original['role'], scope[root]['role']), 'exact source reference private-root role')
            expected_private[stage['index']] = scope[root]
        ingredients.append({'kind': 'reference', 'index': row['index'], 'source_scope': labels[0],
                            'source_copy': [434] + ([477] if 'lanes' in scope else []),
                            'source_call': row['source_call'],
                            'private_indices': [s['index'] for s in row['private_root_copies']]})
    require(len(expected_api) == 22, 'complete source intervention API membership')
    return expected_api, expected_private, ingredients


def range_preparation(original, authored):
    """The dated private sibling coercion is not an outer caller mutation."""
    value = thaw(original['before'])
    require(value[1] == 'root_type_spec' and value[3:] == ['path_text', '.body.lanes[0]'],
            'exact private sibling offset argument/source role')
    root = value[2]
    sibling = root['members']['body']['members']['lanes']['items'][1]
    source_sibling = authored['types']['nested']['members']['body']['members']['lanes']['items'][1]
    require(type(sibling['width']) is str and sibling['width'] == str(source_sibling['width']),
            'source-owned private sibling string width')
    # The canonical range proof establishes this native scalar-flag effect for
    # the captured Perl profile. Limit it to the exact own private source stage.
    sibling['width'] = source_sibling['width']
    return value


def check(records, products, intervention_api, intervention_private, finite):
    Graph, Node = finite['Graph'], finite['Node']
    original_private = {r['index']: r for r in products['private']}
    original_inputs = {r['index']: r for r in load(INPUTS / 'inputs.json')['rows']}
    authored = load(AUTHOR / 'authored-models.json')
    require([r['index'] for r in products['apis'] if not same(r['whole_native']['before'], r['whole_native']['after'])] == [4825],
            'complete known private before/after exception domain')
    require(original_private[313]['api'] == 4751, 'exact detached private range source owner')
    proofs = []
    for mode in ('ordinary', 'storable', 'controls'):
        native = records[mode]
        require(len(native['api']) == len(products['apis']) == 9283 and len(native['copies']) == 697, 'complete current graph population')
        input_nodes = 0
        for index, row in enumerate(products['apis']):
            original = row['whole_native']; actual = native['api'][index]
            for side in ('before', 'after'):
                expected = intervention_api[index] if mode != 'storable' and index in intervention_api else thaw(original[side])
                if index == 4825 and side == 'after':
                    expected = range_preparation(original, authored)
                model = typed(expected, Node); graph = Graph(actual[side]); graph.matches(model)
                input_nodes += len(graph.nodes)
        copied = []
        for index, actual in enumerate(native['copies']):
            if index in original_private:
                original = original_private[index]['whole_native']
                require(same(original['before'], original['after']), 'complete original private readonly authority')
                expected_before = intervention_private[index] if mode != 'storable' and index in intervention_private else thaw(original['before'])
                expected_after = expected_before if mode != 'storable' and index in intervention_private else thaw(original['after'])
                expected_result = thaw(original['copy'])
            else:
                require(index in original_inputs and actual['kind'] == 'test', 'complete original test/private partition')
                original = original_inputs[index]['native']; expected_before = thaw(original['before']); expected_after = thaw(original['after'])
                expected_result = thaw(original['copy' if mode == 'storable' else 'before'])
            before, after, result = (typed(value, Node) for value in (expected_before, expected_after, expected_result))
            for side, model in (('before', before), ('after', after), ('copy', result)):
                Graph(actual[side]).matches(model)
            joint = Graph(actual['joint_input_result']); joint.matches(Node('hash', {'input': after, 'result': result}))
            edges = joint.nodes[''][1]; inputs, outputs = joint.reachable(edges['input']), joint.reachable(edges['result'])
            require(not inputs & outputs, 'whole actual private/test source/result detachment')
            require(type(actual['original_reference_count']) is int and type(actual['copy_reference_count']) is int
                    and actual['original_reference_count'] == len(inputs) and actual['copy_reference_count'] == len(outputs)
                    and type(actual['shared_with_original']) is int and actual['shared_with_original'] == 0,
                    'whole independent native reference population')
            copied.append({'index': index, 'input_referents': len(inputs), 'result_referents': len(outputs), 'shared': 0})
        proofs.append({'mode': mode, 'whole_api_input_nodes': input_nodes,
                       'whole_copy_joint_populations': copied})
    return proofs


def controls(records, products, api, private, finite):
    rejected = []
    causes = {
        'legacy-scope-input': 'primitive value/kind disagrees with authored source model',
        'legacy-private-input': 'primitive value/kind disagrees with authored source model',
        'borrow-source-role': 'primitive value/kind disagrees with authored source model',
        'missing-input-edge': 'container kind/complete edge set differs from source model',
        'alias-private-joint': 'graph sharing/cycle/identity differs from source model',
        'unresolved-private-joint': 'unresolved or forward graph reference',
        'wrong-reference-population': 'whole independent native reference population',
        'hide-private-range-kind-change': 'primitive value/kind disagrees with authored source model',
        'omit-api': 'complete current graph population',
        'omit-copy': 'complete current graph population',
    }

    def rejects(name, change):
        bad = copy.deepcopy(records); change(bad)
        try:
            check(bad, products, api, private, finite)
        except ValueError as error:
            require(str(error) == causes[name], 'wrong reached complete-graph control cause: ' + name)
            rejected.append({'control': name, 'status': 1, 'error': str(error)})
        else:
            raise ValueError('false-green complete input graph control: ' + name)

    rejects('legacy-scope-input', lambda r: r['ordinary']['api'][3599].update(before=r['storable']['api'][3599]['before']))
    rejects('legacy-private-input', lambda r: r['ordinary']['copies'][274].update(before=r['storable']['copies'][274]['before']))
    rejects('borrow-source-role', lambda r: r['ordinary']['copies'][274]['before'][1].update(role='output'))
    rejects('missing-input-edge', lambda r: r['ordinary']['copies'][435]['before'][1].pop('type_spec'))
    rejects('alias-private-joint', lambda r: r['ordinary']['copies'][435]['joint_input_result'][1].update(result=['reference', '/input']))
    rejects('unresolved-private-joint', lambda r: r['ordinary']['copies'][435]['joint_input_result'][1].update(result=['reference', '/absent']))
    rejects('wrong-reference-population', lambda r: r['ordinary']['copies'][435].update(copy_reference_count=1))
    rejects('hide-private-range-kind-change', lambda r: r['ordinary']['api'][4825].update(after=r['ordinary']['api'][4825]['before']))
    rejects('omit-api', lambda r: r['ordinary']['api'].pop())
    rejects('omit-copy', lambda r: r['controls']['copies'].pop())
    return rejected


def main():
    authenticate()
    api, private, ingredients = source_interventions()
    products = load(result_reader['PRODUCTS'] / 'products.json')
    records = {m: load(result_reader['CAPTURE'] / (m + '.json')) for m in ('ordinary', 'storable', 'controls')}
    finite = module(FINITE / 'verify.py')
    result = {'source_interventions': ingredients,
              'proofs': check(records, products, api, private, finite),
              'controls': controls(records, products, api, private, finite)}
    destination = BASE / 'proofs.json'
    if destination.exists():
        require(same(load(destination), result), 'whole saved original source-intervention graph proof')
    else:
        destination.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS complete current original API before/after and private/test before/after/result/joint graphs, source-derived copy interventions, primitive kinds, private/test readonly and actual detachment. Exact known private range sibling kind change retains; outer caller is unchanged. Copied-field and consumer/cause/full-alias semantics remain open.')


if __name__ == '__main__':
    main()
