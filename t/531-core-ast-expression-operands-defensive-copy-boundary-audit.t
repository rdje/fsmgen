#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

sub signal_ref {
    my ($name) = @_;
    return FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => $name));
}

subtest 'Expression operands and attributes are owned by the node' => sub {
    my $left = signal_ref('lhs');
    my $right = signal_ref('rhs');
    my $operands = [$left, $right];
    my $attributes = {
        source => {
            role => 'predicate',
        },
    };

    my $expr = FSM::CoreAST::Expression->new(
        type => 'test_expr',
        operands => $operands,
        attributes => $attributes,
    );

    push @$operands, signal_ref('mutated_input');
    $attributes->{source}{role} = 'mutated_role';

    is(scalar(@{$expr->operands}), 2, 'constructor operand-list mutation cannot contaminate expression');
    is($expr->operands->[0], $left, 'contained operand object identity is preserved in snapshots');
    is_deeply(
        $expr->attributes,
        {
            source => {
                role => 'predicate',
            },
        },
        'constructor attribute mutation cannot contaminate expression',
    );

    my $operand_view = $expr->operands;
    my $attribute_view = $expr->attributes;
    push @$operand_view, signal_ref('mutated_output');
    $attribute_view->{source}{role} = 'mutated_again';

    is(scalar(@{$expr->operands}), 2, 'operands accessor returns a fresh list container');
    is_deeply(
        $expr->attributes,
        {
            source => {
                role => 'predicate',
            },
        },
        'attributes accessor returns fresh nested metadata',
    );
};

subtest 'FunctionCall arguments share the expression operand snapshot boundary' => sub {
    my $arg_a = signal_ref('arg_a');
    my $arg_b = signal_ref('arg_b');
    my $call = FSM::CoreAST::FunctionCall->new('pack', $arg_a, $arg_b);

    my $arguments = $call->arguments;
    push @$arguments, signal_ref('mutated_argument');

    is(scalar(@{$call->arguments}), 2, 'arguments accessor returns a fresh list container');
    is($call->arguments->[0], $arg_a, 'argument object identity is preserved');
    is_deeply($call->arguments, $call->operands, 'arguments and operands expose the same snapshot content');
};

done_testing();
