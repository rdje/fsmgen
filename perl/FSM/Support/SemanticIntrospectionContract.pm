package FSM::Support::SemanticIntrospectionContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use FSM::Support::BackendValidationContract qw(backend_validation_contract_source);
use FSM::Support::CheckDiagnosticsContract qw(check_diagnostics_contract_source);
use FSM::Support::DiagnosticsContract qw(diagnostics_contract_source);
use FSM::Support::DocumentationContract qw(documentation_contract_source);
use FSM::Support::EmbeddingContract qw(embedding_contract_source);
use FSM::Support::ISFPublicInterfaceContract qw(isf_public_interface_contract_source);
use FSM::Support::LanguageSurfaceContract qw(language_surface_contract_source);
use FSM::Support::NormalizedSemanticReportContract qw(normalized_semantic_report_contract_source);
use FSM::Support::ProducerContract qw(producer_contract_source);
use FSM::Support::ReportGeneratedOutputContract qw(report_generated_output_contract_source);
use FSM::Support::SemanticExportsContract qw(semantic_exports_contract_source);
use FSM::Support::SupportAccountingContract qw(support_accounting_contract_source);

our @EXPORT_OK = qw(
    build_semantic_introspection_contract
    semantic_introspection_contract_source
    semantic_introspection_contract_surface_map
    semantic_introspection_mcp_adapter_entrypoints
    semantic_introspection_mcp_resource_uri_templates
    semantic_introspection_mcp_resources
    semantic_introspection_mcp_tool_names
    semantic_introspection_mcp_tools
    semantic_introspection_presence_key_family_map
    semantic_introspection_provenance_support_policy
    semantic_introspection_public_top_level_keys
    semantic_introspection_query_domain_names
    semantic_introspection_query_domains
    semantic_introspection_query_families
    semantic_introspection_query_family_names
    semantic_introspection_raw_private_surfaces_excluded
    semantic_introspection_safety_policy
    semantic_introspection_versioning_policy
);

sub semantic_introspection_contract_source {
    return 'FSM::Support::SemanticIntrospectionContract';
}

sub build_semantic_introspection_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => semantic_introspection_contract_source(),
        report_source => 'FSM::Support::CapabilityManifest',
        entrypoints => {
            cli => './bin/fsmgen --capability-manifest',
            cli_aliases => [
                './bin/fsmgen --emit-capability-manifest',
            ],
            mcp_adapter => semantic_introspection_mcp_adapter_entrypoints(),
            in_process => [
                'FSM::Support::CapabilityManifest::build_capability_manifest()->{semantic_introspection}',
                'FSM::Support::SemanticIntrospectionSection::build_semantic_introspection_section()',
            ],
        },
        mcp_adapter_entrypoints => semantic_introspection_mcp_adapter_entrypoints(),
        public_top_level_presence_keys => semantic_introspection_public_top_level_keys(),
        query_domain_names => semantic_introspection_query_domain_names(),
        query_family_names => semantic_introspection_query_family_names(),
        mcp_resource_uri_templates => semantic_introspection_mcp_resource_uri_templates(),
        mcp_tool_names => semantic_introspection_mcp_tool_names(),
        contract_surface_map => semantic_introspection_contract_surface_map(),
        versioning_policy => semantic_introspection_versioning_policy(),
        provenance_support_policy => semantic_introspection_provenance_support_policy(),
        safety_policy => semantic_introspection_safety_policy(),
        raw_private_surfaces_excluded => semantic_introspection_raw_private_surfaces_excluded(),
        presence_key_family_map => semantic_introspection_presence_key_family_map(),
        read_only_default => JSON::PP::true,
        mcp_adapter_implemented => JSON::PP::true,
        write_generation_tools_enabled => JSON::PP::false,
        guidance => [
            'Treat semantic_introspection as the first-class bounded query contract advertised by the capability manifest for schema version 1.',
            'MCP resources and tools listed here are implemented by the read-only FSMGen MCP adapter over the stable semantic-introspection API.',
            'Use bin/fsmgen-mcp for the shipped local JSON-RPC stdio adapter; write/generation tools remain disabled.',
            'Use query_domains and query_families to discover which existing public FSMGen surfaces can answer a question without depending on private parser, scheduler, lowering, or HDLGenerator objects.',
            'Source-bound queries must preserve source identity, producer metadata, diagnostics, generated-output inventories when emitted, and support-accounting metadata when the backing surface provides it.',
            'Read-only query families are the default. Write, HDL-generation, mutation, network, arbitrary-shell, commit, and push tools require future task-tree ownership before they can be advertised as enabled.',
        ],
    };
}

sub semantic_introspection_public_top_level_keys {
    return [
        qw(
            schema_version
            status
            contract_source
            report_source
            entrypoints
            mcp_adapter_entrypoints
            contract_surface_map
            query_domains
            query_families
            query_domain_names
            query_family_names
            mcp_resources
            mcp_tools
            mcp_resource_uri_templates
            mcp_tool_names
            versioning_policy
            provenance_support_policy
            safety_policy
            raw_private_surfaces_excluded
            read_only_default
            mcp_adapter_implemented
            write_generation_tools_enabled
            section_contract
        ),
    ];
}

sub semantic_introspection_mcp_adapter_entrypoints {
    return [
        'perl bin/fsmgen-mcp --workspace-root DIR',
        'perl bin/fsmgen-mcp --request-json JSON --workspace-root DIR',
        'FSM::Support::SemanticIntrospectionMCPAdapter->new(workspace_root => DIR)->run_stdio()',
    ];
}

sub semantic_introspection_query_domain_names {
    return [
        qw(
            capabilities
            contracts
            diagnostics
            support_accounting
            examples
            source_check
            source_semantic
            source_schedule
            generated_artifacts
            embedding
            backend_validation
            language_surface
        ),
    ];
}

sub semantic_introspection_query_family_names {
    return [
        qw(
            capability_query
            check
            semantic_introspect
            schedule_preview
            find_examples
            explain_diagnostic
            support_summary
        ),
    ];
}

sub semantic_introspection_mcp_resource_uri_templates {
    return [
        'fsmgen://capabilities',
        'fsmgen://contracts',
        'fsmgen://diagnostics',
        'fsmgen://support-accounting',
        'fsmgen://examples',
        'fsmgen://source/{source_id}/check',
        'fsmgen://source/{source_id}/semantic',
        'fsmgen://source/{source_id}/schedule',
    ];
}

sub semantic_introspection_mcp_tool_names {
    return [
        qw(
            fsmgen_capability_query
            fsmgen_check
            fsmgen_semantic_introspect
            fsmgen_schedule_preview
            fsmgen_find_examples
            fsmgen_explain_diagnostic
            fsmgen_support_summary
        ),
    ];
}

sub semantic_introspection_contract_surface_map {
    return {
        capabilities => {
            manifest_path => ['manifest_contract'],
            contract_source => 'FSM::Support::CapabilityManifestContract',
            current_entrypoints => [
                './bin/fsmgen --capability-manifest',
                './bin/fsmgen --emit-capability-manifest',
            ],
        },
        producer => {
            manifest_path => ['producer'],
            contract_source => producer_contract_source(),
            current_entrypoints => ['./bin/fsmgen --capability-manifest'],
        },
        diagnostics => {
            manifest_path => ['diagnostics'],
            contract_source => diagnostics_contract_source(),
            current_entrypoints => ['./bin/fsmgen --capability-manifest'],
        },
        check_json => {
            manifest_path => ['diagnostics', 'check_json'],
            contract_source => check_diagnostics_contract_source(),
            current_entrypoints => [
                './bin/fsmgen --strict --check --json path/to/source',
                './bin/fsmgen --strict --check-json path/to/source',
            ],
        },
        support_accounting => {
            manifest_path => ['support_accounting'],
            contract_source => support_accounting_contract_source(),
            current_entrypoints => [
                './bin/fsmgen --capability-manifest',
                './bin/fsmgen --strict --check --json path/to/source',
                './bin/fsmgen --strict --emit-semantic-json path/to/source',
            ],
        },
        semantic_exports => {
            manifest_path => ['semantic_exports'],
            contract_source => semantic_exports_contract_source(),
            current_entrypoints => ['./bin/fsmgen --capability-manifest'],
        },
        mcp_adapter => {
            manifest_path => ['semantic_introspection'],
            contract_source => 'FSM::Support::SemanticIntrospectionMCPAdapter',
            current_entrypoints => semantic_introspection_mcp_adapter_entrypoints(),
        },
        normalized_semantic_json => {
            manifest_path => ['semantic_exports', 'normalized_semantic_json'],
            contract_source => normalized_semantic_report_contract_source(),
            current_entrypoints => [
                './bin/fsmgen --strict --emit-semantic-json path/to/source',
            ],
        },
        schedule_json => {
            manifest_path => ['embedding', 'isf_public_interface'],
            contract_source => isf_public_interface_contract_source(),
            current_entrypoints => [
                './bin/fsmgen --emit-schedule-json path/to/source.isf',
                './bin/fsmgen --emit-schedule-json path/to/source.ppif',
            ],
        },
        generated_artifacts => {
            manifest_path => ['diagnostics', 'check_json', 'generated_output'],
            contract_source => report_generated_output_contract_source(),
            current_entrypoints => [
                './bin/fsmgen --strict --check --json path/to/source',
                './bin/fsmgen --strict --emit-semantic-json path/to/source',
                './bin/fsmgen --emit-schedule-json path/to/source.isf',
                './bin/fsmgen --emit-schedule-json path/to/source.ppif',
            ],
        },
        documentation_examples => {
            manifest_path => ['documentation'],
            contract_source => documentation_contract_source(),
            current_entrypoints => ['./bin/fsmgen --capability-manifest'],
        },
        embedding => {
            manifest_path => ['embedding'],
            contract_source => embedding_contract_source(),
            current_entrypoints => ['./bin/fsmgen --capability-manifest'],
        },
        backend_validation => {
            manifest_path => ['backend_validation'],
            contract_source => backend_validation_contract_source(),
            current_entrypoints => ['./bin/fsmgen --capability-manifest'],
        },
        language_surface => {
            manifest_path => ['language_surface'],
            contract_source => language_surface_contract_source(),
            current_entrypoints => ['./bin/fsmgen --capability-manifest'],
        },
    };
}

sub semantic_introspection_query_domains {
    return [
        _domain(
            'capabilities',
            'Discover FSMGen manifest sections, contract ownership, and current public entrypoints.',
            ['capabilities', 'producer', 'language_surface'],
            'fsmgen://capabilities',
        ),
        _domain(
            'contracts',
            'Discover bounded contract sources, public key families, schema versions, and nested surface ownership.',
            [qw(capabilities diagnostics support_accounting semantic_exports mcp_adapter embedding backend_validation documentation_examples language_surface)],
            'fsmgen://contracts',
        ),
        _domain(
            'diagnostics',
            'Query stable diagnostic-code metadata and check-JSON diagnostic report shape.',
            [qw(diagnostics check_json)],
            'fsmgen://diagnostics',
        ),
        _domain(
            'support_accounting',
            'Query corpus-backed support coverage, classifications, source kinds, and report-level support-accounting payloads.',
            ['support_accounting'],
            'fsmgen://support-accounting',
        ),
        _domain(
            'examples',
            'Find repo-relative mdBook and corpus examples without exposing machine-local paths.',
            ['documentation_examples'],
            'fsmgen://examples',
        ),
        _domain(
            'source_check',
            'Run or read bounded check-JSON results for an explicit source identity.',
            [qw(check_json diagnostics support_accounting generated_artifacts)],
            'fsmgen://source/{source_id}/check',
        ),
        _domain(
            'source_semantic',
            'Run or read bounded normalized semantic JSON for an explicit source identity.',
            [qw(normalized_semantic_json semantic_exports support_accounting generated_artifacts)],
            'fsmgen://source/{source_id}/semantic',
        ),
        _domain(
            'source_schedule',
            'Run or read bounded schedule/lowering reports for explicit ISF or PPIF source identity.',
            [qw(schedule_json generated_artifacts diagnostics)],
            'fsmgen://source/{source_id}/schedule',
        ),
        _domain(
            'generated_artifacts',
            'Inspect generated .isf, .fsm, HDL, and report artifact inventories that existing public reports already emit.',
            ['generated_artifacts'],
            'fsmgen://source/{source_id}/check',
        ),
        _domain(
            'embedding',
            'Discover bounded in-process facade, result, serializable-report, ISF public-interface, and debug-runtime contracts.',
            ['embedding'],
            'fsmgen://contracts',
        ),
        _domain(
            'backend_validation',
            'Discover external validation capability and failure-mode contracts without running external tools.',
            ['backend_validation'],
            'fsmgen://contracts',
        ),
        _domain(
            'language_surface',
            'Discover strict-mode, file-surface, assignment, expression, declaration, system, and composition contract boundaries.',
            ['language_surface'],
            'fsmgen://contracts',
        ),
    ];
}

sub semantic_introspection_query_families {
    return [
        _query_family(
            'capability_query',
            'Manifest and contract discovery over repo-public metadata.',
            [qw(capabilities contracts diagnostics support_accounting examples embedding backend_validation language_surface)],
            'fsmgen_capability_query',
            ['fsmgen://capabilities', 'fsmgen://contracts'],
        ),
        _query_family(
            'check',
            'Bounded source checking with check JSON, diagnostics, support accounting, and generated-output inventory.',
            ['source_check'],
            'fsmgen_check',
            ['fsmgen://source/{source_id}/check'],
        ),
        _query_family(
            'semantic_introspect',
            'Normalized semantic JSON inspection for source-bound semantic payloads.',
            ['source_semantic'],
            'fsmgen_semantic_introspect',
            ['fsmgen://source/{source_id}/semantic'],
        ),
        _query_family(
            'schedule_preview',
            'Schedule/lowering preview over existing ISF and PPIF schedule-report surfaces.',
            ['source_schedule'],
            'fsmgen_schedule_preview',
            ['fsmgen://source/{source_id}/schedule'],
        ),
        _query_family(
            'find_examples',
            'Example and documentation lookup over repo-relative mdBook and corpus references.',
            ['examples'],
            'fsmgen_find_examples',
            ['fsmgen://examples'],
        ),
        _query_family(
            'explain_diagnostic',
            'Diagnostic-code explanation and nearest public contract lookup.',
            ['diagnostics'],
            'fsmgen_explain_diagnostic',
            ['fsmgen://diagnostics'],
        ),
        _query_family(
            'support_summary',
            'Bounded support-accounting summary for supported, strict-supported, and expected-failure corpus coverage.',
            ['support_accounting'],
            'fsmgen_support_summary',
            ['fsmgen://support-accounting'],
        ),
    ];
}

sub semantic_introspection_mcp_resources {
    my %surface_map = %{semantic_introspection_contract_surface_map()};
    return [
        _resource('fsmgen://capabilities', 'capabilities', ['capabilities', 'producer', 'language_surface'], $surface_map{capabilities}{contract_source}),
        _resource('fsmgen://contracts', 'contracts', [qw(capabilities diagnostics support_accounting semantic_exports mcp_adapter embedding backend_validation documentation_examples language_surface)], semantic_introspection_contract_source()),
        _resource('fsmgen://diagnostics', 'diagnostics', [qw(diagnostics check_json)], diagnostics_contract_source()),
        _resource('fsmgen://support-accounting', 'support_accounting', ['support_accounting'], support_accounting_contract_source()),
        _resource('fsmgen://examples', 'examples', ['documentation_examples'], documentation_contract_source()),
        _resource('fsmgen://source/{source_id}/check', 'source_check', [qw(check_json diagnostics support_accounting generated_artifacts)], check_diagnostics_contract_source(), JSON::PP::true),
        _resource('fsmgen://source/{source_id}/semantic', 'source_semantic', [qw(normalized_semantic_json semantic_exports support_accounting generated_artifacts)], normalized_semantic_report_contract_source(), JSON::PP::true),
        _resource('fsmgen://source/{source_id}/schedule', 'source_schedule', [qw(schedule_json generated_artifacts diagnostics)], isf_public_interface_contract_source(), JSON::PP::true),
    ];
}

sub semantic_introspection_mcp_tools {
    return [
        _tool('fsmgen_capability_query', 'capability_query', 'capabilities', 'capability manifest and section contracts'),
        _tool('fsmgen_check', 'check', 'source_check', 'check JSON'),
        _tool('fsmgen_semantic_introspect', 'semantic_introspect', 'source_semantic', 'normalized semantic JSON'),
        _tool('fsmgen_schedule_preview', 'schedule_preview', 'source_schedule', 'schedule JSON'),
        _tool('fsmgen_find_examples', 'find_examples', 'examples', 'repo-relative documentation and corpus examples'),
        _tool('fsmgen_explain_diagnostic', 'explain_diagnostic', 'diagnostics', 'stable diagnostic-code metadata'),
        _tool('fsmgen_support_summary', 'support_summary', 'support_accounting', 'bounded support-accounting summary'),
    ];
}

sub semantic_introspection_versioning_policy {
    return {
        section_schema_version => 1,
        contract_schema_version => 1,
        manifest_schema_version => 1,
        query_domain_names_versioned_by => 'semantic_introspection.schema_version',
        query_family_names_versioned_by => 'semantic_introspection.schema_version',
        existing_report_version_fields => {
            capability_manifest => 'manifest_schema_version',
            check_json => 'check_schema_version',
            normalized_semantic_json => 'normalized_semantic_schema_version',
            schedule_json => 'schema',
        },
        contract_source_required => JSON::PP::true,
        additive_schema_1_changes_allowed => JSON::PP::true,
        breaking_changes_require_schema_version_increment => JSON::PP::true,
    };
}

sub semantic_introspection_provenance_support_policy {
    return {
        producer_metadata_required => JSON::PP::true,
        source_identity_required_for_source_bound_queries => JSON::PP::true,
        diagnostics_required_when_surface_emits_them => JSON::PP::true,
        support_accounting_required_when_surface_emits_it => JSON::PP::true,
        generated_output_inventory_allowed_when_emitted_by_surface => JSON::PP::true,
        repo_relative_documentation_paths_required => JSON::PP::true,
        contract_source_required => JSON::PP::true,
        provenance_loss_behavior => 'fail closed or report explicit unsupported residue; do not synthesize private-object payloads',
    };
}

sub semantic_introspection_safety_policy {
    return {
        default_access => 'read_only',
        workspace_root_restriction => 'the shipped adapter resolves source_id and paths under the caller-approved workspace root',
        source_bound_path_sanitization => 'workspace_or_repo_absolute_paths_return_relative_else_redacted',
        source_query_provenance => 'adapter_provenance records read_only transport, command shape, source identity policy, and no-shell policy without returning workspace roots',
        jsonrpc_error_code_policy => {
            parse_error => -32700,
            invalid_request => -32600,
            method_not_found => -32601,
            adapter_call_error => -32000,
        },
        arbitrary_shell_access => JSON::PP::false,
        network_access => JSON::PP::false,
        implicit_file_writes => JSON::PP::false,
        generated_hdl_write_tools_enabled => JSON::PP::false,
        mutation_tools_enabled => JSON::PP::false,
        commit_or_push_tools_enabled => JSON::PP::false,
        raw_private_object_exposure => JSON::PP::false,
        mcp_adapter_status => 'implemented_read_only_jsonrpc_stdio',
    };
}

sub semantic_introspection_raw_private_surfaces_excluded {
    return [
        qw(
            raw_parser_ast
            raw_private_scheduler_objects
            raw_lowering_objects
            raw_LoweringIR
            raw_HDLGenerator_result_object
            HDLGenerator_compatibility_hashes
            internal_Perl_references
            arbitrary_shell_output
            machine_local_absolute_paths
        ),
    ];
}

sub semantic_introspection_presence_key_family_map {
    return {
        public_top_level_presence_keys => semantic_introspection_public_top_level_keys(),
        query_domain_names => semantic_introspection_query_domain_names(),
        query_family_names => semantic_introspection_query_family_names(),
        mcp_resource_uri_templates => semantic_introspection_mcp_resource_uri_templates(),
        mcp_tool_names => semantic_introspection_mcp_tool_names(),
        raw_private_surfaces_excluded => semantic_introspection_raw_private_surfaces_excluded(),
        contract_surface_names => [sort keys %{semantic_introspection_contract_surface_map()}],
    };
}

sub _domain {
    my ($name, $description, $surface_names, $resource_template) = @_;
    return {
        name => $name,
        description => $description,
        contract_surfaces => [@{$surface_names || []}],
        mcp_resource_uri_template => $resource_template,
        read_only => JSON::PP::true,
        requires_source_identity => ($resource_template =~ /\{source_id\}/ ? JSON::PP::true : JSON::PP::false),
    };
}

sub _query_family {
    my ($name, $description, $domain_names, $tool_name, $resource_templates) = @_;
    return {
        name => $name,
        description => $description,
        query_domains => [@{$domain_names || []}],
        mcp_tool_name => $tool_name,
        mcp_resource_uri_templates => [@{$resource_templates || []}],
        read_only => JSON::PP::true,
        writes_files => JSON::PP::false,
        network_access => JSON::PP::false,
    };
}

sub _resource {
    my ($uri_template, $domain_name, $surface_names, $output_contract_source, $source_bound) = @_;
    return {
        uri_template => $uri_template,
        query_domain => $domain_name,
        contract_surfaces => [@{$surface_names || []}],
        output_contract_source => $output_contract_source,
        source_bound => $source_bound ? JSON::PP::true : JSON::PP::false,
        read_only => JSON::PP::true,
        adapter_status => 'implemented_read_only',
    };
}

sub _tool {
    my ($name, $query_family, $query_domain, $output_payload) = @_;
    return {
        name => $name,
        query_family => $query_family,
        query_domain => $query_domain,
        output_payload => $output_payload,
        read_only => JSON::PP::true,
        writes_files => JSON::PP::false,
        requires_workspace_root => JSON::PP::true,
        network_access => JSON::PP::false,
        adapter_status => 'implemented_read_only',
    };
}

1;
