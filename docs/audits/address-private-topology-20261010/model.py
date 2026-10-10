"""Per-copy source pools retain topology, never numeric or post-return identity."""


def topology(graph):
    nodes = {}
    def visit(value, path):
        if type(value) in (str, int, type(None)):
            return {'scalar': True}
        if type(value) is not list or len(value) != 2:
            raise ValueError('whole qualified private graph grammar')
        kind, body = value
        if kind == 'reference':
            if type(body) is not str or body not in nodes:
                raise ValueError('private alias targets a previously allocated node')
            return {'node': body}
        if kind not in ('hash', 'array') or type(body) is not (dict if kind == 'hash' else list):
            raise ValueError('private source container kind')
        node = {'kind': kind.upper(), 'edges': {}}
        nodes[path] = node
        for key, child in (body.items() if kind == 'hash' else enumerate(body)):
            segment = str(key).replace('~', '~0').replace('/', '~1')
            node['edges'][str(key)] = visit(child, path + '/' + segment)
        return {'node': path}
    root = visit(graph, '')
    if root != {'node': ''}:
        raise ValueError('whole qualified private root is a container')
    return {'root': '', 'nodes': nodes}


def clone(pool):
    """Independent finite clone hypothesis, including back/repeated edges; no provider reconstruction."""
    result, memo = {}, {}
    def copy_node(name):
        if name in memo:
            return memo[name]
        copied_name = name
        memo[name] = copied_name
        source = pool['nodes'][name]
        target = {'kind': source['kind'], 'edges': {}}
        result[copied_name] = target
        for key, edge in source['edges'].items():
            target['edges'][key] = {'node': copy_node(edge['node'])} if 'node' in edge else {'scalar': True}
        return copied_name
    return {'root': copy_node(pool['root']), 'nodes': result}


def derive(inputs):
    rows = []
    for row in inputs:
        pool = topology(row['before'])
        expected = clone(pool)
        if topology(row['after']) != pool or topology(row['result']) != expected:
            raise ValueError('complete private source/result topology conservation: ' + str(row['domain']))
        rows.append({'domain': row['domain'], 'kind': row['kind'], 'api': row['api'],
                     'input_pool': pool, 'result_pool': expected,
                     'binding_namespace': {'input': ['input', *row['domain']], 'result': ['result', *row['domain']]},
                     'bijection': {name: name for name in sorted(pool['nodes'])},
                     'simultaneously_live': 'input and returned copy inside copy_value before return',
                     'post_return': 'unqualified; caller/throw-phase source roles must establish later liveness'})
    return {'copies': rows, 'scope': 'Complete qualified source-private copy topology and per-copy input/result '
            'detachment hypotheses; scalar flags/values retain their separate qualified graphs. Numerical '
            'addresses, cross-copy identity, post-return liveness, native/provider/formatter identity and '
            'remaining core/helper/parser/nested role joins remain open.'}
