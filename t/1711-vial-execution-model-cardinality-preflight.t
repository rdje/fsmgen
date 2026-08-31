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
    'model_instances', 'gate_candidate_v1',
);
my $accepted_preflight;
my $original_preflight =
    \&FSM::VIAL::ExecutionBuilder::_preflight_model_cardinality;
my $accepted;
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_preflight_model_cardinality = sub {
        $accepted_preflight = $original_preflight->(@_);
        return $accepted_preflight;
    };
    $accepted = $class->build({construction => $accepted_construction});
}
ok($accepted->{ok}, 'the canonical accepted model profile still builds');
diag($json->encode($accepted->{diagnostics})) unless $accepted->{ok};
is($accepted->{plan}{plan_id},
    'plan/89eabfaf10f2935ec34121c9ef661535ba74d289e832d82b0d01782b286d5966',
    'accepted model profile retains its exact plan identity');

my $summary = $accepted->{execution_ir}->as_hashref->{resource_summary};
is_deeply($accepted_preflight, {
        model_instances => $summary->{model_instances},
        scalar_state_cells => $summary->{scalar_state_cells},
    }, 'compact model preflight exactly matches the terminal resource summary');

for my $case (
    [model_instances => model_instances => 4_096],
    [scalar_model_state_cells => scalar_state_cells => 65_536],
) {
    my ($axis, $resource, $limit) = @$case;
    my $constructed = construction($axis, 'over_limit_v1');
    ok($constructed->{ok}, "$axis adjacent excess remains valid source");

    my $build_model_calls = 0;
    my $original_build_models = \&FSM::VIAL::ExecutionBuilder::_build_models;
    my $rejected;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ExecutionBuilder::_build_models = sub {
            ++$build_model_calls;
            return $original_build_models->(@_);
        };
        $rejected = $class->build({construction => $constructed});
    }

    ok(!$rejected->{ok}, "$axis adjacent excess is rejected");
    is_deeply($rejected->{diagnostics}, [{
            schema_version => 1,
            severity => 'error',
            code => 'VIAL_EXECUTION_LIMIT_ERROR',
            phase => 'limit',
            message => "$resource exceeds the limit $limit",
            semantic_path => '/models',
            source_location => undef,
            bridge_fact_paths => [],
            related => [],
        }], "$axis retains the exact /models execution diagnostic");
    is($build_model_calls, 0,
        "$axis rejects before model-record and definition normalization");
    is($rejected->{execution_ir}, undef,
        "$axis rejection returns no partial ExecutionIR");
    is($rejected->{plan}, undef,
        "$axis rejection returns no partial plan");
}

done_testing();

sub construction {
    my ($axis, $level) = @_;
    return $class->construct({
        primary_axis => $axis,
        level => $level,
        reference_hial_text => $reference_hial,
    });
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
