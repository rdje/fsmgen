package FSM::VIAL::Backend::SVPortableVerilator;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Math::BigInt;
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my $BACKEND_PROFILE = 'sv_portable_verilator';
my $BACKEND_SCHEMA = 'fsmgen.vial_backend.sv_portable_verilator.v1';
my $SOURCE_MAP_SCHEMA = 'fsmgen.vial_backend_source_map.v1';
my $TRACE_SCHEMA = 'fsmgen.vial_sv_runtime_trace.v1';
my $BASE = 'backends/sv_portable_verilator';
my $JSON = JSON::PP->new->canonical(1);
my $BALANCED_PORTABLE_CAPABILITY =
    'hial_vial.bridge_qualification.balanced_portable_v2';
my $BALANCED_PORTABLE_CALLER =
    'FSM::VIAL::ArchitectureScaleBalancedPortableEmission';

my @RESULT_KEYS = qw(
    ok status backend_profile plan_id generated_top operation_id negotiation
    backend_manifest source_map trace_contract artifacts diagnostics
);
my @MANIFEST_KEYS = qw(
    schema schema_version backend_profile plan_id fixture_id generated_top
    execution_profile tool_profile capability_evidence limitations artifacts
    commands source_map result cleanup diagnostics
);
my @SOURCE_MAP_KEYS = qw(schema schema_version plan_id artifacts entries);
my @SOURCE_MAP_ENTRY_KEYS = qw(
    source_map_id generated_relpath generated_start_line generated_end_line
    generated_symbol role plan_paths semantic_paths bridge_fact_paths
    source_locations
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
my %PHASE_RANK = (
    drive => 0,
    sample => 1,
    react => 2,
    check => 3,
);
# Backend compatibility, independent of ExecutionBuilder: eligible phases must
# match ExecutionIR, while lowering_completion records how far each generated
# task has genuinely advanced before the root scheduler invokes its successor.
my %OPERATION_PHASE = (
    reset => {eligible => 'drive', lowering_completion => 'check'},
    drive => {eligible => 'drive', lowering_completion => 'drive'},
    start => {eligible => 'drive', lowering_completion => 'react'},
    await => {eligible => 'check', lowering_completion => 'check'},
    parallel => {eligible => 'react', lowering_completion => 'check'},
    repeat => {eligible => 'react', lowering_completion => 'react'},
    expect => {eligible => 'check', lowering_completion => 'check'},
    scoreboard_expect => {eligible => 'react', lowering_completion => 'react'},
    scoreboard_check => {eligible => 'check', lowering_completion => 'check'},
    inject => {eligible => 'react', lowering_completion => 'react'},
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
    return _failure('VIAL_BACKEND_INVOCATION_ERROR', 'emit requires the exact backend class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_BACKEND_INVOCATION_ERROR', 'emit expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _emit($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error) && $error->isa('FSM::VIAL::Backend::SVPortableVerilator::Failure');
    return _failure('VIAL_BACKEND_HOST_ERROR', _sanitize_exception($error), '/');
}

sub emit_balanced_portable_qualification($class, @args) {
    my $caller = caller;
    return _failure(
        'VIAL_BACKEND_INVOCATION_ERROR',
        'balanced-portable emission is caller-sealed',
        '/',
    ) unless defined($class) && !ref($class) && $class eq __PACKAGE__
        && $caller eq $BALANCED_PORTABLE_CALLER;
    return _failure(
        'VIAL_BACKEND_INVOCATION_ERROR',
        'balanced-portable emission expects one closed argument hash',
        '/',
    ) unless @args == 1 && ref($args[0]) eq 'HASH'
        && !blessed($args[0]);
    my $result = eval { _emit($args[0], 'balanced_portable_v2') };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error)
            && $error->isa('FSM::VIAL::Backend::SVPortableVerilator::Failure');
    return _failure(
        'VIAL_BACKEND_HOST_ERROR', _sanitize_exception($error), '/',
    );
}

sub _emit($raw, $qualification_profile = undef) {
    _require_exact_keys($raw, [qw(
        execution_ir bridge_manifest backend_inputs artifact_root backend_profile
    )], 'backend emission');
    _throw('VIAL_BACKEND_INVOCATION_ERROR', 'execution_ir must be an exact FSM::VIAL::ExecutionIR object', '/execution_ir')
        unless blessed($raw->{execution_ir})
            && ref($raw->{execution_ir}) eq 'FSM::VIAL::ExecutionIR';
    _throw('VIAL_BACKEND_INVOCATION_ERROR', 'bridge_manifest must be an exact HIAL/VIAL bridge manifest object', '/bridge_manifest')
        unless blessed($raw->{bridge_manifest})
            && ref($raw->{bridge_manifest}) eq 'FSM::HIAL::VIALBridge::Manifest';
    _throw('VIAL_BACKEND_INVOCATION_ERROR', 'backend_inputs must be one unblessed hash', '/backend_inputs')
        unless ref($raw->{backend_inputs}) eq 'HASH' && !blessed($raw->{backend_inputs});
    _throw('VIAL_BACKEND_INVOCATION_ERROR', 'artifact_root must be a safe repository-relative directory', '/artifact_root')
        unless _safe_relpath($raw->{artifact_root});
    _throw('VIAL_BACKEND_UNSUPPORTED', "backend profile must be '$BACKEND_PROFILE'", '/backend_profile')
        unless defined($raw->{backend_profile}) && !ref($raw->{backend_profile})
            && $raw->{backend_profile} eq $BACKEND_PROFILE;

    my $execution = $raw->{execution_ir}->as_hashref;
    my $bridge = $raw->{bridge_manifest}->as_hashref;
    my $negotiation = _negotiate(
        $execution, $bridge, $raw->{backend_inputs},
        $qualification_profile,
    );
    if (@{$negotiation->{unsatisfied}} || @{$negotiation->{native_only}}) {
        return _failure(
            'VIAL_BACKEND_UNSUPPORTED',
            'portable SystemVerilog backend negotiation rejected one or more requirements',
            '/negotiation',
            $negotiation,
        );
    }

    my $fixture_slug = _sv_slug($execution->{fixture}{fixture_name});
    my $unit = $bridge->{units}[0];
    my $module_name = _backend_name($bridge, $unit->{unit_id}, 'module');
    my $top = $fixture_slug . '_tb';
    my ($plan_digest) = $execution->{plan_id} =~ m{\Aplan/([0-9a-f]{64})\z};
    my $operation_id = 'op-' . sha256_hex(_canonical_json({
        action => 'emit',
        artifact_root => $raw->{artifact_root},
        backend_profile => $BACKEND_PROFILE,
        bridge_manifest_id => $bridge->{manifest_id},
        plan_id => $execution->{plan_id},
    }));
    my $runtime_rel = "$BASE/src/fsmgen_vial_runtime_pkg.sv";
    my $dut_rel = "$BASE/src/dut/" . _slug($module_name) . '.sv';
    my $tb_rel = "$BASE/src/$top.sv";
    my $work_rel = ".artifacts/tmp/vial/$operation_id/work/$BACKEND_PROFILE";
    my $input_rel = "$work_rel/input";
    my $runtime = _render_runtime_package();
    my ($tb, $map_specs) = ($qualification_profile // '')
            eq 'balanced_portable_v2'
        ? _render_balanced_portable_fixture(
            execution => $execution,
            bridge => $bridge,
            module_name => $module_name,
            generated_top => $top,
            generated_relpath => $tb_rel,
        )
        : _render_fixture(
            execution => $execution,
            bridge => $bridge,
            module_name => $module_name,
            generated_top => $top,
            generated_relpath => $tb_rel,
        );
    my $dut = $raw->{backend_inputs}{dut_systemverilog}[0]{text};

    my @source_artifacts = (
        _artifact($dut_rel, 'systemverilog_source', 'systemverilog', 'generated_hial_dut', $dut,
            [$raw->{backend_inputs}{dut_systemverilog}[0]{source_id}]),
        _artifact($runtime_rel, 'systemverilog_source', 'systemverilog', 'vial_runtime_support', $runtime,
            ['docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md']),
        _artifact($tb_rel, 'systemverilog_source', 'systemverilog', 'vial_generated_fixture', $tb,
            [$execution->{plan_id}, $bridge->{manifest_id}]),
    );
    my $source_bytes = 0;
    $source_bytes += bytes::length($_->{content}) for @source_artifacts;
    _throw('VIAL_BACKEND_LIMIT_EXCEEDED', 'generated SystemVerilog exceeds the 16 MiB backend cap', '/artifacts')
        if $source_bytes > 16_777_216;

    my $compile = _command_record(
        logical_executable => 'verilator',
        working_directory => '.',
        arguments => [
            '--binary', '--timing', '--assert', '-j', '1', '--threads', '1',
            '--x-initial', '0', '--x-assign', '0', '--timescale', '1ns/1ps',
            '--top-module', $top,
            '--Mdir', "$work_rel/obj",
            map { "$input_rel/$_" } ($dut_rel, $runtime_rel, $tb_rel),
        ],
        inputs => [map { "$input_rel/$_" } ($dut_rel, $runtime_rel, $tb_rel)],
        expected_outputs => [
            "$work_rel/obj/V$top",
        ],
    );
    my $run = _command_record(
        logical_executable => "V$top",
        working_directory => '.',
        arguments => [],
        inputs => [
            "$work_rel/obj/V$top",
        ],
        expected_outputs => [
            "$raw->{artifact_root}/$BASE/evidence/runtime-trace.jsonl",
        ],
    );
    my $tool_profile = {
        schema => 'fsmgen.vial_backend_tool_profile.v1',
        schema_version => 1,
        selection_status => 'selected_not_executed',
        tool_name => 'verilator',
        qualified_version => '5.046',
        qualified_version_output => 'Verilator 5.046 2026-02-28 rev vUNKNOWN-built20260228',
        timing => JSON::PP::true,
        assertions => JSON::PP::true,
        build_jobs => 1,
        runtime_threads => 1,
        x_initial => '0',
        x_assign => '0',
        default_timescale => '1ns/1ps',
        target_language => 'SystemVerilog',
        methodology => 'plain_sv_no_uvm',
        execution_evidence => JSON::PP::false,
    };

    my @map_artifacts = map { _artifact_ref($_) } @source_artifacts;
    my $source_map = {
        schema => $SOURCE_MAP_SCHEMA,
        schema_version => 1,
        plan_id => $execution->{plan_id},
        artifacts => \@map_artifacts,
        entries => _source_map_entries($execution, $bridge, $map_specs, $runtime_rel, $dut_rel),
    };
    _throw('VIAL_BACKEND_LIMIT_EXCEEDED', 'backend source map exceeds its record cap', '/source_map/entries')
        if @{$source_map->{entries}} > 1_000_000;

    my @support_artifacts = (
        _artifact("$BASE/backend-source-map.json", 'source_map', 'json', 'backend_source_map',
            _json_text($source_map), [$execution->{plan_id}]),
        _artifact("$BASE/commands/compile-command.json", 'command_record', 'json', 'compile_command',
            _json_text($compile), [$execution->{plan_id}]),
        _artifact("$BASE/commands/run-command.json", 'command_record', 'json', 'run_command',
            _json_text($run), [$execution->{plan_id}]),
        _artifact("$BASE/evidence/tool-profile.json", 'tool_profile', 'json', 'selected_tool_profile',
            _json_text($tool_profile), ['docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md']),
    );
    my @referenced = sort { $a->{relpath} cmp $b->{relpath} }
        map { _artifact_ref($_) } (@source_artifacts, @support_artifacts);
    my $balanced_portable = ($qualification_profile // '')
        eq 'balanced_portable_v2';
    my $capability_evidence = {
        negotiation => _clone($negotiation),
        emission => 'passed',
        compile => 'not_run',
        runtime => 'not_run',
        result => 'not_produced',
        parity => 'not_evaluated',
        four_state_observation => JSON::PP::false,
        known_value_trace_only => $balanced_portable
            ? JSON::PP::false : JSON::PP::true,
        probe_adapters => _probe_adapters($execution, $bridge, $source_map),
    };
    $capability_evidence->{balanced_portable_revision_2_structural_qualification}
        = JSON::PP::true if $balanced_portable;
    my $limitations = $balanced_portable
        ? [
            'balanced portable revision-2 qualification-only structural emission; runtime behavior is not claimed',
            'emission is implemented; compile, runtime, trace, result, and parity gates have not run',
            'one exact unit/domain, no native extension, and declared probe adapters only',
        ]
        : [
            'known-value trace observation only; complete four-state observation is not claimed',
            'emission is implemented; compile, runtime, result, and parity gates have not run',
            'one unit, one clock domain, no native extension, and declared probe adapters only',
            'direct endpoint drives require an input carrier in the scenario root fiber',
            'parallel child fibers are limited to exactly one await operation',
        ];
    my $manifest = {
        schema => $BACKEND_SCHEMA,
        schema_version => 1,
        backend_profile => $BACKEND_PROFILE,
        plan_id => $execution->{plan_id},
        fixture_id => $execution->{fixture}{fixture_id},
        generated_top => $top,
        execution_profile => $execution->{profile},
        tool_profile => {
            relpath => "$BASE/evidence/tool-profile.json",
            sha256 => sha256_hex(_json_text($tool_profile)),
            selection_status => 'selected_not_executed',
        },
        capability_evidence => $capability_evidence,
        limitations => $limitations,
        artifacts => \@referenced,
        commands => {
            compile => _command_ref("$BASE/commands/compile-command.json", $compile),
            run => _command_ref("$BASE/commands/run-command.json", $run),
        },
        source_map => {
            schema => $SOURCE_MAP_SCHEMA,
            relpath => "$BASE/backend-source-map.json",
            sha256 => sha256_hex(_json_text($source_map)),
            entry_count => scalar(@{$source_map->{entries}}),
        },
        result => {
            schema => 'fsmgen.verification_result_manifest.v1',
            status => 'not_produced',
            relpath => undef,
            sha256 => undef,
        },
        cleanup => {
            staging_identity => ".artifacts/tmp/vial/$operation_id",
            state => 'not_created',
            removed => JSON::PP::false,
        },
        diagnostics => [],
    };
    my $manifest_artifact = _artifact(
        "$BASE/backend-manifest.json", 'backend_manifest', 'json', 'backend_manifest',
        _json_text($manifest), [$execution->{plan_id}, $bridge->{manifest_id}],
    );
    my @artifacts = sort { $a->{relpath} cmp $b->{relpath} }
        ($manifest_artifact, @source_artifacts, @support_artifacts);

    return _result({
        ok => JSON::PP::true,
        status => 'emitted',
        backend_profile => $BACKEND_PROFILE,
        plan_id => $execution->{plan_id},
        generated_top => $top,
        operation_id => $operation_id,
        negotiation => $negotiation,
        backend_manifest => $manifest,
        source_map => $source_map,
        trace_contract => {
            schema => $TRACE_SCHEMA,
            schema_version => 1,
            line_prefix => "FSMGEN_VIAL_TRACE_V1\t",
            maximum_records => 8_000_002,
            maximum_bytes => 67_108_864,
            validation_status => $balanced_portable
                ? 'not_run_structural_qualification_only'
                : 'validator_shipped_no_runtime_trace',
        },
        artifacts => \@artifacts,
        diagnostics => [],
    });
}

sub _negotiate(
    $execution, $bridge, $backend_inputs, $qualification_profile = undef,
) {
    return _negotiate_balanced_portable(
        $execution, $bridge, $backend_inputs,
    ) if ($qualification_profile // '') eq 'balanced_portable_v2';
    my (@required, @satisfied, @unsatisfied, @native_only, @limitations);
    push @unsatisfied, 'execution schema must be fsmgen.vial_execution_ir.v1'
        unless ($execution->{schema} // '') eq 'fsmgen.vial_execution_ir.v1';
    push @unsatisfied, 'execution profile must be core_directed_single_clock_execution_v1'
        unless ($execution->{profile} // '') eq 'core_directed_single_clock_execution_v1';
    push @unsatisfied, 'bridge schema must be fsmgen.hial_vial_bridge_manifest.v1'
        unless ($bridge->{schema} // '') eq 'fsmgen.hial_vial_bridge_manifest.v1';
    push @unsatisfied, 'exactly one bound unit is required'
        unless ref($bridge->{units}) eq 'ARRAY' && @{$bridge->{units}} == 1;
    push @unsatisfied, 'exactly one execution domain is required'
        unless ref($execution->{domains}) eq 'ARRAY' && @{$execution->{domains}} == 1;
    push @unsatisfied, 'native extensions are unsupported'
        unless ref($execution->{native_extensions}) eq 'ARRAY' && !@{$execution->{native_extensions}};

    for my $entry (@{$execution->{capability_ledger} || []}) {
        my $capability = $entry->{capability_id} // '';
        push @required, $capability;
        if (($entry->{portable_class} // '') eq 'native_only') {
            push @native_only, $capability;
        }
        elsif (!$SUPPORTED_CAPABILITY{$capability}) {
            push @unsatisfied, $capability;
        }
        elsif (($entry->{classification} // '') eq 'satisfied_by_execution_profile') {
            push @satisfied, $capability;
        }
        elsif ($capability eq 'hial_vial.bridge_probe.equivalent_adapter_required'
            && _probe_bindings_are_exact($execution, $bridge)) {
            push @satisfied, $capability;
        }
        else {
            push @unsatisfied, $capability;
        }
    }
    for my $relation (_relations($execution)) {
        push @unsatisfied, "relation:$relation->{relation_id}"
            unless $SUPPORTED_RELATION{$relation->{kind} // ''};
        push @unsatisfied, "width:$relation->{relation_id}"
            unless defined($relation->{width}) && !ref($relation->{width})
                && $relation->{width} =~ /\A[0-9]+\z/
                && $relation->{width} >= 1 && $relation->{width} <= 65_536;
    }
    push @unsatisfied, _operation_phase_errors($execution);
    my $balanced_structural_profile = scalar(grep {
        ($_->{capability_id} // '') eq $BALANCED_PORTABLE_CAPABILITY
    } @{$execution->{capability_ledger} || []});
    # Decision 0077's private revision-2 route has a separate exact-shape
    # structural renderer and no runtime claim.  Its public path already fails
    # on the dedicated capability requirements, so preserve that atomic
    # rejection instead of reinterpreting the graph as a revision-1 runtime.
    push @unsatisfied, _parallel_child_errors($execution)
        unless $balanced_structural_profile;
    push @unsatisfied, _direct_drive_errors($execution, $bridge);
    _walk_values($execution, sub ($value, $path) {
        return unless ref($value) eq 'HASH' && ($value->{kind} // '') eq 'scalar'
            && exists($value->{value_hex}) && exists($value->{known_hex})
            && exists($value->{z_hex});
        my $width = $value->{width};
        if (!defined($width) || ref($width) || $width !~ /\A[0-9]+\z/
            || $width < 1 || $width > 65_536) {
            push @unsatisfied, "scalar-width:$path";
            return;
        }
        push @unsatisfied, "unknown-value:$path"
            unless _fully_known_scalar($value);
    });
    my $dut = $backend_inputs->{dut_systemverilog};
    push @unsatisfied, 'one generated SystemVerilog DUT input is required'
        unless ref($dut) eq 'ARRAY' && @$dut == 1
            && ref($dut->[0]) eq 'HASH' && !blessed($dut->[0])
            && defined($dut->[0]{text}) && !ref($dut->[0]{text})
            && defined($dut->[0]{module_name}) && !ref($dut->[0]{module_name});

    push @limitations,
        'known_value_trace_only',
        'four_state_observation_unavailable',
        'single_unit_single_domain',
        'no_native_extensions',
        'input_carrier_direct_drive_only',
        'root_fiber_direct_drive_only',
        'single_await_parallel_children_only';
    return {
        required => [sort @required],
        satisfied => [sort @satisfied],
        unsatisfied => [sort(_unique(@unsatisfied))],
        native_only => [sort(_unique(@native_only))],
        limitations => \@limitations,
    };
}

sub _negotiate_balanced_portable($execution, $bridge, $backend_inputs) {
    my @required = map { $_->{capability_id} // '' }
        @{$execution->{capability_ledger} || []};
    my @unsatisfied = _balanced_portable_shape_errors(
        $execution, $bridge, $backend_inputs,
    );
    for my $relation (_relations($execution)) {
        push @unsatisfied, "relation:$relation->{relation_id}"
            unless $SUPPORTED_RELATION{$relation->{kind} // ''};
        push @unsatisfied, "width:$relation->{relation_id}"
            unless defined($relation->{width}) && !ref($relation->{width})
                && $relation->{width} =~ /\A[0-9]+\z/
                && $relation->{width} >= 1 && $relation->{width} <= 65_536;
    }
    push @unsatisfied, _operation_phase_errors($execution);
    _walk_values($execution, sub ($value, $path) {
        return unless ref($value) eq 'HASH'
            && ($value->{kind} // '') eq 'scalar'
            && exists($value->{value_hex}) && exists($value->{known_hex})
            && exists($value->{z_hex});
        my $width = $value->{width};
        if (!defined($width) || ref($width)
                || $width !~ /\A[0-9]+\z/
                || $width < 1 || $width > 65_536) {
            push @unsatisfied, "scalar-width:$path";
            return;
        }
        push @unsatisfied, "unknown-value:$path"
            unless _fully_known_scalar($value);
    });
    my @satisfied = @unsatisfied ? () : sort @required;
    return {
        required => [sort @required],
        satisfied => \@satisfied,
        unsatisfied => [sort(_unique(@unsatisfied))],
        native_only => [],
        limitations => [qw(
            qualification_only_structural_emission
            balanced_portable_revision_2_exact_shape
            known_value_runtime_not_claimed
            compile_runtime_trace_result_not_run
            single_unit_single_domain
            no_native_extensions
        )],
    };
}

sub _balanced_portable_shape_errors($execution, $bridge, $backend_inputs) {
    my @error;
    my $reject = sub ($condition, $message) {
        push @error, $message unless $condition;
    };

    $reject->(
        ($execution->{schema} // '') eq 'fsmgen.vial_execution_ir.v1'
            && ($execution->{schema_version} // 0) == 1
            && ($execution->{profile} // '')
                eq 'core_directed_single_clock_execution_v1',
        'balanced:execution-envelope',
    );
    $reject->(
        ($bridge->{schema} // '')
                eq 'fsmgen.hial_vial_bridge_manifest.v1'
            && ($bridge->{schema_version} // 0) == 1
            && ($bridge->{profile} // '') eq 'core_single_unit_v1',
        'balanced:bridge-envelope',
    );
    my $bridge_identity = _clone($bridge);
    my $manifest_id = delete $bridge_identity->{manifest_id};
    $reject->(
        defined($manifest_id) && !ref($manifest_id)
            && $manifest_id eq 'bridge/'
                . sha256_hex(_canonical_json($bridge_identity)),
        'balanced:bridge-identity',
    );
    $reject->(
        ref($execution->{bridge_identity}) eq 'HASH'
            && ($execution->{bridge_identity}{manifest_id} // '')
                eq ($bridge->{manifest_id} // '')
            && ($execution->{bridge_identity}{schema} // '')
                eq ($bridge->{schema} // '')
            && ($execution->{bridge_identity}{schema_version} // 0)
                == ($bridge->{schema_version} // -1)
            && ($execution->{bridge_identity}{profile} // '')
                eq ($bridge->{profile} // ''),
        'balanced:execution-bridge-identity',
    );

    my @expected_capability = sort qw(
        hial_vial.bridge_manifest.v1
        hial_vial.bridge_probe.equivalent_adapter_required
        hial_vial.bridge_profile.core_single_unit_v1
        hial_vial.bridge_qualification.balanced_portable_v2
        hial_vial.bridge_source.ial1
    );
    $reject->(
        _canonical_json([sort @{$bridge->{required_capabilities} || []}])
            eq _canonical_json(\@expected_capability),
        'balanced:bridge-capabilities',
    );
    my @ledger_spec = (
        ['hial_vial.bridge_manifest.v1', 'bridge_manifest',
            'satisfied_by_execution_profile', 'portable'],
        ['hial_vial.bridge_probe.equivalent_adapter_required',
            'bridge_manifest', 'required_from_backend',
            'portable_with_equivalent_adapter'],
        ['hial_vial.bridge_profile.core_single_unit_v1', 'bridge_manifest',
            'satisfied_by_execution_profile', 'portable'],
        [$BALANCED_PORTABLE_CAPABILITY, 'bridge_manifest',
            'qualification_only',
            'portable_with_exact_emitter_qualification'],
        ['hial_vial.bridge_source.ial1', 'bridge_manifest',
            'satisfied_by_execution_profile', 'portable'],
        ['vial.binding.directional_representation.v1', 'execution_profile',
            'satisfied_by_execution_profile', 'portable'],
        ['vial.execution_ir.v1', 'execution_profile',
            'satisfied_by_execution_profile', 'portable'],
        ['vial.execution_profile.core_directed_single_clock_execution_v1',
            'execution_profile', 'satisfied_by_execution_profile', 'portable'],
        ['vial.logical_time.drive_sample_react_check_v1', 'execution_profile',
            'satisfied_by_execution_profile', 'portable'],
        ['vial.plan.v1', 'execution_profile',
            'satisfied_by_execution_profile', 'portable'],
        ['vial.profile.core_directed_single_clock_v1', 'semantic_ir',
            'satisfied_by_execution_profile', 'portable'],
        ['vial.random.sha256_counter_rejection_v1', 'execution_profile',
            'satisfied_by_execution_profile', 'portable'],
        ['vial.replay.v1', 'execution_profile',
            'satisfied_by_execution_profile', 'portable'],
        ['vial.semantic_ir.v1', 'semantic_ir',
            'satisfied_by_execution_profile', 'portable'],
        ['vial.source.v1', 'semantic_ir',
            'satisfied_by_execution_profile', 'portable'],
    );
    my @expected_ledger = map {
        _balanced_capability_entry(@$_)
    } @ledger_spec;
    @expected_ledger = sort {
        $a->{capability_id} cmp $b->{capability_id}
    } @expected_ledger;
    $reject->(
        _canonical_json($execution->{capability_ledger} || [])
            eq _canonical_json(\@expected_ledger),
        'balanced:capability-ledger',
    );

    my @protocol = @{$bridge->{protocols} || []};
    my $protocol = @protocol == 1 ? $protocol[0] : {};
    my @facts = sort { ($a->{name} // '') cmp ($b->{name} // '') }
        @{$protocol->{facts} || []};
    $reject->(
        @protocol == 1
            && ($protocol->{protocol_id} // '')
                eq 'protocol/architecture_scale_probe'
            && ($protocol->{name} // '') eq 'architecture_scale_probe'
            && ($protocol->{profile} // '') eq 'balanced_portable'
            && ($protocol->{revision} // '') eq '2'
            && ($protocol->{role} // '') eq 'verification'
            && ($protocol->{unit_id} // '')
                eq 'unit/vial_architecture_scale_balanced_portable'
            && _canonical_json(\@facts) eq _canonical_json([
                {name => 'qualified_emitter', value => $BACKEND_PROFILE},
                {name => 'scale_evidence_only', value => 'true'},
            ]),
        'balanced:protocol',
    );
    my @route_layer = map { $_->{layer} // '' }
        @{$bridge->{review_route}{stages} || []};
    $reject->(
        ($bridge->{review_route}{authored_layer} // '') eq 'IAL1'
            && !$bridge->{review_route}{direct_ial2_to_verification}
            && _canonical_json(\@route_layer)
                eq _canonical_json([qw(IAL1 IAL0)]),
        'balanced:review-route',
    );

    my @unit = @{$bridge->{units} || []};
    my @domain = @{$bridge->{domains} || []};
    $reject->(
        @unit == 1
            && ($unit[0]{unit_id} // '')
                eq 'unit/vial_architecture_scale_balanced_portable'
            && ($unit[0]{name} // '')
                eq 'vial_architecture_scale_balanced_portable',
        'balanced:unit',
    );
    $reject->(
        @domain == 1
            && ($domain[0]{domain_id} // '') eq 'domain/balanced'
            && ($domain[0]{unit_id} // '')
                eq 'unit/vial_architecture_scale_balanced_portable'
            && ($domain[0]{clock_endpoint_id} // '') eq 'endpoint/clk'
            && ($domain[0]{reset_endpoint_id} // '') eq 'endpoint/rst_n'
            && ($domain[0]{active_edge} // '') eq 'rising'
            && ($domain[0]{reset_polarity} // '') eq 'active_low',
        'balanced:domain',
    );

    my @expected_endpoint = (
        ['clk', 'clock'],
        (map { [sprintf('endpoint_%08d', $_), 'data'] } 0 .. 125),
        ['rst_n', 'reset'],
    );
    my @endpoint = @{$bridge->{endpoints} || []};
    my $endpoints_exact = @endpoint == @expected_endpoint;
    if ($endpoints_exact) {
        for my $index (0 .. $#expected_endpoint) {
            my ($name, $role) = @{$expected_endpoint[$index]};
            my $item = $endpoint[$index];
            $endpoints_exact = 0, last
                unless ($item->{endpoint_id} // '') eq "endpoint/$name"
                    && ($item->{name} // '') eq $name
                    && ($item->{role} // '') eq $role
                    && ($item->{direction} // '') eq 'input'
                    && ($item->{type_id} // '') eq 'type/logic_u1'
                    && ($item->{unit_id} // '')
                        eq 'unit/vial_architecture_scale_balanced_portable'
                    && ($item->{domain_id} // '') eq 'domain/balanced';
        }
    }
    $reject->($endpoints_exact, 'balanced:endpoints');

    my @probe = @{$bridge->{probes} || []};
    my $probes_exact = @probe == 32;
    if ($probes_exact) {
        for my $index (0 .. 31) {
            my $name = sprintf('probe_%08d', $index);
            my $item = $probe[$index];
            $probes_exact = 0, last
                unless ($item->{probe_id} // '') eq "probe/$name"
                    && ($item->{name} // '') eq $name
                    && ($item->{type_id} // '') eq 'type/logic_u1'
                    && ($item->{adapter_requirement} // '')
                        eq 'equivalent_adapter_required'
                    && ($item->{access} // '') eq 'verification_probe';
        }
    }
    $reject->($probes_exact, 'balanced:probes');

    my @transaction = @{$bridge->{transactions} || []};
    my $transactions_exact = @transaction == 16;
    if ($transactions_exact) {
        for my $tx_index (0 .. 15) {
            my $name = sprintf('transaction_%08d', $tx_index);
            my $item = $transaction[$tx_index];
            $transactions_exact = 0, last
                unless ($item->{transaction_id} // '') eq "transaction/$name"
                    && ($item->{name} // '') eq $name
                    && @{$item->{fields} || []} == 109;
            for my $field_index (0 .. 108) {
                my $endpoint = sprintf('endpoint_%08d', $field_index);
                my $field = $item->{fields}[$field_index];
                $transactions_exact = 0, last
                    unless ($field->{name} // '') eq $endpoint
                        && ($field->{endpoint_id} // '') eq "endpoint/$endpoint"
                        && ($field->{type_id} // '') eq 'type/logic_u1'
                        && ($field->{direction} // '') eq 'drive'
                        && ($field->{phase_role} // '') eq 'unspecified';
            }
            last unless $transactions_exact;
        }
    }
    $reject->($transactions_exact, 'balanced:transactions');

    my @event = @{$bridge->{events} || []};
    my $events_exact = @event == 128;
    if ($events_exact) {
        my @actual_ids = sort map { $_->{event_id} // '' } @event;
        my @expected_ids = sort(
            (map {
                'event/transaction_00000000/'
                    . sprintf('bridge_event_%08d', $_)
            } 0 .. 112),
            (map {
                sprintf('event/transaction_%08d/on', $_)
            } 1 .. 15),
        );
        $events_exact = 0 unless _canonical_json(\@actual_ids)
            eq _canonical_json(\@expected_ids);
        my %transaction_id = map { ($_->{transaction_id} // '') => 1 }
            @transaction;
        for my $item (@event) {
            my $name = $item->{name} // '';
            my $transaction_id = $item->{transaction_id} // '';
            $events_exact = 0, last
                unless $transaction_id
                        =~ /\Atransaction\/transaction_[0-9]{8}\z/
                    && $transaction_id{$transaction_id}
                    && ($item->{event_id} // '')
                        eq "event/" . substr($transaction_id, 12) . "/$name"
                    && ($item->{kind} // '') eq 'predicate'
                    && ($item->{phase} // '') eq 'sample';
        }
    }
    $reject->($events_exact, 'balanced:events');

    my %sv_binding = map {
        ($_->{target_language} // '') eq 'systemverilog'
            ? (($_->{semantic_id} // '') => $_) : ()
    } @{$bridge->{backend_bindings} || []};
    my $backend_exact = @{$bridge->{backend_bindings} || []} == 322
        && keys(%sv_binding) == 161;
    if ($backend_exact) {
        for my $item (@endpoint) {
            my $binding = $sv_binding{$item->{endpoint_id}};
            $backend_exact = 0, last
                unless $binding
                    && ($binding->{target_kind} // '') eq 'port'
                    && ($binding->{target_name} // '') eq $item->{name}
                    && ($binding->{status} // '') eq 'declared';
        }
    }
    if ($backend_exact) {
        for my $item (@probe) {
            my $binding = $sv_binding{$item->{probe_id}};
            $backend_exact = 0, last
                unless $binding
                    && ($binding->{target_kind} // '') eq 'probe_adapter'
                    && ($binding->{target_name} // '') eq $item->{name}
                    && ($binding->{status} // '') eq 'adapter_required';
        }
    }
    my $unit_binding = $sv_binding{
        'unit/vial_architecture_scale_balanced_portable'};
    $backend_exact = 0 unless $unit_binding
        && ($unit_binding->{target_kind} // '') eq 'module'
        && ($unit_binding->{target_name} // '')
            eq 'vial_architecture_scale_balanced_portable'
        && ($unit_binding->{status} // '') eq 'declared';
    $reject->($backend_exact, 'balanced:backend-bindings');

    my $resources = $execution->{resource_summary} || {};
    my %expected_resource = (
        selected_units => 1,
        selected_domains => 1,
        selected_fixtures => 1,
        selected_scenarios => 32,
        expanded_operations_total => 1_024,
        total_fibers => 128,
        simultaneous_live_fibers => 32,
        bindings => 2_048,
        execution_types => 512,
        model_instances => 32,
        scalar_state_cells => 512,
        scoreboard_instances => 32,
        scoreboard_declared_capacity => 4_096,
        coverpoints => 256,
        coverage_bins_and_cross_tuples => 4_096,
        faults => 32,
        random_occurrences => 1_024,
        native_extensions => 0,
        native_artifacts => 0,
        native_identity_bytes => 0,
        source_map_records => 4_079,
    );
    $reject->(
        !scalar(grep {
            !defined($resources->{$_}) || ref($resources->{$_})
                || $resources->{$_} != $expected_resource{$_}
        } sort keys %expected_resource),
        'balanced:resource-summary',
    );
    my $bindings = $execution->{bindings} || {};
    my $execution_field_count = 0;
    $execution_field_count += @{$_->{fields} || []}
        for @{$bindings->{transactions} || []};
    $reject->(
        @{$bindings->{domains} || []} == 1
            && @{$bindings->{endpoints} || []} == 126
            && @{$bindings->{probes} || []} == 32
            && @{$bindings->{transactions} || []} == 16
            && $execution_field_count == 1_744
            && @{$execution->{events} || []} == 128
            && @{$execution->{type_table} || []} == 512
            && @{$execution->{models} || []} == 32
            && @{$execution->{scoreboards} || []} == 32
            && @{$execution->{coverage}{coverpoints} || []} == 256
            && @{$execution->{faults} || []} == 32
            && @{$execution->{scenarios} || []} == 32
            && @{$execution->{operation_graph}{operations} || []} == 1_024
            && @{$execution->{randomness}{decisions} || []} == 1_024
            && @{$execution->{native_extensions} || []} == 0,
        'balanced:execution-shape',
    );

    my @backend_keys = sort keys %{$backend_inputs || {}};
    my $inputs_exact = ref($backend_inputs) eq 'HASH'
        && !blessed($backend_inputs)
        && _canonical_json(\@backend_keys)
            eq _canonical_json([qw(dut_systemverilog dut_vhdl)]);
    my $dut = $inputs_exact ? $backend_inputs->{dut_systemverilog} : undef;
    $inputs_exact &&= ref($dut) eq 'ARRAY' && @$dut == 1
        && ref($dut->[0]) eq 'HASH' && !blessed($dut->[0]);
    if ($inputs_exact) {
        my $input = $dut->[0];
        my @keys = sort keys %$input;
        $inputs_exact = _canonical_json(\@keys) eq _canonical_json([sort qw(
            artifact_name byte_length content_sha256 module_name source_id
            text unit_id
        )])
            && ($input->{unit_id} // '')
                eq 'unit/vial_architecture_scale_balanced_portable'
            && ($input->{module_name} // '')
                eq 'vial_architecture_scale_balanced_portable'
            && ($input->{artifact_name} // '')
                eq 'vial_architecture_scale_balanced_portable.sv'
            && ($input->{source_id} // '')
                eq 'generated/vial-scale/balanced-portable/'
                    . 'vial_architecture_scale_balanced_portable.isf'
            && defined($input->{text}) && !ref($input->{text})
            && ($input->{byte_length} // -1) == bytes::length($input->{text})
            && ($input->{content_sha256} // '') eq sha256_hex($input->{text})
            && $input->{text} =~
                /\bmodule\s+vial_architecture_scale_balanced_portable\b/;
    }
    $reject->($inputs_exact, 'balanced:backend-inputs');
    return @error;
}

sub _balanced_capability_entry(
    $capability_id, $origin, $classification, $portable_class,
) {
    return {
        capability_id => $capability_id,
        origins => [$origin],
        classification => $classification,
        portable_class => $portable_class,
        evidence_ids => [$origin],
    };
}

sub _render_runtime_package() {
    return <<'SV';
package fsmgen_vial_runtime_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  function automatic string vial_json_bool(input bit value);
    return value ? "true" : "false";
  endfunction

  function automatic string vial_trace_record(
    input string record_kind,
    input string plan_id,
    input string run_id_json,
    input int unsigned record_sequence,
    input string payload_json
  );
    string sequence_json;
    sequence_json.itoa(record_sequence);
    return {"{\"payload\":", payload_json,
            ",\"plan_id\":\"", plan_id,
            "\",\"record_kind\":\"", record_kind,
            "\",\"run_id\":", run_id_json,
            ",\"schema\":\"fsmgen.vial_sv_runtime_trace.v1\"",
            ",\"schema_version\":1,\"sequence\":", sequence_json, "}"};
  endfunction
endpackage
SV
}

sub _render_balanced_portable_fixture(%arg) {
    my $execution = $arg{execution};
    my $bridge = $arg{bridge};
    my $top = $arg{generated_top};
    my $relpath = $arg{generated_relpath};
    my %type = map { $_->{type_id} => $_ } @{$bridge->{types}};
    my %backend = map {
        ($_->{target_language} // '') eq 'systemverilog'
            ? (($_->{semantic_id} // '') => $_) : ()
    } @{$bridge->{backend_bindings}};
    my %execution_endpoint = map {
        ($_->{endpoint_id} // '') => $_
    } @{$execution->{bindings}{endpoints} || []};
    my @line;
    my @spec;
    my $push = sub (@text) { push @line, @text };

    $push->('// Balanced portable revision-2 qualification-only structural emission.');
    $push->("// Generated from $execution->{plan_id}; runtime behavior is not claimed.");
    $push->("module $top;");
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('  import fsmgen_vial_runtime_pkg::*;');
    $push->('');

    for my $index (0 .. $#{$bridge->{endpoints}}) {
        my $endpoint = $bridge->{endpoints}[$index];
        my $width = $type{$endpoint->{type_id}}{width};
        my $name = $backend{$endpoint->{endpoint_id}}{target_name};
        my $start = @line + 1;
        $push->('  logic '
            . ($width > 1 ? '[' . ($width - 1) . ':0] ' : '')
            . "$name;");
        my @semantic = ($endpoint->{endpoint_id});
        push @semantic, $execution_endpoint{$endpoint->{endpoint_id}}{binding_id}
            if $execution_endpoint{$endpoint->{endpoint_id}};
        push @spec, _map_spec(
            relpath => $relpath,
            start => $start,
            end => $start,
            symbol => $name,
            role => 'balanced_endpoint_binding',
            plan_paths => ["/bindings/endpoints/$index"],
            semantic_paths => \@semantic,
            bridge_paths => ["/endpoints/$index"],
            locations => [],
        );
    }
    $push->('');

    my @ports = map {
        my $name = $backend{$_->{endpoint_id}}{target_name};
        "    .$name($name)"
    } @{$bridge->{endpoints}};
    my $dut_start = @line + 1;
    $push->("  $arg{module_name} dut (");
    for my $index (0 .. $#ports) {
        $push->($ports[$index] . ($index == $#ports ? '' : ','));
    }
    $push->('  );');
    push @spec, _map_spec(
        relpath => $relpath,
        start => $dut_start,
        end => scalar(@line),
        symbol => 'dut',
        role => 'balanced_unit_binding',
        plan_paths => ['/bindings/unit'],
        semantic_paths => [
            $bridge->{units}[0]{unit_id},
            $execution->{bindings}{unit}{binding_id},
        ],
        bridge_paths => ['/units/0'],
        locations => [$execution->{bindings}{unit}{source_location}],
    );
    $push->('');

    for my $index (0 .. $#{$bridge->{probes}}) {
        my $probe = $bridge->{probes}[$index];
        my $binding = $backend{$probe->{probe_id}};
        my $execution_binding = $execution->{bindings}{probes}[$index];
        my $width = $type{$probe->{type_id}}{width};
        my $symbol = 'vial_probe_' . _sv_slug($probe->{name});
        my $start = @line + 1;
        $push->('  wire '
            . ($width > 1 ? '[' . ($width - 1) . ':0] ' : '')
            . "$symbol = dut.$binding->{target_name};");
        push @spec, _map_spec(
            relpath => $relpath,
            start => $start,
            end => $start,
            symbol => $symbol,
            role => 'generated_probe_adapter',
            plan_paths => ["/bindings/probes/$index"],
            semantic_paths => [
                $probe->{probe_id}, $execution_binding->{binding_id},
            ],
            bridge_paths => ["/probes/$index", '/backend_bindings'],
            locations => [$execution_binding->{source_location}],
        );
    }
    $push->('');

    my $domain = $execution->{bindings}{domains}[0];
    my $domain_symbol = 'vial_balanced_domain';
    my $domain_start = @line + 1;
    $push->('  localparam string ' . $domain_symbol . ' = "'
        . _sv_string($domain->{binding_id}) . '";');
    push @spec, _map_spec(
        relpath => $relpath,
        start => $domain_start,
        end => $domain_start,
        symbol => $domain_symbol,
        role => 'balanced_domain_binding',
        plan_paths => ['/bindings/domains/0'],
        semantic_paths => [$domain->{domain_id}, $domain->{binding_id}],
        bridge_paths => ['/domains/0'],
        locations => [$domain->{source_location}],
    );

    for my $tx_index (0 .. $#{$execution->{bindings}{transactions}}) {
        my $transaction = $execution->{bindings}{transactions}[$tx_index];
        my $tx_symbol = sprintf('vial_transaction_binding_%08d', $tx_index);
        my $tx_start = @line + 1;
        $push->('  localparam string ' . $tx_symbol . ' = "'
            . _sv_string($transaction->{binding_id}) . '";');
        push @spec, _map_spec(
            relpath => $relpath,
            start => $tx_start,
            end => $tx_start,
            symbol => $tx_symbol,
            role => 'balanced_transaction_binding',
            plan_paths => ["/bindings/transactions/$tx_index"],
            semantic_paths => [
                $transaction->{transaction_id}, $transaction->{binding_id},
            ],
            bridge_paths => ["/transactions/$tx_index"],
            locations => [$transaction->{source_location}],
        );
        for my $field_index (0 .. $#{$transaction->{fields}}) {
            my $field = $transaction->{fields}[$field_index];
            my $field_symbol = sprintf(
                'vial_transaction_field_%08d_%08d',
                $tx_index, $field_index,
            );
            my $field_start = @line + 1;
            $push->('  localparam string ' . $field_symbol . ' = "'
                . _sv_string($field->{binding_id}) . '";');
            push @spec, _map_spec(
                relpath => $relpath,
                start => $field_start,
                end => $field_start,
                symbol => $field_symbol,
                role => 'balanced_transaction_field_binding',
                plan_paths => [
                    "/bindings/transactions/$tx_index/fields/$field_index",
                ],
                semantic_paths => [
                    $field->{semantic_id}, $field->{binding_id},
                ],
                bridge_paths => [
                    "/transactions/$tx_index/fields/$field_index",
                ],
                locations => [$field->{source_location}],
            );
        }
    }

    for my $event_index (0 .. $#{$execution->{events}}) {
        my $event = $execution->{events}[$event_index];
        my $symbol = sprintf('vial_event_binding_%08d', $event_index);
        my $start = @line + 1;
        $push->('  localparam string ' . $symbol . ' = "'
            . _sv_string($event->{binding_id}) . '";');
        push @spec, _map_spec(
            relpath => $relpath,
            start => $start,
            end => $start,
            symbol => $symbol,
            role => 'balanced_event_binding',
            plan_paths => ["/events/$event_index"],
            semantic_paths => [
                $event->{event_id}, $event->{binding_id},
            ],
            bridge_paths => ["/events/$event_index"],
            locations => [$event->{source_location}],
        );
    }
    $push->('');

    for my $index (0 .. $#{$execution->{operation_graph}{operations}}) {
        my $operation = $execution->{operation_graph}{operations}[$index];
        my $symbol = _operation_symbol($operation);
        my $start = @line + 1;
        $push->("  task automatic $symbol;");
        $push->('    // Qualification-only structural operation: '
            . $operation->{kind});
        $push->('  endtask');
        push @spec, _map_spec(
            relpath => $relpath,
            start => $start,
            end => scalar(@line),
            symbol => $symbol,
            role => "operation_$operation->{kind}",
            plan_paths => ["/operation_graph/operations/$index"],
            semantic_paths => [
                $operation->{operation_id}, $operation->{fiber_id},
            ],
            bridge_paths => [],
            locations => [$operation->{source_location}],
        );
    }
    $push->('');

    for my $index (0 .. $#{$execution->{scenarios}}) {
        my $scenario = $execution->{scenarios}[$index];
        my $symbol = 'vial_scenario_' . _sv_slug($scenario->{name});
        my $start = @line + 1;
        $push->("  task automatic $symbol;");
        $push->('    // Qualification-only structural scenario.');
        $push->('  endtask');
        push @spec, _map_spec(
            relpath => $relpath,
            start => $start,
            end => scalar(@line),
            symbol => $symbol,
            role => 'balanced_scenario',
            plan_paths => ["/scenarios/$index"],
            semantic_paths => [$scenario->{scenario_id}],
            bridge_paths => [],
            locations => [$scenario->{source_location}],
        );
    }
    $push->('');

    my $initial_start = @line + 1;
    $push->('  initial begin');
    for my $endpoint (@{$bridge->{endpoints}}) {
        my $name = $backend{$endpoint->{endpoint_id}}{target_name};
        $push->("    $name = '0;");
    }
    $push->('    #1;');
    $push->('    $finish;');
    $push->('  end');
    push @spec, _map_spec(
        relpath => $relpath,
        start => $initial_start,
        end => scalar(@line),
        symbol => 'initial',
        role => 'balanced_structural_scheduler',
        plan_paths => ['/fixture', '/scenarios'],
        semantic_paths => [$execution->{fixture}{fixture_id}],
        bridge_paths => [],
        locations => [$execution->{fixture}{source_location}],
    );
    $push->('endmodule');
    return (join("\n", @line) . "\n", \@spec);
}

sub _render_fixture(%arg) {
    my $execution = $arg{execution};
    my $bridge = $arg{bridge};
    my $top = $arg{generated_top};
    my $relpath = $arg{generated_relpath};
    my %type = map { $_->{type_id} => $_ } @{$bridge->{types}};
    my %backend = map {
        $_->{target_language} eq 'systemverilog' ? ($_->{semantic_id} => $_) : ()
    } @{$bridge->{backend_bindings}};
    my %endpoint = map { $_->{endpoint_id} => $_ } @{$bridge->{endpoints}};
    my %execution_endpoint = map {
        ($_->{semantic_id} // '') => $_
    } @{$execution->{bindings}{endpoints} || []};
    my @line;
    my @spec;
    my $push = sub (@text) { push @line, @text };
    $push->("// Generated from $execution->{plan_id}; portable VIAL emission only.");
    $push->('module ' . $top . ';');
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('  import fsmgen_vial_runtime_pkg::*;');
    $push->('');
    for my $index (0 .. $#{$bridge->{endpoints}}) {
        my $ep = $bridge->{endpoints}[$index];
        my $width = $type{$ep->{type_id}}{width};
        my $name = $backend{$ep->{endpoint_id}}{target_name};
        my $start = @line + 1;
        $push->('  logic ' . ($width > 1 ? '[' . ($width - 1) . ':0] ' : '') . "$name;");
        push @spec, _map_spec(
            relpath => $relpath, start => $start, end => $start,
            symbol => $name, role => 'driver_or_sample_binding',
            plan_paths => ["/bindings/endpoints/$index"],
            semantic_paths => [$ep->{endpoint_id}],
            bridge_paths => ["/endpoints/$index"],
            locations => [],
        );
    }
    $push->('');
    my @ports = map {
        my $name = $backend{$_->{endpoint_id}}{target_name};
        "    .$name($name)"
    } @{$bridge->{endpoints}};
    my $dut_start = @line + 1;
    $push->("  $arg{module_name} dut (");
    for my $index (0 .. $#ports) {
        $push->($ports[$index] . ($index == $#ports ? '' : ','));
    }
    $push->('  );');
    push @spec, _map_spec(
        relpath => $relpath, start => $dut_start, end => scalar(@line),
        symbol => 'dut', role => 'bound_dut_instance',
        plan_paths => ['/bindings/unit'], semantic_paths => [$bridge->{units}[0]{unit_id}],
        bridge_paths => ['/units/0'], locations => [],
    );
    $push->('');

    for my $index (0 .. $#{$bridge->{probes}}) {
        my $probe = $bridge->{probes}[$index];
        my $binding = $backend{$probe->{probe_id}};
        my $width = $type{$probe->{type_id}}{width};
        my $symbol = 'vial_probe_' . _sv_slug($probe->{name});
        my $start = @line + 1;
        $push->('  wire ' . ($width > 1 ? '[' . ($width - 1) . ':0] ' : '')
            . "$symbol = dut.$binding->{target_name};");
        push @spec, _map_spec(
            relpath => $relpath, start => $start, end => $start,
            symbol => $symbol, role => 'generated_probe_adapter',
            plan_paths => ["/bindings/probes/$index"], semantic_paths => [$probe->{probe_id}],
            bridge_paths => ["/probes/$index", '/backend_bindings'], locations => [],
        );
    }
    $push->('');
    $push->('  longint unsigned vial_cycle;');
    $push->('  int unsigned vial_sequence;');
    $push->('  bit vial_transaction_active;');
    $push->('  bit vial_transaction_accepted;');
    $push->('  bit vial_scenario_failed;');
    $push->('  bit vial_any_scenario_failed;');
    $push->('  bit vial_scoreboard_expected_active;');
    $push->('  bit vial_scoreboard_failed;');
    $push->('  bit vial_fault_active;');
    $push->('  int unsigned vial_transaction_static_rank;');
    $push->('  longint unsigned vial_transaction_request_cycle;');
    $push->('  longint unsigned vial_transaction_accept_cycle;');
    $push->('  string vial_current_run_id;');
    $push->('  string vial_current_run_id_json;');
    $push->('  string vial_current_scenario_id;');
    $push->('  string vial_transaction_fields_json;');
    $push->('  string vial_transaction_handle_id;');
    $push->('  string vial_transaction_binding_id;');
    $push->('  string vial_transaction_operation_id;');
    $push->('  string vial_transaction_request_time_json;');
    $push->('  string vial_transaction_accept_time_json;');
    $push->('  string vial_scoreboard_expected_fields_json;');
    $push->('  string vial_scoreboard_instance_id_json;');
    $push->('  string vial_fault_id_json;');
    $push->('  string vial_fault_target_id_json;');
    $push->('  string vial_fault_original_value_json;');
    $push->('  string vial_fault_substituted_value_json;');
    for my $kind (qw(events drives samples transactions expectations models scoreboards coverage faults fibers)) {
        $push->("  longint unsigned vial_trace_${kind}_count;");
        $push->("  longint unsigned vial_run_${kind}_count;");
    }
    $push->('  longint unsigned vial_coverage_stalled_count;');
    $push->('  longint unsigned vial_coverage_not_stalled_count;');
    for my $event (@{$execution->{events}}) {
        $push->('  longint unsigned vial_event_' . _sv_slug($event->{name}) . '_count;');
    }
    $push->('');
    $push->('  function automatic string vial_logical_time_json(');
    $push->('    input int unsigned phase_rank,');
    $push->('    input int unsigned static_operation_rank,');
    $push->('    input int unsigned local_emission_index,');
    $push->('    input string semantic_id');
    $push->('  );');
    $push->('    return $sformatf("{\"cycle\":%0d,\"domain_rank\":0,\"local_emission_index\":%0d,\"phase_rank\":%0d,\"semantic_id\":\"%s\",\"static_operation_rank\":%0d}",');
    $push->('      vial_cycle, local_emission_index, phase_rank, semantic_id, static_operation_rank);');
    $push->('  endfunction');
    $push->('');
    $push->('  function automatic string vial_public_time_json(');
    $push->('    input longint unsigned cycle,');
    $push->('    input string phase');
    $push->('  );');
    $push->('    return $sformatf("{\"cycle\":%0d,\"domain_id\":\"%s\",\"ordinal\":0,\"phase\":\"%s\"}",');
    $push->('      cycle, "' . _sv_string($execution->{domains}[0]{domain_id}) . '", phase);');
    $push->('  endfunction');
    $push->('');
    $push->('  function automatic string vial_uint_json(input longint unsigned value);');
    $push->('    return $sformatf("%0d", value);');
    $push->('  endfunction');
    $push->('');
    $push->('  function automatic string vial_uint32_json(input int unsigned value);');
    $push->('    return $sformatf("%0d", value);');
    $push->('  endfunction');
    $push->('');
    $push->('  function automatic string vial_u64_value_json(input longint unsigned value);');
    $push->('    return $sformatf("{\"kind\":\"scalar\",\"known_hex\":\"ffffffffffffffff\",\"signed\":0,\"state_domain\":\"two_state\",\"type_id\":\"runtime-type/u64\",\"value_hex\":\"%016x\",\"width\":64,\"z_hex\":\"0000000000000000\"}", value);');
    $push->('  endfunction');
    $push->('');
    $push->('  function automatic string vial_record_id_json(');
    $push->('    input string family,');
    $push->('    input string semantic_id,');
    $push->('    input longint unsigned occurrence_index');
    $push->('  );');
    $push->('    return $sformatf("\"record/%s/%s/%s/%0d\"",');
    $push->('      vial_current_scenario_id, family, semantic_id, occurrence_index);');
    $push->('  endfunction');
    $push->('');
    $push->('  task automatic vial_emit(input string record_kind, input string payload_json);');
    $push->('    $display("FSMGEN_VIAL_TRACE_V1\\t%s", vial_trace_record(record_kind, "'
        . $execution->{plan_id} . '", vial_current_run_id_json, vial_sequence, payload_json));');
    $push->('    vial_sequence = vial_sequence + 1;');
    for my $kind (qw(events drives samples transactions expectations models scoreboards coverage faults fibers)) {
        $push->("    if (record_kind == \"$kind\") vial_trace_${kind}_count = vial_trace_${kind}_count + 1;");
        $push->("    if (record_kind == \"$kind\") vial_run_${kind}_count = vial_run_${kind}_count + 1;");
    }
    $push->('  endtask');
    $push->('');
    $push->('  function automatic string vial_trace_counts_json;');
    $push->('    string result;');
    $push->('    bit comma;');
    $push->('    result = "{";');
    $push->('    comma = 0;');
    my %fixed_count = (
        footer => '1',
        header => '1',
        scenario_end => scalar(@{$execution->{scenarios}}),
        scenario_start => scalar(@{$execution->{scenarios}}),
    );
    for my $kind (sort { $a cmp $b } (keys(%fixed_count), qw(
        events drives samples transactions expectations models scoreboards
        coverage faults fibers
    ))) {
        my $count = exists($fixed_count{$kind})
            ? $fixed_count{$kind} : "vial_trace_${kind}_count";
        $push->("    if ($count != 0) begin");
        $push->('      result = {result, comma ? "," : "", "\"'
            . $kind . '\":", vial_uint_json(' . $count . ')};');
        $push->('      comma = 1;');
        $push->('    end');
    }
    $push->('    return {result, "}"};');
    $push->('  endfunction');
    $push->('');
    my $domain = $bridge->{domains}[0];
    my $clock = $backend{$domain->{clock_endpoint_id}}{target_name};
    my $inactive = $domain->{active_edge} eq 'rising' ? 'negedge' : 'posedge';
    my $scheduler_start = @line + 1;
    $push->("  always #1 $clock = ~$clock;");
    my $hsel = _endpoint_name_by_role($bridge, \%backend, 'select');
    my $hready = _endpoint_name_by_role($bridge, \%backend, 'ready_in');
    my $htrans = _endpoint_name_by_role($bridge, \%backend, 'transfer');
    my $hreadyout = _endpoint_name_by_role($bridge, \%backend, 'ready_out');
    my $hresp = _endpoint_name_by_role($bridge, \%backend, 'response');
    my %event_by_name = map { $_->{name} => $_ } @{$execution->{events}};
    my %event_index = map { $execution->{events}[$_]{name} => $_ }
        0 .. $#{$execution->{events}};
    my $semantic_statement = sub ($kind, $fields, $phase_rank, $static_rank,
            $local_index, $semantic_id, $replacement = {}) {
        my %dynamic = (
            %$replacement,
            __VIAL_RECORD_ID__ => 'vial_record_id_json("' . _sv_string($kind)
                . '", "' . _sv_string($semantic_id) . '", vial_run_' . $kind . '_count)',
        );
        my $payload = _trace_payload_expression(
            {%$fields, record_id => '__VIAL_RECORD_ID__'},
            $phase_rank, $static_rank, $local_index, $semantic_id, \%dynamic,
        );
        return 'vial_emit("' . _sv_string($kind) . '", ' . $payload . ');';
    };
    my $event_statement = sub ($name, $static_rank = 'vial_transaction_static_rank') {
        my $event = $event_by_name{$name};
        confess "execution event '$name' is missing" unless $event;
        my $counter = 'vial_event_' . _sv_slug($name) . '_count';
        my $payload = _trace_payload_expression(
            {
                event_id => $event->{event_id},
                event_occurrence_index => '__VIAL_EVENT_INDEX__',
                record_id => '__VIAL_RECORD_ID__',
                semantic_id => $event->{semantic_id},
            },
            $event->{phase} eq 'drive' ? 0 : 1,
            $static_rank,
            100 + $event_index{$name},
            $event->{semantic_id},
            {
                __VIAL_EVENT_INDEX__ => "vial_uint_json($counter)",
                __VIAL_RECORD_ID__ => 'vial_record_id_json("events", "'
                    . _sv_string($event->{event_id}) . '", ' . $counter . ')',
            },
        );
        return 'vial_emit("events", ' . $payload . ');';
    };
    my $model_statements = sub ($name) {
        my $event = $event_by_name{$name};
        my $counter = 'vial_event_' . _sv_slug($name) . '_count';
        my @statement;
        for my $index (0 .. $#{$execution->{models}}) {
            my $model = $execution->{models}[$index];
            next unless grep {
                ($_->{value}{event_id} // '') eq $event->{event_id}
                    || ($_->{value}{event_id} // '') eq $event->{declaration_semantic_id}
            } @{$model->{bindings}};
            my $state_id = $model->{definition}{state}[0]{semantic_id};
            push @statement, $semantic_statement->(
                'models',
                {
                    model_instance_id => $model->{instance_id},
                    new_value => '__VIAL_MODEL_NEW__',
                    old_value => '__VIAL_MODEL_OLD__',
                    state_id => $state_id,
                    trigger_event_record_id => '__VIAL_TRIGGER_EVENT__',
                },
                2, 'vial_transaction_static_rank', 20 + $index,
                $model->{instance_id},
                {
                    __VIAL_MODEL_NEW__ => "vial_u64_value_json($counter)",
                    __VIAL_MODEL_OLD__ => "vial_u64_value_json($counter - 1)",
                    __VIAL_TRIGGER_EVENT__ => 'vial_record_id_json("events", "'
                        . _sv_string($event->{event_id}) . '", ' . $counter . ' - 1)',
                },
            );
        }
        return @statement;
    };
    my @sample_statement;
    my $sample_index = 0;
    for my $ep (@{$bridge->{endpoints}}) {
        next unless $ep->{direction} eq 'output';
        my $target_name = $backend{$ep->{endpoint_id}}{target_name};
        push @sample_statement, $semantic_statement->(
            'samples',
            {
                sample_id => $ep->{endpoint_id},
                semantic_id => $ep->{semantic_id} // $ep->{endpoint_id},
                value => '__VIAL_SAMPLE_VALUE__',
            },
            1, 'vial_transaction_static_rank', $sample_index++,
            $ep->{semantic_id} // $ep->{endpoint_id},
            {__VIAL_SAMPLE_VALUE__ => _runtime_scalar_expression(
                $target_name, $type{$ep->{type_id}},
            )},
        );
    }
    for my $probe (@{$bridge->{probes}}) {
        my $probe_name = 'vial_probe_' . _sv_slug($probe->{name});
        push @sample_statement, $semantic_statement->(
            'samples',
            {
                sample_id => $probe->{probe_id},
                semantic_id => $probe->{semantic_id} // $probe->{probe_id},
                value => '__VIAL_SAMPLE_VALUE__',
            },
            1, 'vial_transaction_static_rank', $sample_index++,
            $probe->{semantic_id} // $probe->{probe_id},
            {__VIAL_SAMPLE_VALUE__ => _runtime_scalar_expression(
                $probe_name, $type{$probe->{type_id}},
            )},
        );
    }
    my $transaction_statement = $semantic_statement->(
        'transactions',
        {
            accept_time => '__VIAL_ACCEPT_TIME__',
            binding_id => '__VIAL_TRANSACTION_BINDING__',
            complete_time => '__VIAL_COMPLETE_TIME__',
            correlation => '__VIAL_TRANSACTION_HANDLE__',
            effective_fields => '__VIAL_TRANSACTION_FIELDS__',
            handle_id => '__VIAL_TRANSACTION_HANDLE__',
            request_time => '__VIAL_REQUEST_TIME__',
            status => 'completed',
        },
        2, 'vial_transaction_static_rank', 0, 'transaction/completed',
        {
            __VIAL_ACCEPT_TIME__ => 'vial_transaction_accept_time_json',
            __VIAL_COMPLETE_TIME__ => 'vial_public_time_json(vial_cycle, "react")',
            __VIAL_REQUEST_TIME__ => 'vial_transaction_request_time_json',
            __VIAL_TRANSACTION_BINDING__ => 'vial_transaction_binding_id',
            __VIAL_TRANSACTION_FIELDS__ => 'vial_transaction_fields_json',
            __VIAL_TRANSACTION_HANDLE__ => 'vial_transaction_handle_id',
        },
    );
    my @scoreboard_completion;
    if (@{$execution->{scoreboards}}) {
        my $scoreboard = $execution->{scoreboards}[0];
        my %common = (
            actual_value => '__VIAL_TRANSACTION_FIELDS__',
            expected_value => '__VIAL_SCOREBOARD_EXPECTED__',
            instance_id => $scoreboard->{instance_id},
            key => undef,
            queue_depth_actual => 0,
            queue_depth_expected => 1,
        );
        push @scoreboard_completion,
            $semantic_statement->(
                'scoreboards', {%common, operation => 'enqueue_actual', outcome => JSON::PP::true},
                2, 'vial_transaction_static_rank', 100, $scoreboard->{instance_id},
                {
                    __VIAL_TRANSACTION_FIELDS__ => 'vial_transaction_fields_json',
                    __VIAL_SCOREBOARD_EXPECTED__ => 'vial_scoreboard_expected_fields_json',
                },
            ),
            'if (vial_scoreboard_expected_fields_json == vial_transaction_fields_json) begin',
            '  ' . $semantic_statement->(
                'scoreboards', {%common, operation => 'match', outcome => JSON::PP::true,
                    queue_depth_expected => 0},
                2, 'vial_transaction_static_rank', 101, $scoreboard->{instance_id},
                {
                    __VIAL_TRANSACTION_FIELDS__ => 'vial_transaction_fields_json',
                    __VIAL_SCOREBOARD_EXPECTED__ => 'vial_scoreboard_expected_fields_json',
                },
            ),
            'end else begin',
            '  vial_scoreboard_failed = 1;',
            '  vial_scenario_failed = 1;',
            '  ' . $semantic_statement->(
                'scoreboards', {%common, operation => 'mismatch', outcome => JSON::PP::false},
                2, 'vial_transaction_static_rank', 101, $scoreboard->{instance_id},
                {
                    __VIAL_TRANSACTION_FIELDS__ => 'vial_transaction_fields_json',
                    __VIAL_SCOREBOARD_EXPECTED__ => 'vial_scoreboard_expected_fields_json',
                },
            ),
            'end',
            'vial_scoreboard_expected_active = 0;';
    }
    my $fault_expiry_statement = $semantic_statement->(
        'faults',
        {
            fault_id => '__VIAL_FAULT_ID__',
            original_value => '__VIAL_FAULT_ORIGINAL__',
            status => 'expired',
            substituted_value => '__VIAL_FAULT_SUBSTITUTED__',
            target_id => '__VIAL_FAULT_TARGET__',
        },
        2, 'vial_transaction_static_rank', 200, 'fault/active',
        {
            __VIAL_FAULT_ID__ => 'vial_fault_id_json',
            __VIAL_FAULT_ORIGINAL__ => 'vial_fault_original_value_json',
            __VIAL_FAULT_SUBSTITUTED__ => 'vial_fault_substituted_value_json',
            __VIAL_FAULT_TARGET__ => 'vial_fault_target_id_json',
        },
    );
    $push->("  assign $hready = $hreadyout;");
    $push->('');
    $push->('  task automatic vial_inactive_barrier;');
    $push->('    bit vial_complete_now;');
    $push->('    bit vial_accept_now;');
    $push->("    @($inactive $clock);");
    $push->('    vial_cycle = vial_cycle + 1;');
    $push->('    ' . $_) for @sample_statement;
    $push->("    vial_accept_now = vial_transaction_active && !vial_transaction_accepted && $hsel && $hready && ($htrans == 2'h2);");
    $push->("    vial_complete_now = vial_transaction_active && $hreadyout && (vial_transaction_accepted || vial_accept_now);");
    $push->('    if (vial_accept_now) begin');
    $push->('      ' . $event_statement->('accepted'));
    $push->('      vial_event_accepted_count = vial_event_accepted_count + 1;');
    $push->('      ' . $event_statement->('captured'));
    $push->('      vial_event_captured_count = vial_event_captured_count + 1;');
    $push->('      vial_transaction_accepted = 1;');
    $push->('      vial_transaction_accept_cycle = vial_cycle;');
    $push->('      vial_transaction_accept_time_json = vial_public_time_json(vial_cycle, "sample");');
    $push->('    end');
    $push->("    if (vial_transaction_active && !$hreadyout) begin");
    $push->('      ' . $event_statement->('held'));
    $push->('      vial_event_held_count = vial_event_held_count + 1;');
    $push->('    end');
    $push->('    if (vial_complete_now) begin');
    $push->('      ' . $event_statement->('completed'));
    $push->('      vial_event_completed_count = vial_event_completed_count + 1;');
    $push->('    end');
    $push->("    if (vial_transaction_active && $hresp) begin");
    $push->('      ' . $event_statement->('error'));
    $push->('      vial_event_error_count = vial_event_error_count + 1;');
    $push->('    end');
    $push->('    if (vial_complete_now) begin');
    $push->('      ' . $transaction_statement);
    $push->('      ' . $_) for $model_statements->('accepted');
    $push->('      ' . $_) for $model_statements->('completed');
    if (@scoreboard_completion) {
        $push->('      if (vial_scoreboard_expected_active) begin');
        $push->("        $_") for @scoreboard_completion;
        $push->('      end');
    }
    $push->('      if (vial_fault_active) begin');
    $push->('        ' . $fault_expiry_statement);
    $push->('        vial_fault_active = 0;');
    $push->('      end');
    $push->('      vial_transaction_active = 0;');
    $push->("      $hsel = 0;");
    $push->("      $htrans = 0;");
    $push->('    end');
    $push->("    if ($hreadyout) vial_coverage_not_stalled_count = vial_coverage_not_stalled_count + 1;");
    $push->('    else vial_coverage_stalled_count = vial_coverage_stalled_count + 1;');
    $push->('  endtask');
    push @spec, _map_spec(
        relpath => $relpath, start => $scheduler_start, end => scalar(@line),
        symbol => 'vial_inactive_barrier', role => 'inactive_edge_scheduler',
        plan_paths => ['/domains/0', '/operation_graph/phase_order'],
        semantic_paths => [$execution->{domains}[0]{semantic_id}],
        bridge_paths => ['/domains/0'], locations => [$execution->{domains}[0]{source_location}],
    );
    $push->('');

    my %operation = map { $_->{operation_id} => $_ } @{$execution->{operation_graph}{operations}};
    my %symbol = map { $_->{operation_id} => _operation_symbol($_) }
        @{$execution->{operation_graph}{operations}};
    my %operation_index = map {
        $execution->{operation_graph}{operations}[$_]{operation_id} => $_
    } 0 .. $#{$execution->{operation_graph}{operations}};
    my %execution_endpoint_index = map {
        ($execution->{bindings}{endpoints}[$_]{semantic_id} // '') => $_
    } 0 .. $#{$execution->{bindings}{endpoints}};
    my %bridge_endpoint_index = map {
        $bridge->{endpoints}[$_]{endpoint_id} => $_
    } 0 .. $#{$bridge->{endpoints}};
    for my $index (0 .. $#{$execution->{operation_graph}{operations}}) {
        my $op = $execution->{operation_graph}{operations}[$index];
        my $start = @line + 1;
        $push->('  // VIAL operation: ' . $op->{operation_id});
        $push->("  task automatic $symbol{$op->{operation_id}};");
        my @body = _render_operation(
            $op, $execution, $bridge, \%backend, \%endpoint, \%symbol,
            $semantic_statement, $event_statement,
        );
        $push->("    $_") for @body;
        $push->('  endtask');
        push @spec, _map_spec(
            relpath => $relpath, start => $start, end => scalar(@line),
            symbol => $symbol{$op->{operation_id}}, role => "operation_$op->{kind}",
            plan_paths => ["/operation_graph/operations/$index"],
            semantic_paths => [$op->{operation_id}, $op->{fiber_id}],
            bridge_paths => [], locations => [$op->{source_location}],
        );
        $push->('');
    }

    my %operation_by_scenario;
    push @{$operation_by_scenario{$_->{scenario_id}}}, $_
        for @{$execution->{operation_graph}{operations}};
    my @scenario_pass_symbol;
    for my $index (0 .. $#{$execution->{scenarios}}) {
        my $scenario = $execution->{scenarios}[$index];
        my $scenario_symbol = 'vial_scenario_' . _sv_slug($scenario->{name});
        my $pass_symbol = 'vial_scenario_pass_' . $index;
        push @scenario_pass_symbol, $pass_symbol;
        my $run_id = 'run/' . $execution->{plan_id} . '/' . $scenario->{scenario_id};
        my $run_id_json = $JSON->encode($run_id);
        my $start_payload = $JSON->encode({scenario_id => $scenario->{scenario_id}});
        my $root_fiber = (grep { $_->{fiber_id} eq $scenario->{root_fiber_id} }
            @{$scenario->{fibers}})[0];
        my $last_static_rank = 1 + _maximum_static_rank(
            $operation_by_scenario{$scenario->{scenario_id}} || [],
        );
        my $start = @line + 1;
        $push->("  bit $pass_symbol;");
        $push->("  task automatic $scenario_symbol;");
        $push->('    int unsigned vial_hit_index;');
        $push->('    vial_current_run_id = "' . _sv_string($run_id) . '";');
        $push->('    vial_current_run_id_json = "' . _sv_string($run_id_json) . '";');
        $push->('    vial_current_scenario_id = "' . _sv_string($scenario->{scenario_id}) . '";');
        $push->('    vial_cycle = 0;');
        $push->('    vial_scenario_failed = 0;');
        $push->('    vial_scoreboard_failed = 0;');
        $push->('    vial_scoreboard_expected_active = 0;');
        $push->('    vial_fault_active = 0;');
        $push->('    vial_transaction_active = 0;');
        $push->('    vial_transaction_accepted = 0;');
        $push->('    vial_coverage_stalled_count = 0;');
        $push->('    vial_coverage_not_stalled_count = 0;');
        for my $kind (qw(events drives samples transactions expectations models scoreboards coverage faults fibers)) {
            $push->("    vial_run_${kind}_count = 0;");
        }
        for my $event (@{$execution->{events}}) {
            $push->('    vial_event_' . _sv_slug($event->{name}) . '_count = 0;');
        }
        $push->('    $display("FSMGEN_VIAL_TRACE_V1\\t%s", vial_trace_record("scenario_start", "'
            . $execution->{plan_id} . '", vial_current_run_id_json, vial_sequence, "'
            . _sv_string($start_payload) . '"));');
        $push->('    vial_sequence = vial_sequence + 1;');
        $push->('    ' . $semantic_statement->(
            'fibers',
            {
                cancel_scope_id => $root_fiber->{cancel_scope_id},
                cause_id => undef,
                fiber_id => $root_fiber->{fiber_id},
                parent_fiber_id => undef,
                status => 'started',
                winner_fiber_id => undef,
            },
            0, 0, 0, $root_fiber->{fiber_id},
        ));
        my @root_operation = grep {
            $_->{fiber_id} eq $scenario->{root_fiber_id}
        } @{$operation_by_scenario{$scenario->{scenario_id}} || []};
        my $completed_phase;
        for my $op (@root_operation) {
            $push->('    ' . $_) for _successor_rollover_statements(
                $completed_phase, $op,
            );
            $push->("    $symbol{$op->{operation_id}}();");
            $completed_phase = $OPERATION_PHASE{$op->{kind}}{lowering_completion};
        }
        $push->('    ' . $_) for _phase_transition_statements(
            $completed_phase, 'check', 'scenario finalization',
        );

        for my $coverpoint (@{$execution->{coverage}{coverpoints}}) {
            for my $bin (@{$coverpoint->{bins}}) {
                next unless ($bin->{matcher}{kind} // '') eq 'value'
                    && ($bin->{matcher}{value}{kind} // '') eq 'bool_value';
                my $stalled = $bin->{matcher}{value}{value} ? 1 : 0;
                my $counter = $stalled
                    ? 'vial_coverage_stalled_count' : 'vial_coverage_not_stalled_count';
                my $coverage = $semantic_statement->(
                    'coverage',
                    {
                        bin_id => $bin->{semantic_id},
                        coverpoint_id => $coverpoint->{semantic_id},
                        cross_id => undef,
                        cumulative_count => '__VIAL_COVERAGE_COUNT__',
                        delta => 1,
                        hit_kind => $bin->{classification},
                        sampled_value => $stalled ? JSON::PP::true : JSON::PP::false,
                    },
                    3, $last_static_rank, "int'(vial_run_coverage_count)", $bin->{semantic_id},
                    {__VIAL_COVERAGE_COUNT__ => 'vial_uint32_json(vial_hit_index + 1)'},
                );
                $push->("    for (vial_hit_index = 0; vial_hit_index < int'($counter); vial_hit_index = vial_hit_index + 1) begin");
                $push->('      ' . $coverage);
                $push->('    end');
            }
        }
        my %fiber_end = (
            cancel_scope_id => $root_fiber->{cancel_scope_id},
            cause_id => undef,
            fiber_id => $root_fiber->{fiber_id},
            parent_fiber_id => undef,
            winner_fiber_id => undef,
        );
        $push->('    if (vial_scenario_failed) begin');
        $push->('      ' . $semantic_statement->(
            'fibers', {%fiber_end, status => 'failed'},
            3, $last_static_rank + 1, 0, $root_fiber->{fiber_id},
        ));
        $push->("      $pass_symbol = 0;");
        $push->('      vial_any_scenario_failed = 1;');
        $push->('    end else begin');
        $push->('      ' . $semantic_statement->(
            'fibers', {%fiber_end, status => 'completed'},
            3, $last_static_rank + 1, 0, $root_fiber->{fiber_id},
        ));
        $push->("      $pass_symbol = 1;");
        $push->('    end');
        my %finalized_endpoint;
        for my $operation (
            @{$operation_by_scenario{$scenario->{scenario_id}} || []}
        ) {
            next unless ($operation->{kind} // '') eq 'drive';
            my %input = map { ($_->{name} // '') => $_->{value} }
                @{$operation->{typed_inputs} || []};
            my $binding = $execution_endpoint{$input{endpoint_id} // ''};
            next unless $binding
                && !$finalized_endpoint{$binding->{endpoint_id}}++;
            my $target = $backend{$binding->{endpoint_id}}{target_name};
            my @owner = grep {
                ($_->{kind} // '') eq 'drive'
                    && grep {
                        ($_->{name} // '') eq 'endpoint_id'
                            && ($_->{value} // '') eq ($binding->{semantic_id} // '')
                    } @{$_->{typed_inputs} || []}
            } @{$operation_by_scenario{$scenario->{scenario_id}} || []};
            my $finalize_line = @line + 1;
            $push->("    $target = '0;");
            push @spec, _map_spec(
                relpath => $relpath,
                start => $finalize_line,
                end => $finalize_line,
                symbol => $target,
                role => 'direct_driver_safe_zero_finalization',
                plan_paths => [
                    '/bindings/endpoints/'
                        . $execution_endpoint_index{$binding->{semantic_id}},
                    map {
                        '/operation_graph/operations/'
                            . $operation_index{$_->{operation_id}}
                    } @owner,
                ],
                semantic_paths => [
                    $binding->{semantic_id},
                    map { $_->{operation_id} } @owner,
                ],
                bridge_paths => [
                    '/endpoints/' . $bridge_endpoint_index{$binding->{endpoint_id}},
                ],
                locations => [map { $_->{source_location} } @owner],
            );
        }
        $push->('    $display("FSMGEN_VIAL_TRACE_V1\\t%s", vial_trace_record("scenario_end", "'
            . $execution->{plan_id} . '", vial_current_run_id_json, vial_sequence, '
            . '{"{\"logical_cycle_count\":", vial_uint_json(vial_cycle + 1), '
            . '",\"scenario_id\":\"' . _sv_string($scenario->{scenario_id})
            . '\",\"status\":\"", '
            . "$pass_symbol ? \"passed\" : \"failed\", \"\\\"}\"}" . '));');
        $push->('    vial_sequence = vial_sequence + 1;');
        $push->('  endtask');
        push @spec, _map_spec(
            relpath => $relpath, start => $start, end => scalar(@line),
            symbol => $scenario_symbol, role => 'scenario',
            plan_paths => ["/scenarios/$index"], semantic_paths => [$scenario->{scenario_id}],
            bridge_paths => [], locations => [$scenario->{source_location}],
        );
        $push->('');
    }
    my $initial_start = @line + 1;
    my $reset = $backend{$domain->{reset_endpoint_id}}{target_name};
    $push->('  initial begin');
    for my $ep (@{$bridge->{endpoints}}) {
        next if $ep->{direction} eq 'output' || $ep->{role} eq 'ready_in';
        my $name = $backend{$ep->{endpoint_id}}{target_name};
        $push->("    $name = 0;");
    }
    $push->("    $reset = " . ($domain->{reset_polarity} eq 'active_low' ? '1' : '0') . ';');
    $push->('    vial_cycle = 0;');
    $push->('    vial_sequence = 0;');
    $push->('    vial_any_scenario_failed = 0;');
    for my $kind (qw(events drives samples transactions expectations models scoreboards coverage faults fibers)) {
        $push->("    vial_trace_${kind}_count = 0;");
    }
    my @runs = map {{
        scenario_id => $_->{scenario_id},
        run_id => 'run/' . $execution->{plan_id} . '/' . $_->{scenario_id},
    }} @{$execution->{scenarios}};
    my $header_payload = $JSON->encode({
        backend_profile => $BACKEND_PROFILE,
        decision_digest => sha256_hex($JSON->encode($execution->{randomness}{decisions})),
        execution_profile => $execution->{profile},
        fixture_id => $execution->{fixture}{fixture_id},
        scenario_runs => \@runs,
    });
    $push->('    $display("FSMGEN_VIAL_TRACE_V1\\t%s", vial_trace_record("header", "'
        . $execution->{plan_id} . '", "null", vial_sequence, "'
        . _sv_string($header_payload) . '"));');
    $push->('    vial_sequence = vial_sequence + 1;');
    $push->('    vial_scenario_' . _sv_slug($_->{name}) . '();') for @{$execution->{scenarios}};
    my @summary_piece;
    for my $index (0 .. $#runs) {
        push @summary_piece, '"' . ($index ? ',' : '[')
            . '{\"run_id\":\"' . _sv_string($runs[$index]{run_id})
            . '\",\"scenario_id\":\"' . _sv_string($runs[$index]{scenario_id})
            . '\",\"status\":\""',
            "$scenario_pass_symbol[$index] ? \"passed\" : \"failed\"",
            '"\"}' . ($index == $#runs ? ']' : '') . '"';
    }
    my $summary_expression = '{' . join(', ', @summary_piece) . '}';
    $push->('    $display("FSMGEN_VIAL_TRACE_V1\\t%s", vial_trace_record("footer", "'
        . $execution->{plan_id} . '", "null", vial_sequence, '
        . '{"{\"clean_termination\":true,\"counts\":", vial_trace_counts_json(), '
        . '",\"scenario_completion_summaries\":", ' . $summary_expression . ', '
        . '",\"status\":\"", vial_any_scenario_failed ? "failed" : "passed", "\"}"}));');
    $push->('    $finish;');
    $push->('  end');
    push @spec, _map_spec(
        relpath => $relpath, start => $initial_start, end => scalar(@line),
        symbol => 'initial', role => 'scenario_scheduler',
        plan_paths => ['/fixture', '/scenarios'],
        semantic_paths => [$execution->{fixture}{fixture_id}], bridge_paths => [],
        locations => [$execution->{fixture}{source_location}],
    );
    $push->('endmodule');
    return (join("\n", @line) . "\n", \@spec);
}

sub _render_operation($op, $execution, $bridge, $backend, $endpoint, $symbol,
        $semantic_statement, $event_statement) {
    my %input = map { $_->{name} => $_->{value} } @{$op->{typed_inputs}};
    if ($op->{kind} eq 'reset') {
        my $domain = $bridge->{domains}[0];
        my $reset = $backend->{$domain->{reset_endpoint_id}}{target_name};
        my $reset_endpoint = $endpoint->{$domain->{reset_endpoint_id}};
        my %type = map { $_->{type_id} => $_ } @{$bridge->{types}};
        my $active = $domain->{reset_polarity} eq 'active_low' ? 0 : 1;
        my $inactive = $active ? 0 : 1;
        my $drive = sub ($value, $local) {
            return $semantic_statement->(
                'drives',
                {
                    effective_value => _static_scalar_value(
                        $type{$reset_endpoint->{type_id}}, $value,
                    ),
                    endpoint_id => $reset_endpoint->{endpoint_id},
                    operation_id => $op->{operation_id},
                    transaction_field_id => undef,
                },
                0, $op->{static_rank}, $local,
                $reset_endpoint->{semantic_id} // $reset_endpoint->{endpoint_id},
            );
        };
        return (
            'vial_transaction_static_rank = ' . $op->{static_rank} . ';',
            "$reset = $active;",
            $drive->($active, 1),
            "repeat ($input{cycles}) vial_inactive_barrier();",
            'vial_cycle = vial_cycle + 1;',
            "$reset = $inactive;",
            $drive->($inactive, 2),
            'vial_transaction_active = 0;',
            'vial_transaction_accepted = 0;',
        );
    }
    if ($op->{kind} eq 'start') {
        my %field = map { $_->{field_id} => $_->{value}{value} } @{$input{fields}};
        my %fault = map { $_->{semantic_id} => $_ } @{$execution->{faults}};
        my %armed;
        for my $candidate (@{$execution->{operation_graph}{operations}}) {
            next unless $candidate->{scenario_id} eq $op->{scenario_id}
                && $candidate->{static_rank} < $op->{static_rank}
                && $candidate->{kind} eq 'inject';
            my %candidate_input = map { $_->{name} => $_->{value} } @{$candidate->{typed_inputs}};
            $armed{$candidate_input{fault_id}} = 1;
        }
        my (@assignment, @drive, @effective_field, @fault_record);
        my $drive_index = 0;
        for my $transaction (@{$bridge->{transactions}}) {
            for my $carrier (@{$transaction->{fields}}) {
                my ($record) = grep { /::field::\Q$carrier->{name}\E\z/ } keys %field;
                next unless defined $record;
                my $name = $backend->{$carrier->{endpoint_id}}{target_name};
                my ($substitution) = grep {
                    $armed{$_->{semantic_id}} && $_->{field_name} eq $carrier->{name}
                } map { $fault{$_} } sort keys %fault;
                my $value = $substitution ? $substitution->{substitute}{value} : $field{$record};
                push @assignment, "$name = $value->{width}'h$value->{value_hex};";
                push @effective_field, {field_id => $record, value => _clone($value)};
                push @drive, $semantic_statement->(
                    'drives',
                    {
                        effective_value => _clone($value),
                        endpoint_id => $carrier->{endpoint_id},
                        operation_id => $op->{operation_id},
                        transaction_field_id => $record,
                    },
                    0, $op->{static_rank}, $drive_index++, $record,
                );
                if ($substitution) {
                    my $original = $field{$record};
                    push @fault_record,
                        'vial_fault_id_json = "' . _sv_string($JSON->encode($substitution->{semantic_id})) . '";',
                        'vial_fault_target_id_json = "' . _sv_string($JSON->encode($record)) . '";',
                        'vial_fault_original_value_json = "' . _sv_string($JSON->encode($original)) . '";',
                        'vial_fault_substituted_value_json = "' . _sv_string($JSON->encode($value)) . '";',
                        $semantic_statement->(
                            'faults',
                            {
                                fault_id => $substitution->{semantic_id},
                                original_value => _clone($original),
                                status => 'applied',
                                substituted_value => _clone($value),
                                target_id => $record,
                            },
                            0, $op->{static_rank}, 50, $substitution->{semantic_id},
                        );
                }
            }
        }
        my $hsel = _endpoint_name_by_role($bridge, $backend, 'select');
        my $handle_id = $input{handle_id};
        my $binding_id = $input{transaction_binding_id};
        return (
            'vial_transaction_static_rank = ' . $op->{static_rank} . ';',
            'vial_transaction_request_cycle = vial_cycle;',
            'vial_transaction_handle_id = "' . _sv_string($JSON->encode($handle_id)) . '";',
            'vial_transaction_binding_id = "' . _sv_string($JSON->encode($binding_id)) . '";',
            'vial_transaction_operation_id = "' . _sv_string($JSON->encode($op->{operation_id})) . '";',
            'vial_transaction_fields_json = "' . _sv_string($JSON->encode(\@effective_field)) . '";',
            'vial_transaction_request_time_json = vial_public_time_json(vial_cycle, "drive");',
            @assignment,
            @drive,
            @fault_record,
            "$hsel = 1;",
            'vial_transaction_active = 1;',
            'vial_transaction_accepted = 0;',
            $event_statement->('requested', $op->{static_rank}),
            'vial_event_requested_count = vial_event_requested_count + 1;',
            'vial_inactive_barrier();',
        );
    }
    if ($op->{kind} eq 'await') {
        my $condition = _render_property($input{property}, $bridge, $backend);
        my @settle = _property_mentions_event($input{property}, 'completed')
            ? ('if (' . _endpoint_name_by_role($bridge, $backend, 'response')
                . ') vial_inactive_barrier();')
            : ();
        my $deadline = $op->{deadline}{cycle};
        return (
            "while (!($condition) && vial_cycle <= $deadline) vial_inactive_barrier();",
            "if (!($condition)) vial_scenario_failed = 1;",
            @settle,
        );
    }
    if ($op->{kind} eq 'parallel') {
        my ($effect) = grep { $_->{kind} eq 'activate_fibers' } @{$op->{effects}};
        my %operation = map { $_->{operation_id} => $_ } @{$execution->{operation_graph}{operations}};
        my ($scenario) = grep { $_->{scenario_id} eq $op->{scenario_id} } @{$execution->{scenarios}};
        my %fiber = map { $_->{fiber_id} => $_ } @{$scenario->{fibers}};
        my @condition;
        my @child_fiber;
        for my $child_id (@{$effect->{child_root_operation_ids}}) {
            my $child = $operation{$child_id};
            my %child_input = map { $_->{name} => $_->{value} } @{$child->{typed_inputs}};
            push @condition, _render_property($child_input{property}, $bridge, $backend);
            push @child_fiber, $fiber{$child->{fiber_id}};
        }
        my $join = $effect->{join} eq 'all' ? ' && ' : ' || ';
        my $join_any = $effect->{join} eq 'any';
        my @done = map { "vial_child_done_$_" } 0 .. $#condition;
        my @start;
        my @complete;
        for my $index (0 .. $#child_fiber) {
            my $child = $child_fiber[$index];
            push @start, $semantic_statement->(
                'fibers',
                {
                    cancel_scope_id => $child->{cancel_scope_id},
                    cause_id => $op->{operation_id},
                    fiber_id => $child->{fiber_id},
                    parent_fiber_id => $child->{parent_fiber_id},
                    status => 'started',
                    winner_fiber_id => undef,
                },
                2, $op->{static_rank}, $index, $child->{fiber_id},
            );
            my %fiber_record = (
                cancel_scope_id => $child->{cancel_scope_id},
                cause_id => $op->{operation_id},
                fiber_id => $child->{fiber_id},
                parent_fiber_id => $child->{parent_fiber_id},
                winner_fiber_id => $join_any ? '__VIAL_WINNER_FIBER__' : undef,
            );
            if ($join_any) {
                my $replacement = {
                    __VIAL_WINNER_FIBER__ => 'vial_winner_fiber_id_json',
                };
                my $completed = $semantic_statement->(
                    'fibers', {%fiber_record, status => 'completed'},
                    3, $op->{static_rank}, 100 + $index, $child->{fiber_id},
                    $replacement,
                );
                my $cancelled = $semantic_statement->(
                    'fibers', {%fiber_record, status => 'cancelled'},
                    3, $op->{static_rank}, 100 + $index, $child->{fiber_id},
                    $replacement,
                );
                push @complete,
                    "if ($done[$index]) begin",
                    "  $completed",
                    'end else begin',
                    "  $cancelled",
                    'end';
            }
            else {
                push @complete, $semantic_statement->(
                    'fibers', {%fiber_record, status => 'completed'},
                    3, $op->{static_rank}, 100 + $index, $child->{fiber_id},
                );
            }
        }
        my $deadline = $scenario->{timeout_cycles} - 1;
        my @update = $join_any
            ? map {
                my $winner_json = _sv_string($JSON->encode($child_fiber[$_]{fiber_id}));
                (
                    "  if (vial_winner_fiber_id_json == \"null\" && ($condition[$_])) begin",
                    "    $done[$_] = 1;",
                    "    vial_winner_fiber_id_json = \"$winner_json\";",
                    '  end',
                )
            } 0 .. $#condition
            : map { "  if ($condition[$_]) $done[$_] = 1;" } 0 .. $#condition;
        return (
            '// Child fibers are evaluated by this one scheduler; target fork order is not semantic authority.',
            map({ "bit $_;" } @done),
            ($join_any ? ('string vial_winner_fiber_id_json;') : ()),
            map({ "$_ = 0;" } @done),
            ($join_any ? ('vial_winner_fiber_id_json = "null";') : ()),
            @start,
            'while (!(' . join($join, @done) . ") && vial_cycle <= $deadline) begin",
            '  vial_inactive_barrier();',
            @update,
            'end',
            'if (!(' . join($join, @done) . ')) vial_scenario_failed = 1;',
            @complete,
        );
    }
    if ($op->{kind} eq 'expect') {
        my $condition = _render_property($input{property}, $bridge, $backend);
        my $expectation_id = $op->{effects}[0]{target_id};
        my ($name) = $expectation_id =~ /::([^:]+)\z/;
        $name //= $expectation_id;
        my %base = (
            activation_time => '__VIAL_CHECK_TIME__',
            actual_value => '__VIAL_EXPECT_ACTUAL__',
            diagnostic_id => '__VIAL_EXPECT_DIAGNOSTIC__',
            expectation_id => $expectation_id,
            expected_value => JSON::PP::true,
            name => $name,
            outcome => '__VIAL_EXPECT_OUTCOME__',
            property_operation => $input{property}{op},
            resolution_time => '__VIAL_CHECK_TIME__',
        );
        my $pass = $semantic_statement->(
            'expectations', \%base,
            3, $op->{static_rank}, 0, $expectation_id,
            {
                __VIAL_CHECK_TIME__ => 'vial_public_time_json(vial_cycle, "check")',
                __VIAL_EXPECT_ACTUAL__ => 'vial_json_bool(1)',
                __VIAL_EXPECT_DIAGNOSTIC__ => '"null"',
                __VIAL_EXPECT_OUTCOME__ => 'vial_json_bool(1)',
            },
        );
        my $fail = $semantic_statement->(
            'expectations', \%base,
            3, $op->{static_rank}, 0, $expectation_id,
            {
                __VIAL_CHECK_TIME__ => 'vial_public_time_json(vial_cycle, "check")',
                __VIAL_EXPECT_ACTUAL__ => 'vial_json_bool(0)',
                __VIAL_EXPECT_DIAGNOSTIC__ => '"\"diagnostic/'
                    . _sv_string($expectation_id) . '\""',
                __VIAL_EXPECT_OUTCOME__ => 'vial_json_bool(0)',
            },
        );
        return (
            "if ($condition) begin",
            "  $pass",
            'end else begin',
            '  vial_scenario_failed = 1;',
            "  $fail",
            '  $display("VIAL expectation failed: ' . _sv_string($expectation_id) . '");',
            'end',
        );
    }
    if ($op->{kind} eq 'inject') {
        my ($fault) = grep { $_->{semantic_id} eq $input{fault_id} } @{$execution->{faults}};
        my $target_id = "$fault->{transaction_id}::field::$fault->{field_name}";
        return (
            'vial_fault_active = 1;',
            'vial_fault_id_json = "' . _sv_string($JSON->encode($fault->{semantic_id})) . '";',
            'vial_fault_target_id_json = "' . _sv_string($JSON->encode($target_id)) . '";',
            $semantic_statement->(
                'faults',
                {
                    fault_id => $fault->{semantic_id},
                    original_value => undef,
                    status => 'armed',
                    substituted_value => _clone($fault->{substitute}{value}),
                    target_id => $target_id,
                },
                2, $op->{static_rank}, 0, $fault->{semantic_id},
            ),
        );
    }
    if ($op->{kind} eq 'scoreboard_expect') {
        my @fields = map {
            {field_id => $_->{field_id}, value => _clone($_->{value}{value})}
        } @{$input{fields}};
        my ($scoreboard) = grep { $_->{instance_id} eq $input{scoreboard_instance_id} }
            @{$execution->{scoreboards}};
        my $fields_json = $JSON->encode(\@fields);
        return (
            'vial_scoreboard_expected_active = 1;',
            'vial_scoreboard_expected_fields_json = "' . _sv_string($fields_json) . '";',
            'vial_scoreboard_instance_id_json = "'
                . _sv_string($JSON->encode($scoreboard->{instance_id})) . '";',
            $semantic_statement->(
                'scoreboards',
                {
                    actual_value => undef,
                    expected_value => \@fields,
                    instance_id => $scoreboard->{instance_id},
                    key => undef,
                    operation => 'enqueue_expected',
                    outcome => JSON::PP::true,
                    queue_depth_actual => 0,
                    queue_depth_expected => 1,
                },
                2, $op->{static_rank}, 0, $scoreboard->{instance_id},
            ),
        );
    }
    if ($op->{kind} eq 'scoreboard_check') {
        my ($scoreboard) = grep { $_->{instance_id} eq $input{scoreboard_instance_id} }
            @{$execution->{scoreboards}};
        my %base = (
            actual_value => undef,
            expected_value => undef,
            instance_id => $scoreboard->{instance_id},
            key => undef,
            operation => 'check',
            queue_depth_actual => 0,
            queue_depth_expected => '__VIAL_SCOREBOARD_DEPTH__',
            outcome => '__VIAL_SCOREBOARD_OUTCOME__',
        );
        my $pass = $semantic_statement->(
            'scoreboards', \%base, 3, $op->{static_rank}, 0, $scoreboard->{instance_id},
            {
                __VIAL_SCOREBOARD_DEPTH__ => 'vial_uint_json(0)',
                __VIAL_SCOREBOARD_OUTCOME__ => 'vial_json_bool(1)',
            },
        );
        my $fail = $semantic_statement->(
            'scoreboards', \%base, 3, $op->{static_rank}, 0, $scoreboard->{instance_id},
            {
                __VIAL_SCOREBOARD_DEPTH__ => 'vial_uint_json(vial_scoreboard_expected_active ? 64\'d1 : 64\'d0)',
                __VIAL_SCOREBOARD_OUTCOME__ => 'vial_json_bool(0)',
            },
        );
        return (
            'if (!vial_scoreboard_expected_active && !vial_scoreboard_failed) begin',
            "  $pass",
            'end else begin',
            '  vial_scenario_failed = 1;',
            "  $fail",
            'end',
        );
    }
    if ($op->{kind} eq 'drive') {
        my $semantic_endpoint_id = $input{endpoint_id};
        my ($binding) = grep {
            ($_->{semantic_id} // '') eq $semantic_endpoint_id
        } @{$execution->{bindings}{endpoints} || []};
        confess "direct-drive execution binding is missing"
            unless defined $binding;
        my $target = $backend->{$binding->{endpoint_id}}{target_name};
        my $value = $input{value}{value};
        return (
            'vial_transaction_static_rank = ' . $op->{static_rank} . ';',
            "$target = $value->{width}'h$value->{value_hex};",
            $semantic_statement->(
                'drives',
                {
                    effective_value => _clone($value),
                    endpoint_id => $binding->{endpoint_id},
                    operation_id => $op->{operation_id},
                    transaction_field_id => undef,
                },
                0, $op->{static_rank}, 0,
                $binding->{semantic_id},
            ),
        );
    }
    if ($op->{kind} eq 'repeat') {
        return ('// Literal repeat topology is expanded into fixed operation tasks.');
    }
    return ('// Closed operation kind emitted with no additional runtime state.');
}

sub _successor_rollover_statements($completed_phase, $operation) {
    return () unless defined $completed_phase;
    my $kind = $operation->{kind} // '';
    my $eligible_phase = $operation->{eligible_phase} // '';
    confess "portable operation '$kind' has no closed eligible phase"
        unless exists($OPERATION_PHASE{$kind})
            && $eligible_phase eq $OPERATION_PHASE{$kind}{eligible}
            && exists($PHASE_RANK{$completed_phase})
            && exists($PHASE_RANK{$eligible_phase});
    return _phase_transition_statements(
        $completed_phase, $eligible_phase, "operation '$kind' successor",
    );
}

sub _phase_transition_statements($completed_phase, $eligible_phase, $label) {
    return () unless defined $completed_phase;
    confess "portable $label has an unknown phase transition"
        unless exists($PHASE_RANK{$completed_phase})
            && exists($PHASE_RANK{$eligible_phase});
    return () if $completed_phase eq $eligible_phase;

    if ($completed_phase eq 'drive'
            && ($eligible_phase eq 'react' || $eligible_phase eq 'check')) {
        return (
            "// VIAL phase advance: drive -> $eligible_phase traverses the current cycle sample barrier.",
            'vial_inactive_barrier();',
        );
    }
    return () if $PHASE_RANK{$eligible_phase} > $PHASE_RANK{$completed_phase};

    my $comment = "// VIAL successor phase rollover: $completed_phase -> "
        . "$eligible_phase advances to the next logical cycle.";
    return ($comment, 'vial_cycle = vial_cycle + 1;')
        if $eligible_phase eq 'drive';
    return ($comment, 'vial_inactive_barrier();')
        if $eligible_phase eq 'react';
    confess "portable successor rollover to '$eligible_phase' is unsupported";
}

sub _parallel_child_errors($execution) {
    my @error;
    my $graph = $execution->{operation_graph};
    return ('parallel-topology:operations')
        unless ref($graph) eq 'HASH'
            && ref($graph->{operations}) eq 'ARRAY';
    my @operation = @{$graph->{operations}};
    my %operation_by_id;
    my %operation_by_fiber;
    for my $operation (@operation) {
        push @{$operation_by_id{$operation->{operation_id} // ''}}, $operation;
        push @{$operation_by_fiber{join("\0",
            $operation->{scenario_id} // '', $operation->{fiber_id} // '')}},
            $operation;
    }

    return ('parallel-topology:scenarios')
        unless ref($execution->{scenarios}) eq 'ARRAY';
    my %scenario = map { ($_->{scenario_id} // '') => $_ }
        @{$execution->{scenarios}};
    my %fiber_record;
    for my $scenario (@{$execution->{scenarios}}) {
        my $fibers = $scenario->{fibers};
        if (ref($fibers) ne 'ARRAY') {
            push @error,
                'parallel-scenario:' . ($scenario->{scenario_id} // '')
                    . ':fibers';
            next;
        }
        for my $fiber (@$fibers) {
            push @{$fiber_record{join("\0", $scenario->{scenario_id} // '',
                $fiber->{fiber_id} // '')}}, $fiber;
        }
    }

    my %fiber_owner_count;
    for my $parent (@operation) {
        next unless ($parent->{kind} // '') eq 'parallel';
        my $parent_id = $parent->{operation_id} // '';
        my $prefix = "parallel-child:$parent_id";
        my $effects = $parent->{effects};
        if (ref($effects) ne 'ARRAY' || @$effects != 1
                || ref($effects->[0]) ne 'HASH'
                || ($effects->[0]{kind} // '') ne 'activate_fibers') {
            push @error, "$prefix:effect";
            next;
        }
        my $child_ids = $effects->[0]{child_root_operation_ids};
        if (ref($child_ids) ne 'ARRAY' || @$child_ids < 2) {
            push @error, "$prefix:child-roots";
            next;
        }

        my %seen_child;
        for my $child_id (@$child_ids) {
            if (!defined($child_id) || ref($child_id) || !length($child_id)) {
                push @error, "$prefix:invalid-child-root";
                next;
            }
            if ($seen_child{$child_id}++) {
                push @error, "$prefix:$child_id:duplicate-child-root";
                next;
            }
            my @candidate = @{$operation_by_id{$child_id} || []};
            if (@candidate != 1) {
                push @error, "$prefix:$child_id:identity";
                next;
            }
            my $child = $candidate[0];
            if (($child->{scenario_id} // '') ne ($parent->{scenario_id} // '')) {
                push @error, "$prefix:$child_id:scenario";
                next;
            }
            my $fiber_id = $child->{fiber_id} // '';
            my $fiber_key = join("\0", $child->{scenario_id} // '', $fiber_id);
            ++$fiber_owner_count{$fiber_key};
            my @fiber = @{$fiber_record{$fiber_key} || []};
            if (!length($fiber_id) || @fiber != 1
                    || ($fiber[0]{parent_fiber_id} // '')
                        ne ($parent->{fiber_id} // '')) {
                push @error, "$prefix:$child_id:fiber";
                next;
            }
            my @member = @{$operation_by_fiber{$fiber_key} || []};
            unless (@member == 1
                    && ($member[0]{operation_id} // '') eq $child_id) {
                push @error,
                    "$prefix:$child_id:operation-count:" . scalar(@member);
                next;
            }

            my $kind = $child->{kind} // '';
            if ($kind ne 'await') {
                push @error, "$prefix:$child_id:unsupported-kind:$kind";
                next;
            }
            my $input = $child->{typed_inputs};
            my $child_effect = $child->{effects};
            my $successor = $child->{successor_ids};
            my $deadline = $child->{deadline};
            push @error, "$prefix:$child_id:await-shape"
                unless ref($input) eq 'ARRAY' && @$input == 1
                    && ref($input->[0]) eq 'HASH'
                    && ($input->[0]{name} // '') eq 'property'
                    && ref($input->[0]{value}) eq 'HASH'
                    && ref($child_effect) eq 'ARRAY' && @$child_effect == 1
                    && ref($child_effect->[0]) eq 'HASH'
                    && ($child_effect->[0]{kind} // '') eq 'evaluate_property'
                    && ref($successor) eq 'ARRAY' && !@$successor
                    && !defined($child->{failure_successor_id})
                    && ref($deadline) eq 'HASH'
                    && ($deadline->{phase} // '') eq 'check';
        }
    }

    for my $scenario_id (sort keys %scenario) {
        my $root_fiber_id = $scenario{$scenario_id}{root_fiber_id} // '';
        next unless ref($scenario{$scenario_id}{fibers}) eq 'ARRAY';
        for my $fiber (@{$scenario{$scenario_id}{fibers}}) {
            my $fiber_id = $fiber->{fiber_id} // '';
            next if $fiber_id eq $root_fiber_id;
            my $key = join("\0", $scenario_id, $fiber_id);
            my $owners = $fiber_owner_count{$key} // 0;
            push @error, "parallel-fiber:$scenario_id:$fiber_id:owner-count:$owners"
                unless $owners == 1;
        }
    }
    return @error;
}

sub _direct_drive_errors($execution, $bridge) {
    my @error;
    my %root_fiber = map {
        ($_->{scenario_id} // '') => ($_->{root_fiber_id} // '')
    } @{$execution->{scenarios} || []};
    my %parallel_drive;
    for my $operation (@{$execution->{operation_graph}{operations} || []}) {
        next unless ($operation->{kind} // '') eq 'drive'
            && ($operation->{fiber_id} // '')
                ne ($root_fiber{$operation->{scenario_id} // ''} // '');
        my %input = map { ($_->{name} // '') => $_->{value} }
            @{$operation->{typed_inputs} || []};
        next unless defined($input{endpoint_id}) && !ref($input{endpoint_id});
        $parallel_drive{join("\0", $operation->{scenario_id} // '',
            $input{endpoint_id})}{$operation->{fiber_id} // ''} = 1;
    }
    my %parallel_conflict = map {
        keys(%{$parallel_drive{$_}}) > 1 ? ($_ => 1) : ()
    } keys %parallel_drive;
    for my $key (sort keys %parallel_conflict) {
        my ($scenario_id, $endpoint_id) = split /\0/, $key, 2;
        push @error, "direct-drive-conflict:$scenario_id:$endpoint_id";
    }

    my %execution_binding;
    push @{$execution_binding{$_->{semantic_id} // ''}}, $_
        for @{$execution->{bindings}{endpoints} || []};
    my %bridge_endpoint;
    push @{$bridge_endpoint{$_->{endpoint_id} // ''}}, $_
        for @{$bridge->{endpoints} || []};
    my %bridge_type = map { ($_->{type_id} // '') => $_ }
        @{$bridge->{types} || []};
    my %backend_binding;
    push @{$backend_binding{$_->{semantic_id} // ''}}, $_
        for grep { ($_->{target_language} // '') eq 'systemverilog' }
            @{$bridge->{backend_bindings} || []};

    for my $operation (@{$execution->{operation_graph}{operations} || []}) {
        next unless ($operation->{kind} // '') eq 'drive';
        my $operation_id = $operation->{operation_id} // '';
        my $prefix = "direct-drive:$operation_id";
        my %input = map { ($_->{name} // '') => $_->{value} }
            @{$operation->{typed_inputs} || []};
        my $semantic_endpoint_id = $input{endpoint_id};
        my $parallel_key = defined($semantic_endpoint_id)
                && !ref($semantic_endpoint_id)
            ? join("\0", $operation->{scenario_id} // '',
                $semantic_endpoint_id)
            : undef;
        if (($operation->{fiber_id} // '')
                ne ($root_fiber{$operation->{scenario_id} // ''} // '')) {
            push @error, "$prefix:non-root-fiber"
                unless defined($parallel_key)
                    && $parallel_conflict{$parallel_key};
            next;
        }
        my $value = ref($input{value}) eq 'HASH'
            && ($input{value}{kind} // '') eq 'literal'
            ? $input{value}{value} : undef;
        my @effect = @{$operation->{effects} || []};
        push @error, "$prefix:effect"
            unless @effect == 1
                && ($effect[0]{kind} // '') eq 'update_driver'
                && defined($semantic_endpoint_id)
                && !ref($semantic_endpoint_id)
                && ($effect[0]{target_id} // '') eq $semantic_endpoint_id;

        my @binding = defined($semantic_endpoint_id) && !ref($semantic_endpoint_id)
            ? @{$execution_binding{$semantic_endpoint_id} || []} : ();
        push @error, "$prefix:execution-binding" unless @binding == 1;
        next unless @binding == 1;
        my $binding = $binding[0];
        my @carrier = @{$bridge_endpoint{$binding->{endpoint_id} // ''} || []};
        push @error, "$prefix:bridge-endpoint" unless @carrier == 1;
        next unless @carrier == 1;
        my $carrier = $carrier[0];
        push @error, "$prefix:carrier-access"
            unless ($binding->{access} // '') eq 'public_port'
                && ($carrier->{access} // '') eq 'public_port';
        push @error, "$prefix:carrier-direction"
            unless ($binding->{carrier_direction} // '') eq 'input'
                && ($carrier->{direction} // '') eq 'input';

        my @relation = grep { ($_->{direction} // '') eq 'drive' }
            @{$binding->{relations} || []};
        push @error, "$prefix:drive-relation" unless @relation == 1;
        next unless @relation == 1;
        my $relation = $relation[0];
        my $type = $bridge_type{$carrier->{type_id} // ''};
        push @error, "$prefix:value"
            unless ref($value) eq 'HASH'
                && ($value->{kind} // '') eq 'scalar'
                && defined($value->{type_id}) && !ref($value->{type_id})
                && ($value->{type_id} // '')
                    eq ($input{value}{type_id} // '')
                && ($value->{type_id} // '')
                    eq ($relation->{semantic_type_id} // '')
                && defined($value->{width}) && !ref($value->{width})
                && $value->{width} =~ /\A[1-9][0-9]*\z/
                && ref($type) eq 'HASH'
                && $value->{width} == ($relation->{width} // -1)
                && $value->{width} == ($type->{width} // -2)
                && ($relation->{carrier_type_id} // '')
                    eq ($carrier->{type_id} // '')
                && defined($value->{value_hex}) && !ref($value->{value_hex})
                && $value->{value_hex} =~ /\A[0-9a-f]+\z/
                && Math::BigInt->from_hex('0x' . $value->{value_hex})
                    < Math::BigInt->new(2)->bpow($value->{width})
                && _fully_known_scalar($value);

        my @backend = @{$backend_binding{$carrier->{endpoint_id}} || []};
        push @error, "$prefix:systemverilog-binding"
            unless @backend == 1
                && ($backend[0]{target_kind} // '') eq 'port'
                && ($backend[0]{status} // '') eq 'declared'
                && ($backend[0]{target_name} // '')
                    =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    }
    return @error;
}

sub _operation_phase_errors($execution) {
    my @error;
    my $graph = $execution->{operation_graph} || {};
    push @error, 'operation-phase-order'
        unless ref($graph->{phase_order}) eq 'ARRAY'
            && join("\0", @{$graph->{phase_order}})
                eq join("\0", qw(drive sample react check));
    for my $operation (@{$graph->{operations} || []}) {
        my $kind = $operation->{kind} // '';
        push @error, "operation:$kind" unless $SUPPORTED_OPERATION{$kind};
        push @error, "operation-phase:$operation->{operation_id}"
            unless exists($OPERATION_PHASE{$kind})
                && ($operation->{eligible_phase} // '')
                    eq $OPERATION_PHASE{$kind}{eligible};
    }
    return @error;
}

sub _property_mentions_event($node, $event_name) {
    return 0 unless ref($node) eq 'HASH';
    if (($node->{kind} // '') eq 'reference'
        && (($node->{op} // '') eq 'event' || ($node->{op} // '') eq 'event_count')) {
        my ($name) = ($node->{binding_id} // '') =~ m{/([^/]+)\z};
        return defined($name) && $name eq $event_name;
    }
    if (ref($node->{operands}) eq 'ARRAY') {
        return 1 if grep { _property_mentions_event($_, $event_name) } @{$node->{operands}};
    }
    return 0;
}

sub _trace_payload_expression($fields, $phase_rank, $static_rank, $local_index, $semantic_id, $replacement = {}) {
    my $payload = _clone($fields);
    $payload->{logical_time} = '__VIAL_LOGICAL_TIME__';
    $payload->{run_id} = '__VIAL_RUN_ID__' unless exists $payload->{run_id};
    my %expression = (
        __VIAL_LOGICAL_TIME__ => 'vial_logical_time_json('
            . join(', ', $phase_rank, $static_rank, $local_index, '"' . _sv_string($semantic_id) . '"') . ')',
        __VIAL_RUN_ID__ => 'vial_current_run_id_json',
        %$replacement,
    );
    return _sv_json_expression($payload, \%expression);
}

sub _sv_json_expression($value, $replacement) {
    my $json = $JSON->encode($value);
    my @token = sort { length($b) <=> length($a) } keys %$replacement;
    return '"' . _sv_string($json) . '"' unless @token;
    my $pattern = join('|', map { quotemeta($JSON->encode($_)) } @token);
    my @piece = split /($pattern)/, $json;
    my @expression;
    for my $piece (@piece) {
        next unless length $piece;
        my ($token) = grep { $piece eq $JSON->encode($_) } @token;
        if (defined $token) {
            push @expression, $replacement->{$token};
        }
        else {
            push @expression, '"' . _sv_string($piece) . '"';
        }
    }
    return @expression == 1 ? $expression[0] : '{' . join(', ', @expression) . '}';
}

sub _runtime_scalar_expression($expression, $type) {
    my $width = $type->{width};
    my $digits = int(($width + 3) / 4);
    my $known = Math::BigInt->new(2)->bpow($width)->bsub(1)->as_hex;
    $known =~ s/\A0x//;
    $known = ('0' x ($digits - length($known))) . $known;
    my $zero = '0' x $digits;
    my $state_domain = $type->{state_domain} // 'four_state';
    my $type_id = $type->{type_id};
    return '$sformatf("{\"kind\":\"scalar\",\"known_hex\":\"'
        . $known . '\",\"signed\":' . ($type->{signed} ? 1 : 0)
        . ',\"state_domain\":\"' . _sv_string($state_domain)
        . '\",\"type_id\":\"' . _sv_string($type_id)
        . '\",\"value_hex\":\"%0' . $digits
        . 'x\",\"width\":' . $width . ',\"z_hex\":\"'
        . $zero . '\"}", ' . $expression . ')';
}

sub _static_scalar_value($type, $value) {
    my $width = $type->{width};
    my $digits = int(($width + 3) / 4);
    my $known = Math::BigInt->new(2)->bpow($width)->bsub(1)->as_hex;
    $known =~ s/\A0x//;
    $known = ('0' x ($digits - length($known))) . $known;
    my $hex = Math::BigInt->new($value)->as_hex;
    $hex =~ s/\A0x//;
    $hex = ('0' x ($digits - length($hex))) . $hex;
    return {
        kind => 'scalar',
        known_hex => $known,
        signed => $type->{signed} ? 1 : 0,
        state_domain => $type->{state_domain} // 'four_state',
        type_id => $type->{type_id},
        value_hex => $hex,
        width => 0 + $width,
        z_hex => '0' x $digits,
    };
}

sub _maximum_static_rank($operations) {
    my $maximum = 0;
    for my $operation (@$operations) {
        $maximum = $operation->{static_rank}
            if $operation->{static_rank} > $maximum;
    }
    return $maximum;
}

sub _render_property($node, $bridge, $backend) {
    return '1' unless ref($node) eq 'HASH';
    if (($node->{kind} // '') eq 'literal') {
        my $value = $node->{value};
        return "$value->{width}'h$value->{value_hex}";
    }
    if (($node->{kind} // '') eq 'reference') {
        if (($node->{op} // '') eq 'event' || ($node->{op} // '') eq 'event_count') {
            my ($name) = ($node->{binding_id} // '') =~ m{/([^/]+)\z};
            my $counter = 'vial_event_' . _sv_slug($name // 'unknown') . '_count';
            return ($node->{op} // '') eq 'event' ? "($counter != 0)" : $counter;
        }
        if (($node->{op} // '') eq 'sample') {
            my ($id) = ($node->{binding_id} // '') =~ m{/(endpoint/[^/]+|probe/[^/]+)\z};
            if (defined($id) && $id =~ /\Aprobe\//) {
                my ($probe) = grep { $_->{probe_id} eq $id } @{$bridge->{probes}};
                return 'vial_probe_' . _sv_slug($probe->{name}) if $probe;
            }
            return $backend->{$id}{target_name} if defined($id) && $backend->{$id};
        }
    }
    if (($node->{kind} // '') eq 'property') {
        return _render_property($node->{operands}[0], $bridge, $backend)
            if ($node->{op} eq 'within' || $node->{op} eq 'next');
    }
    if (($node->{kind} // '') eq 'operator') {
        my @operand = map { _render_property($_, $bridge, $backend) } @{$node->{operands}};
        return '(' . join(' && ', @operand) . ')' if $node->{op} eq 'logical_all_v1';
        return '(' . join(' || ', @operand) . ')' if $node->{op} eq 'logical_any_v1';
        return "($operand[0] == $operand[1])" if $node->{op} eq 'same'
            || $node->{op} eq 'same_bits_v1' || $node->{op} eq 'value_eq';
        return "(!$operand[0])" if $node->{op} eq 'logical_not_v1';
    }
    return '1';
}

sub _source_map_entries($execution, $bridge, $specs, $runtime_rel, $dut_rel) {
    my @spec = @$specs;
    push @spec, _map_spec(
        relpath => $runtime_rel, start => 1, end => _line_count(_render_runtime_package()),
        symbol => 'fsmgen_vial_runtime_pkg', role => 'backend_runtime_boilerplate',
        plan_paths => [], semantic_paths => [],
        bridge_paths => ['docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md'],
        locations => [],
    );
    push @spec, _map_spec(
        relpath => $dut_rel, start => 1, end => 1,
        symbol => $bridge->{units}[0]{name}, role => 'generated_hial_dut',
        plan_paths => [], semantic_paths => [$bridge->{units}[0]{unit_id}],
        bridge_paths => ['/units/0'], locations => [],
    );
    my @family = (
        [events => $execution->{events}],
        [models => $execution->{models}],
        [scoreboards => $execution->{scoreboards}],
        [coverpoints => $execution->{coverage}{coverpoints}],
        [crosses => $execution->{coverage}{crosses}],
        [faults => $execution->{faults}],
        [transactions => $execution->{transactions}],
    );
    for my $family (@family) {
        my ($name, $items) = @$family;
        for my $index (0 .. $#$items) {
            my $item = $items->[$index];
            my $identity = $item->{semantic_id} // $item->{instance_id}
                // $item->{transaction_id} // $item->{cross_id} // "$name/$index";
            push @spec, _map_spec(
                relpath => $specs->[0]{generated_relpath}, start => 1, end => 1,
                symbol => _sv_slug($identity), role => "semantic_$name",
                plan_paths => ["/$name/$index"], semantic_paths => [$identity],
                bridge_paths => [], locations => [$item->{source_location}],
            );
        }
    }
    my @entries;
    for my $spec (sort {
        $a->{generated_relpath} cmp $b->{generated_relpath}
            || $a->{generated_start_line} <=> $b->{generated_start_line}
            || $a->{generated_symbol} cmp $b->{generated_symbol}
    } @spec) {
        my $identity = join('|', map { defined($_) ? $_ : '' }
            @$spec{qw(generated_relpath generated_start_line generated_end_line generated_symbol role)});
        push @entries, {
            source_map_id => 'source-map/' . sha256_hex($identity),
            map { $_ => _clone($spec->{$_}) } grep { $_ ne 'source_map_id' } @SOURCE_MAP_ENTRY_KEYS,
        };
    }
    return \@entries;
}

sub _map_spec(%arg) {
    return {
        generated_relpath => $arg{relpath},
        generated_start_line => 0 + $arg{start},
        generated_end_line => 0 + $arg{end},
        generated_symbol => $arg{symbol},
        role => $arg{role},
        plan_paths => _clone($arg{plan_paths}),
        semantic_paths => _clone($arg{semantic_paths}),
        bridge_fact_paths => _clone($arg{bridge_paths}),
        source_locations => [map { defined($_) ? _clone($_) : () } @{$arg{locations}}],
    };
}

sub _probe_adapters($execution, $bridge, $source_map) {
    my %sv = map {
        $_->{target_language} eq 'systemverilog' ? ($_->{semantic_id} => $_) : ()
    } @{$bridge->{backend_bindings}};
    my @adapter;
    for my $index (0 .. $#{$execution->{bindings}{probes}}) {
        my $probe = $execution->{bindings}{probes}[$index];
        my $target = $sv{$probe->{probe_id}};
        my ($map) = grep {
            $_->{role} eq 'generated_probe_adapter'
                && grep { $_ eq $probe->{probe_id} } @{$_->{semantic_paths}}
        } @{$source_map->{entries}};
        confess "generated probe adapter is missing its source-map entry"
            unless $map;
        push @adapter, {
            adapter_id => 'adapter/' . $probe->{probe_id} . '/sv_portable_verilator',
            probe_id => $probe->{probe_id},
            bridge_binding_id => $target->{binding_id},
            kind => 'generated_hierarchical_read_alias_v1',
            generated_symbol => 'vial_probe_' . _sv_slug($target->{target_name}),
            width => $probe->{relations}[0]{width},
            relation_id => $probe->{relations}[0]{relation_id},
            source_map_id => $map->{source_map_id},
            capability_id => 'hial_vial.bridge_probe.equivalent_adapter_required',
        };
    }
    return \@adapter;
}

sub _probe_bindings_are_exact($execution, $bridge) {
    my %sv = map {
        $_->{target_language} eq 'systemverilog' ? ($_->{semantic_id} => $_) : ()
    } @{$bridge->{backend_bindings} || []};
    for my $probe (@{$execution->{bindings}{probes} || []}) {
        my $binding = $sv{$probe->{probe_id}};
        return 0 unless $binding
            && ($binding->{target_kind} // '') eq 'probe_adapter'
            && ($binding->{status} // '') eq 'adapter_required'
            && defined($binding->{target_name}) && !ref($binding->{target_name})
            && $binding->{target_name} =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    }
    return 1;
}

sub _relations($execution) {
    my @relation;
    for my $key (qw(endpoints probes)) {
        push @relation, map { @{$_->{relations} || []} } @{$execution->{bindings}{$key} || []};
    }
    push @relation, map { $_->{relation} } map { @{$_->{fields} || []} }
        @{$execution->{bindings}{transactions} || []};
    return @relation;
}

sub _fully_known_scalar($value) {
    return 0 unless defined($value->{known_hex}) && !ref($value->{known_hex})
        && $value->{known_hex} =~ /\A[0-9a-f]+\z/i
        && defined($value->{z_hex}) && !ref($value->{z_hex})
        && $value->{z_hex} =~ /\A0+\z/;
    my $expected = Math::BigInt->new(2)->bpow($value->{width})->bsub(1);
    my $known = Math::BigInt->from_hex('0x' . $value->{known_hex});
    return $known == $expected;
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
        $_->{target_language} eq 'systemverilog'
            && $_->{semantic_id} eq $semantic_id
            && $_->{target_kind} eq $target_kind
            && $_->{status} eq 'declared'
    } @{$bridge->{backend_bindings}};
    _throw('VIAL_BACKEND_UNSUPPORTED', "missing exact SystemVerilog $target_kind binding for '$semantic_id'", '/bridge_manifest/backend_bindings')
        unless @binding == 1 && $binding[0]{target_name} =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $binding[0]{target_name};
}

sub _endpoint_name_by_role($bridge, $backend, $role) {
    my @endpoint = grep { $_->{role} eq $role } @{$bridge->{endpoints}};
    confess "bridge requires exactly one '$role' endpoint" unless @endpoint == 1;
    return $backend->{$endpoint[0]{endpoint_id}}{target_name};
}

sub _operation_symbol($operation) {
    return 'vial_op_' . $operation->{static_rank} . '_' . _sv_slug($operation->{kind})
        . '_' . substr(sha256_hex($operation->{operation_id}), 0, 12);
}

sub _sv_slug($value) {
    my $slug = lc($value // 'unnamed');
    $slug =~ s/[^a-z0-9_]+/_/g;
    $slug =~ s/\A_+|_+\z//g;
    $slug = "n_$slug" if $slug !~ /\A[a-z_]/;
    return length($slug) ? $slug : 'unnamed';
}

sub _slug($value) {
    my $slug = lc($value // 'unnamed');
    $slug =~ s/[^a-z0-9]+/-/g;
    $slug =~ s/\A-+|-+\z//g;
    return length($slug) ? $slug : 'unnamed';
}

sub _sv_string($value) {
    $value //= '';
    $value =~ s/([\\"])/\\$1/g;
    return $value;
}

sub _line_count($text) {
    return scalar(() = $text =~ /\n/g);
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
    return 0 if grep { $_ eq '' || $_ eq '.' || $_ eq '..' } @part;
    return 1;
}

sub _unique(@items) {
    my %seen;
    return grep { !$seen{$_}++ } map {
        defined($_) ? $_ : 'undefined:negotiation-requirement'
    } @items;
}

sub _require_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    _throw('VIAL_BACKEND_INVOCATION_ERROR', "$label has unknown key '$unknown[0]'", '/') if @unknown;
    _throw('VIAL_BACKEND_INVOCATION_ERROR', "$label is missing key '$missing[0]'", '/') if @missing;
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        'FSM::VIAL::Backend::SVPortableVerilator::Failure';
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
        trace_contract => undef,
        artifacts => [],
        diagnostics => [{code => $code, severity => 'error', message => $message, path => $path}],
    });
}

sub _result($value) {
    _require_result_keys($value);
    return _clone($value);
}

sub _require_result_keys($value) {
    my %expected = map { $_ => 1 } @RESULT_KEYS;
    confess 'backend result has unknown key(s)' if grep { !$expected{$_} } keys %$value;
    confess 'backend result is missing key(s)' if grep { !exists($value->{$_}) } @RESULT_KEYS;
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown backend host failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown backend host failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'backend projection contains an unsupported reference' if ref($value);
    return $value;
}

1;
