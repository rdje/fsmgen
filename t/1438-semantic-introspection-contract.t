#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SemanticIntrospectionContract qw(
    build_semantic_introspection_contract
    semantic_introspection_contract_source
    semantic_introspection_contract_surface_map
    semantic_introspection_mcp_resource_uri_templates
    semantic_introspection_mcp_tool_names
    semantic_introspection_public_top_level_keys
    semantic_introspection_query_domain_names
    semantic_introspection_query_family_names
);

my $contract = build_semantic_introspection_contract();

subtest 'semantic-introspection contract identity and public key families are bounded' => sub {
    is($contract->{schema_version}, 1, 'contract uses schema version 1');
    is($contract->{status}, 'bounded_public', 'contract is marked bounded public');
    is(
        $contract->{contract_source},
        semantic_introspection_contract_source(),
        'contract records its owner module',
    );
    is_deeply(
        $contract->{public_top_level_presence_keys},
        semantic_introspection_public_top_level_keys(),
        'contract advertises the semantic_introspection top-level key family',
    );
    is_deeply(
        $contract->{query_domain_names},
        semantic_introspection_query_domain_names(),
        'contract advertises stable query-domain names',
    );
    is_deeply(
        $contract->{query_family_names},
        semantic_introspection_query_family_names(),
        'contract advertises stable query-family names',
    );
};

subtest 'semantic-introspection contract advertises first MCP resource and tool families' => sub {
    is_deeply(
        $contract->{mcp_resource_uri_templates},
        semantic_introspection_mcp_resource_uri_templates(),
        'contract advertises selected MCP resource URI templates',
    );
    is_deeply(
        $contract->{mcp_tool_names},
        semantic_introspection_mcp_tool_names(),
        'contract advertises selected MCP tool names',
    );

    my %resources = map { $_ => 1 } @{$contract->{mcp_resource_uri_templates}};
    ok($resources{'fsmgen://capabilities'}, 'capability resource is selected');
    ok($resources{'fsmgen://source/{source_id}/semantic'}, 'source semantic resource is selected');

    my %tools = map { $_ => 1 } @{$contract->{mcp_tool_names}};
    ok($tools{fsmgen_semantic_introspect}, 'semantic-introspection tool is selected');
    ok($tools{fsmgen_explain_diagnostic}, 'diagnostic-explanation tool is selected');
};

subtest 'semantic-introspection contract maps existing public surfaces to owners' => sub {
    is_deeply(
        $contract->{contract_surface_map},
        semantic_introspection_contract_surface_map(),
        'contract carries the exact public contract-surface map',
    );

    my @required_surfaces = qw(
        capabilities
        check_json
        normalized_semantic_json
        schedule_json
        support_accounting
        diagnostics
        documentation_examples
        embedding
        backend_validation
    );
    for my $surface (@required_surfaces) {
        ok($contract->{contract_surface_map}{$surface}, "$surface has a semantic-introspection surface entry");
        ok(
            $contract->{contract_surface_map}{$surface}{contract_source},
            "$surface has a contract source",
        );
    }
};

subtest 'semantic-introspection contract is read-only and explicit about unimplemented MCP adapter' => sub {
    ok($contract->{read_only_default}, 'read-only is the default');
    ok(!$contract->{mcp_adapter_implemented}, 'MCP adapter is not claimed as implemented');
    ok(!$contract->{write_generation_tools_enabled}, 'write/generation tools are not enabled');
    ok(!$contract->{safety_policy}{arbitrary_shell_access}, 'arbitrary shell access is forbidden');
    ok(!$contract->{safety_policy}{network_access}, 'network access is forbidden');
    ok(!$contract->{safety_policy}{raw_private_object_exposure}, 'raw private object exposure is forbidden');

    my %excluded = map { $_ => 1 } @{$contract->{raw_private_surfaces_excluded}};
    ok($excluded{raw_parser_ast}, 'raw parser AST is explicitly excluded');
    ok($excluded{raw_private_scheduler_objects}, 'raw scheduler objects are explicitly excluded');
    ok($excluded{raw_lowering_objects}, 'raw lowering objects are explicitly excluded');
    ok($excluded{raw_HDLGenerator_result_object}, 'raw HDLGenerator result object is explicitly excluded');
};

done_testing();
