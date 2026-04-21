package FSM::Support::NormalizedSemanticSignalAnalysisContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_normalized_semantic_signal_analysis_contract
    normalized_semantic_signal_analysis_contract_source
    normalized_semantic_signal_analysis_entry_presence_keys
    normalized_semantic_signal_analysis_presence_keys
);

sub normalized_semantic_signal_analysis_contract_source {
    return 'FSM::Support::NormalizedSemanticSignalAnalysisContract';
}

sub build_normalized_semantic_signal_analysis_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => normalized_semantic_signal_analysis_contract_source(),
        object_name => 'signal_analysis',
        parent_object_name => 'semantic.signal_analysis',
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
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)->{semantic}{signal_analysis}',
            ],
        },
        public_presence_keys => normalized_semantic_signal_analysis_presence_keys(),
        entry_presence_keys => normalized_semantic_signal_analysis_entry_presence_keys(),
        bucket_entries_share_one_core_shape => JSON::PP::true,
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `signal_analysis` object used inside successful public normalized semantic JSON reports.},
            'The bounded public promise covers the current signal-family buckets plus the shared core entry shape each bucket emits today.',
            'The published entry key list freezes the common signal identity/direction/width/signed fields without pretending every optional typed extension field is frozen too.',
        ],
    };
}

sub normalized_semantic_signal_analysis_presence_keys {
    return [
        qw(
            inputs
            multi_bit
            outputs
            single_bit
        ),
    ];
}

sub normalized_semantic_signal_analysis_entry_presence_keys {
    return [
        qw(
            direction
            name
            signed
            width
        ),
    ];
}

1;
