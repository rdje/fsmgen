package FSM::Support::NormalizedSemanticSystemContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_normalized_semantic_system_contract
    normalized_semantic_system_contract_behavior_keys
    normalized_semantic_system_contract_clock_keys
    normalized_semantic_system_contract_presence_key_family_map
    normalized_semantic_system_contract_source
    normalized_semantic_system_contract_presence_keys
    normalized_semantic_system_contract_reset_identity_keys
    normalized_semantic_system_contract_reset_metadata_keys
);

sub normalized_semantic_system_contract_source {
    return 'FSM::Support::NormalizedSemanticSystemContract';
}

sub build_normalized_semantic_system_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => normalized_semantic_system_contract_source(),
        object_name => 'system_contract',
        parent_object_name => 'semantic.system_contract',
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
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)->{semantic}{system_contract}',
            ],
        },
        public_presence_keys => normalized_semantic_system_contract_presence_keys(),
        clock_keys => normalized_semantic_system_contract_clock_keys(),
        reset_identity_keys => normalized_semantic_system_contract_reset_identity_keys(),
        reset_metadata_keys => normalized_semantic_system_contract_reset_metadata_keys(),
        behavior_keys => normalized_semantic_system_contract_behavior_keys(),
        presence_key_family_map => normalized_semantic_system_contract_presence_key_family_map(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `system_contract` object used inside successful public normalized semantic JSON reports.},
            'The bounded public promise covers the effective clock/reset identity, reset metadata, and declare_ports/implicit behavior fields.',
            'Use the grouped presence_key_family_map to discover the bounded system-contract clock, reset, and behavior key families without collecting those key-family lists separately.',
        ],
    };
}

sub normalized_semantic_system_contract_presence_keys {
    return [
        qw(
            clock
            declare_ports
            implicit
            reset
            reset_active_level
            reset_keyword
            reset_kind
        ),
    ];
}

sub normalized_semantic_system_contract_clock_keys {
    return [
        qw(
            clock
        ),
    ];
}

sub normalized_semantic_system_contract_reset_identity_keys {
    return [
        qw(
            reset
        ),
    ];
}

sub normalized_semantic_system_contract_reset_metadata_keys {
    return [
        qw(
            reset_active_level
            reset_keyword
            reset_kind
        ),
    ];
}

sub normalized_semantic_system_contract_behavior_keys {
    return [
        qw(
            declare_ports
            implicit
        ),
    ];
}

sub normalized_semantic_system_contract_presence_key_family_map {
    return {
        clock_keys => normalized_semantic_system_contract_clock_keys(),
        reset_identity_keys => normalized_semantic_system_contract_reset_identity_keys(),
        reset_metadata_keys => normalized_semantic_system_contract_reset_metadata_keys(),
        behavior_keys => normalized_semantic_system_contract_behavior_keys(),
    };
}

1;
