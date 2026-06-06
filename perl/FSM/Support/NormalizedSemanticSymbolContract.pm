package FSM::Support::NormalizedSemanticSymbolContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_normalized_semantic_symbol_contract
    normalized_semantic_symbol_contract_constant_detail_keys
    normalized_semantic_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_symbol_contract_constant_value_entry_keys
    normalized_semantic_symbol_contract_enum_entry_value_kinds
    normalized_semantic_symbol_contract_enum_member_value_kinds
    normalized_semantic_symbol_contract_source
    normalized_semantic_symbol_contract_presence_key_family_map
    normalized_semantic_symbol_contract_presence_keys
    normalized_semantic_symbol_contract_summary_presence_keys
    normalized_semantic_symbol_contract_symbol_map_keys
    normalized_semantic_symbol_contract_symbol_name_keys
    normalized_semantic_symbol_contract_package_import_keys
    normalized_semantic_symbol_contract_type_aggregate_value_kinds
    normalized_semantic_symbol_contract_type_entry_keys
    normalized_semantic_symbol_contract_type_list_extension_keys
    normalized_semantic_symbol_contract_type_record_extension_keys
    normalized_semantic_symbol_contract_type_scalar_value_kinds
    normalized_semantic_symbol_contract_type_state_model_extension_keys
);

sub normalized_semantic_symbol_contract_source {
    return 'FSM::Support::NormalizedSemanticSymbolContract';
}

sub build_normalized_semantic_symbol_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => normalized_semantic_symbol_contract_source(),
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
        summary_presence_keys => normalized_semantic_symbol_contract_summary_presence_keys(),
        symbol_name_keys => normalized_semantic_symbol_contract_symbol_name_keys(),
        symbol_map_keys => normalized_semantic_symbol_contract_symbol_map_keys(),
        constant_detail_keys => normalized_semantic_symbol_contract_constant_detail_keys(),
        constant_value_entry_keys => normalized_semantic_symbol_contract_constant_value_entry_keys(),
        constant_scalar_value_extension_keys =>
            normalized_semantic_symbol_contract_constant_scalar_value_extension_keys(),
        constant_list_value_extension_keys =>
            normalized_semantic_symbol_contract_constant_list_value_extension_keys(),
        enum_entry_value_kinds => normalized_semantic_symbol_contract_enum_entry_value_kinds(),
        enum_member_value_kinds => normalized_semantic_symbol_contract_enum_member_value_kinds(),
        type_entry_keys => normalized_semantic_symbol_contract_type_entry_keys(),
        type_scalar_value_kinds => normalized_semantic_symbol_contract_type_scalar_value_kinds(),
        type_aggregate_value_kinds => normalized_semantic_symbol_contract_type_aggregate_value_kinds(),
        type_state_model_extension_keys =>
            normalized_semantic_symbol_contract_type_state_model_extension_keys(),
        type_list_extension_keys => normalized_semantic_symbol_contract_type_list_extension_keys(),
        type_record_extension_keys => normalized_semantic_symbol_contract_type_record_extension_keys(),
        package_import_keys => normalized_semantic_symbol_contract_package_import_keys(),
        presence_key_family_map => normalized_semantic_symbol_contract_presence_key_family_map(),
        optional_for_symbol_free_sources => JSON::PP::true,
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic.symbol_contract` object used by successful public normalized semantic JSON reports for symbol-rich sources.},
            'The bounded public promise covers the published count, name-list, nested map, scalar-leaf, aggregate-path, and package-import top-level keys exported for declared symbols.',
            'The constants map value key families describe the currently emitted scalar/list constant value variants only: every value has `kind`, scalar values add `payload`, and list values add `items`.',
            'The enum map value-kind families describe the currently emitted `enums` shape: each enum entry value is a member-payload map, and each dynamic member-name value is a scalar payload.',
            'The type-entry key families describe the currently emitted recursive `types` shape: every advertised entry carries `kind`, `signed`, and `width`; scalar bit/bits entries may add `state_model`; list entries add recursive `items`; record entries add recursive `members` plus `member_order`.',
            'Use the grouped presence_key_family_map to discover the bounded symbol-contract summary, name-list, nested-map, constant-detail, constant-value, enum-value, type-entry, and package-import key families without collecting those key-family lists separately.',
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

sub normalized_semantic_symbol_contract_summary_presence_keys {
    return [
        qw(
            constant_count
            enum_count
            type_count
        ),
    ];
}

sub normalized_semantic_symbol_contract_symbol_name_keys {
    return [
        qw(
            constant_names
            enum_names
            type_names
        ),
    ];
}

sub normalized_semantic_symbol_contract_symbol_map_keys {
    return [
        qw(
            constants
            enums
            types
        ),
    ];
}

sub normalized_semantic_symbol_contract_constant_detail_keys {
    return [
        qw(
            constant_scalar_leaves
            constant_aggregate_paths
        ),
    ];
}

sub normalized_semantic_symbol_contract_constant_value_entry_keys {
    return [
        qw(
            kind
        ),
    ];
}

sub normalized_semantic_symbol_contract_constant_scalar_value_extension_keys {
    return [
        qw(
            payload
        ),
    ];
}

sub normalized_semantic_symbol_contract_constant_list_value_extension_keys {
    return [
        qw(
            items
        ),
    ];
}

sub normalized_semantic_symbol_contract_enum_entry_value_kinds {
    return [
        qw(
            member_payload_map
        ),
    ];
}

sub normalized_semantic_symbol_contract_enum_member_value_kinds {
    return [
        qw(
            scalar_payload
        ),
    ];
}

sub normalized_semantic_symbol_contract_type_entry_keys {
    return [
        qw(
            kind
            signed
            width
        ),
    ];
}

sub normalized_semantic_symbol_contract_type_scalar_value_kinds {
    return [
        qw(
            bit
            bits
        ),
    ];
}

sub normalized_semantic_symbol_contract_type_aggregate_value_kinds {
    return [
        qw(
            list
            record
        ),
    ];
}

sub normalized_semantic_symbol_contract_type_state_model_extension_keys {
    return [
        qw(
            state_model
        ),
    ];
}

sub normalized_semantic_symbol_contract_type_list_extension_keys {
    return [
        qw(
            items
        ),
    ];
}

sub normalized_semantic_symbol_contract_type_record_extension_keys {
    return [
        qw(
            member_order
            members
        ),
    ];
}

sub normalized_semantic_symbol_contract_package_import_keys {
    return [
        qw(
            package_import_count
            package_imports
        ),
    ];
}

sub normalized_semantic_symbol_contract_presence_key_family_map {
    return {
        summary_presence_keys => normalized_semantic_symbol_contract_summary_presence_keys(),
        symbol_name_keys => normalized_semantic_symbol_contract_symbol_name_keys(),
        symbol_map_keys => normalized_semantic_symbol_contract_symbol_map_keys(),
        constant_detail_keys => normalized_semantic_symbol_contract_constant_detail_keys(),
        constant_value_entry_keys => normalized_semantic_symbol_contract_constant_value_entry_keys(),
        constant_scalar_value_extension_keys =>
            normalized_semantic_symbol_contract_constant_scalar_value_extension_keys(),
        constant_list_value_extension_keys =>
            normalized_semantic_symbol_contract_constant_list_value_extension_keys(),
        enum_entry_value_kinds => normalized_semantic_symbol_contract_enum_entry_value_kinds(),
        enum_member_value_kinds => normalized_semantic_symbol_contract_enum_member_value_kinds(),
        type_entry_keys => normalized_semantic_symbol_contract_type_entry_keys(),
        type_scalar_value_kinds => normalized_semantic_symbol_contract_type_scalar_value_kinds(),
        type_aggregate_value_kinds => normalized_semantic_symbol_contract_type_aggregate_value_kinds(),
        type_state_model_extension_keys => normalized_semantic_symbol_contract_type_state_model_extension_keys(),
        type_list_extension_keys => normalized_semantic_symbol_contract_type_list_extension_keys(),
        type_record_extension_keys => normalized_semantic_symbol_contract_type_record_extension_keys(),
        package_import_keys => normalized_semantic_symbol_contract_package_import_keys(),
    };
}

1;
