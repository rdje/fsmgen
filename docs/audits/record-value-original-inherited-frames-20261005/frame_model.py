"""Source-defined nested API frames, independent of captured stack order."""
VALUE = 'FSM::Support::ISFRecordPortValues::'
METADATA = 'FSM::Support::ISFInterfacePortMetadata::'
CONTRACTS = {
    'capture_lookup': "my $capture = FSM::Support::ISFInterfacePortMetadata->can('capture_interface_port_metadata');",
    'scope_lookup': 'my %value = map {$_ => FSM::Support::ISFRecordPortValues->can($_)}\n        qw(record_value_scope record_value_reference validate_record_port_copy);',
    'scope_wrapper': "local *FSM::Support::ISFRecordPortValues::record_value_scope = sub {\n        return call_api('scope', $value{record_value_scope}, [caller], @_);\n    };",
    'observer_parameters': 'my ($kind, $operation, $caller, @args) = @_;',
    'scope_parameters': 'my %args = @_;',
    'type_parameters': 'my ($spec, $context) = @_;',
}


def reference(role, kind):
    return {'role': role, 'kind': 'reference', 'reference_kind': kind}


def scalar(role, value):
    return {'role': role, 'kind': 'scalar', 'value': value}


def frame(function, site, arguments):
    return {'function': function, 'call_site': site, 'arguments': arguments}


def derive(pair, scope_arguments, argument, inner_error):
    # Source record_value_scope passes the qualified detached root type and
    # root context to _validate_type. It enters the capture eval before the
    # post-catch guard or _closed_type can run. The installed wrapper delegates
    # via call_api's eval, producing this active nested stack at the inner throw.
    scope_args = [argument(value, 'argument_name' if index % 2 == 0 else scope_arguments[index - 1])
                  for index, value in enumerate(scope_arguments)]
    capture_args = [reference('constructed_metadata_interface', 'HASH')]
    scope_observer = [frame('eval {...}', 'observer_scope_operation_eval', []),
                      frame('main::call_api', 'scope_wrapper_delegate', [scalar('api_kind', 'scope'),
                            reference('original_scope_operation', 'CODE'), reference('scope_caller_snapshot', 'ARRAY'), *scope_args]),
                      frame('main::__ANON__', 'installed_scope_wrapper', scope_args)]
    value_path = [frame(VALUE + '_validate_type', 'scope_private_root_type',
                        [reference('detached_private_root_type', 'HASH'), scalar('root_context', pair['context'])]),
                  frame(VALUE + 'record_value_scope', 'original_scope_operation', scope_args)]
    inner = [frame('eval {...}', 'observer_capture_operation_eval', []),
             frame('main::call_api', 'capture_wrapper_delegate', [scalar('api_kind', 'capture'),
                   reference('original_capture_operation', 'CODE'), reference('capture_caller_snapshot', 'ARRAY'), *capture_args]),
             frame('main::__ANON__', 'installed_capture_wrapper', capture_args),
             frame('eval {...}', 'Value_capture_eval', []), *value_path, *scope_observer]
    message = pair['context'] + ' has invalid resolved type: ' + inner_error
    outer = [frame(VALUE + '_require', 'failed_Value_capture_eval_guard',
                   [scalar('failed_eval_result', None), scalar('entire_context_and_inner_error', message)]),
             *value_path, *scope_observer]
    return {'inner_path': inner, 'new_outer_path': outer}
