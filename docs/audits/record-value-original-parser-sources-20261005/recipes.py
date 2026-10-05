"""Independently selected finite own source boundaries; no native trace input."""

UNITS = {
    'facade': ('perl/FSM/Adapter/ISF.pm', 'FSM::Adapter::ISF'),
    'parser': ('perl/FSM/Adapter/ISF/Parser.pm', 'FSM::Adapter::ISF::Parser'),
    'contexts': ('perl/FSM/Support/ISFRecordPortContexts.pm', 'FSM::Support::ISFRecordPortContexts'),
}

# These selections come from the complete original own call/guard source. A
# declaration inventory is lexical provenance, not an inferred active stack.
FUNCTIONS = {
    'facade': {
        'new': ('$class, @constructor_args', 'construct the contained parser and facade'),
        'parse_source': ('$self, @args', 'validate and forward source text and label'),
    },
    'parser': {
        'parse_source': ('$self, $source_text, $source_label', 'published source entry and actor build'),
        '_build_actor': ('$self, $actor_ast, $source_label', 'build and validate the source actor'),
        '_finalize_actor_type_references': ('$self, $actor', 'supply interface type-admission options'),
        '_resolve_typed_width_entry': ('$self, $actor, $entry, $context, %options', 'aggregate type admission guard'),
    },
    'contexts': {
        'validate_actor_record_contexts': ('%args', 'supply whole-output policy and local contexts'),
        '_clauses': ('$clauses, $scope, $actor, $context', 'dispatch authored transaction clauses'),
        '_assignment': ('$target, $source, $scope, $context', 'resolve write target before read source'),
        '_reference': ('$token, $scope, $access, $context', 'resolve reference and apply output-field guard'),
        '_port_root': ('$root', 'classify an input or output record port'),
        '_require': (None, 'guard arity and emit the literal record-context refusal'),
    },
}

# Exact statements are inventoried in source order. They do not claim that
# every inventoried branch executed, nor that a returned call is an active frame.
STATEMENTS = {
    ('facade', 'new'): [
        'my $parser = FSM::Adapter::ISF::Parser->new(debug => $debug);',
        'my $self = bless {\n        parser => $parser,\n        debug  => $debug,\n    }, $class;',
    ],
    ('facade', 'parse_source'): [
        "_validate_object_receiver($self, 'parse_source');",
        "my ($source_text, $source_label) = _validate_scalar_args('parse_source', 2, @args);",
        'my $result = $self->{parser}->parse_source($source_text, $source_label);',
    ],
    ('parser', 'parse_source'): [
        'my $raw = Lispish::multi(\\$source_text);',
        'my $forms = $self->{adapter}->normalize_multi($raw);',
        "my @actor_roots = _forms_by_head($forms, 'actor');",
        'my $actor_ast = $actor_roots[0];',
        'my $result = $self->_build_actor($actor_ast, $source_label);',
    ],
    ('parser', '_build_actor'): [
        'my ($actor_head, $actor_name, @body) = @$actor_ast;',
        '$self->_finalize_actor_type_references($result);',
        'validate_actor_record_contexts(actor => $result, whole_output_writes_only => 1)\n        if actor_has_record_port(actor => $result);',
    ],
    ('parser', '_finalize_actor_type_references'): [
        "my $actor_name = $actor->{actor_name} // 'unknown';",
        'for my $direction (qw(inputs outputs)) {',
        'for my $port (@{$actor->{interface}{$direction} || []}) {',
        '$self->_resolve_typed_width_entry(\n                $actor,\n                $port,\n                "actor \'$actor_name\' interface port \'$port->{name}\'",\n                allow_record => 1,\n            );',
    ],
    ('parser', '_resolve_typed_width_entry'): [
        'return 1 unless exists $entry->{type};',
        'my $type_name = $entry->{type};',
        'my $type_spec = $self->_resolve_actor_type_spec($actor, $type_name);',
        "my $kind = $type_spec->{kind} || '';",
        'my $is_aggregate = _is_aggregate_type_spec($type_spec);',
        'confess "Error: $context references aggregate type \'$type_name\'; this ISF slice accepts aggregate type aliases only on actor-owned storage variables and packed record actor ports\\n"\n        if $is_aggregate && !$options{allow_aggregate}\n            && !($options{allow_record} && $kind eq \'record\');',
    ],
    ('contexts', 'validate_actor_record_contexts'): [
        "my $whole_only = exists($args{whole_output_writes_only}) ? $args{whole_output_writes_only} : 0;",
        'my $actor = $args{actor};',
        'my $scope = record_context_scope(actor => $actor);',
        '$scope->{whole_output_writes_only} = $whole_only;',
        'for my $tx (@{$actor->{transactions} || []}) {',
        'my $local = record_context_scope(actor => $actor, transaction => $tx);',
        '$local->{whole_output_writes_only} = $whole_only;',
        'my $samples = record_transaction_samples(actor => $actor, transaction => $tx, port_only => 1);',
        '$local->{roots} = record_value_scope(outer => $local->{roots}, local => $samples->{bindings});',
        '_clauses($tx->{clauses}, $local, $actor, "transaction \'$tx->{name}\'");',
    ],
    ('contexts', '_clauses'): [
        "if ($head eq 'set' || $head eq 'update') {",
        '_assignment($clause->[1], $clause->[2], $scope, "$context $head");',
    ],
    ('contexts', '_assignment'): [
        'my $to = _reference($target, $scope, \'write\', "$context target");',
        'my $from = _reference($source, $scope, \'read\', "$context RHS");',
        'return 1 if validate_record_port_copy(source => $from, target => $to, context => $context);',
    ],
    ('contexts', '_reference'): [
        'my ($name, $suffix) = ($1, $2);',
        'my $roots = $scope->{roots};',
        'my $kind = record_reference_root_kind(context => $scope, token => $token);',
        "return undef unless defined($kind) && $kind eq 'declaration';",
        'my $value = record_value_reference(scope => $roots, token => $token, access => $access,\n        allow_whole => 1, context => $context);',
        '_require(!($scope->{whole_output_writes_only} && $access eq \'write\' && $value\n            && $value->{role} eq \'output\' && length($value->{path_text})\n            && _port_root($roots->{$name})),\n        "$context record output field writes are not yet admitted; "\n            . "target \'$token\' requires output-field writer qualification");',
    ],
    ('contexts', '_port_root'): [
        "return (ref($root) eq 'HASH' && ($root->{role} eq 'input' || $root->{role} eq 'output')\n        && ref($root->{type_spec}) eq 'HASH' && $root->{type_spec}{kind} eq 'record') ? 1 : 0;",
    ],
    ('contexts', '_require'): [
        'confess "Invalid ISF record context: validation requires a predicate and message\\n" unless @_ == 2;',
        'confess "Invalid ISF record context: $_[1]\\n" unless $_[0];',
    ],
}
