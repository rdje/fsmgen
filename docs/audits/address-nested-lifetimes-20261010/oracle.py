"""Independent graph bijections and source-expression/phase-holder oracle."""
import itertools
import re


def require(condition, message):
    if not condition:
        raise ValueError(message)


def exact(left, right):
    """JSON domain equality includes scalar kinds, especially Boolean versus integer."""
    if type(left) is not type(right):
        return False
    if type(left) is dict:
        return set(left) == set(right) and all(exact(left[key], right[key]) for key in left)
    if type(left) is list:
        return len(left) == len(right) and all(exact(a, b) for a, b in zip(left, right, strict=True))
    return left == right


class Node:
    def __init__(self, kind, path):
        self.kind, self.path, self.edges = kind, path, {}


def graph(encoded):
    allocated = {}
    def read(value, path):
        if type(value) in (str, int, type(None)):
            return value
        require(type(value) is list and len(value) == 2, 'nested qualified graph grammar')
        kind, body = value
        if kind == 'reference':
            require(type(body) is str and body in allocated, 'nested qualified prior graph alias')
            return allocated[body]
        require(kind in ('hash', 'array') and type(body) is (dict if kind == 'hash' else list),
                'nested qualified graph kind')
        node = Node(kind.upper(), path)
        allocated[path] = node
        for key, child in (body.items() if kind == 'hash' else enumerate(body)):
            node.edges[str(key)] = read(child, path + '/' + str(key).replace('~', '~0').replace('/', '~1'))
        return node
    return read(encoded, '')


def bijection(expected, actual):
    forward, backward = {}, {}
    def compare(left, right):
        if not isinstance(left, Node) or not isinstance(right, Node):
            require(type(left) is type(right) and left == right, 'whole nested source graph topology/value/alias')
            return
        if left in forward or right in backward:
            require(forward.get(left) is right and backward.get(right) is left,
                    'whole nested source graph topology/value/alias')
            return
        require(left.kind == right.kind and set(left.edges) == set(right.edges),
                'whole nested source graph topology/value/alias')
        forward[left], backward[right] = right, left
        for key in left.edges:
            compare(left.edges[key], right.edges[key])
    compare(expected, actual)
    return forward


def select(node, pointer):
    for segment in pointer.split('/')[1:]:
        node = node.edges[segment.replace('~1', '/').replace('~0', '~')]
    return node


def expected_graph(source, actual):
    args = graph(source['scope_operation_source']['source_input_graph'])
    value = graph(source['value_private']['result'])
    captured = graph(source['metadata_input']['pair']['capture_input_model'])
    require(captured.kind == 'ARRAY' and set(captured.edges) == {'0'}, 'complete nested capture source slot')
    interface = captured.edges['0']
    require(interface.kind == 'HASH' and set(interface.edges) == {'inputs', 'outputs'}, 'whole source-constructed interface shape')
    require(set(interface.edges['inputs'].edges) == {'0'} and not interface.edges['outputs'].edges,
            'whole finite source-constructed input/output arrays')
    port = interface.edges['inputs'].edges['0']
    require(set(port.edges) == {'name', 'type', 'width', 'type_spec'}
            and port.edges['name'] == 'value' and port.edges['type'] == 'resolved_value'
            and type(port.edges['width']) is type(value.edges['type_spec'].edges['width'])
            and port.edges['width'] == value.edges['type_spec'].edges['width'],
            'complete source-constructed port fields')
    require(value.edges['type_spec'].edges['kind'] != 'list', 'finite nested checked/spec alias profile')
    bijection(value.edges['type_spec'], port.edges['type_spec'])
    port.edges['type_spec'] = value.edges['type_spec']
    metadata = graph(source['metadata_input']['private']['result'])
    whole = Node('ARRAY', '')
    whole.edges = {'0': args, '1': value, '2': interface, '3': metadata}
    mapping = bijection(whole, graph(actual))
    return args, value, captured, interface, metadata, mapping


def node_descriptor(node, mapping, source):
    actual = mapping[node]
    path = actual.path
    pool = {'0': 'supplied_scope', '1': 'value_private', '2': 'constructed', '3': 'metadata_private'}[path.split('/')[1]]
    origin = {'kind': 'joint_source_node', 'node': path, 'pool': pool}
    if pool == 'value_private':
        origin['copy_index'] = source['value_private']['domain'][1]
    if pool == 'metadata_private':
        origin['copy_index'] = source['metadata_input']['private']['domain'][1]
    return 'node:' + path, {'reference_kind': node.kind, 'origin': origin}


def pair_expected(source, row):
    args, value, captured, interface, metadata, mapping = expected_graph(source, row['joint_source_graph'])
    pair = source['metadata_input']['pair']
    scope_api, capture_api = pair['scope_api'], pair['capture_api']
    expected_bindings = {}
    def node(item):
        key, descriptor = node_descriptor(item, mapping, source)
        expected_bindings[key] = descriptor
        return key
    value_root, meta_root, constructed = node(value), node(metadata), node(interface)
    value_spec = node(value.edges['type_spec'])
    scope_refs = {i: node(item) for i, item in args.edges.items() if isinstance(item, Node)}
    for kind, api, expression in (('scope', scope_api, '$value{record_value_scope}'), ('capture', capture_api, '$capture')):
        expected_bindings['saved:' + kind] = {'reference_kind': 'CODE', 'origin': {'kind': 'saved_lookup', 'expression': expression}}
        expected_bindings['caller:' + kind] = {'reference_kind': 'ARRAY', 'origin': {'kind': 'observer_caller_snapshot', 'api': api, 'expression': '[caller]'}}
    for key, original in (('metadata:sink', 'fresh:sink'), ('metadata:active', 'fresh:active')):
        old = source['metadata_hypothesis']['bindings'][original]
        expected_bindings[key] = {'reference_kind': old['reference_kind'], 'origin': {
            'kind': 'metadata_recursion_local', 'capture_api': capture_api, 'source': old['origin']}}
    views = []
    for name, record, phase, inner in (('capture-inner', capture_api, 0, True), ('scope-inner', scope_api, 0, True), ('scope-outer', scope_api, 1, False)):
        frames = source['metadata_input']['capture']['frames'] + source['inherited']['inner_path'] if inner else source['inherited']['new_outer_path']
        slots = {}
        for fi, frame in enumerate(frames):
            for ai, arg in enumerate(frame['arguments']):
                if arg['kind'] != 'reference':
                    continue
                function = frame['function']
                if function.endswith('::_collect_scalar_paths'):
                    if ai == 0:
                        item = metadata.edges['inputs'].edges['0'].edges['type_spec']
                        path = frame['arguments'][1]['value']
                        position = 0
                        for match in re.finditer(r'\.([A-Za-z_]\w*)|\[([0-9]+)\]', path):
                            require(match.start() == position, 'complete Metadata semantic member path')
                            position = match.end()
                            item = item.edges['members'].edges[match[1]] if match[1] else item.edges['items'].edges[match[2]]
                        require(position == len(path), 'complete Metadata semantic member path')
                        key = node(item)
                    else:
                        require(ai in (2, 3), 'declared recursive Metadata reference source slot')
                        key = 'metadata:sink' if ai == 2 else 'metadata:active'
                elif function.endswith('::capture_interface_port_metadata'):
                    key = constructed
                elif function.endswith('::_validate_type'):
                    key = value_spec
                elif function.endswith('::record_value_scope'):
                    key = scope_refs[str(ai)]
                elif function == 'main::call_api':
                    kind = frame['arguments'][0]['value']
                    key = 'saved:' + kind if ai == 1 else 'caller:' + kind if ai == 2 else (
                        constructed if kind == 'capture' else scope_refs[str(ai - 3)])
                elif function == 'main::__ANON__':
                    key = constructed if frame['call_site'] == 'installed_capture_wrapper' else scope_refs[str(ai)]
                else:
                    raise ValueError('undeclared independent nested reference source expression')
                require(expected_bindings[key]['reference_kind'] == arg['reference_kind'], 'qualified nested kind matches source expression')
                slots[fi, ai] = (key, arg['role'])
        active = {key for key, _ in slots.values()} | {value_root, value_spec}
        if inner:
            active |= {meta_root, constructed, 'metadata:sink', 'metadata:active'}
        retained = ['caller:capture', 'caller:scope', 'saved:capture', 'saved:scope']
        operation_case = source['capture_operation_hypothesis'] if record == capture_api else source['scope_operation_hypothesis']
        bridges = []
        for operation in operation_case['operations']:
            if operation['domain'][3] != phase:
                continue
            kind = operation['kind']
            resolved = {}
            for key, old in operation['bindings'].items():
                origin = old['origin']
                if origin['kind'] == 'saved_lookup':
                    require(origin['expression'] == ('$capture' if kind == 'capture' else '$value{record_value_scope}'),
                            'independent nested saved source lookup')
                    joined = 'saved:' + kind
                elif origin['kind'] == 'fresh_caller_array':
                    joined = 'caller:' + kind
                elif origin['kind'] == 'qualified_input_node':
                    joined = node(select(captured if kind == 'capture' else args, origin['path']))
                elif origin['kind'] == 'nested_input_topology_pending':
                    joined = constructed if kind == 'capture' else scope_refs[str(origin['slot'])]
                else:
                    raise ValueError('undeclared nested operation original binding origin')
                resolved[key] = joined
            bridges.append({'domain': operation['domain'], 'canonical_invocation': [kind, capture_api if kind == 'capture' else scope_api],
                            'bindings': resolved, 'previous_input_topology': operation['input_topology'],
                            'joined_input_topology': 'complete qualified nested source graph'})
        views.append({'name': name, 'record_api': record, 'phase': phase, 'frames': frames,
                      'event': ['inner-Metadata', capture_api] if inner else ['new-Value', scope_api], 'slots': slots,
                      'active_bindings': sorted(active), 'source_retained_bindings': retained,
                      'active_invocations': [['scope', scope_api], ['capture', capture_api]] if inner else [['scope', scope_api]],
                      'inactive_invocations': [] if inner else [['capture', capture_api]],
                      'returned_copy_delegates': [
                          {'kind': 'value-private', 'copy_index': source['value_private']['domain'][1], 'result_binding': value_root, 'active_source_holder': True, 'activation': 'returned before this throw; inactive delegate'},
                          {'kind': 'metadata-private', 'copy_index': source['metadata_input']['private']['domain'][1], 'result_binding': meta_root, 'active_source_holder': inner, 'activation': 'returned before this throw; inactive delegate'}],
                      'no_active_own_holder': [] if inner else sorted([constructed, meta_root, 'metadata:sink', 'metadata:active']),
                      'operation_bridges': bridges})
    return expected_bindings, views


def qualify(product, inputs):
    require(set(product) == {'cases', 'scope'}, 'whole nested hypothesis fields')
    require(product['scope'] == 'Complete finite nested Metadata/Value source alias, active-operation and retained-snapshot hypotheses across all source-record/throw views. Graph carrier arrays are symbolic packaging. Original numeric/private/provider/formatter/CODE identity, external/global retention, helper/parser roles and canonical publication remain open.', 'nested source-only open scopes')
    require(len(product['cases']) == len(inputs['cases']), 'complete nested source pair membership')
    measured = {'pairs': 0, 'views': 0, 'reference_slots': 0, 'operation_views': 0,
                'resolved_nested_operation_views': 0, 'distinct_relations': 0, 'unresolved_relations': 0}
    for source, row in zip(inputs['cases'], product['cases'], strict=True):
        pair = source['metadata_input']['pair']
        require(set(row) == {'mode', 'scope_api', 'capture_api', 'joint_source_graph', 'bindings', 'views', 'retention_contract'},
                'whole nested pair fields')
        require(row['mode'] == source['mode'] and type(row['scope_api']) is int and row['scope_api'] == pair['scope_api']
                and type(row['capture_api']) is int and row['capture_api'] == pair['capture_api'], 'whole nested pair allocation')
        require(row['retention_contract'] == 'Observer @api records retain both caller snapshots; saved lookups remain in the observer lexical scope. Inactive source calls do not establish object death or external/provider retention.', 'nested source retained-holder contract')
        bindings, views = pair_expected(source, row)
        require(len(row['views']) == len(views), 'complete nested source-record/throw views')
        aliases, reverse = {}, {}
        for actual, expected in zip(row['views'], views, strict=True):
            require(set(actual) == (set(expected) - {'slots'}) | {'occurrences', 'simultaneously_live_distinct', 'unresolved_distinctions'},
                    'whole nested view fields')
            require(all(actual[key] == expected[key] for key in ('name', 'record_api', 'phase', 'event'))
                    and type(actual['record_api']) is int and type(actual['phase']) is int,
                    'exact nested source record/throw-view domain')
            require(actual['frames'] == expected['frames'], 'whole qualified nested source frames')
            for item in actual['occurrences']:
                require(set(item) == {'frame', 'argument', 'role', 'binding'} and type(item['frame']) is int
                        and type(item['argument']) is int, 'nested exact operand coordinates')
            occurrences = {(item['frame'], item['argument']): item for item in actual['occurrences']}
            require(len(occurrences) == len(actual['occurrences']) and set(occurrences) == set(expected['slots']),
                    'every nested core/operation reference slot exactly once')
            for slot, (key, role) in expected['slots'].items():
                occurrence = occurrences[slot]
                require(occurrence['role'] == role and row['bindings'][occurrence['binding']] == bindings[key],
                        'nested source binding origin and kind')
                require(aliases.get(key, occurrence['binding']) == occurrence['binding']
                        and reverse.get(occurrence['binding'], key) == key, 'nested source alias equivalence across views')
                aliases[key], reverse[occurrence['binding']] = occurrence['binding'], key
            for key in ('active_bindings', 'source_retained_bindings', 'active_invocations', 'inactive_invocations',
                        'returned_copy_delegates', 'no_active_own_holder'):
                require(actual[key] == expected[key], 'nested active/retained/returned source holders')
            require(all(type(item['active_source_holder']) is bool for item in actual['returned_copy_delegates']),
                    'nested returned-copy holder Boolean kind')
            require(exact(actual['operation_bridges'], expected['operation_bridges']), 'complete joined nested operation source bindings/domains')
            distinct, unresolved = [], []
            held = set(expected['active_bindings']) | set(expected['source_retained_bindings'])
            for left, right in itertools.combinations(sorted(held), 2):
                a, b = bindings[left], bindings[right]
                if a['reference_kind'] != b['reference_kind']:
                    reason = 'different reference kinds'
                elif a['reference_kind'] == 'CODE':
                    unresolved.append([left, right])
                    continue
                elif a['origin']['kind'] != 'joint_source_node' or b['origin']['kind'] != 'joint_source_node':
                    reason = 'fresh source local/caller allocation held by active calls or observer records'
                elif a['origin']['pool'] == b['origin']['pool']:
                    reason = 'distinct nodes of one complete qualified source graph'
                elif 'constructed' in (a['origin']['pool'], b['origin']['pool']):
                    reason = 'fresh source interface construction while supplied/private roots remain held'
                else:
                    reason = 'finite detached-copy hypothesis; original provider identity not measured'
                distinct.append({'bindings': [left, right], 'reason': reason})
            require(actual['simultaneously_live_distinct'] == distinct and actual['unresolved_distinctions'] == unresolved,
                    'complete nested live distinctions and explicit opaque CODE relation')
            measured['views'] += 1
            measured['reference_slots'] += len(expected['slots'])
            measured['operation_views'] += len(expected['operation_bridges'])
            measured['resolved_nested_operation_views'] += sum(b['previous_input_topology'] == 'nested successor-owned' for b in expected['operation_bridges'])
            measured['distinct_relations'] += len(distinct)
            measured['unresolved_relations'] += len(unresolved)
        require(row['bindings'] == bindings, 'complete nested source binding membership')
        measured['pairs'] += 1
    return measured
