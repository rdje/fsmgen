package FSM::VIAL::Backend::VHDLPortableGHDL;

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

use FSM::VIAL::Backend::VHDLPortableStaticValidator;

my $BACKEND_PROFILE = 'vhdl_portable_ghdl';
my $BACKEND_SCHEMA = 'fsmgen.vial_backend.vhdl_portable.v1';
my $SOURCE_MAP_SCHEMA = 'fsmgen.vial_vhdl_backend_source_map.v1';
my $BASE = 'backends/vhdl_portable_ghdl';
my $JSON = JSON::PP->new->canonical(1);

my @RESULT_KEYS = qw(
    ok status backend_profile plan_id generated_top operation_id negotiation
    backend_manifest source_map static_validation artifacts diagnostics
);
my @MANIFEST_KEYS = qw(
    schema schema_version backend_profile plan_id fixture_id generated_top
    execution_profile standard_profile tool_profile capability_evidence
    limitations migration artifacts source_order commands source_map result
    cleanup diagnostics
);
my @SOURCE_MAP_KEYS = qw(schema schema_version plan_id artifacts entries);
my @SOURCE_MAP_ENTRY_KEYS = qw(
    source_map_id generated_relpath generated_start_line generated_end_line
    generated_start_column generated_end_column generated_symbol role
    plan_paths semantic_paths bridge_fact_paths source_locations
);
my %SUPPORTED_CAPABILITY = map { $_ => 1 } qw(
    hial_vial.bridge_manifest.v1
    hial_vial.bridge_probe.equivalent_adapter_required
    hial_vial.bridge_profile.core_single_unit_v1
    hial_vial.bridge_protocol.ahb_subordinate_v1
    hial_vial.bridge_source.ial0_direct
    hial_vial.bridge_source.ial1_via_generated_ial0
    hial_vial.bridge_source.ial2_via_generated_ial1
    vial.binding.directional_representation.v1
    vial.execution_ir.v1
    vial.execution_profile.core_directed_single_clock_execution_v1
    vial.logical_time.drive_sample_react_check_v1
    vial.plan.v1
    vial.profile.core_directed_single_clock_v1
    vial.random.sha256_counter_rejection_v1
    vial.replay.v1
    vial.semantic_ir.v1
    vial.source.v1
);
my %SUPPORTED_RELATION = map { $_ => 1 } qw(
    bit_domain_identity_v1 known_value_injection_v1 enum_encoding_injection_v1
);
my %SUPPORTED_OPERATION = map { $_ => 1 } qw(
    reset drive start await parallel repeat expect scoreboard_expect
    scoreboard_check inject
);

sub result_keys($class) {
    confess __PACKAGE__ . "->result_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@RESULT_KEYS];
}

sub manifest_keys($class) {
    confess __PACKAGE__ . "->manifest_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@MANIFEST_KEYS];
}

sub source_map_keys($class) {
    confess __PACKAGE__ . "->source_map_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@SOURCE_MAP_KEYS];
}

sub source_map_entry_keys($class) {
    confess __PACKAGE__ . "->source_map_entry_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@SOURCE_MAP_ENTRY_KEYS];
}

sub emit($class, @args) {
    return _failure('VIAL_VHDL_BACKEND_INVOCATION_ERROR',
        'emit requires the exact backend class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_VHDL_BACKEND_INVOCATION_ERROR',
        'emit expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _emit($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error)
            && $error->isa('FSM::VIAL::Backend::VHDLPortableGHDL::Failure');
    return _failure('VIAL_VHDL_BACKEND_HOST_ERROR', _sanitize_exception($error), '/');
}

sub _emit($raw) {
    _require_exact_keys($raw, [qw(
        execution_ir bridge_manifest backend_inputs artifact_root backend_profile
    )], 'backend emission');
    _throw('VIAL_VHDL_BACKEND_INVOCATION_ERROR',
        'execution_ir must be an exact FSM::VIAL::ExecutionIR object', '/execution_ir')
        unless blessed($raw->{execution_ir})
            && ref($raw->{execution_ir}) eq 'FSM::VIAL::ExecutionIR';
    _throw('VIAL_VHDL_BACKEND_INVOCATION_ERROR',
        'bridge_manifest must be an exact HIAL/VIAL bridge manifest object',
        '/bridge_manifest')
        unless blessed($raw->{bridge_manifest})
            && ref($raw->{bridge_manifest}) eq 'FSM::HIAL::VIALBridge::Manifest';
    _throw('VIAL_VHDL_BACKEND_INVOCATION_ERROR',
        'backend_inputs must be one unblessed hash', '/backend_inputs')
        unless ref($raw->{backend_inputs}) eq 'HASH' && !blessed($raw->{backend_inputs});
    _throw('VIAL_VHDL_BACKEND_INVOCATION_ERROR',
        'artifact_root must be a safe repository-relative directory', '/artifact_root')
        unless _safe_relpath($raw->{artifact_root});
    _throw('VIAL_VHDL_BACKEND_UNSUPPORTED',
        "backend profile must be '$BACKEND_PROFILE'", '/backend_profile')
        unless defined($raw->{backend_profile}) && !ref($raw->{backend_profile})
            && $raw->{backend_profile} eq $BACKEND_PROFILE;

    my $execution = $raw->{execution_ir}->as_hashref;
    my $bridge = $raw->{bridge_manifest}->as_hashref;
    my $negotiation = _negotiate($execution, $bridge, $raw->{backend_inputs});
    if (@{$negotiation->{unsatisfied}}) {
        return _failure('VIAL_VHDL_BACKEND_UNSUPPORTED',
            'portable VHDL semantic negotiation rejected one or more requirements',
            '/negotiation', $negotiation);
    }

    my $fixture_slug = _vhdl_slug($execution->{fixture}{fixture_name});
    my $top = $fixture_slug . '_tb';
    my $metadata_package = $fixture_slug . '_metadata_pkg';
    my $unit = $bridge->{units}[0];
    my $entity_name = _backend_name($bridge, $unit->{unit_id}, 'entity');
    my $operation_id = 'op-' . sha256_hex(_canonical_json({
        action => 'emit_portable_checking',
        artifact_root => $raw->{artifact_root},
        backend_profile => $BACKEND_PROFILE,
        bridge_manifest_id => $bridge->{manifest_id},
        plan_id => $execution->{plan_id},
    }));

    my $probe_adapter = $fixture_slug . '_probe_adapter';
    my $types_rel = "$BASE/src/fsmgen_vial_types_pkg.vhd";
    my $runtime_rel = "$BASE/src/fsmgen_vial_runtime_pkg.vhd";
    my $metadata_rel = "$BASE/src/$metadata_package.vhd";
    my $dut_rel = "$BASE/src/dut/$raw->{backend_inputs}{dut_vhdl}[0]{artifact_name}";
    my $top_rel = "$BASE/src/$top.vhd";
    my $probe_rel = "$BASE/src/$probe_adapter.vhd";
    my $has_probe_adapter = @{$bridge->{probes}} ? 1 : 0;
    my @source_order = ($types_rel, $runtime_rel, $metadata_rel, $dut_rel,
        $top_rel, ($has_probe_adapter ? $probe_rel : ()));

    my $types = _render_types_package();
    my $runtime = _render_runtime_package();
    my $metadata = _render_metadata_package(
        package_name => $metadata_package,
        execution => $execution,
        bridge => $bridge,
    );
    my $probe = $has_probe_adapter ? _render_probe_adapter(
        adapter_name => $probe_adapter,
        top => $top,
        bridge => $bridge,
    ) : undef;
    my $fixture = _render_fixture(
        top => $top,
        entity_name => $entity_name,
        probe_adapter => $probe_adapter,
        execution => $execution,
        bridge => $bridge,
    );
    my $dut = $raw->{backend_inputs}{dut_vhdl}[0]{text};

    my @source_artifacts = (
        _artifact($dut_rel, 'vhdl_source', 'vhdl', 'generated_hial_vhdl_dut', $dut,
            [$raw->{backend_inputs}{dut_vhdl}[0]{source_id}]),
        _artifact($types_rel, 'vhdl_source', 'vhdl', 'vhdl_types_package', $types,
            ['docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md']),
        _artifact($runtime_rel, 'vhdl_source', 'vhdl', 'vhdl_runtime_package', $runtime,
            [$execution->{plan_id}]),
        _artifact($metadata_rel, 'vhdl_source', 'vhdl', 'vhdl_fixture_metadata', $metadata,
            [$execution->{plan_id}, $bridge->{manifest_id}]),
        _artifact($top_rel, 'vhdl_source', 'vhdl', 'vhdl_fixture_top', $fixture,
            [$execution->{plan_id}, $bridge->{manifest_id}]),
        ($has_probe_adapter
            ? _artifact($probe_rel, 'vhdl_source', 'vhdl', 'vhdl_probe_adapter', $probe,
                [map { $_->{probe_id} } @{$bridge->{probes}}])
            : ()),
    );
    my $source_bytes = 0;
    $source_bytes += bytes::length($_->{content}) for @source_artifacts;
    _throw('VIAL_VHDL_BACKEND_LIMIT_EXCEEDED',
        'generated VHDL exceeds the 16 MiB backend cap', '/artifacts')
        if $source_bytes > 16_777_216;

    my $static = FSM::VIAL::Backend::VHDLPortableStaticValidator->validate({
        backend_profile => $BACKEND_PROFILE,
        artifacts => \@source_artifacts,
    });
    _throw('VIAL_VHDL_BACKEND_STATIC_VALIDATION_ERROR',
        'generated portable VHDL semantics failed structural validation', '/static_validation')
        unless $static->{ok};

    my $source_map = {
        schema => $SOURCE_MAP_SCHEMA,
        schema_version => 1,
        plan_id => $execution->{plan_id},
        artifacts => [map { _artifact_ref($_) }
            sort { $a->{relpath} cmp $b->{relpath} } @source_artifacts],
        entries => _source_map_entries(
            execution => $execution,
            bridge => $bridge,
            source_artifacts => \@source_artifacts,
            top_rel => $top_rel,
            metadata_rel => $metadata_rel,
            runtime_rel => $runtime_rel,
            types_rel => $types_rel,
            dut_rel => $dut_rel,
            probe_rel => $has_probe_adapter ? $probe_rel : undef,
            top => $top,
            metadata_package => $metadata_package,
            entity_name => $entity_name,
            probe_adapter => $probe_adapter,
        ),
    };

    my $work_rel = ".artifacts/tmp/vial/$operation_id/work/$BACKEND_PROFILE";
    my $input_rel = "$work_rel/input";
    my @work_sources = map { "$input_rel/$_" } @source_order;
    my $analyze = _command_record(
        logical_executable => 'ghdl',
        working_directory => '.',
        arguments => ['-a', '--std=08', '--work=fsmgen_vial',
            "--workdir=$work_rel/library", @work_sources],
        inputs => \@work_sources,
        expected_outputs => ["$work_rel/library/fsmgen_vial-obj08.cf"],
    );
    my $elaborate = _command_record(
        logical_executable => 'ghdl',
        working_directory => '.',
        arguments => ['-e', '--std=08', '--work=fsmgen_vial',
            "--workdir=$work_rel/library", $top],
        inputs => ["$work_rel/library/fsmgen_vial-obj08.cf"],
        expected_outputs => ["$work_rel/elaborated/$top"],
    );
    my $run = _command_record(
        logical_executable => 'ghdl',
        working_directory => '.',
        arguments => ['-r', '--std=08', '--work=fsmgen_vial',
            "--workdir=$work_rel/library", $top, '--assert-level=error'],
        inputs => ["$work_rel/library/fsmgen_vial-obj08.cf"],
        expected_outputs => [
            "$raw->{artifact_root}/$BASE/evidence/runtime-trace.jsonl",
        ],
    );
    my $source_order_record = {
        schema => 'fsmgen.vial_vhdl_source_order.v1',
        schema_version => 1,
        library => 'fsmgen_vial',
        standard => '08',
        sources => \@source_order,
        order_digest => sha256_hex(join("\n", @source_order) . "\n"),
    };
    my $tool_profile = {
        schema => 'fsmgen.vial_backend_tool_profile.v1',
        schema_version => 1,
        selection_status => 'selected_not_executed',
        tool_name => 'ghdl',
        qualified_version => '6.0.0',
        qualified_version_output => 'not_observed_exact_6_0_0_unavailable',
        target_language => 'VHDL',
        language_standard => 'IEEE 1076-2008',
        standard_option => '--std=08',
        work_library => 'fsmgen_vial',
        methodology => 'provider_free_vhdl_2008',
        provider_library => 'none',
        execution_evidence => JSON::PP::false,
    };

    my @support_artifacts = (
        _artifact("$BASE/backend-source-map.json", 'source_map', 'json',
            'backend_source_map', _json_text($source_map), [$execution->{plan_id}]),
        _artifact("$BASE/commands/analyze-command.json", 'command_record', 'json',
            'analyze_command', _json_text($analyze), [$execution->{plan_id}]),
        _artifact("$BASE/commands/elaborate-command.json", 'command_record', 'json',
            'elaborate_command', _json_text($elaborate), [$execution->{plan_id}]),
        _artifact("$BASE/commands/run-command.json", 'command_record', 'json',
            'run_command', _json_text($run), [$execution->{plan_id}]),
        _artifact("$BASE/evidence/source-order.json", 'source_order', 'json',
            'ordered_vhdl_sources', _json_text($source_order_record), [$execution->{plan_id}]),
        _artifact("$BASE/evidence/static-validation.json", 'static_validation', 'json',
            'vhdl_static_validation', _json_text($static), [$execution->{plan_id}]),
        _artifact("$BASE/evidence/tool-profile.json", 'tool_profile', 'json',
            'selected_tool_profile', _json_text($tool_profile),
            ['docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md']),
    );
    my @referenced = sort { $a->{relpath} cmp $b->{relpath} }
        map { _artifact_ref($_) } (@source_artifacts, @support_artifacts);
    my $manifest = {
        schema => $BACKEND_SCHEMA,
        schema_version => 1,
        backend_profile => $BACKEND_PROFILE,
        plan_id => $execution->{plan_id},
        fixture_id => $execution->{fixture}{fixture_id},
        generated_top => $top,
        execution_profile => $execution->{profile},
        standard_profile => {
            language => 'VHDL',
            standard => 'IEEE 1076-2008',
            standard_option => '--std=08',
            methodology => 'provider_free',
        },
        tool_profile => $tool_profile,
        capability_evidence => {
            hial_vhdl_input => 'passed_deterministic_generation',
            emission => 'passed_portable_semantics',
            static_validation => 'passed_structural_semantics',
            source_map => 'passed_portable_semantics_scope',
            review_gallery => 'byte_locked',
            drivers => 'passed_emission_only',
            samplers => 'passed_emission_only',
            scheduler => 'passed_emission_only',
            scenarios => 'passed_emission_only',
            models => 'passed_emission_only',
            scoreboards => 'passed_bounded_emission_only',
            coverage => 'passed_counter_emission_only',
            faults => 'passed_substitution_emission_only',
            procedural_checks => 'passed_emission_only',
            diagnostic_records => 'passed_emission_only',
            trace => 'passed_closed_projection_emission_only',
            result_projection => 'passed_manifest_v1_emission_only',
            probe_adapters => $has_probe_adapter
                ? 'passed_declared_external_name_emission_only'
                : 'not_required',
            provider_fetch => 'not_performed',
            analysis => 'not_run',
            elaboration => 'not_run',
            runtime => 'not_run',
            result => 'projection_emitted_not_produced',
            parity => 'not_evaluated',
            psl => 'not_emitted',
            full_vhdl_2008 => 'not_claimed',
            product_support => 'not_claimed',
        },
        limitations => [qw(
            portable_checking_emission_only single_unit single_domain
            bounded_scoreboard_capacity_four bounded_coverage_counters
            bounded_substitution_faults procedural_properties_only
            result_projection_not_runtime_evidence no_psl no_provider_library
            no_analysis_evidence no_elaboration_evidence no_runtime_evidence
            no_parity_evidence
        )],
        migration => {
            legacy_surface => 'vhdl_observation_package_skeleton',
            legacy_state => 'unchanged_not_consumed',
            successor_profile => $BACKEND_PROFILE,
            migration_kind => 'parallel_versioned_surface',
        },
        artifacts => \@referenced,
        source_order => _clone($source_order_record),
        commands => [
            _command_ref("$BASE/commands/analyze-command.json", $analyze),
            _command_ref("$BASE/commands/elaborate-command.json", $elaborate),
            _command_ref("$BASE/commands/run-command.json", $run),
        ],
        source_map => {
            relpath => "$BASE/backend-source-map.json",
            schema => $SOURCE_MAP_SCHEMA,
            entry_count => scalar(@{$source_map->{entries}}),
            sha256 => sha256_hex(_json_text($source_map)),
        },
        result => {
            status => 'projection_emitted_not_produced',
            schema => 'fsmgen.verification_result_manifest.v1',
            relpath => undef,
        },
        cleanup => {
            staging_identity => ".artifacts/tmp/vial/$operation_id",
            state => 'not_created',
        },
        diagnostics => [],
    };
    my @all = (@source_artifacts, @support_artifacts,
        _artifact("$BASE/backend-manifest.json", 'backend_manifest', 'json',
            'backend_manifest', _json_text($manifest), [$execution->{plan_id}]));
    my @artifacts = sort { $a->{relpath} cmp $b->{relpath} } @all;
    _throw('VIAL_VHDL_BACKEND_LIMIT_EXCEEDED',
        'portable VHDL semantics emitted an unexpected artifact count', '/artifacts')
        unless @artifacts == 13 + $has_probe_adapter;

    return _result({
        ok => JSON::PP::true,
        status => 'emitted_unqualified_portable_checking',
        backend_profile => $BACKEND_PROFILE,
        plan_id => $execution->{plan_id},
        generated_top => $top,
        operation_id => $operation_id,
        negotiation => $negotiation,
        backend_manifest => $manifest,
        source_map => $source_map,
        static_validation => $static,
        artifacts => \@artifacts,
        diagnostics => [],
    });
}

sub _negotiate($execution, $bridge, $backend_inputs) {
    my (@required, @satisfied, @unsatisfied, @native_only, @limitations);
    push @required, qw(
        fsmgen.vial_execution_ir.v1
        core_directed_single_clock_execution_v1
        fsmgen.hial_vial_bridge_manifest.v1
        one_bound_hial_unit_v1
        one_selected_clock_domain_v1
        deterministic_hial_vhdl_source_v1
        declared_vhdl_entity_and_port_bindings_v1
        typed_four_state_drive_sample_v1
        one_inactive_edge_scheduler_v1
        exact_execution_rank_metadata_v1
        bounded_scenario_fiber_state_v1
        deterministic_event_counter_models_v1
        declared_vhdl_probe_adapter_v1
    );
    push @unsatisfied, 'execution schema must be fsmgen.vial_execution_ir.v1'
        unless ($execution->{schema} // '') eq 'fsmgen.vial_execution_ir.v1';
    push @unsatisfied, 'execution profile must be core_directed_single_clock_execution_v1'
        unless ($execution->{profile} // '') eq 'core_directed_single_clock_execution_v1';
    push @unsatisfied, 'bridge schema must be fsmgen.hial_vial_bridge_manifest.v1'
        unless ($bridge->{schema} // '') eq 'fsmgen.hial_vial_bridge_manifest.v1';
    push @unsatisfied, 'exactly one bound HIAL unit is required'
        unless ref($bridge->{units}) eq 'ARRAY' && @{$bridge->{units}} == 1;
    push @unsatisfied, 'exactly one selected execution domain is required'
        unless ref($execution->{domains}) eq 'ARRAY' && @{$execution->{domains}} == 1;
    push @unsatisfied, 'native extensions are unsupported by portable VHDL semantics'
        unless ref($execution->{native_extensions}) eq 'ARRAY'
            && !@{$execution->{native_extensions}};

    for my $entry (@{$execution->{capability_ledger} || []}) {
        my $capability = $entry->{capability_id} // '';
        push @required, $capability;
        if (($entry->{portable_class} // '') eq 'native_only') {
            push @native_only, $capability;
            push @unsatisfied, "native-only-capability:$capability";
        }
        elsif (!$SUPPORTED_CAPABILITY{$capability}) {
            push @unsatisfied, "capability:$capability";
        }
        elsif (($entry->{classification} // '') eq 'satisfied_by_execution_profile') {
            next;
        }
        elsif ($capability eq 'hial_vial.bridge_probe.equivalent_adapter_required'
            && _probe_bindings_are_exact($execution, $bridge)) {
            next;
        }
        else {
            push @unsatisfied, "capability-state:$capability";
        }
    }

    for my $relation (_relations($execution)) {
        push @unsatisfied, "relation:$relation->{relation_id}"
            unless $SUPPORTED_RELATION{$relation->{kind} // ''};
        push @unsatisfied, "width:$relation->{relation_id}"
            unless defined($relation->{width}) && !ref($relation->{width})
                && $relation->{width} =~ /\A[0-9]+\z/
                && $relation->{width} >= 1 && $relation->{width} <= 65_536;
        for my $key (qw(carrier_state_domain semantic_state_domain)) {
            next unless exists $relation->{$key};
            push @unsatisfied, "nine-state-or-unknown-domain:$relation->{relation_id}:$key"
                unless ($relation->{$key} // '') eq 'two_state'
                    || ($relation->{$key} // '') eq 'four_state';
        }
    }

    my @operation = @{$execution->{operation_graph}{operations} || []};
    push @unsatisfied, 'operation graph must be nonempty and bounded to 65536 operations'
        unless @operation && @operation <= 65_536;
    for my $operation (@operation) {
        push @unsatisfied, "operation:$operation->{kind}"
            unless $SUPPORTED_OPERATION{$operation->{kind} // ''};
        push @unsatisfied, "operation-rank:$operation->{operation_id}"
            unless defined($operation->{static_rank}) && !ref($operation->{static_rank})
                && $operation->{static_rank} =~ /\A[0-9]+\z/;
        push @unsatisfied, "await-shape:$operation->{operation_id}"
            if ($operation->{kind} // '') eq 'await'
                && !_await_shape_supported($operation, $execution);
    }

    my @scenario = @{$execution->{scenarios} || []};
    push @unsatisfied, 'scenario set must contain between 1 and 1024 scenarios'
        unless @scenario && @scenario <= 1_024;
    my $selected_domain = ref($execution->{domains}) eq 'ARRAY'
        && @{$execution->{domains}} == 1 ? $execution->{domains}[0] : undef;
    my $selected_domain_id = ref($selected_domain) eq 'HASH'
        ? ($selected_domain->{semantic_id} // '') : '';
    if (ref($selected_domain) eq 'HASH') {
        push @unsatisfied, 'selected domain active edge must be rising or falling'
            unless ($selected_domain->{active_edge} // '') eq 'rising'
                || ($selected_domain->{active_edge} // '') eq 'falling';
        push @unsatisfied, 'selected domain reset polarity must be active_low or active_high'
            unless ($selected_domain->{reset_polarity} // '') eq 'active_low'
                || ($selected_domain->{reset_polarity} // '') eq 'active_high';
    }
    my %fiber_id;
    for my $scenario (@scenario) {
        my @scenario_operation = grep {
            ($_->{scenario_id} // '') eq ($scenario->{scenario_id} // '')
        } @operation;
        my @reset = grep { ($_->{kind} // '') eq 'reset' } @scenario_operation;
        my @start = grep { ($_->{kind} // '') eq 'start' } @scenario_operation;
        push @unsatisfied, "scenario-reset:$scenario->{scenario_id}"
            unless @reset == 1 && _positive_reset_cycles($reset[0]);
        push @unsatisfied, "scenario-start:$scenario->{scenario_id}"
            unless @start == 1;
        push @unsatisfied, "scenario-domain:$scenario->{scenario_id}"
            unless ($scenario->{domain_id} // '') eq $selected_domain_id;
        push @unsatisfied, "scenario-timeout:$scenario->{scenario_id}"
            unless defined($scenario->{timeout_cycles}) && !ref($scenario->{timeout_cycles})
                && $scenario->{timeout_cycles} =~ /\A[0-9]+\z/
                && $scenario->{timeout_cycles} >= 1;
        my @fiber = @{$scenario->{fibers} || []};
        push @unsatisfied, "scenario-fibers:$scenario->{scenario_id}"
            unless @fiber && @fiber <= 4_096;
        for my $fiber (@fiber) {
            push @unsatisfied, "duplicate-fiber:$fiber->{fiber_id}"
                if $fiber_id{$fiber->{fiber_id}}++;
        }
        my @parallel = grep { ($_->{kind} // '') eq 'parallel' } @scenario_operation;
        push @unsatisfied, "parallel-count:$scenario->{scenario_id}"
            if @parallel > 1;
    }

    push @unsatisfied, 'exactly one typed transaction is required by the portable AHB profile'
        unless ref($execution->{transactions}) eq 'ARRAY'
            && @{$execution->{transactions}} == 1;
    push @unsatisfied, 'exactly one bridge transaction is required by the portable AHB profile'
        unless ref($bridge->{transactions}) eq 'ARRAY'
            && @{$bridge->{transactions}} == 1
            && ref($bridge->{transactions}[0]{fields}) eq 'ARRAY';

    my %role_count;
    $role_count{$_->{role} // ''}++ for @{$bridge->{endpoints} || []};
    for my $role (qw(clock reset select ready_in ready_out transfer response)) {
        push @unsatisfied, "endpoint-role:$role"
            unless ($role_count{$role} // 0) == 1;
    }
    my @event_name = sort map { $_->{name} // '' } @{$execution->{events} || []};
    my @required_event = sort qw(requested accepted captured held completed error);
    push @unsatisfied, 'portable AHB event set must be requested/accepted/captured/held/completed/error'
        unless _canonical_json(\@event_name) eq _canonical_json(\@required_event);
    for my $event (@{$execution->{events} || []}) {
        push @unsatisfied, "asynchronous-event:$event->{event_id}"
            unless ($event->{phase} // '') eq 'drive'
                || ($event->{phase} // '') eq 'sample';
    }
    for my $model (@{$execution->{models} || []}) {
        my $event_id = ref($model->{bindings}) eq 'ARRAY' && @{$model->{bindings}} == 1
            ? $model->{bindings}[0]{value}{event_id} : '';
        push @unsatisfied, "model-shape:$model->{instance_id}"
            unless ($model->{definition}{name} // '') eq 'event_counter'
                && ($event_id // '') =~ /::event::(?:accepted|completed)\z/;
    }

    _walk_values($execution, sub ($value, $path) {
        if (ref($value) eq 'HASH' && exists($value->{state_domain})) {
            push @unsatisfied, "nine-state-value:$path"
                unless ($value->{state_domain} // '') eq 'two_state'
                    || ($value->{state_domain} // '') eq 'four_state';
        }
        return unless ref($value) eq 'HASH' && ($value->{kind} // '') eq 'scalar'
            && exists($value->{value_hex}) && exists($value->{known_hex})
            && exists($value->{z_hex});
        push @unsatisfied, "scalar-shape:$path"
            unless _scalar_value_shape_is_valid($value);
    });

    my $inputs_ok = eval {
        _require_exact_keys($backend_inputs, [qw(dut_systemverilog dut_vhdl)],
            'backend inputs');
        confess 'exactly one deterministic VHDL DUT source is required'
            unless ref($backend_inputs->{dut_vhdl}) eq 'ARRAY'
                && @{$backend_inputs->{dut_vhdl}} == 1;
        my $dut = $backend_inputs->{dut_vhdl}[0];
        confess 'VHDL DUT source must be one unblessed hash'
            unless ref($dut) eq 'HASH' && !blessed($dut);
        _require_exact_keys($dut, [qw(
            unit_id entity_name artifact_name source_id text content_sha256 byte_length
        )], 'VHDL DUT source');
        confess 'VHDL DUT source identity, text, digest, or byte count is malformed'
            unless _vhdl_identifier($dut->{entity_name})
                && $dut->{unit_id} eq "unit/$dut->{entity_name}"
                && $dut->{artifact_name} eq "$dut->{entity_name}.vhd"
                && defined($dut->{text}) && !ref($dut->{text})
                && sha256_hex($dut->{text}) eq $dut->{content_sha256}
                && bytes::length($dut->{text}) == $dut->{byte_length};
        1;
    };
    push @unsatisfied, 'one exact deterministic HIAL VHDL DUT source is required'
        unless $inputs_ok;

    if (ref($bridge->{units}) eq 'ARRAY' && @{$bridge->{units}} == 1) {
        my $unit_id = $bridge->{units}[0]{unit_id};
        my @unit_binding = grep {
            ($_->{target_language} // '') eq 'vhdl'
                && ($_->{semantic_id} // '') eq $unit_id
                && ($_->{target_kind} // '') eq 'entity'
                && ($_->{status} // '') eq 'declared'
                && _vhdl_identifier($_->{target_name})
        } @{$bridge->{backend_bindings} || []};
        push @unsatisfied, "unit '$unit_id' lacks one declared VHDL entity binding"
            unless @unit_binding == 1;
        if ($inputs_ok) {
            push @unsatisfied, "VHDL DUT input does not match bound unit '$unit_id'"
                unless $backend_inputs->{dut_vhdl}[0]{unit_id} eq $unit_id
                    && $backend_inputs->{dut_vhdl}[0]{entity_name}
                        eq $unit_binding[0]{target_name};
        }
    }
    my %folded_name;
    for my $endpoint (@{$bridge->{endpoints} || []}) {
        my @binding = grep {
            ($_->{target_language} // '') eq 'vhdl'
                && ($_->{semantic_id} // '') eq $endpoint->{endpoint_id}
                && ($_->{target_kind} // '') eq 'port'
                && ($_->{status} // '') eq 'declared'
                && _vhdl_identifier($_->{target_name})
        } @{$bridge->{backend_bindings} || []};
        if (@binding != 1) {
            push @unsatisfied,
                "endpoint '$endpoint->{endpoint_id}' lacks one declared VHDL port binding";
            next;
        }
        my $folded = lc($binding[0]{target_name});
        push @unsatisfied, "case-insensitive VHDL port collision at '$binding[0]{target_name}'"
            if $folded_name{$folded}++;
    }
    for my $probe (@{$bridge->{probes} || []}) {
        my @binding = grep {
            ($_->{target_language} // '') eq 'vhdl'
                && ($_->{semantic_id} // '') eq $probe->{probe_id}
                && ($_->{target_kind} // '') eq 'probe_adapter'
                && ($_->{status} // '') eq 'adapter_required'
                && _vhdl_identifier($_->{target_name})
        } @{$bridge->{backend_bindings} || []};
        push @unsatisfied, "probe '$probe->{probe_id}' lacks one declared VHDL adapter binding"
            unless @binding == 1;
    }

    @required = sort _unique(@required);
    @satisfied = @required unless @unsatisfied;
    @limitations = qw(
        portable_checking_emission_only provider_free_vhdl_2008
        one_unit one_clock_domain asynchronous_reset_is_dut_interface_only
        analysis_not_run elaboration_not_run runtime_not_run result_projection_only
        parity_not_evaluated psl_not_emitted support_not_claimed
    );
    return {
        negotiation_scope => 'portable_vhdl_semantics_v1',
        required => \@required,
        satisfied => \@satisfied,
        unsatisfied => [sort _unique(@unsatisfied)],
        native_only => [sort _unique(@native_only)],
        deferred => [qw(analysis elaboration runtime parity psl osvvm support)],
        limitations => \@limitations,
    };
}

sub _render_types_package() {
    return <<'VHDL';
library ieee;
use ieee.std_logic_1164.all;

package fsmgen_vial_types_pkg is
  type vial_value_symbol_t is (
    VIAL_VALUE_0,
    VIAL_VALUE_1,
    VIAL_VALUE_X,
    VIAL_VALUE_Z
  );

  type vial_phase_t is (
    VIAL_DRIVE_PHASE,
    VIAL_SAMPLE_PHASE,
    VIAL_REACT_PHASE,
    VIAL_CHECK_PHASE
  );

  type vial_observation_t is record
    original_symbol : std_logic;
    normalized_value : vial_value_symbol_t;
  end record;

  type vial_value_vector_t is array (natural range <>) of vial_value_symbol_t;
  type vial_observation_vector_t is array (natural range <>) of vial_observation_t;

  function normalize_vial_value(value : std_logic) return vial_value_symbol_t;
  function to_vial_value_vector(value : std_logic_vector) return vial_value_vector_t;
  function to_strong_std_logic(value : vial_value_symbol_t) return std_logic;
  function observe_vial_value(value : std_logic) return vial_observation_t;
  function observe_vial_vector(value : std_logic_vector) return vial_observation_vector_t;
  function vial_is_known_zero(value : vial_observation_t) return boolean;
  function vial_is_known_one(value : vial_observation_t) return boolean;
  function vial_is_known(value : vial_observation_t) return boolean;
  function vial_matches(
    actual : vial_observation_vector_t;
    expected : vial_value_vector_t
  ) return boolean;
  procedure drive_vial_value(
    signal target : out std_logic;
    constant value : in vial_value_symbol_t
  );
  procedure drive_vial_vector(
    signal target : out std_logic_vector;
    constant value : in vial_value_vector_t
  );
end package fsmgen_vial_types_pkg;

package body fsmgen_vial_types_pkg is
  function normalize_vial_value(value : std_logic) return vial_value_symbol_t is
  begin
    case value is
      when '0' => return VIAL_VALUE_0;
      when '1' => return VIAL_VALUE_1;
      when 'Z' => return VIAL_VALUE_Z;
      when 'L' => return VIAL_VALUE_0;
      when 'H' => return VIAL_VALUE_1;
      when others => return VIAL_VALUE_X;
    end case;
  end function normalize_vial_value;

  function observe_vial_value(value : std_logic) return vial_observation_t is
  begin
    return (
      original_symbol => value,
      normalized_value => normalize_vial_value(value)
    );
  end function observe_vial_value;

  function to_vial_value_vector(value : std_logic_vector) return vial_value_vector_t is
    variable result : vial_value_vector_t(value'range);
  begin
    for index in value'range loop
      result(index) := normalize_vial_value(value(index));
    end loop;
    return result;
  end function to_vial_value_vector;

  function to_strong_std_logic(value : vial_value_symbol_t) return std_logic is
  begin
    case value is
      when VIAL_VALUE_0 => return '0';
      when VIAL_VALUE_1 => return '1';
      when VIAL_VALUE_X => return 'X';
      when VIAL_VALUE_Z => return 'Z';
    end case;
  end function to_strong_std_logic;

  function observe_vial_vector(value : std_logic_vector) return vial_observation_vector_t is
    variable result : vial_observation_vector_t(value'range);
  begin
    for index in value'range loop
      result(index) := observe_vial_value(value(index));
    end loop;
    return result;
  end function observe_vial_vector;

  function vial_is_known_zero(value : vial_observation_t) return boolean is
  begin
    return value.normalized_value = VIAL_VALUE_0;
  end function vial_is_known_zero;

  function vial_is_known_one(value : vial_observation_t) return boolean is
  begin
    return value.normalized_value = VIAL_VALUE_1;
  end function vial_is_known_one;

  function vial_is_known(value : vial_observation_t) return boolean is
  begin
    return value.normalized_value = VIAL_VALUE_0
      or value.normalized_value = VIAL_VALUE_1;
  end function vial_is_known;

  function vial_matches(
    actual : vial_observation_vector_t;
    expected : vial_value_vector_t
  ) return boolean is
  begin
    if actual'length /= expected'length then
      return false;
    end if;
    for index in actual'range loop
      if actual(index).normalized_value /= expected(index) then
        return false;
      end if;
    end loop;
    return true;
  end function vial_matches;

  procedure drive_vial_value(
    signal target : out std_logic;
    constant value : in vial_value_symbol_t
  ) is
  begin
    target <= to_strong_std_logic(value);
  end procedure drive_vial_value;

  procedure drive_vial_vector(
    signal target : out std_logic_vector;
    constant value : in vial_value_vector_t
  ) is
  begin
    assert target'length = value'length
      report "FSMGen VIAL driver width mismatch"
      severity failure;
    for index in target'range loop
      target(index) <= to_strong_std_logic(value(index));
    end loop;
  end procedure drive_vial_vector;
end package body fsmgen_vial_types_pkg;
VHDL
}

sub _render_runtime_package() {
    return <<'VHDL';
library ieee;
use ieee.std_logic_1164.all;

use work.fsmgen_vial_types_pkg.all;

package fsmgen_vial_runtime_pkg is
  constant FSMGEN_VIAL_RUNTIME_SCHEMA : string := "fsmgen.vial_vhdl_runtime.v3";

  type vial_logical_time_t is record
    cycle : natural;
    phase : vial_phase_t;
    static_rank : natural;
    local_index : natural;
  end record;

  type vial_runtime_state_t is (
    VIAL_RUNTIME_CONSTRUCTED,
    VIAL_RUNTIME_READY,
    VIAL_RUNTIME_RUNNING,
    VIAL_RUNTIME_COMPLETED,
    VIAL_RUNTIME_FINALIZED
  );

  type vial_fiber_status_t is (
    VIAL_FIBER_DORMANT,
    VIAL_FIBER_RUNNING,
    VIAL_FIBER_COMPLETED,
    VIAL_FIBER_CANCELLED,
    VIAL_FIBER_TIMED_OUT
  );

  type vial_scenario_status_t is (
    VIAL_SCENARIO_DORMANT,
    VIAL_SCENARIO_RUNNING,
    VIAL_SCENARIO_STIMULUS_COMPLETED,
    VIAL_SCENARIO_TIMED_OUT
  );

  type vial_check_outcome_t is (
    VIAL_CHECK_PENDING,
    VIAL_CHECK_PASSED,
    VIAL_CHECK_FAILED,
    VIAL_CHECK_UNKNOWN
  );

  type vial_diagnostic_record_t is record
    code : string(1 to 32);
    code_length : natural;
    severity : string(1 to 8);
    logical_time : vial_logical_time_t;
    outcome : vial_check_outcome_t;
  end record;

  type vial_diagnostic_array_t is array (natural range <>) of vial_diagnostic_record_t;

  type vial_scoreboard_state_t is record
    expected_depth : natural;
    actual_depth : natural;
    comparisons : natural;
    mismatches : natural;
    overflowed : boolean;
  end record;

  type vial_coverage_counter_t is record
    not_stalled : natural;
    stalled : natural;
  end record;

  type vial_fault_state_t is record
    armed : boolean;
    remaining_cycles : natural;
    applications : natural;
  end record;

  constant VIAL_SCOREBOARD_CAPACITY : positive := 4;
  constant VIAL_DIAGNOSTIC_CAPACITY : positive := 64;
  constant VIAL_TRACE_SCHEMA : string := "fsmgen.vial_vhdl_runtime_trace.v1";
  constant VIAL_RESULT_SCHEMA : string := "fsmgen.verification_result_manifest.v1";

  constant VIAL_INITIAL_LOGICAL_TIME : vial_logical_time_t := (
    cycle => 0,
    phase => VIAL_DRIVE_PHASE,
    static_rank => 0,
    local_index => 0
  );
end package fsmgen_vial_runtime_pkg;
VHDL
}

sub _render_metadata_package(%arg) {
    my $execution = $arg{execution};
    my $bridge = $arg{bridge};
    my $domain = $execution->{domains}[0];
    my @fiber = map { @{$_->{fibers}} } @{$execution->{scenarios}};
    my @line = (
        'library ieee;',
        'use ieee.std_logic_1164.all;',
        'use std.textio.all;',
        '',
        "package $arg{package_name} is",
        '  constant VIAL_PLAN_ID : string := "' . _vhdl_string($execution->{plan_id}) . '";',
        '  constant VIAL_FIXTURE_ID : string := "' . _vhdl_string($execution->{fixture}{fixture_id}) . '";',
        '  constant VIAL_EXECUTION_PROFILE : string := "' . _vhdl_string($execution->{profile}) . '";',
        '  constant VIAL_BRIDGE_MANIFEST_ID : string := "' . _vhdl_string($bridge->{manifest_id}) . '";',
        '  constant VIAL_UNIT_ID : string := "' . _vhdl_string($bridge->{units}[0]{unit_id}) . '";',
        '  constant VIAL_DOMAIN_ID : string := "' . _vhdl_string($domain->{domain_id}) . '";',
        '  constant VIAL_ACTIVE_EDGE : string := "' . _vhdl_string($domain->{active_edge}) . '";',
        '  constant VIAL_INACTIVE_EDGE : string := "'
            . ($domain->{active_edge} eq 'rising' ? 'falling' : 'rising') . '";',
        '  constant VIAL_RESET_KIND : string := "' . _vhdl_string($domain->{reset_kind}) . '";',
        '  constant VIAL_RESET_POLARITY : string := "' . _vhdl_string($domain->{reset_polarity}) . '";',
        '  constant VIAL_SCHEDULER_COUNT : natural := 1;',
        '  constant VIAL_OPERATION_COUNT : natural := '
            . scalar(@{$execution->{operation_graph}{operations}}) . ';',
        '  constant VIAL_SCENARIO_COUNT : natural := '
            . scalar(@{$execution->{scenarios}}) . ';',
        '  constant VIAL_FIBER_COUNT : natural := ' . scalar(@fiber) . ';',
        '  constant VIAL_MODEL_COUNT : natural := ' . scalar(@{$execution->{models}}) . ';',
        '',
    );
    for my $index (0 .. $#{$execution->{operation_graph}{operations}}) {
        my $operation = $execution->{operation_graph}{operations}[$index];
        my $tag = sprintf('%02d', $index);
        push @line,
            "  -- VIAL operation $tag: $operation->{kind} at static rank $operation->{static_rank}",
            "  constant VIAL_OPERATION_${tag}_ID : string := \""
                . _vhdl_string($operation->{operation_id}) . '";',
            "  constant VIAL_OPERATION_${tag}_KIND : string := \""
                . _vhdl_string($operation->{kind}) . '";',
            "  constant VIAL_OPERATION_${tag}_STATIC_RANK : natural := "
                . $operation->{static_rank} . ';',
            "  constant VIAL_OPERATION_${tag}_FIBER_ID : string := \""
                . _vhdl_string($operation->{fiber_id}) . '";',
            '';
    }
    for my $index (0 .. $#{$execution->{scenarios}}) {
        my $scenario = $execution->{scenarios}[$index];
        my $tag = sprintf('%02d', $index);
        push @line,
            "  -- VIAL scenario $tag: " . _vhdl_string($scenario->{name}),
            "  constant VIAL_SCENARIO_${tag}_ID : string := \""
                . _vhdl_string($scenario->{scenario_id}) . '";',
            "  constant VIAL_SCENARIO_${tag}_TIMEOUT_CYCLES : natural := "
                . $scenario->{timeout_cycles} . ';',
            "  constant VIAL_SCENARIO_${tag}_FIBER_COUNT : natural := "
                . scalar(@{$scenario->{fibers}}) . ';',
            '';
    }
    for my $index (0 .. $#fiber) {
        my $item = $fiber[$index];
        my $tag = sprintf('%02d', $index);
        push @line,
            "  -- VIAL fiber $tag: " . _vhdl_string($item->{name}),
            "  constant VIAL_FIBER_${tag}_ID : string := \""
                . _vhdl_string($item->{fiber_id}) . '";',
            "  constant VIAL_FIBER_${tag}_CANCEL_SCOPE_ID : string := \""
                . _vhdl_string($item->{cancel_scope_id}) . '";',
            '';
    }
    for my $index (0 .. $#{$execution->{models}}) {
        my $model = $execution->{models}[$index];
        my $tag = sprintf('%02d', $index);
        my $event = $model->{bindings}[0]{value}{event_id};
        push @line,
            "  -- VIAL model $tag: " . _vhdl_string($model->{definition}{name}),
            "  constant VIAL_MODEL_${tag}_INSTANCE_ID : string := \""
                . _vhdl_string($model->{instance_id}) . '";',
            "  constant VIAL_MODEL_${tag}_TRIGGER_EVENT_ID : string := \""
                . _vhdl_string($event) . '";',
            '';
    }
    push @line, "end package $arg{package_name};", '';
    return join("\n", @line);
}

sub _render_probe_adapter(%arg) {
    my $bridge = $arg{bridge};
    my %type = map { $_->{type_id} => $_ } @{$bridge->{types}};
    my %binding = map {
        ($_->{target_language} // '') eq 'vhdl'
            && ($_->{target_kind} // '') eq 'probe_adapter'
            && ($_->{status} // '') eq 'adapter_required'
            ? ($_->{semantic_id} => $_) : ()
    } @{$bridge->{backend_bindings}};
    my @line = (
        'library ieee;',
        'use ieee.std_logic_1164.all;',
        '',
        "entity $arg{adapter_name} is",
        '  port (',
    );
    my @port;
    for my $probe (@{$bridge->{probes}}) {
        my $width = $type{$probe->{type_id}}{width};
        my $symbol = 'vial_probe_' . _vhdl_slug($probe->{name});
        my $kind = $width == 1
            ? 'std_logic'
            : 'std_logic_vector(' . ($width - 1) . ' downto 0)';
        push @port, "    $symbol : out $kind";
    }
    for my $index (0 .. $#port) {
        push @line, $port[$index] . ($index == $#port ? '' : ';');
    }
    push @line,
        '  );',
        "end entity $arg{adapter_name};",
        '',
        "architecture declared_external_names of $arg{adapter_name} is";
    for my $probe (@{$bridge->{probes}}) {
        my $target = $binding{$probe->{probe_id}}{target_name};
        my $width = $type{$probe->{type_id}}{width};
        my $symbol = 'vial_probe_' . _vhdl_slug($probe->{name});
        my $alias = 'vial_declared_' . _vhdl_slug($target);
        my $kind = $width == 1
            ? 'std_logic'
            : 'std_logic_vector(' . ($width - 1) . ' downto 0)';
        push @line,
            "  -- VIAL declared probe $probe->{probe_id} maps to $target",
            "  alias $alias : $kind is",
            "    << signal .$arg{top}.dut.$target : $kind >>;";
    }
    push @line, 'begin';
    for my $probe (@{$bridge->{probes}}) {
        my $target = $binding{$probe->{probe_id}}{target_name};
        my $symbol = 'vial_probe_' . _vhdl_slug($probe->{name});
        my $alias = 'vial_declared_' . _vhdl_slug($target);
        push @line, "  $symbol <= $alias;";
    }
    push @line, "end architecture declared_external_names;", '';
    return join("\n", @line);
}

sub _render_fixture(%arg) {
    my $execution = $arg{execution};
    my $bridge = $arg{bridge};
    my %type = map { $_->{type_id} => $_ } @{$bridge->{types}};
    my %binding = map {
        ($_->{target_language} // '') eq 'vhdl'
            && ($_->{target_kind} // '') eq 'port'
            && ($_->{status} // '') eq 'declared'
            ? ($_->{semantic_id} => $_) : ()
    } @{$bridge->{backend_bindings}};
    my %endpoint = map { $_->{endpoint_id} => $_ } @{$bridge->{endpoints}};
    my $domain = $bridge->{domains}[0];
    my $clock = $binding{$domain->{clock_endpoint_id}}{target_name};
    my $reset = $binding{$domain->{reset_endpoint_id}}{target_name};
    my $inactive_function = $domain->{active_edge} eq 'rising'
        ? 'falling_edge' : 'rising_edge';
    my $reset_active = $domain->{reset_polarity} eq 'active_low'
        ? 'VIAL_VALUE_0' : 'VIAL_VALUE_1';
    my $reset_inactive = $domain->{reset_polarity} eq 'active_low'
        ? 'VIAL_VALUE_1' : 'VIAL_VALUE_0';
    my $ready_in = _endpoint_name_by_role($bridge, \%binding, 'ready_in');
    my $ready_out = _endpoint_name_by_role($bridge, \%binding, 'ready_out');
    my $select = _endpoint_name_by_role($bridge, \%binding, 'select');
    my $transfer = _endpoint_name_by_role($bridge, \%binding, 'transfer');
    my $response = _endpoint_name_by_role($bridge, \%binding, 'response');
    my @fiber = map { @{$_->{fibers}} } @{$execution->{scenarios}};
    my %fiber_index = map { $fiber[$_]{fiber_id} => $_ } 0 .. $#fiber;
    my %sample_symbol;
    for my $item (@{$bridge->{endpoints}}) {
        $sample_symbol{$item->{endpoint_id}}
            = 'vial_sample_' . _vhdl_slug($binding{$item->{endpoint_id}}{target_name});
    }
    for my $item (@{$bridge->{probes}}) {
        $sample_symbol{$item->{probe_id}}
            = 'vial_sample_probe_' . _vhdl_slug($item->{name});
    }

    my @line = (
        'library ieee;',
        'use ieee.std_logic_1164.all;',
        '',
        'use work.fsmgen_vial_types_pkg.all;',
        'use work.fsmgen_vial_runtime_pkg.all;',
        '',
        "entity $arg{top} is",
        "end entity $arg{top};",
        '',
        "architecture portable_semantics of $arg{top} is",
    );
    for my $endpoint (@{$bridge->{endpoints}}) {
        my $name = $binding{$endpoint->{endpoint_id}}{target_name};
        my $width = $type{$endpoint->{type_id}}{width};
        my $is_driver = $endpoint->{direction} eq 'input'
            && $endpoint->{role} ne 'ready_in';
        my $initial = $is_driver ? " := "
            . ($width == 1 ? "'0'" : "(others => '0')") : '';
        my $declaration = $width == 1
            ? "  signal $name : std_logic$initial;"
            : "  signal $name : std_logic_vector(" . ($width - 1)
                . " downto 0)$initial;";
        push @line, $declaration;
    }
    for my $probe (@{$bridge->{probes}}) {
        my $width = $type{$probe->{type_id}}{width};
        my $symbol = 'vial_probe_' . _vhdl_slug($probe->{name});
        push @line, $width == 1
            ? "  signal $symbol : std_logic;"
            : "  signal $symbol : std_logic_vector(" . ($width - 1)
                . ' downto 0);';
    }
    if (@{$bridge->{probes}}) {
        push @line, '', "  component $arg{probe_adapter} is", '    port (';
        my @port;
        for my $probe (@{$bridge->{probes}}) {
            my $width = $type{$probe->{type_id}}{width};
            my $symbol = 'vial_probe_' . _vhdl_slug($probe->{name});
            my $kind = $width == 1
                ? 'std_logic'
                : 'std_logic_vector(' . ($width - 1) . ' downto 0)';
            push @port, "      $symbol : out $kind";
        }
        for my $index (0 .. $#port) {
            push @line, $port[$index] . ($index == $#port ? '' : ';');
        }
        push @line, '    );', '  end component;';
    }
    push @line, '', 'begin',
        "  dut : entity work.$arg{entity_name}(rtl)",
        '    port map (';
    my @ports = map {
        my $name = $binding{$_->{endpoint_id}}{target_name};
        "      $name => $name"
    } @{$bridge->{endpoints}};
    for my $index (0 .. $#ports) {
        push @line, $ports[$index] . ($index == $#ports ? '' : ',');
    }
    push @line, '    );', '';
    if (@{$bridge->{probes}}) {
        push @line, "  probe_adapter : $arg{probe_adapter}", '    port map (';
        my @probe_port = map {
            my $symbol = 'vial_probe_' . _vhdl_slug($_->{name});
            "      $symbol => $symbol"
        } @{$bridge->{probes}};
        for my $index (0 .. $#probe_port) {
            push @line, $probe_port[$index]
                . ($index == $#probe_port ? '' : ',');
        }
        push @line, '    );', '';
    }
    push @line,
        "  $ready_in <= $ready_out;",
        '',
        '  vial_clock_generator : process',
        '  begin',
        '    loop',
        '      wait for 1 ns;',
        "      $clock <= not $clock;",
        '    end loop;',
        '  end process vial_clock_generator;',
        '',
        '  vial_scheduler : process',
        '    variable vial_runtime_state : vial_runtime_state_t := VIAL_RUNTIME_CONSTRUCTED;',
        '    variable vial_time : vial_logical_time_t := VIAL_INITIAL_LOGICAL_TIME;',
        '    variable vial_scenario_status : vial_scenario_status_t := VIAL_SCENARIO_DORMANT;',
        '    variable vial_current_scenario : natural := 0;',
        '    variable vial_scenario_timeout : natural := 0;',
        '    variable vial_current_operation_rank : natural := 0;',
        '    variable vial_scenario_started : boolean := false;',
        '    variable vial_scenario_done : boolean := false;',
        '    variable vial_transaction_active : boolean := false;',
        '    variable vial_transaction_accepted : boolean := false;',
        '    variable vial_scoreboard : vial_scoreboard_state_t := (0, 0, 0, 0, false);',
        '    variable vial_coverage : vial_coverage_counter_t := (0, 0);',
        '    variable vial_fault : vial_fault_state_t := (false, 0, 0);',
        '    variable vial_scoreboard_comparisons_total : natural := 0;',
        '    variable vial_scoreboard_mismatches_total : natural := 0;',
        '    variable vial_scoreboard_overflowed_any : boolean := false;',
        '    variable vial_fault_applications_total : natural := 0;',
        '    variable vial_check_passes : natural := 0;',
        '    variable vial_check_failures : natural := 0;',
        '    variable vial_unknown_evidence : natural := 0;',
        '    variable vial_diagnostic_count : natural := 0;',
        '    variable vial_diagnostics : vial_diagnostic_array_t(0 to VIAL_DIAGNOSTIC_CAPACITY - 1);',
        '    variable vial_scenario_failure_baseline : natural := 0;',
        '    variable vial_scenario_unknown_baseline : natural := 0;',
        '    variable vial_trace_sequence : natural := 0;',
        '    variable vial_trace_open : boolean := false;',
        '    variable vial_trace_closed : boolean := false;',
        '    variable vial_result_consistent : boolean := false;';
    for my $index (0 .. $#{$execution->{scenarios}}) {
        my $tag = sprintf('%02d', $index);
        push @line,
            "    variable vial_scenario_${tag}_passed : boolean := false;",
            "    variable vial_scenario_${tag}_timed_out : boolean := false;",
            "    variable vial_scenario_${tag}_cycles : natural := 0;";
    }
    for my $endpoint (@{$bridge->{endpoints}}) {
        my $width = $type{$endpoint->{type_id}}{width};
        push @line, "    variable $sample_symbol{$endpoint->{endpoint_id}}"
            . ' : vial_observation_vector_t(' . ($width - 1) . ' downto 0);';
    }
    for my $probe (@{$bridge->{probes}}) {
        my $width = $type{$probe->{type_id}}{width};
        push @line, "    variable $sample_symbol{$probe->{probe_id}}"
            . ' : vial_observation_vector_t(' . ($width - 1) . ' downto 0);';
    }
    for my $index (0 .. $#fiber) {
        my $tag = sprintf('%02d', $index);
        push @line,
            "    -- VIAL fiber state $tag: " . _vhdl_string($fiber[$index]{fiber_id}),
            "    variable vial_fiber_${tag}_status : vial_fiber_status_t := VIAL_FIBER_DORMANT;";
    }
    for my $index (0 .. $#{$execution->{models}}) {
        my $tag = sprintf('%02d', $index);
        push @line,
            "    -- VIAL model state $tag: "
                . _vhdl_string($execution->{models}[$index]{instance_id}),
            "    variable vial_model_${tag}_count : natural := 0;";
    }
    for my $event (@{$execution->{events}}) {
        push @line, '    variable vial_event_' . _vhdl_slug($event->{name})
            . '_count : natural := 0;';
    }
    push @line,
        '',
        '    procedure vial_emit_trace(constant record_kind : in string) is',
        '      variable trace_line : line;',
        '    begin',
        '      assert vial_trace_open and not vial_trace_closed',
        '        report "FSMGen VIAL trace record outside the open trace interval"',
        '        severity failure;',
        '      write(trace_line, string\'("FSMGEN_VIAL_TRACE_V1"));',
        '      write(trace_line, HT);',
        '      write(trace_line, string\'("{""payload"":{""logical_time"":{""cycle"":"));',
        '      write(trace_line, vial_time.cycle);',
        '      write(trace_line, string\'(",""local_index"":"));',
        '      write(trace_line, vial_time.local_index);',
        '      write(trace_line, string\'(",""phase_rank"":"));',
        '      write(trace_line, vial_phase_t\'pos(vial_time.phase));',
        '      write(trace_line, string\'(",""static_rank"":"));',
        '      write(trace_line, vial_time.static_rank);',
        '      write(trace_line, string\'("}},""plan_id"":"""));',
        '      write(trace_line, VIAL_PLAN_ID);',
        '      write(trace_line, string\'(""",""record_kind"":"""));',
        '      write(trace_line, record_kind);',
        '      write(trace_line, string\'(""",""run_id"":"));',
        '      if record_kind = "header" or record_kind = "footer" then',
        '        write(trace_line, string\'("null"));',
        '      else',
        '        write(trace_line, string\'("""run/"));',
        '        write(trace_line, VIAL_PLAN_ID);',
        '        write(trace_line, string\'("/"));',
        '        case vial_current_scenario is';
    for my $index (0 .. $#{$execution->{scenarios}}) {
        my $tag = sprintf('%02d', $index);
        push @line,
            "          when $index => write(trace_line, VIAL_SCENARIO_${tag}_ID);";
    }
    push @line,
        '          when others => write(trace_line, string\'("unknown"));',
        '        end case;',
        '        write(trace_line, character\'val(34));',
        '      end if;',
        '      write(trace_line, string\'(",""schema"":"""));',
        '      write(trace_line, VIAL_TRACE_SCHEMA);',
        '      write(trace_line, string\'(""",""schema_version"":1,""sequence"":"));',
        '      write(trace_line, vial_trace_sequence);',
        '      write(trace_line, string\'("}"));',
        '      writeline(output, trace_line);',
        '      vial_trace_sequence := vial_trace_sequence + 1;',
        '    end procedure vial_emit_trace;',
        '',
        '    procedure vial_record_diagnostic(',
        '      constant code : in string;',
        '      constant outcome : in vial_check_outcome_t',
        '    ) is',
        '    begin',
        '      assert vial_diagnostic_count < VIAL_DIAGNOSTIC_CAPACITY',
        '        report "FSMGen VIAL diagnostic capacity overflow" severity failure;',
        '      assert code\'length <= vial_diagnostics(vial_diagnostic_count).code\'length',
        '        report "FSMGen VIAL diagnostic code exceeds its portable bound" severity failure;',
        '      vial_diagnostics(vial_diagnostic_count).code := (others => \' \');',
        '      vial_diagnostics(vial_diagnostic_count).code(1 to code\'length) := code;',
        '      vial_diagnostics(vial_diagnostic_count).code_length := code\'length;',
        '      if outcome = VIAL_CHECK_PASSED then',
        '        vial_diagnostics(vial_diagnostic_count).severity := "info    ";',
        '      else',
        '        vial_diagnostics(vial_diagnostic_count).severity := "error   ";',
        '      end if;',
        '      vial_diagnostics(vial_diagnostic_count).logical_time := vial_time;',
        '      vial_diagnostics(vial_diagnostic_count).outcome := outcome;',
        '      vial_diagnostic_count := vial_diagnostic_count + 1;',
        '      if outcome = VIAL_CHECK_UNKNOWN then',
        '        vial_unknown_evidence := vial_unknown_evidence + 1;',
        '      elsif outcome = VIAL_CHECK_FAILED then',
        '        vial_check_failures := vial_check_failures + 1;',
        '      else',
        '        vial_check_passes := vial_check_passes + 1;',
        '      end if;',
        '      vial_emit_trace("expectations");',
        '    end procedure vial_record_diagnostic;',
        '',
        '    procedure vial_scoreboard_enqueue_expected is',
        '    begin',
        '      if vial_scoreboard.expected_depth = VIAL_SCOREBOARD_CAPACITY then',
        '        vial_scoreboard.overflowed := true;',
        '        vial_scoreboard_overflowed_any := true;',
        '        vial_record_diagnostic("VIAL_SCOREBOARD_OVERFLOW", VIAL_CHECK_FAILED);',
        '      else',
        '        vial_scoreboard.expected_depth := vial_scoreboard.expected_depth + 1;',
        '        vial_emit_trace("scoreboards");',
        '      end if;',
        '    end procedure vial_scoreboard_enqueue_expected;',
        '',
        '    procedure vial_scoreboard_compare(constant matches : in boolean) is',
        '    begin',
        '      assert vial_scoreboard.expected_depth > 0',
        '        report "FSMGen VIAL scoreboard actual without expected item" severity failure;',
        '      vial_scoreboard.actual_depth := vial_scoreboard.actual_depth + 1;',
        '      vial_scoreboard.comparisons := vial_scoreboard.comparisons + 1;',
        '      vial_scoreboard_comparisons_total := vial_scoreboard_comparisons_total + 1;',
        '      if not matches then',
        '        vial_scoreboard.mismatches := vial_scoreboard.mismatches + 1;',
        '        vial_scoreboard_mismatches_total := vial_scoreboard_mismatches_total + 1;',
        '        vial_record_diagnostic("VIAL_SCOREBOARD_MISMATCH", VIAL_CHECK_FAILED);',
        '      end if;',
        '      vial_scoreboard.expected_depth := vial_scoreboard.expected_depth - 1;',
        '      vial_scoreboard.actual_depth := vial_scoreboard.actual_depth - 1;',
        '      vial_emit_trace("scoreboards");',
        '    end procedure vial_scoreboard_compare;',
        '';
    my $all_scenarios_passed = join ' and ', map {
        'vial_scenario_' . sprintf('%02d', $_) . '_passed'
    } 0 .. $#{$execution->{scenarios}};
    my $any_scenario_timed_out = join ' or ', map {
        'vial_scenario_' . sprintf('%02d', $_) . '_timed_out'
    } 0 .. $#{$execution->{scenarios}};
    my $random_decisions = _canonical_json($execution->{randomness}{decisions});
    push @line,
        '    procedure vial_close_trace_and_project_result is',
        '      variable result_line : line;',
        '      procedure vial_write_status(',
        '        variable target : inout line;',
        '        constant passed : in boolean;',
        '        constant timed_out : in boolean',
        '      ) is',
        '      begin',
        '        if timed_out then',
        _vhdl_textio_write('target', 'timeout', '          '),
        '        elsif passed then',
        _vhdl_textio_write('target', 'pass', '          '),
        '        else',
        _vhdl_textio_write('target', 'fail', '          '),
        '        end if;',
        '      end procedure vial_write_status;',
        '    begin',
        '      assert vial_trace_open and not vial_trace_closed',
        '        report "FSMGen VIAL trace did not close exactly once" severity failure;',
        '      vial_emit_trace("footer");',
        '      vial_trace_closed := true;',
        '      vial_result_consistent := vial_check_failures = 0',
        '        and vial_unknown_evidence = 0',
        '        and not vial_scoreboard_overflowed_any',
        '        and vial_scoreboard_mismatches_total = 0',
        '        and vial_scoreboard.expected_depth = 0',
        '        and vial_scoreboard.actual_depth = 0',
        "        and $all_scenarios_passed;",
        '      write(result_line, string\'("FSMGEN_VIAL_RESULT_V1"));',
        '      write(result_line, HT);',
        _vhdl_textio_write('result_line', '{"backend_evidence":{"analysis_status":"not_run","elaboration_status":"not_run","runtime_status":"projection_only"},"backend_profile":{"capabilities":["vial.backend.vhdl_portable_ghdl.v1","vial.backend.vhdl_portable_ghdl.result_manifest_projection.v1"],"id":"vhdl_portable_ghdl","methodology":"plain_vhdl_no_provider","target_language":"VHDL","tool_name":null,"tool_version":null,"uvm_revision":null,"vhdl_standard":"IEEE 1076-2008"},"capability_evidence":{"native_only":[],"required":[],"satisfied":["portable_checking_projection"],"unsatisfied":[]},"coverage":[{"bins":{"not_stalled":'),
        '      write(result_line, vial_coverage.not_stalled);',
        _vhdl_textio_write('result_line', ',"stalled":'),
        '      write(result_line, vial_coverage.stalled);',
        _vhdl_textio_write('result_line', '},"coverpoint_id":"coverpoint/stall_seen"}],"diagnostics":['),
        '      if vial_diagnostic_count > 0 then',
        '        for diagnostic_index in 0 to vial_diagnostic_count - 1 loop',
        '          if diagnostic_index > 0 then',
        _vhdl_textio_write('result_line', ',', '            '),
        '          end if;',
        _vhdl_textio_write('result_line', '{"code":"', '          '),
        '          write(result_line, vial_diagnostics(diagnostic_index).code(',
        '            1 to vial_diagnostics(diagnostic_index).code_length));',
        _vhdl_textio_write('result_line', '","logical_time":{"cycle":', '          '),
        '          write(result_line, vial_diagnostics(diagnostic_index).logical_time.cycle);',
        _vhdl_textio_write('result_line', ',"local_index":', '          '),
        '          write(result_line, vial_diagnostics(diagnostic_index).logical_time.local_index);',
        _vhdl_textio_write('result_line', ',"phase_rank":', '          '),
        '          write(result_line, vial_phase_t\'pos(',
        '            vial_diagnostics(diagnostic_index).logical_time.phase));',
        _vhdl_textio_write('result_line', ',"static_rank":', '          '),
        '          write(result_line, vial_diagnostics(diagnostic_index).logical_time.static_rank);',
        _vhdl_textio_write('result_line', '},"outcome":"', '          '),
        '          if vial_diagnostics(diagnostic_index).outcome = VIAL_CHECK_PASSED then',
        _vhdl_textio_write('result_line', 'pass', '            '),
        '          elsif vial_diagnostics(diagnostic_index).outcome = VIAL_CHECK_UNKNOWN then',
        _vhdl_textio_write('result_line', 'unknown', '            '),
        '          else',
        _vhdl_textio_write('result_line', 'fail', '            '),
        '          end if;',
        _vhdl_textio_write('result_line', '","severity":"', '          '),
        '          if vial_diagnostics(diagnostic_index).outcome = VIAL_CHECK_PASSED then',
        _vhdl_textio_write('result_line', 'info', '            '),
        '          else',
        _vhdl_textio_write('result_line', 'error', '            '),
        '          end if;',
        _vhdl_textio_write('result_line', '"}', '          '),
        '        end loop;',
        '      end if;',
        _vhdl_textio_write('result_line', '],"drives":[],"events":[],"exclusions":[],"execution_profile":"'),
        '      write(result_line, VIAL_EXECUTION_PROFILE);',
        _vhdl_textio_write('result_line', '","expectations":[],"faults":[{"applications":'),
        '      write(result_line, vial_fault_applications_total);',
        _vhdl_textio_write('result_line', ',"fault_id":"fault/unsupported_size","kind":"substitution"}],"fibers":[],"fixture_id":"'),
        '      write(result_line, VIAL_FIXTURE_ID);',
        _vhdl_textio_write('result_line', '","metrics":{"coverage_not_stalled":'),
        '      write(result_line, vial_coverage.not_stalled);',
        _vhdl_textio_write('result_line', ',"coverage_stalled":'),
        '      write(result_line, vial_coverage.stalled);',
        _vhdl_textio_write('result_line', ',"diagnostic_records":'),
        '      write(result_line, vial_diagnostic_count);',
        _vhdl_textio_write('result_line', ',"fault_applications":'),
        '      write(result_line, vial_fault_applications_total);',
        _vhdl_textio_write('result_line', ',"scoreboard_comparisons":'),
        '      write(result_line, vial_scoreboard_comparisons_total);',
        _vhdl_textio_write('result_line', ',"scoreboard_mismatches":'),
        '      write(result_line, vial_scoreboard_mismatches_total);',
        _vhdl_textio_write('result_line', '},"models":[],"native_extensions":[],"parity_digest":null,"parity_projection":null,"plan_id":"'),
        '      write(result_line, VIAL_PLAN_ID);',
        _vhdl_textio_write('result_line', '","portable_parity_eligible":false,"random_decisions":' . $random_decisions . ',"result_id":null,"scenario_results":[');
    for my $index (0 .. $#{$execution->{scenarios}}) {
        my $tag = sprintf('%02d', $index);
        push @line, _vhdl_textio_write('result_line', ',', '      ') if $index;
        push @line,
            _vhdl_textio_write('result_line', '{"cancelled_fiber_ids":[],"completion_reason":"'),
            "      if vial_scenario_${tag}_timed_out then",
            _vhdl_textio_write('result_line', 'timeout', '        '),
            "      elsif vial_scenario_${tag}_passed then",
            _vhdl_textio_write('result_line', 'completed', '        '),
            '      else',
            _vhdl_textio_write('result_line', 'expectation_failed', '        '),
            '      end if;',
            _vhdl_textio_write('result_line', '","diagnostic_ids":[],"end_time":{"cycle":'),
            "      write(result_line, vial_scenario_${tag}_cycles);",
            _vhdl_textio_write('result_line', ',"domain_id":"'),
            '      write(result_line, VIAL_DOMAIN_ID);',
            _vhdl_textio_write('result_line', '","ordinal":0,"phase":"check"},"expectation_ids":[],"logical_cycle_count":'),
            "      write(result_line, vial_scenario_${tag}_cycles);",
            _vhdl_textio_write('result_line', ',"run_id":"run/'),
            '      write(result_line, VIAL_PLAN_ID);',
            _vhdl_textio_write('result_line', '/'),
            "      write(result_line, VIAL_SCENARIO_${tag}_ID);",
            _vhdl_textio_write('result_line', '","scenario_id":"'),
            "      write(result_line, VIAL_SCENARIO_${tag}_ID);",
            _vhdl_textio_write('result_line', '","start_time":{"cycle":0,"domain_id":"'),
            '      write(result_line, VIAL_DOMAIN_ID);',
            _vhdl_textio_write('result_line', '","ordinal":0,"phase":"drive"},"status":"'),
            "      vial_write_status(result_line, vial_scenario_${tag}_passed,",
            "        vial_scenario_${tag}_timed_out);",
            _vhdl_textio_write('result_line', '"}');
    }
    push @line,
        _vhdl_textio_write('result_line', '],"schema":"'),
        '      write(result_line, VIAL_RESULT_SCHEMA);',
        _vhdl_textio_write('result_line', '","schema_version":1,"scoreboards":[{"capacity":4,"comparisons":'),
        '      write(result_line, vial_scoreboard_comparisons_total);',
        _vhdl_textio_write('result_line', ',"mismatches":'),
        '      write(result_line, vial_scoreboard_mismatches_total);',
        _vhdl_textio_write('result_line', '}],"status":"'),
        "      vial_write_status(result_line, vial_result_consistent, $any_scenario_timed_out);",
        _vhdl_textio_write('result_line', '","transactions":[]}'),
        '      writeline(output, result_line);',
        '    end procedure vial_close_trace_and_project_result;',
        '',
        '    procedure vial_inactive_barrier is',
        '      variable vial_accept_now : boolean := false;',
        '      variable vial_complete_now : boolean := false;',
        '    begin',
        "      wait until $inactive_function($clock);",
        '      vial_time.cycle := vial_time.cycle + 1;',
        '      vial_time.phase := VIAL_SAMPLE_PHASE;',
        '      -- FSMGEN VIAL PHASE: SAMPLE';
    for my $endpoint (@{$bridge->{endpoints}}) {
        my $name = $binding{$endpoint->{endpoint_id}}{target_name};
        my $width = $type{$endpoint->{type_id}}{width};
        my $value = $width == 1 ? "std_logic_vector'(0 => $name)" : $name;
        push @line, "      $sample_symbol{$endpoint->{endpoint_id}} := observe_vial_vector($value);";
    }
    for my $probe (@{$bridge->{probes}}) {
        my $name = 'vial_probe_' . _vhdl_slug($probe->{name});
        my $width = $type{$probe->{type_id}}{width};
        my $value = $width == 1 ? "std_logic_vector'(0 => $name)" : $name;
        push @line, "      $sample_symbol{$probe->{probe_id}} := observe_vial_vector($value);";
    }
    my $select_sample = $sample_symbol{_endpoint_id_by_role($bridge, 'select')};
    my $ready_in_sample = $sample_symbol{_endpoint_id_by_role($bridge, 'ready_in')};
    my $ready_out_sample = $sample_symbol{_endpoint_id_by_role($bridge, 'ready_out')};
    my $transfer_sample = $sample_symbol{_endpoint_id_by_role($bridge, 'transfer')};
    my $response_sample = $sample_symbol{_endpoint_id_by_role($bridge, 'response')};
    push @line,
        '',
        '      vial_time.phase := VIAL_REACT_PHASE;',
        '      -- FSMGEN VIAL PHASE: REACT',
        '      vial_accept_now := vial_transaction_active',
        "        and vial_is_known_one(${select_sample}(0))",
        "        and vial_is_known_one(${ready_in_sample}(0))",
        "        and vial_matches($transfer_sample,",
        "          to_vial_value_vector(std_logic_vector'(\"10\")));",
        '      vial_complete_now := vial_transaction_active',
        "        and vial_is_known_one(${ready_out_sample}(0))",
        '        and (vial_transaction_accepted or vial_accept_now);',
        '      if vial_accept_now and not vial_transaction_accepted then',
        '        vial_event_accepted_count := vial_event_accepted_count + 1;',
        '        vial_event_captured_count := vial_event_captured_count + 1;',
        '        vial_transaction_accepted := true;',
        '      end if;',
        "      if vial_transaction_active and vial_is_known_zero(${ready_out_sample}(0)) then",
        '        vial_event_held_count := vial_event_held_count + 1;',
        '        vial_coverage.stalled := vial_coverage.stalled + 1;',
        '        vial_emit_trace("coverage");',
        '      elsif vial_transaction_active and vial_is_known_one(' . $ready_out_sample . '(0)) then',
        '        vial_coverage.not_stalled := vial_coverage.not_stalled + 1;',
        '        vial_emit_trace("coverage");',
        '      end if;',
        "      if vial_transaction_active and vial_is_known_one(${response_sample}(0)) then",
        '        vial_event_error_count := vial_event_error_count + 1;',
        '      end if;',
        '      if vial_complete_now then',
        '        vial_event_completed_count := vial_event_completed_count + 1;',
        '        vial_emit_trace("events");',
        '        if vial_scoreboard.expected_depth > 0 then',
        "          vial_scoreboard_compare(vial_is_known_zero(${response_sample}(0)));",
        '        end if;',
        '      end if;';
    my %event_name;
    for my $event (@{$execution->{events}}) {
        $event_name{$event->{event_id}} = $event->{name};
        $event_name{$event->{declaration_semantic_id}} = $event->{name};
    }
    for my $index (0 .. $#{$execution->{models}}) {
        my $model = $execution->{models}[$index];
        my $trigger = $event_name{$model->{bindings}[0]{value}{event_id}};
        my $condition = $trigger eq 'accepted' ? 'vial_accept_now'
            : $trigger eq 'completed' ? 'vial_complete_now'
            : 'false';
        my $tag = sprintf('%02d', $index);
        push @line,
            "      -- VIAL model update $tag: " . _vhdl_string($model->{instance_id}),
            "      if $condition then",
            "        vial_model_${tag}_count := vial_model_${tag}_count + 1;",
            '      end if;';
    }
    push @line, '      if vial_scenario_started then',
        '        case vial_current_scenario is';
    for my $scenario_index (0 .. $#{$execution->{scenarios}}) {
        my $scenario = $execution->{scenarios}[$scenario_index];
        my @ops = grep { $_->{scenario_id} eq $scenario->{scenario_id} }
            @{$execution->{operation_graph}{operations}};
        my %op_by_id = map { $_->{operation_id} => $_ } @ops;
        my @parallel = grep { $_->{kind} eq 'parallel' } @ops;
        my @root_await = grep {
            $_->{kind} eq 'await' && $_->{fiber_id} eq $scenario->{root_fiber_id}
        } @ops;
        push @line, "          when $scenario_index =>";
        for my $operation (grep { $_->{kind} eq 'await' } @ops) {
            my $fiber_tag = sprintf('%02d', $fiber_index{$operation->{fiber_id}});
            my $condition = _render_await_condition(
                operation => $operation,
                bridge => $bridge,
                binding => \%binding,
                sample_symbol => \%sample_symbol,
                execution => $execution,
            );
            push @line,
                "            vial_current_operation_rank := $operation->{static_rank};",
                "            if $condition then",
                "              vial_fiber_${fiber_tag}_status := VIAL_FIBER_COMPLETED;",
                '            end if;';
        }
        if (@parallel == 1) {
            my ($effect) = grep { $_->{kind} eq 'activate_fibers' }
                @{$parallel[0]{effects}};
            my @child = map { $op_by_id{$_} } @{$effect->{child_root_operation_ids}};
            my @done = map {
                'vial_fiber_' . sprintf('%02d', $fiber_index{$_->{fiber_id}})
                    . '_status = VIAL_FIBER_COMPLETED'
            } @child;
            my $join = $effect->{join} eq 'all' ? ' and ' : ' or ';
            my $root_tag = sprintf('%02d', $fiber_index{$scenario->{root_fiber_id}});
            push @line,
                "            vial_current_operation_rank := $parallel[0]{static_rank};",
                '            if ' . join($join, @done) . ' then',
                "              vial_fiber_${root_tag}_status := VIAL_FIBER_COMPLETED;",
                '              vial_scenario_done := true;',
                '            end if;';
        }
        elsif (@root_await) {
            my $root_tag = sprintf('%02d', $fiber_index{$scenario->{root_fiber_id}});
            push @line,
                "            if vial_fiber_${root_tag}_status = VIAL_FIBER_COMPLETED then",
                '              vial_scenario_done := true;',
                '            end if;';
        }
        else {
            push @line,
                '            if vial_complete_now then',
                '              vial_scenario_done := true;',
                '            end if;';
        }
    }
    push @line,
        '          when others =>',
        '            vial_scenario_done := true;',
        '        end case;',
        '      end if;',
        '      if vial_scenario_started and vial_time.cycle >= vial_scenario_timeout then',
        '        vial_scenario_status := VIAL_SCENARIO_TIMED_OUT;',
        '        vial_scenario_done := true;',
        '      end if;',
        '',
        '      vial_time.phase := VIAL_CHECK_PHASE;',
        '      -- FSMGEN VIAL PHASE: CHECK',
        "      if not vial_is_known(${ready_out_sample}(0))",
        "          or not vial_is_known(${response_sample}(0)) then",
        '        vial_record_diagnostic("VIAL_UNKNOWN_SAMPLE", VIAL_CHECK_UNKNOWN);',
        '      end if;',
        '      if vial_scenario_done then',
        '        if vial_scenario_status = VIAL_SCENARIO_TIMED_OUT then',
        '          vial_record_diagnostic("VIAL_SCENARIO_TIMEOUT", VIAL_CHECK_FAILED);',
        '        elsif vial_current_scenario = 0 then',
        "          if vial_is_known_zero(${response_sample}(0)) then",
        '            vial_record_diagnostic("VIAL_EXPECT_SUCCESS", VIAL_CHECK_PASSED);',
        '          else',
        '            vial_record_diagnostic("VIAL_EXPECT_SUCCESS", VIAL_CHECK_FAILED);',
        '          end if;',
        '        elsif vial_event_error_count = 0 then',
        '          vial_record_diagnostic("VIAL_EXPECT_ERROR", VIAL_CHECK_FAILED);',
        '        else',
        '          vial_record_diagnostic("VIAL_EXPECT_ERROR", VIAL_CHECK_PASSED);',
        '        end if;',
        '      end if;',
        '',
        '      vial_time.phase := VIAL_DRIVE_PHASE;',
        '      -- FSMGEN VIAL PHASE: DRIVE',
        '      if vial_complete_now then',
        "        drive_vial_value($select, VIAL_VALUE_0);",
        "        drive_vial_vector($transfer,",
        "          to_vial_value_vector(std_logic_vector'(\"00\")));",
        '        vial_transaction_active := false;',
        '      end if;',
        '      vial_time.static_rank := vial_current_operation_rank;',
        '      vial_time.local_index := 0;',
        '    end procedure vial_inactive_barrier;',
        '',
        '  begin',
        '    vial_runtime_state := VIAL_RUNTIME_READY;',
        '    vial_time := VIAL_INITIAL_LOGICAL_TIME;',
        '    vial_runtime_state := VIAL_RUNTIME_RUNNING;',
        '    vial_trace_open := true;',
        '    vial_emit_trace("header");',
        '    for scenario_index in 0 to ' . $#{$execution->{scenarios}} . ' loop',
        '      vial_current_scenario := scenario_index;',
        '      vial_scenario_status := VIAL_SCENARIO_RUNNING;',
        '      vial_scenario_started := false;',
        '      vial_scenario_done := false;',
        '      vial_transaction_active := false;',
        '      vial_transaction_accepted := false;',
        '      vial_scoreboard := (0, 0, 0, 0, false);',
        '      vial_fault := (false, 0, 0);',
        '      vial_scenario_failure_baseline := vial_check_failures;',
        '      vial_scenario_unknown_baseline := vial_unknown_evidence;',
        '      vial_time.cycle := 0;',
        '      vial_current_operation_rank := 0;';
    for my $index (0 .. $#fiber) {
        my $tag = sprintf('%02d', $index);
        push @line, "      vial_fiber_${tag}_status := VIAL_FIBER_DORMANT;";
    }
    for my $index (0 .. $#{$execution->{models}}) {
        my $tag = sprintf('%02d', $index);
        push @line, "      vial_model_${tag}_count := 0;";
    }
    for my $event (@{$execution->{events}}) {
        push @line, '      vial_event_' . _vhdl_slug($event->{name}) . '_count := 0;';
    }
    push @line,
        '      vial_emit_trace("scenario_start");',
        '      case scenario_index is';
    for my $scenario_index (0 .. $#{$execution->{scenarios}}) {
        my $scenario = $execution->{scenarios}[$scenario_index];
        my @ops = grep { $_->{scenario_id} eq $scenario->{scenario_id} }
            @{$execution->{operation_graph}{operations}};
        my ($reset_op) = grep { $_->{kind} eq 'reset' } @ops;
        my ($start_op) = grep { $_->{kind} eq 'start' } @ops;
        my ($scoreboard_op) = grep { $_->{kind} eq 'scoreboard_expect' } @ops;
        my ($fault_op) = grep { $_->{kind} eq 'inject' } @ops;
        my %reset_input = map { $_->{name} => $_->{value} } @{$reset_op->{typed_inputs}};
        my %start_input = map { $_->{name} => $_->{value} } @{$start_op->{typed_inputs}};
        my %field = map { $_->{field_id} => $_->{value}{value} } @{$start_input{fields}};
        push @line,
            "        when $scenario_index =>",
            "          -- VIAL scenario $scenario_index: " . _vhdl_string($scenario->{scenario_id}),
            "          vial_scenario_timeout := $scenario->{timeout_cycles};",
            "          vial_current_operation_rank := $reset_op->{static_rank};",
            "          drive_vial_value($reset, $reset_active);",
            "          for reset_index in 1 to $reset_input{cycles} loop",
            '            vial_inactive_barrier;',
            '          end loop;',
            "          drive_vial_value($reset, $reset_inactive);";
        if ($scoreboard_op) {
            push @line,
                "          vial_current_operation_rank := $scoreboard_op->{static_rank};",
                '          vial_scoreboard_enqueue_expected;';
        }
        if ($fault_op) {
            push @line,
                "          vial_current_operation_rank := $fault_op->{static_rank};",
                '          vial_fault.armed := true;',
                '          vial_fault.remaining_cycles := 1;',
                '          vial_emit_trace("faults");';
        }
        for my $carrier (@{$bridge->{transactions}[0]{fields}}) {
            my ($field_id) = grep { /::field::\Q$carrier->{name}\E\z/ } keys %field;
            next unless defined $field_id;
            my $name = $binding{$carrier->{endpoint_id}}{target_name};
            my $width = $type{$endpoint{$carrier->{endpoint_id}}{type_id}}{width};
            my $expression = $width == 1
                ? _vhdl_value_symbol_expression($field{$field_id})
                : _vhdl_value_vector_expression($field{$field_id}, $width);
            if ($fault_op && $carrier->{name} eq $execution->{faults}[0]{field_name}) {
                my $substitute = $execution->{faults}[0]{substitute}{value};
                $expression = $width == 1
                    ? _vhdl_value_symbol_expression($substitute)
                    : _vhdl_value_vector_expression($substitute, $width);
                push @line,
                    '          -- VIAL substitution fault preserves the immutable authored field',
                    '          vial_fault.applications := vial_fault.applications + 1;',
                    '          vial_fault_applications_total := vial_fault_applications_total + 1;',
                    '          vial_fault.remaining_cycles := 0;',
                    '          vial_fault.armed := false;',
                    '          vial_emit_trace("faults");';
            }
            push @line, "          -- VIAL drive $field_id",
                $width == 1
                    ? "          drive_vial_value($name, $expression);"
                    : "          drive_vial_vector($name, $expression);";
        }
        push @line,
            "          drive_vial_value($select, VIAL_VALUE_1);",
            "          vial_current_operation_rank := $start_op->{static_rank};",
            '          vial_transaction_active := true;',
            '          vial_transaction_accepted := false;',
            '          vial_event_requested_count := vial_event_requested_count + 1;';
        for my $scenario_fiber (@{$scenario->{fibers}}) {
            my $tag = sprintf('%02d', $fiber_index{$scenario_fiber->{fiber_id}});
            push @line, "          vial_fiber_${tag}_status := VIAL_FIBER_RUNNING;";
        }
        push @line,
            '          vial_scenario_started := true;',
            '          while not vial_scenario_done loop',
            '            vial_inactive_barrier;',
            '          end loop;',
            '          if vial_scenario_status /= VIAL_SCENARIO_TIMED_OUT then',
            '            vial_scenario_status := VIAL_SCENARIO_STIMULUS_COMPLETED;',
            '          end if;',
            '          vial_scenario_' . sprintf('%02d', $scenario_index)
                . '_timed_out := vial_scenario_status = VIAL_SCENARIO_TIMED_OUT;',
            '          vial_scenario_' . sprintf('%02d', $scenario_index)
                . '_cycles := vial_time.cycle;',
            '          vial_scenario_' . sprintf('%02d', $scenario_index)
                . '_passed := vial_scenario_status /= VIAL_SCENARIO_TIMED_OUT',
            '            and vial_check_failures = vial_scenario_failure_baseline',
            '            and vial_unknown_evidence = vial_scenario_unknown_baseline',
            '            and not vial_scoreboard.overflowed',
            '            and vial_scoreboard.expected_depth = 0',
            '            and vial_scoreboard.actual_depth = 0;',
            '          vial_emit_trace("scenario_end");';
    }
    push @line,
        '        when others =>',
        '          null;',
        '      end case;',
        '    end loop;',
        '    vial_runtime_state := VIAL_RUNTIME_COMPLETED;',
        '    vial_close_trace_and_project_result;',
        '    assert vial_trace_closed and vial_result_consistent',
        '      report "FSMGen VIAL trace/result closure inconsistency" severity failure;',
        '    vial_runtime_state := VIAL_RUNTIME_FINALIZED;',
        '    wait;',
        '  end process vial_scheduler;',
        "end architecture portable_semantics;",
        '';
    return join("\n", @line);
}

sub _source_map_entries(%arg) {
    my $execution = $arg{execution};
    my $bridge = $arg{bridge};
    my %artifact = map { $_->{relpath} => $_ } @{$arg{source_artifacts}};
    my @spec = (
        [$arg{types_rel}, 'fsmgen_vial_types_pkg', 'typed_value_and_phase_foundation',
            ['/types'], [map { $_->{type_id} } @{$bridge->{types}}], ['/types'], []],
        [$arg{runtime_rel}, 'fsmgen_vial_runtime_pkg', 'typed_runtime_foundation',
            ['/execution_profile'], [$execution->{plan_id}], ['/'], []],
        [$arg{metadata_rel}, $arg{metadata_package}, 'fixture_metadata',
            ['/fixture', '/domains/0'],
            [$execution->{fixture}{fixture_id}, $execution->{domains}[0]{semantic_id}],
            ['/units/0', '/endpoints', '/backend_bindings'],
            [$execution->{fixture}{source_location}, $execution->{domains}[0]{source_location}]],
        [$arg{dut_rel}, $arg{entity_name}, 'generated_hial_vhdl_dut',
            ['/bindings/unit'], [$bridge->{units}[0]{unit_id}], ['/units/0'], []],
        [$arg{top_rel}, $arg{top}, 'portable_fixture_top',
            ['/bindings/unit', '/bindings/endpoints'],
            [$execution->{fixture}{fixture_id}, $bridge->{units}[0]{unit_id},
                map { $_->{endpoint_id} } @{$bridge->{endpoints}}],
            ['/units/0', '/endpoints', '/backend_bindings'],
            [$execution->{fixture}{source_location}]],
    );
    if (defined($arg{probe_rel})) {
        push @spec,
            [$arg{probe_rel}, $arg{probe_adapter}, 'declared_probe_adapter',
                ['/bindings/probes'],
                [map { $_->{probe_id} } @{$bridge->{probes}}],
                ['/probes', '/backend_bindings'], []];
    }

    my $metadata_text = $artifact{$arg{metadata_rel}}{content};
    for my $index (0 .. $#{$execution->{operation_graph}{operations}}) {
        my $operation = $execution->{operation_graph}{operations}[$index];
        my $tag = sprintf('%02d', $index);
        my $start = _find_line($metadata_text, qr/^  -- VIAL operation \Q$tag\E:/m);
        push @spec, {
            relpath => $arg{metadata_rel},
            symbol => "VIAL_OPERATION_${tag}_ID",
            role => "operation_rank_$operation->{kind}",
            start => $start,
            end => $start + 4,
            plan => ["/operation_graph/operations/$index"],
            semantic => [$operation->{operation_id}, $operation->{fiber_id}],
            facts => [],
            locations => [$operation->{source_location}],
        };
    }
    for my $index (0 .. $#{$execution->{scenarios}}) {
        my $scenario = $execution->{scenarios}[$index];
        my $tag = sprintf('%02d', $index);
        my $start = _find_line($metadata_text, qr/^  -- VIAL scenario \Q$tag\E:/m);
        push @spec, {
            relpath => $arg{metadata_rel},
            symbol => "VIAL_SCENARIO_${tag}_ID",
            role => 'scenario_metadata',
            start => $start,
            end => $start + 3,
            plan => ["/scenarios/$index"],
            semantic => [$scenario->{scenario_id}],
            facts => [],
            locations => [$scenario->{source_location}],
        };
    }
    my @fiber = map { @{$_->{fibers}} } @{$execution->{scenarios}};
    for my $index (0 .. $#fiber) {
        my $tag = sprintf('%02d', $index);
        my $start = _find_line($metadata_text, qr/^  -- VIAL fiber \Q$tag\E:/m);
        push @spec, {
            relpath => $arg{metadata_rel},
            symbol => "VIAL_FIBER_${tag}_ID",
            role => 'fiber_metadata',
            start => $start,
            end => $start + 2,
            plan => ['/scenarios'],
            semantic => [$fiber[$index]{fiber_id}],
            facts => [],
            locations => [$fiber[$index]{source_location}],
        };
    }
    for my $index (0 .. $#{$execution->{models}}) {
        my $model = $execution->{models}[$index];
        my $tag = sprintf('%02d', $index);
        my $start = _find_line($metadata_text, qr/^  -- VIAL model \Q$tag\E:/m);
        push @spec, {
            relpath => $arg{metadata_rel},
            symbol => "VIAL_MODEL_${tag}_INSTANCE_ID",
            role => 'deterministic_model_metadata',
            start => $start,
            end => $start + 2,
            plan => ["/models/$index"],
            semantic => [$model->{instance_id}, $model->{model_id}],
            facts => [],
            locations => [$model->{source_location}],
        };
    }

    my $top_text = $artifact{$arg{top_rel}}{content};
    my %execution_endpoint = map { $_->{endpoint_id} => $_ }
        @{$execution->{bindings}{endpoints}};
    for my $index (0 .. $#{$bridge->{endpoints}}) {
        my $endpoint = $bridge->{endpoints}[$index];
        my $name = _backend_name($bridge, $endpoint->{endpoint_id}, 'port');
        my $line = _find_line($top_text, qr/^  signal \Q$name\E\s*:/mi);
        push @spec, {
            relpath => $arg{top_rel},
            symbol => $name,
            role => $endpoint->{direction} eq 'input'
                ? 'typed_driver_binding' : 'typed_sample_binding',
            start => $line,
            end => $line,
            plan => ["/bindings/endpoints/$index"],
            semantic => [$endpoint->{endpoint_id}],
            facts => ["/endpoints/$index", '/backend_bindings'],
            locations => [$execution_endpoint{$endpoint->{endpoint_id}}{source_location}],
        };
    }
    my $scheduler_start = _find_line($top_text, qr/^  vial_scheduler\s*:\s*process\b/mi);
    my $scheduler_end = _find_line($top_text,
        qr/^  end process vial_scheduler;/mi);
    push @spec, {
        relpath => $arg{top_rel},
        symbol => 'vial_scheduler',
        role => 'inactive_edge_scheduler',
        start => $scheduler_start,
        end => $scheduler_end,
        plan => ['/domains/0', '/operation_graph', '/scenarios', '/models'],
        semantic => [$execution->{domains}[0]{semantic_id}],
        facts => ['/domains/0'],
        locations => [$execution->{domains}[0]{source_location}],
    };
    my @checking_region = (
        ['vial_scoreboard_enqueue_expected', 'bounded_scoreboard_queue',
            qr/^    procedure vial_scoreboard_enqueue_expected is$/m,
            ['/scoreboards'], [map { $_->{instance_id} } @{$execution->{scoreboards}}]],
        ['vial_scoreboard_compare', 'scoreboard_comparison',
            qr/^    procedure vial_scoreboard_compare\(/m,
            ['/scoreboards'], [map { $_->{instance_id} } @{$execution->{scoreboards}}]],
        ['vial_coverage', 'portable_coverage_counters',
            qr/^    variable vial_coverage\s*:/m,
            ['/coverage'], [map { $_->{semantic_id} } @{$execution->{coverage}{coverpoints}}]],
        ['vial_fault', 'bounded_substitution_fault',
            qr/^    variable vial_fault\s*:/m,
            ['/faults'], [map { $_->{semantic_id} } @{$execution->{faults}}]],
        ['vial_record_diagnostic', 'procedural_checks_and_diagnostics',
            qr/^    procedure vial_record_diagnostic\(/m,
            ['/operation_graph/operations'], [map { $_->{operation_id} }
                grep { $_->{kind} eq 'expect' } @{$execution->{operation_graph}{operations}}]],
        ['vial_emit_trace', 'closed_trace_projection',
            qr/^    procedure vial_emit_trace\(/m,
            ['/fixture', '/scenarios'], [$execution->{fixture}{fixture_id}]],
        ['vial_close_trace_and_project_result', 'normalized_result_projection',
            qr/^    procedure vial_close_trace_and_project_result is$/m,
            ['/fixture', '/scenarios', '/scoreboards', '/coverage', '/faults'],
            [$execution->{fixture}{fixture_id}]],
    );
    for my $region (@checking_region) {
        my ($symbol, $role, $pattern, $plan, $semantic) = @$region;
        my $line = _find_line($top_text, $pattern);
        push @spec, {
            relpath => $arg{top_rel},
            symbol => $symbol,
            role => $role,
            start => $line,
            end => $line,
            plan => $plan,
            semantic => $semantic,
            facts => [],
            locations => [$execution->{fixture}{source_location}],
        };
    }
    for my $index (0 .. $#{$execution->{models}}) {
        my $model = $execution->{models}[$index];
        my $tag = sprintf('%02d', $index);
        my $line = _find_line($top_text, qr/^      -- VIAL model update \Q$tag\E:/m);
        push @spec, {
            relpath => $arg{top_rel},
            symbol => "vial_model_${tag}_count",
            role => 'deterministic_model_update',
            start => $line,
            end => $line + 3,
            plan => ["/models/$index"],
            semantic => [$model->{instance_id}],
            facts => [],
            locations => [$model->{source_location}],
        };
    }
    if (defined($arg{probe_rel})) {
        my $probe_text = $artifact{$arg{probe_rel}}{content};
        for my $index (0 .. $#{$bridge->{probes}}) {
            my $probe = $bridge->{probes}[$index];
            my $line = _find_line($probe_text,
                qr/^  -- VIAL declared probe \Q$probe->{probe_id}\E maps to /m);
            push @spec, {
                relpath => $arg{probe_rel},
                symbol => 'vial_probe_' . _vhdl_slug($probe->{name}),
                role => 'generated_declared_probe_adapter',
                start => $line,
                end => $line + 2,
                plan => ["/bindings/probes/$index"],
                semantic => [$probe->{probe_id}],
                facts => ["/probes/$index", '/backend_bindings'],
                locations => [],
            };
        }
    }

    my @entry;
    for my $spec (@spec) {
        my ($relpath, $symbol, $role, $plan, $semantic, $facts, $locations,
            $start, $end);
        if (ref($spec) eq 'HASH') {
            ($relpath, $symbol, $role, $plan, $semantic, $facts, $locations,
                $start, $end) = @{$spec}{qw(
                    relpath symbol role plan semantic facts locations start end
                )};
        }
        else {
            ($relpath, $symbol, $role, $plan, $semantic, $facts, $locations) = @$spec;
        }
        my $text = $artifact{$relpath}{content};
        my $lines = _line_count($text);
        $start //= 1;
        $end //= $lines;
        push @entry, {
            source_map_id => 'source-map/' . sha256_hex(_canonical_json({
                relpath => $relpath, symbol => $symbol, role => $role,
            })),
            generated_relpath => $relpath,
            generated_start_line => $start,
            generated_end_line => $end,
            generated_start_column => 1,
            generated_end_column => _line_column($text, $end),
            generated_symbol => $symbol,
            role => $role,
            plan_paths => _clone($plan),
            semantic_paths => _clone($semantic),
            bridge_fact_paths => _clone($facts),
            source_locations => [map { _clone($_) } grep { defined($_) } @$locations],
        };
    }
    return \@entry;
}

sub _probe_bindings_are_exact($execution, $bridge) {
    my %vhdl = map {
        ($_->{target_language} // '') eq 'vhdl'
            ? ($_->{semantic_id} => $_) : ()
    } @{$bridge->{backend_bindings} || []};
    for my $probe (@{$execution->{bindings}{probes} || []}) {
        my $binding = $vhdl{$probe->{probe_id}};
        return 0 unless ref($binding) eq 'HASH'
            && ($binding->{target_kind} // '') eq 'probe_adapter'
            && ($binding->{status} // '') eq 'adapter_required'
            && _vhdl_identifier($binding->{target_name});
    }
    return 1;
}

sub _relations($execution) {
    my @relation;
    for my $key (qw(endpoints probes)) {
        push @relation, map { @{$_->{relations} || []} }
            @{$execution->{bindings}{$key} || []};
    }
    push @relation, map { $_->{relation} } map { @{$_->{fields} || []} }
        @{$execution->{bindings}{transactions} || []};
    return @relation;
}

sub _positive_reset_cycles($operation) {
    my @cycles = grep { ($_->{name} // '') eq 'cycles' }
        @{$operation->{typed_inputs} || []};
    return @cycles == 1
        && defined($cycles[0]{value}) && !ref($cycles[0]{value})
        && $cycles[0]{value} =~ /\A[0-9]+\z/
        && $cycles[0]{value} >= 1;
}

sub _await_shape_supported($operation, $execution) {
    my @property = grep { ($_->{name} // '') eq 'property' }
        @{$operation->{typed_inputs} || []};
    return 0 unless @property == 1 && ref($property[0]{value}) eq 'HASH';
    my $value = $property[0]{value};
    return 0 unless ($value->{kind} // '') eq 'property'
        && ($value->{op} // '') eq 'within'
        && defined($value->{min_cycles}) && !ref($value->{min_cycles})
        && defined($value->{max_cycles}) && !ref($value->{max_cycles})
        && $value->{min_cycles} =~ /\A[0-9]+\z/
        && $value->{max_cycles} =~ /\A[0-9]+\z/
        && $value->{min_cycles} >= 1
        && $value->{max_cycles} >= $value->{min_cycles}
        && ref($value->{operands}) eq 'ARRAY'
        && @{$value->{operands}} == 1;
    my $operand = $value->{operands}[0];
    if (ref($operand) eq 'HASH'
            && ($operand->{kind} // '') eq 'reference'
            && ($operand->{op} // '') eq 'event') {
        return scalar(grep {
            ($_->{binding_id} // '') eq ($operand->{binding_id} // '')
        } @{$execution->{events} || []}) == 1;
    }
    return 0 unless ref($operand) eq 'HASH'
        && ($operand->{kind} // '') eq 'operator'
        && ($operand->{op} // '') eq 'same'
        && ref($operand->{operands}) eq 'ARRAY'
        && @{$operand->{operands}} == 2;
    my ($reference, $literal) = @{$operand->{operands}};
    return 0 unless ref($reference) eq 'HASH'
        && ($reference->{kind} // '') eq 'reference'
        && ($reference->{op} // '') eq 'sample'
        && defined($reference->{binding_id}) && !ref($reference->{binding_id})
        && ref($literal) eq 'HASH'
        && ($literal->{kind} // '') eq 'literal'
        && _scalar_value_shape_is_valid($literal->{value});
    my @binding;
    for my $key (qw(endpoints probes)) {
        push @binding, grep {
            ($_->{binding_id} // '') eq $reference->{binding_id}
        } @{$execution->{bindings}{$key} || []};
    }
    return @binding == 1;
}

sub _scalar_value_shape_is_valid($value) {
    return 0 unless ref($value) eq 'HASH'
        && ($value->{kind} // '') eq 'scalar'
        && defined($value->{width}) && !ref($value->{width})
        && $value->{width} =~ /\A[0-9]+\z/
        && $value->{width} >= 1 && $value->{width} <= 65_536;
    for my $key (qw(value_hex known_hex z_hex)) {
        return 0 unless defined($value->{$key}) && !ref($value->{$key})
            && $value->{$key} =~ /\A[0-9a-f]+\z/i
            && length($value->{$key}) <= int(($value->{width} + 3) / 4);
    }
    for my $bit (0 .. $value->{width} - 1) {
        my $known = _hex_bit($value->{known_hex}, $bit);
        my $z = _hex_bit($value->{z_hex}, $bit);
        return 0 if $known && $z;
        return 0 if ($value->{state_domain} // '') eq 'two_state'
            && (!$known || $z);
    }
    return 1;
}

sub _walk_values($value, $visit, $path = '') {
    $visit->($value, length($path) ? $path : '/');
    if (ref($value) eq 'HASH') {
        _walk_values($value->{$_}, $visit, "$path/$_") for sort keys %$value;
    }
    elsif (ref($value) eq 'ARRAY') {
        _walk_values($value->[$_], $visit, "$path/$_") for 0 .. $#$value;
    }
}

sub _artifact($relpath, $kind, $language, $role, $content, $generated_from) {
    return {
        relpath => $relpath,
        kind => $kind,
        language => $language,
        role => $role,
        content => $content,
        encoding => 'utf-8',
        source_layer => 'VIAL_BACKEND',
        generated_from => _clone($generated_from),
    };
}

sub _artifact_ref($artifact) {
    return {
        relpath => $artifact->{relpath},
        kind => $artifact->{kind},
        role => $artifact->{role},
        sha256 => sha256_hex($artifact->{content}),
        bytes => bytes::length($artifact->{content}),
    };
}

sub _command_record(%arg) {
    my $record = {
        schema => 'fsmgen.vial_backend_command.v1',
        schema_version => 1,
        logical_executable => $arg{logical_executable},
        arguments => _clone($arg{arguments}),
        working_directory => $arg{working_directory},
        inputs => _clone($arg{inputs}),
        expected_outputs => _clone($arg{expected_outputs}),
        command_digest => undef,
        execution_status => 'not_run',
    };
    my $digest = _clone($record);
    delete $digest->{command_digest};
    $record->{command_digest} = sha256_hex(_canonical_json($digest));
    return $record;
}

sub _command_ref($relpath, $command) {
    return {
        relpath => $relpath,
        command_digest => $command->{command_digest},
        sha256 => sha256_hex(_json_text($command)),
        execution_status => 'not_run',
    };
}

sub _backend_name($bridge, $semantic_id, $target_kind) {
    my @binding = grep {
        ($_->{target_language} // '') eq 'vhdl'
            && ($_->{semantic_id} // '') eq $semantic_id
            && ($_->{target_kind} // '') eq $target_kind
            && ($_->{status} // '') eq 'declared'
    } @{$bridge->{backend_bindings}};
    _throw('VIAL_VHDL_BACKEND_UNSUPPORTED',
        "missing exact VHDL $target_kind binding for '$semantic_id'",
        '/bridge_manifest/backend_bindings')
        unless @binding == 1 && _vhdl_identifier($binding[0]{target_name});
    return $binding[0]{target_name};
}

sub _endpoint_id_by_role($bridge, $role) {
    my @endpoint = grep { ($_->{role} // '') eq $role }
        @{$bridge->{endpoints} || []};
    _throw('VIAL_VHDL_BACKEND_UNSUPPORTED',
        "bridge requires exactly one '$role' endpoint", '/bridge_manifest/endpoints')
        unless @endpoint == 1;
    return $endpoint[0]{endpoint_id};
}

sub _endpoint_name_by_role($bridge, $binding, $role) {
    my $endpoint_id = _endpoint_id_by_role($bridge, $role);
    my $target = $binding->{$endpoint_id};
    _throw('VIAL_VHDL_BACKEND_UNSUPPORTED',
        "endpoint role '$role' lacks one declared VHDL port binding",
        '/bridge_manifest/backend_bindings')
        unless ref($target) eq 'HASH'
            && _vhdl_identifier($target->{target_name});
    return $target->{target_name};
}

sub _render_await_condition(%arg) {
    my $operation = $arg{operation};
    my @property = grep { ($_->{name} // '') eq 'property' }
        @{$operation->{typed_inputs} || []};
    _throw('VIAL_VHDL_BACKEND_UNSUPPORTED',
        "await operation '$operation->{operation_id}' lacks one property input",
        '/execution_ir/operation_graph/operations')
        unless @property == 1 && ref($property[0]{value}) eq 'HASH';
    my $value = $property[0]{value};
    _throw('VIAL_VHDL_BACKEND_UNSUPPORTED',
        "await operation '$operation->{operation_id}' is not a bounded event wait",
        '/execution_ir/operation_graph/operations')
        unless ($value->{kind} // '') eq 'property'
            && ($value->{op} // '') eq 'within'
            && ref($value->{operands}) eq 'ARRAY'
            && @{$value->{operands}} == 1;
    return _render_wait_operand(\%arg, $value->{operands}[0],
        $operation->{operation_id});
}

sub _render_wait_operand($arg, $value, $operation_id) {
    if (ref($value) eq 'HASH'
            && ($value->{kind} // '') eq 'reference'
            && ($value->{op} // '') eq 'event'
            && defined($value->{binding_id}) && !ref($value->{binding_id})) {
        my @event = grep {
            ($_->{binding_id} // '') eq $value->{binding_id}
        } @{$arg->{execution}{events} || []};
        _throw('VIAL_VHDL_BACKEND_UNSUPPORTED',
            "await operation '$operation_id' does not resolve one event",
            '/execution_ir/events')
            unless @event == 1;
        return 'vial_event_' . _vhdl_slug($event[0]{name}) . '_count > 0';
    }
    if (ref($value) eq 'HASH'
            && ($value->{kind} // '') eq 'operator'
            && ($value->{op} // '') eq 'same'
            && ref($value->{operands}) eq 'ARRAY'
            && @{$value->{operands}} == 2) {
        my ($reference, $literal) = @{$value->{operands}};
        _throw('VIAL_VHDL_BACKEND_UNSUPPORTED',
            "await operation '$operation_id' has an unsupported sample predicate",
            '/execution_ir/operation_graph/operations')
            unless ref($reference) eq 'HASH'
                && ($reference->{kind} // '') eq 'reference'
                && ($reference->{op} // '') eq 'sample'
                && defined($reference->{binding_id}) && !ref($reference->{binding_id})
                && ref($literal) eq 'HASH'
                && ($literal->{kind} // '') eq 'literal'
                && ref($literal->{value}) eq 'HASH';
        my @binding;
        for my $key (qw(endpoints probes)) {
            push @binding, grep {
                ($_->{binding_id} // '') eq $reference->{binding_id}
            } @{$arg->{execution}{bindings}{$key} || []};
        }
        _throw('VIAL_VHDL_BACKEND_UNSUPPORTED',
            "await operation '$operation_id' does not resolve one sampled binding",
            '/execution_ir/bindings')
            unless @binding == 1;
        my $semantic_id = $binding[0]{endpoint_id} // $binding[0]{probe_id};
        my $sample = $arg->{sample_symbol}{$semantic_id};
        my $width = $binding[0]{relations}[0]{width};
        _throw('VIAL_VHDL_BACKEND_UNSUPPORTED',
            "await operation '$operation_id' lacks a sampled VHDL symbol",
            '/execution_ir/bindings')
            unless defined($sample) && !ref($sample)
                && defined($width) && !ref($width);
        return 'vial_matches(' . $sample . ', '
            . _vhdl_value_vector_expression($literal->{value}, $width) . ')';
    }
    _throw('VIAL_VHDL_BACKEND_UNSUPPORTED',
        "await operation '$operation_id' has an unsupported operand",
        '/execution_ir/operation_graph/operations');
}

sub _vhdl_value_vector_expression($value, $width) {
    _throw('VIAL_VHDL_BACKEND_UNSUPPORTED',
        'VHDL drive requires one typed scalar value',
        '/execution_ir/operation_graph/operations')
        unless ref($value) eq 'HASH'
            && ($value->{kind} // '') eq 'scalar'
            && defined($value->{width}) && !ref($value->{width})
            && $value->{width} == $width
            && defined($value->{value_hex}) && !ref($value->{value_hex})
            && defined($value->{known_hex}) && !ref($value->{known_hex})
            && defined($value->{z_hex}) && !ref($value->{z_hex});
    my @symbol;
    for my $bit (reverse 0 .. $width - 1) {
        push @symbol, _hex_bit($value->{z_hex}, $bit) ? 'Z'
            : !_hex_bit($value->{known_hex}, $bit) ? 'X'
            : _hex_bit($value->{value_hex}, $bit) ? '1' : '0';
    }
    return q{to_vial_value_vector(std_logic_vector'("}
        . join('', @symbol) . q{"))};
}

sub _vhdl_value_symbol_expression($value) {
    my $vector = _vhdl_value_vector_expression($value, 1);
    return 'VIAL_VALUE_Z' if $vector =~ /"Z"/;
    return 'VIAL_VALUE_X' if $vector =~ /"X"/;
    return 'VIAL_VALUE_1' if $vector =~ /"1"/;
    return 'VIAL_VALUE_0';
}

sub _hex_bit($hex, $bit) {
    return 0 unless defined($hex) && !ref($hex)
        && $hex =~ /\A[0-9a-f]+\z/i
        && defined($bit) && !ref($bit) && $bit =~ /\A[0-9]+\z/;
    my $offset = int($bit / 4);
    return 0 if $offset >= length($hex);
    my $digit = hex(substr($hex, length($hex) - 1 - $offset, 1));
    return ($digit >> ($bit % 4)) & 1;
}

sub _find_line($text, $pattern) {
    my @line = split /\n/, $text, -1;
    my @found;
    for my $index (0 .. $#line) {
        push @found, $index + 1 if $line[$index] =~ $pattern;
    }
    _throw('VIAL_VHDL_BACKEND_SOURCE_MAP_ERROR',
        'generated source-map anchor does not occur exactly once', '/source_map')
        unless @found == 1;
    return $found[0];
}

sub _line_column($text, $line_number) {
    my @line = split /\n/, $text, -1;
    _throw('VIAL_VHDL_BACKEND_SOURCE_MAP_ERROR',
        'generated source-map line is outside the artifact', '/source_map')
        unless defined($line_number) && !ref($line_number)
            && $line_number =~ /\A[0-9]+\z/
            && $line_number >= 1 && $line_number < @line;
    return bytes::length($line[$line_number - 1]) + 1;
}

sub _vhdl_slug($value) {
    my $slug = lc($value // 'unnamed');
    $slug =~ s/[^a-z0-9]+/_/g;
    $slug =~ s/\A_+|_+\z//g;
    $slug = "n_$slug" unless $slug =~ /\A[a-z]/;
    $slug =~ s/_+/_/g;
    return length($slug) ? $slug : 'unnamed';
}

sub _vhdl_identifier($value) {
    return 0 unless defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z][A-Za-z0-9]*(?:_[A-Za-z0-9]+)*\z/;
    my %reserved = map { $_ => 1 } qw(
        abs access after alias all and architecture array assert assume
        begin block body buffer bus case component configuration constant
        context cover default disconnect downto else elsif end entity exit
        fair file for force function generate generic group guarded if
        impure in inertial inout is label library linkage literal loop map
        mod nand new next nor not null of on open or others out package
        parameter port postponed procedure process property protected pure
        range record register reject release rem report restrict return rol
        ror select sequence severity signal shared sla sll sra srl subtype
        then to transport type unaffected units until use variable view
        vmode vprop vunit wait when while with xnor xor
    );
    return !$reserved{lc($value)};
}

sub _vhdl_string($value) {
    $value //= '';
    $value =~ s/"/""/g;
    return $value;
}

sub _vhdl_textio_write($target, $value, $indent = '      ') {
    return $indent . "write($target, string'(\""
        . _vhdl_string($value) . '"));';
}

sub _line_count($text) {
    return scalar(() = $text =~ /\n/g);
}

sub _last_line_column($text) {
    my @line = split /\n/, $text, -1;
    my $last = @line > 1 ? $line[-2] : $line[0];
    return bytes::length($last) + 1;
}

sub _json_text($value) {
    return JSON::PP->new->canonical(1)->pretty(1)->encode($value);
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _safe_relpath($value) {
    return 0 unless defined($value) && !ref($value) && length($value);
    return 0 if $value =~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)};
    my @part = split m{/}, $value, -1;
    return !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } @part;
}

sub _unique(@items) {
    my %seen;
    return grep { !$seen{$_}++ } @items;
}

sub _require_exact_keys($value, $keys, $label) {
    _throw('VIAL_VHDL_BACKEND_INVOCATION_ERROR',
        "$label must be one unblessed hash", '/')
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    _throw('VIAL_VHDL_BACKEND_INVOCATION_ERROR',
        "$label has unknown key '$unknown[0]'", '/') if @unknown;
    _throw('VIAL_VHDL_BACKEND_INVOCATION_ERROR',
        "$label is missing key '$missing[0]'", '/') if @missing;
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        'FSM::VIAL::Backend::VHDLPortableGHDL::Failure';
}

sub _failure($code, $message, $path, $negotiation = undef) {
    return _result({
        ok => JSON::PP::false,
        status => 'error',
        backend_profile => $BACKEND_PROFILE,
        plan_id => undef,
        generated_top => undef,
        operation_id => undef,
        negotiation => defined($negotiation) ? _clone($negotiation) : undef,
        backend_manifest => undef,
        source_map => undef,
        static_validation => undef,
        artifacts => [],
        diagnostics => [{
            code => $code,
            severity => 'error',
            message => $message,
            path => $path,
        }],
    });
}

sub _result($value) {
    my %expected = map { $_ => 1 } @RESULT_KEYS;
    confess 'VHDL backend result has unknown key(s)'
        if grep { !$expected{$_} } keys %$value;
    confess 'VHDL backend result is missing key(s)'
        if grep { !exists($value->{$_}) } @RESULT_KEYS;
    return _clone($value);
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown VHDL backend host failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown VHDL backend host failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'VHDL backend projection contains an unsupported reference' if ref($value);
    return $value;
}

1;
