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
my @runner_commands;
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo_root,
    workspace_root => $repo_root,
    runner => sub {
        my ($command) = @_;
        push @runner_commands, [@{$command}];
        return {
            runner => 'stub',
            argv => [@{$command}],
            ok => JSON::PP::true,
        };
    },
);

subtest 'adapter initializes and discovers read-only resource and tool families' => sub {
    my $initialize = $adapter->initialize_result({ protocolVersion => 'test-protocol' });
    is($initialize->{protocolVersion}, '2025-06-18', 'initialize reports supported protocol version');
    is($initialize->{serverInfo}{name}, 'fsmgen-semantic-introspection', 'server identity is stable');
    ok($initialize->{capabilities}{resources}, 'resources capability is advertised');
    ok($initialize->{capabilities}{tools}, 'tools capability is advertised');

    my $resources = $adapter->list_resources()->{resources};
    my %resource_uri = map { $_->{uri} => $_ } @{$resources};
    ok($resource_uri{'fsmgen://capabilities'}, 'capability manifest resource is listed');
    ok($resource_uri{'fsmgen://contracts'}, 'contract resource is listed');
    ok($resource_uri{'fsmgen://examples'}, 'examples resource is listed');
    ok($resource_uri{'fsmgen://sources'}, 'source discovery resource is listed');

    my $templates = $adapter->list_resource_templates()->{resourceTemplates};
    my %template_uri = map { $_->{uriTemplate} => $_ } @{$templates};
    ok($template_uri{'fsmgen://sources'}, 'source discovery template is listed');
    ok($template_uri{'fsmgen://source/{source_id}/semantic'}, 'source semantic template is listed');
    ok($template_uri{'fsmgen://source/{source_id}/schedule'}, 'source schedule template is listed');

    my $tools = $adapter->list_tools()->{tools};
    my %tool = map { $_->{name} => $_ } @{$tools};
    ok($tool{fsmgen_capability_query}, 'capability query tool is listed');
    ok($tool{fsmgen_semantic_introspect}, 'semantic introspection tool is listed');
    ok($tool{fsmgen_schedule_preview}, 'schedule preview tool is listed');
    ok($tool{fsmgen_discover_sources}, 'source discovery tool is listed');
    ok($tool{fsmgen_explain_diagnostic}, 'diagnostic explanation tool is listed');

    for my $name (keys %tool) {
        unlike($name, qr/(?:generate|write|commit|push|shell|network)/, "$name is not a write, shell, network, commit, or push tool");
    }
};

subtest 'adapter exposes manifest-backed contract resources without raw source mutation' => sub {
    my $capabilities = decode_resource_json($adapter->read_resource('fsmgen://capabilities'));
    ok($capabilities->{semantic_introspection}, 'capability resource includes semantic_introspection');
    ok($capabilities->{semantic_introspection}{mcp_adapter_implemented}, 'manifest reports read-only MCP adapter implemented');
    ok(!$capabilities->{semantic_introspection}{write_generation_tools_enabled}, 'manifest keeps write/generation tools disabled');

    my $contracts = decode_resource_json($adapter->read_resource('fsmgen://contracts'));
    is(
        $contracts->{semantic_introspection}{contract_surface_map}{mcp_adapter}{contract_source},
        'FSM::Support::SemanticIntrospectionMCPAdapter',
        'contract resource names the adapter implementation owner',
    );

    my $tool_payload = decode_tool_json($adapter->call_tool('fsmgen_capability_query', { section => 'semantic_introspection' }));
    is($tool_payload->{section}, 'semantic_introspection', 'capability query returns requested manifest section');
    ok($tool_payload->{payload}{mcp_adapter_implemented}, 'tool payload reports implemented adapter');
    ok(!$tool_payload->{payload}{write_generation_tools_enabled}, 'tool payload keeps write/generation tools disabled');
};

subtest 'source-bound tools use fixed FSMGen argv and workspace-contained source identity' => sub {
    @runner_commands = ();

    my $source = 'ppif/axi_aw_valid_ready.ppif';
    my $check = decode_tool_json($adapter->call_tool('fsmgen_check', { source_path => $source }));
    is($check->{source_id}, $source, 'check preserves repo-relative source identity');
    is($check->{query_kind}, 'check', 'check query kind is recorded');
    is($check->{report}{runner}, 'stub', 'check result comes from injected runner');
    is(
        $check->{path_sanitization}{machine_local_absolute_paths},
        'workspace_or_repo_absolute_paths_return_relative_else_redacted',
        'source query records path-sanitization policy',
    );
    is($check->{report}{argv}[0], 'bin/fsmgen', 'report payload sanitizes repo-local executable path');
    is($check->{report}{argv}[4], $source, 'report payload sanitizes workspace-local source path');
    is_deeply(
        [@{$runner_commands[-1]}[1 .. 3]],
        ['--strict', '--check', '--json'],
        'check tool uses the fixed strict check-json argv',
    );
    like($runner_commands[-1][0], qr{/bin/fsmgen\z}, 'check argv uses repo-local fsmgen entrypoint');

    my $semantic = decode_tool_json($adapter->call_tool('fsmgen_semantic_introspect', { source_id => $source }));
    is($semantic->{query_kind}, 'semantic', 'semantic query kind is recorded');
    is_deeply(
        [@{$runner_commands[-1]}[1 .. 2]],
        ['--strict', '--emit-semantic-json'],
        'semantic tool uses the fixed normalized-semantic argv',
    );

    my $schedule = decode_resource_json($adapter->read_resource('fsmgen://source/ppif%2Faxi_aw_valid_ready.ppif/schedule'));
    is($schedule->{query_kind}, 'schedule', 'source schedule resource dispatches to schedule query');
    is_deeply(
        [@{$runner_commands[-1]}[1 .. 1]],
        ['--emit-schedule-json'],
        'schedule resource uses the fixed schedule-json argv',
    );
};

subtest 'adapter rejects workspace escape attempts before running FSMGen' => sub {
    my $ppif_root = File::Spec->catdir($repo_root, 'ppif');
    my @escape_commands;
    my $ppif_adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $repo_root,
        workspace_root => $ppif_root,
        runner => sub {
            my ($command) = @_;
            push @escape_commands, [@{$command}];
            return { should_not_run => JSON::PP::true };
        },
    );

    my $ok = eval {
        $ppif_adapter->call_tool('fsmgen_check', { source_path => '../README.md' });
        1;
    };
    ok(!$ok, 'workspace escape is rejected');
    like($@, qr/escapes workspace root/, 'escape error explains workspace-root violation');
    is(scalar @escape_commands, 0, 'escape rejection happens before invoking runner');
};

subtest 'JSON-RPC dispatcher maps adapter calls and errors predictably' => sub {
    my $response = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 11,
        method => 'tools/list',
    });
    is($response->{jsonrpc}, '2.0', 'JSON-RPC response version is stable');
    is($response->{id}, 11, 'JSON-RPC response id is preserved');
    ok($response->{result}{tools}, 'tools/list returns tools');

    my $error = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 12,
        method => 'tools/call',
        params => {
            name => 'fsmgen_write_generation',
            arguments => {},
        },
    });
    is($error->{error}{code}, -32000, 'unsupported tool maps to adapter error code');
    like($error->{error}{message}, qr/Unsupported MCP tool/, 'unsupported tool error names the problem');
};

done_testing();

sub decode_resource_json {
    my ($response) = @_;
    return decode_json($response->{contents}[0]{text});
}

sub decode_tool_json {
    my ($response) = @_;
    return decode_json($response->{content}[0]{text});
}
