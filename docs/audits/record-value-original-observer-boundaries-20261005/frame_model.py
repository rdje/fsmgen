"""Own operation/eval/observer/wrapper roles, before native comparison."""

API_WRAPPERS = {
    'capture': ('FSM::Support::ISFInterfacePortMetadata::capture_interface_port_metadata', '$capture'),
    'snapshot': ('FSM::Support::ISFInterfacePortMetadata::snapshot_interface_port_metadata', '$snapshot'),
    'scope': ('FSM::Support::ISFRecordPortValues::record_value_scope', '$value{record_value_scope}'),
    'reference': ('FSM::Support::ISFRecordPortValues::record_value_reference', '$value{record_value_reference}'),
    'copy': ('FSM::Support::ISFRecordPortValues::validate_record_port_copy', '$value{validate_record_port_copy}'),
    'range': ('FSM::Package::AggregatePathSupport::resolve_packed_range', '$range'),
    'structured-clone': ('FSM::Package::AggregatePathSupport::clone_structured_value', '$structured'),
    'identity': ('FSM::Composition::InterfacePortBuilder::declared_type_conflicts', '$conflicts'),
    'payload': ('FSM::Package::PayloadTypeSupport::payload_compatible_with_type_spec', '$payload'),
}
PARSER_WRAPPERS = {
    'source': ('FSM::Adapter::ISF::parse_source', '$parse_source'),
    'file': ('FSM::Adapter::ISF::parse_file', '$parse_file'),
}
LOOKUPS = {
    '$capture': "my $capture = FSM::Support::ISFInterfacePortMetadata->can('capture_interface_port_metadata');",
    '$snapshot': "my $snapshot = FSM::Support::ISFInterfacePortMetadata->can('snapshot_interface_port_metadata');",
    '$range': "my $range = FSM::Package::AggregatePathSupport->can('resolve_packed_range');",
    '$structured': "my $structured = FSM::Package::AggregatePathSupport->can('clone_structured_value');",
    '$conflicts': "my $conflicts = FSM::Composition::InterfacePortBuilder->can('declared_type_conflicts');",
    '$payload': "my $payload = FSM::Package::PayloadTypeSupport->can('payload_compatible_with_type_spec');",
    '$parse_source': "my $parse_source = FSM::Adapter::ISF->can('parse_source');",
    '$parse_file': "my $parse_file = FSM::Adapter::ISF->can('parse_file');",
}
VALUE_LOOKUP = 'my %value = map {$_ => FSM::Support::ISFRecordPortValues->can($_)}\n        qw(record_value_scope record_value_reference validate_record_port_copy);'
PARAMETERS = 'my ($kind, $operation, $caller, @args) = @_;'
API_EVAL = '$ok = eval {$result = $operation->(@args); 1}; $error = $@;'
PARSER_EVAL = 'my $ok = eval {$result = $operation->(@args); 1}; $error = $@;'
PARSER_INPUTS = 'my @inputs = @args[1..$#args];'
PARSER_CONSTRUCTION = 'my $parser = FSM::Adapter::ISF->new;'
FACADE_CONTRACTS = [
    'sub new($class, @constructor_args) {',
    'my $self = bless {\n        parser => $parser,\n        debug  => $debug,\n    }, $class;',
    "unless defined($class) && !ref($class) && $class eq 'FSM::Adapter::ISF';",
    'sub parse_source($self, @args) {',
    'my $result = $self->{parser}->parse_source($source_text, $source_label);',
]


def reference(role, kind):
    return {'role': role, 'kind': 'reference', 'reference_kind': kind}


def scalar(role, value):
    return {'role': role, 'kind': 'scalar', 'value': value}


def frame(function, site, arguments):
    return {'function': function, 'call_site': site, 'arguments': arguments}


def boundary(kind, arguments, parser=False, original_arguments=None):
    wrappers = PARSER_WRAPPERS if parser else API_WRAPPERS
    original, operation = wrappers[kind]
    name = 'parse' if parser else 'call_api'
    original_arguments = arguments if original_arguments is None else original_arguments
    return {'kind': kind, 'operation_lookup': operation,
            'argument_role_bridge': [{'original': original['role'], 'delegated': delegated['role']}
                                     for original, delegated in zip(original_arguments, arguments, strict=True)],
            'frames': [
        frame(original, 'original_' + kind + '_operation', original_arguments),
        frame('eval {...}', 'observer_' + kind + '_operation_eval', []),
        frame('main::' + name, 'installed_' + kind + '_wrapper_delegate', [
            scalar('operation_kind', kind), reference('original_operation', 'CODE'),
            reference('source_caller_snapshot', 'ARRAY'), *arguments]),
        frame('main::__ANON__', 'installed_' + kind + '_wrapper', arguments),
    ]}
