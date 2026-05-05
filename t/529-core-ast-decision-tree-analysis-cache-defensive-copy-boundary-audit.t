#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

subtest 'DecisionTree analysis cache results are returned as snapshots' => sub {
    my $out = FSM::CoreAST::Signal->new(name => 'OUT');
    my $src_a = FSM::CoreAST::Signal->new(name => 'SRC_A');
    my $src_b = FSM::CoreAST::Signal->new(name => 'SRC_B');

    my $first_assignment = FSM::CoreAST::Assignment->new(
        target => FSM::CoreAST::SignalRef->new($out),
        source => FSM::CoreAST::SignalRef->new($src_a),
    );
    my $second_assignment = FSM::CoreAST::Assignment->new(
        target => FSM::CoreAST::SignalRef->new($out),
        source => FSM::CoreAST::SignalRef->new($src_b),
    );
    my $dt = FSM::CoreAST::DecisionTree->new(
        name => 'analysis_dt',
        elements => [$first_assignment, $second_assignment],
    );

    my $signals = $dt->analyze_signals;
    is($signals->{outputs}{OUT}, $out, 'signal analysis preserves output signal identity');
    is($signals->{inputs}{SRC_A}, $src_a, 'signal analysis preserves input signal identity');
    is(scalar(@{$signals->{dependencies}{OUT}}), 2, 'signal analysis records both dependencies');

    $signals->{outputs}{OUT} = 'mutated_output';
    delete $signals->{inputs}{SRC_A};
    push @{$signals->{dependencies}{OUT}}, 'mutated_dependency';

    my $signals_again = $dt->analyze_signals;
    is($signals_again->{outputs}{OUT}, $out, 'mutating signal analysis output hash cannot contaminate cache');
    is($signals_again->{inputs}{SRC_A}, $src_a, 'mutating signal analysis input hash cannot contaminate cache');
    is(scalar(@{$signals_again->{dependencies}{OUT}}), 2, 'mutating dependencies array cannot contaminate cache');

    my $conflicts = $dt->analyze_conflicts;
    is(scalar(@$conflicts), 1, 'conflict analysis records one conflict');
    is($conflicts->[0][0], $first_assignment, 'conflict analysis preserves first action identity');
    is($conflicts->[0][1], $second_assignment, 'conflict analysis preserves second action identity');

    $conflicts->[0][0] = 'mutated_conflict';
    push @$conflicts, ['extra_conflict'];

    my $conflicts_again = $dt->analyze_conflicts;
    is(scalar(@$conflicts_again), 1, 'mutating conflict list cannot contaminate cache');
    is($conflicts_again->[0][0], $first_assignment, 'mutating nested conflict pair cannot contaminate cache');
    is($conflicts_again->[0][1], $second_assignment, 'conflict pair action identity remains stable');
};

done_testing();
