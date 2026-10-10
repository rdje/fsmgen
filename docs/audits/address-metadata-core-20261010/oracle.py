"""Independent encoded-graph walk of Metadata guards and live source slots."""
import itertools
import re


def require(condition, message):
    if not condition:
        raise ValueError(message)


class Node:
    def __init__(self, kind, path):
        self.kind, self.path, self.edges = kind, path, {}


def graph(encoded):
    allocated = {}
    def read(value, path):
        if type(value) in (str, int, type(None)):
            return value
        require(type(value) is list and len(value) == 2, 'Metadata qualified graph grammar')
        tag, body = value
        if tag == 'reference':
            require(type(body) is str and body in allocated, 'Metadata qualified prior alias')
            return allocated[body]
        require(tag in ('hash', 'array') and type(body) is (dict if tag == 'hash' else list),
                'Metadata qualified graph container kind')
        node = Node(tag.upper(), path); allocated[path] = node
        for key, child in (body.items() if tag == 'hash' else enumerate(body)):
            node.edges[str(key)] = read(child, path + '/' + str(key).replace('~', '~0').replace('/', '~1'))
        return node
    return read(encoded, '')


class Failed(Exception):
    pass


def traversal(spec):
    """Follow the pinned Perl order with one shared active map and sink."""
    stack, active, sink = [], set(), []
    def fail(guard):
        raise Failed(guard, list(stack), sorted(node.path for node in active), list(sink))
    def is_integer(value):
        return type(value) in (str, int) and re.fullmatch(r'[1-9][0-9]*', str(value)) is not None
    def walk(node, path):
        stack.append((node, path)); entered = False
        try:
            if not isinstance(node, Node) or node.kind != 'HASH':
                fail('metadata_type.1')
            if node in active:
                fail('metadata_type.2')
            active.add(node); entered = True
            fields = node.edges
            if not is_integer(fields.get('width')):
                fail('metadata_type.3')
            kind = fields.get('kind', '')
            if kind in ('bit', 'bits'):
                if kind == 'bit' and int(fields['width']) != 1:
                    fail('metadata_type.4')
                if 'signed' in fields and not (type(fields['signed']) in (str, int) and str(fields['signed']) in ('0', '1')):
                    fail('metadata_type.5')
                if 'state_model' in fields and fields['state_model'] not in ('two_state', 'four_state'):
                    fail('metadata_type.6')
                sink.append(path)
                return
            width = 0
            if kind == 'record':
                members, order = fields.get('members'), fields.get('member_order')
                if not (isinstance(members, Node) and members.kind == 'HASH'
                        and isinstance(order, Node) and order.kind == 'ARRAY' and order.edges):
                    fail('metadata_type.7')
                if len(members.edges) != len(order.edges):
                    fail('metadata_type.8')
                seen = set()
                for i in range(len(order.edges)):
                    name = order.edges[str(i)]
                    if not (type(name) is str and re.fullmatch(r'[A-Za-z_]\w*', name)
                            and name not in seen and name in members.edges):
                        fail('metadata_type.9')
                    seen.add(name)
                    child = members.edges[name]
                    walk(child, path + '.' + name)
                    width += int(child.edges['width'])
            elif kind == 'list':
                if not path:
                    fail('metadata_type.10')
                items = fields.get('items')
                if not (isinstance(items, Node) and items.kind == 'ARRAY' and items.edges):
                    fail('metadata_type.11')
                for i in range(len(items.edges)):
                    child = items.edges[str(i)]
                    walk(child, path + '[' + str(i) + ']')
                    width += int(child.edges['width'])
            else:
                fail('metadata_type.unsupported')
            if width != int(fields['width']):
                fail('metadata_type.12')
        finally:
            if entered:
                active.remove(node)
            stack.pop()
    try:
        walk(spec, '')
    except Failed as error:
        guard, ancestry, members, completed = error.args
        return {'guard': guard, 'ancestry': ancestry, 'active': members, 'sink': completed}
    raise ValueError('independent Metadata source traversal must fail')


def expected_slots(source):
    captured, pair, copied = source['capture'], source['pair'], source['private']
    require(copied['domain'][0] == source['mode'] and type(copied['domain'][1]) is int
            and copied['api'] == captured['index'] and copied['kind'] == 'metadata-private',
            'independent Metadata private allocation')
    supplied = graph(pair['capture_input_model'])
    require(isinstance(supplied, Node) and supplied.kind == 'ARRAY' and set(supplied.edges) == {'0'}
            and supplied.edges['0'].kind == 'HASH', 'independent constructed capture argument slot')
    interface = graph(copied['result'])
    require(interface.kind == 'HASH' and interface.edges['inputs'].kind == 'ARRAY'
            and set(interface.edges['inputs'].edges) == {'0'} and not interface.edges['outputs'].edges,
            'independent finite Metadata clone interface traversal')
    spec = interface.edges['inputs'].edges['0'].edges['type_spec']
    event = traversal(spec)
    require(event['guard'] == captured['guard'], 'independent Metadata first guard/path')
    recursive = [i for i, frame in enumerate(captured['frames']) if frame['function'].endswith('::_collect_scalar_paths')]
    require(len(recursive) == len(event['ancestry']), 'complete independent Metadata active ancestry')
    slots = {}
    for fi, frame in enumerate(captured['frames']):
        for ai, arg in enumerate(frame['arguments']):
            if arg['kind'] != 'reference':
                continue
            if frame['function'].endswith('::capture_interface_port_metadata'):
                node = supplied.edges[str(ai)]
                origin, kind = {'kind': 'supplied_capture_input', 'node': node.path}, node.kind
            elif frame['function'].endswith('::_collect_scalar_paths'):
                node, path = list(reversed(event['ancestry']))[recursive.index(fi)]
                require(frame['arguments'][1]['value'] == path, 'independent Metadata first guard/path')
                if ai == 0:
                    origin = {'kind': 'qualified_metadata_private_result', 'api': captured['index'],
                              'copy_index': copied['domain'][1], 'node': node.path}
                    kind = node.kind
                elif ai == 2:
                    origin, kind = {'kind': 'fresh_scalar_path_sink', 'paths': event['sink']}, 'ARRAY'
                elif ai == 3:
                    origin, kind = {'kind': 'fresh_active_type_path', 'nodes': event['active']}, 'HASH'
                else:
                    raise ValueError('undeclared Metadata recursive reference source slot')
            else:
                raise ValueError('undeclared Metadata core source frame')
            require(kind == arg['reference_kind'], 'qualified Metadata reference kind matches source expression')
            symbol = ('copy', origin['copy_index'], origin['node']) if origin['kind'] == 'qualified_metadata_private_result' else (origin['kind'],)
            slots[fi, ai] = (origin, kind, arg['role'], symbol)
    return slots


def qualify(product, inputs):
    require(set(product) == {'cases', 'scope'}, 'whole Metadata hypothesis fields')
    require(product['scope'] == 'Complete finite Metadata core source bindings and shared recursion-local hypotheses. Original numeric/private/provider/formatter identity, later Value throw joins, helper/parser roles and canonical publication remain open.',
            'Metadata source-only open scopes')
    require(len(product['cases']) == len(inputs['cases']), 'complete Metadata case membership')
    measured = {'live_captures': 0, 'preserved_source_cases': 0, 'reference_slots': 0,
                'recursive_frames': 0, 'distinct_relations': 0, 'cyclic_alias_cases': 0}
    for source, row in zip(inputs['cases'], product['cases'], strict=True):
        captured, pair = source['capture'], source['pair']
        require(set(row) == {'mode', 'capture_api', 'scope_api', 'guard', 'frames', 'bindings', 'occurrences',
                             'simultaneously_live_distinct', 'domain', 'caught_outer_trace'}, 'whole Metadata case fields')
        require(row['mode'] == source['mode'] and type(row['capture_api']) is int and row['capture_api'] == captured['index']
                and type(row['scope_api']) is int and row['scope_api'] == pair['scope_api']
                and row['guard'] == captured['guard'] and row['frames'] == captured['frames'],
                'whole qualified Metadata source case')
        require(row['domain'] == [source['mode'], 'api', captured['index'], 'inner-Metadata-source-throw']
                and type(row['domain'][2]) is int, 'exact Metadata active capture/throw domain')
        require(row['caught_outer_trace'] == {'api': pair['scope_api'], 'frames': source['outer']['frames'],
                'state': 'embedded caught trace, inactive before the later Value throw; cross-operation join remains open'},
                'Metadata caught outer trace is inactive')
        expected = expected_slots(source)
        for occurrence in row['occurrences']:
            require(set(occurrence) == {'frame', 'argument', 'role', 'binding'}
                    and type(occurrence['frame']) is int and type(occurrence['argument']) is int,
                    'Metadata exact source operand coordinates')
        actual = {(r['frame'], r['argument']): r for r in row['occurrences']}
        require(len(actual) == len(row['occurrences']) and set(actual) == set(expected), 'every Metadata reference slot exactly once')
        require(set(row['bindings']) == {r['binding'] for r in actual.values()}, 'complete Metadata binding membership')
        for slot, (origin, kind, role, symbol) in expected.items():
            occurrence = actual[slot]; descriptor = row['bindings'][occurrence['binding']]
            require(occurrence['role'] == role, 'Metadata source operand role')
            require(set(descriptor) == {'reference_kind', 'origin', 'lifetime'}, 'whole Metadata binding descriptor')
            require(descriptor['reference_kind'] == kind, 'Metadata source reference kind')
            require(descriptor['origin'] == origin, 'Metadata source referent/local contents')
            require(descriptor['lifetime'] == 'held by active Metadata capture/traversal at the inner throw; no later outer-throw identity',
                    'Metadata source active-call lifetime')
        for left, right in itertools.combinations(expected, 2):
            require((expected[left][3] == expected[right][3]) == (actual[left]['binding'] == actual[right]['binding']),
                    'Metadata source alias equivalence')
        distinct = []
        for left, right in itertools.combinations(sorted(row['bindings']), 2):
            a, b = row['bindings'][left], row['bindings'][right]
            reason = ('different reference kinds' if a['reference_kind'] != b['reference_kind'] else
                      'fresh source local allocation while supplied arguments and active clone nodes live'
                      if a['origin']['kind'].startswith('fresh_') or b['origin']['kind'].startswith('fresh_') else
                      'distinct nodes of one qualified Metadata result graph'
                      if a['origin']['kind'] == b['origin']['kind'] == 'qualified_metadata_private_result' else
                      'finite detached-copy hypothesis; original provider identity not measured')
            distinct.append({'bindings': [left, right], 'reason': reason})
        require(row['simultaneously_live_distinct'] == distinct, 'complete Metadata simultaneous-live distinctions')
        measured['live_captures'] += 1; measured['preserved_source_cases'] += 2
        measured['reference_slots'] += len(expected); measured['distinct_relations'] += len(distinct)
        measured['recursive_frames'] += sum(f['function'].endswith('::_collect_scalar_paths') for f in row['frames'])
        measured['cyclic_alias_cases'] += int(row['guard'] == 'metadata_type.2')
    return measured
