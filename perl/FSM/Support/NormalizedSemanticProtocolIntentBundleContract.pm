package FSM::Support::NormalizedSemanticProtocolIntentBundleContract;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
    build_normalized_semantic_protocol_intent_bundle_contract
    normalized_semantic_protocol_intent_bundle_channel_entry_keys
    normalized_semantic_protocol_intent_bundle_contract_source
    normalized_semantic_protocol_intent_bundle_presence_keys
    normalized_semantic_protocol_intent_bundle_schedule_report_entry_keys
);

sub normalized_semantic_protocol_intent_bundle_contract_source {
    return 'FSM::Support::NormalizedSemanticProtocolIntentBundleContract';
}

sub build_normalized_semantic_protocol_intent_bundle_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => normalized_semantic_protocol_intent_bundle_contract_source(),
        object_name => 'semantic.protocol_intent_bundle',
        report_sources => [
            qw(
                FSM::Support::NormalizedSemanticReport
            ),
        ],
        entrypoints => {
            cli => [
                './bin/fsmgen --strict --emit-semantic-json path/to/file.ppif',
            ],
        },
        public_presence_keys => normalized_semantic_protocol_intent_bundle_presence_keys(),
        channel_entry_keys => normalized_semantic_protocol_intent_bundle_channel_entry_keys(),
        schedule_report_entry_keys => normalized_semantic_protocol_intent_bundle_schedule_report_entry_keys(),
        guidance => [
            'Use this optional semantic payload child only when semantic.module.source_root_kind is ppif_bundle.',
            'The bundle object summarizes the aggregate IAL2 protocol/platform intent, generated review artifacts, and selected aggregate wrapper HDL entry.',
            'Per-channel generated .isf and .fsm artifacts remain reviewable roots; the aggregate wrapper/top .fsm is the selected HDL entry, not any one generated channel root.',
        ],
    };
}

sub normalized_semantic_protocol_intent_bundle_presence_keys {
    return [
        qw(
            schema
            mode
            source_object
            bundle
            channels
            generated_artifacts
            generated_ial1_schedule_report_count
            generated_ial1_schedule_reports
            unsupported_residue
        ),
    ];
}

sub normalized_semantic_protocol_intent_bundle_channel_entry_keys {
    return [
        qw(
            object_name
            source_object
            source_attribution
            target_channel
            bindings
            generated_artifacts
            transfer_fire_condition
            generated_runtime_assertions
            unsupported_residue
        ),
    ];
}

sub normalized_semantic_protocol_intent_bundle_schedule_report_entry_keys {
    return [
        qw(
            object_name
            channel
            schema
        ),
    ];
}

1;
