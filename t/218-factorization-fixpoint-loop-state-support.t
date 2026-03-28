use strict;
use warnings;

use Test::More;

use lib 'perl';

use FSM::HDL::Factorization::Fixpoint::LoopStateSupport;
use FSM::HDL::FlattenedDT;

subtest 'loop-state support initializes the aggregate fixpoint state contract' => sub {
    my $support = build_loop_state_support();
    my $loop_state = $support->initialize_loop_state();

    is_deeply(
        $loop_state,
        {
            all_additional_signals => {},
            seen_signatures => {},
            passes_run => 0,
            total_substitution_count => 0,
            total_update_count => 0,
            termination_reason => 'running',
        },
        'initial loop state matches the saved aggregate contract',
    );
};

subtest 'loop-state support applies accepted pass outcomes and merges new signals' => sub {
    my $support = build_loop_state_support();
    my $loop_state = $support->initialize_loop_state();
    my $primary_intermediate_signals = {
        primary_keep => { ast => 'primary_ast' },
    };

    my $transition = $support->apply_pass_outcome(
        $loop_state,
        {
            status => 'continue',
            termination_reason => undef,
            new_unique_signals => {
                pass_two_sig => { ast => 'pass_two_ast', usage_count => 3 },
            },
            substitution_count => 2,
            update_count => 5,
        },
        $primary_intermediate_signals,
    );

    is_deeply(
        $transition,
        {
            terminate => 0,
            accepted => 1,
        },
        'continue outcome stays in the loop and is accepted',
    );

    is($loop_state->{passes_run}, 1, 'accepted pass increments passes_run');
    is($loop_state->{total_substitution_count}, 2, 'accepted pass accumulates substitution count');
    is($loop_state->{total_update_count}, 5, 'accepted pass accumulates update count');
    ok(exists $loop_state->{all_additional_signals}{pass_two_sig}, 'accepted pass signal is recorded in aggregate additional signals');
    ok(exists $primary_intermediate_signals->{pass_two_sig}, 'accepted pass signal is added to the live primary intermediate map');
    is($loop_state->{termination_reason}, 'running', 'loop remains running after accepted continue outcome');
};

subtest 'loop-state support records pre-accept termination without mutating aggregate counters' => sub {
    my $support = build_loop_state_support();
    my $loop_state = $support->initialize_loop_state();
    my $primary_intermediate_signals = {};

    my $transition = $support->apply_pass_outcome(
        $loop_state,
        {
            status => 'terminate',
            termination_reason => 'repeated_input_signature',
            new_unique_signals => {
                should_not_merge => { ast => 'x' },
            },
            substitution_count => 99,
            update_count => 77,
        },
        $primary_intermediate_signals,
    );

    is_deeply(
        $transition,
        {
            terminate => 1,
            accepted => 0,
        },
        'terminate outcome stops the loop before accept',
    );

    is($loop_state->{termination_reason}, 'repeated_input_signature', 'pre-accept termination reason is recorded');
    is($loop_state->{passes_run}, 0, 'pre-accept termination does not increment passes_run');
    is($loop_state->{total_substitution_count}, 0, 'pre-accept termination does not accumulate substitution count');
    is($loop_state->{total_update_count}, 0, 'pre-accept termination does not accumulate update count');
    ok(!exists $loop_state->{all_additional_signals}{should_not_merge}, 'pre-accept termination does not merge pass signals');
    ok(!exists $primary_intermediate_signals->{should_not_merge}, 'pre-accept termination does not mutate primary intermediates');
};

subtest 'loop-state support records terminate-after-accept outcomes and finalizes the public result contract' => sub {
    my $support = build_loop_state_support();
    my $loop_state = $support->initialize_loop_state();
    my $primary_intermediate_signals = {};

    my $transition = $support->apply_pass_outcome(
        $loop_state,
        {
            status => 'terminate_after_accept',
            termination_reason => 'no_substitution_progress_pass_3',
            new_unique_signals => {
                pass_three_sig => { ast => 'pass_three_ast', usage_count => 2 },
            },
            substitution_count => 0,
            update_count => 1,
        },
        $primary_intermediate_signals,
    );

    is_deeply(
        $transition,
        {
            terminate => 1,
            accepted => 1,
        },
        'terminate-after-accept stops the loop after aggregate acceptance',
    );

    my $result = $support->finalize_loop_result($loop_state, max_pass_number => 16);
    is($result->{termination_reason}, 'no_substitution_progress_pass_3', 'finalized result preserves accepted termination reason');
    is($result->{passes_run}, 1, 'finalized result preserves passes_run');
    is($result->{total_substitution_count}, 0, 'finalized result preserves substitution count');
    is($result->{total_update_count}, 1, 'finalized result preserves update count');
    ok(exists $result->{intermediate_signals}{pass_three_sig}, 'finalized result exposes accepted pass signals');
};

subtest 'loop-state support normalizes unfinished loops to the pass-cap termination contract' => sub {
    my $support = build_loop_state_support();
    my $loop_state = $support->initialize_loop_state();

    my $result = $support->finalize_loop_result($loop_state, max_pass_number => 6);

    is($result->{termination_reason}, 'max_pass_limit_reached_6', 'finalization converts running state into the pass-cap termination reason');
    is($result->{passes_run}, 0, 'pass-cap finalization preserves aggregate counters');
    is($result->{total_substitution_count}, 0, 'pass-cap finalization preserves substitution count');
    is($result->{total_update_count}, 0, 'pass-cap finalization preserves update count');
    is_deeply($result->{intermediate_signals}, {}, 'pass-cap finalization preserves the accepted signal set');
};

done_testing;

sub build_loop_state_support {
    my $flattened_dt = FSM::HDL::FlattenedDT->new(
        module_name => 'FixpointLoopStateSupportHarness',
        target_language => 'systemverilog',
        debug => 0,
    );

    return FSM::HDL::Factorization::Fixpoint::LoopStateSupport->new(
        flattened_dt => $flattened_dt,
    );
}
