package FSM::VIAL::SourceInspection;

use strict;
use warnings;
use JSON::PP ();
use Scalar::Util qw(blessed);
use FSM::Support::VIALSemanticFamilyContract qw(validate_vial_semantic_family_collection);
use FSM::VIAL::LifecycleControl qw(validate_vial_lifecycle_condition);

# Private compiler adapter for the separately versioned public detail schema.
# Descriptors enumerate every accepted field; they never copy arbitrary hashes.
my %META = (semantic_path => 'str', source_span => 'location');
my %NAMED = (%META, semantic_id => 'str', name => 'str');
my %RECORD = (
    source => {source_name => 'str', content_sha256 => 'str', byte_length => 'int', line_ending => 'str'},
    location => {source_name => 'str', map { $_ => 'int' }
        qw(start_byte end_byte_exclusive start_line start_column end_line end_column)},
    import => {%META, alias => 'str', source_name => 'str', package_id => 'str'},
    type_declaration => {%NAMED, declaration_kind => '=alias|enum', type => 'type'},
    enum_member => {%NAMED, value => 'literal_value'},
    record_field => {name => 'str', type => 'type'},
    transaction => {%NAMED, fields => 'typed_name[]', events => 'named[]'},
    named => {%NAMED},
    typed_name => {%NAMED, type => 'type'},
    model => {%NAMED, inputs => 'typed_name[]', state => 'state[]', rules => 'rule[]'},
    state => {%NAMED, type => 'type', initial_value => 'literal_value'},
    rule => {%META, input_id => 'str', assignments => 'assignment[]'},
    assignment => {%META, state_id => 'str', expression => 'expression'},
    scoreboard => {%NAMED, transaction_id => 'str', policy => '=in_order|keyed', key => '?str', capacity => 'int'},
    dut => {%NAMED, unit_bridge_ref => 'str', domains => 'domain[]', endpoints => 'endpoint[]',
        transaction_bindings => 'transaction_binding[]'},
    domain => {%NAMED, bridge_ref => 'str'},
    endpoint => {%NAMED, bridge_ref => 'str', type => 'type', access => '=public_port|verification_probe'},
    transaction_binding => {%NAMED, bridge_ref => 'str', authored_transaction => 'str', transaction_id => 'str'},
    instances => {model_instances => 'model_instance[]', scoreboard_instances => 'scoreboard_instance[]'},
    model_instance => {%NAMED, model_id => 'str', bindings => 'model_binding[]'},
    model_binding => {%META, input_id => 'str', value => 'binding_value'},
    event_binding => {semantic_id => 'str', event_id => 'str'},
    scoreboard_instance => {%NAMED, scoreboard_id => 'str', transaction_id => 'str', actual_id => 'str'},
    coverage => {coverpoints => 'coverpoint[]', crosses => 'cross[]'},
    coverpoint => {%NAMED, domain_id => 'str', expression => 'expression', bins => 'bin[]'},
    bin => {%NAMED, classification => '=normal|illegal|ignore', matcher => 'matcher'},
    cross => {%NAMED, point_ids => 'str[]', max_bins => 'int'},
    randomness => {seed => 'str', choices => 'choice[]'},
    choice => {%NAMED, type => 'type', decision_id => 'str', distribution => 'distribution', constraints => 'expression[]'},
    distribution => {kind => '=uniform', low => 'literal_value', high => 'literal_value'},
    scenario => {%NAMED, domain_id => 'str', timeout_cycles => 'int', actions => 'action[]',
        action_count => 'int', fiber_count => 'int'},
    fiber => {%NAMED, actions => 'action[]'},
    field_value => {%META, field_id => 'str', value => 'expression'},
    intent_scope => {kind => '=fixture', owner_id => 'str'},
    intent_lifetime => {start => '=lifecycle_entered|service_started',
        end => '=result_sealed|service_stopped', cancellation => '=required|cooperative'},
    intent_order => {domain_id => 'str', phase => '=check', rank => 'int', before => 'str[]', after => 'str[]'},
    intent_port => {port_id => 'str', name => '=fixture|domain|result', direction => '=input|output',
        type_id => 'str', cardinality => '=one', required => 'flag'},
    intent_effect => {effect_id => 'str', kind => '=ready|service_start|service_stop|stimulus_start|complete|drain|shutdown|finalize|deadline|failure',
        target_id => 'str', visibility => '=result'},
    intent_failure => {policy => '=fail_scope', scope => '=fixture',
        diagnostic_code => '=VIAL_LIFECYCLE_SERVICE_ERROR|VIAL_LIFECYCLE_DEADLINE_EXPIRED|VIAL_LIFECYCLE_DRAIN_INCOMPLETE|VIAL_LIFECYCLE_CLEANUP_TIMEOUT'},
    intent_result => {kind => '=lifecycle_record', type_id => '=type/vial_lifecycle_record_result_v1', required => 'true_flag'},
    condition_record => {kind => '=all|configured|scenarios_terminal|transactions_terminal|scoreboards_empty|reset_inactive|lifecycle_entered|dependency_satisfied|lifecycle_point|service_started|service_ready|service_quiescent|service_stopped',
        reference_id => '?str', domain_id => '?str', operands => 'condition_record[]'},
    service_detail => {target => '=fixture_background', cancellation => '=cooperative',
        map { $_ => 'condition' } qw(start_condition ready_condition quiescent_condition stop_condition)},
    deadline_detail => {from => 'milestone', until => 'milestone', max_cycles => 'cycles', last_cycle_inclusive => 'true_flag'},
    failure_detail => {disposition => '=fail', cleanup => '=finalize', cleanup_max_cycles => 'cycles', diagnostics => '=first|all'},
    empty_detail => {},
);
my %TYPE = (
    scalar => {kind => '=scalar', family => '=bool|u|s|logic|slogic', width => 'int', signed => 'flag', four_state => 'flag'},
    reference => {kind => '=reference', authored_name => 'str', semantic_id => 'str', resolved => 'type'},
    record => {kind => '=record', fields => 'record_field[]'},
    list => {kind => '=list', length => 'int', element_type => 'type'},
    enum => {kind => '=enum', semantic_id => 'str', base_type => 'type', members => 'enum_member[]'},
    event => {kind => '=event'},
);
my %LITERAL = (
    bool_value => {kind => '=bool_value', value => 'flag'},
    enum_value => {kind => '=enum_value', enum_id => 'str', member_id => 'str'},
    integer_value => {kind => '=integer_value', width => 'int', signed => 'flag', value_decimal => 'str'},
    logic_vector => {kind => '=logic_vector', width => 'int', signed => 'flag',
        value_bits => 'str', known_mask => 'str', z_mask => 'str'},
);
my %ACTION = (
    reset => {domain_id => 'str', cycles => 'int'},
    drive => {endpoint_id => 'str', value => 'expression'},
    start => {handle_id => 'str', transaction_binding_id => 'str', fields => 'field_value[]'},
    await => {property => 'expression'},
    parallel => {join => '=all|any', fibers => 'fiber[]'},
    repeat => {count => 'int', actions => 'action[]'},
    expect => {semantic_id => 'str', name => 'str', property => 'expression'},
    scoreboard_expect => {scoreboard_instance_id => 'str', fields => 'field_value[]'},
    scoreboard_check => {scoreboard_instance_id => 'str'},
    inject => {fault_id => 'str'},
);

sub build {
    my ($class, $ir, @extra) = @_;
    die "SourceInspection requires its exact class and one exact SemanticIR\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__
            && !@extra && ref($ir) eq 'FSM::VIAL::SemanticIR';
    my $data = $ir->as_hashref;
    _hash($data, '/');
    my $version = _value('=1|2', $data->{language_version}, {}, '/language_version');
    my %root_fields = (schema_version => "=$version", language_version => "=$version",
        language => '=vial', profile => "=core_directed_single_clock_v$version",
        root_source => 'source', sources => 'source[]', packages => 'package[]',
        required_capabilities => 'str[]', provenance => 'private_provenance');
    $root_fields{schema} = '=fsmgen.vial_semantic_ir.v2' if $version == 2;
    my $ctx = {version => 0 + $version, unresolved => []};
    my $projected = _record(\%root_fields, $data, $ctx, '');
    delete $projected->{provenance};
    $projected->{schema} = 'fsmgen.vial_source_semantics.v1';
    $projected->{schema_version} = 1;
    $projected->{language_version} = 0 + $version;
    $projected->{unresolved_bridge_refs} = $ctx->{unresolved};
    return $projected;
}

sub _record {
    my ($fields, $data, $ctx, $path) = @_;
    _hash($data, $path);
    for my $key (sort keys %$data) {
        _fail($path, "unknown field '$key'") unless exists $fields->{$key};
    }
    my %out;
    for my $key (sort keys %$fields) {
        _fail($path, "missing field '$key'") unless exists $data->{$key};
        my $public_key = $key eq 'source_span' ? 'source_location' : $key;
        $out{$public_key} = _value($fields->{$key}, $data->{$key}, $ctx, "$path/$public_key");
    }
    return \%out;
}

sub _value {
    my ($type, $data, $ctx, $path) = @_;
    if ($type =~ s/^\?//) {
        return undef unless defined $data;
        return _value($type, $data, $ctx, $path);
    }
    if ($type =~ s/\[\]$//) {
        _fail($path, 'expected plain array') unless ref($data) eq 'ARRAY' && !blessed($data);
        return [map { _value($type, $data->[$_], $ctx, "$path/$_") } 0 .. $#$data];
    }
    if ($type eq 'str' || $type eq 'int' || $type =~ /^=/) {
        _fail($path, 'expected scalar') unless defined($data) && !ref($data);
        if ($type eq 'int') {
            _fail($path, 'expected nonnegative integer') unless $data =~ /\A[0-9]+\z/;
            return 0 + $data;
        }
        if ($type =~ s/^=//) {
            _fail($path, 'unknown discriminant') unless grep { $_ eq $data } split /\|/, $type;
        }
        return "$data";
    }
    if ($type eq 'flag') {
        _fail($path, 'expected Boolean flag') unless JSON::PP::is_bool($data)
            || (defined($data) && !ref($data) && $data =~ /\A[01]\z/);
        return $data ? JSON::PP::true : JSON::PP::false;
    }
    if ($type eq 'true_flag') {
        my $out = _value('flag', $data, $ctx, $path);
        _fail($path, 'expected true flag') unless $out;
        return $out;
    }
    if ($type eq 'cycles') {
        my $out = _value('int', $data, $ctx, $path);
        _fail($path, 'expected bounded positive cycle count') unless $out >= 1 && $out <= 2_147_483_647;
        return $out;
    }
    if ($type eq 'condition' || $type eq 'milestone') {
        # Reuse the bounded condition validator, then explicitly construct the
        # independent public record instead of returning its compiler clone.
        validate_vial_lifecycle_condition($data);
        my $out = _record($RECORD{condition_record}, $data, $ctx, $path);
        _fail($path, 'expected lifecycle milestone')
            if $type eq 'milestone' && !defined($out->{reference_id});
        return $out;
    }
    # Compiler-only provenance is an explicitly consumed input, never output.
    if ($type eq 'private_provenance') { _hash($data, $path); return undef; }
    return _package($data, $ctx, $path) if $type eq 'package';
    return _fixture($data, $ctx, $path) if $type eq 'fixture';
    return _fault($data, $ctx, $path) if $type eq 'fault';
    return _expression($data, $ctx, $path) if $type eq 'expression';
    return _intent_family($data, $ctx, $path) if $type eq 'intent_family';
    return _intent_node($data, $ctx, $path) if $type eq 'intent_node';
    return _lifecycle_payload($data, $ctx, $path) if $type eq 'lifecycle_payload';
    if ($type eq 'binding_value') {
        _hash($data, $path);
        return exists($data->{kind}) ? _expression($data, $ctx, $path)
            : _record($RECORD{event_binding}, $data, $ctx, $path);
    }
    if ($type eq 'type' || $type eq 'literal_value' || $type eq 'action' || $type eq 'matcher') {
        _hash($data, $path);
        my $kind = _value('str', $data->{kind}, $ctx, "$path/kind");
        my $fields;
        $fields = $TYPE{$kind} if $type eq 'type';
        $fields = $LITERAL{$kind} if $type eq 'literal_value';
        $fields = {%META, kind => "=$kind", %{$ACTION{$kind}}}
            if $type eq 'action' && exists $ACTION{$kind};
        $fields = {kind => '=value', value => 'literal_value'} if $type eq 'matcher' && $kind eq 'value';
        $fields = {kind => '=range', low => 'literal_value', high => 'literal_value'} if $type eq 'matcher' && $kind eq 'range';
        _fail($path, "unknown $type kind") unless $fields;
        return _record($fields, $data, $ctx, $path);
    }
    _fail($path, 'unimplemented record type') unless exists $RECORD{$type};
    return _record($RECORD{$type}, $data, $ctx, $path);
}

sub _package {
    my ($data, $ctx, $path) = @_;
    my %fields = (%NAMED, source_name => 'str', imports => 'import[]', types => 'type_declaration[]',
        transactions => 'transaction[]', models => 'model[]', scoreboards => 'scoreboard[]', fixtures => 'fixture[]');
    if ($ctx->{version} == 2) {
        _hash($data, $path);
        # Check common collection bounds, identities and provenance before
        # constructing the closed family-specific public representation.
        validate_vial_semantic_family_collection('semantic_family', $data->{intent_families});
        $fields{intent_families} = 'intent_family[]';
    }
    my $out = _record(\%fields, $data, $ctx, $path);
    # Native collection can follow dependency resolution. Inspection declaration
    # order is authored order, independently recovered from source coordinates.
    for my $section (qw(types transactions models scoreboards)) {
        $out->{$section} = [sort {
            $a->{source_location}{start_byte} <=> $b->{source_location}{start_byte}
        } @{$out->{$section}}];
    }
    $out->{intent_families} = [] unless exists $out->{intent_families};
    return $out;
}

sub _intent_family {
    my ($data, $ctx, $path) = @_;
    my $out = _record({%META, semantic_id => 'str', family_id => '=lifecycle_control',
        revision => '=1', nodes => 'intent_node[]'}, $data, $ctx, $path);
    $out->{revision} = 1;
    return $out;
}

sub _intent_node {
    my ($data, $ctx, $path) = @_;
    my $out = _record({%META, schema => '=fsmgen.vial_semantic_family.v2', schema_version => '=2',
        stage => '=semantic', semantic_id => 'str', family_id => '=lifecycle_control', revision => '=1',
        node_id => 'str', node_kind => '=dependency|readiness|service|stimulus_start|completion|drain|shutdown|finalize|deadline|failure',
        scope => 'intent_scope', lifetime => 'intent_lifetime', order => 'intent_order', ports => 'intent_port[]',
        effects => 'intent_effect[]', failure => 'intent_failure', result => 'intent_result',
        payload => 'lifecycle_payload'}, $data, $ctx, $path);
    my $payload = $out->{payload};
    _fail($path, 'lifecycle payload contradicts its node identity or scope')
        unless $payload->{record_id} eq $out->{semantic_id}
            && $out->{node_id} eq $out->{semantic_id}
            && $payload->{record_kind} eq $out->{node_kind}
            && $payload->{fixture_id} eq $out->{scope}{owner_id}
            && $payload->{domain_id} eq $out->{order}{domain_id};
    delete $out->{stage};
    $out->{schema} = 'fsmgen.vial_intent_node.v1';
    $out->{schema_version} = 1;
    $out->{revision} = 1;
    return $out;
}

sub _lifecycle_payload {
    my ($data, $ctx, $path) = @_;
    _hash($data, $path);
    my $kind = _value('=dependency|readiness|service|stimulus_start|completion|drain|shutdown|finalize|deadline|failure',
        $data->{record_kind}, $ctx, "$path/record_kind");
    my $detail = $kind =~ /\A(?:service|deadline|failure)\z/ ? "${kind}_detail" : 'empty_detail';
    my $no_condition = $kind eq 'deadline' || $kind eq 'failure';
    _fail($path, 'deadline or failure condition must be null')
        if $no_condition && defined($data->{condition});
    my $out = _record({schema => '=fsmgen.vial_lifecycle_control.v1', schema_version => '=1',
        lifecycle_id => 'str', fixture_id => 'str', domain_id => 'str', record_kind => "=$kind", record_id => 'str',
        condition => $no_condition ? '?condition' : 'condition', intrinsic_after => 'str[]', additional_after => 'str[]',
        detail => $detail}, $data, $ctx, $path);
    $out->{schema_version} = 1;
    return $out;
}

sub _fixture {
    my ($data, $ctx, $path) = @_;
    my $fields = {%NAMED, dut => 'dut', instances => 'instances', coverage => 'coverage',
        faults => 'fault[]', randomness => 'randomness', scenarios => 'scenario[]'};
    _hash($data, $path);
    # Construct the DUT first: faults require its independently checked bindings.
    _fail($path, 'missing field dut') unless exists $data->{dut};
    my $dut = _record($RECORD{dut}, $data->{dut}, $ctx, "$path/dut");
    my $local = {%$ctx, transaction_bindings => $dut->{transaction_bindings}};
    my $out = _record($fields, $data, $local, $path);
    my $fixture_id = $out->{semantic_id};
    push @{$ctx->{unresolved}}, {fixture_id => $fixture_id, kind => 'unit', alias => $dut->{name},
        bridge_ref => $dut->{unit_bridge_ref}, expected_type => undef, access => undef};
    for my $group (['domain', 'domains'], ['endpoint', 'endpoints'], ['transaction', 'transaction_bindings']) {
        my ($kind, $key) = @$group;
        for my $item (@{$dut->{$key}}) {
            push @{$ctx->{unresolved}}, {fixture_id => $fixture_id, kind => $kind, alias => $item->{name},
                bridge_ref => $item->{bridge_ref}, expected_type => $kind eq 'endpoint' ? $item->{type}
                    : $kind eq 'transaction' ? $item->{transaction_id} : undef,
                access => $kind eq 'endpoint' ? $item->{access} : undef};
        }
    }
    return $out;
}

sub _fault {
    my ($data, $ctx, $path) = @_;
    _hash($data, $path);
    my %fields = (%NAMED, transaction_id => 'str', field_name => 'str', substitute => 'expression',
        domain_id => 'str', duration_cycles => 'int');
    $fields{transaction_binding_id} = 'str' if exists $data->{transaction_binding_id};
    my $out = _record(\%fields, $data, $ctx, $path);
    my @bindings = grep { $_->{transaction_id} eq $out->{transaction_id} }
        @{$ctx->{transaction_bindings} || []};
    @bindings = grep { $_->{semantic_id} eq $out->{transaction_binding_id} } @bindings
        if exists $out->{transaction_binding_id};
    _fail($path, 'fault target does not resolve to exactly one fixture binding') unless @bindings == 1;
    $out->{transaction_binding_id} = $bindings[0]{semantic_id};
    return $out;
}

sub _expression {
    my ($data, $ctx, $path) = @_;
    _hash($data, $path);
    my $kind = _value('=literal|reference|operator|property', $data->{kind}, $ctx, "$path/kind");
    my %fields = (%META, kind => "=$kind", result_type => 'type');
    if ($kind eq 'literal') { $fields{value} = 'literal_value'; }
    else {
        my $op = _value('str', $data->{op}, $ctx, "$path/op");
        $fields{op} = "=$op";
        if ($kind eq 'reference') {
            _value('=enum_member|symbol|sample|event|event_count|model|choice', $op, $ctx, "$path/op");
            $fields{semantic_id} = 'str';
            $fields{model_instance_id} = 'str' if $op eq 'model';
        }
        else {
            _value($kind eq 'property' ? '==>|next|within' : '=field|not|and|or|xor|same|value_eq|known|+|-|<|<=|>|>=',
                $op, $ctx, "$path/op");
            $fields{operands} = 'expression[]';
            $fields{field_name} = 'str' if $op eq 'field';
            $fields{overflow_policy} = '=error' if $op eq '+' || $op eq '-';
            @fields{qw(min_cycles max_cycles)} = ('int', 'int') if $op eq 'within';
        }
    }
    return _record(\%fields, $data, $ctx, $path);
}

sub _hash {
    _fail($_[1], 'expected plain record') unless ref($_[0]) eq 'HASH' && !blessed($_[0]);
}
sub _fail { die "VIAL source inspection projection at " . ($_[0] || '/') . ": $_[1]\n"; }

1;
