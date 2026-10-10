"""Source bindings for active operation boundaries; never consume raw addresses.

This finite model deliberately stops at operation boundaries. Core/private,
helper and parser-internal identities belong to the next source-model leaf.
"""
import itertools


def graph(value, seen=None, path=''):
    """Serialize qualified source values without losing aliases or cycles."""
    if type(value) in (type(None), int, str):
        return value
    if type(value) not in (dict, list):
        raise ValueError('qualified source graph value kind')
    seen = {} if seen is None else seen
    if id(value) in seen:
        return ['reference', seen[id(value)]]
    seen[id(value)] = path
    def child(key, item):
        segment = str(key).replace('~', '~0').replace('/', '~1')
        return graph(item, seen, path + '/' + segment)
    if type(value) is dict:
        return ['hash', {key: child(key, value[key]) for key in sorted(value)}]
    return ['array', [child(i, item) for i, item in enumerate(value)]]


def root_bindings(encoded):
    if encoded[0] != 'array':
        raise ValueError('qualified source argument array')
    roots = {}
    for index, item in enumerate(encoded[1]):
        if type(item) is list:
            kind, payload = item
            if kind == 'reference':
                roots[index] = ('node:' + payload, None)
            else:
                roots[index] = ('node:/' + str(index), kind.upper())
    # A root alias may point inside another argument, so resolve its kind
    # against the complete graph rather than guessing from the displayed role.
    nodes = {}
    def visit(item, path):
        if type(item) is not list:
            return
        kind, payload = item
        if kind == 'reference':
            return
        nodes[path] = kind.upper()
        entries = payload.items() if kind == 'hash' else enumerate(payload)
        for key, value in entries:
            visit(value, path + '/' + str(key).replace('~', '~0').replace('/', '~1'))
    visit(encoded, '')
    return {index: (name, kind or nodes[name[5:]]) for index, (name, kind) in roots.items()}


def operation(boundary, source_graph, parser, domain):
    frames = boundary['frames']
    if len(frames) != 4 or frames[1]['arguments']:
        raise ValueError('complete original operation/eval/observer/wrapper shape')
    original, delegated, wrapper = (frames[i]['arguments'] for i in (0, 2, 3))
    if delegated[3:] != wrapper or len(original) != len(wrapper):
        raise ValueError('whole source operation forwarding slots')
    if [(r['original'], r['delegated']) for r in boundary['argument_role_bridge']] != [
            (a['role'], b['role']) for a, b in zip(original, wrapper, strict=True)]:
        raise ValueError('complete original source role bridge')
    roots = root_bindings(source_graph) if source_graph is not None else {}
    expected_length = len(source_graph[1]) + int(parser) if source_graph is not None else len(wrapper)
    if len(wrapper) != expected_length:
        raise ValueError('complete source graph argument membership')
    bindings, occurrences = {}, []
    for fi in (0, 2, 3):
        for ai, arg in enumerate(frames[fi]['arguments']):
            if arg['kind'] != 'reference':
                continue
            if fi == 2 and ai in (1, 2):
                name = 'saved-operation' if ai == 1 else 'fresh-caller'
                origin = {'kind': 'saved_lookup', 'expression': boundary['operation_lookup']} if ai == 1 else {
                    'kind': 'fresh_caller_array', 'expression': '[caller]'}
            else:
                slot = ai - 3 if fi == 2 else ai
                graph_slot = slot - int(parser)
                if parser and slot == 0:
                    name, origin = 'facade-receiver', {'kind': 'forwarded_receiver', 'contents': 'not published'}
                elif source_graph is not None:
                    if graph_slot not in roots:
                        raise ValueError('reference source slot has graph reference')
                    name, kind = roots[graph_slot]
                    if kind != arg['reference_kind']:
                        raise ValueError('source graph reference kind')
                    origin = {'kind': 'qualified_input_node', 'path': name[5:]}
                else:
                    name, origin = 'unresolved-slot:' + str(slot), {
                        'kind': 'nested_input_topology_pending', 'slot': slot}
            item = {'reference_kind': arg['reference_kind'], 'origin': origin}
            if name in bindings and bindings[name] != item:
                raise ValueError('same forwarded source binding has one kind and origin')
            bindings[name] = item
            occurrences.append({'frame': fi, 'argument': ai, 'role': arg['role'], 'binding': name})
    distinct, unresolved = [], []
    for left, right in itertools.combinations(sorted(bindings), 2):
        a, b = bindings[left], bindings[right]
        if a['reference_kind'] != b['reference_kind']:
            reason = 'different_reference_kinds'
        elif 'fresh-caller' in (left, right):
            reason = 'fresh_allocation_while_supplied_arguments_live'
        elif a['origin']['kind'] == b['origin']['kind'] == 'qualified_input_node':
            reason = 'distinct_nodes_in_qualified_source_graph'
        else:
            unresolved.append([left, right])
            continue
        distinct.append({'bindings': [left, right], 'reason': reason})
    return {'kind': boundary['kind'], 'domain': domain, 'operation_lookup': boundary['operation_lookup'],
            'frames': frames, 'bindings': bindings, 'occurrences': occurrences,
            'simultaneously_live_distinct': distinct, 'unresolved_distinction': unresolved,
            'lifetime': 'one active call at one throw phase in one capture; no numerical cross-domain identity',
            'input_topology': 'qualified source graph' if source_graph is not None else 'nested successor-owned'}


def derive(inputs):
    result = []
    for case in inputs:
        operations = []
        for phase in case['phases']:
            for number, boundary in enumerate(phase['operations']):
                own_input = boundary['kind'] == case['kind']
                domain = [case['mode'], case['domain'], case['index'], phase['phase'], number]
                operations.append(operation(boundary, case['source_input_graph'] if own_input else None,
                                            case['domain'] == 'parses' and own_input, domain))
        result.append({'mode': case['mode'], 'domain': case['domain'], 'index': case['index'],
                       'source_input_graph': case['source_input_graph'], 'operations': operations})
    return {'cases': result, 'scope': 'Source operation-boundary binding hypotheses only; original raw addresses, '
            'core/private/helper/parser-internal identities, external/framework/provider/formatter identity and '
            'cross-call/cross-capture numerical reuse remain unqualified.'}
