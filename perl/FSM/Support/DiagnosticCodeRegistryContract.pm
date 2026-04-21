package FSM::Support::DiagnosticCodeRegistryContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_diagnostic_code_registry_contract
    diagnostic_code_registry_contract_source
    diagnostic_code_registry_entry_keys
    diagnostic_code_registry_family_values
    diagnostic_code_registry_public_keys
);

sub diagnostic_code_registry_contract_source {
    return 'FSM::Support::DiagnosticCodeRegistryContract';
}

sub build_diagnostic_code_registry_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => diagnostic_code_registry_contract_source(),
        report_source => 'FSM::Support::DiagnosticCodes',
        entrypoints => {
            cli => './bin/fsmgen --capability-manifest',
            cli_aliases => [
                './bin/fsmgen --emit-capability-manifest',
            ],
            in_process => [
                'FSM::Support::CapabilityManifest::build_capability_manifest()->{diagnostics}',
                'FSM::Support::DiagnosticCodes::diagnostic_code_registry()',
            ],
        },
        public_sibling_keys => diagnostic_code_registry_public_keys(),
        entry_presence_keys => diagnostic_code_registry_entry_keys(),
        code_shape => 'FSMGEN_[A-Z0-9_]+',
        bounded_severity_values => [qw(error)],
        bounded_stability_values => [qw(stable)],
        bounded_family_values => diagnostic_code_registry_family_values(),
        registry_returns_defensive_copies => JSON::PP::true,
        guidance => [
            'Treat the listed diagnostics sibling keys and stable-code entry keys as the bounded public diagnostic-code registry contract for schema version 1.',
            'This contract covers the manifest-facing registry view, not every internal helper or future diagnostic family.',
            'Widen the registry deliberately when new families or entry fields are promoted into the maintained expected-failure corpus and regression-backed.',
        ],
    };
}

sub diagnostic_code_registry_public_keys {
    return [
        qw(
            registry_source
            stable_codes
            stable_code_registry
        ),
    ];
}

sub diagnostic_code_registry_entry_keys {
    return [
        qw(
            code
            severity
            stability
            family
            summary
        ),
    ];
}

sub diagnostic_code_registry_family_values {
    return [
        qw(
            strict_mode
            language_contract
            direct_generation_contract
            composition_contract
        ),
    ];
}

1;
