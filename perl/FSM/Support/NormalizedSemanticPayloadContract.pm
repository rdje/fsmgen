package FSM::Support::NormalizedSemanticPayloadContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::NormalizedSemanticCompositionContract qw(
    normalized_semantic_composition_child_entry_keys
    normalized_semantic_composition_child_parameter_override_entry_keys
    normalized_semantic_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_composition_contract_source
    normalized_semantic_composition_generated_child_entry_keys
    normalized_semantic_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_composition_presence_keys
    normalized_semantic_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_composition_shared_datapath_assertion_keys
    normalized_semantic_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_composition_standalone_dt_child_entry_keys
    normalized_semantic_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys
);
use FSM::Support::NormalizedSemanticExplicitSystemContract qw(
    normalized_semantic_explicit_system_contract_source
    normalized_semantic_explicit_system_contract_presence_keys
);
use FSM::Support::NormalizedSemanticForwardIRContract qw(
    normalized_semantic_forward_ir_contract_source
    normalized_semantic_forward_ir_intent_hir_contract_source
    normalized_semantic_forward_ir_intent_hir_composition_child_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_forward_ir_intent_hir_composition_generated_child_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds
    normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_entry_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_list_extension_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_record_extension_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys
    normalized_semantic_forward_ir_nested_presence_key_map
    normalized_semantic_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_forward_ir_intent_hir_presence_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_contract_source
    normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds
    normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning
    normalized_semantic_forward_ir_structural_rtl_ir_contract_source
    normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_presence_keys
    normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_forward_ir_presence_keys
);
use FSM::Support::NormalizedSemanticModuleContract qw(
    normalized_semantic_module_contract_source
    normalized_semantic_module_optional_metric_keys
    normalized_semantic_module_presence_keys
);
use FSM::Support::NormalizedSemanticSignalAnalysisContract qw(
    normalized_semantic_signal_analysis_contract_source
    normalized_semantic_signal_analysis_entry_presence_keys
    normalized_semantic_signal_analysis_presence_keys
);
use FSM::Support::NormalizedSemanticSystemContract qw(
    normalized_semantic_system_contract_source
    normalized_semantic_system_contract_presence_keys
);
use FSM::Support::NormalizedSemanticSymbolContract qw(
    normalized_semantic_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_symbol_contract_constant_value_entry_keys
    normalized_semantic_symbol_contract_enum_entry_value_kinds
    normalized_semantic_symbol_contract_enum_member_value_kinds
    normalized_semantic_symbol_contract_type_aggregate_value_kinds
    normalized_semantic_symbol_contract_type_entry_keys
    normalized_semantic_symbol_contract_type_list_extension_keys
    normalized_semantic_symbol_contract_type_record_extension_keys
    normalized_semantic_symbol_contract_type_scalar_value_kinds
    normalized_semantic_symbol_contract_type_state_model_extension_keys
    normalized_semantic_symbol_contract_source
    normalized_semantic_symbol_contract_presence_keys
);

our @EXPORT_OK = qw(
    build_normalized_semantic_payload_contract
    normalized_semantic_payload_contract_source
    normalized_semantic_payload_explicit_system_contract_keys
    normalized_semantic_payload_presence_key_family_map
    normalized_semantic_payload_nested_presence_key_map
    normalized_semantic_payload_optional_child_presence_keys
    normalized_semantic_payload_forward_ir_nested_contract_source_map
    normalized_semantic_payload_forward_ir_nested_presence_key_map
    normalized_semantic_payload_presence_keys
    normalized_semantic_payload_forward_ir_keys
    normalized_semantic_payload_forward_ir_intent_hir_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_child_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_list_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_record_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds
    normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning
    normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_keys
    normalized_semantic_payload_signal_analysis_entry_keys
    normalized_semantic_payload_signal_analysis_keys
    normalized_semantic_payload_system_contract_keys
    normalized_semantic_payload_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_payload_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_payload_symbol_contract_constant_value_entry_keys
    normalized_semantic_payload_symbol_contract_enum_entry_value_kinds
    normalized_semantic_payload_symbol_contract_enum_member_value_kinds
    normalized_semantic_payload_symbol_contract_type_aggregate_value_kinds
    normalized_semantic_payload_symbol_contract_type_entry_keys
    normalized_semantic_payload_symbol_contract_type_list_extension_keys
    normalized_semantic_payload_symbol_contract_type_record_extension_keys
    normalized_semantic_payload_symbol_contract_type_scalar_value_kinds
    normalized_semantic_payload_symbol_contract_type_state_model_extension_keys
    normalized_semantic_payload_symbol_contract_keys
    normalized_semantic_payload_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_payload_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_payload_composition_shared_datapath_assertion_keys
    normalized_semantic_payload_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_payload_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_payload_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_payload_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_payload_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_payload_composition_child_entry_keys
    normalized_semantic_payload_composition_child_parameter_override_entry_keys
    normalized_semantic_payload_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_payload_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_payload_composition_generated_child_entry_keys
    normalized_semantic_payload_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_payload_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_payload_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_payload_composition_standalone_dt_child_entry_keys
    normalized_semantic_payload_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_payload_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_payload_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_payload_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_payload_composition_keys
);

sub normalized_semantic_payload_contract_source {
    return 'FSM::Support::NormalizedSemanticPayloadContract';
}

sub build_normalized_semantic_payload_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => normalized_semantic_payload_contract_source(),
        object_name => 'semantic',
        report_sources => [
            qw(
                FSM::Support::NormalizedSemanticReport
            ),
        ],
        entrypoints => {
            cli => [
                './bin/fsmgen --strict --emit-semantic-json path/to/file.fsm',
            ],
            in_process => [
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)',
            ],
        },
        public_presence_keys => normalized_semantic_payload_presence_keys(),
        optional_child_presence_keys => normalized_semantic_payload_optional_child_presence_keys(),
        nested_contract_source_map => {
            module => normalized_semantic_module_contract_source(),
            explicit_system_contract => normalized_semantic_explicit_system_contract_source(),
            signal_analysis => normalized_semantic_signal_analysis_contract_source(),
            system_contract => normalized_semantic_system_contract_source(),
            forward_ir => normalized_semantic_forward_ir_contract_source(),
            symbol_contract => normalized_semantic_symbol_contract_source(),
            composition => normalized_semantic_composition_contract_source(),
        },
        nested_presence_key_map => normalized_semantic_payload_nested_presence_key_map(),
        presence_key_family_map => normalized_semantic_payload_presence_key_family_map(),
        module_contract_source => normalized_semantic_module_contract_source(),
        module_presence_keys => normalized_semantic_module_presence_keys(),
        module_optional_metric_keys => normalized_semantic_module_optional_metric_keys(),
        explicit_system_contract_source => normalized_semantic_explicit_system_contract_source(),
        signal_analysis_contract_source => normalized_semantic_signal_analysis_contract_source(),
        system_contract_source => normalized_semantic_system_contract_source(),
        forward_ir_contract_source => normalized_semantic_forward_ir_contract_source(),
        symbol_contract_source => normalized_semantic_symbol_contract_source(),
        symbol_contract_constant_value_entry_keys =>
            normalized_semantic_payload_symbol_contract_constant_value_entry_keys(),
        symbol_contract_constant_scalar_value_extension_keys =>
            normalized_semantic_payload_symbol_contract_constant_scalar_value_extension_keys(),
        symbol_contract_constant_list_value_extension_keys =>
            normalized_semantic_payload_symbol_contract_constant_list_value_extension_keys(),
        symbol_contract_enum_entry_value_kinds =>
            normalized_semantic_payload_symbol_contract_enum_entry_value_kinds(),
        symbol_contract_enum_member_value_kinds =>
            normalized_semantic_payload_symbol_contract_enum_member_value_kinds(),
        symbol_contract_type_entry_keys =>
            normalized_semantic_payload_symbol_contract_type_entry_keys(),
        symbol_contract_type_scalar_value_kinds =>
            normalized_semantic_payload_symbol_contract_type_scalar_value_kinds(),
        symbol_contract_type_aggregate_value_kinds =>
            normalized_semantic_payload_symbol_contract_type_aggregate_value_kinds(),
        symbol_contract_type_state_model_extension_keys =>
            normalized_semantic_payload_symbol_contract_type_state_model_extension_keys(),
        symbol_contract_type_list_extension_keys =>
            normalized_semantic_payload_symbol_contract_type_list_extension_keys(),
        symbol_contract_type_record_extension_keys =>
            normalized_semantic_payload_symbol_contract_type_record_extension_keys(),
        composition_contract_source => normalized_semantic_composition_contract_source(),
        explicit_system_contract_presence_keys => normalized_semantic_payload_explicit_system_contract_keys(),
        signal_analysis_presence_keys => normalized_semantic_payload_signal_analysis_keys(),
        signal_analysis_entry_presence_keys => normalized_semantic_payload_signal_analysis_entry_keys(),
        system_contract_presence_keys => normalized_semantic_payload_system_contract_keys(),
        forward_ir_presence_keys => normalized_semantic_payload_forward_ir_keys(),
        forward_ir_nested_contract_source_map => normalized_semantic_payload_forward_ir_nested_contract_source_map(),
        forward_ir_nested_presence_key_map => normalized_semantic_payload_forward_ir_nested_presence_key_map(),
        forward_ir_intent_hir_contract_source => normalized_semantic_forward_ir_intent_hir_contract_source(),
        forward_ir_intent_hir_presence_keys => normalized_semantic_payload_forward_ir_intent_hir_keys(),
        forward_ir_intent_hir_symbol_contract_constant_value_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys(),
        forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys(),
        forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys(),
        forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds(),
        forward_ir_intent_hir_symbol_contract_enum_member_value_kinds =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds(),
        forward_ir_intent_hir_symbol_contract_type_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_entry_keys(),
        forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds(),
        forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds(),
        forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys(),
        forward_ir_intent_hir_symbol_contract_type_list_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_list_extension_keys(),
        forward_ir_intent_hir_symbol_contract_type_record_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_record_extension_keys(),
        forward_ir_intent_hir_optional_composition_keys => normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys(),
        forward_ir_intent_hir_composition_child_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_entry_keys(),
        forward_ir_intent_hir_composition_child_parameter_override_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_entry_keys(),
        forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
        forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
        forward_ir_intent_hir_composition_generated_child_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_entry_keys(),
        forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys(),
        forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys(),
        forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        forward_ir_intent_hir_composition_standalone_dt_child_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys(),
        forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
        forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys(),
        forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
        forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
        forward_ir_lowered_rtl_ir_contract_source => normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
        forward_ir_lowered_rtl_ir_presence_keys => normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys(),
        forward_ir_lowered_rtl_ir_optional_composition_keys => normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        forward_ir_lowered_rtl_ir_output_drive_family_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        forward_ir_structural_rtl_ir_contract_source => normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        forward_ir_structural_rtl_ir_presence_keys => normalized_semantic_payload_forward_ir_structural_rtl_ir_keys(),
        forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        forward_ir_structural_rtl_ir_net_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys(),
        forward_ir_structural_rtl_ir_declared_link_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        forward_ir_structural_rtl_ir_resolved_link_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        forward_ir_structural_rtl_ir_instance_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys(),
        forward_ir_structural_rtl_ir_instance_interface_port_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        forward_ir_structural_rtl_ir_instance_port_binding_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        forward_ir_structural_rtl_ir_port_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys(),
        forward_ir_structural_rtl_ir_port_composition_extension_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        symbol_contract_presence_keys => normalized_semantic_payload_symbol_contract_keys(),
        composition_presence_keys => normalized_semantic_payload_composition_keys(),
        composition_child_entry_keys => normalized_semantic_payload_composition_child_entry_keys(),
        composition_child_parameter_override_entry_keys =>
            normalized_semantic_payload_composition_child_parameter_override_entry_keys(),
        composition_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_payload_composition_child_parameter_override_raw_value_extension_keys(),
        composition_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_payload_composition_child_parameter_override_value_metadata_extension_keys(),
        composition_generated_child_entry_keys =>
            normalized_semantic_payload_composition_generated_child_entry_keys(),
        composition_generated_child_parameter_override_entry_keys =>
            normalized_semantic_payload_composition_generated_child_parameter_override_entry_keys(),
        composition_generated_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_payload_composition_generated_child_parameter_override_raw_value_extension_keys(),
        composition_generated_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_payload_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        composition_standalone_dt_child_entry_keys =>
            normalized_semantic_payload_composition_standalone_dt_child_entry_keys(),
        composition_standalone_dt_enable_family_entry_keys =>
            normalized_semantic_payload_composition_standalone_dt_enable_family_entry_keys(),
        composition_standalone_dt_module_enable_family_keys =>
            normalized_semantic_payload_composition_standalone_dt_module_enable_family_keys(),
        composition_standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_payload_composition_standalone_dt_multi_drive_target_entry_keys(),
        composition_standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_payload_composition_standalone_dt_multi_drive_assertion_keys(),
        composition_shared_datapath_candidate_entry_keys =>
            normalized_semantic_payload_composition_shared_datapath_candidate_entry_keys(),
        composition_shared_datapath_candidate_declared_type_extension_keys =>
            normalized_semantic_payload_composition_shared_datapath_candidate_declared_type_extension_keys(),
        composition_shared_datapath_candidate_contributor_entry_keys =>
            normalized_semantic_payload_composition_shared_datapath_candidate_contributor_entry_keys(),
        composition_shared_datapath_candidate_contributor_declared_type_extension_keys =>
            normalized_semantic_payload_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        composition_shared_datapath_candidate_contributor_drive_intent_entry_keys =>
            normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys =>
            normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        composition_shared_datapath_bound_connection_expr_keys =>
            normalized_semantic_payload_composition_shared_datapath_bound_connection_expr_keys(),
        composition_shared_datapath_aggregate_enable_family_entry_keys =>
            normalized_semantic_payload_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        composition_shared_datapath_aggregate_enable_contributor_entry_keys =>
            normalized_semantic_payload_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        composition_shared_datapath_assertion_keys =>
            normalized_semantic_payload_composition_shared_datapath_assertion_keys(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic` object used by successful public normalized semantic JSON reports.},
            'The nested object records the public semantic payload: module/system metadata, signal analysis, and the forward-IR projection.',
            'The optional semantic children are advertised as a separate key family so composition and symbol-contract payload discovery does not depend on prose or nested owner maps alone.',
            'The nested `module` object stays bounded through FSM::Support::NormalizedSemanticModuleContract.',
            'The nested `explicit_system_contract` object, when present, stays bounded through FSM::Support::NormalizedSemanticExplicitSystemContract.',
            'The nested `signal_analysis` object stays bounded through FSM::Support::NormalizedSemanticSignalAnalysisContract.',
            'The nested `system_contract` object stays bounded through FSM::Support::NormalizedSemanticSystemContract.',
            'The nested `forward_ir` object stays bounded through FSM::Support::NormalizedSemanticForwardIRContract.',
            'The nested `symbol_contract` and `forward_ir.intent_hir.symbol_contract` constant value key families, enum value-kind families, and type-entry families stay delegated to FSM::Support::NormalizedSemanticSymbolContract.',
            'The nested `forward_ir.intent_hir` composition-child alias families, including child and generated-child parameter-override alias metadata, stay delegated to the already bounded composition child schema owners.',
            'Use the grouped `nested_presence_key_map` to discover the bounded key families for module, explicit_system_contract, signal_analysis, system_contract, forward_ir, symbol_contract, and composition without collecting those child key lists separately.',
            'Use the grouped `presence_key_family_map` to discover the shell-owned semantic payload, optional child, and child extension key families without collecting those field-family lists separately.',
            'Use the grouped `forward_ir_nested_presence_key_map` to discover the deeper bounded `forward_ir` child key families without collecting those nested child key lists separately.',
            'Use the grouped `forward_ir_nested_contract_source_map` to discover the deeper bounded `forward_ir` shell owners without reconstructing them from parallel scalar fields.',
            'Use the grouped output-drive entry key families to inspect `forward_ir.lowered_rtl_ir.output_drive_families` without binding to unrelated lowered-RTL internals.',
            'Use the grouped selector-conflict entry key families to inspect `forward_ir.lowered_rtl_ir.selector_conflict_targets` without binding to unrelated lowered-RTL internals.',
            'Use the grouped standalone-DT multi-drive entry key families to inspect `forward_ir.lowered_rtl_ir.standalone_dt_multi_drive_targets` without binding to unrelated lowered-RTL internals.',
            'Use the grouped composition shared-datapath candidate key families to inspect `forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates`, including contributor drive-intent projections and their rhs-enable-family entries, without binding to unrelated lowered-RTL internals.',
            'Use the grouped structural auxiliary-assignment value-kind, port, net, declared/resolved link, instance shallow, nested instance interface-port, nested instance parameter-override, and nested instance port-binding entry families to inspect `forward_ir.structural_rtl_ir.auxiliary_assignments`, `forward_ir.structural_rtl_ir.ports`, `forward_ir.structural_rtl_ir.nets`, `forward_ir.structural_rtl_ir.declared_links`, `forward_ir.structural_rtl_ir.resolved_links`, `forward_ir.structural_rtl_ir.instances`, `forward_ir.structural_rtl_ir.instances[].interface_ports`, `forward_ir.structural_rtl_ir.instances[].parameter_overrides`, and `forward_ir.structural_rtl_ir.instances[].port_bindings` without binding to unrelated structural-RTL collections.',
            'Use the grouped composition child and generated-child entry families to inspect `composition.children` and `composition.generated_children` shallow entries while delegating child IR summaries plus child/generated-child parameter-override metadata to their existing owners.',
            'Use the grouped composition standalone-DT child entry families to inspect `composition.standalone_dt_children` shallow entries, their enable-family metadata, and nested standalone-DT multi-drive target metadata while delegating child IR summaries and multi-drive assertions to their existing owners.',
            'Use the grouped composition shared-datapath alias key families to inspect `composition.shared_datapath_candidates` entries through the same bounded lowered-RTL shared-datapath candidate owner.',
            'The nested `forward_ir.intent_hir` object shell stays bounded through FSM::Support::NormalizedSemanticIntentHIRContract.',
            'The nested `forward_ir.lowered_rtl_ir` object shell stays bounded through FSM::Support::NormalizedSemanticLoweredRTLIRContract.',
            'The nested `forward_ir.structural_rtl_ir` object shell stays bounded through FSM::Support::NormalizedSemanticStructuralRTLIRContract.',
            'The optional nested `symbol_contract` object stays bounded through FSM::Support::NormalizedSemanticSymbolContract.',
            'The optional nested `composition` object stays bounded through FSM::Support::NormalizedSemanticCompositionContract.',
            'The same owner still advertises the nested `explicit_system_contract`, `signal_analysis`, shared signal-analysis entry, `system_contract`, `forward_ir`, nested `forward_ir.intent_hir`, nested `forward_ir.lowered_rtl_ir`, nested `forward_ir.structural_rtl_ir`, and optional `symbol_contract` plus `composition` key lists so payload widening stays deliberate and regression-backed.',
        ],
    };
}

sub normalized_semantic_payload_presence_keys {
    return [
        qw(
            module
            system_contract
            explicit_system_contract
            signal_analysis
            forward_ir
        ),
    ];
}

sub normalized_semantic_payload_optional_child_presence_keys {
    return [
        qw(
            composition
            symbol_contract
        ),
    ];
}

sub normalized_semantic_payload_nested_presence_key_map {
    return {
        module => normalized_semantic_module_presence_keys(),
        explicit_system_contract => normalized_semantic_payload_explicit_system_contract_keys(),
        signal_analysis => normalized_semantic_payload_signal_analysis_keys(),
        system_contract => normalized_semantic_payload_system_contract_keys(),
        forward_ir => normalized_semantic_payload_forward_ir_keys(),
        symbol_contract => normalized_semantic_payload_symbol_contract_keys(),
        composition => normalized_semantic_payload_composition_keys(),
    };
}

sub normalized_semantic_payload_presence_key_family_map {
    return {
        public_presence_keys => normalized_semantic_payload_presence_keys(),
        optional_child_presence_keys => normalized_semantic_payload_optional_child_presence_keys(),
        module_optional_metric_keys => normalized_semantic_module_optional_metric_keys(),
        signal_analysis_entry_presence_keys => normalized_semantic_payload_signal_analysis_entry_keys(),
        symbol_contract_constant_value_entry_keys =>
            normalized_semantic_payload_symbol_contract_constant_value_entry_keys(),
        symbol_contract_constant_scalar_value_extension_keys =>
            normalized_semantic_payload_symbol_contract_constant_scalar_value_extension_keys(),
        symbol_contract_constant_list_value_extension_keys =>
            normalized_semantic_payload_symbol_contract_constant_list_value_extension_keys(),
        symbol_contract_enum_entry_value_kinds =>
            normalized_semantic_payload_symbol_contract_enum_entry_value_kinds(),
        symbol_contract_enum_member_value_kinds =>
            normalized_semantic_payload_symbol_contract_enum_member_value_kinds(),
        symbol_contract_type_entry_keys =>
            normalized_semantic_payload_symbol_contract_type_entry_keys(),
        symbol_contract_type_scalar_value_kinds =>
            normalized_semantic_payload_symbol_contract_type_scalar_value_kinds(),
        symbol_contract_type_aggregate_value_kinds =>
            normalized_semantic_payload_symbol_contract_type_aggregate_value_kinds(),
        symbol_contract_type_state_model_extension_keys =>
            normalized_semantic_payload_symbol_contract_type_state_model_extension_keys(),
        symbol_contract_type_list_extension_keys =>
            normalized_semantic_payload_symbol_contract_type_list_extension_keys(),
        symbol_contract_type_record_extension_keys =>
            normalized_semantic_payload_symbol_contract_type_record_extension_keys(),
        forward_ir_intent_hir_symbol_contract_constant_value_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys(),
        forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys(),
        forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys(),
        forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds(),
        forward_ir_intent_hir_symbol_contract_enum_member_value_kinds =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds(),
        forward_ir_intent_hir_symbol_contract_type_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_entry_keys(),
        forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds(),
        forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds(),
        forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys(),
        forward_ir_intent_hir_symbol_contract_type_list_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_list_extension_keys(),
        forward_ir_intent_hir_symbol_contract_type_record_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_record_extension_keys(),
        forward_ir_intent_hir_optional_composition_keys => normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys(),
        forward_ir_intent_hir_composition_child_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_entry_keys(),
        forward_ir_intent_hir_composition_child_parameter_override_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_entry_keys(),
        forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
        forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
        forward_ir_intent_hir_composition_generated_child_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_entry_keys(),
        forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys(),
        forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys(),
        forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        forward_ir_intent_hir_composition_standalone_dt_child_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys(),
        forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
        forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys(),
        forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
        forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
        forward_ir_lowered_rtl_ir_optional_composition_keys => normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        forward_ir_lowered_rtl_ir_output_drive_family_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys =>
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        forward_ir_structural_rtl_ir_port_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys(),
        forward_ir_structural_rtl_ir_port_composition_extension_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        forward_ir_structural_rtl_ir_net_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys(),
        forward_ir_structural_rtl_ir_declared_link_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        forward_ir_structural_rtl_ir_resolved_link_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        forward_ir_structural_rtl_ir_instance_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys(),
        forward_ir_structural_rtl_ir_instance_interface_port_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        forward_ir_structural_rtl_ir_instance_port_binding_entry_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys =>
            normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        composition_child_entry_keys => normalized_semantic_payload_composition_child_entry_keys(),
        composition_child_parameter_override_entry_keys =>
            normalized_semantic_payload_composition_child_parameter_override_entry_keys(),
        composition_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_payload_composition_child_parameter_override_raw_value_extension_keys(),
        composition_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_payload_composition_child_parameter_override_value_metadata_extension_keys(),
        composition_generated_child_entry_keys =>
            normalized_semantic_payload_composition_generated_child_entry_keys(),
        composition_generated_child_parameter_override_entry_keys =>
            normalized_semantic_payload_composition_generated_child_parameter_override_entry_keys(),
        composition_generated_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_payload_composition_generated_child_parameter_override_raw_value_extension_keys(),
        composition_generated_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_payload_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        composition_standalone_dt_child_entry_keys =>
            normalized_semantic_payload_composition_standalone_dt_child_entry_keys(),
        composition_standalone_dt_enable_family_entry_keys =>
            normalized_semantic_payload_composition_standalone_dt_enable_family_entry_keys(),
        composition_standalone_dt_module_enable_family_keys =>
            normalized_semantic_payload_composition_standalone_dt_module_enable_family_keys(),
        composition_standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_payload_composition_standalone_dt_multi_drive_target_entry_keys(),
        composition_standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_payload_composition_standalone_dt_multi_drive_assertion_keys(),
        composition_shared_datapath_candidate_entry_keys =>
            normalized_semantic_payload_composition_shared_datapath_candidate_entry_keys(),
        composition_shared_datapath_candidate_declared_type_extension_keys =>
            normalized_semantic_payload_composition_shared_datapath_candidate_declared_type_extension_keys(),
        composition_shared_datapath_candidate_contributor_entry_keys =>
            normalized_semantic_payload_composition_shared_datapath_candidate_contributor_entry_keys(),
        composition_shared_datapath_candidate_contributor_declared_type_extension_keys =>
            normalized_semantic_payload_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        composition_shared_datapath_candidate_contributor_drive_intent_entry_keys =>
            normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys =>
            normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        composition_shared_datapath_bound_connection_expr_keys =>
            normalized_semantic_payload_composition_shared_datapath_bound_connection_expr_keys(),
        composition_shared_datapath_aggregate_enable_family_entry_keys =>
            normalized_semantic_payload_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        composition_shared_datapath_aggregate_enable_contributor_entry_keys =>
            normalized_semantic_payload_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        composition_shared_datapath_assertion_keys =>
            normalized_semantic_payload_composition_shared_datapath_assertion_keys(),
    };
}

sub normalized_semantic_payload_forward_ir_keys {
    return normalized_semantic_forward_ir_presence_keys();
}

sub normalized_semantic_payload_forward_ir_nested_contract_source_map {
    return {
        intent_hir => normalized_semantic_forward_ir_intent_hir_contract_source(),
        lowered_rtl_ir => normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
        structural_rtl_ir => normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
    };
}

sub normalized_semantic_payload_forward_ir_nested_presence_key_map {
    return normalized_semantic_forward_ir_nested_presence_key_map();
}

sub normalized_semantic_payload_forward_ir_intent_hir_keys {
    return normalized_semantic_forward_ir_intent_hir_presence_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys {
    return normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys {
    return normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys {
    return normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds {
    return normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds();
}

sub normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds {
    return normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds();
}

sub normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_entry_keys {
    return normalized_semantic_forward_ir_intent_hir_symbol_contract_type_entry_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds {
    return normalized_semantic_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds();
}

sub normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds {
    return normalized_semantic_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds();
}

sub normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys {
    return normalized_semantic_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_list_extension_keys {
    return normalized_semantic_forward_ir_intent_hir_symbol_contract_type_list_extension_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_record_extension_keys {
    return normalized_semantic_forward_ir_intent_hir_symbol_contract_type_record_extension_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys {
    return normalized_semantic_forward_ir_intent_hir_optional_composition_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_composition_child_entry_keys {
    return normalized_semantic_forward_ir_intent_hir_composition_child_entry_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_entry_keys {
    return normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys {
    return normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys {
    return normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_entry_keys {
    return normalized_semantic_forward_ir_intent_hir_composition_generated_child_entry_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys {
    return normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys {
    return normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys {
    return normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys {
    return normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys {
    return normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys {
    return normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys {
    return normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys {
    return normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_presence_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds {
    return normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning {
    return normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys();
}

sub normalized_semantic_payload_explicit_system_contract_keys {
    return normalized_semantic_explicit_system_contract_presence_keys();
}

sub normalized_semantic_payload_signal_analysis_keys {
    return normalized_semantic_signal_analysis_presence_keys();
}

sub normalized_semantic_payload_signal_analysis_entry_keys {
    return normalized_semantic_signal_analysis_entry_presence_keys();
}

sub normalized_semantic_payload_system_contract_keys {
    return normalized_semantic_system_contract_presence_keys();
}

sub normalized_semantic_payload_symbol_contract_keys {
    return normalized_semantic_symbol_contract_presence_keys();
}

sub normalized_semantic_payload_symbol_contract_constant_value_entry_keys {
    return normalized_semantic_symbol_contract_constant_value_entry_keys();
}

sub normalized_semantic_payload_symbol_contract_constant_scalar_value_extension_keys {
    return normalized_semantic_symbol_contract_constant_scalar_value_extension_keys();
}

sub normalized_semantic_payload_symbol_contract_constant_list_value_extension_keys {
    return normalized_semantic_symbol_contract_constant_list_value_extension_keys();
}

sub normalized_semantic_payload_symbol_contract_enum_entry_value_kinds {
    return normalized_semantic_symbol_contract_enum_entry_value_kinds();
}

sub normalized_semantic_payload_symbol_contract_enum_member_value_kinds {
    return normalized_semantic_symbol_contract_enum_member_value_kinds();
}

sub normalized_semantic_payload_symbol_contract_type_entry_keys {
    return normalized_semantic_symbol_contract_type_entry_keys();
}

sub normalized_semantic_payload_symbol_contract_type_scalar_value_kinds {
    return normalized_semantic_symbol_contract_type_scalar_value_kinds();
}

sub normalized_semantic_payload_symbol_contract_type_aggregate_value_kinds {
    return normalized_semantic_symbol_contract_type_aggregate_value_kinds();
}

sub normalized_semantic_payload_symbol_contract_type_state_model_extension_keys {
    return normalized_semantic_symbol_contract_type_state_model_extension_keys();
}

sub normalized_semantic_payload_symbol_contract_type_list_extension_keys {
    return normalized_semantic_symbol_contract_type_list_extension_keys();
}

sub normalized_semantic_payload_symbol_contract_type_record_extension_keys {
    return normalized_semantic_symbol_contract_type_record_extension_keys();
}

sub normalized_semantic_payload_composition_keys {
    return normalized_semantic_composition_presence_keys();
}

sub normalized_semantic_payload_composition_child_entry_keys {
    return normalized_semantic_composition_child_entry_keys();
}

sub normalized_semantic_payload_composition_child_parameter_override_entry_keys {
    return normalized_semantic_composition_child_parameter_override_entry_keys();
}

sub normalized_semantic_payload_composition_child_parameter_override_raw_value_extension_keys {
    return normalized_semantic_composition_child_parameter_override_raw_value_extension_keys();
}

sub normalized_semantic_payload_composition_child_parameter_override_value_metadata_extension_keys {
    return normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys();
}

sub normalized_semantic_payload_composition_generated_child_entry_keys {
    return normalized_semantic_composition_generated_child_entry_keys();
}

sub normalized_semantic_payload_composition_generated_child_parameter_override_entry_keys {
    return normalized_semantic_composition_generated_child_parameter_override_entry_keys();
}

sub normalized_semantic_payload_composition_generated_child_parameter_override_raw_value_extension_keys {
    return normalized_semantic_composition_generated_child_parameter_override_raw_value_extension_keys();
}

sub normalized_semantic_payload_composition_generated_child_parameter_override_value_metadata_extension_keys {
    return normalized_semantic_composition_generated_child_parameter_override_value_metadata_extension_keys();
}

sub normalized_semantic_payload_composition_standalone_dt_child_entry_keys {
    return normalized_semantic_composition_standalone_dt_child_entry_keys();
}

sub normalized_semantic_payload_composition_standalone_dt_enable_family_entry_keys {
    return normalized_semantic_composition_standalone_dt_enable_family_entry_keys();
}

sub normalized_semantic_payload_composition_standalone_dt_module_enable_family_keys {
    return normalized_semantic_composition_standalone_dt_module_enable_family_keys();
}

sub normalized_semantic_payload_composition_standalone_dt_multi_drive_target_entry_keys {
    return normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys();
}

sub normalized_semantic_payload_composition_standalone_dt_multi_drive_assertion_keys {
    return normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys();
}

sub normalized_semantic_payload_composition_shared_datapath_candidate_entry_keys {
    return normalized_semantic_composition_shared_datapath_candidate_entry_keys();
}

sub normalized_semantic_payload_composition_shared_datapath_candidate_declared_type_extension_keys {
    return normalized_semantic_composition_shared_datapath_candidate_declared_type_extension_keys();
}

sub normalized_semantic_payload_composition_shared_datapath_candidate_contributor_entry_keys {
    return normalized_semantic_composition_shared_datapath_candidate_contributor_entry_keys();
}

sub normalized_semantic_payload_composition_shared_datapath_candidate_contributor_declared_type_extension_keys {
    return normalized_semantic_composition_shared_datapath_candidate_contributor_declared_type_extension_keys();
}

sub normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys {
    return normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys();
}

sub normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys {
    return normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys();
}

sub normalized_semantic_payload_composition_shared_datapath_bound_connection_expr_keys {
    return normalized_semantic_composition_shared_datapath_bound_connection_expr_keys();
}

sub normalized_semantic_payload_composition_shared_datapath_aggregate_enable_family_entry_keys {
    return normalized_semantic_composition_shared_datapath_aggregate_enable_family_entry_keys();
}

sub normalized_semantic_payload_composition_shared_datapath_aggregate_enable_contributor_entry_keys {
    return normalized_semantic_composition_shared_datapath_aggregate_enable_contributor_entry_keys();
}

sub normalized_semantic_payload_composition_shared_datapath_assertion_keys {
    return normalized_semantic_composition_shared_datapath_assertion_keys();
}

1;
