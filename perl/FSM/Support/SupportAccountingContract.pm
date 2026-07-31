package FSM::Support::SupportAccountingContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_support_accounting_contract
    support_accounting_bucket_keys
    support_accounting_catalog_entry_optional_keys
    support_accounting_catalog_entry_required_keys
    support_accounting_contract_source
    support_accounting_id_list_keys
    support_accounting_presence_key_family_map
    support_accounting_public_top_level_keys
);

sub support_accounting_contract_source {
    return 'FSM::Support::SupportAccountingContract';
}

sub build_support_accounting_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => support_accounting_contract_source(),
        report_source => 'FSM::Support::RegressionCorpus',
        entrypoints => {
            cli => './bin/fsmgen --capability-manifest',
            cli_aliases => [
                './bin/fsmgen --emit-capability-manifest',
            ],
            in_process => [
                'FSM::Support::CapabilityManifest::build_capability_manifest()->{support_accounting}',
                'FSM::Support::SupportAccountingSection::build_support_accounting_section()',
                'FSM::Support::RegressionCorpus::regression_corpus_entries()',
            ],
        },
        public_top_level_presence_keys => support_accounting_public_top_level_keys(),
        bucket_presence_keys => support_accounting_bucket_keys(),
        id_list_presence_keys => support_accounting_id_list_keys(),
        catalog_entry_required_keys => support_accounting_catalog_entry_required_keys(),
        catalog_entry_optional_keys => support_accounting_catalog_entry_optional_keys(),
        presence_key_family_map => support_accounting_presence_key_family_map(),
        sanitized_catalog_entries => JSON::PP::true,
        derived_from_regression_corpus => JSON::PP::true,
        guidance => [
            'Treat the published support-accounting top-level and catalog-entry key lists as the bounded manifest-facing contract for schema version 1.',
            'Use the grouped presence_key_family_map to discover the bounded bucket, id-list, and catalog-entry key families without collecting those key-family lists separately.',
            'Catalog entries are sanitized projections of regression-corpus truth, not a promise that every internal corpus field is now public.',
            'Widen this section only when new fields are backed by the maintained corpus and regression-locked deliberately.',
        ],
    };
}

sub support_accounting_public_top_level_keys {
    return [
        qw(
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

sub support_accounting_bucket_keys {
    return [
        qw(
            classifications
            coverage_buckets
            families
            source_kinds
        ),
    ];
}

sub support_accounting_id_list_keys {
    return [
        qw(
            supported_smoke_ids
            strict_supported_ids
            expected_failure_ids
        ),
    ];
}

sub support_accounting_catalog_entry_required_keys {
    return [
        qw(
            id
            relpath
            family
            classification
            coverage
            source_kind
            strict_supported
            has_expected_error_pattern
            has_expected_hint_pattern
        ),
    ];
}

sub support_accounting_catalog_entry_optional_keys {
    return [
        qw(
            expected_module_name
            expected_top_name
            expected_lane
            expected_instance_count
            diagnostic_code
            expected_child_modules
            search_path_relpaths
            expected_hdl_pattern_count
            private_capabilities
            private_nonclaims
        ),
    ];
}

sub support_accounting_presence_key_family_map {
    return {
        bucket_presence_keys => support_accounting_bucket_keys(),
        id_list_presence_keys => support_accounting_id_list_keys(),
        catalog_entry_required_keys => support_accounting_catalog_entry_required_keys(),
        catalog_entry_optional_keys => support_accounting_catalog_entry_optional_keys(),
    };
}

1;
