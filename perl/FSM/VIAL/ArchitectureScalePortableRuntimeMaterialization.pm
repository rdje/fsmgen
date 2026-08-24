package FSM::VIAL::ArchitectureScalePortableRuntimeMaterialization;

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

use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::Backend::SVPortableVerilator;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $SCHEMA =
    'fsmgen.vial_architecture_scale_portable_runtime_materialization.v1';
my $FAMILY = 'runtime_stream_v1';
my $PROFILE = 'sv_portable_verilator';
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
        trace_records => 274,
        operation_count => 21,
        source_map_count => 39,
        expected_fixture_bytes => 106_181,
        expected_fixture_sha256 =>
            '1839aae7d65c3394442a4b26538b9ea73ab35ae142ca32e29177775919d0f730',
        expected_full_graph_bytes => undef,
    },
    gate_candidate_v1 => {
        path => 'vial/qualification/sv_portable_verilator_runtime_gate.vial',
        bytes => 5_064,
        sha256 =>
            'f9a6a3f563b8f58e694ccd2a9e82b50e4866ac9c794b3aef363e7f2251518475',
        reset_cycles => 1_948,
        timeout_cycles => 4_096,
        trace_records => 10_000,
        operation_count => 22,
        source_map_count => 40,
        expected_fixture_bytes => 108_802,
        expected_fixture_sha256 =>
            'd4418957f0558c2426091d3436afc961d8ea1cb43b9fb28c1650d24b01181c0b',
        expected_full_graph_bytes => 32_098_531,
    },
    qualification_candidate_v1 => {
        path =>
            'vial/qualification/sv_portable_verilator_runtime_qualification.vial',
        bytes => 5_064,
        sha256 =>
            '569f9adbffd9aab214b09fab2ed8c9b4731e14b3c17781e1e75195e7a92275fa',
        reset_cycles => 2_948,
        timeout_cycles => 4_096,
        trace_records => 15_000,
        operation_count => 22,
        source_map_count => 40,
        expected_fixture_bytes => 108_802,
        expected_fixture_sha256 =>
            '2f11ddd8b8569a6be0bdb7c150c76bfb19d41449f6a8fb690c915153d2bbfed2',
        expected_full_graph_bytes => 47_505_049,
    },
);
my @REPORT_KEYS = qw(
    ok status schema schema_version report_identity family backend_profile
    level primary_axis workload_identity requested_counts source_identity
    stage_identities structural_equivalence schedule_oracle emission_oracle
    trace_projection graph_projection dominance claims explicit_nonclaims
    diagnostics cleanup
);
my @NONCLAIMS = qw(
    architecture_scale_capacity whole_product_big whole_product_really_big
    multi_unit multi_domain mixed_language native_uvm_runtime full_language
    synthesis general_cross_backend_parity runtime_executed support_claimed
    performance_budget capacity_claimed reached_record_boundary public_api_change
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
    confess "portable runtime materialization report is not canonical\n"
        unless _canonical_json($rebuilt) eq _canonical_json($raw->{report});
    return _clone($rebuilt);
}

sub with_staging($class, @args) {
    _exact_invocant($class, 'with_staging');
    my $raw = _request(
        'with_staging', \@args,
        [qw(repository_root level consumer)],
    );
    confess "portable runtime materialization consumer must be one code reference\n"
        unless ref($raw->{consumer}) eq 'CODE';
    _selected_level($raw->{level});
    confess "preflight-dominated runtime shapes cannot create staging\n"
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

# Runtime measurement needs the canonical blessed route and emission so the
# shared lifecycle, rather than a second adapter-owned executor, remains the
# only tool authority.  Keep this cumulative seam private to the exact
# measurement adapter.  This producer rechecks repository source and emission
# contracts; the adapter binds the returned route and emission projections to
# its admitted canonical structural report before any lifecycle transition.
sub _measurement_inputs($class, @args) {
    _exact_invocant($class, '_measurement_inputs');
    my $caller = caller;
    confess "portable runtime measurement inputs are private to the exact adapter\n"
        unless defined($caller)
            && $caller eq
                'FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement';
    my $raw = _request(
        '_measurement_inputs', \@args,
        [qw(repository_root level artifact_root)],
    );
    my $repo_root = _repository_root($raw->{repository_root});
    _selected_level($raw->{level});
    confess "preflight-dominated runtime shapes have no lifecycle inputs\n"
        unless exists $MATERIALIZED{$raw->{level}};
    my $artifact_root = _safe_relative_path($raw->{artifact_root});
    my $construction = _canonical_construction($repo_root, $raw->{level});
    my $source = _source_input($construction);
    my $route = _canonical_route(
        $source->{relative_path}, $source->{content},
        _hial_input($construction)->{content},
    );
    my $emission = _emit($route, $artifact_root);
    my $oracle = _emission_oracle($raw->{level}, $emission);
    return {
        construction => _clone($construction),
        route => $route,
        emission => $emission,
        emission_oracle => $oracle,
    };
}

sub _evaluate($repo_root, $level) {
    my $first_construction = _canonical_construction($repo_root, $level);
    my $second_construction = _canonical_construction($repo_root, $level);
    confess "portable runtime construction is nondeterministic\n"
        unless _canonical_json($first_construction)
            eq _canonical_json($second_construction);
    my $spec = $first_construction->{specification};
    my $limits = build_vial_tooling_contract()->{limits};
    my $artifact_cap = 0 + $limits->{artifact_bytes};
    my $admission_ceiling = int($artifact_cap * 3 / 4);

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
            graph_projection => {
                artifact_cap_bytes => $artifact_cap,
                qualification_admission_ceiling_bytes => $admission_ceiling,
                expected_full_graph_bytes => undef,
                hard_cap_headroom_bytes => undef,
                admission_headroom_bytes => undef,
                status => 'preflight_dominated',
                evidence_class => 'minimum_trace_representation',
            },
            dominance => _dominance($artifact_cap, $admission_ceiling),
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
    confess "tracked portable runtime source contains an undeclared delta\n"
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
    confess "portable runtime route is nondeterministic\n"
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
    confess "portable runtime emission is nondeterministic\n"
        unless _canonical_json($first_emission)
            eq _canonical_json($second_emission);
    my $emission = _emission_oracle($level, $first_emission);
    my $trace = _record_projection($contract->{reset_cycles});
    confess "portable runtime trace equation changed\n"
        unless $trace->{record_count} == $contract->{trace_records};
    my $full_graph = $contract->{expected_full_graph_bytes};
    my $graph_status = !defined($full_graph)
        ? 'correctness_only'
        : $full_graph <= $admission_ceiling
            ? 'admitted' : 'headroom_rule_rejected';
    confess "selected portable runtime candidate violates its admission rule\n"
        if $level =~ /candidate/ && $graph_status ne 'admitted';

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
        graph_projection => {
            artifact_cap_bytes => $artifact_cap,
            qualification_admission_ceiling_bytes => $admission_ceiling,
            expected_full_graph_bytes => $full_graph,
            hard_cap_headroom_bytes => defined($full_graph)
                ? $artifact_cap - $full_graph : undef,
            admission_headroom_bytes => defined($full_graph)
                ? $admission_ceiling - $full_graph : undef,
            status => $graph_status,
            evidence_class => defined($full_graph)
                ? 'final_tracked_public_run_rederived'
                : 'correctness_only_no_scale_projection',
        },
        dominance => _dominance($artifact_cap, $admission_ceiling),
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
    _selected_level($level);
    my $hial = _read_exact_repository_file(
        $repo_root, $HIAL_PATH, $HIAL_BYTES, $HIAL_SHA256,
        'checked HIAL reference',
    );
    my $source_contract = $MATERIALIZED{$level} // $MATERIALIZED{reference_v1};
    my $source = _read_exact_repository_file(
        $repo_root, $source_contract->{path}, $source_contract->{bytes},
        $source_contract->{sha256}, 'portable runtime VIAL source',
    );
    my $construction = FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $FAMILY,
        level => $level,
        primary_axis => $PRIMARY_AXIS,
        backend_profile => $PROFILE,
        tool_profile => 'verilator_5_046',
        inputs => [
            _input($HIAL_PATH, 'hial_source', $hial),
            _input($source_contract->{path}, 'vial_source', $source),
        ],
    });
    confess "portable runtime workload construction failed\n"
        unless $construction->{ok};
    my $expected_count = $MATERIALIZED{$level}{trace_records}
        if exists $MATERIALIZED{$level} && $level ne 'reference_v1';
    confess "portable runtime requested count changed\n"
        if defined($expected_count)
            && ($construction->{specification}{requested_counts}
                    {semantic_trace_records} // -1) != $expected_count;
    return _clone($construction);
}

sub _canonical_route($source_path, $source, $hial) {
    confess "portable runtime canonical route is caller-sealed\n"
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
    confess "portable runtime canonical plan route failed\n"
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
    my $reference_signature = _execution_signature($reference_execution, 0);
    my $candidate_signature = _execution_signature(
        $candidate_execution, $level eq 'reference_v1' ? 0 : 1,
    );
    confess "portable runtime ExecutionIR has an undeclared structural delta\n"
        unless _canonical_json($reference_signature)
            eq _canonical_json($candidate_signature);
    my $reference_maps = _source_map_signature(
        $reference_execution->{source_map}, 0,
    );
    my $candidate_maps = _source_map_signature(
        $candidate_execution->{source_map},
        $level eq 'reference_v1' ? 0 : 1,
    );
    confess "portable runtime source-map topology has an undeclared delta\n"
        unless _canonical_json($reference_maps)
            eq _canonical_json($candidate_maps);
    my $reference_inputs = _canonical_json($reference->{backend_inputs});
    my $candidate_inputs = _canonical_json($candidate->{backend_inputs});
    confess "portable runtime backend inputs changed\n"
        unless $reference_inputs eq $candidate_inputs;
    return {
        oracle => 'portable_runtime_selected_delta_v1',
        reference_source => $REFERENCE_PATH,
        only_selected_source_deltas => JSON::PP::true,
        semantic_ids_preserved => JSON::PP::true,
        execution_topology_preserved => JSON::PP::true,
        backend_inputs_preserved => JSON::PP::true,
        source_map_topology_preserved => JSON::PP::true,
        allowed_deltas => $level eq 'reference_v1' ? [] : [qw(
            success_reset_cycles success_timeout_cycles
            success_await_windows terminal_scale_response_zero
        )],
    };
}

sub _execution_signature($execution, $remove_scale) {
    my $copy = _clone($execution);
    delete @{$copy}{qw(
        plan_id schema schema_version diagnostics source_map semantic_identity
    )};
    _remove_locations($copy);
    my $success_id = 'ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success';
    my $scale_operation;
    if ($remove_scale) {
        my @kept;
        for my $operation (@{$copy->{operation_graph}{operations}}) {
            if (_is_scale_expectation($operation)) {
                $scale_operation = $operation->{operation_id};
                next;
            }
            push @kept, $operation;
        }
        confess "portable runtime candidate lacks one scale expectation\n"
            unless defined $scale_operation;
        $copy->{operation_graph}{operations} = \@kept;
        $copy->{operation_graph}{total_operation_count}--;
        $copy->{resource_summary}{expanded_operations_total}--;
        $copy->{resource_summary}{source_map_records}--;
    }
    for my $operation (@{$copy->{operation_graph}{operations}}) {
        next unless $operation->{scenario_id} eq $success_id;
        $operation->{deadline}{cycle} = 255
            if ref($operation->{deadline}) eq 'HASH';
        if ($operation->{kind} eq 'reset') {
            _typed_input($operation, 'cycles')->{value} = 3;
        }
        if ($operation->{kind} eq 'await') {
            _typed_input($operation, 'property')->{value}{max_cycles} = 256;
        }
        if (defined($scale_operation)) {
            $operation->{successor_ids} = [grep {
                $_ ne $scale_operation
            } @{$operation->{successor_ids}}];
        }
    }
    for my $scenario (@{$copy->{scenarios}}) {
        next unless $scenario->{scenario_id} eq $success_id;
        $scenario->{timeout_cycles} = 256;
        $scenario->{plan_summary}{timeout_cycles} = 256;
        if (defined($scale_operation)) {
            $scenario->{operation_ids} = [grep {
                $_ ne $scale_operation
            } @{$scenario->{operation_ids}}];
            $scenario->{plan_summary}{operation_count}--;
            $scenario->{plan_summary}{expectation_ids} = [grep {
                $_ !~ /::expectation::scale_response_zero\z/
            } @{$scenario->{plan_summary}{expectation_ids}}];
        }
    }
    return $copy;
}

sub _source_map_signature($maps, $remove_scale) {
    my @signature;
    for my $map (@$maps) {
        next if $remove_scale
            && ($map->{semantic_path} // '') eq
                '/packages/0/fixtures/0/scenarios/0/actions/10';
        push @signature, {
            semantic_path => $map->{semantic_path},
            bridge_fact_paths => _clone($map->{bridge_fact_paths}),
        };
    }
    return \@signature;
}

sub _schedule_oracle($level, $route) {
    my $execution = $route->{execution_ir}->as_hashref;
    my $contract = $MATERIALIZED{$level};
    my ($success) = grep { $_->{name} eq 'success' }
        @{$execution->{scenarios}};
    my ($error) = grep { $_->{name} eq 'unsupported_size' }
        @{$execution->{scenarios}};
    confess "portable runtime scenario inventory changed\n"
        unless defined($success) && defined($error)
            && @{$execution->{scenarios}} == 2;
    my @success_operations = grep {
        $_->{scenario_id} eq $success->{scenario_id}
    } @{$execution->{operation_graph}{operations}};
    my ($reset) = grep { $_->{kind} eq 'reset' } @success_operations;
    my @await = grep { $_->{kind} eq 'await' } @success_operations;
    my ($scale) = grep { _is_scale_expectation($_) } @success_operations;
    my ($scoreboard) = grep { $_->{kind} eq 'scoreboard_check' }
        @success_operations;
    confess "portable runtime reset count changed\n"
        unless _typed_input($reset, 'cycles')->{value}
            == $contract->{reset_cycles};
    confess "portable runtime timeout/window envelope changed\n"
        unless $success->{timeout_cycles} == $contract->{timeout_cycles}
            && @await == 2
            && !grep {
                _typed_input($_, 'property')->{value}{max_cycles}
                    != $contract->{timeout_cycles}
            } @await;
    if ($level eq 'reference_v1') {
        confess "checked reference unexpectedly contains scale expectation\n"
            if defined $scale;
    }
    else {
        confess "portable runtime terminal expectation changed\n"
            unless defined($scale) && defined($scoreboard)
                && $scale->{static_rank} == $scoreboard->{static_rank} + 1
                && !@{$scale->{successor_ids}}
                && @{$scoreboard->{successor_ids}} == 1
                && $scoreboard->{successor_ids}[0] eq $scale->{operation_id};
    }
    confess "portable runtime operation/source-map count changed\n"
        unless $execution->{operation_graph}{total_operation_count}
                == $contract->{operation_count}
            && @{$execution->{source_map}} == $contract->{source_map_count};
    return {
        scenario_names => [map { $_->{name} } @{$execution->{scenarios}}],
        success_timeout_cycles => 0 + $success->{timeout_cycles},
        success_reset_cycles =>
            0 + _typed_input($reset, 'cycles')->{value},
        success_await_max_cycles => [map {
            0 + _typed_input($_, 'property')->{value}{max_cycles}
        } @await],
        operation_count =>
            0 + $execution->{operation_graph}{total_operation_count},
        source_map_count => scalar(@{$execution->{source_map}}),
        scale_expectation_id => defined($scale)
            ? $scale->{effects}[0]{target_id} : undef,
        scale_expectation_after_scoreboard => defined($scale)
            ? JSON::PP::true : JSON::PP::false,
    };
}

sub _emit($route, $artifact_root) {
    my $emission = FSM::VIAL::Backend::SVPortableVerilator->emit({
        execution_ir => $route->{execution_ir},
        bridge_manifest => $route->{bridge_manifest},
        backend_inputs => $route->{backend_inputs},
        artifact_root => $artifact_root,
        backend_profile => $PROFILE,
    });
    confess "portable runtime structural emission failed\n"
        unless $emission->{ok};
    return $emission;
}

sub _emission_oracle($level, $emission) {
    my $contract = $MATERIALIZED{$level};
    my @artifacts = @{$emission->{artifacts}};
    my ($fixture) = grep {
        $_->{relpath} =~ m{/src/base_output_arbitration_tb[.]sv\z}
    } @artifacts;
    confess "portable runtime emission lacks its fixture source\n"
        unless defined $fixture;
    confess "portable runtime fixture source identity changed\n"
        unless bytes::length($fixture->{content})
                == $contract->{expected_fixture_bytes}
            && sha256_hex($fixture->{content})
                eq $contract->{expected_fixture_sha256};
    my $reset = $contract->{reset_cycles};
    my $reset_count = () = $fixture->{content}
        =~ /repeat \(\Q$reset\E\) vial_inactive_barrier\(\);/g;
    confess "portable runtime generated reset loop changed\n"
        unless $reset_count == ($level eq 'reference_v1' ? 2 : 1);
    my @identity = map {{
        relpath => $_->{relpath},
        bytes => bytes::length($_->{content}),
        sha256 => sha256_hex($_->{content}),
    }} @artifacts;
    my $bytes = 0;
    $bytes += $_->{bytes} for @identity;
    my $mapped = scalar(@{$emission->{source_map}{entries}});
    confess "portable runtime emitted source-map count changed\n"
        unless $mapped == $contract->{operation_count} + 33;
    return {
        artifact_root => $emission->{artifact_root},
        artifact_count => scalar(@identity),
        artifact_bytes => $bytes,
        artifact_graph_sha256 => sha256_hex(_canonical_json(\@identity)),
        source_map_entries => $mapped,
        fixture_bytes => bytes::length($fixture->{content}),
        fixture_sha256 => sha256_hex($fixture->{content}),
        generated_reset_loop => "repeat ($reset) vial_inactive_barrier();",
        artifacts => \@identity,
        byte_equal_rerun => JSON::PP::true,
        external_tool_executed => JSON::PP::false,
    };
}

sub _record_projection($reset_cycles) {
    my $extra_cycles = $reset_cycles - 3;
    my %count = (
        header => 1,
        scenario_start => 2,
        events => 36,
        drives => 16,
        samples => 148 + 4 * $extra_cycles,
        transactions => 2,
        expectations => 10 + ($reset_cycles == 3 ? 0 : 1),
        models => 4,
        scoreboards => 4,
        coverage => 37 + $extra_cycles,
        faults => 3,
        fibers => 8,
        scenario_end => 2,
        footer => 1,
    );
    my $total = 0;
    $total += $_ for values %count;
    return {
        schema => 'fsmgen.vial_sv_runtime_trace.v1',
        equation => '5N+260',
        reset_cycles => 0 + $reset_cycles,
        record_count => $total,
        record_families => {map { $_ => 0 + $count{$_} } sort keys %count},
        derivation => {
            checked_reference_records => 274,
            sampled_values_per_added_cycle => 4,
            coverage_records_per_added_cycle => 1,
            terminal_expectation_records => $reset_cycles == 3 ? 0 : 1,
        },
    };
}

sub _structural_trace_projection($spec) {
    my $counts = $spec->{requested_counts};
    return {
        schema => 'fsmgen.vial_sv_runtime_trace.v1',
        equation => undef,
        reset_cycles => undef,
        record_count => $counts->{structural_trace_records},
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

sub _dominance($artifact_cap, $admission_ceiling) {
    return [
        {
            records => 20_000,
            observed_graph_bytes => 62_914_039,
            classification => 'qualification_headroom_rule_rejected',
            governing_bytes => $admission_ceiling,
            external_tool_eligible => JSON::PP::false,
            evidence_class => 'decision_0083_selection_probe',
        },
        {
            records => 25_000,
            observed_graph_bytes => undef,
            classification => 'public_artifact_cap_rejected',
            governing_bytes => $artifact_cap,
            external_tool_eligible => JSON::PP::false,
            evidence_class => 'decision_0083_selection_probe',
        },
        {
            records => 100_000,
            observed_graph_bytes => undef,
            classification => 'runtime_capture_rejected',
            governing_bytes => 67_108_864,
            external_tool_eligible => JSON::PP::false,
            evidence_class => 'decision_0083_selection_probe',
        },
    ];
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
        "(scenario success\n            (timeout (cycles bus 4096))");
    _replace_once(\$source,
        "              (reset bus 3)\n"
            . '              (scoreboard_expect writes',
        '              (reset bus ' . $contract->{reset_cycles} . ")\n"
            . '              (scoreboard_expect writes');
    _replace_once(\$source,
        '(await (within (event success_write completed) 1 256))',
        '(await (within (event success_write completed) 1 4096))');
    _replace_once(\$source,
        '(await (within (same (sample ready_out) #b0) 1 256))',
        '(await (within (same (sample ready_out) #b0) 1 4096))');
    _replace_once(\$source,
        '              (scoreboard_check writes)))',
        "              (scoreboard_check writes)\n"
            . '              (expect scale_response_zero '
            . '(same (sample response) #b0))))');
    return $source;
}

sub _replace_once($text_ref, $before, $after) {
    my $count = () = $$text_ref =~ /\Q$before\E/g;
    confess "portable runtime source oracle anchor is not unique\n"
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
    confess "portable runtime plan identity is invalid\n"
        unless defined $digest;
    return ".artifacts/vial/base-output-arbitration/$digest";
}

sub _typed_input($operation, $name) {
    confess "portable runtime operation is invalid\n"
        unless ref($operation) eq 'HASH';
    my @match = grep { ($_->{name} // '') eq $name }
        @{$operation->{typed_inputs}};
    confess "portable runtime operation must contain one '$name' input\n"
        unless @match == 1;
    return $match[0];
}

sub _is_scale_expectation($operation) {
    return 0 unless ($operation->{kind} // '') eq 'expect';
    return scalar(grep {
        ($_->{target_id} // '') =~ /::expectation::scale_response_zero\z/
    } @{$operation->{effects}}) == 1;
}

sub _remove_locations($value) {
    return unless ref($value);
    if (ref($value) eq 'ARRAY') {
        _remove_locations($_) for @$value;
        return;
    }
    confess "portable runtime signature contains a blessed value\n"
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
    confess "portable runtime construction must contain one $role\n"
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
    confess "portable runtime repository path is unsafe\n"
        unless defined($value) && !ref($value)
            && $value =~ m{\A[A-Za-z0-9_.][A-Za-z0-9_.\/-]*\z}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                split m{/}, $value, -1;
    return $value;
}

sub _seal_report($report) {
    my $projection = _clone($report);
    delete $projection->{report_identity};
    $report->{report_identity} = 'portable-runtime-materialization/'
        . sha256_hex(_canonical_json($projection));
    _validate_report_shape($report);
}

sub _validate_report_shape($report) {
    _exact_keys($report, \@REPORT_KEYS,
        'portable runtime materialization report');
    confess "portable runtime materialization report header is invalid\n"
        unless $report->{ok}
            && ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // -1) == 1
            && ($report->{family} // '') eq $FAMILY
            && ($report->{backend_profile} // '') eq $PROFILE
            && ($report->{primary_axis} // '') eq $PRIMARY_AXIS
            && ($report->{status} // '')
                =~ /\A(?:structurally_qualified|preflight_dominated)\z/;
    _selected_level($report->{level});
    confess "portable runtime report identity is invalid\n"
        unless ($report->{report_identity} // '')
            =~ m{\Aportable-runtime-materialization/[0-9a-f]{64}\z};
    confess "portable runtime report diagnostics changed\n"
        unless ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}};
    confess "portable runtime report nonclaims changed\n"
        unless _canonical_json($report->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
}

sub _selected_level($level) {
    confess "portable runtime materialization level is not selected\n"
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
    confess "portable runtime projection contains an unsupported reference\n"
        if ref($value);
    return $value;
}

1;
