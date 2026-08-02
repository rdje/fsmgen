#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Path qw(remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::VIAL::ArtifactTransaction;
use FSM::VIAL::Backend::VHDLPortableGHDL;
use FSM::VIAL::Backend::VHDLPortableStaticValidator;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $json = JSON::PP->new->canonical(1);
my $profile = 'vhdl_portable_ghdl';
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $artifact_root = '.artifacts/test/vial-vhdl-foundation-publication';
my $built = build_plan();

ok($built->{ok}, 'checked VIAL/HIAL fixture reaches portable VHDL backend inputs');
diag($json->encode($built->{diagnostics})) unless $built->{ok};

subtest 'private HIAL handoff carries deterministic VHDL DUT identity and bytes' => sub {
    is_deeply([sort keys %{$built->{backend_inputs}}],
        [qw(dut_systemverilog dut_vhdl)], 'private handoff is closed over both HDL families');
    is(scalar(@{$built->{backend_inputs}{dut_vhdl}}), 1,
        'one bound HIAL unit supplies one VHDL source');
    my $dut = $built->{backend_inputs}{dut_vhdl}[0];
    is_deeply([sort keys %$dut], [sort qw(
        unit_id entity_name artifact_name source_id text content_sha256 byte_length
    )], 'VHDL DUT record is closed');
    is($dut->{unit_id}, 'unit/ahb_lite_subordinate', 'DUT semantic unit is exact');
    is($dut->{entity_name}, 'ahb_lite_subordinate', 'DUT entity identity is exact');
    is($dut->{artifact_name}, 'ahb_lite_subordinate.vhd', 'DUT filename is deterministic');
    is($dut->{content_sha256}, sha256_hex($dut->{text}), 'DUT digest covers exact bytes');
    is($dut->{byte_length}, bytes::length($dut->{text}), 'DUT byte count covers exact bytes');
    like($dut->{text}, qr/entity ahb_lite_subordinate is/, 'DUT source declares the bound entity');
};

subtest 'emitter produces a deterministic closed unqualified VHDL foundation graph' => sub {
    my $first = emit_backend();
    ok($first->{ok}, 'portable VHDL foundation emission succeeds');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is_deeply([sort keys %$first],
        [sort @{FSM::VIAL::Backend::VHDLPortableGHDL->result_keys}],
        'backend result shell is closed');
    is($first->{status}, 'emitted_unqualified_foundation',
        'status cannot imply analysis, elaboration, or runtime');
    is($first->{backend_profile}, $profile, 'backend profile is exact');
    like($first->{operation_id}, qr/\Aop-[0-9a-f]{64}\z/,
        'operation identity is deterministic and safe');
    is(scalar(@{$first->{artifacts}}), 13, 'foundation graph has exactly thirteen artifacts');
    is_deeply([map { $_->{relpath} } @{$first->{artifacts}}],
        [sort map { $_->{relpath} } @{$first->{artifacts}}],
        'artifact graph is repository-relative and sorted');
    is_deeply([sort keys %{$first->{backend_manifest}}],
        [sort @{FSM::VIAL::Backend::VHDLPortableGHDL->manifest_keys}],
        'backend manifest is closed');
    is_deeply([sort keys %{$first->{source_map}}],
        [sort @{FSM::VIAL::Backend::VHDLPortableGHDL->source_map_keys}],
        'source map is closed');
    is(scalar(@{$first->{source_map}{entries}}), 5,
        'every emitted VHDL source has one foundation-scope source-map entry');
    my %mapped = map { $_->{generated_relpath} => 1 } @{$first->{source_map}{entries}};
    for my $artifact (grep { $_->{language} eq 'vhdl' } @{$first->{artifacts}}) {
        ok($mapped{$artifact->{relpath}}, "'$artifact->{relpath}' is source-mapped");
    }
    for my $entry (@{$first->{source_map}{entries}}) {
        is_deeply([sort keys %$entry],
            [sort @{FSM::VIAL::Backend::VHDLPortableGHDL->source_map_entry_keys}],
            "source-map entry '$entry->{generated_symbol}' is closed");
    }
    my $second = emit_backend();
    is_deeply($second, $first, 'identical input reproduces the byte-identical result');
    $first->{artifacts}[0]{content} = 'mutated';
    isnt($second->{artifacts}[0]{content}, 'mutated', 'emission results are defensive');
};

subtest 'foundation source is provider-free, typed, bound, and deliberately incomplete' => sub {
    my $emission = emit_backend();
    my $types = artifact_by_role($emission, 'vhdl_types_package')->{content};
    like($types, qr/type vial_value_symbol_t is/, 'typed four-state value symbols are emitted');
    like($types, qr/type vial_phase_t is/, 'logical execution phases are typed');
    like($types, qr/original_symbol : std_logic;/,
        'observation foundation preserves the original std_logic symbol');
    like($types, qr/when 'Z' => return VIAL_VALUE_Z;/, 'high-impedance remains distinct');
    like($types, qr/when others => return VIAL_VALUE_X;/,
        'remaining std_logic meta-values normalize to X');
    my $runtime = artifact_by_role($emission, 'vhdl_runtime_package')->{content};
    like($runtime, qr/type vial_logical_time_t is record/,
        'runtime package owns typed logical time');
    my $metadata = artifact_by_role($emission, 'vhdl_fixture_metadata')->{content};
    like($metadata, qr/VIAL_INACTIVE_EDGE : string := "falling";/,
        'metadata freezes the selected inactive edge without implementing the scheduler');
    my $top = artifact_by_role($emission, 'vhdl_fixture_top')->{content};
    like($top, qr/dut : entity work\.ahb_lite_subordinate\(rtl\)/,
        'testbench foundation binds the HIAL VHDL entity directly');
    like($top, qr/HADDR => HADDR/, 'testbench uses named bridge-proved port bindings');
    unlike($top, qr/\bprocess\b/i, 'foundation invents no driver or scheduler process');
    my $vhdl = join('', map { $_->{content} }
        grep { $_->{language} eq 'vhdl' } @{$emission->{artifacts}});
    unlike($vhdl, qr/\b(?:ghdl|osvvm|uvvm|xcelium|nvc|modelsim|questa)\b/i,
        'canonical VHDL has no simulator or methodology-provider branch');
    unlike($vhdl, qr/\bpsl\b/i, 'foundation emits no PSL');
    unlike($vhdl, qr/vhdl-observation-package|observation_vhdl_pkg/i,
        'native VIAL foundation neither consumes nor rewrites the inert legacy package');
};

subtest 'standard, tool, commands, and capability states are exact and honest' => sub {
    my $emission = emit_backend();
    my $manifest = $emission->{backend_manifest};
    is($manifest->{standard_profile}{standard}, 'IEEE 1076-2008',
        'language standard is exact');
    is($manifest->{tool_profile}{tool_name}, 'ghdl', 'selected tool is exact');
    is($manifest->{tool_profile}{qualified_version}, '6.0.0',
        'selected qualification version is exact');
    is($manifest->{tool_profile}{selection_status}, 'selected_not_executed',
        'tool selection is explicitly unexecuted');
    is($manifest->{tool_profile}{provider_library}, 'none',
        'foundation has no methodology provider');
    ok(!$manifest->{tool_profile}{execution_evidence}, 'tool profile carries no execution evidence');
    my $evidence = $manifest->{capability_evidence};
    is($evidence->{emission}, 'passed_foundation_only', 'only foundation emission passes');
    is($evidence->{static_validation}, 'passed_structural_only',
        'static evidence remains structural');
    is($evidence->{provider_fetch}, 'not_performed', 'ordinary emission fetches no provider');
    is($evidence->{analysis}, 'not_run', 'analysis is not run');
    is($evidence->{elaboration}, 'not_run', 'elaboration is not run');
    is($evidence->{runtime}, 'not_run', 'runtime is not run');
    is($evidence->{result}, 'not_produced', 'result is not produced');
    is($evidence->{parity}, 'not_evaluated', 'parity is not evaluated');
    is($evidence->{psl}, 'not_emitted', 'PSL is not emitted');
    is($evidence->{full_vhdl_2008}, 'not_claimed', 'full VHDL-2008 is not claimed');
    is($evidence->{product_support}, 'not_claimed', 'product support is not claimed');
    is_deeply($manifest->{migration}, {
        legacy_surface => 'vhdl_observation_package_skeleton',
        legacy_state => 'unchanged_not_consumed',
        successor_profile => 'vhdl_portable_ghdl',
        migration_kind => 'parallel_versioned_surface',
    }, 'manifest records the exact parallel migration without consuming the legacy package');
    is_deeply($manifest->{source_order}{sources}, [
        'backends/vhdl_portable_ghdl/src/fsmgen_vial_types_pkg.vhd',
        'backends/vhdl_portable_ghdl/src/fsmgen_vial_runtime_pkg.vhd',
        'backends/vhdl_portable_ghdl/src/base_output_arbitration_metadata_pkg.vhd',
        'backends/vhdl_portable_ghdl/src/dut/ahb_lite_subordinate.vhd',
        'backends/vhdl_portable_ghdl/src/base_output_arbitration_tb.vhd',
    ], 'analysis source order is explicit and deterministic');
    for my $role (qw(analyze_command elaborate_command run_command)) {
        my $command = JSON::PP->new->decode(artifact_by_role($emission, $role)->{content});
        is($command->{logical_executable}, 'ghdl', "$role records the selected logical executable");
        is($command->{execution_status}, 'not_run', "$role remains unexecuted evidence");
        ok(scalar(grep { $_ eq '--std=08' } @{$command->{arguments}}),
            "$role fixes the VHDL-2008 option");
        ok(scalar(grep { $_ eq '--work=fsmgen_vial' } @{$command->{arguments}}),
            "$role fixes the work library");
        unlike($json->encode($command), qr{"(?:working_directory|inputs|expected_outputs)":"/},
            "$role contains no absolute project path");
    }
};

subtest 'static validation and negotiation fail closed on malformed inputs' => sub {
    my $emission = emit_backend();
    my $static = $emission->{static_validation};
    ok($static->{ok}, 'selected foundation passes structural validation');
    is_deeply([sort keys %$static],
        [sort @{FSM::VIAL::Backend::VHDLPortableStaticValidator->result_keys}],
        'static result is closed');
    ok(!(grep { $_->{status} ne 'passed' } @{$static->{checks}}),
        'every selected structural check passes');

    my @source = map { clone($_) }
        grep { $_->{language} eq 'vhdl' } @{$emission->{artifacts}};
    my @missing = grep { $_->{role} ne 'vhdl_runtime_package' } @source;
    static_failure(\@missing, 'VIAL_VHDL_STATIC_REQUIRED_ROLE_ERROR',
        'missing required VHDL role');
    my @provider = map { clone($_) } @source;
    artifact_in(\@provider, 'vhdl_fixture_top')->{content} .= "-- ghdl-only workaround\n";
    static_failure(\@provider, 'VIAL_VHDL_STATIC_PROVIDER_LEAK',
        'provider-specific source leakage');
    my @placeholder = map { clone($_) } @source;
    artifact_in(\@placeholder, 'vhdl_runtime_package')->{content} .= "-- __FSMGEN_BAD__\n";
    static_failure(\@placeholder, 'VIAL_VHDL_STATIC_TEXT_SHAPE_ERROR',
        'unresolved generation placeholder');

    backend_failure(emit_backend(backend_profile => 'vhdl_other'),
        'VIAL_VHDL_BACKEND_UNSUPPORTED', 'substituted backend profile');
    backend_failure(emit_backend(artifact_root => '../outside'),
        'VIAL_VHDL_BACKEND_INVOCATION_ERROR', 'unsafe artifact root');
    my $missing_vhdl = clone($built->{backend_inputs});
    $missing_vhdl->{dut_vhdl} = [];
    backend_failure(emit_backend(backend_inputs => $missing_vhdl),
        'VIAL_VHDL_BACKEND_UNSUPPORTED', 'missing VHDL DUT');
    my $bad_hash = clone($built->{backend_inputs});
    $bad_hash->{dut_vhdl}[0]{text} .= "\n";
    backend_failure(emit_backend(backend_inputs => $bad_hash),
        'VIAL_VHDL_BACKEND_UNSUPPORTED', 'VHDL DUT digest mismatch');
};

subtest 'artifact publication is atomic, collision-safe, and exactly cleaned' => sub {
    cleanup_artifact_root();
    my $emission = emit_backend();
    my $first = FSM::VIAL::ArtifactTransaction->publish({
        repo_root => repo_path(),
        artifact_root => $artifact_root,
        operation_id => $emission->{operation_id},
        artifacts => $emission->{artifacts},
    });
    ok($first->{ok}, 'first publication succeeds');
    is($first->{status}, 'planned', 'first publication atomically creates the declared tree');
    ok(-d repo_path(split m{/}, $artifact_root), 'published tree exists under the repository');
    my $identical = FSM::VIAL::ArtifactTransaction->publish({
        repo_root => repo_path(),
        artifact_root => $artifact_root,
        operation_id => $emission->{operation_id},
        artifacts => $emission->{artifacts},
    });
    ok($identical->{ok}, 'identical republication succeeds');
    is($identical->{status}, 'unchanged', 'identical tree is not rewritten');
    my @mutated = map { clone($_) } @{$emission->{artifacts}};
    $mutated[0]{content} .= "\n";
    my $collision = FSM::VIAL::ArtifactTransaction->publish({
        repo_root => repo_path(),
        artifact_root => $artifact_root,
        operation_id => $emission->{operation_id},
        artifacts => \@mutated,
    });
    ok(!$collision->{ok}, 'byte-different republication fails');
    is($collision->{diagnostics}[0]{code}, 'VIAL_ARTIFACT_COLLISION',
        'collision has the exact artifact-transaction diagnostic');
    cleanup_artifact_root();
    ok(!-e repo_path(split m{/}, $artifact_root), 'published test tree is removed exactly');
    ok(!-e repo_path('.artifacts', 'tmp', 'vial', $emission->{operation_id}),
        'no operation staging residue remains');
};

subtest 'checked gallery and support discovery remain byte-exact and honest' => sub {
    my $emission = emit_backend(
        artifact_root => '.artifacts/gallery/vial-vhdl-foundation',
    );
    my $gallery = repo_path(qw(vial review_gallery vhdl_portable_ghdl ahb_base_output_foundation));
    for my $artifact (@{$emission->{artifacts}}) {
        (my $relative = $artifact->{relpath}) =~ s{\Abackends/vhdl_portable_ghdl/}{};
        is(slurp_raw(File::Spec->catfile($gallery, split m{/}, $relative)),
            $artifact->{content}, "gallery snapshot '$relative' matches exact emitted bytes");
    }
    my $readme = slurp_raw(File::Spec->catfile($gallery, 'README.md'));
    like($readme, qr/plan\/038c968edbd7782d36f49af5092dd4301ca95989914eeba73250f9b609525574/,
        'gallery names its exact deterministic plan');
    like($readme, qr/have not been analyzed, elaborated, or run/,
        'gallery prominently preserves execution non-claims');

    my $contract = build_capability_manifest()->{language_surface}{vial_vhdl_emission};
    is($contract->{profile}, $profile, 'capability manifest discovers the exact private profile');
    is($contract->{backend_stage_status}{emission}, 'shipped_foundation_only',
        'support state advertises only the shipped foundation');
    is($contract->{backend_stage_status}{analysis}, 'not_run',
        'support state does not infer VHDL analysis');
    ok(!$contract->{public_embedding_api}, 'private emitter is not promoted to public embedding API');
};

cleanup_artifact_root();
done_testing();

sub build_plan {
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => slurp_raw(repo_path(split m{/}, $vial_id)),
        source_name => $vial_id,
        source_catalog => {},
    });
    return FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_id,
            text => slurp_raw(repo_path(split m{/}, $hial_id)),
            format => 'ppif',
        },
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
}

sub emit_backend {
    my (%override) = @_;
    return FSM::VIAL::Backend::VHDLPortableGHDL->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => '.artifacts/test/vial-vhdl-foundation-emission',
        backend_profile => $profile,
        %override,
    });
}

sub static_failure {
    my ($artifacts, $code, $label) = @_;
    my $result = FSM::VIAL::Backend::VHDLPortableStaticValidator->validate({
        backend_profile => $profile,
        artifacts => $artifacts,
    });
    ok(!$result->{ok}, "$label fails static validation");
    ok(scalar(grep { $_->{code} eq $code } @{$result->{diagnostics}}),
        "$label has diagnostic $code");
}

sub backend_failure {
    my ($result, $code, $label) = @_;
    ok(!$result->{ok}, "$label fails backend emission");
    is($result->{diagnostics}[0]{code}, $code, "$label has diagnostic $code");
    is_deeply($result->{artifacts}, [], "$label emits no artifact");
}

sub artifact_by_role {
    my ($emission, $role) = @_;
    my @found = grep { $_->{role} eq $role } @{$emission->{artifacts}};
    die "artifact role '$role' does not occur exactly once\n" unless @found == 1;
    return $found[0];
}

sub artifact_in {
    my ($artifacts, $role) = @_;
    my @found = grep { $_->{role} eq $role } @$artifacts;
    die "artifact role '$role' does not occur exactly once\n" unless @found == 1;
    return $found[0];
}

sub cleanup_artifact_root {
    my $path = repo_path(split m{/}, $artifact_root);
    return unless -e $path;
    my $errors;
    remove_tree($path, {error => \$errors});
    die "cannot remove exact test artifact root '$artifact_root'\n"
        if ref($errors) eq 'ARRAY' && @$errors;
}

sub clone {
    my ($value) = @_;
    return JSON::PP->new->decode($json->encode($value));
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub repo_path {
    return File::Spec->catfile($FindBin::Bin, '..', @_);
}
