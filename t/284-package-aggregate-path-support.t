#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Package::AggregatePathSupport;

my $pair_t = {
    kind => 'list',
    width => 6,
    signed => 0,
    items => [
        { kind => 'bit', width => 1, signed => 0 },
        { kind => 'bits', width => 4, signed => 0 },
        { kind => 'bit', width => 1, signed => 0 },
    ],
};

my $frame_t = {
    kind => 'record',
    width => 11,
    signed => 0,
    member_order => [qw(tag flag payload)],
    members => {
        tag => { kind => 'bits', width => 4, signed => 0 },
        flag => { kind => 'bit', width => 1, signed => 0 },
        payload => $pair_t,
    },
};

subtest 'package aggregate path support resolves reusable path segments' => sub {
    my $result = FSM::Package::AggregatePathSupport->resolve(
        root_type_spec => $frame_t,
        path_text => '.payload[1]',
    );

    ok($result->{ok}, 'aggregate path resolves successfully');
    is($result->{width}, 4, 'resolved path reports the list item width');
    is($result->{type_spec}{kind}, 'bits', 'resolved path reports the list item type');
    is_deeply(
        $result->{path_segments},
        [
            { kind => 'member', name => 'payload' },
            { kind => 'item', index => 1 },
        ],
        'resolved path reports reusable member/item segments',
    );
};

subtest 'package aggregate path support resolves scalar subselect path segments' => sub {
    my $result = FSM::Package::AggregatePathSupport->resolve(
        root_type_spec => $frame_t,
        path_text => '.tag[3:1]',
    );

    ok($result->{ok}, 'scalar slice after a record member resolves successfully');
    is($result->{width}, 3, 'resolved scalar slice reports the sliced width');
    is($result->{type_spec}{kind}, 'bits', 'resolved scalar slice reports a bits type');
    is_deeply(
        $result->{path_segments},
        [
            { kind => 'member', name => 'tag' },
            { kind => 'bit_slice', high => 3, low => 1 },
        ],
        'resolved scalar slice reports reusable bit-slice segments',
    );
};

subtest 'package aggregate path support resolves packed base-signal ranges' => sub {
    my $tag_range = FSM::Package::AggregatePathSupport->resolve_packed_range(
        root_type_spec => $frame_t,
        path_text => '.tag',
    );
    ok($tag_range->{ok}, 'record member packed range resolves successfully');
    is($tag_range->{high}, 10, 'record member packed range keeps the high bound');
    is($tag_range->{low}, 7, 'record member packed range keeps the low bound');

    my $payload_item_range = FSM::Package::AggregatePathSupport->resolve_packed_range(
        root_type_spec => $frame_t,
        path_segments => [
            { kind => 'member', name => 'payload' },
            { kind => 'item', index => 1 },
        ],
    );
    ok($payload_item_range->{ok}, 'list item packed range resolves successfully from path segments');
    is($payload_item_range->{high}, 4, 'list item packed range keeps the high bound');
    is($payload_item_range->{low}, 1, 'list item packed range keeps the low bound');

    my $tag_slice_range = FSM::Package::AggregatePathSupport->resolve_packed_range(
        root_type_spec => $frame_t,
        path_text => '.tag[3:1]',
    );
    ok($tag_slice_range->{ok}, 'scalar subselect packed range resolves successfully');
    is($tag_slice_range->{high}, 10, 'scalar subselect packed range keeps the high bound');
    is($tag_slice_range->{low}, 8, 'scalar subselect packed range keeps the low bound');
};

subtest 'package aggregate path support reports stable failure codes' => sub {
    my $scalar_root = FSM::Package::AggregatePathSupport->resolve(
        root_type_spec => { kind => 'bits', width => 4, signed => 0 },
        path_text => '.flag',
    );
    is($scalar_root->{code}, 'scalar_root', 'scalar roots return a stable code');
    is($scalar_root->{current_type_label}, 'bits[4]', 'scalar root failure keeps the type label');

    my $unknown_member = FSM::Package::AggregatePathSupport->resolve(
        root_type_spec => $frame_t,
        path_text => '.missing',
    );
    is($unknown_member->{code}, 'unknown_member', 'unknown record member returns a stable code');
    is_deeply($unknown_member->{known_members}, [qw(tag flag payload)], 'unknown record member preserves known member names');

    my $scalar_index = FSM::Package::AggregatePathSupport->resolve(
        root_type_spec => $frame_t,
        path_text => '.tag[4]',
    );
    is($scalar_index->{code}, 'scalar_index_out_of_range', 'scalar index overflow returns a stable code');
    is($scalar_index->{scalar_width}, 4, 'scalar index overflow preserves the resolved scalar width');
};

done_testing();
