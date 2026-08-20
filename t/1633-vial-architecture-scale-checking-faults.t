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
my %selected = (
    gate_candidate_v1 => 32,
    qualification_candidate_v1 => 1_024,
    limit_v1 => 4_096,
    over_limit_v1 => 4_097,
);

sub construction {
    my ($level) = @_;
    return $class->construct({
        primary_axis => 'faults',
        level => $level,
        reference_hial_text => $reference_hial,
    });
}

subtest 'fault gate executes every complete lifecycle in declaration order' => sub {
    my $constructed = construction('gate_candidate_v1');
    ok($constructed->{ok}, 'fault gate constructs ordinary VIAL source');
    my ($vial) = grep { $_->{role} eq 'vial_source' }
        @{$constructed->{inputs}};
    is(length($vial->{content}), 5_650,
        'fault gate freezes its compact source size');

    my $evaluation = $class->evaluate({construction => $constructed});
    ok($evaluation->{ok}, 'fault gate passes the provider-free lifecycle oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'accepted', 'fault gate is accepted');
    is($evaluation->{evaluation_identity},
        'checking-evaluation/f28716141522379d0f9031b49024ef0460c224a17fa4e665a13c1bf8429e4d5f',
        'fault gate evaluation identity is frozen');
    is($evaluation->{rerun_identity},
        'rerun/1b0f85e5067dcc704c6c7673d23b4fa11c048275dfcffa57a1e7a69dcb5b0733',
        'fault gate independent-route identity is frozen');
    is($evaluation->{metrics}{faults}, 32,
        'fault gate reaches the selected metric');
    is($evaluation->{metrics}{serialized_plan_bytes}, 31_817,
        'fault gate freezes its genuine serialized plan size');

    my $faults = $evaluation->{oracle_evidence}{faults};
    is($evaluation->{oracle_evidence}{oracle}, 'faults',
        'gate uses only the fault oracle');
    is($faults->{schema},
        'fsmgen.vial_architecture_scale_fault_oracle_evidence.v1',
        'gate uses the closed fault-evidence schema');
    is($faults->{program}, 'arm_apply_expire_restore_each_fault_v1',
        'gate executes the selected lifecycle program');
    is($faults->{target_transaction_id},
        'architecture_scale_checking_state::transaction::ahb_write',
        'every fault preserves the authored transaction target');
    is($faults->{target_field_name}, 'size',
        'every fault preserves the authored field target');
    is($faults->{duration_drive_intervals}, 1,
        'every fault has the one-interval lifetime');
    is($faults->{original_value_hex}, '2',
        'the synthetic transaction starts with the frozen original value');
    is($faults->{substitute_value_hex}, '7',
        'the active fault substitutes the frozen value');
    for my $metric (qw(
        faults faults_armed faults_applied faults_expired faults_restored
    )) {
        is($faults->{$metric}, 32, "$metric accounts for every fault");
    }
    is($faults->{state_transition_records}, 128,
        'each fault contributes exactly four streamed transition records');
    is($faults->{declaration_order_sha256},
        'e8fcc8da4abf9371348906ba212cf5e588cc9b9696fa472ef4227832e424a8e1',
        'gate declaration-order digest is frozen');
    is($faults->{declaration_order_sha256},
        $faults->{expected_declaration_order_sha256},
        'gate declaration order matches independent reconstruction');
    is($faults->{transition_sha256},
        '2ca24c7e9b401d7df1b30ac42994ef54a6bacf043d241dd2641731657c0106ac',
        'gate lifecycle-transition digest is frozen');
    is($faults->{transition_sha256}, $faults->{expected_transition_sha256},
        'gate lifecycle stream matches independent reconstruction');
    is($faults->{first_arm_identity},
        'fault-transition/9aaefd395fe6757b56494f1c9e0847d36a6050c22ebd531b26a8aed052029583',
        'first arm transition has a stable endpoint witness');
    is($faults->{last_restore_identity},
        'fault-transition/f33454dbdded2f567abf6238eab175c94918fc2faa177ccbf3caf3f6ce468b41',
        'last restoration has a stable endpoint witness');

    for my $proof (qw(
        target_identity_preserved original_values_matched
        substituted_values_matched restoration_values_matched
        stable_order_preserved all_faults_armed all_faults_applied
        all_faults_expired all_faults_restored reinjection_rejected
        overlap_rejected mutation_rejected order_mutation_rejected
    )) {
        ok($faults->{$proof}, "$proof closes its fault proof");
    }
    ok($evaluation->{claims}{axis_level_owned}
        && !$evaluation->{claims}{capability_claimed}
        && !$evaluation->{claims}{support_claimed}
        && !$evaluation->{claims}{performance_claimed}
        && !$evaluation->{claims}{capacity_claimed}
        && !$evaluation->{claims}{backend_authority}
        && !$evaluation->{claims}{runtime_authority},
        'fault gate remains qualification-only without product claims');
    my $validated = $class->validate_evaluation({
        construction => $constructed,
        evaluation => $evaluation,
    });
    is($json->encode($validated), $json->encode($evaluation),
        'canonical fault evaluation validates byte-for-byte');
};

subtest 'one further fault returns only the execution limit diagnostic' => sub {
    my $constructed = construction('over_limit_v1');
    ok($constructed->{ok}, 'one-over fault source is admitted');
    my ($vial) = grep { $_->{role} eq 'vial_source' }
        @{$constructed->{inputs}};
    is(length($vial->{content}), 591_010,
        'one-over source freezes its exact byte witness');
    my $evaluation = $class->evaluate({construction => $constructed});
    ok($evaluation->{ok}, 'one-over outcome is the selected rejection');
    is($evaluation->{status}, 'expected_rejection',
        'one-over fault count has expected-rejection status');
    is_deeply($evaluation->{diagnostics}, [{
        bridge_fact_paths => [],
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        message => 'faults exceeds the limit 4096',
        phase => 'limit',
        related => [],
        schema_version => 1,
        semantic_path => '/faults',
        severity => 'error',
        source_location => undef,
    }], 'one-over freezes the complete sole /faults diagnostic');
    is($evaluation->{metrics}{faults}, 4_097,
        'semantic stage contains exactly one further fault');
    ok(defined($evaluation->{stage_identities}{semantic_ir_sha256})
        && defined($evaluation->{stage_identities}{bridge_manifest_sha256})
        && !defined($evaluation->{stage_identities}{execution_ir_sha256})
        && !defined($evaluation->{stage_identities}{plan_sha256}),
        'rejection exposes only SemanticIR and bridge identities');
    is($evaluation->{oracle_evidence}{oracle}, 'none',
        'rejected fault count cannot claim the lifecycle oracle ran');
};

subtest 'hostile fault structure and report mutation fail closed' => sub {
    my $constructed = construction('gate_candidate_v1');
    my $built = $class->build({construction => $constructed});
    ok($built->{ok}, 'canonical gate reaches ExecutionIR for hostile-state proof');
    my $execution = $built->{execution_ir}->as_hashref;
    $execution->{faults}[0]{substitute}{value}{value_hex} = '6';
    my ($evidence, $diagnostics) = $class->_test_fault_oracle(
        $constructed->{specification}, $execution,
    );
    ok(@$diagnostics, 'substitution mutation fails the provider-free oracle');
    is($diagnostics->[0]{code}, 'VIAL_SCALE_CHECKING_FAULT_ERROR',
        'hostile mutation uses the stable fault diagnostic');
    like($diagnostics->[0]{message},
        qr/exact declared target, substitution, and lifetime/,
        'hostile rejection names the authored fault structure');
    ok(!$evidence->{target_identity_preserved}
        && !$evidence->{substituted_values_matched}
        && !$evidence->{stable_order_preserved}
        && !$evidence->{all_faults_restored},
        'hostile evidence cannot claim positive lifecycle proof');

    my $evaluation = $class->evaluate({construction => $constructed});
    my $mutated = clone_json($evaluation);
    ++$mutated->{oracle_evidence}{faults}{faults_applied};
    my $accepted = eval {
        $class->validate_evaluation({
            construction => $constructed,
            evaluation => $mutated,
        });
        1;
    };
    ok(!$accepted, 'post-identity lifecycle mutation fails closed');
    like($@, qr/evaluation is not canonical/,
        'report mutation rejection names canonical regeneration');
};

subtest 'fault construction and staging remain sealed and residue-free' => sub {
    my $constructed = construction('gate_candidate_v1');
    my $forged = clone_json($constructed);
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted_forgery = eval { $class->evaluate({construction => $forged}); 1 };
    ok(!$accepted_forgery, 'post-identity generated source mutation fails closed');
    like($@, qr/construction is not canonical/,
        'generated-source mutation rejection names canonical regeneration');

    my $stage_abs = repo_path($constructed->{staging_identity});
    ok(!-e $stage_abs && !-l $stage_abs, 'fault stage begins absent');
    my $success = $class->with_staging({
        repository_root => $repo_root,
        construction => $constructed,
        consumer => sub {
            my ($context) = @_;
            ok(-d $context->{staging_root},
                'consumer sees the repository-volume fault stage');
        },
    });
    ok($success->{ok} && $success->{same_volume} && $success->{removed},
        'successful fault staging proves same-volume cleanup');
    ok(!-e $stage_abs && !-l $stage_abs,
        'successful fault staging leaves no residue');
    my $failed = $class->with_staging({
        repository_root => $repo_root,
        construction => $constructed,
        consumer => sub { die "intentional fault consumer failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure is reported');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure keeps the stable diagnostic family');
    ok(!-e $stage_abs && !-l $stage_abs,
        'failed fault staging also leaves no residue');
};

subtest 'qualification and limit fault ladders are exact and RAM-guarded' => sub {
    plan skip_all => 'set FSMGEN_VIAL_SCALE_EXACT=1 under'
        . ' scripts/run_with_ram_guard.sh for complete fault route proof'
        unless $ENV{FSMGEN_VIAL_SCALE_EXACT};

    my %expected = (
        qualification_candidate_v1 => {
            source_bytes => 148_498,
            evaluation =>
                'checking-evaluation/d6da13b8cceee07dc8b66e0b729cac3f51c68b57375e685fe9035f940fd98052',
            rerun =>
                'rerun/666aca26581292803e254020095eb522ba6c696d21b474897b679728b49f8efa',
            declaration =>
                '7a4283b79fcba71cdf25a25a27240ae12828252674b4f05a734405b7af970539',
            transition =>
                '68cdee53e7da06ac0412f5dacf1d894f281ad2d6ee8f718dc5be97c38480200a',
        },
        limit_v1 => {
            source_bytes => 590_866,
            evaluation =>
                'checking-evaluation/7d6f1fa6897a20efff72f021a67d858899d54258915220a96124213c82f7c424',
            rerun =>
                'rerun/3ccc7d2ca2acbd0f6b77b447a867989b78895655d990ca66ae72af5813ebd140',
            declaration =>
                'f6765f251106df0e55ff214877918bfb5e8e59ff73136c34ded65568c18f94e0',
            transition =>
                '4042b666fd911ef3b7d39fe6abeb721c96ade2f322461f3845558ddf1e648dc9',
        },
    );
    for my $level (qw(qualification_candidate_v1 limit_v1)) {
        my $count = $selected{$level};
        my $constructed = construction($level);
        ok($constructed->{ok}, "$level constructs ordinary VIAL source");
        my ($vial) = grep { $_->{role} eq 'vial_source' }
            @{$constructed->{inputs}};
        is(length($vial->{content}), $expected{$level}{source_bytes},
            "$level source byte witness is exact");
        my $evaluation = $class->evaluate({construction => $constructed});
        ok($evaluation->{ok}, "$level passes its exact lifecycle oracle");
        diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
        is($evaluation->{evaluation_identity}, $expected{$level}{evaluation},
            "$level evaluation identity is frozen");
        is($evaluation->{rerun_identity}, $expected{$level}{rerun},
            "$level independent-route identity is frozen");
        is($evaluation->{metrics}{faults}, $count,
            "$level reaches its selected count");
        my $faults = $evaluation->{oracle_evidence}{faults};
        is($faults->{state_transition_records}, 4 * $count,
            "$level streams four lifecycle transitions per fault");
        is($faults->{declaration_order_sha256},
            $expected{$level}{declaration},
            "$level declaration-order digest is frozen");
        is($faults->{transition_sha256}, $expected{$level}{transition},
            "$level lifecycle-transition digest is frozen");
        ok($faults->{all_faults_armed}
            && $faults->{all_faults_applied}
            && $faults->{all_faults_expired}
            && $faults->{all_faults_restored}
            && $faults->{reinjection_rejected}
            && $faults->{overlap_rejected},
            "$level closes every lifecycle and reinjection proof");
    }
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

sub clone_json {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

package FSM::VIAL::ArchitectureScaleCheckingState;

sub _test_fault_oracle {
    my ($class, $specification, $execution_ir) = @_;
    return _evaluate_fault_state($specification, $execution_ir);
}
