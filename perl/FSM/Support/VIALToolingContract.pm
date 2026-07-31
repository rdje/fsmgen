package FSM::Support::VIALToolingContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

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
        writes_files public_embedding_api explicit_nonclaims guidance
    )];
}

sub build_vial_tooling_contract {
    return {
        schema_version => 1,
        status => 'shipped_public_source_tooling_and_atomic_planning',
        contract_source => vial_tooling_contract_source(),
        implementation_entrypoints => [
            'fsmgen vial capabilities [--json]',
            'fsmgen vial check [--style auto|normal|terse] [--json] SOURCE.vial',
            'fsmgen vial format --style normal|terse SOURCE.vial',
            'fsmgen vial plan --dut HIAL_SOURCE [PLAN_OPTIONS] SOURCE.vial',
            'FSM::VIAL::Tool::vial_tool_capabilities()',
            'FSM::VIAL::Tool::execute_vial_tool_request($request, $environment)',
        ],
        request_schema => 'fsmgen.vial_tool_request.v1',
        result_schema => 'fsmgen.vial_tool_result.v1',
        semantic_projection_schema => 'fsmgen.vial_semantic_projection.v1',
        source_styles => [qw(normal_v1 terse_v1)],
        supported_actions => [qw(capabilities check format plan)],
        capabilities => [qw(
            vial.tooling.cli.v1
            vial.tooling.api.v1
            vial.source_projection.normal_v1
            vial.source_projection.terse_v1
            vial.semantic_projection.v1
            vial.artifact_layout.v1
            vial.tool_manifest.v1
            vial.verification_output_manifest.v2
        )],
        diagnostics => [qw(
            VIAL_TOOL_INVOCATION_ERROR
            VIAL_SOURCE_STYLE_ERROR
            VIAL_HIAL_SOURCE_ERROR
            VIAL_BACKEND_UNAVAILABLE
            VIAL_ARTIFACT_PATH_ERROR
            VIAL_ARTIFACT_COLLISION
            VIAL_MANIFEST_SCHEMA_ERROR
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
        writes_files => JSON::PP::true,
        public_embedding_api => JSON::PP::true,
        explicit_nonclaims => [qw(
            backend compile simulation runtime result parity_pass uvm vhdl_methodology
            mixed_language scale
        )],
        guidance => [
            'Normal and terse are deterministic projections of one typed VIAL meaning; they are not separate semantic profiles.',
            'Use the public request/result records or fsmgen vial subcommands; private parser forms and SemanticIR objects do not cross the public boundary.',
            'Capabilities, check, and format never bind HIAL or write an artifact; plan alone binds one canonical HIAL review route and publishes target-neutral projections.',
            'The in-memory plan API publishes one complete virtual artifact sink; the CLI atomically commits the same graph below a repository-relative same-volume root.',
            'Portable-SystemVerilog emission and Verilator execution remain separately owned by .10.3 and .10.4.',
        ],
    };
}

1;
