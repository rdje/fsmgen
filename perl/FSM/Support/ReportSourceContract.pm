package FSM::Support::ReportSourceContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::ISFResetProvenance qw(reset_provenance_contract);

our @EXPORT_OK = qw(
    build_report_source_contract
    report_source_input_keys
    report_source_presence_key_family_map
    report_source_contract_source
    report_source_presence_keys
    report_source_optional_fields
    report_source_resolution_keys
);

sub report_source_contract_source {
    return 'FSM::Support::ReportSourceContract';
}

sub build_report_source_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => report_source_contract_source(),
        object_name => 'source',
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
        public_presence_keys => report_source_presence_keys(),
        optional_fields => report_source_optional_fields(),
        input_keys => report_source_input_keys(),
        resolution_keys => report_source_resolution_keys(),
        presence_key_family_map => report_source_presence_key_family_map(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        reused_across_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `source` object shared by the public check JSON and normalized semantic JSON report surfaces.},
            'The shared object records the caller-facing input and resolved path; successful directly parsed ISF sources also retain reset declaration provenance through optional_fields.',
            'Use the grouped presence_key_family_map to discover the bounded source input and resolution key families without collecting those key-family lists separately.',
            'Widen this nested object only when both public report surfaces and their manifest advertisement need the same additional field.',
        ],
    };
}

sub report_source_optional_fields {
    return {reset_provenance => reset_provenance_contract()};
}

sub report_source_input_keys {
    return [
        qw(
            input
        ),
    ];
}

sub report_source_resolution_keys {
    return [
        qw(
            resolved_path
        ),
    ];
}

sub report_source_presence_keys {
    return [
        qw(
            input
            resolved_path
        ),
    ];
}

sub report_source_presence_key_family_map {
    return {
        input_keys => report_source_input_keys(),
        resolution_keys => report_source_resolution_keys(),
    };
}

1;
