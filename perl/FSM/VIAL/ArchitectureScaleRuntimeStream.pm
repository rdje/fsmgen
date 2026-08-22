package FSM::VIAL::ArchitectureScaleRuntimeStream;

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

use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::VIAL::ArchitectureScaleWorkload;

my $FAMILY = 'runtime_stream_v1';
my $PRIMARY_AXIS = 'runtime_trace_records';
my $HIAL_SOURCE = 'ppif/ahb_lite_subordinate.ppif';
my $HIAL_BYTES = 1_326;
my $HIAL_SHA256 =
    '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c';
my $VIAL_SOURCE = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $VIAL_BYTES = 4_986;
my $VIAL_SHA256 =
    '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd';
my $REPORT_SCHEMA =
    'fsmgen.vial_architecture_scale_runtime_stream_report.v1';
my $HANDOFF_SCHEMA =
    'fsmgen.vial_architecture_scale_runtime_backend_handoff.v1';
my $COMPILE_SCHEMA =
    'fsmgen.vial_architecture_scale_runtime_compile_expectation.v1';
my $RUN_SCHEMA =
    'fsmgen.vial_architecture_scale_runtime_run_expectation.v1';
my $TRACE_SCHEMA =
    'fsmgen.vial_architecture_scale_runtime_trace_expectation.v1';
my $RESULT_SCHEMA =
    'fsmgen.vial_architecture_scale_runtime_result_expectation.v1';
my $CLAIMS_SCHEMA =
    'fsmgen.vial_architecture_scale_runtime_stream_claims.v1';

my @PROFILES = qw(
    sv_portable_verilator
    vhdl_portable_ghdl
    vhdl_osvvm_qualified
);
my @LEVELS = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1 limit_v1
    over_limit_v1
);
my %PROFILE = map { $_ => 1 } @PROFILES;
my %LEVEL = map { $_ => 1 } @LEVELS;
my %PROFILE_CONTRACT = (
    sv_portable_verilator => {
        tool_profile => 'verilator_5_046',
        logical_tool => 'verilator',
        qualified_version => '5.046',
        provider => 'none',
        backend_schema => 'fsmgen.vial_backend.sv_portable_verilator.v1',
        trace_schema => 'fsmgen.vial_sv_runtime_trace.v1',
        trace_projection_schema => 'fsmgen.vial_sv_trace_projection.v1',
        trace_authority => 'FSM::VIAL::Backend::TraceValidator',
        result_authority => 'FSM::VIAL::Backend::ResultProducer',
        compile_command_authorities => [
            'backends/sv_portable_verilator/commands/compile-command.json',
        ],
        run_command_authority =>
            'backends/sv_portable_verilator/commands/run-command.json',
        analysis_timeout_seconds => 120,
        elaboration_timeout_seconds => undef,
        run_timeout_seconds => 30,
    },
    vhdl_portable_ghdl => {
        tool_profile => 'ghdl_6_0_0_llvm_jit',
        logical_tool => 'ghdl',
        qualified_version => '6.0.0',
        provider => 'none',
        backend_schema => 'fsmgen.vial_backend.vhdl_portable.v1',
        trace_schema => 'fsmgen.vial_vhdl_runtime_trace.v1',
        trace_projection_schema => undef,
        trace_authority =>
            'FSM::VIAL::Backend::VHDLPortableGHDLQualification',
        result_authority =>
            'FSM::VIAL::Backend::VHDLPortableGHDLQualification',
        compile_command_authorities => [
            'backends/vhdl_portable_ghdl/commands/analyze-command.json',
            'backends/vhdl_portable_ghdl/commands/elaborate-command.json',
        ],
        run_command_authority =>
            'backends/vhdl_portable_ghdl/commands/run-command.json',
        analysis_timeout_seconds => 120,
        elaboration_timeout_seconds => 60,
        run_timeout_seconds => 30,
    },
    vhdl_osvvm_qualified => {
        tool_profile => 'osvvm_2026_05_ghdl_6_0_0_llvm_jit',
        logical_tool => 'ghdl',
        qualified_version => '6.0.0',
        provider => 'OSVVM 2026.05',
        backend_schema => 'fsmgen.vial_backend.vhdl_osvvm.v1',
        trace_schema => 'fsmgen.vial_vhdl_runtime_trace.v1',
        trace_projection_schema => undef,
        trace_authority =>
            'FSM::VIAL::Backend::VHDLOSVVMGHDLQualification',
        result_authority =>
            'FSM::VIAL::Backend::VHDLOSVVMGHDLQualification',
        compile_command_authorities => [
            'scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl',
            'vial/qualification/vhdl_osvvm_ghdl/osvvm-2026.05-ghdl-6.0.0-qualification.json',
        ],
        run_command_authority =>
            'scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl',
        analysis_timeout_seconds => 120,
        elaboration_timeout_seconds => 60,
        run_timeout_seconds => 30,
    },
);

my @CONSTRUCT_KEYS = qw(
    backend_profile level reference_hial_text reference_vial_text
);
my @BUILD_KEYS = qw(construction);
my @VALIDATE_KEYS = qw(construction report);
my @STAGING_KEYS = qw(construction consumer repository_root);
my @REPORT_KEYS = qw(
    ok status schema schema_version report_identity rerun_identity
    workload_identity family level primary_axis backend_profile tool_profile
    requested_counts backend_handoff stage_expectations compile_expectation
    run_expectation trace_expectation result_expectation claims
    explicit_nonclaims diagnostics
);
my @HANDOFF_KEYS = qw(
    schema schema_version reference_workload_identity backend_profile
    backend_schema structural_authority stage_identities route_metrics
    backend_inputs_sha256 provider_accessed external_tool_executed
);
my @STAGE_IDENTITY_KEYS = qw(
    semantic_ir_sha256 bridge_manifest_sha256 execution_ir_sha256
    backend_inputs_sha256 plan_sha256
);
my @ROUTE_METRIC_KEYS = qw(
    scenarios operations_total fibers_total simultaneously_live_fibers
    source_map_entries backend_input_artifacts
);
my @STAGE_EXPECTATION_KEYS = qw(stage applicability construction_status authority);
my @COMPILE_KEYS = qw(
    schema schema_version status tool_profile logical_tool qualified_version
    provider backend_schema command_authorities analysis_timeout_seconds
    elaboration_timeout_seconds transcript_limit_bytes
);
my @RUN_KEYS = qw(
    schema schema_version status tool_profile command_authority
    timeout_seconds transcript_limit_bytes external_tool_executed
);
my @TRACE_KEYS = qw(
    schema schema_version status trace_schema trace_projection_schema
    validation_authority record_count_expectation framing record_limit
    byte_limit semantic_projection_required materialized
);
my @COUNT_KEYS = qw(
    mode anchor_profile semantic_trace_records structural_trace_records
    structural_trace_bytes earliest_cap_authoritative boundary_reached
);
my @RESULT_KEYS = qw(
    schema schema_version status result_schema production_authority
    expected_result_status byte_limit semantic_oracle_required materialized
);
my @CLAIM_KEYS = qw(
    schema schema_version qualification_only runtime_stream_constructed
    canonical_backend_inputs_constructed backend_artifacts_emitted
    provider_accessed external_tool_executed runtime_executed trace_materialized
    result_materialized support_claimed performance_claimed capacity_claimed
    structural_boundary_reached
);

sub owned_shapes($class) {
    _exact_invocant($class, 'owned_shapes');
    return [map {
        my $profile = $_;
        map {{backend_profile => $profile, level => $_}} @LEVELS
    } @PROFILES];
}

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    confess __PACKAGE__ . "->construct expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $raw = $args[0];
    _confess_exact_keys($raw, \@CONSTRUCT_KEYS,
        'runtime-stream construction');
    _validate_selection($raw->{backend_profile}, $raw->{level});
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
        tool_profile =>
            $PROFILE_CONTRACT{$raw->{backend_profile}}{tool_profile},
        inputs => [
            _input($HIAL_SOURCE, 'hial_source',
                $raw->{reference_hial_text}),
            _input($VIAL_SOURCE, 'vial_source',
                $raw->{reference_vial_text}),
        ],
    });
    confess "canonical runtime-stream workload construction failed\n"
        unless $construction->{ok};
    return $construction;
}

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@BUILD_KEYS, 'runtime-stream evaluation');
    my $construction = _validated_construction($args[0]{construction});
    return __PACKAGE__->_evaluate_candidate({construction => $construction});
}

sub validate_report($class, @args) {
    _exact_invocant($class, 'validate_report');
    confess __PACKAGE__ . "->validate_report expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@VALIDATE_KEYS,
        'runtime-stream report validation');
    my $construction = _validated_construction($args[0]{construction});
    _validate_report_shape($args[0]{report});
    my $rebuilt = __PACKAGE__->_evaluate_candidate({
        construction => $construction,
    });
    confess "runtime-stream report is not canonical\n"
        unless _canonical_json($rebuilt)
            eq _canonical_json($args[0]{report});
    return _clone($rebuilt);
}

sub with_staging($class, @args) {
    _exact_invocant($class, 'with_staging');
    confess __PACKAGE__ . "->with_staging expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@STAGING_KEYS, 'runtime-stream staging');
    my $construction = _validated_construction($args[0]{construction});
    return FSM::VIAL::ArchitectureScaleWorkload->with_staging({
        construction => $construction,
        consumer => $args[0]{consumer},
        repository_root => $args[0]{repository_root},
    });
}

sub _evaluate_candidate($class, @args) {
    confess "runtime-stream candidate evaluation is caller-sealed\n"
        unless caller eq __PACKAGE__;
    _exact_invocant($class, '_evaluate_candidate');
    confess __PACKAGE__ . "->_evaluate_candidate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@BUILD_KEYS,
        'runtime-stream candidate evaluation');
    return _evaluate_validated($args[0]{construction});
}

sub _evaluate_validated($construction) {
    my $spec = $construction->{specification};
    my $profile = $spec->{backend_profile};
    my $contract = $PROFILE_CONTRACT{$profile};
    my $hial = _role_input($construction, 'hial_source');
    my $vial = _role_input($construction, 'vial_source');
    my $backend_construction =
        FSM::VIAL::ArchitectureScaleBackendEmission->construct({
            backend_profile => $profile,
            level => 'reference_v1',
            reference_hial_text => $hial->{content},
            reference_vial_text => $vial->{content},
        });
    my $first = FSM::VIAL::ArchitectureScaleBackendEmission->build({
        construction => $backend_construction,
    });
    my $second = FSM::VIAL::ArchitectureScaleBackendEmission->build({
        construction => $backend_construction,
    });
    confess "canonical runtime backend-input route was rejected\n"
        unless $first->{ok} && $second->{ok};
    my $first_projection = _route_projection($first);
    my $second_projection = _route_projection($second);
    confess "canonical runtime backend-input rerun changed bytes\n"
        unless _canonical_json($first_projection)
            eq _canonical_json($second_projection);

    my $first_identities = _stage_identities($first_projection);
    my $second_identities = _stage_identities($second_projection);
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my $backend_inputs_sha256 =
        sha256_hex(_canonical_json($first_projection->{backend_inputs}));
    my $report = {
        ok => JSON::PP::true,
        status => 'provider_free_runtime_inputs_constructed',
        schema => $REPORT_SCHEMA,
        schema_version => 1,
        report_identity => undef,
        rerun_identity => 'runtime-stream-rerun/' . sha256_hex(
            _canonical_json({
                first => $first_identities,
                second => $second_identities,
            })),
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $spec->{level},
        primary_axis => $PRIMARY_AXIS,
        backend_profile => $profile,
        tool_profile => $spec->{tool_profile},
        requested_counts => _clone($spec->{requested_counts}),
        backend_handoff => {
            schema => $HANDOFF_SCHEMA,
            schema_version => 1,
            reference_workload_identity =>
                $backend_construction->{workload_identity},
            backend_profile => $profile,
            backend_schema => $contract->{backend_schema},
            structural_authority => _clone(
                $catalog->{backend_profiles}{$profile}{structural_authority}),
            stage_identities => $first_identities,
            route_metrics => _route_metrics($first_projection),
            backend_inputs_sha256 => $backend_inputs_sha256,
            provider_accessed => JSON::PP::false,
            external_tool_executed => JSON::PP::false,
        },
        stage_expectations => _stage_expectations($contract),
        compile_expectation => _compile_expectation($contract,
            $spec->{requested_counts}{backend_limits}),
        run_expectation => _run_expectation($contract,
            $spec->{requested_counts}{backend_limits}),
        trace_expectation => _trace_expectation($contract, $spec),
        result_expectation => _result_expectation($contract,
            $spec->{requested_counts}{backend_limits}),
        claims => {
            schema => $CLAIMS_SCHEMA,
            schema_version => 1,
            qualification_only => JSON::PP::true,
            runtime_stream_constructed => JSON::PP::true,
            canonical_backend_inputs_constructed => JSON::PP::true,
            backend_artifacts_emitted => JSON::PP::false,
            provider_accessed => JSON::PP::false,
            external_tool_executed => JSON::PP::false,
            runtime_executed => JSON::PP::false,
            trace_materialized => JSON::PP::false,
            result_materialized => JSON::PP::false,
            support_claimed => JSON::PP::false,
            performance_claimed => JSON::PP::false,
            capacity_claimed => JSON::PP::false,
            structural_boundary_reached => JSON::PP::false,
        },
        explicit_nonclaims => _clone($spec->{explicit_nonclaims}),
        diagnostics => [],
    };
    my $identity_projection = _clone($report);
    delete $identity_projection->{report_identity};
    $report->{report_identity} = 'runtime-stream-report/'
        . sha256_hex(_canonical_json($identity_projection));
    _validate_report_shape($report);
    return _clone($report);
}

sub _stage_expectations($contract) {
    return [
        _stage('construct', 'required', 'completed',
            'FSM::VIAL::ArchitectureScaleWorkload'),
        _stage('semantic', 'required', 'completed',
            'FSM::VIAL::Parser'),
        _stage('bridge', 'required', 'completed',
            'FSM::VIAL::PlanBuilder'),
        _stage('plan', 'required', 'completed',
            'FSM::VIAL::PlanBuilder'),
        _stage('emit', 'required', 'not_run_measurement_required',
            'FSM::VIAL::ArchitectureScaleBackendEmission'),
        _stage('compile', 'required', 'not_run_measurement_required',
            $contract->{tool_profile}),
        _stage('run', 'required', 'not_run_measurement_required',
            $contract->{tool_profile}),
        _stage('trace_validate', 'required', 'not_run_measurement_required',
            $contract->{trace_authority}),
        _stage('result_produce', 'required', 'not_run_measurement_required',
            $contract->{result_authority}),
        _stage('failure', 'required', 'specified_not_observed',
            'docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md'),
    ];
}

sub _stage($stage, $applicability, $status, $authority) {
    return {
        stage => $stage,
        applicability => $applicability,
        construction_status => $status,
        authority => $authority,
    };
}

sub _compile_expectation($contract, $limits) {
    return {
        schema => $COMPILE_SCHEMA,
        schema_version => 1,
        status => 'not_run_measurement_required',
        tool_profile => $contract->{tool_profile},
        logical_tool => $contract->{logical_tool},
        qualified_version => $contract->{qualified_version},
        provider => $contract->{provider},
        backend_schema => $contract->{backend_schema},
        command_authorities => _clone(
            $contract->{compile_command_authorities}),
        analysis_timeout_seconds =>
            0 + $contract->{analysis_timeout_seconds},
        elaboration_timeout_seconds => defined(
            $contract->{elaboration_timeout_seconds})
                ? 0 + $contract->{elaboration_timeout_seconds} : undef,
        transcript_limit_bytes => 0 + $limits->{compile_transcript_bytes},
    };
}

sub _run_expectation($contract, $limits) {
    return {
        schema => $RUN_SCHEMA,
        schema_version => 1,
        status => 'not_run_measurement_required',
        tool_profile => $contract->{tool_profile},
        command_authority => $contract->{run_command_authority},
        timeout_seconds => 0 + $contract->{run_timeout_seconds},
        transcript_limit_bytes => 0 + $limits->{run_transcript_bytes},
        external_tool_executed => JSON::PP::false,
    };
}

sub _trace_expectation($contract, $spec) {
    my $counts = $spec->{requested_counts};
    my ($mode, $anchor, $semantic, $structural_records,
        $structural_bytes, $earliest);
    if ($spec->{level} eq 'reference_v1') {
        $mode = 'checked_anchor_profile';
        $anchor = $counts->{anchor_profile};
    }
    elsif ($spec->{level} eq 'gate_candidate_v1'
            || $spec->{level} eq 'qualification_candidate_v1') {
        $mode = 'exact_semantic_candidate';
        $semantic = 0 + $counts->{semantic_trace_records};
    }
    else {
        $mode = 'earliest_structural_cap_specification';
        $structural_records = 0 + $counts->{structural_trace_records};
        $structural_bytes = 0 + $counts->{structural_trace_bytes};
        $earliest = $counts->{earliest_cap_authoritative}
            ? JSON::PP::true : JSON::PP::false;
    }
    return {
        schema => $TRACE_SCHEMA,
        schema_version => 1,
        status => 'not_materialized_measurement_required',
        trace_schema => $contract->{trace_schema},
        trace_projection_schema => $contract->{trace_projection_schema},
        validation_authority => $contract->{trace_authority},
        record_count_expectation => {
            mode => $mode,
            anchor_profile => $anchor,
            semantic_trace_records => $semantic,
            structural_trace_records => $structural_records,
            structural_trace_bytes => $structural_bytes,
            earliest_cap_authoritative => $earliest // JSON::PP::false,
            boundary_reached => JSON::PP::false,
        },
        framing => 'one_header_then_semantic_records_then_one_footer',
        record_limit => 0 + $counts->{backend_limits}{runtime_trace_records},
        byte_limit => 0 + $counts->{backend_limits}{runtime_trace_bytes},
        semantic_projection_required => JSON::PP::true,
        materialized => JSON::PP::false,
    };
}

sub _result_expectation($contract, $limits) {
    return {
        schema => $RESULT_SCHEMA,
        schema_version => 1,
        status => 'not_materialized_measurement_required',
        result_schema => 'fsmgen.verification_result_manifest.v1',
        production_authority => $contract->{result_authority},
        expected_result_status => 'pass',
        byte_limit => 0 + $limits->{run_transcript_bytes},
        semantic_oracle_required => JSON::PP::true,
        materialized => JSON::PP::false,
    };
}

sub _validated_construction($raw) {
    confess "runtime-stream construction must be one unblessed hash\n"
        unless ref($raw) eq 'HASH' && !blessed($raw);
    my $spec = $raw->{specification};
    confess "runtime-stream construction must carry one specification hash\n"
        unless ref($spec) eq 'HASH' && !blessed($spec);
    confess "runtime-stream construction must be successful\n" unless $raw->{ok};
    confess "construction is not a runtime-stream workload\n"
        unless ($spec->{family} // '') eq $FAMILY
            && ($spec->{primary_axis} // '') eq $PRIMARY_AXIS;
    my $rebuilt = eval { __PACKAGE__->construct({
        backend_profile => $spec->{backend_profile},
        level => $spec->{level},
        reference_hial_text =>
            _role_input($raw, 'hial_source')->{content},
        reference_vial_text =>
            _role_input($raw, 'vial_source')->{content},
    }) };
    confess "runtime-stream construction is not canonical\n"
        unless defined $rebuilt;
    confess "runtime-stream construction is not canonical\n"
        unless _canonical_json($rebuilt) eq _canonical_json($raw);
    return $rebuilt;
}

sub _validate_report_shape($report) {
    _confess_exact_keys($report, \@REPORT_KEYS, 'runtime-stream report');
    _confess_exact_keys($report->{backend_handoff}, \@HANDOFF_KEYS,
        'runtime backend handoff');
    _confess_exact_keys($report->{backend_handoff}{stage_identities},
        \@STAGE_IDENTITY_KEYS, 'runtime backend stage identities');
    _confess_exact_keys($report->{backend_handoff}{route_metrics},
        \@ROUTE_METRIC_KEYS, 'runtime backend route metrics');
    confess "runtime stage expectations must be one array\n"
        unless ref($report->{stage_expectations}) eq 'ARRAY';
    _confess_exact_keys($_, \@STAGE_EXPECTATION_KEYS,
        'runtime stage expectation') for @{$report->{stage_expectations}};
    _confess_exact_keys($report->{compile_expectation}, \@COMPILE_KEYS,
        'runtime compile expectation');
    _confess_exact_keys($report->{run_expectation}, \@RUN_KEYS,
        'runtime run expectation');
    _confess_exact_keys($report->{trace_expectation}, \@TRACE_KEYS,
        'runtime trace expectation');
    _confess_exact_keys(
        $report->{trace_expectation}{record_count_expectation}, \@COUNT_KEYS,
        'runtime trace-count expectation');
    _confess_exact_keys($report->{result_expectation}, \@RESULT_KEYS,
        'runtime result expectation');
    _confess_exact_keys($report->{claims}, \@CLAIM_KEYS,
        'runtime-stream claims');
    confess "runtime-stream explicit nonclaims must be one array\n"
        unless ref($report->{explicit_nonclaims}) eq 'ARRAY';
    confess "runtime-stream diagnostics must be one array\n"
        unless ref($report->{diagnostics}) eq 'ARRAY';
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

sub _stage_identities($projection) {
    return {
        semantic_ir_sha256 =>
            sha256_hex(_canonical_json($projection->{semantic_ir})),
        bridge_manifest_sha256 =>
            sha256_hex(_canonical_json($projection->{bridge_manifest})),
        execution_ir_sha256 =>
            sha256_hex(_canonical_json($projection->{execution_ir})),
        backend_inputs_sha256 =>
            sha256_hex(_canonical_json($projection->{backend_inputs})),
        plan_sha256 => sha256_hex(_canonical_json($projection->{plan})),
    };
}

sub _route_metrics($projection) {
    my $execution = $projection->{execution_ir};
    return {
        scenarios => scalar(@{$execution->{scenarios}}),
        operations_total => 0 + $execution->{operation_graph}{total_operation_count},
        fibers_total => 0 + $execution->{operation_graph}{total_fiber_count},
        simultaneously_live_fibers =>
            0 + $execution->{operation_graph}{maximum_simultaneous_live_fibers},
        source_map_entries => scalar(@{$execution->{source_map}}),
        backend_input_artifacts =>
            _backend_input_artifact_count($projection->{backend_inputs}),
    };
}

sub _backend_input_artifact_count($inputs) {
    confess "runtime backend inputs must be one hash\n"
        unless ref($inputs) eq 'HASH';
    my $count = 0;
    for my $key (sort keys %$inputs) {
        confess "runtime backend input family '$key' must be one array\n"
            unless ref($inputs->{$key}) eq 'ARRAY';
        $count += @{$inputs->{$key}};
    }
    return $count;
}

sub _role_input($construction, $role) {
    confess "runtime-stream construction inputs must be one array\n"
        unless ref($construction->{inputs}) eq 'ARRAY';
    my @matches = grep {
        ref($_) eq 'HASH' && ($_->{role} // '') eq $role
    } @{$construction->{inputs}};
    confess "runtime-stream construction must contain exactly one $role input\n"
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

sub _validate_selection($profile, $level) {
    confess "unknown runtime-stream profile '" . _display($profile) . "'\n"
        unless defined($profile) && !ref($profile) && $PROFILE{$profile};
    confess "unknown runtime-stream level '" . _display($level) . "'\n"
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
    confess "runtime-stream projection contains an unsupported reference\n"
        if ref($value);
    return $value;
}

1;
