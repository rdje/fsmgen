package FSM::Support::CapabilityManifest;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::BackendValidationSection qw(build_backend_validation_section);
use FSM::Support::BackendValidationContract qw(build_backend_validation_contract);
use FSM::Support::CapabilityManifestContract qw(build_capability_manifest_contract);
use FSM::Support::CheckDiagnosticsContract qw(build_check_diagnostics_contract);
use FSM::Support::CompositionReportContract qw(build_composition_report_contract);
use FSM::Support::DiagnosticCodes qw(diagnostic_code_registry);
use FSM::Support::DiagnosticCodeRegistryContract qw(build_diagnostic_code_registry_contract);
use FSM::Support::DiagnosticsContract qw(build_diagnostics_contract);
use FSM::Support::EmbeddingContract qw(build_embedding_contract);
use FSM::Support::DocumentationSection qw(build_documentation_section);
use FSM::Support::ExtensionContract qw(build_extension_contract);
use FSM::Support::HDLGeneratorResultContract qw(build_hdl_generator_result_contract);
use FSM::Support::LanguageSurfaceSection qw(build_language_surface_section);
use FSM::Support::ProducerSection qw(build_producer_section);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::SemanticExportsSection qw(build_semantic_exports_section);
use FSM::Support::SupportAccountingContract qw(build_support_accounting_contract);

our @EXPORT_OK = qw(build_capability_manifest);

sub build_capability_manifest {
    my @entries = regression_corpus_entries();

    my %classifications = _count_by(\@entries, 'classification');
    my %coverage_buckets = _count_by(\@entries, 'coverage');
    my %families = _count_by(\@entries, 'family');
    my %source_kinds = _count_by(\@entries, 'source_kind');

    my @strict_supported_ids = map { $_->{id} } grep { $_->{strict_supported} } @entries;
    my @supported_ids = map { $_->{id} } grep { $_->{classification} eq 'supported_smoke' } @entries;
    my @expected_failure_ids = map { $_->{id} } grep { $_->{classification} eq 'expected_failure' } @entries;
    my $diagnostic_registry = diagnostic_code_registry();

    return {
        manifest_schema_version => 1,
        producer => build_producer_section(),
        support_accounting => {
            %{build_support_accounting_contract()},
            source => 'FSM::Support::RegressionCorpus',
            entry_count => scalar(@entries),
            classifications => \%classifications,
            coverage_buckets => \%coverage_buckets,
            families => \%families,
            source_kinds => \%source_kinds,
            supported_smoke_ids => \@supported_ids,
            strict_supported_ids => \@strict_supported_ids,
            expected_failure_ids => \@expected_failure_ids,
            catalog_entries => [
                map { _manifest_entry($_) } @entries,
            ],
            section_contract => build_support_accounting_contract(),
        },
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
        embedding => {
            composition_report => build_composition_report_contract(),
            hdl_generator_result => build_hdl_generator_result_contract(),
            typed_extensions => build_extension_contract(),
            section_contract => build_embedding_contract(),
        },
        language_surface => build_language_surface_section(),
        documentation => build_documentation_section(),
        manifest_contract => build_capability_manifest_contract(),
    };
}

sub _manifest_entry {
    my ($entry) = @_;

    my %manifest = map { $_ => $entry->{$_} } grep { exists $entry->{$_} } qw(
        id
        relpath
        family
        classification
        coverage
        source_kind
        strict_supported
        expected_module_name
        expected_top_name
        expected_lane
        expected_instance_count
        diagnostic_code
    );

    $manifest{strict_supported} = $entry->{strict_supported} ? JSON::PP::true : JSON::PP::false;
    $manifest{expected_child_modules} = [@{$entry->{expected_child_modules}}]
        if ref($entry->{expected_child_modules}) eq 'ARRAY';
    $manifest{search_path_relpaths} = [@{$entry->{search_path_relpaths}}]
        if ref($entry->{search_path_relpaths}) eq 'ARRAY';
    $manifest{expected_hdl_pattern_count} = scalar(@{$entry->{expected_hdl_patterns}})
        if ref($entry->{expected_hdl_patterns}) eq 'ARRAY';
    $manifest{has_expected_error_pattern} = $entry->{expected_error_pattern}
        ? JSON::PP::true
        : JSON::PP::false;
    $manifest{has_expected_hint_pattern} = $entry->{expected_hint_pattern}
        ? JSON::PP::true
        : JSON::PP::false;

    return \%manifest;
}

sub _count_by {
    my ($entries, $field) = @_;

    my %counts;
    for my $entry (@{$entries}) {
        my $value = $entry->{$field};
        $value = 'unknown' unless defined $value && length $value;
        $counts{$value}++;
    }

    return %counts;
}

1;
