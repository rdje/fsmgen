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
        profile capabilities limits
        fixture writes_files public_embedding_api explicit_nonclaims
        guidance
    )];
}

sub build_vial_execution_contract {
    return {
        schema_version => 1,
        status => 'shipped_private_target_neutral_no_backend',
        contract_source => vial_execution_contract_source(),
        implementation_entrypoints => [
            'FSM::VIAL::ExecutionBuilder->build({...})',
            'FSM::VIAL::ExecutionReport->build($execution_ir)',
        ],
        execution_schema => 'fsmgen.vial_execution_ir.v1',
        plan_schema => 'fsmgen.vial_plan.v1',
        replay_schema => 'fsmgen.vial_replay.v1',
        selected_future_schemas => {
            result_manifest => {
                schema => 'fsmgen.verification_result_manifest.v1',
                status => 'selected_not_implemented',
                implementation_owner => 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10',
            },
            parity_report => {
                schema => 'fsmgen.vial_parity_report.v1',
                status => 'selected_not_implemented',
                implementation_owner => 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.11',
            },
        },
        profile => 'core_directed_single_clock_execution_v1',
        capabilities => [qw(
            vial.binding.directional_representation.v1
            vial.execution_ir.v1
            vial.execution_profile.core_directed_single_clock_execution_v1
            vial.logical_time.drive_sample_react_check_v1
            vial.plan.v1
            vial.random.sha256_counter_rejection_v1
            vial.replay.v1
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
        fixture => 'vial/ahb_subordinate_base_output_arbitration.vial',
        writes_files => JSON::PP::false,
        public_embedding_api => JSON::PP::false,
        explicit_nonclaims => [qw(
            public_vial_cli public_vial_embedding_api plan_file result_file
            verification_artifact_generation backend compile simulation runtime
            parity_pass uvm vhdl_methodology mixed_language scale
        )],
        guidance => [
            'Consume this contract only for capability discovery; VIAL execution construction remains a private no-file compiler seam.',
            'Treat the directional relation records and normalized plan-time decisions as authoritative; do not reinterpret them as target casts or backend randomization.',
            'Treat result/parity schema names as selected future contracts, not shipped result or parity capabilities; their implementation owners remain leaves .10 and .11.',
            'Do not infer a public VIAL CLI/API, generated verification artifact, backend, runtime, result, or parity pass from this target-neutral plan capability.',
        ],
    };
}

1;
