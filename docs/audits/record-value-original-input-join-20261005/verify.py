"""Explicit complete source/graph/field join; consumer and alias causes stay open."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-input-join-20261005')
FIELDS = Path('docs/audits/record-value-original-fields-20261005')
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
PREFIX = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.2.'
CHECKS = ('docs/audits/record-value-original-input-checks-20261005',
          'docs/audits/record-value-original-field-checks-20261005')


def module(path):
    namespace = {'__name__': 'original_input_join_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


field_reader = module(FIELDS / 'verify.py')
graph_reader = field_reader['graph_reader']
result_reader = field_reader['result_reader']
require, load, same, sealed = (field_reader[k] for k in ('require', 'load', 'same', 'sealed'))
identity, digest = result_reader['identity'], result_reader['digest']


def check_binding(binding):
    require(set(binding) == {'revision', 'task_path', 'task_body', 'owners', 'archives', 'checks'}, 'complete input/field join binding schema')
    task = subprocess.check_output(['git', 'show', binding['revision'] + ':' + TASK], text=True)
    require(binding['task_path'] == TASK and binding['task_body'] == task, 'whole committed input/field task context')
    require([r['id'] for r in binding['owners']] == [PREFIX + '1', PREFIX + '2'], 'exact input/field done owner domain')
    for row in binding['owners']:
        start = task.index('- ID: `' + row['id'] + '`'); end = task.index('\n- ID:', start + 1)
        require(task[start:end] == row['body'] and '\n  Status: `done`\n' in row['body'], 'exact whole completed input/field owner')
    expected = set(load(FIELDS / 'binding.json')['archives']) | {str(FIELDS)}
    require(set(binding['archives']) == expected, 'complete input/field prerequisite archive domain')
    require(set(binding['checks']) == set(CHECKS), 'complete input/field prerequisite check domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole immutable input/field archive manifest')
        for name in (*manifest, 'manifest.json'):
            raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + str(Path(path) / name)])
            require(raw == (Path(path) / name).read_bytes(), 'complete committed input/field archive body')
    for path, manifest in binding['checks'].items():
        directory = Path(path)
        require({p.name for p in directory.iterdir()} == set(manifest), 'whole input/field check receipt membership')
        for name, row in manifest.items():
            raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + str(directory / name)])
            require(identity(raw) == row and raw == (directory / name).read_bytes(), 'whole committed input/field check receipt')
        for name in ('sealed-reader.json', 'original-book.json', 'book-build.json',
                     'task-integrity.json', 'claim-inventory.json', 'rendered-book.json', 'final-doctrines.json'):
            receipt = load(directory / name)
            require(type(receipt['status']) is int and receipt['status'] == 0, 'actual completed input/field check status')
        require('fresh evidence-backed acceptance' in load(directory / 'final-doctrines.json')['stdout'], 'actual staged input/field implementation acceptance')


def typed_widths(graph):
    result = []
    for path, (kind, edges) in graph.nodes.items():
        if kind == 'hash' and 'width' in edges and edges['width'][0] == 'scalar':
            _, primitive, value = edges['width']
            result.append({'path': path + '/width', 'value': value, 'primitive_kind': primitive})
    return result


def join(records, fields, graph_proof, field_proof, models, ingredients, finite):
    require(same(graph_proof['source_interventions'], ingredients)
            and same(field_proof['source_interventions'], ingredients), 'whole own source intervention graph/field join')
    Graph, Node = finite['Graph'], finite['Node']
    proof = []
    for mode in ('ordinary', 'storable', 'controls'):
        native, observed, model = records[mode], fields[mode], models[mode]
        require(len(native['copies']) == len(observed['rows']) == len(model['copies']) == 697, 'complete joined copy population')
        graph_mode = next(r for r in graph_proof['proofs'] if r['mode'] == mode)
        field_mode = next(r for r in field_proof['proofs'] if r['mode'] == mode)
        joined = []
        total = {'before': 0, 'result': 0}
        for index, (actual, row, source) in enumerate(zip(native['copies'], observed['rows'], model['copies'])):
            header = dict(index=index, copy_kind=source['kind'], caller=source['caller'],
                          api_index=source['api'], helper_index=source['helper'], parse_index=source['parse'],
                          api_kind=model['api'][source['api']]['kind'] if source['api'] is not None else None,
                          helper_label=model['helpers'][source['helper']]['label'] if source['helper'] is not None else None)
            require(same({key: row[key] for key in header}, header), 'whole own source/caller/nullable field allocation join')
            require(same({key: actual[key] for key in ('kind', 'caller', 'api', 'helper', 'parse')},
                         {key: source[key] for key in ('kind', 'caller', 'api', 'helper', 'parse')}), 'whole own native copy source allocation join')
            typed = {}
            for graph_side, field_side, label in (('before', 'before', 'before'), ('copy', 'after', 'result')):
                source_object = graph_reader['thaw'](source[graph_side])
                typed[label] = graph_reader['typed'](source_object, Node)
                current_graph = Graph(actual[graph_side]); current_graph.matches(typed[label])
                expected_widths = typed_widths(Graph(source[graph_side]))
                actual_widths = [{key: fact[key] for key in ('path', 'value', 'primitive_kind')} for fact in row[field_side]]
                require([r['path'] for r in actual_widths] == [r['path'] for r in expected_widths], 'complete whole graph/field width membership join')
                require(same(actual_widths, expected_widths), 'exact raw graph/field primitive width join')
                total[label] += len(expected_widths)
            Graph(actual['after']).matches(typed['before'])
            joint = Graph(actual['joint_input_result']); joint.matches(Node('hash', {'input': typed['before'], 'result': typed['result']}))
            edges = joint.nodes[''][1]
            inputs, results = joint.reachable(edges['input']), joint.reachable(edges['result'])
            require(not inputs & results, 'complete joined copy detachment')
            population = dict(index=index, input_referents=len(inputs), result_referents=len(results), shared=0)
            require(same(population, graph_mode['whole_copy_joint_populations'][index]), 'whole graph/field reachable population join')
            joined.append(dict(index=index, source_context=header, graph_population=population,
                               before_fields=digest(row['before']), result_fields=digest(row['after'])))
        require(same(field_mode['whole_field_records'], digest(observed['rows'])), 'whole complete field source-role proof join')
        require(total == {'before': 2540, 'result': 2540}, 'complete joined width populations')
        proof.append(dict(mode=mode, width_populations=total, copies=joined))
    return proof


def controls(binding, records, fields, graph_proof, field_proof, models, ingredients, finite):
    rejected = []

    def reject(name, change, cause):
        values = copy.deepcopy([records, fields, graph_proof, field_proof, models])
        change(*values)
        try:
            join(*values, ingredients, finite)
        except ValueError as error:
            require(str(error) == cause, 'wrong intended source/graph/field join control cause: ' + name)
            rejected.append(dict(control=name, status=1, error=str(error)))
        else:
            raise ValueError('false-green source/graph/field join control: ' + name)

    reject('borrow-source-intervention', lambda n, f, g, p, m: p['source_interventions'][0].update(source_copy=80), 'whole own source intervention graph/field join')
    reject('omit-field', lambda n, f, g, p, m: f['ordinary']['rows'][80]['before'].pop(), 'complete whole graph/field width membership join')
    reject('borrow-legacy-field-kinds', lambda n, f, g, p, m: f['ordinary']['rows'][273].update(after=f['storable']['rows'][273]['after']), 'exact raw graph/field primitive width join')
    reject('wrong-field-caller', lambda n, f, g, p, m: f['ordinary']['rows'][80]['caller'].__setitem__(2, 265), 'whole own source/caller/nullable field allocation join')
    reject('borrow-private-native-role', lambda n, f, g, p, m: n['ordinary']['copies'][274]['before'][1].update(role='output'), 'primitive value/kind disagrees with authored source model')
    reject('alias-private-joint', lambda n, f, g, p, m: n['ordinary']['copies'][435]['joint_input_result'][1].update(result=['reference', '/input']), 'graph sharing/cycle/identity differs from source model')
    reject('omit-copy', lambda n, f, g, p, m: f['controls']['rows'].pop(), 'complete joined copy population')
    reject('wrong-graph-population', lambda n, f, g, p, m: g['proofs'][0]['whole_copy_joint_populations'][80].update(input_referents=1), 'whole graph/field reachable population join')
    for index in range(2):
        bad = copy.deepcopy(binding); bad['owners'][index]['body'] = bad['owners'][index]['body'].replace('Status: `done`', 'Status: `pending`')
        try:
            check_binding(bad)
        except ValueError as error:
            require(str(error) == 'exact whole completed input/field owner', 'wrong done join owner control cause')
            rejected.append(dict(control='incomplete-owner-' + str(index), status=1, error=str(error)))
        else:
            raise ValueError('false-green incomplete join owner')
    bad = copy.deepcopy(binding); del bad['archives'][str(FIELDS)]
    try:
        check_binding(bad)
    except ValueError as error:
        require(str(error) == 'complete input/field prerequisite archive domain', 'wrong omitted whole archive join cause')
        rejected.append(dict(control='omit-field-archive', status=1, error=str(error)))
    else:
        raise ValueError('false-green missing join field authority')
    return rejected


def main():
    binding = load(BASE / 'binding.json'); check_binding(binding)
    field_reader['main']()
    api, private, ingredients = graph_reader['source_interventions']()
    products = load(result_reader['PRODUCTS'] / 'products.json')
    models = {m: field_reader['model_native'](m, products, private) for m in ('ordinary', 'storable', 'controls')}
    records = {m: load(result_reader['CAPTURE'] / (m + '.json')) for m in models}
    fields = {m: load(FIELDS / (m + '-fields.json')) for m in models}
    graph_proof = load(field_reader['GRAPHS'] / 'proofs.json'); field_proof = load(FIELDS / 'proofs.json')
    finite = module(graph_reader['FINITE'] / 'verify.py')
    result = dict(join=join(records, fields, graph_proof, field_proof, models, ingredients, finite),
                  controls=controls(binding, records, fields, graph_proof, field_proof, models, ingredients, finite))
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), result), 'complete saved source/graph/field join proof')
    else:
        path.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    if (BASE / 'manifest.json').exists():
        sealed(BASE)
    print('PASS complete current original source/input/private graph/field/context/kind/readonly/detachment join. '
          'Consumer/cause/full-alias/product/semantic/cold and permanent/host-native repairs remain open.')


if __name__ == '__main__':
    main()
