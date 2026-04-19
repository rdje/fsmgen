package FSM::Support::CheckDiagnosticsContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::ReportProducerContract qw(report_producer_common_keys);
use FSM::Support::ReportSourceContract qw(report_source_presence_keys);
use FSM::Support::SupportAccountingMatchContract qw(
    support_accounting_match_common_keys
    support_accounting_match_failure_keys
    support_accounting_match_success_keys
);

our @EXPORT_OK = qw(
    build_check_diagnostics_contract
    check_json_failure_diagnostic_keys
    check_json_failure_diagnostic_optional_artifact_keys
    check_json_failure_diagnostic_support_accounting_keys
    check_json_matched_failure_diagnostic_keys
    check_json_matched_failure_support_accounting_keys
    check_json_matched_success_support_accounting_keys
    check_json_public_top_level_keys
    check_json_success_only_top_level_keys
    check_json_success_result_keys
    check_json_success_support_accounting_keys
);

sub build_check_diagnostics_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::CheckDiagnosticsContract',
        report_source => 'FSM::Support::CheckDiagnostics',
        entrypoints => {
            cli => './bin/fsmgen --strict --check --json path/to/file.fsm',
            cli_aliases => [
                './bin/fsmgen --strict --check-json path/to/file.fsm',
            ],
            in_process => [
                'FSM::Support::CheckDiagnostics::build_check_success_report(...)',
                'FSM::Support::CheckDiagnostics::build_check_failure_report(...)',
            ],
        },
        command_shape => './bin/fsmgen --strict --check --json path/to/file.fsm',
        alias => './bin/fsmgen --strict --check-json path/to/file.fsm',
        emits_stable_codes => JSON::PP::true,
        emits_hdl => JSON::PP::false,
        unclassified_failures_use_null_code => JSON::PP::true,
        emits_support_accounting_object => JSON::PP::true,
        emits_success_support_accounting_object => JSON::PP::true,
        emits_failure_diagnostic_support_accounting_object => JSON::PP::true,
        producer_contract_source => 'FSM::Support::ReportProducerContract',
        source_contract_source => 'FSM::Support::ReportSourceContract',
        support_accounting_contract_source => 'FSM::Support::SupportAccountingMatchContract',
        public_top_level_presence_keys => check_json_public_top_level_keys(),
        producer_presence_keys => report_producer_common_keys(),
        source_presence_keys => report_source_presence_keys(),
        success_only_top_level_keys => check_json_success_only_top_level_keys(),
        success_result_presence_keys => check_json_success_result_keys(),
        success_support_accounting_presence_keys => check_json_success_support_accounting_keys(),
        matched_success_support_accounting_presence_keys => check_json_matched_success_support_accounting_keys(),
        failure_diagnostic_presence_keys => check_json_failure_diagnostic_keys(),
        matched_failure_diagnostic_presence_keys => check_json_matched_failure_diagnostic_keys(),
        failure_diagnostic_optional_artifact_keys => check_json_failure_diagnostic_optional_artifact_keys(),
        failure_diagnostic_support_accounting_presence_keys => check_json_failure_diagnostic_support_accounting_keys(),
        matched_failure_diagnostic_support_accounting_presence_keys => check_json_matched_failure_support_accounting_keys(),
        full_report_json_safe => JSON::PP::true,
        full_diagnostic_schema_stable => JSON::PP::false,
        guidance => [
            'Treat the published top-level, success-result, and failure-diagnostic key lists as the bounded public check-JSON contract for schema version 1.',
            'The nested producer object is shared with normalized semantic JSON and stays bounded through FSM::Support::ReportProducerContract.',
            'The nested source object is shared with normalized semantic JSON and stays bounded through FSM::Support::ReportSourceContract.',
            'Success reports carry report-level support accounting, while failure reports carry support accounting inside each diagnostic object.',
            'Do not treat every nested artifact field as frozen unless it appears in the published bounded key lists or is widened deliberately with regression backing.',
        ],
    };
}

sub check_json_public_top_level_keys {
    return [
        qw(
            check_schema_version
            producer
            command
            source
            success
            diagnostics
            generated_output
        ),
    ];
}

sub check_json_success_only_top_level_keys {
    return [
        qw(
            support_accounting
            result
        ),
    ];
}

sub check_json_success_result_keys {
    return [
        qw(
            module_name
            state_count
            signal_count
            composition_child_count
        ),
    ];
}

sub check_json_success_support_accounting_keys {
    return support_accounting_match_common_keys();
}

sub check_json_matched_success_support_accounting_keys {
    return support_accounting_match_success_keys();
}

sub check_json_failure_diagnostic_keys {
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

sub check_json_matched_failure_diagnostic_keys {
    return [
        qw(
            matched_corpus_entry_id
            coverage
            classification
        ),
    ];
}

sub check_json_failure_diagnostic_optional_artifact_keys {
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

sub check_json_failure_diagnostic_support_accounting_keys {
    return support_accounting_match_common_keys();
}

sub check_json_matched_failure_support_accounting_keys {
    return support_accounting_match_failure_keys();
}

1;
