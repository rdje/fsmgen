#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::ASTFactorization;

sub expected_contexts {
    return [
        {
            label => 'first_use',
            tags => ['factorized', 'debug'],
        },
    ];
}

subtest 'IntermediateSignal constructor owns context metadata' => sub {
    my $contexts = expected_contexts();
    my $expr = FSM::AST::SignalRef->new('A');
    my $signal = FSM::AST::IntermediateSignal->new(
        name => 'A_factored',
        original_expression => $expr,
        usage_count => 2,
        contexts => $contexts,
    );

    push @{$contexts->[0]{tags}}, 'mutated-input';
    $contexts->[0]{label} = 'mutated';

    is($signal->original_expression, $expr, 'original expression identity remains live');
    is_deeply([$signal->contexts], expected_contexts(), 'constructor context input mutation cannot contaminate the signal');
};

subtest 'IntermediateSignal contexts accessor returns caller-owned entries' => sub {
    my $signal = FSM::AST::IntermediateSignal->new(
        name => 'B_factored',
        original_expression => FSM::AST::SignalRef->new('B'),
        usage_count => 3,
        contexts => expected_contexts(),
    );

    my @contexts = $signal->contexts;
    push @{$contexts[0]{tags}}, 'mutated-accessor';
    $contexts[0]{label} = 'mutated';

    is_deeply([$signal->contexts], expected_contexts(), 'contexts accessor mutation cannot contaminate stored context metadata');
};

subtest 'IntermediateSignal debug_info returns caller-owned context metadata' => sub {
    my $signal = FSM::AST::IntermediateSignal->new(
        name => 'C_factored',
        original_expression => FSM::AST::BinaryOp->new(
            '&&',
            FSM::AST::SignalRef->new('C'),
            FSM::AST::SignalRef->new('D'),
        ),
        usage_count => 4,
        contexts => expected_contexts(),
    );

    my $debug_info = $signal->debug_info;
    push @{$debug_info->{contexts}[0]{tags}}, 'mutated-debug';
    $debug_info->{contexts}[0]{label} = 'mutated';

    is($debug_info->{original_sv}, '(C && D)', 'debug info still renders the live original expression');
    is_deeply(
        $signal->debug_info->{contexts},
        expected_contexts(),
        'debug_info context mutation cannot contaminate stored context metadata',
    );
};

done_testing();
