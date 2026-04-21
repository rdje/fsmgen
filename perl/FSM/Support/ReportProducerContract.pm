package FSM::Support::ReportProducerContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_report_producer_contract
    normalized_semantic_report_producer_extra_keys
    report_producer_contract_source
    report_producer_common_keys
);

sub report_producer_contract_source {
    return 'FSM::Support::ReportProducerContract';
}

sub build_report_producer_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => report_producer_contract_source(),
        object_name => 'producer',
        report_sources => [
            qw(
                FSM::Support::CheckDiagnostics
                FSM::Support::NormalizedSemanticReport
            ),
        ],
        entrypoints => {
            cli => [
                './bin/fsmgen --strict --check --json path/to/file.fsm',
                './bin/fsmgen --strict --emit-semantic-json path/to/file.fsm',
            ],
            in_process => [
                'FSM::Support::CheckDiagnostics::build_check_success_report(...)',
                'FSM::Support::CheckDiagnostics::build_check_failure_report(...)',
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)',
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_failure_report(...)',
            ],
        },
        common_presence_keys => report_producer_common_keys(),
        normalized_semantic_extra_presence_keys => normalized_semantic_report_producer_extra_keys(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        reused_across_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `producer` object shared by the public check JSON and normalized semantic JSON report surfaces.},
            'The common shared object records FSMGen identity plus the report builder owner, while normalized semantic JSON advertises its public semantic layer list as an additive bounded extension.',
            'Widen this nested object only when both public report surfaces or one explicitly documented report-specific branch need the same new field family.',
        ],
    };
}

sub report_producer_common_keys {
    return [
        qw(
            name
            report_source
        ),
    ];
}

sub normalized_semantic_report_producer_extra_keys {
    return [
        qw(
            semantic_layers
        ),
    ];
}

1;
