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

subtest 'resource capability remains static and non-subscription based' => sub {
    my $initialize = $adapter->initialize_result({
        protocolVersion => '2025-06-18',
    });

    ok($initialize->{capabilities}{resources}, 'server advertises resources');
    ok(!$initialize->{capabilities}{resources}{listChanged}, 'resource listChanged remains false');
    ok(!exists $initialize->{capabilities}{resources}{subscribe}, 'resource subscriptions are not advertised');

    my $resources = $adapter->list_resources();
    ok(@{$resources->{resources}} >= 1, 'static resource listing is available');
    ok(!exists $resources->{nextCursor}, 'resource listing is not paginated in this bounded profile');
};

subtest 'resource subscription protocol methods are not server methods yet' => sub {
    for my $method (qw(resources/subscribe resources/unsubscribe)) {
        my $response = $adapter->handle_jsonrpc_request({
            jsonrpc => '2.0',
            id => 61,
            method => $method,
            params => {
                uri => 'fsmgen://capabilities',
            },
        });

        is($response->{error}{code}, -32601, "$method maps to Method Not Found");
        like($response->{error}{message}, qr/Unsupported JSON-RPC method/, "$method failure is explicit");
    }
};

done_testing();
