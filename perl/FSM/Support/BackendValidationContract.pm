package FSM::Support::BackendValidationContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::HDLExternalValidationContract qw(
    hdl_external_validation_contract_source
);

our @EXPORT_OK = qw(
    backend_validation_contract_source
    backend_validation_nested_contract_keys
    backend_validation_public_top_level_keys
    build_backend_validation_contract
);

sub backend_validation_contract_source {
    return 'FSM::Support::BackendValidationContract';
}

sub build_backend_validation_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => backend_validation_contract_source(),
        report_source => 'FSM::Support::CapabilityManifest',
        entrypoints => {
            cli => './bin/fsmgen --capability-manifest',
            cli_aliases => [
                './bin/fsmgen --emit-capability-manifest',
            ],
            in_process => [
                'FSM::Support::CapabilityManifest::build_capability_manifest()->{backend_validation}',
            ],
        },
        public_top_level_presence_keys => backend_validation_public_top_level_keys(),
        nested_contract_keys => backend_validation_nested_contract_keys(),
        nested_contract_source_map => {
            systemverilog_external => hdl_external_validation_contract_source(),
        },
        systemverilog_external_contract_advertised => JSON::PP::true,
        full_backend_validation_section_stable => JSON::PP::false,
        guidance => [
            'Treat the published backend-validation top-level keys and nested contract ownership map as the bounded public manifest-facing contract for schema version 1.',
            'The backend_validation section points consumers at bounded validation/report surfaces instead of turning every future backend validation lane into an already-frozen API.',
            'Widen the section deliberately when new backend validation formats or target-language lanes are documented, support-accounted, and regression-backed.',
        ],
    };
}

sub backend_validation_public_top_level_keys {
    return [
        qw(
            systemverilog_external
            section_contract
        ),
    ];
}

sub backend_validation_nested_contract_keys {
    return [
        qw(
            systemverilog_external
        ),
    ];
}

1;
