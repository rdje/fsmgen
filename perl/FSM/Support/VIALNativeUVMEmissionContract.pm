package FSM::Support::VIALNativeUVMEmissionContract;

use strict;
use warnings;
use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_vial_native_uvm_emission_contract
    vial_native_uvm_emission_contract_keys
    vial_native_uvm_emission_contract_source
);

sub vial_native_uvm_emission_contract_source {
    return 'FSM::Support::VIALNativeUVMEmissionContract';
}

sub vial_native_uvm_emission_contract_keys {
    return [qw(
        schema_version status contract_source implementation_entrypoints
        execution_schema profile backend_schema source_map_schema
        static_validation_schema methodology_identity library_materialization
        backend_stage_status capabilities limits fixture review_gallery
        writes_files public_embedding_api explicit_nonclaims guidance
    )];
}

sub build_vial_native_uvm_emission_contract {
    return {
        schema_version => 1,
        status => 'shipped_private_topology_lifecycle_notification_emission_and_review_gallery',
        contract_source => vial_native_uvm_emission_contract_source(),
        implementation_entrypoints => [
            'FSM::VIAL::Backend::SVUVMAccellera2020_3_1->emit({...})',
            'FSM::VIAL::Backend::SVUVMStaticValidator->validate({...})',
            'FSM::VIAL::ArtifactTransaction->publish({...})',
        ],
        execution_schema => 'fsmgen.vial_execution_ir.v1',
        profile => 'sv_uvm_emit.accellera_2020_3_1',
        backend_schema => 'fsmgen.vial_backend.sv_uvm_emit.accellera_2020_3_1.v1',
        source_map_schema => 'fsmgen.vial_uvm_backend_source_map.v1',
        static_validation_schema => 'fsmgen.vial_uvm_static_validation.v1',
        methodology_identity => {
            language => 'IEEE SystemVerilog',
            standard => 'IEEE 1800.2-2020',
            api_target => 'IEEE 1800.2-2020 / Accellera UVM 2020-3.1',
            reference_implementation => 'Accellera UVM',
            release => '2020-3.1',
            git_tag => '2020.3.1',
            git_commit => '78c06547a2a0a29b3dc9dcafae62b75b2ff61544',
            license => 'Apache-2.0',
        },
        library_materialization => {
            required_for_emission => JSON::PP::false,
            network_fetch_during_emission => JSON::PP::false,
            current_state => 'not_requested_or_inspected',
            required_before => [qw(
                library_dependent_preprocessing library_compile fixture_compile
                elaboration runtime
            )],
            verified_project_local_copy_required => JSON::PP::true,
        },
        backend_stage_status => {
            negotiation => 'shipped_topology_lifecycle_notification_scope',
            emission => 'shipped_deterministic_complete_selected_structures',
            static_validation => 'shipped_structural_only',
            manual_review => 'gallery_available_review_pending',
            preprocessing => 'not_run',
            parse => 'not_run',
            library_compile => 'not_run',
            fixture_compile => 'not_run',
            elaboration => 'not_run',
            runtime => 'not_run',
            result => 'not_produced',
            parity => 'not_evaluated',
        },
        capabilities => [qw(
            vial.backend.sv_uvm_emit.accellera_2020_3_1.v1
            vial.backend.sv_uvm_emit.bounded_reentrancy.v1
            vial.backend.sv_uvm_emit.component_foundations.v1
            vial.backend.sv_uvm_emit.component_topology.v1
            vial.backend.sv_uvm_emit.deterministic_artifacts.v1
            vial.backend.sv_uvm_emit.interface_foundation.v1
            vial.backend.sv_uvm_emit.lifecycle.v1
            vial.backend.sv_uvm_emit.methodology_identity.v1
            vial.backend.sv_uvm_emit.notification_interception.v1
            vial.backend.sv_uvm_emit.source_map.v1
            vial.backend.sv_uvm_emit.static_validation.v1
            vial.backend.sv_uvm_emit.typed_context.v1
            vial.backend.sv_uvm_emit.uvm_top_foundation.v1
        )],
        limits => {
            selected_units => 1,
            selected_domains => 1,
            generated_source_artifacts => 7,
            generated_source_bytes => 16_777_216,
            total_artifacts => 11,
            source_map_entries => 1_000_000,
            identifier_bytes => 255,
        },
        fixture => 'vial/ahb_subordinate_base_output_arbitration.vial',
        review_gallery => 'vial/review_gallery/sv_uvm_emit.accellera_2020_3_1/ahb_base_output_foundation',
        writes_files => JSON::PP::true,
        public_embedding_api => JSON::PP::false,
        explicit_nonclaims => [qw(
            complete_uvm_emission systemverilog_parse uvm_library_compile
            fixture_compile elaboration simulation runtime result parity
            complete_four_state general_cross_backend_parity vhdl_methodology
            mixed_language scale
        )],
        guidance => [
            'Use the private emitter to inspect or publish the selected typed context, component topology, timed interface, root-owned lifecycle, bounded notification/interception registry, result-collector structure, DUT binding, and top; public vial run remains the separately qualified portable Verilator pipeline.',
            'Treat the checked review gallery and static validator as deterministic emission evidence only, never as SystemVerilog syntax, UVM compile, elaboration, simulation, result, or parity evidence.',
            'Ordinary emission neither downloads nor inspects UVM library bytes. Materialize and verify the exact Accellera source in project-local storage only before a later library-dependent gate.',
            'Canonical generated source is simulator-neutral and contains no provider-specific branch. Tool commands and workarounds belong to separately identified experimental or qualified adapters.',
            'Public VIAL v1 events drive the selected generated channels. Native interceptor tables remain a private typed preview until a later slice selects their public authoring syntax.',
            'Later emission leaves add stimulus, TLM, factory/configuration, RAL, constrained decisions, coverage, properties, models, scoreboards, faults, and results without waiting for a simulator; these selected structures are not complete VIAL or UVM breadth.',
        ],
    };
}

1;
