package FSM::VIAL::ExecutionBuilder;

use v5.20;
use strict;
use warnings;
use bytes ();
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Math::BigInt;
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::HIAL::VIALBridge::Manifest;
use FSM::Support::VIALExecutionContract qw(build_vial_execution_contract);
use FSM::VIAL::ExecutionIR;
use FSM::VIAL::ExecutionRandom;
use FSM::VIAL::ExecutionReport;
use FSM::VIAL::SemanticIR;

my $SCHEMA = 'fsmgen.vial_execution_ir.v1';
my $PROFILE = 'core_directed_single_clock_execution_v1';
my $RANDOM_ALGORITHM = 'sha256_counter_rejection_v1';
my $ARCHITECTURE_SCALE_CAPABILITY =
    'hial_vial.bridge_qualification.architecture_scale_v1';
my %LIMIT = %{build_vial_execution_contract()->{limits}};

my @EXECUTION_CAPABILITIES = qw(
    vial.execution_ir.v1
    vial.execution_profile.core_directed_single_clock_execution_v1
    vial.binding.directional_representation.v1
    vial.logical_time.drive_sample_react_check_v1
    vial.random.sha256_counter_rejection_v1
    vial.replay.v1
    vial.plan.v1
);

my %ACTION_PHASE = (
    reset => 'drive',
    drive => 'drive',
    start => 'drive',
    await => 'check',
    parallel => 'react',
    repeat => 'react',
    expect => 'check',
    scoreboard_expect => 'react',
    scoreboard_check => 'check',
    inject => 'react',
);

my %ACTION_EFFECT = (
    reset => 'reset_interval',
    drive => 'update_driver',
    start => 'start_transaction',
    await => 'evaluate_property',
    parallel => 'activate_fibers',
    repeat => 'enter_repeat',
    expect => 'record_expectation',
    scoreboard_expect => 'enqueue_expected',
    scoreboard_check => 'check_scoreboard',
    inject => 'arm_fault',
);

sub build($class, @args) {
    return _failure_result(
        code => 'VIAL_EXECUTION_INVOCATION_ERROR',
        phase => 'invocation',
        message => 'build must be called with the FSM::VIAL::ExecutionBuilder class invocant',
        semantic_path => '/',
    ) unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure_result(
        code => 'VIAL_EXECUTION_INVOCATION_ERROR',
        phase => 'invocation',
        message => 'build expects exactly one closed argument hash',
        semantic_path => '/',
    ) unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);

    my $result = eval { _build($args[0]) };
    return $result if $result;
    my $error = $@;
    return _failure_result(%$error)
        if blessed($error) && $error->isa('FSM::VIAL::ExecutionBuilder::Failure');
    return _failure_result(
        code => 'VIAL_EXECUTION_INTERNAL_ERROR',
        phase => 'internal',
        message => 'internal VIAL execution construction failure',
        semantic_path => '/',
    );
}

sub build_architecture_scale_qualification($class, @args) {
    my $caller = caller;
    return _failure_result(
        code => 'VIAL_EXECUTION_INVOCATION_ERROR',
        phase => 'invocation',
        message => 'architecture-scale qualification binding is private to FSM::VIAL::ArchitectureScaleExecutionGraph',
        semantic_path => '/',
    ) unless defined($class) && !ref($class) && $class eq __PACKAGE__
        && defined($caller)
        && $caller eq 'FSM::VIAL::ArchitectureScaleExecutionGraph';
    return _failure_result(
        code => 'VIAL_EXECUTION_INVOCATION_ERROR',
        phase => 'invocation',
        message => 'architecture-scale qualification binding expects exactly one closed argument hash',
        semantic_path => '/',
    ) unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);

    my $result = eval { _build($args[0], 1) };
    return $result if $result;
    my $error = $@;
    return _failure_result(%$error)
        if blessed($error) && $error->isa('FSM::VIAL::ExecutionBuilder::Failure');
    return _failure_result(
        code => 'VIAL_EXECUTION_INTERNAL_ERROR',
        phase => 'internal',
        message => 'internal VIAL execution construction failure',
        semantic_path => '/',
    );
}

sub _build($raw, $architecture_scale_qualification = 0) {
    my %allowed = map { $_ => 1 } qw(
        semantic_ir bridge_manifest fixture_id scenario_ids execution_profile
        replay_manifest native_extension_catalog
    );
    my @unknown = sort grep { !$allowed{$_} } keys %$raw;
    _throw('VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        'unknown build key(s): ' . join(', ', @unknown), '/') if @unknown;
    for my $required (qw(
        semantic_ir bridge_manifest fixture_id scenario_ids execution_profile
        replay_manifest native_extension_catalog
    )) {
        _throw('VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
            "missing build key '$required'", '/') unless exists $raw->{$required};
    }
    _throw('VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        'semantic_ir must be an exact FSM::VIAL::SemanticIR object', '/semantic_ir')
        unless blessed($raw->{semantic_ir})
            && ref($raw->{semantic_ir}) eq 'FSM::VIAL::SemanticIR';
    _throw('VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        'bridge_manifest must be an exact FSM::HIAL::VIALBridge::Manifest object', '/bridge_manifest')
        unless blessed($raw->{bridge_manifest})
            && ref($raw->{bridge_manifest}) eq 'FSM::HIAL::VIALBridge::Manifest';
    _throw('VIAL_CAPABILITY_ERROR', 'capability',
        "execution profile must be $PROFILE", '/execution_profile')
        unless defined($raw->{execution_profile}) && !ref($raw->{execution_profile})
            && $raw->{execution_profile} eq $PROFILE;
    _throw('VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        'fixture_id must be a non-empty semantic ID', '/fixture_id')
        unless defined($raw->{fixture_id}) && !ref($raw->{fixture_id})
            && length($raw->{fixture_id});
    _throw('VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        'scenario_ids must be a non-empty array', '/scenario_ids')
        unless ref($raw->{scenario_ids}) eq 'ARRAY' && @{$raw->{scenario_ids}};
    _limit('selected_scenarios', scalar(@{$raw->{scenario_ids}}), '/scenario_ids');
    _throw('VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        'native_extension_catalog must be an array', '/native_extension_catalog')
        unless ref($raw->{native_extension_catalog}) eq 'ARRAY';
    _limit('native_extensions', scalar(@{$raw->{native_extension_catalog}}), '/native_extension_catalog');
    _throw('VIAL_NATIVE_EXTENSION_ERROR', 'native_extension',
        'the first execution profile requires an empty native extension catalog',
        '/native_extension_catalog') if @{$raw->{native_extension_catalog}};
    _throw('VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        'replay_manifest must be null or an unblessed hash', '/replay_manifest')
        if defined($raw->{replay_manifest})
            && (ref($raw->{replay_manifest}) ne 'HASH' || blessed($raw->{replay_manifest}));

    my $semantic = $raw->{semantic_ir}->as_hashref;
    my $bridge = $raw->{bridge_manifest}->as_hashref;
    _validate_input_profiles($semantic, $bridge, $architecture_scale_qualification);

    my ($package, $fixture) = _find_fixture($semantic, $raw->{fixture_id});
    my @selected_scenarios = _select_scenarios($fixture, $raw->{scenario_ids});
    my $semantic_ir_id = 'semantic/' . sha256_hex(_canonical_json($semantic));
    my $semantic_identity = {
        semantic_ir_id => $semantic_ir_id,
        schema_version => 0 + $semantic->{schema_version},
        profile => $semantic->{profile},
        root_source_name => $semantic->{root_source}{source_name},
        root_content_sha256 => $semantic->{root_source}{content_sha256},
        selected_fixture_id => $fixture->{semantic_id},
    };
    my $bridge_identity = {
        manifest_id => $bridge->{manifest_id},
        schema => $bridge->{schema},
        schema_version => 0 + $bridge->{schema_version},
        profile => $bridge->{profile},
        entry_source_id => $bridge->{entry_source_id},
        review_artifact_ids => [map { $_->{artifact_id} } @{$bridge->{review_artifacts}}],
    };

    my $ctx = {
        semantic => $semantic,
        bridge => $bridge,
        package => $package,
        fixture => $fixture,
        scenarios => \@selected_scenarios,
        type_by_shape => {},
        type_entries => [],
        source_map => [],
        endpoint_binding_by_semantic_id => {},
        bridge_endpoint_binding_id => {},
        bridge_probe_binding_id => {},
        event_binding_by_semantic_id => {},
        event_binding_by_transaction_and_name => {},
        transaction_binding_by_semantic_id => {},
        semantic_transaction_events_by_binding_semantic_id => {},
        operation_by_scenario => {},
    };
    _index_bridge($ctx);
    my $bindings = _bind_fixture($ctx);
    _index_scenario_handle_bindings($ctx);
    my ($operation_graph, $scenario_records) = _build_operations($ctx);
    my $randomness = _build_randomness(
        $ctx, $raw->{replay_manifest}, $semantic_identity, $bridge_identity,
    );
    _resolve_decision_references($operation_graph, $randomness);
    _attach_decisions_to_scenarios($scenario_records, $randomness->{decisions});

    my ($models, $scalar_state_cells) = _build_models($ctx);
    my ($scoreboards, $scoreboard_capacity) = _build_scoreboards($ctx);
    my $coverage = _normalize_node($ctx, $fixture->{coverage});
    my $faults = _normalize_node($ctx, $fixture->{faults});
    my $coverage_materialization = _coverage_materialization_count($fixture->{coverage});
    _limit('model_instances', scalar(@{$fixture->{instances}{model_instances}}), '/models');
    _limit('scoreboard_instances', scalar(@{$fixture->{instances}{scoreboard_instances}}), '/scoreboards');
    _limit('coverpoints', scalar(@{$fixture->{coverage}{coverpoints}}), '/coverage');
    _limit('coverage_bins_and_cross_tuples', $coverage_materialization, '/coverage');
    _limit('faults', scalar(@{$fixture->{faults}}), '/faults');

    my $capability_ledger = _capability_ledger(
        $semantic, $bridge, $architecture_scale_qualification,
    );
    my $resource_summary = _resource_summary(
        $ctx, $bindings, $models, $scoreboards, $coverage, $faults,
        $randomness, $scenario_records, $operation_graph, $scalar_state_cells,
        $scoreboard_capacity, $coverage_materialization,
    );
    _limit('source_map_records', scalar(@{$ctx->{source_map}}), '/source_map');

    my $data = {
        schema => $SCHEMA,
        schema_version => 1,
        profile => $PROFILE,
        plan_id => undef,
        semantic_identity => $semantic_identity,
        bridge_identity => $bridge_identity,
        fixture => {
            fixture_id => $fixture->{semantic_id},
            fixture_name => $fixture->{name},
            unit_binding_id => $bindings->{unit}{binding_id},
            scenario_ids => [map { $_->{semantic_id} } @selected_scenarios],
            source_location => _clone($fixture->{source_span}),
        },
        type_table => $ctx->{type_entries},
        bindings => $bindings,
        domains => _clone($bindings->{domains}),
        transactions => _execution_transactions($ctx, $bindings),
        events => _clone($bindings->{events}),
        models => $models,
        scoreboards => $scoreboards,
        coverage => $coverage,
        faults => $faults,
        randomness => $randomness,
        scenarios => $scenario_records,
        operation_graph => $operation_graph,
        capability_ledger => $capability_ledger,
        native_extensions => [],
        source_map => $ctx->{source_map},
        resource_summary => $resource_summary,
        diagnostics => [],
    };
    my $digest_data = _clone($data);
    delete $digest_data->{plan_id};
    delete $digest_data->{diagnostics};
    $data->{plan_id} = 'plan/' . sha256_hex(_canonical_json($digest_data));

    my $execution_ir = FSM::VIAL::ExecutionIR->_from_builder($data);
    my $plan = FSM::VIAL::ExecutionReport->build($execution_ir);
    _limit_bytes('serialized_plan_bytes', _canonical_json($plan), '/plan');
    return {
        ok => JSON::PP::true,
        execution_ir => $execution_ir,
        plan => $plan,
        diagnostics => [],
    };
}

sub _validate_input_profiles($semantic, $bridge, $architecture_scale_qualification) {
    _throw('VIAL_CAPABILITY_ERROR', 'capability', 'SemanticIR schema/profile is unsupported', '/semantic_ir')
        unless $semantic->{schema_version} == 1
            && $semantic->{language} eq 'vial'
            && $semantic->{language_version} == 1
            && $semantic->{profile} eq 'core_directed_single_clock_v1';
    _throw('VIAL_CAPABILITY_ERROR', 'capability', 'bridge schema/profile is unsupported', '/bridge_manifest')
        unless $bridge->{schema} eq 'fsmgen.hial_vial_bridge_manifest.v1'
            && $bridge->{schema_version} == 1
            && $bridge->{profile} eq 'core_single_unit_v1';
    _throw('VIAL_CAPABILITY_ERROR', 'capability',
        'the first execution profile requires a canonical IAL0, IAL1, or IAL2-via-generated-IAL1 bridge route',
        '/bridge_manifest/review_route')
        unless ($bridge->{review_route}{authored_layer} // '') =~ /\A(?:IAL0|IAL1|IAL2)\z/
            && !$bridge->{review_route}{direct_ial2_to_verification};
    _validate_architecture_scale_qualification($bridge)
        if $architecture_scale_qualification;
}

sub _validate_architecture_scale_qualification($bridge) {
    my @protocols = @{$bridge->{protocols} || []};
    my $protocol = @protocols == 1 ? $protocols[0] : {};
    my @facts = @{$protocol->{facts} || []};
    my @capabilities = @{$bridge->{required_capabilities} || []};
    my %capability = map { $_ => 1 } @capabilities;
    my @layers = map { $_->{layer} // '' }
        @{$bridge->{review_route}{stages} || []};
    _throw('VIAL_CAPABILITY_ERROR', 'capability',
        'architecture-scale qualification requires the exact private direct-IAL1 protocol profile',
        '/bridge_manifest/protocols')
        unless ($bridge->{review_route}{authored_layer} // '') eq 'IAL1'
            && !$bridge->{review_route}{direct_ial2_to_verification}
            && join("\0", @layers) eq join("\0", qw(IAL1 IAL0))
            && ($protocol->{protocol_id} // '') eq 'protocol/architecture_scale_probe'
            && ($protocol->{name} // '') eq 'architecture_scale_probe'
            && ($protocol->{profile} // '') eq 'qualification_only'
            && ($protocol->{revision} // '') eq '1'
            && ($protocol->{role} // '') eq 'verification'
            && @facts == 1
            && ($facts[0]{name} // '') eq 'scale_evidence_only'
            && ($facts[0]{value} // '') eq 'true'
            && $capability{$ARCHITECTURE_SCALE_CAPABILITY}
            && !$capability{'hial_vial.bridge_protocol.ahb_subordinate_v1'};
}

sub _find_fixture($semantic, $fixture_id) {
    my @found;
    for my $package (@{$semantic->{packages}}) {
        push @found, map { [$package, $_] }
            grep { $_->{semantic_id} eq $fixture_id } @{$package->{fixtures}};
    }
    _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
        "fixture '$fixture_id' does not resolve exactly once", '/fixture_id')
        unless @found == 1;
    return @{$found[0]};
}

sub _select_scenarios($fixture, $requested) {
    my %seen;
    for my $index (0 .. $#$requested) {
        _throw('VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
            "scenario_ids/$index must be a non-empty scalar", "/scenario_ids/$index")
            unless defined($requested->[$index]) && !ref($requested->[$index])
                && length($requested->[$index]);
        _throw('VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
            "duplicate scenario ID '$requested->[$index]'", "/scenario_ids/$index")
            if $seen{$requested->[$index]}++;
    }
    my %wanted = map { $_ => 1 } @$requested;
    my @selected = grep { $wanted{$_->{semantic_id}} } @{$fixture->{scenarios}};
    _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
        'one or more selected scenario IDs do not belong to the fixture', '/scenario_ids')
        unless @selected == @$requested;
    _throw('VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        'scenario_ids must preserve authored scenario order', '/scenario_ids')
        unless join("\0", map { $_->{semantic_id} } @selected) eq join("\0", @$requested);
    return @selected;
}

sub _index_bridge($ctx) {
    my $bridge = $ctx->{bridge};
    for my $spec (
        [units => 'unit_id'], [domains => 'domain_id'], [types => 'type_id'],
        [endpoints => 'endpoint_id'], [probes => 'probe_id'],
        [transactions => 'transaction_id'], [events => 'event_id'],
    ) {
        my ($family, $key) = @$spec;
        my %index;
        for my $position (0 .. $#{$bridge->{$family}}) {
            my $record = $bridge->{$family}[$position];
            _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
                "bridge $family contains a duplicate '$record->{$key}'", "/$family/$position/$key")
                if exists $index{$record->{$key}};
            $index{$record->{$key}} = {record => $record, index => $position};
        }
        $ctx->{"bridge_$family"} = \%index;
    }
}

sub _bind_fixture($ctx) {
    my $fixture = $ctx->{fixture};
    my $dut = $fixture->{dut};
    my $unit_entry = $ctx->{bridge_units}{$dut->{unit_bridge_ref}};
    _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
        "unit bridge reference '$dut->{unit_bridge_ref}' is unresolved",
        $dut->{semantic_path}, $dut->{source_span}, ['/units']) unless $unit_entry;
    _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
        'the first execution profile requires exactly one bridge unit',
        $dut->{semantic_path}, $dut->{source_span}, ['/units'])
        unless @{$ctx->{bridge}{units}} == 1;
    my $unit = $unit_entry->{record};
    my $unit_binding_id = _binding_id($fixture->{semantic_id}, $unit->{unit_id});
    my $bindings = {
        unit => {
            binding_id => $unit_binding_id,
            semantic_id => $dut->{semantic_id},
            unit_id => $unit->{unit_id},
            source_location => _clone($dut->{source_span}),
        },
        domains => [], endpoints => [], probes => [], transactions => [], events => [],
    };

    for my $domain (@{$dut->{domains}}) {
        my $entry = $ctx->{bridge_domains}{$domain->{bridge_ref}};
        _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
            "domain bridge reference '$domain->{bridge_ref}' is unresolved",
            $domain->{semantic_path}, $domain->{source_span}, ['/domains']) unless $entry;
        my $carrier = $entry->{record};
        _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
            "domain '$carrier->{domain_id}' does not belong to the bound unit",
            $domain->{semantic_path}, $domain->{source_span}, ["/domains/$entry->{index}"])
            unless $carrier->{unit_id} eq $unit->{unit_id};
        my $record = {
            binding_id => _binding_id($fixture->{semantic_id}, $carrier->{domain_id}),
            semantic_id => $domain->{semantic_id},
            domain_id => $carrier->{domain_id},
            unit_binding_id => $unit_binding_id,
            clock_endpoint_id => $carrier->{clock_endpoint_id},
            active_edge => $carrier->{active_edge},
            reset_endpoint_id => $carrier->{reset_endpoint_id},
            reset_kind => $carrier->{reset_kind},
            reset_polarity => $carrier->{reset_polarity},
            source_location => _clone($domain->{source_span}),
        };
        push @{$bindings->{domains}}, $record;
        _add_source_map($ctx, "/bindings/domains/$#{$bindings->{domains}}",
            $domain->{semantic_path}, ["/domains/$entry->{index}"], $domain->{source_span});
    }
    _throw('VIAL_EXECUTION_LIMIT_ERROR', 'limit',
        'the first execution profile requires exactly one selected domain',
        $dut->{semantic_path}, $dut->{source_span}) unless @{$bindings->{domains}} == 1;

    for my $endpoint (@{$dut->{endpoints}}) {
        if ($endpoint->{access} eq 'verification_probe') {
            _bind_probe($ctx, $bindings, $endpoint, $unit);
        }
        else {
            _bind_endpoint($ctx, $bindings, $endpoint, $unit);
        }
    }
    _bind_transactions($ctx, $bindings, $unit);
    my $binding_count = 1 + @{$bindings->{domains}} + @{$bindings->{endpoints}}
        + @{$bindings->{probes}} + @{$bindings->{transactions}} + @{$bindings->{events}};
    $binding_count += scalar(@{$_->{fields}}) for @{$bindings->{transactions}};
    $binding_count += scalar(@{$_->{event_input_bindings}}) for @{$bindings->{transactions}};
    $binding_count += scalar(@{$_->{adapter_state_binding_ids}}) for @{$bindings->{events}};
    _limit('bindings', $binding_count, '/bindings');
    return $bindings;
}

sub _bind_endpoint($ctx, $bindings, $semantic, $unit) {
    my $entry = $ctx->{bridge_endpoints}{$semantic->{bridge_ref}};
    _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
        "endpoint bridge reference '$semantic->{bridge_ref}' is unresolved",
        $semantic->{semantic_path}, $semantic->{source_span}, ['/endpoints']) unless $entry;
    my $carrier = $entry->{record};
    _throw('VIAL_BIND_REFERENCE_ERROR', 'bind', 'endpoint belongs to a different unit',
        $semantic->{semantic_path}, $semantic->{source_span}, ["/endpoints/$entry->{index}"])
        unless $carrier->{unit_id} eq $unit->{unit_id};
    _throw('VIAL_BIND_ACCESS_ERROR', 'bind',
        "endpoint '$carrier->{endpoint_id}' is not a public port",
        $semantic->{semantic_path}, $semantic->{source_span}, ["/endpoints/$entry->{index}/access"])
        unless $semantic->{access} eq 'public_port' && $carrier->{access} eq 'public_port';
    _throw('VIAL_BIND_ACCESS_ERROR', 'bind',
        "clock/reset endpoint '$carrier->{endpoint_id}' cannot be ordinary VIAL data",
        $semantic->{semantic_path}, $semantic->{source_span}, ["/endpoints/$entry->{index}/role"])
        if $carrier->{role} eq 'clock' || $carrier->{role} eq 'reset';
    my @directions = $carrier->{direction} eq 'inout'
        ? qw(drive sample) : _semantic_endpoint_directions($ctx, $semantic);
    @directions = $carrier->{direction} eq 'input' ? qw(drive) : qw(sample)
        unless @directions;
    for my $direction (@directions) {
        _throw('VIAL_BIND_ACCESS_ERROR', 'bind',
            "sampled endpoint '$carrier->{endpoint_id}' is not an output/inout public port",
            $semantic->{semantic_path}, $semantic->{source_span}, ["/endpoints/$entry->{index}/direction"])
            if $direction eq 'sample'
                && $carrier->{direction} ne 'output' && $carrier->{direction} ne 'inout';
        _throw('VIAL_BIND_ACCESS_ERROR', 'bind',
            "driven endpoint '$carrier->{endpoint_id}' is not an input/inout public port",
            $semantic->{semantic_path}, $semantic->{source_span}, ["/endpoints/$entry->{index}/direction"])
            if $direction eq 'drive'
                && $carrier->{direction} ne 'input' && $carrier->{direction} ne 'inout';
    }
    my $binding_id = _binding_id($ctx->{fixture}{semantic_id}, $carrier->{endpoint_id});
    my $carrier_type = _bridge_type($ctx, $carrier->{type_id}, $semantic);
    my @relations = map {
        _prove_relation($ctx, $binding_id, $semantic->{name}, $_,
            $semantic->{type}, $carrier_type, $semantic)
    } @directions;
    my $record = {
        binding_id => $binding_id,
        semantic_id => $semantic->{semantic_id},
        endpoint_id => $carrier->{endpoint_id},
        access => $carrier->{access},
        carrier_direction => $carrier->{direction},
        relations => \@relations,
        source_location => _clone($semantic->{source_span}),
    };
    push @{$bindings->{endpoints}}, $record;
    $ctx->{endpoint_binding_by_semantic_id}{$semantic->{semantic_id}} = $binding_id;
    $ctx->{bridge_endpoint_binding_id}{$carrier->{endpoint_id}} = $binding_id;
    my $position = $#{$bindings->{endpoints}};
    for my $relation_index (0 .. $#relations) {
        _add_source_map($ctx, "/bindings/endpoints/$position/relations/$relation_index",
            $semantic->{semantic_path}, ["/endpoints/$entry->{index}", _type_fact_path($ctx, $carrier->{type_id})],
            $semantic->{source_span});
    }
}

sub _bind_probe($ctx, $bindings, $semantic, $unit) {
    my $entry = $ctx->{bridge_probes}{$semantic->{bridge_ref}};
    _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
        "probe bridge reference '$semantic->{bridge_ref}' is unresolved",
        $semantic->{semantic_path}, $semantic->{source_span}, ['/probes']) unless $entry;
    my $carrier = $entry->{record};
    _throw('VIAL_BIND_ACCESS_ERROR', 'bind', "probe '$carrier->{probe_id}' has incompatible access",
        $semantic->{semantic_path}, $semantic->{source_span}, ["/probes/$entry->{index}/access"])
        unless $carrier->{unit_id} eq $unit->{unit_id}
            && $carrier->{access} eq 'verification_probe';
    _throw('VIAL_CAPABILITY_ERROR', 'capability',
        "probe '$carrier->{probe_id}' lacks an equivalent adapter requirement",
        $semantic->{semantic_path}, $semantic->{source_span}, ["/probes/$entry->{index}/adapter_requirement"])
        unless $carrier->{adapter_requirement} eq 'equivalent_adapter_required';
    my $binding_id = _binding_id($ctx->{fixture}{semantic_id}, $carrier->{probe_id});
    my $carrier_type = _bridge_type($ctx, $carrier->{type_id}, $semantic);
    my $relation = _prove_relation($ctx, $binding_id, $semantic->{name}, 'sample',
        $semantic->{type}, $carrier_type, $semantic);
    my $record = {
        binding_id => $binding_id,
        semantic_id => $semantic->{semantic_id},
        probe_id => $carrier->{probe_id},
        access => $carrier->{access},
        adapter_requirement => $carrier->{adapter_requirement},
        relations => [$relation],
        source_location => _clone($semantic->{source_span}),
    };
    push @{$bindings->{probes}}, $record;
    $ctx->{endpoint_binding_by_semantic_id}{$semantic->{semantic_id}} = $binding_id;
    $ctx->{bridge_probe_binding_id}{$carrier->{probe_id}} = $binding_id;
    _add_source_map($ctx, "/bindings/probes/$#{$bindings->{probes}}/relations/0",
        $semantic->{semantic_path}, ["/probes/$entry->{index}", _type_fact_path($ctx, $carrier->{type_id})],
        $semantic->{source_span});
}

sub _semantic_endpoint_directions($ctx, $semantic) {
    my @directions;
    _push_unique(\@directions, 'sample')
        if _node_has_reference($ctx->{fixture}, 'sample', $semantic->{semantic_id});
    _push_unique(\@directions, 'drive')
        if _node_has_reference($ctx->{fixture}, 'drive', $semantic->{semantic_id});
    return @directions;
}

sub _node_has_reference($value, $op, $semantic_id) {
    return 0 unless ref($value);
    if (ref($value) eq 'HASH') {
        return 1 if ($value->{kind} // '') eq 'reference'
            && ($value->{op} // '') eq $op
            && ($value->{semantic_id} // '') eq $semantic_id;
        return scalar grep { _node_has_reference($value->{$_}, $op, $semantic_id) } keys %$value;
    }
    return scalar grep { _node_has_reference($_, $op, $semantic_id) } @$value
        if ref($value) eq 'ARRAY';
    return 0;
}

sub _bind_transactions($ctx, $bindings, $unit) {
    my %semantic_transaction = map { $_->{semantic_id} => $_ } @{$ctx->{package}{transactions}};
    for my $binding (@{$ctx->{fixture}{dut}{transaction_bindings}}) {
        my $entry = $ctx->{bridge_transactions}{$binding->{bridge_ref}};
        _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
            "transaction bridge reference '$binding->{bridge_ref}' is unresolved",
            $binding->{semantic_path}, $binding->{source_span}, ['/transactions']) unless $entry;
        my $carrier = $entry->{record};
        my $semantic = $semantic_transaction{$binding->{transaction_id}};
        _throw('VIAL_BIND_REFERENCE_ERROR', 'bind', 'semantic transaction is unresolved',
            $binding->{semantic_path}, $binding->{source_span}) unless $semantic;
        _throw('VIAL_BIND_REFERENCE_ERROR', 'bind', 'transaction belongs to a different unit',
            $binding->{semantic_path}, $binding->{source_span}, ["/transactions/$entry->{index}/unit_id"])
            unless $carrier->{unit_id} eq $unit->{unit_id};
        _throw('VIAL_BIND_EVENT_ERROR', 'bind',
            "transaction '$carrier->{transaction_id}' requires single_active correlation",
            $binding->{semantic_path}, $binding->{source_span}, ["/transactions/$entry->{index}/correlation"])
            unless $carrier->{correlation} eq 'single_active';
        my @semantic_names = map { $_->{name} } @{$semantic->{fields}};
        my @carrier_names = map { $_->{name} } @{$carrier->{fields}};
        _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
            'semantic and carrier transaction field sets/orders differ',
            $semantic->{semantic_path}, $semantic->{source_span}, ["/transactions/$entry->{index}/fields"])
            unless join("\0", @semantic_names) eq join("\0", @carrier_names);
        my $binding_id = _binding_id($ctx->{fixture}{semantic_id}, $carrier->{transaction_id});
        my @fields;
        my $transaction_position = scalar(@{$bindings->{transactions}});
        for my $index (0 .. $#{$semantic->{fields}}) {
            my $semantic_field = $semantic->{fields}[$index];
            my $carrier_field = $carrier->{fields}[$index];
            my $carrier_type = _bridge_type($ctx, $carrier_field->{type_id}, $semantic_field);
            my $direction = $carrier_field->{direction};
            _throw('VIAL_BIND_ACCESS_ERROR', 'bind',
                "transaction field '$carrier_field->{name}' has unsupported direction '$direction'",
                $semantic_field->{semantic_path}, $semantic_field->{source_span},
                ["/transactions/$entry->{index}/fields/$index/direction"])
                unless $direction eq 'drive' || $direction eq 'sample';
            my $relation = _prove_relation($ctx, $binding_id, $semantic_field->{name}, $direction,
                $semantic_field->{type}, $carrier_type, $semantic_field);
            push @fields, {
                binding_id => "$binding_id/field/" . _pointer_escape($semantic_field->{name}),
                semantic_id => $semantic_field->{semantic_id},
                name => $semantic_field->{name},
                endpoint_id => $carrier_field->{endpoint_id},
                direction => $direction,
                phase_role => $carrier_field->{phase_role},
                relation => $relation,
                source_location => _clone($semantic_field->{source_span}),
            };
            $ctx->{bridge_endpoint_binding_id}{$carrier_field->{endpoint_id}}
                = $fields[-1]{binding_id};
            _add_source_map($ctx, "/bindings/transactions/$transaction_position/fields/$index/relation",
                $semantic_field->{semantic_path},
                ["/transactions/$entry->{index}/fields/$index", _type_fact_path($ctx, $carrier_field->{type_id})],
                $semantic_field->{source_span});
        }
        my $record = {
            binding_id => $binding_id,
            semantic_id => $binding->{semantic_id},
            transaction_semantic_id => $semantic->{semantic_id},
            transaction_id => $carrier->{transaction_id},
            protocol_id => $carrier->{protocol_id},
            ordering => $carrier->{ordering},
            correlation => $carrier->{correlation},
            fields => \@fields,
            event_input_bindings => [],
            event_binding_ids => [],
            source_location => _clone($binding->{source_span}),
        };
        push @{$bindings->{transactions}}, $record;
        $ctx->{transaction_binding_by_semantic_id}{$binding->{semantic_id}} = $binding_id;
        $ctx->{semantic_transaction_events_by_binding_semantic_id}{$binding->{semantic_id}}
            = [map { $_->{name} } @{$semantic->{events}}];
        _bind_events($ctx, $bindings, $record, $semantic, $carrier, $entry->{index});
    }
}

sub _bind_events($ctx, $bindings, $transaction_binding, $semantic_transaction, $carrier_transaction, $transaction_index) {
    my %carrier_event = map {
        my $entry = $ctx->{bridge_events}{$_};
        $entry->{record}{name} => $entry;
    } @{$carrier_transaction->{event_ids}};
    for my $semantic_event (@{$semantic_transaction->{events}}) {
        my $entry = $carrier_event{$semantic_event->{name}};
        _throw('VIAL_BIND_EVENT_ERROR', 'bind',
            "transaction event '$semantic_event->{name}' is unresolved",
            $semantic_event->{semantic_path}, $semantic_event->{source_span},
            ["/transactions/$transaction_index/event_ids"]) unless $entry;
        my $carrier = $entry->{record};
        my $binding_id = _binding_id($ctx->{fixture}{semantic_id}, $carrier->{event_id});
        my $semantic_occurrence_id = $transaction_binding->{semantic_id}
            . '::event::' . $semantic_event->{name};
        _bind_event_dependencies($ctx, $transaction_binding, $carrier, $semantic_event);
        my @adapter_state_binding_ids;
        my $expression = _rebind_bridge_expression(
            $ctx, $carrier->{expression}, $transaction_binding, $carrier,
            \@adapter_state_binding_ids,
        );
        my $record = {
            binding_id => $binding_id,
            semantic_id => $semantic_occurrence_id,
            declaration_semantic_id => $semantic_event->{semantic_id},
            event_id => $carrier->{event_id},
            transaction_binding_id => $transaction_binding->{binding_id},
            name => $semantic_event->{name},
            kind => $carrier->{kind},
            phase => $carrier->{phase},
            expression => $expression,
            adapter_state_binding_ids => \@adapter_state_binding_ids,
            source_location => _clone($semantic_event->{source_span}),
        };
        push @{$bindings->{events}}, $record;
        push @{$transaction_binding->{event_binding_ids}}, $binding_id;
        $ctx->{event_binding_by_semantic_id}{$semantic_occurrence_id} = $binding_id;
        $ctx->{event_binding_by_transaction_and_name}{
            $transaction_binding->{semantic_id} . "\0" . $semantic_event->{name}
        } = $binding_id;
        _add_source_map($ctx, "/bindings/events/$#{$bindings->{events}}",
            $semantic_event->{semantic_path}, ["/events/$entry->{index}"], $semantic_event->{source_span});
    }
    _throw('VIAL_BIND_EVENT_ERROR', 'bind', 'carrier contains an event not declared by VIAL',
        $semantic_transaction->{semantic_path}, $semantic_transaction->{source_span},
        ["/transactions/$transaction_index/event_ids"])
        unless keys(%carrier_event) == @{$semantic_transaction->{events}};
}

sub _bind_event_dependencies($ctx, $transaction_binding, $carrier_event, $semantic_event) {
    for my $endpoint_id (@{$carrier_event->{required_endpoint_ids}}) {
        next if defined $ctx->{bridge_endpoint_binding_id}{$endpoint_id};
        my $entry = $ctx->{bridge_endpoints}{$endpoint_id};
        _throw('VIAL_BIND_EVENT_ERROR', 'bind',
            "event dependency endpoint '$endpoint_id' is unresolved",
            $semantic_event->{semantic_path}, $semantic_event->{source_span}, ['/endpoints'])
            unless $entry;
        my $endpoint = $entry->{record};
        _throw('VIAL_BIND_ACCESS_ERROR', 'bind',
            "event dependency endpoint '$endpoint_id' is not a public port on the bound unit",
            $semantic_event->{semantic_path}, $semantic_event->{source_span},
            ["/endpoints/$entry->{index}"])
            unless $endpoint->{unit_id} eq $ctx->{bridge}{units}[0]{unit_id}
                && $endpoint->{access} eq 'public_port';
        my $binding_id = $transaction_binding->{binding_id}
            . '/event-input/' . _pointer_escape($endpoint_id);
        push @{$transaction_binding->{event_input_bindings}}, {
            binding_id => $binding_id,
            endpoint_id => $endpoint_id,
            carrier_direction => $endpoint->{direction},
            carrier_type_id => $endpoint->{type_id},
            access => $endpoint->{access},
        };
        $ctx->{bridge_endpoint_binding_id}{$endpoint_id} = $binding_id;
    }
    for my $probe_id (@{$carrier_event->{required_probe_ids}}) {
        _throw('VIAL_BIND_EVENT_ERROR', 'bind',
            "event dependency probe '$probe_id' is unavailable",
            $semantic_event->{semantic_path}, $semantic_event->{source_span}, ['/probes'])
            unless defined $ctx->{bridge_probe_binding_id}{$probe_id};
    }
}

sub _index_scenario_handle_bindings($ctx) {
    for my $scenario (@{$ctx->{scenarios}}) {
        for my $action (_all_actions($scenario->{actions})) {
            next unless $action->{kind} eq 'start';
            my $transaction_binding = $action->{transaction_binding_id};
            _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
                'scenario start refers to an unbound transaction',
                $action->{semantic_path}, $action->{source_span})
                unless defined $ctx->{transaction_binding_by_semantic_id}{$transaction_binding};
            for my $event_name (@{$ctx->{semantic_transaction_events_by_binding_semantic_id}{$transaction_binding}}) {
                my $key = $transaction_binding . "\0" . $event_name;
                my $binding_id = $ctx->{event_binding_by_transaction_and_name}{$key};
                _throw('VIAL_BIND_EVENT_ERROR', 'bind',
                    "scenario handle event '$event_name' is unbound",
                    $action->{semantic_path}, $action->{source_span}) unless defined $binding_id;
                $ctx->{event_binding_by_semantic_id}{
                    $action->{handle_id} . '::event::' . $event_name
                } = $binding_id;
            }
        }
    }
}

sub _bridge_type($ctx, $type_id, $semantic) {
    my $entry = $ctx->{bridge_types}{$type_id};
    _throw('VIAL_BIND_TYPE_ERROR', 'bind', "carrier type '$type_id' is unresolved",
        $semantic->{semantic_path}, $semantic->{source_span}, ['/types']) unless $entry;
    return $entry->{record};
}

sub _prove_relation($ctx, $binding_id, $name, $direction, $authored_type, $carrier, $semantic) {
    my $resolved = _resolved_type($authored_type);
    my $shape = _type_shape($resolved);
    my $semantic_type_id = _register_type($ctx, $shape, _semantic_type_identity($authored_type));
    my ($semantic_domain, $signed, $width) = _type_domain($resolved);
    _throw('VIAL_BIND_TYPE_ERROR', 'bind', "carrier type '$carrier->{type_id}' is not scalar logic",
        $semantic->{semantic_path}, $semantic->{source_span}, [_type_fact_path($ctx, $carrier->{type_id})])
        unless $carrier->{kind} eq 'logic' && $carrier->{width} > 0;
    _throw('VIAL_BIND_TYPE_ERROR', 'bind', "type width differs for '$name'",
        $semantic->{semantic_path}, $semantic->{source_span}, [_type_fact_path($ctx, $carrier->{type_id})])
        unless $width == $carrier->{width};
    _throw('VIAL_BIND_TYPE_ERROR', 'bind', "type signedness differs for '$name'",
        $semantic->{semantic_path}, $semantic->{source_span}, [_type_fact_path($ctx, $carrier->{type_id})])
        unless $signed == ($carrier->{signed} ? 1 : 0);

    my ($kind, $proofs, @encoding);
    if ($resolved->{kind} eq 'enum') {
        _throw('VIAL_BIND_TYPE_ERROR', 'bind', "enum '$name' may only drive a carrier",
            $semantic->{semantic_path}, $semantic->{source_span}, [_type_fact_path($ctx, $carrier->{type_id})])
            unless $direction eq 'drive';
        my %seen;
        for my $member (@{$resolved->{members}}) {
            my $value = _normalize_literal($ctx, $member->{value}, $resolved->{base_type});
            _throw('VIAL_BIND_TYPE_ERROR', 'bind', "enum '$name' has an unknown or Z encoding",
                $member->{semantic_path}, $member->{source_span}, [_type_fact_path($ctx, $carrier->{type_id})])
                unless $value->{known_hex} =~ /\A[f37]?[f]*\z/ && $value->{z_hex} !~ /[1-9a-f]/;
            _throw('VIAL_BIND_TYPE_ERROR', 'bind', "enum '$name' has duplicate encodings",
                $member->{semantic_path}, $member->{source_span}, [_type_fact_path($ctx, $carrier->{type_id})])
                if $seen{$value->{value_hex}}++;
            push @encoding, {
                semantic_id => $member->{semantic_id},
                name => $member->{name},
                value => $value,
            };
        }
        _throw('VIAL_BIND_TYPE_ERROR', 'bind', "enum '$name' has no members",
            $semantic->{semantic_path}, $semantic->{source_span}) unless @encoding;
        $kind = 'enum_encoding_injection_v1';
        $proofs = [qw(
            enum_base_relation_proven enum_members_nonempty
            enum_member_encodings_unique enum_member_encodings_representable
            enum_member_encodings_preserved
        )];
    }
    elsif ($semantic_domain eq $carrier->{state_domain}) {
        $kind = 'bit_domain_identity_v1';
        $proofs = [qw(state_domain_equal signedness_equal width_equal bit_pattern_preserved)];
    }
    elsif ($semantic_domain eq 'two_state' && $carrier->{state_domain} eq 'four_state'
        && $direction eq 'drive') {
        $kind = 'known_value_injection_v1';
        $proofs = [qw(
            semantic_two_state carrier_four_state signedness_equal width_equal
            value_bits_preserved all_carrier_bits_known no_carrier_z
        )];
    }
    else {
        _throw('VIAL_BIND_TYPE_ERROR', 'bind',
            "no allowed $direction relation maps $semantic_domain to $carrier->{state_domain} for '$name'",
            $semantic->{semantic_path}, $semantic->{source_span}, [_type_fact_path($ctx, $carrier->{type_id})]);
    }
    my $entry = $ctx->{type_by_shape}{_canonical_json($shape)};
    _push_unique($entry->{carrier_type_ids}, $carrier->{type_id});
    return {
        relation_id => 'type-relation/' . $binding_id . '/' . _pointer_escape($name) . "/$direction",
        kind => $kind,
        direction => $direction,
        semantic_type_id => $semantic_type_id,
        carrier_type_id => $carrier->{type_id},
        semantic_state_domain => $semantic_domain,
        carrier_state_domain => $carrier->{state_domain},
        signed => $signed ? 1 : 0,
        width => 0 + $width,
        enum_encoding => \@encoding,
        proof_ids => $proofs,
    };
}

sub _type_shape($resolved) {
    if ($resolved->{kind} eq 'scalar') {
        return {
            kind => 'scalar',
            family => $resolved->{family},
            state_domain => $resolved->{four_state} ? 'four_state' : 'two_state',
            signed => $resolved->{signed} ? 1 : 0,
            width => 0 + $resolved->{width},
        };
    }
    if ($resolved->{kind} eq 'enum') {
        return {
            kind => 'enum',
            semantic_id => $resolved->{semantic_id},
            base_type => _type_shape($resolved->{base_type}),
            members => [map {
                {
                    semantic_id => $_->{semantic_id},
                    name => $_->{name},
                    value => _plain_value($_->{value}),
                }
            } @{$resolved->{members}}],
        };
    }
    _throw('VIAL_BIND_TYPE_ERROR', 'bind', "unsupported semantic type kind '$resolved->{kind}'", '/types');
}

sub _type_domain($resolved) {
    my $base = $resolved->{kind} eq 'enum' ? $resolved->{base_type} : $resolved;
    return ($base->{four_state} ? 'four_state' : 'two_state',
        $base->{signed} ? 1 : 0, 0 + $base->{width});
}

sub _resolved_type($type) {
    return _resolved_type($type->{resolved}) if $type->{kind} eq 'reference';
    return $type;
}

sub _semantic_type_identity($type) {
    return $type->{semantic_id} if $type->{kind} eq 'reference' && defined $type->{semantic_id};
    my $resolved = _resolved_type($type);
    return $resolved->{semantic_id} if $resolved->{kind} eq 'enum';
    return undef;
}

sub _register_type($ctx, $shape, $semantic_id = undef) {
    my $canonical = _canonical_json($shape);
    my $entry = $ctx->{type_by_shape}{$canonical};
    if (!$entry) {
        my $type_id = 'execution-type/' . sha256_hex($canonical);
        $entry = {
            type_id => $type_id,
            semantic_type => _clone($shape),
            semantic_ids => [],
            carrier_type_ids => [],
        };
        $ctx->{type_by_shape}{$canonical} = $entry;
        push @{$ctx->{type_entries}}, $entry;
        _limit('execution_types', scalar(@{$ctx->{type_entries}}), '/type_table');
    }
    _push_unique($entry->{semantic_ids}, $semantic_id) if defined $semantic_id;
    return $entry->{type_id};
}

sub _normalize_literal($ctx, $value, $type) {
    my $resolved = _resolved_type($type);
    my $base = $resolved->{kind} eq 'enum' ? $resolved->{base_type} : $resolved;
    my $shape = _type_shape($base);
    my $type_id = _register_type($ctx, $shape);
    my $state = $base->{four_state} ? 'four_state' : 'two_state';
    my ($numeric, $known, $z);
    if ($value->{kind} eq 'integer_value') {
        $numeric = Math::BigInt->new("$value->{value_decimal}");
        return FSM::VIAL::ExecutionRandom->normalized_scalar(
            $numeric->bstr, $type_id, $state, $base->{signed}, $base->{width});
    }
    if ($value->{kind} eq 'bool_value') {
        return FSM::VIAL::ExecutionRandom->normalized_scalar(
            $value->{value} ? 1 : 0, $type_id, $state, 0, 1);
    }
    if ($value->{kind} eq 'logic_vector') {
        my $digits = int(($base->{width} + 3) / 4);
        my $value_hex = _pad_hex($value->{value_bits}, $digits);
        my $known_hex = _pad_hex($value->{known_mask}, $digits);
        my $z_hex = _pad_hex($value->{z_mask}, $digits);
        return {
            kind => 'scalar', type_id => $type_id, state_domain => $state,
            signed => $base->{signed} ? 1 : 0, width => 0 + $base->{width},
            value_hex => $value_hex, known_hex => $known_hex, z_hex => $z_hex,
        };
    }
    if ($value->{kind} eq 'enum_value') {
        my ($member) = grep { $_->{semantic_id} eq $value->{member_id} } @{$resolved->{members}};
        _throw('VIAL_BIND_TYPE_ERROR', 'bind', 'enum literal member is unresolved', '/') unless $member;
        my $normalized = _normalize_literal($ctx, $member->{value}, $resolved->{base_type});
        $normalized->{type_id} = _register_type($ctx, _type_shape($resolved), $resolved->{semantic_id});
        return $normalized;
    }
    _throw('VIAL_BIND_TYPE_ERROR', 'bind', "unsupported literal kind '$value->{kind}'", '/values');
}

sub _plain_value($value) {
    return {map { $_ => _clone($value->{$_}) } grep { $_ ne 'source_span' && $_ ne 'semantic_path' } sort keys %$value};
}

sub _pad_hex($value, $digits) {
    my $hex = lc("$value");
    $hex =~ s/\A0x//;
    $hex = ('0' x ($digits - length($hex))) . $hex if length($hex) < $digits;
    return $hex;
}

sub _build_operations($ctx) {
    my @all_operations;
    my @scenario_records;
    my $total_fibers = 0;
    my $maximum_simultaneous_live_fibers = 0;
    for my $scenario (@{$ctx->{scenarios}}) {
        my $state = {
            scenario => $scenario,
            rank => 0,
            operation_offset => scalar(@all_operations),
            operations => [],
            fibers => [],
        };
        my $root_fiber = 'fiber/' . $scenario->{semantic_id} . '/root';
        push @{$state->{fibers}}, {
            fiber_id => $root_fiber,
            name => 'root',
            parent_fiber_id => undef,
            cancel_scope_id => 'cancel-scope/' . $scenario->{semantic_id},
            source_location => _clone($scenario->{source_span}),
        };
        _emit_sequence($ctx, $state, $scenario->{actions}, $root_fiber, 'root');
        _limit('expanded_operations_per_scenario', scalar(@{$state->{operations}}), $scenario->{semantic_path});
        push @all_operations, @{$state->{operations}};
        $total_fibers += @{$state->{fibers}};
        my $scenario_live_fibers = 1 + _maximum_live_descendants($scenario->{actions});
        $maximum_simultaneous_live_fibers = $scenario_live_fibers
            if $scenario_live_fibers > $maximum_simultaneous_live_fibers;
        my @expectations = map { $_->{semantic_id} }
            grep { $_->{kind} eq 'expect' } _all_actions($scenario->{actions});
        my @scoreboards = _ordered_unique(map {
            $_->{scoreboard_instance_id}
        } grep { exists $_->{scoreboard_instance_id} } _all_actions($scenario->{actions}));
        my @faults = _ordered_unique(map { $_->{fault_id} }
            grep { $_->{kind} eq 'inject' } _all_actions($scenario->{actions}));
        my $record = {
            scenario_id => $scenario->{semantic_id},
            name => $scenario->{name},
            domain_id => $scenario->{domain_id},
            timeout_cycles => 0 + $scenario->{timeout_cycles},
            root_fiber_id => $root_fiber,
            fibers => $state->{fibers},
            operation_ids => [map { $_->{operation_id} } @{$state->{operations}}],
            plan_summary => {
                scenario_id => $scenario->{semantic_id},
                timeout_domain_id => $scenario->{domain_id},
                timeout_cycles => 0 + $scenario->{timeout_cycles},
                root_fiber_id => $root_fiber,
                operation_count => scalar(@{$state->{operations}}),
                fiber_count => scalar(@{$state->{fibers}}),
                expectation_ids => \@expectations,
                scoreboard_instance_ids => \@scoreboards,
                coverpoint_ids => [map { $_->{semantic_id} } @{$ctx->{fixture}{coverage}{coverpoints}}],
                fault_ids => \@faults,
                decision_occurrence_ids => [],
            },
            source_location => _clone($scenario->{source_span}),
        };
        push @scenario_records, $record;
        $ctx->{operation_by_scenario}{$scenario->{semantic_id}} = $state->{operations};
    }
    _limit('expanded_operations_total', scalar(@all_operations), '/operation_graph/operations');
    _limit('total_fibers', $total_fibers, '/operation_graph/fibers');
    _limit('simultaneous_live_fibers', $maximum_simultaneous_live_fibers,
        '/operation_graph/maximum_simultaneous_live_fibers');
    return ({
        phase_order => [qw(drive sample react check)],
        tie_break_order => [qw(domain_rank static_operation_rank local_emission_index semantic_id)],
        operations => \@all_operations,
        total_operation_count => scalar(@all_operations),
        total_fiber_count => $total_fibers,
        maximum_simultaneous_live_fibers => $maximum_simultaneous_live_fibers,
    }, \@scenario_records);
}

sub _maximum_live_descendants($actions) {
    my $maximum = 0;
    for my $action (@$actions) {
        my $live = 0;
        if ($action->{kind} eq 'parallel') {
            $live += 1 + _maximum_live_descendants($_->{actions})
                for @{$action->{fibers}};
        }
        elsif ($action->{kind} eq 'repeat') {
            $live = _maximum_live_descendants($action->{actions} || $action->{body} || []);
        }
        $maximum = $live if $live > $maximum;
    }
    return $maximum;
}

sub _emit_sequence($ctx, $state, $actions, $fiber_id, $repeat_path) {
    my @sequence_operations;
    for my $action (@$actions) {
        my $phase = $ACTION_PHASE{$action->{kind}};
        _throw('VIAL_SCHEDULE_CONFLICT', 'schedule', "unsupported action kind '$action->{kind}'",
            $action->{semantic_path}, $action->{source_span}) unless $phase;
        my $operation_id = 'operation/' . $state->{scenario}{semantic_id} . '/'
            . _pointer_escape($action->{semantic_path}) . '/' . $repeat_path;
        my $deadline = ($action->{kind} eq 'await' || $action->{kind} eq 'expect')
            ? {
                domain_id => $state->{scenario}{domain_id},
                cycle => $state->{scenario}{timeout_cycles} - 1,
                phase => 'check',
            } : undef;
        my $operation = {
            operation_id => $operation_id,
            kind => $action->{kind},
            scenario_id => $state->{scenario}{semantic_id},
            fiber_id => $fiber_id,
            static_rank => $state->{rank}++,
            eligible_phase => $phase,
            typed_inputs => _action_inputs($ctx, $action),
            effects => [{
                kind => $ACTION_EFFECT{$action->{kind}},
                target_id => _action_target($action),
                local_emission_index => 0,
            }],
            successor_ids => [],
            failure_successor_id => undef,
            cancel_scope_id => 'cancel-scope/' . $state->{scenario}{semantic_id},
            deadline => $deadline,
            source_location => _clone($action->{source_span}),
        };
        push @{$state->{operations}}, $operation;
        push @sequence_operations, $operation;
        my $operation_index = $state->{operation_offset} + $#{$state->{operations}};
        _add_source_map($ctx, "/operation_graph/operations/$operation_index",
            $action->{semantic_path}, [], $action->{source_span});

        if ($action->{kind} eq 'parallel') {
            my @child_roots;
            for my $fiber (@{$action->{fibers}}) {
                my $child_id = 'fiber/' . $state->{scenario}{semantic_id} . '/'
                    . _pointer_escape($action->{semantic_path}) . '/'
                    . _pointer_escape($fiber->{name}) . '/' . $repeat_path;
                push @{$state->{fibers}}, {
                    fiber_id => $child_id,
                    name => $fiber->{name},
                    parent_fiber_id => $fiber_id,
                    cancel_scope_id => $operation->{cancel_scope_id},
                    source_location => _clone($fiber->{source_span}),
                };
                my $before = @{$state->{operations}};
                _emit_sequence($ctx, $state, $fiber->{actions}, $child_id, $repeat_path);
                push @child_roots, $state->{operations}[$before]{operation_id}
                    if @{$state->{operations}} > $before;
            }
            $operation->{effects}[0]{join} = $action->{join};
            $operation->{effects}[0]{child_root_operation_ids} = \@child_roots;
        }
        elsif ($action->{kind} eq 'repeat') {
            my $count = $action->{count} // $action->{times};
            _throw('VIAL_SCHEDULE_CONFLICT', 'schedule', 'repeat count is not a positive literal',
                $action->{semantic_path}, $action->{source_span})
                unless defined($count) && !ref($count) && $count =~ /\A[1-9][0-9]*\z/;
            for my $iteration (0 .. $count - 1) {
                _emit_sequence($ctx, $state, $action->{actions} || $action->{body} || [],
                    $fiber_id, "$repeat_path/$iteration");
            }
        }
    }
    for my $index (0 .. $#sequence_operations - 1) {
        $sequence_operations[$index]{successor_ids} = [$sequence_operations[$index + 1]{operation_id}];
    }
}

sub _action_inputs($ctx, $action) {
    my @inputs;
    for my $key (sort keys %$action) {
        next if $key eq 'kind' || $key eq 'name' || $key eq 'semantic_id'
            || $key eq 'semantic_path' || $key eq 'source_span'
            || $key eq 'actions' || $key eq 'fibers' || $key eq 'body';
        push @inputs, {name => $key, value => _normalize_node($ctx, $action->{$key})};
    }
    return \@inputs;
}

sub _action_target($action) {
    return $action->{domain_id} if exists $action->{domain_id};
    return $action->{transaction_binding_id} if exists $action->{transaction_binding_id};
    return $action->{scoreboard_instance_id} if exists $action->{scoreboard_instance_id};
    return $action->{fault_id} if exists $action->{fault_id};
    return $action->{semantic_id} if exists $action->{semantic_id};
    return undef;
}

sub _all_actions($actions) {
    my @all;
    for my $action (@$actions) {
        push @all, $action;
        push @all, _all_actions($_->{actions}) for @{$action->{fibers} || []};
        push @all, _all_actions($action->{actions} || $action->{body} || [])
            if $action->{kind} eq 'repeat';
    }
    return @all;
}

sub _build_randomness($ctx, $replay, $semantic_identity, $bridge_identity) {
    my @expected;
    my $seed = $ctx->{fixture}{randomness}{seed};
    for my $scenario (@{$ctx->{scenarios}}) {
        my $operations = $ctx->{operation_by_scenario}{$scenario->{semantic_id}};
        for my $choice (@{$ctx->{fixture}{randomness}{choices}}) {
            my @references = map { $_->{operation_id} }
                grep { _contains_scalar($_->{typed_inputs}, $choice->{semantic_id}) } @$operations;
            next unless @references;
            my $type = _resolved_type($choice->{type});
            my $type_id = _register_type($ctx, _type_shape($type), $choice->{semantic_id});
            my $occurrence = 'decision/' . $ctx->{fixture}{semantic_id} . '/'
                . $scenario->{semantic_id} . '/' . $choice->{decision_id} . '/0';
            my $low = _value_decimal($choice->{distribution}{low});
            my $high = _value_decimal($choice->{distribution}{high});
            my $distribution = {
                kind => 'uniform',
                low => _normalize_literal($ctx, $choice->{distribution}{low}, $choice->{type}),
                high => _normalize_literal($ctx, $choice->{distribution}{high}, $choice->{type}),
            };
            push @expected, {
                occurrence_id => $occurrence,
                declaration_semantic_id => $choice->{semantic_id},
                decision_id => $choice->{decision_id},
                scenario_id => $scenario->{semantic_id},
                algorithm => $RANDOM_ALGORITHM,
                seed => 0 + $seed,
                type_id => $type_id,
                distribution => $distribution,
                low_decimal => $low,
                high_decimal => $high,
                choice => $choice,
                reference_operation_ids => \@references,
                source_location => _clone($choice->{source_span}),
            };
        }
    }
    _limit('random_occurrences', scalar(@expected), '/randomness/decisions');
    my @decisions = defined($replay)
        ? _replayed_decisions($ctx, $replay, \@expected, $semantic_identity, $bridge_identity)
        : _generated_decisions($ctx, \@expected);
    for my $index (0 .. $#decisions) {
        my ($expected) = grep { $_->{occurrence_id} eq $decisions[$index]{occurrence_id} } @expected;
        _add_source_map($ctx, "/random_decisions/$index", $expected->{choice}{semantic_path}, [],
            $expected->{choice}{source_span});
    }
    return {
        algorithm => $RANDOM_ALGORITHM,
        seed => 0 + $seed,
        replay_id => defined($replay) ? $replay->{replay_id} : undef,
        decisions => \@decisions,
    };
}

sub _generated_decisions($ctx, $expected) {
    my @decisions;
    for my $item (@$expected) {
        my $generated = FSM::VIAL::ExecutionRandom->generate({
            width => _resolved_type($item->{choice}{type})->{width},
            seed => $item->{seed},
            occurrence_id => $item->{occurrence_id},
            low => $item->{low_decimal},
            high => $item->{high_decimal},
            accept => sub($proposal) {
                return _constraints_hold($item->{choice}{constraints}, $item->{choice}{semantic_id}, $proposal);
            },
        });
        _throw('VIAL_RANDOM_EXHAUSTED', 'random',
            "random choice '$item->{decision_id}' exhausted its attempt limit",
            $item->{choice}{semantic_path}, $item->{choice}{source_span}) unless $generated;
        my $value = FSM::VIAL::ExecutionRandom->normalized_scalar(
            $generated->{value}->bstr, $item->{type_id}, 'two_state',
            _resolved_type($item->{choice}{type})->{signed},
            _resolved_type($item->{choice}{type})->{width},
        );
        push @decisions, _decision_record($item, $value, $generated->{attempt}, 'generated');
    }
    return @decisions;
}

sub _replayed_decisions($ctx, $replay, $expected, $semantic_identity, $bridge_identity) {
    my %allowed = map { $_ => 1 } qw(
        schema schema_version replay_id semantic_ir_id bridge_manifest_id
        fixture_id scenario_ids algorithm decisions
    );
    _closed_hash($replay, \%allowed, 'VIAL_REPLAY_ERROR', '/replay_manifest');
    _throw('VIAL_REPLAY_ERROR', 'replay', 'replay schema/version is invalid', '/replay_manifest')
        unless ($replay->{schema} // '') eq 'fsmgen.vial_replay.v1'
            && ($replay->{schema_version} // 0) == 1;
    my $digest = _clone($replay);
    delete $digest->{replay_id};
    my $expected_replay_id = 'replay/' . sha256_hex(_canonical_json($digest));
    _throw('VIAL_REPLAY_ERROR', 'replay', 'replay_id does not match canonical replay content', '/replay_manifest/replay_id')
        unless ($replay->{replay_id} // '') eq $expected_replay_id;
    _throw('VIAL_REPLAY_ERROR', 'replay', 'replay identity does not match this plan', '/replay_manifest')
        unless ($replay->{semantic_ir_id} // '') eq $semantic_identity->{semantic_ir_id}
            && ($replay->{bridge_manifest_id} // '') eq $bridge_identity->{manifest_id}
            && ($replay->{fixture_id} // '') eq $ctx->{fixture}{semantic_id}
            && ($replay->{algorithm} // '') eq $RANDOM_ALGORITHM
            && ref($replay->{scenario_ids}) eq 'ARRAY'
            && join("\0", @{$replay->{scenario_ids}}) eq join("\0", map { $_->{semantic_id} } @{$ctx->{scenarios}})
            && ref($replay->{decisions}) eq 'ARRAY';
    _throw('VIAL_REPLAY_ERROR', 'replay', 'replay decision count does not match the plan', '/replay_manifest/decisions')
        unless @{$replay->{decisions}} == @$expected;
    my %by_id;
    for my $index (0 .. $#{$replay->{decisions}}) {
        my $decision = $replay->{decisions}[$index];
        my %keys = map { $_ => 1 } qw(
            occurrence_id declaration_semantic_id decision_id scenario_id
            algorithm seed type_id distribution value attempt
        );
        _closed_hash($decision, \%keys, 'VIAL_REPLAY_ERROR', "/replay_manifest/decisions/$index");
        _throw('VIAL_REPLAY_ERROR', 'replay', 'duplicate replay occurrence', "/replay_manifest/decisions/$index")
            if $by_id{$decision->{occurrence_id}}++;
    }
    my @records;
    for my $item (@$expected) {
        my ($decision) = grep { $_->{occurrence_id} eq $item->{occurrence_id} } @{$replay->{decisions}};
        _throw('VIAL_REPLAY_ERROR', 'replay', "missing replay occurrence '$item->{occurrence_id}'", '/replay_manifest/decisions')
            unless $decision;
        for my $key (qw(declaration_semantic_id decision_id scenario_id algorithm seed type_id)) {
            _throw('VIAL_REPLAY_ERROR', 'replay', "replay occurrence has wrong $key", '/replay_manifest/decisions')
                unless _canonical_json($decision->{$key}) eq _canonical_json($item->{$key});
        }
        _throw('VIAL_REPLAY_ERROR', 'replay', 'replay distribution differs from the plan', '/replay_manifest/decisions')
            unless _canonical_json($decision->{distribution}) eq _canonical_json($item->{distribution});
        _validate_normalized_value($decision->{value}, $item->{type_id}, _resolved_type($item->{choice}{type}));
        my $numeric = _normalized_value_math($decision->{value}, _resolved_type($item->{choice}{type}));
        _throw('VIAL_REPLAY_ERROR', 'replay', 'replay value is outside the declared distribution', '/replay_manifest/decisions')
            if $numeric->bcmp($item->{low_decimal}) < 0 || $numeric->bcmp($item->{high_decimal}) > 0;
        _throw('VIAL_REPLAY_ERROR', 'replay', 'replay value violates an authored constraint', '/replay_manifest/decisions')
            unless _constraints_hold($item->{choice}{constraints}, $item->{choice}{semantic_id}, $numeric);
        _throw('VIAL_REPLAY_ERROR', 'replay', 'replay attempt is invalid', '/replay_manifest/decisions')
            unless defined($decision->{attempt}) && !ref($decision->{attempt})
                && $decision->{attempt} =~ /\A[0-9]+\z/ && $decision->{attempt} < $LIMIT{random_attempts};
        push @records, _decision_record($item, $decision->{value}, $decision->{attempt}, 'replayed');
    }
    return @records;
}

sub _normalized_value_math($value, $type) {
    my $numeric = Math::BigInt->from_hex('0x' . $value->{value_hex});
    if ($type->{signed}) {
        my $sign_bit = Math::BigInt->new(2)->bpow($type->{width} - 1);
        $numeric->bsub(Math::BigInt->new(2)->bpow($type->{width}))
            if $numeric->bcmp($sign_bit) >= 0;
    }
    return $numeric;
}

sub _decision_record($item, $value, $attempt, $origin) {
    return {
        occurrence_id => $item->{occurrence_id},
        declaration_semantic_id => $item->{declaration_semantic_id},
        decision_id => $item->{decision_id},
        scenario_id => $item->{scenario_id},
        algorithm => $item->{algorithm},
        seed => $item->{seed},
        type_id => $item->{type_id},
        distribution => _clone($item->{distribution}),
        value => _clone($value),
        attempt => 0 + $attempt,
        origin => $origin,
        reference_operation_ids => _clone($item->{reference_operation_ids}),
        source_location => _clone($item->{source_location}),
    };
}

sub _attach_decisions_to_scenarios($scenarios, $decisions) {
    for my $scenario (@$scenarios) {
        $scenario->{plan_summary}{decision_occurrence_ids} = [map { $_->{occurrence_id} }
            grep { $_->{scenario_id} eq $scenario->{scenario_id} } @$decisions];
    }
}

sub _resolve_decision_references($operation_graph, $randomness) {
    my %decision = map {
        ($_->{scenario_id} . "\0" . $_->{declaration_semantic_id}) => $_
    } @{$randomness->{decisions}};
    for my $operation (@{$operation_graph->{operations}}) {
        $operation->{typed_inputs} = _replace_decision_reference(
            $operation->{typed_inputs}, $operation->{scenario_id}, \%decision,
        );
    }
}

sub _replace_decision_reference($value, $scenario_id, $decision) {
    return undef unless defined $value;
    if (ref($value) eq 'ARRAY') {
        return [map { _replace_decision_reference($_, $scenario_id, $decision) } @$value];
    }
    if (ref($value) eq 'HASH') {
        if (($value->{kind} // '') eq 'reference' && ($value->{op} // '') eq 'choice') {
            my $record = $decision->{$scenario_id . "\0" . ($value->{semantic_id} // '')};
            _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
                'choice reference has no scenario decision occurrence', '/') unless $record;
            return {
                kind => 'decision_reference',
                occurrence_id => $record->{occurrence_id},
                type_id => $record->{type_id},
                value => _clone($record->{value}),
            };
        }
        return {map {
            $_ => _replace_decision_reference($value->{$_}, $scenario_id, $decision)
        } sort keys %$value};
    }
    return $value;
}

sub _constraints_hold($constraints, $choice_id, $proposal) {
    for my $constraint (@$constraints) {
        return 0 unless _eval_constraint($constraint, $choice_id, $proposal);
    }
    return 1;
}

sub _eval_constraint($node, $choice_id, $proposal) {
    if ($node->{kind} eq 'reference' && $node->{op} eq 'choice') {
        return $proposal->copy if $node->{semantic_id} eq $choice_id;
        die "unknown choice reference\n";
    }
    if ($node->{kind} eq 'literal') {
        return Math::BigInt->new(_value_decimal($node->{value}));
    }
    if ($node->{kind} eq 'operator') {
        my @value = map { _eval_constraint($_, $choice_id, $proposal) } @{$node->{operands}};
        return $value[0]->bcmp($value[1]) >= 0 ? 1 : 0 if $node->{op} eq '>=';
        return $value[0]->bcmp($value[1]) <= 0 ? 1 : 0 if $node->{op} eq '<=';
        return $value[0]->bcmp($value[1]) > 0 ? 1 : 0 if $node->{op} eq '>';
        return $value[0]->bcmp($value[1]) < 0 ? 1 : 0 if $node->{op} eq '<';
        return $value[0]->bcmp($value[1]) == 0 ? 1 : 0 if $node->{op} eq 'value_eq' || $node->{op} eq 'same';
        return $value[0]->copy->badd($value[1]) if $node->{op} eq '+';
        return $value[0]->copy->bsub($value[1]) if $node->{op} eq '-';
        return ($value[0] && $value[1]) ? 1 : 0 if $node->{op} eq 'and';
        return ($value[0] || $value[1]) ? 1 : 0 if $node->{op} eq 'or';
        return $value[0] ? 0 : 1 if $node->{op} eq 'not';
    }
    die "unsupported random constraint\n";
}

sub _value_decimal($value) {
    return "$value->{value_decimal}" if $value->{kind} eq 'integer_value';
    return $value->{value} ? '1' : '0' if $value->{kind} eq 'bool_value';
    return Math::BigInt->from_hex('0x' . $value->{value_bits})->bstr
        if $value->{kind} eq 'logic_vector';
    die "value is not a known scalar\n";
}

sub _validate_normalized_value($value, $type_id, $type) {
    my %keys = map { $_ => 1 } qw(kind type_id state_domain signed width value_hex known_hex z_hex);
    _closed_hash($value, \%keys, 'VIAL_REPLAY_ERROR', '/replay_manifest/decisions/value');
    _throw('VIAL_REPLAY_ERROR', 'replay', 'replay value type/shape is invalid', '/replay_manifest/decisions/value')
        unless $value->{kind} eq 'scalar' && $value->{type_id} eq $type_id
            && $value->{state_domain} eq 'two_state'
            && $value->{signed} == ($type->{signed} ? 1 : 0)
            && $value->{width} == $type->{width}
            && $value->{value_hex} =~ /\A[0-9a-f]+\z/
            && $value->{known_hex} =~ /\A[0-9a-f]+\z/
            && $value->{z_hex} =~ /\A0+\z/;
    my $expected = FSM::VIAL::ExecutionRandom->normalized_scalar(
        Math::BigInt->from_hex('0x' . $value->{value_hex})->bstr,
        $type_id, 'two_state', $type->{signed}, $type->{width});
    _throw('VIAL_REPLAY_ERROR', 'replay', 'replay value is not canonically normalized', '/replay_manifest/decisions/value')
        unless _canonical_json($expected) eq _canonical_json($value);
}

sub _build_models($ctx) {
    my %definition = map { $_->{semantic_id} => $_ } @{$ctx->{package}{models}};
    my $scalar_state_cells = 0;
    my @models = map {
        my $definition = $definition{$_->{model_id}};
        $scalar_state_cells += scalar(@{$definition->{state}});
        {
            instance_id => $_->{semantic_id},
            model_id => $_->{model_id},
            bindings => _normalize_node($ctx, $_->{bindings}),
            definition => _normalize_node($ctx, $definition),
            source_location => _clone($_->{source_span}),
        }
    } @{$ctx->{fixture}{instances}{model_instances}};
    _limit('scalar_state_cells', $scalar_state_cells, '/models');
    return (\@models, $scalar_state_cells);
}

sub _build_scoreboards($ctx) {
    my %definition = map { $_->{semantic_id} => $_ } @{$ctx->{package}{scoreboards}};
    my $capacity = 0;
    my @records = map {
        my $def = $definition{$_->{scoreboard_id}};
        $capacity += $def->{capacity};
        {
            instance_id => $_->{semantic_id},
            scoreboard_id => $_->{scoreboard_id},
            actual_id => $_->{actual_id},
            transaction_id => $_->{transaction_id},
            definition => _normalize_node($ctx, $def),
            source_location => _clone($_->{source_span}),
        }
    } @{$ctx->{fixture}{instances}{scoreboard_instances}};
    _limit('scoreboard_declared_capacity', $capacity, '/scoreboards');
    return (\@records, $capacity);
}

sub _coverage_materialization_count($coverage) {
    my %bins_by_point = map {
        $_->{semantic_id} => scalar(@{$_->{bins}})
    } @{$coverage->{coverpoints}};
    my $total = Math::BigInt->new(0);
    $total->badd(scalar(@{$_->{bins}})) for @{$coverage->{coverpoints}};
    for my $cross (@{$coverage->{crosses}}) {
        my $product = Math::BigInt->new(1);
        $product->bmul($bins_by_point{$_}) for @{$cross->{point_ids}};
        $total->badd($product);
    }
    return $total->numify;
}

sub _execution_transactions($ctx, $bindings) {
    my %definition = map { $_->{semantic_id} => $_ } @{$ctx->{package}{transactions}};
    return [map {
        {
            binding_id => $_->{binding_id},
            semantic_id => $_->{transaction_semantic_id},
            transaction_id => $_->{transaction_id},
            fields => [map {
                {
                    semantic_id => $_->{semantic_id}, name => $_->{name},
                    type_id => $_->{relation}{semantic_type_id}, direction => $_->{direction},
                }
            } @{$_->{fields}}],
            definition => _normalize_node($ctx, $definition{$_->{transaction_semantic_id}}),
        }
    } @{$bindings->{transactions}}];
}

sub _normalize_node($ctx, $value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    if (ref($value) eq 'ARRAY') {
        return [map { _normalize_node($ctx, $_) } @$value];
    }
    if (ref($value) eq 'HASH') {
        if (exists($value->{kind}) && exists($value->{result_type}) && exists($value->{value})) {
            my $normalized = {
                kind => 'literal',
                type_id => _register_type($ctx, _type_shape(_resolved_type($value->{result_type})),
                    _semantic_type_identity($value->{result_type})),
                value => _normalize_literal($ctx, $value->{value}, $value->{result_type}),
            };
            return $normalized;
        }
        if (($value->{kind} // '') eq 'reference'
            && ($value->{op} // '') eq 'enum_member') {
            my $type = $value->{result_type};
            my $normalized_value = _normalize_literal($ctx, {
                kind => 'enum_value', member_id => $value->{semantic_id},
            }, $type);
            return {
                kind => 'literal',
                type_id => $normalized_value->{type_id},
                value => $normalized_value,
            };
        }
        my %copy;
        for my $key (sort keys %$value) {
            next if $key eq 'source_span' || $key eq 'semantic_path';
            if (($key eq 'type' || $key eq 'result_type') && ref($value->{$key}) eq 'HASH'
                && ($value->{$key}{kind} // '') =~ /\A(?:scalar|enum|reference)\z/) {
                $copy{type_id} = _register_type($ctx,
                    _type_shape(_resolved_type($value->{$key})), _semantic_type_identity($value->{$key}));
                next;
            }
            $copy{$key} = _normalize_node($ctx, $value->{$key});
        }
        if (($copy{kind} // '') eq 'reference' && defined($copy{semantic_id})
            && ($copy{op} // '') =~ /\A(?:sample|event|event_count)\z/) {
            my $binding_id = ($copy{op} // '') eq 'sample'
                ? $ctx->{endpoint_binding_by_semantic_id}{$copy{semantic_id}}
                : $ctx->{event_binding_by_semantic_id}{$copy{semantic_id}};
            _throw('VIAL_BIND_REFERENCE_ERROR', 'bind',
                "executable reference '$copy{semantic_id}' has no binding", '/', undef)
                unless defined $binding_id;
            $copy{binding_id} = $binding_id;
        }
        return \%copy;
    }
    _throw('VIAL_EXECUTION_INTERNAL_ERROR', 'internal', 'semantic data contains a live reference', '/') if ref($value);
    return $value;
}

sub _rebind_bridge_expression($ctx, $expression, $transaction_binding, $carrier_event, $adapter_states) {
    return undef unless defined $expression;
    _throw('VIAL_BIND_EVENT_ERROR', 'bind', 'bridge event expression is not a closed record',
        '/', undef, ['/events']) unless ref($expression) eq 'HASH' && !blessed($expression);
    my $kind = $expression->{kind} // '';
    if ($kind eq 'reference') {
        my $reference_kind = $expression->{reference_kind} // '';
        if ($reference_kind eq 'endpoint') {
            my $endpoint_id = $expression->{semantic_id};
            my $binding_id = $ctx->{bridge_endpoint_binding_id}{$endpoint_id};
            my $entry = $ctx->{bridge_endpoints}{$endpoint_id};
            _throw('VIAL_BIND_EVENT_ERROR', 'bind',
                "bridge event endpoint '$endpoint_id' has no execution binding",
                '/', undef, ['/events']) unless defined($binding_id) && $entry;
            my $type_id = _register_carrier_type($ctx, $entry->{record}{type_id});
            return {
                kind => 'binding_reference',
                reference_kind => 'endpoint',
                binding_id => $binding_id,
                type_id => $type_id,
            };
        }
        if ($reference_kind eq 'probe') {
            my $probe_id = $expression->{semantic_id};
            my $binding_id = $ctx->{bridge_probe_binding_id}{$probe_id};
            my $entry = $ctx->{bridge_probes}{$probe_id};
            _throw('VIAL_BIND_EVENT_ERROR', 'bind',
                "bridge event probe '$probe_id' has no execution binding",
                '/', undef, ['/events']) unless defined($binding_id) && $entry;
            my $type_id = _register_carrier_type($ctx, $entry->{record}{type_id});
            return {
                kind => 'binding_reference',
                reference_kind => 'probe',
                binding_id => $binding_id,
                type_id => $type_id,
            };
        }
        if ($reference_kind eq 'storage') {
            my $binding_id = $transaction_binding->{binding_id}
                . '/event-adapter-state/' . _pointer_escape($carrier_event->{event_id});
            _push_unique($adapter_states, $binding_id);
            return {
                kind => 'binding_reference',
                reference_kind => 'transaction_adapter_state',
                binding_id => $binding_id,
                type_id => _register_type($ctx, {
                    kind => 'scalar', family => 'logic', state_domain => 'four_state',
                    signed => 0, width => 1,
                }),
            };
        }
        _throw('VIAL_BIND_EVENT_ERROR', 'bind',
            "unsupported bridge event reference kind '$reference_kind'", '/', undef, ['/events']);
    }
    if ($kind eq 'literal') {
        return _normalize_bridge_literal($ctx, $expression->{value});
    }
    if ($kind eq 'call') {
        my %operator = (
            '&' => 'logical_all_v1',
            '==' => 'same_bits_v1',
        );
        my $operator = $operator{$expression->{operator} // ''};
        _throw('VIAL_BIND_EVENT_ERROR', 'bind',
            "unsupported bridge event operator '" . ($expression->{operator} // '') . "'",
            '/', undef, ['/events']) unless $operator;
        my @operands = map {
            _rebind_bridge_expression($ctx, $_, $transaction_binding, $carrier_event, $adapter_states)
        } @{$expression->{operands} || []};
        _throw('VIAL_BIND_EVENT_ERROR', 'bind', 'bridge event operator has no operands',
            '/', undef, ['/events']) unless @operands;
        if ($operator eq 'same_bits_v1') {
            _throw('VIAL_BIND_EVENT_ERROR', 'bind', 'bridge equality requires two operands',
                '/', undef, ['/events']) unless @operands == 2;
            my $left = _execution_value_type($ctx, $operands[0]);
            my $right = _execution_value_type($ctx, $operands[1]);
            _throw('VIAL_BIND_EVENT_ERROR', 'bind', 'bridge equality operand widths differ',
                '/', undef, ['/events']) unless $left->{width} == $right->{width};
        }
        return {
            kind => 'operator',
            operator => $operator,
            operands => \@operands,
            type_id => _register_type($ctx, {
                kind => 'scalar', family => 'bool', state_domain => 'two_state',
                signed => 0, width => 1,
            }),
        };
    }
    _throw('VIAL_BIND_EVENT_ERROR', 'bind',
        "unsupported bridge event expression kind '$kind'", '/', undef, ['/events']);
}

sub _register_carrier_type($ctx, $carrier_type_id) {
    my $entry = $ctx->{bridge_types}{$carrier_type_id};
    _throw('VIAL_BIND_EVENT_ERROR', 'bind',
        "bridge event carrier type '$carrier_type_id' is unresolved", '/', undef, ['/types'])
        unless $entry;
    my $carrier = $entry->{record};
    _throw('VIAL_BIND_EVENT_ERROR', 'bind', 'bridge event carrier type is not scalar logic',
        '/', undef, ["/types/$entry->{index}"])
        unless $carrier->{kind} eq 'logic' && $carrier->{width} > 0;
    my $type_id = _register_type($ctx, {
        kind => 'scalar', family => 'logic', state_domain => $carrier->{state_domain},
        signed => $carrier->{signed} ? 1 : 0, width => 0 + $carrier->{width},
    });
    my $type_entry = $ctx->{type_by_shape}{_canonical_json({
        kind => 'scalar', family => 'logic', state_domain => $carrier->{state_domain},
        signed => $carrier->{signed} ? 1 : 0, width => 0 + $carrier->{width},
    })};
    _push_unique($type_entry->{carrier_type_ids}, $carrier_type_id);
    return $type_id;
}

sub _normalize_bridge_literal($ctx, $text) {
    _throw('VIAL_BIND_EVENT_ERROR', 'bind', 'bridge event literal is not scalar text',
        '/', undef, ['/events']) unless defined($text) && !ref($text);
    if ($text eq 'true' || $text eq 'false') {
        my $type_id = _register_type($ctx, {
            kind => 'scalar', family => 'bool', state_domain => 'two_state',
            signed => 0, width => 1,
        });
        return {
            kind => 'literal',
            value => FSM::VIAL::ExecutionRandom->normalized_scalar(
                $text eq 'true' ? 1 : 0, $type_id, 'two_state', 0, 1,
            ),
            type_id => $type_id,
        };
    }
    my ($width, $digits);
    if ($text =~ /\A([0-9]+)'[sS]?[bB]([01_]+)\z/) {
        ($width, $digits) = (0 + $1, $2);
        $digits =~ s/_//g;
        _throw('VIAL_BIND_EVENT_ERROR', 'bind', 'bridge binary literal width is invalid',
            '/', undef, ['/events']) if !length($digits) || length($digits) > $width;
        my $value = Math::BigInt->from_bin('0b' . $digits);
        my $type_id = _register_type($ctx, {
            kind => 'scalar', family => 'logic', state_domain => 'four_state',
            signed => 0, width => $width,
        });
        return {
            kind => 'literal',
            value => FSM::VIAL::ExecutionRandom->normalized_scalar(
                $value->bstr, $type_id, 'four_state', 0, $width,
            ),
            type_id => $type_id,
        };
    }
    if ($text =~ /\A[0-9]+\z/) {
        my $value = Math::BigInt->new($text);
        my $bits = $value->is_zero ? 1 : length($value->as_bin) - 2;
        my $type_id = _register_type($ctx, {
            kind => 'scalar', family => 'logic', state_domain => 'four_state',
            signed => 0, width => $bits,
        });
        return {
            kind => 'literal',
            value => FSM::VIAL::ExecutionRandom->normalized_scalar(
                $value->bstr, $type_id, 'four_state', 0, $bits,
            ),
            type_id => $type_id,
        };
    }
    _throw('VIAL_BIND_EVENT_ERROR', 'bind',
        'bridge event literal is outside the target-neutral first profile', '/', undef, ['/events']);
}

sub _execution_value_type($ctx, $node) {
    my $type_id = $node->{type_id} // $node->{value}{type_id};
    my ($entry) = grep { $_->{type_id} eq $type_id } @{$ctx->{type_entries}};
    _throw('VIAL_BIND_EVENT_ERROR', 'bind', 'bridge event expression type is unresolved',
        '/', undef, ['/events']) unless $entry;
    return $entry->{semantic_type};
}

sub _capability_ledger($semantic, $bridge, $architecture_scale_qualification) {
    my %known = map { $_ => 1 } (
        @{$semantic->{required_capabilities}}, @{$bridge->{required_capabilities}},
        @EXECUTION_CAPABILITIES,
    );
    my %origin;
    push @{$origin{$_}}, 'semantic_ir' for @{$semantic->{required_capabilities}};
    push @{$origin{$_}}, 'bridge_manifest' for @{$bridge->{required_capabilities}};
    push @{$origin{$_}}, 'execution_profile' for @EXECUTION_CAPABILITIES;
    for my $residue (@{$bridge->{unsupported_residue}}) {
        next unless defined $residue->{required_capability};
        $known{$residue->{required_capability}} = 1;
        push @{$origin{$residue->{required_capability}}}, $residue->{residue_id};
    }
    my %allowed = map { $_ => 1 } (
        qw(vial.source.v1 vial.semantic_ir.v1 vial.profile.core_directed_single_clock_v1),
        qw(
            hial_vial.bridge_manifest.v1
            hial_vial.bridge_observation.passive_monitor
            hial_vial.bridge_probe.equivalent_adapter_required
            hial_vial.bridge_profile.core_single_unit_v1
            hial_vial.bridge_protocol.ahb_subordinate_v1
            hial_vial.bridge_source.ial0
            hial_vial.bridge_source.ial1
            hial_vial.bridge_source.ial2_via_generated_ial1
        ),
        ($architecture_scale_qualification ? $ARCHITECTURE_SCALE_CAPABILITY : ()),
        @EXECUTION_CAPABILITIES,
    );
    for my $capability (sort keys %known) {
        _throw('VIAL_CAPABILITY_ERROR', 'capability',
            "unknown execution capability '$capability'", '/capability_ledger')
            unless $allowed{$capability};
    }
    return [map {
        my $adapter = $_ eq 'hial_vial.bridge_probe.equivalent_adapter_required';
        my $scale_qualification = $_ eq $ARCHITECTURE_SCALE_CAPABILITY;
        {
            capability_id => $_,
            origins => [sort(_ordered_unique(@{$origin{$_} || []}))],
            classification => $scale_qualification ? 'qualification_only'
                : $adapter ? 'required_from_backend' : 'satisfied_by_execution_profile',
            portable_class => $scale_qualification ? 'private_nonportable'
                : $adapter ? 'portable_with_equivalent_adapter' : 'portable',
            evidence_ids => [sort(_ordered_unique(@{$origin{$_} || []}))],
        }
    } sort keys %known];
}

sub _resource_summary($ctx, $bindings, $models, $scoreboards, $coverage, $faults,
    $randomness, $scenarios, $graph, $scalar_state_cells, $scoreboard_capacity,
    $coverage_materialization) {
    my $binding_count = 1 + @{$bindings->{domains}} + @{$bindings->{endpoints}}
        + @{$bindings->{probes}} + @{$bindings->{transactions}} + @{$bindings->{events}};
    $binding_count += scalar(@{$_->{fields}}) for @{$bindings->{transactions}};
    $binding_count += scalar(@{$_->{event_input_bindings}}) for @{$bindings->{transactions}};
    $binding_count += scalar(@{$_->{adapter_state_binding_ids}}) for @{$bindings->{events}};
    return {
        selected_fixtures => 1,
        selected_units => 1,
        selected_domains => scalar(@{$bindings->{domains}}),
        selected_scenarios => scalar(@$scenarios),
        execution_types => scalar(@{$ctx->{type_entries}}),
        bindings => $binding_count,
        expanded_operations_total => $graph->{total_operation_count},
        total_fibers => $graph->{total_fiber_count},
        simultaneous_live_fibers => $graph->{maximum_simultaneous_live_fibers},
        model_instances => scalar(@$models),
        scalar_state_cells => $scalar_state_cells,
        scoreboard_instances => scalar(@$scoreboards),
        scoreboard_declared_capacity => $scoreboard_capacity,
        coverpoints => scalar(@{$ctx->{fixture}{coverage}{coverpoints}}),
        coverage_bins_and_cross_tuples => $coverage_materialization,
        faults => scalar(@$faults),
        random_occurrences => scalar(@{$randomness->{decisions}}),
        native_extensions => 0,
        native_artifacts => 0,
        native_identity_bytes => 0,
        source_map_records => scalar(@{$ctx->{source_map}}),
        limits => _clone(\%LIMIT),
    };
}

sub _add_source_map($ctx, $plan_path, $semantic_path, $bridge_paths, $location) {
    push @{$ctx->{source_map}}, {
        plan_path => $plan_path,
        semantic_path => $semantic_path,
        bridge_fact_paths => [@$bridge_paths],
        source_locations => defined($location) ? [_clone($location)] : [],
    };
}

sub _type_fact_path($ctx, $type_id) {
    my $entry = $ctx->{bridge_types}{$type_id};
    return defined($entry) ? "/types/$entry->{index}" : '/types';
}

sub _binding_id($fixture_id, $bridge_id) {
    return "binding/$fixture_id/$bridge_id";
}

sub _pointer_escape($value) {
    $value =~ s/~/~0/g;
    $value =~ s{/}{~1}g;
    return $value;
}

sub _canonical_json($value) {
    return JSON::PP->new->canonical(1)->allow_nonref(1)->encode($value);
}

sub _contains_scalar($value, $needle) {
    return 0 unless defined $value;
    return $value eq $needle if !ref($value);
    return scalar grep { _contains_scalar($value->{$_}, $needle) } keys %$value
        if ref($value) eq 'HASH';
    return scalar grep { _contains_scalar($_, $needle) } @$value
        if ref($value) eq 'ARRAY';
    return 0;
}

sub _closed_hash($value, $allowed, $code, $path) {
    _throw($code, 'replay', "$path must be a closed hash", $path)
        unless ref($value) eq 'HASH' && !blessed($value);
    my @unknown = sort grep { !$allowed->{$_} } keys %$value;
    my @missing = sort grep { !exists $value->{$_} } keys %$allowed;
    _throw($code, 'replay', "$path has unknown key(s): " . join(', ', @unknown), $path) if @unknown;
    _throw($code, 'replay', "$path is missing key(s): " . join(', ', @missing), $path) if @missing;
}

sub _limit($name, $count, $path) {
    _throw('VIAL_EXECUTION_LIMIT_ERROR', 'limit',
        "$name exceeds the limit $LIMIT{$name}", $path)
        if $count > $LIMIT{$name};
}

sub _limit_bytes($name, $bytes, $path) {
    _throw('VIAL_EXECUTION_LIMIT_ERROR', 'limit',
        "$name exceeds the limit $LIMIT{$name}", $path)
        if bytes::length($bytes) > $LIMIT{$name};
}

sub _push_unique($array, $value) {
    return if grep { $_ eq $value } @$array;
    push @$array, $value;
}

sub _ordered_unique(@values) {
    my %seen;
    return grep { defined($_) && !$seen{$_}++ } @values;
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    _throw('VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        'input contains a live object or unsupported reference', '/') if ref($value);
    return $value;
}

sub _throw($code, $phase, $message, $semantic_path, $source_location = undef, $bridge_fact_paths = [], $related = []) {
    $message =~ s/[\r\n]+/ /g;
    die bless {
        schema_version => 1,
        severity => 'error',
        code => $code,
        phase => $phase,
        message => $message,
        semantic_path => $semantic_path,
        source_location => _clone($source_location),
        bridge_fact_paths => _clone($bridge_fact_paths),
        related => _clone($related),
    }, 'FSM::VIAL::ExecutionBuilder::Failure';
}

sub _failure_result(%args) {
    return {
        ok => JSON::PP::false,
        execution_ir => undef,
        plan => undef,
        diagnostics => [{
            schema_version => 1,
            severity => 'error',
            code => $args{code},
            phase => $args{phase},
            message => $args{message},
            semantic_path => $args{semantic_path},
            source_location => _clone($args{source_location}),
            bridge_fact_paths => _clone($args{bridge_fact_paths} || []),
            related => _clone($args{related} || []),
        }],
    };
}

package FSM::VIAL::ExecutionBuilder::Failure;

use overload '""' => sub { $_[0]{message} // 'VIAL execution failure' }, fallback => 1;

1;
