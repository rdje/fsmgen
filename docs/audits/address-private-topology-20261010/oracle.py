"""Independent graph bijections and joint reachability; no producer imports."""


def require(condition, message):
    if not condition:
        raise ValueError(message)


class Node:
    def __init__(self, kind):
        self.kind = kind
        self.edges = {}


def graph(encoded):
    seen = {}
    def read(value, path):
        if type(value) in (str, int, type(None)):
            return None
        require(type(value) is list and len(value) == 2, 'whole private typed graph grammar')
        tag, body = value
        if tag == 'reference':
            require(type(body) is str and body in seen, 'private typed alias target')
            return seen[body]
        require(tag in ('hash', 'array') and type(body) is (dict if tag == 'hash' else list),
                'private typed container kind')
        node = Node(tag.upper())
        seen[path] = node
        for key, child in (body.items() if tag == 'hash' else enumerate(body)):
            segment = str(key).replace('~', '~0').replace('/', '~1')
            node.edges[str(key)] = read(child, path + '/' + segment)
        return node
    root = read(encoded, '')
    require(root is not None, 'whole private root container')
    return root


def reachable(root):
    pending, found = [root], set()
    while pending:
        item = pending.pop()
        if item is None or item in found:
            continue
        found.add(item)
        pending.extend(item.edges.values())
    return found


def pool(record):
    require(set(record) == {'root', 'nodes'} and type(record['nodes']) is dict,
            'whole source-private pool fields')
    objects = {}
    for name, item in record['nodes'].items():
        require(type(name) is str and set(item) == {'kind', 'edges'} and item['kind'] in ('HASH', 'ARRAY')
                and type(item['edges']) is dict, 'source-private pool container grammar')
        objects[name] = Node(item['kind'])
    require(record['root'] in objects, 'source-private pool root')
    for name, item in record['nodes'].items():
        for key, edge in item['edges'].items():
            require(type(key) is str and type(edge) is dict, 'source-private pool edge grammar')
            if set(edge) == {'node'}:
                require(edge['node'] in objects, 'source-private pool reference target')
                target = objects[edge['node']]
            else:
                require(set(edge) == {'scalar'} and edge['scalar'] is True, 'source-private pool scalar marker')
                target = None
            objects[name].edges[key] = target
    root = objects[record['root']]
    require(reachable(root) == set(objects.values()), 'whole source-private pool reachability')
    return root, objects


def matches(source, target):
    pending, forward, reverse = [(source, target)], {}, {}
    while pending:
        left, right = pending.pop()
        if left is None or right is None:
            require(left is right, 'private scalar versus reference edge')
            continue
        if left in forward:
            require(forward[left] is right, 'private alias equivalence')
            continue
        require(right not in reverse, 'private alias equivalence')
        forward[left], reverse[right] = right, left
        require(left.kind == right.kind, 'private reference kind')
        require(set(left.edges) == set(right.edges), 'complete private edge membership')
        pending.extend((left.edges[key], right.edges[key]) for key in sorted(left.edges))
    require(set(forward) == reachable(source) and set(reverse) == reachable(target),
            'whole private graph bijection')
    return forward


def qualify(product, inputs):
    require(set(product) == {'copies', 'scope'}, 'whole private hypothesis fields')
    require(product['scope'] == 'Complete qualified source-private copy topology and per-copy input/result '
            'detachment hypotheses; scalar flags/values retain their separate qualified graphs. Numerical '
            'addresses, cross-copy identity, post-return liveness, native/provider/formatter identity and '
            'remaining core/helper/parser/nested role joins remain open.', 'private source-only open scopes')
    require(len(product['copies']) == len(inputs), 'complete private copy membership')
    measured = {'copies': 0, 'input_nodes': 0, 'result_nodes': 0, 'shared_input_result_nodes': 0}
    for source, row in zip(inputs, product['copies'], strict=True):
        require(set(row) == {'domain', 'kind', 'api', 'input_pool', 'result_pool', 'binding_namespace',
                             'bijection', 'simultaneously_live', 'post_return'}, 'complete private copy fields')
        require(type(row['domain']) is list and len(row['domain']) == 2
                and type(row['domain'][0]) is str and type(row['domain'][1]) is int
                and row['domain'] == source['domain'], 'exact per-copy per-capture source domain')
        require(type(row['api']) is int and row['api'] == source['api'] and row['kind'] == source['kind'],
                'exact source-private kind and owning API')
        require(row['binding_namespace'] == {'input': ['input', *source['domain']],
                                             'result': ['result', *source['domain']]},
                'distinct source-private input/result binding domains')
        require(row['simultaneously_live'] == 'input and returned copy inside copy_value before return',
                'source-private simultaneous active-copy lifetime')
        require(row['post_return'] == 'unqualified; caller/throw-phase source roles must establish later liveness',
                'no inferred source-private post-return liveness')
        original = graph(source['before'])
        after = graph(source['after'])
        returned = graph(source['result'])
        input_root, inputs_by_name = pool(row['input_pool'])
        result_root, results_by_name = pool(row['result_pool'])
        matches(original, input_root)
        matches(after, input_root)
        correspondence = matches(input_root, result_root)
        matches(returned, result_root)
        reverse_names = {node: name for name, node in results_by_name.items()}
        require(row['bijection'] == {name: reverse_names[correspondence[node]] for name, node in inputs_by_name.items()},
                'complete declared private node correspondence')
        actual = source['actual_graphs']
        require(set(actual) == {'before', 'after', 'copy'}, 'complete actual qualified private graph sides')
        for key, predicted in [('before', input_root), ('after', input_root), ('copy', result_root)]:
            matches(predicted, graph(actual[key]))
        joint = graph(source['qualified_original_joint'])
        require(joint.kind == 'HASH' and set(joint.edges) == {'input', 'result'}, 'whole original private joint graph')
        matches(input_root, joint.edges['input'])
        matches(result_root, joint.edges['result'])
        a, b = reachable(joint.edges['input']), reachable(joint.edges['result'])
        require(not a & b, 'whole original private input/result detachment')
        require(reachable(joint) == {joint} | a | b, 'complete private joint node allocation')
        measured['copies'] += 1
        measured['input_nodes'] += len(a)
        measured['result_nodes'] += len(b)
        measured['shared_input_result_nodes'] += len(a & b)
    return measured
