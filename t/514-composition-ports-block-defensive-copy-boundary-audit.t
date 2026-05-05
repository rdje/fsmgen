#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::PortsBlock;

sub expected_ports {
    return [
        { name => 'clk', direction => 'input' },
        { name => 'data', direction => 'output', width => 8 },
    ];
}

sub expected_raw_ast {
    return [
        '?ports:io',
        'clk',
        'data>',
    ];
}

subtest 'PortsBlock constructor copies mutable inputs' => sub {
    my $ports = expected_ports();
    my $raw_ast = expected_raw_ast();
    my $block = FSM::Composition::PortsBlock->new(
        name => 'io',
        ports => $ports,
        raw_ast => $raw_ast,
    );

    $ports->[0]{name} = 'mutated';
    push @$ports, { name => 'late' };
    $raw_ast->[1] = 'mutated';

    is_deeply($block->ports, expected_ports(), 'ports block stores a snapshot of constructor ports');
    is_deeply($block->raw_ast, expected_raw_ast(), 'ports block stores a snapshot of constructor raw AST');
};

subtest 'PortsBlock accessors return caller-owned containers' => sub {
    my $block = FSM::Composition::PortsBlock->new(
        name => 'io',
        ports => expected_ports(),
        raw_ast => expected_raw_ast(),
    );

    my $ports = $block->ports;
    $ports->[0]{name} = 'mutated';
    push @$ports, { name => 'late' };

    my $raw_ast = $block->raw_ast;
    $raw_ast->[1] = 'mutated';

    is_deeply($block->ports, expected_ports(), 'ports accessor returns a fresh container');
    is_deeply($block->raw_ast, expected_raw_ast(), 'raw_ast accessor returns a fresh container');
};

done_testing;
