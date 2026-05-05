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

sub provenance_report {
    return {
        resolved_link_count => 1,
        override_count => 1,
        block_count => 0,
        port_origin_counts => {
            authored_top_port => 2,
        },
        override_events => [
            {
                kind => 'explicit_toplink_overrides_same_name_top_input_convention',
                source_context => {
                    endpoint => 'child.ready',
                },
            },
        ],
    };
}

subtest 'module_info provenance report is isolated from source report mutation' => sub {
    my $source_report = provenance_report();
    my $module_info = FSM::Composition::ResultMetadataBuilder->build_module_info(
        composition_plan => composition_plan(),
        composition_report => $source_report,
        composition_child_exports => {
            child_count => 0,
            children => [],
        },
        intent_hir => intent_hir_payload(),
        lowered_rtl_ir => lowered_rtl_payload(),
        structural_rtl_ir => structural_rtl_payload(),
    );

    $module_info->{composition_provenance}{port_origin_counts}{authored_top_port} = 99;
    $module_info->{composition_provenance}{override_events}[0]{source_context}{endpoint}
        = 'mutated.endpoint';

    is_deeply(
        $source_report,
        provenance_report(),
        'mutating module_info provenance cannot contaminate source composition report',
    );
};

subtest 'statistics provenance report is isolated from source report mutation' => sub {
    my $source_report = provenance_report();
    my $statistics = FSM::Composition::ResultMetadataBuilder->build_statistics(
        composition_plan => composition_plan(),
        composition_report => $source_report,
        intent_hir => intent_hir_payload(),
        lowered_rtl_ir => lowered_rtl_payload(),
        structural_rtl_ir => structural_rtl_payload(),
        statistics_seed => {
            intermediate_signals => 0,
            global_expressions => 0,
            reused_expressions => [],
            factoring_enabled => 0,
        },
    );

    $statistics->{composition_provenance}{port_origin_counts}{authored_top_port} = 99;
    $statistics->{composition_provenance}{override_events}[0]{source_context}{endpoint}
        = 'mutated.endpoint';

    is_deeply(
        $source_report,
        provenance_report(),
        'mutating statistics provenance cannot contaminate source composition report',
    );
};

done_testing();
