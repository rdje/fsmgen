#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleCalibrationClosure;

my $class = 'FSM::VIAL::ArchitectureScaleCalibrationClosure';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'closure contract rejects borrowed or caller-created evidence' => sub {
    is_deeply([sort @{$class->report_keys}], [sort qw(
        schema schema_version closure_identity authorities profiles summary
        candidate_formula outcome diagnostics explicit_nonclaims
    )], 'closure report has one closed public schema');
    my $nonclaims = $class->explicit_nonclaims;
    ok((grep { $_ eq 'promoted_performance_budget' } @$nonclaims),
        'candidate derivation does not promote a performance budget');
    ok((grep { $_ eq 'architecture_capacity' } @$nonclaims),
        'candidate derivation does not claim architecture capacity');

    like(dies(sub {
        FSM::VIAL::ArchitectureScaleCalibrationClosure::report_keys(
            'borrowed');
    }), qr/requires the exact class invocant/,
        'borrowed class invocants fail closed');
    like(dies(sub {
        $class->derive({
            repository_root => $repo_root,
            publications => [],
        });
    }), qr/unknown key 'publications'/,
        'callers cannot inject publication evidence');
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => {},
            authorities => [],
        });
    }), qr/unknown key 'authorities'/,
        'callers cannot inject authority evidence into validation');
};

subtest 'exact immutable family closure and hostile-input watcher' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_CALIBRATION_CLOSURE_EXACT=1 under scripts/run_with_ram_guard.sh'
        unless $ENV{FSMGEN_VIAL_SCALE_CALIBRATION_CLOSURE_EXACT};

    my $report = $class->derive({repository_root => $repo_root});
    is($report->{schema},
        'fsmgen.vial_architecture_scale_calibration_closure.v1',
        'derivation returns the selected closure schema');
    is(scalar(@{$report->{authorities}}), 7,
        'all seven independently sealed matrix authorities are present');
    is(scalar(@{$report->{profiles}}), 216,
        'producer inventory closes all 216 profile members');
    is($report->{summary}{raw_measurement_records}, 356,
        'closure preserves all 356 accepted raw measurement records');
    is($report->{summary}{excluded_measurement_records}, 0,
        'closure preserves the exact zero-exclusion result');
    cmp_ok($report->{summary}{candidate_profiles}, '>', 0,
        'applicable measured profiles receive candidate budgets');
    is($report->{outcome}, 'accepted', 'complete derivation is accepted');

    my ($candidate) = grep { defined $_->{candidate_budget} }
        @{$report->{profiles}};
    ok(defined($candidate), 'at least one candidate profile is visible');
    is_deeply([sort keys %{$candidate->{cost_statistics}}],
        [sort qw(fsmgen external_tool artifact)],
        'derived views keep FSMGen, external-tool, and artifact costs separate');
    cmp_ok($candidate->{candidate_budget}{wall_time_ns}, '>=', 2_000_000_000,
        'wall candidate applies the two-second floor');
    is($candidate->{candidate_budget}{wall_time_ns} % 1_000_000, 0,
        'wall candidate is rounded to an exact millisecond');
    is($candidate->{candidate_budget}{cpu_time_ns} % 1_000_000, 0,
        'CPU candidate is rounded to an exact millisecond');
    is($candidate->{candidate_budget}{peak_tree_rss_bytes} % 16_777_216, 0,
        'RSS candidate is rounded to an exact 16 MiB');

    my $validated = $class->validate_report({
        repository_root => $repo_root,
        report => $report,
    });
    is($validated->{closure_identity}, $report->{closure_identity},
        'independent reload reproduces the exact closure identity');

    my @mutations = (
        ['missing member', sub { pop @{$_[0]{profiles}} }],
        ['duplicate member', sub { push @{$_[0]{profiles}}, $_[0]{profiles}[0] }],
        ['reordered member', sub {
            @{$_[0]{profiles}}[0, 1] = @{$_[0]{profiles}}[1, 0];
        }],
        ['mutated statistic', sub {
            my ($profile) = grep { defined $_->{candidate_budget} }
                @{$_[0]{profiles}};
            $profile->{aggregate_statistics}{wall_time_ns}{maximum}++;
        }],
        ['mixed applicability identity', sub {
            $_[0]{profiles}[0]{applicability_identity} = 'forged';
        }],
        ['promoted candidate', sub {
            $_[0]{explicit_nonclaims} = [grep {
                $_ ne 'promoted_performance_budget'
            } @{$_[0]{explicit_nonclaims}}];
        }],
    );
    my $require_unchanged = $class->can('_require_unchanged_report');
    ok(defined($require_unchanged),
        'watcher exposes its private closed-report comparator to this test');
    for my $case (@mutations) {
        my ($name, $mutate) = @$case;
        my $copy = clone($report);
        $mutate->($copy);
        like(dies(sub {
            $require_unchanged->($copy, $report);
        }), qr/calibration closure changed from immutable derivation/,
            "$name fails closed");
    }
};

done_testing;

sub dies {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : "$@";
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}
