#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use IO::File;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo_root,
    workspace_root => $repo_root,
);

subtest 'batch arrays are rejected as unsupported single-request envelopes' => sub {
    my $response = $adapter->handle_jsonrpc_request([
        {
            jsonrpc => '2.0',
            id => 1,
            method => 'tools/list',
        },
    ]);

    is($response->{jsonrpc}, '2.0', 'error response is JSON-RPC 2.0');
    is($response->{id}, undef, 'non-object envelope has null response id');
    is($response->{error}{code}, -32600, 'batch array maps to Invalid Request');
    like($response->{error}{message}, qr/batch arrays/, 'error explains batch arrays are unsupported');
};

subtest 'non-object envelopes are rejected without executing adapter methods' => sub {
    for my $envelope ('plain string', JSON::PP::true, undef) {
        my $response = $adapter->handle_jsonrpc_request($envelope);
        is($response->{error}{code}, -32600, 'non-object envelope maps to Invalid Request');
        like($response->{error}{message}, qr/non-object envelopes/, 'non-object error is explicit');
    }
};

subtest 'stdio reports unsupported batch envelopes as invalid requests, not parse errors' => sub {
    my $input = encode_json([
        {
            jsonrpc => '2.0',
            id => 2,
            method => 'ping',
        },
    ]) . "\n";
    open my $in, '<', \$input or die "open input scalar: $!";
    open my $out, '>', \my $output or die "open output scalar: $!";

    $adapter->run_stdio(in => $in, out => $out);

    my @lines = grep { length } split /\n/, $output;
    is(scalar @lines, 1, 'batch envelope emits one error response line');
    my $decoded = decode_json($lines[0]);
    is($decoded->{error}{code}, -32600, 'stdio batch envelope is an invalid request');
    like($decoded->{error}{message}, qr/single request object/, 'stdio error describes single-object contract');
};

done_testing();
