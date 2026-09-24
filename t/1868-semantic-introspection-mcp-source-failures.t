#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use FindBin;
use JSON::PP qw(decode_json encode_json);
use IPC::Cmd ();
use lib "$FindBin::Bin/../perl";
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Support::SemanticIntrospectionContract qw(semantic_introspection_safety_policy);

my $root = abs_path("$FindBin::Bin/..");
my $source = 'fsm/mipicsi2_txccore_ulp.fsm';
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $root, workspace_root => $root,
);
my %reports;

sub request {
    my ($kind, $path) = @_;
    my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect',
                 schedule => 'fsmgen_schedule_preview');
    return { jsonrpc => '2.0', id => 1, method => 'tools/call',
             params => { name => $tools{$kind}, arguments => { source_id => $path // $source } } };
}

# Independent expected projection: only this actual source's known root changes.
sub relative_report {
    my ($value) = @_;
    return { map { $_ => relative_report($value->{$_}) } keys %$value } if ref($value) eq 'HASH';
    return [map { relative_report($_) } @$value] if ref($value) eq 'ARRAY';
    return $value if !defined($value) || ref($value);
    $value =~ s{\Q$root/\E}{}g;
    return $value;
}

subtest 'real failed checks and semantic exports preserve native diagnostic reports' => sub {
    for my $kind (qw(check semantic)) {
        my @flags = $kind eq 'check' ? ('--check', '--json') : ('--emit-semantic-json');
        my ($ok, $error, $all, $out, $err) = IPC::Cmd::run(
            command => ["$root/bin/fsmgen", '--strict', @flags, "$root/$source"],
        );
        ok(!$ok, "$kind native command refuses the catalogued invalid source");
        my $native = decode_json(join('', @{$out || []}));
        $reports{$kind} = $native;
        ok(JSON::PP::is_bool($native->{success}) && !$native->{success}, "$kind native success is JSON false");
        is($native->{diagnostics}[0]{code}, 'FSMGEN_STRICT_LEGACY_FSM_ROOT', "$kind has original stable diagnostic");
        my $response = $adapter->handle_jsonrpc_request(request($kind));
        ok(!exists($response->{error}), "$kind refusal is a tool result, not an opaque JSON-RPC error");
        ok($response->{result}{isError}, "$kind marks the source failure as a tool execution error");
        my $payload = $response->{result}{structuredContent};
        is_deeply($payload->{report}, relative_report($native), "$kind preserves the entire native report except root paths");
        is_deeply(decode_json($response->{result}{content}[0]{text} // '{}'), $payload, "$kind text and structured content agree");
        my $resource = $adapter->handle_jsonrpc_request({ jsonrpc => '2.0', id => 2,
            method => 'resources/read', params => { uri => "fsmgen://source/fsm%2Fmipicsi2_txccore_ulp.fsm/$kind" } });
        my $resource_payload = decode_json($resource->{result}{contents}[0]{text} // '{}');
        is_deeply($resource_payload, $payload, "$kind resource exposes the same report envelope");
        unlike(encode_json($response), qr/\Q$root\E/, "$kind response has no embedded machine root");
    }
};

subtest 'successful native source reports keep their content and success status' => sub {
    my $valid = 'ppif/axi_aw_valid_ready.ppif';
    for my $kind (qw(check semantic)) {
        my @flags = $kind eq 'check' ? ('--check', '--json') : ('--emit-semantic-json');
        my ($ok, $error, $all, $out) = IPC::Cmd::run(
            command => ["$root/bin/fsmgen", '--strict', @flags, "$root/$valid"],
        );
        ok($ok, "$kind valid native command succeeds");
        my $native = decode_json(join('', @{$out || []}));
        my $response = $adapter->handle_jsonrpc_request(request($kind, $valid));
        ok(!$response->{result}{isError}, "$kind valid tool result is not an execution error");
        is_deeply($response->{result}{structuredContent}{report}, relative_report($native), "$kind successful native report survives projection");
    }
};

subtest 'unsuccessful commands require a matching public failure report' => sub {
    my $good = $reports{check};
    my @cases = (
        ['plain stderr', '', 0], ['malformed JSON', '{', 0],
        ['scalar JSON', 'false', 0], ['array JSON', '[]', 0],
        ['unrelated JSON', '{"success":false}', 0],
        ['wrong query', encode_json($reports{semantic}), 0],
        ['matching failure', encode_json($good), 1],
    );
    for my $change (
        ['success on failed exit', sub { $_[0]{success} = JSON::PP::true }],
        ['non-Boolean failure', sub { $_[0]{success} = 0 }],
        ['wrong schema', sub { $_[0]{check_schema_version} = 99 }],
        ['wrong producer', sub { $_[0]{producer}{report_source} = 'other' }],
        ['wrong mode', sub { $_[0]{command}{mode} = 'generate' }],
        ['missing diagnostics', sub { delete $_[0]{diagnostics} }],
        ['malformed diagnostics', sub { $_[0]{diagnostics} = ['not a diagnostic'] }],
    ) {
        my $copy = decode_json(encode_json($good)); $change->[1]->($copy);
        push @cases, [$change->[0], encode_json($copy), 0];
    }
    for my $case (@cases) {
        my ($label, $stdout, $accepted) = @$case;
        no warnings 'redefine';
        local *FSM::Support::SemanticIntrospectionMCPAdapter::run = sub {
            return (0, "command '$root/bin/fsmgen' failed", [], [$stdout], ["secret /external/private/file\n"]);
        };
        my $response = $adapter->handle_jsonrpc_request(request('check'));
        if ($accepted) {
            ok($response->{result}{isError}, "$label survives nonzero execution");
        } else {
            is($response->{error}{code}, -32000, "$label remains an adapter error");
            ok(!exists($response->{error}{data}), "$label remains message-only");
            unlike(encode_json($response), qr/secret|\Q$root\E|\/external|malformed JSON string/, "$label excludes raw execution/decoder details");
        }
    }
    no warnings 'redefine';
    local *FSM::Support::SemanticIntrospectionMCPAdapter::run = sub { return (1, undef, [], ['not JSON'], []) };
    my $response = $adapter->handle_jsonrpc_request(request('check'));
    like($response->{error}{message}, qr/did not emit a JSON object/, 'successful invalid stdout remains distinct from failed execution');
};

subtest 'embedded path sanitization preserves relative references and semantics' => sub {
    my $runner = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $root, workspace_root => $root,
        runner => sub { return { message => "Source '$root/$source': docs/book/src/10-errors-strict-mode-and-troubleshooting.md; ratio a/b; (/ a b); fsmgen://sources; https://example.com/docs",
            paths => ["$root/$source", "external '/outside/private dir/file.fsm'", 'opening /outside/plain.fsm failed',
                      'opening C:\\private\\file.fsm failed', 'file:///outside/plain.fsm', 'path:/outside/file.fsm', "bad '$root/../outside/file.fsm'"],
            success => JSON::PP::true }; },
    );
    my $payload = $runner->call_tool('fsmgen_check', { source_id => $source })->{structuredContent}{report};
    is($payload->{message}, "Source '$source': docs/book/src/10-errors-strict-mode-and-troubleshooting.md; ratio a/b; (/ a b); fsmgen://sources; https://example.com/docs", 'diagnostic prose keeps useful relative references and slash expressions');
    is($payload->{paths}[0], $source, 'standalone source becomes relative');
    for my $i (1 .. $#{$payload->{paths}}) {
        unlike($payload->{paths}[$i], qr/outside|private|\Q$root\E/, "external or escaping path $i is redacted");
        like($payload->{paths}[$i], qr/absolute-path-redacted/, "path $i has explicit redaction marker");
    }
};

subtest 'public errors are bounded and sanitized before JSON-RPC serialization' => sub {
    my $throwing = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $root, workspace_root => $root,
        runner => sub { die "Runner at '$root/$source': opened '/outside/private dir/file' and /outside/plain; " . ('x' x 5000) },
    );
    my $response = $throwing->handle_jsonrpc_request(request('check'));
    is($response->{error}{code}, -32000, 'runner error remains an adapter error');
    unlike($response->{error}{message}, qr/\Q$root\E|outside|private| at .* line \d+/, 'embedded paths and Perl location are absent');
    cmp_ok(length($response->{error}{message}), '<=', 2048, 'public message has a fixed character bound');
    like($response->{error}{message}, qr/\[truncated\]\z/, 'truncation is explicit');
    my $policy = semantic_introspection_safety_policy();
    is($policy->{jsonrpc_error_message_max_characters}, 2048, 'manifest advertises the tested bound');
    is($policy->{source_query_failure_policy}{tool_result},
       'isError_true_with_native_report_in_text_and_structuredContent', 'manifest advertises failure report transport');
    my $input = "{bad-json \"$root/$source\"\n";
    my $output = '';
    open my $in, '<', \$input or die $!; open my $out, '>', \$output or die $!;
    $adapter->run_stdio(in => $in, out => $out);
    my $parse = decode_json($output);
    is($parse->{error}{code}, -32700, 'stdio parsing keeps its standard error code');
    unlike($parse->{error}{message}, qr/\Q$root\E|bad-json/, 'parse error omits raw decoder excerpt');
};

subtest 'workspace escape is rejected before running a source query' => sub {
    my $called = 0;
    my $limited = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $root, workspace_root => "$root/ppif", runner => sub { ++$called },
    );
    my $response = $limited->handle_jsonrpc_request(request('check', "$root/$source"));
    like($response->{error}{message}, qr/escapes workspace root/, 'escape still fails closed');
    unlike($response->{error}{message}, qr/\Q$root\E/, 'escape error does not expose configured roots');
    is($called, 0, 'source runner never sees rejected path');
};

done_testing();
