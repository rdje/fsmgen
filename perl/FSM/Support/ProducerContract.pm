package FSM::Support::ProducerContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_producer_contract
    producer_boolean_keys
    producer_contract_source
    producer_public_top_level_keys
    producer_scalar_string_keys
);

sub producer_contract_source {
    return 'FSM::Support::ProducerContract';
}

sub build_producer_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => producer_contract_source(),
        report_source => 'FSM::Support::CapabilityManifest',
        entrypoints => {
            cli => './bin/fsmgen --capability-manifest',
            cli_aliases => [
                './bin/fsmgen --emit-capability-manifest',
            ],
            in_process => [
                'FSM::Support::CapabilityManifest::build_capability_manifest()->{producer}',
            ],
        },
        public_top_level_presence_keys => producer_public_top_level_keys(),
        scalar_string_keys => producer_scalar_string_keys(),
        boolean_keys => producer_boolean_keys(),
        identity_contract => {
            name_is_tool_identity => JSON::PP::true,
            git_commit_is_best_effort_short_hash_or_unknown => JSON::PP::true,
            source_is_manifest_builder_module => JSON::PP::true,
        },
        guidance => [
            'Treat the published producer-section top-level keys and scalar/boolean field families as the bounded public manifest-facing contract for schema version 1.',
            'The producer section identifies the current FSMGen build/tool source for downstream consumers, but it is not a package-manager release contract.',
            'Widen the section deliberately when new producer/build metadata is documented and regression-backed.',
        ],
    };
}

sub producer_public_top_level_keys {
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

sub producer_scalar_string_keys {
    return [
        qw(
            name
            version
            git_commit
            source
        ),
    ];
}

sub producer_boolean_keys {
    return [
        qw(
            contract_authority
        ),
    ];
}

1;
