package FSM::Support::CheckDiagnosticsContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::CheckFailureDiagnosticContract qw(
    check_failure_diagnostic_contract_source
    check_failure_diagnostic_matched_presence_keys
    check_failure_diagnostic_optional_artifact_keys
    check_failure_diagnostic_presence_keys
    check_failure_diagnostic_support_accounting_matched_presence_keys
    check_failure_diagnostic_support_accounting_presence_keys
);
use FSM::Support::CheckResultContract qw(
    check_result_contract_source
    check_result_presence_keys
);
use FSM::Support::ReportCommandContract qw(
    report_command_contract_source
    report_command_presence_keys
);
use FSM::Support::ReportGeneratedOutputContract qw(
    report_generated_output_contract_source
    report_generated_output_presence_keys
);
use FSM::Support::ReportProducerContract qw(
    report_producer_common_keys
    report_producer_contract_source
);
use FSM::Support::ReportSourceContract qw(
    report_source_contract_source
    report_source_presence_keys
);
use FSM::Support::SupportAccountingMatchContract qw(
    support_accounting_match_contract_source
    support_accounting_match_common_keys
    support_accounting_match_failure_keys
    support_accounting_match_success_keys
);

our @EXPORT_OK = qw(
    build_check_diagnostics_contract
    check_diagnostics_contract_source
    check_json_failure_diagnostic_keys
    check_json_failure_diagnostic_optional_artifact_keys
    check_json_failure_diagnostic_support_accounting_keys
    check_json_matched_failure_diagnostic_keys
    check_json_matched_failure_support_accounting_keys
    check_json_matched_success_support_accounting_keys
    check_json_nested_presence_key_map
    check_json_presence_key_family_map
    check_json_public_top_level_keys
    check_json_success_only_top_level_keys
    check_json_success_result_keys
    check_json_success_support_accounting_keys
);

sub check_diagnostics_contract_source {
    return 'FSM::Support::CheckDiagnosticsContract';
}

sub build_check_diagnostics_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => check_diagnostics_contract_source(),
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
        nested_contract_source_map => {
            command => report_command_contract_source(),
            failure_diagnostic => check_failure_diagnostic_contract_source(),
            generated_output => report_generated_output_contract_source(),
            producer => report_producer_contract_source(),
            result => check_result_contract_source(),
            source => report_source_contract_source(),
            support_accounting => support_accounting_match_contract_source(),
        },
        command_contract_source => report_command_contract_source(),
        failure_diagnostic_contract_source => check_failure_diagnostic_contract_source(),
        result_contract_source => check_result_contract_source(),
        generated_output_contract_source => report_generated_output_contract_source(),
        producer_contract_source => report_producer_contract_source(),
        source_contract_source => report_source_contract_source(),
        support_accounting_contract_source => support_accounting_match_contract_source(),
        public_top_level_presence_keys => check_json_public_top_level_keys(),
        nested_presence_key_map => check_json_nested_presence_key_map(),
        command_presence_keys => report_command_presence_keys(),
        generated_output_presence_keys => report_generated_output_presence_keys(),
        producer_presence_keys => report_producer_common_keys(),
        source_presence_keys => report_source_presence_keys(),
        success_only_top_level_keys => check_json_success_only_top_level_keys(),
        success_result_presence_keys => check_result_presence_keys(),
        success_support_accounting_presence_keys => check_json_success_support_accounting_keys(),
        matched_success_support_accounting_presence_keys => check_json_matched_success_support_accounting_keys(),
        failure_diagnostic_presence_keys => check_json_failure_diagnostic_keys(),
        matched_failure_diagnostic_presence_keys => check_json_matched_failure_diagnostic_keys(),
        failure_diagnostic_optional_artifact_keys => check_json_failure_diagnostic_optional_artifact_keys(),
        failure_diagnostic_support_accounting_presence_keys => check_json_failure_diagnostic_support_accounting_keys(),
        matched_failure_diagnostic_support_accounting_presence_keys => check_json_matched_failure_support_accounting_keys(),
        presence_key_family_map => check_json_presence_key_family_map(),
        full_report_json_safe => JSON::PP::true,
        full_diagnostic_schema_stable => JSON::PP::false,
        guidance => [
            'Treat the published top-level, success-result, and failure-diagnostic key lists as the bounded public check-JSON contract for schema version 1.',
            'The nested command object is shared with normalized semantic JSON and stays bounded through FSM::Support::ReportCommandContract.',
            'The nested failure diagnostic object stays bounded through FSM::Support::CheckFailureDiagnosticContract.',
            'The nested success result object stays bounded through FSM::Support::CheckResultContract.',
            'The nested generated_output object is shared with normalized semantic JSON and stays bounded through FSM::Support::ReportGeneratedOutputContract.',
            'The nested producer object is shared with normalized semantic JSON and stays bounded through FSM::Support::ReportProducerContract.',
            'The nested source object is shared with normalized semantic JSON and stays bounded through FSM::Support::ReportSourceContract.',
            'Use the grouped nested_presence_key_map to discover the primary nested object key families without collecting those key lists one field at a time.',
            'Use the grouped presence_key_family_map to discover the shell-owned success, failure, and shared report key families without collecting those field-family lists separately.',
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

sub check_json_nested_presence_key_map {
    return {
        command => report_command_presence_keys(),
        result => check_result_presence_keys(),
        failure_diagnostic => check_json_failure_diagnostic_keys(),
        generated_output => report_generated_output_presence_keys(),
        producer => report_producer_common_keys(),
        source => report_source_presence_keys(),
        support_accounting => check_json_success_support_accounting_keys(),
    };
}

sub check_json_presence_key_family_map {
    return {
        command_presence_keys => report_command_presence_keys(),
        generated_output_presence_keys => report_generated_output_presence_keys(),
        producer_presence_keys => report_producer_common_keys(),
        source_presence_keys => report_source_presence_keys(),
        success_only_top_level_keys => check_json_success_only_top_level_keys(),
        success_result_presence_keys => check_result_presence_keys(),
        success_support_accounting_presence_keys => check_json_success_support_accounting_keys(),
        matched_success_support_accounting_presence_keys => check_json_matched_success_support_accounting_keys(),
        failure_diagnostic_presence_keys => check_json_failure_diagnostic_keys(),
        matched_failure_diagnostic_presence_keys => check_json_matched_failure_diagnostic_keys(),
        failure_diagnostic_optional_artifact_keys => check_json_failure_diagnostic_optional_artifact_keys(),
        failure_diagnostic_support_accounting_presence_keys => check_json_failure_diagnostic_support_accounting_keys(),
        matched_failure_diagnostic_support_accounting_presence_keys => check_json_matched_failure_support_accounting_keys(),
    };
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
    return check_result_presence_keys();
}

sub check_json_success_support_accounting_keys {
    return support_accounting_match_common_keys();
}

sub check_json_matched_success_support_accounting_keys {
    return support_accounting_match_success_keys();
}

sub check_json_failure_diagnostic_keys {
    return check_failure_diagnostic_presence_keys();
}

sub check_json_matched_failure_diagnostic_keys {
    return check_failure_diagnostic_matched_presence_keys();
}

sub check_json_failure_diagnostic_optional_artifact_keys {
    return check_failure_diagnostic_optional_artifact_keys();
}

sub check_json_failure_diagnostic_support_accounting_keys {
    return check_failure_diagnostic_support_accounting_presence_keys();
}

sub check_json_matched_failure_support_accounting_keys {
    return check_failure_diagnostic_support_accounting_matched_presence_keys();
}

1;
