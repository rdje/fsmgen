package FSM::Support::NormalizedSemanticForwardIRContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::NormalizedSemanticIntentHIRContract qw(
    normalized_semantic_intent_hir_optional_composition_keys
    normalized_semantic_intent_hir_presence_keys
);
use FSM::Support::NormalizedSemanticLoweredRTLIRContract qw(
    normalized_semantic_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_lowered_rtl_ir_presence_keys
);

our @EXPORT_OK = qw(
    build_normalized_semantic_forward_ir_contract
    normalized_semantic_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_forward_ir_intent_hir_presence_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys
    normalized_semantic_forward_ir_presence_keys
);

sub build_normalized_semantic_forward_ir_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::NormalizedSemanticForwardIRContract',
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
        intent_hir_contract_source => 'FSM::Support::NormalizedSemanticIntentHIRContract',
        intent_hir_presence_keys => normalized_semantic_forward_ir_intent_hir_presence_keys(),
        intent_hir_optional_composition_keys => normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        lowered_rtl_ir_contract_source => 'FSM::Support::NormalizedSemanticLoweredRTLIRContract',
        lowered_rtl_ir_presence_keys => normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        lowered_rtl_ir_optional_composition_keys => normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic.forward_ir` object used by successful public normalized semantic JSON reports.},
            'The nested object exposes only the current sanitized forward semantic projections, not raw compiler/private pipeline state.',
            'The nested `intent_hir` branch now also has one bounded owner for its current object shell and composition-only extension keys.',
            'The nested `lowered_rtl_ir` branch now also has one bounded owner for its current direct-root shell and composition-only extension keys.',
            'Widen this object deliberately through one named owner plus regression coverage instead of relying on sample JSON.',
        ],
    };
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

sub normalized_semantic_forward_ir_intent_hir_presence_keys {
    return normalized_semantic_intent_hir_presence_keys();
}

sub normalized_semantic_forward_ir_intent_hir_optional_composition_keys {
    return normalized_semantic_intent_hir_optional_composition_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys {
    return normalized_semantic_lowered_rtl_ir_presence_keys();
}

sub normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys {
    return normalized_semantic_lowered_rtl_ir_optional_composition_keys();
}

1;
