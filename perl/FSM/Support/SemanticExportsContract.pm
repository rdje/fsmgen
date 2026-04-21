package FSM::Support::SemanticExportsContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::NormalizedSemanticReportContract qw(
    normalized_semantic_report_contract_source
);

our @EXPORT_OK = qw(
    build_semantic_exports_contract
    semantic_exports_contract_source
    semantic_exports_nested_contract_keys
    semantic_exports_public_top_level_keys
);

sub semantic_exports_contract_source {
    return 'FSM::Support::SemanticExportsContract';
}

sub build_semantic_exports_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => semantic_exports_contract_source(),
        report_source => 'FSM::Support::CapabilityManifest',
        entrypoints => {
            cli => './bin/fsmgen --capability-manifest',
            cli_aliases => [
                './bin/fsmgen --emit-capability-manifest',
            ],
            in_process => [
                'FSM::Support::CapabilityManifest::build_capability_manifest()->{semantic_exports}',
            ],
        },
        public_top_level_presence_keys => semantic_exports_public_top_level_keys(),
        nested_contract_keys => semantic_exports_nested_contract_keys(),
        nested_contract_source_map => {
            normalized_semantic_json => normalized_semantic_report_contract_source(),
        },
        normalized_semantic_json_contract_advertised => JSON::PP::true,
        full_semantic_exports_section_stable => JSON::PP::false,
        guidance => [
            'Treat the published semantic-exports top-level keys and nested contract ownership map as the bounded public manifest-facing contract for schema version 1.',
            'The semantic_exports section points consumers at bounded semantic interchange surfaces instead of turning every future semantic export into an already-frozen API.',
            'Widen the section deliberately when new semantic export formats are documented, support-accounted, and regression-backed.',
        ],
    };
}

sub semantic_exports_public_top_level_keys {
    return [
        qw(
            normalized_semantic_json
            section_contract
        ),
    ];
}

sub semantic_exports_nested_contract_keys {
    return [
        qw(
            normalized_semantic_json
        ),
    ];
}

1;
