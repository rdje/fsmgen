#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib 'perl';

use FSM::AST::Node;
use FSM::HDL::Factorization::Fixpoint::LoopStateSupport;
use FSM::HDL::FlattenedDT;

sub expected_signal_info {
    my ($ast) = @_;
    return {
        ast => $ast,
        usage_count => 2,
        contexts => ['pass_2_lhs'],
        metadata => {
            source => 'fixpoint',
        },
    };
}

subtest 'finalized fixpoint result owns intermediate-signal containers' => sub {
    my $support = build_loop_state_support();
    my $loop_state = $support->initialize_loop_state();
    my $ast = FSM::AST::SignalRef->new('A_or_B');

    $loop_state->{passes_run} = 1;
    $loop_state->{total_substitution_count} = 2;
    $loop_state->{total_update_count} = 3;
    $loop_state->{termination_reason} = 'no_substitution_progress_pass_2';
    $loop_state->{all_additional_signals}{A_or_B_second_pass} = expected_signal_info($ast);

    my $result = $support->finalize_loop_result($loop_state, max_pass_number => 16);

    is($result->{intermediate_signals}{A_or_B_second_pass}{ast}, $ast, 'final result preserves contained AST object identity');

    push @{$result->{intermediate_signals}{A_or_B_second_pass}{contexts}}, 'mutated-result';
    $result->{intermediate_signals}{A_or_B_second_pass}{metadata}{source} = 'mutated';
    is_deeply(
        $loop_state->{all_additional_signals}{A_or_B_second_pass},
        expected_signal_info($ast),
        'mutating finalized result signal metadata cannot contaminate loop state',
    );

    push @{$loop_state->{all_additional_signals}{A_or_B_second_pass}{contexts}}, 'mutated-loop-state';
    $loop_state->{all_additional_signals}{A_or_B_second_pass}{metadata}{source} = 'mutated-loop';
    is_deeply(
        $result->{intermediate_signals}{A_or_B_second_pass}{contexts},
        ['pass_2_lhs', 'mutated-result'],
        'mutating loop state after finalization cannot contaminate finalized result contexts',
    );
    is(
        $result->{intermediate_signals}{A_or_B_second_pass}{metadata}{source},
        'mutated',
        'mutating loop state after finalization cannot contaminate finalized result metadata',
    );
};

done_testing;

sub build_loop_state_support {
    my $flattened_dt = FSM::HDL::FlattenedDT->new(
        module_name => 'FixpointFinalResultBoundaryHarness',
        target_language => 'systemverilog',
        debug => 0,
    );

    return FSM::HDL::Factorization::Fixpoint::LoopStateSupport->new(
        flattened_dt => $flattened_dt,
    );
}
