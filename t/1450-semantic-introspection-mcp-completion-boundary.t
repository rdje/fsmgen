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

subtest 'completion capability is not advertised in the shipped profile' => sub {
    my $initialize = $adapter->initialize_result({
        protocolVersion => '2025-06-18',
    });

    ok(!$initialize->{capabilities}{completions}, 'server does not advertise completions capability');
    ok($initialize->{capabilities}{resources}, 'server still advertises resources');
    ok($initialize->{capabilities}{tools}, 'server still advertises tools');
};

subtest 'completion/complete remains unsupported until candidate-provider selection' => sub {
    my $response = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 71,
        method => 'completion/complete',
        params => {
            ref => {
                type => 'ref/resource',
                uri => 'fsmgen://source/{source_id}/semantic',
            },
            argument => {
                name => 'source_id',
                value => 'ppif/',
            },
        },
    });

    is($response->{error}{code}, -32601, 'completion/complete maps to Method Not Found');
    like($response->{error}{message}, qr/Unsupported JSON-RPC method/, 'completion failure is explicit');
};

done_testing();
