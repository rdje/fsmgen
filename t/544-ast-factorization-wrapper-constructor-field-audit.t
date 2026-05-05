#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::ASTFactorization;

subtest 'SubstitutedBinaryOp constructor keeps its full runtime shape' => sub {
    my $left = FSM::AST::SignalRef->new('A');
    my $right = FSM::AST::SignalRef->new('B');
    my $node = FSM::HDL::SubstitutedBinaryOp->new(
        operator => '|',
        left => $left,
        right => $right,
    );

    is($node->{type}, 'binary_op', 'binary wrapper keeps its type marker');
    is($node->operator, '|', 'binary wrapper keeps operator');
    is($node->left, $left, 'binary wrapper keeps left child identity');
    is($node->right, $right, 'binary wrapper keeps right child identity');
    is($node->to_systemverilog, '(A | B)', 'binary wrapper renders both children');
};

subtest 'SubstitutedUnaryOp constructor keeps its full runtime shape' => sub {
    my $operand = FSM::AST::SignalRef->new('RST_N');
    my $node = FSM::HDL::SubstitutedUnaryOp->new(
        operator => '!',
        operand => $operand,
    );

    is($node->{type}, 'unary_op', 'unary wrapper keeps its type marker');
    is($node->operator, '!', 'unary wrapper keeps operator');
    is($node->operand, $operand, 'unary wrapper keeps operand identity');
    is($node->to_systemverilog, '!RST_N', 'unary wrapper renders operand');
};

subtest 'IntermediateSignalRef constructor keeps its full runtime shape' => sub {
    my $node = FSM::HDL::IntermediateSignalRef->new(signal_name => 'A_or_B');

    is($node->{type}, 'intermediate_signal_ref', 'intermediate signal ref keeps its type marker');
    is($node->signal_name, 'A_or_B', 'intermediate signal ref keeps signal_name');
    is($node->name, 'A_or_B', 'intermediate signal ref keeps name alias');
    is($node->to_systemverilog, 'A_or_B', 'intermediate signal ref renders the signal name');
    ok($node->isa('FSM::AST::SignalRef'), 'intermediate signal ref remains AST signal-ref compatible');
};

subtest 'wrapper constructors reject missing required fields before partial construction' => sub {
    like(
        exception_from(sub { FSM::HDL::SubstitutedBinaryOp->new(operator => '|', left => FSM::AST::SignalRef->new('A')) }),
        qr/SubstitutedBinaryOp requires right/,
        'binary wrapper rejects missing right child',
    );
    like(
        exception_from(sub { FSM::HDL::SubstitutedUnaryOp->new(operator => '!') }),
        qr/SubstitutedUnaryOp requires operand/,
        'unary wrapper rejects missing operand',
    );
    like(
        exception_from(sub { FSM::HDL::IntermediateSignalRef->new }),
        qr/IntermediateSignalRef requires signal_name/,
        'intermediate signal ref rejects missing signal_name',
    );
};

done_testing();

sub exception_from {
    my ($code) = @_;
    my $exception = '';
    eval { $code->(); 1 } or $exception = $@ || 'unknown exception';
    return $exception;
}
