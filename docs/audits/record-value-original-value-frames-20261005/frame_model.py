"""Source-input model of direct Value call paths, independent of trace text.

The previously qualified cause model supplies predicate semantics. Instrument
its function calls and failed predicates, rather than reconstructing a path
from a native stack. Explicit mappings below join those model events to own
Perl statements. Metadata failures are outside this direct-path slice.
"""
import ast
import functools

PACKAGE = 'FSM::Support::ISFRecordPortValues::'
ENTRY = {'scope': 'record_value_scope', 'reference': 'record_value_reference',
         'copy': 'validate_record_port_copy'}
FUNCTIONS = {'keys': '_keys', 'closed_type': '_closed_type',
             'value_type': '_validate_type', 'reference_value': '_validate_reference'}
PARAMETERS = {'keys': ('value', 'required_keys', 'optional_keys', 'context'),
              'closed_type': ('resolved_type', 'context'),
              'value_type': ('resolved_type', 'context'),
              'reference_value': ('reference_value', 'context')}
# These statements are independently selected from the own Value contract.
# The keys identify lexical failed-predicate sites in the qualified model.
GUARDS = {
    'keys.2': '_require(!grep(!exists($value->{$_}), @$required), "$context lacks required facts");',
    'keys.3': '_require(!grep(!$allowed{$_}, keys %$value), "$context has unknown facts");',
    'closed_type.2': '_require($spec->{signed} == 0, "$context aggregate has a scalar signed overlay");',
    'reference_value.2': '_require(_positive($value->{width}) && $value->{width} == $value->{type_spec}{width},\n        "$context value width disagrees with resolved type");',
    'values.4': '_require(_role($root->{role}), "root \'$name\' has invalid role");',
    'values.8': '_require(_binary($allow_whole), "$context has invalid whole-value permission");',
    'values.10': '_require($access ne \'write\' || $root->{role} ne \'input\',\n        "$context cannot write declared input \'$token\'");',
    'values.11': '_require($allow_whole || !_aggregate($spec),\n            "$context requires a scalar value; \'$token\' is a whole $spec->{kind}");',
    'values.12': '_require($resolved->{ok}, "$context has invalid declared path \'$token\': "\n        . ($resolved->{code} // \'unresolved\'));',
    'values.13': '_require(!_aggregate($resolved->{type_spec}),\n        "$context requires a scalar leaf; \'$token\' resolves to $resolved->{type_spec}{kind}");',
    'values.15': '_require(_whole_record($source) && _whole_record($target),\n        "$context whole record port copy requires declared record roots");',
    'values.16': '_require($target->{role} ne \'input\',\n        "$context cannot write declared input \'$target->{root}\'");',
    'values.17': '_require(!FSM::Composition::InterfacePortBuilder->declared_type_conflicts(\n        $source->{type_spec}, $target->{type_spec}),\n        "$context record port copy from \'$source->{root}\' to \'$target->{root}\' requires the same resolved record type");',
}
CALLS = {
    'scope_keys': "_keys(\\%args, [qw(outer local)], [], 'scope');",
    'scope_type': '_validate_type($spec, "root \'$name\'") if defined $spec;',
    'reference_keys': "_keys(\\%args, [qw(scope token access context)], ['allow_whole'], 'reference');",
    'reference_type': '_validate_type($root->{type_spec}, "$context root \'$name\'");',
    'copy_keys': "_keys(\\%args, [qw(source target context)], [], 'copy');",
    'copy_reference': '_validate_reference($_, $context) for grep { defined $_ } ($source, $target);',
    'reference_value_keys': '_keys($value, [qw(root role path_text type_spec width)], [qw(low high)], "$context value");',
    'reference_value_type': '_validate_type($value->{type_spec}, $context);',
    'type_closed': '_closed_type($spec, $context);',
    'closed_keys': '_keys($spec, [qw(kind width signed), @extra],\n        _aggregate($spec) ? [] : [\'state_model\'], "$context resolved type");',
    'closed_recursion': '_closed_type($_, $context) for @children;',
}
GUARD_CALLERS = {
    'keys.2': '_keys', 'keys.3': '_keys', 'closed_type.2': '_closed_type',
    'reference_value.2': '_validate_reference', 'values.4': 'record_value_scope',
    **{key: 'record_value_reference' for key in ('values.8', 'values.10', 'values.11', 'values.12', 'values.13')},
    **{key: 'validate_record_port_copy' for key in ('values.15', 'values.16', 'values.17')},
}
CALL_CALLERS = {
    **{key: 'record_value_scope' for key in ('scope_keys', 'scope_type')},
    **{key: 'record_value_reference' for key in ('reference_keys', 'reference_type')},
    **{key: 'validate_record_port_copy' for key in ('copy_keys', 'copy_reference')},
    **{key: '_validate_reference' for key in ('reference_value_keys', 'reference_value_type')},
    'type_closed': '_validate_type', 'closed_keys': '_closed_type', 'closed_recursion': '_closed_type',
}


def argument(value, role):
    if type(value) in (dict, list):
        return {'role': role, 'kind': 'reference', 'reference_kind': 'HASH' if type(value) is dict else 'ARRAY'}
    if value is None or type(value) in (int, str):
        return {'role': role, 'kind': 'scalar', 'value': value}
    raise ValueError('unsupported finite model argument kind')


def call_site(parent, child):
    if parent in ENTRY:
        if child == 'keys':
            return parent + '_keys'
        return {'scope': 'scope_type', 'reference': 'reference_type', 'copy': 'copy_reference'}[parent]
    return {('reference_value', 'keys'): 'reference_value_keys',
            ('reference_value', 'value_type'): 'reference_value_type',
            ('value_type', 'closed_type'): 'type_closed',
            ('closed_type', 'keys'): 'closed_keys',
            ('closed_type', 'closed_type'): 'closed_recursion'}[(parent, child)]


def derive(cause_source, kind, arguments):
    tree = ast.parse(cause_source)
    # Add a stable lexical site to each predicate call. This transformation
    # only reports events; it does not replace the qualified predicates.
    for function in tree.body:
        if not isinstance(function, ast.FunctionDef):
            continue
        calls = sorted((node for node in ast.walk(function)
                        if isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
                        and node.func.id == 'must'), key=lambda node: (node.lineno, node.col_offset))
        for index, node in enumerate(calls, 1):
            node.keywords.append(ast.keyword(arg='site', value=ast.Constant(function.name + '.' + str(index))))
    namespace = {'__name__': 'direct_value_source_model'}
    exec(compile(ast.fix_missing_locations(tree), '<qualified-cause-model>', 'exec'), namespace)
    stack, failures = [], []

    def predicate(condition, message, site):
        if condition:
            return
        if site not in GUARDS:
            raise ValueError('failure outside direct Value guard domain: ' + site)
        frames = [{'function': PACKAGE + '_require', 'call_site': site,
                   'arguments': [{'role': 'failed_predicate', 'kind': 'false_predicate'},
                                 argument(message, 'diagnostic_message')]}]
        for index in range(len(stack) - 1, -1, -1):
            frame = stack[index]
            frames.append({'function': PACKAGE + frame['function'],
                           'call_site': 'observer_operation' if index == 0 else call_site(stack[index - 1]['model'], frame['model']),
                           'arguments': frame['arguments']})
        failures.append({'guard': site, 'primary': 'Invalid ISF record value: ' + message, 'frames': frames})
        raise namespace['Primary'](message)

    namespace['must'] = predicate

    def wrap(name, operation):
        @functools.wraps(operation)
        def run(*values):
            if name == 'values':
                model_kind, named = values
                modeled = [argument(value, ('name' if index % 2 == 0 else str(named[index - 1])))
                           for index, value in enumerate(named)]
                frame = {'model': model_kind, 'function': ENTRY[model_kind], 'arguments': modeled}
            else:
                frame = {'model': name, 'function': FUNCTIONS[name],
                         'arguments': [argument(value, role) for value, role in zip(values, PARAMETERS[name], strict=True)]}
            stack.append(frame)
            try:
                return operation(*values)
            finally:
                stack.pop()
        return run

    for name in ('values', *FUNCTIONS):
        namespace[name] = wrap(name, namespace[name])
    primary = namespace['primary'](kind, arguments)
    if len(failures) != 1 or failures[0]['primary'] != primary:
        raise ValueError('direct Value source failure event population')
    return failures[0]
