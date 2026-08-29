package FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::Backend::VHDLPortableGHDL;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $SCHEMA =
    'fsmgen.vial_architecture_scale_portable_vhdl_runtime_materialization.v1';
my $FAMILY = 'runtime_stream_v1';
my $PROFILE = 'vhdl_portable_ghdl';
my $TOOL_PROFILE = 'ghdl_6_0_0_llvm_jit';
my $OSVVM_PROFILE = 'vhdl_osvvm_qualified';
my $OSVVM_TOOL_PROFILE = 'osvvm_2026_05_ghdl_6_0_0_llvm_jit';
my $PRIMARY_AXIS = 'runtime_trace_records';
my $HIAL_PATH = 'ppif/ahb_lite_subordinate.ppif';
my $HIAL_BYTES = 1_326;
my $HIAL_SHA256 =
    '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c';
my $REFERENCE_PATH = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $REFERENCE_BYTES = 4_986;
my $REFERENCE_SHA256 =
    '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd';
my @LEVELS = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
);
my %LEVEL = map { $_ => 1 } @LEVELS;
my %MATERIALIZED = (
    reference_v1 => {
        path => $REFERENCE_PATH,
        bytes => $REFERENCE_BYTES,
        sha256 => $REFERENCE_SHA256,
        reset_cycles => 3,
        timeout_cycles => 256,
        trace_records => 77,
        artifact_bytes => 238_618,
        source_bytes => 118_062,
        fixture_bytes => 46_262,
        fixture_sha256 =>
            'b327edab233200bc9b8ff1b8e6a22588505749f47363b7bc9c4a0380394f16b3',
    },
    gate_candidate_v1 => {
        path => 'vial/qualification/vhdl_portable_ghdl_runtime_gate.vial',
        bytes => 4_991,
        sha256 =>
            'ce1374f97dcf992e823273d70ebcf1014813ff926a103fea53800797cf304959',
        reset_cycles => 9_926,
        timeout_cycles => 16_384,
        trace_records => 10_000,
        artifact_bytes => 238_901,
        source_bytes => 118_075,
        fixture_bytes => 46_273,
        fixture_sha256 =>
            '4a1cc43d625ec6d352c63a6a0e9b2a2e56a3ae41ea26cf480c9979b21dee2513',
    },
    qualification_candidate_v1 => {
        path =>
            'vial/qualification/vhdl_portable_ghdl_runtime_qualification.vial',
        bytes => 4_993,
        sha256 =>
            'cbf752abb62d0b88e5411cde979d0e6eb91a5f0e23a1b2eece8c633edad4b7ca',
        reset_cycles => 99_926,
        timeout_cycles => 131_072,
        trace_records => 100_000,
        artifact_bytes => 239_318,
        source_bytes => 118_087,
        fixture_bytes => 46_284,
        fixture_sha256 =>
            '9e0f2f69389e5bd5e3264dc1aadd220d2bbfa9bf9f35360f2ba692f6ca662b10',
    },
);
my $OPERATIONS = 21;
my $EXECUTION_MAPS = 39;
my $ARTIFACTS = 17;
my $SOURCE_ARTIFACTS = 6;
my $EMISSION_MAPS = 59;
my $STATIC_CHECKS = 21;
my @REPORT_KEYS = qw(
    ok status schema schema_version report_identity family backend_profile
    level primary_axis workload_identity requested_counts source_identity
    stage_identities structural_equivalence schedule_oracle emission_oracle
    trace_projection envelope_projection claims explicit_nonclaims diagnostics
    cleanup
);
my @NONCLAIMS = qw(
    architecture_scale_capacity whole_product_big whole_product_really_big
    multi_unit multi_domain mixed_language osvvm native_uvm_runtime
    full_language synthesis general_cross_backend_parity runtime_executed
    trace_materialized result_produced support_claimed performance_budget
    capacity_claimed reached_record_boundary public_api_change
);

sub owned_shapes($class) {
    _exact_invocant($class, 'owned_shapes');
    return [map {{backend_profile => $PROFILE, level => $_}} @LEVELS];
}

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    my $raw = _request('construct', \@args, [qw(repository_root level)]);
    my $repo_root = _repository_root($raw->{repository_root});
    return _canonical_construction($repo_root, $raw->{level});
}

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    my $raw = _request('evaluate', \@args, [qw(repository_root level)]);
    my $repo_root = _repository_root($raw->{repository_root});
    _selected_level($raw->{level});
    return _evaluate($repo_root, $raw->{level});
}

sub validate_report($class, @args) {
    _exact_invocant($class, 'validate_report');
    my $raw = _request(
        'validate_report', \@args, [qw(repository_root report)],
    );
    my $repo_root = _repository_root($raw->{repository_root});
    _validate_report_shape($raw->{report});
    my $rebuilt = _evaluate($repo_root, $raw->{report}{level});
    confess "portable-VHDL runtime materialization report is not canonical\n"
        unless _canonical_json($rebuilt) eq _canonical_json($raw->{report});
    return _clone($rebuilt);
}

sub with_staging($class, @args) {
    _exact_invocant($class, 'with_staging');
    my $raw = _request(
        'with_staging', \@args,
        [qw(repository_root level consumer)],
    );
    confess "portable-VHDL materialization consumer must be one code reference\n"
        unless ref($raw->{consumer}) eq 'CODE';
    _selected_level($raw->{level});
    confess "preflight-dominated portable-VHDL shapes cannot create staging\n"
        unless exists $MATERIALIZED{$raw->{level}};
    my $repo_root = _repository_root($raw->{repository_root});
    my $construction = _canonical_construction($repo_root, $raw->{level});
    my $report = _evaluate($repo_root, $raw->{level});
    return FSM::VIAL::ArchitectureScaleWorkload->with_staging({
        construction => $construction,
        repository_root => $repo_root,
        consumer => sub ($context) {
            $raw->{consumer}->({
                staging_root => $context->{staging_root},
                staging_identity => $context->{staging_identity},
                workload_identity => $construction->{workload_identity},
                report => _clone($report),
            });
        },
    });
}

# The exact measurement adapter needs the canonical blessed route and emission
# so the shared lifecycle remains the sole GHDL executor.  Keep this seam
# caller-sealed and rederive every input from tracked repository authority.
sub _measurement_inputs($class, @args) {
    _exact_invocant($class, '_measurement_inputs');
    confess "portable-VHDL measurement inputs are private to the exact adapter\n"
        unless caller eq
            'FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement';
    my $raw = _request(
        '_measurement_inputs', \@args,
        [qw(repository_root level artifact_root)],
    );
    my $repo_root = _repository_root($raw->{repository_root});
    _selected_level($raw->{level});
    confess "preflight-dominated portable-VHDL shapes have no lifecycle inputs\n"
        unless exists $MATERIALIZED{$raw->{level}};
    my $artifact_root = _safe_relative_path($raw->{artifact_root});
    my $construction = _canonical_construction($repo_root, $raw->{level});
    my $source = _source_input($construction);
    my $route = _canonical_route(
        $source->{relative_path}, $source->{content},
        _hial_input($construction)->{content},
    );
    my $emission = _emit($route, $artifact_root);
    my $oracle = _emission_oracle(
        $raw->{level}, $emission, $artifact_root,
    );
    return {
        construction => _clone($construction),
        route => $route,
        emission => $emission,
        emission_oracle => $oracle,
    };
}

# The provider-aware runtime materializer must use these exact authored VIAL
# sources and the same ordinary parser/PlanBuilder route.  Keep both seams
# private to that one consumer so no caller can inject alternate source, IR,
# profile, or tool identities through the shared portable authority.
sub _osvvm_runtime_construction($class, @args) {
    _exact_invocant($class, '_osvvm_runtime_construction');
    confess "OSVVM runtime construction is private to the exact materializer\n"
        unless caller eq
            'FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization';
    my $raw = _request(
        '_osvvm_runtime_construction', \@args,
        [qw(repository_root level)],
    );
    my $repo_root = _repository_root($raw->{repository_root});
    return _canonical_construction_for(
        $repo_root, $raw->{level}, $OSVVM_PROFILE, $OSVVM_TOOL_PROFILE,
    );
}

sub _osvvm_runtime_route_inputs($class, @args) {
    _exact_invocant($class, '_osvvm_runtime_route_inputs');
    confess "OSVVM runtime route inputs are private to the exact materializer\n"
        unless caller eq
            'FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization';
    my $raw = _request(
        '_osvvm_runtime_route_inputs', \@args,
        [qw(repository_root level)],
    );
    my $repo_root = _repository_root($raw->{repository_root});
    my $level = $raw->{level};
    my $first_construction = _canonical_construction_for(
        $repo_root, $level, $OSVVM_PROFILE, $OSVVM_TOOL_PROFILE,
    );
    my $second_construction = _canonical_construction_for(
        $repo_root, $level, $OSVVM_PROFILE, $OSVVM_TOOL_PROFILE,
    );
    confess "OSVVM runtime construction is nondeterministic\n"
        unless _canonical_json($first_construction)
            eq _canonical_json($second_construction);
    my $portable_report = _evaluate($repo_root, $level);
    return {
        construction => _clone($first_construction),
        portable_report => $portable_report,
        first_route => undef,
        second_route => undef,
    } unless exists $MATERIALIZED{$level};

    my $source = _source_input($first_construction);
    my $hial = _hial_input($first_construction)->{content};
    my $first_route = _canonical_route(
        $source->{relative_path}, $source->{content}, $hial,
    );
    my $second_route = _canonical_route(
        $source->{relative_path}, $source->{content}, $hial,
    );
    my $first_projection = _route_projection($first_route);
    my $second_projection = _route_projection($second_route);
    confess "OSVVM runtime route is nondeterministic\n"
        unless _canonical_json($first_projection)
            eq _canonical_json($second_projection);
    confess "OSVVM runtime route departed from portable semantic authority\n"
        unless _canonical_json(_stage_identities($first_projection))
            eq _canonical_json($portable_report->{stage_identities});
    return {
        construction => _clone($first_construction),
        portable_report => $portable_report,
        first_route => $first_route,
        second_route => $second_route,
    };
}

sub _evaluate($repo_root, $level) {
    my $first_construction = _canonical_construction($repo_root, $level);
    my $second_construction = _canonical_construction($repo_root, $level);
    confess "portable-VHDL runtime construction is nondeterministic\n"
        unless _canonical_json($first_construction)
            eq _canonical_json($second_construction);
    my $spec = $first_construction->{specification};
    my $limits = $spec->{requested_counts}{backend_limits};

    if (!exists $MATERIALIZED{$level}) {
        my $report = {
            ok => JSON::PP::true,
            status => 'preflight_dominated',
            schema => $SCHEMA,
            schema_version => 1,
            report_identity => undef,
            family => $FAMILY,
            backend_profile => $PROFILE,
            level => $level,
            primary_axis => $PRIMARY_AXIS,
            workload_identity => $first_construction->{workload_identity},
            requested_counts => _clone($spec->{requested_counts}),
            source_identity => undef,
            stage_identities => undef,
            structural_equivalence => undef,
            schedule_oracle => undef,
            emission_oracle => undef,
            trace_projection => _structural_trace_projection($spec),
            envelope_projection => _envelope_projection(
                $level, $limits, undef,
            ),
            claims => _claims(0, 1),
            explicit_nonclaims => [@NONCLAIMS],
            diagnostics => [],
            cleanup => {
                staging_created => JSON::PP::false,
                in_memory_only => JSON::PP::true,
                residue => [],
            },
        };
        _seal_report($report);
        return _clone($report);
    }

    my $source = _source_input($first_construction);
    my $reference = _read_exact_repository_file(
        $repo_root, $REFERENCE_PATH, $REFERENCE_BYTES, $REFERENCE_SHA256,
        'checked VIAL reference',
    );
    my $contract = $MATERIALIZED{$level};
    my $projected_source = _expected_source_projection($reference, $level);
    confess "tracked portable-VHDL runtime source has an undeclared delta\n"
        unless $source->{content} eq $projected_source;

    my $first_route = _canonical_route(
        $source->{relative_path}, $source->{content},
        _hial_input($first_construction)->{content},
    );
    my $second_route = _canonical_route(
        $source->{relative_path}, $source->{content},
        _hial_input($first_construction)->{content},
    );
    my $first_projection = _route_projection($first_route);
    my $second_projection = _route_projection($second_route);
    confess "portable-VHDL runtime route is nondeterministic\n"
        unless _canonical_json($first_projection)
            eq _canonical_json($second_projection);

    my $reference_route = $level eq 'reference_v1'
        ? $first_route
        : _canonical_route(
            $REFERENCE_PATH, $reference,
            _hial_input($first_construction)->{content},
        );
    my $structural = _structural_equivalence(
        $level, $reference_route, $first_route,
    );
    my $schedule = _schedule_oracle($level, $first_route);
    my $artifact_root = _public_artifact_root(
        $first_route->{execution_ir}->plan_id,
    );
    my $first_emission = _emit($first_route, $artifact_root);
    my $second_emission = _emit($second_route, $artifact_root);
    confess "portable-VHDL runtime emission is nondeterministic\n"
        unless _canonical_json($first_emission)
            eq _canonical_json($second_emission);
    my $emission = _emission_oracle(
        $level, $first_emission, $artifact_root,
    );
    my $trace = _record_projection($contract->{reset_cycles});
    confess "portable-VHDL runtime trace equation changed\n"
        unless $trace->{record_count} == $contract->{trace_records};

    my $report = {
        ok => JSON::PP::true,
        status => 'structurally_qualified',
        schema => $SCHEMA,
        schema_version => 1,
        report_identity => undef,
        family => $FAMILY,
        backend_profile => $PROFILE,
        level => $level,
        primary_axis => $PRIMARY_AXIS,
        workload_identity => $first_construction->{workload_identity},
        requested_counts => _clone($spec->{requested_counts}),
        source_identity => {
            relative_path => $source->{relative_path},
            bytes => bytes::length($source->{content}),
            sha256 => sha256_hex($source->{content}),
        },
        stage_identities => _stage_identities($first_projection),
        structural_equivalence => $structural,
        schedule_oracle => $schedule,
        emission_oracle => $emission,
        trace_projection => $trace,
        envelope_projection => _envelope_projection(
            $level, $limits, $trace->{record_count},
        ),
        claims => _claims(1, 0),
        explicit_nonclaims => [@NONCLAIMS],
        diagnostics => [],
        cleanup => {
            staging_created => JSON::PP::false,
            in_memory_only => JSON::PP::true,
            residue => [],
        },
    };
    _seal_report($report);
    return _clone($report);
}

sub _canonical_construction($repo_root, $level) {
    return _canonical_construction_for(
        $repo_root, $level, $PROFILE, $TOOL_PROFILE,
    );
}

sub _canonical_construction_for(
    $repo_root, $level, $backend_profile, $tool_profile
) {
    _selected_level($level);
    my $hial = _read_exact_repository_file(
        $repo_root, $HIAL_PATH, $HIAL_BYTES, $HIAL_SHA256,
        'checked HIAL reference',
    );
    my $source_contract = $MATERIALIZED{$level} // $MATERIALIZED{reference_v1};
    my $source = _read_exact_repository_file(
        $repo_root, $source_contract->{path}, $source_contract->{bytes},
        $source_contract->{sha256}, 'portable-VHDL runtime source',
    );
    my $construction = FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $FAMILY,
        level => $level,
        primary_axis => $PRIMARY_AXIS,
        backend_profile => $backend_profile,
        tool_profile => $tool_profile,
        inputs => [
            _input($HIAL_PATH, 'hial_source', $hial),
            _input($source_contract->{path}, 'vial_source', $source),
        ],
    });
    confess "portable-VHDL runtime workload construction failed\n"
        unless $construction->{ok};
    if (exists($MATERIALIZED{$level}) && $level ne 'reference_v1') {
        confess "portable-VHDL runtime requested count changed\n"
            unless ($construction->{specification}{requested_counts}
                    {semantic_trace_records} // -1)
                == $MATERIALIZED{$level}{trace_records};
    }
    return _clone($construction);
}

sub _canonical_route($source_path, $source, $hial) {
    confess "portable-VHDL runtime canonical route is caller-sealed\n"
        unless caller eq __PACKAGE__;
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $source,
        source_name => $source_path,
        source_catalog => {},
    });
    my $built = FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => _source_envelope($HIAL_PATH, $hial, 'ppif'),
        fixture_id => 'base_output_arbitration',
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
    confess "portable-VHDL runtime canonical plan route failed\n"
        unless $built->{ok};
    return {
        semantic_ir => $semantic_ir,
        bridge_manifest => $built->{bridge_manifest},
        execution_ir => $built->{execution_ir},
        backend_inputs => _clone($built->{backend_inputs}),
        plan => _clone($built->{plan}),
    };
}

sub _structural_equivalence($level, $reference, $candidate) {
    my $reference_execution = $reference->{execution_ir}->as_hashref;
    my $candidate_execution = $candidate->{execution_ir}->as_hashref;
    confess "portable-VHDL ExecutionIR has an undeclared structural delta\n"
        unless _canonical_json(_execution_signature($reference_execution))
            eq _canonical_json(_execution_signature($candidate_execution));
    confess "portable-VHDL source-map topology has an undeclared delta\n"
        unless _canonical_json(_source_map_signature(
                $reference_execution->{source_map}))
            eq _canonical_json(_source_map_signature(
                $candidate_execution->{source_map}));
    confess "portable-VHDL bridge manifest changed\n"
        unless _canonical_json($reference->{bridge_manifest}->as_hashref)
            eq _canonical_json($candidate->{bridge_manifest}->as_hashref);
    confess "portable-VHDL backend inputs changed\n"
        unless _canonical_json($reference->{backend_inputs})
            eq _canonical_json($candidate->{backend_inputs});
    return {
        oracle => 'portable_vhdl_runtime_selected_delta_v1',
        reference_source => $REFERENCE_PATH,
        only_selected_source_deltas => JSON::PP::true,
        semantic_ids_preserved => JSON::PP::true,
        bridge_manifest_preserved => JSON::PP::true,
        execution_topology_preserved => JSON::PP::true,
        backend_inputs_preserved => JSON::PP::true,
        source_map_topology_preserved => JSON::PP::true,
        allowed_deltas => $level eq 'reference_v1'
            ? [] : [qw(success_reset_cycles success_timeout_cycles)],
    };
}

sub _execution_signature($execution) {
    my $copy = _clone($execution);
    delete @{$copy}{qw(
        plan_id schema schema_version diagnostics source_map semantic_identity
    )};
    _remove_locations($copy);
    my $success_id =
        'ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success';
    for my $operation (@{$copy->{operation_graph}{operations}}) {
        next unless $operation->{scenario_id} eq $success_id;
        $operation->{deadline}{cycle} = 255
            if ref($operation->{deadline}) eq 'HASH';
        _typed_input($operation, 'cycles')->{value} = 3
            if $operation->{kind} eq 'reset';
    }
    for my $scenario (@{$copy->{scenarios}}) {
        next unless $scenario->{scenario_id} eq $success_id;
        $scenario->{timeout_cycles} = 256;
        $scenario->{plan_summary}{timeout_cycles} = 256;
    }
    return $copy;
}

sub _source_map_signature($maps) {
    return [map {{
        semantic_path => $_->{semantic_path},
        bridge_fact_paths => _clone($_->{bridge_fact_paths}),
    }} @$maps];
}

sub _schedule_oracle($level, $route) {
    my $execution = $route->{execution_ir}->as_hashref;
    my $contract = $MATERIALIZED{$level};
    my ($success) = grep { $_->{name} eq 'success' }
        @{$execution->{scenarios}};
    my ($error) = grep { $_->{name} eq 'unsupported_size' }
        @{$execution->{scenarios}};
    confess "portable-VHDL runtime scenario inventory changed\n"
        unless defined($success) && defined($error)
            && @{$execution->{scenarios}} == 2;
    my @success_operations = grep {
        $_->{scenario_id} eq $success->{scenario_id}
    } @{$execution->{operation_graph}{operations}};
    my @error_operations = grep {
        $_->{scenario_id} eq $error->{scenario_id}
    } @{$execution->{operation_graph}{operations}};
    my ($success_reset) = grep { $_->{kind} eq 'reset' } @success_operations;
    my ($error_reset) = grep { $_->{kind} eq 'reset' } @error_operations;
    my @await = grep { $_->{kind} eq 'await' } @success_operations;
    confess "portable-VHDL runtime reset count changed\n"
        unless _typed_input($success_reset, 'cycles')->{value}
                == $contract->{reset_cycles}
            && _typed_input($error_reset, 'cycles')->{value} == 3;
    confess "portable-VHDL runtime timeout/window envelope changed\n"
        unless $success->{timeout_cycles} == $contract->{timeout_cycles}
            && $error->{timeout_cycles} == 256
            && @await == 2
            && !grep {
                _typed_input($_, 'property')->{value}{max_cycles} != 256
            } @await;
    confess "portable-VHDL runtime operation/source-map count changed\n"
        unless $execution->{operation_graph}{total_operation_count}
                == $OPERATIONS
            && @{$execution->{source_map}} == $EXECUTION_MAPS;
    return {
        scenario_names => [map { $_->{name} } @{$execution->{scenarios}}],
        success_timeout_cycles => 0 + $success->{timeout_cycles},
        success_reset_cycles =>
            0 + _typed_input($success_reset, 'cycles')->{value},
        success_await_max_cycles => [map {
            0 + _typed_input($_, 'property')->{value}{max_cycles}
        } @await],
        unsupported_size_timeout_cycles => 0 + $error->{timeout_cycles},
        unsupported_size_reset_cycles =>
            0 + _typed_input($error_reset, 'cycles')->{value},
        operation_count =>
            0 + $execution->{operation_graph}{total_operation_count},
        source_map_count => scalar(@{$execution->{source_map}}),
    };
}

sub _emit($route, $artifact_root) {
    my $emission = FSM::VIAL::Backend::VHDLPortableGHDL->emit({
        execution_ir => $route->{execution_ir},
        bridge_manifest => $route->{bridge_manifest},
        backend_inputs => $route->{backend_inputs},
        artifact_root => $artifact_root,
        backend_profile => $PROFILE,
    });
    confess "portable-VHDL runtime structural emission failed\n"
        unless $emission->{ok};
    return $emission;
}

sub _emission_oracle($level, $emission, $artifact_root) {
    my $contract = $MATERIALIZED{$level};
    my @artifacts = @{$emission->{artifacts}};
    confess "portable-VHDL runtime artifact inventory changed\n"
        unless @artifacts == $ARTIFACTS;
    my ($fixture) = grep {
        $_->{relpath} =~ m{/src/base_output_arbitration_tb[.]vhd\z}
    } @artifacts;
    confess "portable-VHDL runtime emission lacks its fixture source\n"
        unless defined $fixture;
    confess "portable-VHDL runtime fixture source identity changed\n"
        unless bytes::length($fixture->{content})
                == $contract->{fixture_bytes}
            && sha256_hex($fixture->{content})
                eq $contract->{fixture_sha256};
    my @identity = map {{
        relpath => $_->{relpath},
        bytes => bytes::length($_->{content}),
        sha256 => sha256_hex($_->{content}),
    }} @artifacts;
    my $artifact_bytes = 0;
    $artifact_bytes += $_->{bytes} for @identity;
    confess "portable-VHDL runtime artifact byte total changed\n"
        unless $artifact_bytes == $contract->{artifact_bytes};
    my @source_identity = map {{
        relpath => $_->{relpath},
        role => $_->{role},
        bytes => 0 + $_->{bytes},
        sha256 => $_->{sha256},
    }} @{$emission->{static_validation}{artifacts}};
    my $source_bytes = 0;
    $source_bytes += $_->{bytes} for @source_identity;
    confess "portable-VHDL runtime source inventory changed\n"
        unless @source_identity == $SOURCE_ARTIFACTS
            && $source_bytes == $contract->{source_bytes};
    my @checks = @{$emission->{static_validation}{checks}};
    confess "portable-VHDL runtime static checks changed\n"
        unless $emission->{static_validation}{ok}
            && ($emission->{static_validation}{status} // '') eq 'passed'
            && @checks == $STATIC_CHECKS
            && !grep { ($_->{status} // '') ne 'passed' } @checks;
    confess "portable-VHDL runtime emitted source-map count changed\n"
        unless @{$emission->{source_map}{entries}} == $EMISSION_MAPS;
    my $reset = $contract->{reset_cycles};
    my $timeout = $contract->{timeout_cycles};
    my $reset_count = () = $fixture->{content}
        =~ /for reset_index in 1 to \Q$reset\E loop/g;
    my $timeout_count = () = $fixture->{content}
        =~ /vial_scenario_timeout := \Q$timeout\E;/g;
    my $expected_count = $level eq 'reference_v1' ? 2 : 1;
    confess "portable-VHDL generated reset loop changed\n"
        unless $reset_count == $expected_count;
    confess "portable-VHDL generated scenario timeout changed\n"
        unless $timeout_count == $expected_count;
    return {
        artifact_root => $artifact_root,
        artifact_count => scalar(@identity),
        artifact_bytes => $artifact_bytes,
        artifact_graph_sha256 => sha256_hex(_canonical_json(\@identity)),
        source_artifact_count => scalar(@source_identity),
        source_artifact_bytes => $source_bytes,
        source_map_entries => scalar(@{$emission->{source_map}{entries}}),
        static_check_count => scalar(@checks),
        fixture_bytes => bytes::length($fixture->{content}),
        fixture_sha256 => sha256_hex($fixture->{content}),
        generated_reset_loop => "for reset_index in 1 to $reset loop",
        generated_scenario_timeout => "vial_scenario_timeout := $timeout;",
        artifacts => \@identity,
        source_artifacts => \@source_identity,
        checks => [map { $_->{check} } @checks],
        byte_equal_rerun => JSON::PP::true,
        external_tool_executed => JSON::PP::false,
    };
}

sub _record_projection($reset_cycles) {
    my %count = (
        header => 1,
        scenario_start => 2,
        samples => $reset_cycles + 32,
        events => 2,
        expectations => 2,
        scoreboards => 2,
        coverage => 28,
        faults => 2,
        scenario_end => 2,
        footer => 1,
    );
    my $total = 0;
    $total += $_ for values %count;
    return {
        schema => 'fsmgen.vial_vhdl_runtime_trace.v2',
        equation => 'N+74',
        reset_cycles => 0 + $reset_cycles,
        record_count => $total,
        record_families => {map { $_ => 0 + $count{$_} } sort keys %count},
        derivation => {
            checked_reference_records => 77,
            checked_reference_reset_cycles => 3,
            reference_sample_records => 35,
            added_samples_per_added_reset_cycle => 1,
            observation_catalog_entries => 4,
            observation_catalog_bits => 66,
        },
    };
}

sub _structural_trace_projection($spec) {
    my $counts = $spec->{requested_counts};
    return {
        schema => 'fsmgen.vial_vhdl_runtime_trace.v2',
        equation => undef,
        reset_cycles => undef,
        record_count => 0 + $counts->{structural_trace_records},
        record_families => undef,
        derivation => {
            minimum_structural_trace_bytes =>
                0 + $counts->{structural_trace_bytes},
            earliest_cap_authoritative => $counts->{earliest_cap_authoritative}
                ? JSON::PP::true : JSON::PP::false,
            materialized => JSON::PP::false,
        },
    };
}

sub _envelope_projection($level, $limits, $records) {
    my $record_limit = 0 + $limits->{runtime_trace_records};
    my $byte_limit = 0 + $limits->{runtime_trace_bytes};
    my $preflight = $level =~ /\A(?:limit|over_limit)_v1\z/;
    confess "portable-VHDL selected candidate exceeds the record envelope\n"
        if defined($records) && $records > $record_limit;
    return {
        record_limit => $record_limit,
        byte_limit => $byte_limit,
        projected_records => $records,
        actual_trace_bytes => undef,
        status => $preflight
            ? 'preflight_dominated'
            : $level eq 'reference_v1'
                ? 'correctness_only_runtime_unmeasured'
                : 'structurally_admitted_runtime_unmeasured',
        earlier_cap_authoritative => JSON::PP::true,
        external_tool_eligible => $preflight
            ? JSON::PP::false : JSON::PP::true,
    };
}

sub _claims($materialized, $preflight) {
    return {
        qualification_only => JSON::PP::true,
        canonical_sources_bound => JSON::PP::true,
        ordinary_route_reconstructed => $materialized
            ? JSON::PP::true : JSON::PP::false,
        structural_equivalence_proved => $materialized
            ? JSON::PP::true : JSON::PP::false,
        schedule_materialized => $materialized
            ? JSON::PP::true : JSON::PP::false,
        preflight_dominance_proved => $preflight
            ? JSON::PP::true : JSON::PP::false,
        external_tool_executed => JSON::PP::false,
        runtime_executed => JSON::PP::false,
        trace_materialized => JSON::PP::false,
        result_produced => JSON::PP::false,
        support_claimed => JSON::PP::false,
        performance_claimed => JSON::PP::false,
        capacity_claimed => JSON::PP::false,
        reached_record_boundary => JSON::PP::false,
        public_api_changed => JSON::PP::false,
    };
}

sub _expected_source_projection($reference, $level) {
    return $reference if $level eq 'reference_v1';
    my $contract = $MATERIALIZED{$level};
    my $source = $reference;
    _replace_once(\$source,
        "(scenario success\n            (timeout (cycles bus 256))",
        '(scenario success' . "\n            (timeout (cycles bus "
            . $contract->{timeout_cycles} . '))');
    _replace_once(\$source,
        "              (reset bus 3)\n"
            . '              (scoreboard_expect writes',
        '              (reset bus ' . $contract->{reset_cycles} . ")\n"
            . '              (scoreboard_expect writes');
    return $source;
}

sub _replace_once($text_ref, $before, $after) {
    my $count = () = $$text_ref =~ /\Q$before\E/g;
    confess "portable-VHDL source oracle anchor is not unique\n"
        unless $count == 1;
    $$text_ref =~ s/\Q$before\E/$after/;
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
    return {map {
        ($_ . '_sha256' => sha256_hex(_canonical_json($projection->{$_})))
    } qw(semantic_ir bridge_manifest execution_ir backend_inputs plan)};
}

sub _public_artifact_root($plan_id) {
    my ($digest) = $plan_id =~ m{\Aplan/([0-9a-f]{64})\z};
    confess "portable-VHDL runtime plan identity is invalid\n"
        unless defined $digest;
    return ".artifacts/vial/base-output-arbitration/$digest";
}

sub _typed_input($operation, $name) {
    confess "portable-VHDL runtime operation is invalid\n"
        unless ref($operation) eq 'HASH';
    my @match = grep { ($_->{name} // '') eq $name }
        @{$operation->{typed_inputs}};
    confess "portable-VHDL runtime operation must contain one '$name' input\n"
        unless @match == 1;
    return $match[0];
}

sub _remove_locations($value) {
    return unless ref($value);
    if (ref($value) eq 'ARRAY') {
        _remove_locations($_) for @$value;
        return;
    }
    confess "portable-VHDL runtime signature contains a blessed value\n"
        if blessed($value);
    delete $value->{source_location};
    delete $value->{source_locations};
    _remove_locations($value->{$_}) for keys %$value;
}

sub _source_input($construction) {
    return _role_input($construction, 'vial_source');
}

sub _hial_input($construction) {
    return _role_input($construction, 'hial_source');
}

sub _role_input($construction, $role) {
    my @match = grep { ($_->{role} // '') eq $role }
        @{$construction->{inputs}};
    confess "portable-VHDL construction must contain one $role\n"
        unless @match == 1;
    return $match[0];
}

sub _input($relative_path, $role, $content) {
    return {
        relative_path => $relative_path,
        role => $role,
        encoding => 'utf-8',
        content => $content,
    };
}

sub _source_envelope($relative_path, $content, $kind) {
    return {
        source_id => $relative_path,
        source_kind_hint => $kind,
        text => $content,
        encoding => 'utf-8',
        origin => 'repository',
        display_name => $relative_path,
        canonical_id => undef,
        relative_path => $relative_path,
        metadata => {},
    };
}

sub _read_exact_repository_file(
    $repo_root, $relative, $bytes, $sha256, $label
) {
    my @parts = split m{/}, _safe_relative_path($relative);
    my $path = File::Spec->catfile($repo_root, @parts);
    confess "$label is not one regular repository file\n"
        unless -f $path && !-l $path;
    my @root_stat = stat($repo_root);
    my @file_stat = stat($path);
    confess "$label is not on the repository volume\n"
        unless @root_stat && @file_stat && $root_stat[0] == $file_stat[0];
    open my $fh, '<:raw', $path or confess "cannot read $label\n";
    local $/;
    my $content = <$fh>;
    close $fh or confess "cannot close $label\n";
    confess "$label byte length changed\n"
        unless bytes::length($content) == $bytes;
    confess "$label identity changed\n"
        unless sha256_hex($content) eq $sha256;
    return $content;
}

sub _repository_root($raw) {
    confess "repository_root must name one existing directory\n"
        unless defined($raw) && !ref($raw) && -d $raw && !-l $raw;
    return File::Spec->rel2abs($raw);
}

sub _safe_relative_path($value) {
    confess "portable-VHDL runtime repository path is unsafe\n"
        unless defined($value) && !ref($value)
            && $value =~ m{\A[A-Za-z0-9_.][A-Za-z0-9_.\/-]*\z}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                split m{/}, $value, -1;
    return $value;
}

sub _seal_report($report) {
    my $projection = _clone($report);
    delete $projection->{report_identity};
    $report->{report_identity} = 'portable-vhdl-runtime-materialization/'
        . sha256_hex(_canonical_json($projection));
    _validate_report_shape($report);
}

sub _validate_report_shape($report) {
    _exact_keys($report, \@REPORT_KEYS,
        'portable-VHDL runtime materialization report');
    confess "portable-VHDL runtime materialization report header is invalid\n"
        unless $report->{ok}
            && ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // -1) == 1
            && ($report->{family} // '') eq $FAMILY
            && ($report->{backend_profile} // '') eq $PROFILE
            && ($report->{primary_axis} // '') eq $PRIMARY_AXIS
            && ($report->{status} // '')
                =~ /\A(?:structurally_qualified|preflight_dominated)\z/;
    _selected_level($report->{level});
    confess "portable-VHDL runtime report identity is invalid\n"
        unless ($report->{report_identity} // '')
            =~ m{\Aportable-vhdl-runtime-materialization/[0-9a-f]{64}\z};
    confess "portable-VHDL runtime report diagnostics changed\n"
        unless ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}};
    confess "portable-VHDL runtime report nonclaims changed\n"
        unless _canonical_json($report->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
}

sub _selected_level($level) {
    confess "portable-VHDL runtime materialization level is not selected\n"
        unless defined($level) && !ref($level) && $LEVEL{$level};
}

sub _request($method, $args, $keys) {
    confess __PACKAGE__ . "->$method expects one closed hash\n"
        unless @$args == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    _exact_keys($args->[0], $keys, "$method invocation");
    return $args->[0];
}

sub _exact_keys($value, $keys, $label) {
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

sub _canonical_json($value) {
    return JSON::PP->new->canonical(1)->allow_nonref(1)->encode($value);
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value)
            && ($value->isa('JSON::PP::Boolean')
                || $value->isa('JSON::PP::BooleanBase'));
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess "portable-VHDL runtime projection has an unsupported reference\n"
        if ref($value);
    return $value;
}

1;
