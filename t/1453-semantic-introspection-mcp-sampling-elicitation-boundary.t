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

subtest 'client sampling and elicitation capabilities do not widen the server profile' => sub {
    my $initialize = $adapter->initialize_result({
        protocolVersion => '2025-06-18',
        capabilities => {
            sampling => {},
            elicitation => {},
        },
    });

    ok(!$initialize->{capabilities}{sampling}, 'server does not advertise sampling');
    ok(!$initialize->{capabilities}{elicitation}, 'server does not advertise elicitation');
    ok($initialize->{capabilities}{resources}, 'resources remain advertised');
    ok($initialize->{capabilities}{tools}, 'tools remain advertised');
};

subtest 'sampling and elicitation requests remain unsupported server methods' => sub {
    my @methods = qw(sampling/createMessage elicitation/create);

    for my $method (@methods) {
        my $response = $adapter->handle_jsonrpc_request({
            jsonrpc => '2.0',
            id => 101,
            method => $method,
            params => {},
        });

        is($response->{error}{code}, -32601, "$method maps to Method Not Found");
        like(
            $response->{error}{message},
            qr/Unsupported JSON-RPC method/,
            "$method failure is explicit",
        );
    }
};

done_testing();
