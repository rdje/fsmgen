package FSM::Support::CapabilityManifest;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::BackendValidationSection qw(build_backend_validation_section);
use FSM::Support::CapabilityManifestContract qw(build_capability_manifest_contract);
use FSM::Support::CheckDiagnosticsContract qw(build_check_diagnostics_contract);
use FSM::Support::DiagnosticCodes qw(diagnostic_code_registry);
use FSM::Support::DiagnosticCodeRegistryContract qw(build_diagnostic_code_registry_contract);
use FSM::Support::DiagnosticsContract qw(build_diagnostics_contract);
use FSM::Support::DocumentationSection qw(build_documentation_section);
use FSM::Support::EmbeddingSection qw(build_embedding_section);
use FSM::Support::LanguageSurfaceSection qw(build_language_surface_section);
use FSM::Support::ProducerSection qw(build_producer_section);
use FSM::Support::SemanticExportsSection qw(build_semantic_exports_section);
use FSM::Support::SupportAccountingSection qw(build_support_accounting_section);

our @EXPORT_OK = qw(build_capability_manifest);

sub build_capability_manifest {
    my $diagnostic_registry = diagnostic_code_registry();

    return {
        manifest_schema_version => 1,
        producer => build_producer_section(),
        support_accounting => build_support_accounting_section(),
        diagnostics => {
            registry_source => 'FSM::Support::DiagnosticCodes',
            stable_codes => [
                map {
                    +{
                        code => $_,
                        %{$diagnostic_registry->{$_}},
                    }
                } sort keys %{$diagnostic_registry}
            ],
            stable_code_registry => build_diagnostic_code_registry_contract(),
            check_json => {
                %{build_check_diagnostics_contract()},
                supported_smoke_corpus_covered => JSON::PP::true,
                strict_supported_corpus_covered => JSON::PP::true,
                expected_failure_corpus_covered => JSON::PP::true,
                classifier_match_policy => 'most_specific_expected_error_pattern',
                success_match_policy => 'resolved_source_path_to_non_failure_corpus_entry',
            },
            section_contract => build_diagnostics_contract(),
        },
        semantic_exports => build_semantic_exports_section(),
        backend_validation => build_backend_validation_section(),
        embedding => build_embedding_section(),
        language_surface => build_language_surface_section(),
        documentation => build_documentation_section(),
        manifest_contract => build_capability_manifest_contract(),
    };
}

1;
