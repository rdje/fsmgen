package FSM::Support::NormalizedSemanticForwardIRContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::NormalizedSemanticIntentHIRContract qw(
    normalized_semantic_intent_hir_contract_source
    normalized_semantic_intent_hir_composition_child_entry_keys
    normalized_semantic_intent_hir_composition_child_parameter_override_entry_keys
    normalized_semantic_intent_hir_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_intent_hir_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_intent_hir_composition_generated_child_entry_keys
    normalized_semantic_intent_hir_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_intent_hir_composition_standalone_dt_child_entry_keys
    normalized_semantic_intent_hir_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_intent_hir_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_intent_hir_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_intent_hir_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_intent_hir_symbol_contract_constant_value_entry_keys
    normalized_semantic_intent_hir_symbol_contract_enum_entry_value_kinds
    normalized_semantic_intent_hir_symbol_contract_enum_member_value_kinds
    normalized_semantic_intent_hir_symbol_contract_package_import_entry_value_kinds
    normalized_semantic_intent_hir_symbol_contract_package_import_entry_value_meaning
    normalized_semantic_intent_hir_symbol_contract_type_aggregate_value_kinds
    normalized_semantic_intent_hir_symbol_contract_type_entry_keys
    normalized_semantic_intent_hir_symbol_contract_type_list_extension_keys
    normalized_semantic_intent_hir_symbol_contract_type_record_extension_keys
    normalized_semantic_intent_hir_symbol_contract_type_scalar_value_kinds
    normalized_semantic_intent_hir_symbol_contract_type_state_model_extension_keys
    normalized_semantic_intent_hir_optional_composition_keys
    normalized_semantic_intent_hir_presence_keys
);
use FSM::Support::NormalizedSemanticLoweredRTLIRContract qw(
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_lowered_rtl_ir_contract_source
    normalized_semantic_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_presence_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_same_value_assertion_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys
    normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys
);
use FSM::Support::NormalizedSemanticStructuralRTLIRContract qw(
    normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_kinds
    normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_meaning
    normalized_semantic_structural_rtl_ir_contract_source
    normalized_semantic_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_structural_rtl_ir_instance_entry_keys
    normalized_semantic_structural_rtl_ir_instance_interface_port_entry_keys
    normalized_semantic_structural_rtl_ir_instance_parameter_override_entry_keys
    normalized_semantic_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys
    normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys
    normalized_semantic_structural_rtl_ir_instance_port_binding_entry_keys
    normalized_semantic_structural_rtl_ir_instance_port_binding_typed_extension_keys
    normalized_semantic_structural_rtl_ir_net_entry_keys
    normalized_semantic_structural_rtl_ir_presence_keys
    normalized_semantic_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_structural_rtl_ir_port_entry_keys
    normalized_semantic_structural_rtl_ir_resolved_link_entry_keys
);

our @EXPORT_OK = qw(
    build_normalized_semantic_forward_ir_contract
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
    normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds
    normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_entry_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_list_extension_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_record_extension_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys
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
    normalized_semantic_forward_ir_nested_presence_key_map
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
    normalized_semantic_forward_ir_presence_key_family_map
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
    normalized_semantic_forward_ir_structural_rtl_ir_presence_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_forward_ir_presence_keys
);

sub build_normalized_semantic_forward_ir_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => normalized_semantic_forward_ir_contract_source(),
        object_name => 'semantic.forward_ir',
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
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)->{semantic}{forward_ir}',
            ],
        },
        public_presence_keys => normalized_semantic_forward_ir_presence_keys(),
        nested_contract_source_map => {
            intent_hir => normalized_semantic_forward_ir_intent_hir_contract_source(),
            lowered_rtl_ir => normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
            structural_rtl_ir => normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        },
        nested_presence_key_map => normalized_semantic_forward_ir_nested_presence_key_map(),
        presence_key_family_map => normalized_semantic_forward_ir_presence_key_family_map(),
        intent_hir_contract_source => normalized_semantic_forward_ir_intent_hir_contract_source(),
        intent_hir_presence_keys => normalized_semantic_forward_ir_intent_hir_presence_keys(),
        intent_hir_symbol_contract_constant_value_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys(),
        intent_hir_symbol_contract_constant_scalar_value_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys(),
        intent_hir_symbol_contract_constant_list_value_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys(),
        intent_hir_symbol_contract_enum_entry_value_kinds =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds(),
        intent_hir_symbol_contract_enum_member_value_kinds =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds(),
        intent_hir_symbol_contract_package_import_entry_value_kinds =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds(),
        intent_hir_symbol_contract_package_import_entry_value_meaning =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning(),
        intent_hir_symbol_contract_type_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_entry_keys(),
        intent_hir_symbol_contract_type_scalar_value_kinds =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds(),
        intent_hir_symbol_contract_type_aggregate_value_kinds =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds(),
        intent_hir_symbol_contract_type_state_model_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys(),
        intent_hir_symbol_contract_type_list_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_list_extension_keys(),
        intent_hir_symbol_contract_type_record_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_record_extension_keys(),
        intent_hir_optional_composition_keys => normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        intent_hir_composition_child_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_child_entry_keys(),
        intent_hir_composition_child_parameter_override_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys(),
        intent_hir_composition_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
        intent_hir_composition_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
        intent_hir_composition_generated_child_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_entry_keys(),
        intent_hir_composition_generated_child_parameter_override_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys(),
        intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys(),
        intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        intent_hir_composition_standalone_dt_child_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys(),
        intent_hir_composition_standalone_dt_enable_family_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
        intent_hir_composition_standalone_dt_module_enable_family_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys(),
        intent_hir_composition_standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
        intent_hir_composition_standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
        lowered_rtl_ir_contract_source => normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
        lowered_rtl_ir_presence_keys => normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        lowered_rtl_ir_optional_composition_keys => normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        lowered_rtl_ir_output_drive_family_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        lowered_rtl_ir_selector_conflict_target_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        lowered_rtl_ir_selector_conflict_multi_value_assertion_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        lowered_rtl_ir_selector_conflict_same_value_assertion_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        lowered_rtl_ir_composition_shared_datapath_assertion_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        structural_rtl_ir_contract_source => normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        structural_rtl_ir_presence_keys => normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        structural_rtl_ir_auxiliary_assignment_entry_value_kinds =>
            normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        structural_rtl_ir_auxiliary_assignment_entry_value_meaning =>
            normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        structural_rtl_ir_net_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        structural_rtl_ir_declared_link_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        structural_rtl_ir_resolved_link_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        structural_rtl_ir_instance_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        structural_rtl_ir_instance_interface_port_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        structural_rtl_ir_instance_parameter_override_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        structural_rtl_ir_instance_parameter_override_raw_value_extension_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        structural_rtl_ir_instance_port_binding_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        structural_rtl_ir_instance_port_binding_typed_extension_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        structural_rtl_ir_port_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        structural_rtl_ir_port_composition_extension_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic.forward_ir` object used by successful public normalized semantic JSON reports.},
            'The nested object exposes only the current sanitized forward semantic projections, not raw compiler/private pipeline state.',
            'The nested `intent_hir` branch now also has one bounded owner for its current object shell, embedded symbol_contract constant value key families, enum value-kind families, package-import entry families, type-entry families, composition-only extension keys, composition-child alias key families, and child/generated-child parameter-override alias key families.',
            'The nested `lowered_rtl_ir` branch now also has one bounded owner for its current direct-root shell, composition-only extension keys, output-drive entry key families, selector-conflict entry key families, standalone-DT multi-drive entry key families, and composition shared-datapath candidate entry key families.',
            'The nested `structural_rtl_ir` branch now also has one bounded owner for its current direct-root and composition-top object shell plus structural auxiliary-assignment value-kind, port, net, declared/resolved link, instance shallow, nested instance interface-port, nested instance parameter-override, and nested instance port-binding key families.',
            'Use the grouped `nested_presence_key_map` to discover the bounded key families for intent_hir, lowered_rtl_ir, and structural_rtl_ir without collecting those child key lists separately.',
            'Use the grouped `presence_key_family_map` to discover the shell-owned forward_ir and child composition-only extension key families without collecting those field-family lists separately.',
            'Widen this object deliberately through one named owner plus regression coverage instead of relying on sample JSON.',
        ],
    };
}

sub normalized_semantic_forward_ir_contract_source {
    return 'FSM::Support::NormalizedSemanticForwardIRContract';
}

sub normalized_semantic_forward_ir_intent_hir_contract_source {
    return normalized_semantic_intent_hir_contract_source();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_contract_source {
    return normalized_semantic_lowered_rtl_ir_contract_source();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_contract_source {
    return normalized_semantic_structural_rtl_ir_contract_source();
}

sub normalized_semantic_forward_ir_presence_keys {
    return [
        qw(
            intent_hir
            lowered_rtl_ir
            structural_rtl_ir
        ),
    ];
}

sub normalized_semantic_forward_ir_nested_presence_key_map {
    return {
        intent_hir => normalized_semantic_forward_ir_intent_hir_presence_keys(),
        lowered_rtl_ir => normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        structural_rtl_ir => normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
    };
}

sub normalized_semantic_forward_ir_presence_key_family_map {
    return {
        public_presence_keys => normalized_semantic_forward_ir_presence_keys(),
        intent_hir_symbol_contract_constant_value_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys(),
        intent_hir_symbol_contract_constant_scalar_value_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys(),
        intent_hir_symbol_contract_constant_list_value_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys(),
        intent_hir_symbol_contract_enum_entry_value_kinds =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds(),
        intent_hir_symbol_contract_enum_member_value_kinds =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds(),
        intent_hir_symbol_contract_package_import_entry_value_kinds =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds(),
        intent_hir_symbol_contract_package_import_entry_value_meaning =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning(),
        intent_hir_symbol_contract_type_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_entry_keys(),
        intent_hir_symbol_contract_type_scalar_value_kinds =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds(),
        intent_hir_symbol_contract_type_aggregate_value_kinds =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds(),
        intent_hir_symbol_contract_type_state_model_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys(),
        intent_hir_symbol_contract_type_list_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_list_extension_keys(),
        intent_hir_symbol_contract_type_record_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_record_extension_keys(),
        intent_hir_optional_composition_keys => normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        intent_hir_composition_child_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_child_entry_keys(),
        intent_hir_composition_child_parameter_override_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys(),
        intent_hir_composition_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
        intent_hir_composition_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
        intent_hir_composition_generated_child_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_entry_keys(),
        intent_hir_composition_generated_child_parameter_override_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys(),
        intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys(),
        intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        intent_hir_composition_standalone_dt_child_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys(),
        intent_hir_composition_standalone_dt_enable_family_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
        intent_hir_composition_standalone_dt_module_enable_family_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys(),
        intent_hir_composition_standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
        intent_hir_composition_standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
        lowered_rtl_ir_optional_composition_keys => normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        lowered_rtl_ir_output_drive_family_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        lowered_rtl_ir_selector_conflict_target_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        lowered_rtl_ir_selector_conflict_multi_value_assertion_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        lowered_rtl_ir_selector_conflict_same_value_assertion_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        lowered_rtl_ir_composition_shared_datapath_assertion_keys =>
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        structural_rtl_ir_auxiliary_assignment_entry_value_kinds =>
            normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        structural_rtl_ir_port_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        structural_rtl_ir_port_composition_extension_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        structural_rtl_ir_net_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        structural_rtl_ir_declared_link_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        structural_rtl_ir_resolved_link_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        structural_rtl_ir_instance_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        structural_rtl_ir_instance_interface_port_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        structural_rtl_ir_instance_parameter_override_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        structural_rtl_ir_instance_parameter_override_raw_value_extension_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        structural_rtl_ir_instance_port_binding_entry_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        structural_rtl_ir_instance_port_binding_typed_extension_keys =>
            normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
    };
}

sub normalized_semantic_forward_ir_intent_hir_presence_keys {
    return normalized_semantic_intent_hir_presence_keys();
}

sub normalized_semantic_forward_ir_intent_hir_optional_composition_keys {
    return normalized_semantic_intent_hir_optional_composition_keys();
}

sub normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys {
    return normalized_semantic_intent_hir_symbol_contract_constant_value_entry_keys();
}

sub normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys {
    return normalized_semantic_intent_hir_symbol_contract_constant_scalar_value_extension_keys();
}

sub normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys {
    return normalized_semantic_intent_hir_symbol_contract_constant_list_value_extension_keys();
}

sub normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds {
    return normalized_semantic_intent_hir_symbol_contract_enum_entry_value_kinds();
}

sub normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds {
    return normalized_semantic_intent_hir_symbol_contract_enum_member_value_kinds();
}

sub normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds {
    return normalized_semantic_intent_hir_symbol_contract_package_import_entry_value_kinds();
}

sub normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning {
    return normalized_semantic_intent_hir_symbol_contract_package_import_entry_value_meaning();
}

sub normalized_semantic_forward_ir_intent_hir_symbol_contract_type_entry_keys {
    return normalized_semantic_intent_hir_symbol_contract_type_entry_keys();
}

sub normalized_semantic_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds {
    return normalized_semantic_intent_hir_symbol_contract_type_scalar_value_kinds();
}

sub normalized_semantic_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds {
    return normalized_semantic_intent_hir_symbol_contract_type_aggregate_value_kinds();
}

sub normalized_semantic_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys {
    return normalized_semantic_intent_hir_symbol_contract_type_state_model_extension_keys();
}

sub normalized_semantic_forward_ir_intent_hir_symbol_contract_type_list_extension_keys {
    return normalized_semantic_intent_hir_symbol_contract_type_list_extension_keys();
}

sub normalized_semantic_forward_ir_intent_hir_symbol_contract_type_record_extension_keys {
    return normalized_semantic_intent_hir_symbol_contract_type_record_extension_keys();
}

sub normalized_semantic_forward_ir_intent_hir_composition_child_entry_keys {
    return normalized_semantic_intent_hir_composition_child_entry_keys();
}

sub normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys {
    return normalized_semantic_intent_hir_composition_child_parameter_override_entry_keys();
}

sub normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys {
    return normalized_semantic_intent_hir_composition_child_parameter_override_raw_value_extension_keys();
}

sub normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys {
    return normalized_semantic_intent_hir_composition_child_parameter_override_value_metadata_extension_keys();
}

sub normalized_semantic_forward_ir_intent_hir_composition_generated_child_entry_keys {
    return normalized_semantic_intent_hir_composition_generated_child_entry_keys();
}

sub normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys {
    return normalized_semantic_intent_hir_composition_generated_child_parameter_override_entry_keys();
}

sub normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys {
    return normalized_semantic_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys();
}

sub normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys {
    return normalized_semantic_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys();
}

sub normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys {
    return normalized_semantic_intent_hir_composition_standalone_dt_child_entry_keys();
}

sub normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys {
    return normalized_semantic_intent_hir_composition_standalone_dt_enable_family_entry_keys();
}

sub normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys {
    return normalized_semantic_intent_hir_composition_standalone_dt_module_enable_family_keys();
}

sub normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys {
    return normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys();
}

sub normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys {
    return normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_assertion_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys {
    return normalized_semantic_lowered_rtl_ir_presence_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys {
    return normalized_semantic_lowered_rtl_ir_optional_composition_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys {
    return normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys {
    return normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys {
    return normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys {
    return normalized_semantic_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys {
    return normalized_semantic_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys {
    return normalized_semantic_lowered_rtl_ir_selector_conflict_same_value_assertion_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys {
    return normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys {
    return normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_presence_keys {
    return normalized_semantic_structural_rtl_ir_presence_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds {
    return normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_kinds();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning {
    return normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_meaning();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys {
    return normalized_semantic_structural_rtl_ir_port_entry_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys {
    return normalized_semantic_structural_rtl_ir_port_composition_extension_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys {
    return normalized_semantic_structural_rtl_ir_net_entry_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys {
    return normalized_semantic_structural_rtl_ir_declared_link_entry_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys {
    return normalized_semantic_structural_rtl_ir_resolved_link_entry_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys {
    return normalized_semantic_structural_rtl_ir_instance_entry_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys {
    return normalized_semantic_structural_rtl_ir_instance_interface_port_entry_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys {
    return normalized_semantic_structural_rtl_ir_instance_parameter_override_entry_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys {
    return normalized_semantic_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys {
    return normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys {
    return normalized_semantic_structural_rtl_ir_instance_port_binding_entry_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys {
    return normalized_semantic_structural_rtl_ir_instance_port_binding_typed_extension_keys();
}

1;
