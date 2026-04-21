package FSM::Support::NormalizedSemanticCompositionContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::CompositionReportContract qw(
    composition_report_contract_source
);

our @EXPORT_OK = qw(
    build_normalized_semantic_composition_contract
    normalized_semantic_composition_presence_keys
);

sub build_normalized_semantic_composition_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::NormalizedSemanticCompositionContract',
        object_name => 'composition',
        parent_object_name => 'semantic.composition',
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
        public_presence_keys => normalized_semantic_composition_presence_keys(),
        provenance_report_contract_source => composition_report_contract_source(),
        optional_for_non_composition_sources => JSON::PP::true,
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `composition` object used inside successful public normalized semantic JSON reports for composition sources.},
            'The bounded public promise covers the lane, child/net/link, generated-child, standalone-DT-child, shared-datapath, and sanitized provenance-report keys exported for composition roots.',
            'The nested provenance_report fragment stays bounded through FSM::Support::CompositionReportContract.',
        ],
    };
}

sub normalized_semantic_composition_presence_keys {
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
