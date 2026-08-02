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
            'portable VHDL foundation negotiation rejected one or more requirements',
            '/negotiation', $negotiation);
    }

    my $fixture_slug = _vhdl_slug($execution->{fixture}{fixture_name});
    my $top = $fixture_slug . '_tb';
    my $metadata_package = $fixture_slug . '_metadata_pkg';
    my $unit = $bridge->{units}[0];
    my $entity_name = _backend_name($bridge, $unit->{unit_id}, 'entity');
    my $operation_id = 'op-' . sha256_hex(_canonical_json({
        action => 'emit_foundation',
        artifact_root => $raw->{artifact_root},
        backend_profile => $BACKEND_PROFILE,
        bridge_manifest_id => $bridge->{manifest_id},
        plan_id => $execution->{plan_id},
    }));

    my $types_rel = "$BASE/src/fsmgen_vial_types_pkg.vhd";
    my $runtime_rel = "$BASE/src/fsmgen_vial_runtime_pkg.vhd";
    my $metadata_rel = "$BASE/src/$metadata_package.vhd";
    my $dut_rel = "$BASE/src/dut/$raw->{backend_inputs}{dut_vhdl}[0]{artifact_name}";
    my $top_rel = "$BASE/src/$top.vhd";
    my @source_order = ($types_rel, $runtime_rel, $metadata_rel, $dut_rel, $top_rel);

    my $types = _render_types_package();
    my $runtime = _render_runtime_package();
    my $metadata = _render_metadata_package(
        package_name => $metadata_package,
        execution => $execution,
        bridge => $bridge,
    );
    my $fixture = _render_fixture(
        top => $top,
        entity_name => $entity_name,
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
        'generated VHDL foundation failed structural validation', '/static_validation')
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
            top => $top,
            metadata_package => $metadata_package,
            entity_name => $entity_name,
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
            emission => 'passed_foundation_only',
            static_validation => 'passed_structural_only',
            source_map => 'passed_foundation_scope',
            review_gallery => 'byte_locked',
            provider_fetch => 'not_performed',
            analysis => 'not_run',
            elaboration => 'not_run',
            runtime => 'not_run',
            result => 'not_produced',
            parity => 'not_evaluated',
            psl => 'not_emitted',
            full_vhdl_2008 => 'not_claimed',
            product_support => 'not_claimed',
        },
        limitations => [qw(
            foundation_only single_unit single_domain drivers_deferred
            samplers_deferred scheduler_deferred scenarios_deferred
            models_deferred probe_adapters_deferred scoreboards_deferred
            coverage_deferred faults_deferred properties_deferred
            trace_deferred results_deferred no_psl no_provider_library
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
        result => {status => 'not_produced', schema => undef, relpath => undef},
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
        'portable VHDL foundation must emit exactly thirteen artifacts', '/artifacts')
        unless @artifacts == 13;

    return _result({
        ok => JSON::PP::true,
        status => 'emitted_unqualified_foundation',
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
    my (@required, @satisfied, @unsatisfied, @limitations);
    @required = qw(
        fsmgen.vial_execution_ir.v1
        core_directed_single_clock_execution_v1
        fsmgen.hial_vial_bridge_manifest.v1
        one_bound_hial_unit_v1
        one_selected_clock_domain_v1
        deterministic_hial_vhdl_source_v1
        declared_vhdl_entity_and_port_bindings_v1
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
    push @unsatisfied, 'native extensions are deferred beyond the VHDL foundation'
        unless ref($execution->{native_extensions}) eq 'ARRAY'
            && !@{$execution->{native_extensions}};

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
    @satisfied = @required unless @unsatisfied;
    @limitations = qw(
        foundation_only provider_free_vhdl_2008 one_unit one_clock_domain
        analysis_not_run elaboration_not_run runtime_not_run result_not_produced
        parity_not_evaluated psl_not_emitted support_not_claimed
    );
    return {
        negotiation_scope => 'portable_vhdl_foundation_v1',
        required => \@required,
        satisfied => \@satisfied,
        unsatisfied => [sort _unique(@unsatisfied)],
        deferred => [qw(
            drivers samplers inactive_edge_scheduler scenarios models
            probe_adapters scoreboards coverage faults properties trace results
            analysis elaboration runtime parity psl osvvm support
        )],
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

  function normalize_vial_value(value : std_logic) return vial_value_symbol_t;
  function observe_vial_value(value : std_logic) return vial_observation_t;
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
end package body fsmgen_vial_types_pkg;
VHDL
}

sub _render_runtime_package() {
    return <<'VHDL';
library ieee;
use ieee.std_logic_1164.all;

use work.fsmgen_vial_types_pkg.all;

package fsmgen_vial_runtime_pkg is
  constant FSMGEN_VIAL_RUNTIME_SCHEMA : string := "fsmgen.vial_vhdl_runtime.v1";

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
    return join("\n",
        'library ieee;',
        'use ieee.std_logic_1164.all;',
        '',
        "package $arg{package_name} is",
        '  constant VIAL_PLAN_ID : string := "' . _vhdl_string($execution->{plan_id}) . '";',
        '  constant VIAL_FIXTURE_ID : string := "' . _vhdl_string($execution->{fixture}{fixture_id}) . '";',
        '  constant VIAL_BRIDGE_MANIFEST_ID : string := "' . _vhdl_string($bridge->{manifest_id}) . '";',
        '  constant VIAL_UNIT_ID : string := "' . _vhdl_string($bridge->{units}[0]{unit_id}) . '";',
        '  constant VIAL_DOMAIN_ID : string := "' . _vhdl_string($domain->{domain_id}) . '";',
        '  constant VIAL_ACTIVE_EDGE : string := "' . _vhdl_string($domain->{active_edge}) . '";',
        '  constant VIAL_INACTIVE_EDGE : string := "falling";',
        '  constant VIAL_RESET_KIND : string := "' . _vhdl_string($domain->{reset_kind}) . '";',
        '  constant VIAL_RESET_POLARITY : string := "' . _vhdl_string($domain->{reset_polarity}) . '";',
        "end package $arg{package_name};",
        '',
    );
}

sub _render_fixture(%arg) {
    my $bridge = $arg{bridge};
    my %type = map { $_->{type_id} => $_ } @{$bridge->{types}};
    my %binding = map {
        ($_->{target_language} // '') eq 'vhdl'
            && ($_->{target_kind} // '') eq 'port'
            && ($_->{status} // '') eq 'declared'
            ? ($_->{semantic_id} => $_) : ()
    } @{$bridge->{backend_bindings}};
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
        "architecture foundation of $arg{top} is",
    );
    for my $endpoint (@{$bridge->{endpoints}}) {
        my $name = $binding{$endpoint->{endpoint_id}}{target_name};
        my $width = $type{$endpoint->{type_id}}{width};
        my $declaration = $width == 1
            ? "  signal $name : std_logic := '0';"
            : "  signal $name : std_logic_vector(" . ($width - 1)
                . " downto 0) := (others => '0');";
        push @line, $declaration;
    }
    push @line, '', 'begin',
        '  -- Driver, sampler, scheduler, scenario, and probe processes are emitted by later slices.',
        "  dut : entity work.$arg{entity_name}(rtl)",
        '    port map (';
    my @ports = map {
        my $name = $binding{$_->{endpoint_id}}{target_name};
        "      $name => $name"
    } @{$bridge->{endpoints}};
    for my $index (0 .. $#ports) {
        push @line, $ports[$index] . ($index == $#ports ? '' : ',');
    }
    push @line, '    );', "end architecture foundation;", '';
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
        [$arg{top_rel}, $arg{top}, 'fixture_top_foundation',
            ['/bindings/unit', '/bindings/endpoints'],
            [$execution->{fixture}{fixture_id}, $bridge->{units}[0]{unit_id},
                map { $_->{endpoint_id} } @{$bridge->{endpoints}}],
            ['/units/0', '/endpoints', '/backend_bindings'],
            [$execution->{fixture}{source_location}]],
    );
    my @entry;
    for my $spec (@spec) {
        my ($relpath, $symbol, $role, $plan, $semantic, $facts, $locations) = @$spec;
        my $text = $artifact{$relpath}{content};
        my $lines = _line_count($text);
        push @entry, {
            source_map_id => 'source-map/' . sha256_hex(_canonical_json({
                relpath => $relpath, symbol => $symbol, role => $role,
            })),
            generated_relpath => $relpath,
            generated_start_line => 1,
            generated_end_line => $lines,
            generated_start_column => 1,
            generated_end_column => _last_line_column($text),
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
