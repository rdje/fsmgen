#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

subtest 'Signal constraints are owned by the signal' => sub {
    my $constraints = [
        {
            kind => 'range',
            bounds => [0, 7],
        },
    ];
    my $signal = FSM::CoreAST::Signal->new(
        name => 'COUNT',
        constraints => $constraints,
    );

    $constraints->[0]{bounds}[1] = 3;
    push @$constraints, { kind => 'mutated_input' };

    is_deeply(
        $signal->constraints,
        [
            {
                kind => 'range',
                bounds => [0, 7],
            },
        ],
        'constructor constraint mutation cannot contaminate signal',
    );

    my $constraint_view = $signal->constraints;
    $constraint_view->[0]{bounds}[0] = 1;
    push @$constraint_view, { kind => 'mutated_output' };

    is_deeply(
        $signal->constraints,
        [
            {
                kind => 'range',
                bounds => [0, 7],
            },
        ],
        'constraints accessor returns fresh nested metadata',
    );

    my $added_constraint = {
        kind => 'alignment',
        values => [2, 4],
    };
    $signal->add_constraint($added_constraint);
    push @{$added_constraint->{values}}, 8;

    is_deeply(
        $signal->constraints->[1],
        {
            kind => 'alignment',
            values => [2, 4],
        },
        'add_constraint stores a cloned constraint payload',
    );
};

subtest 'Signal default constraints shape supports add_constraint' => sub {
    my $signal = FSM::CoreAST::Signal->new(name => 'READY');

    is_deeply($signal->constraints, [], 'default constraints are an empty list');
    $signal->add_constraint({ kind => 'boolean' });
    is_deeply(
        $signal->constraints,
        [
            {
                kind => 'boolean',
            },
        ],
        'default constraint list accepts explicit constraint additions',
    );
};

done_testing();
