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
my $ppif_root = File::Spec->catdir($repo_root, 'ppif');

my @runner_commands;
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo_root,
    workspace_root => $ppif_root,
    runner => sub {
        my ($command) = @_;
        push @runner_commands, [@{$command}];
        return {
            runner => 'stub',
            ok => JSON::PP::true,
            source => {
                resolved_path => $command->[-1],
            },
        };
    },
);

subtest 'client roots capability does not replace explicit workspace-root authority' => sub {
    my $initialize = $adapter->initialize_result({
        protocolVersion => '2025-06-18',
        capabilities => {
            roots => {
                listChanged => JSON::PP::true,
            },
        },
    });

    ok($initialize->{capabilities}{resources}, 'server still advertises read-only resources');
    ok($initialize->{capabilities}{tools}, 'server still advertises read-only tools');
    ok(!$initialize->{capabilities}{roots}, 'server does not advertise roots as a server capability');
    ok(!$initialize->{capabilities}{prompts}, 'server does not advertise prompt templates in this phase');
    ok(!$initialize->{capabilities}{sampling}, 'server does not advertise sampling in this phase');

    my $payload = decode_tool_json($adapter->call_tool('fsmgen_check', {
        source_path => 'axi_aw_valid_ready.ppif',
    }));
    is($payload->{source_id}, 'axi_aw_valid_ready.ppif', 'source id is relative to configured workspace root');
    is($payload->{adapter_provenance}{workspace_root_policy}, 'caller_configured_root_not_returned', 'workspace root remains caller configured');
    is(scalar @runner_commands, 1, 'workspace-contained source invokes runner once');
};

subtest 'roots/list is not a server-side method and source escapes remain blocked' => sub {
    my $roots_response = $adapter->handle_jsonrpc_request({
        jsonrpc => '2.0',
        id => 41,
        method => 'roots/list',
    });
    is($roots_response->{error}{code}, -32601, 'client roots/list request is not a server method');
    like($roots_response->{error}{message}, qr/Unsupported JSON-RPC method/, 'unsupported roots/list is explicit');

    @runner_commands = ();
    my $ok = eval {
        $adapter->call_tool('fsmgen_check', {
            source_path => '../README.md',
        });
        1;
    };
    ok(!$ok, 'source outside configured workspace root is rejected');
    like($@, qr/escapes workspace root/, 'escape error names workspace-root violation');
    is(scalar @runner_commands, 0, 'escape rejection happens before runner invocation');
};

done_testing();

sub decode_tool_json {
    my ($response) = @_;
    return decode_json($response->{content}[0]{text});
}
