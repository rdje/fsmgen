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

my $class = 'FSM::VIAL::ArchitectureScaleExecutionGraph';
my $json = JSON::PP->new->canonical(1);
my $hial_path = 'ppif/ahb_lite_subordinate.ppif';
my $vial_path = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $inputs = $class->_test_operation_cardinality_inputs(
    slurp_raw(repo_path($hial_path)), $hial_path,
    slurp_raw(repo_path($vial_path)), $vial_path,
);

my $accepted = FSM::VIAL::ArchitectureScaleExecutionGraph::_build_execution(
    $inputs,
);
ok($accepted->{ok}, 'the canonical accepted profile still builds');
diag($json->encode($accepted->{diagnostics})) unless $accepted->{ok};
is($accepted->{plan}{plan_id},
    'plan/e236297c8b434a9b374d1800112841e00327bdbd5d8d9130440bd20681fbed6e',
    'accepted profile retains its exact plan identity');

my $semantic = $inputs->{semantic_ir}->as_hashref;
my $scenario = $semantic->{packages}[0]{fixtures}[0]{scenarios}[0];
my $reset = clone_json($scenario->{actions}[0]);
my $repeat = {
    kind => 'repeat',
    count => 65_536,
    actions => [$reset],
    semantic_path => $scenario->{semantic_path} . '/actions/0',
    source_span => clone_json($scenario->{source_span}),
};
$scenario->{action_count} = 65_536;
$scenario->{actions} = [$repeat];

my $expected_diagnostic = [{
    schema_version => 1,
    severity => 'error',
    code => 'VIAL_EXECUTION_LIMIT_ERROR',
    phase => 'limit',
    message => 'expanded_operations_per_scenario exceeds the limit 65536',
    semantic_path => $scenario->{semantic_path},
    source_location => undef,
    bridge_fact_paths => [],
    related => [],
}];

my ($derived_rejected, $derived_index_calls) = build_with_index_sentinel(
    forged_inputs($inputs, $semantic),
);
ok(!$derived_rejected->{ok}, 'compact-tree one-over excess is rejected');
is_deeply($derived_rejected->{diagnostics}, $expected_diagnostic,
    'derived compact excess uses the established per-scenario limit diagnostic');
is($derived_index_calls, 0,
    'derived compact excess rejects before bridge indexing');
is($derived_rejected->{execution_ir}, undef,
    'derived compact excess returns no partial ExecutionIR');
is($derived_rejected->{plan}, undef,
    'derived compact excess returns no partial plan');

my $declared_semantic = $inputs->{semantic_ir}->as_hashref;
my $declared_scenario =
    $declared_semantic->{packages}[0]{fixtures}[0]{scenarios}[0];
$declared_scenario->{action_count} = 65_537;
$declared_scenario->{actions} = [{kind => 'hostile'}];
my ($declared_rejected, $declared_index_calls) = build_with_index_sentinel(
    forged_inputs($inputs, $declared_semantic),
);
ok(!$declared_rejected->{ok}, 'declared one-over excess is rejected');
is_deeply($declared_rejected->{diagnostics}, [{
        %{$expected_diagnostic->[0]},
        semantic_path => $declared_scenario->{semantic_path},
    }], 'declared excess wins before malformed compact action inspection');
is($declared_index_calls, 0,
    'declared excess rejects before bridge indexing');
is($declared_rejected->{execution_ir}, undef,
    'declared excess returns no partial ExecutionIR');
is($declared_rejected->{plan}, undef,
    'declared excess returns no partial plan');

my $exact_scenario = {
    action_count => 65_536,
    actions => [{
        kind => 'repeat',
        count => 65_535,
        actions => [{kind => 'reset'}],
    }],
    semantic_path => '/scenario/exact',
    source_span => undef,
};
is(FSM::VIAL::ExecutionBuilder->_test_operation_cardinality_preflight(
        [$exact_scenario]), 65_536,
    'the exact compact per-scenario boundary remains accepted');

done_testing();

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

sub build_with_index_sentinel {
    my ($forged) = @_;
    my $calls = 0;
    my $result;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ExecutionBuilder::_index_bridge = sub { ++$calls };
        $result = FSM::VIAL::ArchitectureScaleExecutionGraph::_build_execution(
            $forged,
        );
    }
    return ($result, $calls);
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

package FSM::VIAL::ArchitectureScaleExecutionGraph;

sub _test_operation_cardinality_inputs {
    my ($class, $hial, $hial_path, $vial, $vial_path) = @_;
    return _canonical_ahb_inputs(
        {},
        {content => $hial, relative_path => $hial_path},
        {content => $vial, relative_path => $vial_path},
    );
}

package FSM::VIAL::ExecutionBuilder;

sub _test_operation_cardinality_preflight {
    my ($class, $scenarios) = @_;
    return _preflight_expanded_operations_total($scenarios);
}
