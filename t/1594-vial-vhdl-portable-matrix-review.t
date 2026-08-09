#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Path qw(remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::VHDLPortableGHDL;
use FSM::VIAL::Backend::VHDLPortableReviewClosure;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $json = JSON::PP->new->canonical(1);
my $pretty_json = JSON::PP->new->canonical(1)->pretty(1);
my $profile = 'vhdl_portable_ghdl';
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $gallery_rel = join '/', qw(
    vial review_gallery vhdl_portable_ghdl ahb_base_output_portable_semantics
);
my $legacy_root_rel = '.artifacts/test/vial-vhdl-portable-migration-proof';
my $legacy_root = repo_path(split m{/}, $legacy_root_rel);
END { remove_tree($legacy_root) if defined($legacy_root) && -e $legacy_root }

my $built = build_plan();
ok($built->{ok}, 'checked VIAL/HIAL fixture reaches portable VHDL review inputs');
diag($json->encode($built->{diagnostics})) unless $built->{ok};
my $emission = emit_backend();
ok($emission->{ok}, 'selected portable VHDL matrix/review emission succeeds');
diag($json->encode($emission->{diagnostics})) unless $emission->{ok};

subtest 'selected mapping matrix is closed over emitted and rejected boundaries' => sub {
    my $matrix = $emission->{mapping_matrix};
    is($matrix->{schema}, 'fsmgen.vial_vhdl_selected_mapping_matrix.v1',
        'mapping schema is exact');
    is($matrix->{scope},
        'complete_selected_provider_free_vhdl_matrix_with_exact_rejected_boundaries',
        'matrix closes the selected provider-free profile rather than all VHDL');
    is(scalar(@{$matrix->{mappings}}), 24,
        'matrix contains twenty-four exact portable responsibilities and boundaries');
    is(scalar(@{$matrix->{emitted_foundations}}), 20,
        'twenty selected responsibilities have emitted representatives');
    is(scalar(@{$matrix->{unsupported_foundations}}), 4,
        'four excluded boundaries carry exact unsupported reasons');

    my @mapping_id = map { $_->{mapping_id} } @{$matrix->{mappings}};
    is_deeply(\@mapping_id, [sort @mapping_id], 'mapping identities are sorted');
    is(scalar(keys %{ {map { $_ => 1 } @mapping_id} }), scalar(@mapping_id),
        'mapping identities are unique');
    for my $mapping (@{$matrix->{mappings}}) {
        is_deeply(
            [sort keys %$mapping],
            [sort @{FSM::VIAL::Backend::VHDLPortableReviewClosure->mapping_keys}],
            "mapping '$mapping->{mapping_id}' is closed",
        );
        if ($mapping->{emission_status} eq 'emitted') {
            ok(@{$mapping->{generated_roles}} >= 1,
                "mapping '$mapping->{mapping_id}' names emitted role evidence");
            is($mapping->{static_review_status}, 'passed_structural_only',
                "mapping '$mapping->{mapping_id}' labels structural review honestly");
            is($mapping->{visual_review_status}, 'pending',
                "mapping '$mapping->{mapping_id}' leaves visual review pending");
            is($mapping->{qualification_status}, 'not_run',
                "mapping '$mapping->{mapping_id}' leaves qualification not run");
            ok(!defined($mapping->{unsupported_reason}),
                "mapping '$mapping->{mapping_id}' has no false unsupported reason");
        }
        else {
            is_deeply($mapping->{generated_roles}, [],
                "unsupported mapping '$mapping->{mapping_id}' claims no artifact");
            ok(defined($mapping->{unsupported_reason})
                    && length($mapping->{unsupported_reason}),
                "unsupported mapping '$mapping->{mapping_id}' gives one exact reason");
        }
    }

    is_deeply($matrix->{profile_state}, {
        emission => 'emitted',
        static_review => 'reviewed_structurally',
        visual_review => 'pending',
        qualification => 'unqualified_not_run',
    }, 'profile state says emitted, structurally reviewed, and unqualified');
};

subtest 'public, compiler-owned, bridge-owned, and private-preview entries are distinct' => sub {
    my %mapping = map { $_->{foundation_id} => $_ }
        @{$emission->{mapping_matrix}{mappings}};
    is($mapping{typed_drivers}{normal_source}, 'public_vial_v1',
        'typed drivers have a normal public VIAL entry point');
    is($mapping{typed_drivers}{terse_source}, 'public_vial_v1',
        'typed drivers have a terse public VIAL entry point');
    is($mapping{typed_drivers}{typed_ir}, 'public_execution_ir',
        'typed drivers enter through public ExecutionIR intent');

    is($mapping{inactive_edge_scheduler}{normal_source},
        'not_applicable_compiler_owned',
        'scheduler plumbing is compiler-owned rather than invented public syntax');
    is($mapping{inactive_edge_scheduler}{typed_ir}, 'compiler_owned_execution_ir',
        'scheduler plumbing comes from compiler-owned ExecutionIR structure');
    is($mapping{declared_probe_adapter}{typed_ir}, 'compiler_owned_bridge_manifest',
        'probe adapter ownership stays in the HIAL/VIAL bridge');

    is($mapping{osvvm_native_services}{normal_source},
        'not_available_private_preview',
        'provider-native authoring is explicitly unavailable in the public profile');
    is($mapping{osvvm_native_services}{typed_ir},
        'private_typed_preview_not_selected',
        'provider-native typed preview is explicitly not selected');
    like($mapping{osvvm_native_services}{unsupported_reason},
        qr/separately owned profile vhdl_osvvm_qualified/,
        'provider-native boundary names its exact separate owner');
    like($mapping{psl_properties}{unsupported_reason},
        qr/lower procedurally; PSL syntax and tool flags are not selected/,
        'PSL boundary gives the exact procedural-lowering reason');
};

subtest 'review workflow is deterministic, durable, and qualification-honest' => sub {
    my $workflow = $emission->{review_workflow};
    is($workflow->{schema}, 'fsmgen.vial_vhdl_review_workflow.v1',
        'review-workflow schema is exact');
    is($workflow->{gallery_root}, $gallery_rel, 'gallery root is repository-relative');
    is($workflow->{regenerate_command},
        'perl scripts/refresh_vial_vhdl_portable_gallery.pl',
        'regeneration command is repository-relative and exact');
    is($workflow->{check_command},
        'perl scripts/refresh_vial_vhdl_portable_gallery.pl --check',
        'non-mutating check command is repository-relative and exact');
    is(scalar(@{$workflow->{examples}}), 6,
        'workflow exposes all six VHDL source examples');
    is(scalar(@{$workflow->{evidence_examples}}), 3,
        'workflow exposes all three canonical closure evidence files');

    my %stage = map { $_->{stage_id} => $_ } @{$workflow->{stages}};
    is_deeply([sort keys %stage], [sort qw(
        regenerate byte_compare static_shape visual_review defect_capture
        migration_separation qualified_runtime
    )], 'review stages are exact');
    for my $stage (values %stage) {
        is_deeply(
            [sort keys %$stage],
            [sort @{FSM::VIAL::Backend::VHDLPortableReviewClosure->stage_keys}],
            "review stage '$stage->{stage_id}' is closed",
        );
    }
    is($stage{static_shape}{status}, 'passed_structural_only',
        'structural evidence remains narrower than analyzer evidence');
    is($stage{visual_review}{status}, 'pending', 'visual judgment remains pending');
    is($stage{migration_separation}{status}, 'passed_regression_contract',
        'legacy and HIAL separation have an exact regression contract');
    is($stage{qualified_runtime}{status}, 'not_run',
        'runtime qualification remains task-separated and not run');
    ok(!$workflow->{defect_routing}{conversation_only_is_durable},
        'review defects must be routed to the durable task-tree');
    is_deeply($workflow->{defect_routing}{required_fields}, [qw(
        artifact_relpath generated_symbol source_map_id observation severity
        reproduction expected_intent disposition
    )], 'defect leaves require the exact durable evidence fields');

    my %nonclaim = map { $_ => 1 } @{$workflow->{nonclaims}};
    ok($nonclaim{visual_review_complete}, 'visual completion is explicitly unclaimed');
    ok($nonclaim{vhdl_analysis}, 'VHDL analysis is explicitly unclaimed');
    ok($nonclaim{runtime}, 'runtime is explicitly unclaimed');
    ok($nonclaim{produced_result}, 'result production is explicitly unclaimed');
    ok($nonclaim{parity}, 'parity is explicitly unclaimed');
    ok($nonclaim{product_support}, 'product support is explicitly unclaimed');
};

subtest 'legacy bytes/schema and HIAL successor separation are exact' => sub {
    remove_tree($legacy_root) if -e $legacy_root;
    my @command = (
        repo_path('bin', 'fsmgen'), '--quiet',
        '--emit-verification-output', 'vhdl-observation-package',
        '--verification-outdir', $legacy_root_rel,
        'isf/verification_observation_metadata.isf',
    );
    is(system(@command), 0, 'legacy compatibility fixture emits successfully');
    my $package_rel = join '/', qw(
        vhdl verification_observation_metadata_observation_vhdl_pkg.vhd
    );
    my $package = slurp_raw(File::Spec->catfile($legacy_root, split m{/}, $package_rel));
    my $manifest = JSON::PP->new->decode(
        slurp_raw(File::Spec->catfile($legacy_root, 'verification-output-manifest.json')),
    );
    my $proof = $emission->{migration_proof};
    is($proof->{schema}, 'fsmgen.vial_vhdl_migration_proof.v1',
        'migration-proof schema is exact');
    is($proof->{legacy_surface}{package_relpath}, $package_rel,
        'proof names the exact inert legacy package');
    is(length($package), $proof->{legacy_surface}{package_bytes},
        'legacy package byte length remains exact');
    is(sha256_hex($package), $proof->{legacy_surface}{package_sha256},
        'legacy package bytes remain exactly locked');
    delete $manifest->{source}{resolved_path};
    is(sha256_hex($json->encode($manifest)),
        $proof->{legacy_surface}{manifest_projection_sha256},
        'legacy manifest schema/content projection remains exactly locked');
    ok(!$proof->{legacy_surface}{consumed_by_successor},
        'successor explicitly does not consume the legacy surface');

    my $dut = artifact('generated_hial_vhdl_dut');
    my $hial_input = $built->{backend_inputs}{dut_vhdl}[0];
    is($dut->{content}, $hial_input->{text},
        'emitted HIAL DUT bytes equal the private handoff exactly');
    is($proof->{hial_successor}{private_handoff_sha256},
        $hial_input->{content_sha256},
        'proof records the exact HIAL private-handoff digest');
    is($proof->{hial_successor}{emitted_sha256}, sha256_hex($dut->{content}),
        'proof records the exact emitted DUT digest');
    ok($proof->{hial_successor}{byte_identical},
        'proof reports the HIAL DUT as byte-identical');
    like($proof->{hial_successor}{emitted_relpath},
        qr{\Abackends/vhdl_portable_ghdl/src/dut/},
        'HIAL DUT remains isolated under the backend DUT directory');
    my $successor_vhdl = join '', map { $_->{content} }
        grep { $_->{language} eq 'vhdl' && $_->{role} ne 'generated_hial_vhdl_dut' }
        @{$emission->{artifacts}};
    unlike($successor_vhdl, qr/observation_vhdl_pkg|vhdl-observation-package/i,
        'successor support source imports or rewrites no legacy package');
    remove_tree($legacy_root);
    ok(!-e $legacy_root, 'repository-local legacy proof output is removed exactly');
};

subtest 'artifact graph, manifest references, and gallery evidence are byte exact' => sub {
    is($emission->{backend_manifest}{emitter_revision}, 5,
        'matrix/review closure is emitter revision five');
    is(scalar(@{$emission->{artifacts}}), 17,
        'artifact graph contains seventeen artifacts');
    is(scalar(grep { $_->{language} eq 'vhdl' } @{$emission->{artifacts}}), 6,
        'artifact graph retains six generated VHDL sources');
    is(scalar(@{$emission->{source_map}{entries}}), 59,
        'source map retains fifty-nine selected entries');
    is(scalar(@{$emission->{static_validation}{checks}}), 20,
        'static validator retains twenty structure checks');
    is($emission->{backend_manifest}{review_workflow}{check_count}, 7,
        'manifest records seven review-closure invariants');

    my %evidence = (
        selected_mapping_matrix => [
            'selected-mapping-matrix.json', $emission->{mapping_matrix}, 'mapping_matrix'
        ],
        review_workflow => [
            'review-workflow.json', $emission->{review_workflow}, 'review_workflow'
        ],
        migration_proof => [
            'migration-proof.json', $emission->{migration_proof}, 'migration_proof'
        ],
    );
    for my $role (sort keys %evidence) {
        my ($filename, $value, $manifest_key) = @{$evidence{$role}};
        my $artifact = artifact($role);
        is($artifact->{content}, $pretty_json->encode($value),
            "evidence artifact '$filename' is canonical pretty JSON");
        is(sha256_hex($artifact->{content}),
            $emission->{backend_manifest}{$manifest_key}{sha256},
            "manifest digest for '$filename' is exact");
        is($artifact->{content}, slurp_raw(repo_path(
            (split m{/}, $gallery_rel), 'evidence', $filename)),
            "gallery evidence '$filename' is byte-identical to emission");
    }

    open my $check_fh, '-|', $^X, 'scripts/refresh_vial_vhdl_portable_gallery.pl',
        '--check' or die "cannot start portable VHDL gallery check: $!\n";
    local $/;
    my $check_output = <$check_fh>;
    close $check_fh;
    is($? >> 8, 0, 'non-mutating portable VHDL gallery check succeeds');
    like($check_output,
        qr/\Aportable VHDL semantics gallery current: 6 VHDL sources; 11 evidence artifacts; 59 source-map entries; 20 static checks; 24 mappings; 7 review-closure checks\n\z/,
        'gallery check reports the exact closed evidence counts');
};

subtest 'review-closure API rejects malformed or incomplete evidence fail closed' => sub {
    my @source = map { clone($_) }
        grep { $_->{language} eq 'vhdl' } @{$emission->{artifacts}};
    my $hial = $built->{backend_inputs}{dut_vhdl}[0];
    my $base = {
        plan_id => $emission->{plan_id},
        fixture_id => $emission->{backend_manifest}{fixture_id},
        emitter_revision => 5,
        source_artifacts => \@source,
        review_gallery => $gallery_rel,
        hial_source_identity => {
            source_id => $hial->{source_id},
            content_sha256 => $hial->{content_sha256},
            byte_length => $hial->{byte_length},
            emitted_relpath => artifact('generated_hial_vhdl_dut')->{relpath},
        },
    };

    my $closed = FSM::VIAL::Backend::VHDLPortableReviewClosure->build(clone($base));
    ok($closed->{ok}, 'direct review-closure API accepts the exact evidence graph');
    is_deeply(
        [sort keys %$closed],
        [sort @{FSM::VIAL::Backend::VHDLPortableReviewClosure->result_keys}],
        'direct review-closure result is closed',
    );

    my $missing = clone($base);
    $missing->{source_artifacts} = [grep { $_->{role} ne 'generated_hial_vhdl_dut' }
        @{$missing->{source_artifacts}}];
    review_failure($missing, qr/role 'generated_hial_vhdl_dut' must occur exactly once/,
        'missing generated HIAL role evidence');

    my $revision = clone($base);
    $revision->{emitter_revision} = 3;
    review_failure($revision, qr/emitter_revision must be 5/,
        'substituted emitter revision');

    my $digest = clone($base);
    $digest->{hial_source_identity}{content_sha256} = '0' x 64;
    review_failure($digest, qr/HIAL emitted bytes disagree/,
        'substituted HIAL private-handoff digest');

    my $legacy_import = clone($base);
    my ($top) = grep { $_->{role} eq 'vhdl_fixture_top' }
        @{$legacy_import->{source_artifacts}};
    $top->{content} .= "-- use work.observation_vhdl_pkg.all;\n";
    review_failure($legacy_import,
        qr/review closure failed an internal invariant/,
        'legacy-package import leakage');

    my $unsafe = clone($base);
    $unsafe->{review_gallery} = '../outside';
    review_failure($unsafe, qr/review_gallery must be a safe repository-relative path/,
        'traversing gallery path');

    my $extra_role = clone($base);
    push @{$extra_role->{source_artifacts}}, {
        %{$extra_role->{source_artifacts}[0]},
        role => 'invented_source_role',
        relpath => 'backends/vhdl_portable_ghdl/src/invented.vhd',
    };
    review_failure($extra_role, qr/outside the selected matrix/,
        'unexpected source role');

    my $duplicate_path = clone($base);
    $duplicate_path->{source_artifacts}[1]{relpath} =
        $duplicate_path->{source_artifacts}[0]{relpath};
    review_failure($duplicate_path, qr/source artifact relpath .* is duplicated/,
        'duplicate source relpath');

    my $unknown = clone($base);
    $unknown->{invented} = 1;
    review_failure($unknown, qr/unknown key 'invented'/,
        'unknown invocation key');
};

done_testing;

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
    return FSM::VIAL::Backend::VHDLPortableGHDL->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => '.artifacts/test/vial-vhdl-portable-matrix-review',
        backend_profile => $profile,
    });
}

sub artifact {
    my ($role) = @_;
    my @artifact = grep { $_->{role} eq $role } @{$emission->{artifacts}};
    die "artifact role '$role' is not unique\n" unless @artifact == 1;
    return $artifact[0];
}

sub review_failure {
    my ($args, $message_re, $label) = @_;
    my $result = FSM::VIAL::Backend::VHDLPortableReviewClosure->build($args);
    ok(!$result->{ok}, "$label fails closed");
    is($result->{diagnostics}[0]{code}, 'VIAL_VHDL_REVIEW_HOST_ERROR',
        "$label has the exact diagnostic code");
    like($result->{diagnostics}[0]{message}, $message_re,
        "$label retains a sanitized actionable explanation");
}

sub clone {
    my ($value) = @_;
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if ref($value) eq 'JSON::PP::Boolean';
    return {map { $_ => clone($value->{$_}) } keys %$value}
        if ref($value) eq 'HASH';
    return [map { clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
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
