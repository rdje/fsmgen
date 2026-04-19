package FSM::Support::CheckResultContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_check_result_contract
    check_result_presence_keys
);

sub build_check_result_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::CheckResultContract',
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
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `result` object used by successful public check JSON reports.},
            'The nested object records the small public success summary: module identity plus basic state, signal, and composition-child counts.',
            'Widen this nested object only when check JSON needs more success-result metadata and the change is backed by regression coverage.',
        ],
    };
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

1;
