#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Package::Spec;
use FSM::Package::Symbols;

sub expected_raw_ast {
    return [
        '?pkg:types_pkg',
        ['+types', ['type', 'byte_t', ['bits', 8]]],
    ];
}

subtest 'Package::Spec constructor copies raw AST containers' => sub {
    my $symbols = FSM::Package::Symbols->new();
    my $raw_ast = expected_raw_ast();
    my $spec = FSM::Package::Spec->new(
        name => 'types_pkg',
        symbols => $symbols,
        raw_ast => $raw_ast,
    );

    $raw_ast->[1][1][2][1] = 99;

    is($spec->symbols, $symbols, 'symbols accessor preserves the owned symbol table object');
    is_deeply($spec->raw_ast, expected_raw_ast(), 'raw_ast is isolated from constructor mutation');
};

subtest 'Package::Spec raw_ast accessor returns caller-owned containers' => sub {
    my $spec = FSM::Package::Spec->new(
        name => 'types_pkg',
        symbols => FSM::Package::Symbols->new(),
        raw_ast => expected_raw_ast(),
    );

    my $raw_ast = $spec->raw_ast;
    $raw_ast->[1][1][2][1] = 99;
    push @$raw_ast, ['+constants'];

    is_deeply($spec->raw_ast, expected_raw_ast(), 'raw_ast accessor returns a fresh container');
};

done_testing;
