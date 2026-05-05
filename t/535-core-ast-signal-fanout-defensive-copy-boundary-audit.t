#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

sub signal {
    my ($name) = @_;
    return FSM::CoreAST::Signal->new(name => $name);
}

subtest 'Signal fanout list containers are owned by the signal' => sub {
    my $out_a = signal('OUT_A');
    my $out_b = signal('OUT_B');
    my $fanouts = [$out_a];
    my $source = FSM::CoreAST::Signal->new(
        name => 'SRC',
        fanout_signals => $fanouts,
    );

    push @$fanouts, signal('MUTATED_INPUT');

    is(scalar(@{$source->fanout_signals}), 1, 'constructor fanout-list mutation cannot contaminate signal');
    is($source->fanout_signals->[0], $out_a, 'fanout signal object identity is preserved in snapshots');

    my $fanout_view = $source->fanout_signals;
    my $navigation_view = $source->get_fanout_signals;
    push @$fanout_view, signal('MUTATED_ACCESSOR');
    push @$navigation_view, signal('MUTATED_NAVIGATION');

    is(scalar(@{$source->fanout_signals}), 1, 'fanout_signals accessor returns a fresh list container');
    is(scalar(@{$source->get_fanout_signals}), 1, 'get_fanout_signals returns a fresh list container');

    $source->add_fanout_signal($out_b);
    is(scalar(@{$source->fanout_signals}), 2, 'add_fanout_signal remains the explicit mutation path');
    is($source->fanout_signals->[1], $out_b, 'add_fanout_signal preserves supplied signal identity');
};

subtest 'set_driving_ast still updates source fanout relationships' => sub {
    my $source = signal('SRC2');
    my $driven = signal('DRIVEN');

    $driven->set_driving_ast(FSM::CoreAST::SignalRef->new($source));

    is(scalar(@{$source->get_fanout_signals}), 1, 'driving AST update records one fanout');
    is($source->get_fanout_signals->[0], $driven, 'driving AST update preserves driven signal identity');
};

done_testing();
