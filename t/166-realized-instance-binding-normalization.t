#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::RealizedInstance;

subtest 'realized instance normalizes signal-name bindings into signal_ref expressions' => sub {
    my $instance = FSM::Composition::RealizedInstance->new(
        kind => 'fsmc',
        instance_name => 'child',
        module_name => 'child_mod',
        source_name => 'child_src',
        port_bindings => [
            {
                port_name => 'clk',
                signal_name => 'clk',
            },
            {
                port_name => 'data_in',
                signal_name => 'top_data',
            },
        ],
    );

    is_deeply(
        $instance->port_bindings,
        [
            {
                port_name => 'clk',
                signal_name => 'clk',
                connection_expr => {
                    kind => 'signal_ref',
                    signal_name => 'clk',
                },
            },
            {
                port_name => 'data_in',
                signal_name => 'top_data',
                connection_expr => {
                    kind => 'signal_ref',
                    signal_name => 'top_data',
                },
            },
        ],
        'signal-name-only bindings gain backend-neutral signal_ref expressions',
    );
};

subtest 'realized instance backfills signal_name from signal_ref expressions' => sub {
    my $instance = FSM::Composition::RealizedInstance->new(
        kind => 'rtl',
        instance_name => 'uart0',
        module_name => 'uart',
        port_bindings => [
            {
                port_name => 'rx',
                connection_expr => {
                    kind => 'signal_ref',
                    signal_name => 'rx_line',
                },
            },
        ],
    );

    is_deeply(
        $instance->port_bindings,
        [
            {
                port_name => 'rx',
                signal_name => 'rx_line',
                connection_expr => {
                    kind => 'signal_ref',
                    signal_name => 'rx_line',
                },
            },
        ],
        'signal_ref expressions keep the compatibility signal_name mirror filled in',
    );
};

subtest 'realized instance clones connection_expr payloads instead of aliasing caller hashes' => sub {
    my $expr = {
        kind => 'signal_ref',
        signal_name => 'shared_bus',
    };

    my $instance = FSM::Composition::RealizedInstance->new(
        kind => 'dtc',
        instance_name => 'route0',
        module_name => 'route_src',
        port_bindings => [
            {
                port_name => 'IN_A',
                connection_expr => $expr,
            },
        ],
    );

    $expr->{signal_name} = 'mutated_after_construction';

    is_deeply(
        $instance->port_bindings,
        [
            {
                port_name => 'IN_A',
                signal_name => 'shared_bus',
                connection_expr => {
                    kind => 'signal_ref',
                    signal_name => 'shared_bus',
                },
            },
        ],
        'realized instance keeps its own cloned binding expression payload',
    );
};

done_testing();
