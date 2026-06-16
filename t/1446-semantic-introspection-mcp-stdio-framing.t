#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo_root,
    workspace_root => $repo_root,
    runner => sub {
        return {
            runner => 'stub',
            ok => JSON::PP::true,
        };
    },
);

subtest 'stdio transport emits one compact JSON-RPC message per line' => sub {
    my $input = join(
        "\n",
        encode_json({
            jsonrpc => '2.0',
            id => 31,
            method => 'initialize',
            params => {
                protocolVersion => '2025-06-18',
            },
        }),
        encode_json({
            jsonrpc => '2.0',
            method => 'notifications/initialized',
        }),
        encode_json({
            jsonrpc => '2.0',
            id => 32,
            method => 'tools/list',
        }),
        '',
    );

    my $output = run_stdio_capture($adapter, $input);
    my @lines = split /\n/, $output, -1;
    pop @lines if @lines && $lines[-1] eq '';

    is(scalar @lines, 2, 'id-less notification produces no response line');
    for my $line (@lines) {
        ok(length $line, 'stdio response line is non-empty');
        unlike($line, qr/\n/, 'stdio response line has no embedded newline');
        my $decoded = decode_json($line);
        is($decoded->{jsonrpc}, '2.0', 'stdio response is JSON-RPC 2.0');
    }

    my @ids = map { decode_json($_)->{id} } @lines;
    is_deeply(\@ids, [31, 32], 'stdio response ids preserve request order');
};

subtest 'stdio parse failures still use one compact error line' => sub {
    my $output = run_stdio_capture($adapter, "{not json}\n");
    my @lines = split /\n/, $output, -1;
    pop @lines if @lines && $lines[-1] eq '';

    is(scalar @lines, 1, 'parse failure emits one error response line');
    my $decoded = decode_json($lines[0]);
    is($decoded->{error}{code}, -32700, 'parse failure maps to JSON-RPC parse error');
    unlike($lines[0], qr/\Q$repo_root\E/, 'parse failure line does not leak repo root');
};

done_testing();

sub run_stdio_capture {
    my ($adapter, $input_text) = @_;

    open my $in, '<', \$input_text or die "cannot open scalar input: $!";
    my $output_text = '';
    open my $out, '>', \$output_text or die "cannot open scalar output: $!";
    $adapter->run_stdio(in => $in, out => $out);
    close $in or die "cannot close scalar input: $!";
    close $out or die "cannot close scalar output: $!";

    return $output_text;
}
