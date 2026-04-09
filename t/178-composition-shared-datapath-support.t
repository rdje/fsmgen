#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Plan;
use FSM::Composition::Port;
use FSM::Composition::RealizedInstance;
use FSM::Composition::SharedDatapathSupport;

subtest 'shared-datapath support projects generated child source exports from lowered drive families' => sub {
    my $exports = FSM::Composition::SharedDatapathSupport->build_source_export_metadata([
        {
            signal_name => 'status_bus',
            rhs_enable_families => [
                {
                    rhs_value => "8'd1",
                    family_enable_signal => 'status_bus__8_d1_en',
                },
                {
                    rhs_value => "8'd2",
                    family_enable_signal => 'status_bus__8_d2_en',
                },
            ],
        },
    ]);

    is_deeply(
        $exports,
        [
            {
                signal_name => 'status_bus',
                rhs_value => "8'd1",
                source_signal => 'status_bus__8_d1_en',
                port_name => 'shared_dp_export_status_bus_8_d1_en',
            },
            {
                signal_name => 'status_bus',
                rhs_value => "8'd2",
                source_signal => 'status_bus__8_d2_en',
                port_name => 'shared_dp_export_status_bus_8_d2_en',
            },
        ],
        'support keeps the bounded child source-export projection contract',
    );
};

subtest 'shared-datapath support augments one plan with registered shared re-export runtime' => sub {
    my $rhs_value = "8'd1";
    my $family_enable = FSM::Composition::SharedDatapathSupport->value_enable_name('status_bus', $rhs_value);
    my $same_value_conflict = FSM::Composition::SharedDatapathSupport->same_value_conflict_name('status_bus', $rhs_value);
    my $multi_value_conflict = FSM::Composition::SharedDatapathSupport->multi_value_conflict_name('status_bus');

    my $plan = FSM::Composition::Plan->new(
        lane => 'C2',
        top_name => 'shared_dp_direct_fixture',
        ports => [
            port('clk', 'input', 1, 'clock'),
            port('rstn', 'input', 1, 'reset'),
            port('left_status', 'output', 8),
            port('right_status', 'output', 8),
        ],
        instances => [
            realized_instance(
                'left',
                [
                    { port_name => 'status_bus', signal_name => 'left_status' },
                ],
                [
                    output_port('status_bus', 8),
                    output_port('shared_dp_export_status_bus_8_d1_en', 1),
                ],
                [
                    {
                        signal_name => 'status_bus',
                        rhs_value => $rhs_value,
                        source_signal => 'status_bus__8_d1_en',
                        port_name => 'shared_dp_export_status_bus_8_d1_en',
                    },
                ],
            ),
            realized_instance(
                'right',
                [
                    { port_name => 'status_bus', signal_name => 'right_status' },
                ],
                [
                    output_port('status_bus', 8),
                    output_port('shared_dp_export_status_bus_8_d1_en', 1),
                ],
                [
                    {
                        signal_name => 'status_bus',
                        rhs_value => $rhs_value,
                        source_signal => 'status_bus__8_d1_en',
                        port_name => 'shared_dp_export_status_bus_8_d1_en',
                    },
                ],
            ),
            realized_instance(
                'consumer',
                [
                    { port_name => 'status_bus', signal_name => 'left_status' },
                ],
                [
                    input_port('status_bus', 8),
                ],
                [],
            ),
        ],
    );

    my $candidates = [
        {
            signal_name => 'status_bus',
            width => 8,
            declared_type_name => 'byte_t',
            declared_type_spec => {
                kind => 'bits',
                width => 8,
                signed => 1,
                state_model => 'four_state',
            },
            storage_class => 'registered',
            reset_value => "8'h00",
            peer_read_policy => 'registered_loopback',
            loopback_allowed => 1,
            peer_input_count => 1,
            peer_input_endpoints => [
                { endpoint => 'consumer.status_bus' },
            ],
            top_output_signals => ['left_status', 'right_status'],
            planned_reexport_top_output_signals => ['left_status', 'right_status'],
            aggregate_target_enable_signal => FSM::Composition::SharedDatapathSupport->target_enable_name('status_bus'),
            multi_value_conflict_signal => $multi_value_conflict,
            multi_value_assertion => FSM::Composition::SharedDatapathSupport->assertion_metadata(
                $multi_value_conflict,
                [$family_enable],
            ),
            aggregate_enable_families => [
                {
                    rhs_value => $rhs_value,
                    aggregate_enable_signal => $family_enable,
                    same_value_conflict_signal => $same_value_conflict,
                    same_value_assertion => FSM::Composition::SharedDatapathSupport->assertion_metadata(
                        $same_value_conflict,
                        [
                            FSM::Composition::SharedDatapathSupport->source_value_enable_name('left', 'status_bus', $rhs_value),
                            FSM::Composition::SharedDatapathSupport->source_value_enable_name('right', 'status_bus', $rhs_value),
                        ],
                    ),
                    contributors => [
                        {
                            endpoint => 'left.status_bus',
                            source_enable_signal => FSM::Composition::SharedDatapathSupport->source_value_enable_name('left', 'status_bus', $rhs_value),
                            declared_type_name => 'byte_t',
                            declared_type_spec => {
                                kind => 'bits',
                                width => 8,
                                signed => 1,
                                state_model => 'four_state',
                            },
                        },
                        {
                            endpoint => 'right.status_bus',
                            source_enable_signal => FSM::Composition::SharedDatapathSupport->source_value_enable_name('right', 'status_bus', $rhs_value),
                            declared_type_name => 'byte_t',
                            declared_type_spec => {
                                kind => 'bits',
                                width => 8,
                                signed => 1,
                                state_model => 'four_state',
                            },
                        },
                    ],
                },
            ],
            contributors => [
                {
                    endpoint => 'left.status_bus',
                    declared_type_name => 'byte_t',
                    declared_type_spec => {
                        kind => 'bits',
                        width => 8,
                        signed => 1,
                        state_model => 'four_state',
                    },
                },
                {
                    endpoint => 'right.status_bus',
                    declared_type_name => 'byte_t',
                    declared_type_spec => {
                        kind => 'bits',
                        width => 8,
                        signed => 1,
                        state_model => 'four_state',
                    },
                },
            ],
        },
    ];

    FSM::Composition::SharedDatapathSupport->augment_plan(
        composition_plan => $plan,
        shared_datapath_candidates => $candidates,
        target_language => 'systemverilog',
    );

    my $candidate = $candidates->[0];
    is($candidate->{lifted_runtime_kind}, 'registered_shared_reexport', 'support records the bounded registered shared re-export runtime');
    is($candidate->{lifted_runtime_next_signal}, 'status_bus_shared_next', 'support records the lifted next signal');
    is($candidate->{lifted_runtime_signal}, 'status_bus_shared_q', 'support records the lifted register signal');
    is($candidate->{lifted_runtime_reset_value}, "8'h00", 'support records the lifted reset value');

    my @net_names = map { $_->name } @{$plan->nets || []};
    is_deeply(
        \@net_names,
        [
            'left_status_bus__8_d1_src_en',
            'right_status_bus__8_d1_src_en',
            'status_bus_shared_en',
            'status_bus_multi_value_conflict',
            'status_bus__8_d1_shared_en',
            'status_bus__8_d1_multi_src_conflict',
            'status_bus_shared_next',
            'status_bus_shared_q',
            'shared_dp_raw_left_status_bus',
            'shared_dp_raw_right_status_bus',
        ],
        'support adds the bounded helper and raw-source net set',
    );
    my %nets_by_name = map { $_->name => $_ } @{$plan->nets || []};
    is($nets_by_name{shared_dp_raw_left_status_bus}->declared_type_name, 'byte_t', 'support preserves declared type identity on the left raw-source carrier net');
    is($nets_by_name{shared_dp_raw_right_status_bus}->declared_type_spec->{signed}, 1, 'support preserves declared type signedness on the right raw-source carrier net');
    is($nets_by_name{status_bus_shared_next}->declaration_keyword, 'logic', 'support promotes the lifted next-value carrier into one explicit logic net');
    is($nets_by_name{status_bus_shared_q}->declared_type_name, 'byte_t', 'support preserves declared type identity on the lifted shared register net');
    is($nets_by_name{status_bus_shared_q}->signed, 1, 'support preserves signedness on the lifted shared register net');
    ok(!defined($nets_by_name{status_bus_shared_en}->declared_type_name), 'helper enable nets stay intentionally untyped');

    my %left_bindings = map { $_->{port_name} => $_->{signal_name} } @{$plan->instances->[0]->port_bindings};
    my %right_bindings = map { $_->{port_name} => $_->{signal_name} } @{$plan->instances->[1]->port_bindings};
    my %consumer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$plan->instances->[2]->port_bindings};

    is($left_bindings{status_bus}, 'shared_dp_raw_left_status_bus', 'left contributor output is rebound to a private raw net');
    is($right_bindings{status_bus}, 'shared_dp_raw_right_status_bus', 'right contributor output is rebound to a private raw net');
    is($consumer_bindings{status_bus}, 'status_bus_shared_q', 'peer-read child input is rebound to the lifted shared register');
    is($left_bindings{shared_dp_export_status_bus_8_d1_en}, 'left_status_bus__8_d1_src_en', 'left source-export binding is added');
    is($right_bindings{shared_dp_export_status_bus_8_d1_en}, 'right_status_bus__8_d1_src_en', 'right source-export binding is added');

    my $aux = join("\n", @{$plan->auxiliary_assignments || []});
    like($aux, qr/assign status_bus__8_d1_shared_en = left_status_bus__8_d1_src_en \| right_status_bus__8_d1_src_en;/, 'support emits the aggregate enable helper assignment');
    like($aux, qr/assign status_bus__8_d1_multi_src_conflict = \(left_status_bus__8_d1_src_en & right_status_bus__8_d1_src_en\);/, 'support emits the same-value conflict helper assignment');
    unlike($aux, qr/logic \[7:0\] status_bus_shared_next;/, 'support no longer hides the lifted next-value declaration only in auxiliary text');
    unlike($aux, qr/logic \[7:0\] status_bus_shared_q;/, 'support no longer hides the lifted shared register declaration only in auxiliary text');
    like($aux, qr/assign left_status = status_bus_shared_q;/, 'support re-exports the lifted shared register through the first top output');
    like($aux, qr/assign right_status = status_bus_shared_q;/, 'support re-exports the lifted shared register through the second top output');
};

done_testing();

sub port {
    my ($name, $direction, $width, $type) = @_;
    return FSM::Composition::Port->new(
        name => $name,
        direction => $direction,
        width => $width,
        type => $type,
    );
}

sub input_port {
    my ($name, $width, $type) = @_;
    return port($name, 'input', $width, $type);
}

sub output_port {
    my ($name, $width, $type) = @_;
    return port($name, 'output', $width, $type);
}

sub realized_instance {
    my ($instance_name, $bindings, $ports, $shared_exports) = @_;
    return FSM::Composition::RealizedInstance->new(
        kind => 'fsmc',
        instance_name => $instance_name,
        module_name => $instance_name.'_mod',
        source_name => $instance_name.'_src',
        interface_ports => ($ports || []),
        port_bindings => ($bindings || []),
        module_info => {
            shared_datapath_source_exports => ($shared_exports || []),
        },
        hdl_code => undef,
    );
}
