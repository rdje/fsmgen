#!/usr/bin/env perl

use strict;
use warnings;

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
my @axes = qw(
    bins_and_cross_tuples coverpoints faults model_instances
    random_occurrences scalar_model_state_cells scoreboard_capacity
    scoreboard_instances
);
my @selected_levels = qw(
    gate_candidate_v1 qualification_candidate_v1 limit_v1 over_limit_v1
);
my %oracle_for = (
    bins_and_cross_tuples => 'coverage',
    coverpoints => 'coverage',
    faults => 'faults',
    model_instances => 'model',
    random_occurrences => 'random_replay',
    scalar_model_state_cells => 'model',
    scoreboard_capacity => 'scoreboard',
    scoreboard_instances => 'scoreboard',
);
my %metric_for = (
    scoreboard_capacity => 'scoreboard_declared_capacity',
);

sub construction {
    my ($axis, $level) = @_;
    return $class->construct({
        primary_axis => $axis,
        level => $level,
        reference_hial_text => $reference_hial,
    });
}

subtest 'catalog partitions exactly into 32 owned and eight reference shapes' => sub {
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my $family = $catalog->{families}{checking_state_v1};
    is_deeply([sort keys %{$family->{axes}}], \@axes,
        'catalog contains exactly the eight checking-state axes');
    is_deeply($catalog->{levels}, [
        'reference_v1', @selected_levels,
    ], 'catalog contains the exact five-level ladder');

    my @expected_owned = map {
        my $axis = $_;
        map { "$axis/$_" } @selected_levels;
    } @axes;
    my @owned = map { "$_->{primary_axis}/$_->{level}" }
        @{$class->owned_shapes};
    is_deeply(\@owned, \@expected_owned,
        'published ownership is the exact 32-shape selected partition');

    my %owned = map { $_ => 1 } @owned;
    my @unowned;
    for my $axis (@axes) {
        for my $level (@{$catalog->{levels}}) {
            push @unowned, "$axis/$level" unless $owned{"$axis/$level"};
        }
    }
    is_deeply(\@unowned, [map { "$_/reference_v1" } @axes],
        'only the eight catalog reference records remain unowned');

    for my $axis (@axes) {
        my $accepted = eval { construction($axis, 'reference_v1'); 1 };
        ok(!$accepted, "$axis reference record fails closed");
        like($@, qr/reference_v1 remains a catalog record/,
            "$axis reference rejection names the catalog-only boundary");
    }
};

subtest 'all eight gates produce deterministic canonical reports and nonclaims' => sub {
    for my $axis (@axes) {
        subtest $axis => sub {
            my $first_construction = construction($axis, 'gate_candidate_v1');
            my $second_construction = construction($axis, 'gate_candidate_v1');
            ok($first_construction->{ok}, 'gate constructs ordinary source');
            is($json->encode($second_construction),
                $json->encode($first_construction),
                'independent construction is byte-identical');

            my $first = $class->evaluate({
                construction => $first_construction,
            });
            my $second = $class->evaluate({
                construction => $second_construction,
            });
            ok($first->{ok}, 'gate passes its provider-free oracle');
            diag($json->encode($first->{diagnostics})) unless $first->{ok};
            is($first->{status}, 'accepted', 'gate has accepted status');
            is($json->encode($second), $json->encode($first),
                'independent complete-route report is byte-identical');
            is($first->{oracle_evidence}{oracle}, $oracle_for{$axis},
                'gate selects exactly its axis oracle');
            my $metric = $metric_for{$axis} // $axis;
            is($first->{metrics}{$metric},
                $first->{requested_counts}{$axis},
                'gate claims exactly the catalog-selected count');
            is_deeply($first->{contract_discrepancies}, [],
                'gate has no higher-level limit discrepancy');
            ok($first->{claims}{qualification_only}
                && $first->{claims}{axis_level_owned}
                && !$first->{claims}{capability_claimed}
                && !$first->{claims}{support_claimed}
                && !$first->{claims}{performance_claimed}
                && !$first->{claims}{capacity_claimed}
                && !$first->{claims}{backend_authority}
                && !$first->{claims}{runtime_authority},
                'gate remains owned qualification evidence without product claims');
            is_deeply($first->{explicit_nonclaims},
                FSM::VIAL::ArchitectureScaleWorkload->catalog->{explicit_nonclaims},
                'gate retains every catalog nonclaim');

            my $validated = $class->validate_evaluation({
                construction => $first_construction,
                evaluation => $first,
            });
            is($json->encode($validated), $json->encode($first),
                'canonical report validates byte-for-byte');

            my $stage_abs = repo_path($first_construction->{staging_identity});
            ok(!-e $stage_abs && !-l $stage_abs, 'stage begins absent');
            my $staged = $class->with_staging({
                repository_root => $repo_root,
                construction => $first_construction,
                consumer => sub {
                    my ($context) = @_;
                    ok(-d $context->{staging_root},
                        'consumer sees the repository-volume stage');
                },
            });
            ok($staged->{ok} && $staged->{same_volume} && $staged->{removed},
                'successful staging is same-volume and removed exactly');
            ok(!-e $stage_abs && !-l $stage_abs,
                'successful staging leaves no axis residue');
        };
    }
};

subtest 'hostile callers and failed consumers cannot forge or strand evidence' => sub {
    my $unknown = eval {
        $class->construct({
            primary_axis => 'model_instances',
            level => 'gate_candidate_v1',
            reference_hial_text => $reference_hial,
            runtime_result => {},
        });
        1;
    };
    ok(!$unknown, 'caller-created runtime evidence cannot enter construction');
    like($@, qr/unknown key 'runtime_result'/,
        'closed construction names hostile metadata');

    for my $axis (@axes) {
        my $constructed = construction($axis, 'gate_candidate_v1');
        my $forged = clone_json($constructed);
        my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
        $vial->{content} .= ' ';
        my $accepted = eval { $class->evaluate({construction => $forged}); 1 };
        ok(!$accepted, "$axis post-identity source mutation fails closed");
        like($@, qr/construction is not canonical/,
            "$axis mutation rejection names canonical regeneration");
    }

    my $constructed = construction('random_occurrences', 'gate_candidate_v1');
    my $evaluation = $class->evaluate({construction => $constructed});
    my $forged_report = clone_json($evaluation);
    $forged_report->{claims}{support_claimed} = JSON::PP::true;
    my $validated = eval {
        $class->validate_evaluation({
            construction => $constructed,
            evaluation => $forged_report,
        });
        1;
    };
    ok(!$validated, 'post-identity support-claim mutation fails closed');
    like($@, qr/evaluation is not canonical/,
        'report mutation rejection names canonical regeneration');

    my $stage_abs = repo_path($constructed->{staging_identity});
    my $failed = $class->with_staging({
        repository_root => $repo_root,
        construction => $constructed,
        consumer => sub { die "intentional final-qualification failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure is reported');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure retains its stable diagnostic');
    ok(!-e $stage_abs && !-l $stage_abs,
        'failed consumer leaves no repository-volume residue');
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
