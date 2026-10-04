"""Join full current field records to independently qualified source graphs.

The complete predecessor field/source algorithm is retained and transformed
only at its intake. Observed native graphs never supply expected field graphs.
"""
import copy
import json
import subprocess
from pathlib import Path
from types import SimpleNamespace

BASE = Path('docs/audits/record-value-original-fields-20261005')
GRAPHS = Path('docs/audits/record-value-original-input-graphs-20261005')
FIELDS = Path('docs/audits/record-value-copy-fields-20261004')


def module(path):
    namespace = {'__name__': 'original_field_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


graph_reader = module(GRAPHS / 'verify.py')
require, load, same, sealed = (graph_reader[k] for k in ('require', 'load', 'same', 'sealed'))
result_reader = graph_reader['result_reader']


def authenticate():
    binding = load(BASE / 'binding.json')
    prior = load(GRAPHS / 'binding.json')
    task = subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'complete committed field owner context')
    ids = [r['id'] for r in prior['owners']] + [
        'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.2.1']
    require([r['id'] for r in binding['owners']] == sorted(ids), 'complete done field prerequisite owners')
    for row in binding['owners']:
        start = task.index('- ID: `' + row['id'] + '`'); end = task.index('\n- ID:', start + 1)
        require(task[start:end] == row['body'] and '\n  Status: `done`\n' in row['body'], 'exact done field prerequisite body')
    require(set(binding['archives']) == set(prior['archives']) | {str(GRAPHS)}, 'complete field/source/graph archive domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'complete immutable field prerequisite manifest')
        for name in (*manifest, 'manifest.json'):
            raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + str(Path(path) / name)])
            require(raw == (Path(path) / name).read_bytes(), 'complete committed field prerequisite body')
    graph_reader['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def freeze(value, seen=None, path=''):
    """Serialize source-model objects, including cycles and sharing, canonically."""
    if type(value) in (type(None), int, str):
        return value
    require(type(value) in (dict, list), 'source field model value domain')
    seen = {} if seen is None else seen
    if id(value) in seen:
        return ['reference', seen[id(value)]]
    seen[id(value)] = path
    if type(value) is dict:
        result = {}
        for key in sorted(value):
            segment = key.replace('~', '~0').replace('/', '~1')
            result[key] = freeze(value[key], seen, path + '/' + segment)
        return ['hash', result]
    return ['array', [freeze(child, seen, path + '/' + str(index)) for index, child in enumerate(value)]]


def model_native(mode, products, intervention_private):
    private = {r['index']: r['whole_native'] for r in products['private']}
    inputs = {r['index']: r['native'] for r in load(graph_reader['INPUTS'] / 'inputs.json')['rows']}
    require(set(private).isdisjoint(inputs) and set(private) | set(inputs) == set(range(697)), 'complete own source field graph partition')
    original = load(Path('docs/audits/record-value-runtime-20261004/ordinary.json'))
    expected = {'api': [r['whole_native'] for r in products['apis']],
                'helpers': original['helpers'], 'copies': []}
    for index in range(697):
        row = copy.deepcopy(private[index] if index in private else inputs[index])
        if index in private:
            if mode != 'storable' and index in intervention_private:
                row['before'] = freeze(intervention_private[index])
        elif mode != 'storable':
            row['copy'] = copy.deepcopy(row['before'])
        expected['copies'].append(row)
    return expected


def reader_transform():
    source = (FIELDS / 'verify.py').read_text()
    start = source.index('BASE = Path(__file__).parent\n')
    end = source.index('def exact(a, b):\n', start)
    replacements = [(source[start:end], '# Intake supplied by the independently qualified complete source graph reader.\n\n')]
    # Strengthen diagnostic loci without changing the qualified field algorithm.
    replacements += [
        ("assert recorded['index'] == index and recorded['caller'] == original['caller']",
         "assert recorded['index'] == index and recorded['caller'] == original['caller'], 'own field index/caller allocation'"),
        ("assert recorded['copy_kind'] == original['kind']", "assert recorded['copy_kind'] == original['kind'], 'own field copy role'"),
        ("assert recorded['api_index'] == original['api'] and recorded['helper_index'] == original['helper']",
         "assert recorded['api_index'] == original['api'] and recorded['helper_index'] == original['helper'], 'own field API/helper allocation'"),
        ("assert recorded['parse_index'] == original['parse']", "assert recorded['parse_index'] == original['parse'], 'own field parse allocation'"),
        ("assert exact(fact['value'], value) and fact['primitive_kind'] == type(value).__name__",
         "assert exact(fact['value'], value) and fact['primitive_kind'] == type(value).__name__, 'exact raw field value/primitive kind'"),
        ("assert source_ids and source_ids == fact['source_nodes']", "assert source_ids and source_ids == fact['source_nodes'], 'complete own resolved source-candidate set'"),
        ("assert exact(fact['type_shape'], raw)", "assert exact(fact['type_shape'], raw), 'whole raw resolved source shape'"),
        ("assert exact(expected, fact['default_port'])", "assert exact(expected, fact['default_port']), 'complete source default carrier role'"),
    ]
    tail = source[source.index("print('PASS every original697") :]
    replacements.append((tail, "proof_result = dict(roles=[list(key) + [count] for key, count in sorted(totals.items())],\n"
                        "    sites=[list(key) + [count] for key, count in sorted(site_totals.items())],\n"
                        "    contradictions=contradictions, source_roots=expected_roots, source_nodes=expected_nodes)\n"))
    transformed = source
    for old, new in replacements:
        require(transformed.count(old) == 1, 'unique complete independent field-reader transform')
        transformed = transformed.replace(old, new)
    return {'source_path': str(FIELDS / 'verify.py'), 'replacements': [list(pair) for pair in replacements], 'complete_program': transformed}


def check(mode, data, expected, models, transform):
    require(len(data['rows']) == len(expected['copies']) == 697, 'complete current field copy population')
    namespace = {'__name__': 'complete_source_field_reader', 'native': expected, 'data': data,
                 'models': copy.deepcopy(models), 'binding': load(FIELDS / 'binding.json'),
                 'args': SimpleNamespace(omit_field=False, swap_source_role=False,
                                         trust_private_product=False, swap_malformed_model=False)}
    exec(compile(transform['complete_program'], mode + '-complete-independent-field-reader', 'exec'), namespace)
    headers = {'index', 'copy_kind', 'caller', 'api_index', 'api_kind',
               'helper_index', 'helper_label', 'parse_index'}
    for index, row in enumerate(data['rows']):
        source = expected['copies'][index]
        header = dict(index=index, copy_kind=source['kind'], caller=source['caller'],
                      api_index=source['api'], helper_index=source['helper'], parse_index=source['parse'],
                      api_kind=expected['api'][source['api']]['kind'] if source['api'] is not None else None,
                      helper_label=expected['helpers'][source['helper']]['label'] if source['helper'] is not None else None)
        require(set(row) == headers | {'before', 'after'}, 'complete copy field row property domain')
        require(same({key: row[key] for key in headers}, header), 'complete own nullable field context allocation')
    proof = namespace['proof_result']
    proof['contradictions'] = [list(row) for row in proof['contradictions']]
    proof['mode'] = mode
    proof['whole_field_records'] = result_reader['digest'](data['rows'])
    return proof


def controls(mode_data, expected, models, transform):
    rejected = []

    def reject(name, change, cause):
        data = copy.deepcopy(mode_data['ordinary']); change(data)
        try:
            check('ordinary', data, expected['ordinary'], models, transform)
        except (AssertionError, ValueError) as error:
            require(str(error) == cause, 'wrong intended whole-field control cause: ' + name)
            rejected.append({'control': name, 'status': 1, 'error': str(error)})
        else:
            raise ValueError('false-green whole-field control: ' + name)

    reject('omit-field', lambda d: d['rows'][80]['before'].pop(), 'complete original copied width membership')
    reject('borrow-legacy-kind-boundary', lambda d: d['rows'][273].update(after=mode_data['storable']['rows'][273]['after']),
           'whole raw resolved source shape')
    reject('wrong-caller', lambda d: d['rows'][80]['caller'].__setitem__(2, 265), 'own field index/caller allocation')
    reject('wrong-copy-role', lambda d: d['rows'][80].update(copy_kind='value-private'), 'own field copy role')
    reject('wrong-helper', lambda d: d['rows'][80].update(helper_index=0), 'own field API/helper allocation')
    reject('wrong-parse', lambda d: d['rows'][80].update(parse_index=0), 'own field parse allocation')
    reject('omit-source-candidate', lambda d: d['rows'][273]['after'][0]['source_nodes'].pop(), 'complete own resolved source-candidate set')
    reject('wrong-source-property', lambda d: d['rows'][273]['after'][0]['type_shape'].update(signed=1), 'whole raw resolved source shape')
    reject('wrong-ancestor', lambda d: d['rows'][273]['after'][0]['type_ancestor'].update(path='/foreign'),
           'whole field-role record and ancestor/source allocation')
    default = next(i for i, f in enumerate(mode_data['ordinary']['rows'][80]['before']) if f['default_port'])
    reject('promote-default-carrier', lambda d: d['rows'][80]['before'][default].update(default_port=None, type_kind='bit'),
           'complete source default carrier role')
    reject('wrong-null-api-kind', lambda d: d['rows'][80].update(api_kind='scope'),
           'complete own nullable field context allocation')
    reject('extra-field-row-property', lambda d: d['rows'][80].update(foreign_source='frame'),
           'complete copy field row property domain')
    cyclic = [(r['index'], i) for r in mode_data['ordinary']['rows'] for i, f in enumerate(r['before'])
              if 'malformed:cyclic member:' in f['source_nodes']]
    require(cyclic, 'actual own cyclic source field control operand')
    index, field = cyclic[0]
    reject('hide-source-cycle', lambda d: d['rows'][index]['before'][field]['type_shape']['members'].update(
               data={'kind': 'bits', 'width': 7, 'signed': 0}), 'whole raw resolved source shape')
    metadata = [(r['index'], i) for r in mode_data['ordinary']['rows'] for i, f in enumerate(r['before'])
                if f['metadata_ancestor'] is not None]
    require(metadata, 'actual own metadata source field control operand')
    index, field = metadata[0]
    reject('wrong-metadata-ancestor', lambda d: d['rows'][index]['before'][field]['metadata_ancestor'].update(
               path='/foreign'), 'whole field-role record and ancestor/source allocation')
    reject('omit-copy', lambda d: d['rows'].pop(), 'complete current field copy population')
    return rejected


def main():
    authenticate()
    api, private, ingredients = graph_reader['source_interventions']()
    products = load(result_reader['PRODUCTS'] / 'products.json')
    models = load(FIELDS / 'source-models.json')
    expected = {m: model_native(m, products, private) for m in ('ordinary', 'storable', 'controls')}
    observations = load(BASE / 'observer-transforms.json')
    require([r['mode'] for r in observations] == ['ordinary', 'storable', 'controls'], 'complete field observation mode domain')
    mode_data = {}
    for row in observations:
        mode = row['mode']; transformed = (FIELDS / 'produce.py').read_text()
        for old, new in row['replacements']:
            require(transformed.count(old) == 1, 'exact observation path-only transform')
            transformed = transformed.replace(old, new)
        require(row['source_path'] == str(FIELDS / 'produce.py') and row['complete_program'] == transformed,
                'complete bound current field observer')
        data = load(BASE / (mode + '-fields.json')); path = result_reader['CAPTURE'] / (mode + '.json')
        require(data['native_input'] == result_reader['identity'](path.read_bytes()),
                'whole current native field observation provenance')
        require(load(BASE / (mode + '-source-node-gaps.json')) == [], 'complete mapped current source-node observations')
        mode_data[mode] = data
    transform = reader_transform(); transform_path = BASE / 'reader-transform.json'
    if transform_path.exists():
        require(same(load(transform_path), transform), 'whole saved independent field-reader transformation')
    else:
        transform_path.write_text(json.dumps(transform, sort_keys=True, indent=2) + '\n')
    result = {'source_interventions': ingredients,
              'proofs': [check(m, mode_data[m], expected[m], models, transform) for m in mode_data],
              'controls': controls(mode_data, expected, models, transform)}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), result), 'whole saved source-derived current field proof')
    else:
        path.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS complete current copied fields, raw kinds, whole source properties/orders/cycles, '
          'source-candidate sets and ancestor/carrier/default/metadata roles in all three unchanged-input modes. '
          'Graph/field join, consumer/cause/full-alias and cold/permanent repairs remain open.')


if __name__ == '__main__':
    main()
