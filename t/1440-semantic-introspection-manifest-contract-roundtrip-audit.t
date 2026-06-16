#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SemanticIntrospectionContract qw(build_semantic_introspection_contract);
use FSM::Support::SemanticIntrospectionSection qw(build_semantic_introspection_section);

my $sentinel = '__semantic_introspection_manifest_mutation__';

subtest 'manifest semantic-introspection contract survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{semantic_introspection}{section_contract};
    my $expected = build_semantic_introspection_contract();

    is_deeply($contract->{entrypoints}, $expected->{entrypoints}, 'decoded contract keeps entrypoints');
    is_deeply($contract->{mcp_adapter_entrypoints}, $expected->{mcp_adapter_entrypoints}, 'decoded contract keeps MCP adapter entrypoints');
    is_deeply($contract->{contract_surface_map}, $expected->{contract_surface_map}, 'decoded contract keeps contract surface map');
    is_deeply($contract->{query_domain_names}, $expected->{query_domain_names}, 'decoded contract keeps query-domain names');
    is_deeply($contract->{query_family_names}, $expected->{query_family_names}, 'decoded contract keeps query-family names');
    is_deeply($contract->{mcp_resource_uri_templates}, $expected->{mcp_resource_uri_templates}, 'decoded contract keeps MCP resource templates');
    is_deeply($contract->{mcp_tool_names}, $expected->{mcp_tool_names}, 'decoded contract keeps MCP tool names');
};

subtest 'manifest semantic-introspection section rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    mutate_structure($first->{semantic_introspection}{query_domains});
    mutate_structure($first->{semantic_introspection}{query_families});
    mutate_structure($first->{semantic_introspection}{mcp_resources});
    mutate_structure($first->{semantic_introspection}{mcp_tools});
    mutate_structure($first->{semantic_introspection}{section_contract});

    my $second = build_capability_manifest();
    my $expected = build_semantic_introspection_section();

    is_deeply($second->{semantic_introspection}, $expected, 'fresh semantic-introspection section rebuilds cleanly');
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') {
        push @{$value}, $sentinel;
        mutate_structure($_) for @{$value};
        return;
    }
    if (ref($value) eq 'HASH') {
        $value->{$sentinel} = $sentinel;
        mutate_structure($_) for values %{$value};
        return;
    }
}
