#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::LoweredRTLIR;

subtest 'LoweredRTLIR constructor and array accessors return caller-owned copies' => sub {
    my $output_drive_families = [
        {
            signal_name => 'status',
            multiplexer_type => 'flop',
            rhs_enable_families => [
                {
                    enable_signal => 'status_en',
                },
            ],
        },
    ];
    my $standalone_dt_targets = [
        {
            signal_name => 'OUT',
            multiplexer_type => 'comb',
            dt_names => ['-from_a', '-from_b'],
        },
    ];
    my $selector_conflict_targets = [
        {
            signal_name => 'valid',
            multi_value_assertion => {
                input_enable_signals => ['valid_0_en', 'valid_1_en'],
            },
        },
    ];
    my $shared_datapath_candidates = [
        {
            group_name => 'shared_a',
            member_count => 2,
        },
    ];
    my $internal_net_names = ['internal_a', 'internal_b'];
    my $instance_names = ['child_a', 'child_b'];

    my $lowered_rtl_ir = FSM::IR::LoweredRTLIR->new(
        module_name => 'lowered_accessor_copy_top',
        source_root_kind => 'composition',
        output_drive_families => $output_drive_families,
        selector_conflict_targets => $selector_conflict_targets,
        standalone_dt_multi_drive_targets => $standalone_dt_targets,
        composition_shared_datapath_candidates => $shared_datapath_candidates,
        internal_net_names => $internal_net_names,
        instance_names => $instance_names,
        auxiliary_assignment_count => 1,
    );

    $output_drive_families->[0]{multiplexer_type} = 'mutated_after_constructor';
    $selector_conflict_targets->[0]{multi_value_assertion}{input_enable_signals}[0] = 'mutated_after_constructor';
    $standalone_dt_targets->[0]{dt_names}[0] = 'mutated_after_constructor';
    $shared_datapath_candidates->[0]{group_name} = 'mutated_after_constructor';
    $internal_net_names->[0] = 'mutated_after_constructor';
    $instance_names->[0] = 'mutated_after_constructor';

    my $first_output_families = $lowered_rtl_ir->output_drive_families;
    my $first_selector_targets = $lowered_rtl_ir->selector_conflict_targets;
    my $first_dt_targets = $lowered_rtl_ir->standalone_dt_multi_drive_targets;
    my $first_shared_candidates = $lowered_rtl_ir->composition_shared_datapath_candidates;
    my $first_internal_nets = $lowered_rtl_ir->internal_net_names;
    my $first_instances = $lowered_rtl_ir->instance_names;

    $first_output_families->[0]{rhs_enable_families}[0]{enable_signal} = 'mutated_after_accessor';
    $first_selector_targets->[0]{multi_value_assertion}{input_enable_signals}[1] = 'mutated_after_accessor';
    $first_dt_targets->[0]{dt_names}[1] = 'mutated_after_accessor';
    $first_shared_candidates->[0]{member_count} = 99;
    $first_internal_nets->[1] = 'mutated_after_accessor';
    $first_instances->[1] = 'mutated_after_accessor';

    is_deeply(
        $lowered_rtl_ir->output_drive_families,
        [
            {
                signal_name => 'status',
                multiplexer_type => 'flop',
                rhs_enable_families => [
                    {
                        enable_signal => 'status_en',
                    },
                ],
            },
        ],
        'output_drive_families is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $lowered_rtl_ir->standalone_dt_multi_drive_targets,
        [
            {
                signal_name => 'OUT',
                multiplexer_type => 'comb',
                dt_names => ['-from_a', '-from_b'],
            },
        ],
        'standalone_dt_multi_drive_targets is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $lowered_rtl_ir->selector_conflict_targets,
        [
            {
                signal_name => 'valid',
                multi_value_assertion => {
                    input_enable_signals => ['valid_0_en', 'valid_1_en'],
                },
            },
        ],
        'selector_conflict_targets is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $lowered_rtl_ir->composition_shared_datapath_candidates,
        [
            {
                group_name => 'shared_a',
                member_count => 2,
            },
        ],
        'composition_shared_datapath_candidates is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $lowered_rtl_ir->internal_net_names,
        ['internal_a', 'internal_b'],
        'internal_net_names is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $lowered_rtl_ir->instance_names,
        ['child_a', 'child_b'],
        'instance_names is isolated from constructor and accessor mutation',
    );
};

subtest 'as_hashref remains isolated after accessor-return mutation' => sub {
    my $lowered_rtl_ir = FSM::IR::LoweredRTLIR->new(
        module_name => 'lowered_accessor_hash_top',
        output_drive_families => [
            {
                signal_name => 'status',
                multiplexer_type => 'flop',
            },
        ],
        selector_conflict_targets => [
            {
                signal_name => 'valid',
                multi_value_assertion => {
                    input_enable_signals => ['valid_0_en', 'valid_1_en'],
                },
            },
        ],
    );

    my $families = $lowered_rtl_ir->output_drive_families;
    my $selector_targets = $lowered_rtl_ir->selector_conflict_targets;
    $families->[0]{multiplexer_type} = 'mutated_after_accessor';
    $selector_targets->[0]{multi_value_assertion}{input_enable_signals}[0] = 'mutated_after_accessor';

    is(
        $lowered_rtl_ir->as_hashref->{output_drive_families}[0]{multiplexer_type},
        'flop',
        'as_hashref is isolated from prior accessor-return mutation',
    );
    is(
        $lowered_rtl_ir->as_hashref->{selector_conflict_targets}[0]{multi_value_assertion}{input_enable_signals}[0],
        'valid_0_en',
        'as_hashref selector conflict targets are isolated from prior accessor-return mutation',
    );
};

done_testing();
