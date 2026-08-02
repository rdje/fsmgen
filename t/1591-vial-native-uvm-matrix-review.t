#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::SVUVMAccellera2020_3_1;
use FSM::VIAL::Backend::SVUVMReviewClosure;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $json = JSON::PP->new->canonical(1)->pretty(1);
my $profile = 'sv_uvm_emit.accellera_2020_3_1';
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $gallery_rel = join '/', qw(
    vial review_gallery sv_uvm_emit.accellera_2020_3_1
    ahb_base_output_foundation
);
my $built = build_plan();
ok($built->{ok}, 'checked VIAL/HIAL fixture reaches native UVM matrix inputs');
diag(JSON::PP->new->canonical(1)->encode($built->{diagnostics})) unless $built->{ok};
my $emission = emit_backend();
ok($emission->{ok}, 'selected native UVM matrix/review emission succeeds');
diag(JSON::PP->new->canonical(1)->encode($emission->{diagnostics})) unless $emission->{ok};

subtest 'selected mapping matrix is closed and accounts for every emitted foundation' => sub {
    my $matrix = $emission->{mapping_matrix};
    is($matrix->{schema}, 'fsmgen.vial_uvm_selected_mapping_matrix.v1',
        'mapping schema is exact');
    is($matrix->{scope},
        'complete_selected_native_uvm_emission_matrix_not_full_uvm_breadth',
        'selected-scope closure does not claim complete UVM breadth');
    is(scalar(@{$matrix->{mappings}}), 25,
        'matrix contains the exact twenty-five selected foundations');

    my @mapping_id = map { $_->{mapping_id} } @{$matrix->{mappings}};
    is_deeply(\@mapping_id, [sort @mapping_id], 'mapping identities are sorted');
    is(scalar(keys %{ {map { $_ => 1 } @mapping_id} }), scalar(@mapping_id),
        'mapping identities are unique');
    for my $mapping (@{$matrix->{mappings}}) {
        is_deeply(
            [sort keys %$mapping],
            [sort @{FSM::VIAL::Backend::SVUVMReviewClosure->mapping_keys}],
            "mapping '$mapping->{mapping_id}' is closed",
        );
        is($mapping->{emission_status}, 'emitted',
            "mapping '$mapping->{mapping_id}' records emission only");
        is($mapping->{static_review_status}, 'passed_structural_only',
            "mapping '$mapping->{mapping_id}' labels structural review honestly");
        is($mapping->{visual_review_status}, 'pending',
            "mapping '$mapping->{mapping_id}' leaves visual review pending");
        is($mapping->{qualification_status}, 'not_run',
            "mapping '$mapping->{mapping_id}' leaves qualification not run");
    }

    is_deeply(
        [sort map { $_->{foundation_id} } @{$matrix->{mappings}}],
        [sort @{$emission->{backend_manifest}{capability_evidence}{emitted_foundations}}],
        'matrix foundations equal the manifest emitted-foundation set exactly',
    );
};

subtest 'public, compiler-owned, and preview entry points remain distinguishable' => sub {
    my %mapping = map { $_->{foundation_id} => $_ }
        @{$emission->{mapping_matrix}{mappings}};
    is($mapping{transaction_items}{normal_source}, 'public_vial_v1',
        'transaction items have a normal public VIAL entry point');
    is($mapping{transaction_items}{terse_source}, 'public_vial_v1',
        'transaction items have a terse public VIAL entry point');
    is($mapping{transaction_items}{typed_ir}, 'public_execution_ir',
        'transaction items enter the backend through public ExecutionIR');
    ok(!defined($mapping{transaction_items}{unsupported_reason}),
        'public transaction authoring needs no unsupported-reason label');

    is($mapping{fixture_test}{normal_source}, 'not_applicable_compiler_owned',
        'fixture test topology is compiler-owned rather than invented public syntax');
    is($mapping{ral_preview}{normal_source}, 'not_available_private_preview',
        'RAL authoring is explicitly unavailable at the public source entry');
    is($mapping{ral_preview}{typed_ir}, 'private_typed_preview',
        'RAL remains an explicitly private typed preview');
    like($mapping{ral_preview}{unsupported_reason}, qr/public VIAL RAL authoring syntax is not selected/,
        'RAL preview gives the exact unsupported public-authoring reason');
    like($mapping{notification_interception}{unsupported_reason},
        qr/native interceptor authoring syntax is not selected/,
        'mixed public notification/private interception ownership is explicit');

    for my $mapping (values %mapping) {
        my $preview = $mapping->{intent_owner} =~ /(?:private|mixed)/;
        ok($preview ? defined($mapping->{unsupported_reason})
                    : !defined($mapping->{unsupported_reason}),
            "mapping '$mapping->{foundation_id}' has the exact preview-reason partition");
    }
};

subtest 'review workflow is deterministic, repository-relative, and qualification-honest' => sub {
    my $workflow = $emission->{review_workflow};
    is($workflow->{schema}, 'fsmgen.vial_uvm_review_workflow.v1',
        'review-workflow schema is exact');
    is($workflow->{gallery_root}, $gallery_rel, 'gallery root is repository-relative');
    is($workflow->{regenerate_command},
        'perl scripts/refresh_vial_native_uvm_gallery.pl',
        'regeneration command is repository-relative and exact');
    is($workflow->{check_command},
        'perl scripts/refresh_vial_native_uvm_gallery.pl --check',
        'non-mutating check command is repository-relative and exact');
    is(scalar(@{$workflow->{examples}}), 9,
        'workflow exposes the nine UVM-facing source examples');
    is(scalar(@{$workflow->{evidence_examples}}), 2,
        'workflow exposes both canonical review-evidence files');

    my %stage = map { $_->{stage_id} => $_ } @{$workflow->{stages}};
    is_deeply([sort keys %stage], [sort qw(
        regenerate byte_compare static_shape visual_review defect_capture
        experimental_compile qualified_runtime
    )], 'review stages are exact');
    for my $stage (values %stage) {
        is_deeply(
            [sort keys %$stage],
            [sort @{FSM::VIAL::Backend::SVUVMReviewClosure->stage_keys}],
            "review stage '$stage->{stage_id}' is closed",
        );
    }
    is($stage{static_shape}{status}, 'passed_structural_only',
        'structural evidence remains narrower than syntax evidence');
    is($stage{visual_review}{status}, 'pending', 'visual judgment remains pending');
    is($stage{experimental_compile}{status}, 'not_run',
        'experimental compilation remains task-separated and not run');
    is($stage{qualified_runtime}{status}, 'not_run',
        'qualified runtime remains task-separated and not run');
    unlike($json->encode($workflow), qr/\b(?:xcelium|irun|vcs|questa|modelsim|verilator|iverilog|nexsim)\b/i,
        'canonical workflow evidence contains no simulator-provider name');

    my %nonclaim = map { $_ => 1 } @{$workflow->{nonclaims}};
    ok($nonclaim{visual_review_complete}, 'visual completion is explicitly unclaimed');
    ok($nonclaim{systemverilog_parse}, 'SystemVerilog parsing is explicitly unclaimed');
    ok($nonclaim{runtime}, 'runtime is explicitly unclaimed');
    ok($nonclaim{result}, 'result production is explicitly unclaimed');
    ok($nonclaim{parity}, 'parity is explicitly unclaimed');
    ok($nonclaim{full_uvm_breadth}, 'full UVM breadth is explicitly unclaimed');
    ok(!$workflow->{defect_routing}{conversation_only_is_durable},
        'review defects must be routed to the durable task-tree');
};

subtest 'artifact graph, manifest references, and gallery evidence are byte exact' => sub {
    is($emission->{backend_manifest}{emitter_revision}, 5,
        'matrix/review closure is emitter revision five');
    is(scalar(@{$emission->{artifacts}}), 16, 'artifact graph contains sixteen artifacts');
    is(scalar(grep { $_->{language} eq 'systemverilog' } @{$emission->{artifacts}}), 10,
        'artifact graph retains ten generated SystemVerilog sources');
    is(scalar(@{$emission->{source_map}{entries}}), 75,
        'source map retains seventy-five selected entries');
    is(scalar(@{$emission->{static_validation}{checks}}), 14,
        'static validator retains fourteen structure checks');
    is($emission->{backend_manifest}{review_workflow}{check_count}, 5,
        'manifest records five review-closure invariants');

    my %evidence = (
        selected_mapping_matrix => [
            'selected-mapping-matrix.json', $emission->{mapping_matrix}, 'mapping_matrix'
        ],
        review_workflow => [
            'review-workflow.json', $emission->{review_workflow}, 'review_workflow'
        ],
    );
    for my $role (sort keys %evidence) {
        my ($filename, $value, $manifest_key) = @{$evidence{$role}};
        my $artifact = artifact($role);
        is($artifact->{content}, $json->encode($value),
            "evidence artifact '$filename' is canonical pretty JSON");
        is(sha256_hex($artifact->{content}),
            $emission->{backend_manifest}{$manifest_key}{sha256},
            "manifest digest for '$filename' is exact");
        is($artifact->{content},
            slurp_raw(repo_path((split m{/}, $gallery_rel), $filename)),
            "gallery evidence '$filename' is byte-identical to emission");
    }

    open my $check_fh, '-|', $^X, 'scripts/refresh_vial_native_uvm_gallery.pl', '--check'
        or die "cannot start native UVM gallery check: $!\n";
    local $/;
    my $check_output = <$check_fh>;
    close $check_fh;
    is($? >> 8, 0, 'non-mutating native UVM gallery check succeeds');
    like($check_output,
        qr/\Anative UVM gallery current: 9 source snapshots; 2 review evidence files; 75 source-map entries; 14 static checks; 5 review-closure checks\n\z/,
        'gallery check reports the exact closed evidence counts');
};

subtest 'review-closure API rejects malformed or incomplete evidence fail closed' => sub {
    my @source = map { clone($_) }
        grep { $_->{language} eq 'systemverilog' } @{$emission->{artifacts}};
    my $base = {
        plan_id => $emission->{plan_id},
        fixture_id => $emission->{backend_manifest}{fixture_id},
        emitter_revision => 5,
        source_artifacts => \@source,
        review_gallery => $gallery_rel,
    };

    my $closed = FSM::VIAL::Backend::SVUVMReviewClosure->build(clone($base));
    ok($closed->{ok}, 'direct review-closure API accepts the exact evidence graph');
    is_deeply(
        [sort keys %$closed],
        [sort @{FSM::VIAL::Backend::SVUVMReviewClosure->result_keys}],
        'direct review-closure result is closed',
    );

    my $missing = clone($base);
    $missing->{source_artifacts} = [grep { $_->{role} ne 'generated_hial_dut' }
        @{$missing->{source_artifacts}}];
    review_failure($missing, qr/lacks exact source role 'generated_hial_dut'/,
        'missing generated-role evidence');

    my $revision = clone($base);
    $revision->{emitter_revision} = 4;
    review_failure($revision, qr/emitter_revision must be 5/,
        'substituted emitter revision');

    my $unsafe = clone($base);
    $unsafe->{review_gallery} = '../outside';
    review_failure($unsafe, qr/review_gallery must be a safe repository-relative path/,
        'traversing gallery path');

    my $extra_role = clone($base);
    push @{$extra_role->{source_artifacts}}, {
        %{$extra_role->{source_artifacts}[0]},
        role => 'invented_source_role',
        relpath => 'backends/sv_uvm_emit.accellera_2020_3_1/src/invented.sv',
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
    return FSM::VIAL::Backend::SVUVMAccellera2020_3_1->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => '.artifacts/test/vial-native-uvm-matrix-review',
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
    my $result = FSM::VIAL::Backend::SVUVMReviewClosure->build($args);
    ok(!$result->{ok}, "$label fails closed");
    is($result->{diagnostics}[0]{code}, 'VIAL_UVM_REVIEW_HOST_ERROR',
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
