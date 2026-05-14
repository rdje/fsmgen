package FSM::Support::LanguageSurfaceContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_language_surface_contract
    language_surface_contract_source
    language_surface_assignments_keys
    language_surface_composition_keys
    language_surface_declarations_keys
    language_surface_default_mode_compatibility_keys
    language_surface_expressions_keys
    language_surface_nested_presence_key_map
    language_surface_public_top_level_keys
    language_surface_strict_mode_keys
    language_surface_system_contracts_keys
);

sub language_surface_contract_source {
    return 'FSM::Support::LanguageSurfaceContract';
}

sub build_language_surface_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => language_surface_contract_source(),
        report_source => 'FSM::Support::CapabilityManifest',
        entrypoints => {
            cli => './bin/fsmgen --capability-manifest',
            cli_aliases => [
                './bin/fsmgen --emit-capability-manifest',
            ],
            in_process => [
                'FSM::Support::CapabilityManifest::build_capability_manifest()->{language_surface}',
            ],
        },
        public_top_level_presence_keys => language_surface_public_top_level_keys(),
        strict_mode_presence_keys => language_surface_strict_mode_keys(),
        default_mode_compatibility_presence_keys => language_surface_default_mode_compatibility_keys(),
        assignments_presence_keys => language_surface_assignments_keys(),
        system_contracts_presence_keys => language_surface_system_contracts_keys(),
        expressions_presence_keys => language_surface_expressions_keys(),
        declarations_presence_keys => language_surface_declarations_keys(),
        composition_presence_keys => language_surface_composition_keys(),
        nested_presence_key_map => language_surface_nested_presence_key_map(),
        full_language_surface_stable => JSON::PP::false,
        guidance => [
            'Treat the published language-surface top-level and first nested section key lists as the bounded public manifest-facing contract for schema version 1.',
            'Use the grouped nested_presence_key_map to discover the bounded key families for strict_mode, default_mode_compatibility, assignments, system_contracts, expressions, declarations, and composition without collecting those first nested key lists separately.',
            'This contract makes the current strict/default language families discoverable without pretending every future syntax, diagnostic, or migration detail is now frozen.',
            'Widen the section deliberately when new authored-surface metadata is ready to be regression-backed and documented as public.',
        ],
    };
}

sub language_surface_public_top_level_keys {
    return [
        qw(
            strict_mode
            default_mode_compatibility
            assignments
            system_contracts
            expressions
            declarations
            composition
            intentionally_blocked_or_not_yet_public
            surface_contract
        ),
    ];
}

sub language_surface_strict_mode_keys {
    return [
        qw(
            intended_for_generated_fsm
            compatibility_syntax_is_canonical
            canonical_direct_roots
            canonical_composition_roots
            canonical_child_roots
        ),
    ];
}

sub language_surface_default_mode_compatibility_keys {
    return [
        qw(
            accepted_but_not_canonical_for_generated_output
        ),
    ];
}

sub language_surface_assignments_keys {
    return [
        qw(
            canonical_pair_forms
            canonical_lhs_pack_forms
            canonical_rhs_pack_forms
            compatibility_forms
        ),
    ];
}

sub language_surface_system_contracts_keys {
    return [
        qw(
            canonical_clock
            canonical_synchronous_reset
            canonical_asynchronous_reset
            legacy_or_misleading_reset_forms_rejected_in_strict
        ),
    ];
}

sub language_surface_expressions_keys {
    return [
        qw(
            guard_forms
            scalar_constant_expression_operators
            runtime_expression_operators
            test_node_selectors
            literal_families
        ),
    ];
}

sub language_surface_declarations_keys {
    return [
        qw(
            scalar_and_aggregate_names
            width_declarations
            package_roots
        ),
    ];
}

sub language_surface_composition_keys {
    return [
        qw(
            top_root
            generated_children
            external_rtl_children
            wiring
            lanes
        ),
    ];
}

sub language_surface_nested_presence_key_map {
    return {
        strict_mode => language_surface_strict_mode_keys(),
        default_mode_compatibility => language_surface_default_mode_compatibility_keys(),
        assignments => language_surface_assignments_keys(),
        system_contracts => language_surface_system_contracts_keys(),
        expressions => language_surface_expressions_keys(),
        declarations => language_surface_declarations_keys(),
        composition => language_surface_composition_keys(),
    };
}

1;
