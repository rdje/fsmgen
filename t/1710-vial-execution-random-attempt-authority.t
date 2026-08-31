#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleExecutionGraph;
use FSM::VIAL::ExecutionBuilder;
use FSM::VIAL::ExecutionIR;
use FSM::VIAL::ExecutionRandom;
use FSM::VIAL::ExecutionReport;

my $class = 'FSM::VIAL::ArchitectureScaleExecutionGraph';
my $json = JSON::PP->new->canonical(1);
my $reference_hial = slurp_raw(repo_path('ppif/ahb_lite_subordinate.ppif'));
my $construction = $class->construct({
    primary_axis => 'random_attempts',
    level => 'over_limit_v1',
    reference_hial_text => $reference_hial,
});
ok($construction->{ok}, 'the canonical one-over random workload constructs');
diag($json->encode($construction->{diagnostics})) unless $construction->{ok};

my $inputs = $class->_test_random_attempt_inputs($construction);
my $choice = $inputs->{semantic_ir}->as_hashref
    ->{packages}[0]{fixtures}[0]{randomness}{choices}[0];
my %calls = (
    projection => 0,
    generate => 0,
    plan_preflight => 0,
    decisions => 0,
    execution_ir => 0,
    report => 0,
);
my $caller_supplied_attempt_limit;
my $original_projection =
    \&FSM::VIAL::ExecutionBuilder::_project_random_plan_arrays;
my $rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_project_random_plan_arrays = sub {
        ++$calls{projection};
        return $original_projection->(@_);
    };
    local *FSM::VIAL::ExecutionRandom::generate = sub {
        my ($random_class, $arguments) = @_;
        ++$calls{generate};
        $caller_supplied_attempt_limit = exists $arguments->{max_attempts};
        return undef;
    };
    local *FSM::VIAL::ExecutionBuilder::_preflight_serialized_plan_bytes = sub {
        ++$calls{plan_preflight};
        die "serialized-plan preflight entered\n";
    };
    local *FSM::VIAL::ExecutionBuilder::_build_randomness = sub {
        ++$calls{decisions};
        die "random-decision materialization entered\n";
    };
    local *FSM::VIAL::ExecutionIR::_from_builder = sub {
        ++$calls{execution_ir};
        die "ExecutionIR materialization entered\n";
    };
    local *FSM::VIAL::ExecutionReport::build = sub {
        ++$calls{report};
        die "execution-report materialization entered\n";
    };
    $rejected = FSM::VIAL::ArchitectureScaleExecutionGraph::_build_execution(
        $inputs,
    );
}

ok(!$rejected->{ok}, 'random exhaustion rejects the execution build');
is_deeply($rejected->{diagnostics}, [{
        schema_version => 1,
        severity => 'error',
        code => 'VIAL_RANDOM_EXHAUSTED',
        phase => 'random',
        message => "random choice '$choice->{decision_id}' exhausted its attempt limit",
        semantic_path => $choice->{semantic_path},
        source_location => $choice->{source_span},
        bridge_fact_paths => [],
        related => [],
    }], 'projection exhaustion retains the exact random diagnostic');
is($calls{projection}, 1, 'exhaustion is decided inside random projection');
is($calls{generate}, 1, 'one occurrence enters bounded generation once');
ok(!$caller_supplied_attempt_limit,
    'the builder retains ExecutionRandom intrinsic attempt authority');
is_deeply(
    [@calls{qw(plan_preflight decisions execution_ir report)}],
    [0, 0, 0, 0],
    'exhaustion precedes plan preflight and every final materializer',
);
is($rejected->{execution_ir}, undef,
    'random exhaustion returns no partial ExecutionIR');
is($rejected->{plan}, undef, 'random exhaustion returns no partial plan');

done_testing();

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

package FSM::VIAL::ArchitectureScaleExecutionGraph;

sub _test_random_attempt_inputs {
    my ($class, $construction) = @_;
    return _canonical_inputs($construction);
}
