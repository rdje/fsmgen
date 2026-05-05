#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib 'perl';

use FSM::AST::Node;
use FSM::HDL::Factorization::Fixpoint::LoopStateSupport;
use FSM::HDL::FlattenedDT;

sub signal_info {
    my ($ast) = @_;
    return {
        ast => $ast,
        usage_count => 2,
        contexts => ['accepted_pass_context'],
        metadata => {
            source => 'pass_outcome',
        },
    };
}

subtest 'accepted pass signals are copied into loop state and primary map' => sub {
    my $support = build_loop_state_support();
    my $loop_state = $support->initialize_loop_state();
    my $primary_intermediate_signals = {};
    my $ast = FSM::AST::SignalRef->new('A_or_B');
    my $pass_signal_info = signal_info($ast);
    my $pass_outcome = {
        status => 'continue',
        new_unique_signals => {
            accepted_sig => $pass_signal_info,
        },
        substitution_count => 1,
        update_count => 1,
    };

    $support->apply_pass_outcome($loop_state, $pass_outcome, $primary_intermediate_signals);

    is($loop_state->{all_additional_signals}{accepted_sig}{ast}, $ast, 'loop state preserves AST identity');
    is($primary_intermediate_signals->{accepted_sig}{ast}, $ast, 'primary map preserves AST identity');

    push @{$pass_signal_info->{contexts}}, 'mutated-pass-outcome';
    $pass_signal_info->{metadata}{source} = 'mutated-pass-outcome';
    is_deeply(
        $loop_state->{all_additional_signals}{accepted_sig},
        signal_info($ast),
        'pass outcome mutation cannot contaminate accepted loop-state signal metadata',
    );
    is_deeply(
        $primary_intermediate_signals->{accepted_sig},
        signal_info($ast),
        'pass outcome mutation cannot contaminate accepted primary-map signal metadata',
    );

    push @{$primary_intermediate_signals->{accepted_sig}{contexts}}, 'mutated-primary';
    $primary_intermediate_signals->{accepted_sig}{metadata}{source} = 'mutated-primary';
    is_deeply(
        $loop_state->{all_additional_signals}{accepted_sig},
        signal_info($ast),
        'primary-map mutation cannot contaminate accepted loop-state signal metadata',
    );
};

done_testing;

sub build_loop_state_support {
    my $flattened_dt = FSM::HDL::FlattenedDT->new(
        module_name => 'FixpointAcceptedSignalBoundaryHarness',
        target_language => 'systemverilog',
        debug => 0,
    );

    return FSM::HDL::Factorization::Fixpoint::LoopStateSupport->new(
        flattened_dt => $flattened_dt,
    );
}
