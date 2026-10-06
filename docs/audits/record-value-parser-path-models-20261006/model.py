"""Finite own-source refusal ancestry, selected before any native frame join.

Reference roles identify source expressions, not measured referent contents or
addresses. This is a model of two pinned forms, not a Perl or ISF interpreter.
"""
import re


def forms(text):
    tokens = re.findall(r'\(|\)|[^\s()]+', text)
    if ''.join(tokens) != re.sub(r'\s+', '', text):
        raise ValueError('complete finite authored token input')
    stack, roots = [], []
    for token in tokens:
        if token == '(':
            node = []
            (stack[-1] if stack else roots).append(node)
            stack.append(node)
        elif token == ')':
            if not stack:
                raise ValueError('balanced finite authored form')
            stack.pop()
        elif stack:
            stack[-1].append(token)
        else:
            raise ValueError('finite input has no outer form')
    if stack or len(roots) != 1:
        raise ValueError('one complete finite authored form')
    return roots[0]


def value(role, expression, concrete=None):
    result = {'role': role, 'expression': expression}
    if concrete is not None:
        result['source_value'] = concrete
    return result


def reference(role, expression, kind):
    return dict(value(role, expression), reference_kind=kind,
                referent_contents='not measured', native_identity='not measured')


def derive(inventory, inputs, require, identity):
    functions = {(r['unit'], r['name']): r for r in inventory['functions']}
    require('sub new($class, %args) {\n    return bless {\n' in inventory['source_units']['parser']['body'],
            'whole original contained parser HASH construction contract')

    def function(unit, name):
        row = functions[(unit, name)]
        return {'function': inventory['source_units'][unit]['package'] + '::' + name,
                'whole_source_body': row['identity'], 'parameters': row['parameters']}

    def frame(unit, name, args):
        return dict(function(unit, name), supplied_arguments=args)

    def statement(unit, name, text):
        body = functions[(unit, name)]['body']
        require(body.count(text) == 1, 'unique complete source guard/call statement')
        return {'function': function(unit, name)['function'], 'statement': text,
                'offset_bytes': len(body[:body.index(text)].encode())}

    require(len(inputs) == 2 and all(type(s) is str for s in inputs),
            'complete finite refusal source input kinds')
    recipes = []
    for index, text in enumerate(inputs):
        actor = forms(text)
        require(actor[0:2] == ['actor', 'refused'], 'finite authored actor identity')
        require([node[0] for node in actor[2:]] == ['types', 'interface', 'transaction'],
                'complete finite actor clause domain/order')
        declarations, interface, tx = actor[2:]
        require(declarations == ['types', ['type', 'frame', ['record', ['flag', 'bit']]],
                                 ['type', 'lanes', ['list', 'bit', 'bit']]],
                'complete independently selected finite type declarations')
        direction, type_name = ('output', 'frame') if index == 0 else ('input', 'lanes')
        require(interface == ['interface', [direction, 'value', ['type', type_name]], ['output', 'done']],
                'complete finite actor port declaration')
        require(tx == (['transaction', 'main', ['set', 'value.flag', '1']] if index == 0
                       else ['transaction', 'main', ['complete', 'done']]),
                'complete finite transaction source')
        parser = reference('contained parser receiver', '$self', 'HASH')
        partial = reference('partially built actor', '$result / $actor', 'HASH')
        label = value('source label', '$source_label', 'still-refused.isf')
        ancestry = [
            frame('facade', 'parse_source', [reference('facade receiver', '$self', 'HASH'),
                                            value('source text', '$source_text', text), label]),
            frame('parser', 'parse_source', [parser, value('source text', '$source_text', text), label]),
            frame('parser', '_build_actor', [parser, reference('normalized actor AST', '$actor_ast', 'ARRAY'), label]),
        ]
        # These are source facts needed by the guard, not a reconstruction of
        # the complete partially built actor or normalized AST in memory.
        facts = {'actor_name': 'refused', 'port_name': 'value', 'direction': direction,
                 'type_name': type_name, 'type_kind': 'record' if index == 0 else 'list',
                 'aggregate': 1, 'allow_record': 1, 'allow_aggregate': 0}
        denied = bool(facts['aggregate'] and not facts['allow_aggregate']
                      and not (facts['allow_record'] and facts['type_kind'] == 'record'))
        type_guard = statement('parser', '_resolve_typed_width_entry',
            'if $is_aggregate && !$options{allow_aggregate}\n'
            "            && !($options{allow_record} && $kind eq 'record');")
        guards = [dict(type_guard, source_facts=facts, refuses=int(denied))]
        build = functions[('parser', '_build_actor')]['body']
        require(build.index('$self->_finalize_actor_type_references($result);') <
                build.index('validate_actor_record_contexts(actor => $result, whole_output_writes_only => 1)'),
                'source type admission precedes record context validation')
        completed = []
        if denied:
            ancestry += [
                frame('parser', '_finalize_actor_type_references', [parser, partial]),
                frame('parser', '_resolve_typed_width_entry', [parser, partial,
                    reference('interface port entry', '$port', 'HASH'),
                    value('admission context', "$context", "actor 'refused' interface port 'value'"),
                    value('option key', 'allow_record', 'allow_record'),
                    value('option value', '1', 1)]),
            ]
            primary = ("Error: actor 'refused' interface port 'value' references aggregate type 'lanes'; "
                       'this ISF slice accepts aggregate type aliases only on actor-owned storage variables '
                       'and packed record actor ports')
            not_reached = ['validate_actor_record_contexts', 'transaction clause validation',
                           'actor publication']
        else:
            local = reference('transaction record context', '$local / $scope', 'HASH')
            context = "transaction 'main'"
            write_facts = {'whole_output_writes_only': 1, 'access': 'write', 'value_exists': 1,
                           'value_role': 'output', 'path_text': 'flag', 'root_kind': 'record',
                           'port_root_returns': 1}
            blocked = bool(write_facts['whole_output_writes_only'] and write_facts['access'] == 'write'
                           and write_facts['value_exists'] and write_facts['value_role'] == 'output'
                           and write_facts['path_text'] and write_facts['port_root_returns'])
            message = (context + " set target record output field writes are not yet admitted; "
                       "target 'value.flag' requires output-field writer qualification")
            ancestry += [
                frame('contexts', 'validate_actor_record_contexts', [value('option key', 'actor', 'actor'),
                    partial, value('option key', 'whole_output_writes_only', 'whole_output_writes_only'),
                    value('option value', '1', 1)]),
                frame('contexts', '_clauses', [reference('transaction clauses', '$tx->{clauses}', 'ARRAY'),
                    local, partial, value('transaction context', context, context)]),
                frame('contexts', '_assignment', [value('write target', '$clause->[1]', 'value.flag'),
                    value('source operand', '$clause->[2]', '1'), local,
                    value('assignment context', '$context set', context + ' set')]),
                frame('contexts', '_reference', [value('target token', '$target', 'value.flag'), local,
                    value('access', "'write'", 'write'),
                    value('reference context', '$context target', context + ' set target')]),
                frame('contexts', '_require', [value('guard predicate', '!output_field_write', int(not blocked)),
                    value('guard message', '$message', message)]),
            ]
            write_guard = statement('contexts', '_reference',
                '_require(!($scope->{whole_output_writes_only} && $access eq \'write\' && $value\n'
                "            && $value->{role} eq 'output' && length($value->{path_text})\n"
                '            && _port_root($roots->{$name})),')
            guards.append(dict(write_guard, source_facts=write_facts, refuses=int(blocked)))
            completed = ['_finalize_actor_type_references', '_resolve_typed_width_entry',
                         'record_value_reference', '_port_root']
            primary = 'Invalid ISF record context: ' + message
            not_reached = ['assignment RHS reference', 'validate_record_port_copy', 'actor publication']
        recipes.append({'parse_index': index + 2, 'source': text, 'whole_source': identity(text.encode()),
                        'source_form_projection': actor, 'active_own_ancestry_outer_to_inner': ancestry,
                        'guards': guards, 'completed_delegates_not_active_ancestors': completed,
                        'not_reached_after_refusal': not_reached, 'primary': primary})
    return recipes
