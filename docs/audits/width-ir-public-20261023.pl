use strict;
use warnings;
use lib 'perl', 't/lib';
use Cwd qw(abs_path);
use JSON::PP;
use Time::HiRes qw(time clock_gettime CLOCK_MONOTONIC);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $json = JSON::PP->new->canonical;
my $expected = $json->decode(do {local $/; <STDIN>});
my $root = abs_path('.');
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
for my $case (qw(actor plain)) {
    my $path = "t/data/isf-width-ir/$case.isf";
    for my $kind (qw(check semantic schedule)) {
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $tools{$kind}, arguments => {source_id => $path}}};
        my $utc = time;
        my $started = clock_gettime(CLOCK_MONOTONIC);
        my $response = $api->handle_jsonrpc_request($request);
        my $api_finished = clock_gettime(CLOCK_MONOTONIC);
        my $wire = FSM::Test::SourceQueryRunner::_capture(
            [$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
        my $record = {case => $case, kind => $kind, request => $request, api => $response, wire => $wire,
            observation => {programme_pid => 0 + $$, started_utc_epoch => $utc,
                api_started_monotonic => $started, api_finished_monotonic => $api_finished,
                newline_finished_monotonic => clock_gettime(CLOCK_MONOTONIC)}};
        # Retain original observations even if an oracle below refuses them.
        print $json->encode(normalize_repository_paths($record, $root)), "\n" or die $!;
        die "API refused $case $kind\n" if $response->{error} || $response->{result}{isError};
        die "native/API mismatch $case $kind\n" unless $json->encode(
            normalize_repository_paths($response->{result}{structuredContent}{report}, $root))
            eq $json->encode($expected->{$case}{$kind});
        die "API text mismatch $case $kind\n" unless $json->encode($json->decode($response->{result}{content}[0]{text}))
            eq $json->encode($response->{result}{structuredContent});
        die "newline refused $case $kind\n" unless $wire->{exit_code} == 0 && $wire->{stderr} eq ''
            && $wire->{stdout} =~ /\A[^\n]+\n\z/;
        die "API/newline mismatch $case $kind\n" unless $json->encode($json->decode($wire->{stdout})) eq $json->encode($response);
    }
}
