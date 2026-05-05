#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Port;
use FSM::Composition::RealizedInstance;

subtest 'RealizedInstance constructor and accessors return caller-owned structured payloads' => sub {
    my $interface_port = FSM::Composition::Port->new(
        name => 'data_in',
        direction => 'input',
        width => 8,
        signed => 1,
        state_model => 'four_state',
        declared_type_name => 'byte_t',
        declared_type_spec => {
            kind => 'logic',
            width => 8,
            signed => 1,
        },
        type => 'data',
        binding_mode => 'explicit',
        raw_token => 'data_in<8:data',
        origin_kind => 'rtlif',
    );
    my $interface_ports = [$interface_port];
    my $port_bindings = [
        {
            port_name => 'data_in',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'top_data',
            },
        },
    ];
    my $parameter_overrides = [
        {
            name => 'WIDTH',
            value_kind => 'scalar',
            value => '8',
        },
    ];
    my $module_info = {
        metadata_path => 'child.rtlif',
        parameter_declarations => [
            {
                name => 'WIDTH',
                default => '8',
            },
        ],
        structural_rtl_ir => {
            ports => [
                {
                    name => 'data_in',
                    width => 8,
                },
            ],
        },
    };

    my $instance = FSM::Composition::RealizedInstance->new(
        kind => 'rtl',
        instance_name => 'child_a',
        module_name => 'child_mod',
        source_name => 'child_src',
        interface_ports => $interface_ports,
        port_bindings => $port_bindings,
        parameter_overrides => $parameter_overrides,
        module_info => $module_info,
        hdl_code => undef,
    );

    push @$interface_ports, FSM::Composition::Port->new(
        name => 'mutated_after_constructor',
        direction => 'output',
    );
    $interface_port->set_width(99);
    $interface_port->set_declared_type_spec({ kind => 'logic', width => 99 });
    $port_bindings->[0]{connection_expr}{signal_name} = 'mutated_after_constructor';
    $parameter_overrides->[0]{value} = '99';
    $module_info->{structural_rtl_ir}{ports}[0]{width} = 99;

    my $first_ports = $instance->interface_ports;
    my $first_bindings = $instance->port_bindings;
    my $first_overrides = $instance->parameter_overrides;
    my $first_module_info = $instance->module_info;

    $first_ports->[0]->set_width(32);
    $first_ports->[0]->set_declared_type_spec({ kind => 'logic', width => 32 });
    push @$first_ports, FSM::Composition::Port->new(
        name => 'mutated_after_accessor',
        direction => 'output',
    );
    $first_bindings->[0]{connection_expr}{signal_name} = 'mutated_after_accessor';
    $first_overrides->[0]{value} = '32';
    $first_module_info->{structural_rtl_ir}{ports}[0]{width} = 32;

    my $second_ports = $instance->interface_ports;
    is(scalar(@$second_ports), 1, 'interface_ports returns a caller-owned array');
    isa_ok($second_ports->[0], 'FSM::Composition::Port');
    isnt($second_ports->[0], $interface_port, 'constructor clones interface port objects');
    isnt($second_ports->[0], $first_ports->[0], 'accessor returns a fresh interface port object');
    is($second_ports->[0]->name, 'data_in', 'interface port name is preserved');
    is($second_ports->[0]->width, 8, 'interface port width is isolated from constructor and accessor mutation');
    is(
        $second_ports->[0]->declared_type_spec->{width},
        8,
        'interface port declared type spec is isolated from constructor and accessor mutation',
    );

    is_deeply(
        $instance->port_bindings,
        [
            {
                port_name => 'data_in',
                signal_name => 'top_data',
                connection_expr => {
                    kind => 'signal_ref',
                    signal_name => 'top_data',
                },
            },
        ],
        'port_bindings is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $instance->parameter_overrides,
        [
            {
                name => 'WIDTH',
                value_kind => 'scalar',
                value => '8',
            },
        ],
        'parameter_overrides is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $instance->module_info,
        {
            metadata_path => 'child.rtlif',
            parameter_declarations => [
                {
                    name => 'WIDTH',
                    default => '8',
                },
            ],
            structural_rtl_ir => {
                ports => [
                    {
                        name => 'data_in',
                        width => 8,
                    },
                ],
            },
        },
        'module_info is isolated from constructor and accessor mutation',
    );
};

done_testing();
