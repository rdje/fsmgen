#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleCheckingState;
use FSM::VIAL::ArchitectureScaleWorkload;

my $class = 'FSM::VIAL::ArchitectureScaleCheckingState';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path('ppif/ahb_lite_subordinate.ppif'));
my $reference_vial = slurp_raw(
    repo_path('vial/ahb_subordinate_base_output_arbitration.vial'),
);
my %expected = (
    workload_identity =>
        'workload/7a125500c716e333ac8849ca5594849dc52e34380f0ba0ec416a2e12975247c7',
    evaluation_identity =>
        'checking-evaluation/9b6746001158e81fb6e4f55d5ede16c257d31c4f479495472665c000d5acd159',
    rerun_identity =>
        'rerun/ceefc4f30bd60d5d7af60a20ae278e35e1478dbc43a0f61010c8473462c69033',
    semantic_ir_sha256 =>
        '00dce6495e6a144ba2ae36184ef50b1c3596b3359fc0acdb4a56fdc4c92dca31',
    bridge_manifest_sha256 =>
        'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca',
    execution_ir_sha256 =>
        '5f04ca97e2a29f208363ceb50cdf311272ab8732357e7bec10fa41da738f3a5e',
    plan_sha256 =>
        '1a3b97f40ae03a82e10aa553072adf73c2d16bf266730a14e2bdc57649d3b307',
    serialized_plan_bytes => 44_467,
);

sub candidate {
    my (%overrides) = @_;
    return FSM::VIAL::ArchitectureScaleCheckingState::_test_construct_candidate({
        primary_axis => 'model_instances',
        level => 'gate_candidate_v1',
        reference_hial_text => $reference_hial,
        vial_source_text => $reference_vial,
        %overrides,
    });
}

subtest 'public ownership begins empty and every catalog boundary fails closed' => sub {
    is_deeply($class->owned_shapes, [],
        'foundation publishes no owned checking-state level');

    my $reference = eval {
        $class->construct({
            primary_axis => 'model_instances',
            level => 'reference_v1',
            reference_hial_text => $reference_hial,
        });
        1;
    };
    ok(!$reference, 'reference catalog record is not a generated shape');
    like($@, qr/reference_v1 remains a catalog record/,
        'reference rejection names the catalog-only boundary');

    my $selected = eval {
        $class->construct({
            primary_axis => 'model_instances',
            level => 'gate_candidate_v1',
            reference_hial_text => $reference_hial,
        });
        1;
    };
    ok(!$selected, 'foundation does not prematurely own a selected level');
    like($@, qr/foundation does not own any selected axis level/,
        'selected rejection names the bounded implementation frontier');

    my $unknown_axis = eval {
        $class->construct({
            primary_axis => 'backend_results',
            level => 'gate_candidate_v1',
            reference_hial_text => $reference_hial,
        });
        1;
    };
    ok(!$unknown_axis, 'unknown axis fails closed');
    like($@, qr/unknown checking-state primary axis/,
        'unknown-axis rejection is exact');

    my $unknown_level = eval {
        $class->construct({
            primary_axis => 'model_instances',
            level => 'unbounded_v1',
            reference_hial_text => $reference_hial,
        });
        1;
    };
    ok(!$unknown_level, 'unknown level fails closed');
    like($@, qr/unknown checking-state level/,
        'unknown-level rejection is exact');

    my $unknown_key = eval {
        $class->construct({
            primary_axis => 'model_instances',
            level => 'gate_candidate_v1',
            reference_hial_text => $reference_hial,
            semantic_ir => {},
        });
        1;
    };
    ok(!$unknown_key, 'caller-created IR cannot enter construction');
    like($@, qr/unknown key 'semantic_ir'/,
        'closed construction identifies injected IR metadata');
};

subtest 'private candidate construction is caller-sealed and content-addressed' => sub {
    my $direct = eval {
        $class->_construct_candidate({
            primary_axis => 'model_instances',
            level => 'gate_candidate_v1',
            reference_hial_text => $reference_hial,
            vial_source_text => $reference_vial,
        });
        1;
    };
    ok(!$direct, 'external caller cannot invoke candidate construction');
    like($@, qr/candidate construction is private/,
        'caller-seal rejection names the private boundary');
    my $direct_internal = eval {
        FSM::VIAL::ArchitectureScaleCheckingState::_construct_candidate_internal({
            primary_axis => 'model_instances',
            level => 'gate_candidate_v1',
            reference_hial_text => $reference_hial,
            vial_source_text => $reference_vial,
        });
        1;
    };
    ok(!$direct_internal, 'external caller cannot bypass the candidate wrapper');
    like($@, qr/candidate internals are private/,
        'internal caller seal rejects direct fully-qualified invocation');

    my $first = candidate();
    my $second = candidate();
    ok($first->{ok}, 'same-package candidate reaches the common workload contract');
    is($json->encode($second), $json->encode($first),
        'independent candidate construction is byte-identical');
    like($first->{workload_identity}, qr{\Aworkload/[0-9a-f]{64}\z},
        'construction carries one content address');
    is($first->{workload_identity}, $expected{workload_identity},
        'foundation construction identity is exact');
    is($first->{specification}{family}, 'checking_state_v1',
        'candidate cannot escape the checking-state family');
    is($first->{specification}{requested_counts}{model_instances}, 32,
        'candidate derives its selected specification from the shared catalog');
    is_deeply([map { $_->{role} } @{$first->{inputs}}],
        [qw(vial_source hial_source)],
        'canonical path order contains only ordinary VIAL and exact HIAL source');
    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is($input{hial_source}{relative_path}, 'ppif/ahb_lite_subordinate.ppif',
        'HIAL input retains the checked-AHB repository-relative identity');
    is(sha256_hex($input{hial_source}{content}),
        '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c',
        'HIAL input retains the exact checked-AHB content identity');
    is($input{vial_source}{relative_path},
        'generated/vial-scale/checking_state/checking_state.vial',
        'VIAL input uses one fixed repository-relative generated identity');
    is($input{vial_source}{content}, $reference_vial,
        'candidate retains every ordinary VIAL source byte');

    my $altered_hial = $reference_hial;
    substr($altered_hial, 0, 1, substr($altered_hial, 0, 1) eq '(' ? ' ' : '(');
    my $forged_anchor = eval { candidate(reference_hial_text => $altered_hial); 1 };
    ok(!$forged_anchor, 'changed checked-AHB bytes fail before construction');
    like($@, qr/checked-AHB reference identity changed/,
        'anchor mutation rejection names the frozen identity');

    my $extra = eval { candidate(trace_result => {}); 1 };
    ok(!$extra, 'candidate cannot accept result-provider metadata');
    like($@, qr/unknown key 'trace_result'/,
        'candidate projection names injected provider metadata');
};

subtest 'canonical producers yield deterministic SemanticIR, bridge, and ExecutionIR' => sub {
    my $construction = candidate();
    my $built = $class->build({construction => $construction});
    ok($built->{ok}, 'foundation builds through the public execution producer');
    diag($json->encode($built->{diagnostics})) unless $built->{ok};
    is(ref($built->{execution_ir}), 'FSM::VIAL::ExecutionIR',
        'build returns exact canonical ExecutionIR');
    is($built->{plan}{schema}, 'fsmgen.vial_plan.v1',
        'build returns the canonical target-neutral plan projection');

    my $evaluation = $class->evaluate({construction => $construction});
    ok($evaluation->{ok}, 'independent full-route rerun is byte-deterministic');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is_deeply([sort keys %$evaluation], [sort @{$class->evaluation_keys}],
        'evaluation is one closed projection');
    is($evaluation->{status}, 'foundation_validated',
        'foundation status does not claim an axis result');
    is($evaluation->{observed_outcome}, 'accepted_not_axis_evaluated',
        'outcome distinguishes route acceptance from axis evaluation');
    like($evaluation->{evaluation_identity},
        qr{\Achecking-evaluation/[0-9a-f]{64}\z},
        'evaluation is content-addressed');
    is($evaluation->{evaluation_identity}, $expected{evaluation_identity},
        'foundation evaluation identity is exact');
    like($evaluation->{rerun_identity}, qr{\Arerun/[0-9a-f]{64}\z},
        'rerun stage tuple has its own deterministic identity');
    is($evaluation->{rerun_identity}, $expected{rerun_identity},
        'foundation rerun identity is exact');
    for my $stage (qw(
        semantic_ir_sha256 bridge_manifest_sha256 execution_ir_sha256 plan_sha256
    )) {
        like($evaluation->{stage_identities}{$stage}, qr/\A[0-9a-f]{64}\z/,
            "$stage is an exact canonical digest");
        is($evaluation->{stage_identities}{$stage}, $expected{$stage},
            "$stage matches the frozen foundation identity");
    }
    is($evaluation->{metrics}{model_instances}, 2,
        'foundation observes the two reference model instances without claiming 32');
    is($evaluation->{metrics}{scoreboard_instances}, 1,
        'foundation observes the reference scoreboard');
    is($evaluation->{metrics}{scoreboard_declared_capacity}, 4,
        'foundation observes the reference capacity');
    is($evaluation->{metrics}{coverpoints}, 1,
        'foundation observes the reference coverpoint');
    is($evaluation->{metrics}{bins_and_cross_tuples}, 2,
        'foundation observes the reference static bin domain');
    is($evaluation->{metrics}{faults}, 1,
        'foundation observes the reference fault');
    is($evaluation->{metrics}{random_occurrences}, 1,
        'foundation observes the reference keyed occurrence');
    is($evaluation->{metrics}{serialized_plan_bytes},
        $expected{serialized_plan_bytes},
        'foundation records the exact genuine serialized plan size');

    ok(!$evaluation->{outcome_contract}{axis_oracle_executed},
        'foundation explicitly reports no axis oracle yet');
    ok(!$evaluation->{outcome_contract}{selected_count_claimed},
        'foundation does not equate reference observations with selected counts');
    is_deeply($evaluation->{outcome_contract}{canonical_stages_completed},
        [qw(semantic bridge execution_ir plan)],
        'outcome records the exact completed canonical stages');
    is($evaluation->{oracle_evidence}{schema},
        'fsmgen.vial_architecture_scale_checking_oracle_evidence.v1',
        'closed report reserves one versioned axis-oracle compartment');
    is($evaluation->{oracle_evidence}{oracle}, 'none',
        'zero-owned-level foundation carries no axis oracle');
    ok(!scalar(grep { defined $evaluation->{oracle_evidence}{$_} }
        qw(model scoreboard coverage faults random_replay)),
        'every future axis-evidence compartment begins null');
    ok($evaluation->{claims}{qualification_only},
        'checking evaluator is explicitly qualification-only');
    for my $claim (qw(
        capability_claimed support_claimed performance_claimed capacity_claimed
        backend_authority runtime_authority axis_level_owned
    )) {
        ok(!$evaluation->{claims}{$claim}, "$claim remains false");
    }
    is_deeply($evaluation->{explicit_nonclaims},
        candidate()->{specification}{explicit_nonclaims},
        'evaluation preserves every common workload nonclaim');
    my @host_path_fragments = (
        '/Volumes/',
        join('/', '', 'private', 'tmp', ''),
        join('/', '', 'tmp', ''),
    );
    ok(!scalar(grep { index($json->encode($evaluation), $_) >= 0 }
        @host_path_fragments),
        'durable evaluation contains no absolute host or off-volume path');
};

subtest 'packed-state schema is closed and bounded before axis semantics land' => sub {
    my $evaluation = $class->evaluate({construction => candidate()});
    my $packed = $evaluation->{packed_state_contract};
    is($packed->{schema},
        'fsmgen.vial_architecture_scale_packed_checking_state.v1',
        'packed-state schema is versioned');
    is($packed->{digest_algorithm}, 'sha256',
        'all future packed payload identities use the selected digest');
    is($packed->{model_cells}{unknown_state_policy}, 'reject',
        'model packing fails closed on unknown state');
    is($packed->{scoreboard_fifo}{encoding}, 'uint32_big_endian_fifo_v1',
        'scoreboard payload encoding is exact');
    is($packed->{scoreboard_fifo}{maximum_entries}, 1_000_000,
        'scoreboard packing bounds the selected maximum entry count');
    is($packed->{scoreboard_fifo}{maximum_payload_bytes}, 4_000_000,
        'scoreboard packed payload is capped at four million bytes');
    is($packed->{scoreboard_fifo}{fixed_fields_policy},
        'reconstruct_and_compare_complete_transaction_v1',
        'payload packing cannot skip complete transaction comparison');
    is($packed->{coverage_vector}{maximum_entries}, 1_000_000,
        'coverage packing bounds the selected static domain');
    is($packed->{coverage_vector}{maximum_vector_bytes}, 125_000,
        'million-entry coverage vector is exactly 125000 bytes');
    is($packed->{coverage_vector}{comparison},
        'byte_equal_independently_derived_expected_vector_v1',
        'coverage proof requires independent byte equality');
};

subtest 'construction and evaluation mutation are rejected defensively' => sub {
    my $construction = candidate();
    my $evaluation = $class->evaluate({construction => $construction});
    my $validated = $class->validate_evaluation({
        construction => $construction,
        evaluation => $evaluation,
    });
    is($json->encode($validated), $json->encode($evaluation),
        'canonical evaluation validates byte-for-byte');

    my $mutated_construction = clone($construction);
    $mutated_construction->{inputs}[0]{content} .= ' ';
    my $built_mutation = eval {
        $class->build({construction => $mutated_construction});
        1;
    };
    ok(!$built_mutation, 'post-identity source mutation fails closed');
    like($@, qr/construction is not canonical/,
        'construction mutation rejection names canonical regeneration');

    my $mutated_evaluation = clone($evaluation);
    $mutated_evaluation->{metrics}{model_instances}++;
    my $evaluation_mutation = eval {
        $class->validate_evaluation({
            construction => $construction,
            evaluation => $mutated_evaluation,
        });
        1;
    };
    ok(!$evaluation_mutation, 'post-identity evaluation mutation fails closed');
    like($@, qr/evaluation is not canonical/,
        'evaluation mutation rejection names canonical regeneration');

    my $unknown_projection = clone($evaluation);
    $unknown_projection->{backend_result} = {};
    my $unknown = eval {
        $class->validate_evaluation({
            construction => $construction,
            evaluation => $unknown_projection,
        });
        1;
    };
    ok(!$unknown, 'backend result cannot enter the evaluation projection');
    like($@, qr/unknown key 'backend_result'/,
        'evaluation schema identifies unknown provider data');

    $evaluation->{metrics}{model_instances} = 999;
    my $fresh = $class->evaluate({construction => candidate()});
    is($fresh->{metrics}{model_instances}, 2,
        'returned evaluation does not share mutable storage with reruns');
};

subtest 'repository-volume staging cleans success and failure exactly' => sub {
    my $construction = candidate();
    my $stage_abs = repo_path($construction->{staging_identity});
    ok(!-e $stage_abs && !-l $stage_abs,
        'deterministic checking-state stage begins absent');
    my ($seen_stage, @seen_paths);
    my $success = $class->with_staging({
        repository_root => $repo_root,
        construction => $construction,
        consumer => sub {
            my ($context) = @_;
            $seen_stage = $context->{staging_identity};
            @seen_paths = sort map { $_->{relative_path} } @{$context->{inputs}};
            ok(-d $context->{staging_root},
                'consumer sees a repository-local staging directory');
        },
    });
    ok($success->{ok}, 'successful staging reports success');
    ok($success->{same_volume}, 'successful staging proves same-volume identity');
    ok($success->{removed}, 'successful staging reports exact cleanup');
    is($seen_stage, $construction->{staging_identity},
        'consumer sees the content-addressed repository-relative stage');
    is_deeply(\@seen_paths, [
        'generated/vial-scale/checking_state/checking_state.vial',
        'ppif/ahb_lite_subordinate.ppif',
    ], 'consumer sees only the two canonical source inputs');
    ok(!-e $stage_abs && !-l $stage_abs,
        'successful staging leaves no content-addressed residue');

    my $failed = $class->with_staging({
        repository_root => $repo_root,
        construction => $construction,
        consumer => sub { die "intentional checking-state consumer failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure is reported');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure uses the stable diagnostic family');
    ok(!-e $stage_abs && !-l $stage_abs,
        'failed staging also leaves no content-addressed residue');
};

done_testing();

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

package FSM::VIAL::ArchitectureScaleCheckingState;

sub _test_construct_candidate {
    my ($args) = @_;
    return __PACKAGE__->_construct_candidate($args);
}
