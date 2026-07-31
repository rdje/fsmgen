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
        status => 'shipped_public_source_tooling_no_artifacts',
        contract_source => vial_tooling_contract_source(),
        implementation_entrypoints => [
            'fsmgen vial capabilities [--json]',
            'fsmgen vial check [--style auto|normal|terse] [--json] SOURCE.vial',
            'fsmgen vial format --style normal|terse SOURCE.vial',
            'FSM::VIAL::Tool::vial_tool_capabilities()',
            'FSM::VIAL::Tool::execute_vial_tool_request($request, $environment)',
        ],
        request_schema => 'fsmgen.vial_tool_request.v1',
        result_schema => 'fsmgen.vial_tool_result.v1',
        semantic_projection_schema => 'fsmgen.vial_semantic_projection.v1',
        source_styles => [qw(normal_v1 terse_v1)],
        supported_actions => [qw(capabilities check format)],
        capabilities => [qw(
            vial.tooling.cli.v1
            vial.tooling.api.v1
            vial.source_projection.normal_v1
            vial.source_projection.terse_v1
            vial.semantic_projection.v1
        )],
        diagnostics => [qw(
            VIAL_TOOL_INVOCATION_ERROR
            VIAL_SOURCE_STYLE_ERROR
            VIAL_HOST_ERROR
        )],
        limits => {
            source_bytes => 1_048_576,
            combined_source_bytes => 16_777_216,
            imported_sources => 64,
            tokens => 1_000_000,
            list_depth => 128,
            formatted_source_bytes => 1_048_576,
        },
        writes_files => JSON::PP::false,
        public_embedding_api => JSON::PP::true,
        explicit_nonclaims => [qw(
            hial_binding plan_file artifact_generation backend compile
            simulation runtime result parity_pass uvm vhdl_methodology
            mixed_language scale
        )],
        guidance => [
            'Normal and terse are deterministic projections of one typed VIAL meaning; they are not separate semantic profiles.',
            'Use the public request/result records or fsmgen vial subcommands; private parser forms and SemanticIR objects do not cross the public boundary.',
            'Capabilities, check, and format never bind HIAL, write an artifact, invoke a backend, or claim runtime support.',
            'Planning, artifact publication, portable-SystemVerilog emission, and Verilator execution remain separately owned by .10.2 through .10.4.',
        ],
    };
}

1;
