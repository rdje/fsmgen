package FSM::Support::VIALToolingContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::VIALArchitectureScaleRegressionContract qw(
    build_vial_architecture_scale_regression_contract
);
use FSM::Support::VIALSemanticFamilyRegistry qw(
    vial_public_tool_capabilities
);

our @EXPORT_OK = qw(
    build_vial_tooling_contract
    vial_tooling_contract_keys
    vial_tooling_contract_source
);

sub vial_tooling_contract_source {
    return 'FSM::Support::VIALToolingContract';
}

sub vial_tooling_contract_keys {
    return [qw(
        schema_version status contract_source implementation_entrypoints
        request_schema result_schema semantic_projection_schema
        source_styles supported_actions capabilities diagnostics limits
        architecture_scale_regression writes_files public_embedding_api
        explicit_nonclaims guidance
    )];
}

sub build_vial_tooling_contract {
    my $public_capabilities = vial_public_tool_capabilities();
    return {
        schema_version => 1,
        status => 'shipped_public_verilator_execution_result_and_ahb_parity',
        contract_source => vial_tooling_contract_source(),
        implementation_entrypoints => [
            'fsmgen vial capabilities [--json]',
            'fsmgen vial check [--style auto|normal|terse] [--json] SOURCE.vial',
            'fsmgen vial format --style normal|terse SOURCE.vial',
            'fsmgen vial plan --dut HIAL_SOURCE [PLAN_OPTIONS] SOURCE.vial',
            'fsmgen vial run --dut HIAL_SOURCE --backend sv_portable_verilator [RUN_OPTIONS] SOURCE.vial',
            'FSM::VIAL::Tool::vial_tool_capabilities()',
            'FSM::VIAL::Tool::execute_vial_tool_request($request, $environment)',
        ],
        request_schema => 'fsmgen.vial_tool_request.v1',
        result_schema => 'fsmgen.vial_tool_result.v1',
        semantic_projection_schema => 'fsmgen.vial_semantic_projection.v1',
        source_styles => [qw(normal_v1 terse_v1)],
        supported_actions => [qw(capabilities check format plan run)],
        capabilities => $public_capabilities,
        diagnostics => [qw(
            VIAL_TOOL_INVOCATION_ERROR
            VIAL_SOURCE_STYLE_ERROR
            VIAL_HIAL_SOURCE_ERROR
            VIAL_BACKEND_UNSUPPORTED
            VIAL_ARTIFACT_PATH_ERROR
            VIAL_ARTIFACT_COLLISION
            VIAL_MANIFEST_SCHEMA_ERROR
            VIAL_RUN_INVOCATION_ERROR
            VIAL_RUN_PATH_ERROR
            VIAL_RUN_TOOL_ERROR
            VIAL_RUN_COMMAND_ERROR
            VIAL_RUN_COLLISION
            VIAL_RUN_COMPILE_ERROR
            VIAL_RUN_RUNTIME_ERROR
            VIAL_RUN_LIMIT_EXCEEDED
            VIAL_RUN_TRACE_ERROR
            VIAL_RUN_RESULT_ERROR
            VIAL_RUN_CLEANUP_ERROR
            VIAL_RUN_HOST_ERROR
            VIAL_HOST_ERROR
        )],
        limits => {
            source_bytes => 1_048_576,
            combined_source_bytes => 16_777_216,
            imported_sources => 64,
            tokens => 1_000_000,
            list_depth => 128,
            formatted_source_bytes => 1_048_576,
            artifacts => 256,
            artifact_bytes => 67_108_864,
        },
        architecture_scale_regression =>
            build_vial_architecture_scale_regression_contract(),
        writes_files => JSON::PP::true,
        public_embedding_api => JSON::PP::true,
        explicit_nonclaims => [qw(
            complete_four_state general_cross_backend_parity uvm
            vhdl_methodology mixed_language architecture_scale_capacity
            whole_product_big whole_product_really_big multi_unit
            multi_domain native_uvm_runtime full_language synthesis
            arbitrary_tool_capacity support_promotion
        )],
        guidance => [
            'Normal and terse are deterministic projections of one typed VIAL meaning; they are not separate semantic profiles.',
            'Use the public request/result records or fsmgen vial subcommands; private parser forms and SemanticIR objects do not cross the public boundary.',
            'Capabilities, check, and format never bind HIAL or write an artifact; plan and run bind one canonical HIAL review route, while only run selects a backend.',
            'The in-memory plan/run API publishes one complete virtual artifact sink; the CLI atomically commits the same graph below a repository-relative same-volume root.',
            'Run selects the exact qualified Verilator profile, compiles and executes repository-local generated SystemVerilog, validates its closed trace, and publishes a verification result manifest.',
            'Known-value runtime evidence and bounded parity with the handwritten AHB oracle are shipped for the selected one-unit, one-clock, declared-probe profile.',
            'A separate public eleven-profile architecture-scale regression gate enforces deterministic correctness everywhere and immutable performance budgets only on the exact qualified environment; it does not promote general support or capacity.',
            'Complete four-state observation, general cross-backend parity, UVM, VHDL methodology, mixed-language execution, whole-product big/really-big, multi-unit/domain, native-UVM runtime, full-language, synthesis, arbitrary-tool capacity, support promotion, and architecture-scale capacity remain explicit nonclaims.',
        ],
    };
}

1;
