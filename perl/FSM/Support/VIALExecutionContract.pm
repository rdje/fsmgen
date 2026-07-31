package FSM::Support::VIALExecutionContract;

use strict;
use warnings;
use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_vial_execution_contract
    vial_execution_contract_keys
    vial_execution_contract_source
);

sub vial_execution_contract_source {
    return 'FSM::Support::VIALExecutionContract';
}

sub vial_execution_contract_keys {
    return [qw(
        schema_version status contract_source implementation_entrypoints
        execution_schema plan_schema replay_schema selected_future_schemas
        profile backend_profile backend_schema runtime_trace_schema
        trace_projection_schema backend_stage_status capabilities limits
        backend_limits
        fixture writes_files public_embedding_api explicit_nonclaims
        guidance
    )];
}

sub build_vial_execution_contract {
    return {
        schema_version => 1,
        status => 'shipped_public_verilator_execution_and_result',
        contract_source => vial_execution_contract_source(),
        implementation_entrypoints => [
            'FSM::VIAL::ExecutionBuilder->build({...})',
            'FSM::VIAL::ExecutionReport->build($execution_ir)',
            'FSM::VIAL::Backend::SVPortableVerilator->emit({...})',
            'FSM::VIAL::Backend::TraceValidator->validate({...})',
            'FSM::VIAL::Backend::Runner->run({...})',
            'FSM::VIAL::Backend::ResultProducer->produce({...})',
            'FSM::VIAL::Tool::execute_vial_tool_request($request, $environment)',
        ],
        execution_schema => 'fsmgen.vial_execution_ir.v1',
        plan_schema => 'fsmgen.vial_plan.v1',
        replay_schema => 'fsmgen.vial_replay.v1',
        selected_future_schemas => {
            result_manifest => {
                schema => 'fsmgen.verification_result_manifest.v1',
                status => 'shipped',
                implementation_owner => 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.4',
            },
            parity_report => {
                schema => 'fsmgen.vial_parity_report.v1',
                status => 'selected_not_implemented',
                implementation_owner => 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.11',
            },
        },
        profile => 'core_directed_single_clock_execution_v1',
        backend_profile => 'sv_portable_verilator',
        backend_schema => 'fsmgen.vial_backend.sv_portable_verilator.v1',
        runtime_trace_schema => 'fsmgen.vial_sv_runtime_trace.v1',
        trace_projection_schema => 'fsmgen.vial_sv_trace_projection.v1',
        backend_stage_status => {
            negotiation => 'shipped_public_run_pipeline',
            emission => 'shipped_public_run_pipeline',
            trace_validation => 'shipped_public_run_pipeline',
            compile => 'shipped_exact_verilator_5_046',
            runtime => 'shipped_known_value_declared_probe_profile',
            result => 'shipped_verification_result_manifest_v1',
            parity => 'not_implemented',
        },
        capabilities => [qw(
            vial.binding.directional_representation.v1
            vial.backend.sv_portable_verilator.emission.v1
            vial.backend.sv_portable_verilator.v1
            vial.backend.sv_portable_verilator.declared_probe_adapter_v1
            vial.backend.sv_portable_verilator.inactive_edge_scheduler_v1
            vial.backend.sv_portable_verilator.known_value_runtime_v1
            vial.backend.sv_portable_verilator.runtime_trace_v1
            vial.backend.sv_portable_verilator.trace_validation.v1
            vial.execution_ir.v1
            vial.execution_profile.core_directed_single_clock_execution_v1
            vial.logical_time.drive_sample_react_check_v1
            vial.plan.v1
            vial.random.sha256_counter_rejection_v1
            vial.replay.v1
            vial.result_manifest.v1
        )],
        limits => {
            selected_fixtures => 1,
            selected_units => 1,
            selected_domains => 1,
            selected_scenarios => 4096,
            expanded_operations_per_scenario => 65_536,
            expanded_operations_total => 1_000_000,
            total_fibers => 65_536,
            simultaneous_live_fibers => 16_384,
            bindings => 65_536,
            execution_types => 65_536,
            model_instances => 4096,
            scalar_state_cells => 65_536,
            scoreboard_instances => 4096,
            scoreboard_declared_capacity => 1_000_000,
            coverpoints => 65_536,
            coverage_bins_and_cross_tuples => 1_000_000,
            faults => 4096,
            random_occurrences => 65_536,
            native_extensions => 256,
            native_artifacts => 1024,
            native_identity_bytes => 16_777_216,
            source_map_records => 1_000_000,
            random_attempts => 1_000_000,
            serialized_plan_bytes => 16_777_216,
        },
        backend_limits => {
            generated_systemverilog_artifacts_base => 3,
            generated_systemverilog_artifacts_per_unit => 1,
            generated_systemverilog_bytes => 16_777_216,
            source_map_entries => 1_000_000,
            runtime_trace_records => 8_000_002,
            runtime_trace_bytes => 67_108_864,
            compile_transcript_bytes => 4_194_304,
            run_transcript_bytes => 4_194_304,
            execution_seconds => 120,
        },
        fixture => 'vial/ahb_subordinate_base_output_arbitration.vial',
        writes_files => JSON::PP::true,
        public_embedding_api => JSON::PP::true,
        explicit_nonclaims => [qw(
            complete_four_state parity_pass uvm vhdl_methodology mixed_language scale
        )],
        guidance => [
            'Use the public VIAL run CLI/API for the selected portable-SystemVerilog Verilator pipeline; the backend classes remain private compiler seams.',
            'Treat the directional relation records and normalized plan-time decisions as authoritative; do not reinterpret them as target casts or backend randomization.',
            'Run materializes only an operation-owned repository-local staging tree, invokes exact Verilator 5.046 commands without warning suppressions, and removes staging before publication.',
            'Trace validation projects the produced closed trace without executing VIAL meaning; ResultProducer converts that validated projection into the closed verification-result contract.',
            'The result schema is shipped by leaf .10.4; the parity-report schema remains selected but unimplemented under leaf .11.',
            'Do not infer complete four-state observation, cross-backend parity, UVM, VHDL, mixed-language execution, or scale qualification from the selected runtime profile.',
        ],
    };
}

1;
