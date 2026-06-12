#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticForwardIRContract qw(
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
    normalized_semantic_forward_ir_presence_key_family_map
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
    normalized_semantic_forward_ir_structural_rtl_ir_presence_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_target_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_target_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_forward_ir_presence_keys
);
use FSM::Support::NormalizedSemanticPayloadContract qw(
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
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_target_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_target_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_keys
    normalized_semantic_payload_forward_ir_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(
    normalized_semantic_forward_ir_keys
    normalized_semantic_forward_ir_intent_hir_keys
    normalized_semantic_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_keys
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
    normalized_semantic_forward_ir_structural_rtl_ir_port_target_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_target_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_keys
);

subtest 'contract exposes the bounded normalized semantic forward-IR object' => sub {
    my $contract = build_normalized_semantic_forward_ir_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested forward-IR object as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_forward_ir_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'semantic.forward_ir', 'contract records the nested object name');
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
        'contract says the nested forward-IR object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_forward_ir_presence_keys(),
        'contract publishes the bounded forward-IR key list',
    );
    is_deeply(
        $contract->{nested_contract_source_map},
        {
            intent_hir => normalized_semantic_forward_ir_intent_hir_contract_source(),
            lowered_rtl_ir => normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
            structural_rtl_ir => normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        },
        'contract publishes the bounded forward-ir nested-contract ownership map',
    );
    is_deeply(
        $contract->{nested_presence_key_map},
        normalized_semantic_forward_ir_nested_presence_key_map(),
        'contract publishes the bounded forward-ir nested key-family map',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_forward_ir_presence_key_family_map(),
        'contract publishes the grouped forward-ir shell key-family discovery map',
    );
    is_deeply(
        $contract->{presence_key_family_map}{lowered_rtl_ir_selector_conflict_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'grouped forward-ir family map publishes selector-conflict target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{lowered_rtl_ir_output_drive_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'grouped forward-ir family map publishes output-drive family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'grouped forward-ir family map publishes output-drive rhs-family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'grouped forward-ir family map publishes selector-conflict rhs-family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'grouped forward-ir family map publishes standalone-DT multi-drive target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'grouped forward-ir family map publishes standalone-DT multi-drive assertion keys',
    );
    for my $case (
        [
            'lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_assertion_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        ],
    ) {
        is_deeply(
            $contract->{presence_key_family_map}{$case->[0]},
            $case->[1],
            "grouped forward-ir family map publishes $case->[0]",
        );
    }
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_auxiliary_assignment_entry_value_kinds},
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'grouped forward-ir family map publishes structural-rtl-ir auxiliary-assignment entry value kinds',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir port entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_port_composition_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir port composition extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_port_target_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_target_extension_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir port target extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_port_target_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_target_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir port target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_net_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir net entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_net_source_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_source_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir net source entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_net_target_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_target_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir net target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_declared_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir declared-link entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_resolved_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir resolved-link entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_instance_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir instance shallow entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_instance_interface_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir instance interface-port entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_instance_parameter_override_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir instance parameter-override core entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_instance_parameter_override_raw_value_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir instance parameter-override raw-value extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir instance parameter-override value-metadata extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_instance_port_binding_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir instance port-binding core entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_instance_port_binding_typed_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir instance port-binding typed extension keys',
    );
    is(
        $contract->{intent_hir_contract_source},
        normalized_semantic_forward_ir_intent_hir_contract_source(),
        'contract records the nested intent-hir object owner',
    );
    is_deeply(
        $contract->{intent_hir_presence_keys},
        normalized_semantic_forward_ir_intent_hir_presence_keys(),
        'contract publishes the bounded forward-ir intent-hir key list',
    );
    is_deeply(
        $contract->{intent_hir_optional_composition_keys},
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'contract publishes the bounded forward-ir intent-hir composition-only key list',
    );
    for my $case (
        [
            'intent_hir_symbol_contract_constant_value_entry_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys(),
        ],
        [
            'intent_hir_symbol_contract_constant_scalar_value_extension_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys(),
        ],
        [
            'intent_hir_symbol_contract_constant_list_value_extension_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys(),
        ],
        [
            'intent_hir_symbol_contract_enum_entry_value_kinds',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds(),
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds(),
        ],
        [
            'intent_hir_symbol_contract_enum_member_value_kinds',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds(),
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds(),
        ],
        [
            'intent_hir_symbol_contract_package_import_entry_value_kinds',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds(),
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds(),
        ],
        [
            'intent_hir_symbol_contract_package_import_entry_value_meaning',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning(),
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning(),
        ],
        [
            'intent_hir_symbol_contract_type_entry_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_entry_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_entry_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_symbol_contract_type_entry_keys(),
        ],
        [
            'intent_hir_symbol_contract_type_scalar_value_kinds',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds(),
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds(),
        ],
        [
            'intent_hir_symbol_contract_type_aggregate_value_kinds',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds(),
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds(),
        ],
        [
            'intent_hir_symbol_contract_type_state_model_extension_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys(),
        ],
        [
            'intent_hir_symbol_contract_type_list_extension_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_list_extension_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_list_extension_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_symbol_contract_type_list_extension_keys(),
        ],
        [
            'intent_hir_symbol_contract_type_record_extension_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_record_extension_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_type_record_extension_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_symbol_contract_type_record_extension_keys(),
        ],
        [
            'intent_hir_composition_child_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_child_entry_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_entry_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_composition_child_entry_keys(),
        ],
        [
            'intent_hir_composition_child_parameter_override_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_entry_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys(),
        ],
        [
            'intent_hir_composition_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
        ],
        [
            'intent_hir_composition_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
        ],
        [
            'intent_hir_composition_generated_child_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_entry_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_entry_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_composition_generated_child_entry_keys(),
        ],
        [
            'intent_hir_composition_generated_child_parameter_override_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys(),
        ],
        [
            'intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys(),
        ],
        [
            'intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        ],
        [
            'intent_hir_composition_standalone_dt_child_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys(),
        ],
        [
            'intent_hir_composition_standalone_dt_enable_family_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
        ],
        [
            'intent_hir_composition_standalone_dt_module_enable_family_keys',
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys(),
        ],
        [
            'intent_hir_composition_standalone_dt_multi_drive_target_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
        ],
        [
            'intent_hir_composition_standalone_dt_multi_drive_assertion_keys',
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
            normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
        ],
    ) {
        my ($field, $forward_keys, $payload_keys, $report_keys) = @{$case};

        is_deeply(
            $contract->{$field},
            $forward_keys,
            "contract publishes the bounded forward-ir $field",
        );
        is_deeply(
            $contract->{presence_key_family_map}{$field},
            _family_map_expected($field, $forward_keys),
            "grouped forward-ir family map publishes $field",
        );
        is_deeply(
            $payload_keys,
            $forward_keys,
            "semantic payload $field maps to the nested forward-ir owner",
        );
        is_deeply(
            $report_keys,
            $forward_keys,
            "normalized semantic report $field maps to the nested forward-ir owner",
        );
    }
    is(
        $contract->{lowered_rtl_ir_contract_source},
        normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
        'contract records the nested lowered-rtl-ir object owner',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_presence_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_optional_composition_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir composition-only key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_output_drive_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir output-drive family entry key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir output-drive rhs-family key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_selector_conflict_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector target entry key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector rhs-family key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_selector_conflict_multi_value_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector multi-value assertion key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_selector_conflict_same_value_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector same-value assertion key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir standalone-DT multi-drive target entry key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir standalone-DT multi-drive assertion key list',
    );
    for my $case (
        [
            'lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        ],
        [
            'lowered_rtl_ir_composition_shared_datapath_assertion_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        ],
    ) {
        is_deeply(
            $contract->{$case->[0]},
            $case->[1],
            "contract publishes the bounded forward-ir $case->[0]",
        );
    }
    is(
        $contract->{structural_rtl_ir_contract_source},
        normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        'contract records the nested structural-rtl-ir object owner',
    );
    is_deeply(
        $contract->{structural_rtl_ir_presence_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_auxiliary_assignment_entry_value_kinds},
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'contract publishes the bounded forward-ir structural-rtl-ir auxiliary-assignment entry value-kind family',
    );
    is(
        $contract->{structural_rtl_ir_auxiliary_assignment_entry_value_meaning},
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        'contract publishes the bounded forward-ir structural-rtl-ir auxiliary-assignment entry value meaning',
    );
    for my $case (
        [
            structural_rtl_ir_assignment_record_entry_keys =>
                normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_entry_keys(),
            'assignment-record entry',
        ],
        [
            structural_rtl_ir_assignment_record_lhs_entry_keys =>
                normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_lhs_entry_keys(),
            'assignment-record lhs',
        ],
        [
            structural_rtl_ir_assignment_record_rhs_entry_keys =>
                normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_rhs_entry_keys(),
            'assignment-record rhs',
        ],
        [
            structural_rtl_ir_assignment_record_provenance_entry_keys =>
                normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_provenance_entry_keys(),
            'assignment-record provenance',
        ],
    ) {
        is_deeply(
            $contract->{$case->[0]},
            $case->[1],
            "contract publishes the bounded forward-ir structural-rtl-ir $case->[2] key list",
        );
    }
    is_deeply(
        $contract->{structural_rtl_ir_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_port_composition_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port composition extension key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_port_target_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_target_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port target extension key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_port_target_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_target_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port target entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_net_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir net entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_net_source_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_source_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir net source entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_net_target_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_target_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir net target entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_declared_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir declared-link entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_resolved_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir resolved-link entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_instance_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance shallow entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_instance_interface_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance interface-port entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_instance_parameter_override_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance parameter-override core entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_instance_parameter_override_raw_value_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance parameter-override raw-value extension key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance parameter-override value-metadata extension key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_instance_port_binding_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance port-binding core entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_instance_port_binding_typed_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
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
        'semantic payload intent-hir keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys(),
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'semantic payload intent-hir composition keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        'semantic payload lowered-rtl-ir keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'semantic payload lowered-rtl-ir composition keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'semantic payload lowered-rtl-ir output-drive family entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'semantic payload lowered-rtl-ir output-drive rhs-family keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'semantic payload lowered-rtl-ir selector target entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'semantic payload lowered-rtl-ir selector rhs-family keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'semantic payload lowered-rtl-ir selector multi-value assertion keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'semantic payload lowered-rtl-ir selector same-value assertion keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'semantic payload lowered-rtl-ir standalone-DT multi-drive target entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'semantic payload lowered-rtl-ir standalone-DT multi-drive assertion keys map to the nested lowered-rtl-ir owner',
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
            "semantic payload lowered-rtl-ir shared-datapath $case->[2] keys map to the nested lowered-rtl-ir owner",
        );
    }
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'semantic payload structural-rtl-ir keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'semantic payload structural-rtl-ir auxiliary-assignment entry value kinds map to the nested structural-rtl-ir owner',
    );
    is(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        'semantic payload structural-rtl-ir auxiliary-assignment entry value meaning maps to the nested structural-rtl-ir owner',
    );
    for my $case (
        [
            normalized_semantic_payload_forward_ir_structural_rtl_ir_assignment_record_entry_keys(),
            normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_entry_keys(),
            'assignment-record entry',
        ],
        [
            normalized_semantic_payload_forward_ir_structural_rtl_ir_assignment_record_lhs_entry_keys(),
            normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_lhs_entry_keys(),
            'assignment-record lhs',
        ],
        [
            normalized_semantic_payload_forward_ir_structural_rtl_ir_assignment_record_rhs_entry_keys(),
            normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_rhs_entry_keys(),
            'assignment-record rhs',
        ],
        [
            normalized_semantic_payload_forward_ir_structural_rtl_ir_assignment_record_provenance_entry_keys(),
            normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_provenance_entry_keys(),
            'assignment-record provenance',
        ],
    ) {
        is_deeply(
            $case->[0],
            $case->[1],
            "semantic payload structural-rtl-ir $case->[2] keys map to the nested structural-rtl-ir owner",
        );
    }
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'semantic payload structural-rtl-ir port entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'semantic payload structural-rtl-ir port composition extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_target_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_target_extension_keys(),
        'semantic payload structural-rtl-ir port target extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_target_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_target_entry_keys(),
        'semantic payload structural-rtl-ir port target entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'semantic payload structural-rtl-ir net entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_source_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_net_source_entry_keys(),
        'semantic payload structural-rtl-ir net source entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_target_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_net_target_entry_keys(),
        'semantic payload structural-rtl-ir net target entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'semantic payload structural-rtl-ir declared-link entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'semantic payload structural-rtl-ir resolved-link entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'semantic payload structural-rtl-ir instance shallow entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'semantic payload structural-rtl-ir instance interface-port entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'semantic payload structural-rtl-ir instance parameter-override core entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'semantic payload structural-rtl-ir instance parameter-override raw-value extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'semantic payload structural-rtl-ir instance parameter-override value-metadata extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'semantic payload structural-rtl-ir instance port-binding core entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'semantic payload structural-rtl-ir instance port-binding typed extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_keys(),
        normalized_semantic_forward_ir_presence_keys(),
        'normalized semantic report forward-IR keys map to the nested forward-IR owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_intent_hir_keys(),
        normalized_semantic_forward_ir_intent_hir_presence_keys(),
        'normalized semantic report intent-hir keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'normalized semantic report intent-hir composition keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        'normalized semantic report lowered-rtl-ir keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'normalized semantic report lowered-rtl-ir composition keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'normalized semantic report lowered-rtl-ir output-drive family entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'normalized semantic report lowered-rtl-ir output-drive rhs-family keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'normalized semantic report lowered-rtl-ir standalone-DT multi-drive target entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'normalized semantic report lowered-rtl-ir standalone-DT multi-drive assertion keys map to the nested lowered-rtl-ir owner',
    );
    for my $case (
        [
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
            'candidate entry',
        ],
        [
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
            'candidate declared-type extension',
        ],
        [
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
            'candidate contributor entry',
        ],
        [
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
            'candidate contributor declared-type extension',
        ],
        [
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
            'candidate contributor drive-intent entry',
        ],
        [
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
            'candidate contributor drive-intent rhs-enable-family entry',
        ],
        [
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
            'bound connection expression',
        ],
        [
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
            'aggregate-enable family entry',
        ],
        [
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
            'aggregate-enable contributor entry',
        ],
        [
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
            'assertion metadata',
        ],
    ) {
        is_deeply(
            $case->[0],
            $case->[1],
            "normalized semantic report lowered-rtl-ir shared-datapath $case->[2] keys map to the nested lowered-rtl-ir owner",
        );
    }
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'normalized semantic report structural-rtl-ir keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'normalized semantic report structural-rtl-ir auxiliary-assignment entry value kinds map to the nested structural-rtl-ir owner',
    );
    is(
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        'normalized semantic report structural-rtl-ir auxiliary-assignment entry value meaning maps to the nested structural-rtl-ir owner',
    );
    for my $case (
        [
            normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_entry_keys(),
            normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_entry_keys(),
            'assignment-record entry',
        ],
        [
            normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_lhs_entry_keys(),
            normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_lhs_entry_keys(),
            'assignment-record lhs',
        ],
        [
            normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_rhs_entry_keys(),
            normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_rhs_entry_keys(),
            'assignment-record rhs',
        ],
        [
            normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_provenance_entry_keys(),
            normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_provenance_entry_keys(),
            'assignment-record provenance',
        ],
    ) {
        is_deeply(
            $case->[0],
            $case->[1],
            "normalized semantic report structural-rtl-ir $case->[2] keys map to the nested structural-rtl-ir owner",
        );
    }
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'normalized semantic report structural-rtl-ir port entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'normalized semantic report structural-rtl-ir port composition extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'normalized semantic report structural-rtl-ir net entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_net_source_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_net_source_entry_keys(),
        'normalized semantic report structural-rtl-ir net source entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_net_target_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_net_target_entry_keys(),
        'normalized semantic report structural-rtl-ir net target entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'normalized semantic report structural-rtl-ir declared-link entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'normalized semantic report structural-rtl-ir resolved-link entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'normalized semantic report structural-rtl-ir instance shallow entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'normalized semantic report structural-rtl-ir instance interface-port entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'normalized semantic report structural-rtl-ir instance parameter-override core entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'normalized semantic report structural-rtl-ir instance parameter-override raw-value extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'normalized semantic report structural-rtl-ir instance parameter-override value-metadata extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'normalized semantic report structural-rtl-ir instance port-binding core entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'normalized semantic report structural-rtl-ir instance port-binding typed extension keys map to the nested structural-rtl-ir owner',
    );
};

done_testing();

sub _family_map_expected {
    my ($field, $expected) = @_;
    return [$expected] if ($field || '') =~ /package_import_entry_value_meaning\z/;
    return $expected;
}
