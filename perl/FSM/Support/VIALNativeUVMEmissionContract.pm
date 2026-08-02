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
        static_validation_schema mapping_matrix_schema review_workflow_schema
        methodology_identity library_materialization
        backend_stage_status capabilities limits fixture review_gallery
        experimental_probe writes_files public_embedding_api
        explicit_nonclaims guidance
    )];
}

sub build_vial_native_uvm_emission_contract {
    return {
        schema_version => 1,
        status => 'shipped_private_selected_matrix_and_review_workflow',
        contract_source => vial_native_uvm_emission_contract_source(),
        implementation_entrypoints => [
            'FSM::VIAL::Backend::SVUVMAccellera2020_3_1->emit({...})',
            'FSM::VIAL::Backend::SVUVMStaticValidator->validate({...})',
            'FSM::VIAL::Backend::SVUVMReviewClosure->build({...})',
            'FSM::VIAL::ArtifactTransaction->publish({...})',
        ],
        execution_schema => 'fsmgen.vial_execution_ir.v1',
        profile => 'sv_uvm_emit.accellera_2020_3_1',
        backend_schema => 'fsmgen.vial_backend.sv_uvm_emit.accellera_2020_3_1.v1',
        source_map_schema => 'fsmgen.vial_uvm_backend_source_map.v1',
        static_validation_schema => 'fsmgen.vial_uvm_static_validation.v1',
        mapping_matrix_schema => 'fsmgen.vial_uvm_selected_mapping_matrix.v1',
        review_workflow_schema => 'fsmgen.vial_uvm_review_workflow.v1',
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
            negotiation => 'shipped_selected_matrix_review_scope',
            emission => 'shipped_deterministic_complete_selected_structures',
            static_validation => 'shipped_structural_only',
            mapping_matrix => 'shipped_complete_selected_scope',
            review_workflow => 'shipped_deterministic_check_available',
            manual_review => 'workflow_available_review_pending',
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
            vial.backend.sv_uvm_emit.typed_stimulus.v1
            vial.backend.sv_uvm_emit.scenario_sequences.v1
            vial.backend.sv_uvm_emit.analysis_tlm.v1
            vial.backend.sv_uvm_emit.scoped_factory_configuration.v1
            vial.backend.sv_uvm_emit.ral_preview.v1
            vial.backend.sv_uvm_emit.constrained_decision_replay.v1
            vial.backend.sv_uvm_emit.functional_coverage.v1
            vial.backend.sv_uvm_emit.bound_sva_properties.v1
            vial.backend.sv_uvm_emit.event_models.v1
            vial.backend.sv_uvm_emit.bounded_scoreboard.v1
            vial.backend.sv_uvm_emit.declared_fault_interception.v1
            vial.backend.sv_uvm_emit.structured_diagnostics.v1
            vial.backend.sv_uvm_emit.result_collection.v1
            vial.backend.sv_uvm_emit.source_map.v1
            vial.backend.sv_uvm_emit.static_validation.v1
            vial.backend.sv_uvm_emit.selected_mapping_matrix.v1
            vial.backend.sv_uvm_emit.review_workflow.v1
            vial.backend.sv_uvm_emit.typed_context.v1
            vial.backend.sv_uvm_emit.uvm_top_foundation.v1
        )],
        limits => {
            selected_units => 1,
            selected_domains => 1,
            generated_source_artifacts => 10,
            generated_source_bytes => 16_777_216,
            total_artifacts => 16,
            source_map_entries => 1_000_000,
            identifier_bytes => 255,
        },
        fixture => 'vial/ahb_subordinate_base_output_arbitration.vial',
        review_gallery => 'vial/review_gallery/sv_uvm_emit.accellera_2020_3_1/ahb_base_output_foundation',
        experimental_probe => {
            status => 'observed_partial_tool_limited',
            profile => 'sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0',
            implementation_entrypoint =>
                'FSM::VIAL::Backend::SVUVMExperimentalProbe->run({...})',
            command => 'perl scripts/run_vial_native_uvm_experimental_probe.pl [--check]',
            report_schema => 'fsmgen.vial_uvm_experimental_probe.v1',
            evidence => 'vial/experimental_probes/sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0/probe-report.json',
            product_support => JSON::PP::false,
            qualification_status => 'unqualified_experimental_evidence_only',
            source_variant => {
                provider => 'CHIPS Alliance uvm-verilator',
                ref => 'uvm-2020-3.1-vlt',
                commit => '656f20d087370a7c742e00188d20bbf30fa95339',
                tree => '882930bb7debe79b22234e4a8a53854549046778',
            },
            stage_status => {
                uvm_library_preprocess => 'passed',
                uvm_library_parse => 'passed',
                uvm_library_compile_elaboration => 'passed',
                uvm_library_runtime_smoke => 'passed',
                generated_fixture_preprocess => 'passed',
                generated_fixture_parse => 'unsupported_tool_limitation',
                generated_fixture_compile_elaboration => 'failed_tool_internal_fault',
                generated_fixture_runtime => 'not_run',
                normalized_result => 'not_exercised',
                parity => 'not_exercised',
            },
            deviations => [qw(uvm_no_dpi bbox_unsupported_for_fixture_attempt_only)],
        },
        writes_files => JSON::PP::true,
        public_embedding_api => JSON::PP::false,
        explicit_nonclaims => [qw(
            complete_uvm_emission systemverilog_parse uvm_library_compile
            fixture_compile elaboration simulation runtime result parity
            complete_four_state general_cross_backend_parity vhdl_methodology
            mixed_language scale
        )],
        guidance => [
            'Use the private emitter to inspect or publish the selected typed context, active component topology, timed interface, root-owned lifecycle, bounded notification/interception registry, typed transaction items and scenario sequences, driver/sequencer, analysis TLM, scoped factory/configuration, RAL preview, fixed decision replay, functional coverage, bound SVA, event models, bounded scoreboard, declared fault interception, structured diagnostics/result collection, DUT binding, and top; public vial run remains the separately qualified portable Verilator pipeline.',
            'Treat the checked review gallery and static validator as deterministic emission evidence only, never as SystemVerilog syntax, UVM compile, elaboration, simulation, result, or parity evidence.',
            'Ordinary emission neither downloads nor inspects UVM library bytes. Materialize and verify the exact Accellera source in project-local storage only before a later library-dependent gate.',
            'Canonical generated source is simulator-neutral and contains no provider-specific branch. Tool commands and workarounds belong to separately identified experimental or qualified adapters.',
            'Public VIAL v1 events, transactions, scenarios, and fixed plan decisions own the selected generated channels and stimulus. Native interceptor tables, role substitutions, RAL metadata, and native constraint solving remain private typed previews until later public authoring decisions.',
            'Portable decisions are replayed from immutable ExecutionIR and are never rerandomized by the backend. The isolated native solver form is emitted for review but not called by the generated fixture.',
            'The selected mapping matrix accounts exactly once for every emitted foundation across normal source, terse source, typed IR, generated roles, and independent maturity states. It closes the selected gallery scope, not full UVM breadth.',
            'The repository-relative gallery workflow regenerates or byte-checks all nine review sources plus its mapping and workflow evidence. Visual review remains a deliberate human or delegated judgment step; executable qualification remains separate.',
            'The selected coverage, property, model, scoreboard, fault, diagnostic, and result-collection structures are emitted without waiting for a simulator. They remain unqualified until separately identified compile, elaboration, runtime, result, and parity evidence exists.',
            'The exact Verilator 5.046 plus CHIPS Alliance uvm-verilator 2020.3.1-vlt probe is separate experimental evidence: its isolated UVM library control passes preprocess, parse, compile/elaboration, and zero-error runtime smoke, while the generated fixture reaches an unsupported ranged-SVA parse result and a tool internal fault under unsupported-feature blackboxing. It neither changes ordinary emission stage states nor advertises product runtime support.',
        ],
    };
}

1;
