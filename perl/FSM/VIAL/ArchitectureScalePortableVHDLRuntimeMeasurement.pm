package FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement;

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
use FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization;
use FSM::VIAL::Backend::GHDLLifecycle;
use FSM::VIAL::Backend::VHDLPortableGHDLQualification;
use FSM::VIAL::Backend::VHDLPortableTraceValidator;

my $SCHEMA =
    'fsmgen.vial_architecture_scale_portable_vhdl_runtime_measurement_set.v1';
my $FAMILY = 'runtime_stream_v1';
my $PROFILE = 'vhdl_portable_ghdl';
my $PRIMARY_AXIS = 'runtime_trace_records';
my $MATERIALIZER =
    'FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization';
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
my %EXTERNAL_STAGE = map { $_ => 1 } qw(compile_analyze elaborate run);
# The common worker also reconstructs canonical repository authority.  Its
# outer envelope therefore remains the controller's 900/60/300-second stage
# bounds; the shared lifecycle independently enforces the actual 10/120/60/30
# tool deadlines.  Applying a tool deadline to authority reconstruction would
# shorten, not strengthen, that contract.
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
    tool_profile lifecycle_contract controller_applicability
    measurement_applicability validation_record measurement_records
    sample_exclusions outcome diagnostics cleanup explicit_nonclaims
);
my @APPLICABILITY_KEYS = qw(applicable reason);
my @LIFECYCLE_KEYS = qw(
    implementation state_order stage_mapping storage_mode containment
    version_timeout_seconds analysis_timeout_seconds
    elaboration_timeout_seconds run_timeout_seconds version_capture_bytes
    analysis_capture_bytes elaboration_capture_bytes run_capture_bytes
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
        full_vhdl_2008 psl osvvm uvvm native_uvm mixed_language
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
        repository_root => $repo_root,
        level => $request->{level},
    });
}

sub validate_profile($class, @args) {
    _exact_invocant($class, 'validate_profile');
    my $request = _request(
        'validate_profile', \@args, [qw(repository_root level)],
    );
    my $repo_root = _repository_root($request->{repository_root});
    my ($construction, $materialization) =
        _canonical_pair($repo_root, $request->{level});
    if ($materialization->{status} eq 'preflight_dominated') {
        return _finalize_report({
            repository_root => $repo_root,
            construction => $construction,
            materialization => $materialization,
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
        run_class => 'validation',
        run_ordinal => 0,
        validation_record => undef,
    });
    return _finalize_report({
        repository_root => $repo_root,
        construction => $construction,
        materialization => $materialization,
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
    confess "only the portable gate and qualification candidates are measurable\n"
        unless defined $mode;
    _require_active_guard();
    my $repo_root = _repository_root($request->{repository_root});
    my ($construction, $materialization) =
        _canonical_pair($repo_root, $request->{level});
    confess "preflight-dominated runtime shape reached measurement\n"
        unless $materialization->{status} eq 'structurally_qualified';
    my $validation = _run_record({
        repository_root => $repo_root,
        construction => $construction,
        materialization => $materialization,
        run_class => 'validation',
        run_ordinal => 0,
        validation_record => undef,
    });
    my @measured;
    if ($validation->{outcome} eq 'accepted') {
        for my $ordinal (1 .. $MODE_SAMPLES{$mode}) {
            my $record = _run_record({
                repository_root => $repo_root,
                construction => $construction,
                materialization => $materialization,
                run_class => $mode,
                run_ordinal => $ordinal,
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
    my $construction = $raw->{construction};
    my $materialization = $raw->{materialization};
    my $level = $construction->{specification}{level};
    my $source_counts = _source_counts($construction);
    my @plan;
    for my $stage (@PLANNED_STAGES) {
        my $input_counts = $stage eq 'construct'
            ? {
                files => 0,
                lines => 1,
                bytes => bytes::length(_canonical_json(
                    $construction->{specification},
                )),
                objects => 1,
            }
            : _clone($source_counts);
        push @plan, {
            stage => $stage,
            classification => $EXTERNAL_STAGE{$stage}
                ? 'external_tool' : 'fsmgen_owned',
            command_identity => _command_identity($stage, $level),
            input_counts => $input_counts,
            backend_timeout_seconds => $BACKEND_TIMEOUT{$stage},
            worker => sub ($context) {
                return _stage_worker({
                    repository_root => $raw->{repository_root},
                    construction => $construction,
                    materialization => $materialization,
                    stage => $stage,
                    context => $context,
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
        confess "portable runtime construction changed inside controller\n"
            unless _canonical_json($rebuilt)
                eq _canonical_json($raw->{construction});
        my $payload = {
            workload_identity => $rebuilt->{workload_identity},
            specification => _clone($rebuilt->{specification}),
            inputs => [map {{
                relative_path => $_->{relative_path},
                role => $_->{role},
                bytes => bytes::length($_->{content}),
                sha256 => sha256_hex($_->{content}),
            }} @{$rebuilt->{inputs}}],
        };
        return _materialize_payload($context, {
            status => 'portable_runtime_construct_completed',
            oracle_id => 'portable_runtime_construct_canonical',
            evidence => $payload,
            semantic_counts => {
                constructed_inputs => scalar(@{$rebuilt->{inputs}}),
                construction_identity_records => 1,
            },
            artifacts => [{
                suffix => 'construction.json',
                kind => 'portable_runtime_construction',
                content => _canonical_json($payload) . "\n",
            }],
        });
    }

    my $authority = _canonical_authority($raw, $context);
    return _structural_stage($raw, $authority)
        if $stage =~ /\A(?:parse_validate|bridge|bind_plan)\z/;
    return _lifecycle_stage($raw, $authority);
}

sub _canonical_authority($raw, $context) {
    my $level = $raw->{construction}{specification}{level};
    my $artifact_root =
        "$context->{staging_identity}/outputs/emit/source-graph";
    my $first = $MATERIALIZER->_measurement_inputs({
        repository_root => $raw->{repository_root},
        level => $level,
        artifact_root => $artifact_root,
    });
    confess "portable runtime controller construction authority changed\n"
        unless _canonical_json($first->{construction})
            eq _canonical_json($raw->{construction});
    my $route = $first->{route};
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
    confess "portable runtime controller route authority changed\n"
        unless _canonical_json(\%identity)
            eq _canonical_json($raw->{materialization}{stage_identities});
    my $observed = $first->{emission_oracle};
    my $expected = $raw->{materialization}{emission_oracle};
    confess "portable runtime controller emission authority changed\n"
        unless $observed->{artifact_count} == $expected->{artifact_count}
            && $observed->{artifact_bytes} == $expected->{artifact_bytes}
            && $observed->{source_artifact_count}
                == $expected->{source_artifact_count}
            && $observed->{source_artifact_bytes}
                == $expected->{source_artifact_bytes}
            && $observed->{source_map_entries}
                == $expected->{source_map_entries}
            && $observed->{static_check_count}
                == $expected->{static_check_count}
            && $observed->{fixture_bytes} == $expected->{fixture_bytes}
            && $observed->{fixture_sha256} eq $expected->{fixture_sha256}
            && $observed->{generated_reset_loop}
                eq $expected->{generated_reset_loop};
    return $first;
}

sub _structural_stage($raw, $authority) {
    my $stage = $raw->{stage};
    my $route = $authority->{route};
    my $expected = $raw->{materialization};
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
    confess "portable runtime structural stage identities changed\n"
        unless _canonical_json(\%identity)
            eq _canonical_json($expected->{stage_identities});
    my ($evidence, $counts);
    if ($stage eq 'parse_validate') {
        $evidence = {
            workload_identity => $authority->{construction}{workload_identity},
            source_identity => _clone($expected->{source_identity}),
            semantic_ir_sha256 => $identity{semantic_ir_sha256},
            status => 'accepted', diagnostics => [],
        };
        $counts = {
            semantic_ir_nodes => _json_node_count($projection{semantic_ir}),
            parse_diagnostics => 0,
        };
    }
    elsif ($stage eq 'bridge') {
        $evidence = {
            workload_identity => $authority->{construction}{workload_identity},
            semantic_ir_sha256 => $identity{semantic_ir_sha256},
            bridge_manifest_sha256 => $identity{bridge_manifest_sha256},
            backend_inputs_sha256 => $identity{backend_inputs_sha256},
            structural_equivalence =>
                _clone($expected->{structural_equivalence}),
            status => 'accepted', diagnostics => [],
        };
        $counts = {
            bridge_manifest_nodes =>
                _json_node_count($projection{bridge_manifest}),
            backend_input_nodes =>
                _json_node_count($projection{backend_inputs}),
            bridge_diagnostics => 0,
        };
    }
    else {
        $evidence = {
            workload_identity => $authority->{construction}{workload_identity},
            execution_ir_sha256 => $identity{execution_ir_sha256},
            plan_sha256 => $identity{plan_sha256},
            schedule_oracle => _clone($expected->{schedule_oracle}),
            status => 'accepted', diagnostics => [],
        };
        $counts = {
            execution_ir_nodes =>
                _json_node_count($projection{execution_ir}),
            plan_nodes => _json_node_count($projection{plan}),
            operations => 0 + $expected->{schedule_oracle}{operation_count},
            source_maps => 0 + $expected->{schedule_oracle}{source_map_count},
        };
    }
    return _materialize_payload($raw->{context}, {
        status => "portable_runtime_${stage}_accepted",
        oracle_id => "portable_runtime_${stage}_canonical",
        evidence => $evidence,
        semantic_counts => $counts,
        artifacts => [{
            suffix => "$stage-evidence.json",
            kind => "portable_runtime_${stage}_evidence",
            content => _canonical_json($evidence) . "\n",
        }],
    });
}

sub _lifecycle_stage($raw, $authority) {
    my $stage = $raw->{stage};
    my $context = $raw->{context};
    my $source_records = $stage eq 'emit'
        ? _materialize_sources($context, $authority->{emission}) : [];
    my $request = _lifecycle_request($raw, $authority, $context);
    my $result;
    if ($stage eq 'emit') {
        $result = $LIFECYCLE->begin_session($request);
        return _lifecycle_failure($stage, $result) unless $result->{ok};
        confess "portable runtime lifecycle admission state changed\n"
            unless $result->{status} eq 'admitted';
    }
    else {
        my $handle = _read_predecessor_handle($context, $stage);
        $request->{handle} = $handle;
        if ($stage eq 'compile_analyze') {
            for my $target (qw(prepared tool_verified analyzed)) {
                $result = $LIFECYCLE->advance_session($request);
                return _lifecycle_failure($stage, $result)
                    unless $result->{ok};
                confess "portable-VHDL lifecycle analysis transition changed\n"
                    unless $result->{status} eq $target;
                $request->{handle} = $result->{handle};
            }
        }
        elsif ($stage eq 'publish') {
            my $assembled = $LIFECYCLE->advance_session($request);
            return _lifecycle_failure($stage, $assembled)
                unless $assembled->{ok};
            confess "portable-VHDL lifecycle assembly state changed\n"
                unless $assembled->{status} eq 'assembled';
            $request->{handle} = $assembled->{handle};
            my $finished = $LIFECYCLE->finish_session($request);
            return _lifecycle_failure($stage, $finished)
                unless $finished->{ok};
            confess "portable runtime lifecycle cleanup state changed\n"
                unless $finished->{status} eq 'cleaned'
                    && $finished->{cleanup}{removed}
                    && ref($finished->{assembled_result}) eq 'HASH';
            return _publish_payload(
                $raw, $assembled, $finished, $request,
            );
        }
        else {
            my %target = (
                elaborate => 'elaborated',
                run => 'ran',
                trace_validate => 'trace_validated',
                result_produce => 'result_produced',
            );
            $result = $LIFECYCLE->advance_session($request);
            return _lifecycle_failure($stage, $result) unless $result->{ok};
            confess "portable runtime lifecycle stage transition changed\n"
                unless $result->{status} eq $target{$stage};
        }
    }

    my $evidence = _lifecycle_evidence($stage, $result);
    my $payload = _materialize_payload($context, {
        status => "portable_runtime_${stage}_completed",
        oracle_id => "portable_runtime_${stage}_lifecycle_canonical",
        evidence => $evidence,
        semantic_counts => _lifecycle_semantic_counts($result),
        artifacts => [
            {
                suffix => 'lifecycle-handle.json',
                kind => 'portable_runtime_lifecycle_handle',
                content => _canonical_json($result->{handle}) . "\n",
            },
            {
                suffix => 'lifecycle-evidence.json',
                kind => 'portable_runtime_lifecycle_evidence',
                content => _canonical_json($evidence) . "\n",
            },
        ],
    });
    return _merge_existing_records($payload, $source_records);
}

sub _publish_payload($raw, $assembled_state, $finished, $request) {
    my $assembled = $finished->{assembled_result};
    confess "portable-VHDL assembled runtime output cardinality changed\n"
        unless ref($assembled->{runtime_outputs}) eq 'ARRAY'
            && @{$assembled->{runtime_outputs}} == 1
            && ref($assembled->{trace_validation}) eq 'HASH'
            && ref($assembled->{normalized_result}) eq 'HASH';
    my $trace = _state_evidence($assembled_state, 'trace_validated');
    my $result = _state_evidence($assembled_state, 'result_produced');
    my $tool = _state_evidence($assembled_state, 'tool_verified');
    my $analysis = _state_evidence($assembled_state, 'analyzed');
    my $elaboration = _state_evidence($assembled_state, 'elaborated');
    my $run = _state_evidence($assembled_state, 'ran');
    confess "portable runtime validated trace record count changed\n"
        unless $trace->{record_count}
            == $raw->{materialization}{trace_projection}{record_count};
    my %command_identity = map {
        ($_ => sha256_hex(_canonical_json($request->{commands}{$_})))
    } qw(version analyze elaborate run);
    my $transcript_identity = {
        version => $tool->{version_sha256},
        analyze => $analysis->{output_sha256},
        elaborate => $elaboration->{output_sha256},
        run => $run->{output_sha256}[0],
    };
    my $artifact_identity = {
        source_identity => $request->{source_identity},
        emission_identity => $request->{emission_identity},
        emission_artifact_count =>
            0 + $raw->{materialization}{emission_oracle}{artifact_count},
        emission_artifact_bytes =>
            0 + $raw->{materialization}{emission_oracle}{artifact_bytes},
        emission_artifact_graph_sha256 =>
            $raw->{materialization}{emission_oracle}{artifact_graph_sha256},
        source_set_sha256 => sha256_hex(
            _canonical_json($request->{source_set}),
        ),
    };
    my $evidence = {
        lifecycle_identity => $assembled_state->{lifecycle_identity},
        terminal_state => $finished->{status},
        state_order => [map { $_->{state} }
            @{$assembled_state->{stage_evidence}}],
        stage_evidence => _clone($assembled_state->{stage_evidence}),
        artifact_identity => $artifact_identity,
        source_set => _clone($request->{source_set}),
        commands => _clone($request->{commands}),
        command_identities => \%command_identity,
        transcript_identities => $transcript_identity,
        trace_sha256 => $trace->{trace_sha256},
        trace_record_count => 0 + $trace->{record_count},
        trace_validation_sha256 => sha256_hex(
            _canonical_json($assembled->{trace_validation}),
        ),
        trace_validation => _clone($assembled->{trace_validation}),
        result_sha256 => $result->{result_sha256},
        result_status => $result->{result_status},
        normalized_result_sha256 => sha256_hex(
            _canonical_json($assembled->{normalized_result}),
        ),
        normalized_result => _clone($assembled->{normalized_result}),
        cleanup => _clone($finished->{cleanup}),
    };
    my @summary_artifacts = (
        ['lifecycle-evidence.json', 'portable_vhdl_lifecycle_evidence',
            $evidence],
        ['artifact-identities.json', 'portable_vhdl_artifact_identities',
            $artifact_identity],
        ['command-authority.json', 'portable_vhdl_command_authority',
            $request->{commands}],
        ['transcript-identities.json', 'portable_vhdl_transcript_identities',
            $transcript_identity],
        ['trace-validation.json', 'portable_vhdl_trace_validation',
            $assembled->{trace_validation}],
        ['normalized-result.json', 'portable_vhdl_normalized_result',
            $assembled->{normalized_result}],
    );
    return _materialize_payload($raw->{context}, {
        status => 'portable_runtime_publish_completed',
        oracle_id => 'portable_runtime_publish_lifecycle_canonical',
        evidence => $evidence,
        semantic_counts => {
            lifecycle_states => scalar(@{$assembled_state->{stage_evidence}}),
            artifact_graph_files =>
                0 + $artifact_identity->{emission_artifact_count},
            trace_records => 0 + $trace->{record_count},
            result_manifests => 1,
        },
        artifacts => [map {{
            suffix => $_->[0], kind => $_->[1],
            content => _canonical_json($_->[2]) . "\n",
        }} @summary_artifacts],
    });
}

sub _lifecycle_request($raw, $authority, $context) {
    my $provider =
        FSM::VIAL::Backend::VHDLPortableGHDLQualification
            ->_measurement_provider_authority;
    my $source_set = _source_set($authority->{emission}, $context);
    my $source_identity = 'source/'
        . sha256_hex(_canonical_json($source_set));
    my $library = "$context->{staging_identity}/lifecycle/library";
    my $binary = $provider->{binary};
    my $execution = $authority->{route}{execution_ir}->as_hashref;
    my $top = $authority->{emission}{generated_top};
    confess "portable-VHDL generated top identity changed\n"
        unless defined($top) && !ref($top)
            && $top =~ /\A[A-Za-z][A-Za-z0-9_]*\z/;
    my $commands = {
        version => [$binary, '--version'],
        analyze => [$binary, '-a', '--std=08', '--work=fsmgen_vial',
            "--workdir=$library", map { $_->{relpath} } @$source_set],
        elaborate => [$binary, '-e', '--std=08', '--work=fsmgen_vial',
            "--workdir=$library", $top],
        run => [$binary, '-r', '--std=08', '--work=fsmgen_vial',
            "--workdir=$library", $top, '--assert-level=error'],
    };
    my $checked =
        FSM::VIAL::Backend::VHDLPortableTraceValidator
            ->checked_reference_authority;
    my @run_ids = map {
        "run/$execution->{plan_id}/$_->{scenario_id}"
    } @{$execution->{scenarios}};
    my $emission_identity = 'emission/' . sha256_hex(_canonical_json({
        workload_identity => $raw->{construction}{workload_identity},
        source_identity => $source_identity,
        emission_oracle => $raw->{materialization}{emission_oracle},
        commands => $commands,
    }));
    return {
        repo_root => $raw->{repository_root},
        provider => $provider,
        source_set => $source_set,
        source_identity => $source_identity,
        emission_identity => $emission_identity,
        commands => $commands,
        validation => {
            expected_record_counts => _clone(
                $raw->{materialization}{trace_projection}{record_families},
            ),
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
            mode => 'architecture_scale_measurement',
            staging_identity => "$context->{staging_identity}/lifecycle",
            containment => 'outer_worker_process_group',
        },
    };
}

sub _source_set($emission, $context) {
    my %by_path = map { $_->{relpath} => $_ } @{$emission->{artifacts}};
    my %validated = map { $_->{relpath} => $_ }
        @{$emission->{static_validation}{artifacts}};
    my $ordered = $emission->{backend_manifest}{source_order}{sources};
    confess "portable-VHDL compiler source order is not exact\n"
        unless ref($ordered) eq 'ARRAY' && @$ordered == 6;
    my $root =
        "$context->{staging_identity}/outputs/emit/source-graph";
    my @source;
    for my $relpath (@$ordered) {
        my $entry = $validated{$relpath};
        my $artifact = $by_path{$relpath};
        confess "portable-VHDL lifecycle source artifact is absent\n"
            unless defined($entry) && defined($artifact)
                && bytes::length($artifact->{content}) == $entry->{bytes}
                && sha256_hex($artifact->{content}) eq $entry->{sha256};
        push @source, {
            relpath => "$root/$relpath",
            bytes => 0 + $entry->{bytes},
            sha256 => $entry->{sha256},
        };
    }
    confess "portable-VHDL lifecycle source cardinality changed\n"
        unless @source == 6;
    return \@source;
}

sub _materialize_sources($context, $emission) {
    my %by_path = map { $_->{relpath} => $_ } @{$emission->{artifacts}};
    my $prefix = "$context->{staging_identity}/outputs/emit/";
    my $source_graph_prefix = "${prefix}source-graph/";
    my @records;
    for my $source (@{_source_set($emission, $context)}) {
        confess "portable-VHDL source is outside the emit worker root\n"
            unless index($source->{relpath}, $prefix) == 0;
        my $suffix = _safe_relative_path(
            substr($source->{relpath}, length($prefix)),
        );
        my @parts = split m{/}, $suffix;
        my $path = File::Spec->catfile($context->{output_root}, @parts);
        my @parent = @parts;
        pop @parent;
        make_path(File::Spec->catdir($context->{output_root}, @parent))
            if @parent;
        my $emission_relpath = substr(
            $source->{relpath}, length($source_graph_prefix),
        );
        my $content = $by_path{$emission_relpath}{content};
        open my $fh, '>:raw', $path
            or die "cannot create portable-VHDL lifecycle source: $!\n";
        print {$fh} $content;
        close $fh
            or die "cannot close portable-VHDL lifecycle source: $!\n";
        push @records, {
            relative_path => "$context->{output_identity}/$suffix",
            kind => 'portable_vhdl_lifecycle_source',
            bytes => bytes::length($content),
            lines => _line_count($content),
            sha256 => sha256_hex($content),
        };
    }
    return \@records;
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

sub _read_predecessor_handle($context, $stage) {
    my $predecessor = $PREDECESSOR_STAGE{$stage};
    confess "portable runtime lifecycle predecessor stage is unknown\n"
        unless defined $predecessor;
    my $path = File::Spec->catfile(
        $context->{staging_root}, 'outputs', $predecessor,
        'lifecycle-handle.json',
    );
    open my $fh, '<:raw', $path
        or confess "portable runtime lifecycle predecessor handle is absent\n";
    local $/;
    my $content = <$fh>;
    close $fh
        or confess "cannot close portable runtime predecessor handle\n";
    my $handle = eval { JSON::PP->new->decode($content) };
    confess "portable runtime lifecycle predecessor handle is malformed\n"
        unless ref($handle) eq 'HASH' && !blessed($handle);
    return $handle;
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
        lifecycle_evidence_records => scalar(@{$result->{stage_evidence}}),
    };
}

sub _state_evidence($result, $state) {
    my @match = grep { ($_->{state} // '') eq $state }
        @{$result->{stage_evidence}};
    confess "portable runtime lifecycle state evidence is not unique\n"
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
            'lifecycle-identity:' . ($result->{lifecycle_identity} // 'none'),
            'stage-evidence-json:' . _canonical_json(
                $result->{stage_evidence} // [],
            ),
            'cleanup-json:' . _canonical_json($result->{cleanup} // {});
    }
    return {
        ok => JSON::PP::false,
        status => "portable_runtime_${stage}_rejected",
        output_counts => _zero_counts(),
        semantic_object_counts => {},
        correctness_oracles => [],
        artifacts => [],
        diagnostic => _diagnostic(
            $diagnostic->{code} // 'VIAL_RUNTIME_MEASUREMENT_ERROR',
            $diagnostic->{message} // 'shared lifecycle rejected the stage',
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
            or die "cannot create portable runtime measurement artifact: $!\n";
        print {$fh} $artifact->{content};
        close $fh
            or die "cannot close portable runtime measurement artifact: $!\n";
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
    confess "portable runtime measurement report must be one unblessed hash\n"
        unless ref($report) eq 'HASH' && !blessed($report);
    _exact_keys($report, \@REPORT_KEYS,
        'portable runtime measurement report');
    confess "portable runtime measurement report header is invalid\n"
        unless ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // -1) == 1
            && ($report->{family} // '') eq $FAMILY
            && ($report->{backend_profile} // '') eq $PROFILE
            && ($report->{primary_axis} // '') eq $PRIMARY_AXIS;
    my ($construction, $materialization) =
        _canonical_pair($repo_root, $report->{level});
    confess "portable runtime measurement workload identity changed\n"
        unless ($report->{workload_identity} // '')
            eq $construction->{workload_identity};
    confess "portable runtime materialization evidence changed\n"
        unless _canonical_json($report->{materialization})
                eq _canonical_json($materialization)
            && _canonical_json($report->{requested_counts})
                eq _canonical_json($materialization->{requested_counts});
    confess "portable runtime tool profile changed\n"
        unless _canonical_json($report->{tool_profile})
            eq _canonical_json(_tool_profile());
    _exact_keys($report->{lifecycle_contract}, \@LIFECYCLE_KEYS,
        'portable runtime lifecycle contract');
    confess "portable runtime lifecycle contract changed\n"
        unless _canonical_json($report->{lifecycle_contract})
            eq _canonical_json(_lifecycle_contract());
    _validate_applicability(
        $report->{controller_applicability}, 'controller applicability');
    _validate_applicability(
        $report->{measurement_applicability}, 'measurement applicability');
    confess "portable runtime measurement records must be one array\n"
        unless ref($report->{measurement_records}) eq 'ARRAY';
    confess "portable runtime sample exclusions must be one array\n"
        unless ref($report->{sample_exclusions}) eq 'ARRAY';
    confess "portable runtime diagnostics must be one array\n"
        unless ref($report->{diagnostics}) eq 'ARRAY';
    my $preflight = $materialization->{status} eq 'preflight_dominated';
    my $mode = $report->{mode};
    confess "portable runtime report mode is invalid\n"
        unless $mode eq 'validation' || $mode eq 'preflight'
            || exists $MODE_SAMPLES{$mode};
    confess "portable runtime preflight mode changed\n"
        if $preflight != ($mode eq 'preflight');
    my $validation = $report->{validation_record};
    my @measured = @{$report->{measurement_records}};
    if ($preflight) {
        confess "preflight-dominated runtime report executed a controller\n"
            if defined($validation) || @measured;
    }
    else {
        confess "portable runtime report has no validation record\n"
            unless ref($validation) eq 'HASH' && !blessed($validation);
        $CONTROLLER->validate_record({record => $validation});
        $CONTROLLER->validate_record({record => $_}) for @measured;
        confess "portable runtime validation ordinal changed\n"
            unless $validation->{run_class} eq 'validation'
                && $validation->{run_ordinal} == 0;
        my @records = ($validation, @measured);
        _validate_record_evidence(
            $_, $construction, $materialization,
        ) for @records;
        if ($mode eq 'validation') {
            confess "validation-only runtime report retained samples\n"
                if @measured;
        }
        else {
            confess "runtime measurement mode does not match selected level\n"
                unless ($LEVEL_MODE{$report->{level}} // '') eq $mode;
            for my $index (0 .. $#measured) {
                confess "runtime sample ordinal or class changed\n"
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
    confess "portable runtime controller applicability changed\n"
        unless _canonical_json($report->{controller_applicability})
            eq _canonical_json($expected_controller);
    confess "portable runtime measurement applicability changed\n"
        unless _canonical_json($report->{measurement_applicability})
            eq _canonical_json($expected_measurement);
    my @expected_exclusions = map {{
        run_ordinal => $_->{run_ordinal},
        reason => $_->{outcome},
        measurement_identity => $_->{measurement_identity},
        diagnostic => _clone($_->{diagnostic}),
    }} grep { $_->{outcome} ne 'accepted' } @measured;
    _exact_keys($_, \@EXCLUSION_KEYS, 'portable runtime sample exclusion')
        for @{$report->{sample_exclusions}};
    confess "portable runtime sample exclusion evidence changed\n"
        unless _canonical_json($report->{sample_exclusions})
            eq _canonical_json(\@expected_exclusions);
    _exact_keys($report->{cleanup}, \@CLEANUP_KEYS,
        'portable runtime cleanup');
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
    confess "portable runtime cleanup evidence changed\n"
        unless _canonical_json($report->{cleanup})
            eq _canonical_json($expected_cleanup);
    confess "portable runtime nonclaim boundary changed\n"
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
    elsif (@expected_exclusions
            || @measured != $MODE_SAMPLES{$mode}) {
        $expected_outcome = 'rejected';
        push @expected_diagnostics,
            _clone($expected_exclusions[0]{diagnostic})
            if @expected_exclusions;
    }
    else {
        $expected_outcome = 'accepted';
    }
    confess "portable runtime report outcome changed\n"
        unless ($report->{outcome} // '') eq $expected_outcome;
    confess "portable runtime report diagnostics changed\n"
        unless _canonical_json($report->{diagnostics})
            eq _canonical_json(\@expected_diagnostics);
    confess "portable runtime report identity changed\n"
        unless ($report->{report_identity} // '') eq _report_identity($report);
    return;
}

sub _validate_record_evidence($record, $construction, $materialization) {
    confess "portable runtime record workload changed\n"
        unless $record->{workload_identity} eq $construction->{workload_identity}
            && _canonical_json($record->{workload_specification})
                eq _canonical_json($construction->{specification})
            && _canonical_json($record->{tool_profile})
                eq _canonical_json(_tool_profile());
    my %stage = map { $_->{stage} => $_ } @{$record->{stage_measurements}};
    my $source_counts = _source_counts($construction);
    for my $name (@PLANNED_STAGES) {
        my $entry = $stage{$name};
        confess "portable runtime record is missing stage '$name'\n"
            unless defined $entry;
        next if $entry->{status} =~ /rejected\z/
            || $entry->{status} eq 'not_run';
        my $expected_class = $EXTERNAL_STAGE{$name}
            ? 'external_tool' : 'fsmgen_owned';
        confess "portable runtime stage classification changed\n"
            unless $entry->{classification} eq $expected_class;
        confess "portable runtime stage command identity changed\n"
            unless _canonical_json($entry->{command_identity})
                eq _canonical_json(_command_identity(
                    $name, $construction->{specification}{level},
                ));
        my $expected_input = $name eq 'construct'
            ? {
                files => 0,
                lines => 1,
                bytes => bytes::length(_canonical_json(
                    $construction->{specification},
                )),
                objects => 1,
            }
            : $source_counts;
        confess "portable runtime stage input counts changed\n"
            unless _canonical_json($entry->{input_counts})
                eq _canonical_json($expected_input);
        confess "portable runtime backend timeout authority changed\n"
            unless _canonical_json($entry->{timeout}{backend_seconds})
                eq _canonical_json($BACKEND_TIMEOUT{$name});
    }
    return unless $record->{outcome} eq 'accepted';
    my %oracle = map { $_->{oracle_id} => $_ }
        @{$record->{correctness_oracles}};
    for my $name (@PLANNED_STAGES) {
        my $id = $name =~ /\A(?:construct|parse_validate|bridge|bind_plan)\z/
            ? "portable_runtime_${name}_canonical"
            : "portable_runtime_${name}_lifecycle_canonical";
        confess "portable runtime stage oracle '$id' is absent\n"
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
    confess "portable runtime construction oracle evidence changed\n"
        unless _canonical_json(
            $oracle{portable_runtime_construct_canonical}{evidence},
        ) eq _canonical_json($construct_evidence);
    my $stage_identity = $materialization->{stage_identities};
    my $parse_evidence = {
        workload_identity => $construction->{workload_identity},
        source_identity => _clone($materialization->{source_identity}),
        semantic_ir_sha256 => $stage_identity->{semantic_ir_sha256},
        status => 'accepted', diagnostics => [],
    };
    confess "portable runtime parse oracle evidence changed\n"
        unless _canonical_json(
            $oracle{portable_runtime_parse_validate_canonical}{evidence},
        ) eq _canonical_json($parse_evidence);
    my $bridge_evidence = {
        workload_identity => $construction->{workload_identity},
        semantic_ir_sha256 => $stage_identity->{semantic_ir_sha256},
        bridge_manifest_sha256 => $stage_identity->{bridge_manifest_sha256},
        backend_inputs_sha256 => $stage_identity->{backend_inputs_sha256},
        structural_equivalence =>
            _clone($materialization->{structural_equivalence}),
        status => 'accepted', diagnostics => [],
    };
    confess "portable runtime bridge oracle evidence changed\n"
        unless _canonical_json(
            $oracle{portable_runtime_bridge_canonical}{evidence},
        ) eq _canonical_json($bridge_evidence);
    my $bind_evidence = {
        workload_identity => $construction->{workload_identity},
        execution_ir_sha256 => $stage_identity->{execution_ir_sha256},
        plan_sha256 => $stage_identity->{plan_sha256},
        schedule_oracle => _clone($materialization->{schedule_oracle}),
        status => 'accepted', diagnostics => [],
    };
    confess "portable runtime bind-plan oracle evidence changed\n"
        unless _canonical_json(
            $oracle{portable_runtime_bind_plan_canonical}{evidence},
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
        my $evidence = $oracle{"portable_runtime_${name}_lifecycle_canonical"}
            {evidence};
        my $last = 0;
        $last++ until $state_order[$last] eq $terminal{$name};
        confess "portable-VHDL lifecycle stage evidence changed\n"
            unless ($evidence->{measurement_stage} // '') eq $name
                && ($evidence->{lifecycle_state} // '') eq $terminal{$name}
                && ($evidence->{handle}{state} // '') eq $terminal{$name}
                && _canonical_json([map { $_->{state} }
                        @{$evidence->{stage_evidence}}])
                    eq _canonical_json([@state_order[0 .. $last]])
                && !$evidence->{cleanup}{removed}
                && @{$evidence->{cleanup}{residue}} == 0;
        $lifecycle_identity //= $evidence->{lifecycle_identity};
        confess "portable-VHDL lifecycle identity changed across stages\n"
            unless $evidence->{lifecycle_identity} eq $lifecycle_identity;
        _validate_lifecycle_chain($evidence->{stage_evidence});
    }
    my $publish = $oracle{portable_runtime_publish_lifecycle_canonical}
        {evidence};
    confess "portable-VHDL terminal lifecycle evidence changed\n"
        unless $publish->{lifecycle_identity} eq $lifecycle_identity
            && $publish->{terminal_state} eq 'cleaned'
            && _canonical_json($publish->{state_order})
                eq _canonical_json(\@state_order)
            && $publish->{cleanup}{removed}
            && @{$publish->{cleanup}{residue}} == 0;
    _validate_lifecycle_chain($publish->{stage_evidence});
    my %state_evidence = map { $_->{state} => $_->{evidence} }
        @{$publish->{stage_evidence}};
    _validate_runtime_commands(
        $publish->{commands}, $record->{artifacts}{staging_identity},
        $publish->{source_set},
    );
    my %expected_command_identity = map {
        ($_ => sha256_hex(_canonical_json($publish->{commands}{$_})))
    } qw(version analyze elaborate run);
    confess "portable-VHDL command identities changed\n"
        unless _canonical_json($publish->{command_identities})
            eq _canonical_json(\%expected_command_identity)
            && $state_evidence{analyzed}{command_digest}
                eq $expected_command_identity{analyze}
            && $state_evidence{elaborated}{command_digest}
                eq $expected_command_identity{elaborate}
            && $state_evidence{ran}{command_digest}
                eq $expected_command_identity{run};
    my $expected_transcript_identity = {
        version => $state_evidence{tool_verified}{version_sha256},
        analyze => $state_evidence{analyzed}{output_sha256},
        elaborate => $state_evidence{elaborated}{output_sha256},
        run => $state_evidence{ran}{output_sha256}[0],
    };
    confess "portable-VHDL transcript identities changed\n"
        unless _canonical_json($publish->{transcript_identities})
            eq _canonical_json($expected_transcript_identity);
    confess "portable-VHDL qualified phase policy changed\n"
        unless $state_evidence{tool_verified}{version_sha256}
                eq sha256_hex(_tool_profile()->{reported_version} . "\n")
            && $state_evidence{tool_verified}{capture}{timeout_seconds} == 10
            && $state_evidence{tool_verified}{capture}{capture_limit_bytes}
                == 65_536
            && $state_evidence{analyzed}{capture}{timeout_seconds} == 120
            && $state_evidence{analyzed}{capture}{capture_limit_bytes}
                == 8_388_608
            && $state_evidence{elaborated}{capture}{timeout_seconds} == 60
            && $state_evidence{elaborated}{capture}{capture_limit_bytes}
                == 8_388_608
            && $state_evidence{ran}{captures}[0]{timeout_seconds} == 30
            && $state_evidence{ran}{captures}[0]{capture_limit_bytes}
                == 67_108_864;
    confess "portable-VHDL trace/result identities changed\n"
        unless $publish->{trace_record_count}
                == $materialization->{trace_projection}{record_count}
            && $state_evidence{trace_validated}{record_count}
                == $publish->{trace_record_count}
            && $state_evidence{trace_validated}{trace_sha256}
                eq $publish->{trace_sha256}
            && sha256_hex(_canonical_json($publish->{trace_validation}))
                eq $publish->{trace_validation_sha256}
            && $state_evidence{result_produced}{result_sha256}
                eq $publish->{result_sha256}
            && $state_evidence{result_produced}{result_status}
                eq $publish->{result_status}
            && sha256_hex(_canonical_json($publish->{normalized_result}))
                eq $publish->{normalized_result_sha256};
    my $artifact = $publish->{artifact_identity};
    confess "portable-VHDL emission identity changed during execution\n"
        unless $artifact->{emission_artifact_count}
                == $materialization->{emission_oracle}{artifact_count}
            && $artifact->{emission_artifact_bytes}
                == $materialization->{emission_oracle}{artifact_bytes}
            && $artifact->{emission_artifact_graph_sha256}
                eq $materialization->{emission_oracle}
                    {artifact_graph_sha256}
            && $artifact->{source_identity} =~ m{\Asource/[0-9a-f]{64}\z}
            && $artifact->{emission_identity}
                =~ m{\Aemission/[0-9a-f]{64}\z}
            && $artifact->{source_set_sha256}
                eq sha256_hex(_canonical_json($publish->{source_set}));
    _validate_publish_artifacts($record, $publish);
    my $cleanup = $oracle{owned_stage_absent};
    confess "portable runtime controller cleanup oracle changed\n"
        unless $cleanup && $cleanup->{stage} eq 'cleanup' && $cleanup->{ok}
            && $cleanup->{evidence}{absent}
            && @{$cleanup->{evidence}{residue}} == 0
            && $cleanup->{evidence}{staging_identity}
                eq $record->{artifacts}{staging_identity};
}

sub _validate_lifecycle_chain($chain) {
    confess "portable runtime lifecycle chain must be one non-empty array\n"
        unless ref($chain) eq 'ARRAY' && @$chain;
    my $predecessor;
    for my $index (0 .. $#$chain) {
        my $state = $chain->[$index];
        confess "portable runtime lifecycle state order changed\n"
            unless $state->{ordinal} == $index
                && ($state->{state_identity} // '')
                    =~ m{\Astate/[0-9a-f]{64}\z}
                && _canonical_json($state->{predecessor_identity})
                    eq _canonical_json($predecessor);
        $predecessor = $state->{state_identity};
    }
}

sub _validate_runtime_commands($commands, $controller_root, $source_set) {
    _exact_keys($commands, [qw(version analyze elaborate run)],
        'portable-VHDL command set');
    _safe_relative_path($controller_root);
    confess "portable-VHDL source set is not exact\n"
        unless ref($source_set) eq 'ARRAY' && @$source_set == 6;
    my $provider =
        FSM::VIAL::Backend::VHDLPortableGHDLQualification
            ->_measurement_provider_authority;
    my $binary = $provider->{binary};
    confess "portable-VHDL version command changed\n"
        unless _canonical_json($commands->{version})
            eq _canonical_json([$binary, '--version']);
    my $analyze = $commands->{analyze};
    my $elaborate = $commands->{elaborate};
    my $run = $commands->{run};
    my $lifecycle_root = "$controller_root/lifecycle";
    my $library = "$lifecycle_root/library";
    my @source = map { $_->{relpath} } @$source_set;
    my $source_prefix = "$controller_root/outputs/emit/source-graph/";
    confess "portable-VHDL source paths left their emit worker root\n"
        if grep { index($_, $source_prefix) != 0 || $_ !~ /[.]vhd\z/ }
            @source;
    my @expected_analyze = ($binary, '-a', '--std=08',
        '--work=fsmgen_vial', "--workdir=$library", @source);
    confess "portable-VHDL analysis command changed\n"
        unless _canonical_json($analyze)
            eq _canonical_json(\@expected_analyze);
    my $top = $elaborate->[-1];
    confess "portable-VHDL generated top changed\n"
        unless defined($top) && $top =~ /\A[A-Za-z][A-Za-z0-9_]*\z/;
    my @expected_elaborate = ($binary, '-e', '--std=08',
        '--work=fsmgen_vial', "--workdir=$library", $top);
    my @expected_run = ($binary, '-r', '--std=08',
        '--work=fsmgen_vial', "--workdir=$library", $top,
        '--assert-level=error');
    confess "portable-VHDL elaborate or run command changed\n"
        unless _canonical_json($elaborate)
                eq _canonical_json(\@expected_elaborate)
            && _canonical_json($run) eq _canonical_json(\@expected_run);
}

sub _validate_publish_artifacts($record, $publish) {
    my @expected = (
        ['artifact-identities.json', 'portable_vhdl_artifact_identities',
            $publish->{artifact_identity}],
        ['command-authority.json', 'portable_vhdl_command_authority',
            $publish->{commands}],
        ['lifecycle-evidence.json', 'portable_vhdl_lifecycle_evidence',
            $publish],
        ['normalized-result.json', 'portable_vhdl_normalized_result',
            $publish->{normalized_result}],
        ['trace-validation.json', 'portable_vhdl_trace_validation',
            $publish->{trace_validation}],
        ['transcript-identities.json', 'portable_vhdl_transcript_identities',
            $publish->{transcript_identities}],
    );
    my %record = map { $_->{relative_path} => $_ }
        grep { index($_->{relative_path}, 'outputs/publish/') == 0 }
            @{$record->{artifacts}{records}};
    confess "portable-VHDL publish artifact cardinality changed\n"
        unless keys(%record) == @expected;
    for my $expected (@expected) {
        my ($suffix, $kind, $value) = @$expected;
        my $path = "outputs/publish/$suffix";
        my $content = _canonical_json($value) . "\n";
        confess "portable-VHDL publish artifact '$suffix' changed\n"
            unless $record{$path}
                && $record{$path}{kind} eq $kind
                && $record{$path}{bytes} == bytes::length($content)
                && $record{$path}{lines} == 1
                && $record{$path}{sha256} eq sha256_hex($content);
    }
}

sub _canonical_pair($repo_root, $level) {
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
    confess "portable runtime structural authority changed during validation\n"
        unless _canonical_json($validated)
            eq _canonical_json($materialization)
            && $construction->{workload_identity}
                eq $materialization->{workload_identity};
    return (_clone($construction), _clone($materialization));
}

sub _command_identity($stage, $level) {
    my %external_name = (
        compile_analyze => 'ghdl_6_0_0_analyze',
        elaborate => 'ghdl_6_0_0_elaborate',
        run => 'ghdl_6_0_0_generated_runtime',
    );
    my $logical = $EXTERNAL_STAGE{$stage}
        ? $external_name{$stage}
        : "vial_scale_portable_vhdl_runtime_$stage";
    my @arguments = ($PROFILE, $level, $PRIMARY_AXIS);
    if ($stage eq 'compile_analyze') {
        @arguments = qw(--version -a --std=08 --work=fsmgen_vial
            --workdir=<lifecycle-root>/library <ordered-source-set>);
    }
    elsif ($stage eq 'elaborate') {
        @arguments = qw(-e --std=08 --work=fsmgen_vial
            --workdir=<lifecycle-root>/library <generated-top>);
    }
    elsif ($stage eq 'run') {
        @arguments = qw(-r --std=08 --work=fsmgen_vial
            --workdir=<lifecycle-root>/library <generated-top>
            --assert-level=error);
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
        provider_identity => 'qualified_ghdl_6_0_0_llvm_jit',
        arguments => [qw(--std=08 --work=fsmgen_vial)],
        thread_count => 1,
        job_count => 1,
        external_verification_tool => JSON::PP::true,
    };
}

sub _lifecycle_contract() {
    return {
        implementation => $LIFECYCLE,
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
        storage_mode => 'architecture_scale_measurement',
        containment => 'outer_worker_process_group',
        version_timeout_seconds => 10,
        analysis_timeout_seconds => 120,
        elaboration_timeout_seconds => 60,
        run_timeout_seconds => 30,
        version_capture_bytes => 65_536,
        analysis_capture_bytes => 8_388_608,
        elaboration_capture_bytes => 8_388_608,
        run_capture_bytes => 67_108_864,
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
    confess "portable runtime validation and measurement require the active repository RAM guard\n"
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
    confess "portable runtime measurement level is not selected\n"
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
    return 'portable-vhdl-runtime-measurement/'
        . sha256_hex(_canonical_json($copy));
}

sub _diagnostic($code, $message, $path, $notes = undef) {
    $message //= 'portable runtime measurement failed';
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
    confess "portable runtime measurement path is unsafe\n"
        unless defined($value) && !ref($value)
            && $value =~ m{\A[A-Za-z0-9_.][A-Za-z0-9_.\/-]*\z}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                split m{/}, $value, -1;
    return $value;
}

sub _safe_token($value) {
    confess "portable runtime measurement token is unsafe\n"
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

sub _json_text($value) {
    my $text = JSON::PP->new->ascii->canonical->pretty->encode($value);
    $text .= "\n" unless $text =~ /\n\z/;
    return $text;
}

sub _clone($value) {
    return undef unless defined $value;
    return JSON::PP->new->decode(_canonical_json($value));
}

1;
