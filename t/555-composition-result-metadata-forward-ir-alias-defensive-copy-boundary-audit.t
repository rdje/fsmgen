#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Plan;
use FSM::Composition::ResultMetadataBuilder;

sub composition_plan {
    return FSM::Composition::Plan->new(
        lane => 'C3',
        top_name => 'metadata_top',
        ports => [],
        links => [],
        resolved_links => [],
        nets => [],
        instances => [],
        auxiliary_assignments => [],
        shared_datapath_candidates => [],
    );
}

sub intent_hir_payload {
    return {
        module_name => 'metadata_top',
        source_root_kind => 'composition',
        regular_state_count => 1,
        regular_state_names => ['idle'],
        standalone_dt_count => 1,
        standalone_dt_names => ['-route'],
        signal_count => 1,
        signal_names => ['serial_payload'],
        signal_analysis => {
            outputs => [
                {
                    name => 'serial_payload',
                    width => 8,
                },
            ],
        },
        explicit_system_contract => {
            ports => [
                {
                    name => 'clk',
                },
            ],
        },
        system_contract => {
            clock => 'clk',
        },
        requires_implicit_system_ports => 0,
        parameter_count => 1,
        parameter_names => ['DEPTH'],
        symbol_contract => {
            symbols => [
                {
                    name => 'serial_payload',
                },
            ],
        },
        state_count => 1,
        composition_lane => 'C3',
        composition_children => [
            {
                instance_name => 'producer',
                intent_hir => {
                    standalone_dt_names => ['-route'],
                },
            },
        ],
        composition_generated_children => [
            {
                instance_name => 'producer',
                lowered_rtl_ir => {
                    output_drive_families => [
                        {
                            signal_name => 'serial_payload',
                        },
                    ],
                },
            },
        ],
        composition_standalone_dt_children => [
            {
                instance_name => 'producer',
                standalone_dt_names => ['-route'],
            },
        ],
    };
}

sub lowered_rtl_payload {
    return {
        module_name => 'metadata_top',
        source_root_kind => 'composition',
        output_drive_family_count => 1,
        output_drive_families => [
            {
                signal_name => 'serial_payload',
                rhs_values => ["8'h01"],
            },
        ],
        standalone_dt_multi_drive_target_count => 1,
        standalone_dt_multi_drive_targets => [
            {
                signal_name => 'serial_payload',
                dt_names => ['-route'],
            },
        ],
        internal_net_count => 1,
        internal_net_names => ['producer_serial_payload'],
        instance_count => 1,
        instance_names => ['producer'],
        auxiliary_assignment_count => 0,
        composition_shared_datapath_candidate_count => 1,
        composition_shared_datapath_candidates => [
            {
                signal_name => 'serial_payload',
                contributors => [
                    {
                        endpoint => 'producer.serial_payload',
                    },
                ],
            },
        ],
    };
}

sub structural_rtl_payload {
    return {
        module_name => 'metadata_top',
        source_root_kind => 'composition',
        target_language => 'systemverilog',
        ports => [
            {
                name => 'serial_payload',
                direction => 'output',
                width => 8,
            },
        ],
        nets => [],
        instances => [],
        declared_links => [],
        resolved_links => [],
        auxiliary_assignments => [],
    };
}

subtest 'module_info top-level forward-IR projections do not alias embedded IR payloads' => sub {
    my $module_info = FSM::Composition::ResultMetadataBuilder->build_module_info(
        composition_plan => composition_plan(),
        composition_report => undef,
        composition_child_exports => {
            child_count => 0,
            children => [],
        },
        intent_hir => intent_hir_payload(),
        lowered_rtl_ir => lowered_rtl_payload(),
        structural_rtl_ir => structural_rtl_payload(),
    );

    $module_info->{regular_state_names}[0] = 'mutated_state';
    $module_info->{signal_analysis}{outputs}[0]{name} = 'mutated_signal';
    $module_info->{explicit_system_contract}{ports}[0]{name} = 'mutated_clk';
    $module_info->{parameter_names}[0] = 'MUTATED_DEPTH';
    $module_info->{composition_children}[0]{intent_hir}{standalone_dt_names}[0]
        = 'mutated_child';
    $module_info->{composition_generated_children}[0]{lowered_rtl_ir}{output_drive_families}[0]{signal_name}
        = 'mutated_generated';
    $module_info->{composition_standalone_dt_children}[0]{standalone_dt_names}[0]
        = 'mutated_standalone';

    is($module_info->{intent_hir}{regular_state_names}[0], 'idle', 'regular_state_names top-level projection is independent');
    is($module_info->{intent_hir}{signal_analysis}{outputs}[0]{name}, 'serial_payload', 'signal_analysis top-level projection is independent');
    is($module_info->{intent_hir}{explicit_system_contract}{ports}[0]{name}, 'clk', 'explicit_system_contract top-level projection is independent');
    is($module_info->{intent_hir}{parameter_names}[0], 'DEPTH', 'parameter_names top-level projection is independent');
    is($module_info->{intent_hir}{composition_children}[0]{intent_hir}{standalone_dt_names}[0], '-route', 'composition child top-level projection is independent');
    is($module_info->{intent_hir}{composition_generated_children}[0]{lowered_rtl_ir}{output_drive_families}[0]{signal_name}, 'serial_payload', 'generated child top-level projection is independent');
    is($module_info->{intent_hir}{composition_standalone_dt_children}[0]{standalone_dt_names}[0], '-route', 'standalone-DT child top-level projection is independent');
};

subtest 'module_info top-level lowered projections do not alias embedded lowered RTL' => sub {
    my $module_info = FSM::Composition::ResultMetadataBuilder->build_module_info(
        composition_plan => composition_plan(),
        composition_report => undef,
        composition_child_exports => {
            child_count => 0,
            children => [],
        },
        intent_hir => intent_hir_payload(),
        lowered_rtl_ir => lowered_rtl_payload(),
        structural_rtl_ir => structural_rtl_payload(),
    );

    $module_info->{output_drive_families}[0]{rhs_values}[0] = "8'hff";
    $module_info->{standalone_dt_multi_drive_targets}[0]{dt_names}[0] = 'mutated_route';
    $module_info->{internal_net_names}[0] = 'mutated_net';
    $module_info->{instance_names}[0] = 'mutated_instance';
    $module_info->{composition_shared_datapath_candidates}[0]{contributors}[0]{endpoint}
        = 'mutated.endpoint';

    is($module_info->{lowered_rtl_ir}{output_drive_families}[0]{rhs_values}[0], "8'h01", 'output_drive_families top-level projection is independent');
    is($module_info->{lowered_rtl_ir}{standalone_dt_multi_drive_targets}[0]{dt_names}[0], '-route', 'standalone_dt_multi_drive_targets top-level projection is independent');
    is($module_info->{lowered_rtl_ir}{internal_net_names}[0], 'producer_serial_payload', 'internal_net_names top-level projection is independent');
    is($module_info->{lowered_rtl_ir}{instance_names}[0], 'producer', 'instance_names top-level projection is independent');
    is($module_info->{lowered_rtl_ir}{composition_shared_datapath_candidates}[0]{contributors}[0]{endpoint}, 'producer.serial_payload', 'shared-datapath top-level projection is independent');
};

done_testing();
