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
        static_validation_schema mapping_matrix_schema review_workflow_schema
        migration_proof_schema standard_identity tool_selection
        methodology_identity library_materialization backend_stage_status
        capabilities limits fixture review_gallery writes_files
        public_embedding_api explicit_nonclaims guidance
    )];
}

sub build_vial_vhdl_emission_contract {
    return {
        schema_version => 1,
        status => 'shipped_private_exact_ghdl_6_0_0_qualified_portable_profile',
        contract_source => vial_vhdl_emission_contract_source(),
        implementation_entrypoints => [
            'FSM::VIAL::Backend::VHDLPortableGHDL->emit({...})',
            'FSM::VIAL::Backend::VHDLPortableStaticValidator->validate({...})',
            'FSM::VIAL::Backend::VHDLPortableReviewClosure->build({...})',
            'FSM::VIAL::Backend::VHDLPortableGHDLQualification->qualify({...})',
            'FSM::VIAL::ArtifactTransaction->publish({...})',
            'perl scripts/run_vial_vhdl_portable_ghdl_qualification.pl --check',
        ],
        execution_schema => 'fsmgen.vial_execution_ir.v1',
        profile => 'vhdl_portable_ghdl',
        backend_schema => 'fsmgen.vial_backend.vhdl_portable.v1',
        source_map_schema => 'fsmgen.vial_vhdl_backend_source_map.v1',
        static_validation_schema => 'fsmgen.vial_vhdl_static_validation.v1',
        mapping_matrix_schema => 'fsmgen.vial_vhdl_selected_mapping_matrix.v1',
        review_workflow_schema => 'fsmgen.vial_vhdl_review_workflow.v1',
        migration_proof_schema => 'fsmgen.vial_vhdl_migration_proof.v1',
        standard_identity => {
            language => 'VHDL',
            standard => 'IEEE 1076-2008',
            standard_option => '--std=08',
            status => 'executed_qualified_selected_fixture',
        },
        tool_selection => {
            tool => 'GHDL',
            exact_version => '6.0.0',
            backend => 'llvm_jit',
            build_commit => 'e589c698c351369ac5bcfe7abe1f1152ac5d4727',
            local_state => 'repository_local_exact_materialization',
            archive => '.artifacts/cache/providers/ghdl/6.0.0/llvm-jit-archive/ghdl-llvm-jit-6.0.0-macos15-aarch64.tar.gz',
            archive_sha256 => 'c21312d5a0cc5833e6d8690d8c4343e67f4fc32f070c07343816cd11a31c7769',
            binary => '.artifacts/cache/providers/ghdl/6.0.0/llvm-jit-tool/ghdl-llvm-jit-6.0.0-macos15-aarch64/bin/ghdl',
            binary_sha256 => '38a99c1cc18b04dfae128b118c7344910e08b8ba6eeb9c1e67f950a84bca3c3d',
            qualification_report => 'vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json',
            execution_evidence => JSON::PP::true,
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
            current_state => 'no_methodology_provider_requested_or_inspected',
            verified_project_local_copy_required_before_provider_use => JSON::PP::true,
        },
        backend_stage_status => {
            hial_vhdl_generation => 'shipped_deterministic_private_handoff',
            negotiation => 'shipped_portable_semantics_scope',
            emission => 'shipped_complete_selected_portable_emission',
            static_validation => 'shipped_twenty_structural_checks',
            source_map => 'shipped_portable_checking_scope',
            selected_mapping_matrix => 'shipped_twenty_four_rows',
            review_workflow => 'shipped_seven_stages_visual_pending',
            migration_separation => 'shipped_exact_regression_contract',
            review_gallery => 'shipped_byte_locked_review_closure',
            drivers => 'shipped_emission_only',
            samplers => 'shipped_emission_only',
            scheduler => 'shipped_emission_only',
            scenarios => 'shipped_emission_only',
            models => 'shipped_emission_only',
            probe_adapters => 'shipped_emission_only',
            scoreboards => 'shipped_bounded_emission_only',
            coverage => 'shipped_counter_emission_only',
            faults => 'shipped_substitution_emission_only',
            properties => 'shipped_procedural_emission_only',
            diagnostics => 'shipped_bounded_emission_only',
            trace => 'passed_closed_forty_two_record_runtime_trace',
            analysis => 'passed_exact_ghdl_6_0_0_llvm_jit',
            elaboration => 'passed_exact_ghdl_6_0_0_llvm_jit',
            runtime => 'passed_bounded_selected_fixture',
            four_state => 'passed_bounded_timed_0_1_x_z_probe',
            result => 'produced_normalized_pass',
            parity => 'passed_nineteen_applicable_portable_sv_paths',
            psl => 'not_emitted',
            product_support => 'qualified_private_fixture_profile_not_public_api',
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
            vial.backend.vhdl_portable_ghdl.bounded_scoreboard.v1
            vial.backend.vhdl_portable_ghdl.coverage_counters.v1
            vial.backend.vhdl_portable_ghdl.substitution_faults.v1
            vial.backend.vhdl_portable_ghdl.procedural_checks.v1
            vial.backend.vhdl_portable_ghdl.diagnostic_records.v1
            vial.backend.vhdl_portable_ghdl.closed_trace_projection.v1
            vial.backend.vhdl_portable_ghdl.result_manifest_projection.v1
            vial.backend.vhdl_portable_ghdl.declared_probe_adapter.v1
            vial.backend.vhdl_portable_ghdl.exact_rank_maps.v1
            vial.backend.vhdl_portable_ghdl.source_order.v1
            vial.backend.vhdl_portable_ghdl.command_evidence.v1
            vial.backend.vhdl_portable_ghdl.source_map.v1
            vial.backend.vhdl_portable_ghdl.static_validation.v1
            vial.backend.vhdl_portable_ghdl.selected_mapping_matrix.v1
            vial.backend.vhdl_portable_ghdl.review_workflow.v1
            vial.backend.vhdl_portable_ghdl.migration_separation.v1
            vial.backend.vhdl_portable_ghdl.deterministic_artifacts.v1
            vial.backend.vhdl_portable_ghdl.ghdl_6_0_0_qualification.v1
            vial.backend.vhdl_portable_ghdl.four_state_timed_probe.v1
            vial.backend.vhdl_portable_ghdl.normalized_result.v1
            vial.backend.vhdl_portable_ghdl.bounded_ahb_portable_sv_parity.v1
            vial.backend.vhdl_portable_ghdl.deterministic_runtime.v1
            vial.backend.vhdl_portable_ghdl.exact_cleanup.v1
        )],
        limits => {
            selected_units => 1,
            selected_domains => 1,
            generated_vhdl_sources => 6,
            generated_source_bytes => 16_777_216,
            total_artifacts => 17,
            source_map_entries => 59,
            static_validation_checks => 20,
            selected_mappings => 24,
            emitted_mappings => 20,
            unsupported_mappings => 4,
            review_workflow_stages => 7,
            review_closure_checks => 7,
            scoreboard_capacity => 4,
            diagnostic_capacity => 64,
            static_validation_artifacts => 32,
            identifier_bytes => 255,
            qualification_trace_records => 42,
            qualification_parity_paths => 19,
            qualification_process_rss_mib => 4_096,
        },
        fixture => 'vial/ahb_subordinate_base_output_arbitration.vial',
        review_gallery =>
            'vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics',
        writes_files => JSON::PP::true,
        public_embedding_api => JSON::PP::false,
        explicit_nonclaims => [qw(
            complete_vhdl_backend general_cross_backend_parity psl
            complete_vhdl_2008 osvvm uvvm another_simulator mixed_language scale
        )],
        guidance => [
            'Use the private emitter to inspect deterministic provider-free VHDL-2008 typed drivers, samplers, scheduling, scenarios, models, bounded scoreboards, coverage, substitution faults, procedural checks, diagnostics, trace closure, normalized result projection, probe adapters, exact ranks, HIAL DUT bytes, and source maps.',
            'Treat the twenty-four-row selected matrix, twenty structural checks, seven-stage workflow, and checked gallery as emission/review evidence; visual review remains pending. The separate checked qualification report proves only the bounded selected fixture under exact GHDL 6.0.0 LLVM-JIT.',
            'Ordinary portable emission downloads and inspects no simulator or methodology-provider bytes. The exact GHDL qualification runner consumes a verified repository-local tool; OSVVM materialization remains separately owned.',
            'The exact migration proof locks the inert legacy fixture bytes/schema and byte-identical HIAL DUT handoff; the generated native VIAL graph remains separate and does not consume, rewrite, or widen either surface.',
            'Canonical VHDL source remains provider-neutral. The qualification report freezes and executes exact GHDL identity, ordered analysis/elaboration/run commands, deterministic reruns, four-state timing, trace/result validation, applicable portable-SV parity, resource controls, and cleanup.',
            'Do not generalize the LLVM-JIT result to GHDL LLVM AOT: the exact 6.0.0 AOT package analyzed and elaborated the fixture but failed its external-name adapter at runtime.',
        ],
    };
}

1;
