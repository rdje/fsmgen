package FSM::Support::NormalizedSemanticReportContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::CheckFailureDiagnosticContract qw(
    check_failure_diagnostic_contract_source
    check_failure_diagnostic_matched_presence_keys
    check_failure_diagnostic_optional_artifact_keys
    check_failure_diagnostic_presence_keys
    check_failure_diagnostic_support_accounting_matched_presence_keys
    check_failure_diagnostic_support_accounting_presence_keys
);
use FSM::Support::NormalizedSemanticCompositionContract qw(
    normalized_semantic_composition_contract_source
    normalized_semantic_composition_presence_keys
);
use FSM::Support::NormalizedSemanticExplicitSystemContract qw(
    normalized_semantic_explicit_system_contract_source
    normalized_semantic_explicit_system_contract_presence_keys
);
use FSM::Support::NormalizedSemanticForwardIRContract qw(
    normalized_semantic_forward_ir_contract_source
    normalized_semantic_forward_ir_intent_hir_contract_source
    normalized_semantic_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_forward_ir_intent_hir_presence_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_contract_source
    normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys
    normalized_semantic_forward_ir_structural_rtl_ir_contract_source
    normalized_semantic_forward_ir_structural_rtl_ir_presence_keys
    normalized_semantic_forward_ir_presence_keys
);
use FSM::Support::NormalizedSemanticModuleContract qw(
    normalized_semantic_module_contract_source
    normalized_semantic_module_presence_keys
);
use FSM::Support::NormalizedSemanticSignalAnalysisContract qw(
    normalized_semantic_signal_analysis_contract_source
    normalized_semantic_signal_analysis_entry_presence_keys
    normalized_semantic_signal_analysis_presence_keys
);
use FSM::Support::NormalizedSemanticPayloadContract qw(
    normalized_semantic_payload_contract_source
    normalized_semantic_payload_composition_keys
    normalized_semantic_payload_explicit_system_contract_keys
    normalized_semantic_payload_forward_ir_nested_contract_source_map
    normalized_semantic_payload_forward_ir_nested_presence_key_map
    normalized_semantic_payload_nested_presence_key_map
    normalized_semantic_payload_presence_key_family_map
    normalized_semantic_payload_presence_keys
    normalized_semantic_payload_forward_ir_intent_hir_keys
    normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_keys
    normalized_semantic_payload_system_contract_keys
    normalized_semantic_payload_signal_analysis_keys
    normalized_semantic_payload_symbol_contract_keys
);
use FSM::Support::NormalizedSemanticSystemContract qw(
    normalized_semantic_system_contract_source
    normalized_semantic_system_contract_presence_keys
);
use FSM::Support::NormalizedSemanticSymbolContract qw(
    normalized_semantic_symbol_contract_source
    normalized_semantic_symbol_contract_presence_keys
);
use FSM::Support::ReportCommandContract qw(
    report_command_contract_source
    report_command_presence_keys
);
use FSM::Support::ReportGeneratedOutputContract qw(
    report_generated_output_contract_source
    report_generated_output_presence_keys
);
use FSM::Support::SerializableGenerationResultSnapshot qw(
    serializable_generation_result_snapshot_contract_source
    serializable_generation_result_snapshot_public_top_level_keys
);
use FSM::Support::SerializableDiagnosticSummary qw(
    serializable_diagnostic_summary_contract_source
    serializable_diagnostic_summary_public_top_level_keys
);
use FSM::Support::ReportProducerContract qw(
    normalized_semantic_report_producer_extra_keys
    report_producer_contract_source
    report_producer_common_keys
);
use FSM::Support::ReportSourceContract qw(
    report_source_contract_source
    report_source_presence_keys
);
use FSM::Support::SupportAccountingMatchContract qw(
    support_accounting_match_contract_source
    support_accounting_match_common_keys
    support_accounting_match_failure_keys
    support_accounting_match_success_keys
);

our @EXPORT_OK = qw(
    build_normalized_semantic_report_contract
    normalized_semantic_report_contract_source
    normalized_semantic_composition_keys
    normalized_semantic_explicit_system_contract_keys
    normalized_semantic_failure_diagnostic_keys
    normalized_semantic_failure_diagnostic_optional_artifact_keys
    normalized_semantic_failure_diagnostic_support_accounting_keys
    normalized_semantic_forward_ir_keys
    normalized_semantic_forward_ir_intent_hir_keys
    normalized_semantic_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_forward_ir_structural_rtl_ir_keys
    normalized_semantic_matched_failure_diagnostic_keys
    normalized_semantic_matched_failure_diagnostic_support_accounting_keys
    normalized_semantic_matched_failure_support_accounting_keys
    normalized_semantic_matched_success_support_accounting_keys
    normalized_semantic_module_keys
    normalized_semantic_module_optional_metric_keys
    normalized_semantic_nested_presence_key_map
    normalized_semantic_presence_key_family_map
    normalized_semantic_public_top_level_keys
    normalized_semantic_signal_analysis_entry_keys
    normalized_semantic_signal_analysis_keys
    normalized_semantic_system_contract_keys
    normalized_semantic_symbol_contract_keys
    normalized_semantic_success_only_top_level_keys
    normalized_semantic_success_semantic_keys
    normalized_semantic_support_accounting_keys
);

sub normalized_semantic_report_contract_source {
    return 'FSM::Support::NormalizedSemanticReportContract';
}

sub build_normalized_semantic_report_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => normalized_semantic_report_contract_source(),
        report_source => 'FSM::Support::NormalizedSemanticReport',
        entrypoints => {
            cli => './bin/fsmgen --strict --emit-semantic-json path/to/file.fsm',
            cli_aliases => [
                './bin/fsmgen --strict --semantic-json path/to/file.fsm',
                './bin/fsmgen --strict --emit-normalized-json path/to/file.fsm',
                './bin/fsmgen --strict --normalized-json path/to/file.fsm',
            ],
            in_process => [
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)',
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_failure_report(...)',
            ],
        },
        emits_hdl => JSON::PP::false,
        emits_support_accounting_object => JSON::PP::true,
        failure_diagnostics_reuse_stable_codes => JSON::PP::true,
        sanitizes_private_perl_objects => JSON::PP::true,
        public_layers => [qw(intent_hir lowered_rtl_ir structural_rtl_ir)],
        nested_contract_source_map => {
            command => report_command_contract_source(),
            failure_diagnostic => check_failure_diagnostic_contract_source(),
            diagnostic_summary => serializable_diagnostic_summary_contract_source(),
            generated_output => report_generated_output_contract_source(),
            generation_result_snapshot => serializable_generation_result_snapshot_contract_source(),
            composition => normalized_semantic_composition_contract_source(),
            explicit_system_contract => normalized_semantic_explicit_system_contract_source(),
            forward_ir => normalized_semantic_forward_ir_contract_source(),
            module => normalized_semantic_module_contract_source(),
            semantic => normalized_semantic_payload_contract_source(),
            signal_analysis => normalized_semantic_signal_analysis_contract_source(),
            system_contract => normalized_semantic_system_contract_source(),
            symbol_contract => normalized_semantic_symbol_contract_source(),
            producer => report_producer_contract_source(),
            source => report_source_contract_source(),
            support_accounting => support_accounting_match_contract_source(),
        },
        command_contract_source => report_command_contract_source(),
        failure_diagnostic_contract_source => check_failure_diagnostic_contract_source(),
        diagnostic_summary_contract_source => serializable_diagnostic_summary_contract_source(),
        generated_output_contract_source => report_generated_output_contract_source(),
        generation_result_snapshot_contract_source => serializable_generation_result_snapshot_contract_source(),
        composition_contract_source => normalized_semantic_composition_contract_source(),
        explicit_system_contract_source => normalized_semantic_explicit_system_contract_source(),
        forward_ir_contract_source => normalized_semantic_forward_ir_contract_source(),
        module_contract_source => normalized_semantic_module_contract_source(),
        semantic_contract_source => normalized_semantic_payload_contract_source(),
        signal_analysis_contract_source => normalized_semantic_signal_analysis_contract_source(),
        system_contract_source => normalized_semantic_system_contract_source(),
        symbol_contract_source => normalized_semantic_symbol_contract_source(),
        producer_contract_source => report_producer_contract_source(),
        source_contract_source => report_source_contract_source(),
        support_accounting_contract_source => support_accounting_match_contract_source(),
        public_top_level_presence_keys => normalized_semantic_public_top_level_keys(),
        nested_presence_key_map => normalized_semantic_nested_presence_key_map(),
        presence_key_family_map => normalized_semantic_presence_key_family_map(),
        command_presence_keys => report_command_presence_keys(),
        generated_output_presence_keys => report_generated_output_presence_keys(),
        producer_presence_keys => report_producer_common_keys(),
        producer_extra_presence_keys => normalized_semantic_report_producer_extra_keys(),
        source_presence_keys => report_source_presence_keys(),
        success_only_top_level_keys => normalized_semantic_success_only_top_level_keys(),
        support_accounting_presence_keys => normalized_semantic_support_accounting_keys(),
        failure_diagnostic_presence_keys => normalized_semantic_failure_diagnostic_keys(),
        matched_failure_diagnostic_presence_keys => normalized_semantic_matched_failure_diagnostic_keys(),
        failure_diagnostic_optional_artifact_keys => normalized_semantic_failure_diagnostic_optional_artifact_keys(),
        failure_diagnostic_support_accounting_presence_keys => normalized_semantic_failure_diagnostic_support_accounting_keys(),
        matched_failure_diagnostic_support_accounting_presence_keys => normalized_semantic_matched_failure_diagnostic_support_accounting_keys(),
        matched_success_support_accounting_presence_keys => normalized_semantic_matched_success_support_accounting_keys(),
        matched_failure_support_accounting_presence_keys => normalized_semantic_matched_failure_support_accounting_keys(),
        success_semantic_presence_keys => normalized_semantic_payload_presence_keys(),
        success_module_presence_keys => normalized_semantic_module_keys(),
        success_module_optional_metric_keys => normalized_semantic_module_optional_metric_keys(),
        success_explicit_system_contract_presence_keys => normalized_semantic_explicit_system_contract_keys(),
        success_signal_analysis_presence_keys => normalized_semantic_signal_analysis_keys(),
        success_signal_analysis_entry_presence_keys => normalized_semantic_signal_analysis_entry_keys(),
        success_system_contract_presence_keys => normalized_semantic_system_contract_keys(),
        success_forward_ir_presence_keys => normalized_semantic_forward_ir_keys(),
        semantic_presence_key_family_map => normalized_semantic_payload_presence_key_family_map(),
        semantic_nested_presence_key_map => normalized_semantic_payload_nested_presence_key_map(),
        forward_ir_nested_contract_source_map => normalized_semantic_payload_forward_ir_nested_contract_source_map(),
        forward_ir_nested_presence_key_map => normalized_semantic_payload_forward_ir_nested_presence_key_map(),
        forward_ir_intent_hir_contract_source => normalized_semantic_forward_ir_intent_hir_contract_source(),
        success_forward_ir_intent_hir_presence_keys => normalized_semantic_forward_ir_intent_hir_keys(),
        success_forward_ir_intent_hir_optional_composition_keys => normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        forward_ir_lowered_rtl_ir_contract_source => normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
        success_forward_ir_lowered_rtl_ir_presence_keys => normalized_semantic_forward_ir_lowered_rtl_ir_keys(),
        success_forward_ir_lowered_rtl_ir_optional_composition_keys => normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        forward_ir_structural_rtl_ir_contract_source => normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        success_forward_ir_structural_rtl_ir_presence_keys => normalized_semantic_forward_ir_structural_rtl_ir_keys(),
        success_symbol_contract_presence_keys => normalized_semantic_symbol_contract_keys(),
        composition_presence_keys => normalized_semantic_payload_composition_keys(),
        failure_omits_semantic_payload => JSON::PP::true,
        full_report_json_safe => JSON::PP::true,
        full_export_stable => JSON::PP::false,
        guidance => [
            'Treat the listed top-level and bounded nested key-presence lists as the public normalized semantic JSON contract for schema version 1.',
            'The nested command object is shared with check JSON and stays bounded through FSM::Support::ReportCommandContract.',
            'The nested failure diagnostic object is shared with check JSON and stays bounded through FSM::Support::CheckFailureDiagnosticContract.',
            'The top-level diagnostic_summary object stays bounded through FSM::Support::SerializableDiagnosticSummary.',
            'The nested generated_output object is shared with check JSON and stays bounded through FSM::Support::ReportGeneratedOutputContract.',
            'The success-only generation_result_snapshot object stays bounded through FSM::Support::SerializableGenerationResultSnapshot.',
            'The nested semantic success payload stays bounded through FSM::Support::NormalizedSemanticPayloadContract.',
            'The nested semantic composition object stays bounded through FSM::Support::NormalizedSemanticCompositionContract.',
            'The nested semantic explicit_system_contract object, when present, stays bounded through FSM::Support::NormalizedSemanticExplicitSystemContract.',
            'The nested semantic forward_ir object stays bounded through FSM::Support::NormalizedSemanticForwardIRContract.',
            'Use the grouped nested_presence_key_map to discover the primary nested object key families without collecting those key lists one field at a time.',
            'Use the grouped presence_key_family_map to discover the shell-owned shared-report, success, and failure key families without collecting those normalized semantic field-family lists separately.',
            'Use the grouped semantic_presence_key_family_map to discover the shell-owned semantic payload and child-extension key families without reconstructing them from separate success_* fields.',
            'Use the grouped semantic_nested_presence_key_map to discover the deeper semantic child key families without reconstructing them from separate success_* lists.',
            'Use the grouped forward_ir_nested_presence_key_map to discover the deeper semantic `forward_ir` child key families without reconstructing them from separate success_forward_ir_* lists.',
            'Use the grouped `forward_ir_nested_contract_source_map` to discover the deeper bounded semantic `forward_ir` shell owners without reconstructing them from parallel scalar fields.',
            'The nested semantic forward_ir.intent_hir object shell stays bounded through FSM::Support::NormalizedSemanticIntentHIRContract.',
            'The nested semantic forward_ir.lowered_rtl_ir object shell stays bounded through FSM::Support::NormalizedSemanticLoweredRTLIRContract.',
            'The nested semantic forward_ir.structural_rtl_ir object shell stays bounded through FSM::Support::NormalizedSemanticStructuralRTLIRContract.',
            'The nested semantic module object stays bounded through FSM::Support::NormalizedSemanticModuleContract.',
            'The nested semantic signal_analysis object stays bounded through FSM::Support::NormalizedSemanticSignalAnalysisContract.',
            'The nested semantic system_contract object stays bounded through FSM::Support::NormalizedSemanticSystemContract.',
            'The nested semantic symbol_contract object stays bounded through FSM::Support::NormalizedSemanticSymbolContract.',
            'The nested producer object is shared with check JSON and stays bounded through FSM::Support::ReportProducerContract.',
            'The nested source object is shared with check JSON and stays bounded through FSM::Support::ReportSourceContract.',
            'The current signal-analysis bucket entries also share one bounded core entry shape through FSM::Support::NormalizedSemanticSignalAnalysisContract.',
            'Do not treat every nested scalar/list/hash field inside those branches as frozen unless it is separately documented and regression-backed.',
            'Use the contract owner plus regression coverage to widen this surface deliberately instead of dumping raw pipeline state.',
        ],
    };
}

sub normalized_semantic_public_top_level_keys {
    return [
        qw(
            normalized_semantic_schema_version
            producer
            command
            source
            success
            diagnostics
            diagnostic_summary
            support_accounting
            generated_output
        ),
    ];
}

sub normalized_semantic_nested_presence_key_map {
    return {
        command => report_command_presence_keys(),
        failure_diagnostic => normalized_semantic_failure_diagnostic_keys(),
        diagnostic_summary => serializable_diagnostic_summary_public_top_level_keys(),
        generated_output => report_generated_output_presence_keys(),
        generation_result_snapshot => serializable_generation_result_snapshot_public_top_level_keys(),
        producer => report_producer_common_keys(),
        source => report_source_presence_keys(),
        support_accounting => normalized_semantic_support_accounting_keys(),
        semantic => normalized_semantic_success_semantic_keys(),
        module => normalized_semantic_module_keys(),
        explicit_system_contract => normalized_semantic_explicit_system_contract_keys(),
        signal_analysis => normalized_semantic_signal_analysis_keys(),
        system_contract => normalized_semantic_system_contract_keys(),
        forward_ir => normalized_semantic_forward_ir_keys(),
        symbol_contract => normalized_semantic_symbol_contract_keys(),
        composition => normalized_semantic_composition_keys(),
    };
}

sub normalized_semantic_presence_key_family_map {
    return {
        command_presence_keys => report_command_presence_keys(),
        generated_output_presence_keys => report_generated_output_presence_keys(),
        producer_presence_keys => report_producer_common_keys(),
        producer_extra_presence_keys => normalized_semantic_report_producer_extra_keys(),
        source_presence_keys => report_source_presence_keys(),
        success_only_top_level_keys => normalized_semantic_success_only_top_level_keys(),
        support_accounting_presence_keys => normalized_semantic_support_accounting_keys(),
        failure_diagnostic_presence_keys => normalized_semantic_failure_diagnostic_keys(),
        matched_failure_diagnostic_presence_keys => normalized_semantic_matched_failure_diagnostic_keys(),
        failure_diagnostic_optional_artifact_keys => normalized_semantic_failure_diagnostic_optional_artifact_keys(),
        failure_diagnostic_support_accounting_presence_keys => normalized_semantic_failure_diagnostic_support_accounting_keys(),
        matched_failure_diagnostic_support_accounting_presence_keys => normalized_semantic_matched_failure_diagnostic_support_accounting_keys(),
        matched_success_support_accounting_presence_keys => normalized_semantic_matched_success_support_accounting_keys(),
        matched_failure_support_accounting_presence_keys => normalized_semantic_matched_failure_support_accounting_keys(),
        success_semantic_presence_keys => normalized_semantic_success_semantic_keys(),
        success_module_presence_keys => normalized_semantic_module_keys(),
        success_module_optional_metric_keys => normalized_semantic_module_optional_metric_keys(),
        success_explicit_system_contract_presence_keys => normalized_semantic_explicit_system_contract_keys(),
        success_signal_analysis_presence_keys => normalized_semantic_signal_analysis_keys(),
        success_signal_analysis_entry_presence_keys => normalized_semantic_signal_analysis_entry_keys(),
        success_system_contract_presence_keys => normalized_semantic_system_contract_keys(),
        success_forward_ir_presence_keys => normalized_semantic_forward_ir_keys(),
        success_forward_ir_intent_hir_presence_keys => normalized_semantic_forward_ir_intent_hir_keys(),
        success_forward_ir_intent_hir_optional_composition_keys => normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        success_forward_ir_lowered_rtl_ir_presence_keys => normalized_semantic_forward_ir_lowered_rtl_ir_keys(),
        success_forward_ir_lowered_rtl_ir_optional_composition_keys => normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        success_forward_ir_structural_rtl_ir_presence_keys => normalized_semantic_forward_ir_structural_rtl_ir_keys(),
        success_symbol_contract_presence_keys => normalized_semantic_symbol_contract_keys(),
        composition_presence_keys => normalized_semantic_composition_keys(),
    };
}

sub normalized_semantic_success_only_top_level_keys {
    return [
        qw(semantic generation_result_snapshot),
    ];
}

sub normalized_semantic_support_accounting_keys {
    return support_accounting_match_common_keys();
}

sub normalized_semantic_failure_diagnostic_keys {
    return check_failure_diagnostic_presence_keys();
}

sub normalized_semantic_matched_failure_diagnostic_keys {
    return check_failure_diagnostic_matched_presence_keys();
}

sub normalized_semantic_failure_diagnostic_optional_artifact_keys {
    return check_failure_diagnostic_optional_artifact_keys();
}

sub normalized_semantic_failure_diagnostic_support_accounting_keys {
    return check_failure_diagnostic_support_accounting_presence_keys();
}

sub normalized_semantic_matched_failure_diagnostic_support_accounting_keys {
    return check_failure_diagnostic_support_accounting_matched_presence_keys();
}

sub normalized_semantic_matched_success_support_accounting_keys {
    return support_accounting_match_success_keys();
}

sub normalized_semantic_matched_failure_support_accounting_keys {
    return support_accounting_match_failure_keys();
}

sub normalized_semantic_success_semantic_keys {
    return normalized_semantic_payload_presence_keys();
}

sub normalized_semantic_module_keys {
    return normalized_semantic_module_presence_keys();
}

sub normalized_semantic_module_optional_metric_keys {
    return FSM::Support::NormalizedSemanticModuleContract::normalized_semantic_module_optional_metric_keys();
}

sub normalized_semantic_forward_ir_keys {
    return normalized_semantic_forward_ir_presence_keys();
}

sub normalized_semantic_forward_ir_intent_hir_keys {
    return normalized_semantic_forward_ir_intent_hir_presence_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys();
}

sub normalized_semantic_forward_ir_structural_rtl_ir_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_presence_keys();
}

sub normalized_semantic_explicit_system_contract_keys {
    return normalized_semantic_explicit_system_contract_presence_keys();
}

sub normalized_semantic_signal_analysis_keys {
    return normalized_semantic_signal_analysis_presence_keys();
}

sub normalized_semantic_signal_analysis_entry_keys {
    return normalized_semantic_signal_analysis_entry_presence_keys();
}

sub normalized_semantic_system_contract_keys {
    return normalized_semantic_system_contract_presence_keys();
}

sub normalized_semantic_symbol_contract_keys {
    return normalized_semantic_symbol_contract_presence_keys();
}

sub normalized_semantic_composition_keys {
    return normalized_semantic_composition_presence_keys();
}

1;
