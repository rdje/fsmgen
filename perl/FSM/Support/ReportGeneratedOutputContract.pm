package FSM::Support::ReportGeneratedOutputContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_report_generated_output_contract
    report_generated_output_emission_keys
    report_generated_output_presence_key_family_map
    report_generated_output_contract_source
    report_generated_output_presence_keys
);

sub report_generated_output_contract_source {
    return 'FSM::Support::ReportGeneratedOutputContract';
}

sub build_report_generated_output_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => report_generated_output_contract_source(),
        object_name => 'generated_output',
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
        public_presence_keys => report_generated_output_presence_keys(),
        emission_keys => report_generated_output_emission_keys(),
        presence_key_family_map => report_generated_output_presence_key_family_map(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        reused_across_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `generated_output` object shared by the public check JSON and normalized semantic JSON report surfaces.},
            'The shared object records whether the public report invocation emitted HDL artifacts as a side effect.',
            'Use the grouped presence_key_family_map to discover the bounded generated-output emission key family without collecting that key-family list separately.',
            'Widen this nested object only when both public report surfaces need the same generated-output metadata and the change is backed by regression coverage.',
        ],
    };
}

sub report_generated_output_emission_keys {
    return [
        qw(
            emitted
        ),
    ];
}

sub report_generated_output_presence_keys {
    return [
        qw(
            emitted
        ),
    ];
}

sub report_generated_output_presence_key_family_map {
    return {
        emission_keys => report_generated_output_emission_keys(),
    };
}

1;
