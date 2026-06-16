#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo_root,
    workspace_root => $repo_root,
    runner => sub {
        my ($command) = @_;
        return {
            runner => 'stub',
            argv => [@{$command}],
            ok => JSON::PP::true,
            source => {
                resolved_path => $command->[-1],
            },
        };
    },
);

subtest 'read-only MCP resource and tool envelopes match bounded snapshot fixture' => sub {
    my $fixture = File::Spec->catfile(
        $repo_root,
        't',
        'fixtures',
        'semantic_introspection_mcp',
        'read_only_schema_snapshot.json',
    );
    my $expected = decode_json(slurp($fixture));
    my $actual = build_schema_snapshot($adapter);

    is_deeply($actual, $expected, 'read-only MCP schema projection matches fixture');
};

subtest 'snapshot fixture does not advertise mutation or ambient-access tools' => sub {
    my $actual = build_schema_snapshot($adapter);

    my @tool_names = map { $_->{name} } @{$actual->{tools}};
    for my $name (@tool_names) {
        unlike(
            $name,
            qr/(?:generate|write|commit|push|shell|network)/,
            "$name is not a write, shell, network, commit, or push tool",
        );
    }

    my $encoded = JSON::PP->new->ascii->canonical->encode($actual);
    unlike($encoded, qr/\Q$repo_root\E/, 'snapshot projection does not leak the machine-local repo root');
};

done_testing();

sub build_schema_snapshot {
    my ($adapter) = @_;

    return {
        initialize => project_initialize($adapter->initialize_result({
            protocolVersion => 'test-protocol',
        })),
        resources => project_resources($adapter->list_resources()),
        resource_templates => project_resource_templates($adapter->list_resource_templates()),
        tools => project_tools($adapter->list_tools()),
        tool_envelopes => {
            capability_query => project_tool_response(
                $adapter->call_tool('fsmgen_capability_query', {
                    section => 'semantic_introspection',
                }),
                \&project_capability_query_payload,
            ),
            support_summary => project_tool_response(
                $adapter->call_tool('fsmgen_support_summary', {
                    limit_examples => 2,
                }),
                \&project_support_summary_payload,
            ),
            examples => project_tool_response(
                $adapter->call_tool('fsmgen_find_examples', {
                    query => 'composition',
                    limit => 2,
                }),
                \&project_examples_payload,
            ),
            diagnostic => project_tool_response(
                $adapter->call_tool('fsmgen_explain_diagnostic', {
                    code => 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE',
                    limit_examples => 2,
                }),
                \&project_diagnostic_payload,
            ),
            check => project_tool_response(
                $adapter->call_tool('fsmgen_check', {
                    source_path => 'ppif/axi_aw_valid_ready.ppif',
                }),
                \&project_source_payload,
            ),
            semantic => project_tool_response(
                $adapter->call_tool('fsmgen_semantic_introspect', {
                    source_path => 'ppif/axi_aw_valid_ready.ppif',
                }),
                \&project_source_payload,
            ),
            schedule => project_tool_response(
                $adapter->call_tool('fsmgen_schedule_preview', {
                    source_path => 'ppif/axi_aw_valid_ready.ppif',
                }),
                \&project_source_payload,
            ),
        },
    };
}

sub project_initialize {
    my ($response) = @_;

    return {
        protocolVersion => $response->{protocolVersion},
        capability_keys => sorted_keys($response->{capabilities}),
        resource_capability_keys => sorted_keys($response->{capabilities}{resources}),
        tool_capability_keys => sorted_keys($response->{capabilities}{tools}),
        server_name => $response->{serverInfo}{name},
        server_version_type => defined($response->{serverInfo}{version}) ? 'string' : 'missing',
        instructions_mentions_read_only => json_bool(($response->{instructions} || '') =~ /Read-only/),
    };
}

sub project_resources {
    my ($response) = @_;

    return [
        map {
            {
                uri => $_->{uri},
                name => $_->{name},
                mimeType => $_->{mimeType},
                has_description => json_bool(length($_->{description} || '')),
            }
        } @{$response->{resources}}
    ];
}

sub project_resource_templates {
    my ($response) = @_;

    return [
        map {
            {
                uriTemplate => $_->{uriTemplate},
                name => $_->{name},
                mimeType => $_->{mimeType},
                has_description => json_bool(length($_->{description} || '')),
            }
        } @{$response->{resourceTemplates}}
    ];
}

sub project_tools {
    my ($response) = @_;

    return [
        map {
            my $schema = $_->{inputSchema} || {};
            my $properties = $schema->{properties} || {};
            my $output_schema = $_->{outputSchema} || {};
            my $output_properties = $output_schema->{properties} || {};
            {
                name => $_->{name},
                required => [@{$schema->{required} || []}],
                property_names => sorted_keys($properties),
                property_types => {
                    map { $_ => ($properties->{$_}{type} || 'unspecified') }
                    sort keys %{$properties}
                },
                output_schema_type => $output_schema->{type} || 'missing',
                output_required => [@{$output_schema->{required} || []}],
                output_property_names => sorted_keys($output_properties),
            }
        } @{$response->{tools}}
    ];
}

sub project_tool_response {
    my ($response, $payload_projection) = @_;
    my $payload = decode_json($response->{content}[0]{text});

    return {
        response_keys => sorted_keys($response),
        isError => json_bool($response->{isError}),
        content_types => [map { $_->{type} } @{$response->{content}}],
        structuredContent_matches_text => json_bool(
            JSON::PP->new->ascii->canonical->encode($response->{structuredContent})
                eq JSON::PP->new->ascii->canonical->encode($payload)
        ),
        decoded_payload => $payload_projection->($payload),
    };
}

sub project_capability_query_payload {
    my ($payload) = @_;

    return {
        payload_keys => sorted_keys($payload),
        section => $payload->{section},
        semantic_keys => sorted_keys($payload->{payload}),
        mcp_tool_names => $payload->{payload}{mcp_tool_names},
        mcp_resource_templates => [
            map { $_->{uri_template} } @{$payload->{payload}{mcp_resources}}
        ],
        mcp_adapter_implemented => json_bool($payload->{payload}{mcp_adapter_implemented}),
        write_generation_tools_enabled => json_bool($payload->{payload}{write_generation_tools_enabled}),
    };
}

sub project_support_summary_payload {
    my ($payload) = @_;

    return {
        payload_keys => sorted_keys($payload),
        query_kind => $payload->{query_kind},
        aggregate_shapes => {
            classifications => ref($payload->{classifications}) || 'SCALAR',
            coverage_buckets => ref($payload->{coverage_buckets}) || 'SCALAR',
            families => ref($payload->{families}) || 'SCALAR',
            source_kinds => ref($payload->{source_kinds}) || 'SCALAR',
        },
        id_count_keys => sorted_keys($payload->{id_counts}),
        sample_count => scalar @{$payload->{sample_catalog_entries}},
        sample_entry_keys => sorted_keys($payload->{sample_catalog_entries}[0] || {}),
    };
}

sub project_examples_payload {
    my ($payload) = @_;

    return {
        payload_keys => sorted_keys($payload),
        query => $payload->{query},
        limit => $payload->{limit},
        returned_count => $payload->{returned_count},
        catalog_entry_keys => sorted_keys($payload->{catalog_entries}[0] || {}),
        embedded_support_summary_sample_count => scalar @{$payload->{support_summary}{sample_catalog_entries}},
    };
}

sub project_diagnostic_payload {
    my ($payload) = @_;

    return {
        payload_keys => sorted_keys($payload),
        code => $payload->{code},
        diagnostic_keys => sorted_keys($payload->{diagnostic}),
        registry_contract_keys => sorted_keys($payload->{registry_contract}),
        support_example_count => scalar @{$payload->{support_examples}},
        support_example_keys => sorted_keys($payload->{support_examples}[0] || {}),
    };
}

sub project_source_payload {
    my ($payload) = @_;

    return {
        payload_keys => sorted_keys($payload),
        source_id => $payload->{source_id},
        query_kind => $payload->{query_kind},
        adapter_provenance => {
            contract_source => $payload->{adapter_provenance}{contract_source},
            transport => $payload->{adapter_provenance}{transport},
            read_only => json_bool($payload->{adapter_provenance}{read_only}),
            shell_access => json_bool($payload->{adapter_provenance}{shell_access}),
            workspace_root_policy => $payload->{adapter_provenance}{workspace_root_policy},
            source_identity => $payload->{adapter_provenance}{source_identity},
            command_shape => $payload->{adapter_provenance}{command_shape},
        },
        path_sanitization_keys => sorted_keys($payload->{path_sanitization}),
        report_keys => sorted_keys($payload->{report}),
    };
}

sub sorted_keys {
    my ($value) = @_;
    return [sort keys %{$value || {}}];
}

sub json_bool {
    my ($value) = @_;
    return $value ? JSON::PP::true : JSON::PP::false;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}
