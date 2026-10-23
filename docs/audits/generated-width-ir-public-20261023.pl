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
my $native = $json->decode(do {local $/; <STDIN>});
my $root = abs_path('.');
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
for my $case (qw(generated plain)) {
    for my $kind (qw(check semantic schedule)) {
        my $path = "t/data/isf-generated-width-ir/$case.isf";
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $tools{$kind}, arguments => {source_id => $path}}};
        my $utc = time;
        my $start = clock_gettime(CLOCK_MONOTONIC);
        my $response = $api->handle_jsonrpc_request($request);
        my $api_end = clock_gettime(CLOCK_MONOTONIC);
        my $wire = FSM::Test::SourceQueryRunner::_capture(
            [$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
        print $json->encode(normalize_repository_paths({case => $case, kind => $kind,
            request => $request, api => $response, wire => $wire,
            observation => {programme_pid => 0 + $$, started_utc_epoch => $utc,
                api_started_monotonic => $start, api_finished_monotonic => $api_end,
                newline_finished_monotonic => clock_gettime(CLOCK_MONOTONIC)}}, $root)), "\n" or die $!;
        die "API refused $case $kind\n" if $response->{error} || $response->{result}{isError};
        die "native/API mismatch $case $kind\n" unless $json->encode(
            normalize_repository_paths($response->{result}{structuredContent}{report}, $root)) eq $json->encode($native->{$case}{$kind});
        die "API text mismatch $case $kind\n" unless $json->encode($json->decode($response->{result}{content}[0]{text}))
            eq $json->encode($response->{result}{structuredContent});
        die "newline failure $case $kind\n" unless $wire->{exit_code} == 0 && $wire->{signal} == 0 && $wire->{stderr} eq ''
            && $wire->{stdout} =~ /\A[^\n]+\n\z/;
        die "API/newline mismatch $case $kind\n" unless $json->encode($json->decode($wire->{stdout})) eq $json->encode($response);
    }
}
