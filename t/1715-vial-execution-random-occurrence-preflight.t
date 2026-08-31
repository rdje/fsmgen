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

my $accepted_construction = construction('gate_candidate_v1');
my $accepted_preflight;
my $original_preflight =
    \&FSM::VIAL::ExecutionBuilder::_preflight_random_occurrence_count;
my $accepted;
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_preflight_random_occurrence_count = sub {
        $accepted_preflight = $original_preflight->(@_);
        return $accepted_preflight;
    };
    $accepted = $class->build({construction => $accepted_construction});
}
ok($accepted->{ok}, 'the canonical accepted random profile still builds');
diag($json->encode($accepted->{diagnostics})) unless $accepted->{ok};
is($accepted->{plan}{plan_id},
    'plan/8ff991f7f983316f16421b34e8997b892234246784982e6756075762dc7bf97c',
    'accepted random profile retains its exact plan identity');
is($accepted_preflight,
    $accepted->{execution_ir}->as_hashref->{resource_summary}
        {random_occurrences},
    'compact random preflight matches the terminal resource summary');

my $excess = construction('over_limit_v1');
ok($excess->{ok}, 'adjacent random-occurrence excess remains valid source');
my $build_operation_calls = 0;
my $original_build = \&FSM::VIAL::ExecutionBuilder::_build_operations;
my $rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_build_operations = sub {
        ++$build_operation_calls;
        return $original_build->(@_);
    };
    $rejected = $class->build({construction => $excess});
}

ok(!$rejected->{ok}, 'adjacent random-occurrence excess is rejected');
is_deeply($rejected->{diagnostics}, [{
        schema_version => 1,
        severity => 'error',
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        phase => 'limit',
        message => 'random_occurrences exceeds the limit 65536',
        semantic_path => '/randomness/decisions',
        source_location => undef,
        bridge_fact_paths => [],
        related => [],
    }], 'adjacent excess retains the exact randomness execution diagnostic');
is($build_operation_calls, 0,
    'adjacent excess does not enter _build_operations');
is($rejected->{execution_ir}, undef,
    'adjacent excess returns no partial ExecutionIR');
is($rejected->{plan}, undef, 'adjacent excess returns no partial plan');

done_testing();

sub construction {
    my ($level) = @_;
    return $class->construct({
        primary_axis => 'random_occurrences',
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
