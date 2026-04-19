package FSM::Support::NormalizedSemanticSymbolContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_normalized_semantic_symbol_contract
    normalized_semantic_symbol_contract_presence_keys
);

sub build_normalized_semantic_symbol_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::NormalizedSemanticSymbolContract',
        object_name => 'semantic.symbol_contract',
        report_sources => [
            qw(
                FSM::Support::NormalizedSemanticReport
            ),
        ],
        entrypoints => {
            cli => [
                './bin/fsmgen --strict --emit-semantic-json path/to/file.fsm',
            ],
            in_process => [
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)->{semantic}{symbol_contract}',
            ],
        },
        public_presence_keys => normalized_semantic_symbol_contract_presence_keys(),
        optional_for_symbol_free_sources => JSON::PP::true,
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic.symbol_contract` object used by successful public normalized semantic JSON reports for symbol-rich sources.},
            'The bounded public promise covers the published count, name-list, nested map, scalar-leaf, aggregate-path, and package-import top-level keys exported for declared symbols.',
            'Do not treat every nested scalar/list/hash field inside `constants`, `enums`, or `types` as frozen unless it is separately documented and regression-backed.',
        ],
    };
}

sub normalized_semantic_symbol_contract_presence_keys {
    return [
        qw(
            constant_count
            constant_names
            constants
            enum_count
            enum_names
            enums
            type_count
            type_names
            types
            constant_scalar_leaves
            constant_aggregate_paths
            package_import_count
            package_imports
        ),
    ];
}

1;
