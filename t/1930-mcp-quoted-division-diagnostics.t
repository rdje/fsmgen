#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $source_id;
for my $case (['unsupported', '(bogus a b)', 0], ['arity', '(/ a)', 0], ['division', '(/ a b)', 1]) {
    my ($name, $expr, $success) = @$case;
    subtest "$name public diagnostic/report parity" => sub {
        my $file = "$work/$name.fsm";
        open my $fh, '>', $file or die $!;
        print $fh "(?fsm:division_$name (+system (clock clk) (areset rst_n)) (+size (a 8) (b 8) (q 8)) (-exprs (= (q $expr))))\n";
        close $fh;
        my $relative = File::Spec->abs2rel($file, $root);
        $source_id = $relative;
        for my $query (['check', [qw(--strict --check --json)], 'fsmgen_check'],
                       ['semantic', [qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect']) {
            my ($kind, $flags, $tool) = @$query;
            my $native = $capture->([$^X, 'bin/fsmgen', @$flags, $relative], '');
            is($native->{exit_code}, $success ? 0 : 1, "native $kind admission status");
            my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
            like($report->{diagnostics}[0]{message}, qr/'\/'/, 'native error contains a quoted division operator') unless $success;
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tool, arguments => {source_id => $relative}}};
            my $response = $api->handle_jsonrpc_request($request);
            is($response->{result}{isError} ? 1 : 0, $success ? 0 : 1, "API $kind retains source status");
            is_deeply($response->{result}{structuredContent}{report}, $report, "complete native/API $kind report parity");
            my $text = $json->decode($response->{result}{content}[0]{text});
            is_deeply($text, $response->{result}{structuredContent}, "$kind serialized and structured tool content agree");
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
            is($wire->{exit_code}, 0, "$kind newline protocol success");
            is_deeply($json->decode($wire->{stdout}), $response, "complete newline/API $kind parity");
        }
    };
}

subtest 'operator context does not exempt actual paths' => sub {
    # These are hostile diagnostic strings, not external fixture locations.
    # No external file is created. The existing sanitizer owns path resolution.
    my @cases = (
        ["Unsupported expression operator '/'", "Unsupported expression operator '/'"],
        ['Malformed expression operator "/" with invalid arity', 'Malformed expression operator "/" with invalid arity'],
        ["Active expression operators currently include '!', '+', '/', '%'", "Active expression operators currently include '!', '+', '/', '%'"],
        ['operators include "+", "/", "concat"', 'operators include "+", "/", "concat"'],
        ["Unsupported expression Operator '/'", "Unsupported expression Operator '/'"],
        ['Malformed expression OPERATOR "/" with invalid arity', 'Malformed expression OPERATOR "/" with invalid arity'],
        ["Active expression Operators Currently Include '!', '+', '/', '%'", "Active expression Operators Currently Include '!', '+', '/', '%'"],
        ['OPERATORS INCLUDE "+", "/", "concat"', 'OPERATORS INCLUDE "+", "/", "concat"'],
        ["operator '/' then opened '/outside/private dir/source.fsm'", "operator '/' then opened '[absolute-path-redacted]'"],
        ["Operator '/' then opened '/outside/private dir/source.fsm'", "Operator '/' then opened '[absolute-path-redacted]'"],
        ["operator '/outside/source.fsm'", "operator '[absolute-path-redacted]'"],
        ["OPERATOR '/outside/source.fsm'", "OPERATOR '[absolute-path-redacted]'"],
        ["path '/'", "path '[absolute-path-redacted]'"],
        ["PATH '/'", "PATH '[absolute-path-redacted]'"],
        ['"/"', '"[absolute-path-redacted]"'],
        ['/', '[absolute-path-redacted]'],
        ["Source '$root/$source_id'", "Source '$source_id'"],
        ['opening /outside/private.fsm failed', 'opening [absolute-path-redacted] failed'],
        ['opening "C:\\private\\file.fsm" failed', 'opening "[absolute-path-redacted]" failed'],
        ['file:///outside/private.fsm', '[absolute-path-redacted]'],
        ['(/ a b), ratio a/b, docs/book/src/90-reference-map.md, https://example.com/docs',
         '(/ a b), ratio a/b, docs/book/src/90-reference-map.md, https://example.com/docs'],
    );
    for my $case (@cases) {
        my ($message, $expected) = @$case;
        my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root,
            runner => sub { return {message => $message, success => JSON::PP::true} });
        my $out = $adapter->call_tool('fsmgen_check', {source_id => $source_id});
        is($out->{structuredContent}{report}{message}, $expected, "contextual sanitization: $message");
    }
    for my $operator ('operator', 'Operator', 'OPERATOR') {
        my $throwing = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root,
            runner => sub { die "Malformed expression $operator '/' while opening '/outside/private.fsm'\n" });
        my $error = $throwing->handle_jsonrpc_request({jsonrpc => '2.0', id => 1, method => 'tools/call',
            params => {name => 'fsmgen_check', arguments => {source_id => $source_id}}});
        is_deeply($error, {jsonrpc => '2.0', id => 1, error => {code => -32000,
            message => "Malformed expression $operator '/' while opening '[absolute-path-redacted]'"}},
            "$operator message-only error preserves operator and redacts path");
    }
};
done_testing;
