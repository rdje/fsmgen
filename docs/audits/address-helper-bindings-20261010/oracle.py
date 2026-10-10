"""Independent graph bijections, named member walks and semantic source roles."""
import itertools
import re
from pathlib import Path

_graphs = {'__name__': 'qualified_graph_primitives'}
exec(compile(Path('docs/audits/address-nested-lifetimes-20261010/oracle.py').read_bytes(),
             'docs/audits/address-nested-lifetimes-20261010/oracle.py', 'exec'), _graphs)
Node, graph, bijection, exact = (_graphs[key] for key in ('Node', 'graph', 'bijection', 'exact'))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def array(items):
    result = Node('ARRAY', '')
    result.edges = {str(i): item for i, item in enumerate(items)}
    return result


def named(node):
    require(node.kind == 'ARRAY' and len(node.edges) % 2 == 0, 'whole helper named source vector')
    result = {}
    for i in range(0, len(node.edges), 2):
        key = node.edges[str(i)]
        require(type(key) is str and key not in result, 'distinct helper named source roles')
        result[key] = node.edges[str(i + 1)]
    return result


def expected_profile(helper, direct, encoded):
    supplied = graph(helper['supplied_arguments'])
    family = helper['call_shape']['active']['function'] if helper['call_shape']['active'] else None
    operations, completed = [], []
    for operation in helper['named_operations']:
        values = graph(operation['normalized_operation_inputs'])
        fields = named(values)
        if operation['kind'] == 'reference':
            if family == 'reference':
                formal = supplied
            else:
                formal = graph(operation['supplied'])
                if family == 'copy':
                    bijection(supplied.edges['0'], formal.edges['0'])
                    formal.edges['0'] = supplied.edges['0']
                completed.append(formal)
            bijection(formal.edges['0'], fields['scope'])
            values.edges['1'] = formal.edges['0']
            require(fields['token'] == formal.edges['1'] and fields['context'] == 'control'
                    and exact(fields['access'], formal.edges.get('2', 'read'))
                    and exact(fields['allow_whole'], formal.edges.get('3', 0)),
                    'whole helper supplied/default source parameter values')
        elif operation['kind'] == 'scope':
            require(set(fields) == {'outer', 'local'}, 'complete scope helper source named roles')
            outer = fields['outer']
            require(set(outer.edges) == {'packet', 'held', 'output', 'scalar'} and not fields['local'].edges,
                    'complete source scope helper root/local construction')
            for name, role, argument in (('packet', 'input', '0'), ('held', 'storage', '1'), ('output', 'output', '1')):
                port = outer.edges[name]
                require(set(port.edges) == {'role', 'type_spec'} and port.edges['role'] == role,
                        'complete constructed helper port source fields')
                bijection(supplied.edges[argument], port.edges['type_spec'])
                port.edges['type_spec'] = supplied.edges[argument]
            scalar = outer.edges['scalar']
            require(set(scalar.edges) == {'role', 'type_spec'} and scalar.edges['role'] == 'output'
                    and exact(scalar.edges['type_spec'].edges, {'kind': 'bits', 'width': 7, 'signed': 0}),
                    'whole declared scalar helper source constant')
        else:
            require(operation['kind'] == 'copy' and set(fields) == {'source', 'target', 'context'},
                    'complete finite copy helper source named roles')
        operations.append(values)
    outside = graph(direct) if direct is not None else None
    expected = array([supplied, array(operations), array(completed), outside])
    mapping = bijection(expected, graph(encoded))
    return supplied, operations, outside, mapping


def qualify(product, inputs):
    scope = ('Complete finite helper/callback/own-subtest source bindings and source-held lifetimes. '
             'Graph carriers are symbolic source checkpoints, not native allocations or later scalar-flag snapshots. '
             'Original numeric/provider/formatter/Regexp/CODE identity, external framework/global retention, '
             'parser/actor/context roles and canonical publication remain open.')
    require(set(product) == {'modes', 'scope'} and product['scope'] == scope, 'helper source-only scope')
    require(len(product['modes']) == len(inputs['helper_modes']), 'complete helper source mode population')
    subs = {mode['mode']: mode for mode in inputs['subtests']['modes']}
    source_ops = {(row['mode'], row['domain'], row['index']): row for row in inputs['operation_inputs']}
    sub_indices = {body['name']: index for index, body in enumerate(inputs['subtests']['bodies'])}
    measured = dict(helpers=0, cases=0, views=0, reference_slots=0, pattern_slots=0, named_operations=0,
                    returned_operations=0, returned_result_holders=0, CODE_relations_open=0, source_distinctions=0)
    for source_mode, mode in zip(inputs['helper_modes'], product['modes'], strict=True):
        require(set(mode) == {'mode', 'profiles', 'bindings', 'cases'} and mode['mode'] == source_mode['mode'],
                'whole helper source mode allocation')
        require(len(mode['profiles']) == len(source_mode['helpers']), 'complete helper recipe population')
        own = {(row['domain'], row['index']): row for row in subs[mode['mode']]['cases']}
        require(set(own) == {(row['domain'], row['index']) for row in source_mode['cases']},
                'complete helper/subtest source case join')
        expected_bindings, keys, profiles = {}, {}, {}
        def bind(key, kind, origin):
            descriptor = {'reference_kind': kind, 'origin': origin}
            require(key not in expected_bindings or exact(expected_bindings[key], descriptor),
                    'one complete independent source binding descriptor')
            expected_bindings[key] = descriptor
            return key
        def code(key, expression, subtest=None, helper=None):
            origin = {'kind': 'source_code_handle', 'expression': expression}
            if subtest is not None:
                origin['subtest'] = subtest
            if helper is not None:
                origin['helper'] = helper
            return bind(key, 'CODE', origin)
        public = code('saved-public-subtest', "$subtest = Test::More->can('subtest')")
        for helper, actual in zip(source_mode['helpers'], mode['profiles'], strict=True):
            hi = helper['index']
            cases = [case for case in source_mode['cases'] if case['helper'] == hi]
            sub = own[cases[0]['domain'], cases[0]['index']]
            si = sub_indices[sub['name']]
            require(all(own[case['domain'], case['index']]['name'] == sub['name'] for case in cases),
                    'one source subtest entry per helper invocation')
            body = code('subtest:' + str(si) + ':body', 'authored subtest body', subtest=si)
            wrapped = code('subtest:' + str(si) + ':wrapped', 'observer subtest callback', subtest=si)
            saved = code('subtest:' + str(si) + ':helper', "main->can('refuses')", subtest=si)
            callback = code('helper:' + str(hi) + ':callback', 'original parameterless refuses callback', helper=hi)
            pattern = bind('helper:' + str(hi) + ':pattern', 'Regexp',
                           {'kind': 'source_pattern_parameter', 'helper': hi, 'pattern': cases[0]['pattern'],
                            'source_declaration': helper['source_declaration']})
            caller = bind('helper:' + str(hi) + ':caller', 'ARRAY',
                          {'kind': 'observer_helper_caller_snapshot', 'helper': hi, 'expression': '[caller]', 'holder': '@helpers'})
            direct = (source_ops[mode['mode'], cases[0]['domain'], cases[0]['index']]['source_input_graph']
                      if helper['call_shape']['completed'] else None)
            supplied, op_nodes, outside, mapping = expected_profile(helper, direct, actual['graph'])
            def node(item):
                actual_node = mapping[item]
                return bind('helper:' + str(hi) + ':node:' + actual_node.path, item.kind,
                            {'kind': 'qualified_helper_source_node', 'helper': hi, 'node': actual_node.path})
            formals = {i: node(item) for i, item in supplied.edges.items() if isinstance(item, Node)}
            forwarding, returned, activations = [], [], []
            for oi, operation in enumerate(helper['named_operations']):
                fields = named(op_nodes[oi])
                if operation['kind'] in ('reference', 'scope'):
                    roles = ('scope',) if operation['kind'] == 'reference' else ('outer', 'local')
                    forwarding += [{'operation': operation['index'], 'named_argument': role, 'binding': node(fields[role])}
                                   for role in roles]
                else:
                    previous = [op for op in helper['named_operations'][:oi] if op['kind'] == 'reference']
                    by_access = {named(graph(op['normalized_operation_inputs']))['access']: op for op in previous}
                    require(set(by_access) == {'read', 'write'}, 'complete returned read/write helper source results')
                    returned += [{'returned_operation': by_access[access]['index'], 'holder_operation': operation['index'],
                                  'named_argument': role, 'binding': node(fields[role])}
                                 for role, access in (('source', 'read'), ('target', 'write'))]
                key = (mode['mode'], 'api', operation['index'])
                if key in source_ops:
                    bijection(graph(operation['normalized_operation_inputs']), graph(source_ops[key]['source_input_graph']))
                api = operation['index']
                caller_key = bind('api:' + str(api) + ':caller', 'ARRAY',
                                  {'kind': 'observer_api_caller_snapshot', 'api': api, 'expression': '[caller]', 'holder': '@api'})
                lookup = {'reference': 'record_value_reference', 'scope': 'record_value_scope',
                          'copy': 'validate_record_port_copy'}[operation['kind']]
                saved_key = code('saved-api:' + operation['kind'], '$value{' + lookup + '}')
                activations.append({'index': api, 'kind': operation['kind'], 'activation': operation['phase'],
                                    'caller_binding': caller_key, 'saved_operation_binding': saved_key})
            if helper['call_shape']['completed']:
                roles = re.findall(r'\b(source|target)\s*=>\s*reference\(', helper['source_statement'])
                require(len(roles) == 1 and len(helper['named_operations']) == 1, 'complete direct returned source expression')
                returned.append({'returned_operation': helper['named_operations'][0]['index'],
                                 'holder_operation': cases[0]['index'], 'named_argument': roles[0],
                                 'binding': node(named(outside)[roles[0]])})
            expected = {'helper': hi, 'subtest': si, 'name': sub['name'], 'source_recipe': helper,
                        'graph': actual['graph'], 'formal_bindings': formals, 'forwarding': forwarding,
                        'returned_result_holders': returned, 'named_activations': activations}
            require(exact(actual, expected), 'complete helper source graph/forwarding/activation profile')
            keys[hi] = (si, body, wrapped, saved, callback, pattern, caller, formals)
            profiles[hi] = expected
            measured['helpers'] += 1
            measured['named_operations'] += len(activations)
            measured['returned_operations'] += sum(op['activation'] == 'returned_before_outer_operation' for op in activations)
            measured['returned_result_holders'] += len(returned)
        require(len(mode['cases']) == len(source_mode['cases']), 'complete helper refusal case population')
        alias_keys, reverse = {}, {}
        for source_case, case in zip(source_mode['cases'], mode['cases'], strict=True):
            sub = own[source_case['domain'], source_case['index']]
            si, body, wrapped, saved, callback, pattern, caller, formals = keys[source_case['helper']]
            require(set(case) == {'domain', 'index', 'helper', 'subtest', 'views'}
                    and exact({k: case[k] for k in ('domain', 'index', 'helper')},
                              {k: source_case[k] for k in ('domain', 'index', 'helper')}) and type(case['subtest']) is int
                    and case['subtest'] == si, 'whole helper case source allocation')
            require(len(case['views']) == len(source_case['paths']), 'complete helper throw view population')
            profile = profiles[case['helper']]
            for phase, (path, view) in enumerate(zip(source_case['paths'], case['views'], strict=True)):
                require(exact(view['domain'], [mode['mode'], case['domain'], case['index'], phase]),
                        'exact helper source record/phase domain')
                events = []
                for pair in inputs['nested_pairs']:
                    if pair['mode'] == mode['mode'] and case['domain'] == 'api':
                        if case['index'] == pair['capture_api'] or (case['index'] == pair['scope_api'] and phase == 0):
                            events.append(['inner-Metadata', pair['capture_api']])
                        elif case['index'] == pair['scope_api']:
                            events.append(['new-Value', pair['scope_api']])
                event = events[0] if events else ['own-source-throw', case['domain'], case['index'], phase]
                require(len(events) <= 1 and exact(view['event'], event), 'complete helper nested/shared source event')
                frames = path + sub['body_frames'] + sub['entry_frames']
                require(exact(view['frames'], frames), 'whole qualified helper/subtest source frames')
                slots = {}
                for fi, frame in enumerate(frames):
                    for ai, arg in enumerate(frame['arguments']):
                        if arg['kind'] == 'regex_source':
                            binding = pattern
                        elif arg['kind'] != 'reference':
                            continue
                        elif arg['role'] == 'original_compiled_parameterless_callback':
                            binding = callback
                        elif frame.get('role') == 'saved_public_delegate':
                            binding = wrapped
                        elif frame.get('role') == 'own_subtest_entry':
                            binding = body
                        else:
                            family = frame['function'].split('::')[-1]
                            index = {'scope_for': {'source_type': '0', 'target_type': '1'},
                                     'reference': {'scope': '0'}, 'copy': {'scope': '0'}}[family][arg['role']]
                            binding = formals[index]
                        slots[fi, ai] = (binding, arg['role'])
                rows = view['occurrences']
                actual_slots = {(row['frame'], row['argument']): row for row in rows}
                require(len(actual_slots) == len(rows) and set(actual_slots) == set(slots)
                        and all(set(row) == {'frame', 'argument', 'role', 'binding'}
                                and type(row['frame']) is int and type(row['argument']) is int for row in rows),
                        'every helper reference/pattern slot exactly once')
                for slot, (binding, role) in slots.items():
                    row = actual_slots[slot]
                    require(row['role'] == role and exact(mode['bindings'][row['binding']], expected_bindings[binding]),
                            'helper source binding origin/kind')
                    require(alias_keys.get(binding, row['binding']) == row['binding']
                            and reverse.get(row['binding'], binding) == binding, 'helper source alias equivalence across views')
                    alias_keys[binding], reverse[row['binding']] = row['binding'], binding
                held = sorted({key for key, _ in slots.values()} | {body, wrapped, saved, public, callback, pattern, caller}
                              | {row['binding'] for row in profile['forwarding'] + profile['returned_result_holders']}
                              | {op[key] for op in profile['named_activations'] for key in ('caller_binding', 'saved_operation_binding')})
                opaque = [list(pair) for pair in itertools.combinations(held, 2)
                          if expected_bindings[pair[0]]['reference_kind'] == expected_bindings[pair[1]]['reference_kind'] == 'CODE']
                distinct = [list(pair) for pair in itertools.combinations(held, 2) if list(pair) not in opaque]
                wanted = {'held_bindings': held, 'retained_bindings': [caller] + [op['caller_binding'] for op in profile['named_activations']],
                          'active_named_operations': [op['index'] for op in profile['named_activations'] if op['activation'] == 'active'],
                          'inactive_named_operations': [op['index'] for op in profile['named_activations'] if op['activation'] == 'returned_before_outer_operation'],
                          'opaque_CODE_relations': opaque, 'source_distinct_bindings': distinct,
                          'distinction_scope': 'Different source kinds, fresh retained caller arrays, or distinct complete source graph nodes; detached returns are finite source hypotheses, not native identity.',
                          'public_delegate_activation': 'active own source call; internal framework interval opaque',
                          'opaque_framework_interval': {'after': len(path) + len(sub['body_frames']) - 1,
                                                        'before': len(path) + len(sub['body_frames']), 'scope': sub['external_interval']}}
                require(set(view) == set(wanted) | {'domain', 'event', 'frames', 'occurrences'}, 'whole helper source view fields')
                require(all(exact(view[key], value) for key, value in wanted.items()), 'complete helper active/retained/inactive/opaque source holders')
                measured['views'] += 1
                measured['reference_slots'] += sum(arg['kind'] == 'reference' for frame in frames for arg in frame['arguments'])
                measured['pattern_slots'] += sum(arg['kind'] == 'regex_source' for frame in frames for arg in frame['arguments'])
                measured['CODE_relations_open'] += len(opaque)
                measured['source_distinctions'] += len(distinct)
            measured['cases'] += 1
        require(exact(mode['bindings'], expected_bindings), 'complete helper source binding membership')
    return measured
