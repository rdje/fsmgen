package FSM::Support::VIALVHDLEmissionContract;

use strict;
use warnings;
use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_vial_vhdl_emission_contract
    vial_vhdl_emission_contract_keys
    vial_vhdl_emission_contract_source
);

sub vial_vhdl_emission_contract_source {
    return 'FSM::Support::VIALVHDLEmissionContract';
}

sub vial_vhdl_emission_contract_keys {
    return [qw(
        schema_version status contract_source implementation_entrypoints
        execution_schema profile backend_schema source_map_schema
        static_validation_schema standard_identity tool_selection
        methodology_identity library_materialization backend_stage_status
        capabilities limits fixture review_gallery writes_files
        public_embedding_api explicit_nonclaims guidance
    )];
}

sub build_vial_vhdl_emission_contract {
    return {
        schema_version => 1,
        status => 'shipped_private_unqualified_portable_semantics',
        contract_source => vial_vhdl_emission_contract_source(),
        implementation_entrypoints => [
            'FSM::VIAL::Backend::VHDLPortableGHDL->emit({...})',
            'FSM::VIAL::Backend::VHDLPortableStaticValidator->validate({...})',
            'FSM::VIAL::ArtifactTransaction->publish({...})',
        ],
        execution_schema => 'fsmgen.vial_execution_ir.v1',
        profile => 'vhdl_portable_ghdl',
        backend_schema => 'fsmgen.vial_backend.vhdl_portable.v1',
        source_map_schema => 'fsmgen.vial_vhdl_backend_source_map.v1',
        static_validation_schema => 'fsmgen.vial_vhdl_static_validation.v1',
        standard_identity => {
            language => 'VHDL',
            standard => 'IEEE 1076-2008',
            standard_option => '--std=08',
            status => 'selected_unexecuted',
        },
        tool_selection => {
            tool => 'GHDL',
            exact_version => '6.0.0',
            local_state => 'not_available',
            execution_evidence => JSON::PP::false,
        },
        methodology_identity => {
            portable_core => 'provider_free_vhdl_2008',
            provider_required_for_emission => JSON::PP::false,
            advanced_provider => 'OSVVM 2026.05',
            advanced_provider_status => 'selected_not_materialized_separate_profile',
        },
        library_materialization => {
            required_for_foundation_emission => JSON::PP::false,
            required_for_portable_emission => JSON::PP::false,
            network_fetch_during_emission => JSON::PP::false,
            current_state => 'no_provider_requested_or_inspected',
            verified_project_local_copy_required_before_provider_use => JSON::PP::true,
        },
        backend_stage_status => {
            hial_vhdl_generation => 'shipped_deterministic_private_handoff',
            negotiation => 'shipped_portable_semantics_scope',
            emission => 'shipped_portable_semantics_emission_only',
            static_validation => 'shipped_thirteen_structural_checks',
            source_map => 'shipped_portable_semantics_scope',
            review_gallery => 'shipped_byte_locked_portable_semantics',
            drivers => 'shipped_emission_only',
            samplers => 'shipped_emission_only',
            scheduler => 'shipped_emission_only',
            scenarios => 'shipped_emission_only',
            models => 'shipped_emission_only',
            probe_adapters => 'shipped_emission_only',
            analysis => 'not_run',
            elaboration => 'not_run',
            runtime => 'not_run',
            result => 'not_produced',
            parity => 'not_evaluated',
            psl => 'not_emitted',
            product_support => 'not_claimed',
        },
        capabilities => [qw(
            vial.backend.vhdl_portable_ghdl.foundation.v1
            vial.backend.vhdl_portable_ghdl.deterministic_hial_input.v1
            vial.backend.vhdl_portable_ghdl.typed_values.v1
            vial.backend.vhdl_portable_ghdl.typed_logical_time.v1
            vial.backend.vhdl_portable_ghdl.fixture_metadata.v1
            vial.backend.vhdl_portable_ghdl.dut_binding_foundation.v1
            vial.backend.vhdl_portable_ghdl.typed_drivers.v1
            vial.backend.vhdl_portable_ghdl.original_symbol_samplers.v1
            vial.backend.vhdl_portable_ghdl.inactive_edge_scheduler.v1
            vial.backend.vhdl_portable_ghdl.scenario_fibers.v1
            vial.backend.vhdl_portable_ghdl.deterministic_models.v1
            vial.backend.vhdl_portable_ghdl.declared_probe_adapter.v1
            vial.backend.vhdl_portable_ghdl.exact_rank_maps.v1
            vial.backend.vhdl_portable_ghdl.source_order.v1
            vial.backend.vhdl_portable_ghdl.command_evidence.v1
            vial.backend.vhdl_portable_ghdl.source_map.v1
            vial.backend.vhdl_portable_ghdl.static_validation.v1
            vial.backend.vhdl_portable_ghdl.deterministic_artifacts.v1
        )],
        limits => {
            selected_units => 1,
            selected_domains => 1,
            generated_vhdl_sources => 6,
            generated_source_bytes => 16_777_216,
            total_artifacts => 14,
            source_map_entries => 52,
            static_validation_checks => 13,
            static_validation_artifacts => 32,
            identifier_bytes => 255,
        },
        fixture => 'vial/ahb_subordinate_base_output_arbitration.vial',
        review_gallery =>
            'vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics',
        writes_files => JSON::PP::true,
        public_embedding_api => JSON::PP::false,
        explicit_nonclaims => [qw(
            complete_vhdl_backend scoreboards coverage faults properties checks trace
            vhdl_analysis elaboration simulation runtime result parity psl
            complete_vhdl_2008 osvvm uvvm mixed_language product_support scale
        )],
        guidance => [
            'Use the private emitter to inspect deterministic provider-free VHDL-2008 typed drivers, original-symbol samplers, inactive-edge scheduling, scenario/fiber state, models, probe adapters, exact ranks, HIAL DUT bytes, and source maps.',
            'Treat thirteen-check structural validation and the checked gallery as emission evidence only; neither proves VHDL analysis, elaboration, runtime behavior, checking, normalized results, parity, PSL, or product support.',
            'Ordinary portable emission downloads and inspects no simulator or methodology-provider bytes. Exact GHDL and OSVVM materialization belong to later separately qualified slices.',
            'The generated native VIAL graph is separate from and does not consume, rewrite, or widen the inert vhdl-observation-package compatibility surface.',
            'Canonical VHDL source is provider-neutral. GHDL identity and ordered command shapes live only in JSON evidence until the exact tool is executed.',
        ],
    };
}

1;
