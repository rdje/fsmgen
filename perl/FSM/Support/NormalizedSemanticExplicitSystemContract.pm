package FSM::Support::NormalizedSemanticExplicitSystemContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_normalized_semantic_explicit_system_contract
    normalized_semantic_explicit_system_contract_clock_keys
    normalized_semantic_explicit_system_contract_presence_key_family_map
    normalized_semantic_explicit_system_contract_reset_identity_keys
    normalized_semantic_explicit_system_contract_reset_metadata_keys
    normalized_semantic_explicit_system_contract_source
    normalized_semantic_explicit_system_contract_presence_keys
);

sub normalized_semantic_explicit_system_contract_source {
    return 'FSM::Support::NormalizedSemanticExplicitSystemContract';
}

sub build_normalized_semantic_explicit_system_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => normalized_semantic_explicit_system_contract_source(),
        object_name => 'explicit_system_contract',
        parent_object_name => 'semantic.explicit_system_contract',
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
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)->{semantic}{explicit_system_contract}',
            ],
        },
        public_presence_keys => normalized_semantic_explicit_system_contract_presence_keys(),
        clock_keys => normalized_semantic_explicit_system_contract_clock_keys(),
        reset_identity_keys => normalized_semantic_explicit_system_contract_reset_identity_keys(),
        reset_metadata_keys => normalized_semantic_explicit_system_contract_reset_metadata_keys(),
        presence_key_family_map => normalized_semantic_explicit_system_contract_presence_key_family_map(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `explicit_system_contract` object used inside successful public normalized semantic JSON reports when the authored explicit system contract is preserved.},
            'The bounded public promise covers the authored explicit clock/reset identity and reset metadata fields.',
            'Use the grouped presence_key_family_map to discover the bounded explicit-system clock and reset key families without collecting those key-family lists separately.',
        ],
    };
}

sub normalized_semantic_explicit_system_contract_presence_keys {
    return [
        qw(
            clock
            reset
            reset_active_level
            reset_keyword
            reset_kind
        ),
    ];
}

sub normalized_semantic_explicit_system_contract_clock_keys {
    return [
        qw(
            clock
        ),
    ];
}

sub normalized_semantic_explicit_system_contract_reset_identity_keys {
    return [
        qw(
            reset
        ),
    ];
}

sub normalized_semantic_explicit_system_contract_reset_metadata_keys {
    return [
        qw(
            reset_active_level
            reset_keyword
            reset_kind
        ),
    ];
}

sub normalized_semantic_explicit_system_contract_presence_key_family_map {
    return {
        clock_keys => normalized_semantic_explicit_system_contract_clock_keys(),
        reset_identity_keys => normalized_semantic_explicit_system_contract_reset_identity_keys(),
        reset_metadata_keys => normalized_semantic_explicit_system_contract_reset_metadata_keys(),
    };
}

1;
