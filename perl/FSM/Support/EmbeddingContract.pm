package FSM::Support::EmbeddingContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::CompositionReportContract qw(
    composition_report_contract_source
    composition_report_public_top_level_keys
);
use FSM::Support::ExtensionContract qw(
    extension_contract_public_top_level_keys
    extension_contract_source
);
use FSM::Support::HDLGeneratorResultContract qw(
    hdl_generator_result_contract_source
    hdl_generator_result_known_top_level_keys
);

our @EXPORT_OK = qw(
    build_embedding_contract
    embedding_contract_source
    embedding_nested_contract_keys
    embedding_nested_presence_key_map
    embedding_public_top_level_keys
);

sub embedding_contract_source {
    return 'FSM::Support::EmbeddingContract';
}

sub build_embedding_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => embedding_contract_source(),
        report_source => 'FSM::Support::CapabilityManifest',
        entrypoints => {
            cli => './bin/fsmgen --capability-manifest',
            cli_aliases => [
                './bin/fsmgen --emit-capability-manifest',
            ],
            in_process => [
                'FSM::Support::CapabilityManifest::build_capability_manifest()->{embedding}',
            ],
        },
        public_top_level_presence_keys => embedding_public_top_level_keys(),
        nested_contract_keys => embedding_nested_contract_keys(),
        nested_contract_source_map => {
            composition_report => composition_report_contract_source(),
            hdl_generator_result => hdl_generator_result_contract_source(),
            typed_extensions => extension_contract_source(),
        },
        nested_presence_key_map => embedding_nested_presence_key_map(),
        nested_contracts_advertised => JSON::PP::true,
        full_embedding_section_stable => JSON::PP::false,
        guidance => [
            'Treat the published embedding-section top-level keys and nested contract ownership map as the bounded public manifest-facing contract for schema version 1.',
            'Use the grouped nested_presence_key_map to discover the bounded key families for composition_report, hdl_generator_result, and typed_extensions without collecting those child key lists separately.',
            'The embedding section groups narrower in-process result, composition-report, and typed-extension contracts instead of turning the whole embedding tree into one flat API.',
            'Widen the section deliberately when new embedding-facing surfaces are documented and regression-backed.',
        ],
    };
}

sub embedding_public_top_level_keys {
    return [
        qw(
            composition_report
            hdl_generator_result
            typed_extensions
            section_contract
        ),
    ];
}

sub embedding_nested_contract_keys {
    return [
        qw(
            composition_report
            hdl_generator_result
            typed_extensions
        ),
    ];
}

sub embedding_nested_presence_key_map {
    return {
        composition_report => composition_report_public_top_level_keys(),
        hdl_generator_result => hdl_generator_result_known_top_level_keys(),
        typed_extensions => extension_contract_public_top_level_keys(),
    };
}

1;
