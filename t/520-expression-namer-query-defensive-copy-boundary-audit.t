#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;
use FSM::ExpressionNamer;

sub build_expression {
    my $left_signal = FSM::CoreAST::Signal->new(name => 'a', width => 8);
    my $right_signal = FSM::CoreAST::Signal->new(name => 'b', width => 8);
    return FSM::CoreAST::BinaryOp->new(
        '&',
        FSM::CoreAST::SignalRef->new($left_signal),
        FSM::CoreAST::SignalRef->new($right_signal),
    );
}

subtest 'ExpressionNamer query accessors return caller-owned maps' => sub {
    my $namer = FSM::ExpressionNamer->new();
    my $expr = build_expression();
    my $signal_name = $namer->name_ast_expression($expr);
    my $definition = $expr->to_systemverilog;

    my $definitions = $namer->get_signal_definitions;
    is($definitions->{$signal_name}{definition}, $definition, 'signal definitions expose generated expression definition');
    $definitions->{$signal_name}{width} = 99;
    $definitions->{$signal_name}{definition} = 'mutated';
    $definitions->{late_signal} = {
        width => 1,
        definition => 'late',
    };

    my $named_expressions = $namer->get_named_expressions;
    is($named_expressions->{$definition}, $signal_name, 'named expression map exposes generated expression name');
    $named_expressions->{$definition} = 'mutated';
    $named_expressions->{late_expr} = 'late_signal';

    my $fresh_definitions = $namer->get_signal_definitions;
    is($fresh_definitions->{$signal_name}{width}, 8, 'definition width is isolated from query mutation');
    is($fresh_definitions->{$signal_name}{definition}, $definition, 'definition text is isolated from query mutation');
    ok(!exists $fresh_definitions->{late_signal}, 'new definition keys do not enter internal state through query mutation');

    my $fresh_named_expressions = $namer->get_named_expressions;
    is($fresh_named_expressions->{$definition}, $signal_name, 'named expression map is isolated from query mutation');
    ok(!exists $fresh_named_expressions->{late_expr}, 'new expression keys do not enter internal state through query mutation');

    my @wire_declarations = $namer->generate_wire_declarations;
    is(scalar(@wire_declarations), 1, 'wire declarations still read one internal definition after query mutation');
    like($wire_declarations[0], qr/\b\Q$signal_name\E\b/, 'wire declaration still names the internally stored signal');
    unlike($wire_declarations[0], qr/late_signal|mutated|99/, 'wire declaration does not use mutated query-map data');
    is_deeply(
        [$namer->generate_assignments],
        ["assign $signal_name = $definition;"],
        'assignments still use internal definition state after query mutation',
    );
};

done_testing;
