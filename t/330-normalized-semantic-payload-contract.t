#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

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
    normalized_semantic_forward_ir_lowered_rtl_ir_contract_source
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
    normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_lhs_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_provenance_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_rhs_entry_keys
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
    normalized_semantic_forward_ir_structural_rtl_ir_net_source_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_net_target_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_source_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_source_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_target_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_target_extension_keys
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
    normalized_semantic_symbol_contract_package_import_entry_value_kinds
    normalized_semantic_symbol_contract_package_import_entry_value_meaning
    normalized_semantic_symbol_contract_type_aggregate_value_kinds
    normalized_semantic_symbol_contract_type_entry_keys
    normalized_semantic_symbol_contract_type_list_extension_keys
    normalized_semantic_symbol_contract_type_record_extension_keys
    normalized_semantic_symbol_contract_type_scalar_value_kinds
    normalized_semantic_symbol_contract_type_state_model_extension_keys
    normalized_semantic_symbol_contract_source
    normalized_semantic_symbol_contract_presence_keys
);
use FSM::Support::NormalizedSemanticPayloadContract qw(
    build_normalized_semantic_payload_contract
    normalized_semantic_payload_contract_source
    normalized_semantic_payload_composition_child_entry_keys
    normalized_semantic_payload_composition_child_parameter_override_entry_keys
    normalized_semantic_payload_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_payload_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_payload_composition_generated_child_entry_keys
    normalized_semantic_payload_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_payload_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_payload_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_payload_composition_keys
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
    normalized_semantic_payload_composition_standalone_dt_child_entry_keys
    normalized_semantic_payload_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_payload_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_payload_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_payload_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_payload_explicit_system_contract_keys
    normalized_semantic_payload_presence_key_family_map
    normalized_semantic_payload_nested_presence_key_map
    normalized_semantic_payload_optional_child_presence_keys
    normalized_semantic_payload_forward_ir_keys
    normalized_semantic_payload_forward_ir_nested_contract_source_map
    normalized_semantic_payload_forward_ir_nested_presence_key_map
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
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning
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
    normalized_semantic_payload_forward_ir_structural_rtl_ir_assignment_record_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_assignment_record_lhs_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_assignment_record_provenance_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_assignment_record_rhs_entry_keys
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
    normalized_semantic_payload_forward_ir_structural_rtl_ir_net_source_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_net_target_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_source_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_source_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_target_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_target_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_keys
    normalized_semantic_payload_presence_keys
    normalized_semantic_payload_signal_analysis_entry_keys
    normalized_semantic_payload_signal_analysis_keys
    normalized_semantic_payload_system_contract_keys
    normalized_semantic_payload_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_payload_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_payload_symbol_contract_constant_value_entry_keys
    normalized_semantic_payload_symbol_contract_enum_entry_value_kinds
    normalized_semantic_payload_symbol_contract_enum_member_value_kinds
    normalized_semantic_payload_symbol_contract_package_import_entry_value_kinds
    normalized_semantic_payload_symbol_contract_package_import_entry_value_meaning
    normalized_semantic_payload_symbol_contract_type_aggregate_value_kinds
    normalized_semantic_payload_symbol_contract_type_entry_keys
    normalized_semantic_payload_symbol_contract_type_list_extension_keys
    normalized_semantic_payload_symbol_contract_type_record_extension_keys
    normalized_semantic_payload_symbol_contract_type_scalar_value_kinds
    normalized_semantic_payload_symbol_contract_type_state_model_extension_keys
    normalized_semantic_payload_symbol_contract_keys
);
use FSM::Support::NormalizedSemanticProtocolIntentBundleContract qw(
    normalized_semantic_protocol_intent_bundle_contract_source
);

subtest 'contract exposes the bounded normalized semantic payload object' => sub {
    my $contract = build_normalized_semantic_payload_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested semantic object as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_payload_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'semantic', 'contract records the nested object name');
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Support::NormalizedSemanticReport
            ),
        ],
        'contract records the public report builder that reuses the nested object',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested semantic object is JSON-safe when embedded in public reports',
    );
    is(
        $contract->{module_contract_source},
        normalized_semantic_module_contract_source(),
        'contract records the nested module object owner',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_payload_presence_keys(),
        'contract publishes the bounded semantic-object key list',
    );
    is_deeply(
        $contract->{optional_child_presence_keys},
        normalized_semantic_payload_optional_child_presence_keys(),
        'contract publishes the optional semantic child key list',
    );
    is_deeply(
        normalized_semantic_payload_optional_child_presence_keys(),
        [qw(composition protocol_intent_bundle symbol_contract)],
        'optional semantic child key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{nested_contract_source_map},
        {
            module => normalized_semantic_module_contract_source(),
            explicit_system_contract => normalized_semantic_explicit_system_contract_source(),
            signal_analysis => normalized_semantic_signal_analysis_contract_source(),
            system_contract => normalized_semantic_system_contract_source(),
            forward_ir => normalized_semantic_forward_ir_contract_source(),
            symbol_contract => normalized_semantic_symbol_contract_source(),
            composition => normalized_semantic_composition_contract_source(),
            protocol_intent_bundle => normalized_semantic_protocol_intent_bundle_contract_source(),
        },
        'contract publishes the bounded semantic-payload nested-contract ownership map',
    );
    is_deeply(
        $contract->{nested_presence_key_map},
        normalized_semantic_payload_nested_presence_key_map(),
        'contract publishes the bounded semantic-payload nested key-family map',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_payload_presence_key_family_map(),
        'contract publishes the grouped semantic-payload shell key-family map',
    );
    is_deeply(
        $contract->{presence_key_family_map}{optional_child_presence_keys},
        normalized_semantic_payload_optional_child_presence_keys(),
        'grouped semantic-payload family map publishes the optional child key list',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_child_entry_keys},
        normalized_semantic_payload_composition_child_entry_keys(),
        'grouped semantic-payload family map publishes composition child entry keys',
    );
    for my $case (
        [
            'composition_child_parameter_override_entry_keys',
            normalized_semantic_payload_composition_child_parameter_override_entry_keys(),
        ],
        [
            'composition_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_payload_composition_child_parameter_override_raw_value_extension_keys(),
        ],
        [
            'composition_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_payload_composition_child_parameter_override_value_metadata_extension_keys(),
        ],
    ) {
        is_deeply(
            $contract->{presence_key_family_map}{$case->[0]},
            $case->[1],
            "grouped semantic-payload family map publishes $case->[0]",
        );
    }
    is_deeply(
        $contract->{presence_key_family_map}{composition_generated_child_entry_keys},
        normalized_semantic_payload_composition_generated_child_entry_keys(),
        'grouped semantic-payload family map publishes composition generated-child entry keys',
    );
    for my $case (
        [
            'composition_generated_child_parameter_override_entry_keys',
            normalized_semantic_payload_composition_generated_child_parameter_override_entry_keys(),
        ],
        [
            'composition_generated_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_payload_composition_generated_child_parameter_override_raw_value_extension_keys(),
        ],
        [
            'composition_generated_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_payload_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        ],
    ) {
        is_deeply(
            $contract->{presence_key_family_map}{$case->[0]},
            $case->[1],
            "grouped semantic-payload family map publishes $case->[0]",
        );
    }
    is_deeply(
        $contract->{presence_key_family_map}{composition_standalone_dt_child_entry_keys},
        normalized_semantic_payload_composition_standalone_dt_child_entry_keys(),
        'grouped semantic-payload family map publishes composition standalone-DT child entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_standalone_dt_enable_family_entry_keys},
        normalized_semantic_payload_composition_standalone_dt_enable_family_entry_keys(),
        'grouped semantic-payload family map publishes composition standalone-DT enable-family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_standalone_dt_module_enable_family_keys},
        normalized_semantic_payload_composition_standalone_dt_module_enable_family_keys(),
        'grouped semantic-payload family map publishes composition standalone-DT module-enable-family keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_payload_composition_standalone_dt_multi_drive_target_entry_keys(),
        'grouped semantic-payload family map publishes composition standalone-DT multi-drive target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_payload_composition_standalone_dt_multi_drive_assertion_keys(),
        'grouped semantic-payload family map publishes composition standalone-DT multi-drive assertion keys',
    );
    for my $case (composition_shared_datapath_alias_cases()) {
        my ($field, $payload_helper) = @{$case};
        is_deeply(
            $contract->{presence_key_family_map}{$field},
            $payload_helper->(),
            "grouped semantic-payload family map publishes $field",
        );
    }
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'grouped semantic-payload family map publishes selector-conflict target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_lowered_rtl_ir_output_drive_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'grouped semantic-payload family map publishes output-drive family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'grouped semantic-payload family map publishes output-drive rhs-enable-family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'grouped semantic-payload family map publishes selector-conflict rhs-enable-family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'grouped semantic-payload family map publishes standalone-DT multi-drive target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'grouped semantic-payload family map publishes standalone-DT multi-drive assertion keys',
    );
    for my $case (
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        ],
    ) {
        is_deeply(
            $contract->{presence_key_family_map}{$case->[0]},
            $case->[1],
            "grouped semantic-payload family map publishes $case->[0]",
        );
    }
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'grouped semantic-payload family map publishes structural-rtl-ir auxiliary-assignment entry value kinds',
    );
    for my $case (
        [
            forward_ir_structural_rtl_ir_assignment_record_entry_keys =>
                normalized_semantic_payload_forward_ir_structural_rtl_ir_assignment_record_entry_keys(),
            'assignment-record entry',
        ],
        [
            forward_ir_structural_rtl_ir_assignment_record_lhs_entry_keys =>
                normalized_semantic_payload_forward_ir_structural_rtl_ir_assignment_record_lhs_entry_keys(),
            'assignment-record lhs',
        ],
        [
            forward_ir_structural_rtl_ir_assignment_record_rhs_entry_keys =>
                normalized_semantic_payload_forward_ir_structural_rtl_ir_assignment_record_rhs_entry_keys(),
            'assignment-record rhs',
        ],
        [
            forward_ir_structural_rtl_ir_assignment_record_provenance_entry_keys =>
                normalized_semantic_payload_forward_ir_structural_rtl_ir_assignment_record_provenance_entry_keys(),
            'assignment-record provenance',
        ],
    ) {
        is_deeply(
            $contract->{presence_key_family_map}{$case->[0]},
            $case->[1],
            "grouped semantic-payload family map publishes structural-rtl-ir $case->[2] keys",
        );
    }
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_port_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir port entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_port_composition_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir port composition extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_port_source_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_source_extension_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir port source extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_port_source_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_source_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir port source entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_port_target_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_target_extension_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir port target extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_port_target_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_target_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir port target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_net_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir net entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_net_source_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_source_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir net source entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_net_target_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_target_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir net target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_declared_link_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir declared-link entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_resolved_link_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir resolved-link entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_instance_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir instance shallow entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_instance_interface_port_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir instance interface-port entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir instance parameter-override core entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir instance parameter-override raw-value extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir instance parameter-override value-metadata extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_instance_port_binding_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir instance port-binding core entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir instance port-binding typed extension keys',
    );
    is_deeply(
        $contract->{module_presence_keys},
        normalized_semantic_module_presence_keys(),
        'contract publishes the bounded module-object key list',
    );
    is_deeply(
        $contract->{module_optional_metric_keys},
        normalized_semantic_module_optional_metric_keys(),
        'contract publishes the bounded optional module metric key list',
    );
    is(
        $contract->{composition_contract_source},
        normalized_semantic_composition_contract_source(),
        'contract records the nested composition object owner',
    );
    is(
        $contract->{forward_ir_contract_source},
        normalized_semantic_forward_ir_contract_source(),
        'contract records the nested forward-IR object owner',
    );
    is(
        $contract->{signal_analysis_contract_source},
        normalized_semantic_signal_analysis_contract_source(),
        'contract records the nested signal-analysis object owner',
    );
    is(
        $contract->{explicit_system_contract_source},
        normalized_semantic_explicit_system_contract_source(),
        'contract records the nested explicit-system-contract object owner',
    );
    is(
        $contract->{system_contract_source},
        normalized_semantic_system_contract_source(),
        'contract records the nested system-contract object owner',
    );
    is(
        $contract->{symbol_contract_source},
        normalized_semantic_symbol_contract_source(),
        'contract records the nested symbol-contract object owner',
    );
    is_deeply(
        $contract->{explicit_system_contract_presence_keys},
        normalized_semantic_payload_explicit_system_contract_keys(),
        'contract publishes the bounded explicit-system-contract key list',
    );
    is_deeply(
        normalized_semantic_payload_explicit_system_contract_keys(),
        normalized_semantic_explicit_system_contract_presence_keys(),
        'semantic payload explicit-system-contract keys map to the nested explicit-system-contract owner',
    );
    is_deeply(
        $contract->{signal_analysis_presence_keys},
        normalized_semantic_payload_signal_analysis_keys(),
        'contract publishes the bounded signal-analysis key list',
    );
    is_deeply(
        normalized_semantic_payload_signal_analysis_keys(),
        normalized_semantic_signal_analysis_presence_keys(),
        'semantic payload signal-analysis keys map to the nested signal-analysis owner',
    );
    is_deeply(
        $contract->{signal_analysis_entry_presence_keys},
        normalized_semantic_payload_signal_analysis_entry_keys(),
        'contract publishes the bounded signal-analysis entry key list',
    );
    is_deeply(
        normalized_semantic_payload_signal_analysis_entry_keys(),
        normalized_semantic_signal_analysis_entry_presence_keys(),
        'semantic payload signal-analysis entry keys map to the nested signal-analysis owner',
    );
    is_deeply(
        $contract->{system_contract_presence_keys},
        normalized_semantic_payload_system_contract_keys(),
        'contract publishes the bounded system-contract key list',
    );
    is_deeply(
        normalized_semantic_payload_system_contract_keys(),
        normalized_semantic_system_contract_presence_keys(),
        'semantic payload system-contract keys map to the nested system-contract owner',
    );
    is_deeply(
        $contract->{forward_ir_presence_keys},
        normalized_semantic_payload_forward_ir_keys(),
        'contract publishes the bounded forward-IR key list',
    );
    is_deeply(
        $contract->{forward_ir_nested_contract_source_map},
        normalized_semantic_payload_forward_ir_nested_contract_source_map(),
        'contract publishes the bounded grouped forward-ir child-owner map',
    );
    is_deeply(
        $contract->{forward_ir_nested_presence_key_map},
        normalized_semantic_payload_forward_ir_nested_presence_key_map(),
        'contract publishes the bounded grouped forward-ir child key-family map',
    );
    is(
        $contract->{forward_ir_intent_hir_contract_source},
        normalized_semantic_forward_ir_intent_hir_contract_source(),
        'contract records the nested forward-ir intent-hir object owner',
    );
    is_deeply(
        $contract->{forward_ir_intent_hir_presence_keys},
        normalized_semantic_payload_forward_ir_intent_hir_keys(),
        'contract publishes the bounded forward-ir intent-hir key list',
    );
    is_deeply(
        $contract->{forward_ir_intent_hir_optional_composition_keys},
        normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys(),
        'contract publishes the bounded forward-ir intent-hir composition-only key list',
    );
    for my $case (intent_hir_alias_cases()) {
        my ($field, $payload_keys, $forward_keys) = @{$case};

        is_deeply(
            $contract->{$field},
            $payload_keys,
            "contract publishes the bounded $field",
        );
        is_deeply(
            $contract->{presence_key_family_map}{$field},
            _family_map_expected($field, $payload_keys),
            "grouped semantic-payload family map publishes $field",
        );
        is_deeply(
            $payload_keys,
            $forward_keys,
            "$field maps to the nested forward-ir owner",
        );
    }
    is(
        $contract->{forward_ir_lowered_rtl_ir_contract_source},
        normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
        'contract records the nested forward-ir lowered-rtl-ir object owner',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_presence_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_optional_composition_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir composition-only key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_output_drive_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir output-drive family entry key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir output-drive rhs-family key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector-conflict target entry key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector-conflict rhs-enable-family key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector-conflict multi-value assertion key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector-conflict same-value assertion key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir standalone-DT multi-drive target entry key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir standalone-DT multi-drive assertion key list',
    );
    for my $case (
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        ],
        [
            'forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys',
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        ],
    ) {
        is_deeply(
            $contract->{$case->[0]},
            $case->[1],
            "contract publishes the bounded $case->[0]",
        );
    }
    is(
        $contract->{forward_ir_structural_rtl_ir_contract_source},
        normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        'contract records the nested forward-ir structural-rtl-ir object owner',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_presence_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'contract publishes the bounded forward-ir structural-rtl-ir auxiliary-assignment entry value-kind family',
    );
    is(
        $contract->{forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        'contract publishes the bounded forward-ir structural-rtl-ir auxiliary-assignment entry value meaning',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_port_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_port_composition_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port composition extension key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_port_source_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_source_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port source extension key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_port_source_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_source_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port source entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_port_target_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_target_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port target extension key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_port_target_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_target_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port target entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_net_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir net entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_net_source_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_source_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir net source entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_net_target_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_target_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir net target entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_declared_link_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir declared-link entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_resolved_link_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir resolved-link entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_instance_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance shallow entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_instance_interface_port_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance interface-port entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance parameter-override core entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance parameter-override raw-value extension key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance parameter-override value-metadata extension key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_instance_port_binding_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance port-binding core entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance port-binding typed extension key list',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_keys(),
        normalized_semantic_forward_ir_presence_keys(),
        'semantic payload forward-IR keys map to the nested forward-IR owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_intent_hir_keys(),
        normalized_semantic_forward_ir_intent_hir_presence_keys(),
        'semantic payload forward-ir intent-hir keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys(),
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'semantic payload forward-ir intent-hir composition keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        'semantic payload forward-ir lowered-rtl-ir keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'semantic payload forward-ir lowered-rtl-ir composition keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'semantic payload forward-ir lowered-rtl-ir output-drive family entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'semantic payload forward-ir lowered-rtl-ir output-drive rhs-family keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'semantic payload forward-ir lowered-rtl-ir selector target entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'semantic payload forward-ir lowered-rtl-ir selector rhs-family keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'semantic payload forward-ir lowered-rtl-ir selector multi-value assertion keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'semantic payload forward-ir lowered-rtl-ir selector same-value assertion keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'semantic payload forward-ir lowered-rtl-ir standalone-DT multi-drive target entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'semantic payload forward-ir lowered-rtl-ir standalone-DT multi-drive assertion keys map to the nested lowered-rtl-ir owner',
    );
    for my $case (
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
            'candidate entry',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
            'candidate declared-type extension',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
            'candidate contributor entry',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
            'candidate contributor declared-type extension',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
            'candidate contributor drive-intent entry',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
            'candidate contributor drive-intent rhs-enable-family entry',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
            'bound connection expression',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
            'aggregate-enable family entry',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
            'aggregate-enable contributor entry',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
            'assertion metadata',
        ],
    ) {
        is_deeply(
            $case->[0],
            $case->[1],
            "semantic payload forward-ir lowered-rtl-ir shared-datapath $case->[2] keys map to the nested lowered-rtl-ir owner",
        );
    }
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'semantic payload forward-ir structural-rtl-ir keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'semantic payload forward-ir structural-rtl-ir auxiliary-assignment entry value kinds map to the nested structural-rtl-ir owner',
    );
    is(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        'semantic payload forward-ir structural-rtl-ir auxiliary-assignment entry value meaning maps to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir port entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'semantic payload forward-ir structural-rtl-ir port composition extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_source_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_source_extension_keys(),
        'semantic payload forward-ir structural-rtl-ir port source extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_source_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_source_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir port source entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_target_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_target_extension_keys(),
        'semantic payload forward-ir structural-rtl-ir port target extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_target_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_target_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir port target entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir net entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_source_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_net_source_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir net source entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_target_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_net_target_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir net target entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir declared-link entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir resolved-link entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir instance shallow entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir instance interface-port entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir instance parameter-override core entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'semantic payload forward-ir structural-rtl-ir instance parameter-override raw-value extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'semantic payload forward-ir structural-rtl-ir instance parameter-override value-metadata extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir instance port-binding core entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'semantic payload forward-ir structural-rtl-ir instance port-binding typed extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        $contract->{symbol_contract_presence_keys},
        normalized_semantic_payload_symbol_contract_keys(),
        'contract publishes the bounded symbol-contract key list',
    );
    is_deeply(
        normalized_semantic_payload_symbol_contract_keys(),
        normalized_semantic_symbol_contract_presence_keys(),
        'semantic payload symbol-contract keys map to the nested symbol-contract owner',
    );
    for my $case (
        [
            'symbol_contract_constant_value_entry_keys',
            normalized_semantic_payload_symbol_contract_constant_value_entry_keys(),
            normalized_semantic_symbol_contract_constant_value_entry_keys(),
            'constant value core keys',
        ],
        [
            'symbol_contract_constant_scalar_value_extension_keys',
            normalized_semantic_payload_symbol_contract_constant_scalar_value_extension_keys(),
            normalized_semantic_symbol_contract_constant_scalar_value_extension_keys(),
            'scalar constant value extension keys',
        ],
        [
            'symbol_contract_constant_list_value_extension_keys',
            normalized_semantic_payload_symbol_contract_constant_list_value_extension_keys(),
            normalized_semantic_symbol_contract_constant_list_value_extension_keys(),
            'list constant value extension keys',
        ],
        [
            'symbol_contract_enum_entry_value_kinds',
            normalized_semantic_payload_symbol_contract_enum_entry_value_kinds(),
            normalized_semantic_symbol_contract_enum_entry_value_kinds(),
            'enum entry value kinds',
        ],
        [
            'symbol_contract_enum_member_value_kinds',
            normalized_semantic_payload_symbol_contract_enum_member_value_kinds(),
            normalized_semantic_symbol_contract_enum_member_value_kinds(),
            'enum member value kinds',
        ],
        [
            'symbol_contract_package_import_entry_value_kinds',
            normalized_semantic_payload_symbol_contract_package_import_entry_value_kinds(),
            normalized_semantic_symbol_contract_package_import_entry_value_kinds(),
            'package-import entry value kinds',
        ],
        [
            'symbol_contract_package_import_entry_value_meaning',
            normalized_semantic_payload_symbol_contract_package_import_entry_value_meaning(),
            normalized_semantic_symbol_contract_package_import_entry_value_meaning(),
            'package-import entry value meaning',
        ],
        [
            'symbol_contract_type_entry_keys',
            normalized_semantic_payload_symbol_contract_type_entry_keys(),
            normalized_semantic_symbol_contract_type_entry_keys(),
            'type entry keys',
        ],
        [
            'symbol_contract_type_scalar_value_kinds',
            normalized_semantic_payload_symbol_contract_type_scalar_value_kinds(),
            normalized_semantic_symbol_contract_type_scalar_value_kinds(),
            'scalar type value kinds',
        ],
        [
            'symbol_contract_type_aggregate_value_kinds',
            normalized_semantic_payload_symbol_contract_type_aggregate_value_kinds(),
            normalized_semantic_symbol_contract_type_aggregate_value_kinds(),
            'aggregate type value kinds',
        ],
        [
            'symbol_contract_type_state_model_extension_keys',
            normalized_semantic_payload_symbol_contract_type_state_model_extension_keys(),
            normalized_semantic_symbol_contract_type_state_model_extension_keys(),
            'type state-model extension keys',
        ],
        [
            'symbol_contract_type_list_extension_keys',
            normalized_semantic_payload_symbol_contract_type_list_extension_keys(),
            normalized_semantic_symbol_contract_type_list_extension_keys(),
            'type list extension keys',
        ],
        [
            'symbol_contract_type_record_extension_keys',
            normalized_semantic_payload_symbol_contract_type_record_extension_keys(),
            normalized_semantic_symbol_contract_type_record_extension_keys(),
            'type record extension keys',
        ],
    ) {
        my ($field, $payload_keys, $symbol_keys, $label) = @{$case};

        is_deeply(
            $contract->{$field},
            $payload_keys,
            "contract publishes the bounded symbol-contract $label",
        );
        is_deeply(
            $contract->{presence_key_family_map}{$field},
            _family_map_expected($field, $payload_keys),
            "grouped semantic-payload family map publishes symbol-contract $label",
        );
        is_deeply(
            $payload_keys,
            $symbol_keys,
            "semantic payload symbol-contract $label map to the nested symbol-contract owner",
        );
    }
    is_deeply(
        $contract->{composition_presence_keys},
        normalized_semantic_composition_presence_keys(),
        'contract publishes the bounded composition key list',
    );
    is_deeply(
        normalized_semantic_payload_composition_keys(),
        normalized_semantic_composition_presence_keys(),
        'semantic payload composition keys map to the nested composition owner',
    );
    is_deeply(
        $contract->{composition_child_entry_keys},
        normalized_semantic_payload_composition_child_entry_keys(),
        'contract publishes the bounded composition child entry key list',
    );
    is_deeply(
        normalized_semantic_payload_composition_child_entry_keys(),
        normalized_semantic_composition_child_entry_keys(),
        'semantic payload composition child entry keys map to the nested composition owner',
    );
    for my $case (
        [
            'composition_child_parameter_override_entry_keys',
            normalized_semantic_payload_composition_child_parameter_override_entry_keys(),
            normalized_semantic_composition_child_parameter_override_entry_keys(),
            'core entry',
        ],
        [
            'composition_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_payload_composition_child_parameter_override_raw_value_extension_keys(),
            normalized_semantic_composition_child_parameter_override_raw_value_extension_keys(),
            'raw-value extension',
        ],
        [
            'composition_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_payload_composition_child_parameter_override_value_metadata_extension_keys(),
            normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys(),
            'value-metadata extension',
        ],
    ) {
        my ($field, $payload_keys, $composition_keys, $label) = @{$case};

        is_deeply(
            $contract->{$field},
            $payload_keys,
            "contract publishes the bounded composition child parameter-override $label key list",
        );
        is_deeply(
            $payload_keys,
            $composition_keys,
            "semantic payload composition child parameter-override $label keys map to the nested composition owner",
        );
    }
    is_deeply(
        $contract->{composition_generated_child_entry_keys},
        normalized_semantic_payload_composition_generated_child_entry_keys(),
        'contract publishes the bounded composition generated-child entry key list',
    );
    is_deeply(
        normalized_semantic_payload_composition_generated_child_entry_keys(),
        normalized_semantic_composition_generated_child_entry_keys(),
        'semantic payload composition generated-child entry keys map to the nested composition owner',
    );
    for my $case (
        [
            'composition_generated_child_parameter_override_entry_keys',
            normalized_semantic_payload_composition_generated_child_parameter_override_entry_keys(),
            normalized_semantic_composition_generated_child_parameter_override_entry_keys(),
            'core entry',
        ],
        [
            'composition_generated_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_payload_composition_generated_child_parameter_override_raw_value_extension_keys(),
            normalized_semantic_composition_generated_child_parameter_override_raw_value_extension_keys(),
            'raw-value extension',
        ],
        [
            'composition_generated_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_payload_composition_generated_child_parameter_override_value_metadata_extension_keys(),
            normalized_semantic_composition_generated_child_parameter_override_value_metadata_extension_keys(),
            'value-metadata extension',
        ],
    ) {
        my ($field, $payload_keys, $composition_keys, $label) = @{$case};

        is_deeply(
            $contract->{$field},
            $payload_keys,
            "contract publishes the bounded composition generated-child parameter-override $label key list",
        );
        is_deeply(
            $payload_keys,
            $composition_keys,
            "semantic payload composition generated-child parameter-override $label keys map to the nested composition owner",
        );
    }
    is_deeply(
        $contract->{composition_standalone_dt_child_entry_keys},
        normalized_semantic_payload_composition_standalone_dt_child_entry_keys(),
        'contract publishes the bounded composition standalone-DT child entry key list',
    );
    is_deeply(
        normalized_semantic_payload_composition_standalone_dt_child_entry_keys(),
        normalized_semantic_composition_standalone_dt_child_entry_keys(),
        'semantic payload composition standalone-DT child entry keys map to the nested composition owner',
    );
    is_deeply(
        $contract->{composition_standalone_dt_enable_family_entry_keys},
        normalized_semantic_payload_composition_standalone_dt_enable_family_entry_keys(),
        'contract publishes the bounded composition standalone-DT enable-family entry key list',
    );
    is_deeply(
        normalized_semantic_payload_composition_standalone_dt_enable_family_entry_keys(),
        normalized_semantic_composition_standalone_dt_enable_family_entry_keys(),
        'semantic payload composition standalone-DT enable-family entry keys map to the nested composition owner',
    );
    is_deeply(
        $contract->{composition_standalone_dt_module_enable_family_keys},
        normalized_semantic_payload_composition_standalone_dt_module_enable_family_keys(),
        'contract publishes the bounded composition standalone-DT module-enable-family key list',
    );
    is_deeply(
        normalized_semantic_payload_composition_standalone_dt_module_enable_family_keys(),
        normalized_semantic_composition_standalone_dt_module_enable_family_keys(),
        'semantic payload composition standalone-DT module-enable-family keys map to the nested composition owner',
    );
    is_deeply(
        $contract->{composition_standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_payload_composition_standalone_dt_multi_drive_target_entry_keys(),
        'contract publishes the bounded composition standalone-DT multi-drive target entry key list',
    );
    is_deeply(
        normalized_semantic_payload_composition_standalone_dt_multi_drive_target_entry_keys(),
        normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys(),
        'semantic payload composition standalone-DT multi-drive target entry keys map to the nested composition owner',
    );
    is_deeply(
        $contract->{composition_standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_payload_composition_standalone_dt_multi_drive_assertion_keys(),
        'contract publishes the bounded composition standalone-DT multi-drive assertion key list',
    );
    is_deeply(
        normalized_semantic_payload_composition_standalone_dt_multi_drive_assertion_keys(),
        normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys(),
        'semantic payload composition standalone-DT multi-drive assertion keys map to the nested composition owner',
    );
    for my $case (composition_shared_datapath_alias_cases()) {
        my ($field, $payload_helper, $composition_helper) = @{$case};
        is_deeply(
            $contract->{$field},
            $payload_helper->(),
            "contract publishes the bounded $field list",
        );
        is_deeply(
            $payload_helper->(),
            $composition_helper->(),
            "semantic payload $field maps to the nested composition owner",
        );
    }
};

sub composition_shared_datapath_alias_cases {
    return (
        [
            'composition_shared_datapath_candidate_entry_keys',
            \&normalized_semantic_payload_composition_shared_datapath_candidate_entry_keys,
            \&normalized_semantic_composition_shared_datapath_candidate_entry_keys,
        ],
        [
            'composition_shared_datapath_candidate_declared_type_extension_keys',
            \&normalized_semantic_payload_composition_shared_datapath_candidate_declared_type_extension_keys,
            \&normalized_semantic_composition_shared_datapath_candidate_declared_type_extension_keys,
        ],
        [
            'composition_shared_datapath_candidate_contributor_entry_keys',
            \&normalized_semantic_payload_composition_shared_datapath_candidate_contributor_entry_keys,
            \&normalized_semantic_composition_shared_datapath_candidate_contributor_entry_keys,
        ],
        [
            'composition_shared_datapath_candidate_contributor_declared_type_extension_keys',
            \&normalized_semantic_payload_composition_shared_datapath_candidate_contributor_declared_type_extension_keys,
            \&normalized_semantic_composition_shared_datapath_candidate_contributor_declared_type_extension_keys,
        ],
        [
            'composition_shared_datapath_candidate_contributor_drive_intent_entry_keys',
            \&normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys,
            \&normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys,
        ],
        [
            'composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys',
            \&normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys,
            \&normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys,
        ],
        [
            'composition_shared_datapath_bound_connection_expr_keys',
            \&normalized_semantic_payload_composition_shared_datapath_bound_connection_expr_keys,
            \&normalized_semantic_composition_shared_datapath_bound_connection_expr_keys,
        ],
        [
            'composition_shared_datapath_aggregate_enable_family_entry_keys',
            \&normalized_semantic_payload_composition_shared_datapath_aggregate_enable_family_entry_keys,
            \&normalized_semantic_composition_shared_datapath_aggregate_enable_family_entry_keys,
        ],
        [
            'composition_shared_datapath_aggregate_enable_contributor_entry_keys',
            \&normalized_semantic_payload_composition_shared_datapath_aggregate_enable_contributor_entry_keys,
            \&normalized_semantic_composition_shared_datapath_aggregate_enable_contributor_entry_keys,
        ],
        [
            'composition_shared_datapath_assertion_keys',
            \&normalized_semantic_payload_composition_shared_datapath_assertion_keys,
            \&normalized_semantic_composition_shared_datapath_assertion_keys,
        ],
    );
}

sub intent_hir_alias_cases {
    return (
        [
            'forward_ir_intent_hir_symbol_contract_constant_value_entry_keys',
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys(),
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys(),
        ],
        [
            'forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys',
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys(),
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys(),
        ],
        [
            'forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys',
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys(),
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys(),
        ],
        [
            'forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds',
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds(),
            normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds(),
        ],
        [
            'forward_ir_intent_hir_symbol_contract_enum_member_value_kinds',
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds(),
            normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds(),
        ],
        [
            'forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds',
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds(),
            normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds(),
        ],
        [
            'forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning',
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning(),
            normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning(),
        ],
        [
            'forward_ir_intent_hir_symbol_contract_type_entry_keys',
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_entry_keys(),
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_entry_keys(),
        ],
        [
            'forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds',
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds(),
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds(),
        ],
        [
            'forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds',
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds(),
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds(),
        ],
        [
            'forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys',
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys(),
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys(),
        ],
        [
            'forward_ir_intent_hir_symbol_contract_type_list_extension_keys',
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_list_extension_keys(),
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_list_extension_keys(),
        ],
        [
            'forward_ir_intent_hir_symbol_contract_type_record_extension_keys',
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_record_extension_keys(),
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_record_extension_keys(),
        ],
        [
            'forward_ir_intent_hir_composition_child_entry_keys',
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_entry_keys(),
            normalized_semantic_forward_ir_intent_hir_composition_child_entry_keys(),
        ],
        [
            'forward_ir_intent_hir_composition_child_parameter_override_entry_keys',
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_entry_keys(),
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys(),
        ],
        [
            'forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
        ],
        [
            'forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
        ],
        [
            'forward_ir_intent_hir_composition_generated_child_entry_keys',
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_entry_keys(),
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_entry_keys(),
        ],
        [
            'forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys',
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys(),
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys(),
        ],
        [
            'forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys(),
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys(),
        ],
        [
            'forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys(),
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        ],
        [
            'forward_ir_intent_hir_composition_standalone_dt_child_entry_keys',
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys(),
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys(),
        ],
        [
            'forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys',
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
        ],
        [
            'forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys',
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys(),
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys(),
        ],
        [
            'forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys',
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
        ],
        [
            'forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys',
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
        ],
    );
}

done_testing();

sub _family_map_expected {
    my ($field, $expected) = @_;
    return [$expected] if ($field || '') =~ /package_import_entry_value_meaning\z/;
    return $expected;
}
