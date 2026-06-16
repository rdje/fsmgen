package FSM::Support::SemanticIntrospectionSection;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use FSM::Support::SemanticIntrospectionContract qw(
    build_semantic_introspection_contract
    semantic_introspection_contract_source
    semantic_introspection_contract_surface_map
    semantic_introspection_mcp_resource_uri_templates
    semantic_introspection_mcp_resources
    semantic_introspection_mcp_tool_names
    semantic_introspection_mcp_tools
    semantic_introspection_provenance_support_policy
    semantic_introspection_query_domain_names
    semantic_introspection_query_domains
    semantic_introspection_query_families
    semantic_introspection_query_family_names
    semantic_introspection_raw_private_surfaces_excluded
    semantic_introspection_safety_policy
    semantic_introspection_versioning_policy
);

our @EXPORT_OK = qw(build_semantic_introspection_section);

sub build_semantic_introspection_section {
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
            in_process => [
                'FSM::Support::CapabilityManifest::build_capability_manifest()->{semantic_introspection}',
                'FSM::Support::SemanticIntrospectionSection::build_semantic_introspection_section()',
            ],
        },
        contract_surface_map => semantic_introspection_contract_surface_map(),
        query_domains => semantic_introspection_query_domains(),
        query_families => semantic_introspection_query_families(),
        query_domain_names => semantic_introspection_query_domain_names(),
        query_family_names => semantic_introspection_query_family_names(),
        mcp_resources => semantic_introspection_mcp_resources(),
        mcp_tools => semantic_introspection_mcp_tools(),
        mcp_resource_uri_templates => semantic_introspection_mcp_resource_uri_templates(),
        mcp_tool_names => semantic_introspection_mcp_tool_names(),
        versioning_policy => semantic_introspection_versioning_policy(),
        provenance_support_policy => semantic_introspection_provenance_support_policy(),
        safety_policy => semantic_introspection_safety_policy(),
        raw_private_surfaces_excluded => semantic_introspection_raw_private_surfaces_excluded(),
        read_only_default => JSON::PP::true,
        mcp_adapter_implemented => JSON::PP::false,
        write_generation_tools_enabled => JSON::PP::false,
        section_contract => build_semantic_introspection_contract(),
    };
}

1;
