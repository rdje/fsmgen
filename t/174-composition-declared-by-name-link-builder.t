#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::DeclaredByNameLinkBuilder;
use FSM::Composition::Port;
use FSM::Composition::RealizedInstance;

subtest 'declared-by-name builder fans one top input out to multiple same-name child inputs' => sub {
    my $links = FSM::Composition::DeclaredByNameLinkBuilder->build_links(
        ports => [
            FSM::Composition::Port->new(name => 'payload_in', direction => 'input', width => 8, binding_mode => 'connect_by_name'),
            FSM::Composition::Port->new(name => 'left_seen', direction => 'output', width => 8, binding_mode => 'connect_by_name'),
            FSM::Composition::Port->new(name => 'right_seen', direction => 'output', width => 8, binding_mode => 'connect_by_name'),
        ],
        realized_instances => [
            make_child(
                instance_name => 'left',
                ports => [
                    FSM::Composition::Port->new(name => 'payload_in', direction => 'input', width => 8),
                    FSM::Composition::Port->new(name => 'left_seen', direction => 'output', width => 8),
                ],
            ),
            make_child(
                instance_name => 'right',
                ports => [
                    FSM::Composition::Port->new(name => 'payload_in', direction => 'input', width => 8),
                    FSM::Composition::Port->new(name => 'right_seen', direction => 'output', width => 8),
                ],
            ),
        ],
        fsm_file => 'declared_by_name_builder_top.fsm',
        header => 'declared_by_name_builder_top',
    );

    is_deeply(
        [
            map { { source => $_->source, target => $_->target, origin_kind => $_->origin_kind } } @$links
        ],
        [
            { source => 'payload_in', target => 'left.payload_in', origin_kind => 'declared_connect_by_name_link' },
            { source => 'payload_in', target => 'right.payload_in', origin_kind => 'declared_connect_by_name_link' },
            { source => 'left.left_seen', target => 'left_seen', origin_kind => 'declared_connect_by_name_link' },
            { source => 'right.right_seen', target => 'right_seen', origin_kind => 'declared_connect_by_name_link' },
        ],
        'builder emits declared connect-by-name links for input fanout and same-name top outputs',
    );
};

subtest 'declared-by-name builder rejects reserved system-port declarations' => sub {
    my $exception = eval {
        FSM::Composition::DeclaredByNameLinkBuilder->build_links(
            ports => [
                FSM::Composition::Port->new(name => 'clk', direction => 'input', width => 1, type => 'clock', binding_mode => 'connect_by_name'),
            ],
            realized_instances => [
                make_child(
                    instance_name => 'child',
                    ports => [
                        FSM::Composition::Port->new(name => 'clk', direction => 'input', width => 1, type => 'clock'),
                    ],
                ),
            ],
            fsm_file => 'declared_by_name_builder_top.fsm',
            header => 'declared_by_name_builder_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declared connect-by-name is blocked because the shared system ports 'clk' already use the dedicated system-input contract/s,
        'builder keeps the reserved system-port exclusion visible',
    );
};

done_testing();

sub make_child {
    my (%args) = @_;
    return FSM::Composition::RealizedInstance->new(
        kind => 'fsmc',
        instance_name => $args{instance_name},
        module_name => $args{instance_name}.'_mod',
        source_name => $args{instance_name}.'_src',
        interface_ports => ($args{ports} || []),
        module_info => {},
        hdl_code => undef,
    );
}
