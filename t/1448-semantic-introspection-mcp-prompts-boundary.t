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

subtest 'prompt templates are not advertised in the shipped read-only profile' => sub {
    my $initialize = $adapter->initialize_result({
        protocolVersion => '2025-06-18',
    });

    ok(!$initialize->{capabilities}{prompts}, 'server does not advertise prompts capability');
    ok($initialize->{capabilities}{resources}, 'server still advertises resources');
    ok($initialize->{capabilities}{tools}, 'server still advertises tools');

    my @tool_names = map { $_->{name} } @{$adapter->list_tools()->{tools}};
    for my $name (@tool_names) {
        unlike($name, qr/prompt/i, "$name is not a prompt-shaped tool");
    }
};

subtest 'prompt protocol methods remain unsupported until prompt contract selection' => sub {
    my $list = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 51,
        method => 'prompts/list',
    });
    is($list->{error}{code}, -32601, 'prompts/list maps to Method Not Found');
    like($list->{error}{message}, qr/Unsupported JSON-RPC method/, 'prompts/list failure is explicit');

    my $get = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 52,
        method => 'prompts/get',
        params => {
            name => 'fsmgen_diagnostic_triage',
        },
    });
    is($get->{error}{code}, -32601, 'prompts/get maps to Method Not Found');
    like($get->{error}{message}, qr/Unsupported JSON-RPC method/, 'prompts/get failure is explicit');
};

done_testing();
