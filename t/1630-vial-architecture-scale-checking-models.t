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
my @accepted_levels = qw(
    gate_candidate_v1 qualification_candidate_v1 limit_v1
);
my %selected = (
    model_instances => {
        gate_candidate_v1 => 32,
        qualification_candidate_v1 => 1_024,
        limit_v1 => 4_096,
        over_limit_v1 => 4_097,
    },
    scalar_model_state_cells => {
        gate_candidate_v1 => 512,
        qualification_candidate_v1 => 32_768,
        limit_v1 => 65_536,
        over_limit_v1 => 65_537,
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

subtest 'gate model programs author and exercise every selected cell' => sub {
    my %expected = (
        model_instances => {
            cells => 32,
            evaluation =>
                'checking-evaluation/47829e33f266be0576f5aa9a476b16330bbcbd687b3597f9c2ddec7be6206e74',
            rerun =>
                'rerun/2a7bba2ee778c3f795e7216587b8223c25bee25cfa17e89662392f873de7f15e',
            initial =>
                '66687aadf862bd776c8fc18b8e9f8e20089714856ee233b3902a591d0d5f2925',
            final =>
                '72cd6e8422c407fb6d098690f1130b7ded7ec2f7f5e1d30bd9d521f015363793',
        },
        scalar_model_state_cells => {
            cells => 512,
            evaluation =>
                'checking-evaluation/41b08c0e4095c7f71a6337650bbc9d99722a2cedc73d05280b0d97fd89e3ead0',
            rerun =>
                'rerun/19d7e8c601c2701e9eedaba1b00d4beb6624c3bec6a191e7120ba017e088ec38',
            initial =>
                '076a27c79e5ace2a3d47f9dd2e83e4ff6ea8872b3c2218f66c92b89b55f36560',
            final =>
                '6caf38d537984e261527b8caef5f990fb91415a1db917198821a79ed28997973',
        },
    );
    for my $axis (sort keys %expected) {
        my $constructed = construction($axis, 'gate_candidate_v1');
        ok($constructed->{ok}, "$axis gate constructs ordinary source");
        check_scalar_source_factorization(
            'scalar_model_state_cells/gate_candidate_v1',
            $constructed, 32, 1, 16,
        ) if $axis eq 'scalar_model_state_cells';
        my $evaluation = $class->evaluate({construction => $constructed});
        ok($evaluation->{ok}, "$axis gate passes the provider-free oracle");
        diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
        is($evaluation->{status}, 'accepted', "$axis gate is accepted");
        is($evaluation->{observed_outcome}, 'accepted',
            "$axis gate records the exact accepted outcome");
        is($evaluation->{evaluation_identity}, $expected{$axis}{evaluation},
            "$axis gate evaluation identity is frozen");
        is($evaluation->{rerun_identity}, $expected{$axis}{rerun},
            "$axis gate independent-route identity is frozen");
        is($evaluation->{metrics}{$axis}, $selected{$axis}{gate_candidate_v1},
            "$axis gate reaches its exact requested count");

        my $model = $evaluation->{oracle_evidence}{model};
        is($evaluation->{oracle_evidence}{oracle}, 'model',
            "$axis uses only the model oracle");
        is($model->{program}, 'one_bound_event_occurrence_per_instance_v1',
            "$axis uses the closed event program");
        is($model->{scalar_state_cells}, $expected{$axis}{cells},
            "$axis authors every expected scalar cell");
        is($model->{packed_bytes}, $expected{$axis}{cells},
            "$axis packs every one-byte scalar cell");
        is($model->{cells_initialized}, $expected{$axis}{cells},
            "$axis initializes every cell");
        is($model->{cells_updated}, $expected{$axis}{cells},
            "$axis updates every cell");
        is($model->{cells_read}, $expected{$axis}{cells},
            "$axis reads every cell after commit");
        is($model->{trigger_occurrences}, $model->{model_instances},
            "$axis synthesizes one exact bound event per model instance");
        like($model->{trigger_event_id}, qr/::transaction_binding::write::event::accepted\z/,
            "$axis trigger is the canonical accepted event");
        is($model->{initial_state_sha256}, $expected{$axis}{initial},
            "$axis packed all-zero initial state is exact");
        is($model->{final_state_sha256}, $expected{$axis}{final},
            "$axis packed all-one final state is exact");
        is($model->{initial_state_sha256}, $model->{expected_initial_state_sha256},
            "$axis initial bytes match the independent expectation");
        is($model->{final_state_sha256}, $model->{expected_final_state_sha256},
            "$axis final bytes match the independent expectation");
        ok($model->{byte_equal_expected} && $model->{all_updates_committed}
            && $model->{all_reads_matched},
            "$axis closes byte equality, update, and read proofs");
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
        ++$mutated->{oracle_evidence}{model}{cells_read};
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

subtest 'adjacent model excesses return only the exact models diagnostic' => sub {
    for my $axis (sort keys %selected) {
        my $constructed = construction($axis, 'over_limit_v1');
        ok($constructed->{ok}, "$axis adjacent excess remains valid source");
        check_scalar_source_factorization(
            'scalar_model_state_cells/over_limit_v1',
            $constructed, 33, 2, 2_049,
        ) if $axis eq 'scalar_model_state_cells';
        my $evaluation = $class->evaluate({construction => $constructed});
        ok($evaluation->{ok}, "$axis adjacent excess is the selected expected outcome");
        diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
        is($evaluation->{status}, 'expected_rejection',
            "$axis excess has the exact expected-rejection status");
        is($evaluation->{observed_outcome}, 'rejected',
            "$axis excess records rejection");
        is(scalar(@{$evaluation->{diagnostics}}), 1,
            "$axis excess returns one diagnostic only");
        my ($resource, $limit) = $axis eq 'model_instances'
            ? ('model_instances', 4_096)
            : ('scalar_state_cells', 65_536);
        is_deeply($evaluation->{diagnostics}[0], {
            bridge_fact_paths => [],
            code => 'VIAL_EXECUTION_LIMIT_ERROR',
            message => "$resource exceeds the limit $limit",
            phase => 'limit',
            related => [],
            schema_version => 1,
            semantic_path => '/models',
            severity => 'error',
            source_location => undef,
        }, "$axis excess freezes the complete /models diagnostic");
        is($evaluation->{metrics}{$axis}, $selected{$axis}{over_limit_v1},
            "$axis semantic stage authors the exact adjacent excess");
        ok(!defined($evaluation->{stage_identities}{execution_ir_sha256})
            && !defined($evaluation->{stage_identities}{plan_sha256}),
            "$axis rejection exposes no downstream identity");
        is($evaluation->{oracle_evidence}{oracle}, 'none',
            "$axis rejected source cannot claim a state oracle ran");
        ok(!$evaluation->{outcome_contract}{axis_oracle_executed},
            "$axis rejected source reports no oracle execution");
        like($evaluation->{rerun_identity}, qr{\Arerun/[0-9a-f]{64}\z},
            "$axis rejection has a content-addressed rerun identity");
        my $validated = $class->validate_evaluation({
            construction => $constructed,
            evaluation => $evaluation,
        });
        is($json->encode($validated), $json->encode($evaluation),
            "$axis rejected evaluation validates byte-for-byte");
    }
};

subtest 'hostile unknown packed state is rejected inside the oracle' => sub {
    my $constructed = construction('model_instances', 'gate_candidate_v1');
    my $built = $class->build({construction => $constructed});
    ok($built->{ok}, 'canonical gate reaches ExecutionIR for hostile-state test');
    my $execution = $built->{execution_ir}->as_hashref;
    $execution->{models}[0]{definition}{rules}[0]{assignments}[0]
        {expression}{operands}[1]{value}{known_hex} = '00';
    my ($evidence, $diagnostics) = $class->_test_model_oracle(
        $constructed->{specification}, $execution,
    );
    ok(@$diagnostics, 'unknown-state mutation fails the provider-free oracle');
    is($diagnostics->[0]{code}, 'VIAL_SCALE_CHECKING_MODEL_ERROR',
        'unknown-state mutation uses the stable model-oracle diagnostic');
    like($diagnostics->[0]{message}, qr/exact known u8 zero-to-one transition/,
        'unknown-state rejection names the known-value contract');
    ok(!$evidence->{byte_equal_expected}
        && !$evidence->{all_updates_committed}
        && !$evidence->{all_reads_matched},
        'hostile-state evidence cannot claim equality, update, or read success');
};

subtest 'model construction and staging remain caller-sealed and residue-free' => sub {
    my $constructed = construction('model_instances', 'gate_candidate_v1');
    my $forged = clone_json($constructed);
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted_forgery = eval { $class->evaluate({construction => $forged}); 1 };
    ok(!$accepted_forgery, 'post-identity generated source mutation fails closed');
    like($@, qr/construction is not canonical/,
        'generated-source mutation rejection names canonical regeneration');

    my $stage_abs = repo_path($constructed->{staging_identity});
    ok(!-e $stage_abs && !-l $stage_abs,
        'model stage begins absent');
    my $success = $class->with_staging({
        repository_root => $repo_root,
        construction => $constructed,
        consumer => sub {
            my ($context) = @_;
            ok(-d $context->{staging_root},
                'consumer sees the repository-volume model stage');
        },
    });
    ok($success->{ok} && $success->{same_volume} && $success->{removed},
        'successful model staging proves same-volume cleanup');
    ok(!-e $stage_abs && !-l $stage_abs,
        'successful model staging leaves no residue');

    my $failed = $class->with_staging({
        repository_root => $repo_root,
        construction => $constructed,
        consumer => sub { die "intentional model consumer failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure is reported');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure keeps the stable diagnostic family');
    ok(!-e $stage_abs && !-l $stage_abs,
        'failed model staging also leaves no residue');
};

subtest 'qualification and limit levels are exact and RAM-guarded' => sub {
    plan skip_all => 'set FSMGEN_VIAL_SCALE_EXACT=1 under'
        . ' scripts/run_with_ram_guard.sh for complete model ladder proof'
        unless $ENV{FSMGEN_VIAL_SCALE_EXACT};

    for my $axis (sort keys %selected) {
        for my $level (qw(qualification_candidate_v1 limit_v1)) {
            my $constructed = construction($axis, $level);
            ok($constructed->{ok}, "$axis/$level constructs");
            my ($vial) = grep { $_->{role} eq 'vial_source' }
                @{$constructed->{inputs}};
            cmp_ok(length($vial->{content}), '<=', 1_114_112,
                "$axis/$level stays inside the construction envelope");
            if ($axis eq 'scalar_model_state_cells') {
                my %declared_cells = (
                    qualification_candidate_v1 => 1_024,
                    limit_v1 => 2_048,
                );
                check_scalar_source_factorization(
                    "$axis/$level", $constructed, 32, 1,
                    $declared_cells{$level},
                );
            }
            my $evaluation = $class->evaluate({construction => $constructed});
            ok($evaluation->{ok}, "$axis/$level passes its complete oracle");
            diag($json->encode($evaluation->{diagnostics}))
                unless $evaluation->{ok};
            is($evaluation->{metrics}{$axis}, $selected{$axis}{$level},
                "$axis/$level reaches the exact selected count");
            my $model = $evaluation->{oracle_evidence}{model};
            is($model->{cells_initialized}, $model->{scalar_state_cells},
                "$axis/$level initializes every cell");
            is($model->{cells_updated}, $model->{scalar_state_cells},
                "$axis/$level updates every cell");
            is($model->{cells_read}, $model->{scalar_state_cells},
                "$axis/$level reads every cell");
            is($model->{trigger_occurrences}, $model->{model_instances},
                "$axis/$level triggers every instance exactly once");
            is($model->{initial_state_sha256},
                $model->{expected_initial_state_sha256},
                "$axis/$level initial bytes match independently");
            is($model->{final_state_sha256},
                $model->{expected_final_state_sha256},
                "$axis/$level final bytes match independently");
            like($evaluation->{evaluation_identity},
                qr{\Achecking-evaluation/[0-9a-f]{64}\z},
                "$axis/$level evaluation is content-addressed");
            like($evaluation->{rerun_identity}, qr{\Arerun/[0-9a-f]{64}\z},
                "$axis/$level rerun is content-addressed");
        }
    }
};

done_testing();

sub check_scalar_source_factorization {
    my ($label, $constructed, $instances, $definitions, $declared_cells) = @_;
    my ($vial) = grep { $_->{role} eq 'vial_source' }
        @{$constructed->{inputs}};
    is(scalar(() = $vial->{content}
            =~ /\(model [^()[:space:]]+ \(inputs \(tick event\)\)/g),
        $definitions, "$label authors the exact shared-definition count");
    is(scalar(() = $vial->{content}
            =~ /\(model [^()[:space:]]+ [^()[:space:]]+ \(bind tick \(event write accepted\)/g),
        $instances, "$label authors the exact model-instance count");
    is(scalar(() = $vial->{content}
            =~ /\([^()[:space:]]+ \(u 8\) 0\)/g),
        $declared_cells, "$label authors the exact state declarations per definition set");
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

sub _test_model_oracle {
    my ($class, $specification, $execution_ir) = @_;
    return _evaluate_model_state($specification, $execution_ir);
}
