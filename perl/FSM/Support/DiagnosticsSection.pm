package FSM::Support::DiagnosticsSection;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use FSM::Support::CheckDiagnosticsContract qw(build_check_diagnostics_contract);
use FSM::Support::DiagnosticCodes qw(diagnostic_code_registry);
use FSM::Support::DiagnosticCodeRegistryContract qw(build_diagnostic_code_registry_contract);
use FSM::Support::DiagnosticsContract qw(build_diagnostics_contract);

our @EXPORT_OK = qw(
    build_manifest_check_json_surface
    build_diagnostics_section
);

sub build_diagnostics_section {
    my $diagnostic_registry = diagnostic_code_registry();

    return {
        registry_source => 'FSM::Support::DiagnosticCodes',
        stable_codes => [
            map {
                +{
                    code => $_,
                    %{$diagnostic_registry->{$_}},
                }
            } sort keys %{$diagnostic_registry || {}}
        ],
        stable_code_registry => build_diagnostic_code_registry_contract(),
        check_json => build_manifest_check_json_surface(),
        section_contract => build_diagnostics_contract(),
    };
}

sub build_manifest_check_json_surface {
    return {
        %{build_check_diagnostics_contract()},
        supported_smoke_corpus_covered => JSON::PP::true,
        strict_supported_corpus_covered => JSON::PP::true,
        expected_failure_corpus_covered => JSON::PP::true,
        classifier_match_policy => 'most_specific_expected_error_pattern',
        success_match_policy => 'resolved_source_path_to_non_failure_corpus_entry',
    };
}

1;
