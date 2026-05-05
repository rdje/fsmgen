#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::ASTFactorization;

sub repeated_ast {
    return FSM::AST::BinaryOp->new(
        '|',
        FSM::AST::SignalRef->new('A'),
        FSM::AST::SignalRef->new('B'),
    );
}

subtest 'generated intermediate signal contexts are isolated from structural-map contexts' => sub {
    my $factorizer = FSM::HDL::ASTFactorization->new(
        min_usage_count => 2,
        debug => 0,
        debug_level => 0,
    );

    $factorizer->add_ast_expression(repeated_ast(), 'first_context');
    $factorizer->add_ast_expression(repeated_ast(), 'second_context');

    my $result = $factorizer->analyze_and_factorize;
    my $signal_info = $result->{intermediate_signals}{A_or_B};
    ok($signal_info, 'repeated expression generated the expected intermediate signal');

    my $structural_id = $signal_info->{structural_id};
    is_deeply(
        $signal_info->{contexts},
        ['first_context', 'second_context'],
        'generated signal starts with the structural-map context list',
    );

    push @{$factorizer->{ast_structure_map}{$structural_id}{contexts}}, 'mutated-structure-map';
    is_deeply(
        $signal_info->{contexts},
        ['first_context', 'second_context'],
        'structural-map context mutation cannot contaminate generated signal contexts',
    );

    push @{$signal_info->{contexts}}, 'mutated-signal-info';
    is_deeply(
        $factorizer->{ast_structure_map}{$structural_id}{contexts},
        ['first_context', 'second_context', 'mutated-structure-map'],
        'generated signal context mutation cannot contaminate structural-map contexts',
    );
};

done_testing();
