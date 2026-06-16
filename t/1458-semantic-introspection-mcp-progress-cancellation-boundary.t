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
);

subtest 'progress tokens do not create progress notifications in the one-shot profile' => sub {
    my $response = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 1,
        method => 'tools/list',
        params => {
            _meta => {
                progressToken => 'progress-token-1',
            },
        },
    });

    is($response->{jsonrpc}, '2.0', 'request still returns a normal JSON-RPC response');
    is($response->{id}, 1, 'response id is preserved');
    ok($response->{result}{tools}, 'tools/list still returns the tool list');
    ok(!exists $response->{result}{_meta}, 'result carries no progress metadata');
    ok(!exists $response->{result}{progress}, 'result carries no progress shortcut');
};

subtest 'tool calls with progress metadata remain ordinary read-only calls' => sub {
    my $response = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 2,
        method => 'tools/call',
        params => {
            _meta => {
                progressToken => 2,
            },
            name => 'fsmgen_capability_query',
            arguments => {
                section => 'semantic_introspection',
            },
        },
    });
    my $payload = decode_json($response->{result}{content}[0]{text});

    ok(!$response->{result}{isError}, 'tool call remains successful');
    is($payload->{section}, 'semantic_introspection', 'tool payload remains unchanged');
    ok(!exists $response->{result}{_meta}, 'tool result emits no progress metadata');
};

subtest 'cancelled notifications are silent while id-bearing requests stay unsupported' => sub {
    my $notification = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        method => 'notifications/cancelled',
        params => {
            requestId => 2,
            reason => 'client no longer needs the result',
        },
    });
    is($notification, undef, 'id-less cancelled notification emits no response');

    my $request = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 3,
        method => 'notifications/cancelled',
        params => {
            requestId => 2,
        },
    });
    is($request->{error}{code}, -32601, 'id-bearing cancelled method is not supported');
    like(
        $request->{error}{message},
        qr/Unsupported JSON-RPC method: notifications\/cancelled/,
        'unsupported cancellation request is explicit',
    );
};

done_testing();
