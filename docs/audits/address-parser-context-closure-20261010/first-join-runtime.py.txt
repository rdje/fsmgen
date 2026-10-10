"""Independent finite own API semantics extending the qualified context graph."""
from pathlib import Path

BOUNDARY = Path('docs/audits/address-parser-contexts-20261010')
namespace = {'__name__': 'qualified_context_boundary_dependency'}
exec(compile((BOUNDARY / 'oracle.py').read_bytes(), str(BOUNDARY / 'oracle.py'), 'exec'), namespace)
Node, array, record, values, clone, graph, exact = (
    namespace[key] for key in ('Node', 'array', 'record', 'values', 'clone', 'graph', 'exact'))


def require(condition, message):
    if not condition:
        raise ValueError(message)


class Construction(namespace['Construction']):
    def __init__(self, public, anchor):
        super().__init__(public, anchor)
        self.apis = []

    def api(self, kind, arguments, operation, site, numeric_scalar=False):
        row = {'kind': kind, 'arguments': array(arguments), 'result': None,
               'site': site, 'numeric_scalar': numeric_scalar}
        self.apis.append(row) # Original observer reserves entry indices before nesting.
        row['result'] = operation()
        return row['result']

    def call(self, kind, arguments, construct):
        if kind == 'reference':
            def construct():
                scope = arguments[1]
                private = self.copied('Values', scope.edges['value'])
                self.metadata_check(private.edges['type_spec'])
                resolved = self.packed_range(private.edges['type_spec'], 'Values')
                return record({'root': 'value', 'role': 'output', 'path_text': '.flag',
                    **{key: resolved.edges[key] for key in ('type_spec', 'width', 'low', 'high')}})
        def delegated():
            return super(Construction, self).call(kind, arguments, construct)
        if kind in ('scope', 'reference'):
            site = 'Contexts' if kind == 'reference' or len(self.outputs['scope']) == 7 else 'Scopes'
            return self.api(kind, arguments, delegated, site)
        return delegated()

    def structured(self, value, site, numeric_scalar=False):
        def build():
            if not isinstance(value, Node):
                return value
            result = Node(value.kind, '')
            keys = sorted(value.edges) if value.kind == 'HASH' else [str(i) for i in range(len(value.edges))]
            for key in keys:
                result.edges[key] = self.structured(value.edges[key], 'Aggregate',
                    value.kind == 'HASH' and key in namespace['numeric_fields'](value))
            return result
        return self.api('structured-clone', ['FSM::Package::AggregatePathSupport', value], build,
                        site, numeric_scalar)

    def packed_range(self, spec, site):
        def build():
            require(spec.edges['kind'] == 'record' and values(spec.edges['member_order']) == ['flag']
                    and spec.edges['width'] == 1, 'finite declared packed-path source contract')
            # resolve() first clones its path segments and leaf; packed traversal
            # then returns a separately cloned leaf. The resolve result is inactive.
            self.structured(array([record({'kind': 'member', 'name': 'flag'})]), 'Aggregate')
            leaf = spec.edges['members'].edges['flag']
            self.structured(leaf, 'Aggregate')
            return record({'ok': 1, 'high': 0, 'low': 0, 'width': 1,
                           'type_spec': self.structured(leaf, 'Aggregate')})
        return self.api('range', ['FSM::Package::AggregatePathSupport', 'root_type_spec', spec,
                                  'path_text', '.flag'], build, site)

    def metadata_check(self, spec):
        interface = record({'inputs': array([record({'name': 'value', 'type': 'resolved_value',
            'width': spec.edges['width'], 'type_spec': spec})]), 'outputs': array([])})
        def capture():
            private = self.copied('Metadata', interface)
            port = private.edges['inputs'].edges['0']
            checked = port.edges['type_spec']
            projected = {'name': 'value', 'direction': 'input', 'width': port.edges['width'],
                         'type': 'resolved_value', 'type_kind': checked.edges['kind']}
            if checked.edges['kind'] == 'record':
                resolved = self.packed_range(checked, 'Metadata')
                projected['fields'] = array([record({'path': 'flag', 'width': resolved.edges['width'],
                    'lsb': resolved.edges['low'], 'msb': resolved.edges['high'], 'signed': 0})])
            metadata = array([record(projected)])
            def snapshot():
                copied = self.copied('Metadata', metadata)
                # Own snapshot rebuilds each entry and field, not a provider call.
                return clone(copied)
            return self.api('snapshot', [metadata], snapshot, 'Metadata')
        self.api('capture', [interface], capture, 'Values')

    def value_scope(self, outer, local):
        def build():
            roots = {}
            for layer in (outer, local):
                for name in sorted(layer.edges):
                    private = self.copied('Values', layer.edges[name])
                    spec = private.edges['type_spec']
                    self.metadata_check(spec)
                    roots[name] = record({'role': private.edges['role'],
                                          'type_spec': self.structured(spec, 'Values')})
            return record(roots)
        return self.call('scope', ['outer', outer, 'local', local], build)


def numeric_fields(node):
    result = namespace['numeric_fields'](node)
    if node.kind == 'HASH' and set(node.edges) == {'ok', 'high', 'low', 'width', 'type_spec'}:
        result |= {'high', 'low', 'width'}
    return result


def protocol_bijection(expected, actual, scalar_paths=()):
    """Full finite graphs; scalar clone numeric permissions follow source fields."""
    forward, backward = {}, {}
    def compare(left, right, path='', parent=None, key=None):
        if not isinstance(left, Node) or not isinstance(right, Node):
            numeric = path in scalar_paths or (isinstance(parent, Node) and key in numeric_fields(parent))
            if numeric:
                canonical = type(right) is int or type(right) is str and namespace['re'].fullmatch(r'0|[1-9][0-9]*', right)
                require(type(left) is int and canonical and left == int(right), 'whole original protocol numeric source meaning')
            else:
                require(type(left) is type(right) and left == right, 'whole original protocol source topology/value/alias')
            return
        if left in forward or right in backward:
            require(forward.get(left) is right and backward.get(right) is left,
                    'whole original protocol source topology/value/alias')
            return
        require(left.kind == right.kind and set(left.edges) == set(right.edges),
                'whole original protocol source topology/value/alias')
        forward[left], backward[right] = right, left
        for child in left.edges:
            compare(left.edges[child], right.edges[child], path+'/'+child.replace('~','~0').replace('/','~1'), left, child)
    compare(expected, actual)
    return forward
