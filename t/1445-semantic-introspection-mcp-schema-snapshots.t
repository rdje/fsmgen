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
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SupportAccountingContract qw(
    support_accounting_catalog_entry_optional_keys
    support_accounting_catalog_entry_required_keys
);

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

subtest 'support sample schema accepts both real optional-field variants in either order' => sub {
    ok(scalar(grep { $_ eq 'diagnostic_code' } @{support_accounting_catalog_entry_optional_keys()}),
        'the public catalog contract declares diagnostic_code optional');
    my $manifest = build_capability_manifest();
    my $entries = $manifest->{support_accounting}{catalog_entries};
    my ($diagnostic) = grep { exists $_->{diagnostic_code} } @$entries;
    my ($ordinary) = grep { !exists $_->{diagnostic_code} } @$entries;
    ok($diagnostic && $ordinary, 'real catalog supplies both entry variants') or return;
    my $expected = decode_json(slurp(File::Spec->catfile($repo_root, 't', 'fixtures',
        'semantic_introspection_mcp', 'read_only_schema_snapshot.json')))
        ->{tool_envelopes}{support_summary}{decoded_payload};
    my @common = qw(classification coverage family id relpath source_kind strict_supported);
    my $json = JSON::PP->new->canonical;
    my $before = $json->encode($manifest);

    for my $first ([$diagnostic, $ordinary], [$ordinary, $diagnostic]) {
        my %selected = map { $_->{id} => 1 } @$first;
        my @ordered = (@$first, grep { !$selected{$_->{id}} } @$entries);
        is(scalar(@ordered), scalar(@$entries), 'reordering preserves complete catalog membership');
        my $variant = {%$manifest, support_accounting => {
            %{$manifest->{support_accounting}}, catalog_entries => \@ordered,
        }};
        my $client = FSM::Support::SemanticIntrospectionMCPAdapter->new(
            repo_root => $repo_root, workspace_root => $repo_root, manifest_builder => sub { $variant });
        my $result = $client->call_tool('fsmgen_support_summary', {limit_examples => 2});
        my $payload = $result->{structuredContent};
        is($json->encode(decode_json($result->{content}[0]{text})), $json->encode($payload),
            'complete text and structured payloads retain identical values');
        for my $index (0, 1) {
            my $source = $first->[$index];
            my %wanted = map { $_ => $source->{$_} } @common;
            $wanted{diagnostic_code} = $source->{diagnostic_code} if exists $source->{diagnostic_code};
            is_deeply($payload->{sample_catalog_entries}[$index], \%wanted,
                'actual sample preserves common values and exactly the applicable optional code');
        }
        is_deeply(project_support_summary_payload($payload), $expected,
            'snapshot schema is independent of the first real entry variant');
        my $examples = $client->call_tool('fsmgen_find_examples', {limit => 2});
        is_deeply($examples->{structuredContent}{catalog_entries}, $first,
            'examples preserve selected full public catalog records rather than compact samples');
        is_deeply($examples->{structuredContent}{support_summary}{sample_catalog_entries}, [],
            'the examples query embeds support aggregates without catalog samples');
        is($json->encode(decode_json($examples->{content}[0]{text})),
            $json->encode($examples->{structuredContent}), 'full examples survive both result forms');
        for my $mutation ('missing_common', 'unknown_field') {
            my $bad = {%$payload, sample_catalog_entries => [
                {%{$payload->{sample_catalog_entries}[0]}}, $payload->{sample_catalog_entries}[1],
            ]};
            if ($mutation eq 'missing_common') {
                delete $bad->{sample_catalog_entries}[0]{family};
            } else {
                $bad->{sample_catalog_entries}[0]{unpublished_field} = 'counterfeit';
            }
            isnt($json->encode(project_support_summary_payload($bad)), $json->encode($expected),
                "$mutation remains distinguishable from the admitted snapshot");
        }
    }
    is($json->encode($manifest), $before, 'variant calls leave the original complete manifest unchanged');
};

subtest 'full example schema admits declared optional fields without depending on record order' => sub {
    my $manifest = build_capability_manifest();
    my $entries = $manifest->{support_accounting}{catalog_entries};
    my %by_id = map { $_->{id} => $_ } @$entries;
    my @selected = @by_id{qw(feature.composition_scalar_rtl_parameters
        contract.composition_top_parameters_lowering_pending intent.isf_apb_requester)};
    ok(!scalar(grep { !defined $_ } @selected), 'real catalog supplies all distinct optional-field variants')
        or return;
    my $json = JSON::PP->new->canonical;
    my $before = $json->encode($manifest);
    my $expected = decode_json(slurp(File::Spec->catfile($repo_root, 't', 'fixtures',
        'semantic_introspection_mcp', 'read_only_schema_snapshot.json')))
        ->{tool_envelopes}{examples}{decoded_payload};
    $expected = {%$expected, query => '', limit => 3, returned_count => 3};

    # Independently authored public record: in addition to the schema, guard
    # the newly leading example's complete values and numeric/Boolean kinds.
    is($json->encode($selected[0]), $json->encode({
        id => 'feature.composition_scalar_rtl_parameters',
        relpath => 't/corpus/composition_scalar_rtl_parameters.fsm',
        family => 'language_feature_fixture', classification => 'supported_smoke',
        coverage => 'composition_top_pipeline_cli', source_kind => 'composition',
        strict_supported => JSON::PP::true, expected_top_name => 'composition_scalar_rtl_parameters',
        expected_lane => 'C3', expected_instance_count => 1, expected_child_modules => [],
        expected_hdl_pattern_count => 4, has_expected_error_pattern => JSON::PP::false,
        has_expected_hint_pattern => JSON::PP::false,
    }), 'new leading composition record retains its full authored public values and JSON kinds');

    for my $first (\@selected, [reverse @selected]) {
        my %selected_ids = map { $_->{id} => 1 } @$first;
        my @ordered = (@$first, grep { !$selected_ids{$_->{id}} } @$entries);
        is(scalar(@ordered), scalar(@$entries), 'variant order preserves complete catalog membership');
        my $variant = {%$manifest, support_accounting => {
            %{$manifest->{support_accounting}}, catalog_entries => \@ordered,
        }};
        my $client = FSM::Support::SemanticIntrospectionMCPAdapter->new(
            repo_root => $repo_root, workspace_root => $repo_root, manifest_builder => sub { $variant });
        my $response = $client->call_tool('fsmgen_find_examples', {limit => 3});
        my $payload = $response->{structuredContent};
        is($json->encode($payload->{catalog_entries}), $json->encode($first),
            'every selected full record survives with exact values, order and JSON kinds');
        is($json->encode(decode_json($response->{content}[0]{text})), $json->encode($payload),
            'complete examples text and structured payloads agree');
        is_deeply(project_examples_payload($payload), $expected,
            'full catalog schema is independent of the leading optional-field variant');
        my $valid_json = $json->encode(project_examples_payload($payload));

        for my $index (0 .. $#$first) {
            for my $key (@{support_accounting_catalog_entry_required_keys()}, 'unpublished_field') {
                my $bad = decode_json($json->encode($payload));
                if ($key eq 'unpublished_field') {
                    $bad->{catalog_entries}[$index]{$key} = 'counterfeit';
                } else {
                    delete $bad->{catalog_entries}[$index]{$key};
                }
                isnt($json->encode(project_examples_payload($bad)), $valid_json,
                    "record $index changed required/unknown key $key remains distinguishable");
            }
            for my $key (@{support_accounting_catalog_entry_optional_keys()}) {
                next unless exists $first->[$index]{$key};
                my $variant_payload = decode_json($json->encode($payload));
                delete $variant_payload->{catalog_entries}[$index]{$key};
                is_deeply(project_examples_payload($variant_payload), $expected,
                    "record $index permits absent declared optional key $key");
            }
        }
    }
    is($json->encode($manifest), $before, 'schema variant calls leave the complete manifest unchanged');
};

subtest 'diagnostic discovery and bounded samples retain their public contract' => sub {
    my ($tool) = grep { $_->{name} eq 'fsmgen_explain_diagnostic' }
        @{$adapter->list_tools->{tools}};
    is(($tool->{inputSchema}{properties}{limit_examples} || {})->{type}, 'integer',
        'discovery advertises the existing integer sample limit');
    is_deeply($tool->{inputSchema}{required}, ['code'], 'only the diagnostic code is required');
    ok(!$tool->{inputSchema}{additionalProperties}, 'diagnostic arguments remain closed');

    my $manifest = build_capability_manifest();
    my $json = JSON::PP->new->canonical;
    my $before = $json->encode($manifest);
    my $code = 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE';
    my ($diagnostic) = grep { $_->{code} eq $code } @{$manifest->{diagnostics}{stable_codes}};
    # A controlled catalog is necessary: real per-code sample populations are
    # smaller than the cap. Keep genuine record identities/fields and order;
    # only their diagnostic association is counterfactual in this fixture.
    my @entries = map { +{%$_, diagnostic_code => $code} }
        @{$manifest->{support_accounting}{catalog_entries}}[0 .. 120];
    my $fixture = {%$manifest, support_accounting => {
        %{$manifest->{support_accounting}}, catalog_entries => \@entries,
    }};
    my $client = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $repo_root, workspace_root => $repo_root,
        manifest_builder => sub { $fixture });
    my @fields = qw(id relpath family classification coverage source_kind strict_supported diagnostic_code);
    for my $case ([undef, 10], [0, 10], [101, 100], [-1, 10], map { [$_, $_] } 1 .. 100) {
        my ($limit, $count) = @$case;
        my $arguments = {code => $code};
        $arguments->{limit_examples} = $limit if defined $limit;
        my $result = $client->call_tool('fsmgen_explain_diagnostic', $arguments);
        my @wanted = map { my $entry = $_; +{map { $_ => $entry->{$_} } @fields} }
            @entries[0 .. $count - 1];
        my $expected = {code => $code, diagnostic => $diagnostic,
            registry_contract => $manifest->{diagnostics}{stable_code_registry},
            support_examples => \@wanted};
        my $label = defined($limit) ? $limit : 'omitted';
        is($json->encode($result->{structuredContent}), $json->encode($expected),
            "$label preserves complete bounded records, order and JSON kinds");
        is($json->encode(decode_json($result->{content}[0]{text})), $json->encode($expected),
            "$label preserves the same complete text result");
        ok(!$result->{isError}, "$label is a successful metadata query");
    }
    is_deeply($client->call_tool('fsmgen_support_summary', {limit_examples => 0})
        ->{structuredContent}{sample_catalog_entries}, [], 'support-summary zero retains its distinct empty-sample policy');
    for my $arguments ({}, {code => 'UNKNOWN_DIAGNOSTIC_FIXTURE'}) {
        my $response = $client->handle_jsonrpc_request({jsonrpc => '2.0', id => 1,
            method => 'tools/call', params => {name => 'fsmgen_explain_diagnostic', arguments => $arguments}});
        is($response->{error}{code}, exists($arguments->{code}) ? -32000 : -32602,
            'missing required code is invalid params; unknown string code retains semantic refusal');
        like($response->{error}{message}, qr/(?:requires argument 'code'|Unknown FSMGen diagnostic code)/,
            'refusal retains the public reason');
    }
    is($json->encode($manifest), $before, 'counterfactual bounds checks do not mutate the actual manifest');
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
            source_discovery => project_tool_response(
                $adapter->call_tool('fsmgen_discover_sources', {
                    query => 'axi_aw',
                    file_kind => 'ppif',
                    limit => 2,
                }),
                \&project_sources_payload,
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
            vial_inspection => project_tool_response(
                $adapter->call_tool('fsmgen_vial_inspect', {
                    source_id => 'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial',
                    language_version => 2,
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
        server_title => $response->{serverInfo}{title},
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
            my $annotations = $_->{annotations} || {};
            {
                name => $_->{name},
                annotation_keys => sorted_keys($annotations),
                openWorldHint => json_bool($annotations->{openWorldHint}),
                readOnlyHint => json_bool($annotations->{readOnlyHint}),
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
        # This is a schema projection, not a freeze of which catalog entry is
        # first. Only this declared optional field is normalized; new unknown
        # fields and missing common fields still change the snapshot.
        sample_entry_keys => [grep { $_ ne 'diagnostic_code' }
            @{sorted_keys($payload->{sample_catalog_entries}[0] || {})}],
        sample_entry_optional_keys => ['diagnostic_code'],
    };
}

sub project_examples_payload {
    my ($payload) = @_;

    # Full records may have different declared optional fields. Pin their
    # vocabulary separately, preserving unknown keys and missing required keys
    # in every result position rather than treating the first record as schema.
    my %optional = map { $_ => 1 } @{support_accounting_catalog_entry_optional_keys()};
    my %keys;
    my @missing;
    for my $index (0 .. $#{$payload->{catalog_entries}}) {
        my $entry = $payload->{catalog_entries}[$index];
        $keys{$_} = 1 for grep { !$optional{$_} } keys %$entry;
        my @absent = sort grep { !exists $entry->{$_} }
            @{support_accounting_catalog_entry_required_keys()};
        push @missing, {index => $index, keys => \@absent} if @absent;
    }

    return {
        payload_keys => sorted_keys($payload),
        query => $payload->{query},
        limit => $payload->{limit},
        returned_count => $payload->{returned_count},
        catalog_entry_keys => [sort keys %keys],
        catalog_entry_optional_keys => [sort keys %optional],
        catalog_entry_missing_required_keys => \@missing,
        embedded_support_summary_sample_count => scalar @{$payload->{support_summary}{sample_catalog_entries}},
    };
}

sub project_sources_payload {
    my ($payload) = @_;

    return {
        payload_keys => sorted_keys($payload),
        query_kind => $payload->{query_kind},
        query => $payload->{query},
        limit => $payload->{limit},
        filter_keys => sorted_keys($payload->{filters}),
        path_policy_keys => sorted_keys($payload->{path_policy}),
        matched_count_type => defined($payload->{matched_count}) ? 'integer' : 'missing',
        returned_count => $payload->{returned_count},
        source_entry_keys => sorted_keys($payload->{sources}[0] || {}),
        first_source_file_kind => $payload->{sources}[0]{file_kind},
        first_source_query_kinds => $payload->{sources}[0]{available_query_kinds} || [],
        first_source_support_keys => sorted_keys($payload->{sources}[0]{support} || {}),
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
