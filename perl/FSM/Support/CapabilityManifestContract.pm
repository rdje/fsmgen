package FSM::Support::CapabilityManifestContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use FSM::Support::BackendValidationContract qw(
    backend_validation_contract_source
);
use FSM::Support::DiagnosticsContract qw(
    diagnostics_contract_source
);
use FSM::Support::DocumentationContract qw(
    documentation_contract_source
);
use FSM::Support::EmbeddingContract qw(
    embedding_contract_source
);
use FSM::Support::LanguageSurfaceContract qw(
    language_surface_contract_source
);
use FSM::Support::ProducerContract qw(
    producer_contract_source
);
use FSM::Support::SemanticExportsContract qw(
    semantic_exports_contract_source
);
use FSM::Support::SupportAccountingContract qw(
    support_accounting_contract_source
);

our @EXPORT_OK = qw(
    build_capability_manifest_contract
    capability_manifest_top_level_contract_source_map
    capability_manifest_presence_key_family_map
    capability_manifest_top_level_section_presence_key_map
    capability_manifest_contract_source
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

sub capability_manifest_contract_source {
    return 'FSM::Support::CapabilityManifestContract';
}

sub build_capability_manifest_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => capability_manifest_contract_source(),
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
        top_level_contract_source_map => capability_manifest_top_level_contract_source_map(),
        top_level_section_presence_key_map => capability_manifest_top_level_section_presence_key_map(),
        presence_key_family_map => capability_manifest_presence_key_family_map(),
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
            'Use the grouped top_level_contract_source_map to discover which dedicated contract owns each public top-level manifest object without depending on per-section contract slot names.',
            'Use the grouped top_level_section_presence_key_map to discover the bounded key family for each public top-level manifest section without collecting those section lists one field at a time.',
            'Use the grouped presence_key_family_map to discover the manifest-owned *_presence_keys field families without collecting those legacy compatibility field lists separately.',
            'Deeper nested payload meaning stays with the dedicated section contract owners instead of becoming implicitly frozen just because it appears in sample manifest output.',
            'Widen the manifest deliberately from regression-backed support-accounting truth rather than turning the whole builder payload into an accidental API.',
        ],
    };
}

sub capability_manifest_top_level_contract_source_map {
    return {
        producer => producer_contract_source(),
        support_accounting => support_accounting_contract_source(),
        diagnostics => diagnostics_contract_source(),
        semantic_exports => semantic_exports_contract_source(),
        backend_validation => backend_validation_contract_source(),
        embedding => embedding_contract_source(),
        language_surface => language_surface_contract_source(),
        documentation => documentation_contract_source(),
    };
}

sub capability_manifest_top_level_section_presence_key_map {
    return {
        producer => capability_manifest_producer_keys(),
        support_accounting => capability_manifest_support_accounting_keys(),
        diagnostics => capability_manifest_diagnostics_keys(),
        semantic_exports => capability_manifest_semantic_exports_keys(),
        backend_validation => capability_manifest_backend_validation_keys(),
        embedding => capability_manifest_embedding_keys(),
        language_surface => capability_manifest_language_surface_keys(),
        documentation => capability_manifest_documentation_keys(),
    };
}

sub capability_manifest_presence_key_family_map {
    return {
        producer_presence_keys => capability_manifest_producer_keys(),
        support_accounting_presence_keys => capability_manifest_support_accounting_keys(),
        diagnostics_presence_keys => capability_manifest_diagnostics_keys(),
        semantic_exports_presence_keys => capability_manifest_semantic_exports_keys(),
        backend_validation_presence_keys => capability_manifest_backend_validation_keys(),
        embedding_presence_keys => capability_manifest_embedding_keys(),
        language_surface_presence_keys => capability_manifest_language_surface_keys(),
        documentation_presence_keys => capability_manifest_documentation_keys(),
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
            presence_key_family_map
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
            section_contract
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
