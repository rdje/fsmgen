use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Support::SemanticIntrospectionMCPAdapter;

# Run from the repository root. This only emits HDL; it never starts a simulator.
my $audit = 'docs/audits/specforge-unstated-reset-20260930';
my $work = '.artifacts/specforge-unstated-reset';
my $root = abs_path('.');
my $json = JSON::PP->new->canonical->pretty;
my $wire_json = JSON::PP->new->canonical;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $root, workspace_root => $root);
my %products;
for my $case (qw(baseline-good omitted-reset clock-domain-no-reset)) {
    subtest $case => sub {
        my $path = "$audit/$case.isf";
        for my $query (qw(check semantic schedule)) {
            my %flags = (check => [qw(--strict --check --json)],
                semantic => [qw(--strict --emit-semantic-json)],
                schedule => ['--emit-schedule-json']);
            my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect',
                schedule => 'fsmgen_schedule_preview');
            my $native = capture([$^X, 'bin/fsmgen', @{$flags{$query}}, $path]);
            is($native->{exit_code}, 0, "$query native success");
            is($native->{stderr}, '', "$query native clean stderr");
            my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths(
                $json->decode($native->{stdout}), $root);
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tools{$query}, arguments => {source_id => $path}}};
            my $response = $api->handle_jsonrpc_request($request);
            ok(!$response->{error} && !$response->{result}{isError}, "$query API success");
            is_deeply($response->{result}{structuredContent}{report}, $report,
                "$query complete native/API equality");
            my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'],
                $wire_json->encode($request)."\n");
            is($wire->{exit_code}, 0, "$query newline success");
            is($wire->{stderr}, '', "$query newline clean stderr");
            is_deeply($json->decode($wire->{stdout}), $response, "$query complete API/newline equality");
            $products{$case}{queries}{$query} = {
                native => $native, report => $report, api => $response, wire => $wire};
        }
        for my $language (qw(systemverilog verilog)) {
            my $dir = "$work/$case/$language";
            make_path("$dir/lowered");
            my $output = "$dir/output.".($language eq 'verilog' ? 'v' : 'sv');
            my $result = capture([$^X, 'bin/fsmgen', '--outdir', "$dir/lowered",
                '--language', $language, '--output', $output, $path]);
            is($result->{exit_code}, 0, "$language generation succeeds");
            my %files;
            for my $file ($output, glob("$dir/lowered/*.fsm")) {
                open my $fh, '<', $file or die "$file: $!";
                local $/; $files{$file} = <$fh>;
                close $fh or die $!;
            }
            ok(exists $files{$output}, 'actual HDL retained');
            $products{$case}{generated}{$language} = {command => $result, files => \%files};
        }
    };
}
open my $fh, '>', "$work/current.json" or die $!;
print {$fh} $json->encode(FSM::Test::SourceQueryRunner::normalize_repository_paths(\%products, $root));
close $fh or die $!;
done_testing();

sub capture {
    my ($argv, $stdin) = @_;
    my $result = FSM::Test::SourceQueryRunner::_capture($argv, $stdin // '');
    return {argv => $argv, %$result};
}
