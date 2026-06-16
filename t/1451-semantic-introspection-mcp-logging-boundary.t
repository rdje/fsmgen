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

subtest 'logging capability is not advertised in the shipped profile' => sub {
    my $initialize = $adapter->initialize_result({
        protocolVersion => '2025-06-18',
    });

    ok(!$initialize->{capabilities}{logging}, 'server does not advertise logging capability');
    ok($initialize->{capabilities}{resources}, 'server still advertises resources');
    ok($initialize->{capabilities}{tools}, 'server still advertises tools');
};

subtest 'logging protocol methods remain unsupported until logging contract selection' => sub {
    my $response = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 81,
        method => 'logging/setLevel',
        params => {
            level => 'info',
        },
    });

    is($response->{error}{code}, -32601, 'logging/setLevel maps to Method Not Found');
    like($response->{error}{message}, qr/Unsupported JSON-RPC method/, 'logging failure is explicit');
};

done_testing();
