#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::C1PlanBuilder;
use FSM::Composition::Port;
use FSM::Composition::PortsBlock;
use FSM::Composition::RealizedInstance;
use FSM::Composition::Spec;
use FSM::Composition::Top;

subtest 'C1 plan builder infers implicit passthrough ports from one realized child' => sub {
    my $plan = FSM::Composition::C1PlanBuilder->build_plan(
        composition_spec => FSM::Composition::Spec->new(
            top => FSM::Composition::Top->new(name => 'c1_plan_builder_top'),
        ),
        ports_block => undef,
        ports => [],
        realized_instance => make_realized_child(),
        fsm_file => 'c1_plan_builder_top.fsm',
        header => 'c1_plan_builder_top',
    );

    is($plan->lane, 'C1', 'builder records the C1 lane');
    is_deeply(
        [map { $_->name } @{$plan->ports}],
        ['clk', 'rstn', 'start', 'done'],
        'builder preserves child interface port order when inferring passthrough ports',
    );
    is_deeply(
        [map { $_->binding_mode } @{$plan->ports}],
        ['implicit_passthrough', 'implicit_passthrough', 'implicit_passthrough', 'implicit_passthrough'],
        'builder marks inferred passthrough ports explicitly',
    );
    is_deeply(
        [map { $_->origin_kind } @{$plan->ports}],
        [
            'inferred_c1_passthrough_port',
            'inferred_c1_passthrough_port',
            'inferred_c1_passthrough_port',
            'inferred_c1_passthrough_port',
        ],
        'builder marks inferred passthrough port origins',
    );
    is_deeply(
        [map { $_->origin_kind } @{$plan->resolved_links}],
        [
            'inferred_c1_passthrough_link',
            'inferred_c1_passthrough_link',
            'inferred_c1_passthrough_link',
            'inferred_c1_passthrough_link',
        ],
        'builder marks inferred passthrough link origins',
    );
    is_deeply(
        { map { $_->{port_name} => $_->{signal_name} } @{$plan->instances->[0]->port_bindings} },
        {
            clk => 'clk',
            rstn => 'rstn',
            start => 'start',
            done => 'done',
        },
        'builder wires passthrough bindings directly by name',
    );
};

subtest 'C1 plan builder keeps explicit top-port exposure when provided' => sub {
    my @ports = (
        FSM::Composition::Port->new(name => 'clk', direction => 'input', width => 1, type => 'clock'),
        FSM::Composition::Port->new(name => 'rstn', direction => 'input', width => 1, type => 'reset'),
        FSM::Composition::Port->new(name => 'start', direction => 'input', width => 1),
        FSM::Composition::Port->new(name => 'done', direction => 'output', width => 1),
    );
    my $ports_block = FSM::Composition::PortsBlock->new(ports => \@ports);
    my $plan = FSM::Composition::C1PlanBuilder->build_plan(
        composition_spec => FSM::Composition::Spec->new(
            top => FSM::Composition::Top->new(name => 'c1_plan_builder_top'),
        ),
        ports_block => $ports_block,
        ports => \@ports,
        realized_instance => make_realized_child(),
        fsm_file => 'c1_plan_builder_top.fsm',
        header => 'c1_plan_builder_top',
    );

    is_deeply(
        [map { $_->binding_mode } @{$plan->ports}],
        ['explicit', 'explicit', 'explicit', 'explicit'],
        'builder keeps explicit top ports explicit when passthrough exposure is declared',
    );
    is_deeply(
        [map { $_->origin_kind // '' } @{$plan->resolved_links}],
        [
            'declared_c1_passthrough_link',
            'declared_c1_passthrough_link',
            'declared_c1_passthrough_link',
            'declared_c1_passthrough_link',
        ],
        'builder marks declared passthrough link origins when top ports are explicit',
    );
};

done_testing();

sub make_realized_child {
    return FSM::Composition::RealizedInstance->new(
        kind => 'fsmc',
        instance_name => 'child',
        module_name => 'child_mod',
        source_name => 'child_src',
        interface_ports => [
            FSM::Composition::Port->new(name => 'clk', direction => 'input', width => 1, type => 'clock'),
            FSM::Composition::Port->new(name => 'rstn', direction => 'input', width => 1, type => 'reset'),
            FSM::Composition::Port->new(name => 'start', direction => 'input', width => 1),
            FSM::Composition::Port->new(name => 'done', direction => 'output', width => 1),
        ],
        module_info => {},
        hdl_code => undef,
    );
}
