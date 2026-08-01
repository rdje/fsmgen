package FSM::VIAL::Backend::SVUVMAccellera2020_3_1;

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

use FSM::VIAL::Backend::SVUVMStaticValidator;

my $BACKEND_PROFILE = 'sv_uvm_emit.accellera_2020_3_1';
my $BACKEND_SCHEMA = 'fsmgen.vial_backend.sv_uvm_emit.accellera_2020_3_1.v1';
my $SOURCE_MAP_SCHEMA = 'fsmgen.vial_uvm_backend_source_map.v1';
my $STATIC_SCHEMA = 'fsmgen.vial_uvm_static_validation.v1';
my $BASE = 'backends/sv_uvm_emit.accellera_2020_3_1';
my $CONTRACT = 'docs/decisions/0050-vial-native-uvm-is-open-source-first-with-capability-gated-runtime.md';
my $JSON = JSON::PP->new->canonical(1);

my @RESULT_KEYS = qw(
    ok status backend_profile plan_id generated_top operation_id negotiation
    backend_manifest source_map static_validation artifacts diagnostics
);
my @MANIFEST_KEYS = qw(
    schema schema_version backend_profile emitter_revision plan_id fixture_id
    generated_top execution_profile methodology_profile capability_evidence
    limitations limits artifacts source_map static_validation result cleanup
    diagnostics
);
my @SOURCE_MAP_KEYS = qw(schema schema_version plan_id artifacts entries);
my @SOURCE_MAP_ENTRY_KEYS = qw(
    source_map_id generated_relpath generated_start_line generated_start_column
    generated_end_line generated_end_column generated_symbol role plan_paths
    semantic_paths bridge_fact_paths source_locations
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
    return _failure('VIAL_UVM_BACKEND_INVOCATION_ERROR', 'emit requires the exact backend class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_UVM_BACKEND_INVOCATION_ERROR', 'emit expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _emit($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error) && $error->isa(__PACKAGE__ . '::Failure');
    return _failure('VIAL_UVM_BACKEND_HOST_ERROR', _sanitize_exception($error), '/');
}

sub _emit($raw) {
    _require_exact_keys($raw, [qw(
        execution_ir bridge_manifest backend_inputs artifact_root backend_profile
    )], 'native UVM emission');
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR',
        'execution_ir must be an exact FSM::VIAL::ExecutionIR object', '/execution_ir')
        unless blessed($raw->{execution_ir})
            && ref($raw->{execution_ir}) eq 'FSM::VIAL::ExecutionIR';
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR',
        'bridge_manifest must be an exact HIAL/VIAL bridge manifest object', '/bridge_manifest')
        unless blessed($raw->{bridge_manifest})
            && ref($raw->{bridge_manifest}) eq 'FSM::HIAL::VIALBridge::Manifest';
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR',
        'backend_inputs must be one unblessed hash', '/backend_inputs')
        unless ref($raw->{backend_inputs}) eq 'HASH' && !blessed($raw->{backend_inputs});
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR',
        'artifact_root must be a safe repository-relative directory', '/artifact_root')
        unless _safe_relpath($raw->{artifact_root});
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        "backend profile must be '$BACKEND_PROFILE'", '/backend_profile')
        unless defined($raw->{backend_profile}) && !ref($raw->{backend_profile})
            && $raw->{backend_profile} eq $BACKEND_PROFILE;

    my $execution = $raw->{execution_ir}->as_hashref;
    my $bridge = $raw->{bridge_manifest}->as_hashref;
    my $negotiation = _negotiate($execution, $bridge, $raw->{backend_inputs});
    if (@{$negotiation->{unsatisfied}}) {
        return _failure(
            'VIAL_UVM_BACKEND_UNSUPPORTED',
            'native UVM foundation negotiation rejected one or more requirements',
            '/negotiation', $negotiation,
        );
    }

    my $fixture_slug = _sv_slug($execution->{fixture}{fixture_name});
    my $unit = $bridge->{units}[0];
    my $module_name = _backend_name($bridge, $unit->{unit_id}, 'module');
    my $interface_name = $fixture_slug . '_if';
    my $fixture_package = $fixture_slug . '_pkg';
    my $top = $fixture_slug . '_tb';
    my ($plan_digest) = $execution->{plan_id} =~ m{\Aplan/([0-9a-f]{64})\z};
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR', 'execution plan identity is malformed', '/execution_ir/plan_id')
        unless defined $plan_digest;
    my $operation_id = 'op-' . sha256_hex(_canonical_json({
        action => 'emit_native_uvm_foundation',
        artifact_root => $raw->{artifact_root},
        backend_profile => $BACKEND_PROFILE,
        bridge_manifest_id => $bridge->{manifest_id},
        emitter_revision => 1,
        plan_id => $execution->{plan_id},
    }));

    my $types_rel = "$BASE/src/fsmgen_vial_uvm_types_pkg.sv";
    my $components_rel = "$BASE/src/fsmgen_vial_uvm_components_pkg.sv";
    my $interface_rel = "$BASE/src/$interface_name.sv";
    my $fixture_rel = "$BASE/src/$fixture_package.sv";
    my $top_rel = "$BASE/src/$top.sv";
    my $dut_rel = "$BASE/src/dut/" . _slug($module_name) . '.sv';

    my ($types, $types_specs) = _render_types_package($types_rel);
    my ($components, $component_specs) = _render_components_package($components_rel);
    my ($interface, $interface_specs) = _render_interface(
        bridge => $bridge,
        interface_name => $interface_name,
        relpath => $interface_rel,
    );
    my ($fixture, $fixture_specs) = _render_fixture_package(
        execution => $execution,
        bridge => $bridge,
        interface_name => $interface_name,
        package_name => $fixture_package,
        relpath => $fixture_rel,
    );
    my ($top_source, $top_specs) = _render_top(
        execution => $execution,
        bridge => $bridge,
        interface_name => $interface_name,
        package_name => $fixture_package,
        module_name => $module_name,
        top => $top,
        relpath => $top_rel,
    );
    my $dut_input = $raw->{backend_inputs}{dut_systemverilog}[0];

    my @source_artifacts = (
        _artifact($dut_rel, 'systemverilog_source', 'systemverilog',
            'generated_hial_dut', $dut_input->{text}, [$dut_input->{source_id}]),
        _artifact($types_rel, 'systemverilog_source', 'systemverilog',
            'uvm_types_package', $types, [$CONTRACT]),
        _artifact($components_rel, 'systemverilog_source', 'systemverilog',
            'uvm_component_foundations', $components, [$CONTRACT]),
        _artifact($interface_rel, 'systemverilog_source', 'systemverilog',
            'uvm_fixture_interface', $interface, [$execution->{plan_id}, $bridge->{manifest_id}]),
        _artifact($fixture_rel, 'systemverilog_source', 'systemverilog',
            'uvm_fixture_package', $fixture, [$execution->{plan_id}, $bridge->{manifest_id}]),
        _artifact($top_rel, 'systemverilog_source', 'systemverilog',
            'uvm_fixture_top', $top_source, [$execution->{plan_id}, $bridge->{manifest_id}]),
    );
    my $source_bytes = 0;
    $source_bytes += bytes::length($_->{content}) for @source_artifacts;
    _throw('VIAL_UVM_BACKEND_LIMIT_EXCEEDED',
        'generated native UVM source exceeds the 16 MiB backend cap', '/artifacts')
        if $source_bytes > 16_777_216;

    my @spec = (
        @$types_specs, @$component_specs, @$interface_specs, @$fixture_specs, @$top_specs,
        _map_spec(
            relpath => $dut_rel, start => 1, end => _line_count($dut_input->{text}),
            symbol => $module_name, role => 'generated_hial_dut',
            plan_paths => ['/bindings/unit'], semantic_paths => [$unit->{unit_id}],
            bridge_paths => ['/units/0'], locations => [],
        ),
    );
    my %source_text = map { $_->{relpath} => $_->{content} } @source_artifacts;
    my $source_map = {
        schema => $SOURCE_MAP_SCHEMA,
        schema_version => 1,
        plan_id => $execution->{plan_id},
        artifacts => [sort {$a->{relpath} cmp $b->{relpath}}
            map { _artifact_ref($_) } @source_artifacts],
        entries => _source_map_entries(\@spec, \%source_text),
    };
    _throw('VIAL_UVM_BACKEND_LIMIT_EXCEEDED',
        'native UVM source map exceeds its record cap', '/source_map/entries')
        if @{$source_map->{entries}} > 1_000_000;

    my $static = FSM::VIAL::Backend::SVUVMStaticValidator->validate({
        backend_profile => $BACKEND_PROFILE,
        artifacts => \@source_artifacts,
    });
    if (!$static->{ok}) {
        my $detail = join('; ', map { "$_->{code}: $_->{message}" }
            @{$static->{diagnostics}});
        return _failure(
            'VIAL_UVM_BACKEND_STATIC_VALIDATION_ERROR',
            'generated native UVM foundation failed static shape validation: ' . $detail,
            '/static_validation', $negotiation,
        );
    }

    my $methodology = _methodology_profile();
    my @support_artifacts = (
        _artifact("$BASE/backend-source-map.json", 'source_map', 'json',
            'backend_source_map', _json_text($source_map), [$execution->{plan_id}]),
        _artifact("$BASE/evidence/methodology-profile.json", 'methodology_profile', 'json',
            'selected_methodology_profile', _json_text($methodology), [$CONTRACT]),
        _artifact("$BASE/evidence/static-validation.json", 'validation_report', 'json',
            'static_validation', _json_text($static), [$execution->{plan_id}]),
    );
    my @referenced = sort { $a->{relpath} cmp $b->{relpath} }
        map { _artifact_ref($_) } (@source_artifacts, @support_artifacts);
    my $manifest = {
        schema => $BACKEND_SCHEMA,
        schema_version => 1,
        backend_profile => $BACKEND_PROFILE,
        emitter_revision => 1,
        plan_id => $execution->{plan_id},
        fixture_id => $execution->{fixture}{fixture_id},
        generated_top => $top,
        execution_profile => $execution->{profile},
        methodology_profile => {
            relpath => "$BASE/evidence/methodology-profile.json",
            sha256 => sha256_hex(_json_text($methodology)),
            api_target => 'IEEE 1800.2-2020 / Accellera UVM 2020-3.1',
            library_materialization => 'not_required_for_emission',
        },
        capability_evidence => {
            negotiation => _clone($negotiation),
            emission => 'passed',
            static_validation => 'passed_structural_only',
            manual_review => 'pending',
            preprocessing => 'not_run',
            parse => 'not_run',
            library_compile => 'not_run',
            fixture_compile => 'not_run',
            elaboration => 'not_run',
            runtime => 'not_run',
            result => 'not_produced',
            parity => 'not_evaluated',
            library_materialization => 'not_required_for_emission',
            emitted_foundations => [qw(
                typed_context component_bases timed_interface fixture_config
                fixture_environment fixture_test dut_binding top
            )],
            deferred_to_later_emission_slices => [qw(
                lifecycle_execution notification_interception stimulus_sequences
                tlm factory_overrides scoped_configuration ral randomization
                coverage properties models scoreboards faults results
            )],
        },
        limitations => [
            'static validation checks deterministic structure only; it is not a SystemVerilog parser or compiler',
            'the first gallery emits typed, interface, component, fixture, and top foundations only',
            'UVM library bytes are intentionally absent from and unnecessary for ordinary emission',
            'preprocessing, parse, library compile, fixture compile, elaboration, runtime, result, and parity have not run',
            'one HIAL unit and one VIAL clock domain are selected for the first review gallery',
        ],
        limits => {
            selected_units => 1,
            selected_domains => 1,
            generated_source_artifacts => 6,
            generated_source_bytes => 16_777_216,
            total_artifacts => 10,
            source_map_entries => 1_000_000,
            identifier_bytes => 255,
        },
        artifacts => \@referenced,
        source_map => {
            schema => $SOURCE_MAP_SCHEMA,
            relpath => "$BASE/backend-source-map.json",
            sha256 => sha256_hex(_json_text($source_map)),
            entry_count => scalar(@{$source_map->{entries}}),
        },
        static_validation => {
            schema => $STATIC_SCHEMA,
            relpath => "$BASE/evidence/static-validation.json",
            sha256 => sha256_hex(_json_text($static)),
            status => $static->{status},
            check_count => scalar(@{$static->{checks}}),
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
    _throw('VIAL_UVM_BACKEND_LIMIT_EXCEEDED',
        'native UVM artifact graph exceeds its ten-artifact foundation cap', '/artifacts')
        unless @artifacts == 10;

    return _result({
        ok => JSON::PP::true,
        status => 'emitted_unqualified',
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
    my (@required, @satisfied, @unsatisfied, @deferred);
    push @required, qw(
        fsmgen.vial_execution_ir.v1
        core_directed_single_clock_execution_v1
        fsmgen.hial_vial_bridge_manifest.v1
        one_bound_hial_unit_v1
        one_selected_clock_domain_v1
        deterministic_hial_systemverilog_source_v1
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
    push @unsatisfied, 'native extensions are deferred beyond the first UVM foundation'
        if ref($execution->{native_extensions}) ne 'ARRAY' || @{$execution->{native_extensions} || []};

    my $inputs_ok = eval {
        _require_exact_keys($backend_inputs, [qw(dut_systemverilog)], 'backend inputs');
        confess 'exactly one deterministic DUT source is required'
            unless ref($backend_inputs->{dut_systemverilog}) eq 'ARRAY'
                && @{$backend_inputs->{dut_systemverilog}} == 1;
        my $dut = $backend_inputs->{dut_systemverilog}[0];
        confess 'DUT source must be one unblessed hash'
            unless ref($dut) eq 'HASH' && !blessed($dut);
        confess 'DUT source text or digest is malformed'
            unless defined($dut->{text}) && !ref($dut->{text})
                && defined($dut->{content_sha256}) && !ref($dut->{content_sha256})
                && sha256_hex($dut->{text}) eq $dut->{content_sha256};
        1;
    };
    push @unsatisfied, 'one exact deterministic DUT SystemVerilog source is required'
        unless $inputs_ok;

    my %sv_binding = map {
        ($_->{target_language} // '') eq 'systemverilog'
            ? ($_->{semantic_id} => $_) : ()
    } @{$bridge->{backend_bindings} || []};
    for my $endpoint (@{$bridge->{endpoints} || []}) {
        my $binding = $sv_binding{$endpoint->{endpoint_id}};
        push @unsatisfied, "endpoint '$endpoint->{endpoint_id}' lacks one declared SystemVerilog binding"
            unless $binding && ($binding->{status} // '') eq 'declared'
                && ($binding->{target_kind} // '') eq 'port'
                && _identifier($binding->{target_name});
    }
    @satisfied = @required unless @unsatisfied;
    @deferred = qw(
        complete_component_topology lifecycle_execution notification_interception
        sequence_and_tlm_execution factory_and_config_semantics ral_semantics
        native_constraints coverage_and_properties model_scoreboard_fault_result
        preprocessing parse library_compile fixture_compile elaboration runtime
        result parity
    );
    return {
        negotiation_scope => 'native_uvm_emission_foundation_v1',
        required => [sort @required],
        satisfied => [sort @satisfied],
        unsatisfied => [sort @unsatisfied],
        deferred => [sort @deferred],
        limitations => [
            'negotiation covers emission foundations, not full VIAL-to-UVM semantic breadth',
            'library-dependent and executable gates are deliberately outside ordinary emission',
        ],
    };
}

sub _render_types_package($relpath) {
    my @line;
    my $push = sub (@text) { push @line, @text };
    $push->('// Simulator-neutral native VIAL UVM support.');
    $push->('package fsmgen_vial_uvm_types_pkg;');
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    $push->('  import uvm_pkg::*;');
    $push->('  `include "uvm_macros.svh"');
    $push->('');
    $push->('  typedef enum int unsigned {');
    $push->('    VIAL_DRIVE_PHASE = 0,');
    $push->('    VIAL_SAMPLE_PHASE = 1,');
    $push->('    VIAL_REACT_PHASE = 2,');
    $push->('    VIAL_CHECK_PHASE = 3');
    $push->('  } vial_phase_e;');
    $push->('');
    $push->('  typedef struct {');
    $push->('    longint unsigned cycle;');
    $push->('    int unsigned ordinal;');
    $push->('    vial_phase_e phase;');
    $push->('  } vial_logical_time_s;');
    $push->('');
    my $class_start = @line + 1;
    $push->('  class fsmgen_vial_execution_context extends uvm_object;');
    $push->('    `uvm_object_utils(fsmgen_vial_execution_context)');
    $push->('');
    $push->('    string plan_id;');
    $push->('    vial_logical_time_s logical_time;');
    $push->('');
    $push->('    function new(string name = "fsmgen_vial_execution_context");');
    $push->('      super.new(name);');
    $push->('      logical_time = \'{cycle: 0, ordinal: 0, phase: VIAL_DRIVE_PHASE};');
    $push->('    endfunction');
    $push->('');
    $push->('    function void set_logical_time(');
    $push->('      longint unsigned cycle,');
    $push->('      vial_phase_e phase,');
    $push->('      int unsigned ordinal = 0');
    $push->('    );');
    $push->('      logical_time.cycle = cycle;');
    $push->('      logical_time.phase = phase;');
    $push->('      logical_time.ordinal = ordinal;');
    $push->('    endfunction');
    $push->('  endclass');
    $push->('endpackage');
    my $text = join("\n", @line) . "\n";
    return ($text, [_map_spec(
        relpath => $relpath, start => $class_start, end => _line_count($text) - 1,
        symbol => 'fsmgen_vial_execution_context', role => 'typed_execution_context',
        plan_paths => ['/profile', '/operation_graph'], semantic_paths => [],
        bridge_paths => [$CONTRACT], locations => [],
    )]);
}

sub _render_components_package($relpath) {
    my @line;
    my @spec;
    my $push = sub (@text) { push @line, @text };
    $push->('// Simulator-neutral native VIAL UVM component foundations.');
    $push->('package fsmgen_vial_uvm_components_pkg;');
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    $push->('  import uvm_pkg::*;');
    $push->('  `include "uvm_macros.svh"');
    $push->('  import fsmgen_vial_uvm_types_pkg::*;');
    $push->('');
    my $base_start = @line + 1;
    $push->('  class fsmgen_vial_component_base extends uvm_component;');
    $push->('    `uvm_component_utils(fsmgen_vial_component_base)');
    $push->('');
    $push->('    fsmgen_vial_execution_context context;');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build_phase(uvm_phase phase);');
    $push->('      super.build_phase(phase);');
    $push->('      if (!uvm_config_db#(fsmgen_vial_execution_context)::get(this, "", "vial_context", context))');
    $push->('        `uvm_fatal("VIAL/CONTEXT", "missing VIAL execution context")');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $relpath, start => $base_start, end => scalar(@line),
        symbol => 'fsmgen_vial_component_base', role => 'uvm_component_foundation',
        plan_paths => ['/fixture'], semantic_paths => [], bridge_paths => [$CONTRACT], locations => [],
    );
    $push->('');
    my $env_start = @line + 1;
    $push->('  class fsmgen_vial_env_base extends fsmgen_vial_component_base;');
    $push->('    `uvm_component_utils(fsmgen_vial_env_base)');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $relpath, start => $env_start, end => scalar(@line),
        symbol => 'fsmgen_vial_env_base', role => 'uvm_environment_foundation',
        plan_paths => ['/fixture'], semantic_paths => [], bridge_paths => [$CONTRACT], locations => [],
    );
    $push->('');
    my $test_start = @line + 1;
    $push->('  class fsmgen_vial_test_base extends uvm_test;');
    $push->('    `uvm_component_utils(fsmgen_vial_test_base)');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $relpath, start => $test_start, end => scalar(@line),
        symbol => 'fsmgen_vial_test_base', role => 'uvm_test_foundation',
        plan_paths => ['/fixture'], semantic_paths => [], bridge_paths => [$CONTRACT], locations => [],
    );
    $push->('endpackage');
    return (join("\n", @line) . "\n", \@spec);
}

sub _render_interface(%arg) {
    my $bridge = $arg{bridge};
    my %type = map { $_->{type_id} => $_ } @{$bridge->{types}};
    my %binding = _sv_binding_map($bridge);
    my $domain = $bridge->{domains}[0];
    my $clock = $binding{$domain->{clock_endpoint_id}}{target_name};
    my $inactive = $domain->{active_edge} eq 'rising' ? 'negedge' : 'posedge';
    my $active = $domain->{active_edge} eq 'rising' ? 'posedge' : 'negedge';
    my @line;
    my @spec;
    my $push = sub (@text) { push @line, @text };
    $push->('// Generated VIAL timed-interface foundation; simulator-neutral IEEE SystemVerilog.');
    $push->("interface $arg{interface_name};");
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    for my $index (0 .. $#{$bridge->{endpoints}}) {
        my $endpoint = $bridge->{endpoints}[$index];
        my $name = $binding{$endpoint->{endpoint_id}}{target_name};
        my $record = $type{$endpoint->{type_id}};
        my $start = @line + 1;
        $push->('  logic ' . _packed_type($record) . "$name;");
        push @spec, _map_spec(
            relpath => $arg{relpath}, start => $start, end => $start,
            symbol => $name, role => $endpoint->{direction} eq 'input'
                ? 'driver_signal_binding' : 'monitor_signal_binding',
            plan_paths => ["/bindings/endpoints/$index"],
            semantic_paths => [$endpoint->{endpoint_id}],
            bridge_paths => ["/endpoints/$index"], locations => [],
        );
    }
    my @driven = map { $binding{$_->{endpoint_id}}{target_name} }
        grep { $_->{direction} eq 'input' && $_->{endpoint_id} ne $domain->{clock_endpoint_id} }
        @{$bridge->{endpoints}};
    my @sampled = map { $binding{$_->{endpoint_id}}{target_name} }
        grep { $_->{endpoint_id} ne $domain->{clock_endpoint_id} } @{$bridge->{endpoints}};
    $push->('');
    my $driver_start = @line + 1;
    $push->("  clocking driver_cb @($inactive $clock);");
    $push->('    default input #1step output #0;');
    $push->('    output ' . join(', ', @driven) . ';') if @driven;
    $push->('    input ' . join(', ', grep {
        my $candidate = $_;
        !grep { $_ eq $candidate } @driven
    } @sampled) . ';') if grep {
        my $candidate = $_;
        !grep { $_ eq $candidate } @driven
    } @sampled;
    $push->('  endclocking');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $driver_start, end => scalar(@line),
        symbol => 'driver_cb', role => 'logical_drive_clocking_block',
        plan_paths => ['/domains/0', '/operation_graph'],
        semantic_paths => [$domain->{domain_id}], bridge_paths => ['/domains/0'], locations => [],
    );
    $push->('');
    my $monitor_start = @line + 1;
    $push->("  clocking monitor_cb @($active $clock);");
    $push->('    default input #1step;');
    $push->('    input ' . join(', ', @sampled) . ';') if @sampled;
    $push->('  endclocking');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $monitor_start, end => scalar(@line),
        symbol => 'monitor_cb', role => 'logical_sample_clocking_block',
        plan_paths => ['/domains/0', '/operation_graph'],
        semantic_paths => [$domain->{domain_id}], bridge_paths => ['/domains/0'], locations => [],
    );
    $push->('');
    $push->("  modport driver_mp(clocking driver_cb, input $clock);");
    $push->("  modport monitor_mp(clocking monitor_cb, input $clock);");
    $push->('endinterface');
    return (join("\n", @line) . "\n", \@spec);
}

sub _render_fixture_package(%arg) {
    my $fixture_slug = _sv_slug($arg{execution}{fixture}{fixture_name});
    my $config = $fixture_slug . '_config';
    my $env = $fixture_slug . '_env';
    my $test = $fixture_slug . '_test';
    my @line;
    my @spec;
    my $push = sub (@text) { push @line, @text };
    $push->('// Generated native VIAL UVM fixture foundation.');
    $push->("package $arg{package_name};");
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    $push->('  import uvm_pkg::*;');
    $push->('  `include "uvm_macros.svh"');
    $push->('  import fsmgen_vial_uvm_types_pkg::*;');
    $push->('  import fsmgen_vial_uvm_components_pkg::*;');
    $push->('');
    my $config_start = @line + 1;
    $push->("  class $config extends uvm_object;");
    $push->("    `uvm_object_utils($config)");
    $push->('');
    $push->("    virtual $arg{interface_name} vif;");
    $push->('');
    $push->("    function new(string name = \"$config\");");
    $push->('      super.new(name);');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $config_start, end => scalar(@line),
        symbol => $config, role => 'fixture_configuration_foundation',
        plan_paths => ['/fixture', '/bindings'], semantic_paths => [$arg{execution}{fixture}{fixture_id}],
        bridge_paths => ['/units/0', '/domains/0'], locations => [],
    );
    $push->('');
    my $env_start = @line + 1;
    $push->("  class $env extends fsmgen_vial_env_base;");
    $push->("    `uvm_component_utils($env)");
    $push->('');
    $push->("    $config cfg;");
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build_phase(uvm_phase phase);');
    $push->('      super.build_phase(phase);');
    $push->("      if (!uvm_config_db#($config)::get(this, \"\", \"cfg\", cfg))");
    $push->('        `uvm_fatal("VIAL/CONFIG", "missing generated fixture configuration")');
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $env_start, end => scalar(@line),
        symbol => $env, role => 'fixture_environment_foundation',
        plan_paths => ['/fixture'], semantic_paths => [$arg{execution}{fixture}{fixture_id}],
        bridge_paths => ['/units/0'], locations => [],
    );
    $push->('');
    my $test_start = @line + 1;
    $push->("  class $test extends fsmgen_vial_test_base;");
    $push->("    `uvm_component_utils($test)");
    $push->('');
    $push->("    $config cfg;");
    $push->("    $env env;");
    $push->('    fsmgen_vial_execution_context context;');
    $push->('');
    $push->('    function new(string name, uvm_component parent);');
    $push->('      super.new(name, parent);');
    $push->('    endfunction');
    $push->('');
    $push->('    virtual function void build_phase(uvm_phase phase);');
    $push->('      super.build_phase(phase);');
    $push->("      cfg = ${config}::type_id::create(\"cfg\");");
    $push->("      if (!uvm_config_db#(virtual $arg{interface_name})::get(this, \"\", \"vif\", cfg.vif))");
    $push->('        `uvm_fatal("VIAL/VIF", "missing generated virtual interface")');
    $push->('      context = fsmgen_vial_execution_context::type_id::create("context");');
    $push->('      context.plan_id = "' . _sv_string($arg{execution}{plan_id}) . '";');
    $push->("      uvm_config_db#($config)::set(this, \"env\", \"cfg\", cfg);");
    $push->('      uvm_config_db#(fsmgen_vial_execution_context)::set(this, "env", "vial_context", context);');
    $push->("      env = ${env}::type_id::create(\"env\", this);");
    $push->('    endfunction');
    $push->('  endclass');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $test_start, end => scalar(@line),
        symbol => $test, role => 'fixture_test_foundation',
        plan_paths => ['/fixture', '/profile'], semantic_paths => [$arg{execution}{fixture}{fixture_id}],
        bridge_paths => ['/units/0'], locations => [],
    );
    $push->('endpackage');
    return (join("\n", @line) . "\n", \@spec);
}

sub _render_top(%arg) {
    my $bridge = $arg{bridge};
    my %binding = _sv_binding_map($bridge);
    my $domain = $bridge->{domains}[0];
    my $clock = $binding{$domain->{clock_endpoint_id}}{target_name};
    my $reset = $binding{$domain->{reset_endpoint_id}}{target_name};
    my $reset_active = $domain->{reset_polarity} eq 'active_low' ? "1'b0" : "1'b1";
    my $reset_inactive = $domain->{reset_polarity} eq 'active_low' ? "1'b1" : "1'b0";
    my $fixture_slug = _sv_slug($arg{execution}{fixture}{fixture_name});
    my $test = $fixture_slug . '_test';
    my @line;
    my @spec;
    my $push = sub (@text) { push @line, @text };
    $push->('// Generated native VIAL UVM top foundation; emission is not compile qualification.');
    $push->("module $arg{top};");
    $push->('  timeunit 1ns;');
    $push->('  timeprecision 1ps;');
    $push->('');
    $push->('  import uvm_pkg::*;');
    $push->("  import $arg{package_name}::*;");
    $push->('');
    $push->("  $arg{interface_name} vial_if();");
    $push->('');
    my @ports = map {
        my $name = $binding{$_->{endpoint_id}}{target_name};
        "    .$name(vial_if.$name)"
    } @{$bridge->{endpoints}};
    my $dut_start = @line + 1;
    $push->("  $arg{module_name} dut (");
    for my $index (0 .. $#ports) {
        $push->($ports[$index] . ($index == $#ports ? '' : ','));
    }
    $push->('  );');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $dut_start, end => scalar(@line),
        symbol => 'dut', role => 'bound_dut_instance',
        plan_paths => ['/bindings/unit'], semantic_paths => [$bridge->{units}[0]{unit_id}],
        bridge_paths => ['/units/0'], locations => [],
    );
    $push->('');
    my $clock_start = @line + 1;
    $push->('  initial begin');
    $push->("    vial_if.$clock = 1'b0;");
    $push->('    forever #5ns vial_if.' . $clock . ' = ~vial_if.' . $clock . ';');
    $push->('  end');
    $push->('');
    $push->('  initial begin');
    $push->("    vial_if.$reset = $reset_active;");
    $push->('    repeat (2) @(posedge vial_if.' . $clock . ');');
    $push->("    vial_if.$reset = $reset_inactive;");
    $push->('  end');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $clock_start, end => scalar(@line),
        symbol => 'vial_clock_reset_foundation', role => 'clock_reset_foundation',
        plan_paths => ['/domains/0'], semantic_paths => [$domain->{domain_id}],
        bridge_paths => ['/domains/0'], locations => [],
    );
    $push->('');
    my $uvm_start = @line + 1;
    $push->('  initial begin');
    $push->("    uvm_config_db#(virtual $arg{interface_name})::set(null, \"uvm_test_top\", \"vif\", vial_if);");
    $push->("    run_test(\"$test\");");
    $push->('  end');
    push @spec, _map_spec(
        relpath => $arg{relpath}, start => $uvm_start, end => scalar(@line),
        symbol => $arg{top}, role => 'uvm_top_foundation',
        plan_paths => ['/fixture', '/profile'], semantic_paths => [$arg{execution}{fixture}{fixture_id}],
        bridge_paths => ['/units/0', '/domains/0'], locations => [],
    );
    $push->('endmodule');
    return (join("\n", @line) . "\n", \@spec);
}

sub _methodology_profile() {
    return {
        schema => 'fsmgen.vial_uvm_methodology_profile.v1',
        schema_version => 1,
        backend_profile => $BACKEND_PROFILE,
        target_language => 'IEEE SystemVerilog',
        methodology_standard => {
            organization => 'IEEE',
            designation => 'IEEE 1800.2-2020',
            revision => '2020',
        },
        reference_implementation => {
            organization => 'Accellera Systems Initiative',
            name => 'Universal Verification Methodology',
            release => '2020-3.1',
            git_tag => '2020.3.1',
            git_commit => '78c06547a2a0a29b3dc9dcafae62b75b2ff61544',
            license => 'Apache-2.0',
        },
        api_target => 'IEEE 1800.2-2020 / Accellera UVM 2020-3.1',
        canonical_source_policy => 'simulator_neutral_no_provider_conditionals',
        library_materialization => {
            emission_requirement => 'not_required',
            current_state => 'not_requested_or_inspected',
            required_before => [qw(
                library_dependent_preprocessing library_compile fixture_compile
                elaboration runtime
            )],
            project_local_verified_copy_required => JSON::PP::true,
            network_fetch_during_emission => JSON::PP::false,
        },
        execution_evidence => JSON::PP::false,
    };
}

sub _source_map_entries($specs, $source_text) {
    my @entries;
    for my $spec (sort {
        $a->{generated_relpath} cmp $b->{generated_relpath}
            || $a->{generated_start_line} <=> $b->{generated_start_line}
            || $a->{generated_symbol} cmp $b->{generated_symbol}
    } @$specs) {
        my $text = $source_text->{$spec->{generated_relpath}};
        confess "source-map artifact '$spec->{generated_relpath}' is unavailable"
            unless defined $text;
        my $entry = {
            %$spec,
            generated_start_column => 1,
            generated_end_column => _line_bytes($text, $spec->{generated_end_line}) + 1,
        };
        my $identity = join('|', map { defined($_) ? $_ : '' }
            @$entry{qw(generated_relpath generated_start_line generated_start_column generated_end_line generated_end_column generated_symbol role)});
        push @entries, {
            source_map_id => 'source-map/' . sha256_hex($identity),
            map { $_ => _clone($entry->{$_}) }
                grep { $_ ne 'source_map_id' } @SOURCE_MAP_ENTRY_KEYS,
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

sub _sv_binding_map($bridge) {
    return map {
        ($_->{target_language} // '') eq 'systemverilog'
            ? ($_->{semantic_id} => $_) : ()
    } @{$bridge->{backend_bindings}};
}

sub _backend_name($bridge, $semantic_id, $target_kind) {
    my @binding = grep {
        ($_->{target_language} // '') eq 'systemverilog'
            && ($_->{semantic_id} // '') eq $semantic_id
            && ($_->{target_kind} // '') eq $target_kind
            && ($_->{status} // '') eq 'declared'
    } @{$bridge->{backend_bindings}};
    _throw('VIAL_UVM_BACKEND_UNSUPPORTED',
        "missing exact SystemVerilog $target_kind binding for '$semantic_id'",
        '/bridge_manifest/backend_bindings')
        unless @binding == 1 && _identifier($binding[0]{target_name});
    return $binding[0]{target_name};
}

sub _packed_type($record) {
    my $width = $record->{width};
    my $signed = $record->{signed} ? 'signed ' : '';
    return $signed . ($width > 1 ? '[' . ($width - 1) . ':0] ' : '');
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

sub _identifier($value) {
    return defined($value) && !ref($value)
        && bytes::length($value) <= 255
        && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
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

sub _line_bytes($text, $line_number) {
    confess 'source-map line number must be positive'
        unless defined($line_number) && !ref($line_number) && $line_number =~ /\A[1-9][0-9]*\z/;
    my @line = split /\n/, $text, -1;
    confess "source-map line $line_number is outside generated source"
        if $line_number > @line - 1;
    return bytes::length($line[$line_number - 1]);
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
    return !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $value, -1;
}

sub _require_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR', "$label has unknown key '$unknown[0]'", '/') if @unknown;
    _throw('VIAL_UVM_BACKEND_INVOCATION_ERROR', "$label is missing key '$missing[0]'", '/') if @missing;
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        __PACKAGE__ . '::Failure';
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
        diagnostics => [{code => $code, severity => 'error', message => $message, path => $path}],
    });
}

sub _result($value) {
    my %expected = map { $_ => 1 } @RESULT_KEYS;
    confess 'native UVM backend result has unknown key(s)'
        if grep { !$expected{$_} } keys %$value;
    confess 'native UVM backend result is missing key(s)'
        if grep { !exists($value->{$_}) } @RESULT_KEYS;
    return _clone($value);
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown native UVM backend host failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown native UVM backend host failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'native UVM backend projection contains unsupported reference data' if ref($value);
    return $value;
}

package FSM::VIAL::Backend::SVUVMAccellera2020_3_1::Failure;

use overload '""' => sub { $_[0]{message} // 'native UVM backend failure' }, fallback => 1;

1;
