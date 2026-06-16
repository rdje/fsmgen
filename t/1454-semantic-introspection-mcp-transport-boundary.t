#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));

subtest 'CLI help advertises only one-shot and newline-delimited stdio transports' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => [$^X, File::Spec->catfile($repo_root, 'bin', 'fsmgen-mcp'), '--help'],
    );

    ok($success, 'help command succeeds');
    my $stdout = join('', @{$stdout_buf || []});
    my $stderr = join('', @{$stderr_buf || []});
    is($stderr, '', 'help command keeps stderr clean');
    like($stdout, qr/newline-delimited stdio/, 'help advertises stdio transport');
    like($stdout, qr/--request-json JSON/, 'help advertises one-shot JSON-RPC probe');
    unlike($stdout, qr/--(?:listen|http|port|serve)\b/, 'help does not advertise HTTP or service flags');
    unlike($stdout, qr/Streamable HTTP/i, 'help does not claim Streamable HTTP');
};

subtest 'HTTP and service-mode launch flags remain unsupported' => sub {
    for my $flag (qw(--http --listen --port --serve)) {
        my ($success, undef, undef, undef, $stderr_buf) = run(
            command => [$^X, File::Spec->catfile($repo_root, 'bin', 'fsmgen-mcp'), $flag],
        );

        ok(!$success, "$flag is not accepted");
        my $stderr = join('', @{$stderr_buf || []});
        like($stderr, qr/(?:Unknown option|Error in command line arguments)/, "$flag failure is explicit");
    }
};

subtest 'source-query provenance still names the stdio JSON-RPC profile' => sub {
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

    my $response = $adapter->call_tool('fsmgen_check', {
        source_path => 'ppif/axi_aw_valid_ready.ppif',
    });
    my $payload = decode_json($response->{content}[0]{text});

    is($payload->{adapter_provenance}{transport}, 'jsonrpc_stdio', 'source query provenance stays on stdio');
    ok(!$payload->{adapter_provenance}{streamable_http}, 'source query does not claim Streamable HTTP');
    ok(!$payload->{adapter_provenance}{service_mode}, 'source query does not claim service mode');
};

done_testing();
