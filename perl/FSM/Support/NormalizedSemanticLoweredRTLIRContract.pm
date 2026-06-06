package FSM::Support::NormalizedSemanticLoweredRTLIRContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_normalized_semantic_lowered_rtl_ir_contract
    normalized_semantic_lowered_rtl_ir_contract_source
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
    normalized_semantic_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_presence_key_family_map
    normalized_semantic_lowered_rtl_ir_presence_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_same_value_assertion_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys
    normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys
);

sub build_normalized_semantic_lowered_rtl_ir_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => normalized_semantic_lowered_rtl_ir_contract_source(),
        object_name => 'lowered_rtl_ir',
        parent_object_name => 'semantic.forward_ir.lowered_rtl_ir',
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
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)->{semantic}{forward_ir}{lowered_rtl_ir}',
            ],
        },
        public_presence_keys => normalized_semantic_lowered_rtl_ir_presence_keys(),
        optional_composition_keys => normalized_semantic_lowered_rtl_ir_optional_composition_keys(),
        output_drive_family_entry_keys =>
            normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys(),
        output_drive_rhs_enable_family_entry_keys =>
            normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        selector_conflict_target_entry_keys =>
            normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        selector_conflict_rhs_enable_family_entry_keys =>
            normalized_semantic_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        selector_conflict_multi_value_assertion_keys =>
            normalized_semantic_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        selector_conflict_same_value_assertion_keys =>
            normalized_semantic_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        composition_shared_datapath_candidate_entry_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        composition_shared_datapath_candidate_declared_type_extension_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        composition_shared_datapath_candidate_contributor_entry_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        composition_shared_datapath_candidate_contributor_declared_type_extension_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        composition_shared_datapath_candidate_contributor_drive_intent_entry_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        composition_shared_datapath_bound_connection_expr_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        composition_shared_datapath_aggregate_enable_family_entry_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        composition_shared_datapath_aggregate_enable_contributor_entry_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        composition_shared_datapath_assertion_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        presence_key_family_map => normalized_semantic_lowered_rtl_ir_presence_key_family_map(),
        optional_for_non_composition_sources => JSON::PP::true,
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic.forward_ir.lowered_rtl_ir` object used by successful public normalized semantic JSON reports.},
            'The bounded public promise covers the current lowered-RTL summary shared by direct roots, including selector-conflict metadata, plus the current composition-only extension keys.',
            'The output-drive family and rhs-enable-family key families describe the current nested entry schemas emitted in output_drive_families[].',
            'The selector-conflict target, rhs-enable-family, and assertion key families describe the current nested entry schemas emitted in selector_conflict_targets[].',
            'The standalone-DT multi-drive target and assertion key families describe the current nested entry schemas emitted in standalone_dt_multi_drive_targets[].',
            'The composition shared-datapath candidate key families describe the current nested entry schemas emitted in composition_shared_datapath_candidates[], including contributor drive-intent projections and their rhs-enable-family entries. Nested contributor child IR summaries remain delegated to their existing bounded contracts.',
            'Use the grouped presence_key_family_map to discover the bounded core and composition-only lowered_rtl_ir key families without collecting those key-family lists separately.',
            'Full normalized semantic export stabilization remains outside this bounded lowered-RTL contract.',
        ],
    };
}

sub normalized_semantic_lowered_rtl_ir_contract_source {
    return 'FSM::Support::NormalizedSemanticLoweredRTLIRContract';
}

sub normalized_semantic_lowered_rtl_ir_presence_keys {
    return [
        qw(
            module_name
            output_drive_families
            output_drive_family_count
            selector_conflict_target_count
            selector_conflict_targets
            source_root_kind
            standalone_dt_multi_drive_target_count
            standalone_dt_multi_drive_targets
            target_language
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_optional_composition_keys {
    return [
        qw(
            auxiliary_assignment_count
            composition_shared_datapath_candidate_count
            composition_shared_datapath_candidates
            instance_count
            instance_names
            internal_net_count
            internal_net_names
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys {
    return [
        qw(
            default_value
            driver_blocks
            driver_count
            driver_enable_signals
            family_enable_signals
            multiplexer_type
            reset_value
            rhs_enable_families
            rhs_values
            signal_name
            width
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys {
    return [
        qw(
            driver_blocks
            driver_enable_signals
            family_enable_signal
            rhs_value
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys {
    return [
        qw(
            family_enable_signals
            multi_value_assertion
            multiplexer_type
            rhs_enable_families
            rhs_values
            signal_name
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys {
    return [
        qw(
            driver_enable_signals
            family_enable_signal
            rhs_value
            same_value_assertion
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys {
    return [
        qw(
            input_count
            input_enable_signals
            kind
            target_signal
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_selector_conflict_same_value_assertion_keys {
    return [
        qw(
            input_count
            input_enable_signals
            kind
            rhs_value
            target_signal
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys {
    return [
        qw(
            dt_enable_signals
            dt_names
            lhs_enable_signals
            multi_drive_assertion
            multiplexer_type
            rhs_values
            signal_name
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys {
    return [
        qw(
            input_count
            input_enable_signals
            kind
            target_signal
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys {
    return [
        qw(
            signal_name
            width
            interface_type
            storage_class
            reset_value
            contributor_count
            contributors
            top_output_signals
            peer_input_count
            peer_input_endpoints
            default_lifted_visibility
            planned_reexport_top_output_signals
            loopback_allowed
            lifted_runtime_kind
            lifted_runtime_signal
            lifted_runtime_next_signal
            lifted_runtime_reset_value
            lifted_runtime_reset_active_level
            lifted_runtime_reset_kind
            lifted_runtime_reset_keyword
            aggregate_target_enable_signal
            multi_value_conflict_signal
            multi_value_assertion
            aggregate_enable_family_count
            aggregate_enable_families
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys {
    return [
        qw(
            declared_type_name
            declared_type_spec
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys {
    return [
        qw(
            kind
            instance_name
            module_name
            source_name
            endpoint
            bound_signal
            bound_signals
            bound_connection_expr
            output_drive_family
            drive_intent
            intent_hir
            lowered_rtl_ir
            structural_rtl_ir
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys {
    return [
        qw(
            declared_type_name
            declared_type_spec
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys {
    return [
        qw(
            default_value
            driver_blocks
            driver_count
            driver_enable_signals
            family_enable_signals
            multiplexer_type
            reset_value
            rhs_enable_families
            rhs_values
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys {
    return normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys();
}

sub normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys {
    return [
        qw(
            kind
            signal_name
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys {
    return [
        qw(
            rhs_value
            aggregate_enable_signal
            same_value_conflict_signal
            same_value_assertion
            contributor_count
            contributors
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys {
    return [
        qw(
            endpoint
            family_enable_signal
            source_enable_signal
            driver_blocks
            driver_enable_signals
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys {
    return [
        qw(
            input_count
            input_enable_signals
            kind
            result_signal
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_presence_key_family_map {
    return {
        public_presence_keys => normalized_semantic_lowered_rtl_ir_presence_keys(),
        optional_composition_keys => normalized_semantic_lowered_rtl_ir_optional_composition_keys(),
        output_drive_family_entry_keys =>
            normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys(),
        output_drive_rhs_enable_family_entry_keys =>
            normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        selector_conflict_target_entry_keys =>
            normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        selector_conflict_rhs_enable_family_entry_keys =>
            normalized_semantic_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        selector_conflict_multi_value_assertion_keys =>
            normalized_semantic_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        selector_conflict_same_value_assertion_keys =>
            normalized_semantic_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        composition_shared_datapath_candidate_entry_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        composition_shared_datapath_candidate_declared_type_extension_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        composition_shared_datapath_candidate_contributor_entry_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        composition_shared_datapath_candidate_contributor_declared_type_extension_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        composition_shared_datapath_candidate_contributor_drive_intent_entry_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        composition_shared_datapath_bound_connection_expr_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        composition_shared_datapath_aggregate_enable_family_entry_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        composition_shared_datapath_aggregate_enable_contributor_entry_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        composition_shared_datapath_assertion_keys =>
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
    };
}

1;
