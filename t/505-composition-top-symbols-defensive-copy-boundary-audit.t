#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::TopSymbols;
use FSM::Package::Symbols;

subtest 'TopSymbols imported packages and raw blocks are caller-owned across construction and access' => sub {
    my $package_symbols = package_symbols_with_reset('0');
    my $raw_blocks = [
        ['+import', ['shared']],
    ];

    my $top_symbols = FSM::Composition::TopSymbols->new(
        imported_packages => {
            shared => $package_symbols,
        },
        raw_blocks => $raw_blocks,
    );

    $package_symbols->store_constant('RESET', scalar_payload('1'));
    $raw_blocks->[0][1][0] = 'mutated_after_constructor';

    my $first_imports = $top_symbols->imported_packages;
    my $first_raw_blocks = $top_symbols->raw_blocks;

    $first_imports->{shared}->store_constant('RESET', scalar_payload('2'));
    $first_imports->{mutated_after_accessor} = package_symbols_with_reset('3');
    $first_raw_blocks->[0][1][0] = 'mutated_after_accessor';

    is(
        $top_symbols->resolve_actual_payload('shared.RESET'),
        '0',
        'imported package symbols are isolated from constructor and accessor mutation',
    );
    is_deeply(
        [sort keys %{$top_symbols->imported_packages}],
        ['shared'],
        'imported package map is isolated from accessor mutation',
    );
    is_deeply(
        $top_symbols->raw_blocks,
        [
            ['+import', ['shared']],
        ],
        'raw_blocks is isolated from constructor and accessor mutation',
    );
};

subtest 'TopSymbols import_package and push_raw_block return caller-owned snapshots' => sub {
    my $top_symbols = FSM::Composition::TopSymbols->new();
    my $package_symbols = package_symbols_with_reset('4');
    my $raw_block = ['+import', ['late']];

    my $returned_package = $top_symbols->import_package('late', $package_symbols);
    my $returned_raw_blocks = $top_symbols->push_raw_block($raw_block);

    $package_symbols->store_constant('RESET', scalar_payload('5'));
    $returned_package->store_constant('RESET', scalar_payload('6'));
    $raw_block->[1][0] = 'mutated_after_push_input';
    $returned_raw_blocks->[0][1][0] = 'mutated_after_push_return';

    is(
        $top_symbols->resolve_actual_payload('late.RESET'),
        '4',
        'import_package stores and returns isolated package symbols',
    );
    is_deeply(
        $top_symbols->raw_blocks,
        [
            ['+import', ['late']],
        ],
        'push_raw_block stores and returns isolated raw block lists',
    );
    is_deeply(
        $top_symbols->as_hashref->{package_imports},
        ['late'],
        'as_hashref package import summary is stable after returned snapshot mutation',
    );
};

done_testing();

sub package_symbols_with_reset {
    my ($payload) = @_;
    return FSM::Package::Symbols->new(
        constants => {
            RESET => scalar_payload($payload),
        },
    );
}

sub scalar_payload {
    my ($payload) = @_;
    return {
        kind => 'scalar',
        payload => $payload,
    };
}
