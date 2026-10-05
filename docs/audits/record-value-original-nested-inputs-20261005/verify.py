"""Source private-root/capture input join; catch and stack meaning stay open."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-nested-inputs-20261005')
METADATA = Path('docs/audits/record-value-original-metadata-frames-20261005')
SCOPES = Path('docs/audits/record-value-scopes-20261004/scope-products.json')
REVISION = '822103048448f36c1e5b8cd98f2926c13d0f7118'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.2.2'


def module(path):
    namespace = {'__name__': 'nested_input_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


metadata = module(METADATA / 'verify.py')
primary = metadata['primary']
require, load, same, sealed = (metadata[key] for key in ('require', 'load', 'same', 'sealed'))
digest = primary['digest']
VALUE_SOURCE = 'perl/FSM/Support/ISFRecordPortValues.pm'
CONTRACTS = {
    'scope_order': 'for my $layer (qw(outer local)) {',
    'root_order': 'for my $name (sort keys %$roots) {',
    'private_root': '$root = dclone($root);',
    'scope_type': '_validate_type($spec, "root \'$name\'") if defined $spec;',
    'capture_input': "capture_interface_port_metadata({inputs => [{name => 'value', type => 'resolved_value',\n            width => $checked->{width}, type_spec => $checked}], outputs => []});",
    'capture_wrapper': "local *FSM::Support::ISFInterfacePortMetadata::capture_interface_port_metadata = sub {\n        return call_api('capture', $capture, [caller], @_);\n    };",
    'wrapper_before_import': 'require FSM::Support::ISFRecordPortValues;',
    'active_api': 'local $active_api = scalar @api;',
}


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact done metadata owner intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed nested-input intake task')
    start = task.index('- ID: `' + OWNER + '`'); end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in task[start:end], 'whole completed metadata owner')
    require(set(binding['archives']) == set(load(METADATA / 'binding.json')['archives']) | {str(METADATA)},
            'complete nested-input prerequisite domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole nested-input prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            require(subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)])
                    == (Path(path) / name).read_bytes(), 'whole committed nested-input prerequisite bytes')
    metadata['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def sources():
    capture = primary['result_reader']['CAPTURE']
    return {'value': load(capture / 'binding.json')['sources'][VALUE_SOURCE]['body'],
            'observer': (capture / 'observe.pl').read_text()}


def check_sources(source):
    for key, statement in CONTRACTS.items():
        body = source['observer'] if key in ('capture_wrapper', 'wrapper_before_import', 'active_api') else source['value']
        # The reference API has a separate root clone; bind the exact Scope
        # function here instead of treating its matching statement as unique.
        if key in ('scope_order', 'root_order', 'private_root', 'scope_type'):
            body = body[body.index('sub record_value_scope {'):body.index('sub record_value_reference {')]
        require(body.count(statement) == 1, 'exact nested source input/active-parent contract')
    require(source['observer'].index(CONTRACTS['capture_wrapper']) < source['observer'].index(CONTRACTS['wrapper_before_import']),
            'capture wrapper is installed before Value import')


def freeze(value, seen=None, path=''):
    """Portable typed source model; preserve cycles and repeated referents."""
    seen = {} if seen is None else seen
    if type(value) not in (dict, list):
        require(value is None or type(value) in (str, int), 'finite nested source scalar profile')
        return value
    if id(value) in seen:
        return ['reference', seen[id(value)]]
    seen[id(value)] = path
    if type(value) is dict:
        return ['hash', {key: freeze(value[key], seen, path + '/' + key) for key in sorted(value)}]
    return ['array', [freeze(child, seen, path + '/' + str(index)) for index, child in enumerate(value)]]


def expected_models(source):
    check_sources(source)
    _, helpers, _, products = primary['context']['source_models']()
    helper_source = {row['index']: row for row in helpers}
    scopes = {row['index']: row for row in load(SCOPES)['rows']}
    private = {row['index']: row for row in products['private']}
    cases = load(METADATA / 'proofs.json')['models']
    primary_models = load(primary['BASE'] / 'proofs.json')['proofs']
    result = []
    for modeled, causes in zip(cases, primary_models, strict=True):
        require(modeled['mode'] == causes['mode'], 'nested source mode identity')
        case_by_index = {row['index']: row for row in modeled['cases']}
        pairs = []
        for helper in causes['helpers']:
            rows = [case_by_index[index] for index in helper['failing_api_members'] if index in case_by_index]
            if not rows:
                continue
            parents = [row for row in rows if row['kind'] == 'scope']
            children = [row for row in rows if row['kind'] == 'capture']
            require(len(parents) == len(children) == 1, 'source helper has one failing Scope/capture pair')
            parent, child = parents[0], children[0]
            require(parent['guard'] == child['guard'] and parent['metadata_primary'] == child['metadata_primary'],
                    'source nested pair shares intended metadata guard')
            scope = scopes[parent['index']]
            context = primary['graph']['thaw'](scope['recipe']['arguments'])
            # A source-modeled first failure selects the root independently
            # of a captured stack. These finite malformed helpers fail only
            # while checking the declared input root packet.
            declared = dict(zip(context[::2], context[1::2]))
            candidates = [stage for stage in scope['stages']
                          if declared[stage['layer']][stage['name']]['role'] == 'input']
            require(len(candidates) == 1 and candidates[0]['layer'] == 'outer'
                    and candidates[0]['name'] == 'packet', 'finite source malformed input-root stage')
            stage = candidates[0]; copy_index = stage['copy_index']
            qualified = private[copy_index]
            require(qualified['api'] == parent['index'] and qualified['whole_native']['kind'] == 'value-private',
                    'source-qualified private root API allocation')
            root = primary['graph']['thaw'](qualified['whole_native']['copy'])
            require(root['role'] == 'input' and type(root['type_spec']) is dict
                    and root['type_spec']['kind'] != 'list', 'finite private-root type/role profile')
            spec = root['type_spec']
            constructed = [{'inputs': [{'name': 'value', 'type': 'resolved_value', 'width': spec['width'], 'type_spec': spec}], 'outputs': []}]
            source_helper = helper_source[helper['index']]
            require(parent['index'] in source_helper['api_members'] and child['index'] in source_helper['api_members'],
                    'whole qualified source helper operation membership')
            pairs.append({'helper': helper['index'], 'helper_label': helper['label'],
                          'scope_api': parent['index'], 'capture_api': child['index'], 'private_copy': copy_index,
                          'layer': stage['layer'], 'root': stage['name'], 'role': root['role'],
                          'context': "root '" + stage['name'] + "'", 'guard': parent['guard'],
                          'metadata_primary': child['metadata_primary'], 'capture_input_model': freeze(constructed),
                          'private_result_model': freeze(root),
                          'private_result_authority': digest(qualified['whole_native']['copy'])})
        require({index for pair in pairs for index in (pair['scope_api'], pair['capture_api'])} == set(case_by_index),
                'complete nested failure source-pair partition')
        result.append({'mode': modeled['mode'], 'pairs': pairs})
    return result


def check(models, expected, records, source):
    check_sources(source)
    require(same(models, expected), 'complete nested source pair/root/role models')
    finite = module(primary['graph']['FINITE'] / 'verify.py')
    # The original graph reader exposes the independently interpreted typed
    # graph classes; identity is checked by bijection, not JSON path equality.
    Graph, Node = finite['Graph'], finite['Node']
    proof = []
    for modeled in models:
        native = records[modeled['mode']]; rows = []
        for pair in modeled['pairs']:
            parent, child = native['api'][pair['scope_api']], native['api'][pair['capture_api']]
            private = native['copies'][pair['private_copy']]
            require(parent['kind'] == 'scope' and child['kind'] == 'capture'
                    and parent['helper'] == child['helper'] == private['helper'] == pair['helper']
                    and private['kind'] == 'value-private' and private['api'] == pair['scope_api'],
                    'actual nested source API/private/helper allocation')
            private_model = primary['graph']['typed'](primary['graph']['thaw'](pair['private_result_model']), Node)
            Graph(private['copy']).matches(private_model)
            model = primary['graph']['typed'](primary['graph']['thaw'](pair['capture_input_model']), Node)
            Graph(child['before']).matches(model)
            rows.append({'scope_api': pair['scope_api'], 'capture_api': pair['capture_api'],
                         'private_copy': pair['private_copy'], 'capture_input': digest(child['before']),
                         'private_result': digest(private['copy'])})
        proof.append({'mode': modeled['mode'], 'pairs': rows})
    return proof


def captured_port(records, pair):
    return records['ordinary']['api'][pair['capture_api']]['before'][1][0][1]['inputs'][1][0][1]


def main():
    authenticate()
    source = sources(); expected = expected_models(source)
    capture = primary['result_reader']['CAPTURE']
    records = {mode: load(capture / (mode + '.json')) for mode in ('ordinary', 'storable', 'controls')}
    observed = check(expected, expected, records, source)
    controls = []
    mutations = [
        ('wrong-source-interface-role', lambda m, n, s: s.update(value=s['value'].replace("type => 'resolved_value'", "type => 'borrowed_value'")), 'exact nested source input/active-parent contract'),
        ('wrapper-after-import', lambda m, n, s: s.update(observer=s['observer'].replace(CONTRACTS['capture_wrapper'], '').replace(CONTRACTS['wrapper_before_import'], CONTRACTS['wrapper_before_import'] + '\n' + CONTRACTS['capture_wrapper'])), 'capture wrapper is installed before Value import'),
        ('wrong-parent-pair', lambda m, n, s: m[0]['pairs'][0].update(scope_api=m[0]['pairs'][1]['scope_api']), 'complete nested source pair/root/role models'),
        ('wrong-root-role', lambda m, n, s: m[0]['pairs'][0].update(role='output'), 'complete nested source pair/root/role models'),
        ('omitted-source-pair', lambda m, n, s: m[0]['pairs'].pop(), 'complete nested source pair/root/role models'),
        ('borrowed-private-owner', lambda m, n, s: n['ordinary']['copies'][m[0]['pairs'][0]['private_copy']].update(api=m[0]['pairs'][1]['scope_api']), 'actual nested source API/private/helper allocation'),
        ('wrong-capture-helper', lambda m, n, s: n['ordinary']['api'][m[0]['pairs'][0]['capture_api']].update(helper=0), 'actual nested source API/private/helper allocation'),
        ('private-result-kind', lambda m, n, s: n['ordinary']['copies'][m[0]['pairs'][0]['private_copy']]['copy'][1]['type_spec'][1].update(width=str(n['ordinary']['copies'][m[0]['pairs'][0]['private_copy']]['copy'][1]['type_spec'][1]['width'])), 'primitive value/kind disagrees with authored source model'),
        ('wrong-capture-type', lambda m, n, s: captured_port(n, m[0]['pairs'][0])['type_spec'][1].update(kind='bits'), 'primitive value/kind disagrees with authored source model'),
        ('capture-width-kind', lambda m, n, s: captured_port(n, m[0]['pairs'][0]).update(width=str(captured_port(n, m[0]['pairs'][0])['width'])), 'primitive value/kind disagrees with authored source model'),
        ('broken-cyclic-input', lambda m, n, s: captured_port(n, next(pair for pair in m[0]['pairs'] if pair['helper_label'] == 'cyclic member'))['type_spec'][1]['members'][1]['data'].__setitem__(1, '/absent'), 'unresolved or forward graph reference'),
    ]
    for name, mutate, cause in mutations:
        changed = [copy.deepcopy(item) for item in (expected, records, source)]; mutate(*changed)
        try:
            check(changed[0], expected, changed[1], changed[2])
        except ValueError as error:
            require(str(error) == cause, 'intended nested input control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green nested source-input control: ' + name)
    proof = {'models': expected, 'input_joins': observed, 'controls': controls,
             'scope': 'Whole source private-root/capture input and API/helper allocation; error forwarding and inherited/full frame meaning stay open.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved nested source-input proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed nested-input producer cannot publish')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS whole finite nested Scope/private-root/capture input joins; catch/rethrow and inherited/full frame meanings remain open.')


if __name__ == '__main__':
    main()
