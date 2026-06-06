package FSM::Support::NormalizedSemanticIntentHIRContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::NormalizedSemanticCompositionContract qw(
    normalized_semantic_composition_child_entry_keys
    normalized_semantic_composition_child_parameter_override_entry_keys
    normalized_semantic_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_composition_generated_child_entry_keys
    normalized_semantic_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_composition_standalone_dt_child_entry_keys
    normalized_semantic_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys
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
);

our @EXPORT_OK = qw(
    build_normalized_semantic_intent_hir_contract
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
    normalized_semantic_intent_hir_symbol_contract_type_aggregate_value_kinds
    normalized_semantic_intent_hir_symbol_contract_type_entry_keys
    normalized_semantic_intent_hir_symbol_contract_type_list_extension_keys
    normalized_semantic_intent_hir_symbol_contract_type_record_extension_keys
    normalized_semantic_intent_hir_symbol_contract_type_scalar_value_kinds
    normalized_semantic_intent_hir_symbol_contract_type_state_model_extension_keys
    normalized_semantic_intent_hir_optional_composition_keys
    normalized_semantic_intent_hir_presence_key_family_map
    normalized_semantic_intent_hir_presence_keys
);

sub build_normalized_semantic_intent_hir_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => normalized_semantic_intent_hir_contract_source(),
        object_name => 'intent_hir',
        parent_object_name => 'semantic.forward_ir.intent_hir',
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
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)->{semantic}{forward_ir}{intent_hir}',
            ],
        },
        public_presence_keys => normalized_semantic_intent_hir_presence_keys(),
        symbol_contract_constant_value_entry_keys =>
            normalized_semantic_intent_hir_symbol_contract_constant_value_entry_keys(),
        symbol_contract_constant_scalar_value_extension_keys =>
            normalized_semantic_intent_hir_symbol_contract_constant_scalar_value_extension_keys(),
        symbol_contract_constant_list_value_extension_keys =>
            normalized_semantic_intent_hir_symbol_contract_constant_list_value_extension_keys(),
        symbol_contract_enum_entry_value_kinds =>
            normalized_semantic_intent_hir_symbol_contract_enum_entry_value_kinds(),
        symbol_contract_enum_member_value_kinds =>
            normalized_semantic_intent_hir_symbol_contract_enum_member_value_kinds(),
        symbol_contract_type_entry_keys =>
            normalized_semantic_intent_hir_symbol_contract_type_entry_keys(),
        symbol_contract_type_scalar_value_kinds =>
            normalized_semantic_intent_hir_symbol_contract_type_scalar_value_kinds(),
        symbol_contract_type_aggregate_value_kinds =>
            normalized_semantic_intent_hir_symbol_contract_type_aggregate_value_kinds(),
        symbol_contract_type_state_model_extension_keys =>
            normalized_semantic_intent_hir_symbol_contract_type_state_model_extension_keys(),
        symbol_contract_type_list_extension_keys =>
            normalized_semantic_intent_hir_symbol_contract_type_list_extension_keys(),
        symbol_contract_type_record_extension_keys =>
            normalized_semantic_intent_hir_symbol_contract_type_record_extension_keys(),
        optional_composition_keys => normalized_semantic_intent_hir_optional_composition_keys(),
        composition_child_entry_keys => normalized_semantic_intent_hir_composition_child_entry_keys(),
        composition_child_parameter_override_entry_keys =>
            normalized_semantic_intent_hir_composition_child_parameter_override_entry_keys(),
        composition_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
        composition_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
        composition_generated_child_entry_keys =>
            normalized_semantic_intent_hir_composition_generated_child_entry_keys(),
        composition_generated_child_parameter_override_entry_keys =>
            normalized_semantic_intent_hir_composition_generated_child_parameter_override_entry_keys(),
        composition_generated_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys(),
        composition_generated_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        composition_standalone_dt_child_entry_keys =>
            normalized_semantic_intent_hir_composition_standalone_dt_child_entry_keys(),
        composition_standalone_dt_enable_family_entry_keys =>
            normalized_semantic_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
        composition_standalone_dt_module_enable_family_keys =>
            normalized_semantic_intent_hir_composition_standalone_dt_module_enable_family_keys(),
        composition_standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
        composition_standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
        presence_key_family_map => normalized_semantic_intent_hir_presence_key_family_map(),
        optional_for_non_composition_sources => JSON::PP::true,
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic.forward_ir.intent_hir` object used by successful public normalized semantic JSON reports.},
            'The bounded public promise covers the current core intent-hir summary plus the current composition-only extension keys.',
            'The embedded symbol_contract constant value, enum value-kind, and type-entry families delegate to the already bounded semantic.symbol_contract schemas.',
            'The composition child key families are aliases of the already bounded semantic.composition child and standalone-DT child schemas; nested child IR summaries and child/generated-child parameter-override metadata remain delegated to their existing owners.',
            'Use the grouped presence_key_family_map to discover the bounded core, embedded symbol_contract, and composition-only intent_hir key families without collecting those key-family lists separately.',
            'The nested `signal_analysis`, `explicit_system_contract`, `system_contract`, and `symbol_contract` branches remain separate public surfaces with their own owners; this contract only freezes the intent-hir object shell itself.',
        ],
    };
}

sub normalized_semantic_intent_hir_contract_source {
    return 'FSM::Support::NormalizedSemanticIntentHIRContract';
}

sub normalized_semantic_intent_hir_presence_keys {
    return [
        qw(
            explicit_system_contract
            module_name
            parameter_count
            parameter_names
            regular_state_count
            regular_state_names
            requires_implicit_system_ports
            signal_analysis
            signal_count
            signal_names
            source_root_kind
            standalone_dt_count
            standalone_dt_enable_families
            standalone_dt_module_enable_family
            standalone_dt_names
            state_count
            symbol_contract
            system_contract
        ),
    ];
}

sub normalized_semantic_intent_hir_optional_composition_keys {
    return [
        qw(
            composition_child_count
            composition_children
            composition_generated_child_count
            composition_generated_children
            composition_generated_dt_child_count
            composition_generated_fsm_child_count
            composition_lane
            composition_standalone_dt_block_count
            composition_standalone_dt_child_count
            composition_standalone_dt_children
            composition_standalone_dt_multi_drive_target_count
        ),
    ];
}

sub normalized_semantic_intent_hir_symbol_contract_constant_value_entry_keys {
    return normalized_semantic_symbol_contract_constant_value_entry_keys();
}

sub normalized_semantic_intent_hir_symbol_contract_constant_scalar_value_extension_keys {
    return normalized_semantic_symbol_contract_constant_scalar_value_extension_keys();
}

sub normalized_semantic_intent_hir_symbol_contract_constant_list_value_extension_keys {
    return normalized_semantic_symbol_contract_constant_list_value_extension_keys();
}

sub normalized_semantic_intent_hir_symbol_contract_enum_entry_value_kinds {
    return normalized_semantic_symbol_contract_enum_entry_value_kinds();
}

sub normalized_semantic_intent_hir_symbol_contract_enum_member_value_kinds {
    return normalized_semantic_symbol_contract_enum_member_value_kinds();
}

sub normalized_semantic_intent_hir_symbol_contract_type_entry_keys {
    return normalized_semantic_symbol_contract_type_entry_keys();
}

sub normalized_semantic_intent_hir_symbol_contract_type_scalar_value_kinds {
    return normalized_semantic_symbol_contract_type_scalar_value_kinds();
}

sub normalized_semantic_intent_hir_symbol_contract_type_aggregate_value_kinds {
    return normalized_semantic_symbol_contract_type_aggregate_value_kinds();
}

sub normalized_semantic_intent_hir_symbol_contract_type_state_model_extension_keys {
    return normalized_semantic_symbol_contract_type_state_model_extension_keys();
}

sub normalized_semantic_intent_hir_symbol_contract_type_list_extension_keys {
    return normalized_semantic_symbol_contract_type_list_extension_keys();
}

sub normalized_semantic_intent_hir_symbol_contract_type_record_extension_keys {
    return normalized_semantic_symbol_contract_type_record_extension_keys();
}

sub normalized_semantic_intent_hir_composition_child_entry_keys {
    return normalized_semantic_composition_child_entry_keys();
}

sub normalized_semantic_intent_hir_composition_child_parameter_override_entry_keys {
    return normalized_semantic_composition_child_parameter_override_entry_keys();
}

sub normalized_semantic_intent_hir_composition_child_parameter_override_raw_value_extension_keys {
    return normalized_semantic_composition_child_parameter_override_raw_value_extension_keys();
}

sub normalized_semantic_intent_hir_composition_child_parameter_override_value_metadata_extension_keys {
    return normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys();
}

sub normalized_semantic_intent_hir_composition_generated_child_entry_keys {
    return normalized_semantic_composition_generated_child_entry_keys();
}

sub normalized_semantic_intent_hir_composition_generated_child_parameter_override_entry_keys {
    return normalized_semantic_composition_generated_child_parameter_override_entry_keys();
}

sub normalized_semantic_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys {
    return normalized_semantic_composition_generated_child_parameter_override_raw_value_extension_keys();
}

sub normalized_semantic_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys {
    return normalized_semantic_composition_generated_child_parameter_override_value_metadata_extension_keys();
}

sub normalized_semantic_intent_hir_composition_standalone_dt_child_entry_keys {
    return normalized_semantic_composition_standalone_dt_child_entry_keys();
}

sub normalized_semantic_intent_hir_composition_standalone_dt_enable_family_entry_keys {
    return normalized_semantic_composition_standalone_dt_enable_family_entry_keys();
}

sub normalized_semantic_intent_hir_composition_standalone_dt_module_enable_family_keys {
    return normalized_semantic_composition_standalone_dt_module_enable_family_keys();
}

sub normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys {
    return normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys();
}

sub normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_assertion_keys {
    return normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys();
}

sub normalized_semantic_intent_hir_presence_key_family_map {
    return {
        public_presence_keys => normalized_semantic_intent_hir_presence_keys(),
        symbol_contract_constant_value_entry_keys =>
            normalized_semantic_intent_hir_symbol_contract_constant_value_entry_keys(),
        symbol_contract_constant_scalar_value_extension_keys =>
            normalized_semantic_intent_hir_symbol_contract_constant_scalar_value_extension_keys(),
        symbol_contract_constant_list_value_extension_keys =>
            normalized_semantic_intent_hir_symbol_contract_constant_list_value_extension_keys(),
        symbol_contract_enum_entry_value_kinds =>
            normalized_semantic_intent_hir_symbol_contract_enum_entry_value_kinds(),
        symbol_contract_enum_member_value_kinds =>
            normalized_semantic_intent_hir_symbol_contract_enum_member_value_kinds(),
        symbol_contract_type_entry_keys =>
            normalized_semantic_intent_hir_symbol_contract_type_entry_keys(),
        symbol_contract_type_scalar_value_kinds =>
            normalized_semantic_intent_hir_symbol_contract_type_scalar_value_kinds(),
        symbol_contract_type_aggregate_value_kinds =>
            normalized_semantic_intent_hir_symbol_contract_type_aggregate_value_kinds(),
        symbol_contract_type_state_model_extension_keys =>
            normalized_semantic_intent_hir_symbol_contract_type_state_model_extension_keys(),
        symbol_contract_type_list_extension_keys =>
            normalized_semantic_intent_hir_symbol_contract_type_list_extension_keys(),
        symbol_contract_type_record_extension_keys =>
            normalized_semantic_intent_hir_symbol_contract_type_record_extension_keys(),
        optional_composition_keys => normalized_semantic_intent_hir_optional_composition_keys(),
        composition_child_entry_keys => normalized_semantic_intent_hir_composition_child_entry_keys(),
        composition_child_parameter_override_entry_keys =>
            normalized_semantic_intent_hir_composition_child_parameter_override_entry_keys(),
        composition_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
        composition_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
        composition_generated_child_entry_keys =>
            normalized_semantic_intent_hir_composition_generated_child_entry_keys(),
        composition_generated_child_parameter_override_entry_keys =>
            normalized_semantic_intent_hir_composition_generated_child_parameter_override_entry_keys(),
        composition_generated_child_parameter_override_raw_value_extension_keys =>
            normalized_semantic_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys(),
        composition_generated_child_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        composition_standalone_dt_child_entry_keys =>
            normalized_semantic_intent_hir_composition_standalone_dt_child_entry_keys(),
        composition_standalone_dt_enable_family_entry_keys =>
            normalized_semantic_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
        composition_standalone_dt_module_enable_family_keys =>
            normalized_semantic_intent_hir_composition_standalone_dt_module_enable_family_keys(),
        composition_standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
        composition_standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
    };
}

1;
