#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json encode_json);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'fsmgen-mcp lists read-only semantic-introspection tools through one-shot JSON-RPC' => sub {
    my $response = run_mcp_request({
        jsonrpc => '2.0',
        id => 1,
        method => 'tools/list',
    });

    is($response->{jsonrpc}, '2.0', 'response is JSON-RPC 2.0');
    is($response->{id}, 1, 'response id is preserved');

    my %tool = map { $_->{name} => $_ } @{$response->{result}{tools}};
    ok($tool{fsmgen_capability_query}, 'capability query tool is listed');
    ok($tool{fsmgen_semantic_introspect}, 'semantic introspection tool is listed');
    ok($tool{fsmgen_schedule_preview}, 'schedule preview tool is listed');
    ok(!$tool{fsmgen_write_generation}, 'write/generation tool is not listed');
};

subtest 'fsmgen-mcp reads the capability resource and reports shipped adapter policy' => sub {
    my $response = run_mcp_request({
        jsonrpc => '2.0',
        id => 2,
        method => 'resources/read',
        params => {
            uri => 'fsmgen://capabilities',
        },
    });

    my $manifest = decode_json($response->{result}{contents}[0]{text});
    ok($manifest->{semantic_introspection}{mcp_adapter_implemented}, 'capability resource reports read-only MCP adapter implemented');
    ok(!$manifest->{semantic_introspection}{write_generation_tools_enabled}, 'capability resource keeps write/generation tools disabled');
};

subtest 'fsmgen-mcp capability query tool returns the semantic-introspection section' => sub {
    my $response = run_mcp_request({
        jsonrpc => '2.0',
        id => 3,
        method => 'tools/call',
        params => {
            name => 'fsmgen_capability_query',
            arguments => {
                section => 'semantic_introspection',
            },
        },
    });

    my $payload = decode_json($response->{result}{content}[0]{text});
    is($payload->{section}, 'semantic_introspection', 'tool returns the requested manifest section');
    is(
        $payload->{payload}{contract_surface_map}{mcp_adapter}{contract_source},
        'FSM::Support::SemanticIntrospectionMCPAdapter',
        'tool payload names the MCP adapter implementation owner',
    );
};

done_testing();

sub run_mcp_request {
    my ($request) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            $^X,
            File::Spec->catfile($repo_root, 'bin', 'fsmgen-mcp'),
            '--workspace-root',
            $repo_root,
            '--request-json',
            encode_json($request),
        ],
    );

    ok($success, "$request->{method} request succeeds");
    is(join('', @{$stderr_buf || []}), '', "$request->{method} keeps stderr clean");

    my $stdout = join('', @{$stdout_buf || []});
    ok(length $stdout, "$request->{method} emits a response");
    return decode_json($stdout);
}
