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
use FSM::Composition::TopLink;

subtest 'linked plan builder assembles a bounded explicit-link plan with auto system wiring' => sub {
    my @ports = (
        port('clk', 'input', 1, 'clock'),
        port('rstn', 'input', 1, 'reset'),
        port('go', 'input', 1, undef),
        port('done', 'output', 1, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C2',
        composition_spec => composition_spec('linked_plan_builder_top'),
        top => FSM::Composition::Top->new(name => 'linked_plan_builder_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
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
    is(scalar(@{$plan->links}), 3, 'builder preserves the declared explicit toplink set');
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

subtest 'linked plan builder rejects missing explicit toplinks on explicit-link lanes' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C2',
            composition_spec => composition_spec('blocked_top'),
            top => FSM::Composition::Top->new(name => 'blocked_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            toplinks => [],
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
        qr/explicit-link lane entry is blocked because the current active C2 lane requires explicit '\?toplink' wiring/s,
        'builder keeps the bounded explicit-link lane-entry diagnostic',
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
    my ($name, $direction, $width, $type) = @_;
    return FSM::Composition::Port->new(
        name => $name,
        direction => $direction,
        width => $width,
        type => $type,
    );
}
