package FSM::VIAL::ArchitectureScaleBalancedPortable;

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
use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::VIAL::ArchitectureScaleBridgeFanout;
use FSM::VIAL::ArchitectureScaleCheckingState;
use FSM::VIAL::ArchitectureScaleExecutionGraph;
use FSM::VIAL::ArchitectureScaleRuntimeStream;
use FSM::VIAL::ArchitectureScaleSemanticCatalog;
use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::ExecutionBuilder;
use FSM::VIAL::Parser;

my $SCHEMA = 'fsmgen.vial_architecture_scale_balanced_portable_construction.v1';
my $REPORT_SCHEMA =
    'fsmgen.vial_architecture_scale_balanced_portable_report.v1';
my $HIAL_SOURCE =
    'generated/vial-scale/balanced-portable/'
    . 'vial_architecture_scale_balanced_portable.isf';
my $VIAL_SOURCE =
    'generated/vial-scale/balanced-portable/'
    . 'vial_architecture_scale_balanced_portable.vial';
my $REFERENCE_HIAL_SOURCE = 'ppif/ahb_lite_subordinate.ppif';
my $REFERENCE_VIAL_SOURCE =
    'vial/ahb_subordinate_base_output_arbitration.vial';
my $REFERENCE_HIAL_BYTES = 1_326;
my $REFERENCE_HIAL_SHA256 =
    '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c';
my $REFERENCE_VIAL_BYTES = 4_986;
my $REFERENCE_VIAL_SHA256 =
    '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd';
my @CONSTRUCT_KEYS = qw(reference_hial_text reference_vial_text);
my @CONSTRUCTION_KEYS = qw(
    ok status schema schema_version workload reference_sources diagnostics
);
my @BUILD_KEYS = qw(construction);
my @VALIDATE_KEYS = qw(construction report);
my @STAGING_KEYS = qw(construction repository_root consumer);
my @REPORT_KEYS = qw(
    ok status schema schema_version report_identity rerun_identity
    replay_identity workload_identity gate_evidence stage_identities metrics
    logical_time fiber_semantics checking_semantics random_semantics
    oracle_applicability claims explicit_nonclaims diagnostics
);

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    confess __PACKAGE__ . "->construct expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@CONSTRUCT_KEYS,
        'balanced-portable construction');
    return _construct($args[0]);
}

sub build($class, @args) {
    _exact_invocant($class, 'build');
    confess __PACKAGE__ . "->build expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@BUILD_KEYS, 'balanced-portable build');
    my $construction = _validated_construction($args[0]{construction});
    my ($gate_evidence, $gate_diagnostics) =
        _fresh_gate_evidence($construction);
    return {
        ok => JSON::PP::false,
        status => 'gate_prerequisite_rejected',
        semantic_ir => undef,
        bridge_manifest => undef,
        execution_ir => undef,
        plan => undef,
        gate_evidence => $gate_evidence,
        diagnostics => $gate_diagnostics,
    } if @$gate_diagnostics;
    my $route = _canonical_route($construction->{workload});
    $route->{gate_evidence} = $gate_evidence;
    return $route;
}

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@BUILD_KEYS,
        'balanced-portable evaluation');
    my $construction = _validated_construction($args[0]{construction});
    return _evaluate_validated($construction);
}

sub validate_report($class, @args) {
    _exact_invocant($class, 'validate_report');
    confess __PACKAGE__ . "->validate_report expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@VALIDATE_KEYS,
        'balanced-portable report validation');
    my $construction = _validated_construction($args[0]{construction});
    _validate_report_shape($args[0]{report});
    my $rebuilt = _evaluate_validated($construction);
    confess "balanced-portable report is not canonical\n"
        unless _canonical_json($rebuilt) eq _canonical_json($args[0]{report});
    return _clone($rebuilt);
}

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub with_staging($class, @args) {
    _exact_invocant($class, 'with_staging');
    confess __PACKAGE__ . "->with_staging expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@STAGING_KEYS,
        'balanced-portable staging');
    my $construction = _validated_construction($args[0]{construction});
    return FSM::VIAL::ArchitectureScaleWorkload->with_staging({
        construction => $construction->{workload},
        repository_root => $args[0]{repository_root},
        consumer => $args[0]{consumer},
    });
}

sub _construct($raw) {
    _validate_reference(
        $raw->{reference_hial_text}, $REFERENCE_HIAL_BYTES,
        $REFERENCE_HIAL_SHA256, 'checked-AHB HIAL',
    );
    _validate_reference(
        $raw->{reference_vial_text}, $REFERENCE_VIAL_BYTES,
        $REFERENCE_VIAL_SHA256, 'checked-AHB VIAL',
    );
    my $workload = FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => 'balanced_portable_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'interaction_profile',
        backend_profile => 'sv_portable_verilator',
        tool_profile => undef,
        inputs => [
            _input($HIAL_SOURCE, 'hial_source', _render_hial()),
            _input($VIAL_SOURCE, 'vial_source', _render_vial()),
        ],
    });
    confess "canonical balanced-portable workload construction failed\n"
        unless $workload->{ok};
    return _construction({
        ok => JSON::PP::true,
        status => 'canonical_sources_constructed',
        schema => $SCHEMA,
        schema_version => 1,
        workload => $workload,
        reference_sources => {
            hial => _input(
                $REFERENCE_HIAL_SOURCE, 'hial_source',
                $raw->{reference_hial_text},
            ),
            vial => _input(
                $REFERENCE_VIAL_SOURCE, 'vial_source',
                $raw->{reference_vial_text},
            ),
        },
        diagnostics => [],
    });
}

sub _validated_construction($raw) {
    confess "construction must be one unblessed hash\n"
        unless ref($raw) eq 'HASH' && !blessed($raw);
    _confess_exact_keys($raw, \@CONSTRUCTION_KEYS,
        'balanced-portable construction result');
    confess "construction is not successful\n"
        unless $raw->{ok} && ($raw->{status} // '') eq
            'canonical_sources_constructed'
            && ($raw->{schema} // '') eq $SCHEMA
            && ($raw->{schema_version} // 0) == 1
            && ref($raw->{reference_sources}) eq 'HASH'
            && ref($raw->{diagnostics}) eq 'ARRAY'
            && !@{$raw->{diagnostics}};
    _confess_exact_keys($raw->{reference_sources}, [qw(hial vial)],
        'balanced-portable reference sources');
    my $rebuilt = _construct({
        reference_hial_text => $raw->{reference_sources}{hial}{content},
        reference_vial_text => $raw->{reference_sources}{vial}{content},
    });
    confess "balanced-portable construction is not canonical\n"
        unless _canonical_json($rebuilt) eq _canonical_json($raw);
    return _clone($rebuilt);
}

sub _fresh_gate_evidence($construction) {
    my $hial = $construction->{reference_sources}{hial}{content};
    my $vial = $construction->{reference_sources}{vial}{content};
    my @gate = (
        {
            constructor => 'FSM::VIAL::ArchitectureScaleSemanticCatalog',
            family => 'semantic_catalog_v1',
            axis => 'record_fields',
            status => 'accepted',
            schema =>
                'fsmgen.vial_architecture_scale_semantic_evaluation.v1',
            construct => sub {
                FSM::VIAL::ArchitectureScaleSemanticCatalog->construct({
                    primary_axis => 'record_fields',
                    level => 'gate_candidate_v1',
                    reference_text => undef,
                });
            },
            evaluate => sub($candidate) {
                FSM::VIAL::ArchitectureScaleSemanticCatalog->evaluate({
                    construction => $candidate,
                });
            },
            substantive => sub($report) {
                return ($report->{metrics}{record_fields} // -1) == 32;
            },
        },
        {
            constructor => 'FSM::VIAL::ArchitectureScaleBridgeFanout',
            family => 'bridge_fanout_v1',
            axis => 'endpoints',
            status => 'accepted',
            schema => 'fsmgen.vial_architecture_scale_bridge_evaluation.v1',
            construct => sub {
                FSM::VIAL::ArchitectureScaleBridgeFanout->construct({
                    primary_axis => 'endpoints',
                    level => 'gate_candidate_v1',
                    reference_hial_text => undef,
                    reference_vial_text => undef,
                });
            },
            evaluate => sub($candidate) {
                FSM::VIAL::ArchitectureScaleBridgeFanout->evaluate({
                    construction => $candidate,
                });
            },
            substantive => sub($report) {
                return ($report->{metrics}{endpoints} // -1) == 256
                    && ($report->{metrics}{selected_units} // -1) == 1
                    && ($report->{metrics}{selected_domains} // -1) == 1;
            },
        },
        {
            constructor => 'FSM::VIAL::ArchitectureScaleExecutionGraph',
            family => 'execution_graph_v1',
            axis => 'bindings',
            status => 'accepted',
            schema =>
                'fsmgen.vial_architecture_scale_execution_evaluation.v1',
            construct => sub {
                FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
                    primary_axis => 'bindings',
                    level => 'gate_candidate_v1',
                });
            },
            evaluate => sub($candidate) {
                FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
                    construction => $candidate,
                });
            },
            substantive => sub($report) {
                return ($report->{metrics}{bindings} // -1) == 2_048;
            },
        },
        {
            constructor => 'FSM::VIAL::ArchitectureScaleCheckingState',
            family => 'checking_state_v1',
            axis => 'random_occurrences',
            status => 'accepted',
            schema =>
                'fsmgen.vial_architecture_scale_checking_evaluation.v1',
            construct => sub {
                FSM::VIAL::ArchitectureScaleCheckingState->construct({
                    primary_axis => 'random_occurrences',
                    level => 'gate_candidate_v1',
                    reference_hial_text => $hial,
                });
            },
            evaluate => sub($candidate) {
                FSM::VIAL::ArchitectureScaleCheckingState->evaluate({
                    construction => $candidate,
                });
            },
            substantive => sub($report) {
                my $random = $report->{oracle_evidence}{random_replay} || {};
                return ($report->{metrics}{random_occurrences} // -1) == 1_024
                    && ($report->{oracle_evidence}{oracle} // '')
                        eq 'random_replay'
                    && $random->{generated_values_matched}
                    && $random->{replay_values_matched}
                    && $random->{normalized_plans_equal};
            },
        },
        {
            constructor => 'FSM::VIAL::ArchitectureScaleBackendEmission',
            family => 'backend_emission_v1',
            axis => 'artifact_graph',
            backend_profile => 'sv_portable_verilator',
            status => 'profile_validated',
            schema =>
                'fsmgen.vial_architecture_scale_backend_emission_evaluation.v1',
            construct => sub {
                FSM::VIAL::ArchitectureScaleBackendEmission->construct({
                    backend_profile => 'sv_portable_verilator',
                    level => 'gate_candidate_v1',
                    reference_hial_text => $hial,
                    reference_vial_text => $vial,
                });
            },
            evaluate => sub($candidate) {
                FSM::VIAL::ArchitectureScaleBackendEmission->evaluate({
                    construction => $candidate,
                });
            },
            substantive => sub($report) {
                return $report->{outcome_contract}{artifacts_emitted}
                    && $report->{outcome_contract}{backend_negotiation_executed}
                    && $report->{claims}{artifact_graph_claimed}
                    && !$report->{claims}{external_runtime_executed}
                    && !$report->{claims}{capacity_claimed};
            },
        },
        {
            constructor => 'FSM::VIAL::ArchitectureScaleRuntimeStream',
            family => 'runtime_stream_v1',
            axis => 'runtime_trace_records',
            backend_profile => 'sv_portable_verilator',
            status => 'provider_free_runtime_inputs_constructed',
            schema =>
                'fsmgen.vial_architecture_scale_runtime_stream_report.v1',
            construct => sub {
                FSM::VIAL::ArchitectureScaleRuntimeStream->construct({
                    backend_profile => 'sv_portable_verilator',
                    level => 'gate_candidate_v1',
                    reference_hial_text => $hial,
                    reference_vial_text => $vial,
                });
            },
            evaluate => sub($candidate) {
                FSM::VIAL::ArchitectureScaleRuntimeStream->evaluate({
                    construction => $candidate,
                });
            },
            substantive => sub($report) {
                return ($report->{requested_counts}{semantic_trace_records}
                        // -1) == 10_000
                    && $report->{claims}{runtime_stream_constructed}
                    && $report->{claims}{canonical_backend_inputs_constructed}
                    && !$report->{claims}{external_tool_executed}
                    && !$report->{claims}{runtime_executed}
                    && !$report->{claims}{capacity_claimed};
            },
        },
    );

    my (@evidence, @diagnostics);
    for my $gate (@gate) {
        my ($candidate, $report);
        my $completed = eval {
            $candidate = $gate->{construct}->();
            confess "gate construction rejected\n" unless $candidate->{ok};
            $report = $gate->{evaluate}->($candidate);
            1;
        };
        if (!$completed) {
            push @diagnostics, _diagnostic(
                'VIAL_SCALE_BALANCED_GATE_ERROR',
                "fresh $gate->{family} gate construction failed",
                "/gate_evidence/$gate->{family}",
            );
            push @evidence, {
                constructor => $gate->{constructor},
                family => $gate->{family},
                level => 'gate_candidate_v1',
                primary_axis => $gate->{axis},
                backend_profile => $gate->{backend_profile},
                status => 'failed',
                report_schema => $gate->{schema},
                workload_identity => undef,
                requested_counts => undef,
                report_sha256 => undef,
                substantive_oracle => JSON::PP::false,
            };
            next;
        }
        my $substantive = eval { $gate->{substantive}->($report) } ? 1 : 0;
        my $valid = $report->{ok}
            && ($report->{status} // '') eq $gate->{status}
            && ($report->{schema} // '') eq $gate->{schema}
            && ($report->{family} // '') eq $gate->{family}
            && ($report->{level} // '') eq 'gate_candidate_v1'
            && ($report->{primary_axis} // '') eq $gate->{axis}
            && (!defined($gate->{backend_profile})
                || ($report->{backend_profile} // '')
                    eq $gate->{backend_profile})
            && ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}}
            && $substantive;
        push @diagnostics, _diagnostic(
            'VIAL_SCALE_BALANCED_GATE_ERROR',
            "fresh $gate->{family} gate report failed its closed oracle",
            "/gate_evidence/$gate->{family}",
        ) unless $valid;
        push @evidence, {
            constructor => $gate->{constructor},
            family => $gate->{family},
            level => 'gate_candidate_v1',
            primary_axis => $gate->{axis},
            backend_profile => $gate->{backend_profile},
            status => $report->{status},
            report_schema => $report->{schema},
            workload_identity => $report->{workload_identity},
            requested_counts => _clone($report->{requested_counts}),
            report_sha256 => sha256_hex(_canonical_json($report)),
            substantive_oracle => $substantive
                ? JSON::PP::true : JSON::PP::false,
        };
    }
    return (\@evidence, \@diagnostics);
}

sub _evaluate_validated($construction) {
    my ($gate_evidence, $gate_diagnostics) =
        _fresh_gate_evidence($construction);
    return _failed_report(
        $construction, 'gate_prerequisite_failure', $gate_evidence,
        $gate_diagnostics,
    ) if @$gate_diagnostics;

    my $first = _canonical_route($construction->{workload});
    return _failed_report(
        $construction, 'canonical_route_failure', $gate_evidence,
        $first->{diagnostics},
    ) unless $first->{ok};
    my $second = _canonical_route($construction->{workload});
    return _failed_report(
        $construction, 'canonical_rerun_failure', $gate_evidence,
        $second->{diagnostics},
    ) unless $second->{ok};

    my $first_projection = _route_projection($first);
    my $second_projection = _route_projection($second);
    my @diagnostics;
    for my $stage (qw(semantic_ir bridge_manifest execution_ir plan)) {
        push @diagnostics, _diagnostic(
            'VIAL_SCALE_BALANCED_DETERMINISM_ERROR',
            "independent canonical $stage production changed bytes",
            "/stage_identities/$stage",
        ) unless _canonical_json($first_projection->{$stage})
            eq _canonical_json($second_projection->{$stage});
    }

    my $stage_identities = {
        hial_source_sha256 => sha256_hex(
            _role_input($construction->{workload}, 'hial_source')->{content},
        ),
        vial_source_sha256 => sha256_hex(
            _role_input($construction->{workload}, 'vial_source')->{content},
        ),
        semantic_ir_sha256 =>
            sha256_hex(_canonical_json($first_projection->{semantic_ir})),
        bridge_manifest_sha256 =>
            sha256_hex(_canonical_json($first_projection->{bridge_manifest})),
        execution_ir_sha256 =>
            sha256_hex(_canonical_json($first_projection->{execution_ir})),
        plan_sha256 => sha256_hex(_canonical_json($first_projection->{plan})),
    };
    my $second_identities = {
        semantic_ir_sha256 =>
            sha256_hex(_canonical_json($second_projection->{semantic_ir})),
        bridge_manifest_sha256 =>
            sha256_hex(_canonical_json($second_projection->{bridge_manifest})),
        execution_ir_sha256 =>
            sha256_hex(_canonical_json($second_projection->{execution_ir})),
        plan_sha256 => sha256_hex(_canonical_json($second_projection->{plan})),
    };
    my $rerun_identity = 'rerun/' . sha256_hex(_canonical_json({
        workload_identity => $construction->{workload}{workload_identity},
        first => $stage_identities,
        second => $second_identities,
    }));

    my $replay_manifest = _replay_manifest($first_projection->{plan});
    my $replayed = _canonical_route(
        $construction->{workload}, $replay_manifest,
    );
    push @diagnostics, _diagnostic(
        'VIAL_SCALE_BALANCED_REPLAY_ERROR',
        'balanced keyed random replay was rejected',
        '/random_semantics/replay',
    ) unless $replayed->{ok};
    my $replay_equal = 0;
    if ($replayed->{ok}) {
        my $generated_plan = _clone($first_projection->{plan});
        my $replayed_plan = _clone($replayed->{plan});
        delete $generated_plan->{plan_id};
        delete $replayed_plan->{plan_id};
        $_->{origin} = 'replayed'
            for @{$generated_plan->{random_decisions} || []};
        $replay_equal = _canonical_json($generated_plan)
            eq _canonical_json($replayed_plan);
        push @diagnostics, _diagnostic(
            'VIAL_SCALE_BALANCED_REPLAY_ERROR',
            'balanced replay changed the normalized execution plan',
            '/random_semantics/normalized_plans_equal',
        ) unless $replay_equal;
    }

    my $bridge = $first_projection->{bridge_manifest};
    my $ir = $first_projection->{execution_ir};
    my $plan = $first_projection->{plan};
    my $resources = $ir->{resource_summary};
    my $transaction_fields = 0;
    $transaction_fields += @{$_->{fields}}
        for @{$ir->{bindings}{transactions}};
    my $hial_input = _role_input($construction->{workload}, 'hial_source');
    my $vial_input = _role_input($construction->{workload}, 'vial_source');
    my $metrics = {
        selected_units => scalar(@{$bridge->{units}}),
        selected_domains => 0 + $resources->{selected_domains},
        endpoints => scalar(@{$bridge->{endpoints}}),
        transactions => scalar(@{$bridge->{transactions}}),
        fields_per_transaction => [map { scalar(@{$_->{fields}}) }
            @{$bridge->{transactions}}],
        transaction_fields => $transaction_fields,
        events => scalar(@{$bridge->{events}}),
        probes => scalar(@{$bridge->{probes}}),
        scenarios => 0 + $resources->{selected_scenarios},
        operations_total => 0 + $resources->{expanded_operations_total},
        fibers_total => 0 + $resources->{total_fibers},
        simultaneously_live_fibers =>
            0 + $resources->{simultaneous_live_fibers},
        bindings => 0 + $resources->{bindings},
        execution_types => 0 + $resources->{execution_types},
        model_instances => 0 + $resources->{model_instances},
        scalar_model_state_cells => 0 + $resources->{scalar_state_cells},
        scoreboard_instances => 0 + $resources->{scoreboard_instances},
        scoreboard_capacity =>
            0 + $resources->{scoreboard_declared_capacity},
        coverpoints => 0 + $resources->{coverpoints},
        coverage_bins => 0 + $resources->{coverage_bins_and_cross_tuples},
        faults => 0 + $resources->{faults},
        random_occurrences => 0 + $resources->{random_occurrences},
        source_map_records => 0 + $resources->{source_map_records},
        serialized_plan_bytes => bytes::length(_canonical_json($plan)),
        hial_source_bytes => bytes::length($hial_input->{content}),
        vial_source_bytes => bytes::length($vial_input->{content}),
    };
    _validate_metrics(
        $construction->{workload}{specification}{requested_counts},
        $metrics, \@diagnostics,
    );

    my @fiber_counts = map { scalar(@{$_->{fibers}}) } @{$ir->{scenarios}};
    my @operation_counts = map { 0 + $_->{plan_summary}{operation_count} }
        @{$ir->{scenarios}};
    my %operation_kind;
    $operation_kind{$_->{kind}}++
        for @{$ir->{operation_graph}{operations}};
    my $fiber_exact = join(',', @fiber_counts)
        eq join(',', 32, (4) x 3, (3) x 28)
        && join(',', @operation_counts)
            eq join(',', 60, (32) x 3, (31) x 28);
    push @diagnostics, _diagnostic(
        'VIAL_SCALE_BALANCED_FIBER_ERROR',
        'balanced per-scenario fiber/operation topology changed',
        '/fiber_semantics',
    ) unless $fiber_exact;
    my $fiber_semantics = {
        total_fibers => 0 + $resources->{total_fibers},
        maximum_simultaneously_live =>
            0 + $resources->{simultaneous_live_fibers},
        scenario_fiber_counts => \@fiber_counts,
        scenario_operation_counts => \@operation_counts,
        topology_exact => $fiber_exact
            ? JSON::PP::true : JSON::PP::false,
    };

    my $logical_exact = _canonical_json($plan->{logical_time}{phase_order})
            eq _canonical_json([qw(drive sample react check)])
        && _canonical_json($plan->{logical_time}{tie_break_order})
            eq _canonical_json([qw(
                domain_rank static_operation_rank local_emission_index
                semantic_id
            )])
        && ($plan->{logical_time}{scenario_cycle_origin} // -1) == 0
        && $plan->{logical_time}{timeout_last_cycle_inclusive};
    push @diagnostics, _diagnostic(
        'VIAL_SCALE_BALANCED_LOGICAL_TIME_ERROR',
        'balanced logical-time ordering changed',
        '/logical_time',
    ) unless $logical_exact;
    my $logical_time = {
        phase_order => _clone($plan->{logical_time}{phase_order}),
        tie_break_order => _clone($plan->{logical_time}{tie_break_order}),
        scenario_cycle_origin =>
            0 + $plan->{logical_time}{scenario_cycle_origin},
        timeout_last_cycle_inclusive =>
            $plan->{logical_time}{timeout_last_cycle_inclusive}
                ? JSON::PP::true : JSON::PP::false,
        exact => $logical_exact ? JSON::PP::true : JSON::PP::false,
    };

    my $models_exact = @{$ir->{models}} == 32
        && !scalar(grep {
            @{$_->{definition}{state} || []} != 16
                || @{$_->{definition}{rules} || []} != 1
                || @{$_->{definition}{rules}[0]{assignments} || []} != 16
        } @{$ir->{models}});
    my $scoreboards_exact = @{$ir->{scoreboards}} == 32
        && !scalar(grep { ($_->{definition}{capacity} // -1) != 128 }
            @{$ir->{scoreboards}})
        && ($operation_kind{scoreboard_expect} // 0) == 32
        && ($operation_kind{scoreboard_check} // 0) == 32
        && ($operation_kind{start} // 0) == 32;
    my $coverage_exact = @{$ir->{coverage}{coverpoints}} == 256
        && !scalar(grep { @{$_->{bins} || []} != 16 }
            @{$ir->{coverage}{coverpoints}});
    my $faults_exact = @{$ir->{faults}} == 32
        && ($operation_kind{inject} // 0) == 32
        && !scalar(grep { ($_->{duration_cycles} // -1) != 1 }
            @{$ir->{faults}});
    push @diagnostics, _diagnostic(
        'VIAL_SCALE_BALANCED_CHECKING_ERROR',
        'balanced model, scoreboard, coverage, or fault semantics changed',
        '/checking_semantics',
    ) unless $models_exact && $scoreboards_exact
        && $coverage_exact && $faults_exact;
    my $checking_semantics = {
        models_have_sixteen_increment_rules => $models_exact
            ? JSON::PP::true : JSON::PP::false,
        scoreboards_exercise_expect_start_check => $scoreboards_exact
            ? JSON::PP::true : JSON::PP::false,
        coverpoints_have_sixteen_authored_bins => $coverage_exact
            ? JSON::PP::true : JSON::PP::false,
        faults_have_one_cycle_activation => $faults_exact
            ? JSON::PP::true : JSON::PP::false,
        operation_kind_counts => {map { $_ => 0 + $operation_kind{$_} }
            sort keys %operation_kind},
    };

    my $decisions = $ir->{randomness}{decisions};
    my %occurrence;
    my %scenario;
    my $random_exact = @$decisions == 1_024;
    for my $decision (@$decisions) {
        $random_exact = 0 if $occurrence{$decision->{occurrence_id}}++
            || ($decision->{algorithm} // '')
                ne 'sha256_counter_rejection_v1'
            || ($decision->{seed} // -1) != 1_701
            || @{$decision->{reference_operation_ids} || []} != 1;
        $scenario{$decision->{scenario_id}}++;
    }
    $random_exact = 0 if keys(%scenario) != 32
        || grep { $_ != 32 } values %scenario;
    $random_exact = 0 unless $replay_equal;
    push @diagnostics, _diagnostic(
        'VIAL_SCALE_BALANCED_RANDOM_ERROR',
        'balanced keyed-random cardinality, identity, or replay changed',
        '/random_semantics',
    ) unless $random_exact;
    my $random_semantics = {
        algorithm => $ir->{randomness}{algorithm},
        seed => 0 + $ir->{randomness}{seed},
        choices_per_scenario => 32,
        scenario_count => scalar(keys %scenario),
        occurrence_count => scalar(@$decisions),
        occurrences_unique => keys(%occurrence) == @$decisions
            ? JSON::PP::true : JSON::PP::false,
        normalized_plans_equal => $replay_equal
            ? JSON::PP::true : JSON::PP::false,
    };

    my $report = {
        ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
        status => @diagnostics ? 'oracle_failure'
            : 'canonical_composition_validated',
        schema => $REPORT_SCHEMA,
        schema_version => 1,
        report_identity => undef,
        rerun_identity => $rerun_identity,
        replay_identity => $replay_manifest->{replay_id},
        workload_identity => $construction->{workload}{workload_identity},
        gate_evidence => $gate_evidence,
        stage_identities => $stage_identities,
        metrics => $metrics,
        logical_time => $logical_time,
        fiber_semantics => $fiber_semantics,
        checking_semantics => $checking_semantics,
        random_semantics => $random_semantics,
        oracle_applicability => [
            {stage => 'construct', status => 'completed'},
            {stage => 'semantic', status => 'completed'},
            {stage => 'bridge', status => 'completed'},
            {stage => 'plan', status => 'completed'},
            {stage => 'emit', status => 'deferred_to_17_2_7_2_4'},
            {stage => 'failure', status => 'specified'},
        ],
        claims => {
            schema =>
                'fsmgen.vial_architecture_scale_balanced_portable_claims.v1',
            schema_version => 1,
            qualification_only => JSON::PP::true,
            all_six_gate_reports_consumed => JSON::PP::true,
            canonical_sources_constructed => JSON::PP::true,
            canonical_execution_constructed => JSON::PP::true,
            portable_emission_qualified => JSON::PP::false,
            external_tool_executed => JSON::PP::false,
            runtime_executed => JSON::PP::false,
            support_claimed => JSON::PP::false,
            performance_claimed => JSON::PP::false,
            capacity_claimed => JSON::PP::false,
        },
        explicit_nonclaims =>
            _clone($construction->{workload}{specification}{explicit_nonclaims}),
        diagnostics => \@diagnostics,
    };
    my $identity_projection = _clone($report);
    delete $identity_projection->{report_identity};
    $report->{report_identity} = 'balanced-composition/'
        . sha256_hex(_canonical_json($identity_projection));
    _validate_report_shape($report);
    return _clone($report);
}

sub _failed_report($construction, $status, $gate_evidence, $diagnostics) {
    my $report = {
        ok => JSON::PP::false,
        status => $status,
        schema => $REPORT_SCHEMA,
        schema_version => 1,
        report_identity => undef,
        rerun_identity => undef,
        replay_identity => undef,
        workload_identity => $construction->{workload}{workload_identity},
        gate_evidence => _clone($gate_evidence),
        stage_identities => undef,
        metrics => undef,
        logical_time => undef,
        fiber_semantics => undef,
        checking_semantics => undef,
        random_semantics => undef,
        oracle_applicability => [],
        claims => {
            schema =>
                'fsmgen.vial_architecture_scale_balanced_portable_claims.v1',
            schema_version => 1,
            qualification_only => JSON::PP::true,
            all_six_gate_reports_consumed => JSON::PP::false,
            canonical_sources_constructed => JSON::PP::true,
            canonical_execution_constructed => JSON::PP::false,
            portable_emission_qualified => JSON::PP::false,
            external_tool_executed => JSON::PP::false,
            runtime_executed => JSON::PP::false,
            support_claimed => JSON::PP::false,
            performance_claimed => JSON::PP::false,
            capacity_claimed => JSON::PP::false,
        },
        explicit_nonclaims =>
            _clone($construction->{workload}{specification}{explicit_nonclaims}),
        diagnostics => _clone($diagnostics),
    };
    my $identity_projection = _clone($report);
    delete $identity_projection->{report_identity};
    $report->{report_identity} = 'balanced-composition/'
        . sha256_hex(_canonical_json($identity_projection));
    return _clone($report);
}

sub _validate_metrics($expected, $metrics, $diagnostics) {
    my %actual = (
        selected_units => $metrics->{selected_units},
        selected_domains => $metrics->{selected_domains},
        endpoints => $metrics->{endpoints},
        transactions => $metrics->{transactions},
        events => $metrics->{events},
        probes => $metrics->{probes},
        scenarios => $metrics->{scenarios},
        operations_total => $metrics->{operations_total},
        fibers_total => $metrics->{fibers_total},
        simultaneously_live_fibers =>
            $metrics->{simultaneously_live_fibers},
        bindings => $metrics->{bindings},
        execution_types => $metrics->{execution_types},
        model_instances => $metrics->{model_instances},
        scalar_model_state_cells => $metrics->{scalar_model_state_cells},
        scoreboard_instances => $metrics->{scoreboard_instances},
        scoreboard_capacity => $metrics->{scoreboard_capacity},
        coverpoints => $metrics->{coverpoints},
        coverage_bins => $metrics->{coverage_bins},
        faults => $metrics->{faults},
        random_occurrences => $metrics->{random_occurrences},
    );
    for my $key (sort keys %actual) {
        push @$diagnostics, _diagnostic(
            'VIAL_SCALE_BALANCED_COUNT_ERROR',
            "balanced $key count changed",
            "/metrics/$key",
        ) unless defined($expected->{$key})
            && $actual{$key} == $expected->{$key};
    }
    push @$diagnostics, _diagnostic(
        'VIAL_SCALE_BALANCED_COUNT_ERROR',
        'balanced transaction fields are not exactly 109 per alias',
        '/metrics/fields_per_transaction',
    ) unless $metrics->{transaction_fields} == 1_744
        && @{$metrics->{fields_per_transaction}} == 16
        && !grep { $_ != 109 } @{$metrics->{fields_per_transaction}};
}

sub _route_projection($route) {
    return {
        semantic_ir => $route->{semantic_ir}->as_hashref,
        bridge_manifest => $route->{bridge_manifest}->as_hashref,
        execution_ir => $route->{execution_ir}->as_hashref,
        plan => _clone($route->{plan}),
    };
}

sub _replay_manifest($plan) {
    my @keys = qw(
        occurrence_id declaration_semantic_id decision_id scenario_id
        algorithm seed type_id distribution value attempt
    );
    my @decisions = @{$plan->{random_decisions} || []};
    confess "balanced replay requires generated decisions\n" unless @decisions;
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
            +{map { $_ => _clone($decision->{$_}) } @keys}
        } @decisions],
    };
    my $identity_projection = _clone($replay);
    delete $identity_projection->{replay_id};
    $replay->{replay_id} = 'replay/'
        . sha256_hex(_canonical_json($identity_projection));
    return $replay;
}

sub _validate_report_shape($report) {
    _confess_exact_keys($report, \@REPORT_KEYS,
        'balanced-portable report');
    confess "balanced-portable report schema/version is invalid\n"
        unless ($report->{schema} // '') eq $REPORT_SCHEMA
            && ($report->{schema_version} // 0) == 1;
    confess "balanced-portable report identity is invalid\n"
        unless ($report->{report_identity} // '')
            =~ m{\Abalanced-composition/[0-9a-f]{64}\z};
    my $identity_projection = _clone($report);
    my $identity = delete $identity_projection->{report_identity};
    confess "balanced-portable report identity does not cover its payload\n"
        unless $identity eq 'balanced-composition/'
            . sha256_hex(_canonical_json($identity_projection));
    confess "balanced-portable report collections are malformed\n"
        unless ref($report->{gate_evidence}) eq 'ARRAY'
            && ref($report->{oracle_applicability}) eq 'ARRAY'
            && ref($report->{claims}) eq 'HASH'
            && ref($report->{explicit_nonclaims}) eq 'ARRAY'
            && ref($report->{diagnostics}) eq 'ARRAY';
}

sub _diagnostic($code, $message, $path) {
    return {
        code => $code,
        severity => 'error',
        message => $message,
        path => $path,
    };
}

sub _canonical_route($workload, $replay_manifest = undef) {
    confess "canonical balanced route is private to " . __PACKAGE__ . "\n"
        unless caller eq __PACKAGE__;
    my $hial = _role_input($workload, 'hial_source');
    my $vial = _role_input($workload, 'vial_source');
    my $actor = FSM::Adapter::ISF->new()->parse_source(
        $hial->{content}, basename($hial->{relative_path}),
    );
    my $scheduler = FSM::Scheduler::ISF->new();
    my $schedule_report = JSON::PP->new->decode($scheduler->report($actor));
    my $lowered = $scheduler->lower($actor);
    my $artifact_name = $actor->{actor_name} . '.fsm';
    $artifact_name = $actor->{actor_name} . '_top.fsm'
        unless exists $lowered->{files}{$artifact_name};
    my $bridge = __PACKAGE__->_call_bridge({
        profile => 'core_single_unit_v1',
        authored_source => _source_record(
            $hial->{content}, $hial->{relative_path},
        ),
        actor => $actor,
        schedule_report => $schedule_report,
        generated_ial0 => _source_record(
            $lowered->{files}{$artifact_name}, undef, $artifact_name,
        ),
        backend_names => _backend_names($actor),
    });
    return {
        ok => JSON::PP::false,
        status => 'bridge_rejected',
        semantic_ir => undef,
        bridge_manifest => undef,
        execution_ir => undef,
        plan => undef,
        diagnostics => _clone($bridge->{diagnostics}),
    } unless $bridge->{ok};

    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $vial->{content},
        source_name => $vial->{relative_path},
        source_catalog => {},
    });
    my $semantic = $semantic_ir->as_hashref;
    my $fixture = $semantic->{packages}[0]{fixtures}[0];
    my $execution = __PACKAGE__->_call_execution({
        semantic_ir => $semantic_ir,
        bridge_manifest => $bridge->{manifest},
        fixture_id => $fixture->{semantic_id},
        scenario_ids => [map { $_->{semantic_id} }
            @{$fixture->{scenarios}}],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => $replay_manifest,
        native_extension_catalog => [],
    });
    return {
        ok => JSON::PP::false,
        status => 'execution_rejected',
        semantic_ir => $semantic_ir,
        bridge_manifest => $bridge->{manifest},
        execution_ir => undef,
        plan => undef,
        diagnostics => _clone($execution->{diagnostics}),
    } unless $execution->{ok};
    return {
        ok => JSON::PP::true,
        status => 'canonical_execution_constructed',
        semantic_ir => $semantic_ir,
        bridge_manifest => $bridge->{manifest},
        execution_ir => $execution->{execution_ir},
        plan => _clone($execution->{plan}),
        diagnostics => [],
    };
}

sub _render_hial() {
    my @endpoints = map { sprintf('endpoint_%08d', $_) } 0 .. 125;
    my @field_endpoints = @endpoints[0 .. 108];
    my @interface = map { "(input $_)" } @endpoints;
    my @storage = map {
        sprintf('(var probe_%08d (width 1))', $_)
    } 0 .. 31;
    my @fields = map { "(field $_ $_ drive unspecified)" }
        @field_endpoints;
    my @bridge_events = map {
        sprintf('(event bridge_event_%08d predicate sample endpoint_00000000)',
            $_)
    } 0 .. 112;
    my @probes = map { sprintf('(probe probe_%08d read_only)', $_) }
        0 .. 31;
    my @ports = map { "(input $_)" } @field_endpoints;
    my @transactions = map {
        sprintf('(transaction transaction_%08d (ports %s) '
            . '(on endpoint_00000000))', $_, join(' ', @ports))
    } 1 .. 15;
    return join('',
        '(actor vial_architecture_scale_balanced_portable',
        ' (clock clk)',
        ' (reset (rst_n async active_low))',
        ' (interface ', join(' ', @interface), ')',
        ' (storage ', join(' ', @storage), ')',
        ' (verification-bridge',
        ' (domain balanced)',
        ' (protocol architecture_scale_probe',
        ' (profile balanced_portable)',
        ' (revision 2)',
        ' (role verification)',
        ' (facts (fact scale_evidence_only true)',
        ' (fact qualified_emitter sv_portable_verilator)))',
        ' (transaction transaction_00000000',
        ' (fields ', join(' ', @fields), ')',
        ' (events ', join(' ', @bridge_events), '))',
        ' ', join(' ', @probes), ')',
        ' ', join(' ', @transactions), ')',
        "\n",
    );
}

sub _render_vial() {
    my @endpoints = map { sprintf('endpoint_%08d', $_) } 0 .. 125;
    my @field_endpoints = @endpoints[0 .. 108];
    my @fields = map { "($_ (type bit_t))" } @field_endpoints;
    my @bridge_events = map { sprintf('bridge_event_%08d', $_) }
        0 .. 112;
    my @transaction_types = (
        '(transaction transaction_00000000 (fields '
            . join(' ', @fields) . ') (events '
            . join(' ', @bridge_events) . '))',
        map {
            sprintf('(transaction transaction_%08d (fields %s) (events on))',
                $_, join(' ', @fields))
        } 1 .. 15,
    );
    my @types = ('(type bit_t (logic 1))');
    push @types, map {
        sprintf('(type value_type_%08d (u %d))', $_, $_ + 16)
    } 0 .. 509;

    my (@models, @model_instances);
    for my $model_ordinal (0 .. 31) {
        my (@state, @sets);
        for my $cell_ordinal (0 .. 15) {
            my $ordinal = $model_ordinal * 16 + $cell_ordinal;
            my $cell = sprintf('cell_%08d', $ordinal);
            my $type = sprintf('value_type_%08d', $ordinal % 510);
            push @state, "($cell (type $type) 0)";
            push @sets, "(set $cell (+ $cell 1))";
        }
        my $model = sprintf('model_%08d', $model_ordinal);
        push @models, join('',
            '(model ', $model,
            ' (inputs (tick event))',
            ' (state ', join(' ', @state), ')',
            ' (rules (on tick ', join(' ', @sets), ')))',
        );
        push @model_instances, sprintf(
            '(model model_instance_%08d %s '
                . '(bind tick (event alias_00000000 bridge_event_%08d)))',
            $model_ordinal, $model, $model_ordinal,
        );
    }

    my $scoreboard_definition = join('',
        '(scoreboard balanced_scoreboard',
        ' (transaction transaction_00000000)',
        ' (policy in_order)',
        ' (capacity 128))',
    );
    my @scoreboard_instances = map {
        sprintf('(scoreboard scoreboard_%08d balanced_scoreboard '
            . '(actual alias_00000000))', $_)
    } 0 .. 31;

    my @endpoint_bindings = map {
        sprintf('(endpoint %s "endpoint/%s" (type bit_t) public_port)',
            $_, $_)
    } @endpoints;
    my @probe_bindings = map {
        sprintf('(endpoint probe_%08d "probe/probe_%08d" '
            . '(type bit_t) verification_probe)', $_, $_)
    } 0 .. 31;
    my @transaction_bindings = map {
        sprintf('(transaction alias_%08d "transaction/transaction_%08d" '
            . 'transaction_%08d)', $_, $_, $_)
    } 0 .. 15;

    my @coverpoints;
    for my $point_ordinal (0 .. 255) {
        my @bins = map {
            sprintf('(bin bin_%08d_%02d normal (value #b%d))',
                $point_ordinal, $_, $_ % 2)
        } 0 .. 15;
        push @coverpoints, sprintf(
            '(coverpoint coverpoint_%08d (sample balanced) '
                . '(expr (sample probe_00000000)) (bins %s))',
            $point_ordinal, join(' ', @bins),
        );
    }

    my @faults = map {
        sprintf('(fault fault_%08d '
            . '(target (transaction alias_%08d endpoint_00000000)) '
            . '(action (substitute #b1)) '
            . '(duration (cycles balanced 1)))', $_, $_ % 16)
    } 0 .. 31;
    my @choices = map {
        sprintf('(choice choice_%08d bool (decision_id "balanced.%08d") '
            . '(distribution (uniform false true)) (constraints))', $_, $_)
    } 0 .. 31;

    my $transaction_fields = join(' ', map { "($_ #b0)" }
        @field_endpoints);
    my $random_property = '(and ' . join(' ', map {
        sprintf('(choice choice_%08d)', $_)
    } 0 .. 31) . ')';
    my @scenarios;
    for my $scenario_ordinal (0 .. 31) {
        my $child_count = $scenario_ordinal == 0 ? 31
            : $scenario_ordinal <= 3 ? 3 : 2;
        my @fibers = map {
            sprintf('(fiber fiber_%08d_%08d (reset balanced 1))',
                $scenario_ordinal, $_)
        } 0 .. $child_count - 1;
        my @root_resets = map { '(reset balanced 1)' } 0 .. 22;
        push @scenarios, join('',
            sprintf('(scenario scenario_%08d', $scenario_ordinal),
            ' (timeout (cycles balanced 4096))',
            ' (steps',
            sprintf('(expect random_%08d %s)',
                $scenario_ordinal, $random_property),
            '(parallel all ', join(' ', @fibers), ')',
            join(' ', @root_resets),
            sprintf('(scoreboard_expect scoreboard_%08d (fields %s))',
                $scenario_ordinal, $transaction_fields),
            sprintf('(inject fault_%08d)', $scenario_ordinal),
            sprintf('(start transaction_instance_%08d alias_00000000 '
                . '(fields %s))', $scenario_ordinal,
                $transaction_fields),
            sprintf('(scoreboard_check scoreboard_%08d)',
                $scenario_ordinal),
            '))',
        );
    }

    return join('',
        '(vial (version 1) (package architecture_scale_balanced_portable',
        ' (imports)',
        ' (types ', join(' ', @types), ')',
        ' (transactions ', join(' ', @transaction_types), ')',
        ' (models ', join(' ', @models), ')',
        ' (scoreboards ', $scoreboard_definition, ')',
        ' (fixtures (fixture balanced_gate',
        ' (dut dut',
        ' (unit "unit/vial_architecture_scale_balanced_portable")',
        ' (domains (domain balanced "domain/balanced"))',
        ' (endpoints ', join(' ', @endpoint_bindings), ' ',
            join(' ', @probe_bindings), ')',
        ' (transactions ', join(' ', @transaction_bindings), '))',
        ' (instances ', join(' ', @model_instances), ' ',
            join(' ', @scoreboard_instances), ')',
        ' (coverage ', join(' ', @coverpoints), ')',
        ' (faults ', join(' ', @faults), ')',
        ' (randomness (seed 1701) ', join(' ', @choices), ')',
        ' (scenarios ', join(' ', @scenarios), ')))))',
        "\n",
    );
}

sub _call_bridge($class, $arguments) {
    confess "balanced bridge call requires the exact composer invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__
            && caller eq __PACKAGE__;
    return FSM::HIAL::VIALBridge::Builder
        ->build_balanced_portable_qualification($arguments);
}

sub _call_execution($class, $arguments) {
    confess "balanced execution call requires the exact composer invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__
            && caller eq __PACKAGE__;
    return FSM::VIAL::ExecutionBuilder
        ->build_balanced_portable_qualification($arguments);
}

sub _backend_names($actor) {
    my @endpoints = ($actor->{clock}, $actor->{reset}{name});
    push @endpoints, map { $_->{name} }
        @{$actor->{interface}{inputs} || []};
    push @endpoints, map { $_->{name} }
        @{$actor->{interface}{outputs} || []};
    my @probes = map { $_->{name} }
        @{$actor->{verification_bridge}{probes} || []};
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

sub _input($relative_path, $role, $content) {
    return {
        relative_path => $relative_path,
        role => $role,
        encoding => 'utf-8',
        content => $content,
    };
}

sub _role_input($workload, $role) {
    my @found = grep { ($_->{role} // '') eq $role }
        @{$workload->{inputs} || []};
    confess "balanced-portable workload requires exactly one $role input\n"
        unless @found == 1;
    return $found[0];
}

sub _validate_reference($text, $bytes, $digest, $label) {
    confess "$label text is required\n"
        unless defined($text) && !ref($text);
    confess "$label byte length changed\n"
        unless bytes::length($text) == $bytes;
    confess "$label identity changed\n"
        unless sha256_hex($text) eq $digest;
}

sub _construction($value) {
    _confess_exact_keys($value, \@CONSTRUCTION_KEYS,
        'balanced-portable construction result');
    return _clone($value);
}

sub _confess_exact_keys($value, $keys, $label) {
    confess "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    confess "$label has unknown key(s): " . join(', ', @unknown) . "\n"
        if @unknown;
    confess "$label is missing key(s): " . join(', ', @missing) . "\n"
        if @missing;
}

sub _exact_invocant($class, $method) {
    confess "$method requires the exact " . __PACKAGE__ . " class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _canonical_json($value) {
    return JSON::PP->new->canonical(1)->allow_nonref(1)->encode($value);
}

sub _clone($value) {
    return JSON::PP->new->canonical(1)->allow_nonref(1)
        ->decode(JSON::PP->new->canonical(1)->allow_nonref(1)->encode($value));
}

1;
