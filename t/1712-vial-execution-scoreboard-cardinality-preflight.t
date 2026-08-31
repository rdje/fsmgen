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
    'scoreboard_instances', 'gate_candidate_v1',
);
my $accepted_preflight;
my $original_preflight =
    \&FSM::VIAL::ExecutionBuilder::_preflight_scoreboard_cardinality;
my $accepted;
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_preflight_scoreboard_cardinality = sub {
        $accepted_preflight = $original_preflight->(@_);
        return $accepted_preflight;
    };
    $accepted = $class->build({construction => $accepted_construction});
}
ok($accepted->{ok}, 'the canonical accepted scoreboard profile still builds');
diag($json->encode($accepted->{diagnostics})) unless $accepted->{ok};
is($accepted->{plan}{plan_id},
    'plan/d1393ecbf38efa45825dce9c0748982f68baa9ec199f94233f3ed2fc79bcadd8',
    'accepted scoreboard profile retains its exact plan identity');

my $summary = $accepted->{execution_ir}->as_hashref->{resource_summary};
is_deeply($accepted_preflight, {
        scoreboard_instances => $summary->{scoreboard_instances},
        scoreboard_declared_capacity =>
            $summary->{scoreboard_declared_capacity},
    }, 'compact scoreboard preflight matches the terminal resource summary');

my $instance_excess = construction(
    'scoreboard_instances', 'over_limit_v1',
);
ok($instance_excess->{ok}, 'scoreboard instance excess remains valid source');
check_rejection(
    sub { $class->build({construction => $instance_excess}) },
    'scoreboard_instances', 4_096,
    'instance excess rejects before scoreboard normalization',
);

my $capacity_construction = construction(
    'scoreboard_capacity', 'gate_candidate_v1',
);
my $inputs = $class->_test_scoreboard_cardinality_inputs(
    $capacity_construction,
);
my $semantic = $inputs->{semantic_ir}->as_hashref;
my $package = $semantic->{packages}[0];
my $fixture = $package->{fixtures}[0];
my $first_definition = $package->{scoreboards}[0];
my $first_instance = $fixture->{instances}{scoreboard_instances}[0];
$first_definition->{capacity} = 1_000_000;

my $second_definition = clone_json($first_definition);
$second_definition->{capacity} = 1;
$second_definition->{name} .= '__adjacent';
$second_definition->{semantic_id} .= '::adjacent';
$second_definition->{semantic_path} = '/packages/0/scoreboards/1';
push @{$package->{scoreboards}}, $second_definition;

my $second_instance = clone_json($first_instance);
$second_instance->{name} .= '__adjacent';
$second_instance->{semantic_id} .= '::adjacent';
$second_instance->{semantic_path} .= '/adjacent';
$second_instance->{scoreboard_id} = $second_definition->{semantic_id};
push @{$fixture->{instances}{scoreboard_instances}}, $second_instance;

my $forged = forged_inputs($inputs, $semantic);
check_rejection(
    sub { FSM::VIAL::ExecutionBuilder->build($forged->{arguments}) },
    'scoreboard_declared_capacity', 1_000_000,
    'aggregate capacity excess rejects before scoreboard normalization',
);

done_testing();

sub check_rejection {
    my ($build, $resource, $limit, $label) = @_;
    my $build_scoreboard_calls = 0;
    my $original_build = \&FSM::VIAL::ExecutionBuilder::_build_scoreboards;
    my $rejected;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ExecutionBuilder::_build_scoreboards = sub {
            ++$build_scoreboard_calls;
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
            semantic_path => '/scoreboards',
            source_location => undef,
            bridge_fact_paths => [],
            related => [],
        }], "$label retains the exact execution diagnostic");
    is($build_scoreboard_calls, 0,
        "$label does not enter _build_scoreboards");
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

sub clone_json {
    my ($value) = @_;
    return $json->decode($json->encode($value));
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

sub _test_scoreboard_cardinality_inputs {
    my ($class, $construction) = @_;
    return _canonical_inputs_from_construction($construction);
}
