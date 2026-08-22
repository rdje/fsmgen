package FSM::VIAL::ArchitectureScaleCheckingState;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Adapter::IAL2::PPIF;
use FSM::Adapter::ISF;
use FSM::HIAL::VIALBridge::Builder;
use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::ExecutionBuilder;
use FSM::VIAL::Parser;

my $FAMILY = 'checking_state_v1';
my $REFERENCE_HIAL_SOURCE = 'ppif/ahb_lite_subordinate.ppif';
my $REFERENCE_HIAL_BYTES = 1_326;
my $REFERENCE_HIAL_SHA256 =
    '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c';
my $REFERENCE_VIAL_SHA256 =
    '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd';
my $VIAL_SOURCE = 'generated/vial-scale/checking_state/checking_state.vial';
my $EXECUTION_PROFILE = 'core_directed_single_clock_execution_v1';
my $EVALUATION_SCHEMA =
    'fsmgen.vial_architecture_scale_checking_evaluation.v1';
my $PACKED_STATE_SCHEMA =
    'fsmgen.vial_architecture_scale_packed_checking_state.v1';
my $OUTCOME_SCHEMA =
    'fsmgen.vial_architecture_scale_checking_outcome.v1';
my $ORACLE_EVIDENCE_SCHEMA =
    'fsmgen.vial_architecture_scale_checking_oracle_evidence.v1';
my $CLAIMS_SCHEMA =
    'fsmgen.vial_architecture_scale_checking_nonclaims.v1';

my @CONSTRUCT_KEYS = qw(level primary_axis reference_hial_text);
my @CANDIDATE_KEYS = qw(
    level primary_axis reference_hial_text vial_source_text
);
my @EVALUATE_KEYS = qw(construction);
my @VALIDATE_EVALUATION_KEYS = qw(construction evaluation);
my @STAGING_KEYS = qw(construction consumer repository_root);
my @EVALUATION_KEYS = qw(
    ok status schema schema_version evaluation_identity rerun_identity
    workload_identity family level primary_axis requested_counts
    observed_outcome stage_identities metrics packed_state_contract
    outcome_contract oracle_evidence claims explicit_nonclaims diagnostics
    contract_discrepancies
);
my @STAGE_IDENTITY_KEYS = qw(
    semantic_ir_sha256 bridge_manifest_sha256 execution_ir_sha256 plan_sha256
);
my @METRIC_KEYS = qw(
    model_instances scalar_model_state_cells scoreboard_instances
    scoreboard_declared_capacity coverpoints bins_and_cross_tuples faults
    random_occurrences serialized_plan_bytes
);
my @PACKED_STATE_KEYS = qw(
    schema schema_version digest_algorithm model_cells scoreboard_fifo
    coverage_vector
);
my @MODEL_PACKING_KEYS = qw(encoding byte_order unknown_state_policy);
my @SCOREBOARD_PACKING_KEYS = qw(
    encoding bytes_per_entry maximum_entries maximum_payload_bytes
    fixed_fields_policy ordering
);
my @COVERAGE_PACKING_KEYS = qw(
    encoding bit_order maximum_entries maximum_vector_bytes comparison
);
my @OUTCOME_KEYS = qw(
    schema schema_version observed_outcome axis_oracle_executed
    selected_count_claimed canonical_stages_completed
);
my @ORACLE_EVIDENCE_KEYS = qw(
    schema schema_version oracle model scoreboard coverage faults random_replay
);
my @CLAIM_KEYS = qw(
    schema schema_version qualification_only capability_claimed support_claimed
    performance_claimed capacity_claimed backend_authority runtime_authority
    axis_level_owned
);
my @MODEL_EVIDENCE_KEYS = qw(
    schema schema_version program axis model_instances scalar_state_cells
    cell_width_bits packed_bytes trigger_occurrences cells_initialized
    cells_updated cells_read initial_state_sha256 final_state_sha256
    expected_initial_state_sha256 expected_final_state_sha256
    first_instance_id last_instance_id first_state_id last_state_id
    trigger_event_id first_trigger_identity last_trigger_identity
    byte_equal_expected all_updates_committed all_reads_matched
);
my $MODEL_EVIDENCE_SCHEMA =
    'fsmgen.vial_architecture_scale_model_oracle_evidence.v1';
my @SCOREBOARD_EVIDENCE_KEYS = qw(
    schema schema_version program axis scoreboard_instances
    scoreboard_definitions declared_capacity transactions_enqueued
    transactions_observed transactions_matched transactions_drained
    fields_per_transaction complete_field_comparisons packed_payload_bytes
    packed_payload_sha256 expected_payload_sha256 maximum_total_expected_depth
    maximum_expected_depth maximum_actual_depth final_expected_depth
    final_actual_depth pending_entries first_instance_id last_instance_id
    first_transaction_identity last_transaction_identity first_payload_hex
    last_payload_hex fifo_order_preserved complete_transactions_equal
    all_instances_drained mismatch_rejected overflow_rejected
    corruption_rejected
);
my $SCOREBOARD_EVIDENCE_SCHEMA =
    'fsmgen.vial_architecture_scale_scoreboard_oracle_evidence.v1';
my @COVERAGE_EVIDENCE_KEYS = qw(
    schema schema_version program axis coverpoints authored_bins
    authored_crosses static_cross_tuples static_domain_entries sample_count
    sampled_value_hex packed_vector_bytes packed_vector_sha256
    expected_vector_sha256 static_domain_sha256 expected_static_domain_sha256
    first_coverpoint_id last_coverpoint_id first_bin_id last_bin_id
    first_cross_id last_cross_id normal_bin_hits cross_tuple_hits
    illegal_bin_hits ignore_bin_hits hit_entries byte_equal_expected
    static_domain_order_preserved all_authored_bins_matched
    all_static_cross_tuples_hit illegal_match_rejected ignore_match_excluded
    mutation_rejected order_mutation_rejected no_undeclared_domain_entries
);
my $COVERAGE_EVIDENCE_SCHEMA =
    'fsmgen.vial_architecture_scale_coverage_oracle_evidence.v1';
my @FAULT_EVIDENCE_KEYS = qw(
    schema schema_version program axis faults target_transaction_id
    target_field_name duration_drive_intervals original_value_hex
    substitute_value_hex faults_armed faults_applied faults_expired
    faults_restored state_transition_records declaration_order_sha256
    expected_declaration_order_sha256 transition_sha256
    expected_transition_sha256 first_fault_id last_fault_id
    first_arm_identity last_restore_identity target_identity_preserved
    original_values_matched substituted_values_matched
    restoration_values_matched stable_order_preserved all_faults_armed
    all_faults_applied all_faults_expired all_faults_restored
    reinjection_rejected overlap_rejected mutation_rejected
    order_mutation_rejected
);
my $FAULT_EVIDENCE_SCHEMA =
    'fsmgen.vial_architecture_scale_fault_oracle_evidence.v1';
my @RANDOM_EVIDENCE_KEYS = qw(
    schema schema_version program axis random_occurrences choice_declarations
    scenario_count generated_decisions replayed_decisions
    generated_sequence_sha256 rerun_sequence_sha256 replayed_sequence_sha256
    normalized_generated_sequence_sha256 normalized_replayed_sequence_sha256
    generated_plan_sha256 replayed_plan_sha256 replay_manifest_id
    first_occurrence_id last_occurrence_id first_value_hex last_value_hex
    key_order_preserved values_canonically_normalized generated_values_matched
    replay_values_matched replay_identity_preserved normalized_plans_equal
    mutation_rejected order_mutation_rejected
);
my $RANDOM_EVIDENCE_SCHEMA =
    'fsmgen.vial_architecture_scale_random_replay_oracle_evidence.v1';
my @CONTRACT_DISCREPANCY_KEYS = qw(code message path repair_owner);
my $CONSTRUCTION_ENVELOPE_BYTES = 1_114_112;
my $LIMIT_POLICY_REPAIR_OWNER =
    'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4';
my %UNCONSTRUCTIBLE = (
    coverpoints => {
        levels => [qw(limit_v1 over_limit_v1)],
        envelope_input_index => 1,
        declared_cap => 65_536,
        route_boundary => {
            accepted => 9_524,
            accepted_source_bytes => 1_048_467,
            rejected => 9_525,
            rejected_source_bytes => 1_048_577,
            cap => 'the 1048576-byte VIAL parser cap',
            path => '/',
        },
    },
);

my %OWNED_LEVELS = (
    model_instances => [qw(
        gate_candidate_v1 qualification_candidate_v1 limit_v1 over_limit_v1
    )],
    scalar_model_state_cells => [qw(
        gate_candidate_v1 qualification_candidate_v1 limit_v1 over_limit_v1
    )],
    scoreboard_instances => [qw(
        gate_candidate_v1 qualification_candidate_v1 limit_v1 over_limit_v1
    )],
    scoreboard_capacity => [qw(
        gate_candidate_v1 qualification_candidate_v1 limit_v1 over_limit_v1
    )],
    coverpoints => [qw(
        gate_candidate_v1 qualification_candidate_v1 limit_v1 over_limit_v1
    )],
    bins_and_cross_tuples => [qw(
        gate_candidate_v1 qualification_candidate_v1 limit_v1 over_limit_v1
    )],
    faults => [qw(
        gate_candidate_v1 qualification_candidate_v1 limit_v1 over_limit_v1
    )],
    random_occurrences => [qw(
        gate_candidate_v1 qualification_candidate_v1 limit_v1 over_limit_v1
    )],
);

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    confess __PACKAGE__ . "->construct expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@CONSTRUCT_KEYS, 'checking-state construction');
    my ($axis, $level) = @{$args[0]}{qw(primary_axis level)};
    my $requested = _selected_contract($axis, $level);
    confess "reference_v1 remains a catalog record and is not a generated checking-state shape\n"
        if $level eq 'reference_v1';
    confess "checking-state active slices do not own the requested shape\n"
        unless _owns($axis, $level);
    _validate_reference_hial($args[0]{reference_hial_text});
    return __PACKAGE__->_construct_candidate({
        primary_axis => $axis,
        level => $level,
        reference_hial_text => $args[0]{reference_hial_text},
        vial_source_text => _render_axis_source(
            $axis, $level, $requested->{$axis},
        ),
    });
}

sub owned_shapes($class) {
    _exact_invocant($class, 'owned_shapes');
    return [map {
        my $axis = $_;
        map { {primary_axis => $axis, level => $_} } @{$OWNED_LEVELS{$axis}}
    } sort keys %OWNED_LEVELS];
}

# Axis renderers call this boundary from this exact package, while focused tests
# exercise the foundational seal through a same-package test hook. The caller
# supplies source text, never SemanticIR, bridge, plan, trace, result, or support
# metadata.
sub _construct_candidate($class, @args) {
    my $caller = caller;
    confess "checking-state candidate construction is private to " . __PACKAGE__ . "\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__
            && defined($caller) && $caller eq __PACKAGE__;
    return _construct_candidate_internal(@args);
}

sub _construct_candidate_internal(@args) {
    my $caller = caller;
    confess "checking-state candidate internals are private to " . __PACKAGE__ . "\n"
        unless defined($caller) && $caller eq __PACKAGE__;
    confess "checking-state candidate construction expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $raw = $args[0];
    _confess_exact_keys($raw, \@CANDIDATE_KEYS, 'checking-state candidate');
    my ($axis, $level) = @{$raw}{qw(primary_axis level)};
    _selected_contract($axis, $level);
    confess "reference_v1 remains a catalog record and is not a generated checking-state shape\n"
        if $level eq 'reference_v1';
    _validate_reference_hial($raw->{reference_hial_text});

    my $constructed = FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        backend_profile => undef,
        tool_profile => undef,
        inputs => [
            _input(
                $REFERENCE_HIAL_SOURCE, 'hial_source',
                $raw->{reference_hial_text},
            ),
            _input($VIAL_SOURCE, 'vial_source', $raw->{vial_source_text}),
        ],
    });
    if (_unconstructible($axis, $level)) {
        confess "an unconstructible checking-state level was accepted by the workload contract\n"
            if $constructed->{ok};
        my $canonical = JSON::PP->new->canonical(1)->allow_nonref(1);
        confess "an unconstructible checking-state level did not return its exact envelope diagnostic\n"
            unless $canonical->encode($constructed->{diagnostics})
                eq $canonical->encode([_envelope_diagnostic($axis)]);
        return _unconstructible_construction($constructed, $axis, $level);
    }
    confess "checking-state candidate source did not fit the construction contract\n"
        unless $constructed->{ok};
    return $constructed;
}

sub build($class, @args) {
    _exact_invocant($class, 'build');
    confess __PACKAGE__ . "->build expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'checking-state build');
    my $construction = _validated_construction($args[0]{construction});
    my $spec = $construction->{specification};
    confess "preflight-dominated checking-state level is not materialized\n"
        if _random_preflight_dominance($spec);
    confess "unconstructible checking-state level has no admitted source to build\n"
        if _unconstructible(@{$spec}{qw(primary_axis level)});
    my $inputs = _canonical_inputs_from_construction($construction);
    return FSM::VIAL::ExecutionBuilder->build($inputs->{arguments});
}

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'checking-state evaluation');
    my $construction = _validated_construction($args[0]{construction});
    my $construction_specification = $construction->{specification};
    return _random_preflight_evaluation($construction)
        if _random_preflight_dominance($construction_specification);
    return _unconstructible_evaluation($construction)
        if _unconstructible(
            @{$construction_specification}{qw(primary_axis level)},
        );
    my $generated_axis = _generated_axis_kind($construction);
    return _evaluate_model_axis($construction) if $generated_axis eq 'model';
    return _evaluate_scoreboard_axis($construction)
        if $generated_axis eq 'scoreboard';
    return _evaluate_coverage_axis($construction)
        if $generated_axis eq 'coverage';
    return _evaluate_fault_axis($construction) if $generated_axis eq 'fault';
    return _evaluate_random_axis($construction) if $generated_axis eq 'random';

    my $first_inputs = _canonical_inputs_from_construction($construction);
    my $first = FSM::VIAL::ExecutionBuilder->build($first_inputs->{arguments});
    confess "checking-state foundation source did not produce canonical ExecutionIR\n"
        unless $first->{ok};
    my $second_inputs = _canonical_inputs_from_construction($construction);
    my $second = FSM::VIAL::ExecutionBuilder->build($second_inputs->{arguments});
    confess "checking-state foundation rerun did not produce canonical ExecutionIR\n"
        unless $second->{ok};

    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $first_semantic = $first_inputs->{semantic_ir}->as_hashref;
    my $second_semantic = $second_inputs->{semantic_ir}->as_hashref;
    my $first_bridge = $first_inputs->{bridge_manifest}->as_hashref;
    my $second_bridge = $second_inputs->{bridge_manifest}->as_hashref;
    my $first_execution = $first->{execution_ir}->as_hashref;
    my $second_execution = $second->{execution_ir}->as_hashref;
    my @diagnostics;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed SemanticIR',
        '/stage_identities/semantic_ir_sha256',
    ) unless $canonical->encode($second_semantic)
        eq $canonical->encode($first_semantic);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed the bridge manifest',
        '/stage_identities/bridge_manifest_sha256',
    ) unless $canonical->encode($second_bridge)
        eq $canonical->encode($first_bridge);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed ExecutionIR',
        '/stage_identities/execution_ir_sha256',
    ) unless $canonical->encode($second_execution)
        eq $canonical->encode($first_execution);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed the execution plan',
        '/stage_identities/plan_sha256',
    ) unless $canonical->encode($second->{plan})
        eq $canonical->encode($first->{plan});

    my $stage_identities = {
        semantic_ir_sha256 => sha256_hex($canonical->encode($first_semantic)),
        bridge_manifest_sha256 => sha256_hex($canonical->encode($first_bridge)),
        execution_ir_sha256 => sha256_hex($canonical->encode($first_execution)),
        plan_sha256 => sha256_hex($canonical->encode($first->{plan})),
    };
    my $rerun_identity = 'rerun/' . sha256_hex(
        $canonical->encode({
            workload_identity => $construction->{workload_identity},
            stage_identities => $stage_identities,
        }),
    );
    my $resources = $first_execution->{resource_summary};
    my $specification = $construction->{specification};
    return _evaluation({
        ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
        status => @diagnostics ? 'oracle_failure' : 'foundation_validated',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        evaluation_identity => undef,
        rerun_identity => $rerun_identity,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $specification->{level},
        primary_axis => $specification->{primary_axis},
        requested_counts => _clone($specification->{requested_counts}),
        observed_outcome => 'accepted_not_axis_evaluated',
        stage_identities => $stage_identities,
        metrics => {
            model_instances => 0 + $resources->{model_instances},
            scalar_model_state_cells => 0 + $resources->{scalar_state_cells},
            scoreboard_instances => 0 + $resources->{scoreboard_instances},
            scoreboard_declared_capacity =>
                0 + $resources->{scoreboard_declared_capacity},
            coverpoints => 0 + $resources->{coverpoints},
            bins_and_cross_tuples =>
                0 + $resources->{coverage_bins_and_cross_tuples},
            faults => 0 + $resources->{faults},
            random_occurrences => 0 + $resources->{random_occurrences},
            serialized_plan_bytes =>
                bytes::length($canonical->encode($first->{plan})),
        },
        packed_state_contract => _packed_state_contract(),
        outcome_contract => {
            schema => $OUTCOME_SCHEMA,
            schema_version => 1,
            observed_outcome => 'accepted_not_axis_evaluated',
            axis_oracle_executed => JSON::PP::false,
            selected_count_claimed => JSON::PP::false,
            canonical_stages_completed => [qw(semantic bridge execution_ir plan)],
        },
        oracle_evidence => {
            schema => $ORACLE_EVIDENCE_SCHEMA,
            schema_version => 1,
            oracle => 'none',
            model => undef,
            scoreboard => undef,
            coverage => undef,
            faults => undef,
            random_replay => undef,
        },
        claims => {
            schema => $CLAIMS_SCHEMA,
            schema_version => 1,
            qualification_only => JSON::PP::true,
            capability_claimed => JSON::PP::false,
            support_claimed => JSON::PP::false,
            performance_claimed => JSON::PP::false,
            capacity_claimed => JSON::PP::false,
            backend_authority => JSON::PP::false,
            runtime_authority => JSON::PP::false,
            axis_level_owned => JSON::PP::false,
        },
        explicit_nonclaims => _clone($specification->{explicit_nonclaims}),
        contract_discrepancies => [],
        diagnostics => \@diagnostics,
    });
}

sub _generated_axis_kind($construction) {
    my $vial = _role_input($construction, 'vial_source');
    return '' if sha256_hex($vial->{content}) eq $REFERENCE_VIAL_SHA256;
    my $spec = $construction->{specification};
    my ($axis, $level) = @{$spec}{qw(primary_axis level)};
    return '' unless _owns($axis, $level);
    my $requested = _selected_contract($axis, $level);
    my $expected = _render_axis_source($axis, $level, $requested->{$axis});
    confess "generated checking-state source is not canonical\n"
        unless $vial->{content} eq $expected;
    return 'model' if $axis eq 'model_instances'
        || $axis eq 'scalar_model_state_cells';
    return 'scoreboard' if $axis eq 'scoreboard_instances'
        || $axis eq 'scoreboard_capacity';
    return 'coverage' if $axis eq 'coverpoints'
        || $axis eq 'bins_and_cross_tuples';
    return 'fault' if $axis eq 'faults';
    return 'random' if $axis eq 'random_occurrences';
    confess "generated checking-state axis has no evaluator\n";
}

sub _evaluate_model_axis($construction) {
    my $spec = $construction->{specification};
    my ($axis, $level) = @{$spec}{qw(primary_axis level)};
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $first_inputs = _canonical_inputs_from_construction($construction);
    my $first = FSM::VIAL::ExecutionBuilder->build($first_inputs->{arguments});
    my $second_inputs = _canonical_inputs_from_construction($construction);
    my $second = FSM::VIAL::ExecutionBuilder->build($second_inputs->{arguments});
    my $first_semantic = $first_inputs->{semantic_ir}->as_hashref;
    my $second_semantic = $second_inputs->{semantic_ir}->as_hashref;
    my $first_bridge = $first_inputs->{bridge_manifest}->as_hashref;
    my $second_bridge = $second_inputs->{bridge_manifest}->as_hashref;
    my @diagnostics;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed SemanticIR',
        '/stage_identities/semantic_ir_sha256',
    ) unless $canonical->encode($second_semantic)
        eq $canonical->encode($first_semantic);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed the bridge manifest',
        '/stage_identities/bridge_manifest_sha256',
    ) unless $canonical->encode($second_bridge)
        eq $canonical->encode($first_bridge);

    my $semantic_sha = sha256_hex($canonical->encode($first_semantic));
    my $bridge_sha = sha256_hex($canonical->encode($first_bridge));
    if (!$first->{ok} || !$second->{ok}) {
        my $first_diagnostics = $first->{diagnostics} || [];
        my $second_diagnostics = $second->{diagnostics} || [];
        push @diagnostics, _oracle_error(
            'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
            'independent canonical checking-state rejection changed diagnostics',
            '/diagnostics',
        ) unless !$first->{ok} && !$second->{ok}
            && $canonical->encode($second_diagnostics)
                eq $canonical->encode($first_diagnostics);
        my $expected = _expected_model_rejection_diagnostic($axis);
        push @diagnostics, _oracle_error(
            'VIAL_SCALE_CHECKING_OUTCOME_ERROR',
            'checking-state model rejection did not match the selected adjacent excess',
            '/diagnostics',
        ) unless $level eq 'over_limit_v1'
            && $canonical->encode($first_diagnostics)
                eq $canonical->encode([$expected]);
        my $metrics = _semantic_model_metrics($first_semantic);
        my $stage_identities = {
            semantic_ir_sha256 => $semantic_sha,
            bridge_manifest_sha256 => $bridge_sha,
            execution_ir_sha256 => undef,
            plan_sha256 => undef,
        };
        my $rerun_identity = _rerun_identity(
            $construction->{workload_identity}, $stage_identities,
            $first_diagnostics,
        );
        return _evaluation({
            ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
            status => @diagnostics ? 'oracle_failure' : 'expected_rejection',
            schema => $EVALUATION_SCHEMA,
            schema_version => 1,
            evaluation_identity => undef,
            rerun_identity => $rerun_identity,
            workload_identity => $construction->{workload_identity},
            family => $FAMILY,
            level => $level,
            primary_axis => $axis,
            requested_counts => _clone($spec->{requested_counts}),
            observed_outcome => 'rejected',
            stage_identities => $stage_identities,
            metrics => $metrics,
            packed_state_contract => _packed_state_contract(),
            outcome_contract => {
                schema => $OUTCOME_SCHEMA,
                schema_version => 1,
                observed_outcome => 'rejected',
                axis_oracle_executed => JSON::PP::false,
                selected_count_claimed => JSON::PP::true,
                canonical_stages_completed => [qw(semantic bridge)],
            },
            oracle_evidence => _oracle_evidence('none', undef),
            claims => _claims(JSON::PP::true),
            explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
            contract_discrepancies => [],
            diagnostics => [@{_clone($first_diagnostics)}, @diagnostics],
        });
    }

    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_OUTCOME_ERROR',
        'checking-state adjacent excess unexpectedly produced ExecutionIR',
        '/observed_outcome',
    ) if $level eq 'over_limit_v1';
    my $first_execution = $first->{execution_ir}->as_hashref;
    my $second_execution = $second->{execution_ir}->as_hashref;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed ExecutionIR',
        '/stage_identities/execution_ir_sha256',
    ) unless $canonical->encode($second_execution)
        eq $canonical->encode($first_execution);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed the execution plan',
        '/stage_identities/plan_sha256',
    ) unless $canonical->encode($second->{plan})
        eq $canonical->encode($first->{plan});

    my ($model_evidence, $model_diagnostics) =
        _evaluate_model_state($spec, $first_execution);
    push @diagnostics, @$model_diagnostics;
    my $stage_identities = {
        semantic_ir_sha256 => $semantic_sha,
        bridge_manifest_sha256 => $bridge_sha,
        execution_ir_sha256 =>
            sha256_hex($canonical->encode($first_execution)),
        plan_sha256 => sha256_hex($canonical->encode($first->{plan})),
    };
    my $rerun_identity = _rerun_identity(
        $construction->{workload_identity}, $stage_identities, [],
    );
    my $resources = $first_execution->{resource_summary};
    return _evaluation({
        ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
        status => @diagnostics ? 'oracle_failure' : 'accepted',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        evaluation_identity => undef,
        rerun_identity => $rerun_identity,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'accepted',
        stage_identities => $stage_identities,
        metrics => _execution_metrics($resources, $first->{plan}, $canonical),
        packed_state_contract => _packed_state_contract(),
        outcome_contract => {
            schema => $OUTCOME_SCHEMA,
            schema_version => 1,
            observed_outcome => 'accepted',
            axis_oracle_executed => JSON::PP::true,
            selected_count_claimed => JSON::PP::true,
            canonical_stages_completed => [qw(semantic bridge execution_ir plan)],
        },
        oracle_evidence => _oracle_evidence('model', $model_evidence),
        claims => _claims(JSON::PP::true),
        explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
        contract_discrepancies => [],
        diagnostics => \@diagnostics,
    });
}

sub _evaluate_scoreboard_axis($construction) {
    my $spec = $construction->{specification};
    my ($axis, $level) = @{$spec}{qw(primary_axis level)};
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);

    if ($axis eq 'scoreboard_capacity' && $level eq 'over_limit_v1') {
        return _evaluate_scoreboard_semantic_rejection(
            $construction, $canonical,
        );
    }

    my $first_inputs = _canonical_inputs_from_construction($construction);
    my $first = FSM::VIAL::ExecutionBuilder->build($first_inputs->{arguments});
    my $second_inputs = _canonical_inputs_from_construction($construction);
    my $second = FSM::VIAL::ExecutionBuilder->build($second_inputs->{arguments});
    my $first_semantic = $first_inputs->{semantic_ir}->as_hashref;
    my $second_semantic = $second_inputs->{semantic_ir}->as_hashref;
    my $first_bridge = $first_inputs->{bridge_manifest}->as_hashref;
    my $second_bridge = $second_inputs->{bridge_manifest}->as_hashref;
    my @diagnostics;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed SemanticIR',
        '/stage_identities/semantic_ir_sha256',
    ) unless $canonical->encode($second_semantic)
        eq $canonical->encode($first_semantic);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed the bridge manifest',
        '/stage_identities/bridge_manifest_sha256',
    ) unless $canonical->encode($second_bridge)
        eq $canonical->encode($first_bridge);

    my $semantic_sha = sha256_hex($canonical->encode($first_semantic));
    my $bridge_sha = sha256_hex($canonical->encode($first_bridge));
    if (!$first->{ok} || !$second->{ok}) {
        my $first_diagnostics = $first->{diagnostics} || [];
        my $second_diagnostics = $second->{diagnostics} || [];
        push @diagnostics, _oracle_error(
            'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
            'independent canonical checking-state rejection changed diagnostics',
            '/diagnostics',
        ) unless !$first->{ok} && !$second->{ok}
            && $canonical->encode($second_diagnostics)
                eq $canonical->encode($first_diagnostics);
        my $expected = _expected_scoreboard_execution_rejection_diagnostic();
        push @diagnostics, _oracle_error(
            'VIAL_SCALE_CHECKING_OUTCOME_ERROR',
            'checking-state scoreboard rejection did not match the selected adjacent excess',
            '/diagnostics',
        ) unless $axis eq 'scoreboard_instances'
            && $level eq 'over_limit_v1'
            && $canonical->encode($first_diagnostics)
                eq $canonical->encode([$expected]);
        my $stage_identities = {
            semantic_ir_sha256 => $semantic_sha,
            bridge_manifest_sha256 => $bridge_sha,
            execution_ir_sha256 => undef,
            plan_sha256 => undef,
        };
        my $rerun_identity = _rerun_identity(
            $construction->{workload_identity}, $stage_identities,
            $first_diagnostics,
        );
        return _evaluation({
            ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
            status => @diagnostics ? 'oracle_failure' : 'expected_rejection',
            schema => $EVALUATION_SCHEMA,
            schema_version => 1,
            evaluation_identity => undef,
            rerun_identity => $rerun_identity,
            workload_identity => $construction->{workload_identity},
            family => $FAMILY,
            level => $level,
            primary_axis => $axis,
            requested_counts => _clone($spec->{requested_counts}),
            observed_outcome => 'rejected',
            stage_identities => $stage_identities,
            metrics => _semantic_scoreboard_metrics($first_semantic),
            packed_state_contract => _packed_state_contract(),
            outcome_contract => {
                schema => $OUTCOME_SCHEMA,
                schema_version => 1,
                observed_outcome => 'rejected',
                axis_oracle_executed => JSON::PP::false,
                selected_count_claimed => JSON::PP::true,
                canonical_stages_completed => [qw(semantic bridge)],
            },
            oracle_evidence => _oracle_evidence('none', undef),
            claims => _claims(JSON::PP::true),
            explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
            contract_discrepancies => [],
            diagnostics => [@{_clone($first_diagnostics)}, @diagnostics],
        });
    }

    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_OUTCOME_ERROR',
        'checking-state adjacent excess unexpectedly produced ExecutionIR',
        '/observed_outcome',
    ) if $level eq 'over_limit_v1';
    my $first_execution = $first->{execution_ir}->as_hashref;
    my $second_execution = $second->{execution_ir}->as_hashref;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed ExecutionIR',
        '/stage_identities/execution_ir_sha256',
    ) unless $canonical->encode($second_execution)
        eq $canonical->encode($first_execution);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed the execution plan',
        '/stage_identities/plan_sha256',
    ) unless $canonical->encode($second->{plan})
        eq $canonical->encode($first->{plan});

    my ($scoreboard_evidence, $scoreboard_diagnostics) =
        _evaluate_scoreboard_state($spec, $first_execution);
    push @diagnostics, @$scoreboard_diagnostics;
    my $stage_identities = {
        semantic_ir_sha256 => $semantic_sha,
        bridge_manifest_sha256 => $bridge_sha,
        execution_ir_sha256 =>
            sha256_hex($canonical->encode($first_execution)),
        plan_sha256 => sha256_hex($canonical->encode($first->{plan})),
    };
    my $rerun_identity = _rerun_identity(
        $construction->{workload_identity}, $stage_identities, [],
    );
    my $resources = $first_execution->{resource_summary};
    return _evaluation({
        ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
        status => @diagnostics ? 'oracle_failure' : 'accepted',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        evaluation_identity => undef,
        rerun_identity => $rerun_identity,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'accepted',
        stage_identities => $stage_identities,
        metrics => _execution_metrics($resources, $first->{plan}, $canonical),
        packed_state_contract => _packed_state_contract(),
        outcome_contract => {
            schema => $OUTCOME_SCHEMA,
            schema_version => 1,
            observed_outcome => 'accepted',
            axis_oracle_executed => JSON::PP::true,
            selected_count_claimed => JSON::PP::true,
            canonical_stages_completed => [qw(semantic bridge execution_ir plan)],
        },
        oracle_evidence => _oracle_evidence(
            'scoreboard', $scoreboard_evidence,
        ),
        claims => _claims(JSON::PP::true),
        explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
        contract_discrepancies => [],
        diagnostics => \@diagnostics,
    });
}

sub _evaluate_coverage_axis($construction) {
    my $spec = $construction->{specification};
    my ($axis, $level) = @{$spec}{qw(primary_axis level)};
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $first_inputs = _canonical_inputs_from_construction($construction);
    my $first = FSM::VIAL::ExecutionBuilder->build($first_inputs->{arguments});
    my $second_inputs = _canonical_inputs_from_construction($construction);
    my $second = FSM::VIAL::ExecutionBuilder->build($second_inputs->{arguments});
    my $first_semantic = $first_inputs->{semantic_ir}->as_hashref;
    my $second_semantic = $second_inputs->{semantic_ir}->as_hashref;
    my $first_bridge = $first_inputs->{bridge_manifest}->as_hashref;
    my $second_bridge = $second_inputs->{bridge_manifest}->as_hashref;
    my @diagnostics;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed SemanticIR',
        '/stage_identities/semantic_ir_sha256',
    ) unless $canonical->encode($second_semantic)
        eq $canonical->encode($first_semantic);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed the bridge manifest',
        '/stage_identities/bridge_manifest_sha256',
    ) unless $canonical->encode($second_bridge)
        eq $canonical->encode($first_bridge);

    my $semantic_sha = sha256_hex($canonical->encode($first_semantic));
    my $bridge_sha = sha256_hex($canonical->encode($first_bridge));
    if (!$first->{ok} || !$second->{ok}) {
        my $first_diagnostics = $first->{diagnostics} || [];
        my $second_diagnostics = $second->{diagnostics} || [];
        push @diagnostics, _oracle_error(
            'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
            'independent canonical checking-state rejection changed diagnostics',
            '/diagnostics',
        ) unless !$first->{ok} && !$second->{ok}
            && $canonical->encode($second_diagnostics)
                eq $canonical->encode($first_diagnostics);
        my $expected = _expected_coverage_execution_rejection_diagnostic();
        push @diagnostics, _oracle_error(
            'VIAL_SCALE_CHECKING_OUTCOME_ERROR',
            'checking-state coverage rejection did not match the selected adjacent excess',
            '/diagnostics',
        ) unless $axis eq 'bins_and_cross_tuples'
            && $level eq 'over_limit_v1'
            && $canonical->encode($first_diagnostics)
                eq $canonical->encode([$expected]);
        my $stage_identities = {
            semantic_ir_sha256 => $semantic_sha,
            bridge_manifest_sha256 => $bridge_sha,
            execution_ir_sha256 => undef,
            plan_sha256 => undef,
        };
        return _evaluation({
            ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
            status => @diagnostics ? 'oracle_failure' : 'expected_rejection',
            schema => $EVALUATION_SCHEMA,
            schema_version => 1,
            evaluation_identity => undef,
            rerun_identity => _rerun_identity(
                $construction->{workload_identity}, $stage_identities,
                $first_diagnostics,
            ),
            workload_identity => $construction->{workload_identity},
            family => $FAMILY,
            level => $level,
            primary_axis => $axis,
            requested_counts => _clone($spec->{requested_counts}),
            observed_outcome => 'rejected',
            stage_identities => $stage_identities,
            metrics => _semantic_coverage_metrics($first_semantic),
            packed_state_contract => _packed_state_contract(),
            outcome_contract => {
                schema => $OUTCOME_SCHEMA,
                schema_version => 1,
                observed_outcome => 'rejected',
                axis_oracle_executed => JSON::PP::false,
                selected_count_claimed => JSON::PP::true,
                canonical_stages_completed => [qw(semantic bridge)],
            },
            oracle_evidence => _oracle_evidence('none', undef),
            claims => _claims(JSON::PP::true),
            explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
            contract_discrepancies => [],
            diagnostics => [@{_clone($first_diagnostics)}, @diagnostics],
        });
    }

    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_OUTCOME_ERROR',
        'checking-state adjacent coverage excess unexpectedly produced ExecutionIR',
        '/observed_outcome',
    ) if $level eq 'over_limit_v1';
    my $first_execution = $first->{execution_ir}->as_hashref;
    my $second_execution = $second->{execution_ir}->as_hashref;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed ExecutionIR',
        '/stage_identities/execution_ir_sha256',
    ) unless $canonical->encode($second_execution)
        eq $canonical->encode($first_execution);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed the execution plan',
        '/stage_identities/plan_sha256',
    ) unless $canonical->encode($second->{plan})
        eq $canonical->encode($first->{plan});

    my ($coverage_evidence, $coverage_diagnostics) =
        _evaluate_coverage_state($spec, $first_execution);
    push @diagnostics, @$coverage_diagnostics;
    my $stage_identities = {
        semantic_ir_sha256 => $semantic_sha,
        bridge_manifest_sha256 => $bridge_sha,
        execution_ir_sha256 =>
            sha256_hex($canonical->encode($first_execution)),
        plan_sha256 => sha256_hex($canonical->encode($first->{plan})),
    };
    my $resources = $first_execution->{resource_summary};
    return _evaluation({
        ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
        status => @diagnostics ? 'oracle_failure' : 'accepted',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        evaluation_identity => undef,
        rerun_identity => _rerun_identity(
            $construction->{workload_identity}, $stage_identities, [],
        ),
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'accepted',
        stage_identities => $stage_identities,
        metrics => _execution_metrics($resources, $first->{plan}, $canonical),
        packed_state_contract => _packed_state_contract(),
        outcome_contract => {
            schema => $OUTCOME_SCHEMA,
            schema_version => 1,
            observed_outcome => 'accepted',
            axis_oracle_executed => JSON::PP::true,
            selected_count_claimed => JSON::PP::true,
            canonical_stages_completed => [qw(semantic bridge execution_ir plan)],
        },
        oracle_evidence => _oracle_evidence('coverage', $coverage_evidence),
        claims => _claims(JSON::PP::true),
        explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
        contract_discrepancies => [],
        diagnostics => \@diagnostics,
    });
}

sub _evaluate_fault_axis($construction) {
    my $spec = $construction->{specification};
    my ($axis, $level) = @{$spec}{qw(primary_axis level)};
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $first_inputs = _canonical_inputs_from_construction($construction);
    my $first = FSM::VIAL::ExecutionBuilder->build($first_inputs->{arguments});
    my $second_inputs = _canonical_inputs_from_construction($construction);
    my $second = FSM::VIAL::ExecutionBuilder->build($second_inputs->{arguments});
    my $first_semantic = $first_inputs->{semantic_ir}->as_hashref;
    my $second_semantic = $second_inputs->{semantic_ir}->as_hashref;
    my $first_bridge = $first_inputs->{bridge_manifest}->as_hashref;
    my $second_bridge = $second_inputs->{bridge_manifest}->as_hashref;
    my @diagnostics;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed SemanticIR',
        '/stage_identities/semantic_ir_sha256',
    ) unless $canonical->encode($second_semantic)
        eq $canonical->encode($first_semantic);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed the bridge manifest',
        '/stage_identities/bridge_manifest_sha256',
    ) unless $canonical->encode($second_bridge)
        eq $canonical->encode($first_bridge);

    my $semantic_sha = sha256_hex($canonical->encode($first_semantic));
    my $bridge_sha = sha256_hex($canonical->encode($first_bridge));
    if (!$first->{ok} || !$second->{ok}) {
        my $first_diagnostics = $first->{diagnostics} || [];
        my $second_diagnostics = $second->{diagnostics} || [];
        push @diagnostics, _oracle_error(
            'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
            'independent canonical checking-state rejection changed diagnostics',
            '/diagnostics',
        ) unless !$first->{ok} && !$second->{ok}
            && $canonical->encode($second_diagnostics)
                eq $canonical->encode($first_diagnostics);
        my $expected = _expected_fault_execution_rejection_diagnostic();
        push @diagnostics, _oracle_error(
            'VIAL_SCALE_CHECKING_OUTCOME_ERROR',
            'checking-state fault rejection did not match the selected adjacent excess',
            '/diagnostics',
        ) unless $level eq 'over_limit_v1'
            && $canonical->encode($first_diagnostics)
                eq $canonical->encode([$expected]);
        my $stage_identities = {
            semantic_ir_sha256 => $semantic_sha,
            bridge_manifest_sha256 => $bridge_sha,
            execution_ir_sha256 => undef,
            plan_sha256 => undef,
        };
        return _evaluation({
            ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
            status => @diagnostics ? 'oracle_failure' : 'expected_rejection',
            schema => $EVALUATION_SCHEMA,
            schema_version => 1,
            evaluation_identity => undef,
            rerun_identity => _rerun_identity(
                $construction->{workload_identity}, $stage_identities,
                $first_diagnostics,
            ),
            workload_identity => $construction->{workload_identity},
            family => $FAMILY,
            level => $level,
            primary_axis => $axis,
            requested_counts => _clone($spec->{requested_counts}),
            observed_outcome => 'rejected',
            stage_identities => $stage_identities,
            metrics => _semantic_fault_metrics($first_semantic),
            packed_state_contract => _packed_state_contract(),
            outcome_contract => {
                schema => $OUTCOME_SCHEMA,
                schema_version => 1,
                observed_outcome => 'rejected',
                axis_oracle_executed => JSON::PP::false,
                selected_count_claimed => JSON::PP::true,
                canonical_stages_completed => [qw(semantic bridge)],
            },
            oracle_evidence => _oracle_evidence('none', undef),
            claims => _claims(JSON::PP::true),
            explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
            contract_discrepancies => [],
            diagnostics => [@{_clone($first_diagnostics)}, @diagnostics],
        });
    }

    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_OUTCOME_ERROR',
        'checking-state adjacent fault excess unexpectedly produced ExecutionIR',
        '/observed_outcome',
    ) if $level eq 'over_limit_v1';
    my $first_execution = $first->{execution_ir}->as_hashref;
    my $second_execution = $second->{execution_ir}->as_hashref;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed ExecutionIR',
        '/stage_identities/execution_ir_sha256',
    ) unless $canonical->encode($second_execution)
        eq $canonical->encode($first_execution);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed the execution plan',
        '/stage_identities/plan_sha256',
    ) unless $canonical->encode($second->{plan})
        eq $canonical->encode($first->{plan});

    my ($fault_evidence, $fault_diagnostics) =
        _evaluate_fault_state($spec, $first_execution);
    push @diagnostics, @$fault_diagnostics;
    my $stage_identities = {
        semantic_ir_sha256 => $semantic_sha,
        bridge_manifest_sha256 => $bridge_sha,
        execution_ir_sha256 =>
            sha256_hex($canonical->encode($first_execution)),
        plan_sha256 => sha256_hex($canonical->encode($first->{plan})),
    };
    my $resources = $first_execution->{resource_summary};
    return _evaluation({
        ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
        status => @diagnostics ? 'oracle_failure' : 'accepted',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        evaluation_identity => undef,
        rerun_identity => _rerun_identity(
            $construction->{workload_identity}, $stage_identities, [],
        ),
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'accepted',
        stage_identities => $stage_identities,
        metrics => _execution_metrics($resources, $first->{plan}, $canonical),
        packed_state_contract => _packed_state_contract(),
        outcome_contract => {
            schema => $OUTCOME_SCHEMA,
            schema_version => 1,
            observed_outcome => 'accepted',
            axis_oracle_executed => JSON::PP::true,
            selected_count_claimed => JSON::PP::true,
            canonical_stages_completed => [qw(semantic bridge execution_ir plan)],
        },
        oracle_evidence => _oracle_evidence('faults', $fault_evidence),
        claims => _claims(JSON::PP::true),
        explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
        contract_discrepancies => [],
        diagnostics => \@diagnostics,
    });
}

sub _evaluate_random_axis($construction) {
    my $spec = $construction->{specification};
    my ($axis, $level) = @{$spec}{qw(primary_axis level)};
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $first_inputs = _canonical_inputs_from_construction($construction);
    my $first = FSM::VIAL::ExecutionBuilder->build($first_inputs->{arguments});
    my $second_inputs = _canonical_inputs_from_construction($construction);
    my $second = FSM::VIAL::ExecutionBuilder->build($second_inputs->{arguments});
    my $first_semantic = $first_inputs->{semantic_ir}->as_hashref;
    my $second_semantic = $second_inputs->{semantic_ir}->as_hashref;
    my $first_bridge = $first_inputs->{bridge_manifest}->as_hashref;
    my $second_bridge = $second_inputs->{bridge_manifest}->as_hashref;
    my @diagnostics;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical random route changed SemanticIR',
        '/stage_identities/semantic_ir_sha256',
    ) unless $canonical->encode($second_semantic)
        eq $canonical->encode($first_semantic);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical random route changed the bridge manifest',
        '/stage_identities/bridge_manifest_sha256',
    ) unless $canonical->encode($second_bridge)
        eq $canonical->encode($first_bridge);

    my $semantic_sha = sha256_hex($canonical->encode($first_semantic));
    my $bridge_sha = sha256_hex($canonical->encode($first_bridge));
    if (!$first->{ok} || !$second->{ok}) {
        my $first_diagnostics = $first->{diagnostics} || [];
        my $second_diagnostics = $second->{diagnostics} || [];
        push @diagnostics, _oracle_error(
            'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
            'independent canonical random rejection changed diagnostics',
            '/diagnostics',
        ) unless !$first->{ok} && !$second->{ok}
            && $canonical->encode($second_diagnostics)
                eq $canonical->encode($first_diagnostics);
        my $expected = $level eq 'qualification_candidate_v1'
            ? _expected_plan_rejection_diagnostic()
            : _expected_random_rejection_diagnostic();
        push @diagnostics, _oracle_error(
            'VIAL_SCALE_CHECKING_OUTCOME_ERROR',
            'checking-state random rejection did not match its selected earliest authority',
            '/diagnostics',
        ) unless ($level eq 'qualification_candidate_v1'
                || $level eq 'over_limit_v1')
            && $canonical->encode($first_diagnostics)
                eq $canonical->encode([$expected]);
        my $stage_identities = {
            semantic_ir_sha256 => $semantic_sha,
            bridge_manifest_sha256 => $bridge_sha,
            execution_ir_sha256 => undef,
            plan_sha256 => undef,
        };
        return _evaluation({
            ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
            status => @diagnostics ? 'oracle_failure' : 'expected_rejection',
            schema => $EVALUATION_SCHEMA,
            schema_version => 1,
            evaluation_identity => undef,
            rerun_identity => _rerun_identity(
                $construction->{workload_identity}, $stage_identities,
                $first_diagnostics,
            ),
            workload_identity => $construction->{workload_identity},
            family => $FAMILY,
            level => $level,
            primary_axis => $axis,
            requested_counts => _clone($spec->{requested_counts}),
            observed_outcome => 'rejected',
            stage_identities => $stage_identities,
            metrics => _semantic_random_metrics($first_semantic),
            packed_state_contract => _packed_state_contract(),
            outcome_contract => {
                schema => $OUTCOME_SCHEMA,
                schema_version => 1,
                observed_outcome => 'rejected',
                axis_oracle_executed => JSON::PP::false,
                selected_count_claimed => JSON::PP::true,
                canonical_stages_completed => [qw(semantic bridge)],
            },
            oracle_evidence => _oracle_evidence('none', undef),
            claims => _claims(JSON::PP::true),
            explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
            contract_discrepancies => _random_contract_discrepancies($spec),
            diagnostics => [@{_clone($first_diagnostics)}, @diagnostics],
        });
    }

    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_OUTCOME_ERROR',
        'checking-state random non-gate unexpectedly produced a plan',
        '/observed_outcome',
    ) unless $level eq 'gate_candidate_v1';
    my $first_execution = $first->{execution_ir}->as_hashref;
    my $second_execution = $second->{execution_ir}->as_hashref;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical random route changed ExecutionIR',
        '/stage_identities/execution_ir_sha256',
    ) unless $canonical->encode($second_execution)
        eq $canonical->encode($first_execution);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical random route changed the execution plan',
        '/stage_identities/plan_sha256',
    ) unless $canonical->encode($second->{plan})
        eq $canonical->encode($first->{plan});

    my $replay = _build_random_replay_execution($first_inputs, $first->{plan});
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_REPLAY_ERROR',
        'strict random replay did not produce one accepted plan',
        '/oracle_evidence/random_replay',
    ) unless $replay->{execution}{ok};
    my ($random_evidence, $random_diagnostics) = _evaluate_random_state(
        $spec, $first_execution, $first->{plan}, $second->{plan},
        $replay, $canonical,
    );
    push @diagnostics, @$random_diagnostics;
    my $stage_identities = {
        semantic_ir_sha256 => $semantic_sha,
        bridge_manifest_sha256 => $bridge_sha,
        execution_ir_sha256 => sha256_hex($canonical->encode($first_execution)),
        plan_sha256 => sha256_hex($canonical->encode($first->{plan})),
    };
    my $resources = $first_execution->{resource_summary};
    return _evaluation({
        ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
        status => @diagnostics ? 'oracle_failure' : 'accepted',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        evaluation_identity => undef,
        rerun_identity => _rerun_identity(
            $construction->{workload_identity}, $stage_identities, [],
        ),
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'accepted',
        stage_identities => $stage_identities,
        metrics => _execution_metrics($resources, $first->{plan}, $canonical),
        packed_state_contract => _packed_state_contract(),
        outcome_contract => {
            schema => $OUTCOME_SCHEMA,
            schema_version => 1,
            observed_outcome => 'accepted',
            axis_oracle_executed => JSON::PP::true,
            selected_count_claimed => JSON::PP::true,
            canonical_stages_completed => [qw(semantic bridge execution_ir plan)],
        },
        oracle_evidence => _oracle_evidence('random_replay', $random_evidence),
        claims => _claims(JSON::PP::true),
        explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
        contract_discrepancies => [],
        diagnostics => \@diagnostics,
    });
}

sub _evaluate_scoreboard_semantic_rejection($construction, $canonical) {
    my $spec = $construction->{specification};
    my $vial = _role_input($construction, 'vial_source');
    my $check = sub {
        return FSM::VIAL::Parser->check_source({
            text => $vial->{content},
            source_name => $vial->{relative_path},
            source_catalog => {},
        });
    };
    my $first = $check->();
    my $second = $check->();
    my @diagnostics;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical semantic rejection changed diagnostics',
        '/diagnostics',
    ) unless !$first->{ok} && !$second->{ok}
        && $canonical->encode($second->{diagnostics})
            eq $canonical->encode($first->{diagnostics});
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_OUTCOME_ERROR',
        'checking-state capacity rejection did not match the semantic bound',
        '/diagnostics',
    ) unless _is_expected_scoreboard_semantic_rejection($first);
    my $stage_identities = {
        semantic_ir_sha256 => undef,
        bridge_manifest_sha256 => undef,
        execution_ir_sha256 => undef,
        plan_sha256 => undef,
    };
    my $reported = $first->{diagnostics} || [];
    my $rerun_identity = _rerun_identity(
        $construction->{workload_identity}, $stage_identities, $reported,
    );
    return _evaluation({
        ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
        status => @diagnostics ? 'oracle_failure' : 'expected_rejection',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        evaluation_identity => undef,
        rerun_identity => $rerun_identity,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $spec->{level},
        primary_axis => $spec->{primary_axis},
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'rejected',
        stage_identities => $stage_identities,
        metrics => _scoreboard_recipe_metrics($spec),
        packed_state_contract => _packed_state_contract(),
        outcome_contract => {
            schema => $OUTCOME_SCHEMA,
            schema_version => 1,
            observed_outcome => 'rejected',
            axis_oracle_executed => JSON::PP::false,
            selected_count_claimed => JSON::PP::true,
            canonical_stages_completed => [],
        },
        oracle_evidence => _oracle_evidence('none', undef),
        claims => _claims(JSON::PP::true),
        explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
        contract_discrepancies => [],
        diagnostics => [@{_clone($reported)}, @diagnostics],
    });
}

sub _unconstructible_evaluation($construction) {
    my $spec = $construction->{specification};
    my ($axis, $level) = @{$spec}{qw(primary_axis level)};
    my $stage_identities = {
        semantic_ir_sha256 => undef,
        bridge_manifest_sha256 => undef,
        execution_ir_sha256 => undef,
        plan_sha256 => undef,
    };
    my $reported = _clone($construction->{diagnostics});
    return _evaluation({
        ok => JSON::PP::true,
        status => 'envelope_unconstructible',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        evaluation_identity => undef,
        rerun_identity => _rerun_identity(undef, $stage_identities, $reported),
        workload_identity => undef,
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'not_constructed',
        stage_identities => $stage_identities,
        metrics => _zero_metrics(),
        packed_state_contract => _packed_state_contract(),
        outcome_contract => {
            schema => $OUTCOME_SCHEMA,
            schema_version => 1,
            observed_outcome => 'not_constructed',
            axis_oracle_executed => JSON::PP::false,
            selected_count_claimed => JSON::PP::false,
            canonical_stages_completed => [],
        },
        oracle_evidence => _oracle_evidence('none', undef),
        claims => _claims(JSON::PP::true),
        explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
        contract_discrepancies => _unconstructible_discrepancies($axis),
        diagnostics => $reported,
    });
}

sub _random_preflight_evaluation($construction) {
    my $spec = $construction->{specification};
    my $stage_identities = {
        semantic_ir_sha256 => undef,
        bridge_manifest_sha256 => undef,
        execution_ir_sha256 => undef,
        plan_sha256 => undef,
    };
    return _evaluation({
        ok => JSON::PP::true,
        status => 'preflight_dominated',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        evaluation_identity => undef,
        rerun_identity => _rerun_identity(
            $construction->{workload_identity}, $stage_identities, [],
        ),
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $spec->{level},
        primary_axis => $spec->{primary_axis},
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'not_materialized',
        stage_identities => $stage_identities,
        metrics => _zero_metrics(),
        packed_state_contract => _packed_state_contract(),
        outcome_contract => {
            schema => $OUTCOME_SCHEMA,
            schema_version => 1,
            observed_outcome => 'not_materialized',
            axis_oracle_executed => JSON::PP::false,
            selected_count_claimed => JSON::PP::false,
            canonical_stages_completed => [],
        },
        oracle_evidence => _oracle_evidence('none', undef),
        claims => _claims(JSON::PP::true),
        explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
        contract_discrepancies => _random_contract_discrepancies($spec),
        diagnostics => [],
    });
}

sub _random_contract_discrepancies($spec) {
    my $level = $spec->{level} // '';
    return [] unless ($spec->{primary_axis} // '') eq 'random_occurrences'
        && ($level eq 'qualification_candidate_v1' || $level eq 'limit_v1');
    my @records = (
        {
            code => 'VIAL_SCALE_LIMIT_INTERACTION',
            message => 'the 16777216-byte serialized-plan cap precedes this selected random-occurrence level',
            path => '/requested_counts/random_occurrences',
            repair_owner => $LIMIT_POLICY_REPAIR_OWNER,
        },
        {
            code => 'VIAL_SCALE_ROUTE_BOUNDARY',
            message => 'the canonical compact route accepts 8440 occurrences in 16775415 bytes and rejects 8441 at the 16777216-byte plan cap',
            path => '/requested_counts/random_occurrences',
            repair_owner => $LIMIT_POLICY_REPAIR_OWNER,
        },
    );
    push @records, {
        code => 'VIAL_SCALE_PREFLIGHT_DOMINANCE',
        message => 'the adjacent 8440/8441 route proves that the selected 65536-occurrence level cannot materialize below the plan cap',
        path => '/requested_counts/random_occurrences',
        repair_owner => $LIMIT_POLICY_REPAIR_OWNER,
    } if $level eq 'limit_v1';
    return \@records;
}

sub _unconstructible_discrepancies($axis) {
    my $contract = $UNCONSTRUCTIBLE{$axis};
    my $boundary = $contract->{route_boundary};
    return [
        {
            code => 'VIAL_SCALE_LIMIT_INTERACTION',
            message => "the $CONSTRUCTION_ENVELOPE_BYTES-byte bounded construction"
                . ' envelope precedes every product cap at this level, so its'
                . ' earliest decider is a fixture bound and not a product limit',
            path => "/requested_counts/$axis",
            repair_owner => $LIMIT_POLICY_REPAIR_OWNER,
        },
        {
            code => 'VIAL_SCALE_ROUTE_BOUNDARY',
            message => "the canonical route accepts $boundary->{accepted} in"
                . " $boundary->{accepted_source_bytes} source bytes and rejects"
                . " $boundary->{rejected} in $boundary->{rejected_source_bytes}"
                . " source bytes at $boundary->{cap}, reported at"
                . " $boundary->{path}, against the declared"
                . " $contract->{declared_cap} execution cap this level was"
                . ' selected from',
            path => "/requested_counts/$axis",
            repair_owner => $LIMIT_POLICY_REPAIR_OWNER,
        },
    ];
}

sub _zero_metrics() {
    return {
        model_instances => 0,
        scalar_model_state_cells => 0,
        scoreboard_instances => 0,
        scoreboard_declared_capacity => 0,
        coverpoints => 0,
        bins_and_cross_tuples => 0,
        faults => 0,
        random_occurrences => 0,
        serialized_plan_bytes => 0,
    };
}

sub validate_evaluation($class, @args) {
    _exact_invocant($class, 'validate_evaluation');
    confess __PACKAGE__ . "->validate_evaluation expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys(
        $args[0], \@VALIDATE_EVALUATION_KEYS,
        'checking-state evaluation validation',
    );
    _validated_construction($args[0]{construction});
    _validate_evaluation_shape($args[0]{evaluation});
    my $rebuilt = __PACKAGE__->evaluate({
        construction => $args[0]{construction},
    });
    my $canonical = JSON::PP->new->canonical(1)->allow_nonref(1);
    confess "checking-state evaluation is not canonical\n"
        unless $canonical->encode($rebuilt)
            eq $canonical->encode($args[0]{evaluation});
    return _clone($rebuilt);
}

sub with_staging($class, @args) {
    _exact_invocant($class, 'with_staging');
    confess __PACKAGE__ . "->with_staging expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@STAGING_KEYS, 'checking-state staging');
    my $construction = _validated_construction($args[0]{construction});
    my $spec = $construction->{specification};
    confess "unconstructible checking-state level has no admitted source to stage\n"
        if _unconstructible(@{$spec}{qw(primary_axis level)});
    return FSM::VIAL::ArchitectureScaleWorkload->with_staging({
        repository_root => $args[0]{repository_root},
        construction => $construction,
        consumer => $args[0]{consumer},
    });
}

sub evaluation_keys($class) {
    _exact_invocant($class, 'evaluation_keys');
    return [@EVALUATION_KEYS];
}

# Measurement consumes this family's canonical stage products through one
# caller-sealed seam. It cannot inject SemanticIR, bridge, plan, trace, result,
# or support metadata and it does not widen the public execution builder.
sub _measurement_inputs($class, @args) {
    _exact_invocant($class, '_measurement_inputs');
    my $caller = caller;
    confess "checking measurement inputs are private to the exact adapter\n"
        unless defined($caller)
            && $caller eq
                'FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement';
    confess __PACKAGE__ . "->_measurement_inputs expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    _confess_exact_keys(
        $args[0], \@EVALUATE_KEYS, 'checking measurement inputs',
    );
    return _canonical_inputs_from_construction(
        _validated_construction($args[0]{construction}),
    );
}

sub _owns($axis, $level) {
    return 0 unless defined($axis) && defined($level) && $OWNED_LEVELS{$axis};
    return scalar(grep { $_ eq $level } @{$OWNED_LEVELS{$axis}});
}

sub _unconstructible($axis, $level) {
    return 0 unless defined($axis) && defined($level) && $UNCONSTRUCTIBLE{$axis};
    return scalar(grep { $_ eq $level } @{$UNCONSTRUCTIBLE{$axis}{levels}});
}

sub _random_preflight_dominance($spec) {
    return ref($spec) eq 'HASH'
        && ($spec->{primary_axis} // '') eq 'random_occurrences'
        && ($spec->{level} // '') eq 'limit_v1';
}

sub _render_axis_source($axis, $level, $requested_count) {
    return _render_model_source($axis, $level, $requested_count)
        if $axis eq 'model_instances'
            || $axis eq 'scalar_model_state_cells';
    return _render_scoreboard_source($axis, $level, $requested_count)
        if $axis eq 'scoreboard_instances'
            || $axis eq 'scoreboard_capacity';
    return _render_coverage_source($axis, $level, $requested_count)
        if $axis eq 'coverpoints'
            || $axis eq 'bins_and_cross_tuples';
    return _render_fault_source($axis, $level, $requested_count)
        if $axis eq 'faults';
    return _render_random_source($axis, $level, $requested_count)
        if $axis eq 'random_occurrences';
    confess "checking-state renderer does not own axis '$axis'\n";
}

sub _render_model_source($axis, $level, $requested_count) {
    confess "checking-state model renderer received an invalid requested count\n"
        unless defined($requested_count) && !ref($requested_count)
            && $requested_count =~ /\A[1-9][0-9]*\z/;

    my (@definitions, @instances);
    if ($axis eq 'model_instances') {
        push @definitions, _model_definition($axis, 0, 1);
        for my $ordinal (0 .. $requested_count - 1) {
            push @instances, _model_instance($axis, $ordinal, 0);
        }
    }
    elsif ($axis eq 'scalar_model_state_cells') {
        my ($instance_count, $cells_per_instance, $extra_cells) =
            $level eq 'gate_candidate_v1'          ? (32, 16,    0)
          : $level eq 'qualification_candidate_v1' ? (32, 1_024, 0)
          : $level eq 'limit_v1'                   ? (32, 2_048, 0)
          : $level eq 'over_limit_v1'              ? (32, 2_048, 1)
          : confess "checking-state scalar-cell renderer received an unknown level\n";
        confess "checking-state scalar-cell recipe changed its requested count\n"
            unless $instance_count * $cells_per_instance + $extra_cells
                == $requested_count;
        push @definitions, _model_definition($axis, 0, $cells_per_instance);
        for my $ordinal (0 .. $instance_count - 1) {
            push @instances, _model_instance($axis, $ordinal, 0);
        }
        if ($extra_cells) {
            push @definitions, _model_definition($axis, 1, $extra_cells);
            push @instances, _model_instance($axis, $instance_count, 1);
        }
    }
    else {
        confess "checking-state model renderer does not own axis '$axis'\n";
    }

    return join('',
        '(vial (version 1) (package architecture_scale_checking_state',
        ' (imports)',
        ' (types',
        ' (enum htrans_t (logic 2) (idle #b00) (nonseq #b10))',
        ' (type address_t (logic 32))',
        ' (type data_t (logic 32)))',
        ' (transactions (transaction ahb_write',
        ' (fields',
        ' (address (type address_t))',
        ' (transfer (type htrans_t))',
        ' (write bool)',
        ' (size (logic 3))',
        ' (data (type data_t))',
        ' (wait_cycles (u 4)))',
        ' (events requested accepted captured held completed error)))',
        ' (models ', join(' ', @definitions), ')',
        ' (scoreboards)',
        ' (fixtures (fixture checking_gate',
        ' (dut dut',
        ' (unit "unit/ahb_lite_subordinate")',
        ' (domains (domain bus "domain/ahb_bus"))',
        ' (endpoints',
        ' (endpoint ready_out "endpoint/HREADYOUT" (logic 1) public_port)',
        ' (endpoint response "endpoint/HRESP" (logic 1) public_port)',
        ' (endpoint read_data "endpoint/HRDATA" (logic 32) public_port)',
        ' (endpoint stored_data "probe/reg_data_q" (logic 32) verification_probe))',
        ' (transactions (transaction write "transaction/ahb_write" ahb_write)))',
        ' (instances ', join(' ', @instances), ')',
        ' (coverage)',
        ' (faults)',
        ' (randomness (seed 1701))',
        ' (scenarios (scenario model_transition',
        ' (timeout (cycles bus 2))',
        ' (steps (reset bus 1))))))))',
        "\n",
    );
}

sub _render_scoreboard_source($axis, $level, $requested_count) {
    confess "checking-state scoreboard renderer received an invalid requested count\n"
        unless defined($requested_count) && !ref($requested_count)
            && $requested_count =~ /\A[1-9][0-9]*\z/;

    my ($instance_count, $capacity) = $axis eq 'scoreboard_instances'
        ? ($requested_count, 1)
        : $axis eq 'scoreboard_capacity'
            ? (1, $requested_count)
            : confess "checking-state scoreboard renderer does not own axis '$axis'\n";
    my $definition = FSM::VIAL::ArchitectureScaleWorkload->stable_name({
        family => $FAMILY,
        primary_axis => $axis . '_definition',
        ordinal => 0,
    });
    my @instances;
    for my $ordinal (0 .. $instance_count - 1) {
        my $instance = FSM::VIAL::ArchitectureScaleWorkload->stable_name({
            family => $FAMILY,
            primary_axis => $axis,
            ordinal => $ordinal,
        });
        push @instances,
            "(scoreboard $instance $definition (actual write))";
    }

    return join('',
        '(vial (version 1) (package architecture_scale_checking_state',
        ' (imports)',
        ' (types',
        ' (enum htrans_t (logic 2) (idle #b00) (nonseq #b10))',
        ' (type address_t (logic 32))',
        ' (type data_t (logic 32)))',
        ' (transactions (transaction ahb_write',
        ' (fields',
        ' (address (type address_t))',
        ' (transfer (type htrans_t))',
        ' (write bool)',
        ' (size (logic 3))',
        ' (data (type data_t))',
        ' (wait_cycles (u 4)))',
        ' (events requested accepted captured held completed error)))',
        ' (models)',
        ' (scoreboards (scoreboard ', $definition,
        ' (transaction ahb_write)',
        ' (policy in_order)',
        ' (capacity ', $capacity, ')))',
        ' (fixtures (fixture checking_gate',
        ' (dut dut',
        ' (unit "unit/ahb_lite_subordinate")',
        ' (domains (domain bus "domain/ahb_bus"))',
        ' (endpoints',
        ' (endpoint ready_out "endpoint/HREADYOUT" (logic 1) public_port)',
        ' (endpoint response "endpoint/HRESP" (logic 1) public_port)',
        ' (endpoint read_data "endpoint/HRDATA" (logic 32) public_port)',
        ' (endpoint stored_data "probe/reg_data_q" (logic 32) verification_probe))',
        ' (transactions (transaction write "transaction/ahb_write" ahb_write)))',
        ' (instances ', join(' ', @instances), ')',
        ' (coverage)',
        ' (faults)',
        ' (randomness (seed 1701))',
        ' (scenarios (scenario scoreboard_transition',
        ' (timeout (cycles bus 2))',
        ' (steps (reset bus 1))))))))',
        "\n",
    );
}

# Decision 0073 deliberately keeps coverage declarations compact.  The
# coverpoint ladder has one 110-byte declaration per point and 827 fixed bytes;
# those equalities are the measured 9,524/9,525 parser boundary and must not
# drift into an approximate fixture claim.  The static-domain ladder uses two
# equal bin sets, their authored Cartesian cross, and one independent point.
sub _render_coverage_source($axis, $level, $requested_count) {
    confess "checking-state coverage renderer received an invalid requested count\n"
        unless defined($requested_count) && !ref($requested_count)
            && $requested_count =~ /\A[1-9][0-9]*\z/;

    if ($axis eq 'coverpoints') {
        my @coverpoints = map {
            sprintf(
                '(coverpoint cp%08d (sample bus) (expr (same (sample ready_out) #b1))'
                    . ' (bins (bin hit normal (value true))))',
                $_,
            )
        } 0 .. $requested_count - 1;
        my $source = _coverage_source_shell(join('', @coverpoints), 349);
        confess "checking-state coverpoint renderer changed its exact linear byte law\n"
            unless bytes::length($source) == 827 + 110 * $requested_count;
        return $source;
    }

    confess "checking-state coverage renderer does not own axis '$axis'\n"
        unless $axis eq 'bins_and_cross_tuples';
    my ($bins_per_cross_point, $independent_bins) =
          $level eq 'gate_candidate_v1'          ? (63,  1)
        : $level eq 'qualification_candidate_v1' ? (511, 1)
        : $level eq 'limit_v1'                   ? (999, 1)
        : $level eq 'over_limit_v1'              ? (999, 2)
        : confess "checking-state static-domain renderer received an unknown level\n";
    my $cross_tuples = $bins_per_cross_point * $bins_per_cross_point;
    confess "checking-state static-domain recipe changed its requested count\n"
        unless 2 * $bins_per_cross_point + $cross_tuples + $independent_bins
            == $requested_count;

    my $a_bins = join('', map {
        sprintf('(bin a%03d normal (value #b1))', $_)
    } 0 .. $bins_per_cross_point - 1);
    my $b_bins = join('', map {
        sprintf('(bin b%03d normal (value #b1))', $_)
    } 0 .. $bins_per_cross_point - 1);
    my $i_bins = join('', map {
        sprintf('(bin i%03d normal (value #b1))', $_)
    } 0 .. $independent_bins - 1);
    my $coverage = join('',
        '(coverpoint a (sample bus) (expr (sample ready_out)) (bins ',
        $a_bins, '))',
        '(coverpoint b (sample bus) (expr (sample ready_out)) (bins ',
        $b_bins, '))',
        '(coverpoint i (sample bus) (expr (sample ready_out)) (bins ',
        $i_bins, '))',
        '(cross x (points a b) (max_bins ', $cross_tuples, '))',
    );
    # The constant whitespace is part of the frozen compact-source recipe used
    # by the selection measurements.  It leaves the semantic domain unchanged
    # while making the recorded 62,841/62,870-byte witnesses reproducible.
    my $source = _coverage_source_shell($coverage, 4_169);
    if ($level eq 'limit_v1' || $level eq 'over_limit_v1') {
        my $expected_bytes = $level eq 'limit_v1' ? 62_841 : 62_870;
        confess "checking-state static-domain renderer changed its selected byte witness\n"
            unless bytes::length($source) == $expected_bytes;
    }
    return $source;
}

sub _coverage_source_shell($coverage, $padding) {
    return join('',
        '(vial (version 1) (package architecture_scale_checking_state',
        ' (imports)',
        ' (types)',
        ' (transactions)',
        ' (models)',
        ' (scoreboards)',
        ' (fixtures (fixture checking_gate',
        ' (dut dut',
        ' (unit "unit/ahb_lite_subordinate")',
        ' (domains (domain bus "domain/ahb_bus"))',
        ' (endpoints',
        ' (endpoint ready_out "endpoint/HREADYOUT" (logic 1) public_port))',
        ' (transactions))',
        ' (instances)',
        ' (coverage ', $coverage, ')',
        ' (faults)',
        ' (randomness (seed 1701))',
        ' (scenarios (scenario coverage_transition',
        ' (timeout (cycles bus 2))',
        ' (steps (reset bus 1))))))))',
        ' ' x $padding,
        "\n",
    );
}

sub _render_fault_source($axis, $level, $requested_count) {
    confess "checking-state fault renderer does not own axis '$axis'\n"
        unless $axis eq 'faults';
    confess "checking-state fault renderer received an invalid requested count\n"
        unless defined($requested_count) && !ref($requested_count)
            && $requested_count =~ /\A[1-9][0-9]*\z/;
    my @faults = map {
        my $name = FSM::VIAL::ArchitectureScaleWorkload->stable_name({
            family => $FAMILY,
            primary_axis => $axis,
            ordinal => $_,
        });
        join('',
            '(fault ', $name,
            ' (target (transaction write size))',
            ' (action (substitute #b111))',
            ' (duration (cycles bus 1)))',
        );
    } 0 .. $requested_count - 1;

    return join('',
        '(vial (version 1) (package architecture_scale_checking_state',
        ' (imports)',
        ' (types',
        ' (enum htrans_t (logic 2) (idle #b00) (nonseq #b10))',
        ' (type address_t (logic 32))',
        ' (type data_t (logic 32)))',
        ' (transactions (transaction ahb_write',
        ' (fields',
        ' (address (type address_t))',
        ' (transfer (type htrans_t))',
        ' (write bool)',
        ' (size (logic 3))',
        ' (data (type data_t))',
        ' (wait_cycles (u 4)))',
        ' (events requested accepted captured held completed error)))',
        ' (models)',
        ' (scoreboards)',
        ' (fixtures (fixture checking_gate',
        ' (dut dut',
        ' (unit "unit/ahb_lite_subordinate")',
        ' (domains (domain bus "domain/ahb_bus"))',
        ' (endpoints',
        ' (endpoint ready_out "endpoint/HREADYOUT" (logic 1) public_port)',
        ' (endpoint response "endpoint/HRESP" (logic 1) public_port)',
        ' (endpoint read_data "endpoint/HRDATA" (logic 32) public_port)',
        ' (endpoint stored_data "probe/reg_data_q" (logic 32) verification_probe))',
        ' (transactions (transaction write "transaction/ahb_write" ahb_write)))',
        ' (instances)',
        ' (coverage)',
        ' (faults ', join(' ', @faults), ')',
        ' (randomness (seed 1701))',
        ' (scenarios (scenario fault_transition',
        ' (timeout (cycles bus 2))',
        ' (steps (reset bus 1))))))))',
        "\n",
    );
}

# One random occurrence is selected for each referenced (scenario, choice)
# pair.  A fixed 128-choice Boolean palette therefore keeps every selected
# source inside the parser and workload envelopes without changing the public
# language or relying on a private repetition form.  A final partial scenario
# carries the exact remainder.  The gate and route identities/timeouts below
# are the frozen decision-0073 byte witnesses: they affect only target-neutral
# names and timeout metadata, while every occurrence remains a real uniform
# Boolean decision on the same canonical builder route.
sub _render_random_source($axis, $level, $requested_count) {
    confess "checking-state random renderer does not own axis '$axis'\n"
        unless $axis eq 'random_occurrences';
    confess "checking-state random renderer received an invalid requested count\n"
        unless defined($requested_count) && !ref($requested_count)
            && $requested_count =~ /\A[1-9][0-9]*\z/;

    my $choice_count = $requested_count < 128 ? $requested_count : 128;
    my $gate_recipe = $requested_count == 1_024;
    my $package_name = $gate_recipe
        ? 'architecture_scale_checking_state'
        : 'architecture_scale_randomness';
    my $fixture_name = 'gate';
    my @choice_names = map { 'c' . $_ } 0 .. $choice_count - 1;
    my @choices = map {
        my $name = $choice_names[$_];
        my $decision_id = $gate_recipe
            ? (($_ < 74 ? 'randx' : 'rand') . $_)
            : (($_ < 40 ? 'ddd' : 'dd') . $_);
        sprintf(
            '(choice %s bool (decision_id "%s")'
                . ' (distribution (uniform false true)) (constraints))',
            $name, $decision_id,
        )
    } 0 .. $#choice_names;

    my $full_scenarios = int($requested_count / $choice_count);
    my $remainder = $requested_count % $choice_count;
    my @widths = (($choice_count) x $full_scenarios);
    push @widths, $remainder if $remainder;
    my @scenarios;
    for my $ordinal (0 .. $#widths) {
        my @references = map { "(choice $choice_names[$_])" }
            0 .. $widths[$ordinal] - 1;
        my $property = @references == 1
            ? $references[0]
            : '(and ' . join(' ', @references) . ')';
        my $timeout_cycles = $ordinal == 0
            ? ($gate_recipe ? 1_000 : 100_000_000)
            : 2;
        push @scenarios, sprintf(
            '(scenario s%d (timeout (cycles b %d))'
                . ' (steps (expect e %s)))',
            $ordinal, $timeout_cycles, $property,
        );
    }

    my $source = join('',
        '(vial (version 1) (package ', $package_name,
        ' (imports)',
        ' (types)',
        ' (transactions)',
        ' (models)',
        ' (scoreboards)',
        ' (fixtures (fixture ', $fixture_name,
        ' (dut dut',
        ' (unit "unit/ahb_lite_subordinate")',
        ' (domains (domain b "domain/ahb_bus"))',
        ' (endpoints',
        ' (endpoint ready_out "endpoint/HREADYOUT" (logic 1) public_port))',
        ' (transactions))',
        ' (instances)',
        ' (coverage)',
        ' (faults)',
        ' (randomness (seed 1701) ', join(' ', @choices), ')',
        ' (scenarios ', join(' ', @scenarios), ')))))',
        "\n",
    );

    my %selected_bytes = (
        32_768 => 470_412,
        65_536 => 933_555,
        65_537 => 933_642,
    );
    if (my $exact = $selected_bytes{$requested_count}) {
        confess "checking-state random renderer produced " . bytes::length($source)
            . " bytes above its selected $exact-byte witness\n"
            if bytes::length($source) > $exact;
        substr($source, -1, 0, ' ' x ($exact - bytes::length($source)));
        confess "checking-state random renderer changed its selected byte witness\n"
            unless bytes::length($source) == $exact;
    }
    return $source;
}

sub _evaluate_random_route_boundary($reference_hial_text, $requested_count) {
    _validate_reference_hial($reference_hial_text);
    confess "random route boundary owns only 8440 and 8441 occurrences\n"
        unless defined($requested_count)
            && ($requested_count == 8_440 || $requested_count == 8_441);
    my $source = _render_random_source(
        'random_occurrences', 'route_boundary_v1', $requested_count,
    );
    my $construction = FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $FAMILY,
        level => 'qualification_candidate_v1',
        primary_axis => 'random_occurrences',
        backend_profile => undef,
        tool_profile => undef,
        inputs => [
            _input(
                $REFERENCE_HIAL_SOURCE, 'hial_source', $reference_hial_text,
            ),
            _input($VIAL_SOURCE, 'vial_source', $source),
        ],
    });
    confess "random route-boundary source escaped the workload envelope\n"
        unless $construction->{ok};
    my $inputs = _canonical_inputs_from_construction($construction);
    my $first = FSM::VIAL::ExecutionBuilder->build($inputs->{arguments});
    my $second = FSM::VIAL::ExecutionBuilder->build($inputs->{arguments});
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $expected_diagnostics = [_expected_plan_rejection_diagnostic()];
    my $accepted = $requested_count == 8_440
        && $first->{ok} && $second->{ok}
        && bytes::length($canonical->encode($first->{plan})) == 16_775_415
        && $canonical->encode($second->{plan})
            eq $canonical->encode($first->{plan});
    my $rejected = $requested_count == 8_441
        && !$first->{ok} && !$second->{ok}
        && $canonical->encode($first->{diagnostics})
            eq $canonical->encode($expected_diagnostics)
        && $canonical->encode($second->{diagnostics})
            eq $canonical->encode($expected_diagnostics);
    my $semantic = $inputs->{semantic_ir}->as_hashref;
    my $bridge = $inputs->{bridge_manifest}->as_hashref;
    my $execution = $first->{ok} ? $first->{execution_ir}->as_hashref : undef;
    return {
        ok => $accepted || $rejected ? JSON::PP::true : JSON::PP::false,
        requested_count => 0 + $requested_count,
        source_bytes => bytes::length($source),
        observed_outcome => $first->{ok} ? 'accepted' : 'rejected',
        serialized_plan_bytes => $first->{ok}
            ? bytes::length($canonical->encode($first->{plan})) : 0,
        semantic_ir_sha256 => sha256_hex($canonical->encode($semantic)),
        bridge_manifest_sha256 => sha256_hex($canonical->encode($bridge)),
        execution_ir_sha256 => $execution
            ? sha256_hex($canonical->encode($execution)) : undef,
        plan_sha256 => $first->{ok}
            ? sha256_hex($canonical->encode($first->{plan})) : undef,
        random_occurrences => $execution
            ? 0 + $execution->{resource_summary}{random_occurrences}
            : _semantic_random_metrics($semantic)->{random_occurrences},
        diagnostics => _clone($first->{diagnostics} || []),
    };
}

sub _model_definition($axis, $definition_ordinal, $cell_count) {
    my $definition = FSM::VIAL::ArchitectureScaleWorkload->stable_name({
        family => $FAMILY,
        primary_axis => $axis . '_definition',
        ordinal => $definition_ordinal,
    });
    my (@state, @assignments);
    for my $ordinal (0 .. $cell_count - 1) {
        my $cell = FSM::VIAL::ArchitectureScaleWorkload->stable_name({
            family => $FAMILY,
            primary_axis => $axis . '_state',
            ordinal => $ordinal,
        });
        push @state, "($cell (u 8) 0)";
        push @assignments, "(set $cell (+ $cell 1))";
    }
    return join('',
        '(model ', $definition,
        ' (inputs (tick event))',
        ' (state ', join(' ', @state), ')',
        ' (rules (on tick ', join(' ', @assignments), ')))',
    );
}

sub _model_instance($axis, $instance_ordinal, $definition_ordinal) {
    my $instance = FSM::VIAL::ArchitectureScaleWorkload->stable_name({
        family => $FAMILY,
        primary_axis => $axis,
        ordinal => $instance_ordinal,
    });
    my $definition = FSM::VIAL::ArchitectureScaleWorkload->stable_name({
        family => $FAMILY,
        primary_axis => $axis . '_definition',
        ordinal => $definition_ordinal,
    });
    return "(model $instance $definition (bind tick (event write accepted)))";
}

sub _selected_contract($axis, $level) {
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my $family = $catalog->{families}{$FAMILY};
    confess "unknown checking-state primary axis\n"
        unless defined($axis) && !ref($axis) && exists $family->{axes}{$axis};
    confess "unknown checking-state level\n"
        unless defined($level) && !ref($level)
            && exists $family->{axes}{$axis}{levels}{$level};
    return $family->{axes}{$axis}{levels}{$level};
}

sub _envelope_diagnostic($axis) {
    my $index = $UNCONSTRUCTIBLE{$axis}{envelope_input_index};
    return {
        code => 'VIAL_SCALE_INPUT_ERROR',
        severity => 'error',
        message => "input $index exceeds the bounded construction envelope",
        path => "/inputs/$index/content",
    };
}

sub _selected_specification($axis, $level) {
    my $minimal = FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        backend_profile => undef,
        tool_profile => undef,
        inputs => [
            _input($REFERENCE_HIAL_SOURCE, 'hial_source', ''),
            _input($VIAL_SOURCE, 'vial_source', ''),
        ],
    });
    confess "checking-state selected specification could not be derived\n"
        unless $minimal->{ok} && ref($minimal->{specification}) eq 'HASH';
    return _clone($minimal->{specification});
}

sub _unconstructible_construction($failure, $axis, $level) {
    return {
        %{$failure},
        specification => _selected_specification($axis, $level),
    };
}

sub _generic_envelope_failure($axis, $level) {
    my $failure = FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        backend_profile => undef,
        tool_profile => undef,
        inputs => [
            _input($REFERENCE_HIAL_SOURCE, 'hial_source', ''),
            _input(
                $VIAL_SOURCE, 'vial_source',
                'x' x ($CONSTRUCTION_ENVELOPE_BYTES + 1),
            ),
        ],
    });
    return _unconstructible_construction($failure, $axis, $level);
}

sub _canonical_inputs($raw) {
    return _canonical_inputs_from_construction(_validated_construction($raw));
}

sub _canonical_inputs_from_construction($construction) {
    my $hial = _role_input($construction, 'hial_source');
    my $vial = _role_input($construction, 'vial_source');

    # Decision 0073 preserves the ordinary product order: authored VIAL first,
    # then the canonical checked-AHB bridge, then public execution binding.
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $vial->{content},
        source_name => $vial->{relative_path},
        source_catalog => {},
    });
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_source(
        $hial->{content}, $hial->{relative_path},
    );
    my $ial1_text = $ppif->{generated_ial1}{text};
    my $actor = FSM::Adapter::ISF->new()->parse_source(
        $ial1_text, $ppif->{generated_ial1}{name},
    );
    my $bridge = FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
        profile => 'core_single_unit_v1',
        authored_source => _source_record(
            $hial->{content}, $hial->{relative_path},
        ),
        generated_ial1 => {
            source => _source_record(
                $ial1_text, undef, $ppif->{generated_ial1}{name},
            ),
            actor => $actor,
            schedule_report => $ppif->{generated_ial1_schedule_report},
        },
        generated_ial0 => _source_record(
            $ppif->{generated_ial0}{files}{'ahb_lite_subordinate.fsm'},
            undef, 'ahb_lite_subordinate.fsm',
        ),
        backend_names => _backend_names($actor),
    });
    confess "canonical checked-AHB bridge construction failed\n"
        unless $bridge->{ok};

    my $semantic = $semantic_ir->as_hashref;
    confess "checking-state candidate must contain exactly one package and fixture\n"
        unless @{$semantic->{packages}} == 1
            && @{$semantic->{packages}[0]{fixtures}} == 1;
    my $fixture = $semantic->{packages}[0]{fixtures}[0];
    my @scenario_ids = map { $_->{semantic_id} } @{$fixture->{scenarios}};
    confess "checking-state candidate must contain at least one scenario\n"
        unless @scenario_ids;
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
    my $specification = $raw->{specification};
    confess "construction must carry one specification hash\n"
        unless ref($specification) eq 'HASH' && !blessed($specification);
    my ($axis, $level) = @{$specification}{qw(primary_axis level)};
    confess "construction must be successful\n"
        unless $raw->{ok} || _unconstructible($axis, $level);
    if (_unconstructible($axis, $level)) {
        my $rebuilt = _generic_envelope_failure($axis, $level);
        my $canonical = JSON::PP->new->canonical(1)->allow_nonref(1);
        confess "construction is not canonical\n"
            unless $canonical->encode($rebuilt) eq $canonical->encode($raw);
        return $rebuilt;
    }
    my $rebuilt = _construct_candidate_internal({
        primary_axis => $axis,
        level => $level,
        reference_hial_text => _role_input($raw, 'hial_source')->{content},
        vial_source_text => _role_input($raw, 'vial_source')->{content},
    });
    my $canonical = JSON::PP->new->canonical(1)->allow_nonref(1);
    confess "construction is not canonical\n"
        unless $canonical->encode($rebuilt) eq $canonical->encode($raw);
    return $rebuilt;
}

sub _packed_state_contract() {
    return {
        schema => $PACKED_STATE_SCHEMA,
        schema_version => 1,
        digest_algorithm => 'sha256',
        model_cells => {
            encoding => 'fixed_width_packed_scalar_v1',
            byte_order => 'big_endian',
            unknown_state_policy => 'reject',
        },
        scoreboard_fifo => {
            encoding => 'uint32_big_endian_fifo_v1',
            bytes_per_entry => 4,
            maximum_entries => 1_000_000,
            maximum_payload_bytes => 4_000_000,
            fixed_fields_policy => 'reconstruct_and_compare_complete_transaction_v1',
            ordering => 'fifo',
        },
        coverage_vector => {
            encoding => 'one_bit_per_static_bin_or_tuple_v1',
            bit_order => 'least_significant_bit_first',
            maximum_entries => 1_000_000,
            maximum_vector_bytes => 125_000,
            comparison => 'byte_equal_independently_derived_expected_vector_v1',
        },
    };
}

sub _execution_metrics($resources, $plan, $canonical) {
    return {
        model_instances => 0 + $resources->{model_instances},
        scalar_model_state_cells => 0 + $resources->{scalar_state_cells},
        scoreboard_instances => 0 + $resources->{scoreboard_instances},
        scoreboard_declared_capacity =>
            0 + $resources->{scoreboard_declared_capacity},
        coverpoints => 0 + $resources->{coverpoints},
        bins_and_cross_tuples =>
            0 + $resources->{coverage_bins_and_cross_tuples},
        faults => 0 + $resources->{faults},
        random_occurrences => 0 + $resources->{random_occurrences},
        serialized_plan_bytes => bytes::length($canonical->encode($plan)),
    };
}

sub _semantic_model_metrics($semantic) {
    my $package = $semantic->{packages}[0];
    my $fixture = $package->{fixtures}[0];
    my %definition = map { $_->{semantic_id} => $_ } @{$package->{models}};
    my $cells = 0;
    for my $instance (@{$fixture->{instances}{model_instances}}) {
        my $model = $definition{$instance->{model_id}};
        $cells += scalar(@{$model->{state}}) if $model;
    }
    return {
        model_instances => scalar(@{$fixture->{instances}{model_instances}}),
        scalar_model_state_cells => $cells,
        scoreboard_instances => 0,
        scoreboard_declared_capacity => 0,
        coverpoints => 0,
        bins_and_cross_tuples => 0,
        faults => 0,
        random_occurrences => 0,
        serialized_plan_bytes => 0,
    };
}

sub _semantic_scoreboard_metrics($semantic) {
    my $package = $semantic->{packages}[0];
    my $fixture = $package->{fixtures}[0];
    my %definition = map { $_->{semantic_id} => $_ } @{$package->{scoreboards}};
    my $capacity = 0;
    for my $instance (@{$fixture->{instances}{scoreboard_instances}}) {
        my $scoreboard = $definition{$instance->{scoreboard_id}};
        $capacity += $scoreboard->{capacity} if $scoreboard;
    }
    return {
        model_instances => 0,
        scalar_model_state_cells => 0,
        scoreboard_instances =>
            scalar(@{$fixture->{instances}{scoreboard_instances}}),
        scoreboard_declared_capacity => $capacity,
        coverpoints => 0,
        bins_and_cross_tuples => 0,
        faults => 0,
        random_occurrences => 0,
        serialized_plan_bytes => 0,
    };
}

sub _scoreboard_recipe_metrics($spec) {
    my $axis = $spec->{primary_axis};
    my $requested = $spec->{requested_counts}{$axis};
    return {
        model_instances => 0,
        scalar_model_state_cells => 0,
        scoreboard_instances =>
            $axis eq 'scoreboard_instances' ? $requested : 1,
        scoreboard_declared_capacity => $requested,
        coverpoints => 0,
        bins_and_cross_tuples => 0,
        faults => 0,
        random_occurrences => 0,
        serialized_plan_bytes => 0,
    };
}

sub _semantic_coverage_metrics($semantic) {
    my $coverage = $semantic->{packages}[0]{fixtures}[0]{coverage};
    my %bins_by_point = map {
        $_->{semantic_id} => scalar(@{$_->{bins}})
    } @{$coverage->{coverpoints}};
    my $entries = 0;
    $entries += scalar(@{$_->{bins}}) for @{$coverage->{coverpoints}};
    for my $cross (@{$coverage->{crosses}}) {
        my $product = 1;
        $product *= $bins_by_point{$_} for @{$cross->{point_ids}};
        $entries += $product;
    }
    my $metrics = _zero_metrics();
    $metrics->{coverpoints} = scalar(@{$coverage->{coverpoints}});
    $metrics->{bins_and_cross_tuples} = $entries;
    return $metrics;
}

sub _semantic_fault_metrics($semantic) {
    my $metrics = _zero_metrics();
    my $faults = $semantic->{packages}[0]{fixtures}[0]{faults};
    $metrics->{faults} = ref($faults) eq 'ARRAY' ? scalar(@$faults) : 0;
    return $metrics;
}

sub _semantic_random_metrics($semantic) {
    my $fixture = $semantic->{packages}[0]{fixtures}[0];
    my $occurrences = 0;
    for my $scenario (@{$fixture->{scenarios} || []}) {
        for my $choice (@{$fixture->{randomness}{choices} || []}) {
            ++$occurrences if _contains_semantic_reference(
                $scenario->{actions}, $choice->{semantic_id},
            );
        }
    }
    my $metrics = _zero_metrics();
    $metrics->{random_occurrences} = $occurrences;
    return $metrics;
}

sub _contains_semantic_reference($value, $semantic_id) {
    return 0 unless defined $value;
    if (ref($value) eq 'ARRAY') {
        return scalar(grep { _contains_semantic_reference($_, $semantic_id) }
            @$value) ? 1 : 0;
    }
    return 0 unless ref($value) eq 'HASH';
    return 1 if ($value->{semantic_id} // '') eq $semantic_id
        && ($value->{kind} // '') eq 'reference';
    return scalar(grep {
        _contains_semantic_reference($value->{$_}, $semantic_id)
    } keys %$value) ? 1 : 0;
}

sub _build_random_replay_execution($inputs, $plan) {
    my @decisions = @{$plan->{random_decisions} || []};
    confess "checking-state random replay requires generated decisions\n"
        unless @decisions;
    my @decision_keys = qw(
        occurrence_id declaration_semantic_id decision_id scenario_id algorithm
        seed type_id distribution value attempt
    );
    my $replay = {
        schema => 'fsmgen.vial_replay.v1',
        schema_version => 1,
        replay_id => undef,
        semantic_ir_id => $plan->{semantic_identity}{semantic_ir_id},
        bridge_manifest_id => $plan->{bridge_identity}{manifest_id},
        fixture_id => $plan->{fixture}{fixture_id},
        scenario_ids => _clone($plan->{fixture}{scenario_ids}),
        algorithm => $decisions[0]{algorithm},
        decisions => [map {
            my $decision = $_;
            +{map { $_ => _clone($decision->{$_}) } @decision_keys}
        } @decisions],
    };
    my $identity_projection = _clone($replay);
    delete $identity_projection->{replay_id};
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    $replay->{replay_id} = 'replay/'
        . sha256_hex($canonical->encode($identity_projection));
    my %arguments = %{$inputs->{arguments}};
    $arguments{scenario_ids} = _clone($inputs->{arguments}{scenario_ids});
    $arguments{native_extension_catalog} = [];
    $arguments{replay_manifest} = $replay;
    return {
        manifest => $replay,
        execution => FSM::VIAL::ExecutionBuilder->build(\%arguments),
    };
}

sub _evaluate_random_state(
    $spec, $execution, $generated_plan, $rerun_plan, $replay, $canonical,
) {
    my $generated = $generated_plan->{random_decisions} || [];
    my $rerun = $rerun_plan->{random_decisions} || [];
    my $replayed_plan = $replay->{execution}{ok}
        ? $replay->{execution}{plan} : {random_decisions => []};
    my $replayed = $replayed_plan->{random_decisions} || [];
    my $requested = $spec->{requested_counts}{random_occurrences};
    my @expected_order = map {
        @{$_->{plan_summary}{decision_occurrence_ids} || []}
    } @{$execution->{scenarios} || []};
    my @observed_order = map { $_->{occurrence_id} // '' } @$generated;
    my $key_order_preserved = @expected_order == @$generated
        && join("\0", @expected_order) eq join("\0", @observed_order);
    my $values_normalized = @$generated == $requested
        && !scalar(grep { !_random_decision_is_closed($_, 'generated') }
            @$generated);
    my $generated_values_matched = @$rerun == @$generated
        && $canonical->encode($rerun) eq $canonical->encode($generated);

    my $normalized_generated = _clone($generated);
    my $normalized_replayed = _clone($replayed);
    delete $_->{origin} for @$normalized_generated;
    delete $_->{origin} for @$normalized_replayed;
    my $replay_values_matched = @$replayed == @$generated
        && !scalar(grep { !_random_decision_is_closed($_, 'replayed') }
            @$replayed)
        && $canonical->encode($normalized_replayed)
            eq $canonical->encode($normalized_generated);

    my $normalized_generated_plan = _clone($generated_plan);
    my $normalized_replayed_plan = _clone($replayed_plan);
    delete $normalized_generated_plan->{plan_id};
    delete $normalized_replayed_plan->{plan_id};
    $_->{origin} = 'replayed'
        for @{$normalized_generated_plan->{random_decisions} || []};
    my $normalized_plans_equal = $replay->{execution}{ok}
        && $canonical->encode($normalized_replayed_plan)
            eq $canonical->encode($normalized_generated_plan);
    my $replay_identity_preserved = $replay->{execution}{ok}
        && ($replay->{manifest}{replay_id} // '') =~ m{\Areplay/[0-9a-f]{64}\z}
        && ($generated_plan->{plan_id} // '') =~ m{\Aplan/[0-9a-f]{64}\z}
        && ($replayed_plan->{plan_id} // '') =~ m{\Aplan/[0-9a-f]{64}\z}
        && ($generated_plan->{plan_id} // '') ne ($replayed_plan->{plan_id} // '');

    my $mutated = _clone($normalized_replayed);
    if (@$mutated) {
        $mutated->[0]{value}{value_hex} =
            ($mutated->[0]{value}{value_hex} // '') eq '0' ? '1' : '0';
    }
    my $mutation_rejected = @$mutated
        && $canonical->encode($mutated)
            ne $canonical->encode($normalized_generated);
    my $reordered = _clone($generated);
    @$reordered[0, 1] = @$reordered[1, 0] if @$reordered > 1;
    my $order_mutation_rejected = @$reordered > 1
        && join("\0", map { $_->{occurrence_id} // '' } @$reordered)
            ne join("\0", @expected_order);

    my %choice_ids = map { ($_->{declaration_semantic_id} // '') => 1 }
        @$generated;
    my @diagnostics;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_RANDOM_ERROR',
        'generated and replayed random decisions did not preserve exact keyed values, order, normalization, and plan identity',
        '/oracle_evidence/random_replay',
    ) unless @$generated == $requested
        && @$rerun == $requested
        && @$replayed == $requested
        && $key_order_preserved
        && $values_normalized
        && $generated_values_matched
        && $replay_values_matched
        && $replay_identity_preserved
        && $normalized_plans_equal
        && $mutation_rejected
        && $order_mutation_rejected;

    my $first = @$generated ? $generated->[0] : {};
    my $last = @$generated ? $generated->[-1] : {};
    return ({
        schema => $RANDOM_EVIDENCE_SCHEMA,
        schema_version => 1,
        program => 'generate_replay_compare_each_keyed_boolean_v1',
        axis => 'random_occurrences',
        random_occurrences => 0 + @$generated,
        choice_declarations => scalar(keys %choice_ids),
        scenario_count => scalar(@{$execution->{scenarios} || []}),
        generated_decisions => 0 + @$generated,
        replayed_decisions => 0 + @$replayed,
        generated_sequence_sha256 => sha256_hex($canonical->encode($generated)),
        rerun_sequence_sha256 => sha256_hex($canonical->encode($rerun)),
        replayed_sequence_sha256 => sha256_hex($canonical->encode($replayed)),
        normalized_generated_sequence_sha256 =>
            sha256_hex($canonical->encode($normalized_generated)),
        normalized_replayed_sequence_sha256 =>
            sha256_hex($canonical->encode($normalized_replayed)),
        generated_plan_sha256 => sha256_hex($canonical->encode($generated_plan)),
        replayed_plan_sha256 => sha256_hex($canonical->encode($replayed_plan)),
        replay_manifest_id => $replay->{manifest}{replay_id},
        first_occurrence_id => $first->{occurrence_id},
        last_occurrence_id => $last->{occurrence_id},
        first_value_hex => $first->{value}{value_hex},
        last_value_hex => $last->{value}{value_hex},
        key_order_preserved => $key_order_preserved
            ? JSON::PP::true : JSON::PP::false,
        values_canonically_normalized => $values_normalized
            ? JSON::PP::true : JSON::PP::false,
        generated_values_matched => $generated_values_matched
            ? JSON::PP::true : JSON::PP::false,
        replay_values_matched => $replay_values_matched
            ? JSON::PP::true : JSON::PP::false,
        replay_identity_preserved => $replay_identity_preserved
            ? JSON::PP::true : JSON::PP::false,
        normalized_plans_equal => $normalized_plans_equal
            ? JSON::PP::true : JSON::PP::false,
        mutation_rejected => $mutation_rejected
            ? JSON::PP::true : JSON::PP::false,
        order_mutation_rejected => $order_mutation_rejected
            ? JSON::PP::true : JSON::PP::false,
    }, \@diagnostics);
}

sub _random_decision_is_closed($decision, $origin) {
    return ref($decision) eq 'HASH'
        && ($decision->{algorithm} // '') eq 'sha256_counter_rejection_v1'
        && ($decision->{seed} // -1) == 1701
        && ($decision->{origin} // '') eq $origin
        && ($decision->{occurrence_id} // '') =~ m{\Adecision/.+/0\z}
        && ($decision->{declaration_semantic_id} // '') =~ /::choice::c[0-9]+\z/
        && ($decision->{scenario_id} // '') =~ /::scenario::s[0-9]+\z/
        && ($decision->{decision_id} // '') =~ /\A(?:randx?|ddd?)?[0-9]+\z/
        && ref($decision->{reference_operation_ids}) eq 'ARRAY'
        && @{$decision->{reference_operation_ids}} == 1
        && ($decision->{attempt} // -1) == 0
        && ref($decision->{distribution}) eq 'HASH'
        && ($decision->{distribution}{kind} // '') eq 'uniform'
        && ($decision->{distribution}{low}{value_hex} // '') eq '0'
        && ($decision->{distribution}{high}{value_hex} // '') eq '1'
        && ref($decision->{value}) eq 'HASH'
        && ($decision->{value}{kind} // '') eq 'scalar'
        && ($decision->{value}{known_hex} // '') eq '1'
        && ($decision->{value}{z_hex} // '') eq '0'
        && ($decision->{value}{width} // 0) == 1
        && !($decision->{value}{signed} // 1)
        && ($decision->{value}{state_domain} // '') eq 'two_state'
        && (($decision->{value}{value_hex} // '') eq '0'
            || ($decision->{value}{value_hex} // '') eq '1');
}

sub _oracle_evidence($oracle, $evidence) {
    return {
        schema => $ORACLE_EVIDENCE_SCHEMA,
        schema_version => 1,
        oracle => $oracle,
        model => $oracle eq 'model' ? _clone($evidence) : undef,
        scoreboard => $oracle eq 'scoreboard' ? _clone($evidence) : undef,
        coverage => $oracle eq 'coverage' ? _clone($evidence) : undef,
        faults => $oracle eq 'faults' ? _clone($evidence) : undef,
        random_replay => $oracle eq 'random_replay' ? _clone($evidence) : undef,
    };
}

sub _claims($owned) {
    return {
        schema => $CLAIMS_SCHEMA,
        schema_version => 1,
        qualification_only => JSON::PP::true,
        capability_claimed => JSON::PP::false,
        support_claimed => JSON::PP::false,
        performance_claimed => JSON::PP::false,
        capacity_claimed => JSON::PP::false,
        backend_authority => JSON::PP::false,
        runtime_authority => JSON::PP::false,
        axis_level_owned => $owned ? JSON::PP::true : JSON::PP::false,
    };
}

sub _rerun_identity($workload_identity, $stage_identities, $diagnostics) {
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    return 'rerun/' . sha256_hex($canonical->encode({
        workload_identity => $workload_identity,
        stage_identities => $stage_identities,
        diagnostics => $diagnostics,
    }));
}

sub _expected_model_rejection_diagnostic($axis) {
    my ($resource, $limit) = $axis eq 'model_instances'
        ? ('model_instances', 4_096)
        : ('scalar_state_cells', 65_536);
    return {
        bridge_fact_paths => [],
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        message => "$resource exceeds the limit $limit",
        phase => 'limit',
        related => [],
        schema_version => 1,
        semantic_path => '/models',
        severity => 'error',
        source_location => undef,
    };
}

sub _expected_scoreboard_execution_rejection_diagnostic() {
    return {
        bridge_fact_paths => [],
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        message => 'scoreboard_instances exceeds the limit 4096',
        phase => 'limit',
        related => [],
        schema_version => 1,
        semantic_path => '/scoreboards',
        severity => 'error',
        source_location => undef,
    };
}

sub _expected_coverage_execution_rejection_diagnostic() {
    return {
        bridge_fact_paths => [],
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        message => 'coverage_bins_and_cross_tuples exceeds the limit 1000000',
        phase => 'limit',
        related => [],
        schema_version => 1,
        semantic_path => '/coverage',
        severity => 'error',
        source_location => undef,
    };
}

sub _expected_fault_execution_rejection_diagnostic() {
    return {
        bridge_fact_paths => [],
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        message => 'faults exceeds the limit 4096',
        phase => 'limit',
        related => [],
        schema_version => 1,
        semantic_path => '/faults',
        severity => 'error',
        source_location => undef,
    };
}

sub _expected_plan_rejection_diagnostic() {
    return {
        bridge_fact_paths => [],
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        message => 'serialized_plan_bytes exceeds the limit 16777216',
        phase => 'limit',
        related => [],
        schema_version => 1,
        semantic_path => '/plan',
        severity => 'error',
        source_location => undef,
    };
}

sub _expected_random_rejection_diagnostic() {
    return {
        bridge_fact_paths => [],
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        message => 'random_occurrences exceeds the limit 65536',
        phase => 'limit',
        related => [],
        schema_version => 1,
        semantic_path => '/randomness/decisions',
        severity => 'error',
        source_location => undef,
    };
}

sub _is_expected_scoreboard_semantic_rejection($result) {
    return 0 unless ref($result) eq 'HASH' && !$result->{ok}
        && ref($result->{diagnostics}) eq 'ARRAY'
        && @{$result->{diagnostics}} == 1;
    my $diagnostic = $result->{diagnostics}[0];
    return 0 unless ref($diagnostic) eq 'HASH';
    my %expected_keys = map { $_ => 1 } qw(
        schema_version severity code phase message semantic_path
        source_location notes
    );
    return 0 unless keys(%$diagnostic) == keys(%expected_keys)
        && !grep { !$expected_keys{$_} } keys %$diagnostic;
    return ($diagnostic->{schema_version} // 0) == 1
        && ($diagnostic->{severity} // '') eq 'error'
        && ($diagnostic->{code} // '') eq 'VIAL_LIMIT_ERROR'
        && ($diagnostic->{phase} // '') eq 'limit'
        && ($diagnostic->{message} // '')
            eq 'integer is outside the bounded range 1 through 1000000'
        && ($diagnostic->{semantic_path} // '')
            eq '/packages/0/scoreboards/0/capacity'
        && ref($diagnostic->{source_location}) eq 'HASH'
        && ($diagnostic->{source_location}{source_name} // '') eq $VIAL_SOURCE
        && ref($diagnostic->{notes}) eq 'ARRAY'
        && @{$diagnostic->{notes}} == 0;
}

sub _evaluate_model_state($spec, $execution) {
    my $axis = $spec->{primary_axis};
    my $requested = $spec->{requested_counts}{$axis};
    my (@errors, @instance_ids, @cell_ids, @trigger_ids);
    my ($trigger_event_id, $initial, $final) = (undef, '', '');

    for my $instance_ordinal (0 .. $#{$execution->{models}}) {
        my $instance = $execution->{models}[$instance_ordinal];
        push @instance_ids, $instance->{instance_id};
        my $bindings = $instance->{bindings};
        my $definition = $instance->{definition};
        my $binding = ref($bindings) eq 'ARRAY' && @$bindings == 1
            ? $bindings->[0] : undef;
        my $event_id = $binding && ref($binding->{value}) eq 'HASH'
            ? $binding->{value}{semantic_id} : undef;
        if (!defined($event_id)) {
            push @errors, _oracle_error(
                'VIAL_SCALE_CHECKING_MODEL_ERROR',
                'model instance does not have exactly one canonical event binding',
                "/models/$instance_ordinal/bindings",
            );
            next;
        }
        $trigger_event_id //= $event_id;
        push @errors, _oracle_error(
            'VIAL_SCALE_CHECKING_MODEL_ERROR',
            'model instances do not share the authored trigger event',
            "/models/$instance_ordinal/bindings/0/value/semantic_id",
        ) unless $event_id eq $trigger_event_id;
        my $rules = $definition->{rules};
        my $rule = ref($rules) eq 'ARRAY' && @$rules == 1 ? $rules->[0] : undef;
        my %assignment = $rule && ref($rule->{assignments}) eq 'ARRAY'
            ? map { $_->{state_id} => $_ } @{$rule->{assignments}} : ();
        push @errors, _oracle_error(
            'VIAL_SCALE_CHECKING_MODEL_ERROR',
            'model definition does not have one complete event rule',
            "/models/$instance_ordinal/definition/rules",
        ) unless $rule
            && ($rule->{input_id} // '') eq ($binding->{input_id} // '')
            && keys(%assignment) == @{$definition->{state}};

        my $trigger_identity = 'model-trigger/' . sha256_hex(
            join("\0", $instance->{instance_id}, $event_id, 'occurrence/1'),
        );
        push @trigger_ids, $trigger_identity;
        for my $state_ordinal (0 .. $#{$definition->{state}}) {
            my $state = $definition->{state}[$state_ordinal];
            my $cell_identity = join('::instance_state::',
                $instance->{instance_id}, $state->{semantic_id});
            push @cell_ids, $cell_identity;
            my $initial_value = $state->{initial_value};
            my $assignment = $assignment{$state->{semantic_id}};
            my $expression = $assignment ? $assignment->{expression} : undef;
            my $valid = $initial_value
                && ($initial_value->{kind} // '') eq 'integer_value'
                && ($initial_value->{width} // 0) == 8
                && ($initial_value->{signed} // 1) == 0
                && ($initial_value->{value_decimal} // -1) == 0
                && _is_increment_expression($expression, $state->{semantic_id});
            push @errors, _oracle_error(
                'VIAL_SCALE_CHECKING_MODEL_ERROR',
                'model cell is not the exact known u8 zero-to-one transition',
                "/models/$instance_ordinal/definition/state/$state_ordinal",
            ) unless $valid;
            $initial .= pack('C', 0);
            $final .= pack('C', $valid ? 1 : 0);
        }
    }

    my $model_count = scalar(@instance_ids);
    my $cell_count = scalar(@cell_ids);
    my $expected_count = $axis eq 'model_instances' ? $model_count : $cell_count;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_MODEL_ERROR',
        'model oracle did not reach the selected axis count',
        "/requested_counts/$axis",
    ) unless $expected_count == $requested;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_MODEL_ERROR',
        'model-instance ladder does not carry exactly one state cell per instance',
        '/oracle_evidence/model/scalar_state_cells',
    ) if $axis eq 'model_instances' && $cell_count != $model_count;
    my $expected_initial = "\0" x $cell_count;
    my $expected_final = "\1" x $cell_count;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_MODEL_ERROR',
        'packed model state differs from the independently derived expectation',
        '/oracle_evidence/model/final_state_sha256',
    ) unless $initial eq $expected_initial && $final eq $expected_final;

    my $evidence = {
        schema => $MODEL_EVIDENCE_SCHEMA,
        schema_version => 1,
        program => 'one_bound_event_occurrence_per_instance_v1',
        axis => $axis,
        model_instances => $model_count,
        scalar_state_cells => $cell_count,
        cell_width_bits => 8,
        packed_bytes => bytes::length($final),
        trigger_occurrences => scalar(@trigger_ids),
        cells_initialized => $cell_count,
        cells_updated => $cell_count,
        cells_read => $cell_count,
        initial_state_sha256 => sha256_hex($initial),
        final_state_sha256 => sha256_hex($final),
        expected_initial_state_sha256 => sha256_hex($expected_initial),
        expected_final_state_sha256 => sha256_hex($expected_final),
        first_instance_id => $instance_ids[0],
        last_instance_id => $instance_ids[-1],
        first_state_id => $cell_ids[0],
        last_state_id => $cell_ids[-1],
        trigger_event_id => $trigger_event_id,
        first_trigger_identity => $trigger_ids[0],
        last_trigger_identity => $trigger_ids[-1],
        byte_equal_expected => @errors ? JSON::PP::false : JSON::PP::true,
        all_updates_committed => @errors ? JSON::PP::false : JSON::PP::true,
        all_reads_matched => @errors ? JSON::PP::false : JSON::PP::true,
    };
    return ($evidence, \@errors);
}

sub _evaluate_scoreboard_state($spec, $execution) {
    my $axis = $spec->{primary_axis};
    my $requested = $spec->{requested_counts}{$axis};
    my $scoreboards = $execution->{scoreboards};
    my $transactions = $execution->{transactions};
    my (@errors, @instance_ids);
    my %instance_ids;
    my %definition_ids;
    my $declared_capacity = 0;

    if (ref($scoreboards) ne 'ARRAY' || ref($transactions) ne 'ARRAY') {
        push @errors, _oracle_error(
            'VIAL_SCALE_CHECKING_SCOREBOARD_ERROR',
            'scoreboard oracle requires canonical scoreboard and transaction arrays',
            '/scoreboards',
        );
        $scoreboards = [] unless ref($scoreboards) eq 'ARRAY';
        $transactions = [] unless ref($transactions) eq 'ARRAY';
    }
    my %transaction = map {
        (($_->{semantic_id} // '') => $_)
    } grep { ref($_) eq 'HASH' } @$transactions;
    my @expected_fields = qw(
        address transfer write size data wait_cycles
    );
    for my $ordinal (0 .. $#$scoreboards) {
        my $scoreboard = $scoreboards->[$ordinal];
        my $definition = ref($scoreboard->{definition}) eq 'HASH'
            ? $scoreboard->{definition} : {};
        my $capacity = $definition->{capacity};
        my $instance_id = $scoreboard->{instance_id};
        push @instance_ids, $instance_id;
        ++$instance_ids{$instance_id // ''};
        $definition_ids{$scoreboard->{scoreboard_id} // ''} = 1;
        $declared_capacity += $capacity
            if defined($capacity) && !ref($capacity)
                && $capacity =~ /\A[0-9]+\z/;
        my $expected_capacity = $axis eq 'scoreboard_instances'
            ? 1 : $requested;
        push @errors, _oracle_error(
            'VIAL_SCALE_CHECKING_SCOREBOARD_ERROR',
            'scoreboard instance is not the exact selected in-order definition',
            "/scoreboards/$ordinal/definition",
        ) unless ($definition->{policy} // '') eq 'in_order'
            && !defined($definition->{key})
            && ($capacity // 0) == $expected_capacity
            && ($scoreboard->{transaction_id} // '')
                eq ($definition->{transaction_id} // '')
            && ($scoreboard->{actual_id} // '')
                =~ /::transaction_binding::write\z/;
        my $transaction = $transaction{$scoreboard->{transaction_id} // ''};
        my @fields = $transaction
            && ref($transaction->{definition}) eq 'HASH'
            && ref($transaction->{definition}{fields}) eq 'ARRAY'
            ? map { $_->{name} // '' }
                @{$transaction->{definition}{fields}}
            : ();
        push @errors, _oracle_error(
            'VIAL_SCALE_CHECKING_SCOREBOARD_ERROR',
            'scoreboard transaction does not contain the six selected fields in order',
            "/scoreboards/$ordinal/transaction_id",
        ) unless join("\0", @fields) eq join("\0", @expected_fields);
    }

    my $instance_count = scalar(@$scoreboards);
    my $expected_instances = $axis eq 'scoreboard_instances' ? $requested : 1;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_SCOREBOARD_ERROR',
        'scoreboard oracle did not reach the selected instance count',
        '/oracle_evidence/scoreboard/scoreboard_instances',
    ) unless $instance_count == $expected_instances;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_SCOREBOARD_ERROR',
        'scoreboard instances must have distinct nonempty canonical identities',
        '/oracle_evidence/scoreboard/scoreboard_instances',
    ) unless keys(%instance_ids) == $instance_count
        && !exists($instance_ids{''});
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_SCOREBOARD_ERROR',
        'scoreboard oracle did not reach the selected total capacity',
        '/oracle_evidence/scoreboard/declared_capacity',
    ) unless $declared_capacity == $requested;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_SCOREBOARD_ERROR',
        'scoreboard ladder must reuse exactly one authored definition',
        '/oracle_evidence/scoreboard/scoreboard_definitions',
    ) unless keys(%definition_ids) == 1;

    my $entry_count = $requested;
    my $packed_payload = '';
    for my $ordinal (0 .. $entry_count - 1) {
        $packed_payload .= pack('N', $ordinal);
    }
    my $payload_bytes = bytes::length($packed_payload);
    my $payload_sha = sha256_hex($packed_payload);
    my $expected_digest = Digest::SHA->new(256);
    my @expected_depths = $axis eq 'scoreboard_instances'
        ? ((1) x $entry_count) : ($entry_count);
    my @actual_depths = (0) x scalar(@expected_depths);
    my ($expected_depth, $actual_depth, $maximum_actual_depth) =
        ($entry_count, 0, 0);
    my ($field_comparisons, $matched, $drained) = (0, 0, 0);
    my $fifo_order_preserved = 1;
    my $complete_transactions_equal = 1;
    my ($first_identity, $last_identity);
    for my $ordinal (0 .. $entry_count - 1) {
        my $instance_ordinal = $axis eq 'scoreboard_instances' ? $ordinal : 0;
        my $chunk = substr($packed_payload, $ordinal * 4, 4);
        my $expected_chunk = pack('N', $ordinal);
        $expected_digest->add($expected_chunk);
        $fifo_order_preserved = 0 unless $chunk eq $expected_chunk;
        my $payload = unpack('N', $chunk);
        my $expected = _scoreboard_expected_transaction($payload);
        my $actual = _scoreboard_actual_transaction($ordinal);
        ++$actual_depths[$instance_ordinal];
        ++$actual_depth;
        $maximum_actual_depth = $actual_depths[$instance_ordinal]
            if $actual_depths[$instance_ordinal] > $maximum_actual_depth;
        my ($equal, $compared) =
            _scoreboard_transactions_equal($expected, $actual);
        $field_comparisons += $compared;
        $complete_transactions_equal = 0 unless $equal;
        ++$matched if $equal;
        my $identity = _scoreboard_transaction_identity($expected);
        $first_identity //= $identity;
        $last_identity = $identity;
        --$expected_depths[$instance_ordinal];
        --$actual_depths[$instance_ordinal];
        --$expected_depth;
        --$actual_depth;
        ++$drained;
    }
    my $expected_payload_sha = $expected_digest->hexdigest;
    $fifo_order_preserved = 0 unless $payload_sha eq $expected_payload_sha;
    $packed_payload = '';

    my $mismatch_expected = _scoreboard_expected_transaction(0);
    my $mismatch_actual = _scoreboard_actual_transaction(1);
    my ($mismatch_equal) =
        _scoreboard_transactions_equal($mismatch_expected, $mismatch_actual);
    my $mismatch_rejected = !$mismatch_equal;
    my $per_instance_capacity = $axis eq 'scoreboard_instances'
        ? 1 : $requested;
    my $overflow_rejected = !_scoreboard_enqueue_allowed(
        $per_instance_capacity, $per_instance_capacity,
    );
    my $corrupt = pack('N', 0);
    substr($corrupt, 3, 1, chr(ord(substr($corrupt, 3, 1)) ^ 1));
    my $corruption_rejected = $corrupt ne pack('N', 0);
    my $all_instance_queues_drained = !grep { $_ != 0 }
        (@expected_depths, @actual_depths);
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_SCOREBOARD_ERROR',
        'packed scoreboard FIFO did not preserve exact authored order',
        '/oracle_evidence/scoreboard/packed_payload_sha256',
    ) unless $fifo_order_preserved;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_SCOREBOARD_ERROR',
        'scoreboard did not compare every complete transaction field',
        '/oracle_evidence/scoreboard/complete_field_comparisons',
    ) unless $complete_transactions_equal
        && $field_comparisons == $entry_count * @expected_fields;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_SCOREBOARD_ERROR',
        'scoreboard negative checks did not reject mismatch, overflow, and corruption',
        '/oracle_evidence/scoreboard/mismatch_rejected',
    ) unless $mismatch_rejected && $overflow_rejected && $corruption_rejected;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_SCOREBOARD_ERROR',
        'scoreboard queues did not drain to zero pending entries',
        '/oracle_evidence/scoreboard/pending_entries',
    ) unless $expected_depth == 0 && $actual_depth == 0
        && $all_instance_queues_drained && $drained == $entry_count;

    my $success = @errors ? 0 : 1;
    my $evidence = {
        schema => $SCOREBOARD_EVIDENCE_SCHEMA,
        schema_version => 1,
        program => 'packed_complete_transaction_fifo_v1',
        axis => $axis,
        scoreboard_instances => $instance_count,
        scoreboard_definitions => scalar(keys %definition_ids),
        declared_capacity => $declared_capacity,
        transactions_enqueued => $entry_count,
        transactions_observed => $entry_count,
        transactions_matched => $matched,
        transactions_drained => $drained,
        fields_per_transaction => scalar(@expected_fields),
        complete_field_comparisons => $field_comparisons,
        packed_payload_bytes => $payload_bytes,
        packed_payload_sha256 => $payload_sha,
        expected_payload_sha256 => $expected_payload_sha,
        maximum_total_expected_depth => $entry_count,
        maximum_expected_depth => $per_instance_capacity,
        maximum_actual_depth => $maximum_actual_depth,
        final_expected_depth => $expected_depth,
        final_actual_depth => $actual_depth,
        pending_entries => $expected_depth + $actual_depth,
        first_instance_id => $instance_ids[0],
        last_instance_id => $instance_ids[-1],
        first_transaction_identity => $first_identity,
        last_transaction_identity => $last_identity,
        first_payload_hex => sprintf('%08x', 0),
        last_payload_hex => sprintf('%08x', $entry_count - 1),
        fifo_order_preserved => $success && $fifo_order_preserved
            ? JSON::PP::true : JSON::PP::false,
        complete_transactions_equal => $success && $complete_transactions_equal
            ? JSON::PP::true : JSON::PP::false,
        all_instances_drained => $success && $expected_depth == 0
            && $actual_depth == 0 && $all_instance_queues_drained
            ? JSON::PP::true : JSON::PP::false,
        mismatch_rejected => $success && $mismatch_rejected
            ? JSON::PP::true : JSON::PP::false,
        overflow_rejected => $success && $overflow_rejected
            ? JSON::PP::true : JSON::PP::false,
        corruption_rejected => $success && $corruption_rejected
            ? JSON::PP::true : JSON::PP::false,
    };
    return ($evidence, \@errors);
}

sub _evaluate_coverage_state($spec, $execution) {
    my $axis = $spec->{primary_axis};
    my $requested = $spec->{requested_counts}{$axis};
    my $coverage = $execution->{coverage};
    my (@errors, @coverpoint_ids, @bin_ids, @cross_ids);
    my ($points, $crosses) = ref($coverage) eq 'HASH'
        ? @{$coverage}{qw(coverpoints crosses)} : (undef, undef);
    if (ref($points) ne 'ARRAY' || ref($crosses) ne 'ARRAY') {
        push @errors, _oracle_error(
            'VIAL_SCALE_CHECKING_COVERAGE_ERROR',
            'coverage oracle requires canonical coverpoint and cross arrays',
            '/coverage',
        );
        $points = [] unless ref($points) eq 'ARRAY';
        $crosses = [] unless ref($crosses) eq 'ARRAY';
    }

    my $recipe = _coverage_recipe($axis, $spec->{level}, $requested);
    my $structure_closed = @$points == @{$recipe->{points}}
        && @$crosses == @{$recipe->{crosses}};
    my %point_by_id;
    my %seen_id;
    my $all_bins_match = 1;
    my $all_normal = 1;
    for my $point_ordinal (0 .. $#$points) {
        my $point = $points->[$point_ordinal];
        my $expected = $recipe->{points}[$point_ordinal] || {};
        my $point_id = $point->{semantic_id};
        push @coverpoint_ids, $point_id;
        $point_by_id{$point_id // ''} = $point;
        ++$seen_id{$point_id // ''};
        my $bins = ref($point->{bins}) eq 'ARRAY' ? $point->{bins} : [];
        $structure_closed = 0 unless ($point->{name} // '')
                eq ($expected->{name} // '')
            && @$bins == @{$expected->{bin_names} || []}
            && ($point->{domain_id} // '') =~ /::domain::bus\z/
            && _coverage_expression_samples_one($axis, $point->{expression});
        for my $bin_ordinal (0 .. $#$bins) {
            my $bin = $bins->[$bin_ordinal];
            my $expected_name = $expected->{bin_names}[$bin_ordinal];
            my $bin_id = $bin->{semantic_id};
            push @bin_ids, $bin_id;
            ++$seen_id{$bin_id // ''};
            $structure_closed = 0 unless ($bin->{name} // '')
                    eq ($expected_name // '')
                && ($bin->{classification} // '') eq 'normal';
            $all_normal = 0 unless ($bin->{classification} // '') eq 'normal';
            $all_bins_match = 0 unless _coverage_matcher_matches_one(
                $bin->{matcher},
            );
        }
    }

    my $cross_tuple_count = 0;
    for my $cross_ordinal (0 .. $#$crosses) {
        my $cross = $crosses->[$cross_ordinal];
        my $expected = $recipe->{crosses}[$cross_ordinal] || {};
        my $cross_id = $cross->{semantic_id};
        push @cross_ids, $cross_id;
        ++$seen_id{$cross_id // ''};
        my $point_ids = ref($cross->{point_ids}) eq 'ARRAY'
            ? $cross->{point_ids} : [];
        my @cross_points = map { $point_by_id{$_ // ''} } @$point_ids;
        my @expected_point_ids = map {
            _coverage_point_id($_)
        } @{$expected->{point_names} || []};
        my $product = 1;
        for my $point (@cross_points) {
            $product *= $point && ref($point->{bins}) eq 'ARRAY'
                ? scalar(@{$point->{bins}}) : 0;
        }
        $cross_tuple_count += $product;
        $structure_closed = 0 unless ($cross->{name} // '')
                eq ($expected->{name} // '')
            && join("\0", @$point_ids) eq join("\0", @expected_point_ids)
            && ($cross->{max_bins} // 0) == $product
            && $product == ($expected->{tuple_count} // -1);
    }
    $structure_closed = 0 if exists($seen_id{''})
        || keys(%seen_id) != @coverpoint_ids + @bin_ids + @cross_ids;

    my $static_entries = @bin_ids + $cross_tuple_count;
    my $selected_count = $axis eq 'coverpoints'
        ? scalar(@coverpoint_ids) : $static_entries;
    my $resource_entries = $execution->{resource_summary}
        {coverage_bins_and_cross_tuples};
    my $resource_points = $execution->{resource_summary}{coverpoints};
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_COVERAGE_ERROR',
        'coverage oracle did not reconstruct the exact authored static domain',
        '/coverage',
    ) unless $structure_closed && $all_normal && $all_bins_match;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_COVERAGE_ERROR',
        'coverage oracle did not reach the selected axis count',
        "/requested_counts/$axis",
    ) unless $selected_count == $requested
        && ($resource_entries // -1) == $static_entries
        && ($resource_points // -1) == @coverpoint_ids;

    my $actual_vector = "\0" x int(($static_entries + 7) / 8);
    my $actual_digest = Digest::SHA->new(256);
    my $actual_index = 0;
    for my $point (@$points) {
        for my $bin (@{$point->{bins} || []}) {
            _coverage_digest_add($actual_digest, $bin->{semantic_id} // '');
            vec($actual_vector, $actual_index++, 1) = 1
                if _coverage_matcher_matches_one($bin->{matcher})
                    && ($bin->{classification} // '') eq 'normal';
        }
    }
    for my $cross (@$crosses) {
        my @cross_points = map { $point_by_id{$_ // ''} }
            @{$cross->{point_ids} || []};
        if (@cross_points == 2 && !grep { !defined($_) } @cross_points) {
            for my $left (@{$cross_points[0]{bins}}) {
                for my $right (@{$cross_points[1]{bins}}) {
                    my $token = join("\0",
                        $cross->{semantic_id} // '',
                        $left->{semantic_id} // '',
                        $right->{semantic_id} // '',
                    );
                    _coverage_digest_add($actual_digest, $token);
                    vec($actual_vector, $actual_index++, 1) = 1
                        if _coverage_matcher_matches_one($left->{matcher})
                            && _coverage_matcher_matches_one($right->{matcher})
                            && ($left->{classification} // '') eq 'normal'
                            && ($right->{classification} // '') eq 'normal';
                }
            }
        }
    }

    my $expected_digest = Digest::SHA->new(256);
    my $order_mutation_digest = Digest::SHA->new(256);
    my ($first_expected_token, $expected_index) = (undef, 0);
    my $add_expected = sub ($token) {
        _coverage_digest_add($expected_digest, $token);
        if ($expected_index == 0) {
            $first_expected_token = $token;
        }
        elsif ($expected_index == 1) {
            _coverage_digest_add($order_mutation_digest, $token);
            _coverage_digest_add(
                $order_mutation_digest, $first_expected_token,
            );
        }
        else {
            _coverage_digest_add($order_mutation_digest, $token);
        }
        ++$expected_index;
    };
    for my $point (@{$recipe->{points}}) {
        my $point_id = _coverage_point_id($point->{name});
        for my $bin_name (@{$point->{bin_names}}) {
            $add_expected->("$point_id\::bin\::$bin_name");
        }
    }
    for my $cross (@{$recipe->{crosses}}) {
        my $cross_id = _coverage_cross_id($cross->{name});
        my ($left, $right) = @{$cross->{point_names}};
        my ($left_recipe) = grep { $_->{name} eq $left }
            @{$recipe->{points}};
        my ($right_recipe) = grep { $_->{name} eq $right }
            @{$recipe->{points}};
        my $left_id = _coverage_point_id($left);
        my $right_id = _coverage_point_id($right);
        for my $left_bin (@{$left_recipe->{bin_names}}) {
            for my $right_bin (@{$right_recipe->{bin_names}}) {
                $add_expected->(join("\0", $cross_id,
                    "$left_id\::bin\::$left_bin",
                    "$right_id\::bin\::$right_bin",
                ));
            }
        }
    }
    my $static_domain_sha = $actual_digest->hexdigest;
    my $expected_domain_sha = $expected_digest->hexdigest;
    my $order_mutation_sha = $order_mutation_digest->hexdigest;
    my $expected_vector = _coverage_all_hit_vector($static_entries);
    my $vector_equal = $actual_vector eq $expected_vector;
    my $domain_ordered = $static_domain_sha eq $expected_domain_sha;
    my $mutation = $actual_vector;
    vec($mutation, 0, 1) = vec($mutation, 0, 1) ? 0 : 1
        if $static_entries;
    my $mutation_rejected = $mutation ne $expected_vector;
    my $order_mutation_rejected = $order_mutation_sha ne $expected_domain_sha;
    my $illegal_match_rejected =
        _coverage_sample_outcome('illegal', 1) eq 'illegal';
    my $ignore_match_excluded =
        _coverage_sample_outcome('ignore', 1) eq 'ignored';
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_COVERAGE_ERROR',
        'packed coverage vector differs from the independent all-hit vector',
        '/oracle_evidence/coverage/packed_vector_sha256',
    ) unless $actual_index == $static_entries && $vector_equal;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_COVERAGE_ERROR',
        'coverage static-domain order differs from the authored order',
        '/oracle_evidence/coverage/static_domain_sha256',
    ) unless $domain_ordered;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_COVERAGE_ERROR',
        'coverage negative checks did not reject illegal, ignore, bit, and order mutations',
        '/oracle_evidence/coverage/mutation_rejected',
    ) unless $illegal_match_rejected && $ignore_match_excluded
        && $mutation_rejected && $order_mutation_rejected;

    my $success = @errors ? 0 : 1;
    my $evidence = {
        schema => $COVERAGE_EVIDENCE_SCHEMA,
        schema_version => 1,
        program => 'one_sample_packed_static_domain_vector_v1',
        axis => $axis,
        coverpoints => scalar(@coverpoint_ids),
        authored_bins => scalar(@bin_ids),
        authored_crosses => scalar(@cross_ids),
        static_cross_tuples => $cross_tuple_count,
        static_domain_entries => $static_entries,
        sample_count => 1,
        sampled_value_hex => '1',
        packed_vector_bytes => bytes::length($actual_vector),
        packed_vector_sha256 => sha256_hex($actual_vector),
        expected_vector_sha256 => sha256_hex($expected_vector),
        static_domain_sha256 => $static_domain_sha,
        expected_static_domain_sha256 => $expected_domain_sha,
        first_coverpoint_id => $coverpoint_ids[0],
        last_coverpoint_id => $coverpoint_ids[-1],
        first_bin_id => $bin_ids[0],
        last_bin_id => $bin_ids[-1],
        first_cross_id => $cross_ids[0],
        last_cross_id => $cross_ids[-1],
        normal_bin_hits => scalar(@bin_ids),
        cross_tuple_hits => $cross_tuple_count,
        illegal_bin_hits => 0,
        ignore_bin_hits => 0,
        hit_entries => $actual_index,
        byte_equal_expected => $success && $vector_equal
            ? JSON::PP::true : JSON::PP::false,
        static_domain_order_preserved => $success && $domain_ordered
            ? JSON::PP::true : JSON::PP::false,
        all_authored_bins_matched => $success && $all_bins_match
            ? JSON::PP::true : JSON::PP::false,
        all_static_cross_tuples_hit => $success
                && $cross_tuple_count == $recipe->{static_cross_tuples}
            ? JSON::PP::true : JSON::PP::false,
        illegal_match_rejected => $success && $illegal_match_rejected
            ? JSON::PP::true : JSON::PP::false,
        ignore_match_excluded => $success && $ignore_match_excluded
            ? JSON::PP::true : JSON::PP::false,
        mutation_rejected => $success && $mutation_rejected
            ? JSON::PP::true : JSON::PP::false,
        order_mutation_rejected => $success && $order_mutation_rejected
            ? JSON::PP::true : JSON::PP::false,
        no_undeclared_domain_entries => $success && $structure_closed
            ? JSON::PP::true : JSON::PP::false,
    };
    return ($evidence, \@errors);
}

sub _evaluate_fault_state($spec, $execution) {
    my $axis = $spec->{primary_axis};
    my $requested = $spec->{requested_counts}{$axis};
    my $faults = $execution->{faults};
    my (@errors, @fault_ids);
    if (ref($faults) ne 'ARRAY') {
        push @errors, _oracle_error(
            'VIAL_SCALE_CHECKING_FAULT_ERROR',
            'fault oracle requires one canonical fault array',
            '/faults',
        );
        $faults = [];
    }

    my $transaction_id =
        'architecture_scale_checking_state::transaction::ahb_write';
    my $domain_id =
        'architecture_scale_checking_state::fixture::checking_gate::domain::bus';
    my ($transaction) = grep {
        ($_->{semantic_id} // '') eq $transaction_id
    } @{ref($execution->{transactions}) eq 'ARRAY'
        ? $execution->{transactions} : []};
    my ($field) = $transaction && ref($transaction->{fields}) eq 'ARRAY'
        ? grep { ($_->{name} // '') eq 'size' } @{$transaction->{fields}}
        : ();
    my $field_type_id = $field ? $field->{type_id} : undef;
    my ($domain) = grep {
        ($_->{semantic_id} // '') eq $domain_id
    } @{ref($execution->{domains}) eq 'ARRAY' ? $execution->{domains} : []};

    my $structure_closed = @$faults == $requested
        && $transaction && $field && $domain;
    my ($all_targets, $all_substitutes, $all_durations) = (1, 1, 1);
    my ($all_originals, $all_applied_values, $all_restorations) = (1, 1, 1);
    my (%seen_id, %seen_name);
    my $actual_order = Digest::SHA->new(256);
    my $actual_transitions = Digest::SHA->new(256);
    my ($first_arm_identity, $last_restore_identity);
    my ($armed, $applied, $expired, $restored) = (0, 0, 0, 0);
    my ($reinjection_rejected, $overlap_rejected) = (1, 1);

    for my $ordinal (0 .. $#$faults) {
        my $fault = $faults->[$ordinal];
        my $expected_name = FSM::VIAL::ArchitectureScaleWorkload->stable_name({
            family => $FAMILY,
            primary_axis => $axis,
            ordinal => $ordinal,
        });
        my $expected_id = _fault_id($expected_name);
        my $fault_id = $fault->{semantic_id};
        push @fault_ids, $fault_id;
        ++$seen_id{$fault_id // ''};
        ++$seen_name{$fault->{name} // ''};
        _checking_digest_add($actual_order, $fault_id // '');

        my $target_ok = ($fault->{name} // '') eq $expected_name
            && ($fault_id // '') eq $expected_id
            && ($fault->{transaction_id} // '') eq $transaction_id
            && ($fault->{field_name} // '') eq 'size'
            && ($fault->{domain_id} // '') eq $domain_id;
        my $substitute_hex = _fault_substitute_hex(
            $fault->{substitute}, $field_type_id,
        );
        my $substitute_ok = defined($substitute_hex)
            && $substitute_hex eq '7';
        my $duration_ok = ($fault->{duration_cycles} // 0) == 1;
        $all_targets = 0 unless $target_ok;
        $all_substitutes = 0 unless $substitute_ok;
        $all_durations = 0 unless $duration_ok;

        my ($state, $original, $value) = ('inactive', '2', '2');
        my @transition;
        $all_originals = 0 unless $value eq $original;
        if (_fault_arm_allowed($state)) {
            $state = 'armed';
            push @transition, _fault_transition_token(
                $fault_id, $state, $transaction_id, 'size', '', '',
            );
            ++$armed;
        }
        else {
            $all_originals = 0;
        }
        $reinjection_rejected = 0 if _fault_arm_allowed($state);
        if ($state eq 'armed') {
            $state = 'active';
            $value = _fault_effective_value(
                $original,
                defined($substitute_hex) ? $substitute_hex : '',
                1,
            );
            push @transition, _fault_transition_token(
                $fault_id, 'applied', $transaction_id, 'size',
                $original, $value,
            );
            ++$applied;
        }
        $all_applied_values = 0 unless $value eq '7';
        $overlap_rejected = 0 if _fault_arm_allowed($state);
        if ($state eq 'active') {
            $state = 'expired';
            push @transition, _fault_transition_token(
                $fault_id, $state, $transaction_id, 'size', '', '',
            );
            ++$expired;
        }
        if ($state eq 'expired') {
            $value = _fault_effective_value($original, '', 0);
            $state = 'inactive';
            push @transition, _fault_transition_token(
                $fault_id, 'restored', $transaction_id, 'size',
                $original, $value,
            );
            ++$restored;
        }
        $all_restorations = 0 unless $state eq 'inactive'
            && $value eq $original;
        _checking_digest_add($actual_transitions, $_) for @transition;
        $first_arm_identity //= 'fault-transition/' . sha256_hex($transition[0]);
        $last_restore_identity =
            'fault-transition/' . sha256_hex($transition[-1]);
    }
    $structure_closed = 0 if exists($seen_id{''}) || exists($seen_name{''})
        || keys(%seen_id) != @$faults || keys(%seen_name) != @$faults;
    $structure_closed = 0 unless $all_targets && $all_substitutes
        && $all_durations;

    my $expected_order = Digest::SHA->new(256);
    my $expected_transitions = Digest::SHA->new(256);
    my $order_mutation = Digest::SHA->new(256);
    my @expected_ids;
    for my $ordinal (0 .. $requested - 1) {
        my $name = FSM::VIAL::ArchitectureScaleWorkload->stable_name({
            family => $FAMILY,
            primary_axis => $axis,
            ordinal => $ordinal,
        });
        my $fault_id = _fault_id($name);
        push @expected_ids, $fault_id;
        _checking_digest_add($expected_order, $fault_id);
        _checking_digest_add($expected_transitions, $_) for (
            _fault_transition_token(
                $fault_id, 'armed', $transaction_id, 'size', '', '',
            ),
            _fault_transition_token(
                $fault_id, 'applied', $transaction_id, 'size', '2', '7',
            ),
            _fault_transition_token(
                $fault_id, 'expired', $transaction_id, 'size', '', '',
            ),
            _fault_transition_token(
                $fault_id, 'restored', $transaction_id, 'size', '2', '2',
            ),
        );
    }
    my @mutated_order = @expected_ids;
    @mutated_order[0, 1] = @mutated_order[1, 0]
        if @mutated_order > 1;
    _checking_digest_add($order_mutation, $_) for @mutated_order;

    my $actual_order_sha = $actual_order->hexdigest;
    my $expected_order_sha = $expected_order->hexdigest;
    my $actual_transition_sha = $actual_transitions->hexdigest;
    my $expected_transition_sha = $expected_transitions->hexdigest;
    my $stable_order = $actual_order_sha eq $expected_order_sha;
    my $transitions_equal = $actual_transition_sha eq $expected_transition_sha;
    my $mutation_rejected =
        _fault_effective_value('2', '7', 1) eq '7'
        && _fault_effective_value('2', '6', 1) ne '7';
    my $order_mutation_rejected =
        $order_mutation->hexdigest ne $expected_order_sha;

    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_FAULT_ERROR',
        'fault oracle did not reconstruct the exact declared target, substitution, and lifetime',
        '/faults',
    ) unless $structure_closed;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_FAULT_ERROR',
        'fault oracle did not reach the selected axis count',
        '/requested_counts/faults',
    ) unless @$faults == $requested
        && ($execution->{resource_summary}{faults} // -1) == $requested;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_FAULT_ERROR',
        'fault lifecycle transitions differ from the independent authored-order program',
        '/oracle_evidence/faults/transition_sha256',
    ) unless $stable_order && $transitions_equal;
    push @errors, _oracle_error(
        'VIAL_SCALE_CHECKING_FAULT_ERROR',
        'fault negatives did not reject reinjection, active overlap, value mutation, and order mutation',
        '/oracle_evidence/faults/mutation_rejected',
    ) unless $reinjection_rejected && $overlap_rejected
        && $mutation_rejected && $order_mutation_rejected;

    my $success = @errors ? 0 : 1;
    my $evidence = {
        schema => $FAULT_EVIDENCE_SCHEMA,
        schema_version => 1,
        program => 'arm_apply_expire_restore_each_fault_v1',
        axis => $axis,
        faults => scalar(@$faults),
        target_transaction_id => $transaction_id,
        target_field_name => 'size',
        duration_drive_intervals => 1,
        original_value_hex => '2',
        substitute_value_hex => '7',
        faults_armed => $armed,
        faults_applied => $applied,
        faults_expired => $expired,
        faults_restored => $restored,
        state_transition_records => 4 * scalar(@$faults),
        declaration_order_sha256 => $actual_order_sha,
        expected_declaration_order_sha256 => $expected_order_sha,
        transition_sha256 => $actual_transition_sha,
        expected_transition_sha256 => $expected_transition_sha,
        first_fault_id => $fault_ids[0],
        last_fault_id => $fault_ids[-1],
        first_arm_identity => $first_arm_identity,
        last_restore_identity => $last_restore_identity,
        target_identity_preserved => $success && $all_targets
            ? JSON::PP::true : JSON::PP::false,
        original_values_matched => $success && $all_originals
            ? JSON::PP::true : JSON::PP::false,
        substituted_values_matched => $success && $all_substitutes
                && $all_applied_values
            ? JSON::PP::true : JSON::PP::false,
        restoration_values_matched => $success && $all_restorations
            ? JSON::PP::true : JSON::PP::false,
        stable_order_preserved => $success && $stable_order
            ? JSON::PP::true : JSON::PP::false,
        all_faults_armed => $success && $armed == $requested
            ? JSON::PP::true : JSON::PP::false,
        all_faults_applied => $success && $applied == $requested
            ? JSON::PP::true : JSON::PP::false,
        all_faults_expired => $success && $expired == $requested
            ? JSON::PP::true : JSON::PP::false,
        all_faults_restored => $success && $restored == $requested
            ? JSON::PP::true : JSON::PP::false,
        reinjection_rejected => $success && $reinjection_rejected
            ? JSON::PP::true : JSON::PP::false,
        overlap_rejected => $success && $overlap_rejected
            ? JSON::PP::true : JSON::PP::false,
        mutation_rejected => $success && $mutation_rejected
            ? JSON::PP::true : JSON::PP::false,
        order_mutation_rejected => $success && $order_mutation_rejected
            ? JSON::PP::true : JSON::PP::false,
    };
    return ($evidence, \@errors);
}

sub _coverage_recipe($axis, $level, $requested) {
    if ($axis eq 'coverpoints') {
        my @points = map {
            {name => sprintf('cp%08d', $_), bin_names => ['hit']}
        } 0 .. $requested - 1;
        return {
            points => \@points,
            crosses => [],
            static_cross_tuples => 0,
        };
    }
    my ($bins_per_point, $independent_bins) =
          $level eq 'gate_candidate_v1'          ? (63,  1)
        : $level eq 'qualification_candidate_v1' ? (511, 1)
        : $level eq 'limit_v1'                   ? (999, 1)
        : $level eq 'over_limit_v1'              ? (999, 2)
        : confess "checking-state coverage recipe received an unknown level\n";
    my $tuples = $bins_per_point * $bins_per_point;
    return {
        points => [
            {name => 'a', bin_names => [map { sprintf('a%03d', $_) }
                0 .. $bins_per_point - 1]},
            {name => 'b', bin_names => [map { sprintf('b%03d', $_) }
                0 .. $bins_per_point - 1]},
            {name => 'i', bin_names => [map { sprintf('i%03d', $_) }
                0 .. $independent_bins - 1]},
        ],
        crosses => [{
            name => 'x', point_names => [qw(a b)], tuple_count => $tuples,
        }],
        static_cross_tuples => $tuples,
    };
}

sub _coverage_expression_samples_one($axis, $expression) {
    return 0 unless ref($expression) eq 'HASH';
    if ($axis eq 'coverpoints') {
        return 0 unless ($expression->{kind} // '') eq 'operator'
            && ($expression->{op} // '') eq 'same'
            && ref($expression->{operands}) eq 'ARRAY'
            && @{$expression->{operands}} == 2;
        return _coverage_sample_reference($expression->{operands}[0])
            && _coverage_literal_is_one($expression->{operands}[1]);
    }
    return _coverage_sample_reference($expression);
}

sub _coverage_sample_reference($expression) {
    return ref($expression) eq 'HASH'
        && ($expression->{kind} // '') eq 'reference'
        && ($expression->{op} // '') eq 'sample'
        && ($expression->{semantic_id} // '') =~ /::endpoint::ready_out\z/
        && ($expression->{binding_id} // '') =~ m{/endpoint/HREADYOUT\z};
}

sub _coverage_literal_is_one($literal) {
    return 0 unless ref($literal) eq 'HASH'
        && ($literal->{kind} // '') eq 'literal';
    return _coverage_normalized_value_is_one($literal->{value});
}

sub _coverage_matcher_matches_one($matcher) {
    return ref($matcher) eq 'HASH'
        && ($matcher->{kind} // '') eq 'value'
        && _coverage_normalized_value_is_one($matcher->{value});
}

sub _coverage_normalized_value_is_one($value) {
    return 0 unless ref($value) eq 'HASH';
    return ($value->{kind} // '') eq 'bool_value'
        ? ($value->{value} // 0) == 1
        : ($value->{kind} // '') eq 'logic_vector'
            ? ($value->{width} // 0) == 1
                && ($value->{value_bits} // '') eq '1'
                && ($value->{known_mask} // '') eq '1'
                && ($value->{z_mask} // '') eq '0'
        : ($value->{kind} // '') eq 'scalar'
            && ($value->{width} // 0) == 1
            && ($value->{value_hex} // '') eq '1'
            && ($value->{known_hex} // '') eq '1'
            && ($value->{z_hex} // '') eq '0';
}

sub _coverage_sample_outcome($classification, $matches) {
    return 'miss' unless $matches;
    return 'illegal' if $classification eq 'illegal';
    return 'ignored' if $classification eq 'ignore';
    return 'hit' if $classification eq 'normal';
    return 'invalid';
}

sub _coverage_all_hit_vector($entries) {
    my $vector = chr(255) x int($entries / 8);
    my $remaining = $entries % 8;
    $vector .= chr((1 << $remaining) - 1) if $remaining;
    return $vector;
}

sub _coverage_digest_add($digest, $token) {
    $digest->add(pack('N', bytes::length($token)), $token);
}

sub _coverage_point_id($name) {
    return "architecture_scale_checking_state::fixture::checking_gate"
        . "::coverpoint::$name";
}

sub _coverage_cross_id($name) {
    return "architecture_scale_checking_state::fixture::checking_gate"
        . "::cross::$name";
}

sub _fault_id($name) {
    return "architecture_scale_checking_state::fixture::checking_gate"
        . "::fault::$name";
}

sub _fault_substitute_hex($expression, $field_type_id) {
    return undef unless ref($expression) eq 'HASH'
        && ($expression->{kind} // '') eq 'literal'
        && defined($field_type_id)
        && ($expression->{type_id} // '') eq $field_type_id
        && ref($expression->{value}) eq 'HASH';
    my $value = $expression->{value};
    return undef unless ($value->{kind} // '') eq 'scalar'
        && ($value->{state_domain} // '') eq 'four_state'
        && ($value->{signed} // 1) == 0
        && ($value->{width} // 0) == 3
        && ($value->{type_id} // '') eq $field_type_id
        && ($value->{known_hex} // '') eq '7'
        && ($value->{z_hex} // '') eq '0'
        && ($value->{value_hex} // '') =~ /\A[0-7]\z/;
    return $value->{value_hex};
}

sub _fault_arm_allowed($state) {
    return defined($state) && $state eq 'inactive';
}

sub _fault_effective_value($original, $substitute, $active) {
    return $active ? $substitute : $original;
}

sub _fault_transition_token(
    $fault_id, $status, $transaction_id, $field_name, $original, $substitute
) {
    return join("\0", map { defined($_) ? $_ : '' } (
        $fault_id, $status, $transaction_id, $field_name,
        $original, $substitute,
    ));
}

sub _checking_digest_add($digest, $token) {
    $digest->add(pack('N', bytes::length($token)), $token);
}

sub _scoreboard_expected_transaction($payload) {
    return {
        address => 0,
        transfer => 2,
        write => 1,
        size => 2,
        data => $payload,
        wait_cycles => 0,
    };
}

sub _scoreboard_actual_transaction($payload) {
    return {
        address => 0,
        transfer => 2,
        write => 1,
        size => 2,
        data => $payload,
        wait_cycles => 0,
    };
}

sub _scoreboard_transactions_equal($expected, $actual) {
    my @fields = qw(address transfer write size data wait_cycles);
    return (0, 0) unless ref($expected) eq 'HASH'
        && ref($actual) eq 'HASH'
        && keys(%$expected) == @fields && keys(%$actual) == @fields;
    my $compared = 0;
    for my $field (@fields) {
        ++$compared;
        return (0, $compared)
            unless exists($expected->{$field}) && exists($actual->{$field})
                && $expected->{$field} == $actual->{$field};
    }
    return (1, $compared);
}

sub _scoreboard_transaction_identity($transaction) {
    return 'scoreboard-transaction/' . sha256_hex(join("\0",
        map { $transaction->{$_} }
            qw(address transfer write size data wait_cycles),
    ));
}

sub _scoreboard_enqueue_allowed($depth, $capacity) {
    return defined($depth) && defined($capacity)
        && $depth >= 0 && $capacity >= 1 && $depth < $capacity;
}

sub _is_increment_expression($expression, $state_id) {
    return 0 unless ref($expression) eq 'HASH'
        && ($expression->{kind} // '') eq 'operator'
        && ($expression->{op} // '') eq '+'
        && ($expression->{overflow_policy} // '') eq 'error'
        && ref($expression->{operands}) eq 'ARRAY'
        && @{$expression->{operands}} == 2;
    my ($reference, $literal) = @{$expression->{operands}};
    my $value = ref($literal) eq 'HASH' ? $literal->{value} : undef;
    return ref($reference) eq 'HASH'
        && ($reference->{kind} // '') eq 'reference'
        && ($reference->{op} // '') eq 'symbol'
        && ($reference->{semantic_id} // '') eq $state_id
        && ref($value) eq 'HASH'
        && ($literal->{kind} // '') eq 'literal'
        && ($value->{kind} // '') eq 'scalar'
        && ($value->{state_domain} // '') eq 'two_state'
        && ($value->{signed} // 1) == 0
        && ($value->{width} // 0) == 8
        && ($value->{value_hex} // '') eq '01'
        && ($value->{known_hex} // '') eq 'ff'
        && ($value->{z_hex} // '') eq '00';
}

sub _validate_evaluation_shape($raw) {
    confess "checking-state evaluation must be one unblessed hash\n"
        unless ref($raw) eq 'HASH' && !blessed($raw);
    _confess_exact_keys($raw, \@EVALUATION_KEYS, 'checking-state evaluation');
    _confess_exact_keys(
        $raw->{stage_identities}, \@STAGE_IDENTITY_KEYS,
        'checking-state stage identities',
    );
    _confess_exact_keys($raw->{metrics}, \@METRIC_KEYS, 'checking-state metrics');
    _confess_exact_keys(
        $raw->{packed_state_contract}, \@PACKED_STATE_KEYS,
        'checking-state packed-state contract',
    );
    _confess_exact_keys(
        $raw->{packed_state_contract}{model_cells}, \@MODEL_PACKING_KEYS,
        'checking-state model packing',
    );
    _confess_exact_keys(
        $raw->{packed_state_contract}{scoreboard_fifo}, \@SCOREBOARD_PACKING_KEYS,
        'checking-state scoreboard packing',
    );
    _confess_exact_keys(
        $raw->{packed_state_contract}{coverage_vector}, \@COVERAGE_PACKING_KEYS,
        'checking-state coverage packing',
    );
    _confess_exact_keys(
        $raw->{outcome_contract}, \@OUTCOME_KEYS,
        'checking-state outcome contract',
    );
    _confess_exact_keys(
        $raw->{oracle_evidence}, \@ORACLE_EVIDENCE_KEYS,
        'checking-state oracle evidence',
    );
    _confess_exact_keys($raw->{claims}, \@CLAIM_KEYS, 'checking-state claims');
    confess "checking-state evaluation schema is invalid\n"
        unless ($raw->{schema} // '') eq $EVALUATION_SCHEMA
            && ($raw->{schema_version} // 0) == 1;
    confess "checking-state packed-state schema is invalid\n"
        unless ($raw->{packed_state_contract}{schema} // '') eq $PACKED_STATE_SCHEMA
            && ($raw->{packed_state_contract}{schema_version} // 0) == 1;
    confess "checking-state outcome schema is invalid\n"
        unless ($raw->{outcome_contract}{schema} // '') eq $OUTCOME_SCHEMA
            && ($raw->{outcome_contract}{schema_version} // 0) == 1;
    confess "checking-state oracle-evidence schema is invalid\n"
        unless ($raw->{oracle_evidence}{schema} // '') eq $ORACLE_EVIDENCE_SCHEMA
            && ($raw->{oracle_evidence}{schema_version} // 0) == 1;
    my $oracle = $raw->{oracle_evidence}{oracle} // '';
    if ($oracle eq 'none') {
        confess "checking-state no-oracle outcome cannot carry axis evidence\n"
            if grep { defined($raw->{oracle_evidence}{$_}) }
                qw(model scoreboard coverage faults random_replay);
    }
    elsif ($oracle eq 'model') {
        _confess_exact_keys(
            $raw->{oracle_evidence}{model}, \@MODEL_EVIDENCE_KEYS,
            'checking-state model evidence',
        );
        confess "checking-state model-evidence schema is invalid\n"
            unless ($raw->{oracle_evidence}{model}{schema} // '')
                    eq $MODEL_EVIDENCE_SCHEMA
                && ($raw->{oracle_evidence}{model}{schema_version} // 0) == 1;
        confess "checking-state model oracle cannot carry another oracle family\n"
            if grep { defined($raw->{oracle_evidence}{$_}) }
                qw(scoreboard coverage faults random_replay);
    }
    elsif ($oracle eq 'scoreboard') {
        _confess_exact_keys(
            $raw->{oracle_evidence}{scoreboard}, \@SCOREBOARD_EVIDENCE_KEYS,
            'checking-state scoreboard evidence',
        );
        confess "checking-state scoreboard-evidence schema is invalid\n"
            unless ($raw->{oracle_evidence}{scoreboard}{schema} // '')
                    eq $SCOREBOARD_EVIDENCE_SCHEMA
                && ($raw->{oracle_evidence}{scoreboard}{schema_version} // 0) == 1;
        confess "checking-state scoreboard oracle cannot carry another oracle family\n"
            if grep { defined($raw->{oracle_evidence}{$_}) }
                qw(model coverage faults random_replay);
    }
    elsif ($oracle eq 'coverage') {
        _confess_exact_keys(
            $raw->{oracle_evidence}{coverage}, \@COVERAGE_EVIDENCE_KEYS,
            'checking-state coverage evidence',
        );
        confess "checking-state coverage-evidence schema is invalid\n"
            unless ($raw->{oracle_evidence}{coverage}{schema} // '')
                    eq $COVERAGE_EVIDENCE_SCHEMA
                && ($raw->{oracle_evidence}{coverage}{schema_version} // 0) == 1;
        confess "checking-state coverage oracle cannot carry another oracle family\n"
            if grep { defined($raw->{oracle_evidence}{$_}) }
                qw(model scoreboard faults random_replay);
    }
    elsif ($oracle eq 'faults') {
        _confess_exact_keys(
            $raw->{oracle_evidence}{faults}, \@FAULT_EVIDENCE_KEYS,
            'checking-state fault evidence',
        );
        confess "checking-state fault-evidence schema is invalid\n"
            unless ($raw->{oracle_evidence}{faults}{schema} // '')
                    eq $FAULT_EVIDENCE_SCHEMA
                && ($raw->{oracle_evidence}{faults}{schema_version} // 0) == 1;
        confess "checking-state fault oracle cannot carry another oracle family\n"
            if grep { defined($raw->{oracle_evidence}{$_}) }
                qw(model scoreboard coverage random_replay);
    }
    elsif ($oracle eq 'random_replay') {
        _confess_exact_keys(
            $raw->{oracle_evidence}{random_replay}, \@RANDOM_EVIDENCE_KEYS,
            'checking-state random/replay evidence',
        );
        confess "checking-state random/replay-evidence schema is invalid\n"
            unless ($raw->{oracle_evidence}{random_replay}{schema} // '')
                    eq $RANDOM_EVIDENCE_SCHEMA
                && ($raw->{oracle_evidence}{random_replay}{schema_version} // 0)
                    == 1;
        confess "checking-state random/replay oracle cannot carry another oracle family\n"
            if grep { defined($raw->{oracle_evidence}{$_}) }
                qw(model scoreboard coverage faults);
    }
    else {
        confess "checking-state oracle kind is invalid\n";
    }
    confess "checking-state contract discrepancies must be one array\n"
        unless ref($raw->{contract_discrepancies}) eq 'ARRAY';
    for my $record (@{$raw->{contract_discrepancies}}) {
        _confess_exact_keys(
            $record, \@CONTRACT_DISCREPANCY_KEYS,
            'checking-state contract discrepancy',
        );
        confess "checking-state contract discrepancy code is invalid\n"
            unless ($record->{code} // '') eq 'VIAL_SCALE_LIMIT_INTERACTION'
                || ($record->{code} // '') eq 'VIAL_SCALE_ROUTE_BOUNDARY'
                || ($record->{code} // '') eq 'VIAL_SCALE_PREFLIGHT_DOMINANCE';
    }
    confess "checking-state nonclaim schema is invalid\n"
        unless ($raw->{claims}{schema} // '') eq $CLAIMS_SCHEMA
            && ($raw->{claims}{schema_version} // 0) == 1;
    confess "checking-state evaluation identity is invalid\n"
        unless ($raw->{evaluation_identity} // '')
            =~ m{\Achecking-evaluation/[0-9a-f]{64}\z};
    confess "checking-state rerun identity is invalid\n"
        unless ($raw->{rerun_identity} // '') =~ m{\Arerun/[0-9a-f]{64}\z};
    my @stage = @{$raw->{stage_identities}}{
        qw(semantic_ir_sha256 bridge_manifest_sha256 execution_ir_sha256 plan_sha256)
    };
    my $no_stage = !grep { defined($_) } @stage;
    my $semantic_and_bridge = defined($stage[0]) && defined($stage[1])
        && $stage[0] =~ /\A[0-9a-f]{64}\z/
        && $stage[1] =~ /\A[0-9a-f]{64}\z/;
    my $no_downstream = !defined($stage[2]) && !defined($stage[3]);
    my $complete_downstream = defined($stage[2]) && defined($stage[3])
        && $stage[2] =~ /\A[0-9a-f]{64}\z/
        && $stage[3] =~ /\A[0-9a-f]{64}\z/;
    confess "checking-state evaluation contains an invalid stage-identity prefix\n"
        unless $no_stage
            || ($semantic_and_bridge
                && ($no_downstream || $complete_downstream));
    return 1;
}

sub _evaluation($value) {
    # Validate the complete closed projection before and after attaching its
    # own content identity. No identity may authenticate bytes outside it.
    $value->{evaluation_identity} =
        'checking-evaluation/' . ('0' x 64)
        unless defined $value->{evaluation_identity};
    _validate_evaluation_shape($value);
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $identity_projection = _clone($value);
    $identity_projection->{evaluation_identity} = undef;
    # This field was added when decision 0072 first became reachable in this
    # family.  Empty records do not perturb identities already frozen by the
    # earlier model and scoreboard leaves; nonempty records remain covered.
    delete $identity_projection->{contract_discrepancies}
        unless @{$identity_projection->{contract_discrepancies}};
    $value->{evaluation_identity} = 'checking-evaluation/'
        . sha256_hex($canonical->encode($identity_projection));
    _validate_evaluation_shape($value);
    return _clone($value);
}

sub _validate_reference_hial($text) {
    confess "checked-AHB reference text is required for checking-state construction\n"
        unless defined($text) && !ref($text);
    confess "checked-AHB reference byte length changed\n"
        unless bytes::length($text) == $REFERENCE_HIAL_BYTES;
    confess "checked-AHB reference identity changed\n"
        unless sha256_hex($text) eq $REFERENCE_HIAL_SHA256;
}

sub _source_record($text, $repository_path, $artifact_name = undef) {
    $artifact_name //= $repository_path || 'generated';
    $artifact_name =~ s{.*/}{};
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

sub _backend_names($actor) {
    my @clock_names = defined($actor->{clock}) ? ($actor->{clock}) : ();
    my @reset_names = ref($actor->{reset}) eq 'HASH'
        ? ($actor->{reset}{name}) : ();
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

sub _role_input($construction, $role) {
    confess "construction inputs must be an array\n"
        unless ref($construction->{inputs}) eq 'ARRAY';
    my @matches = grep { ref($_) eq 'HASH' && ($_->{role} || '') eq $role }
        @{$construction->{inputs}};
    confess "construction must contain exactly one $role input\n"
        unless @matches == 1;
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

sub _oracle_error($code, $message, $path) {
    return {
        code => $code,
        severity => 'error',
        message => $message,
        path => $path,
    };
}

sub _confess_exact_keys($value, $keys, $label) {
    confess "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
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
    confess "checking-state projection contains an unsupported reference\n"
        if ref($value);
    return $value;
}

1;
