package FSM::VIAL::Backend::VHDLOSVVM2026_05;

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

use FSM::VIAL::Backend::OSVVM2026_05Materialization;
use FSM::VIAL::Backend::VHDLOSVVMStaticValidator;
use FSM::VIAL::Backend::VHDLPortableGHDL;

my $BACKEND_PROFILE = 'vhdl_osvvm_qualified';
my $BACKEND_SCHEMA = 'fsmgen.vial_backend.vhdl_osvvm.v1';
my $BASE = 'backends/vhdl_osvvm_qualified';
my $DEPENDENCY_ROOT = '.artifacts/cache/providers/osvvm/2026.05/source';
my $JSON = JSON::PP->new->canonical(1);
my $PRETTY_JSON = JSON::PP->new->canonical(1)->pretty(1);
my @REQUIREMENT_IDS = qw(
    advanced_coverage advanced_data_structure advanced_randomization
    advanced_reporting advanced_scoreboard advanced_synchronization
    verification_component_adapter
);
my @RESULT_KEYS = qw(
    ok status backend_profile plan_id generated_top operation_id negotiation
    provider_materialization mapping_matrix semantic_preservation source_map
    static_validation backend_manifest artifacts diagnostics
);

sub result_keys($class) {
    _exact_class($class, 'result_keys');
    return [@RESULT_KEYS];
}

sub emit($class, @args) {
    return _failure('VIAL_OSVVM_BACKEND_INVOCATION_ERROR',
        'emit requires the exact backend class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_OSVVM_BACKEND_INVOCATION_ERROR',
        'emit expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _emit($args[0]) };
    return $result if defined $result;
    my $error = $@ || 'unknown OSVVM backend error';
    $error =~ s/\s+\z//;
    return _failure('VIAL_OSVVM_BACKEND_HOST_ERROR', $error, '/');
}

sub _emit($raw) {
    _require_keys($raw, [qw(
        execution_ir bridge_manifest backend_inputs artifact_root
        backend_profile dependency_root advanced_requirements
    )]);
    confess "backend_profile must be '$BACKEND_PROFILE'\n"
        unless defined($raw->{backend_profile}) && !ref($raw->{backend_profile})
            && $raw->{backend_profile} eq $BACKEND_PROFILE;
    confess "dependency_root must be the exact repository-local OSVVM 2026.05 root\n"
        unless defined($raw->{dependency_root}) && !ref($raw->{dependency_root})
            && $raw->{dependency_root} eq $DEPENDENCY_ROOT;
    confess "advanced_requirements must be one exact array\n"
        unless ref($raw->{advanced_requirements}) eq 'ARRAY';
    my @requirements = @{$raw->{advanced_requirements}};
    confess "advanced_requirements must contain seven unique sorted exact requirements\n"
        unless join("\0", @requirements) eq join("\0", @REQUIREMENT_IDS);

    my $provider = FSM::VIAL::Backend::OSVVM2026_05Materialization->verify({
        dependency_root => $raw->{dependency_root},
    });
    return _failure('VIAL_OSVVM_PROVIDER_MATERIALIZATION_ERROR',
        $provider->{diagnostics}[0]{message}, '/dependency_root')
        unless $provider->{ok};

    my $portable = FSM::VIAL::Backend::VHDLPortableGHDL->emit({
        execution_ir => $raw->{execution_ir},
        bridge_manifest => $raw->{bridge_manifest},
        backend_inputs => $raw->{backend_inputs},
        artifact_root => $raw->{artifact_root},
        backend_profile => 'vhdl_portable_ghdl',
    });
    return _failure('VIAL_OSVVM_PORTABLE_FOUNDATION_ERROR',
        $portable->{diagnostics}[0]{message}, '/portable_foundation')
        unless $portable->{ok};

    my @portable_source;
    my @preserved;
    for my $artifact (grep { ($_->{language} // '') eq 'vhdl' }
        @{$portable->{artifacts}}) {
        my $portable_sha256 = sha256_hex($artifact->{content});
        my $portable_bytes = bytes::length($artifact->{content});
        my $tail = $artifact->{relpath};
        $tail =~ s{\Abackends/vhdl_portable_ghdl/src/}{} or
            confess "portable source path is outside the selected source root\n";
        my $advanced = _artifact(
            "$BASE/src/portable/$tail",
            "portable_$artifact->{role}",
            'vhdl_source',
            'vhdl',
            $artifact->{content},
            [$portable_sha256, $portable->{plan_id}],
        );
        push @portable_source, $advanced;
        push @preserved, {
            role => $artifact->{role},
            portable_relpath => $artifact->{relpath},
            advanced_relpath => $advanced->{relpath},
            byte_length => $portable_bytes,
            portable_sha256 => $portable_sha256,
            advanced_sha256 => $advanced->{sha256},
            byte_identical => JSON::PP::true,
        };
    }
    confess "portable foundation did not provide six VHDL sources\n"
        unless @portable_source == 6;

    my $adapter_text = _render_adapter();
    my $adapter = _artifact(
        "$BASE/src/fsmgen_vial_osvvm_adapter_pkg.vhd",
        'vhdl_osvvm_adapter_package',
        'vhdl_source',
        'vhdl',
        $adapter_text,
        [$provider->{manifest}{root_commit}, $portable->{plan_id}],
    );
    my @source_artifacts = (@portable_source, $adapter);

    my $semantic_preservation = {
        schema => 'fsmgen.vial_vhdl_osvvm_semantic_preservation.v1',
        schema_version => 1,
        portable_profile => 'vhdl_portable_ghdl',
        advanced_profile => $BACKEND_PROFILE,
        portable_plan_id => $portable->{plan_id},
        portable_sources => [sort { $a->{role} cmp $b->{role} } @preserved],
        guards => {
            portable_random_replay_unchanged => JSON::PP::true,
            phase_order_unchanged => JSON::PP::true,
            comparison_semantics_unchanged => JSON::PP::true,
            coverage_semantics_unchanged => JSON::PP::true,
            closed_trace_unchanged => JSON::PP::true,
            normalized_result_unchanged => JSON::PP::true,
        },
        provider_role =>
            'isolated negotiated native services and supplementary evidence only',
    };

    my $mapping_matrix = _mapping_matrix($adapter_text);
    my $source_map = _source_map(
        plan_id => $portable->{plan_id},
        source_artifacts => \@source_artifacts,
        mapping_matrix => $mapping_matrix,
    );
    my $static = FSM::VIAL::Backend::VHDLOSVVMStaticValidator->validate({
        artifacts => \@source_artifacts,
        materialization => $provider->{manifest},
        mapping_matrix => $mapping_matrix,
        semantic_preservation => $semantic_preservation,
    });
    return _failure('VIAL_OSVVM_STATIC_VALIDATION_ERROR',
        $static->{diagnostics}[0]{message}, '/static_validation')
        unless $static->{ok};

    my @source_order = (
        (map { $_->{relpath} } @portable_source),
        $adapter->{relpath},
    );
    my $source_order = {
        schema => 'fsmgen.vial_vhdl_osvvm_source_order.v1',
        schema_version => 1,
        provider_build_roots => [
            "$DEPENDENCY_ROOT/osvvm/osvvm.pro",
            "$DEPENDENCY_ROOT/Common/build.pro",
        ],
        generated_sources => \@source_order,
        order_digest => sha256_hex(join("\n", @source_order) . "\n"),
        status => 'selected_not_executed',
    };
    my $tool_profile = {
        schema => 'fsmgen.vial_backend_tool_profile.v1',
        schema_version => 1,
        profile => $BACKEND_PROFILE,
        language => 'VHDL',
        standard => 'IEEE 1076-2008',
        standard_option => '--std=08',
        provider => 'OSVVM',
        provider_version => '2026.05',
        provider_commit => $provider->{manifest}{root_commit},
        tool => 'GHDL',
        tool_version => '6.0.0',
        tool_backend => 'llvm_jit',
        tool_commit => 'e589c698c351369ac5bcfe7abe1f1152ac5d4727',
        materialization => 'complete_recursive_verified',
        combined_execution => 'not_run_separate_leaf_15_7',
    };

    my @support_artifacts = (
        _artifact("$BASE/backend-source-map.json", 'backend_source_map',
            'source_map', 'json', _json_text($source_map), [$portable->{plan_id}]),
        _artifact("$BASE/evidence/provider-materialization.json",
            'provider_materialization', 'provider_identity', 'json',
            _json_text($provider->{manifest}), [$provider->{manifest}{root_commit}]),
        _artifact("$BASE/evidence/advanced-mapping-matrix.json",
            'advanced_mapping_matrix', 'mapping_matrix', 'json',
            _json_text($mapping_matrix), [$portable->{plan_id}]),
        _artifact("$BASE/evidence/semantic-preservation.json",
            'semantic_preservation', 'semantic_preservation', 'json',
            _json_text($semantic_preservation), [$portable->{plan_id}]),
        _artifact("$BASE/evidence/source-order.json", 'source_order',
            'source_order', 'json', _json_text($source_order), [$portable->{plan_id}]),
        _artifact("$BASE/evidence/static-validation.json", 'static_validation',
            'static_validation', 'json', _json_text($static), [$portable->{plan_id}]),
        _artifact("$BASE/evidence/tool-profile.json", 'tool_profile',
            'tool_profile', 'json', _json_text($tool_profile),
            [$provider->{manifest}{root_commit}]),
    );

    my $operation_id = 'op-' . sha256_hex($JSON->encode({
        action => 'emit_osvvm_2026_05_adapter_gallery',
        artifact_root => $raw->{artifact_root},
        plan_id => $portable->{plan_id},
        provider_commit => $provider->{manifest}{root_commit},
        requirements => \@requirements,
    }));
    my @referenced = sort { $a->{relpath} cmp $b->{relpath} }
        map { _artifact_ref($_) } (@source_artifacts, @support_artifacts);
    my $manifest = {
        schema => $BACKEND_SCHEMA,
        schema_version => 1,
        backend_profile => $BACKEND_PROFILE,
        plan_id => $portable->{plan_id},
        fixture_id => $portable->{backend_manifest}{fixture_id},
        generated_top => $portable->{generated_top},
        emitter_revision => 1,
        execution_profile => $portable->{backend_manifest}{execution_profile},
        standard_profile => {
            language => 'VHDL',
            standard => 'IEEE 1076-2008',
            standard_option => '--std=08',
            methodology => 'OSVVM 2026.05',
        },
        provider_profile => $tool_profile,
        profile_state => {
            materialization => 'complete_recursive_verified',
            emission => 'emitted',
            static_review => 'passed_structural_only',
            visual_review => 'pending',
            qualification => 'not_run_separate_leaf_15_7',
        },
        negotiation => {
            required => \@requirements,
            satisfied => \@requirements,
            unsatisfied => [],
            semantic_authority => 'portable_vhdl_execution_and_result_oracles',
        },
        capability_evidence => {
            provider_materialization => 'passed_exact_recursive_identity',
            provider_licence_notice_inventory =>
                'passed_exact_inventory_with_documentation_absence_explicit',
            advanced_adapter_emission => 'passed',
            advanced_mapping_matrix => 'passed_seven_exact_mappings',
            portable_semantic_preservation => 'passed_six_byte_identical_sources',
            static_validation => 'passed_structural_only',
            source_map => 'passed_adapter_mapping_scope',
            analysis => 'not_run',
            elaboration => 'not_run',
            runtime => 'not_run',
            result => 'not_produced',
            parity => 'not_evaluated',
            product_support => 'not_claimed',
        },
        limitations => [
            'The exact Documentation submodule has no tracked licence or notice file; no coverage is inferred.',
            'Advanced provider services cannot rerandomize portable decisions, move phase barriers, redefine comparison or coverage meaning, alter the closed trace, or replace normalized results.',
            'Provider presence, adapter emission, and structural checks are not analysis, elaboration, execution, result, parity, or product-support evidence.',
        ],
        source_order => $source_order,
        source_map => {
            relpath => "$BASE/backend-source-map.json",
            schema => $source_map->{schema},
            entry_count => scalar(@{$source_map->{entries}}),
            sha256 => sha256_hex(_json_text($source_map)),
        },
        artifacts => \@referenced,
        result => {
            schema => 'fsmgen.verification_result_manifest.v1',
            status => 'not_produced',
            relpath => undef,
        },
        cleanup => {
            staging_identity => ".artifacts/tmp/vial/$operation_id",
            state => 'not_created',
        },
        diagnostics => [],
    };
    my $manifest_artifact = _artifact("$BASE/backend-manifest.json",
        'backend_manifest', 'backend_manifest', 'json', _json_text($manifest),
        [$portable->{plan_id}, $provider->{manifest}{root_commit}]);
    my @artifacts = sort { $a->{relpath} cmp $b->{relpath} }
        (@source_artifacts, @support_artifacts, $manifest_artifact);

    return {
        ok => JSON::PP::true,
        status => 'emitted_structurally_reviewed_unqualified',
        backend_profile => $BACKEND_PROFILE,
        plan_id => $portable->{plan_id},
        generated_top => $portable->{generated_top},
        operation_id => $operation_id,
        negotiation => $manifest->{negotiation},
        provider_materialization => $provider->{manifest},
        mapping_matrix => $mapping_matrix,
        semantic_preservation => $semantic_preservation,
        source_map => $source_map,
        static_validation => $static,
        backend_manifest => $manifest,
        artifacts => \@artifacts,
        diagnostics => [],
    };
}

sub _mapping_matrix($adapter_text) {
    my @definition = (
        ['advanced_coverage', 'osvvm.CoveragePkg', 'fsmgen_osvvm_coverage_sample',
            'supplementary_provider_coverage',
            'portable VIAL coverage counters and bin meaning remain authoritative'],
        ['advanced_data_structure', 'osvvm.MemoryPkg', 'fsmgen_osvvm_memory_write',
            'negotiated_provider_memory',
            'provider storage is available only for a distinct native requirement'],
        ['advanced_randomization', 'osvvm.RandomPkg', 'fsmgen_osvvm_native_random',
            'isolated_native_decision',
            'portable keyed decisions are replayed and never rerandomized'],
        ['advanced_reporting', 'osvvm.AlertLogPkg', 'fsmgen_osvvm_affirm',
            'supplementary_provider_reporting',
            'provider reports cannot replace the normalized result oracle'],
        ['advanced_scoreboard', 'osvvm.ScoreboardGenericPkg',
            'fsmgen_osvvm_scoreboard_check', 'supplementary_provider_scoreboard',
            'portable comparison meaning and bounded scoreboard remain authoritative'],
        ['advanced_synchronization', 'osvvm.TbUtilPkg',
            'fsmgen_osvvm_wait_for_barrier', 'provider_component_coordination',
            'provider synchronization cannot move the generated phase barrier'],
        ['verification_component_adapter',
            'osvvm_common.AddressBusTransactionPkg',
            'fsmgen_vial_osvvm_address_bus_t', 'negotiated_mit_adapter',
            'component completion projects into unchanged generated plan ranks'],
    );
    my @mappings;
    for my $definition (@definition) {
        my ($mapping_id, $provider_package, $symbol, $mode, $guard) = @$definition;
        my ($start, $end) = _line_span($adapter_text, $symbol);
        push @mappings, {
            mapping_id => $mapping_id,
            provider_package => $provider_package,
            provider_symbol => $symbol,
            mode => $mode,
            generated_role => 'vhdl_osvvm_adapter_package',
            source_map_id => "osvvm-map-$mapping_id",
            generated_start_line => $start,
            generated_end_line => $end,
            emission_status => 'emitted',
            static_status => 'passed',
            qualification_status => 'not_run',
            semantic_guard => $guard,
        };
    }
    return {
        schema => 'fsmgen.vial_vhdl_osvvm_mapping_matrix.v1',
        schema_version => 1,
        profile => $BACKEND_PROFILE,
        provider => 'OSVVM 2026.05',
        mappings => \@mappings,
        profile_state => {
            emission => 'emitted',
            static_review => 'passed_structural_only',
            qualification => 'not_run',
        },
    };
}

sub _source_map(%args) {
    my ($adapter) = grep { $_->{role} eq 'vhdl_osvvm_adapter_package' }
        @{$args{source_artifacts}};
    my @entries = map {
        +{
            source_map_id => $_->{source_map_id},
            generated_relpath => $adapter->{relpath},
            generated_start_line => $_->{generated_start_line},
            generated_end_line => $_->{generated_end_line},
            generated_symbol => $_->{provider_symbol},
            role => $_->{generated_role},
            plan_paths => ['/advanced_requirements/' . $_->{mapping_id}],
            semantic_paths => ['/provider_mappings/' . $_->{mapping_id}],
            source_locations => [
                'docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md',
            ],
        }
    } @{$args{mapping_matrix}{mappings}};
    for my $artifact (sort { $a->{role} cmp $b->{role} }
        grep { $_->{role} =~ /\Aportable_/ } @{$args{source_artifacts}}) {
        push @entries, {
            source_map_id => 'portable-' . $artifact->{sha256},
            generated_relpath => $artifact->{relpath},
            generated_start_line => 1,
            generated_end_line => scalar(() = $artifact->{content} =~ /\n/g),
            generated_symbol => $artifact->{role},
            role => $artifact->{role},
            plan_paths => ['/portable_foundation'],
            semantic_paths => ['/semantic_preservation/portable_sources'],
            source_locations => [
                'FSM::VIAL::Backend::VHDLPortableGHDL',
            ],
        };
    }
    return {
        schema => 'fsmgen.vial_vhdl_osvvm_source_map.v1',
        schema_version => 1,
        plan_id => $args{plan_id},
        artifacts => [map { _artifact_ref($_) }
            sort { $a->{relpath} cmp $b->{relpath} } @{$args{source_artifacts}}],
        entries => \@entries,
    };
}

sub _render_adapter() {
    return <<'VHDL';
-- Generated by FSM::VIAL::Backend::VHDLOSVVM2026_05 revision 1.
-- OSVVM services are isolated native/supplementary mappings. Portable VIAL
-- scheduling, replay, comparison, coverage, trace, and result meaning remain
-- authoritative and are byte-identical to vhdl_portable_ghdl.
library ieee;
use ieee.std_logic_1164.all;

library osvvm;
context osvvm.OsvvmContext;

library osvvm_common;

package fsmgen_vial_osvvm_adapter_pkg is
  constant FSMGEN_VIAL_OSVVM_VERSION : string := "2026.05";
  constant FSMGEN_VIAL_OSVVM_SCOREBOARD_BASIS : string :=
    "osvvm.ScoreboardGenericPkg via osvvm.ScoreboardPkg_slv";

  subtype fsmgen_vial_osvvm_scoreboard_id_t is
    osvvm.ScoreboardPkg_slv.ScoreboardIDType;
  subtype fsmgen_vial_osvvm_coverage_id_t is
    osvvm.CoveragePkg.CoverageIDType;
  subtype fsmgen_vial_osvvm_barrier_t is
    osvvm.TbUtilPkg.BarrierType;
  subtype fsmgen_vial_osvvm_memory_id_t is
    osvvm.MemoryPkg.MemoryIDType;
  subtype fsmgen_vial_osvvm_address_bus_t is
    osvvm_common.AddressBusTransactionPkg.AddressBusRecType;

  procedure fsmgen_osvvm_native_random(
    variable generator : inout osvvm.RandomPkg.RandomPType;
    constant minimum : in integer;
    constant maximum : in integer;
    variable value : out integer
  );

  procedure fsmgen_osvvm_coverage_sample(
    constant coverage_id : in fsmgen_vial_osvvm_coverage_id_t;
    constant point : in integer
  );

  procedure fsmgen_osvvm_scoreboard_expect(
    constant scoreboard_id : in fsmgen_vial_osvvm_scoreboard_id_t;
    constant expected : in std_logic_vector
  );

  procedure fsmgen_osvvm_scoreboard_check(
    constant scoreboard_id : in fsmgen_vial_osvvm_scoreboard_id_t;
    constant actual : in std_logic_vector
  );

  procedure fsmgen_osvvm_affirm(
    constant condition : in boolean;
    constant message : in string
  );

  procedure fsmgen_osvvm_wait_for_barrier(
    signal barrier : inout fsmgen_vial_osvvm_barrier_t
  );

  impure function fsmgen_osvvm_new_memory(
    constant name : in string;
    constant address_width : in positive;
    constant data_width : in positive
  ) return fsmgen_vial_osvvm_memory_id_t;

  procedure fsmgen_osvvm_memory_write(
    constant memory_id : in fsmgen_vial_osvvm_memory_id_t;
    constant address_value : in std_logic_vector;
    constant data_value : in std_logic_vector
  );
end package;

package body fsmgen_vial_osvvm_adapter_pkg is
  procedure fsmgen_osvvm_native_random(
    variable generator : inout osvvm.RandomPkg.RandomPType;
    constant minimum : in integer;
    constant maximum : in integer;
    variable value : out integer
  ) is
  begin
    value := generator.Uniform(minimum, maximum);
  end procedure;

  procedure fsmgen_osvvm_coverage_sample(
    constant coverage_id : in fsmgen_vial_osvvm_coverage_id_t;
    constant point : in integer
  ) is
  begin
    osvvm.CoveragePkg.ICover(coverage_id, point);
  end procedure;

  procedure fsmgen_osvvm_scoreboard_expect(
    constant scoreboard_id : in fsmgen_vial_osvvm_scoreboard_id_t;
    constant expected : in std_logic_vector
  ) is
  begin
    osvvm.ScoreboardPkg_slv.Push(scoreboard_id, expected);
  end procedure;

  procedure fsmgen_osvvm_scoreboard_check(
    constant scoreboard_id : in fsmgen_vial_osvvm_scoreboard_id_t;
    constant actual : in std_logic_vector
  ) is
  begin
    osvvm.ScoreboardPkg_slv.Check(scoreboard_id, actual);
  end procedure;

  procedure fsmgen_osvvm_affirm(
    constant condition : in boolean;
    constant message : in string
  ) is
  begin
    osvvm.AlertLogPkg.AffirmIf(condition, message);
  end procedure;

  procedure fsmgen_osvvm_wait_for_barrier(
    signal barrier : inout fsmgen_vial_osvvm_barrier_t
  ) is
  begin
    osvvm.TbUtilPkg.WaitForBarrier(barrier);
  end procedure;

  impure function fsmgen_osvvm_new_memory(
    constant name : in string;
    constant address_width : in positive;
    constant data_width : in positive
  ) return fsmgen_vial_osvvm_memory_id_t is
  begin
    return osvvm.MemoryPkg.NewID(name, address_width, data_width);
  end function;

  procedure fsmgen_osvvm_memory_write(
    constant memory_id : in fsmgen_vial_osvvm_memory_id_t;
    constant address_value : in std_logic_vector;
    constant data_value : in std_logic_vector
  ) is
  begin
    osvvm.MemoryPkg.MemWrite(memory_id, address_value, data_value);
  end procedure;
end package body;
VHDL
}

sub _line_span($text, $symbol) {
    my $offset = index($text, $symbol);
    confess "generated adapter lacks mapped symbol '$symbol'\n" if $offset < 0;
    my $prefix = substr($text, 0, $offset);
    my $line = 1 + (() = $prefix =~ /\n/g);
    return ($line, $line);
}

sub _artifact($relpath, $role, $kind, $language, $content, $source_ids) {
    return {
        relpath => $relpath,
        role => $role,
        kind => $kind,
        language => $language,
        content => $content,
        byte_length => bytes::length($content),
        sha256 => sha256_hex($content),
        source_ids => [@$source_ids],
    };
}

sub _artifact_ref($artifact) {
    return {
        relpath => $artifact->{relpath},
        role => $artifact->{role},
        kind => $artifact->{kind},
        language => $artifact->{language},
        byte_length => $artifact->{byte_length},
        sha256 => $artifact->{sha256},
        source_ids => [@{$artifact->{source_ids}}],
    };
}

sub _json_text($value) {
    return $PRETTY_JSON->encode($value);
}

sub _require_keys($value, $expected) {
    confess "backend invocation key set is not closed\n"
        unless join("\0", sort keys %$value) eq join("\0", sort @$expected);
}

sub _failure($code, $message, $path) {
    return {
        ok => JSON::PP::false,
        status => 'failed',
        backend_profile => $BACKEND_PROFILE,
        plan_id => undef,
        generated_top => undef,
        operation_id => undef,
        negotiation => undef,
        provider_materialization => undef,
        mapping_matrix => undef,
        semantic_preservation => undef,
        source_map => undef,
        static_validation => undef,
        backend_manifest => undef,
        artifacts => [],
        diagnostics => [{code => $code, message => $message, path => $path}],
    };
}

sub _exact_class($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

1;
