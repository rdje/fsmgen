#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

sub literal {
    my ($value) = @_;
    return FSM::CoreAST::Literal->new($value);
}

subtest 'BinaryOp operator registry owns registered metadata' => sub {
    my $aliases = ['audit_alias'];
    FSM::CoreAST::BinaryOp->register_operator(
        'audit_copy_boundary_op_533',
        verilog => '@@',
        vhdl => 'audit_vhdl',
        verilog_precedence => 6,
        vhdl_precedence => 6,
        systemverilog_precedence => 6,
        associative => 0,
        commutative => 0,
        metadata => {
            aliases => $aliases,
        },
    );

    push @$aliases, 'mutated_input';

    my $info = FSM::CoreAST::BinaryOp->get_operator_info('audit_copy_boundary_op_533');
    is_deeply(
        $info->{metadata}{aliases},
        ['audit_alias'],
        'registration clones nested operator metadata',
    );

    $info->{verilog} = 'mutated_symbol';
    push @{$info->{metadata}{aliases}}, 'mutated_output';

    my $info_again = FSM::CoreAST::BinaryOp->get_operator_info('audit_copy_boundary_op_533');
    is($info_again->{verilog}, '@@', 'operator-info accessor returns a fresh metadata map');
    is_deeply(
        $info_again->{metadata}{aliases},
        ['audit_alias'],
        'nested operator-info metadata is also returned as a snapshot',
    );

    my $expr = FSM::CoreAST::BinaryOp->new(
        'audit_copy_boundary_op_533',
        literal('1'),
        literal('0'),
    );
    is($expr->to_verilog, '1 @@ 0', 'rendering still reads the owned operator registry entry');
    is(
        FSM::CoreAST::BinaryOp->is_commutative('audit_copy_boundary_op_533'),
        0,
        'is_commutative still reads the owned registry metadata',
    );
};

subtest 'unknown operator info remains undef' => sub {
    is(
        FSM::CoreAST::BinaryOp->get_operator_info('missing_copy_boundary_op_533'),
        undef,
        'missing operator info remains undef',
    );
};

done_testing();
