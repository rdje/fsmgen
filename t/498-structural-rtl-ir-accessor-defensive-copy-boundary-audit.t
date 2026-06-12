#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::StructuralRTLIR;

subtest 'StructuralRTLIR constructor and collection accessors return caller-owned copies' => sub {
    my $ports = [
        {
            name => 'clk',
            direction => 'input',
            width => 1,
            declared_type_spec => {
                kind => 'logic',
            },
        },
    ];
    my $nets = [
        {
            name => 'status',
            width => 8,
        },
    ];
    my $instances = [
        {
            instance_name => 'child_a',
            module_name => 'child_mod',
            interface_ports => [
                {
                    name => 'status',
                    direction => 'output',
                },
            ],
        },
    ];
    my $declared_links = [
        {
            source => 'child_a.status',
            target => 'status',
        },
    ];
    my $resolved_links = [
        {
            source => 'child_a.status',
            target => 'status',
            origin_kind => 'wiring',
        },
    ];
    my $assignment_records = [
        {
            kind => 'continuous_assign',
            lhs => {
                kind => 'signal_ref',
                name => 'status',
            },
            rhs => {
                kind => 'expression',
                ast => {
                    kind => 'signal_ref',
                    name => 'child_a_status',
                },
            },
        },
    ];
    my $auxiliary_assignments = [
        {
            lhs => 'status',
            rhs => {
                kind => 'signal_ref',
                signal => 'child_a_status',
            },
        },
    ];

    my $structural_rtl_ir = FSM::IR::StructuralRTLIR->new(
        module_name => 'structural_accessor_copy_top',
        source_root_kind => 'composition',
        target_language => 'systemverilog',
        ports => $ports,
        nets => $nets,
        instances => $instances,
        declared_links => $declared_links,
        resolved_links => $resolved_links,
        assignment_records => $assignment_records,
        auxiliary_assignments => $auxiliary_assignments,
    );

    $ports->[0]{declared_type_spec}{kind} = 'mutated_after_constructor';
    $nets->[0]{name} = 'mutated_after_constructor';
    $instances->[0]{interface_ports}[0]{name} = 'mutated_after_constructor';
    $declared_links->[0]{source} = 'mutated_after_constructor';
    $resolved_links->[0]{origin_kind} = 'mutated_after_constructor';
    $assignment_records->[0]{rhs}{ast}{name} = 'mutated_after_constructor';
    $auxiliary_assignments->[0]{rhs}{signal} = 'mutated_after_constructor';

    my $first_ports = $structural_rtl_ir->ports;
    my $first_nets = $structural_rtl_ir->nets;
    my $first_instances = $structural_rtl_ir->instances;
    my $first_declared_links = $structural_rtl_ir->declared_links;
    my $first_resolved_links = $structural_rtl_ir->resolved_links;
    my $first_assignment_records = $structural_rtl_ir->assignment_records;
    my $first_auxiliary_assignments = $structural_rtl_ir->auxiliary_assignments;

    $first_ports->[0]{declared_type_spec}{kind} = 'mutated_after_accessor';
    $first_nets->[0]{width} = 99;
    $first_instances->[0]{interface_ports}[0]{direction} = 'mutated_after_accessor';
    $first_declared_links->[0]{target} = 'mutated_after_accessor';
    $first_resolved_links->[0]{source} = 'mutated_after_accessor';
    $first_assignment_records->[0]{rhs}{ast}{name} = 'mutated_after_accessor';
    $first_auxiliary_assignments->[0]{rhs}{signal} = 'mutated_after_accessor';

    is_deeply(
        $structural_rtl_ir->ports,
        [
            {
                name => 'clk',
                direction => 'input',
                width => 1,
                declared_type_spec => {
                    kind => 'logic',
                },
            },
        ],
        'ports is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $structural_rtl_ir->nets,
        [
            {
                name => 'status',
                width => 8,
            },
        ],
        'nets is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $structural_rtl_ir->instances,
        [
            {
                instance_name => 'child_a',
                module_name => 'child_mod',
                interface_ports => [
                    {
                        name => 'status',
                        direction => 'output',
                    },
                ],
            },
        ],
        'instances is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $structural_rtl_ir->declared_links,
        [
            {
                source => 'child_a.status',
                target => 'status',
            },
        ],
        'declared_links is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $structural_rtl_ir->resolved_links,
        [
            {
                source => 'child_a.status',
                target => 'status',
                origin_kind => 'wiring',
            },
        ],
        'resolved_links is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $structural_rtl_ir->assignment_records,
        [
            {
                kind => 'continuous_assign',
                lhs => {
                    kind => 'signal_ref',
                    name => 'status',
                },
                rhs => {
                    kind => 'expression',
                    ast => {
                        kind => 'signal_ref',
                        name => 'child_a_status',
                    },
                },
            },
        ],
        'assignment_records is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $structural_rtl_ir->auxiliary_assignments,
        [
            {
                lhs => 'status',
                rhs => {
                    kind => 'signal_ref',
                    signal => 'child_a_status',
                },
            },
        ],
        'auxiliary_assignments is isolated from constructor and accessor mutation',
    );
};

subtest 'helper summaries remain isolated after accessor-return mutation' => sub {
    my $structural_rtl_ir = FSM::IR::StructuralRTLIR->new(
        module_name => 'structural_accessor_helper_top',
        ports => [
            {
                name => 'ready',
                direction => 'output',
                width => 1,
            },
        ],
        instances => [
            {
                instance_name => 'child_a',
                module_name => 'child_mod',
                interface_ports => [
                    {
                        name => 'ready',
                        direction => 'output',
                    },
                ],
            },
        ],
    );

    my $ports = $structural_rtl_ir->ports;
    my $instances = $structural_rtl_ir->instances;
    $ports->[0]{direction} = 'mutated_after_accessor';
    $instances->[0]{interface_ports}[0]{name} = 'mutated_after_accessor';

    is(
        $structural_rtl_ir->as_hashref->{ports}[0]{direction},
        'output',
        'as_hashref is isolated from prior ports accessor-return mutation',
    );
    is(
        $structural_rtl_ir->port_metadata->{signal_analysis}{outputs}[0]{name},
        'ready',
        'port_metadata is isolated from prior ports accessor-return mutation',
    );
    is_deeply(
        $structural_rtl_ir->interface_signal_endpoints('ready', 'output'),
        [
            {
                endpoint => 'child_a.ready',
                instance_name => 'child_a',
                port_name => 'ready',
                instance => {
                    instance_name => 'child_a',
                    module_name => 'child_mod',
                    interface_ports => [
                        {
                            name => 'ready',
                            direction => 'output',
                        },
                    ],
                },
                port => {
                    name => 'ready',
                    direction => 'output',
                },
            },
        ],
        'interface endpoint helpers are isolated from prior instances accessor-return mutation',
    );
};

done_testing();
