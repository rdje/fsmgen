"""Independently select referents from source expressions and closed-type walks.

The producer tags predicate-model runtime objects. This oracle instead walks
qualified private results and source argument slots; it never imports it.
"""
import itertools
import re


def require(condition, message):
    if not condition:
        raise ValueError(message)


class Node:
    def __init__(self, kind, path):
        self.kind, self.path, self.edges = kind, path, {}


def graph(encoded):
    seen = {}
    def read(value, path):
        if type(value) in (str, int, type(None)):
            return value
        require(type(value) is list and len(value) == 2, 'core qualified typed graph grammar')
        tag, body = value
        if tag == 'reference':
            require(type(body) is str and body in seen, 'core graph prior alias target')
            return seen[body]
        require(tag in ('hash', 'array') and type(body) is (dict if tag == 'hash' else list), 'core graph container kind')
        node = Node(tag.upper(), path)
        seen[path] = node
        for key, child in (body.items() if tag == 'hash' else enumerate(body)):
            node.edges[str(key)] = read(child, path + '/' + str(key).replace('~', '~0').replace('/', '~1'))
        return node
    return read(encoded, '')


def closed_failure(spec):
    """Finite pinned _closed_type source order; Metadata admission is a prerequisite."""
    active = []
    def walk(node):
        require(isinstance(node, Node) and node.kind == 'HASH' and node not in active,
                'direct closed type is an admitted acyclic map')
        active.append(node)
        kind = node.edges['kind']
        extra = ['members', 'member_order'] if kind == 'record' else ['items'] if kind == 'list' else []
        required = ['kind', 'width', 'signed', *extra]
        optional = [] if extra else ['state_model']
        if not set(required) <= set(node.edges):
            return 'keys.2', list(active)
        if not set(node.edges) <= set(required + optional):
            return 'keys.3', list(active)
        require(str(node.edges['signed']) in ('0', '1'), 'direct signed predicate admitted by Metadata')
        if extra and int(node.edges['signed']) != 0:
            return 'closed_type.2', list(active)
        if extra:
            if kind == 'record':
                order = node.edges['member_order'].edges
                children = [node.edges['members'].edges[order[str(i)]] for i in range(len(order))]
            else:
                items = node.edges['items'].edges
                children = [items[str(i)] for i in range(len(items))]
            for child in children:
                result = walk(child)
                if result is not None:
                    return result
        active.pop()
        return None
    return walk(spec)


def expected_slots(source):
    root = graph(source['arguments'])
    require(isinstance(root, Node) and root.kind == 'ARRAY' and len(root.edges) % 2 == 0,
            'whole core source named argument array')
    named = {root.edges[str(i)]: root.edges[str(i + 1)] for i in range(0, len(root.edges), 2)}
    private = source['private']
    selectors = []
    for item in private:
        require(item['domain'][0] == source['mode'] and item['api'] == source['index'] and item['kind'] == 'value-private',
                'qualified core private source allocation')
    if source['kind'] == 'copy':
        roles = [role for role in ('source', 'target') if isinstance(named[role], Node) and named[role].kind == 'HASH']
        require(len(roles) == len(private), 'independent source/target clone assignment order')
        selectors = [(role, graph(item['result']), item['domain'][1]) for role, item in zip(roles, private, strict=True)]
    elif source['kind'] == 'scope':
        require([r['copy_index'] for r in source['scope_stages']] == [r['domain'][1] for r in private],
                'independent complete Scope clone assignment order')
        selectors = [(stage['layer'] + '.' + stage['name'], graph(item['result']), item['domain'][1])
                     for stage, item in zip(source['scope_stages'], private, strict=True)]
    elif private:
        require(len(private) == 1, 'independent one selected reference clone')
        name = re.match(r'([A-Za-z_]\w*)', named['token'])[1]
        selectors = [('scope.' + name, graph(private[0]['result']), private[0]['domain'][1])]
    frames = source['frames']
    type_context = next((a['value'] for f in frames if f['function'].endswith('::_validate_type')
                         for a in f['arguments'] if a['role'] == 'context'), None)
    active_copy, closed = None, None
    if type_context is not None:
        require(source['kind'] == 'scope' and selectors, 'finite direct type ancestry belongs to Scope')
        name = re.fullmatch(r"root '([^']+)'", type_context)[1]
        active_copy = selectors[-1]
        require(active_copy[0].endswith('.' + name), 'last reached Scope clone owns the active root context')
        closed = closed_failure(active_copy[1].edges['type_spec'])
        require(closed is not None and closed[0] == source['guard'], 'independent complete closed-type first guard')
    if any(f['function'].endswith('::_validate_reference') for f in frames):
        require(source['kind'] == 'copy' and source['guard'] == 'reference_value.2', 'finite direct reference validation guard')
        for selected in selectors:
            value = selected[1].edges
            width = value['width']
            if re.fullmatch(r'[1-9][0-9]*', str(width)) is None or int(width) != int(value['type_spec'].edges['width']):
                active_copy = selected
                break
        require(active_copy is not None, 'first failing source/target width selects its own copy')
    closed_frames = [i for i, f in enumerate(frames) if f['function'].endswith('::_closed_type')]
    if closed is not None:
        require(len(closed_frames) == len(closed[1]), 'complete independent closed-type active ancestry')
    slots = {}
    for fi, frame in enumerate(frames):
        for ai, arg in enumerate(frame['arguments']):
            if arg['kind'] != 'reference':
                continue
            role = arg['role']
            if fi == len(frames) - 1:
                node = root.edges[str(ai)]
                require(isinstance(node, Node), 'source entry reference comes from supplied argument slot')
                origin = {'kind': 'supplied_input_node', 'node': node.path}
                kind = node.kind
            elif role in ('required_keys', 'optional_keys'):
                if frame['call_site'] == 'closed_keys':
                    spec_kind = closed[1][-1].edges['kind']
                    extra = ['members', 'member_order'] if spec_kind == 'record' else ['items'] if spec_kind == 'list' else []
                    required, optional = ['kind', 'width', 'signed', *extra], [] if extra else ['state_model']
                else:
                    required = {'scope_keys': ['outer', 'local'], 'reference_keys': ['scope', 'token', 'access', 'context'],
                                'copy_keys': ['source', 'target', 'context']}[frame['call_site']]
                    optional = ['allow_whole'] if frame['call_site'] == 'reference_keys' else []
                origin = {'kind': 'fresh_key_array', 'source_values': required if role == 'required_keys' else optional}
                kind = 'ARRAY'
            elif frame['call_site'] in ('scope_keys', 'reference_keys', 'copy_keys'):
                origin = {'kind': 'fresh_named_arguments', 'keys': sorted(named), 'statement': 'my %args = @_;'}
                kind = 'HASH'
            else:
                require(active_copy is not None, 'every internal core reference has an active source copy')
                if frame['function'].endswith('::_keys'):
                    node = closed[1][-1]
                elif frame['function'].endswith('::_closed_type'):
                    node = list(reversed(closed[1]))[closed_frames.index(fi)]
                elif frame['function'].endswith('::_validate_type'):
                    node = active_copy[1].edges['type_spec']
                elif frame['function'].endswith('::_validate_reference'):
                    node = active_copy[1]
                else:
                    raise ValueError('undeclared internal direct Value reference source expression')
                origin = {'kind': 'qualified_private_result', 'copy_index': active_copy[2], 'node': node.path,
                          'source_root': active_copy[0], 'api': source['index']}
                kind = node.kind
            require(kind == arg['reference_kind'], 'qualified original reference kind matches its source expression')
            symbol = ('fresh', fi, ai) if origin['kind'].startswith('fresh_') else tuple(sorted(origin.items()))
            slots[fi, ai] = (origin, kind, arg['role'], symbol)
    return slots


def qualify(product, inputs):
    require(set(product) == {'cases', 'scope'}, 'whole core hypothesis fields')
    require(product['scope'] == 'Complete finite direct Value core source binding hypotheses; '
            'entry arguments retain supplied referents while active validator locals may hold detached copies. '
            'Original numeric/private/provider/formatter identities, cross-call/post-return lifetimes and '
            'Metadata/nested/helper/parser roles and canonical publication remain open.', 'core source-only open scopes')
    require(len(product['cases']) == len(inputs['cases']), 'complete direct core case membership')
    measured = {'cases': 0, 'reference_slots': 0, 'distinct_relations': 0, 'private_result_slots': 0, 'fresh_slots': 0}
    for source, row in zip(inputs['cases'], product['cases'], strict=True):
        require(set(row) == {'mode', 'index', 'kind', 'guard', 'frames', 'bindings', 'occurrences',
                             'simultaneously_live_distinct', 'domain'}, 'whole direct core case fields')
        require(type(row['index']) is int and all(row[key] == source[key] for key in ('mode', 'index', 'kind', 'guard', 'frames')),
                'whole independently qualified direct core source path')
        require(row['domain'] == [source['mode'], 'api', source['index'], 'direct-source-throw']
                and type(row['domain'][2]) is int, 'exact active direct core capture/call/throw domain')
        expected = expected_slots(source)
        actual = {(r['frame'], r['argument']): r for r in row['occurrences']}
        require(len(actual) == len(row['occurrences']) and set(actual) == set(expected), 'every direct core reference slot exactly once')
        require(set(row['bindings']) == {r['binding'] for r in actual.values()}, 'complete direct core binding membership')
        for slot, (origin, kind, role, symbol) in expected.items():
            occurrence = actual[slot]
            require(set(occurrence) == {'frame', 'argument', 'role', 'binding'} and occurrence['role'] == role,
                    'exact direct core source operand role')
            descriptor = row['bindings'][occurrence['binding']]
            require(set(descriptor) == {'reference_kind', 'origin', 'lifetime'}, 'whole direct core binding descriptor')
            require(descriptor['reference_kind'] == kind, 'core source reference kind')
            require(descriptor['origin'] == origin, 'core source referent origin')
            require(descriptor['lifetime'] == 'held by active source call at this throw; no post-return or numeric identity',
                    'core source active-call lifetime')
            measured['private_result_slots'] += int(origin['kind'] == 'qualified_private_result')
            measured['fresh_slots'] += int(origin['kind'].startswith('fresh_'))
        for left, right in itertools.combinations(expected, 2):
            require((expected[left][3] == expected[right][3]) ==
                    (actual[left]['binding'] == actual[right]['binding']), 'core source alias equivalence')
        distinct = []
        for left, right in itertools.combinations(sorted(row['bindings']), 2):
            a, b = row['bindings'][left], row['bindings'][right]
            if a['reference_kind'] != b['reference_kind']:
                reason = 'different reference kinds'
            elif a['origin']['kind'].startswith('fresh_') or b['origin']['kind'].startswith('fresh_'):
                reason = 'fresh source allocation while supplied arguments and active locals live'
            elif a['origin']['kind'] == b['origin']['kind'] == 'supplied_input_node':
                reason = 'distinct simultaneously retained supplied graph nodes'
            elif (a['origin']['kind'] == b['origin']['kind'] == 'qualified_private_result'
                  and a['origin']['copy_index'] == b['origin']['copy_index']):
                reason = 'distinct nodes of one qualified private result graph'
            else:
                reason = 'finite fresh-copy hypothesis; original provider identity not measured'
            distinct.append({'bindings': [left, right], 'reason': reason})
        require(row['simultaneously_live_distinct'] == distinct, 'complete core simultaneous-live distinction allocation')
        measured['cases'] += 1
        measured['reference_slots'] += len(expected)
        measured['distinct_relations'] += len(distinct)
    return measured
