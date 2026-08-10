package FSM::VIAL::ArchitectureScaleExecutionGraph;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Adapter::ISF;
use FSM::HIAL::VIALBridge::Builder;
use FSM::Scheduler::ISF;
use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::ExecutionBuilder;
use FSM::VIAL::Parser;

my $FAMILY = 'execution_graph_v1';
my $HIAL_SOURCE = 'generated/vial-scale/execution_graph/vial_architecture_scale.isf';
my $VIAL_SOURCE = 'generated/vial-scale/execution_graph/vial_architecture_scale.vial';
my $EVALUATION_SCHEMA = 'fsmgen.vial_architecture_scale_execution_evaluation.v1';
my $EXECUTION_PROFILE = 'core_directed_single_clock_execution_v1';
my $ARCHITECTURE_SCALE_CAPABILITY =
    'hial_vial.bridge_qualification.architecture_scale_v1';
my @CONSTRUCT_KEYS = qw(level primary_axis);
my @EVALUATE_KEYS = qw(construction);
my @EVALUATION_KEYS = qw(
    ok status schema schema_version workload_identity family level primary_axis
    requested_counts observed_outcome metrics semantic_ir_sha256
    bridge_manifest_sha256 plan_sha256 diagnostics contract_discrepancies
);

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    confess __PACKAGE__ . "->construct expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $raw = $args[0];
    _confess_exact_keys($raw, \@CONSTRUCT_KEYS, 'execution construction');

    my ($axis, $level) = @{$raw}{qw(primary_axis level)};
    confess "execution-graph foundation currently owns only the binding gate\n"
        unless defined($axis) && $axis eq 'bindings'
            && defined($level) && $level eq 'gate_candidate_v1';
    my $axis_contract = FSM::VIAL::ArchitectureScaleWorkload->catalog
        ->{families}{$FAMILY}{axes}{$axis};
    my $requested = $axis_contract->{levels}{$level};
    my $binding_count = $requested->{bindings};
    my $event_count = $binding_count - 6;
    confess "execution binding gate has no valid ordinal-event construction\n"
        unless $event_count > 0;

    return FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        backend_profile => undef,
        tool_profile => undef,
        inputs => [
            _input($HIAL_SOURCE, 'hial_source', _render_hial($event_count)),
            _input($VIAL_SOURCE, 'vial_source', _render_vial($event_count)),
        ],
    });
}

sub build($class, @args) {
    _exact_invocant($class, 'build');
    confess __PACKAGE__ . "->build expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'execution build');
    my $inputs = _canonical_inputs($args[0]{construction});
    return FSM::VIAL::ExecutionBuilder->build_architecture_scale_qualification(
        $inputs->{arguments},
    );
}

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'execution evaluation');
    my $construction = _validated_construction($args[0]{construction});
    my $spec = $construction->{specification};
    my $inputs = _canonical_inputs($construction);
    my $first = FSM::VIAL::ExecutionBuilder->build_architecture_scale_qualification(
        $inputs->{arguments},
    );
    return _rejected_evaluation($construction, $first->{diagnostics})
        unless $first->{ok};

    my @oracle_errors;
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $second = FSM::VIAL::ExecutionBuilder->build_architecture_scale_qualification(
        $inputs->{arguments},
    );
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_DETERMINISM_ERROR',
        'independent qualification binding did not reproduce byte-equal plan output',
        '/plan',
    ) unless $second->{ok}
        && $canonical->encode($second->{plan}) eq $canonical->encode($first->{plan});

    my $ir = $first->{execution_ir}->as_hashref;
    my $plan_json = $canonical->encode($first->{plan});
    my $semantic = $inputs->{semantic_ir}->as_hashref;
    my $manifest = $inputs->{bridge_manifest}->as_hashref;
    my $requested_bindings = $spec->{requested_counts}{bindings};
    my $observed_bindings = $ir->{resource_summary}{bindings};
    my $event_count = scalar(@{$ir->{bindings}{events}});
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_COUNT_ERROR',
        "observed binding count $observed_bindings does not equal requested count $requested_bindings",
        '/metrics/bindings',
    ) unless $observed_bindings == $requested_bindings;
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_EVENT_ERROR',
        'binding gate does not contain the exact ordinal private-event family',
        '/metrics/execution_events',
    ) unless $event_count == $requested_bindings - 6
        && _ordinal_events($ir->{bindings}{events});

    my ($scale_capability) = grep {
        ($_->{capability_id} // '') eq $ARCHITECTURE_SCALE_CAPABILITY
    } @{$first->{plan}{capability_ledger}};
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_CAPABILITY_ERROR',
        'private architecture-scale evidence is not isolated in the capability ledger',
        '/capability_ledger',
    ) unless $scale_capability
        && ($scale_capability->{classification} // '') eq 'qualification_only'
        && ($scale_capability->{portable_class} // '') eq 'private_nonportable'
        && join("\0", @{$scale_capability->{origins} || []}) eq 'bridge_manifest';
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_TARGET_ERROR',
        'target or methodology spelling escaped into the target-neutral plan',
        '/plan',
    ) if $plan_json =~ /(?:systemverilog|\buvm\b|\bvhdl\b|target_name|build_phase|objection)/i;

    return _evaluation({
        ok => @oracle_errors ? JSON::PP::false : JSON::PP::true,
        status => @oracle_errors ? 'oracle_failure' : 'accepted',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $spec->{level},
        primary_axis => $spec->{primary_axis},
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'accepted',
        metrics => {
            bindings => 0 + $observed_bindings,
            execution_events => $event_count,
            execution_types => scalar(@{$ir->{type_table}}),
            selected_scenarios => scalar(@{$ir->{scenarios}}),
            expanded_operations_total => 0 + $ir->{operation_graph}{total_operation_count},
            total_fibers => 0 + $ir->{operation_graph}{total_fiber_count},
            simultaneous_live_fibers =>
                0 + $ir->{operation_graph}{maximum_simultaneous_live_fibers},
            source_map_records => scalar(@{$ir->{source_map}}),
            serialized_plan_bytes => bytes::length($plan_json),
        },
        semantic_ir_sha256 => sha256_hex($canonical->encode($semantic)),
        bridge_manifest_sha256 => sha256_hex($canonical->encode($manifest)),
        plan_sha256 => sha256_hex($plan_json),
        diagnostics => \@oracle_errors,
        contract_discrepancies => [],
    });
}

sub evaluation_keys($class) {
    _exact_invocant($class, 'evaluation_keys');
    return [@EVALUATION_KEYS];
}

sub _canonical_inputs($raw) {
    my $construction = _validated_construction($raw);
    my $hial = _role_input($construction, 'hial_source');
    my $vial = _role_input($construction, 'vial_source');
    my $adapter = FSM::Adapter::ISF->new();
    my $actor = $adapter->parse_source($hial->{content}, basename($hial->{relative_path}));
    my $scheduler = FSM::Scheduler::ISF->new();
    my $schedule_report = JSON::PP->new->decode($scheduler->report($actor));
    my $lowered = $scheduler->lower($actor);
    my $artifact_name = $actor->{actor_name} . '.fsm';
    $artifact_name = $actor->{actor_name} . '_top.fsm'
        unless exists $lowered->{files}{$artifact_name};
    my $ial0_text = $lowered->{files}{$artifact_name};
    confess "ordinary IAL1 lowering did not emit '$artifact_name'\n"
        unless defined $ial0_text;
    my $bridge = FSM::HIAL::VIALBridge::Builder->build_ial1({
        profile => 'core_single_unit_v1',
        authored_source => _source_record($hial->{content}, $hial->{relative_path}),
        actor => $actor,
        schedule_report => $schedule_report,
        generated_ial0 => _source_record($ial0_text, undef, $artifact_name),
        backend_names => _backend_names($actor),
    });
    confess "canonical architecture-scale bridge construction failed\n"
        unless $bridge->{ok};

    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $vial->{content},
        source_name => $vial->{relative_path},
        source_catalog => {},
    });
    my $semantic = $semantic_ir->as_hashref;
    confess "binding gate must contain exactly one package and fixture\n"
        unless @{$semantic->{packages}} == 1
            && @{$semantic->{packages}[0]{fixtures}} == 1;
    my $fixture = $semantic->{packages}[0]{fixtures}[0];
    my @scenario_ids = map { $_->{semantic_id} } @{$fixture->{scenarios}};
    confess "binding gate must contain one scenario\n" unless @scenario_ids == 1;
    return {
        semantic_ir => $semantic_ir,
        bridge_manifest => $bridge->{manifest},
        arguments => {
            semantic_ir => $semantic_ir,
            bridge_manifest => $bridge->{manifest},
            fixture_id => $fixture->{semantic_id},
            scenario_ids => \@scenario_ids,
            execution_profile => $EXECUTION_PROFILE,
            replay_manifest => undef,
            native_extension_catalog => [],
        },
    };
}

sub _validated_construction($raw) {
    confess "construction must be one unblessed hash\n"
        unless ref($raw) eq 'HASH' && !blessed($raw);
    my $spec = $raw->{specification};
    confess "construction must be successful and carry one specification hash\n"
        unless $raw->{ok} && ref($spec) eq 'HASH' && !blessed($spec);
    my $rebuilt = __PACKAGE__->construct({
        primary_axis => $spec->{primary_axis},
        level => $spec->{level},
    });
    my $canonical = JSON::PP->new->canonical(1)->allow_nonref(1);
    confess "construction is not canonical\n"
        unless $rebuilt->{ok}
            && $canonical->encode($rebuilt) eq $canonical->encode($raw);
    return $rebuilt;
}

sub _render_hial($event_count) {
    my @events = map {
        sprintf('(event bridge_event_%08d predicate sample scale_input)', $_)
    } 0 .. $event_count - 1;
    return join('',
        '(actor vial_architecture_scale',
        ' (clock clk)',
        ' (reset (rst_n async active_low))',
        ' (interface (input scale_input) (output scale_output))',
        ' (storage (var probe_00000000 (width 1)))',
        ' (verification-bridge',
        ' (domain scale)',
        ' (protocol architecture_scale_probe',
        ' (profile qualification_only)',
        ' (revision 1)',
        ' (role verification)',
        ' (facts (fact scale_evidence_only true)))',
        ' (transaction bridge_anchor',
        ' (fields (field anchor scale_input drive unspecified))',
        ' (events ', join(' ', @events), '))',
        ' (probe probe_00000000 read_only)))',
        "\n",
    );
}

sub _render_vial($event_count) {
    my @events = map { sprintf('bridge_event_%08d', $_) } 0 .. $event_count - 1;
    return join('',
        '(vial (version 1) (package architecture_scale_execution',
        ' (imports)',
        ' (types (type bit_t (logic 1)))',
        ' (transactions (transaction bridge_anchor',
        ' (fields (anchor (type bit_t)))',
        ' (events ', join(' ', @events), ')))',
        ' (models)',
        ' (scoreboards)',
        ' (fixtures (fixture binding_gate',
        ' (dut dut',
        ' (unit "unit/vial_architecture_scale")',
        ' (domains (domain scale "domain/scale"))',
        ' (endpoints',
        ' (endpoint anchor "endpoint/scale_input" (type bit_t) public_port)',
        ' (endpoint retained "probe/probe_00000000" (type bit_t) verification_probe))',
        ' (transactions (transaction bridge "transaction/bridge_anchor" bridge_anchor)))',
        ' (instances)',
        ' (coverage)',
        ' (faults)',
        ' (randomness (seed 1701))',
        ' (scenarios (scenario smoke',
        ' (timeout (cycles scale 16))',
        ' (steps (reset scale 1))))))))',
        "\n",
    );
}

sub _ordinal_events($events) {
    for my $index (0 .. $#$events) {
        return 0 unless ($events->[$index]{name} // '')
            eq sprintf('bridge_event_%08d', $index);
    }
    return 1;
}

sub _backend_names($actor) {
    my @clock_names = defined($actor->{clock}) ? ($actor->{clock}) : ();
    my @reset_names = ref($actor->{reset}) eq 'HASH' ? ($actor->{reset}{name}) : ();
    my @endpoints = (@clock_names, @reset_names);
    push @endpoints, map { $_->{name} } @{$actor->{interface}{inputs} || []};
    push @endpoints, map { $_->{name} } @{$actor->{interface}{outputs} || []};
    my @probes = map { $_->{name} } @{$actor->{verification_bridge}{probes} || []};
    my %endpoint = map { $_ => $_ } @endpoints;
    my %probe = map { $_ => $_ } @probes;
    return {
        map {
            $_ => {
                unit => $actor->{actor_name},
                endpoints => {%endpoint},
                configurations => {},
                probes => {%probe},
            }
        } qw(systemverilog vhdl)
    };
}

sub _source_record($text, $repository_path, $artifact_name = undef) {
    $artifact_name //= basename($repository_path || 'generated');
    my $lines = length($text)
        ? (() = $text =~ /\n/g) + ($text =~ /\n\z/ ? 0 : 1)
        : 0;
    return {
        text => $text,
        repository_path => $repository_path,
        artifact_name => $artifact_name,
        content_sha256 => sha256_hex($text),
        byte_length => bytes::length($text),
        line_count => $lines,
    };
}

sub _role_input($construction, $role) {
    my @matches = grep { ($_->{role} || '') eq $role } @{$construction->{inputs}};
    confess "construction must contain exactly one $role input\n" unless @matches == 1;
    return $matches[0];
}

sub _input($relative_path, $role, $content) {
    return {
        relative_path => $relative_path,
        role => $role,
        encoding => 'utf-8',
        content => $content,
    };
}

sub _rejected_evaluation($construction, $diagnostics) {
    my $spec = $construction->{specification};
    return _evaluation({
        ok => JSON::PP::false,
        status => 'unexpected_rejection',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $spec->{level},
        primary_axis => $spec->{primary_axis},
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'rejected',
        metrics => {},
        semantic_ir_sha256 => undef,
        bridge_manifest_sha256 => undef,
        plan_sha256 => undef,
        diagnostics => _clone($diagnostics || []),
        contract_discrepancies => [],
    });
}

sub _oracle_error($code, $message, $path) {
    return {code => $code, severity => 'error', message => $message, path => $path};
}

sub _evaluation($value) {
    my %expected = map { $_ => 1 } @EVALUATION_KEYS;
    confess "execution evaluation has unknown key(s)\n"
        if grep { !$expected{$_} } keys %$value;
    confess "execution evaluation is missing key(s)\n"
        if grep { !exists($value->{$_}) } @EVALUATION_KEYS;
    return _clone($value);
}

sub _confess_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    confess "$label has unknown key '$unknown[0]'\n" if @unknown;
    confess "$label is missing key '$missing[0]'\n" if @missing;
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'execution evaluation contains an unsupported reference' if ref($value);
    return $value;
}

1;
