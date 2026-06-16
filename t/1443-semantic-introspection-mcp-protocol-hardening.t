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
            argv => [@{$command}],
            source => {
                resolved_path => $command->[-1],
            },
        };
    },
);

subtest 'JSON-RPC compatibility errors use protocol-level codes' => sub {
    my $bad_version = $adapter->handle_jsonrpc_request({
        jsonrpc => '1.0',
        id => 21,
        method => 'tools/list',
    });
    is($bad_version->{error}{code}, -32600, 'invalid JSON-RPC version maps to Invalid Request');
    like($bad_version->{error}{message}, qr/expected 2\.0/, 'invalid version message is explicit');

    my $missing_method = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 22,
    });
    is($missing_method->{error}{code}, -32600, 'missing method maps to Invalid Request');

    my $unknown_method = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 23,
        method => 'completion/complete',
    });
    is($unknown_method->{error}{code}, -32601, 'unknown method maps to Method Not Found');
    like($unknown_method->{error}{message}, qr/Unsupported JSON-RPC method/, 'unknown method message names the method family');
    unlike($unknown_method->{error}{message}, qr/\Q$repo_root\E/, 'unknown method error does not leak local repo root');

    my $notification = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        method => 'notifications/initialized',
    });
    is($notification, undef, 'notifications without an id do not emit a response');
};

subtest 'resource URI source ids reject malformed percent encoding' => sub {
    my $response = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 24,
        method => 'resources/read',
        params => {
            uri => 'fsmgen://source/ppif%GGaxi_aw_valid_ready.ppif/check',
        },
    });

    is($response->{error}{code}, -32000, 'malformed resource URI is an adapter-level call error');
    like($response->{error}{message}, qr/Invalid percent encoding/, 'malformed percent escape is rejected explicitly');
    unlike($response->{error}{message}, qr/\Q$repo_root\E/, 'malformed URI error does not leak local repo root');
};

subtest 'source query envelopes expose provenance without leaking workspace roots' => sub {
    my $response = $adapter->call_tool('fsmgen_semantic_introspect', {
        source_path => 'ppif/axi_aw_valid_ready.ppif',
    });
    my $payload = decode_json($response->{content}[0]{text});

    is(
        $payload->{adapter_provenance}{contract_source},
        'FSM::Support::SemanticIntrospectionMCPAdapter',
        'source query payload records adapter contract source',
    );
    is($payload->{adapter_provenance}{transport}, 'jsonrpc_stdio', 'source query records transport family');
    ok($payload->{adapter_provenance}{read_only}, 'source query records read-only policy');
    ok(!$payload->{adapter_provenance}{shell_access}, 'source query records no-shell policy');
    is(
        $payload->{adapter_provenance}{workspace_root_policy},
        'caller_configured_root_not_returned',
        'source query does not return the workspace root',
    );
    is(
        $payload->{adapter_provenance}{command_shape},
        'bin/fsmgen --strict --emit-semantic-json <source>',
        'source query records sanitized command shape',
    );
    is(
        $payload->{report}{source}{resolved_path},
        'ppif/axi_aw_valid_ready.ppif',
        'source-bound report path is workspace-relative',
    );

    my $text = $response->{content}[0]{text};
    unlike($text, qr/\Q$repo_root\E/, 'source query response does not include the machine-local repo root');
};

done_testing();
