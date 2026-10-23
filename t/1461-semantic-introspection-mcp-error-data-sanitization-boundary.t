#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use JSON::PP ();
use Storable qw(dclone);

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

for my $context ('no record', 'line record', 'chunk record') {
    subtest "public reasons survive native $context locations" => sub {
        my $input = "first\nsecond\n";
        open my $record_input, '<', \$input or die $!;
        local $/ = $context eq 'chunk record' ? undef : "\n";
        my $read = <$record_input> unless $context eq 'no record';
        my @messages = (
            ["Callback rejected operator '/'", "Callback rejected operator '/'"],
            ["Authored diagnostic at design.isf line 17.\n", 'Authored diagnostic at design.isf line 17.'],
            ['Authored diagnostic at design.isf line 17.', 'Authored diagnostic at design.isf line 17.'],
            ["First line\nSource at design.fsm line 8.\n", "First line\nSource at design.fsm line 8."],
            ["Reason at fake.pm line 17, <pretend> chunk 9.\n", 'Reason at fake.pm line 17, <pretend> chunk 9.'],
            ["Reason at $0 line 99; operator '/' rejected\n", "Reason at $0 line 99; operator '/' rejected"],
            ["Reason at $0 line 99, <pretend> line 5. operator '/' rejected",
             "Reason at $0 line 99, <pretend> line 5. operator '/' rejected"],
            ["Unsupported expression operator '/' at 'design.isf:17'\n",
             "Unsupported expression operator '/' at 'design.isf:17'"],
            ["operator '/' while opening '/outside/private dir/source.fsm'\n",
             "operator '/' while opening '[absolute-path-redacted]'"],
            ["0\n", '0'],
            ["\n", 'FSMGen MCP adapter error'],
            ["\x00\n", 'FSMGen MCP adapter error'],
            [('x' x 2200), ('x' x (2048 - length(' [truncated]'))) . ' [truncated]'],
            [('é' x 2200), ('é' x (2048 - length(' [truncated]'))) . ' [truncated]'],
        );
        my $json = JSON::PP->new->canonical->ascii;
        for my $i (0 .. $#messages) {
            my ($message, $expected) = @{$messages[$i]};
            my $throwing = FSM::Support::SemanticIntrospectionMCPAdapter->new(
                repo_root => $repo_root, workspace_root => $repo_root,
                runner => sub { die $message });
            my $request = {jsonrpc => '2.0', id => $i, method => 'tools/call', params => {
                name => 'fsmgen_check', arguments => {source_id => 'fsm/ahb_lite_subordinate.fsm'}}};
            my $before = $json->encode(dclone($request));
            is_deeply($throwing->handle_jsonrpc_request($request), {
                jsonrpc => '2.0', id => $i, error => {code => -32000, message => $expected}},
                "case $i preserves complete message-only error");
            is($json->encode(dclone($request)), $before, "case $i caller copy preserves");
        }
        my $missing = $adapter->handle_jsonrpc_request({jsonrpc => '2.0', id => 100,
            method => 'tools/call', params => {name => 'fsmgen_check', arguments => {}}});
        is_deeply($missing, {jsonrpc => '2.0', id => 100, error => {code => -32602,
            message => 'Invalid params: source_path or source_id is required'}},
            'native adapter refusal retains exact public reason and class');
        close $record_input or die $!;
    };
}

done_testing();
