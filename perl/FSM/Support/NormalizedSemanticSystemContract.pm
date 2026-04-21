package FSM::Support::NormalizedSemanticSystemContract;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
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
