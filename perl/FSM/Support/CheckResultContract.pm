package FSM::Support::CheckResultContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_check_result_contract
    check_result_contract_source
    check_result_identity_keys
    check_result_presence_key_family_map
    check_result_presence_keys
    check_result_summary_keys
);

sub check_result_contract_source {
    return 'FSM::Support::CheckResultContract';
}

sub build_check_result_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => check_result_contract_source(),
        object_name => 'result',
        report_sources => [
            qw(
                FSM::Support::CheckDiagnostics
            ),
        ],
        entrypoints => {
            cli => [
                './bin/fsmgen --strict --check --json path/to/file.fsm',
            ],
            in_process => [
                'FSM::Support::CheckDiagnostics::build_check_success_report(...)',
            ],
        },
        public_presence_keys => check_result_presence_keys(),
        identity_keys => check_result_identity_keys(),
        summary_keys => check_result_summary_keys(),
        presence_key_family_map => check_result_presence_key_family_map(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `result` object used by successful public check JSON reports.},
            'The nested object records the small public success summary: module identity plus basic state, signal, and composition-child counts.',
            'Use the grouped presence_key_family_map to discover the bounded result identity and summary key families without collecting those key-family lists separately.',
            'Widen this nested object only when check JSON needs more success-result metadata and the change is backed by regression coverage.',
        ],
    };
}

sub check_result_identity_keys {
    return [
        qw(
            module_name
        ),
    ];
}

sub check_result_summary_keys {
    return [
        qw(
            state_count
            signal_count
            composition_child_count
        ),
    ];
}

sub check_result_presence_keys {
    return [
        qw(
            module_name
            state_count
            signal_count
            composition_child_count
        ),
    ];
}

sub check_result_presence_key_family_map {
    return {
        identity_keys => check_result_identity_keys(),
        summary_keys => check_result_summary_keys(),
    };
}

1;
