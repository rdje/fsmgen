package FSM::Support::NormalizedSemanticPayloadContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::NormalizedSemanticCompositionContract qw(
    normalized_semantic_composition_presence_keys
);
use FSM::Support::NormalizedSemanticForwardIRContract qw(
    normalized_semantic_forward_ir_presence_keys
);
use FSM::Support::NormalizedSemanticModuleContract qw(
    normalized_semantic_module_optional_metric_keys
    normalized_semantic_module_presence_keys
);

our @EXPORT_OK = qw(
    build_normalized_semantic_payload_contract
    normalized_semantic_payload_presence_keys
    normalized_semantic_payload_forward_ir_keys
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
        module_contract_source => 'FSM::Support::NormalizedSemanticModuleContract',
        module_presence_keys => normalized_semantic_module_presence_keys(),
        module_optional_metric_keys => normalized_semantic_module_optional_metric_keys(),
        forward_ir_contract_source => 'FSM::Support::NormalizedSemanticForwardIRContract',
        composition_contract_source => 'FSM::Support::NormalizedSemanticCompositionContract',
        forward_ir_presence_keys => normalized_semantic_payload_forward_ir_keys(),
        composition_presence_keys => normalized_semantic_payload_composition_keys(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic` object used by successful public normalized semantic JSON reports.},
            'The nested object records the public semantic payload: module/system metadata, signal analysis, and the forward-IR projection.',
            'The nested `module` object stays bounded through FSM::Support::NormalizedSemanticModuleContract.',
            'The nested `forward_ir` object stays bounded through FSM::Support::NormalizedSemanticForwardIRContract.',
            'The optional nested `composition` object stays bounded through FSM::Support::NormalizedSemanticCompositionContract.',
            'The same owner still advertises the nested `forward_ir` and optional `composition` key lists so payload widening stays deliberate and regression-backed.',
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

sub normalized_semantic_payload_composition_keys {
    return normalized_semantic_composition_presence_keys();
}

1;
