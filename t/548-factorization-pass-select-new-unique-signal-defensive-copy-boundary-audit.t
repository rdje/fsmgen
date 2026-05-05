#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib 'perl';

use FSM::AST::Node;
use FSM::HDL::Factorization::Fixpoint::PassSupport;

sub signal_info {
    my ($ast) = @_;
    return {
        ast => $ast,
        usage_count => 2,
        contexts => ['pass_context'],
        metadata => {
            source => 'pass_signal',
        },
    };
}

subtest 'select_new_unique_signals returns caller-owned signal metadata' => sub {
    my $support = FSM::HDL::Factorization::Fixpoint::PassSupport->new(
        flattened_dt => bless({}, 'Local::FlattenedDTHarness'),
    );
    my $ast = FSM::AST::SignalRef->new('A_or_B');
    my $pass_signals = {
        A_or_B_second_pass => signal_info($ast),
        already_primary => signal_info(FSM::AST::SignalRef->new('primary')),
        already_additional => signal_info(FSM::AST::SignalRef->new('additional')),
    };

    my $selected = $support->select_new_unique_signals(
        $pass_signals,
        { already_additional => $pass_signals->{already_additional} },
        { already_primary => $pass_signals->{already_primary} },
    );

    is_deeply(
        [sort keys %{$selected}],
        ['A_or_B_second_pass'],
        'selection excludes already-known additional and primary signals',
    );
    is($selected->{A_or_B_second_pass}{ast}, $ast, 'selection preserves contained AST identity');

    push @{$selected->{A_or_B_second_pass}{contexts}}, 'mutated-selected';
    $selected->{A_or_B_second_pass}{metadata}{source} = 'mutated-selected';
    is_deeply(
        $pass_signals->{A_or_B_second_pass},
        signal_info($ast),
        'mutating selected signal metadata cannot contaminate pass signal metadata',
    );

    push @{$pass_signals->{A_or_B_second_pass}{contexts}}, 'mutated-pass';
    $pass_signals->{A_or_B_second_pass}{metadata}{source} = 'mutated-pass';
    is_deeply(
        $selected->{A_or_B_second_pass}{contexts},
        ['pass_context', 'mutated-selected'],
        'mutating pass signal metadata after selection cannot contaminate selected contexts',
    );
    is(
        $selected->{A_or_B_second_pass}{metadata}{source},
        'mutated-selected',
        'mutating pass signal metadata after selection cannot contaminate selected metadata',
    );
};

done_testing;
