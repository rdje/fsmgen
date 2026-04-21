package FSM::Support::SupportAccountingMatchContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_support_accounting_match_contract
    support_accounting_match_contract_source
    support_accounting_match_common_keys
    support_accounting_match_failure_keys
    support_accounting_match_presence_key_family_map
    support_accounting_match_success_keys
);

sub support_accounting_match_contract_source {
    return 'FSM::Support::SupportAccountingMatchContract';
}

sub build_support_accounting_match_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => support_accounting_match_contract_source(),
        report_sources => [
            'FSM::Support::CheckDiagnostics',
            'FSM::Support::NormalizedSemanticReport',
        ],
        entrypoints => {
            cli => [
                './bin/fsmgen --strict --check --json path/to/file.fsm',
                './bin/fsmgen --strict --emit-semantic-json path/to/file.fsm',
            ],
            in_process => [
                'FSM::Support::CheckDiagnostics::build_check_success_report(...)->{support_accounting}',
                'FSM::Support::CheckDiagnostics::build_check_failure_report(...)->{diagnostics}[0]{support_accounting}',
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)->{support_accounting}',
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_failure_report(...)->{support_accounting}',
            ],
        },
        common_presence_keys => support_accounting_match_common_keys(),
        matched_success_presence_keys => support_accounting_match_success_keys(),
        matched_failure_presence_keys => support_accounting_match_failure_keys(),
        presence_key_family_map => support_accounting_match_presence_key_family_map(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        reused_across_public_reports => JSON::PP::true,
        guidance => [
            'Treat the published common and matched key lists as the bounded public contract for support-accounting match objects embedded in check JSON and normalized semantic JSON.',
            'Success-side objects carry source-kind and support-tier identity, while failure-side objects carry diagnostic-code and migration-hint identity.',
            'Use the grouped presence_key_family_map to discover the bounded common, matched-success, and matched-failure support-accounting key families without collecting those key-family lists separately.',
            'Widen this nested object only from regression-backed support-accounting truth shared across the public JSON/report surfaces.',
        ],
    };
}

sub support_accounting_match_common_keys {
    return [qw(matched)];
}

sub support_accounting_match_success_keys {
    return [
        qw(
            entry_id
            family
            coverage
            classification
            source_kind
            strict_supported
        ),
    ];
}

sub support_accounting_match_failure_keys {
    return [
        qw(
            entry_id
            family
            coverage
            classification
            diagnostic_code
            migration_hint_available
        ),
    ];
}

sub support_accounting_match_presence_key_family_map {
    return {
        common_presence_keys => support_accounting_match_common_keys(),
        matched_success_presence_keys => support_accounting_match_success_keys(),
        matched_failure_presence_keys => support_accounting_match_failure_keys(),
    };
}

1;
