package FSM::Support::HDLGeneratorModuleInfoContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_hdl_generator_module_info_contract
    hdl_generator_module_info_contract_source
    hdl_generator_module_info_identity_keys
    hdl_generator_module_info_optional_composition_summary_keys
    hdl_generator_module_info_stable_subsurfaces
    hdl_generator_module_info_summary_keys
);

sub hdl_generator_module_info_contract_source {
    return 'FSM::Support::HDLGeneratorModuleInfoContract';
}

sub build_hdl_generator_module_info_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => hdl_generator_module_info_contract_source(),
        object_name => 'module_info',
        parent_object_name => 'HDLGeneratorResult.module_info',
        report_sources => [
            qw(
                FSM::Pipeline::HDLGenerator
            ),
        ],
        entrypoints => {
            in_process => [
                'FSM::Pipeline::HDLGenerator->new(...)->generate_hdl_from_file($path)->{module_info}',
            ],
        },
        identity_presence_keys => hdl_generator_module_info_identity_keys(),
        summary_presence_keys => hdl_generator_module_info_summary_keys(),
        optional_composition_summary_keys => hdl_generator_module_info_optional_composition_summary_keys(),
        stable_subsurfaces => hdl_generator_module_info_stable_subsurfaces(),
        full_hash_stable => JSON::PP::false,
        json_safe_as_whole => JSON::PP::false,
        guidance => [
            q{Treat this contract as the bounded nested `module_info` object reused by in-process `HDLGenerator` results.},
            'The bounded public promise covers the current module identity keys, the current scalar summary keys, and the current composition-only scalar summary keys.',
            'The wider module_info hash remains compatibility-heavy, so callers should target the advertised stable subsurfaces instead of treating the whole hash as public API.',
        ],
    };
}

sub hdl_generator_module_info_identity_keys {
    return [qw(
        module_name
        source_root_kind
    )];
}

sub hdl_generator_module_info_summary_keys {
    return [qw(
        output_drive_family_count
        parameter_count
        regular_state_count
        requires_implicit_system_ports
        signal_count
        standalone_dt_count
        standalone_dt_multi_drive_target_count
        state_count
    )];
}

sub hdl_generator_module_info_optional_composition_summary_keys {
    return [qw(
        auxiliary_assignment_count
        composition_block_count
        composition_child_count
        composition_generated_child_count
        composition_generated_dt_child_count
        composition_generated_fsm_child_count
        composition_lane
        composition_net_count
        composition_override_count
        composition_resolved_link_count
        composition_shared_datapath_candidate_count
        composition_standalone_dt_block_count
        composition_standalone_dt_child_count
        composition_standalone_dt_multi_drive_target_count
        instance_count
        internal_net_count
    )];
}

sub hdl_generator_module_info_stable_subsurfaces {
    return [
        qw(
            module_info.module_name
            module_info.source_root_kind
            module_info.output_drive_family_count
            module_info.parameter_count
            module_info.regular_state_count
            module_info.requires_implicit_system_ports
            module_info.signal_count
            module_info.standalone_dt_count
            module_info.standalone_dt_multi_drive_target_count
            module_info.state_count
            module_info.auxiliary_assignment_count
            module_info.composition_block_count
            module_info.composition_child_count
            module_info.composition_generated_child_count
            module_info.composition_generated_dt_child_count
            module_info.composition_generated_fsm_child_count
            module_info.composition_lane
            module_info.composition_net_count
            module_info.composition_override_count
            module_info.composition_resolved_link_count
            module_info.composition_shared_datapath_candidate_count
            module_info.composition_standalone_dt_block_count
            module_info.composition_standalone_dt_child_count
            module_info.composition_standalone_dt_multi_drive_target_count
            module_info.instance_count
            module_info.internal_net_count
        ),
    ];
}

1;
