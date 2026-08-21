package FSM::VIAL::ArchitectureScaleBackendEmission;

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

use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::ArchitectureScaleBackendEmission::PortableSV;
use FSM::VIAL::ArchitectureScaleBackendEmission::PortableVHDL;
use FSM::VIAL::ArchitectureScaleBackendEmission::OSVVM;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $FAMILY = 'backend_emission_v1';
my $PRIMARY_AXIS = 'artifact_graph';
my $EXECUTION_PROFILE = 'core_directed_single_clock_execution_v1';
my $HIAL_SOURCE = 'ppif/ahb_lite_subordinate.ppif';
my $HIAL_BYTES = 1_326;
my $HIAL_SHA256 =
    '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c';
my $VIAL_SOURCE = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $VIAL_BYTES = 4_986;
my $VIAL_SHA256 =
    '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd';
my $EVALUATION_SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_evaluation.v1';
my $OUTCOME_SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_outcome.v1';
my $ORACLE_SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_artifact_oracle.v1';
my $CLAIMS_SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_claims.v1';
my $PORTABLE_SV_CLASS =
    'FSM::VIAL::ArchitectureScaleBackendEmission::PortableSV';
my $PORTABLE_SV_PROFILE = $PORTABLE_SV_CLASS->profile;
my $PORTABLE_VHDL_CLASS =
    'FSM::VIAL::ArchitectureScaleBackendEmission::PortableVHDL';
my $PORTABLE_VHDL_PROFILE = $PORTABLE_VHDL_CLASS->profile;
my $OSVVM_CLASS =
    'FSM::VIAL::ArchitectureScaleBackendEmission::OSVVM';
my $OSVVM_PROFILE = $OSVVM_CLASS->profile;

my @PROFILES = qw(
    sv_portable_verilator
    vhdl_portable_ghdl
    vhdl_osvvm_qualified
    sv_uvm_emit.accellera_2020_3_1
);
my @LEVELS = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1 limit_v1
    over_limit_v1
);
my %PROFILE = map { $_ => 1 } @PROFILES;
my %LEVEL = map { $_ => 1 } @LEVELS;

my %OWNED_LEVELS = map { $_ => [] } @PROFILES;
$OWNED_LEVELS{$PORTABLE_SV_PROFILE} = $PORTABLE_SV_CLASS->owned_levels;
$OWNED_LEVELS{$PORTABLE_VHDL_PROFILE} = $PORTABLE_VHDL_CLASS->owned_levels;
$OWNED_LEVELS{$OSVVM_PROFILE} = $OSVVM_CLASS->owned_levels;

my @CONSTRUCT_KEYS = qw(
    backend_profile level reference_hial_text reference_vial_text
);
my @BUILD_KEYS = qw(construction);
my @STAGING_KEYS = qw(construction consumer repository_root);
my @VALIDATE_KEYS = qw(construction evaluation);
my @EVALUATION_KEYS = qw(
    ok status schema schema_version evaluation_identity rerun_identity
    workload_identity family level primary_axis backend_profile
    requested_counts observed_outcome stage_identities route_metrics
    outcome_contract artifact_oracle claims explicit_nonclaims diagnostics
);
my @STAGE_KEYS = qw(
    semantic_ir_sha256 bridge_manifest_sha256 execution_ir_sha256
    backend_inputs_sha256 plan_sha256
);
my @METRIC_KEYS = qw(
    scenarios operations_total fibers_total simultaneously_live_fibers
    source_map_entries serialized_plan_bytes backend_input_artifacts
);
my @OUTCOME_KEYS = qw(
    schema schema_version observed_outcome backend_negotiation_executed
    artifacts_emitted backend_shape_owned canonical_stages_completed
);
my @ORACLE_KEYS = qw(
    schema schema_version oracle portable_sv portable_vhdl osvvm native_uvm
);
my @CLAIM_KEYS = qw(
    schema schema_version qualification_only backend_shape_owned
    artifact_graph_claimed capability_claimed support_claimed
    performance_claimed capacity_claimed external_runtime_executed
);

sub owned_shapes($class) {
    _exact_invocant($class, 'owned_shapes');
    return [map {
        my $profile = $_;
        map {{backend_profile => $profile, level => $_}}
            @{$OWNED_LEVELS{$profile}}
    } @PROFILES];
}

sub evaluation_keys($class) {
    _exact_invocant($class, 'evaluation_keys');
    return [@EVALUATION_KEYS];
}

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    confess __PACKAGE__ . "->construct expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $raw = $args[0];
    _confess_exact_keys($raw, \@CONSTRUCT_KEYS, 'backend-emission construction');
    _validate_selection($raw->{backend_profile}, $raw->{level});
    confess "active slices do not own the requested backend shape\n"
        unless _owns($raw->{backend_profile}, $raw->{level});
    return _construct_candidate_internal($raw);
}

sub _construct_candidate($class, @args) {
    confess "candidate construction is private\n"
        unless caller eq __PACKAGE__;
    _exact_invocant($class, '_construct_candidate');
    confess __PACKAGE__ . "->_construct_candidate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    return _construct_candidate_internal($args[0]);
}

sub _construct_candidate_internal($raw) {
    confess "candidate internals are private\n"
        unless caller eq __PACKAGE__;
    _confess_exact_keys($raw, \@CONSTRUCT_KEYS, 'backend-emission candidate');
    _validate_selection($raw->{backend_profile}, $raw->{level});
    confess "backend-emission foundation accepts reference_v1 only outside an owned profile ladder\n"
        unless $raw->{level} eq 'reference_v1'
            || _owns($raw->{backend_profile}, $raw->{level});
    _validate_reference_source(
        $raw->{reference_hial_text}, $HIAL_BYTES, $HIAL_SHA256,
        'checked-AHB HIAL',
    );
    _validate_reference_source(
        $raw->{reference_vial_text}, $VIAL_BYTES, $VIAL_SHA256,
        'checked-AHB VIAL',
    );
    my $construction = FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $FAMILY,
        level => $raw->{level},
        primary_axis => $PRIMARY_AXIS,
        backend_profile => $raw->{backend_profile},
        tool_profile => undef,
        inputs => [
            _input($HIAL_SOURCE, 'hial_source', $raw->{reference_hial_text}),
            _input($VIAL_SOURCE, 'vial_source', $raw->{reference_vial_text}),
        ],
    });
    confess "canonical backend-emission workload construction failed\n"
        unless $construction->{ok};
    return $construction;
}

sub build($class, @args) {
    _exact_invocant($class, 'build');
    confess __PACKAGE__ . "->build expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@BUILD_KEYS, 'backend-emission build');
    my $construction = _validated_construction($args[0]{construction});
    return _canonical_route_from_construction($construction);
}

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@BUILD_KEYS, 'backend-emission evaluation');
    my $construction = _validated_construction($args[0]{construction});
    return _evaluate_validated($construction);
}

sub validate_evaluation($class, @args) {
    _exact_invocant($class, 'validate_evaluation');
    confess __PACKAGE__ . "->validate_evaluation expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@VALIDATE_KEYS,
        'backend-emission evaluation validation');
    my $construction = _validated_construction($args[0]{construction});
    my $evaluation = $args[0]{evaluation};
    _validate_evaluation_shape($evaluation);
    my $rebuilt = _evaluate_validated($construction);
    confess "evaluation is not canonical\n"
        unless _canonical_json($evaluation) eq _canonical_json($rebuilt);
    return _clone($rebuilt);
}

sub with_staging($class, @args) {
    _exact_invocant($class, 'with_staging');
    confess __PACKAGE__ . "->with_staging expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@STAGING_KEYS,
        'backend-emission staging');
    my $construction = _validated_construction($args[0]{construction});
    return FSM::VIAL::ArchitectureScaleWorkload->with_staging({
        construction => $construction,
        consumer => $args[0]{consumer},
        repository_root => $args[0]{repository_root},
    });
}

sub _evaluate_foundation_candidate($class, @args) {
    confess "foundation candidate evaluation is private\n"
        unless caller eq __PACKAGE__;
    _exact_invocant($class, '_evaluate_foundation_candidate');
    confess __PACKAGE__
        . "->_evaluate_foundation_candidate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@BUILD_KEYS,
        'backend-emission foundation candidate evaluation');
    my $construction = _validated_construction($args[0]{construction});
    return _evaluate_validated($construction, 1);
}

sub _validate_foundation_candidate($class, @args) {
    confess "foundation candidate validation is private\n"
        unless caller eq __PACKAGE__;
    _exact_invocant($class, '_validate_foundation_candidate');
    confess __PACKAGE__
        . "->_validate_foundation_candidate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@VALIDATE_KEYS,
        'backend-emission foundation candidate validation');
    my $construction = _validated_construction($args[0]{construction});
    _validate_evaluation_shape($args[0]{evaluation});
    my $rebuilt = _evaluate_validated($construction, 1);
    confess "evaluation is not canonical\n"
        unless _canonical_json($args[0]{evaluation})
            eq _canonical_json($rebuilt);
    return _clone($rebuilt);
}

sub _evaluate_validated($construction, $foundation_only = 0) {
    my $first = _canonical_route_from_construction(
        $construction, $foundation_only,
    );
    my $second = _canonical_route_from_construction(
        $construction, $foundation_only,
    );
    confess "canonical backend-emission foundation route was rejected\n"
        unless $first->{ok} && $second->{ok};

    my $first_projection = _route_projection($first);
    my $second_projection = _route_projection($second);
    my @diagnostics;
    for my $stage (qw(
        semantic_ir bridge_manifest execution_ir backend_inputs plan
    )) {
        push @diagnostics, _oracle_error(
            'VIAL_SCALE_BACKEND_FOUNDATION_DETERMINISM_ERROR',
            "independent canonical $stage production was not byte-identical",
            "/$stage",
        ) unless _canonical_json($first_projection->{$stage})
            eq _canonical_json($second_projection->{$stage});
    }

    my $stage_identities = {
        semantic_ir_sha256 =>
            sha256_hex(_canonical_json($first_projection->{semantic_ir})),
        bridge_manifest_sha256 =>
            sha256_hex(_canonical_json($first_projection->{bridge_manifest})),
        execution_ir_sha256 =>
            sha256_hex(_canonical_json($first_projection->{execution_ir})),
        backend_inputs_sha256 =>
            sha256_hex(_canonical_json($first_projection->{backend_inputs})),
        plan_sha256 => sha256_hex(_canonical_json($first_projection->{plan})),
    };
    my $rerun_identity = 'rerun/' . sha256_hex(_canonical_json({
        first => $stage_identities,
        second => {
            semantic_ir_sha256 =>
                sha256_hex(_canonical_json($second_projection->{semantic_ir})),
            bridge_manifest_sha256 =>
                sha256_hex(_canonical_json($second_projection->{bridge_manifest})),
            execution_ir_sha256 =>
                sha256_hex(_canonical_json($second_projection->{execution_ir})),
            backend_inputs_sha256 =>
                sha256_hex(_canonical_json($second_projection->{backend_inputs})),
            plan_sha256 =>
                sha256_hex(_canonical_json($second_projection->{plan})),
        },
    }));
    if (!$foundation_only
            && $construction->{specification}{backend_profile}
            eq $PORTABLE_SV_PROFILE
            && _owns(
                $construction->{specification}{backend_profile},
                $construction->{specification}{level},
            )) {
        return _evaluate_portable_sv(
            $construction, $first, $second, $first_projection,
            $stage_identities, $rerun_identity, \@diagnostics,
        );
    }
    if (!$foundation_only
            && $construction->{specification}{backend_profile}
            eq $PORTABLE_VHDL_PROFILE
            && _owns(
                $construction->{specification}{backend_profile},
                $construction->{specification}{level},
            )) {
        return _evaluate_portable_vhdl(
            $construction, $first, $second, $first_projection,
            $stage_identities, $rerun_identity, \@diagnostics,
        );
    }
    if (!$foundation_only
            && $construction->{specification}{backend_profile}
            eq $OSVVM_PROFILE
            && _owns(
                $construction->{specification}{backend_profile},
                $construction->{specification}{level},
            )) {
        return _evaluate_osvvm(
            $construction, $first, $second, $first_projection,
            $stage_identities, $rerun_identity, \@diagnostics,
        );
    }
    my $execution = $first_projection->{execution_ir};
    my $report = {
        ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
        status => @diagnostics ? 'determinism_failure' : 'foundation_validated',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        evaluation_identity => undef,
        rerun_identity => $rerun_identity,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $construction->{specification}{level},
        primary_axis => $PRIMARY_AXIS,
        backend_profile => $construction->{specification}{backend_profile},
        requested_counts =>
            _clone($construction->{specification}{requested_counts}),
        observed_outcome => 'execution_ir_accepted_emission_not_evaluated',
        stage_identities => $stage_identities,
        route_metrics => {
            scenarios => scalar(@{$execution->{scenarios}}),
            operations_total =>
                0 + $execution->{operation_graph}{total_operation_count},
            fibers_total =>
                0 + $execution->{operation_graph}{total_fiber_count},
            simultaneously_live_fibers =>
                0 + $execution->{operation_graph}
                    {maximum_simultaneous_live_fibers},
            source_map_entries => scalar(@{$execution->{source_map}}),
            serialized_plan_bytes =>
                bytes::length(_canonical_json($first_projection->{plan})),
            backend_input_artifacts =>
                _backend_input_artifact_count($first_projection->{backend_inputs}),
        },
        outcome_contract => {
            schema => $OUTCOME_SCHEMA,
            schema_version => 1,
            observed_outcome =>
                'execution_ir_accepted_emission_not_evaluated',
            backend_negotiation_executed => JSON::PP::false,
            artifacts_emitted => JSON::PP::false,
            backend_shape_owned => JSON::PP::false,
            canonical_stages_completed =>
                [qw(semantic bridge backend_inputs execution_ir plan)],
        },
        artifact_oracle => {
            schema => $ORACLE_SCHEMA,
            schema_version => 1,
            oracle => 'none',
            portable_sv => undef,
            portable_vhdl => undef,
            osvvm => undef,
            native_uvm => undef,
        },
        claims => {
            schema => $CLAIMS_SCHEMA,
            schema_version => 1,
            qualification_only => JSON::PP::true,
            backend_shape_owned => JSON::PP::false,
            artifact_graph_claimed => JSON::PP::false,
            capability_claimed => JSON::PP::false,
            support_claimed => JSON::PP::false,
            performance_claimed => JSON::PP::false,
            capacity_claimed => JSON::PP::false,
            external_runtime_executed => JSON::PP::false,
        },
        explicit_nonclaims =>
            _clone($construction->{specification}{explicit_nonclaims}),
        diagnostics => \@diagnostics,
    };
    my $identity_projection = _clone($report);
    delete $identity_projection->{evaluation_identity};
    $report->{evaluation_identity} = 'backend-emission-evaluation/'
        . sha256_hex(_canonical_json($identity_projection));
    return _clone($report);
}

sub _evaluate_portable_sv(
    $construction, $first_route, $second_route, $first_projection,
    $stage_identities, $rerun_identity, $route_diagnostics,
) {
    return _evaluate_owned_profile(
        $construction, $first_route, $second_route, $first_projection,
        $stage_identities, $rerun_identity, $route_diagnostics,
        $PORTABLE_SV_CLASS, $PORTABLE_SV_PROFILE,
        'portable_sv', 'portable_sv_artifact_graph_v1',
    );
}

sub _evaluate_portable_vhdl(
    $construction, $first_route, $second_route, $first_projection,
    $stage_identities, $rerun_identity, $route_diagnostics,
) {
    return _evaluate_owned_profile(
        $construction, $first_route, $second_route, $first_projection,
        $stage_identities, $rerun_identity, $route_diagnostics,
        $PORTABLE_VHDL_CLASS, $PORTABLE_VHDL_PROFILE,
        'portable_vhdl', 'portable_vhdl_artifact_graph_v1',
    );
}

sub _evaluate_osvvm(
    $construction, $first_route, $second_route, $first_projection,
    $stage_identities, $rerun_identity, $route_diagnostics,
) {
    return _evaluate_owned_profile(
        $construction, $first_route, $second_route, $first_projection,
        $stage_identities, $rerun_identity, $route_diagnostics,
        $OSVVM_CLASS, $OSVVM_PROFILE,
        'osvvm', 'vhdl_osvvm_qualified_artifact_graph_v1',
    );
}

sub _evaluate_owned_profile(
    $construction, $first_route, $second_route, $first_projection,
    $stage_identities, $rerun_identity, $route_diagnostics,
    $profile_class, $profile, $oracle_slot, $oracle_name,
) {
    my $level = $construction->{specification}{level};
    my $profile_evaluation = $profile_class->evaluate({
        construction => $construction,
        first_route => $first_route,
        second_route => $second_route,
    });
    my @diagnostics = @$route_diagnostics;
    push @diagnostics, @{$profile_evaluation->{diagnostics}};
    my $rejected = $profile_evaluation->{rejected};
    my $observed_outcome = $profile_evaluation->{observed_outcome};
    my $execution = $first_projection->{execution_ir};
    my $report = {
        ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
        status => @diagnostics ? 'profile_oracle_failure' : 'profile_validated',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        evaluation_identity => undef,
        rerun_identity => $rerun_identity,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $level,
        primary_axis => $PRIMARY_AXIS,
        backend_profile => $profile,
        requested_counts =>
            _clone($construction->{specification}{requested_counts}),
        observed_outcome => $observed_outcome,
        stage_identities => _clone($stage_identities),
        route_metrics => {
            scenarios => scalar(@{$execution->{scenarios}}),
            operations_total =>
                0 + $execution->{operation_graph}{total_operation_count},
            fibers_total =>
                0 + $execution->{operation_graph}{total_fiber_count},
            simultaneously_live_fibers =>
                0 + $execution->{operation_graph}
                    {maximum_simultaneous_live_fibers},
            source_map_entries => scalar(@{$execution->{source_map}}),
            serialized_plan_bytes =>
                bytes::length(_canonical_json($first_projection->{plan})),
            backend_input_artifacts =>
                _backend_input_artifact_count(
                    $first_projection->{backend_inputs}),
        },
        outcome_contract => {
            schema => $OUTCOME_SCHEMA,
            schema_version => 1,
            observed_outcome => $observed_outcome,
            backend_negotiation_executed => JSON::PP::true,
            artifacts_emitted =>
                $rejected ? JSON::PP::false : JSON::PP::true,
            backend_shape_owned => JSON::PP::true,
            canonical_stages_completed =>
                [qw(semantic bridge backend_inputs execution_ir plan emit)],
        },
        artifact_oracle => {
            schema => $ORACLE_SCHEMA,
            schema_version => 1,
            oracle => $oracle_name,
            portable_sv => undef,
            portable_vhdl => undef,
            osvvm => undef,
            native_uvm => undef,
        },
        claims => {
            schema => $CLAIMS_SCHEMA,
            schema_version => 1,
            qualification_only => JSON::PP::true,
            backend_shape_owned => JSON::PP::true,
            artifact_graph_claimed =>
                $rejected ? JSON::PP::false : JSON::PP::true,
            capability_claimed => JSON::PP::false,
            support_claimed => JSON::PP::false,
            performance_claimed => JSON::PP::false,
            capacity_claimed => JSON::PP::false,
            external_runtime_executed => JSON::PP::false,
        },
        explicit_nonclaims =>
            _clone($construction->{specification}{explicit_nonclaims}),
        diagnostics => \@diagnostics,
    };
    $report->{artifact_oracle}{$oracle_slot} = $profile_evaluation->{oracle};
    my $identity_projection = _clone($report);
    delete $identity_projection->{evaluation_identity};
    $report->{evaluation_identity} = 'backend-emission-evaluation/'
        . sha256_hex(_canonical_json($identity_projection));
    return _clone($report);
}

sub _canonical_route_from_construction($construction, $foundation_only = 0) {
    my $hial = _role_input($construction, 'hial_source');
    my $vial = _role_input($construction, 'vial_source');
    my ($vial_source_name, $vial_text) = $foundation_only
        ? ($vial->{relative_path}, $vial->{content})
        : _canonical_vial_source($construction, $vial);
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $vial_text,
        source_name => $vial_source_name,
        source_catalog => {},
    });
    my $built = FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial->{relative_path},
            text => $hial->{content},
            format => 'ppif',
        },
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => $EXECUTION_PROFILE,
        replay_manifest => undef,
        native_extension_catalog => [],
    });
    return {
        ok => $built->{ok} ? JSON::PP::true : JSON::PP::false,
        semantic_ir => $semantic_ir,
        bridge_manifest => $built->{bridge_manifest},
        execution_ir => $built->{execution_ir},
        backend_inputs => $built->{backend_inputs},
        plan => $built->{plan},
        diagnostics => _clone($built->{diagnostics}),
    };
}

sub _canonical_vial_source($construction, $vial) {
    my $spec = $construction->{specification};
    for my $profile_class (
        [$PORTABLE_SV_PROFILE, $PORTABLE_SV_CLASS],
        [$PORTABLE_VHDL_PROFILE, $PORTABLE_VHDL_CLASS],
        [$OSVVM_PROFILE, $OSVVM_CLASS],
    ) {
        next unless $spec->{backend_profile} eq $profile_class->[0];
        return @{$profile_class->[1]->canonical_vial_source({
            level => $spec->{level},
            reference_relative_path => $vial->{relative_path},
            reference_text => $vial->{content},
        })};
    }
    return ($vial->{relative_path}, $vial->{content});
}

sub _route_projection($route) {
    return {
        semantic_ir => $route->{semantic_ir}->as_hashref,
        bridge_manifest => $route->{bridge_manifest}->as_hashref,
        execution_ir => $route->{execution_ir}->as_hashref,
        backend_inputs => _clone($route->{backend_inputs}),
        plan => _clone($route->{plan}),
    };
}

sub _validated_construction($raw) {
    confess "construction must be one unblessed hash\n"
        unless ref($raw) eq 'HASH' && !blessed($raw);
    my $spec = $raw->{specification};
    confess "construction must carry one specification hash\n"
        unless ref($spec) eq 'HASH' && !blessed($spec);
    confess "construction must be successful\n" unless $raw->{ok};
    my $rebuilt = eval { _construct_candidate_internal({
        backend_profile => $spec->{backend_profile},
        level => $spec->{level},
        reference_hial_text => _role_input($raw, 'hial_source')->{content},
        reference_vial_text => _role_input($raw, 'vial_source')->{content},
    }) };
    confess "construction is not canonical\n" unless defined $rebuilt;
    confess "construction is not canonical\n"
        unless _canonical_json($rebuilt) eq _canonical_json($raw);
    return $rebuilt;
}

sub _validate_evaluation_shape($evaluation) {
    _confess_exact_keys($evaluation, \@EVALUATION_KEYS,
        'backend-emission evaluation');
    _confess_exact_keys($evaluation->{stage_identities}, \@STAGE_KEYS,
        'backend-emission stage identities');
    _confess_exact_keys($evaluation->{route_metrics}, \@METRIC_KEYS,
        'backend-emission route metrics');
    _confess_exact_keys($evaluation->{outcome_contract}, \@OUTCOME_KEYS,
        'backend-emission outcome contract');
    _confess_exact_keys($evaluation->{artifact_oracle}, \@ORACLE_KEYS,
        'backend-emission artifact oracle');
    _confess_exact_keys(
        $evaluation->{artifact_oracle}{portable_sv},
        $PORTABLE_SV_CLASS->oracle_keys,
        'portable-SystemVerilog artifact oracle',
    ) if defined $evaluation->{artifact_oracle}{portable_sv};
    _confess_exact_keys(
        $evaluation->{artifact_oracle}{portable_vhdl},
        $PORTABLE_VHDL_CLASS->oracle_keys,
        'portable-VHDL artifact oracle',
    ) if defined $evaluation->{artifact_oracle}{portable_vhdl};
    _confess_exact_keys(
        $evaluation->{artifact_oracle}{osvvm},
        $OSVVM_CLASS->oracle_keys,
        'OSVVM-qualified artifact oracle',
    ) if defined $evaluation->{artifact_oracle}{osvvm};
    _confess_exact_keys($evaluation->{claims}, \@CLAIM_KEYS,
        'backend-emission claims');
    confess "backend-emission evaluation diagnostics must be an array\n"
        unless ref($evaluation->{diagnostics}) eq 'ARRAY';
    confess "backend-emission explicit nonclaims must be an array\n"
        unless ref($evaluation->{explicit_nonclaims}) eq 'ARRAY';
}

sub _validate_selection($profile, $level) {
    confess "unknown backend-emission profile '" . _display($profile) . "'\n"
        unless defined($profile) && !ref($profile) && $PROFILE{$profile};
    confess "unknown backend-emission level '" . _display($level) . "'\n"
        unless defined($level) && !ref($level) && $LEVEL{$level};
}

sub _validate_reference_source($text, $bytes, $digest, $label) {
    confess "$label text must be a scalar\n"
        unless defined($text) && !ref($text);
    confess "$label byte length changed\n"
        unless bytes::length($text) == $bytes;
    confess "$label identity changed\n"
        unless sha256_hex($text) eq $digest;
}

sub _owns($profile, $level) {
    return 0 unless defined($profile) && defined($level)
        && $OWNED_LEVELS{$profile};
    return scalar(grep { $_ eq $level } @{$OWNED_LEVELS{$profile}});
}

sub _backend_input_artifact_count($inputs) {
    confess "backend inputs must be one hash\n" unless ref($inputs) eq 'HASH';
    my $count = 0;
    for my $key (sort keys %$inputs) {
        confess "backend input family '$key' must be an array\n"
            unless ref($inputs->{$key}) eq 'ARRAY';
        $count += @{$inputs->{$key}};
    }
    return $count;
}

sub _role_input($construction, $role) {
    confess "construction inputs must be an array\n"
        unless ref($construction->{inputs}) eq 'ARRAY';
    my @matches = grep {
        ref($_) eq 'HASH' && ($_->{role} || '') eq $role
    } @{$construction->{inputs}};
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

sub _display($value) {
    return '<undefined>' unless defined $value;
    return '<reference>' if ref $value;
    return $value;
}

sub _canonical_json($value) {
    return JSON::PP->new->canonical(1)->allow_nonref(1)->encode($value);
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess "backend-emission projection contains an unsupported reference\n"
        if ref($value);
    return $value;
}

1;
