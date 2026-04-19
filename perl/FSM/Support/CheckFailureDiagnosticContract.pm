package FSM::Support::CheckFailureDiagnosticContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::SupportAccountingMatchContract qw(
    support_accounting_match_common_keys
    support_accounting_match_failure_keys
);

our @EXPORT_OK = qw(
    build_check_failure_diagnostic_contract
    check_failure_diagnostic_matched_presence_keys
    check_failure_diagnostic_optional_artifact_keys
    check_failure_diagnostic_presence_keys
    check_failure_diagnostic_support_accounting_matched_presence_keys
    check_failure_diagnostic_support_accounting_presence_keys
);

sub build_check_failure_diagnostic_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::CheckFailureDiagnosticContract',
        object_name => 'diagnostic',
        parent_object_name => 'diagnostics[]',
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
                'FSM::Support::CheckDiagnostics::build_check_failure_report(...)',
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_failure_report(...)',
            ],
        },
        support_accounting_contract_source => 'FSM::Support::SupportAccountingMatchContract',
        public_presence_keys => check_failure_diagnostic_presence_keys(),
        matched_presence_keys => check_failure_diagnostic_matched_presence_keys(),
        optional_artifact_keys => check_failure_diagnostic_optional_artifact_keys(),
        support_accounting_presence_keys => check_failure_diagnostic_support_accounting_presence_keys(),
        matched_support_accounting_presence_keys => check_failure_diagnostic_support_accounting_matched_presence_keys(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        reused_across_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested failure `diagnostic` object shared by the public check JSON and normalized semantic JSON report surfaces.},
            'The bounded public promise covers the core stable diagnostic identity, the matched-only corpus identity keys, the optional extracted artifact file keys, and the nested support-accounting match object.',
            'Widen this nested object only when the public failure-report surface needs more stable metadata and the change is backed by regression coverage.',
        ],
    };
}

sub check_failure_diagnostic_presence_keys {
    return [
        qw(
            code
            severity
            stability
            family
            summary
            message
            source_file
            support_accounting
            migration_hint_available
        ),
    ];
}

sub check_failure_diagnostic_matched_presence_keys {
    return [
        qw(
            matched_corpus_entry_id
            coverage
            classification
        ),
    ];
}

sub check_failure_diagnostic_optional_artifact_keys {
    return [
        qw(
            parent_composition_source
            generated_child_source
            expected_rtl_metadata_file
            expected_child_source_file
            rtl_metadata_file
        ),
    ];
}

sub check_failure_diagnostic_support_accounting_presence_keys {
    return support_accounting_match_common_keys();
}

sub check_failure_diagnostic_support_accounting_matched_presence_keys {
    return support_accounting_match_failure_keys();
}

1;
