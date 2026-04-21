package FSM::Support::ReportCommandContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_report_command_contract
    report_command_contract_source
    report_command_presence_keys
);

sub report_command_contract_source {
    return 'FSM::Support::ReportCommandContract';
}

sub build_report_command_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => report_command_contract_source(),
        object_name => 'command',
        report_sources => [
            qw(
                FSM::Support::CheckDiagnostics
                FSM::Support::NormalizedSemanticReport
            ),
        ],
        report_mode_map => {
            'FSM::Support::CheckDiagnostics' => 'check',
            'FSM::Support::NormalizedSemanticReport' => 'semantic_export',
        },
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
        public_presence_keys => report_command_presence_keys(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        reused_across_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `command` object shared by the public check JSON and normalized semantic JSON report surfaces.},
            'The shared object records mode, JSON emission, strict-mode routing, and target-language intent for the report invocation.',
            'Widen this nested object only when both public report surfaces need the same new command metadata and the change is backed by regression coverage.',
        ],
    };
}

sub report_command_presence_keys {
    return [
        qw(
            mode
            json
            strict_mode
            target_language
        ),
    ];
}

1;
