#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::TopSymbols;
use FSM::Package::Symbols;

subtest 'TopSymbols local symbol table is caller-owned across construction and access' => sub {
    my $local_symbols = FSM::Package::Symbols->new(
        constants => {
            RESET => scalar_payload('0'),
        },
        types => {
            byte_t => {
                kind => 'bits',
                width => 8,
            },
        },
    );

    my $top_symbols = FSM::Composition::TopSymbols->new(
        local_symbols => $local_symbols,
    );

    $local_symbols->store_constant('RESET', scalar_payload('1'));
    $local_symbols->store_type('byte_t', {
        kind => 'bits',
        width => 32,
    });

    my $first_local_symbols = $top_symbols->local_symbols;
    $first_local_symbols->store_constant('RESET', scalar_payload('2'));
    $first_local_symbols->store_type('byte_t', {
        kind => 'bits',
        width => 64,
    });

    is(
        $top_symbols->resolve_actual_payload('RESET'),
        '0',
        'local symbol constants are isolated from constructor and accessor mutation',
    );
    is_deeply(
        $top_symbols->resolve_type('byte_t'),
        {
            kind => 'bits',
            width => 8,
        },
        'local symbol types are isolated from constructor and accessor mutation',
    );
};

subtest 'TopSymbols store wrappers return caller-owned snapshots' => sub {
    my $top_symbols = FSM::Composition::TopSymbols->new();

    my $constant_payload = scalar_payload('4');
    my $enum_members = {
        IDLE => '0',
    };
    my $type_spec = {
        kind => 'bits',
        width => 8,
    };

    my $returned_constant = $top_symbols->store_constant('LOCAL', $constant_payload);
    my $returned_enum = $top_symbols->store_enum('mode', $enum_members);
    my $returned_type = $top_symbols->store_type('byte_t', $type_spec);

    $constant_payload->{payload} = 'mutated_after_store_input';
    $enum_members->{IDLE} = 'mutated_after_store_input';
    $type_spec->{width} = 99;

    $returned_constant->{payload} = 'mutated_after_store_return';
    $returned_enum->{IDLE} = 'mutated_after_store_return';
    $returned_type->{width} = 32;

    is($top_symbols->resolve_actual_payload('LOCAL'), '4', 'store_constant wrapper return is isolated');
    is_deeply(
        $top_symbols->resolve_payload('mode.IDLE'),
        {
            kind => 'scalar',
            payload => '0',
        },
        'store_enum wrapper return is isolated',
    );
    is_deeply(
        $top_symbols->resolve_type('byte_t'),
        {
            kind => 'bits',
            width => 8,
        },
        'store_type wrapper return is isolated',
    );
};

done_testing();

sub scalar_payload {
    my ($payload) = @_;
    return {
        kind => 'scalar',
        payload => $payload,
    };
}
