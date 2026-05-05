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
        regular_state_count => 0,
        regular_state_names => [],
        standalone_dt_count => 0,
        standalone_dt_names => [],
        signal_count => 0,
        signal_names => [],
        signal_analysis => {
            inputs => [],
            outputs => [],
            multi_bit => [],
            single_bit => [],
        },
        system_contract => {},
        requires_implicit_system_ports => 0,
        parameter_count => 0,
        parameter_names => [],
        state_count => 0,
        composition_lane => 'C3',
    };
}

sub lowered_rtl_payload {
    return {
        module_name => 'metadata_top',
        source_root_kind => 'composition',
        output_drive_family_count => 0,
        output_drive_families => [],
        standalone_dt_multi_drive_target_count => 0,
        standalone_dt_multi_drive_targets => [],
        internal_net_count => 0,
        internal_net_names => [],
        instance_count => 0,
        instance_names => [],
        auxiliary_assignment_count => 0,
        composition_shared_datapath_candidate_count => 0,
        composition_shared_datapath_candidates => [],
    };
}

sub structural_rtl_payload {
    return {
        module_name => 'metadata_top',
        source_root_kind => 'composition',
        target_language => 'systemverilog',
        ports => [],
        nets => [],
        instances => [],
        declared_links => [],
        resolved_links => [],
        auxiliary_assignments => [],
    };
}

sub composition_child_exports {
    return {
        child_count => 1,
        children => [
            {
                instance_name => 'producer',
                intent_hir => {
                    standalone_dt_names => ['-route'],
                },
            },
        ],
    };
}

sub generated_child_exports {
    return {
        child_count => 1,
        fsm_child_count => 0,
        dt_child_count => 1,
        children => [
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
    };
}

sub standalone_dt_child_exports {
    return {
        child_count => 1,
        block_count => 1,
        multi_drive_target_count => 1,
        children => [
            {
                instance_name => 'producer',
                standalone_dt_names => ['-route'],
                standalone_dt_multi_drive_targets => [
                    {
                        signal_name => 'serial_payload',
                        dt_names => ['-route'],
                    },
                ],
            },
        ],
    };
}

subtest 'module_info child-export fallbacks are isolated from source exports' => sub {
    my $source_child_exports = composition_child_exports();
    my $source_generated_exports = generated_child_exports();
    my $source_standalone_exports = standalone_dt_child_exports();

    my $module_info = FSM::Composition::ResultMetadataBuilder->build_module_info(
        composition_plan => composition_plan(),
        composition_report => undef,
        composition_child_exports => $source_child_exports,
        generated_child_exports => $source_generated_exports,
        standalone_dt_child_exports => $source_standalone_exports,
        intent_hir => intent_hir_payload(),
        lowered_rtl_ir => lowered_rtl_payload(),
        structural_rtl_ir => structural_rtl_payload(),
    );

    $module_info->{composition_children}[0]{intent_hir}{standalone_dt_names}[0]
        = 'mutated_child';
    $module_info->{composition_generated_children}[0]{lowered_rtl_ir}{output_drive_families}[0]{signal_name}
        = 'mutated_generated';
    $module_info->{composition_standalone_dt_children}[0]{standalone_dt_multi_drive_targets}[0]{dt_names}[0]
        = 'mutated_standalone';

    is_deeply(
        $source_child_exports,
        composition_child_exports(),
        'composition child export mutation cannot contaminate source child exports',
    );
    is_deeply(
        $source_generated_exports,
        generated_child_exports(),
        'generated child export mutation cannot contaminate source generated exports',
    );
    is_deeply(
        $source_standalone_exports,
        standalone_dt_child_exports(),
        'standalone-DT child export mutation cannot contaminate source standalone exports',
    );
};

done_testing();
