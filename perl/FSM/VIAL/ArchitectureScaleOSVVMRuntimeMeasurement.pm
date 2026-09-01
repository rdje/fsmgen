package FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleMeasurement;
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeExecutionPlan;
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization;
use FSM::VIAL::Backend::GHDLLifecycle;
use FSM::VIAL::Backend::OSVVM2026_05Materialization;
use FSM::VIAL::Backend::VHDLPortableTraceValidator;

my $SCHEMA =
    'fsmgen.vial_architecture_scale_osvvm_runtime_measurement_set.v1';
my $FAMILY = 'runtime_stream_v1';
my $PROFILE = 'vhdl_osvvm_qualified';
my $PRIMARY_AXIS = 'runtime_trace_records';
my $MATERIALIZER =
    'FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization';
my $EXECUTION_PLAN =
    'FSM::VIAL::ArchitectureScaleOSVVMRuntimeExecutionPlan';
my $CONTROLLER = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $LIFECYCLE = 'FSM::VIAL::Backend::GHDLLifecycle';
my @LEVELS = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
);
my %LEVEL = map { $_ => 1 } @LEVELS;
my %LEVEL_MODE = (
    gate_candidate_v1 => 'gate_measurement',
    qualification_candidate_v1 => 'qualification_measurement',
);
my %MODE_SAMPLES = (
    gate_measurement => 3,
    qualification_measurement => 5,
);
my @PLANNED_STAGES = qw(
    construct parse_validate bridge bind_plan emit compile_analyze elaborate
    run trace_validate result_produce publish
);
my %EXTERNAL_STAGE = map { $_ => 1 } qw(
    compile_analyze elaborate run
);
my %BACKEND_TIMEOUT;
my %PREDECESSOR_STAGE = (
    compile_analyze => 'emit',
    elaborate => 'compile_analyze',
    run => 'elaborate',
    trace_validate => 'run',
    result_produce => 'trace_validate',
    publish => 'result_produce',
);
my @REPORT_KEYS = qw(
    schema schema_version report_identity family backend_profile level
    primary_axis workload_identity mode requested_counts materialization
    execution_plan tool_profile lifecycle_contract controller_applicability
    measurement_applicability validation_record measurement_records
    sample_exclusions outcome diagnostics cleanup explicit_nonclaims
);
my @APPLICABILITY_KEYS = qw(applicable reason);
my @LIFECYCLE_KEYS = qw(
    implementation schema_version state_order stage_mapping storage_mode
    containment version_timeout_seconds
    provider_analysis_timeout_seconds_per_source
    generated_analysis_timeout_seconds elaboration_timeout_seconds
    execution_timeout_seconds version_capture_bytes provider_capture_bytes
    fixture_capture_bytes
);
my @EXCLUSION_KEYS = qw(
    run_ordinal reason measurement_identity diagnostic
);
my @CLEANUP_KEYS = qw(records_total ephemeral_removed residue);
my @NONCLAIMS = (
    @{$CONTROLLER->explicit_nonclaims},
    qw(
        promoted_performance_budget backend_support architecture_capacity
        reached_record_boundary cross_backend_parity public_api_change
        provider_generality full_osvvm full_vhdl_2008 psl uvvm native_uvm
        mixed_language verification_component_transactions
    ),
);

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub owned_shapes($class) {
    _exact_invocant($class, 'owned_shapes');
    return [map {{backend_profile => $PROFILE, level => $_}} @LEVELS];
}

sub explicit_nonclaims($class) {
    _exact_invocant($class, 'explicit_nonclaims');
    return [@NONCLAIMS];
}

sub tool_profile($class) {
    _exact_invocant($class, 'tool_profile');
    return _tool_profile();
}

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    my $request = _request(
        'construct', \@args, [qw(repository_root level)],
    );
    my $repo_root = _repository_root($request->{repository_root});
    _selected_level($request->{level});
    return $MATERIALIZER->construct({
        repository_root => $repo_root, level => $request->{level},
    });
}

sub validate_profile($class, @args) {
    _exact_invocant($class, 'validate_profile');
    my $request = _request(
        'validate_profile', \@args, [qw(repository_root level)],
    );
    my $repo_root = _repository_root($request->{repository_root});
    my ($construction, $materialization, $plan) =
        _canonical_set($repo_root, $request->{level});
    if ($materialization->{status} eq 'preflight_dominated') {
        return _finalize_report({
            repository_root => $repo_root,
            construction => $construction,
            materialization => $materialization,
            execution_plan => undef,
            mode => 'preflight',
            validation_record => undef,
            measurement_records => [],
        });
    }
    _require_active_guard();
    my $validation = _run_record({
        repository_root => $repo_root,
        construction => $construction,
        materialization => $materialization,
        execution_plan => $plan,
        run_class => 'validation', run_ordinal => 0,
        validation_record => undef,
    });
    return _finalize_report({
        repository_root => $repo_root,
        construction => $construction,
        materialization => $materialization,
        execution_plan => $plan,
        mode => 'validation',
        validation_record => $validation,
        measurement_records => [],
    });
}

sub measure_profile($class, @args) {
    _exact_invocant($class, 'measure_profile');
    my $request = _request(
        'measure_profile', \@args, [qw(repository_root level)],
    );
    my $mode = $LEVEL_MODE{$request->{level}};
    confess "only the OSVVM gate and qualification candidates are measurable\n"
        unless defined $mode;
    _require_active_guard();
    my $repo_root = _repository_root($request->{repository_root});
    my ($construction, $materialization, $plan) =
        _canonical_set($repo_root, $request->{level});
    confess "preflight-dominated OSVVM shape reached measurement\n"
        unless $materialization->{status}
            eq 'provider_structurally_qualified';
    my $validation = _run_record({
        repository_root => $repo_root,
        construction => $construction,
        materialization => $materialization,
        execution_plan => $plan,
        run_class => 'validation', run_ordinal => 0,
        validation_record => undef,
    });
    my @measured;
    if ($validation->{outcome} eq 'accepted') {
        for my $ordinal (1 .. $MODE_SAMPLES{$mode}) {
            my $record = _run_record({
                repository_root => $repo_root,
                construction => $construction,
                materialization => $materialization,
                execution_plan => $plan,
                run_class => $mode, run_ordinal => $ordinal,
                validation_record => $validation,
            });
            push @measured, $record;
            last unless $record->{outcome} eq 'accepted';
        }
    }
    return _finalize_report({
        repository_root => $repo_root,
        construction => $construction,
        materialization => $materialization,
        execution_plan => $plan,
        mode => $mode,
        validation_record => $validation,
        measurement_records => \@measured,
    });
}

sub validate_report($class, @args) {
    _exact_invocant($class, 'validate_report');
    my $request = _request(
        'validate_report', \@args, [qw(repository_root report)],
    );
    my $repo_root = _repository_root($request->{repository_root});
    _validate_report($repo_root, $request->{report});
    return _clone($request->{report});
}

sub _run_record($raw) {
    return $CONTROLLER->measure({
        repository_root => $raw->{repository_root},
        construction => $raw->{construction},
        run_class => $raw->{run_class},
        run_ordinal => $raw->{run_ordinal},
        validation_record => $raw->{validation_record},
        stage_plan => _stage_plan($raw),
        tool_profile => _tool_profile(),
    });
}

sub _stage_plan($raw) {
    my $source_counts = _source_counts($raw->{construction});
    my @plan;
    for my $stage (@PLANNED_STAGES) {
        my $input_counts = $stage eq 'construct'
            ? {
                files => 0, lines => 1,
                bytes => bytes::length(_canonical_json(
                    $raw->{construction}{specification},
                )),
                objects => 1,
            }
            : _clone($source_counts);
        push @plan, {
            stage => $stage,
            classification => $EXTERNAL_STAGE{$stage}
                ? 'external_tool' : 'fsmgen_owned',
            command_identity => _command_identity(
                $stage, $raw->{construction}{specification}{level},
            ),
            input_counts => $input_counts,
            backend_timeout_seconds => undef,
            worker => sub ($context) {
                return _stage_worker({
                    %$raw, stage => $stage, context => $context,
                });
            },
        };
    }
    return \@plan;
}

sub _stage_worker($raw) {
    my $stage = $raw->{stage};
    my $context = $raw->{context};
    my $level = $raw->{construction}{specification}{level};
    if ($stage eq 'construct') {
        my $rebuilt = $MATERIALIZER->construct({
            repository_root => $raw->{repository_root}, level => $level,
        });
        confess "OSVVM runtime construction changed inside controller\n"
            unless _canonical_json($rebuilt)
                eq _canonical_json($raw->{construction});
        my $evidence = {
            workload_identity => $rebuilt->{workload_identity},
            specification => _clone($rebuilt->{specification}),
            inputs => [map {{
                relative_path => $_->{relative_path},
                role => $_->{role}, bytes => bytes::length($_->{content}),
                sha256 => sha256_hex($_->{content}),
            }} @{$rebuilt->{inputs}}],
        };
        return _materialize_payload($context, {
            status => 'osvvm_runtime_construct_completed',
            oracle_id => 'osvvm_runtime_construct_canonical',
            evidence => $evidence,
            semantic_counts => {
                constructed_inputs => scalar(@{$rebuilt->{inputs}}),
                construction_identity_records => 1,
            },
            artifacts => [{
                suffix => 'construction.json',
                kind => 'osvvm_runtime_construction',
                content => _canonical_json($evidence) . "\n",
            }],
        });
    }

    my $authority = _route_authority($raw);
    return _structural_stage($raw, $authority)
        if $stage =~ /\A(?:parse_validate|bridge|bind_plan)\z/;
    return _lifecycle_stage($raw, $authority);
}

sub _route_authority($raw) {
    my $level = $raw->{construction}{specification}{level};
    my $inputs = $MATERIALIZER->_measurement_route_inputs({
        repository_root => $raw->{repository_root}, level => $level,
    });
    confess "OSVVM controller construction authority changed\n"
        unless _canonical_json($inputs->{construction})
            eq _canonical_json($raw->{construction});
    my $route = $inputs->{first_route};
    my %projection = (
        semantic_ir => $route->{semantic_ir}->as_hashref,
        bridge_manifest => $route->{bridge_manifest}->as_hashref,
        execution_ir => $route->{execution_ir}->as_hashref,
        backend_inputs => _clone($route->{backend_inputs}),
        plan => _clone($route->{plan}),
    );
    my %identity = map {
        ($_ . '_sha256' => sha256_hex(_canonical_json($projection{$_})))
    } sort keys %projection;
    confess "OSVVM controller route authority changed\n"
        unless _canonical_json(\%identity)
            eq _canonical_json($raw->{materialization}{stage_identities});
    return {inputs => $inputs, projection => \%projection,
        identities => \%identity};
}

sub _structural_stage($raw, $authority) {
    my $stage = $raw->{stage};
    my $expected = $raw->{materialization};
    my $projection = $authority->{projection};
    my $identity = $authority->{identities};
    my ($evidence, $counts);
    if ($stage eq 'parse_validate') {
        $evidence = {
            workload_identity => $raw->{construction}{workload_identity},
            source_identity => _clone($expected->{source_identity}),
            semantic_ir_sha256 => $identity->{semantic_ir_sha256},
            status => 'accepted', diagnostics => [],
        };
        $counts = {
            semantic_ir_nodes => _json_node_count($projection->{semantic_ir}),
            parse_diagnostics => 0,
        };
    }
    elsif ($stage eq 'bridge') {
        $evidence = {
            workload_identity => $raw->{construction}{workload_identity},
            semantic_ir_sha256 => $identity->{semantic_ir_sha256},
            bridge_manifest_sha256 => $identity->{bridge_manifest_sha256},
            backend_inputs_sha256 => $identity->{backend_inputs_sha256},
            structural_equivalence =>
                _clone($expected->{structural_equivalence}),
            status => 'accepted', diagnostics => [],
        };
        $counts = {
            bridge_manifest_nodes =>
                _json_node_count($projection->{bridge_manifest}),
            backend_input_nodes =>
                _json_node_count($projection->{backend_inputs}),
            bridge_diagnostics => 0,
        };
    }
    else {
        $evidence = {
            workload_identity => $raw->{construction}{workload_identity},
            execution_ir_sha256 => $identity->{execution_ir_sha256},
            plan_sha256 => $identity->{plan_sha256},
            schedule_oracle => _clone($expected->{schedule_oracle}),
            status => 'accepted', diagnostics => [],
        };
        $counts = {
            execution_ir_nodes =>
                _json_node_count($projection->{execution_ir}),
            plan_nodes => _json_node_count($projection->{plan}),
            operations => 0 + $expected->{schedule_oracle}{operation_count},
            source_maps => 0 + $expected->{schedule_oracle}{source_map_count},
        };
    }
    return _materialize_payload($raw->{context}, {
        status => "osvvm_runtime_${stage}_accepted",
        oracle_id => "osvvm_runtime_${stage}_canonical",
        evidence => $evidence,
        semantic_counts => $counts,
        artifacts => [{
            suffix => "$stage-evidence.json",
            kind => "osvvm_runtime_${stage}_evidence",
            content => _canonical_json($evidence) . "\n",
        }],
    });
}

sub _lifecycle_stage($raw, $route_authority) {
    my $stage = $raw->{stage};
    my $context = $raw->{context};
    my ($request, $envelope, @source_records);
    my $result;
    if ($stage eq 'emit') {
        my $artifact_root =
            "$context->{staging_identity}/outputs/emit/source-graph";
        my $emitted = $MATERIALIZER->_measurement_inputs({
            repository_root => $raw->{repository_root},
            level => $raw->{construction}{specification}{level},
            artifact_root => $artifact_root,
        });
        confess "OSVVM measured emission construction changed\n"
            unless _canonical_json($emitted->{construction})
                eq _canonical_json($raw->{construction});
        my $measured_oracle = _clone($emitted->{emission_oracle});
        my $canonical_oracle =
            _clone($raw->{materialization}{emission_oracle});
        delete $measured_oracle->{artifact_root};
        delete $canonical_oracle->{artifact_root};
        # The graph digest covers every artifact byte, including the emitted
        # manifest's caller-selected repository-relative root.  All stable
        # graph fields and every generated-source identity remain exact; the
        # root-bound whole-graph digest is necessarily record-local.
        delete $measured_oracle->{artifact_graph_sha256};
        delete $canonical_oracle->{artifact_graph_sha256};
        confess "OSVVM measured emission oracle changed\n"
            unless _canonical_json($measured_oracle)
                eq _canonical_json($canonical_oracle);
        my ($records, $generated) = _materialize_generated_sources(
            $context, $emitted->{emission}, $raw->{execution_plan},
        );
        @source_records = @$records;
        my $instantiated = $EXECUTION_PLAN->_measurement_plan({
            level => $raw->{construction}{specification}{level},
            staging_identity => "$context->{staging_identity}/lifecycle",
            canonical_plan => $raw->{execution_plan},
            generated_source_set => $generated,
        });
        ($request, $envelope) = _lifecycle_request(
            $raw, $route_authority, $instantiated,
        );
        $result = $LIFECYCLE->begin_session($request);
        return _lifecycle_failure($stage, $result) unless $result->{ok};
        confess "OSVVM runtime lifecycle admission state changed\n"
            unless $result->{status} eq 'admitted';
    }
    else {
        $envelope = _read_request_envelope($context);
        $request = _validated_request_envelope(
            $raw, $route_authority, $envelope,
        );
        $request->{handle} = _read_predecessor_handle($context, $stage);
        if ($stage eq 'compile_analyze') {
            for my $target (qw(prepared tool_verified analyzed)) {
                $result = $LIFECYCLE->advance_session($request);
                return _lifecycle_failure($stage, $result)
                    unless $result->{ok};
                confess "OSVVM lifecycle analysis transition changed\n"
                    unless $result->{status} eq $target;
                $request->{handle} = $result->{handle};
            }
        }
        elsif ($stage eq 'publish') {
            my $assembled = $LIFECYCLE->advance_session($request);
            return _lifecycle_failure($stage, $assembled)
                unless $assembled->{ok};
            confess "OSVVM lifecycle assembly state changed\n"
                unless $assembled->{status} eq 'assembled';
            my $post_provider = _post_provider_authority(
                $raw->{execution_plan},
            );
            $request->{handle} = $assembled->{handle};
            my $finished = $LIFECYCLE->finish_session($request);
            return _lifecycle_failure($stage, $finished)
                unless $finished->{ok};
            confess "OSVVM runtime lifecycle cleanup state changed\n"
                unless $finished->{status} eq 'cleaned'
                    && $finished->{cleanup}{removed}
                    && ref($finished->{assembled_result}) eq 'HASH';
            return _publish_payload(
                $raw, $assembled, $finished, $envelope, $post_provider,
            );
        }
        else {
            my %target = (
                elaborate => 'elaborated', run => 'ran',
                trace_validate => 'trace_validated',
                result_produce => 'result_produced',
            );
            $result = $LIFECYCLE->advance_session($request);
            return _lifecycle_failure($stage, $result) unless $result->{ok};
            confess "OSVVM runtime lifecycle stage transition changed\n"
                unless $result->{status} eq $target{$stage};
        }
    }

    my $evidence = _lifecycle_evidence($stage, $result);
    if ($stage eq 'emit') {
        $evidence->{plan_identity} = $envelope->{plan_identity};
        $evidence->{materialization_identity} =
            $envelope->{materialization_identity};
        $evidence->{provider_verification} = _clone(
            $envelope->{provider_verification},
        );
        $evidence->{emission_oracle} =
            _clone($raw->{materialization}{emission_oracle});
    }
    my @artifacts = (
        {
            suffix => 'lifecycle-handle.json',
            kind => 'osvvm_runtime_lifecycle_handle',
            content => _canonical_json($result->{handle}) . "\n",
        },
        {
            suffix => 'lifecycle-evidence.json',
            kind => 'osvvm_runtime_lifecycle_evidence',
            content => _canonical_json($evidence) . "\n",
        },
    );
    push @artifacts, {
        suffix => 'lifecycle-request.json',
        kind => 'osvvm_runtime_lifecycle_request',
        content => _canonical_json($envelope) . "\n",
    } if $stage eq 'emit';
    my $payload = _materialize_payload($context, {
        status => "osvvm_runtime_${stage}_completed",
        oracle_id => "osvvm_runtime_${stage}_lifecycle_canonical",
        evidence => $evidence,
        semantic_counts => _lifecycle_semantic_counts($result),
        artifacts => \@artifacts,
    });
    return _merge_existing_records($payload, \@source_records);
}

sub _lifecycle_request($raw, $route_authority, $instantiated) {
    my $execution = $route_authority->{projection}{execution_ir};
    my $checked =
        FSM::VIAL::Backend::VHDLPortableTraceValidator
            ->checked_reference_authority;
    my @run_ids = map {
        "run/$execution->{plan_id}/$_->{scenario_id}"
    } @{$execution->{scenarios}};
    my $request_without_root = {
        provider => _clone($instantiated->{provider}),
        source_set => _clone($instantiated->{source_set}),
        source_identity => $instantiated->{source_identity},
        emission_identity => undef,
        commands => _clone($instantiated->{commands}),
        validation => {
            expected_record_counts => _clone(
                $raw->{materialization}{trace_projection}{record_families},
            ),
            expected_diagnostic_codes => [map {
                $_->{name} eq 'success'
                    ? 'VIAL_EXPECT_SUCCESS' : 'VIAL_EXPECT_ERROR'
            } @{$execution->{scenarios}}],
            expected_domain_id => $execution->{domains}[0]{domain_id},
            expected_fixture_id => $execution->{fixture}{fixture_id},
            expected_plan_id => $execution->{plan_id},
            expected_random_decisions_sha256 =>
                sha256_hex(_canonical_json(
                    $execution->{randomness}{decisions},
                )),
            expected_run_ids => \@run_ids,
            expected_observation_catalog =>
                $checked->{expected_observation_catalog},
            run_repetitions => 1,
        },
        storage_context => {
            schema => 'fsmgen.vial_ghdl_lifecycle_storage.v1',
            schema_version => 1,
            mode => 'osvvm_architecture_scale_measurement',
            staging_identity =>
                "$raw->{context}{staging_identity}/lifecycle",
            containment => 'outer_worker_process_group',
        },
    };
    $request_without_root->{emission_identity} =
        'emission/' . sha256_hex(_canonical_json({
            workload_identity => $raw->{construction}{workload_identity},
            materialization_identity =>
                $raw->{materialization}{report_identity},
            plan_identity => $instantiated->{plan_identity},
            source_identity => $instantiated->{source_identity},
            commands => $instantiated->{commands},
        }));
    my $provider_verification = {
        provider => $instantiated->{provider_authority}{provider},
        version => $instantiated->{provider_authority}{version},
        root_commit => $instantiated->{provider_authority}{root_commit},
        root_tree => $instantiated->{provider_authority}{root_tree},
        materialization_manifest_sha256 =>
            $instantiated->{provider_authority}
                {materialization_manifest_sha256},
        provider_source_identity =>
            $instantiated->{provider_authority}{provider_source_identity},
    };
    my $envelope = {
        schema => 'fsmgen.vial_osvvm_runtime_lifecycle_request.v1',
        schema_version => 1,
        materialization_identity =>
            $raw->{materialization}{report_identity},
        plan_identity => $instantiated->{plan_identity},
        provider_verification => $provider_verification,
        request => $request_without_root,
    };
    return ({
        repo_root => $raw->{repository_root}, %$request_without_root,
    }, $envelope);
}

sub _validated_request_envelope($raw, $route_authority, $envelope) {
    _exact_keys($envelope, [qw(
        schema schema_version materialization_identity plan_identity
        provider_verification request
    )], 'OSVVM runtime lifecycle request envelope');
    confess "OSVVM runtime lifecycle request envelope changed\n"
        unless _scalar_equals($envelope->{schema},
                'fsmgen.vial_osvvm_runtime_lifecycle_request.v1')
            && _json_integer_equals($envelope->{schema_version}, 1)
            && _scalar_equals(
                $envelope->{materialization_identity},
                $raw->{materialization}{report_identity},
            )
            && _scalar_equals(
                $envelope->{plan_identity},
                $raw->{execution_plan}{plan_identity},
            );
    confess "OSVVM runtime persisted provider verification changed\n"
        unless _canonical_json($envelope->{provider_verification})
            eq _canonical_json(_provider_projection(
                $raw->{execution_plan},
            ));
    my $request = $envelope->{request};
    _exact_keys($request, [qw(
        provider source_set source_identity emission_identity commands
        validation storage_context
    )], 'OSVVM runtime persisted lifecycle request');
    confess "OSVVM runtime persisted source identity changed\n"
        unless _scalar_equals(
            $request->{source_identity},
            'source/' . sha256_hex(_canonical_json($request->{source_set})),
        );
    confess "OSVVM runtime persisted lifecycle storage changed\n"
        unless _scalar_equals(
                $request->{storage_context}{staging_identity},
                "$raw->{context}{staging_identity}/lifecycle",
            )
            && _scalar_equals(
                $request->{storage_context}{mode},
                'osvvm_architecture_scale_measurement',
            )
            && _scalar_equals(
                $request->{storage_context}{containment},
                'outer_worker_process_group',
            );
    my $execution = $route_authority->{projection}{execution_ir};
    confess "OSVVM runtime persisted validation plan changed\n"
        unless _scalar_equals(
                $request->{validation}{expected_plan_id},
                $execution->{plan_id},
            )
            && _json_integer_equals(
                $request->{validation}{run_repetitions}, 1,
            );
    return {repo_root => $raw->{repository_root}, %$request};
}

sub _scalar_equals($actual, $expected) {
    return defined($actual) && !ref($actual) && $actual eq $expected;
}

sub _json_integer_equals($actual, $expected) {
    return defined($actual) && !ref($actual)
        && _canonical_json($actual) eq "$expected";
}

sub _read_request_envelope($context) {
    my $path = File::Spec->catfile(
        $context->{staging_root}, 'outputs', 'emit',
        'lifecycle-request.json',
    );
    return _read_json_file($path,
        'OSVVM runtime lifecycle request is absent or malformed');
}

sub _read_predecessor_handle($context, $stage) {
    my $predecessor = $PREDECESSOR_STAGE{$stage};
    confess "OSVVM runtime lifecycle predecessor stage is unknown\n"
        unless defined $predecessor;
    my $path = File::Spec->catfile(
        $context->{staging_root}, 'outputs', $predecessor,
        'lifecycle-handle.json',
    );
    return _read_json_file($path,
        'OSVVM runtime lifecycle predecessor handle is absent or malformed');
}

sub _read_json_file($path, $message) {
    open my $fh, '<:raw', $path or confess "$message\n";
    local $/;
    my $content = <$fh>;
    close $fh or confess "$message\n";
    my $value = eval { JSON::PP->new->decode($content) };
    confess "$message\n"
        unless defined($value) && !$@ && ref($value) eq 'HASH'
            && !blessed($value)
            && $content eq _canonical_json($value) . "\n";
    return $value;
}

sub _publish_payload(
    $raw, $assembled_state, $finished, $envelope, $post_provider,
) {
    my $assembled = $finished->{assembled_result};
    confess "OSVVM assembled runtime output cardinality changed\n"
        unless ref($assembled->{fixture_runtime_outputs}) eq 'ARRAY'
            && @{$assembled->{fixture_runtime_outputs}} == 1
            && ref($assembled->{provider_runtime_outputs}) eq 'ARRAY'
            && @{$assembled->{provider_runtime_outputs}} == 1
            && ref($assembled->{provider_reports}) eq 'ARRAY'
            && @{$assembled->{provider_reports}} == 1
            && ref($assembled->{provider_reports}[0]) eq 'ARRAY'
            && @{$assembled->{provider_reports}[0]} == 4
            && ref($assembled->{trace_validation}) eq 'HASH'
            && ref($assembled->{normalized_result}) eq 'HASH';
    my $trace = _state_evidence($assembled_state, 'trace_validated');
    my $result = _state_evidence($assembled_state, 'result_produced');
    my $tool = _state_evidence($assembled_state, 'tool_verified');
    my $analysis = _state_evidence($assembled_state, 'analyzed');
    my $elaboration = _state_evidence($assembled_state, 'elaborated');
    my $run = _state_evidence($assembled_state, 'ran');
    confess "OSVVM validated trace record count changed\n"
        unless $trace->{record_count}
            == $raw->{materialization}{trace_projection}{record_count};
    confess "OSVVM provider compiler byte evidence is absent\n"
        unless defined($assembled->{provider_compiler_output_bytes})
            && !ref($assembled->{provider_compiler_output_bytes})
            && $assembled->{provider_compiler_output_bytes} =~ /\A[0-9]+\z/;
    my $request = $envelope->{request};
    my %command_identity = map {
        ($_ => sha256_hex(_canonical_json($request->{commands}{$_})))
    } qw(
        version provider_analyze analyze_generated elaborate_fixture
        elaborate_provider_probe run_fixture run_provider_probe
    );
    my $transcript_identity = {
        version => $tool->{version_sha256},
        provider_analysis => _clone($analysis->{output_sha256}),
        generated_analysis => $analysis->{generated_output_sha256},
        elaboration => _clone($elaboration->{output_sha256}),
        fixture_run => $run->{fixture_output_sha256}[0],
        provider_run => $run->{provider_output_sha256}[0],
        provider_report_set => $run->{provider_report_sha256}[0],
    };
    my $artifact_identity = {
        materialization_identity => $envelope->{materialization_identity},
        plan_identity => $envelope->{plan_identity},
        source_identity => $request->{source_identity},
        emission_identity => $request->{emission_identity},
        emission_artifact_count =>
            0 + $raw->{materialization}{emission_oracle}{artifact_count},
        emission_source_bytes =>
            0 + $raw->{materialization}{emission_oracle}{source_bytes},
        emission_artifact_graph_sha256 =>
            $raw->{materialization}{emission_oracle}
                {artifact_graph_sha256},
        source_set_sha256 =>
            sha256_hex(_canonical_json($request->{source_set})),
        generated_settings_sha256 =>
            $assembled->{generated_settings_sha256},
        provider_compiler_output_bytes =>
            0 + $assembled->{provider_compiler_output_bytes},
    };
    my @report_identity = map {{
        name => $_->{name}, relpath => $_->{relpath},
        bytes => 0 + $_->{bytes}, sha256 => $_->{sha256},
    }} @{$assembled->{provider_reports}[0]};
    my $evidence = {
        lifecycle_identity => $assembled_state->{lifecycle_identity},
        terminal_state => $finished->{status},
        state_order => [map { $_->{state} }
            @{$assembled_state->{stage_evidence}}],
        stage_evidence => _clone($assembled_state->{stage_evidence}),
        provider_before_execution =>
            _clone($envelope->{provider_verification}),
        provider_after_execution => _clone($post_provider),
        artifact_identity => $artifact_identity,
        source_set => _clone($request->{source_set}),
        commands => _clone($request->{commands}),
        command_identities => \%command_identity,
        transcript_identities => $transcript_identity,
        provider_report_identities => \@report_identity,
        trace_sha256 => $trace->{trace_sha256},
        trace_record_count => 0 + $trace->{record_count},
        trace_validation_sha256 =>
            sha256_hex(_canonical_json($assembled->{trace_validation})),
        trace_validation => _clone($assembled->{trace_validation}),
        result_sha256 => $result->{result_sha256},
        result_status => $result->{result_status},
        normalized_result_sha256 =>
            sha256_hex(_canonical_json($assembled->{normalized_result})),
        normalized_result => _clone($assembled->{normalized_result}),
        cleanup => _clone($finished->{cleanup}),
    };
    my @summary_artifacts = (
        ['lifecycle-evidence.json', 'osvvm_runtime_lifecycle_evidence',
            $evidence],
        ['artifact-identities.json', 'osvvm_runtime_artifact_identities',
            $artifact_identity],
        ['command-authority.json', 'osvvm_runtime_command_authority',
            $request->{commands}],
        ['transcript-identities.json',
            'osvvm_runtime_transcript_identities', $transcript_identity],
        ['provider-authority.json', 'osvvm_runtime_provider_authority', {
            before_execution => $envelope->{provider_verification},
            after_execution => $post_provider,
        }],
        ['provider-report-identities.json',
            'osvvm_runtime_provider_report_identities', \@report_identity],
        ['trace-validation.json', 'osvvm_runtime_trace_validation',
            $assembled->{trace_validation}],
        ['normalized-result.json', 'osvvm_runtime_normalized_result',
            $assembled->{normalized_result}],
    );
    my @report_artifacts = map {{
        suffix => "provider-reports/" . _safe_relative_path($_->{name}),
        kind => 'osvvm_runtime_provider_report',
        content => $_->{content},
    }} @{$assembled->{provider_reports}[0]};
    return _materialize_payload($raw->{context}, {
        status => 'osvvm_runtime_publish_completed',
        oracle_id => 'osvvm_runtime_publish_lifecycle_canonical',
        evidence => $evidence,
        semantic_counts => {
            lifecycle_states =>
                scalar(@{$assembled_state->{stage_evidence}}),
            artifact_graph_files =>
                0 + $artifact_identity->{emission_artifact_count},
            provider_analysis_commands =>
                scalar(@{$request->{commands}{provider_analyze}}),
            fixture_runtime_outputs => 1,
            provider_runtime_outputs => 1,
            provider_reports => scalar(@report_identity),
            trace_records => 0 + $trace->{record_count},
            result_manifests => 1,
        },
        artifacts => [
            (map {{
                suffix => $_->[0], kind => $_->[1],
                content => _canonical_json($_->[2]) . "\n",
            }} @summary_artifacts),
            @report_artifacts,
        ],
    });
}

sub _post_provider_authority($canonical_plan) {
    my $expected = $canonical_plan->{provider_authority};
    my $verified =
        FSM::VIAL::Backend::OSVVM2026_05Materialization->verify({
            dependency_root => $expected->{dependency_root},
        });
    confess "OSVVM post-execution provider verification failed\n"
        unless $verified->{ok}
            && $verified->{status} eq 'complete_recursive_verified'
            && ref($verified->{manifest}) eq 'HASH';
    my $manifest = $verified->{manifest};
    my $authority = {
        provider => $manifest->{provider},
        version => $manifest->{version},
        root_commit => $manifest->{root_commit},
        root_tree => $manifest->{root_tree},
        materialization_manifest_sha256 =>
            sha256_hex(_canonical_json($manifest)),
        repository_count =>
            0 + $manifest->{materialization}{repository_count},
        gitlink_count => 0 + $manifest->{materialization}{gitlink_count},
        license_file_count =>
            0 + $manifest->{license_notice_summary}{license_file_count},
        notice_file_count =>
            0 + $manifest->{license_notice_summary}{notice_file_count},
    };
    confess "OSVVM provider authority changed across execution\n"
        unless $authority->{provider} eq $expected->{provider}
            && $authority->{version} eq $expected->{version}
            && $authority->{root_commit} eq $expected->{root_commit}
            && $authority->{root_tree} eq $expected->{root_tree}
            && $authority->{materialization_manifest_sha256}
                eq $expected->{materialization_manifest_sha256};
    return $authority;
}

sub _materialize_generated_sources($context, $emission, $canonical_plan) {
    my %by_path = map { $_->{relpath} => $_ } @{$emission->{artifacts}};
    my @records;
    my @source;
    for my $expected (
        @{$canonical_plan->{source_authority}{generated_sources}}
    ) {
        my $source_artifact =
            _safe_relative_path($expected->{source_artifact_relpath});
        my $artifact = $by_path{$source_artifact};
        confess "OSVVM emitted lifecycle source is absent\n"
            unless defined($artifact)
                && bytes::length($artifact->{content}) == $expected->{bytes}
                && sha256_hex($artifact->{content}) eq $expected->{sha256};
        my @parts = split m{/}, $source_artifact;
        my $path = File::Spec->catfile(
            $context->{output_root}, 'source-graph', @parts,
        );
        my @parent = @parts;
        pop @parent;
        make_path(File::Spec->catdir(
            $context->{output_root}, 'source-graph', @parent,
        ));
        open my $fh, '>:raw', $path
            or die "cannot create OSVVM runtime lifecycle source: $!\n";
        print {$fh} $artifact->{content};
        close $fh
            or die "cannot close OSVVM runtime lifecycle source: $!\n";
        my $relpath =
            "$context->{staging_identity}/outputs/emit/source-graph/"
            . $source_artifact;
        push @source, {
            relpath => $relpath,
            bytes => 0 + $expected->{bytes},
            sha256 => $expected->{sha256},
        };
        push @records, {
            relative_path =>
                "$context->{output_identity}/source-graph/$source_artifact",
            kind => 'osvvm_runtime_lifecycle_source',
            bytes => bytes::length($artifact->{content}),
            lines => _line_count($artifact->{content}),
            sha256 => sha256_hex($artifact->{content}),
        };
    }
    confess "OSVVM runtime generated source cardinality changed\n"
        unless @source == 7 && @records == 7;
    return (\@records, \@source);
}

sub _merge_existing_records($payload, $extra) {
    return $payload unless @$extra;
    push @{$payload->{artifacts}}, @$extra;
    @{$payload->{artifacts}} = sort {
        $a->{relative_path} cmp $b->{relative_path}
    } @{$payload->{artifacts}};
    my $counts = _zero_counts();
    $counts->{files} = scalar(@{$payload->{artifacts}});
    $counts->{objects} = $counts->{files};
    for my $artifact (@{$payload->{artifacts}}) {
        $counts->{lines} += $artifact->{lines};
        $counts->{bytes} += $artifact->{bytes};
    }
    $payload->{output_counts} = $counts;
    return $payload;
}

sub _lifecycle_evidence($stage, $result) {
    return {
        lifecycle_identity => $result->{lifecycle_identity},
        measurement_stage => $stage,
        lifecycle_state => $result->{status},
        handle => _clone($result->{handle}),
        stage_evidence => _clone($result->{stage_evidence}),
        cleanup => _clone($result->{cleanup}),
    };
}

sub _lifecycle_semantic_counts($result) {
    return {
        lifecycle_states => scalar(@{$result->{stage_evidence}}),
        lifecycle_evidence_records =>
            scalar(@{$result->{stage_evidence}}),
    };
}

sub _state_evidence($result, $state) {
    my @match = grep { ($_->{state} // '') eq $state }
        @{$result->{stage_evidence}};
    confess "OSVVM runtime lifecycle state evidence is not unique\n"
        unless @match == 1;
    return $match[0]{evidence};
}

sub _lifecycle_failure($stage, $result) {
    my $diagnostic = ref($result) eq 'HASH'
            && ref($result->{diagnostics}) eq 'ARRAY'
            && @{$result->{diagnostics}}
        ? $result->{diagnostics}[0] : {};
    my @notes;
    if (ref($result) eq 'HASH') {
        push @notes,
            'lifecycle-identity:' .
                ($result->{lifecycle_identity} // 'none'),
            'stage-evidence-json:' . _canonical_json(
                $result->{stage_evidence} // [],
            ),
            'cleanup-json:' . _canonical_json($result->{cleanup} // {});
    }
    return {
        ok => JSON::PP::false,
        status => "osvvm_runtime_${stage}_rejected",
        output_counts => _zero_counts(),
        semantic_object_counts => {},
        correctness_oracles => [],
        artifacts => [],
        diagnostic => _diagnostic(
            $diagnostic->{code} // 'VIAL_OSVVM_RUNTIME_MEASUREMENT_ERROR',
            $diagnostic->{message} //
                'shared provider-aware lifecycle rejected the stage',
            "/stage_measurements/$stage",
            \@notes,
        ),
    };
}

sub _materialize_payload($context, $payload) {
    my @records;
    make_path($context->{output_root});
    for my $artifact (@{$payload->{artifacts}}) {
        my $suffix = _safe_relative_path($artifact->{suffix});
        my @parts = split m{/}, $suffix;
        my $path = File::Spec->catfile($context->{output_root}, @parts);
        my @parent = @parts;
        pop @parent;
        make_path(File::Spec->catdir($context->{output_root}, @parent))
            if @parent;
        open my $fh, '>:raw', $path
            or die "cannot create OSVVM runtime measurement artifact: $!\n";
        print {$fh} $artifact->{content};
        close $fh
            or die "cannot close OSVVM runtime measurement artifact: $!\n";
        push @records, {
            relative_path => "$context->{output_identity}/$suffix",
            kind => _safe_token($artifact->{kind}),
            bytes => bytes::length($artifact->{content}),
            lines => _line_count($artifact->{content}),
            sha256 => sha256_hex($artifact->{content}),
        };
    }
    @records = sort {
        $a->{relative_path} cmp $b->{relative_path}
    } @records;
    my $counts = _zero_counts();
    $counts->{files} = scalar(@records);
    $counts->{objects} = scalar(@records);
    for my $record (@records) {
        $counts->{lines} += $record->{lines};
        $counts->{bytes} += $record->{bytes};
    }
    return {
        ok => JSON::PP::true,
        status => $payload->{status},
        output_counts => $counts,
        semantic_object_counts => _clone($payload->{semantic_counts}),
        correctness_oracles => [{
            oracle_id => $payload->{oracle_id},
            ok => JSON::PP::true,
            evidence => _clone($payload->{evidence}),
        }],
        artifacts => \@records,
        diagnostic => undef,
    };
}

sub _finalize_report($raw) {
    my $construction = $raw->{construction};
    my $materialization = $raw->{materialization};
    my $validation = $raw->{validation_record};
    my @measured = @{$raw->{measurement_records}};
    my $preflight = $raw->{mode} eq 'preflight';
    my $controller = $preflight
        ? {applicable => JSON::PP::false, reason => 'preflight_dominated'}
        : {applicable => JSON::PP::true, reason => undef};
    my $measurement = $preflight
        ? {applicable => JSON::PP::false, reason => 'preflight_dominated'}
        : $raw->{mode} eq 'validation'
            ? {applicable => JSON::PP::false,
                reason => 'correctness_only_requested'}
            : $validation->{outcome} ne 'accepted'
                ? {applicable => JSON::PP::false,
                    reason => 'correctness_validation_failed'}
                : {applicable => JSON::PP::true, reason => undef};
    my @exclusions = map {{
        run_ordinal => $_->{run_ordinal},
        reason => $_->{outcome},
        measurement_identity => $_->{measurement_identity},
        diagnostic => _clone($_->{diagnostic}),
    }} grep { $_->{outcome} ne 'accepted' } @measured;
    my @records = $preflight ? () : ($validation, @measured);
    my @residue = map { @{$_->{cleanup}{residue}} }
        grep { ref($_->{cleanup}{residue}) eq 'ARRAY' } @records;
    my $removed = !grep { !$_->{cleanup}{ephemeral_removed} } @records;
    my ($outcome, @diagnostics);
    if ($preflight) {
        $outcome = 'preflight_dominated';
    }
    elsif ($validation->{outcome} ne 'accepted') {
        $outcome = 'rejected';
        push @diagnostics, _clone($validation->{diagnostic});
    }
    elsif ($raw->{mode} eq 'validation') {
        $outcome = 'accepted_validation';
    }
    elsif (@exclusions || @measured != $MODE_SAMPLES{$raw->{mode}}) {
        $outcome = 'rejected';
        push @diagnostics, _clone($exclusions[0]{diagnostic})
            if @exclusions;
    }
    else {
        $outcome = 'accepted';
    }
    my $report = {
        schema => $SCHEMA,
        schema_version => 1,
        report_identity => undef,
        family => $FAMILY,
        backend_profile => $PROFILE,
        level => $construction->{specification}{level},
        primary_axis => $PRIMARY_AXIS,
        workload_identity => $construction->{workload_identity},
        mode => $raw->{mode},
        requested_counts => _clone($materialization->{requested_counts}),
        materialization => _clone($materialization),
        execution_plan => _clone($raw->{execution_plan}),
        tool_profile => _tool_profile(),
        lifecycle_contract => _lifecycle_contract(),
        controller_applicability => $controller,
        measurement_applicability => $measurement,
        validation_record => _clone($validation),
        measurement_records => _clone(\@measured),
        sample_exclusions => \@exclusions,
        outcome => $outcome,
        diagnostics => \@diagnostics,
        cleanup => {
            records_total => scalar(@records),
            ephemeral_removed => $removed
                ? JSON::PP::true : JSON::PP::false,
            residue => \@residue,
        },
        explicit_nonclaims => [@NONCLAIMS],
    };
    $report->{report_identity} = _report_identity($report);
    _validate_report($raw->{repository_root}, $report);
    return _clone($report);
}

sub _validate_report($repo_root, $report) {
    confess "OSVVM runtime measurement report must be one unblessed hash\n"
        unless ref($report) eq 'HASH' && !blessed($report);
    _exact_keys($report, \@REPORT_KEYS,
        'OSVVM runtime measurement report');
    confess "OSVVM runtime measurement report header is invalid\n"
        unless ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // -1) == 1
            && ($report->{family} // '') eq $FAMILY
            && ($report->{backend_profile} // '') eq $PROFILE
            && ($report->{primary_axis} // '') eq $PRIMARY_AXIS;
    my ($construction, $materialization, $plan) =
        _canonical_set($repo_root, $report->{level});
    confess "OSVVM runtime measurement workload identity changed\n"
        unless ($report->{workload_identity} // '')
            eq $construction->{workload_identity};
    confess "OSVVM runtime materialization evidence changed\n"
        unless _canonical_json($report->{materialization})
                eq _canonical_json($materialization)
            && _canonical_json($report->{requested_counts})
                eq _canonical_json($materialization->{requested_counts});
    confess "OSVVM runtime execution-plan evidence changed\n"
        unless _canonical_json($report->{execution_plan})
            eq _canonical_json($plan);
    confess "OSVVM runtime tool profile changed\n"
        unless _canonical_json($report->{tool_profile})
            eq _canonical_json(_tool_profile());
    _exact_keys($report->{lifecycle_contract}, \@LIFECYCLE_KEYS,
        'OSVVM runtime lifecycle contract');
    confess "OSVVM runtime lifecycle contract changed\n"
        unless _canonical_json($report->{lifecycle_contract})
            eq _canonical_json(_lifecycle_contract());
    _validate_applicability(
        $report->{controller_applicability}, 'controller applicability');
    _validate_applicability(
        $report->{measurement_applicability},
        'measurement applicability');
    confess "OSVVM runtime measurement records must be one array\n"
        unless ref($report->{measurement_records}) eq 'ARRAY';
    confess "OSVVM runtime sample exclusions must be one array\n"
        unless ref($report->{sample_exclusions}) eq 'ARRAY';
    confess "OSVVM runtime diagnostics must be one array\n"
        unless ref($report->{diagnostics}) eq 'ARRAY';
    my $preflight =
        $materialization->{status} eq 'preflight_dominated';
    my $mode = $report->{mode};
    confess "OSVVM runtime report mode is invalid\n"
        unless $mode eq 'validation' || $mode eq 'preflight'
            || exists $MODE_SAMPLES{$mode};
    confess "OSVVM runtime preflight mode changed\n"
        if $preflight != ($mode eq 'preflight');
    my $validation = $report->{validation_record};
    my @measured = @{$report->{measurement_records}};
    if ($preflight) {
        confess "preflight-dominated OSVVM report executed a controller\n"
            if defined($validation) || @measured || defined($plan);
    }
    else {
        confess "OSVVM runtime report has no validation record\n"
            unless ref($validation) eq 'HASH' && !blessed($validation);
        $CONTROLLER->validate_record({record => $validation});
        $CONTROLLER->validate_record({record => $_}) for @measured;
        confess "OSVVM runtime validation ordinal changed\n"
            unless $validation->{run_class} eq 'validation'
                && $validation->{run_ordinal} == 0;
        _validate_record_evidence(
            $_, $construction, $materialization, $plan,
        ) for ($validation, @measured);
        if ($mode eq 'validation') {
            confess "validation-only OSVVM report retained samples\n"
                if @measured;
        }
        else {
            confess "OSVVM measurement mode does not match selected level\n"
                unless ($LEVEL_MODE{$report->{level}} // '') eq $mode;
            for my $index (0 .. $#measured) {
                confess "OSVVM runtime sample ordinal or class changed\n"
                    unless $measured[$index]{run_class} eq $mode
                        && $measured[$index]{run_ordinal} == $index + 1;
            }
        }
    }
    my $expected_controller = $preflight
        ? {applicable => JSON::PP::false, reason => 'preflight_dominated'}
        : {applicable => JSON::PP::true, reason => undef};
    my $expected_measurement = $preflight
        ? {applicable => JSON::PP::false, reason => 'preflight_dominated'}
        : $mode eq 'validation'
            ? {applicable => JSON::PP::false,
                reason => 'correctness_only_requested'}
            : $validation->{outcome} ne 'accepted'
                ? {applicable => JSON::PP::false,
                    reason => 'correctness_validation_failed'}
                : {applicable => JSON::PP::true, reason => undef};
    confess "OSVVM runtime controller applicability changed\n"
        unless _canonical_json($report->{controller_applicability})
            eq _canonical_json($expected_controller);
    confess "OSVVM runtime measurement applicability changed\n"
        unless _canonical_json($report->{measurement_applicability})
            eq _canonical_json($expected_measurement);
    my @expected_exclusions = map {{
        run_ordinal => $_->{run_ordinal},
        reason => $_->{outcome},
        measurement_identity => $_->{measurement_identity},
        diagnostic => _clone($_->{diagnostic}),
    }} grep { $_->{outcome} ne 'accepted' } @measured;
    _exact_keys($_, \@EXCLUSION_KEYS,
        'OSVVM runtime sample exclusion')
        for @{$report->{sample_exclusions}};
    confess "OSVVM runtime sample exclusion evidence changed\n"
        unless _canonical_json($report->{sample_exclusions})
            eq _canonical_json(\@expected_exclusions);
    _exact_keys($report->{cleanup}, \@CLEANUP_KEYS,
        'OSVVM runtime cleanup');
    my @records = $preflight ? () : ($validation, @measured);
    my @residue = map { @{$_->{cleanup}{residue}} }
        grep { ref($_->{cleanup}{residue}) eq 'ARRAY' } @records;
    my $removed = !grep { !$_->{cleanup}{ephemeral_removed} } @records;
    my $expected_cleanup = {
        records_total => scalar(@records),
        ephemeral_removed => $removed
            ? JSON::PP::true : JSON::PP::false,
        residue => \@residue,
    };
    confess "OSVVM runtime cleanup evidence changed\n"
        unless _canonical_json($report->{cleanup})
            eq _canonical_json($expected_cleanup);
    confess "OSVVM runtime nonclaim boundary changed\n"
        unless _canonical_json($report->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    my ($expected_outcome, @expected_diagnostics);
    if ($preflight) {
        $expected_outcome = 'preflight_dominated';
    }
    elsif ($validation->{outcome} ne 'accepted') {
        $expected_outcome = 'rejected';
        push @expected_diagnostics, _clone($validation->{diagnostic});
    }
    elsif ($mode eq 'validation') {
        $expected_outcome = 'accepted_validation';
    }
    elsif (@expected_exclusions || @measured != $MODE_SAMPLES{$mode}) {
        $expected_outcome = 'rejected';
        push @expected_diagnostics,
            _clone($expected_exclusions[0]{diagnostic})
            if @expected_exclusions;
    }
    else {
        $expected_outcome = 'accepted';
    }
    confess "OSVVM runtime report outcome changed\n"
        unless ($report->{outcome} // '') eq $expected_outcome;
    confess "OSVVM runtime report diagnostics changed\n"
        unless _canonical_json($report->{diagnostics})
            eq _canonical_json(\@expected_diagnostics);
    confess "OSVVM runtime report identity changed\n"
        unless ($report->{report_identity} // '')
            eq _report_identity($report);
    return;
}

sub _validate_record_evidence(
    $record, $construction, $materialization, $plan,
) {
    confess "OSVVM runtime record workload changed\n"
        unless $record->{workload_identity}
                eq $construction->{workload_identity}
            && _canonical_json($record->{workload_specification})
                eq _canonical_json($construction->{specification})
            && _canonical_json($record->{tool_profile})
                eq _canonical_json(_tool_profile());
    my %stage = map { $_->{stage} => $_ } @{$record->{stage_measurements}};
    my $source_counts = _source_counts($construction);
    for my $name (@PLANNED_STAGES) {
        my $entry = $stage{$name};
        confess "OSVVM runtime record is missing stage '$name'\n"
            unless defined $entry;
        next if $entry->{status} =~ /rejected\z/
            || $entry->{status} eq 'not_run';
        my $expected_class = $EXTERNAL_STAGE{$name}
            ? 'external_tool' : 'fsmgen_owned';
        confess "OSVVM runtime stage classification changed\n"
            unless $entry->{classification} eq $expected_class;
        confess "OSVVM runtime stage command identity changed\n"
            unless _canonical_json($entry->{command_identity})
                eq _canonical_json(_command_identity(
                    $name, $construction->{specification}{level},
                ));
        my $expected_input = $name eq 'construct'
            ? {
                files => 0, lines => 1,
                bytes => bytes::length(_canonical_json(
                    $construction->{specification},
                )),
                objects => 1,
            }
            : $source_counts;
        confess "OSVVM runtime stage input counts changed\n"
            unless _canonical_json($entry->{input_counts})
                eq _canonical_json($expected_input);
        confess "OSVVM runtime backend timeout authority changed\n"
            unless _canonical_json($entry->{timeout}{backend_seconds})
                eq _canonical_json($BACKEND_TIMEOUT{$name});
    }
    return unless $record->{outcome} eq 'accepted';

    my %oracle = map { $_->{oracle_id} => $_ }
        @{$record->{correctness_oracles}};
    for my $name (@PLANNED_STAGES) {
        my $id = $name =~
                /\A(?:construct|parse_validate|bridge|bind_plan)\z/
            ? "osvvm_runtime_${name}_canonical"
            : "osvvm_runtime_${name}_lifecycle_canonical";
        confess "OSVVM runtime stage oracle '$id' is absent\n"
            unless $oracle{$id} && $oracle{$id}{ok}
                && $oracle{$id}{stage} eq $name;
    }
    my $construct_evidence = {
        workload_identity => $construction->{workload_identity},
        specification => _clone($construction->{specification}),
        inputs => [map {{
            relative_path => $_->{relative_path},
            role => $_->{role},
            bytes => bytes::length($_->{content}),
            sha256 => sha256_hex($_->{content}),
        }} @{$construction->{inputs}}],
    };
    confess "OSVVM runtime construction oracle evidence changed\n"
        unless _canonical_json(
            $oracle{osvvm_runtime_construct_canonical}{evidence},
        ) eq _canonical_json($construct_evidence);
    my $stage_identity = $materialization->{stage_identities};
    my $parse_evidence = {
        workload_identity => $construction->{workload_identity},
        source_identity => _clone($materialization->{source_identity}),
        semantic_ir_sha256 => $stage_identity->{semantic_ir_sha256},
        status => 'accepted', diagnostics => [],
    };
    confess "OSVVM runtime parse oracle evidence changed\n"
        unless _canonical_json(
            $oracle{osvvm_runtime_parse_validate_canonical}{evidence},
        ) eq _canonical_json($parse_evidence);
    my $bridge_evidence = {
        workload_identity => $construction->{workload_identity},
        semantic_ir_sha256 => $stage_identity->{semantic_ir_sha256},
        bridge_manifest_sha256 =>
            $stage_identity->{bridge_manifest_sha256},
        backend_inputs_sha256 =>
            $stage_identity->{backend_inputs_sha256},
        structural_equivalence =>
            _clone($materialization->{structural_equivalence}),
        status => 'accepted', diagnostics => [],
    };
    confess "OSVVM runtime bridge oracle evidence changed\n"
        unless _canonical_json(
            $oracle{osvvm_runtime_bridge_canonical}{evidence},
        ) eq _canonical_json($bridge_evidence);
    my $bind_evidence = {
        workload_identity => $construction->{workload_identity},
        execution_ir_sha256 => $stage_identity->{execution_ir_sha256},
        plan_sha256 => $stage_identity->{plan_sha256},
        schedule_oracle => _clone($materialization->{schedule_oracle}),
        status => 'accepted', diagnostics => [],
    };
    confess "OSVVM runtime bind-plan oracle evidence changed\n"
        unless _canonical_json(
            $oracle{osvvm_runtime_bind_plan_canonical}{evidence},
        ) eq _canonical_json($bind_evidence);

    my @lifecycle_stage = qw(
        emit compile_analyze elaborate run trace_validate result_produce
    );
    my %terminal = (
        emit => 'admitted', compile_analyze => 'analyzed',
        elaborate => 'elaborated', run => 'ran',
        trace_validate => 'trace_validated',
        result_produce => 'result_produced',
    );
    my @state_order = qw(
        admitted prepared tool_verified analyzed elaborated ran
        trace_validated result_produced assembled
    );
    my $lifecycle_identity;
    for my $name (@lifecycle_stage) {
        my $evidence =
            $oracle{"osvvm_runtime_${name}_lifecycle_canonical"}
                {evidence};
        my $last = 0;
        $last++ until $state_order[$last] eq $terminal{$name};
        confess "OSVVM lifecycle stage evidence changed\n"
            unless ($evidence->{measurement_stage} // '') eq $name
                && ($evidence->{lifecycle_state} // '')
                    eq $terminal{$name}
                && ($evidence->{handle}{state} // '')
                    eq $terminal{$name}
                && _canonical_json([map { $_->{state} }
                        @{$evidence->{stage_evidence}}])
                    eq _canonical_json([@state_order[0 .. $last]])
                && !$evidence->{cleanup}{removed}
                && @{$evidence->{cleanup}{residue}} == 0;
        $lifecycle_identity //= $evidence->{lifecycle_identity};
        confess "OSVVM lifecycle identity changed across stages\n"
            unless $evidence->{lifecycle_identity}
                eq $lifecycle_identity;
        _validate_lifecycle_chain($evidence->{stage_evidence});
    }
    my $emit =
        $oracle{osvvm_runtime_emit_lifecycle_canonical}{evidence};
    my $expected_provider = _provider_projection($plan);
    confess "OSVVM emit authority evidence changed\n"
        unless $emit->{plan_identity} eq $plan->{plan_identity}
            && $emit->{materialization_identity}
                eq $materialization->{report_identity}
            && _canonical_json($emit->{provider_verification})
                eq _canonical_json($expected_provider)
            && _canonical_json($emit->{emission_oracle})
                eq _canonical_json($materialization->{emission_oracle});

    my $publish =
        $oracle{osvvm_runtime_publish_lifecycle_canonical}{evidence};
    confess "OSVVM terminal lifecycle evidence changed\n"
        unless $publish->{lifecycle_identity} eq $lifecycle_identity
            && $publish->{terminal_state} eq 'cleaned'
            && _canonical_json($publish->{state_order})
                eq _canonical_json(\@state_order)
            && $publish->{cleanup}{removed}
            && @{$publish->{cleanup}{residue}} == 0
            && _canonical_json($publish->{provider_before_execution})
                eq _canonical_json($expected_provider)
            && _canonical_json($publish->{provider_after_execution})
                eq _canonical_json(_post_provider_authority($plan));
    _validate_lifecycle_chain($publish->{stage_evidence});
    my %state_evidence = map { $_->{state} => $_->{evidence} }
        @{$publish->{stage_evidence}};
    _validate_runtime_commands(
        $publish->{commands}, $record->{artifacts}{staging_identity},
        $publish->{source_set}, $plan,
    );
    my %expected_command_identity = map {
        ($_ => sha256_hex(_canonical_json($publish->{commands}{$_})))
    } qw(
        version provider_analyze analyze_generated elaborate_fixture
        elaborate_provider_probe run_fixture run_provider_probe
    );
    confess "OSVVM command identities changed\n"
        unless _canonical_json($publish->{command_identities})
            eq _canonical_json(\%expected_command_identity)
            && _canonical_json($state_evidence{analyzed}{command_digests})
                eq _canonical_json([map {
                    sha256_hex(_canonical_json($_))
                } @{$publish->{commands}{provider_analyze}}])
            && $state_evidence{analyzed}{generated_command_digest}
                eq $expected_command_identity{analyze_generated}
            && _canonical_json(
                $state_evidence{elaborated}{command_digests},
            ) eq _canonical_json([
                $expected_command_identity{elaborate_fixture},
                $expected_command_identity{elaborate_provider_probe},
            ])
            && _canonical_json($state_evidence{ran}{command_digests})
                eq _canonical_json({
                    fixture => $expected_command_identity{run_fixture},
                    provider_probe =>
                        $expected_command_identity{run_provider_probe},
                });
    _validate_osvvm_phase_evidence(
        \%state_evidence, $publish, $materialization, $plan,
    );
    _validate_publish_artifacts($record, $publish);
    my $cleanup = $oracle{owned_stage_absent};
    confess "OSVVM runtime controller cleanup oracle changed\n"
        unless $cleanup && $cleanup->{stage} eq 'cleanup'
            && $cleanup->{ok} && $cleanup->{evidence}{absent}
            && @{$cleanup->{evidence}{residue}} == 0
            && $cleanup->{evidence}{staging_identity}
                eq $record->{artifacts}{staging_identity};
}

sub _provider_projection($plan) {
    my $provider = $plan->{provider_authority};
    return {
        provider => $provider->{provider},
        version => $provider->{version},
        root_commit => $provider->{root_commit},
        root_tree => $provider->{root_tree},
        materialization_manifest_sha256 =>
            $provider->{materialization_manifest_sha256},
        provider_source_identity =>
            $provider->{provider_source_identity},
    };
}

sub _validate_lifecycle_chain($chain) {
    confess "OSVVM runtime lifecycle chain must be one non-empty array\n"
        unless ref($chain) eq 'ARRAY' && @$chain;
    my $predecessor;
    for my $index (0 .. $#$chain) {
        my $state = $chain->[$index];
        confess "OSVVM runtime lifecycle state order changed\n"
            unless $state->{ordinal} == $index
                && ($state->{state_identity} // '')
                    =~ m{\Astate/[0-9a-f]{64}\z}
                && _canonical_json($state->{predecessor_identity})
                    eq _canonical_json($predecessor);
        $predecessor = $state->{state_identity};
    }
}

sub _validate_runtime_commands(
    $commands, $controller_root, $source_set, $plan,
) {
    _safe_relative_path($controller_root);
    confess "OSVVM runtime source set is not exact\n"
        unless ref($source_set) eq 'ARRAY' && @$source_set == 68;
    my $prefix = "$controller_root/outputs/emit/source-graph/";
    my @generated = grep {
        index($_->{relpath}, $prefix) == 0
    } @$source_set;
    confess "OSVVM runtime generated source subset changed\n"
        unless @generated == 7;
    my $instantiated = $EXECUTION_PLAN->_measurement_plan({
        level => $plan->{level},
        staging_identity => "$controller_root/lifecycle",
        canonical_plan => $plan,
        generated_source_set => \@generated,
    });
    confess "OSVVM runtime lifecycle source authority changed\n"
        unless _canonical_json($source_set)
                eq _canonical_json($instantiated->{source_set})
            && _canonical_json($commands)
                eq _canonical_json($instantiated->{commands});
}

sub _validate_osvvm_phase_evidence(
    $state, $publish, $materialization, $plan,
) {
    my $commands = $publish->{commands};
    my $resources = $commands->{resource_controls};
    my $tool = $state->{tool_verified};
    my $prepared = $state->{prepared};
    my $analysis = $state->{analyzed};
    my $elaboration = $state->{elaborated};
    my $run = $state->{ran};
    confess "OSVVM prepared lifecycle evidence changed\n"
        unless $prepared->{source_count} == 68
            && $prepared->{settings_sha256}
                eq $commands->{generated_settings}{sha256}
            && _canonical_json($prepared->{library_identities})
                eq _canonical_json($commands->{libraries});
    confess "OSVVM tool-verification evidence changed\n"
        unless $tool->{version_sha256}
                eq sha256_hex(_tool_profile()->{reported_version} . "\n")
            && $tool->{capture}{timeout_seconds}
                == $resources->{version_timeout_seconds}
            && $tool->{capture}{capture_limit_bytes}
                == $resources->{version_capture_limit_bytes};
    confess "OSVVM provider-analysis evidence changed\n"
        unless ref($analysis->{captures}) eq 'ARRAY'
            && @{$analysis->{captures}}
                == @{$commands->{provider_analyze}}
            && @{$analysis->{captures}} == 61
            && ref($analysis->{output_sha256}) eq 'ARRAY'
            && @{$analysis->{output_sha256}} == 61
            && ref($analysis->{command_digests}) eq 'ARRAY'
            && @{$analysis->{command_digests}} == 61
            && $analysis->{generated_capture}{timeout_seconds}
                == $resources->{generated_analysis_timeout_seconds}
            && $analysis->{generated_capture}{capture_limit_bytes}
                == $resources->{provider_capture_limit_bytes};
    for my $capture (@{$analysis->{captures}}) {
        confess "OSVVM provider-analysis capture policy changed\n"
            unless $capture->{timeout_seconds}
                    == $resources
                        ->{provider_analysis_timeout_seconds_per_source}
                && $capture->{capture_limit_bytes}
                    == $resources->{provider_capture_limit_bytes};
    }
    confess "OSVVM elaboration evidence changed\n"
        unless ref($elaboration->{captures}) eq 'ARRAY'
            && @{$elaboration->{captures}} == 2
            && ref($elaboration->{output_sha256}) eq 'ARRAY'
            && @{$elaboration->{output_sha256}} == 2;
    for my $capture (@{$elaboration->{captures}}) {
        confess "OSVVM elaboration capture policy changed\n"
            unless $capture->{timeout_seconds}
                    == $resources->{elaboration_timeout_seconds}
                && $capture->{capture_limit_bytes}
                    == $resources->{provider_capture_limit_bytes};
    }
    confess "OSVVM runtime capture evidence changed\n"
        unless @{$run->{fixture_captures}} == 1
            && @{$run->{provider_captures}} == 1
            && @{$run->{fixture_output_sha256}} == 1
            && @{$run->{provider_output_sha256}} == 1
            && @{$run->{provider_report_sha256}} == 1
            && !$run->{deterministic}
            && $run->{fixture_captures}[0]{timeout_seconds}
                == $resources->{execution_timeout_seconds}
            && $run->{fixture_captures}[0]{capture_limit_bytes}
                == $resources->{fixture_capture_limit_bytes}
            && $run->{provider_captures}[0]{timeout_seconds}
                == $resources->{execution_timeout_seconds}
            && $run->{provider_captures}[0]{capture_limit_bytes}
                == $resources->{provider_capture_limit_bytes};
    my $expected_transcript = {
        version => $tool->{version_sha256},
        provider_analysis => _clone($analysis->{output_sha256}),
        generated_analysis => $analysis->{generated_output_sha256},
        elaboration => _clone($elaboration->{output_sha256}),
        fixture_run => $run->{fixture_output_sha256}[0],
        provider_run => $run->{provider_output_sha256}[0],
        provider_report_set => $run->{provider_report_sha256}[0],
    };
    confess "OSVVM transcript identities changed\n"
        unless _canonical_json($publish->{transcript_identities})
            eq _canonical_json($expected_transcript);
    confess "OSVVM trace/result identities changed\n"
        unless $publish->{trace_record_count}
                == $materialization->{trace_projection}{record_count}
            && $state->{trace_validated}{record_count}
                == $publish->{trace_record_count}
            && $state->{trace_validated}{trace_sha256}
                eq $publish->{trace_sha256}
            && sha256_hex(_canonical_json($publish->{trace_validation}))
                eq $publish->{trace_validation_sha256}
            && $state->{result_produced}{result_sha256}
                eq $publish->{result_sha256}
            && $state->{result_produced}{result_status}
                eq $publish->{result_status}
            && sha256_hex(_canonical_json($publish->{normalized_result}))
                eq $publish->{normalized_result_sha256};
    my $artifact = $publish->{artifact_identity};
    confess "OSVVM execution artifact authority changed\n"
        unless $artifact->{materialization_identity}
                eq $materialization->{report_identity}
            && $artifact->{plan_identity} eq $plan->{plan_identity}
            && $artifact->{emission_artifact_count}
                == $materialization->{emission_oracle}{artifact_count}
            && $artifact->{emission_source_bytes}
                == $materialization->{emission_oracle}{source_bytes}
            && $artifact->{emission_artifact_graph_sha256}
                eq $materialization->{emission_oracle}
                    {artifact_graph_sha256}
            && $artifact->{source_identity}
                =~ m{\Asource/[0-9a-f]{64}\z}
            && $artifact->{emission_identity}
                =~ m{\Aemission/[0-9a-f]{64}\z}
            && $artifact->{source_set_sha256}
                eq sha256_hex(_canonical_json($publish->{source_set}))
            && $artifact->{generated_settings_sha256}
                eq $commands->{generated_settings}{sha256}
            && $artifact->{provider_compiler_output_bytes} >= 0;
    confess "OSVVM provider report identity inventory changed\n"
        unless @{$publish->{provider_report_identities}} == 4;
    for my $index (0 .. 3) {
        my $identity = $publish->{provider_report_identities}[$index];
        my $authority = $commands->{provider_reports}[$index];
        confess "OSVVM provider report identity changed\n"
            unless $identity->{name} eq $authority->{name}
                && $identity->{relpath} eq $authority->{relpath}
                && $identity->{bytes} >= 0
                && $identity->{sha256} =~ /\A[0-9a-f]{64}\z/;
    }
}

sub _validate_publish_artifacts($record, $publish) {
    my @expected = (
        ['artifact-identities.json',
            'osvvm_runtime_artifact_identities',
            $publish->{artifact_identity}],
        ['command-authority.json', 'osvvm_runtime_command_authority',
            $publish->{commands}],
        ['lifecycle-evidence.json', 'osvvm_runtime_lifecycle_evidence',
            $publish],
        ['normalized-result.json', 'osvvm_runtime_normalized_result',
            $publish->{normalized_result}],
        ['provider-authority.json', 'osvvm_runtime_provider_authority', {
            before_execution => $publish->{provider_before_execution},
            after_execution => $publish->{provider_after_execution},
        }],
        ['provider-report-identities.json',
            'osvvm_runtime_provider_report_identities',
            $publish->{provider_report_identities}],
        ['trace-validation.json', 'osvvm_runtime_trace_validation',
            $publish->{trace_validation}],
        ['transcript-identities.json',
            'osvvm_runtime_transcript_identities',
            $publish->{transcript_identities}],
    );
    my %record = map { $_->{relative_path} => $_ }
        grep { index($_->{relative_path}, 'outputs/publish/') == 0 }
            @{$record->{artifacts}{records}};
    confess "OSVVM publish artifact cardinality changed\n"
        unless keys(%record) == @expected + 4;
    for my $expected (@expected) {
        my ($suffix, $kind, $value) = @$expected;
        my $path = "outputs/publish/$suffix";
        my $content = _canonical_json($value) . "\n";
        confess "OSVVM publish artifact '$suffix' changed\n"
            unless $record{$path}
                && $record{$path}{kind} eq $kind
                && $record{$path}{bytes} == bytes::length($content)
                && $record{$path}{lines} == 1
                && $record{$path}{sha256} eq sha256_hex($content);
    }
    for my $identity (@{$publish->{provider_report_identities}}) {
        my $path = "outputs/publish/provider-reports/$identity->{name}";
        confess "OSVVM raw provider report artifact changed\n"
            unless $record{$path}
                && $record{$path}{kind}
                    eq 'osvvm_runtime_provider_report'
                && $record{$path}{bytes} == $identity->{bytes}
                && $record{$path}{sha256} eq $identity->{sha256};
    }
}

sub _canonical_set($repo_root, $level) {
    _selected_level($level);
    my $construction = $MATERIALIZER->construct({
        repository_root => $repo_root, level => $level,
    });
    my $materialization = $MATERIALIZER->evaluate({
        repository_root => $repo_root, level => $level,
    });
    my $validated = $MATERIALIZER->validate_report({
        repository_root => $repo_root, report => $materialization,
    });
    confess "OSVVM runtime structural authority changed during validation\n"
        unless _canonical_json($validated)
                eq _canonical_json($materialization)
            && $construction->{workload_identity}
                eq $materialization->{workload_identity};
    my $plan;
    if ($materialization->{status} eq 'provider_structurally_qualified') {
        $plan = $EXECUTION_PLAN->evaluate({
            repository_root => $repo_root, level => $level,
        });
        my $validated_plan = $EXECUTION_PLAN->validate_report({
            repository_root => $repo_root, report => $plan,
        });
        confess "OSVVM runtime execution authority changed during validation\n"
            unless _canonical_json($validated_plan) eq _canonical_json($plan)
                && $plan->{materialization_identity}
                    eq $materialization->{report_identity}
                && $plan->{workload_identity}
                    eq $construction->{workload_identity};
    }
    return (
        _clone($construction), _clone($materialization), _clone($plan),
    );
}

sub _command_identity($stage, $level) {
    my %external_name = (
        compile_analyze =>
            'ghdl_6_0_0_osvvm_provider_and_generated_analysis',
        elaborate =>
            'ghdl_6_0_0_osvvm_fixture_and_probe_elaboration',
        run => 'ghdl_6_0_0_osvvm_fixture_and_probe_runtime',
    );
    my $logical = $EXTERNAL_STAGE{$stage}
        ? $external_name{$stage}
        : "vial_scale_osvvm_runtime_$stage";
    my @arguments = ($PROFILE, $level, $PRIMARY_AXIS);
    if ($stage eq 'compile_analyze') {
        @arguments = qw(
            --version -a --std=08 -Wno-library -Wno-hide
            --work=<provider-or-fsmgen-library>
            --workdir=<lifecycle-library-root>
            -P<lifecycle-library-root> <ordered-provider-source-set>
            <ordered-generated-source-set>
        );
    }
    elsif ($stage eq 'elaborate') {
        @arguments = qw(
            -e --std=08 --work=fsmgen_vial
            --workdir=<lifecycle-library-root>
            -P<lifecycle-library-root> <fixture-and-provider-probe>
        );
    }
    elsif ($stage eq 'run') {
        @arguments = qw(
            -r --std=08 --work=fsmgen_vial
            --workdir=<lifecycle-library-root>
            -P<lifecycle-library-root> <fixture-and-provider-probe>
            --assert-level=error
        );
    }
    return {
        logical_name => $logical,
        arguments => \@arguments,
        thread_count => 1,
        job_count => 1,
    };
}

sub _tool_profile() {
    return {
        applicability => 'qualified_runtime',
        logical_name => 'ghdl',
        reported_version => join("\n",
            'GHDL 6.0.0 (6.0.0.r0.ge589c698c) [Dunoon edition]',
            ' Compiled with GNAT Version: 14.2.0',
            ' static elaboration, LLVM JIT code generator',
            'Written by Tristan Gingold.',
            '',
            'Copyright (C) 2003 - 2026 Tristan Gingold.',
            'GHDL is free software, covered by the GNU General Public License.  There is NO',
            'warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.'),
        build => '6.0.0-llvm-jit',
        provider_identity =>
            'qualified_osvvm_2026_05_ghdl_6_0_0_llvm_jit',
        arguments => [qw(
            --std=08 -Wno-library -Wno-hide --work=fsmgen_vial
            -P<lifecycle-library-root>
        )],
        thread_count => 1,
        job_count => 1,
        external_verification_tool => JSON::PP::true,
    };
}

sub _lifecycle_contract() {
    return {
        implementation => $LIFECYCLE,
        schema_version => 2,
        state_order => $LIFECYCLE->state_order,
        stage_mapping => {
            emit => ['admitted'],
            compile_analyze => [qw(prepared tool_verified analyzed)],
            elaborate => ['elaborated'],
            run => ['ran'],
            trace_validate => ['trace_validated'],
            result_produce => ['result_produced'],
            publish => [qw(assembled cleaned)],
        },
        storage_mode => 'osvvm_architecture_scale_measurement',
        containment => 'outer_worker_process_group',
        version_timeout_seconds => 10,
        provider_analysis_timeout_seconds_per_source => 120,
        generated_analysis_timeout_seconds => 120,
        elaboration_timeout_seconds => 60,
        execution_timeout_seconds => 30,
        version_capture_bytes => 65_536,
        provider_capture_bytes => 8_388_608,
        fixture_capture_bytes => 67_108_864,
    };
}

sub _source_counts($construction) {
    my $counts = {files => 0, lines => 0, bytes => 0, objects => 0};
    for my $input (@{$construction->{inputs}}) {
        $counts->{files}++;
        $counts->{objects}++;
        $counts->{bytes} += bytes::length($input->{content});
        $counts->{lines} += _line_count($input->{content});
    }
    return $counts;
}

sub _require_active_guard() {
    confess "OSVVM runtime validation and measurement require the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1'
            && defined($ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT})
            && defined($ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB});
}

sub _validate_applicability($value, $label) {
    _exact_keys($value, \@APPLICABILITY_KEYS, $label);
    confess "$label applicability must be one JSON boolean\n"
        unless JSON::PP::is_bool($value->{applicable});
    confess "$label reason is invalid\n"
        unless defined($value->{reason})
            ? _safe_token($value->{reason}) : $value->{applicable};
}

sub _selected_level($level) {
    confess "OSVVM runtime measurement level is not selected\n"
        unless defined($level) && !ref($level) && $LEVEL{$level};
}

sub _repository_root($raw) {
    confess "repository_root must name one existing directory\n"
        unless defined($raw) && !ref($raw) && -d $raw && !-l $raw;
    return File::Spec->rel2abs($raw);
}

sub _request($method, $args, $keys) {
    confess __PACKAGE__ . "->$method expects one closed hash\n"
        unless @$args == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    _exact_keys($args->[0], $keys, "$method invocation");
    return $args->[0];
}

sub _report_identity($report) {
    my $copy = _clone($report);
    delete $copy->{report_identity};
    return 'osvvm-runtime-measurement/'
        . sha256_hex(_canonical_json($copy));
}

sub _diagnostic($code, $message, $path, $notes = undef) {
    $message //= 'OSVVM runtime measurement failed';
    $message =~ s{(?:/Volumes|/Users|/private|/tmp)/\S+}{<machine-path>}g;
    $message =~ s/\s+at\s+\S+\s+line\s+\d+[.]?\s*\z//;
    return {
        code => _safe_token($code),
        severity => 'error',
        message => $message,
        source_locations => [],
        semantic_path => $path,
        related => [], notes => _clone($notes // []), hints => [],
    };
}

sub _safe_relative_path($value) {
    confess "OSVVM runtime measurement path is unsafe\n"
        unless defined($value) && !ref($value)
            && $value =~ m{\A[A-Za-z0-9_.][A-Za-z0-9_.\/-]*\z}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                split m{/}, $value, -1;
    return $value;
}

sub _safe_token($value) {
    confess "OSVVM runtime measurement token is unsafe\n"
        unless defined($value) && !ref($value)
            && $value =~ /\A[A-Za-z0-9_.:-]+\z/;
    return $value;
}

sub _line_count($content) {
    my $count = () = $content =~ /\n/g;
    return $count;
}

sub _json_node_count($value) {
    return 0 unless ref($value);
    return 1 + _sum(map { _json_node_count($value->{$_}) }
        sort keys %$value) if ref($value) eq 'HASH';
    return 1 + _sum(map { _json_node_count($_) } @$value)
        if ref($value) eq 'ARRAY';
    return 1;
}

sub _sum(@values) {
    my $sum = 0;
    $sum += $_ for @values;
    return $sum;
}

sub _zero_counts() {
    return {files => 0, lines => 0, bytes => 0, objects => 0};
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
    return JSON::PP->new->decode(_canonical_json($value));
}

1;
