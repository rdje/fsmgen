"""Check binding relations directly from source slots and graph topology.

No producer function is imported. This checks operation forwarding only;
matching symbolic relations is not a measurement of old numeric addresses.
"""
import itertools


def demand(condition, message):
    if not condition:
        raise ValueError(message)


def topology(encoded):
    nodes, references = {}, {}
    def descend(value, path):
        if type(value) in (str, int, type(None)):
            return
        demand(type(value) is list and len(value) == 2, 'whole typed source graph grammar')
        tag, contents = value
        if tag == 'reference':
            demand(type(contents) is str and contents in nodes, 'source alias targets an earlier live graph node')
            references[path] = contents
            return
        demand(tag in ('hash', 'array') and type(contents) is (dict if tag == 'hash' else list),
               'whole typed source graph container')
        nodes[path] = tag.upper()
        for key, child in (contents.items() if tag == 'hash' else enumerate(contents)):
            descend(child, path + '/' + str(key).replace('~', '~0').replace('/', '~1'))
    descend(encoded, '')
    demand(nodes.get('') == 'ARRAY', 'whole source argument array')
    return nodes, references


def qualify(product, inputs):
    demand(set(product) == {'cases', 'scope'}, 'whole source hypothesis product fields')
    demand(product['scope'] == 'Source operation-boundary binding hypotheses only; original raw addresses, '
           'core/private/helper/parser-internal identities, external/framework/provider/formatter identity and '
           'cross-call/cross-capture numerical reuse remain unqualified.', 'source-only open scopes')
    demand(len(product['cases']) == len(inputs), 'complete source case membership')
    totals = {'cases': 0, 'operations': 0, 'occurrences': 0, 'distinct_relations': 0,
              'unresolved_relations': 0, 'nested_topology_pending': 0}
    for source, actual in zip(inputs, product['cases'], strict=True):
        demand(set(actual) == {'mode', 'domain', 'index', 'source_input_graph', 'operations'}, 'complete case fields')
        demand(all(actual[key] == source[key] for key in ('mode', 'domain', 'index', 'source_input_graph')),
               'exact source case and whole graph allocation')
        nodes, aliases = topology(source['source_input_graph'])
        boundaries = [(phase['phase'], number, boundary) for phase in source['phases']
                      for number, boundary in enumerate(phase['operations'])]
        demand(len(actual['operations']) == len(boundaries), 'complete source operation membership')
        for (phase, number, boundary), row in zip(boundaries, actual['operations'], strict=True):
            demand(set(row) == {'kind', 'domain', 'operation_lookup', 'frames', 'bindings', 'occurrences',
                               'simultaneously_live_distinct', 'unresolved_distinction', 'lifetime', 'input_topology'},
                   'complete source operation fields')
            demand(row['domain'] == [source['mode'], source['domain'], source['index'], phase, number],
                   'exact per-capture per-phase active-call domain')
            demand(row['kind'] == boundary['kind'] and row['frames'] == boundary['frames']
                   and row['operation_lookup'] == boundary['operation_lookup'], 'whole source operation/frames/lookup')
            demand(row['lifetime'] == 'one active call at one throw phase in one capture; no numerical cross-domain identity',
                   'no inferred numerical cross-domain identity')
            supplied = boundary['frames'][3]['arguments']
            own = boundary['kind'] == source['kind']
            parser = source['domain'] == 'parses' and own
            demand(row['input_topology'] == ('qualified source graph' if own else 'nested successor-owned'),
                   'source graph authority versus nested open scope')
            if own:
                demand(len(supplied) == len(source['source_input_graph'][1]) + int(parser),
                       'whole supplied input slot membership')
            expected = {}
            for fi, frame in enumerate(boundary['frames']):
                for ai, arg in enumerate(frame['arguments']):
                    if arg['kind'] != 'reference':
                        continue
                    if fi == 2 and ai == 1:
                        symbol, origin = ('lookup', boundary['operation_lookup']), {
                            'kind': 'saved_lookup', 'expression': boundary['operation_lookup']}
                    elif fi == 2 and ai == 2:
                        symbol, origin = ('new', 'caller'), {'kind': 'fresh_caller_array', 'expression': '[caller]'}
                    else:
                        slot = ai - 3 if fi == 2 else ai
                        if parser and slot == 0:
                            symbol, origin = ('receiver',), {'kind': 'forwarded_receiver', 'contents': 'not published'}
                        elif own:
                            path = '/' + str(slot - int(parser))
                            target = aliases.get(path, path)
                            demand(target in nodes and nodes[target] == arg['reference_kind'], 'source root reference kind')
                            symbol, origin = ('graph', target), {'kind': 'qualified_input_node', 'path': target}
                        else:
                            symbol, origin = ('pending', slot), {'kind': 'nested_input_topology_pending', 'slot': slot}
                    expected[fi, ai] = (symbol, origin, arg['role'], arg['reference_kind'])
            observed = {(r['frame'], r['argument']): r for r in row['occurrences']}
            demand(len(observed) == len(row['occurrences']) and set(observed) == set(expected),
                   'every reference operand source slot exactly once')
            demand(set(row['bindings']) == {r['binding'] for r in observed.values()}, 'complete binding membership')
            symbols = {}
            for slot, (symbol, origin, role, kind) in expected.items():
                r = observed[slot]
                demand(set(r) == {'frame', 'argument', 'role', 'binding'} and r['role'] == role,
                       'exact reference operand role')
                binding = row['bindings'][r['binding']]
                demand(binding == {'reference_kind': kind, 'origin': origin}, 'source binding origin and reference kind')
                symbols[r['binding']] = symbol
            for left, right in itertools.combinations(expected, 2):
                demand((expected[left][0] == expected[right][0]) ==
                       (observed[left]['binding'] == observed[right]['binding']), 'exact forwarded source alias equivalence')
            distinct, pending = [], []
            for left, right in itertools.combinations(sorted(symbols), 2):
                a, b = row['bindings'][left], row['bindings'][right]
                if a['reference_kind'] != b['reference_kind']:
                    reason = 'different_reference_kinds'
                elif ('new', 'caller') in (symbols[left], symbols[right]):
                    reason = 'fresh_allocation_while_supplied_arguments_live'
                elif symbols[left][0] == symbols[right][0] == 'graph':
                    reason = 'distinct_nodes_in_qualified_source_graph'
                else:
                    pending.append([left, right]); continue
                distinct.append({'bindings': [left, right], 'reason': reason})
            demand(row['simultaneously_live_distinct'] == distinct and row['unresolved_distinction'] == pending,
                   'complete simultaneous-live distinction and explicitly unresolved allocation')
            totals['operations'] += 1; totals['occurrences'] += len(observed)
            totals['distinct_relations'] += len(distinct); totals['unresolved_relations'] += len(pending)
            totals['nested_topology_pending'] += int(not own)
        totals['cases'] += 1
    return totals
