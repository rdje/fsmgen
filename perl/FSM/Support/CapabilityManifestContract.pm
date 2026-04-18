package FSM::Support::CapabilityManifestContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_capability_manifest_contract
    capability_manifest_backend_validation_keys
    capability_manifest_diagnostics_keys
    capability_manifest_documentation_keys
    capability_manifest_embedding_keys
    capability_manifest_language_surface_keys
    capability_manifest_producer_keys
    capability_manifest_public_top_level_keys
    capability_manifest_semantic_exports_keys
    capability_manifest_support_accounting_keys
);

sub build_capability_manifest_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::CapabilityManifestContract',
        report_source => 'FSM::Support::CapabilityManifest',
        entrypoints => {
            cli => './bin/fsmgen --capability-manifest',
            cli_aliases => [
                './bin/fsmgen --emit-capability-manifest',
            ],
            in_process => [
                'FSM::Support::CapabilityManifest::build_capability_manifest()',
            ],
        },
        public_top_level_presence_keys => capability_manifest_public_top_level_keys(),
        producer_presence_keys => capability_manifest_producer_keys(),
        support_accounting_presence_keys => capability_manifest_support_accounting_keys(),
        diagnostics_presence_keys => capability_manifest_diagnostics_keys(),
        semantic_exports_presence_keys => capability_manifest_semantic_exports_keys(),
        backend_validation_presence_keys => capability_manifest_backend_validation_keys(),
        embedding_presence_keys => capability_manifest_embedding_keys(),
        language_surface_presence_keys => capability_manifest_language_surface_keys(),
        documentation_presence_keys => capability_manifest_documentation_keys(),
        full_manifest_json_safe => JSON::PP::true,
        nested_section_contracts_advertised => JSON::PP::true,
        guidance => [
            'Treat the published top-level and first nested section key lists as the bounded public capability-manifest shell contract for schema version 1.',
            'Deeper nested payload meaning stays with the dedicated section contract owners instead of becoming implicitly frozen just because it appears in sample manifest output; support_accounting is the embedded special case where the section itself carries the dedicated contract owner.',
            'Widen the manifest deliberately from regression-backed support-accounting truth rather than turning the whole builder payload into an accidental API.',
        ],
    };
}

sub capability_manifest_public_top_level_keys {
    return [
        qw(
            manifest_schema_version
            producer
            support_accounting
            diagnostics
            semantic_exports
            backend_validation
            embedding
            language_surface
            documentation
            manifest_contract
        ),
    ];
}

sub capability_manifest_producer_keys {
    return [
        qw(
            name
            version
            git_commit
            contract_authority
            source
            section_contract
        ),
    ];
}

sub capability_manifest_support_accounting_keys {
    return [
        qw(
            schema_version
            status
            contract_source
            report_source
            entrypoints
            public_top_level_presence_keys
            bucket_presence_keys
            id_list_presence_keys
            catalog_entry_required_keys
            catalog_entry_optional_keys
            sanitized_catalog_entries
            derived_from_regression_corpus
            guidance
            source
            entry_count
            classifications
            coverage_buckets
            families
            source_kinds
            supported_smoke_ids
            strict_supported_ids
            expected_failure_ids
            catalog_entries
        ),
    ];
}

sub capability_manifest_diagnostics_keys {
    return [
        qw(
            registry_source
            stable_codes
            stable_code_registry
            check_json
            section_contract
        ),
    ];
}

sub capability_manifest_semantic_exports_keys {
    return [
        qw(
            normalized_semantic_json
            section_contract
        ),
    ];
}

sub capability_manifest_backend_validation_keys {
    return [
        qw(
            systemverilog_external
            section_contract
        ),
    ];
}

sub capability_manifest_embedding_keys {
    return [
        qw(
            composition_report
            hdl_generator_result
            typed_extensions
            section_contract
        ),
    ];
}

sub capability_manifest_language_surface_keys {
    return [
        qw(
            strict_mode
            default_mode_compatibility
            assignments
            system_contracts
            expressions
            declarations
            composition
            intentionally_blocked_or_not_yet_public
            surface_contract
        ),
    ];
}

sub capability_manifest_documentation_keys {
    return [
        qw(
            human_contract
            downstream_alignment
            section_contract
        ),
    ];
}

1;
