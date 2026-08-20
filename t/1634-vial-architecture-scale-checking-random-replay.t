#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleCheckingState;

my $class = 'FSM::VIAL::ArchitectureScaleCheckingState';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path('ppif/ahb_lite_subordinate.ppif'));

sub construction {
    my ($level) = @_;
    return $class->construct({
        primary_axis => 'random_occurrences',
        level => $level,
        reference_hial_text => $reference_hial,
    });
}

subtest '1,024 keyed Boolean decisions generate, rerun, and replay exactly' => sub {
    my $constructed = construction('gate_candidate_v1');
    ok($constructed->{ok}, 'random gate constructs ordinary VIAL source');
    my ($vial) = grep { $_->{role} eq 'vial_source' }
        @{$constructed->{inputs}};
    is(length($vial->{content}), 26_101,
        'gate freezes its compact source byte witness');

    my $evaluation = $class->evaluate({construction => $constructed});
    ok($evaluation->{ok}, 'random gate passes the provider-free replay oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'accepted', 'random gate is accepted');
    is($evaluation->{workload_identity},
        'workload/9f06f3b03d0e442568f5deeca3473eec000e50b6f0b7992f864a4435eeab7b5f',
        'gate workload identity is frozen');
    is($evaluation->{evaluation_identity},
        'checking-evaluation/a9096cdfca0276253a5640d5a38c2ff3e07fe0a583346a1479f23218ec9baf4d',
        'gate evaluation identity is frozen');
    is($evaluation->{rerun_identity},
        'rerun/4d6b29dcf7316abade1b588e6ccf8b57740c178623796437b029d3f425f3bb27',
        'gate complete-route rerun identity is frozen');
    is($evaluation->{metrics}{random_occurrences}, 1_024,
        'gate reaches every selected occurrence');
    is($evaluation->{metrics}{serialized_plan_bytes}, 2_073_805,
        'gate freezes its selected genuine plan byte count');

    my $random = $evaluation->{oracle_evidence}{random_replay};
    is($evaluation->{oracle_evidence}{oracle}, 'random_replay',
        'gate selects only the random/replay oracle');
    is($random->{schema},
        'fsmgen.vial_architecture_scale_random_replay_oracle_evidence.v1',
        'gate uses the closed random/replay evidence schema');
    is($random->{program}, 'generate_replay_compare_each_keyed_boolean_v1',
        'gate executes the exact keyed Boolean program');
    is($random->{choice_declarations}, 128,
        'gate uses the bounded 128-choice palette');
    is($random->{scenario_count}, 8,
        'gate uses eight real one-operation scenarios');
    is($random->{generated_decisions}, 1_024,
        'generated sequence accounts for every occurrence');
    is($random->{replayed_decisions}, 1_024,
        'replayed sequence accounts for every occurrence');
    is($random->{generated_sequence_sha256},
        'c0eda23016661909e91ece2a64e3a25a47cab0b42fa3ec085d8d567ff303fc0f',
        'generated keyed sequence identity is frozen');
    is($random->{generated_sequence_sha256},
        $random->{rerun_sequence_sha256},
        'independent generation reproduces the byte-equal sequence');
    is($random->{normalized_generated_sequence_sha256},
        '7fe17fd25162111783fd1c4933cd186c4e7b3135a10a377a0d436f2b79c364ce',
        'origin-free generated sequence identity is frozen');
    is($random->{normalized_generated_sequence_sha256},
        $random->{normalized_replayed_sequence_sha256},
        'strict replay differs from generation only by origin');
    is($random->{replay_manifest_id},
        'replay/ef9c73c378ac4aebf979a291b1cc9a720fccead9ecbbd30b15b398bf214281f9',
        'strict replay manifest identity is frozen');
    for my $proof (qw(
        key_order_preserved values_canonically_normalized
        generated_values_matched replay_values_matched
        replay_identity_preserved normalized_plans_equal mutation_rejected
        order_mutation_rejected
    )) {
        ok($random->{$proof}, "$proof closes its random/replay proof");
    }
    ok($evaluation->{claims}{axis_level_owned}
        && !$evaluation->{claims}{capability_claimed}
        && !$evaluation->{claims}{support_claimed}
        && !$evaluation->{claims}{performance_claimed}
        && !$evaluation->{claims}{capacity_claimed}
        && !$evaluation->{claims}{backend_authority}
        && !$evaluation->{claims}{runtime_authority},
        'random gate remains qualification-only without product claims');
    my $validated = $class->validate_evaluation({
        construction => $constructed,
        evaluation => $evaluation,
    });
    is($json->encode($validated), $json->encode($evaluation),
        'canonical random evaluation validates byte-for-byte');
};

subtest '65,536 occurrences are preflight dominated without materialization' => sub {
    my $constructed = construction('limit_v1');
    ok($constructed->{ok}, 'limit source remains inside every input envelope');
    my ($vial) = grep { $_->{role} eq 'vial_source' }
        @{$constructed->{inputs}};
    is(length($vial->{content}), 933_555,
        'limit source freezes the selected byte witness');
    my $evaluation = $class->evaluate({construction => $constructed});
    ok($evaluation->{ok}, 'preflight dominance is the selected outcome');
    is($evaluation->{status}, 'preflight_dominated',
        'limit has explicit preflight-dominated status');
    is($evaluation->{observed_outcome}, 'not_materialized',
        'limit explicitly denies materialization');
    is_deeply($evaluation->{stage_identities}, {
        semantic_ir_sha256 => undef,
        bridge_manifest_sha256 => undef,
        execution_ir_sha256 => undef,
        plan_sha256 => undef,
    }, 'preflight outcome carries no falsely materialized stage identity');
    is($evaluation->{metrics}{random_occurrences}, 0,
        'preflight outcome does not claim the nominal count was executed');
    is_deeply([map { $_->{code} } @{$evaluation->{contract_discrepancies}}],
        [qw(
            VIAL_SCALE_LIMIT_INTERACTION VIAL_SCALE_ROUTE_BOUNDARY
            VIAL_SCALE_PREFLIGHT_DOMINANCE
        )], 'limit retains exact interaction, boundary, and dominance records');
    my $built = eval { $class->build({construction => $constructed}); 1 };
    ok(!$built, 'public fixture build refuses preflight materialization');
    like($@, qr/preflight-dominated checking-state level is not materialized/,
        'build refusal names the selected bounded method');
};

subtest 'replay, report, source, and staging mutation fail closed' => sub {
    my $constructed = construction('gate_candidate_v1');
    my $original =
        \&FSM::VIAL::ArchitectureScaleCheckingState::_build_random_replay_execution;
    my $tampered;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleCheckingState::_build_random_replay_execution = sub {
            my $bundle = $original->(@_);
            my $value =
                $bundle->{execution}{plan}{random_decisions}[0]{value}{value_hex};
            $bundle->{execution}{plan}{random_decisions}[0]{value}{value_hex} =
                $value eq '0' ? '1' : '0';
            return $bundle;
        };
        $tampered = $class->evaluate({construction => $constructed});
    }
    ok(!$tampered->{ok}, 'replayed value mutation fails the exact oracle');
    is($tampered->{status}, 'oracle_failure',
        'replay mutation has oracle-failure status');
    is($tampered->{diagnostics}[0]{code},
        'VIAL_SCALE_CHECKING_RANDOM_ERROR',
        'replay mutation uses the stable random diagnostic');

    my $evaluation = $class->evaluate({construction => $constructed});
    my $mutated = clone_json($evaluation);
    ++$mutated->{oracle_evidence}{random_replay}{generated_decisions};
    my $accepted_report = eval {
        $class->validate_evaluation({
            construction => $constructed,
            evaluation => $mutated,
        });
        1;
    };
    ok(!$accepted_report, 'post-identity evidence mutation fails closed');
    like($@, qr/evaluation is not canonical/,
        'report mutation rejection names canonical regeneration');

    my $forged = clone_json($constructed);
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted_source = eval { $class->evaluate({construction => $forged}); 1 };
    ok(!$accepted_source, 'post-identity random source mutation fails closed');
    like($@, qr/construction is not canonical/,
        'source mutation rejection names canonical regeneration');

    my $stage_abs = repo_path($constructed->{staging_identity});
    ok(!-e $stage_abs && !-l $stage_abs, 'random stage begins absent');
    my $success = $class->with_staging({
        repository_root => $repo_root,
        construction => $constructed,
        consumer => sub {
            my ($context) = @_;
            ok(-d $context->{staging_root},
                'consumer sees the repository-volume random stage');
        },
    });
    ok($success->{ok} && $success->{same_volume} && $success->{removed},
        'successful random staging proves same-volume cleanup');
    my $failed = $class->with_staging({
        repository_root => $repo_root,
        construction => $constructed,
        consumer => sub { die "intentional random consumer failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure is reported');
    ok(!-e $stage_abs && !-l $stage_abs,
        'success and failure both leave no random-stage residue');
};

subtest 'high-count and adjacent route outcomes are exact and RAM-guarded' => sub {
    plan skip_all => 'set FSMGEN_VIAL_SCALE_EXACT=1 under'
        . ' scripts/run_with_ram_guard.sh for complete random route proof'
        unless $ENV{FSMGEN_VIAL_SCALE_EXACT};

    my $qualification = construction('qualification_candidate_v1');
    my ($qualification_source) = grep { $_->{role} eq 'vial_source' }
        @{$qualification->{inputs}};
    is(length($qualification_source->{content}), 470_412,
        '32,768 source byte witness is exact');
    my $qualification_evaluation =
        $class->evaluate({construction => $qualification});
    ok($qualification_evaluation->{ok},
        '32,768 full route reaches the selected plan rejection');
    is($qualification_evaluation->{status}, 'expected_rejection',
        '32,768 outcome is an expected rejection');
    is($qualification_evaluation->{metrics}{random_occurrences}, 32_768,
        'semantic route contains all 32,768 selected occurrences');
    is_deeply($qualification_evaluation->{diagnostics}, [plan_diagnostic()],
        '32,768 route returns only the exact plan diagnostic');

    my $limit = construction('over_limit_v1');
    my ($limit_source) = grep { $_->{role} eq 'vial_source' }
        @{$limit->{inputs}};
    is(length($limit_source->{content}), 933_642,
        '65,537 source byte witness is exact');
    my $limit_evaluation = $class->evaluate({construction => $limit});
    ok($limit_evaluation->{ok},
        '65,537 route reaches the selected occurrence rejection');
    is($limit_evaluation->{metrics}{random_occurrences}, 65_537,
        'semantic route contains the first excessive occurrence');
    is_deeply($limit_evaluation->{diagnostics}, [random_diagnostic()],
        '65,537 route returns only the exact occurrence diagnostic');

    my $accepted = $class->_test_random_route_boundary(
        $reference_hial, 8_440,
    );
    ok($accepted->{ok}, '8,440 route boundary is accepted deterministically');
    is($accepted->{random_occurrences}, 8_440,
        'accepted route contains every boundary occurrence');
    is($accepted->{serialized_plan_bytes}, 16_775_415,
        'accepted route freezes the exact sub-cap plan bytes');
    my $rejected = $class->_test_random_route_boundary(
        $reference_hial, 8_441,
    );
    ok($rejected->{ok}, '8,441 route boundary rejects deterministically');
    is($rejected->{random_occurrences}, 8_441,
        'rejected semantic route contains the adjacent occurrence');
    is_deeply($rejected->{diagnostics}, [plan_diagnostic()],
        'adjacent route returns only the exact plan diagnostic');
};

done_testing();

sub plan_diagnostic {
    return {
        bridge_fact_paths => [],
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        message => 'serialized_plan_bytes exceeds the limit 16777216',
        phase => 'limit',
        related => [],
        schema_version => 1,
        semantic_path => '/plan',
        severity => 'error',
        source_location => undef,
    };
}

sub random_diagnostic {
    return {
        bridge_fact_paths => [],
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        message => 'random_occurrences exceeds the limit 65536',
        phase => 'limit',
        related => [],
        schema_version => 1,
        semantic_path => '/randomness/decisions',
        severity => 'error',
        source_location => undef,
    };
}

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

sub clone_json {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

package FSM::VIAL::ArchitectureScaleCheckingState;

sub _test_random_route_boundary {
    my ($class, $reference_hial_text, $requested_count) = @_;
    return _evaluate_random_route_boundary(
        $reference_hial_text, $requested_count,
    );
}
