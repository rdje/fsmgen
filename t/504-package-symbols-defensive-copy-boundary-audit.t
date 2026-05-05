#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Package::Symbols;

subtest 'Package::Symbols constructor and accessors return caller-owned copies' => sub {
    my $constants = {
        FRAME => frame_payload(),
    };
    my $enums = {
        mode => {
            IDLE => '0',
        },
    };
    my $types = {
        frame_t => frame_type(),
    };
    my $raw_blocks = [
        ['+constants', ['FRAME']],
    ];

    my $symbols = FSM::Package::Symbols->new(
        constants => $constants,
        enums => $enums,
        types => $types,
        raw_blocks => $raw_blocks,
    );

    $constants->{FRAME}{members}{payload}{payload} = 'mutated_after_constructor';
    $enums->{mode}{IDLE} = 'mutated_after_constructor';
    $types->{frame_t}{members}{payload}{width} = 99;
    $raw_blocks->[0][1][0] = 'mutated_after_constructor';

    my $first_constants = $symbols->constants;
    my $first_enums = $symbols->enums;
    my $first_types = $symbols->types;
    my $first_raw_blocks = $symbols->raw_blocks;

    $first_constants->{FRAME}{members}{payload}{payload} = 'mutated_after_accessor';
    $first_enums->{mode}{IDLE} = 'mutated_after_accessor';
    $first_types->{frame_t}{members}{payload}{width} = 32;
    $first_raw_blocks->[0][1][0] = 'mutated_after_accessor';

    is_deeply(
        $symbols->constants->{FRAME},
        frame_payload(),
        'constants accessor is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $symbols->enums,
        {
            mode => {
                IDLE => '0',
            },
        },
        'enums accessor is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $symbols->types->{frame_t},
        frame_type(),
        'types accessor is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $symbols->raw_blocks,
        [
            ['+constants', ['FRAME']],
        ],
        'raw_blocks accessor is isolated from constructor and accessor mutation',
    );
};

subtest 'Package::Symbols store and resolve methods return caller-owned copies' => sub {
    my $symbols = FSM::Package::Symbols->new();
    my $constant_payload = frame_payload();
    my $enum_members = {
        IDLE => '0',
    };
    my $type_payload = frame_type();
    my $raw_block = ['+types', ['frame_t']];

    my $returned_constant = $symbols->store_constant('FRAME', $constant_payload);
    my $returned_enum = $symbols->store_enum('mode', $enum_members);
    my $returned_type = $symbols->store_type('frame_t', $type_payload);
    my $returned_raw_blocks = $symbols->push_raw_block($raw_block);

    $constant_payload->{members}{payload}{payload} = 'mutated_after_store_input';
    $enum_members->{IDLE} = 'mutated_after_store_input';
    $type_payload->{members}{payload}{width} = 99;
    $raw_block->[1][0] = 'mutated_after_store_input';

    $returned_constant->{members}{payload}{payload} = 'mutated_after_store_return';
    $returned_enum->{IDLE} = 'mutated_after_store_return';
    $returned_type->{members}{payload}{width} = 32;
    $returned_raw_blocks->[0][1][0] = 'mutated_after_store_return';

    is_deeply($symbols->resolve_payload('FRAME'), frame_payload(), 'stored constant is isolated');
    is_deeply(
        $symbols->resolve_payload('mode.IDLE'),
        {
            kind => 'scalar',
            payload => '0',
        },
        'stored enum member is isolated',
    );
    is_deeply($symbols->resolve_type('frame_t'), frame_type(), 'stored type is isolated');
    is_deeply($symbols->raw_blocks, [['+types', ['frame_t']]], 'stored raw block is isolated');

    my $resolved_constant = $symbols->resolve_payload('FRAME');
    my $resolved_suffix = $symbols->resolve_payload('FRAME.payload');
    my $resolved_type = $symbols->resolve_type('frame_t');

    $resolved_constant->{members}{payload}{payload} = 'mutated_after_resolve';
    $resolved_suffix->{payload} = 'mutated_after_resolve';
    $resolved_type->{members}{payload}{width} = 64;

    is_deeply(
        $symbols->resolve_payload('FRAME'),
        frame_payload(),
        'resolve_payload exact-name result is caller-owned',
    );
    is_deeply(
        $symbols->resolve_payload('FRAME.payload'),
        {
            kind => 'scalar',
            payload => "8'hA5",
        },
        'resolve_payload suffix result is caller-owned',
    );
    is_deeply(
        $symbols->resolve_type('frame_t'),
        frame_type(),
        'resolve_type result remains caller-owned',
    );
};

done_testing();

sub frame_payload {
    return {
        kind => 'map',
        member_order => [qw(tag payload)],
        members => {
            tag => {
                kind => 'scalar',
                payload => '1',
            },
            payload => {
                kind => 'scalar',
                payload => "8'hA5",
            },
        },
    };
}

sub frame_type {
    return {
        kind => 'record',
        width => 9,
        member_order => [qw(tag payload)],
        members => {
            tag => {
                kind => 'bit',
                width => 1,
            },
            payload => {
                kind => 'bits',
                width => 8,
            },
        },
    };
}
