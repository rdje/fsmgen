"""Independent complete graph traversal, own normalization and source-role checks."""
import itertools
import json
from pathlib import Path

_graphs = {'__name__': 'qualified_graph_primitives'}
exec(compile(Path('docs/audits/address-nested-lifetimes-20261010/oracle.py').read_bytes(),
             'docs/audits/address-nested-lifetimes-20261010/oracle.py', 'exec'), _graphs)
Node, graph, bijection, exact = (_graphs[key] for key in ('Node', 'graph', 'bijection', 'exact'))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def array(items):
    node = Node('ARRAY', '')
    node.edges = {str(i): value for i, value in enumerate(items)}
    return node


def record(fields):
    node = Node('HASH', '')
    node.edges = fields
    return node


def values(node):
    require(isinstance(node, Node) and node.kind == 'ARRAY'
            and set(node.edges) == {str(i) for i in range(len(node.edges))}, 'complete normalization array members')
    return [node.edges[str(i)] for i in range(len(node.edges))]


def normalize(form, preserve=False):
    items = values(form)
    if not items:
        return array([])
    head = items[0]
    preserve = preserve or (type(head) is str and head == 'reset')
    if len(items) == 1:
        return array([]) if preserve and head is None else head
    if isinstance(items[1], Node) and items[1].kind == 'ARRAY':
        tail = values(items[1])
        first = tail[0] if tail else None
        first = normalize(first, preserve) if isinstance(first, Node) else first
        rest = [normalize(item, preserve) if isinstance(item, Node) else item for item in tail[1:]]
        return array([head, first, *rest])
    return array([normalize(item, preserve) if isinstance(item, Node) else item for item in items])


def plain(node):
    return [plain(item) for item in values(node)] if isinstance(node, Node) else node


def source_contract(inputs):
    units = inputs['inventory']['source_units']
    original = json.loads(Path('docs/audits/address-helper-bindings-20261010/inputs.json').read_bytes())['source']
    contracts = {
        'facade': ["my $parser = FSM::Adapter::ISF::Parser->new(debug => $debug);",
                   'parser => $parser,', 'debug  => $debug,', 'my $debug = $args{debug} // 0;',
                   'my $result = $self->{parser}->parse_source($source_text, $source_label);'],
        'parser': ['debug   => ($args{debug} // 0),',
                   'adapter => FSM::Adapter::ISF::LispishAdapter->new(debug => ($args{debug} // 0)),',
                   'my $raw = Lispish::multi(\\$source_text);',
                   'my $forms = $self->{adapter}->normalize_multi($raw);',
                   "my @actor_roots = _forms_by_head($forms, 'actor');", 'my $actor_ast = $actor_roots[0];',
                   'my $result = $self->_build_actor($actor_ast, $source_label);']}
    for unit, statements in contracts.items():
        require(all(statement in units[unit]['body'] for statement in statements), 'whole original constructor/forwarding source contract')
    require('return bless { debug => ($args{debug} // 0) }, $class;' in inputs['normalizer'],
            'original contained normalizer constructor')
    require(original['test'].count('my $parser = FSM::Adapter::ISF->new;') == 1,
            'one original mode lexical receiver factory')
    observer = original['observer']
    lookup = "my $parse_source = FSM::Adapter::ISF->can('parse_source');"
    wrapper = 'local *FSM::Adapter::ISF::parse_source = sub {'
    require(lookup in observer and wrapper in observer and observer.index(lookup) < observer.index(wrapper)
            and "return parse('source', $parse_source, [caller], @_);" in observer
            and 'my ($kind, $operation, $caller, @args) = @_;' in observer
            and 'my @inputs = @args[1..$#args];' in observer
            and 'push @parses, {kind => $kind, caller => $caller, helper => $active_helper,' in observer
            and 'my $ok = eval {$result = $operation->(@args); 1};' in observer,
            'original saved delegate, excluded receiver, retained caller and complete forwarding')


def qualify(product, inputs):
    source_contract(inputs)
    scope = ('Complete parser-entry receiver/delegate/caller source bindings and fresh public normalization '
             'checkpoints for both refused inputs in every original mode. Original heap identity, payload/flags, '
             'provider implementation, later AST contents, partial actor/context graphs, complete source/raw '
             'integration and canonical publication remain open.')
    require(set(product) == {'scope', 'factory', 'classes', 'profiles', 'modes'} and product['scope'] == scope,
            'parser entry source-only checkpoint scope')
    adapter = record({'debug': 0})
    parser = record({'adapter': adapter, 'debug': 0})
    facade = record({'parser': parser, 'debug': 0})
    mapping = bijection(array([facade, parser, adapter]), graph(product['factory']))
    require(exact(product['classes'], {'/0': 'FSM::Adapter::ISF', '/0/parser': 'FSM::Adapter::ISF::Parser',
                    '/0/parser/adapter': 'FSM::Adapter::ISF::LispishAdapter'}), 'complete own constructor class map')
    require(len(product['profiles']) == len(inputs['authored']) == 2, 'complete normalization profile population')
    measured = dict(modes=0, cases=0, checkpoint_nodes=0, qualified_slots=0, pending_slots=0,
                    operation_bindings=0, retained_caller_holders=0, distinct_source_relations=0)
    for position, (profile, public, source_path) in enumerate(zip(product['profiles'], inputs['public']['cases'], inputs['paths'], strict=True)):
        raw = graph(public['stages']).edges['0']
        normalized = array([normalize(node) for node in values(raw) if isinstance(node, Node) and node.kind == 'ARRAY'])
        roots = [node for node in values(normalized) if isinstance(node, Node) and node.kind == 'ARRAY'
                 and node.edges and node.edges['0'] == 'actor']
        require(len(roots) == 1, 'complete original actor root selector boundary')
        stage_mapping = bijection(array([raw, normalized, roots[0]]), graph(profile['stages']))
        require(exact(plain(roots[0]), source_path['source_form_projection']),
                'authored projection independently reconciles normalized actor contents')
        require(exact({k: profile[k] for k in profile if k != 'stages'}, {
            'parse_index': position + 2, 'source': inputs['authored'][position],
            'authored_projection': source_path['source_form_projection'],
            'checkpoint': 'After normalize_multi and actor-root selection, before _build_actor.'}),
            'whole normalization checkpoint source allocation')
        measured['checkpoint_nodes'] += len(stage_mapping) - 1
    source_modes = list(dict.fromkeys(row['mode'] for row in inputs['operation_inputs']))
    require(len(product['modes']) == len(source_modes), 'complete parser entry mode population')
    for mode_name, mode in zip(source_modes, product['modes'], strict=True):
        require(set(mode) == {'mode', 'bindings', 'cases'} and mode['mode'] == mode_name, 'whole parser entry mode allocation')
        expected_bindings = {}
        for name, node, cls in (('facade', facade, 'FSM::Adapter::ISF'), ('parser', parser, 'FSM::Adapter::ISF::Parser'),
                                ('adapter', adapter, 'FSM::Adapter::ISF::LispishAdapter')):
            expected_bindings[name] = {'reference_kind': cls + '=HASH', 'origin': {
                'kind': 'own_source_constructor', 'mode': mode_name, 'node': mapping[node].path, 'class': cls}}
        expected_bindings['saved-parse-source'] = {'reference_kind': 'CODE', 'origin': {
            'kind': 'saved_lookup', 'mode': mode_name, 'expression': "$parse_source = FSM::Adapter::ISF->can('parse_source')"}}
        operations = [row for row in inputs['operation_hypotheses'] if row['mode'] == mode_name]
        require(len(mode['cases']) == len(operations), 'complete parser entry refusal population')
        aliases, inverse = {}, {}
        for case, old in zip(mode['cases'], operations, strict=True):
            index = old['index']
            prefix = 'parse:' + str(index) + ':'
            operation = old['operations'][0]
            require(exact(case['domain'], [mode_name, 'parses', index, 0, 0]), 'exact original parser record/phase domain')
            expected_bindings[prefix + 'caller'] = {'reference_kind': 'ARRAY', 'origin': {
                'kind': 'observer_caller_snapshot', 'mode': mode_name, 'parse_index': index,
                'expression': '[caller]', 'holder': '@parses'}}
            for name, path in (('raw', '/0'), ('forms', '/1'), ('ast', '/1/0')):
                expected_bindings[prefix + name] = {'reference_kind': 'ARRAY', 'origin': {
                    'kind': 'normalization_checkpoint_node', 'mode': mode_name, 'parse_index': index, 'node': path,
                    'authority': 'Fresh public boundary plus original own normalizer source; original native payload unmeasured.'}}
            core = next(row for row in inputs['arguments'] if row['parse_index'] == index)['frames']
            frames = core + operation['frames'][1:]
            require(exact(case['frames'], frames), 'complete original parser core/boundary frame membership')
            slots, pending = {}, []
            for fi, frame in enumerate(frames):
                for ai, arg in enumerate(frame['arguments']):
                    if 'reference_kind' not in arg:
                        continue
                    function, role = frame['function'], arg['role']
                    if fi < len(core):
                        if function == 'FSM::Adapter::ISF::parse_source' and ai == 0:
                            key = 'facade'
                        elif function.startswith('FSM::Adapter::ISF::Parser::') and ai == 0:
                            key = 'parser'
                        elif function.endswith('::_build_actor') and ai == 1:
                            key = prefix + 'ast'
                        else:
                            pending.append({'frame': fi, 'argument': ai, 'role': role,
                                            'reference_kind': arg['reference_kind'], 'owner': 'partial-actor-context-child'})
                            continue
                    elif function == 'main::parse':
                        key = {1: 'saved-parse-source', 2: prefix + 'caller', 3: 'facade'}[ai]
                    else:
                        require(function == 'main::__ANON__' and ai == 0, 'declared original parser boundary reference expression')
                        key = 'facade'
                    slots[fi, ai] = key, role
            require(exact(case['pending'], pending), 'complete explicitly pending actor/context reference membership')
            actual_slots = {(row['frame'], row['argument']): row for row in case['occurrences']}
            require(len(actual_slots) == len(case['occurrences']) and set(actual_slots) == set(slots)
                    and all(set(row) == {'frame', 'argument', 'role', 'binding'} and type(row['frame']) is int
                            and type(row['argument']) is int for row in case['occurrences']),
                    'every qualified parser entry source slot exactly once')
            for slot, (key, role) in slots.items():
                row = actual_slots[slot]
                require(row['role'] == role and row['binding'] in mode['bindings']
                        and exact(mode['bindings'][row['binding']], expected_bindings[key]), 'parser entry source binding origin/kind')
                require(aliases.get(key, row['binding']) == row['binding'] and inverse.get(row['binding'], key) == key,
                        'parser entry source alias equivalence across calls')
                aliases[key], inverse[row['binding']] = row['binding'], key
            held = sorted(set(['facade', 'parser', 'adapter', 'saved-parse-source']
                              + [prefix + k for k in ('caller', 'raw', 'forms', 'ast')])
                          | {'parse:' + str(i) + ':caller' for i in (2, 3) if i <= index})
            bridge = {key: ('saved-parse-source' if old_binding['origin']['kind'] == 'saved_lookup' else
                           prefix + 'caller' if old_binding['origin']['kind'] == 'fresh_caller_array' else 'facade')
                      for key, old_binding in operation['bindings'].items()}
            wanted = {'held': held, 'retained_callers': ['parse:' + str(i) + ':caller' for i in (2, 3) if i <= index],
                      'inactive_delegates': ['Lispish::multi', 'normalize_multi', 'normalize_form', '_forms_by_head'],
                      'active_own_parser_ancestors': ['FSM::Adapter::ISF::parse_source',
                          'FSM::Adapter::ISF::Parser::parse_source', 'FSM::Adapter::ISF::Parser::_build_actor'],
                      'operation_bridge': {'domain': operation['domain'], 'bindings': bridge,
                          'preserved_operation': operation,
                          'overlap': 'Original facade call is the final core frame; appended operation frames start at eval.'},
                      'simultaneously_held_distinct': [list(pair) for pair in itertools.combinations(held, 2)],
                      'lifetime': ('One lexical facade constructor per original mode holds its contained parser and adapter. '
                          'Saved parse_source lookup remains held by the observer; @parses retains each fresh caller ARRAY. '
                          'Raw/forms/root graphs describe the normalization checkpoint; their source roots remain held '
                          'by the active parse call, without asserting unchanged later payload or scalar flags.')}
            require(set(case) == set(wanted) | {'domain', 'frames', 'occurrences', 'pending'}, 'whole parser entry case fields')
            require(all(exact(case[key], value) for key, value in wanted.items()), 'complete parser entry source holders/activation/operation bridge')
            measured['cases'] += 1
            measured['qualified_slots'] += len(slots)
            measured['pending_slots'] += len(pending)
            measured['operation_bindings'] += len(bridge)
            measured['retained_caller_holders'] += len(wanted['retained_callers'])
            measured['distinct_source_relations'] += len(wanted['simultaneously_held_distinct'])
        require(exact(mode['bindings'], expected_bindings), 'complete parser entry source binding membership')
        measured['modes'] += 1
    return measured
