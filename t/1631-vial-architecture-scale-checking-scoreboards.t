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
    scoreboard_instances => {
        gate_candidate_v1 => 32,
        qualification_candidate_v1 => 1_024,
        limit_v1 => 4_096,
        over_limit_v1 => 4_097,
    },
    scoreboard_capacity => {
        gate_candidate_v1 => 4_096,
        qualification_candidate_v1 => 262_144,
        limit_v1 => 1_000_000,
        over_limit_v1 => 1_000_001,
    },
);

sub construction {
    my ($axis, $level) = @_;
    return $class->construct({
        primary_axis => $axis,
        level => $level,
        reference_hial_text => $reference_hial,
    });
}

subtest 'gate scoreboards compare complete transactions and drain exactly' => sub {
    my %expected = (
        scoreboard_instances => {
            instances => 32,
            capacity => 32,
            packed_bytes => 128,
            source_bytes => 6_404,
            payload_sha256 =>
                '4be2dacd2b764ab9391ca9943b0ab077ba8dbebf715d941f2788404e35bb46ab',
            evaluation =>
                'checking-evaluation/fa874264dd49f8c2e1605e6a8b6323a4b0145518e7ce7283410503aa31af6a2b',
            rerun =>
                'rerun/24dfd3967af51b5046206c6fbef8da5acad099bee3c136d898f134b6839074e2',
            maximum_expected_depth => 1,
            last_payload_hex => '0000001f',
        },
        scoreboard_capacity => {
            instances => 1,
            capacity => 4_096,
            packed_bytes => 16_384,
            source_bytes => 1_351,
            payload_sha256 =>
                'f3641a1e67168de9eab1170abc1f5c75d75bd7720ea7f57b7b065c17cafc8745',
            evaluation =>
                'checking-evaluation/c972275e8901d2429d927da7c4787137b34435d6d1aa20635620b1667e8da87a',
            rerun =>
                'rerun/9c22d0bbb479cb0d9c3169bbe27ee62edeab5d360b23a0286211c46b7b88b7d8',
            maximum_expected_depth => 4_096,
            last_payload_hex => '00000fff',
        },
    );

    for my $axis (sort keys %expected) {
        my $constructed = construction($axis, 'gate_candidate_v1');
        ok($constructed->{ok}, "$axis gate constructs ordinary VIAL source");
        my ($vial) = grep { $_->{role} eq 'vial_source' }
            @{$constructed->{inputs}};
        is(length($vial->{content}), $expected{$axis}{source_bytes},
            "$axis gate freezes the compact source size");

        my $evaluation = $class->evaluate({construction => $constructed});
        ok($evaluation->{ok}, "$axis gate passes the packed FIFO oracle");
        diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
        is($evaluation->{status}, 'accepted', "$axis gate is accepted");
        is($evaluation->{observed_outcome}, 'accepted',
            "$axis gate records the exact accepted outcome");
        is($evaluation->{evaluation_identity}, $expected{$axis}{evaluation},
            "$axis gate evaluation identity is frozen");
        is($evaluation->{rerun_identity}, $expected{$axis}{rerun},
            "$axis gate independent-route identity is frozen");
        my $metric = $axis eq 'scoreboard_capacity'
            ? 'scoreboard_declared_capacity' : $axis;
        is($evaluation->{metrics}{$metric}, $selected{$axis}{gate_candidate_v1},
            "$axis gate reaches its exact selected count");

        my $scoreboard = $evaluation->{oracle_evidence}{scoreboard};
        is($evaluation->{oracle_evidence}{oracle}, 'scoreboard',
            "$axis uses only the scoreboard oracle");
        is($scoreboard->{schema},
            'fsmgen.vial_architecture_scale_scoreboard_oracle_evidence.v1',
            "$axis publishes the closed scoreboard evidence schema");
        is($scoreboard->{program}, 'packed_complete_transaction_fifo_v1',
            "$axis uses the closed packed FIFO program");
        is($scoreboard->{scoreboard_instances},
            $expected{$axis}{instances},
            "$axis reaches every selected scoreboard instance");
        is($scoreboard->{scoreboard_definitions}, 1,
            "$axis reuses one authored scoreboard definition");
        is($scoreboard->{declared_capacity}, $expected{$axis}{capacity},
            "$axis reaches the exact aggregate declared capacity");
        for my $count (qw(
            transactions_enqueued transactions_observed
            transactions_matched transactions_drained
        )) {
            is($scoreboard->{$count}, $expected{$axis}{capacity},
                "$axis $count covers every selected entry");
        }
        is($scoreboard->{fields_per_transaction}, 6,
            "$axis compares the complete six-field AHB transaction");
        is($scoreboard->{complete_field_comparisons},
            $expected{$axis}{capacity} * 6,
            "$axis compares every field of every transaction");
        is($scoreboard->{packed_payload_bytes},
            $expected{$axis}{packed_bytes},
            "$axis stores exactly four varying bytes per entry");
        is($scoreboard->{packed_payload_sha256},
            $expected{$axis}{payload_sha256},
            "$axis packed payload digest is frozen");
        is($scoreboard->{expected_payload_sha256},
            $scoreboard->{packed_payload_sha256},
            "$axis packed FIFO bytes match the independent expectation");
        is($scoreboard->{maximum_total_expected_depth},
            $expected{$axis}{capacity},
            "$axis reaches the selected aggregate expected depth");
        is($scoreboard->{maximum_expected_depth},
            $expected{$axis}{maximum_expected_depth},
            "$axis reaches the selected per-instance expected depth");
        is($scoreboard->{maximum_actual_depth}, 1,
            "$axis observes and drains one actual transaction at a time");
        is($scoreboard->{final_expected_depth}, 0,
            "$axis expected queue drains to zero");
        is($scoreboard->{final_actual_depth}, 0,
            "$axis actual queue drains to zero");
        is($scoreboard->{pending_entries}, 0,
            "$axis leaves no pending scoreboard entries");
        is($scoreboard->{first_payload_hex}, '00000000',
            "$axis begins with the exact zero payload");
        is($scoreboard->{last_payload_hex},
            $expected{$axis}{last_payload_hex},
            "$axis ends with the exact selected payload");
        like($scoreboard->{first_transaction_identity},
            qr{\Ascoreboard-transaction/[0-9a-f]{64}\z},
            "$axis first complete transaction is content-addressed");
        like($scoreboard->{last_transaction_identity},
            qr{\Ascoreboard-transaction/[0-9a-f]{64}\z},
            "$axis last complete transaction is content-addressed");
        ok($scoreboard->{fifo_order_preserved}
            && $scoreboard->{complete_transactions_equal}
            && $scoreboard->{all_instances_drained}
            && $scoreboard->{mismatch_rejected}
            && $scoreboard->{overflow_rejected}
            && $scoreboard->{corruption_rejected},
            "$axis closes equality, drain, mismatch, overflow, and corruption proofs");
        ok($evaluation->{claims}{axis_level_owned},
            "$axis gate is owned without making a product claim");
        ok(!$evaluation->{claims}{capability_claimed}
            && !$evaluation->{claims}{support_claimed}
            && !$evaluation->{claims}{performance_claimed}
            && !$evaluation->{claims}{capacity_claimed}
            && !$evaluation->{claims}{backend_authority}
            && !$evaluation->{claims}{runtime_authority},
            "$axis keeps every public/backend/runtime claim false");

        my $validated = $class->validate_evaluation({
            construction => $constructed,
            evaluation => $evaluation,
        });
        is($json->encode($validated), $json->encode($evaluation),
            "$axis canonical evaluation validates byte-for-byte");

        my $mutated = clone_json($evaluation);
        ++$mutated->{oracle_evidence}{scoreboard}{transactions_drained};
        my $accepted_mutation = eval {
            $class->validate_evaluation({
                construction => $constructed,
                evaluation => $mutated,
            });
            1;
        };
        ok(!$accepted_mutation, "$axis rejects post-identity oracle mutation");
        like($@, qr/evaluation is not canonical/,
            "$axis mutation rejection names canonical regeneration");
    }
};

subtest 'one-million-entry capacity uses bounded packed state and drains' => sub {
    my $constructed = construction('scoreboard_capacity', 'limit_v1');
    ok($constructed->{ok}, 'capacity limit constructs ordinary source');
    my ($vial) = grep { $_->{role} eq 'vial_source' }
        @{$constructed->{inputs}};
    is(length($vial->{content}), 1_354,
        'one-million-entry capacity remains a compact source recipe');
    my $evaluation = $class->evaluate({construction => $constructed});
    ok($evaluation->{ok}, 'one-million-entry packed FIFO proof passes');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{evaluation_identity},
        'checking-evaluation/c2f05c948034403fe322a26d2119b7cd4912b795360b3b78ae3bfa239cfb048f',
        'capacity-limit evaluation identity is frozen');
    is($evaluation->{rerun_identity},
        'rerun/2287f5ed349d34895f0db36f28d1c223a55eab938531061827ec91094fe1e90a',
        'capacity-limit independent-route identity is frozen');
    my $scoreboard = $evaluation->{oracle_evidence}{scoreboard};
    is($scoreboard->{declared_capacity}, 1_000_000,
        'oracle reaches the exact one-million-entry capacity');
    is($scoreboard->{transactions_drained}, 1_000_000,
        'oracle drains every one-million-entry transaction');
    is($scoreboard->{complete_field_comparisons}, 6_000_000,
        'oracle compares all six million complete-transaction fields');
    is($scoreboard->{packed_payload_bytes}, 4_000_000,
        'one million entries occupy exactly four million varying bytes');
    is($scoreboard->{packed_payload_sha256},
        'a515ca39768fa0e597911d6564fa44f9163ecf81559ecc776c16f751f29b2b65',
        'one-million-entry packed payload digest is frozen');
    is($scoreboard->{packed_payload_sha256},
        $scoreboard->{expected_payload_sha256},
        'one-million-entry packed bytes match independently');
    is($scoreboard->{last_payload_hex}, '000f423f',
        'one-million-entry proof ends at payload ordinal 999999');
    is($scoreboard->{pending_entries}, 0,
        'one-million-entry proof drains to zero pending entries');
    ok($scoreboard->{fifo_order_preserved}
        && $scoreboard->{complete_transactions_equal}
        && $scoreboard->{all_instances_drained},
        'one-million-entry proof preserves FIFO order and complete equality');
};

subtest 'adjacent scoreboard excesses return only their exact diagnostics' => sub {
    my %expected = (
        scoreboard_instances => {
            diagnostic => {
                bridge_fact_paths => [],
                code => 'VIAL_EXECUTION_LIMIT_ERROR',
                message => 'scoreboard_instances exceeds the limit 4096',
                phase => 'limit',
                related => [],
                schema_version => 1,
                semantic_path => '/scoreboards',
                severity => 'error',
                source_location => undef,
            },
            stages => [qw(semantic bridge)],
        },
        scoreboard_capacity => {
            diagnostic => {
                code => 'VIAL_LIMIT_ERROR',
                message =>
                    'integer is outside the bounded range 1 through 1000000',
                notes => [],
                phase => 'limit',
                schema_version => 1,
                semantic_path => '/packages/0/scoreboards/0/capacity',
                severity => 'error',
                source_location => {
                    source_name =>
                        'generated/vial-scale/checking_state/checking_state.vial',
                    start_byte => 573,
                    end_byte_exclusive => 580,
                    start_line => 1,
                    end_line => 1,
                    start_column => 574,
                    end_column => 580,
                },
            },
            stages => [],
        },
    );

    for my $axis (sort keys %expected) {
        my $constructed = construction($axis, 'over_limit_v1');
        ok($constructed->{ok}, "$axis adjacent excess has a sealed source recipe");
        my $evaluation = $class->evaluate({construction => $constructed});
        ok($evaluation->{ok}, "$axis adjacent excess is the selected rejection");
        diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
        is($evaluation->{status}, 'expected_rejection',
            "$axis excess has exact expected-rejection status");
        is($evaluation->{observed_outcome}, 'rejected',
            "$axis excess records rejection");
        is_deeply($evaluation->{diagnostics},
            [$expected{$axis}{diagnostic}],
            "$axis excess freezes its complete single diagnostic");
        my $metric = $axis eq 'scoreboard_capacity'
            ? 'scoreboard_declared_capacity' : $axis;
        is($evaluation->{metrics}{$metric}, $selected{$axis}{over_limit_v1},
            "$axis recipe records the exact adjacent excess");
        is_deeply($evaluation->{outcome_contract}{canonical_stages_completed},
            $expected{$axis}{stages},
            "$axis exposes only the canonical stages reached before rejection");
        ok(!defined($evaluation->{stage_identities}{execution_ir_sha256})
            && !defined($evaluation->{stage_identities}{plan_sha256}),
            "$axis rejection exposes no downstream identity");
        is(defined($evaluation->{stage_identities}{semantic_ir_sha256}) ? 1 : 0,
            $axis eq 'scoreboard_instances' ? 1 : 0,
            "$axis semantic identity presence matches its rejection layer");
        is(defined($evaluation->{stage_identities}{bridge_manifest_sha256}) ? 1 : 0,
            $axis eq 'scoreboard_instances' ? 1 : 0,
            "$axis bridge identity presence matches its rejection layer");
        is($evaluation->{oracle_evidence}{oracle}, 'none',
            "$axis rejected source cannot claim a FIFO oracle ran");
        ok(!$evaluation->{outcome_contract}{axis_oracle_executed},
            "$axis rejected source reports no oracle execution");
        my $validated = $class->validate_evaluation({
            construction => $constructed,
            evaluation => $evaluation,
        });
        is($json->encode($validated), $json->encode($evaluation),
            "$axis rejected evaluation validates byte-for-byte");
    }
};

subtest 'hostile scoreboard structure is rejected inside the oracle' => sub {
    my $constructed = construction('scoreboard_capacity', 'gate_candidate_v1');
    my $built = $class->build({construction => $constructed});
    ok($built->{ok}, 'canonical gate reaches ExecutionIR for hostile-state test');
    my $execution = $built->{execution_ir}->as_hashref;
    $execution->{scoreboards}[0]{definition}{policy} = 'keyed';
    my ($evidence, $diagnostics) = $class->_test_scoreboard_oracle(
        $constructed->{specification}, $execution,
    );
    ok(@$diagnostics, 'hostile policy mutation fails the provider-free oracle');
    is($diagnostics->[0]{code}, 'VIAL_SCALE_CHECKING_SCOREBOARD_ERROR',
        'hostile mutation uses the stable scoreboard-oracle diagnostic');
    like($diagnostics->[0]{message}, qr/exact selected in-order definition/,
        'hostile mutation rejection names the selected in-order contract');
    ok(!$evidence->{fifo_order_preserved}
        && !$evidence->{complete_transactions_equal}
        && !$evidence->{all_instances_drained}
        && !$evidence->{mismatch_rejected}
        && !$evidence->{overflow_rejected}
        && !$evidence->{corruption_rejected},
        'hostile evidence cannot claim any positive scoreboard proof');

    my $instance_construction =
        construction('scoreboard_instances', 'gate_candidate_v1');
    my $instance_build = $class->build({
        construction => $instance_construction,
    });
    my $instance_execution = $instance_build->{execution_ir}->as_hashref;
    $instance_execution->{scoreboards}[1]{instance_id} =
        $instance_execution->{scoreboards}[0]{instance_id};
    my ($instance_evidence, $instance_diagnostics) =
        $class->_test_scoreboard_oracle(
            $instance_construction->{specification}, $instance_execution,
        );
    ok(@$instance_diagnostics,
        'duplicate instance identity fails the per-instance drain oracle');
    like($instance_diagnostics->[0]{message}, qr/distinct nonempty canonical/,
        'duplicate identity rejection names the per-instance identity contract');
    ok(!$instance_evidence->{all_instances_drained},
        'duplicate instance identity cannot claim every instance drained');
};

subtest 'scoreboard construction and staging remain caller-sealed and clean' => sub {
    my $constructed = construction('scoreboard_instances', 'gate_candidate_v1');
    my $forged = clone_json($constructed);
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted_forgery = eval { $class->evaluate({construction => $forged}); 1 };
    ok(!$accepted_forgery, 'post-identity generated source mutation fails closed');
    like($@, qr/construction is not canonical/,
        'generated-source mutation rejection names canonical regeneration');

    my $stage_abs = repo_path($constructed->{staging_identity});
    ok(!-e $stage_abs && !-l $stage_abs,
        'scoreboard stage begins absent');
    my $success = $class->with_staging({
        repository_root => $repo_root,
        construction => $constructed,
        consumer => sub {
            my ($context) = @_;
            ok(-d $context->{staging_root},
                'consumer sees the repository-volume scoreboard stage');
        },
    });
    ok($success->{ok} && $success->{same_volume} && $success->{removed},
        'successful scoreboard staging proves same-volume cleanup');
    ok(!-e $stage_abs && !-l $stage_abs,
        'successful scoreboard staging leaves no residue');

    my $failed = $class->with_staging({
        repository_root => $repo_root,
        construction => $constructed,
        consumer => sub { die "intentional scoreboard consumer failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure is reported');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure keeps the stable diagnostic family');
    ok(!-e $stage_abs && !-l $stage_abs,
        'failed scoreboard staging also leaves no residue');
};

subtest 'qualification and instance-limit levels are exact and RAM-guarded' => sub {
    plan skip_all => 'set FSMGEN_VIAL_SCALE_EXACT=1 under'
        . ' scripts/run_with_ram_guard.sh for the complete scoreboard ladder proof'
        unless $ENV{FSMGEN_VIAL_SCALE_EXACT};

    my @shapes = (
        [scoreboard_instances => 'qualification_candidate_v1'],
        [scoreboard_instances => 'limit_v1'],
        [scoreboard_capacity => 'qualification_candidate_v1'],
    );
    for my $shape (@shapes) {
        my ($axis, $level) = @$shape;
        my $constructed = construction($axis, $level);
        ok($constructed->{ok}, "$axis/$level constructs");
        my ($vial) = grep { $_->{role} eq 'vial_source' }
            @{$constructed->{inputs}};
        cmp_ok(length($vial->{content}), '<=', 1_114_112,
            "$axis/$level stays inside the construction envelope");
        my $evaluation = $class->evaluate({construction => $constructed});
        ok($evaluation->{ok}, "$axis/$level passes its complete FIFO oracle");
        diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
        my $metric = $axis eq 'scoreboard_capacity'
            ? 'scoreboard_declared_capacity' : $axis;
        is($evaluation->{metrics}{$metric}, $selected{$axis}{$level},
            "$axis/$level reaches the exact selected count");
        my $scoreboard = $evaluation->{oracle_evidence}{scoreboard};
        is($scoreboard->{transactions_enqueued},
            $scoreboard->{declared_capacity},
            "$axis/$level enqueues every selected entry");
        is($scoreboard->{transactions_matched},
            $scoreboard->{declared_capacity},
            "$axis/$level matches every selected entry");
        is($scoreboard->{transactions_drained},
            $scoreboard->{declared_capacity},
            "$axis/$level drains every selected entry");
        is($scoreboard->{packed_payload_bytes},
            $scoreboard->{declared_capacity} * 4,
            "$axis/$level uses exactly four varying bytes per entry");
        is($scoreboard->{packed_payload_sha256},
            $scoreboard->{expected_payload_sha256},
            "$axis/$level packed FIFO bytes match independently");
        is($scoreboard->{pending_entries}, 0,
            "$axis/$level leaves no pending entries");
        ok($scoreboard->{fifo_order_preserved}
            && $scoreboard->{complete_transactions_equal}
            && $scoreboard->{all_instances_drained},
            "$axis/$level closes FIFO order, equality, and drain proofs");
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

sub _test_scoreboard_oracle {
    my ($class, $specification, $execution_ir) = @_;
    return _evaluate_scoreboard_state($specification, $execution_ir);
}
