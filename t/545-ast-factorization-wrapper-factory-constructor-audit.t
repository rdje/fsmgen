#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::ASTFactorization;

subtest 'ASTFactorization wrapper factories use constructor-owned runtime shapes' => sub {
    my $factorizer = FSM::HDL::ASTFactorization->new(debug => 0);
    my $left = FSM::AST::SignalRef->new('A');
    my $right = FSM::AST::SignalRef->new('B');

    my $signal_ref = $factorizer->create_signal_ref_ast('A_or_B');
    isa_ok($signal_ref, 'FSM::HDL::IntermediateSignalRef', 'signal-ref factory result');
    is($signal_ref->{type}, 'intermediate_signal_ref', 'signal-ref factory keeps constructor type marker');
    is($signal_ref->to_systemverilog, 'A_or_B', 'signal-ref factory result renders through constructor class');

    my $binary = $factorizer->create_binary_op_ast('|', $left, $right);
    isa_ok($binary, 'FSM::HDL::SubstitutedBinaryOp', 'binary factory result');
    is($binary->{type}, 'binary_op', 'binary factory keeps constructor type marker');
    is($binary->left, $left, 'binary factory preserves left identity');
    is($binary->right, $right, 'binary factory preserves right identity');
    is($binary->to_systemverilog, '(A | B)', 'binary factory result renders through constructor class');

    my $unary = $factorizer->create_unary_op_ast('!', $left);
    isa_ok($unary, 'FSM::HDL::SubstitutedUnaryOp', 'unary factory result');
    is($unary->{type}, 'unary_op', 'unary factory keeps constructor type marker');
    is($unary->operand, $left, 'unary factory preserves operand identity');
    is($unary->to_systemverilog, '!A', 'unary factory result renders through constructor class');
};

subtest 'ASTFactorization wrapper factories share constructor validation' => sub {
    my $factorizer = FSM::HDL::ASTFactorization->new(debug => 0);
    my $left = FSM::AST::SignalRef->new('A');

    like(
        exception_from(sub { $factorizer->create_signal_ref_ast('') }),
        qr/IntermediateSignalRef requires signal_name/,
        'signal-ref factory rejects empty signal names',
    );
    like(
        exception_from(sub { $factorizer->create_binary_op_ast('|', $left, undef) }),
        qr/SubstitutedBinaryOp requires right/,
        'binary factory rejects missing right child',
    );
    like(
        exception_from(sub { $factorizer->create_unary_op_ast('', $left) }),
        qr/SubstitutedUnaryOp requires operator/,
        'unary factory rejects empty operator',
    );
};

done_testing();

sub exception_from {
    my ($code) = @_;
    my $exception = '';
    eval { $code->(); 1 } or $exception = $@ || 'unknown exception';
    return $exception;
}
