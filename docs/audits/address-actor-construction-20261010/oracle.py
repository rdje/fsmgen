"""Independent whole construction interpreter, graph bijections and source slots."""
import itertools
import re
from pathlib import Path

_entry = {'__name__': 'qualified_entry_oracle'}
exec(compile(Path('docs/audits/address-parser-entry-20261010/oracle.py').read_bytes(),
             'docs/audits/address-parser-entry-20261010/oracle.py', 'exec'), _entry)
Node, graph, bijection, exact, array, record, values = (
    _entry[key] for key in ('Node', 'graph', 'bijection', 'exact', 'array', 'record', 'values'))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def clone(node):
    if not isinstance(node, Node):
        return node
    result = Node(node.kind, '')
    result.edges = {key: clone(value) for key, value in node.edges.items()}
    return result


def canonical_type(ast):
    if ast == 'bit':
        return record({'kind': 'bit', 'width': 1, 'signed': 0})
    parts = values(ast)
    require(parts[0] in ('record', 'list'), 'finite published aggregate type contract')
    if parts[0] == 'list':
        members = [canonical_type(item) for item in parts[1:]]
        return record({'kind': 'list', 'items': array(members), 'signed': 0,
                       'width': sum(item.edges['width'] for item in members)})
    names, members = [], {}
    for member in parts[1:]:
        name, spec = values(member)
        require(type(name) is str and name not in members, 'finite published record member contract')
        names.append(name)
        members[name] = canonical_type(spec)
    return record({'kind': 'record', 'members': record(members), 'member_order': array(names),
                   'signed': 0, 'width': sum(item.edges['width'] for item in members.values())})


def construct(ast):
    head, name, *body = values(ast)
    require(head == 'actor' and name == 'refused', 'whole original finite actor root')
    fields = {key: None for key in ('clock', 'reset', 'clock_domains', 'watchdog',
                                    'verification_bridge', 'actor_network')}
    fields.update({key: array([]) for key in ('transactions', 'rules', 'resources', 'storage', 'constants',
        'crossings', 'priorities', 'phases', 'stages', 'verification_observations', 'params', 'imports',
        'package_imports', 'type_declarations', 'enum_declarations', 'package_roots', 'uses', 'library_uses')})
    fields.update({key: record({}) for key in ('handshakes', 'procs', 'drives')})
    fields.update(actor_name=name, interface=record({'inputs': array([]), 'outputs': array([])}),
                  constant_symbols=record({'packages': record({})}),
                  type_symbols=record({'local': record({}), 'packages': record({})}),
                  enum_symbols=record({'local': record({}), 'packages': record({})}))
    require([values(clause)[0] for clause in body] == ['types', 'interface', 'transaction'],
            'complete reached original actor clause families')
    for clause in body:
        keyword, *items = values(clause)
        if keyword == 'types':
            fields['type_declarations'] = array([clone(item) for item in items])
        elif keyword == 'interface':
            for item in items:
                direction, port_name, *options = values(item)
                port = record({'name': port_name, 'width': 1})
                for option in options:
                    option_name, type_name = values(option)
                    require(option_name == 'type', 'finite authored interface type option')
                    port.edges['type'] = type_name
                target = fields['interface'].edges[direction + 's']
                target.edges[str(len(target.edges))] = port
        else:
            transaction_name, *clauses = items
            transaction = record({'name': transaction_name,
                'ports': record({'inputs': array([]), 'outputs': array([])}), 'clauses': array(clauses)})
            fields['transactions'] = array([transaction])
    return record(fields)


def source_contract(inputs):
    body = inputs['parser_source']
    match = re.search(r'^sub _build_actor\b', body, re.M)
    build = body[match.start():body.index('\n}\n', match.start()) + 3]
    pass_names = ['_expand_' + suffix for suffix in ('cond_loops', 'for_loops', 'let_bindings',
        'procedure_calls', 'bit_tests', 'when_fields', 'compound_assign', 'bit_ops', 'set_fields',
        'rotate', 'swap', 'minmax', 'selects')]
    pass_names += ['_finalize_actor_' + suffix for suffix in ('symbol_tables', 'constant_values',
        'param_values', 'interface_widths', 'storage_depths', 'storage_widths',
        'transaction_port_widths', 'type_references', 'verification_observations', 'verification_bridge')]
    pass_names += ['_validate_deferred_atl_drive_sink_expression_candidates', '_validate_rule_pulse_targets']
    require(exact(inputs['passes'], pass_names) and all('$self->' + name + '($result' in build for name in pass_names)
            and 'validate_actor_record_contexts(actor=>$result,whole_output_writes_only=>1)'
                in build.replace(' ', '').replace('\n', ''),
            'complete original reached construction pass sequence')
    required = ['return [ map { $self->_substitute_proc_body($_, $subst) } @$node ];',
        'type_ast_layout => \'flat\'', 'return $symbols->as_hashref;',
        '$entry->{type_spec} = _clone_isf_value($type_spec);',
        'return _clone_isf_value(($symbols->{local} || {})->{$type_name});']
    require(all(statement in body for statement in required), 'whole original own clone and resolver contracts')
    predicate = ("sub _is_aggregate_type_spec {\n    my ($type_spec) = @_;\n"
        "    return 0 unless ref($type_spec) eq 'HASH';\n    my $kind = $type_spec->{kind} || '';\n"
        "    return ($kind eq 'list' || $kind eq 'record') ? 1 : 0;\n}\n")
    require(predicate in body, 'whole original pure aggregate predicate source bridge')
    required_epochs = ['perl/FSM/Package/' + name + '.pm' for name in (
        'Parser', 'Symbols', 'DeclarativeTypeSupport', 'DeclarativeTypeResolver')]
    require(all(path in inputs['own_source_epochs'] for path in required_epochs),
            'whole original published resolver dependency epochs')
    return pass_names


def qualify(product, inputs):
    passes = source_contract(inputs)
    scope = ('Complete partial actor construction and reached pass checkpoints for both refused sources. '
        'Bindings are original own-source hypotheses; fresh graph probes do not measure original native '
        'identity, payload, flags or stack capture. Local record contexts, complete source/raw integration '
        'and canonical publication remain open.')
    require(set(product) == {'scope', 'preserved_entry', 'profiles', 'modes'} and product['scope'] == scope,
            'actor construction source-only scope')
    require(exact(product['preserved_entry'], inputs['entry_model']), 'whole corrected entry model conservation')
    _entry['qualify'](product['preserved_entry'], inputs['entry_inputs'])
    require(len(product['profiles']) == 2, 'complete actor construction profile population')
    measured = dict(profiles=0, events=0, type_checks=0, final_graph_nodes=0, modes=0, cases=0,
                    inherited_slots=0, qualified_actor_slots=0, pending_context_slots=0,
                    retained_caller_holders=0, distinct_source_relations=0)
    final_nodes = {}
    classes = {'/0': 'FSM::Adapter::ISF', '/0/parser': 'FSM::Adapter::ISF::Parser',
               '/0/parser/adapter': 'FSM::Adapter::ISF::LispishAdapter'}
    for position, profile in enumerate(product['profiles']):
        index = position + 2
        require(set(profile) == {'parse_index', 'source', 'primary', 'events', 'type_checks', 'final'}
                and type(profile['parse_index']) is int and profile['parse_index'] == index
                and profile['source'] == inputs['entry_inputs']['authored'][position],
                'whole actor construction source domain')
        # The prerequisite already qualifies this full normalization graph independently.
        ast = graph(inputs['entry_model']['profiles'][position]['stages']).edges['2']
        adapter = record({'debug': 0})
        parser = record({'debug': 0, 'adapter': adapter})
        facade = record({'debug': 0, 'parser': parser})
        actor = construct(ast)
        tx = actor.edges['transactions'].edges['0']
        events, event_index = profile['events'], 0
        def checkpoint(actual, items):
            require(set(actual) == {'graph', 'classes'}, 'whole own construction checkpoint fields')
            result = bijection(array(items), graph(actual['graph']))
            require(exact(actual['classes'], classes), 'whole own construction receiver class fields')
            return result
        def event(pass_name, boundary, items):
            nonlocal event_index
            require(event_index < len(events), 'complete reached pass entry/return membership')
            actual = events[event_index]
            require(set(actual) == {'pass', 'boundary', 'graph', 'classes'}
                    and actual['pass'] == pass_name and actual['boundary'] == boundary,
                    'complete reached pass entry/return order')
            checkpoint({key: actual[key] for key in ('graph', 'classes')}, items)
            event_index += 1
        for pass_name in passes:
            event(pass_name, 'entry', [facade, ast, actor])
            old_clauses = tx.edges['clauses']
            if pass_name.startswith('_expand_') and pass_name != '_expand_procedure_calls':
                tx.edges['clauses'] = (clone(old_clauses) if pass_name == '_expand_let_bindings'
                                       else array(values(old_clauses)))
            elif pass_name == '_finalize_actor_symbol_tables':
                local = {}
                for declaration in values(actor.edges['type_declarations']):
                    keyword, name, spec = values(declaration)
                    require(keyword == 'type', 'complete authored local type declaration')
                    local[name] = canonical_type(spec)
                actor.edges['type_symbols'] = record({'local': record(local), 'packages': record({})})
                actor.edges['constant_symbols'] = record({'packages': record({})})
                actor.edges['enum_symbols'] = record({'local': record({}), 'packages': record({})})
                actor.edges['package_roots'] = array([])
            elif pass_name == '_finalize_actor_type_references':
                interface = actor.edges['interface']
                ports = values(interface.edges['inputs']) + values(interface.edges['outputs'])
                typed = [port for port in ports if 'type' in port.edges]
                require(len(typed) == len(profile['type_checks']) == 1, 'complete type admission checkpoint population')
                port = typed[0]
                spec = clone(actor.edges['type_symbols'].edges['local'].edges[port.edges['type']])
                checkpoint(profile['type_checks'][0], [facade, ast, actor, spec])
                measured['type_checks'] += 1
                if index == 3:
                    require(spec.edges['kind'] == 'list', 'original rejected list type guard')
                    break
                require(spec.edges['kind'] == 'record', 'original admitted record type guard')
                port.edges['width'] = spec.edges['width']
                port.edges['type_spec'] = clone(spec)
            event(pass_name, 'return', [facade, ast, actor, old_clauses, tx.edges['clauses']])
        require(event_index == len(events), 'complete reached pass entry/return membership')
        point = 'record_context_guard' if index == 2 else 'aggregate_admission_guard'
        final = profile['final']
        require(set(final) == {'point', 'graph', 'classes'} and final['point'] == point,
                'exact source refusal construction stage')
        mapping = checkpoint({key: final[key] for key in ('graph', 'classes')},
                             [facade, ast, actor] + ([spec] if index == 3 else []))
        primary = ("Invalid ISF record context: transaction 'main' set target record output field writes are not yet admitted; target 'value.flag' requires output-field writer qualification"
            if index == 2 else "Error: actor 'refused' interface port 'value' references aggregate type 'lanes'; this ISF slice accepts aggregate type aliases only on actor-owned storage variables and packed record actor ports")
        require(profile['primary'] == primary, 'exact primary refusal boundary')
        final_nodes[index] = {actual.path: (expected.kind, expected) for expected, actual in mapping.items()
                              if actual.path}
        measured['profiles'] += 1
        measured['events'] += len(events)
        measured['final_graph_nodes'] += len(mapping) - 1
    old_modes = product['preserved_entry']['modes']
    require(len(product['modes']) == len(old_modes), 'complete actor source mode population')
    for mode, old_mode in zip(product['modes'], old_modes, strict=True):
        require(set(mode) == {'mode', 'bindings', 'cases'} and mode['mode'] == old_mode['mode'],
                'exact actor source mode allocation')
        expected_bindings = dict(old_mode['bindings'])
        require(len(mode['cases']) == len(old_mode['cases']), 'complete original actor refusal population')
        for case, old in zip(mode['cases'], old_mode['cases'], strict=True):
            index = old['domain'][2]
            require(exact(case['domain'], old['domain']), 'exact original actor record/phase domain')
            profile = product['profiles'][index - 2]
            path_bindings = {}
            for path, (kind, _) in final_nodes[index].items():
                key = {'/0': 'facade', '/0/parser': 'parser', '/0/parser/adapter': 'adapter',
                       '/1': f'parse:{index}:ast'}.get(path, f'parse:{index}:node:{path}')
                path_bindings[path] = key
                if key not in expected_bindings:
                    expected_bindings[key] = {'reference_kind': kind, 'origin': {
                        'kind': 'own_construction_checkpoint_node', 'mode': mode['mode'],
                        'parse_index': index, 'checkpoint': profile['final']['point'], 'node': path,
                        'scope': 'Whole fresh source graph; original native identity and payload unmeasured.'}}
            require(exact(case['final_graph_bindings'], path_bindings), 'complete actor joint graph binding bridge')
            slots, pending = [], []
            for item in old['pending']:
                fi, ai = item['frame'], item['argument']
                function = old['frames'][fi]['function']
                if (function, ai) in {
                    ('FSM::Support::ISFRecordPortContexts::_clauses', 2),
                    ('FSM::Support::ISFRecordPortContexts::validate_actor_record_contexts', 1),
                    ('FSM::Adapter::ISF::Parser::_resolve_typed_width_entry', 1),
                    ('FSM::Adapter::ISF::Parser::_finalize_actor_type_references', 1)}:
                    path = '/2'
                elif function == 'FSM::Support::ISFRecordPortContexts::_clauses' and ai == 0:
                    path = '/2/transactions/0/clauses'
                elif function == 'FSM::Adapter::ISF::Parser::_resolve_typed_width_entry' and ai == 2:
                    path = '/2/interface/inputs/0'
                else:
                    require(item['role'] == 'transaction record context', 'only local record context slots remain')
                    pending.append({**item, 'owner': 'local-record-context-child'})
                    continue
                slots.append({key: item[key] for key in ('frame', 'argument', 'role')}
                             | {'binding': path_bindings[path]})
            require(exact(case['occurrences'], slots), 'every original actor/entry/clause source slot exactly once')
            require(exact(case['pending'], pending), 'complete explicitly pending local context membership')
            require(exact(case['frames'], old['frames'])
                    and exact(case['inherited_occurrences'], old['occurrences']),
                    'complete inherited original parser frames and slots')
            held = sorted(set(old['held']) | set(path_bindings.values()))
            wanted = {'entry_bridge': {key: key for key in old['held']}, 'held': held,
                'retained_callers': old['retained_callers'],
                'simultaneously_held_distinct': [list(pair) for pair in itertools.combinations(held, 2)],
                'returned_passes': passes if index == 2 else passes[:passes.index('_finalize_actor_type_references')],
                'active_own_calls': [row['function'] for row in old['frames']
                    if row['function'].startswith(('FSM::Adapter::ISF', 'FSM::Support::ISFRecordPortContexts'))],
                'returned_construction_delegates': ['_parse_actor_types', '_parse_interface', '_parse_transaction',
                    '_resolve_actor_package_symbols', '_resolve_actor_local_symbols',
                    'FSM::Package::Parser::resolve_pending_package_types', 'FSM::Package::Symbols::as_hashref',
                    '_resolve_actor_type_spec', '_is_aggregate_type_spec']
                    + (['_resolve_typed_width_entry'] if index == 2 else []),
                'type_checkpoint_bridge': {'probe': 'Entry to own _is_aggregate_type_spec before its pure read.',
                    'refusal': profile['final']['point'], 'predicate_has_returned_at_original_refusal': True,
                    'source_bridge': ('Record admission then publishes a second own clone before context refusal.'
                        if index == 2 else 'Pure predicate returns; aggregate rejection precedes width/type_spec writes.')},
                'resolved_type_holder': ('The record admission clone has returned; the output entry holds a '
                    'separate own clone. No original active own holder for that intermediate clone is asserted.'
                    if index == 2 else 'The rejected list admission clone is held by the active '
                    '_resolve_typed_width_entry local $type_spec; width/type_spec publication has not run.'),
                'observer_scope': ('Old clause arrays in return checkpoints are held only by fresh instrumentation. '
                    'They are not added to original source holders; returned delegates do not imply object death.')}
            require(set(case) == set(wanted) | {'domain', 'frames', 'inherited_occurrences', 'occurrences',
                    'pending', 'final_graph_bindings'}, 'whole actor source case fields')
            require(all(exact(case[key], value) for key, value in wanted.items()),
                    'complete actor holders, returned delegates and entry bridge')
            measured['cases'] += 1
            measured['inherited_slots'] += len(old['occurrences'])
            measured['qualified_actor_slots'] += len(slots)
            measured['pending_context_slots'] += len(pending)
            measured['retained_caller_holders'] += len(old['retained_callers'])
            measured['distinct_source_relations'] += len(wanted['simultaneously_held_distinct'])
        require(exact(mode['bindings'], expected_bindings), 'complete actor binding origins/kinds and membership')
        measured['modes'] += 1
    return measured
