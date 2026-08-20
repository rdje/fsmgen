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

my %OWNED_LEVELS = (
    model_instances => [qw(
        gate_candidate_v1 qualification_candidate_v1 limit_v1 over_limit_v1
    )],
    scalar_model_state_cells => [qw(
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
    confess "checking-state model slice does not own the requested shape\n"
        unless _owns($axis, $level);
    _validate_reference_hial($args[0]{reference_hial_text});
    return __PACKAGE__->_construct_candidate({
        primary_axis => $axis,
        level => $level,
        reference_hial_text => $args[0]{reference_hial_text},
        vial_source_text => _render_model_source(
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
    confess "checking-state candidate source did not fit the construction contract\n"
        unless $constructed->{ok};
    return $constructed;
}

sub build($class, @args) {
    _exact_invocant($class, 'build');
    confess __PACKAGE__ . "->build expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'checking-state build');
    my $inputs = _canonical_inputs($args[0]{construction});
    return FSM::VIAL::ExecutionBuilder->build($inputs->{arguments});
}

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'checking-state evaluation');
    my $construction = _validated_construction($args[0]{construction});
    return _evaluate_model_axis($construction)
        if _is_generated_model_construction($construction);

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
        diagnostics => \@diagnostics,
    });
}

sub _is_generated_model_construction($construction) {
    my $vial = _role_input($construction, 'vial_source');
    return 0 if sha256_hex($vial->{content}) eq $REFERENCE_VIAL_SHA256;
    my $spec = $construction->{specification};
    my ($axis, $level) = @{$spec}{qw(primary_axis level)};
    return 0 unless _owns($axis, $level);
    my $requested = _selected_contract($axis, $level);
    my $expected = _render_model_source($axis, $level, $requested->{$axis});
    confess "generated checking-state model source is not canonical\n"
        unless $vial->{content} eq $expected;
    return 1;
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
        diagnostics => \@diagnostics,
    });
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

sub _owns($axis, $level) {
    return 0 unless defined($axis) && defined($level) && $OWNED_LEVELS{$axis};
    return scalar(grep { $_ eq $level } @{$OWNED_LEVELS{$axis}});
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
    confess "construction must be successful and carry one specification hash\n"
        unless $raw->{ok}
            && ref($specification) eq 'HASH' && !blessed($specification);
    my $rebuilt = _construct_candidate_internal({
        primary_axis => $specification->{primary_axis},
        level => $specification->{level},
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

sub _oracle_evidence($oracle, $model) {
    return {
        schema => $ORACLE_EVIDENCE_SCHEMA,
        schema_version => 1,
        oracle => $oracle,
        model => _clone($model),
        scoreboard => undef,
        coverage => undef,
        faults => undef,
        random_replay => undef,
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
    else {
        confess "checking-state oracle kind is invalid\n";
    }
    confess "checking-state nonclaim schema is invalid\n"
        unless ($raw->{claims}{schema} // '') eq $CLAIMS_SCHEMA
            && ($raw->{claims}{schema_version} // 0) == 1;
    confess "checking-state evaluation identity is invalid\n"
        unless ($raw->{evaluation_identity} // '')
            =~ m{\Achecking-evaluation/[0-9a-f]{64}\z};
    confess "checking-state rerun identity is invalid\n"
        unless ($raw->{rerun_identity} // '') =~ m{\Arerun/[0-9a-f]{64}\z};
    confess "checking-state evaluation contains an invalid source-stage identity\n"
        if grep { ($raw->{stage_identities}{$_} // '') !~ /\A[0-9a-f]{64}\z/ }
            qw(semantic_ir_sha256 bridge_manifest_sha256);
    my @downstream = @{$raw->{stage_identities}}{
        qw(execution_ir_sha256 plan_sha256)
    };
    confess "checking-state evaluation contains an invalid downstream-stage identity\n"
        unless (!defined($downstream[0]) && !defined($downstream[1]))
            || (defined($downstream[0]) && defined($downstream[1])
                && $downstream[0] =~ /\A[0-9a-f]{64}\z/
                && $downstream[1] =~ /\A[0-9a-f]{64}\z/);
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
