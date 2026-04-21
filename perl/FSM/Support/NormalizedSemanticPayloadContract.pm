package FSM::Support::NormalizedSemanticPayloadContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
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
    normalized_semantic_symbol_contract_source
    normalized_semantic_symbol_contract_presence_keys
);

our @EXPORT_OK = qw(
    build_normalized_semantic_payload_contract
    normalized_semantic_payload_explicit_system_contract_keys
    normalized_semantic_payload_presence_keys
    normalized_semantic_payload_forward_ir_keys
    normalized_semantic_payload_forward_ir_intent_hir_keys
    normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_keys
    normalized_semantic_payload_signal_analysis_entry_keys
    normalized_semantic_payload_signal_analysis_keys
    normalized_semantic_payload_system_contract_keys
    normalized_semantic_payload_symbol_contract_keys
    normalized_semantic_payload_composition_keys
);

sub build_normalized_semantic_payload_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::NormalizedSemanticPayloadContract',
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
        module_contract_source => normalized_semantic_module_contract_source(),
        module_presence_keys => normalized_semantic_module_presence_keys(),
        module_optional_metric_keys => normalized_semantic_module_optional_metric_keys(),
        explicit_system_contract_source => normalized_semantic_explicit_system_contract_source(),
        signal_analysis_contract_source => normalized_semantic_signal_analysis_contract_source(),
        system_contract_source => normalized_semantic_system_contract_source(),
        forward_ir_contract_source => normalized_semantic_forward_ir_contract_source(),
        symbol_contract_source => normalized_semantic_symbol_contract_source(),
        composition_contract_source => normalized_semantic_composition_contract_source(),
        explicit_system_contract_presence_keys => normalized_semantic_payload_explicit_system_contract_keys(),
        signal_analysis_presence_keys => normalized_semantic_payload_signal_analysis_keys(),
        signal_analysis_entry_presence_keys => normalized_semantic_payload_signal_analysis_entry_keys(),
        system_contract_presence_keys => normalized_semantic_payload_system_contract_keys(),
        forward_ir_presence_keys => normalized_semantic_payload_forward_ir_keys(),
        forward_ir_intent_hir_contract_source => normalized_semantic_forward_ir_intent_hir_contract_source(),
        forward_ir_intent_hir_presence_keys => normalized_semantic_payload_forward_ir_intent_hir_keys(),
        forward_ir_intent_hir_optional_composition_keys => normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys(),
        forward_ir_lowered_rtl_ir_contract_source => normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
        forward_ir_lowered_rtl_ir_presence_keys => normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys(),
        forward_ir_lowered_rtl_ir_optional_composition_keys => normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        forward_ir_structural_rtl_ir_contract_source => normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        forward_ir_structural_rtl_ir_presence_keys => normalized_semantic_payload_forward_ir_structural_rtl_ir_keys(),
        symbol_contract_presence_keys => normalized_semantic_payload_symbol_contract_keys(),
        composition_presence_keys => normalized_semantic_payload_composition_keys(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic` object used by successful public normalized semantic JSON reports.},
            'The nested object records the public semantic payload: module/system metadata, signal analysis, and the forward-IR projection.',
            'The nested `module` object stays bounded through FSM::Support::NormalizedSemanticModuleContract.',
            'The nested `explicit_system_contract` object, when present, stays bounded through FSM::Support::NormalizedSemanticExplicitSystemContract.',
            'The nested `signal_analysis` object stays bounded through FSM::Support::NormalizedSemanticSignalAnalysisContract.',
            'The nested `system_contract` object stays bounded through FSM::Support::NormalizedSemanticSystemContract.',
            'The nested `forward_ir` object stays bounded through FSM::Support::NormalizedSemanticForwardIRContract.',
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

sub normalized_semantic_payload_forward_ir_keys {
    return normalized_semantic_forward_ir_presence_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_keys {
    return normalized_semantic_forward_ir_intent_hir_presence_keys();
}

sub normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys {
    return normalized_semantic_forward_ir_intent_hir_optional_composition_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys();
}

sub normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys {
    return normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys();
}

sub normalized_semantic_payload_forward_ir_structural_rtl_ir_keys {
    return normalized_semantic_forward_ir_structural_rtl_ir_presence_keys();
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

sub normalized_semantic_payload_composition_keys {
    return normalized_semantic_composition_presence_keys();
}

1;
