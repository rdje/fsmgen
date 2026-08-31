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
    \&FSM::VIAL::ExecutionBuilder::_preflight_fault_cardinality;
my $accepted;
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_preflight_fault_cardinality = sub {
        $accepted_preflight = $original_preflight->(@_);
        return $accepted_preflight;
    };
    $accepted = $class->build({construction => $accepted_construction});
}
ok($accepted->{ok}, 'the canonical accepted fault profile still builds');
diag($json->encode($accepted->{diagnostics})) unless $accepted->{ok};
is($accepted->{plan}{plan_id},
    'plan/0cc79695997bd43ca1f7680d49fa2fbc05be14a69530f2234ab5dd83e14b9e58',
    'accepted fault profile retains its exact plan identity');
is($accepted_preflight,
    $accepted->{execution_ir}->as_hashref->{resource_summary}{faults},
    'compact fault preflight matches the terminal resource summary');

my $excess = construction('over_limit_v1');
ok($excess->{ok}, 'adjacent fault excess remains valid source');
my $build_fault_calls = 0;
my $original_build = \&FSM::VIAL::ExecutionBuilder::_build_faults;
my $rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_build_faults = sub {
        ++$build_fault_calls;
        return $original_build->(@_);
    };
    $rejected = $class->build({construction => $excess});
}

ok(!$rejected->{ok}, 'adjacent fault excess is rejected');
is_deeply($rejected->{diagnostics}, [{
        schema_version => 1,
        severity => 'error',
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        phase => 'limit',
        message => 'faults exceeds the limit 4096',
        semantic_path => '/faults',
        source_location => undef,
        bridge_fact_paths => [],
        related => [],
    }], 'adjacent excess retains the exact /faults execution diagnostic');
is($build_fault_calls, 0,
    'adjacent excess does not enter _build_faults');
is($rejected->{execution_ir}, undef,
    'adjacent excess returns no partial ExecutionIR');
is($rejected->{plan}, undef, 'adjacent excess returns no partial plan');

done_testing();

sub construction {
    my ($level) = @_;
    return $class->construct({
        primary_axis => 'faults',
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
