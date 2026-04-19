package FSM::Support::NormalizedSemanticPayloadContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

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
        forward_ir_presence_keys => normalized_semantic_payload_forward_ir_keys(),
        composition_presence_keys => normalized_semantic_payload_composition_keys(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic` object used by successful public normalized semantic JSON reports.},
            'The nested object records the public semantic payload: module/system metadata, signal analysis, and the forward-IR projection.',
            'The same owner also publishes the nested `forward_ir` and optional `composition` key lists so that widening stays deliberate and regression-backed.',
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
    return [
        qw(
            intent_hir
            lowered_rtl_ir
            structural_rtl_ir
        ),
    ];
}

sub normalized_semantic_payload_composition_keys {
    return [
        qw(
            lane
            child_count
            children
            net_count
            resolved_link_count
            generated_child_count
            generated_children
            standalone_dt_child_count
            standalone_dt_children
            shared_datapath_candidate_count
            shared_datapath_candidates
            provenance_report
        ),
    ];
}

1;
