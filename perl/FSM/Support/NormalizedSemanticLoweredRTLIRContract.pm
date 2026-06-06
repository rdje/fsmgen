package FSM::Support::NormalizedSemanticLoweredRTLIRContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_normalized_semantic_lowered_rtl_ir_contract
    normalized_semantic_lowered_rtl_ir_contract_source
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
        presence_key_family_map => normalized_semantic_lowered_rtl_ir_presence_key_family_map(),
        optional_for_non_composition_sources => JSON::PP::true,
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic.forward_ir.lowered_rtl_ir` object used by successful public normalized semantic JSON reports.},
            'The bounded public promise covers the current lowered-RTL summary shared by direct roots, including selector-conflict metadata, plus the current composition-only extension keys.',
            'The output-drive family and rhs-enable-family key families describe the current nested entry schemas emitted in output_drive_families[].',
            'The selector-conflict target, rhs-enable-family, and assertion key families describe the current nested entry schemas emitted in selector_conflict_targets[].',
            'The standalone-DT multi-drive target and assertion key families describe the current nested entry schemas emitted in standalone_dt_multi_drive_targets[].',
            'Use the grouped presence_key_family_map to discover the bounded core and composition-only lowered_rtl_ir key families without collecting those key-family lists separately.',
            'The deeper composition candidate payload contents remain bounded only at the current object-shell level unless later widened deliberately.',
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
    };
}

1;
