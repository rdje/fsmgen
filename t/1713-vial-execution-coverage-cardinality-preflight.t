#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleCheckingState;
use FSM::VIAL::ExecutionBuilder;

my $class = 'FSM::VIAL::ArchitectureScaleCheckingState';
my $json = JSON::PP->new->canonical(1);
my $reference_hial = slurp_raw(repo_path('ppif/ahb_lite_subordinate.ppif'));

my $accepted_construction = construction(
    'bins_and_cross_tuples', 'gate_candidate_v1',
);
my $accepted_preflight;
my $original_preflight =
    \&FSM::VIAL::ExecutionBuilder::_preflight_coverage_cardinality;
my $accepted;
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_preflight_coverage_cardinality = sub {
        $accepted_preflight = $original_preflight->(@_);
        return $accepted_preflight;
    };
    $accepted = $class->build({construction => $accepted_construction});
}
ok($accepted->{ok}, 'the canonical accepted coverage profile still builds');
diag($json->encode($accepted->{diagnostics})) unless $accepted->{ok};
is($accepted->{plan}{plan_id},
    'plan/d2bf527ee775de17b82a24ff299425ab61ad480eb16fe76fb23701d84d9dcf79',
    'accepted coverage profile retains its exact plan identity');

my $summary = $accepted->{execution_ir}->as_hashref->{resource_summary};
is_deeply($accepted_preflight, {
        coverpoints => $summary->{coverpoints},
        coverage_bins_and_cross_tuples =>
            $summary->{coverage_bins_and_cross_tuples},
    }, 'compact coverage preflight matches the terminal resource summary');

my $materialization_excess = construction(
    'bins_and_cross_tuples', 'over_limit_v1',
);
ok($materialization_excess->{ok},
    'coverage materialization excess remains valid source');
check_rejection(
    sub { $class->build({construction => $materialization_excess}) },
    'coverage_bins_and_cross_tuples', 1_000_000,
    'materialization excess rejects before coverage normalization',
);

my $inputs = $class->_test_coverage_cardinality_inputs(
    $accepted_construction,
);
my $semantic = $inputs->{semantic_ir}->as_hashref;
my $coverage = $semantic->{packages}[0]{fixtures}[0]{coverage};
my $minimal_point = {
    semantic_id => 'forged::coverpoint',
    bins => [],
};
$coverage->{coverpoints} = [($minimal_point) x 65_537];
$coverage->{crosses} = [];

my $forged = forged_inputs($inputs, $semantic);
check_rejection(
    sub { FSM::VIAL::ExecutionBuilder->build($forged->{arguments}) },
    'coverpoints', 65_536,
    'defensive coverpoint excess rejects before coverage normalization',
);

done_testing();

sub check_rejection {
    my ($build, $resource, $limit, $label) = @_;
    my $build_coverage_calls = 0;
    my $original_build = \&FSM::VIAL::ExecutionBuilder::_build_coverage;
    my $rejected;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ExecutionBuilder::_build_coverage = sub {
            ++$build_coverage_calls;
            return $original_build->(@_);
        };
        $rejected = $build->();
    }

    ok(!$rejected->{ok}, $label);
    is_deeply($rejected->{diagnostics}, [{
            schema_version => 1,
            severity => 'error',
            code => 'VIAL_EXECUTION_LIMIT_ERROR',
            phase => 'limit',
            message => "$resource exceeds the limit $limit",
            semantic_path => '/coverage',
            source_location => undef,
            bridge_fact_paths => [],
            related => [],
        }], "$label retains the exact /coverage execution diagnostic");
    is($build_coverage_calls, 0,
        "$label does not enter _build_coverage");
    is($rejected->{execution_ir}, undef,
        "$label returns no partial ExecutionIR");
    is($rejected->{plan}, undef, "$label returns no partial plan");
}

sub construction {
    my ($axis, $level) = @_;
    return $class->construct({
        primary_axis => $axis,
        level => $level,
        reference_hial_text => $reference_hial,
    });
}

sub forged_inputs {
    my ($base, $semantic_data) = @_;
    my $semantic_ir = bless({data => $semantic_data}, 'FSM::VIAL::SemanticIR');
    return {
        %{$base},
        semantic_ir => $semantic_ir,
        arguments => {
            %{$base->{arguments}},
            semantic_ir => $semantic_ir,
        },
    };
}

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}

package FSM::VIAL::ArchitectureScaleCheckingState;

sub _test_coverage_cardinality_inputs {
    my ($class, $construction) = @_;
    return _canonical_inputs_from_construction($construction);
}
