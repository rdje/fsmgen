#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Top;
use FSM::Composition::TopSymbols;

sub expected_snapshot {
    return {
        instances => [{ name => 'producer', kind => 'fsmc' }],
        ports_blocks => [{ name => 'io', ports => ['clk'] }],
        wiring_blocks => [{ name => 'wiring', links => ['producer.out/consumer.in'] }],
        package_imports => ['types_pkg'],
        raw_ast => ['?top:top', ['?fsmc:producer']],
    };
}

sub make_top {
    my %args = %{expected_snapshot()};
    return FSM::Composition::Top->new(
        name => 'top',
        top_symbols => FSM::Composition::TopSymbols->new(),
        %args,
    );
}

sub snapshot {
    my ($top) = @_;
    return {
        instances => $top->instances,
        ports_blocks => $top->ports_blocks,
        wiring_blocks => $top->wiring_blocks,
        package_imports => $top->package_imports,
        raw_ast => $top->raw_ast,
    };
}

subtest 'Top constructor copies mutable containers' => sub {
    my %args = %{expected_snapshot()};
    my $top = FSM::Composition::Top->new(
        name => 'top',
        top_symbols => FSM::Composition::TopSymbols->new(),
        %args,
    );

    $args{instances}[0]{name} = 'mutated';
    $args{ports_blocks}[0]{ports}[0] = 'mutated';
    $args{wiring_blocks}[0]{links}[0] = 'mutated';
    push @{$args{package_imports}}, 'late_pkg';
    $args{raw_ast}[1][0] = '?mutated';

    is_deeply(snapshot($top), expected_snapshot(), 'top containers are isolated from constructor mutation');
};

subtest 'Top accessors return caller-owned containers' => sub {
    my $top = make_top();

    my $instances = $top->instances;
    $instances->[0]{name} = 'mutated';

    my $ports_blocks = $top->ports_blocks;
    $ports_blocks->[0]{ports}[0] = 'mutated';

    my $wiring_blocks = $top->wiring_blocks;
    $wiring_blocks->[0]{links}[0] = 'mutated';

    my $package_imports = $top->package_imports;
    push @$package_imports, 'late_pkg';

    my $raw_ast = $top->raw_ast;
    $raw_ast->[1][0] = '?mutated';

    is_deeply(snapshot($top), expected_snapshot(), 'top containers are isolated from accessor mutation');
};

subtest 'TopSymbols remains the owned symbol-table object' => sub {
    my $top_symbols = FSM::Composition::TopSymbols->new();
    my $top = FSM::Composition::Top->new(
        name => 'top',
        top_symbols => $top_symbols,
    );

    is($top->top_symbols, $top_symbols, 'top_symbols accessor preserves the owned symbol-table object');
};

done_testing;
