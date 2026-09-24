package FSM::Support::VIALToolingContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::VIALArchitectureScaleRegressionContract qw(
    build_vial_architecture_scale_regression_contract
);
use FSM::Support::VIALSemanticFamilyRegistry qw(
    vial_profile_supported_capabilities
    vial_public_tool_capabilities
);

our @EXPORT_OK = qw(
    build_vial_tooling_contract
    build_vial_tooling_contract_v2
    build_vial_source_file_check_contract
    vial_tooling_contract_keys
    vial_tooling_contract_v2_keys
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

sub vial_tooling_contract_v2_keys {
    return [qw(
        schema_version status contract_source implementation_entrypoints
        request_schema result_schema tool_manifest_schema migration_schema
        semantic_projection_schema compatibility_projection_schema
        source_styles supported_actions unavailable_actions action_states
        capabilities diagnostics limits writes_files public_embedding_api
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
            %{_source_loading_limits()},
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

sub build_vial_source_file_check_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => vial_tooling_contract_source(),
        entrypoint => 'FSM::VIAL::Tool::check_vial_source_file($invocation)',
        required_invocation_keys => [qw(workspace_root source_id)],
        optional_invocation_keys => [qw(language_version source_style)],
        defaults => {language_version => 1, source_style => 'auto'},
        language_versions => [1, 2],
        source_styles => [qw(auto normal terse)],
        action => 'check',
        result_schemas => {1 => 'fsmgen.vial_tool_result.v1', 2 => 'fsmgen.vial_tool_result.v2'},
        writes_files => JSON::PP::false,
        prints_output => JSON::PP::false,
        source_identity => 'caller_root_relative_non_symlink_same_volume',
        loading_limits => _source_loading_limits(),
        combined_bytes_include_root => JSON::PP::true,
        imported_file_count_excludes_root => JSON::PP::true,
        imported_file_count_is_distinct => JSON::PP::true,
        parser_import_edge_checks_retained => JSON::PP::true,
        limit_diagnostic => 'VIAL_LIMIT_ERROR',
    };
}

sub _source_loading_limits {
    return {source_bytes => 1_048_576, combined_source_bytes => 16_777_216, imported_sources => 64};
}

sub build_vial_tooling_contract_v2 {
    my %capability = map { $_ => 1 } (
        @{vial_profile_supported_capabilities('vial_parser_v2')},
        @{vial_profile_supported_capabilities(
            'core_directed_single_clock_execution_v2',
        )},
        qw(
            vial.artifact_layout.v2
            vial.compatibility_projection.v1
            vial.semantic_projection.v2
            vial.source_migration.v1
            vial.source_projection.normal_v2
            vial.source_projection.terse_v2
            vial.tool_manifest.v2
            vial.tooling.api.v2
            vial.tooling.cli.v2
        ),
    );
    my @capabilities = sort keys %capability;
    return {
        schema_version => 2,
        status => 'shipped_public_v2_lifecycle_source_and_planning',
        contract_source => vial_tooling_contract_source(),
        implementation_entrypoints => [
            'fsmgen vial capabilities --language-version 2 [--json]',
            'fsmgen vial check --language-version 2 [--style auto|normal|terse] [--json] SOURCE.vial',
            'fsmgen vial format --language-version 2 --style normal|terse SOURCE.vial',
            'fsmgen vial migrate --language-version 2 [--style normal|terse] [--json] SOURCE.vial',
            'fsmgen vial plan --language-version 2 --dut HIAL_SOURCE [PLAN_OPTIONS] SOURCE.vial',
            'FSM::VIAL::Tool::vial_tool_capabilities_v2()',
            'FSM::VIAL::Tool::execute_vial_tool_request($request, $environment)',
        ],
        request_schema => 'fsmgen.vial_tool_request.v2',
        result_schema => 'fsmgen.vial_tool_result.v2',
        tool_manifest_schema => 'fsmgen.vial_tool_manifest.v2',
        migration_schema => 'fsmgen.vial_source_migration.v1',
        semantic_projection_schema => 'fsmgen.vial_semantic_projection.v2',
        compatibility_projection_schema => 'fsmgen.vial_compatibility_projection.v1',
        source_styles => [qw(normal_v2 terse_v2)],
        supported_actions => [qw(capabilities check format migrate plan)],
        unavailable_actions => ['run'],
        action_states => [
            {
                action => 'capabilities', maturity => 'supported_smoke',
                writes_files => JSON::PP::false,
                artifact_atomic => JSON::PP::true,
            },
            {
                action => 'check', maturity => 'supported_smoke',
                writes_files => JSON::PP::false,
                artifact_atomic => JSON::PP::true,
            },
            {
                action => 'format', maturity => 'supported_smoke',
                writes_files => JSON::PP::false,
                artifact_atomic => JSON::PP::true,
            },
            {
                action => 'migrate', maturity => 'supported_smoke',
                writes_files => JSON::PP::false,
                artifact_atomic => JSON::PP::true,
            },
            {
                action => 'plan', maturity => 'supported_smoke',
                writes_files => JSON::PP::true,
                artifact_atomic => JSON::PP::true,
            },
            {
                action => 'run', maturity => 'unavailable',
                writes_files => JSON::PP::false,
                artifact_atomic => JSON::PP::true,
            },
        ],
        capabilities => \@capabilities,
        diagnostics => [qw(
            VIAL_TOOL_INVOCATION_ERROR
            VIAL_SOURCE_STYLE_ERROR
            VIAL_VERSION_UNSUPPORTED
            VIAL_IMPORT_VERSION_MISMATCH
            VIAL_COMPATIBILITY_ADAPTER_UNAVAILABLE
            VIAL_COMPATIBILITY_ADAPTER_INVALID
            VIAL_MIGRATION_ERROR
            VIAL_FAMILY_UNSUPPORTED
            VIAL_FAMILY_REVISION_MISMATCH
            VIAL_PARSE_ERROR
            VIAL_SCHEMA_ERROR
            VIAL_SEMANTIC_ERROR
            VIAL_LIMIT_ERROR
            VIAL_BIND_REFERENCE_ERROR
            VIAL_LIFECYCLE_DEADLINE_EXPIRED
            VIAL_LIFECYCLE_SERVICE_ERROR
            VIAL_LIFECYCLE_DRAIN_INCOMPLETE
            VIAL_LIFECYCLE_CLEANUP_TIMEOUT
            VIAL_HIAL_SOURCE_ERROR
            VIAL_ARTIFACT_PATH_ERROR
            VIAL_ARTIFACT_COLLISION
            VIAL_MANIFEST_SCHEMA_ERROR
            VIAL_HOST_ERROR
        )],
        limits => {
            %{_source_loading_limits()},
            tokens => 1_000_000,
            list_depth => 128,
            formatted_source_bytes => 1_048_576,
            artifacts => 256,
            artifact_bytes => 67_108_864,
        },
        writes_files => JSON::PP::true,
        public_embedding_api => JSON::PP::true,
        explicit_nonclaims => [qw(
            compatibility_adapter complete_result_manifest non_lifecycle_expressive_family
            family_backend family_parity family_runtime mixed_language
            qualified_v2_backend reverse_migration support_promotion
            v2_backend_emission v2_compile v2_result v2_run
        )],
        guidance => [
            'Select request schema version 2 or --language-version 2 explicitly; the default version-1 route is unchanged and never upgrades source.',
            'Check and format accept only VIAL language version 2 and preserve its language version; normal_v2 and terse_v2 are one typed meaning.',
            'Migrate accepts one complete valid version-1 catalog, returns canonical version-2 bytes plus source maps and one compatibility digest, and never overwrites source or publishes artifacts.',
            'Check, format, and plan accept the implemented lifecycle_control revision-1 family; all other expressive families remain unavailable.',
            'Plan atomically publishes typed lifecycle binding, execution, operation, capability, and cumulative source-map records without selecting a backend.',
            'Run and every version-2 backend, compile, runtime, complete-result, and parity state remain unavailable and reject before artifacts.',
        ],
    };
}

1;
