#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo_root,
    workspace_root => $repo_root,
);

subtest 'JSON-RPC errors remain message-only until error data schema is selected' => sub {
    for my $case (
        [
            'method-not-found',
            {
                jsonrpc => '2.0',
                id => 1,
                method => 'unknown/method',
            },
            -32601,
        ],
        [
            'invalid params',
            {
                jsonrpc => '2.0',
                id => 2,
                method => 'tools/list',
                params => {
                    cursor => 'client-made-cursor',
                },
            },
            -32602,
        ],
        [
            'unsupported envelope',
            [],
            -32600,
        ],
        [
            'adapter failure',
            {
                jsonrpc => '2.0',
                id => 3,
                method => 'resources/read',
                params => {
                    uri => 'fsmgen://source/ppif%GGbad/check',
                },
            },
            -32000,
        ],
    ) {
        my ($label, $request, $code) = @{$case};
        my $response = $adapter->handle_jsonrpc_request($request);

        is($response->{error}{code}, $code, "$label has expected error code");
        ok(length($response->{error}{message} || ''), "$label has a message");
        ok(!exists $response->{error}{data}, "$label has no error.data yet");
        unlike($response->{error}{message}, qr/\Q$repo_root\E/, "$label message redacts repo root");
        unlike($response->{error}{message}, qr/\bat .* line \d+\b/, "$label message strips Perl location");
    }
};

done_testing();
