#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::AggregatePathSupport;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(signal_ref_expr);

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

subtest 'shared aggregate path support resolves record members and list items' => sub {
    my $result = FSM::Composition::AggregatePathSupport->resolve(
        root_type_spec => $frame_t,
        path_text => '.payload[1]',
        base_expr => signal_ref_expr('frame'),
    );

    ok($result->{ok}, 'aggregate path resolves successfully');
    is($result->{width}, 4, 'resolved path reports the list item width');
    is($result->{type_spec}{kind}, 'bits', 'resolved path reports the list item type');
    is($result->{connection_expr}{kind}, 'member_access', 'resolved path lowers list access as a member-access expression');
    is($result->{connection_expr}{member_name}, 'item_1', 'resolved path uses the generated list item field');
    is($result->{connection_expr}{source_expr}{kind}, 'member_access', 'resolved path keeps the record member access before the item');
    is($result->{connection_expr}{source_expr}{member_name}, 'payload', 'resolved path preserves the record member name');
};

subtest 'shared aggregate path support resolves scalar subselects after members' => sub {
    my $result = FSM::Composition::AggregatePathSupport->resolve(
        root_type_spec => $frame_t,
        path_text => '.tag[3:1]',
        base_expr => 'frame',
    );

    ok($result->{ok}, 'scalar slice after a record member resolves successfully');
    is($result->{width}, 3, 'resolved scalar slice reports the sliced width');
    is($result->{type_spec}{kind}, 'bits', 'resolved scalar slice reports a bits type');
    is($result->{connection_expr}{kind}, 'slice', 'resolved scalar slice lowers as a slice expression');
    is($result->{connection_expr}{source_expr}{source_expr}{signal_name}, 'frame', 'resolved scalar slice accepts a signal-name base expression');
    is($result->{connection_expr}{source_expr}{member_name}, 'tag', 'resolved scalar slice keeps the source member');
};

subtest 'shared aggregate path support reports stable failure codes' => sub {
    my $empty_path = FSM::Composition::AggregatePathSupport->resolve(
        root_type_spec => $frame_t,
        path_text => '',
    );
    is($empty_path->{code}, 'empty_path', 'empty aggregate paths return a stable code');

    my $unknown_member = FSM::Composition::AggregatePathSupport->resolve(
        root_type_spec => $frame_t,
        path_text => '.missing',
    );
    is($unknown_member->{ok}, 0, 'unknown record member fails');
    is($unknown_member->{code}, 'unknown_member', 'unknown record member returns a stable code');
    is_deeply($unknown_member->{known_members}, [qw(tag flag payload)], 'unknown record member preserves known member names');

    my $list_range = FSM::Composition::AggregatePathSupport->resolve(
        root_type_spec => $frame_t,
        path_text => '.payload[1:0]',
    );
    is($list_range->{code}, 'list_range_not_supported', 'list range access returns a stable code');

    my $list_index = FSM::Composition::AggregatePathSupport->resolve(
        root_type_spec => $frame_t,
        path_text => '.payload[4]',
    );
    is($list_index->{code}, 'list_index_out_of_range', 'list index overflow returns a stable code');
    is($list_index->{max_index}, 2, 'list index overflow preserves the declared max index');

    my $scalar_index = FSM::Composition::AggregatePathSupport->resolve(
        root_type_spec => $frame_t,
        path_text => '.tag[4]',
    );
    is($scalar_index->{code}, 'scalar_index_out_of_range', 'scalar index overflow returns a stable code');
    is($scalar_index->{scalar_width}, 4, 'scalar index overflow preserves the resolved scalar width');

    my ($type_spec, $width) = FSM::Composition::AggregatePathSupport->resolve_type_path(
        root_type_spec => $frame_t,
        path_text => '.payload[4]',
    );
    is($type_spec, undef, 'type-only helper returns undef type on unresolved paths');
    is($width, undef, 'type-only helper returns undef width on unresolved paths');
};

done_testing();
