#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Plan;
use FSM::Composition::Port;
use FSM::Composition::RealizedInstance;
use FSM::Composition::SharedDatapathCandidateBuilder;
use FSM::Composition::SharedDatapathSupport;
use FSM::IR::StructuralRTLIR;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    signal_ref_expr
    member_access_expr
    index_access_expr
    binding_signal_summary_leaf_signal
);

subtest 'composition system-signal inference only accepts flat leaf bindings' => sub {
    my $nonleaf_plan = FSM::Composition::Plan->new(
        top_name => 'nonleaf_system_top',
        ports => [],
        instances => [
            FSM::Composition::RealizedInstance->new(
                kind => 'fsmc',
                instance_name => 'u_cfg',
                module_name => 'cfg_mod',
                source_name => 'cfg_src',
                interface_ports => [
                    FSM::Composition::Port->new(name => 'clk', direction => 'input', width => 1, type => 'clock'),
                    FSM::Composition::Port->new(name => 'rstn', direction => 'input', width => 1, type => 'reset'),
                ],
                port_bindings => [
                    {
                        port_name => 'clk',
                        connection_expr => member_access_expr('sys_bundle', 'clk'),
                    },
                    {
                        port_name => 'rstn',
                        connection_expr => index_access_expr('reset_bus', 0),
                    },
                ],
            ),
        ],
    );

    my ($nonleaf_clock, $nonleaf_reset) = FSM::Composition::SharedDatapathSupport->system_signal_names($nonleaf_plan);
    is($nonleaf_clock // '', '', 'non-leaf clock bindings do not get misclassified as flat system carriers');
    is($nonleaf_reset // '', '', 'non-leaf reset bindings do not get misclassified as flat system carriers');

    my $leaf_plan = FSM::Composition::Plan->new(
        top_name => 'leaf_system_top',
        ports => [],
        instances => [
            FSM::Composition::RealizedInstance->new(
                kind => 'fsmc',
                instance_name => 'u_leaf',
                module_name => 'leaf_mod',
                source_name => 'leaf_src',
                interface_ports => [
                    FSM::Composition::Port->new(name => 'clk', direction => 'input', width => 1, type => 'clock'),
                    FSM::Composition::Port->new(name => 'rstn', direction => 'input', width => 1, type => 'reset'),
                ],
                port_bindings => [
                    {
                        port_name => 'clk',
                        connection_expr => signal_ref_expr('core_clk'),
                    },
                    {
                        port_name => 'rstn',
                        connection_expr => signal_ref_expr('core_rstn'),
                    },
                ],
            ),
        ],
    );

    my ($leaf_clock, $leaf_reset) = FSM::Composition::SharedDatapathSupport->system_signal_names($leaf_plan);
    is($leaf_clock, 'core_clk', 'flat clock bindings still infer the system clock name');
    is($leaf_reset, 'core_rstn', 'flat reset bindings still infer the system reset name');
};

subtest 'shared-datapath leaf-carrier helpers prefer typed structural expressions over stale mirrors' => sub {
    is(
        binding_signal_summary_leaf_signal({
            bound_signal => 'stale_status',
            bound_connection_expr => signal_ref_expr('typed_status'),
        }),
        'typed_status',
        'shared-datapath leaf binding lookup follows the typed signal-ref expression before the compatibility mirror',
    );

    is(
        binding_signal_summary_leaf_signal({
            bound_signal => 'stale_status',
            bound_connection_expr => member_access_expr('status_bundle', 'right'),
        }),
        '',
        'shared-datapath leaf binding lookup refuses to misclassify non-leaf typed expressions as flat carriers',
    );

    is(
        binding_signal_summary_leaf_signal({
            bound_signal => 'fallback_status',
        }),
        'fallback_status',
        'shared-datapath leaf binding lookup still falls back to the compatibility mirror when no typed expression is present',
    );
};

subtest 'shared-datapath candidate metadata distinguishes leaf carriers from richer dependency expressions' => sub {
    my $plan = FSM::Composition::Plan->new(
        top_name => 'shared_leaf_vs_dependency_top',
    );

    my $structural_rtl_ir = FSM::IR::StructuralRTLIR->new(
        module_name => 'shared_leaf_vs_dependency_top',
        source_root_kind => 'top',
        target_language => 'systemverilog',
        ports => [
            { name => 'status_top', direction => 'output', width => 1, type => 'wire' },
        ],
        nets => [],
        instances => [
            {
                kind => 'fsmc',
                instance_name => 'u_left',
                module_name => 'left_mod',
                source_name => 'left_src',
                interface_ports => [
                    { name => 'status', direction => 'output', width => 1, type => 'wire' },
                ],
                port_bindings => [
                    {
                        port_name => 'status',
                        connection_expr => signal_ref_expr('status_top'),
                    },
                ],
            },
            {
                kind => 'fsmc',
                instance_name => 'u_right',
                module_name => 'right_mod',
                source_name => 'right_src',
                interface_ports => [
                    { name => 'status', direction => 'output', width => 1, type => 'wire' },
                ],
                port_bindings => [
                    {
                        port_name => 'status',
                        connection_expr => member_access_expr('status_bundle', 'right'),
                    },
                ],
            },
        ],
        declared_links => [],
        resolved_links => [],
        auxiliary_assignments => [],
    );

    my $intent_hir = {
        composition_children => [
            {
                kind => 'fsmc',
                instance_name => 'u_left',
                module_name => 'left_mod',
                source_name => 'left_src',
                intent_hir => {},
                lowered_rtl_ir => {
                    output_drive_families => [
                        {
                            signal_name => 'status',
                            multiplexer_type => 'flop',
                            reset_value => '0',
                            rhs_enable_families => [],
                        },
                    ],
                },
                structural_rtl_ir => {},
            },
            {
                kind => 'fsmc',
                instance_name => 'u_right',
                module_name => 'right_mod',
                source_name => 'right_src',
                intent_hir => {},
                lowered_rtl_ir => {
                    output_drive_families => [
                        {
                            signal_name => 'status',
                            multiplexer_type => 'flop',
                            reset_value => '0',
                            rhs_enable_families => [],
                        },
                    ],
                },
                structural_rtl_ir => {},
            },
        ],
    };

    my $candidates = FSM::Composition::SharedDatapathCandidateBuilder->build_candidates(
        composition_plan => $plan,
        structural_rtl_ir => $structural_rtl_ir,
        intent_hir => $intent_hir,
        target_language => 'systemverilog',
    );

    is(scalar(@$candidates), 1, 'one shared-datapath candidate is still discovered');
    my $candidate = $candidates->[0];

    is_deeply(
        $candidate->{top_output_signals},
        ['status_top'],
        'only flat leaf carrier bindings count as preserved top-output carriers',
    );

    is_deeply(
        $candidate->{contributors},
        [
            {
                kind => 'fsmc',
                instance_name => 'u_left',
                module_name => 'left_mod',
                source_name => 'left_src',
                endpoint => 'u_left.status',
                bound_signal => 'status_top',
                bound_signals => ['status_top'],
                bound_connection_expr => {
                    kind => 'signal_ref',
                    signal_name => 'status_top',
                },
                intent_hir => {},
                lowered_rtl_ir => {
                    output_drive_families => [
                        {
                            signal_name => 'status',
                            multiplexer_type => 'flop',
                            reset_value => '0',
                            rhs_enable_families => [],
                        },
                    ],
                },
                structural_rtl_ir => {},
                output_drive_family => {
                    signal_name => 'status',
                    multiplexer_type => 'flop',
                    reset_value => '0',
                    rhs_enable_families => [],
                },
                drive_intent => {
                    multiplexer_type => 'flop',
                    default_value => undef,
                    reset_value => '0',
                    driver_count => 0,
                    driver_blocks => [],
                    rhs_values => [],
                    driver_enable_signals => [],
                    family_enable_signals => [],
                    rhs_enable_families => [],
                },
            },
            {
                kind => 'fsmc',
                instance_name => 'u_right',
                module_name => 'right_mod',
                source_name => 'right_src',
                endpoint => 'u_right.status',
                bound_signal => '',
                bound_signals => ['status_bundle'],
                bound_connection_expr => {
                    kind => 'member_access',
                    member_name => 'right',
                    source_expr => {
                        kind => 'signal_ref',
                        signal_name => 'status_bundle',
                    },
                },
                intent_hir => {},
                lowered_rtl_ir => {
                    output_drive_families => [
                        {
                            signal_name => 'status',
                            multiplexer_type => 'flop',
                            reset_value => '0',
                            rhs_enable_families => [],
                        },
                    ],
                },
                structural_rtl_ir => {},
                output_drive_family => {
                    signal_name => 'status',
                    multiplexer_type => 'flop',
                    reset_value => '0',
                    rhs_enable_families => [],
                },
                drive_intent => {
                    multiplexer_type => 'flop',
                    default_value => undef,
                    reset_value => '0',
                    driver_count => 0,
                    driver_blocks => [],
                    rhs_values => [],
                    driver_enable_signals => [],
                    family_enable_signals => [],
                    rhs_enable_families => [],
                },
            },
        ],
        'shared-datapath contributor metadata now keeps the typed binding expression alongside dependency lists without mislabeling non-leaf bindings as flat carriers',
    );
};

done_testing();
