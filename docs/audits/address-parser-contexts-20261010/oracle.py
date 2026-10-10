"""Independent finite context interpreter and fresh boundary qualification."""
import json
import re
from pathlib import Path

ACTOR = Path('docs/audits/address-actor-construction-20261010')
HELPER = Path('docs/audits/address-helper-bindings-20261010')


def module(path):
    namespace = {'__name__': 'qualified_context_dependency'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


_actor = module(ACTOR / 'oracle.py')
_helper = module(HELPER / 'oracle.py')
Node, graph, bijection, exact, array, record, values, clone = (
    _actor[key] for key in ('Node', 'graph', 'bijection', 'exact', 'array', 'record', 'values', 'clone'))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def reachable(roots):
    seen = set()
    def visit(node):
        if not isinstance(node, Node) or node in seen:
            return
        seen.add(node)
        for value in node.edges.values():
            visit(value)
    for root in roots:
        visit(root)
    return seen



def numeric_fields(node):
    """Finite own API numeric properties; AST tokens and all anchor nodes stay typed."""
    if node.kind != 'HASH':
        return set()
    facts = node.edges
    if facts.get('kind') in ('bit', 'bits', 'record'):
        return {'width', 'signed'}
    if facts.get('type') == 'resolved_value' or facts.get('name') == 'done' and set(facts) == {'name', 'width'}:
        return {'width'}
    if set(facts) == {'path', 'width', 'lsb', 'msb', 'signed'}:
        return {'width', 'lsb', 'msb', 'signed'}
    if set(facts) == {'root', 'role', 'path_text', 'type_spec', 'width', 'low', 'high'}:
        return {'width', 'low', 'high'}
    return set()


def semantic_bijection(expected, actual, strict_nodes):
    """Check complete aliases and numeric meanings without guessing provider flags.

    The returned ledger records actual JSON kinds without editing the input graph.
    Exact typed fresh replay is separately required by the verifier.
    """
    forward, backward, ledger = {}, {}, []
    def compare(left, right, parent=None, key=None):
        if not isinstance(left, Node) or not isinstance(right, Node):
            numeric = (isinstance(parent, Node) and parent not in strict_nodes
                       and key in numeric_fields(parent) and type(left) is int)
            if numeric:
                canonical = type(right) is int or (type(right) is str and re.fullmatch(r'0|[1-9][0-9]*', right))
                require(canonical and int(right) == left, 'complete context numeric source meaning')
                ledger.append({'node': forward[parent].path, 'field': key,
                               'json_kind': type(right).__name__, 'observed': right, 'meaning': left})
            else:
                require(type(left) is type(right) and left == right, 'complete context source topology/value/alias')
            return
        if left in forward or right in backward:
            require(forward.get(left) is right and backward.get(right) is left,
                    'complete context source topology/value/alias')
            return
        require(left.kind == right.kind and set(left.edges) == set(right.edges),
                'complete context source topology/value/alias')
        forward[left], backward[right] = right, left
        for child in left.edges:
            compare(left.edges[child], right.edges[child], left, child)
    compare(expected, actual)
    return forward, ledger


class Construction:
    def __init__(self, public, anchor):
        self.public, self.anchor, self.cursor = public, anchor, 0
        self.outputs = {kind: [] for kind in ('context', 'scope', 'samples', 'reference')}
        self.copies, self.protocols, self.arguments = [], [], []
        self.numeric_observations = []
        self.strict_nodes = reachable(anchor)
        self.joint_arguments = True
        self.classes = {'/0': 'FSM::Adapter::ISF', '/0/parser': 'FSM::Adapter::ISF::Parser',
                        '/0/parser/adapter': 'FSM::Adapter::ISF::LispishAdapter'}

    def checkpoint(self, actual, items):
        require(set(actual) == {'graph', 'classes'}, 'whole context checkpoint fields')
        mapping, ledger = semantic_bijection(array(items), graph(actual['graph']), self.strict_nodes)
        self.numeric_observations.append(ledger)
        require(exact(actual['classes'], self.classes), 'complete context receiver classes')
        return mapping

    def step(self, kind, index, boundary, items, module_name=None):
        require(self.cursor < len(self.public['steps']), 'complete context construction step membership')
        actual = self.public['steps'][self.cursor]
        expected = {'kind': kind, 'index': index, 'boundary': boundary}
        if module_name is not None:
            expected['module'] = module_name
        require(set(actual) == set(expected) | {'graph', 'classes'}
                and all(exact(actual[key], value) for key, value in expected.items()),
                'exact context construction step order/domain')
        self.checkpoint({key: actual[key] for key in ('graph', 'classes')}, [*self.anchor, *items])
        self.cursor += 1

    def call(self, kind, arguments, construct):
        index = len(self.outputs[kind])
        self.outputs[kind].append(None)
        args = array(arguments)
        self.arguments.append(record({'kind': kind, 'index': index, 'arguments': args}))
        self.step(kind, index, 'entry', [args])
        result = construct()
        self.outputs[kind][index] = result
        self.step(kind, index, 'return', [args, result])
        self.protocols.append((kind, index, args, result))
        return result

    def copied(self, module_name, node):
        index = len(self.copies)
        result = clone(node) # Finite detached hypothesis, not provider implementation.
        self.copies.append(record({'module': module_name, 'input': node, 'result': result}))
        self.step('private-copy', index, 'entry', [node], module_name)
        self.step('private-copy', index, 'return', [node, result], module_name)
        return result

    def metadata_check(self, spec):
        interface = record({'inputs': array([record({'name': 'value', 'type': 'resolved_value',
            'width': spec.edges['width'], 'type_spec': spec})]), 'outputs': array([])})
        private = self.copied('Metadata', interface)
        port = private.edges['inputs'].edges['0']
        checked = port.edges['type_spec']
        projected = {'name': 'value', 'direction': 'input', 'width': port.edges['width'],
                     'type': 'resolved_value', 'type_kind': checked.edges['kind']}
        if checked.edges['kind'] == 'record':
            require(values(checked.edges['member_order']) == ['flag']
                    and checked.edges['members'].edges['flag'].edges['width'] == 1,
                    'finite original record leaf metadata contract')
            projected['fields'] = array([record({'path': 'flag', 'width': 1, 'lsb': 0, 'msb': 0, 'signed': 0})])
        self.copied('Metadata', array([record(projected)]))

    def value_scope(self, outer, local):
        def build():
            roots = {}
            for layer in (outer, local):
                for name in sorted(layer.edges):
                    private = self.copied('Values', layer.edges[name])
                    spec = private.edges['type_spec']
                    self.metadata_check(spec)
                    roots[name] = record({'role': private.edges['role'], 'type_spec': clone(spec)})
            return record(roots)
        return self.call('scope', ['outer', outer, 'local', local], build)

    def actor_scope(self):
        actor = self.anchor[2]
        roots = {}
        for direction, role in (('inputs', 'input'), ('outputs', 'output')):
            for entry in values(actor.edges['interface'].edges[direction]):
                private = self.copied('Scopes', entry)
                spec = private.edges.get('type_spec')
                if spec is None:
                    require('type' not in private.edges, 'finite untyped scalar scope binding')
                    spec = record({'kind': 'bits', 'width': private.edges['width'], 'signed': 0})
                roots[private.edges['name']] = record({'role': role, 'type_spec': spec})
        return self.value_scope(record(roots), record({}))

    def transaction_scope(self):
        outer = self.actor_scope()
        return self.value_scope(outer, record({}))

    def context(self, transaction=False):
        actor = self.anchor[2]
        args = ['actor', actor]
        if transaction:
            args += ['transaction', actor.edges['transactions'].edges['0']]
        def build():
            outer = self.actor_scope()
            roots = self.transaction_scope() if transaction else outer
            aggregates = {name: self.copied('Scopes', root.edges['type_spec'])
                          for name, root in roots.edges.items() if root.edges['type_spec'].edges['kind'] == 'record'}
            return record({'roots': roots, 'aggregate_roots': record(aggregates),
                'enum_exclusion_roots': record({'value': 1}), 'namespaces': record({}),
                'rule_declared_roots': record({name: 1 for name in outer.edges}),
                'scalar_parameter_roots': record({})})
        return self.call('context', args, build)

    def run(self):
        actor = self.anchor[2]
        tx = actor.edges['transactions'].edges['0']
        actor_context = self.context()
        actor_context.edges['whole_output_writes_only'] = 1
        local_context = self.context(True)
        local_context.edges['whole_output_writes_only'] = 1
        def samples():
            self.context(True)
            require([values(clause)[0] for clause in values(tx.edges['clauses'])] == ['set'],
                    'complete original sample-free transaction')
            return record({'samples': array([]), 'bindings': record({}), 'record_aliases': record({})})
        sample_result = self.call('samples', ['actor', actor, 'transaction', tx, 'port_only', 1], samples)
        local_context.edges['roots'] = self.value_scope(local_context.edges['roots'], sample_result.edges['bindings'])
        def reference():
            private = self.copied('Values', local_context.edges['roots'].edges['value'])
            self.metadata_check(private.edges['type_spec'])
            leaf = private.edges['type_spec'].edges['members'].edges['flag']
            return record({'root': 'value', 'role': 'output', 'path_text': '.flag',
                'type_spec': clone(leaf), 'width': 1, 'low': 0, 'high': 0})
        resolved = self.call('reference', ['scope', local_context.edges['roots'], 'token', 'value.flag',
            'access', 'write', 'allow_whole', 1, 'context', "transaction 'main' set target"], reference)
        args = [array([tx.edges['clauses'], local_context, actor, "transaction 'main'"]),
                array(['value.flag', '1', local_context, "transaction 'main' set"]),
                array(['value.flag', local_context, 'write', "transaction 'main' set target"])]
        require(self.cursor == len(self.public['steps']), 'complete context construction step membership')
        mapping = self.checkpoint(self.public['final'], [*self.anchor,
            array(self.outputs['context']), array(self.outputs['scope']), array(self.outputs['samples']),
            array(self.outputs['reference']), array(self.copies), array(args),
            *([array(self.arguments)] if self.joint_arguments else [])])
        live = reachable([*self.anchor, actor_context, local_context, resolved])
        observer = {node for node, actual in mapping.items() if not actual.path
            or re.fullmatch(r'/(?:3|4|5|6|7|8|9)(?:/\d+)?', actual.path)
                and (actual.path.count('/') == 1 or actual.path.startswith(('/7/', '/8/', '/9/')))}
        observer |= {row.edges['arguments'] for row in self.arguments}
        source_nodes = {actual.path: node for node, actual in mapping.items() if node not in observer}
        require(live <= set(source_nodes.values()), 'complete active source roots exclude probe carriers')
        return mapping, source_nodes, live


def source_contract(inputs):
    units = inputs['own_sources']
    required = {
        'ISFRecordPortContexts.pm': ['my $scope = record_context_scope(actor => $actor);',
            'my $local = record_context_scope(actor => $actor, transaction => $tx);',
            'my $samples = record_transaction_samples(actor => $actor, transaction => $tx, port_only => 1);',
            '$local->{roots} = record_value_scope(outer => $local->{roots}, local => $samples->{bindings});',
            "        }\n        _clauses($tx->{clauses}, $local, $actor, \"transaction '$tx->{name}'\");",
            "my $value = record_value_reference(scope => $roots, token => $token, access => $access,"],
        'ISFRecordPortScopes.pm': ['$entry = dclone($entry);', 'my %aggregates = map {$_ => dclone($roots->{$_}{type_spec})}',
            'return record_value_scope(outer => $outer, local => \\%local);'],
        'ISFRecordPortValues.pm': ['$root = dclone($root);', 'type_spec => FSM::Package::AggregatePathSupport->clone_structured_value($spec),',
            '@result{qw(type_spec width low high)} = @{$resolved}{qw(type_spec width low high)};'],
        'ISFRecordPortSamples.pm': ['my $context = record_context_scope(actor => $args{actor}, transaction => $args{transaction});',
            'return {samples => \\@samples, bindings => \\%bindings, record_aliases => \\%derived};'],
        'ISFInterfacePortMetadata.pm': ['$interface = dclone($interface);', '$value = dclone($value);'],
        'AggregatePathSupport.pm': ['type_spec => $class->clone_structured_value($current_type_spec),']}
    for filename, statements in required.items():
        path = next((p for p in units if p.endswith('/' + filename)), None)
        require(path is not None and all(statement in units[path] for statement in statements),
                'whole original context construction/source-holder contracts')


def qualify(product, inputs):
    source_contract(inputs)
    scope = ('Complete fresh context source construction under own numeric-field semantics, with exact typed public observations retained. '
             'Original scalar flags/native payload/identity, original context-slot/source closure, provider implementation, '
             'global object census, source/raw integration, cold replay and canonical publication remain open.')
    require(set(product) == {'scope', 'preserved_construction', 'public', 'phase'}
            and product['scope'] == scope, 'context boundary source-only scope')
    require(exact(product['preserved_construction'], inputs['construction_model']),
            'whole corrected construction conservation')
    inherited = _actor['qualify'](product['preserved_construction'], inputs['construction_inputs'])
    public = product['public']
    require(set(public) == {'source', 'parse_index', 'primary', 'steps', 'final', 'scope'}
            and type(public['parse_index']) is int and public['parse_index'] == 2
            and public['source'] == inputs['construction_inputs']['entry_inputs']['authored'][0]
            and public['primary'] == inputs['construction_model']['profiles'][0]['primary']
            and public['scope'] == inputs['public']['scope'], 'exact context public source/refusal domain')
    root = graph(inputs['construction_model']['profiles'][0]['final']['graph'])
    runtime = Construction(public, [root.edges[str(i)] for i in range(3)])
    mapping, source_nodes, live = runtime.run()
    phase = {
        'active_roots': ['/0', '/1', '/2', '/3/0', '/3/1', '/6/0'],
        'inactive_contexts': [2], 'inactive_scopes': [1, 2, 3, 4, 5, 6], 'inactive_samples': [0],
        'sample_lifetime': 'The sample lexical block ends before _clauses; the final overlay argument aliases its former bindings, but sample output is not an active original source holder.',
        'observer_carriers': 'Final carrier, result collections, copy rows, active-argument arrays and construction-argument rows/arrays are probe allocations. Their presence does not establish original retention or object death.',
        'numeric_boundary': 'Only declared finite numeric properties outside the conserved facade/AST/actor accept canonical nonnegative integer JSON strings with the same numeric meaning. Exact original and fresh typed observations are never normalized; original native scalar flags remain unmeasured.'}
    require(exact(product['phase'], phase), 'complete context active/source/observer phase contract')
    require(exact(public, inputs['public']), 'complete exact typed context observations')
    return {'construction': inherited, 'steps': runtime.cursor,
            'constructor_arguments': len(runtime.arguments), 'private_copies': len(runtime.copies),
            'source_nodes': len(source_nodes), 'active_source_nodes': len(live),
            'numeric_observations': runtime.numeric_observations}
