#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Link;
use FSM::Composition::LinkedPlanBuilder;
use FSM::Composition::Port;
use FSM::Composition::PortsBlock;
use FSM::Composition::RealizedInstance;
use FSM::Composition::Spec;
use FSM::Composition::Top;
use FSM::Composition::WiringBlock;

subtest 'linked plan builder assembles a bounded explicit-link plan with auto system wiring' => sub {
    my @ports = (
        port('clk', 'input', 1, 'clock'),
        port('rstn', 'input', 1, 'reset'),
        port('go', 'input', 1, undef),
        port('done', 'output', 1, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
        lane => 'C2',
        composition_spec => composition_spec('linked_plan_builder_top'),
        top => FSM::Composition::Top->new(name => 'linked_plan_builder_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => 'go', target => 'producer.go'),
                    FSM::Composition::Link->new(source => 'producer.payload', target => 'consumer.payload'),
                    FSM::Composition::Link->new(source => 'consumer.done', target => 'done'),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'producer',
                port('clk', 'input', 1, 'clock'),
                port('rstn', 'input', 1, 'reset'),
                port('go', 'input', 1, undef),
                port('payload', 'output', 8, undef),
            ),
            realized_instance(
                'consumer',
                port('clk', 'input', 1, 'clock'),
                port('rstn', 'input', 1, 'reset'),
                port('payload', 'input', 8, undef),
                port('done', 'output', 1, undef),
            ),
        ],
        fsm_file => 'linked_plan_builder_top.fsm',
        header => 'linked_plan_builder_top',
    );

    is($plan->lane, 'C2', 'builder records the active explicit-link lane');
    is(scalar(@{$plan->links}), 3, 'builder preserves the declared explicit wiring set');
    is(scalar(@{$plan->nets}), 1, 'builder creates one deterministic internal carrier net');
    is($plan->nets->[0]->name, 'comp_link_producer_payload', 'builder keeps the deterministic net naming rule');

    my @resolved_sources = map { $_->source } @{$plan->resolved_links};
    ok(grep { $_ eq 'clk' } @resolved_sources, 'builder adds auto system clock wiring');
    ok(grep { $_ eq 'rstn' } @resolved_sources, 'builder adds auto system reset wiring');

    my %producer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$plan->instances->[0]->port_bindings};
    my %consumer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$plan->instances->[1]->port_bindings};

    is($producer_bindings{clk}, 'clk', 'producer clock is auto-wired from the top system port');
    is($producer_bindings{rstn}, 'rstn', 'producer reset is auto-wired from the top system port');
    is($producer_bindings{go}, 'go', 'top input link binds directly by name');
    is($producer_bindings{payload}, 'comp_link_producer_payload', 'producer output drives the deterministic carrier net');
    is($consumer_bindings{clk}, 'clk', 'consumer clock is auto-wired from the top system port');
    is($consumer_bindings{rstn}, 'rstn', 'consumer reset is auto-wired from the top system port');
    is($consumer_bindings{payload}, 'comp_link_producer_payload', 'consumer input is fed from the deterministic carrier net');
    is($consumer_bindings{done}, 'done', 'consumer output is rebound directly to the top output');
};

subtest 'linked plan builder fans one child source out to multiple top outputs through one carrier net' => sub {
    my @ports = (
        port('clk', 'input', 1, 'clock'),
        port('rstn', 'input', 1, 'reset'),
        port('status_a', 'output', 8, undef),
        port('status_b', 'output', 8, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
        lane => 'C2',
        composition_spec => composition_spec('linked_plan_builder_multi_top_output_top'),
        top => FSM::Composition::Top->new(name => 'linked_plan_builder_multi_top_output_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => 'producer.payload', target => 'status_a'),
                    FSM::Composition::Link->new(source => 'producer.payload', target => 'status_b'),
                    FSM::Composition::Link->new(source => 'producer.payload', target => 'consumer.payload'),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'producer',
                port('clk', 'input', 1, 'clock'),
                port('rstn', 'input', 1, 'reset'),
                port('payload', 'output', 8, undef),
            ),
            realized_instance(
                'consumer',
                port('clk', 'input', 1, 'clock'),
                port('rstn', 'input', 1, 'reset'),
                port('payload', 'input', 8, undef),
            ),
        ],
        fsm_file => 'linked_plan_builder_multi_top_output_top.fsm',
        header => 'linked_plan_builder_multi_top_output_top',
    );

    is($plan->lane, 'C2', 'builder keeps the active explicit-link lane for multi-top-output fanout');
    is(scalar(@{$plan->nets}), 1, 'builder creates one deterministic carrier net for multi-top-output fanout');
    is($plan->nets->[0]->name, 'comp_link_producer_payload', 'builder keeps the deterministic carrier net naming rule for multi-top-output fanout');
    is_deeply(
        $plan->nets->[0]->targets,
        ['status_a', 'status_b', 'consumer.payload'],
        'carrier net records both top-output targets and child-input consumers',
    );
    is_deeply(
        $plan->auxiliary_assignments,
        [
            '    assign status_a = comp_link_producer_payload;',
            '    assign status_b = comp_link_producer_payload;',
        ],
        'builder emits explicit top-output fanout assignments for the shared carrier',
    );

    my %producer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$plan->instances->[0]->port_bindings};
    my %consumer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$plan->instances->[1]->port_bindings};

    is($producer_bindings{payload}, 'comp_link_producer_payload', 'producer output drives the shared carrier net for multi-top-output fanout');
    is($consumer_bindings{payload}, 'comp_link_producer_payload', 'consumer input reuses the shared carrier net for multi-top-output fanout');
};

subtest 'linked plan builder fans one top input directly to top outputs and child inputs' => sub {
    my @ports = (
        port('clk', 'input', 1, 'clock'),
        port('rstn', 'input', 1, 'reset'),
        port('start', 'input', 8, undef),
        port('tap_a', 'output', 8, undef),
        port('tap_b', 'output', 8, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
        lane => 'C2',
        composition_spec => composition_spec('linked_plan_builder_top_input_fanout_top'),
        top => FSM::Composition::Top->new(name => 'linked_plan_builder_top_input_fanout_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => 'start', target => 'tap_a'),
                    FSM::Composition::Link->new(source => 'start', target => 'tap_b'),
                    FSM::Composition::Link->new(source => 'start', target => 'left.payload'),
                    FSM::Composition::Link->new(source => 'start', target => 'right.payload'),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'left',
                port('clk', 'input', 1, 'clock'),
                port('rstn', 'input', 1, 'reset'),
                port('payload', 'input', 8, undef),
            ),
            realized_instance(
                'right',
                port('clk', 'input', 1, 'clock'),
                port('rstn', 'input', 1, 'reset'),
                port('payload', 'input', 8, undef),
            ),
        ],
        fsm_file => 'linked_plan_builder_top_input_fanout_top.fsm',
        header => 'linked_plan_builder_top_input_fanout_top',
    );

    is($plan->lane, 'C2', 'builder keeps the active explicit-link lane for direct top-input fanout');
    is(scalar(@{$plan->nets}), 0, 'builder keeps direct top-input fanout net-free');
    is_deeply(
        $plan->auxiliary_assignments,
        [
            '    assign tap_a = start;',
            '    assign tap_b = start;',
        ],
        'builder emits direct top-output assignments for the top-input fanout',
    );

    my %left_bindings = map { $_->{port_name} => $_->{signal_name} } @{$plan->instances->[0]->port_bindings};
    my %right_bindings = map { $_->{port_name} => $_->{signal_name} } @{$plan->instances->[1]->port_bindings};

    is($left_bindings{payload}, 'start', 'left child input reuses the top input directly');
    is($right_bindings{payload}, 'start', 'right child input reuses the same top input directly');
};

subtest 'linked plan builder rejects missing explicit wiring_blocks on explicit-link lanes' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C2',
            composition_spec => composition_spec('blocked_top'),
            top => FSM::Composition::Top->new(name => 'blocked_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [],
            realized_instances => [
                realized_instance('producer', port('payload', 'output', 8, undef)),
                realized_instance('consumer', port('payload', 'input', 8, undef)),
            ],
            fsm_file => 'blocked_top.fsm',
            header => 'blocked_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/explicit-link lane entry is blocked because the current active C2 lane requires explicit '\?wiring' wiring/s,
        'builder keeps the bounded explicit-link lane-entry diagnostic',
    );
};

subtest 'linked plan builder rejects explicit port-to-port links across incompatible declared type contracts' => sub {
    my @ports = (
        port('clk', 'input', 1, 'clock'),
        port('rstn', 'input', 1, 'reset'),
        port('result_data', 'output', 8, undef),
    );

    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C2',
            composition_spec => composition_spec('typed_linked_plan_builder_top'),
            top => FSM::Composition::Top->new(name => 'typed_linked_plan_builder_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
            ports => \@ports,
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => 'producer.payload', target => 'consumer.payload'),
                        FSM::Composition::Link->new(source => 'consumer.result_data', target => 'result_data'),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance(
                    'producer',
                    port('clk', 'input', 1, 'clock'),
                    port('rstn', 'input', 1, 'reset'),
                    port('payload', 'output', 8, undef,
                        declared_type_name => 'packet_t',
                        declared_type_spec => record_spec(
                            tag => bit_spec(),
                            payload => bits_spec(7),
                        ),
                    ),
                ),
                realized_instance(
                    'consumer',
                    port('clk', 'input', 1, 'clock'),
                    port('rstn', 'input', 1, 'reset'),
                    port('payload', 'input', 8, undef,
                        declared_type_name => 'byte_t',
                        declared_type_spec => bits_spec(8),
                    ),
                    port('result_data', 'output', 8, undef,
                        declared_type_name => 'byte_t',
                        declared_type_spec => bits_spec(8),
                    ),
                ),
            ],
            fsm_file => 'typed_linked_plan_builder_top.fsm',
            header => 'typed_linked_plan_builder_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/links 'producer\.payload' to 'consumer\.payload', .*explicit link is blocked because those endpoints preserve incompatible declared type contracts \('packet_t' vs 'byte_t'\)/s,
        'builder rejects explicit port-to-port links across incompatible declared type contracts',
    );
};

done_testing();

sub composition_spec {
    my ($top_name) = @_;
    return FSM::Composition::Spec->new(
        top => FSM::Composition::Top->new(name => $top_name),
    );
}

sub realized_instance {
    my ($instance_name, @ports) = @_;

    return FSM::Composition::RealizedInstance->new(
        kind => 'fsmc',
        instance_name => $instance_name,
        module_name => $instance_name.'_mod',
        source_name => $instance_name.'_src',
        interface_ports => \@ports,
        port_bindings => [],
        module_info => {},
        hdl_code => undef,
    );
}

sub port {
    my ($name, $direction, $width, $type, %extra) = @_;
    return FSM::Composition::Port->new(
        name => $name,
        direction => $direction,
        width => $width,
        type => $type,
        %extra,
    );
}

sub bit_spec {
    return {
        kind => 'bit',
        width => 1,
        signed => 0,
    };
}

sub bits_spec {
    my ($width) = @_;
    return {
        kind => 'bits',
        width => $width,
        signed => 0,
    };
}

sub record_spec {
    my (%members) = @_;
    my @member_order = sort keys %members;
    my $width = 0;
    $width += ($members{$_}{width} // 0) for @member_order;
    return {
        kind => 'record',
        width => $width,
        signed => 0,
        member_order => \@member_order,
        members => { %members },
    };
}
