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

subtest 'list responses remain bounded and unpaginated' => sub {
    my @cases = (
        ['resources/list', 'resources', $adapter->list_resources()],
        ['resources/templates/list', 'resourceTemplates', $adapter->list_resource_templates()],
        ['tools/list', 'tools', $adapter->list_tools()],
    );

    for my $case (@cases) {
        my ($method, $field, $response) = @{$case};
        ok($response->{$field}, "$method returns $field");
        cmp_ok(scalar @{$response->{$field}}, '>=', 1, "$method returns at least one entry");
        cmp_ok(scalar @{$response->{$field}}, '<=', 25, "$method stays within the bounded list profile");
        ok(!exists $response->{nextCursor}, "$method does not emit nextCursor");
    }
};

subtest 'unissued cursors are invalid for bounded unpaginated list methods' => sub {
    for my $method (qw(resources/list resources/templates/list tools/list)) {
        my $response = $adapter->handle_jsonrpc_request({
            jsonrpc => '2.0',
            id => 91,
            method => $method,
            params => {
                cursor => 'client-supplied-unissued-cursor',
            },
        });

        is($response->{error}{code}, -32602, "$method cursor maps to Invalid params");
        like(
            $response->{error}{message},
            qr/cursor pagination is not supported/,
            "$method cursor failure names the pagination boundary",
        );
    }
};

subtest 'prompt listing does not become a hidden paginated surface' => sub {
    my $response = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 92,
        method => 'prompts/list',
        params => {
            cursor => 'prompt-cursor',
        },
    });

    is($response->{error}{code}, -32601, 'prompts/list remains unsupported');
    like($response->{error}{message}, qr/Unsupported JSON-RPC method/, 'prompt list failure is explicit');
};

done_testing();
