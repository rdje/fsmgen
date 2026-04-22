package FSM::Support::DiagnosticsContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use FSM::Support::CheckDiagnosticsContract qw(
    check_diagnostics_contract_source
    check_json_public_top_level_keys
);
use FSM::Support::DiagnosticCodeRegistryContract qw(
    diagnostic_code_registry_contract_source
    diagnostic_code_registry_entry_keys
    diagnostic_code_registry_family_values
    diagnostic_code_registry_public_keys
);

our @EXPORT_OK = qw(
    build_diagnostics_contract
    diagnostics_contract_source
    diagnostics_list_keys
    diagnostics_nested_contract_keys
    diagnostics_nested_presence_key_map
    diagnostics_presence_key_family_map
    diagnostics_public_top_level_keys
    diagnostics_scalar_string_keys
);

sub diagnostics_contract_source {
    return 'FSM::Support::DiagnosticsContract';
}

sub build_diagnostics_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => diagnostics_contract_source(),
        report_source => 'FSM::Support::CapabilityManifest',
        entrypoints => {
            cli => './bin/fsmgen --capability-manifest',
            cli_aliases => [
                './bin/fsmgen --emit-capability-manifest',
            ],
            in_process => [
                'FSM::Support::CapabilityManifest::build_capability_manifest()->{diagnostics}',
                'FSM::Support::DiagnosticsSection::build_diagnostics_section()',
            ],
        },
        public_top_level_presence_keys => diagnostics_public_top_level_keys(),
        scalar_string_keys => diagnostics_scalar_string_keys(),
        list_keys => diagnostics_list_keys(),
        nested_contract_keys => diagnostics_nested_contract_keys(),
        nested_contract_source_map => {
            stable_code_registry => diagnostic_code_registry_contract_source(),
            check_json => check_diagnostics_contract_source(),
        },
        nested_presence_key_map => diagnostics_nested_presence_key_map(),
        stable_code_entry_presence_keys => diagnostic_code_registry_entry_keys(),
        presence_key_family_map => diagnostics_presence_key_family_map(),
        stable_code_family_values => diagnostic_code_registry_family_values(),
        stable_code_registry_contract_advertised => JSON::PP::true,
        check_json_contract_advertised => JSON::PP::true,
        full_diagnostics_section_stable => JSON::PP::false,
        guidance => [
            'Treat the published diagnostics-section top-level keys plus the stable-code entry key family as the bounded public manifest-facing contract for schema version 1.',
            'Use the grouped nested_presence_key_map to discover the bounded key family for the stable-code registry and check-JSON child objects without collecting those child key lists one field at a time.',
            'Use the grouped presence_key_family_map to discover the bounded diagnostics-owned scalar-string, list, and stable-code entry key families without collecting those key-family lists separately.',
            'The diagnostics section keeps the stable registry discoverable while delegating narrower stable-code registry and check-JSON details to their dedicated contracts.',
            'Widen the section deliberately when new diagnostics metadata is backed by support-accounting truth and regression coverage.',
        ],
    };
}

sub diagnostics_public_top_level_keys {
    return [
        qw(
            registry_source
            stable_codes
            stable_code_registry
            check_json
            section_contract
        ),
    ];
}

sub diagnostics_scalar_string_keys {
    return [
        qw(
            registry_source
        ),
    ];
}

sub diagnostics_list_keys {
    return [
        qw(
            stable_codes
        ),
    ];
}

sub diagnostics_nested_contract_keys {
    return [
        qw(
            stable_code_registry
            check_json
        ),
    ];
}

sub diagnostics_nested_presence_key_map {
    return {
        stable_code_registry => diagnostic_code_registry_public_keys(),
        check_json => check_json_public_top_level_keys(),
    };
}

sub diagnostics_presence_key_family_map {
    return {
        scalar_string_keys => diagnostics_scalar_string_keys(),
        list_keys => diagnostics_list_keys(),
        stable_code_entry_presence_keys => diagnostic_code_registry_entry_keys(),
    };
}

1;
