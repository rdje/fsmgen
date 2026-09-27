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
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $work = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $json = JSON::PP->new->canonical;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $ordinal = 0;

for my $expr ('(~ cycles)', '(&& cycles bias)', '(|| cycles bias)', '(concat cycles)',
    '(+ cycles (~ bias))', '(+ cycles (concat bias))') {
    subtest "unsupported count $expr" => sub {
        my $source = source($expr);
        my $actor = FSM::Adapter::ISF->new->parse_source($source, 'wait_grammar.isf');
        eval {FSM::Scheduler::ISF->new->lower($actor)};
        like($@, qr/runtime dynamic wait count expression .*must use a supported expression operator shape/,
            'wait validation rejects before emitting an invalid carrier');
        qualify_reports(write_file("$work/bad_" . $ordinal++ . '.isf', $source), 0);
    };
}

for my $expr ('(! cycles)', map {"($_ cycles bias)"} qw(+ - * / % & | ^ == != < <= > >= << >> concat)) {
    subtest "supported count $expr" => sub {
        my $source = source($expr);
        my $actor = FSM::Adapter::ISF->new->parse_source($source, 'wait_grammar.isf');
        my $scheduler = FSM::Scheduler::ISF->new;
        my $files = $scheduler->lower($actor)->{files};
        my $report = $json->decode($scheduler->report($actor));
        is($report->{transaction_waits}[0]{count_source}, $expr, 'authored count expression unchanged');
        is($report->{transaction_waits}[0]{count_kind}, 'runtime_expression', 'count remains a runtime snapshot');
        my $path = write_file("$work/good_" . $ordinal++ . '.fsm', $files->{'wait_grammar.fsm'});
        my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
        is($check->{exit_code}, 0, 'scheduled carrier passes strict public replay') or diag($check->{stdout}, $check->{stderr});
        qualify_reports(write_file("$work/control.isf", $source), 1) if $expr eq '(+ cycles bias)';
    };
}
done_testing;

sub source {
    my ($expr) = @_;
    return "(actor wait_grammar (clock clk) (reset (rst_n async active_low)) "
        . "(interface (input start) (input cycles (width 4)) (input bias (width 4)) (output done)) "
        . "(transaction main (on start) (wait $expr) (complete done)))\n";
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die $!;print $fh $text;close $fh;
    return $path;
}

sub qualify_reports {
    my ($path, $success) = @_;
    my $relative = File::Spec->abs2rel($path, $root);
    for my $query (
        ['check', [qw(--strict --check --json)], 'fsmgen_check'],
        ['semantic', [qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
        ['schedule', ['--emit-schedule-json'], 'fsmgen_schedule_preview'],
    ) {
        my ($kind, $flags, $tool) = @$query;
        my $native = $capture->([$^X, 'bin/fsmgen', @$flags, $relative], '');
        if ($kind eq 'schedule' && !$success) {
            # Only check/semantic have public failure-report schemas. Schedule
            # refusals retain the documented message-only adapter boundary.
            isnt($native->{exit_code}, 0, 'native schedule rejects the unsupported wait');
            is($native->{stdout}, '', 'failed schedule emits no success report');
            like($native->{stderr}, qr/must use a supported expression operator shape/, 'native schedule locates wait refusal');
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call',
                params => {name => $tool, arguments => {source_id => $relative}}};
            my $response = $api->handle_jsonrpc_request($request);
            is($response->{error}{code}, -32000, 'failed schedule uses adapter error contract');
            ok(!exists($response->{error}{data}), 'schedule error remains message-only');
            like($response->{error}{message}, qr/failed without a matching public failure report/, 'schedule failure cannot masquerade as a successful preview');
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
            is($wire->{exit_code}, 0, 'schedule refusal does not break newline protocol');
            is_deeply($json->decode($wire->{stdout}), $response, 'complete newline/API schedule refusal parity');
            next;
        }
        is($native->{exit_code}, $success ? 0 : 1, "native $kind exit agrees with source admission");
        my $report = eval {$json->decode($native->{stdout})};
        ok($report, "native $kind returns structured report") or diag($native->{stdout}, $native->{stderr}, $@);
        next unless $report;
        $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($report, $root);
        if (!$success) {
            like($json->encode($report), qr/must use a supported expression operator shape/, "$kind locates wait grammar refusal");
            unlike($json->encode($report), qr/Error parsing FSM with adapter/, "$kind fails before carrier parsing");
        }
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call',
            params => {name => $tool, arguments => {source_id => $relative}}};
        my $response = $api->handle_jsonrpc_request($request);
        is_deeply($response->{result}{structuredContent}{report}, $report, "complete native/API $kind parity");
        is($response->{result}{isError} ? 1 : 0, $success ? 0 : 1, "API $kind exposes admission status");
        my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
        is($wire->{exit_code}, 0, "newline $kind protocol exits successfully");
        is_deeply($json->decode($wire->{stdout}), $response, "complete newline/API $kind parity");
    }
}
