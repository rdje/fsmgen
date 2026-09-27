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

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $fixtures = $json->decode(read_file('docs/audits/runtime-wait-book-20260927/fixtures.json'));
my ($pending) = grep {$_->{id} eq 'wait-dynamic-sample-extract'} @{$fixtures->{cases}};
my @cases = (
    ['declared', '(input packet (width 16)) (output header (width 4)) (output payload (width 8)) (output crc (width 4))',
        '(extract packet as header payload crc)', [[header=>4], [payload=>8], [crc=>4]]],
    ['assembled', '(input hi (width 4)) (input mid (width 8)) (input lo (width 4)) (output header (width 4)) (output payload (width 8)) (output crc (width 4))',
        '(assemble hi mid lo as packet) (extract packet as header payload crc)', [[packet=>16], [header=>4], [payload=>8], [crc=>4]]],
    ['explicit_assembly', '(output out (width 8))',
        '(assemble hi lo as packet (widths 4 4)) (extract packet as out)', [[packet=>8], [out=>8]]],
    ['constant_assembly', '(input hi (width 4)) (output out (width 8))',
        '(assemble K hi as packet (widths 4 4)) (extract packet as out)', [[packet=>8], [out=>8]], q{(constants (K 4'd3))}],
    ['inferred', '(input packet (width 16)) (output header (width 4)) (output crc (width 4)) (output out (width 8))',
        '(extract packet as header payload crc) (set out payload)', [[payload=>8]]],
    ['single', '(input packet (width 8)) (output out (width 8))',
        '(extract packet as field) (set out field)', [[field=>8]]],
    ['bit', '(input packet) (output out)', '(extract packet as out)', [[out=>1]]],
    ['explicit', '', '(extract packet as header payload crc (widths 4 8 4))', [[header=>4], [payload=>8], [crc=>4]]],
);
for my $case (@cases) {
    my ($name, $interface, $body, $widths, $declarations) = @$case;
    $declarations //= '';
    my $source = "(actor extract_$name (clock clk) (reset (rst_n async active_low)) "
        . "$declarations (interface (input start) (output done) $interface) "
        . "(transaction main (on start) $body (complete done)))\n";
    subtest "$name extraction" => sub { qualify($name, $source, $widths) };
}
subtest 'pending-sample extraction' => sub { qualify('pending', $pending->{source}, []) };
done_testing;

sub qualify {
    my ($name, $source, $widths) = @_;
    my $actor = FSM::Adapter::ISF->new->parse_source($source, "$name.isf");
    my $scheduler = FSM::Scheduler::ISF->new;
    my $lowered = $scheduler->lower($actor);
    my $report = $json->decode($scheduler->report($actor));
    for my $expected (@$widths) {
        my ($signal, $width) = @$expected;
        my ($storage) = grep {$_->{name} eq $signal} @{$report->{inferred_storage}};
        ok($storage, "$signal storage is reported");
        is($storage ? $storage->{width} : undef, $width, "$signal has exact width evidence");
    }
    for my $file (sort keys %{$lowered->{files}}) {
        next unless $file =~ /\.fsm\z/;
        my $path = write_file("$work/$file", $lowered->{files}{$file});
        my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
        is($check->{exit_code}, 0, "$file strict carrier replay succeeds") or diag($check->{stdout});
    }
    my $file = write_file("$work/$name.isf", $source);
    my $relative = File::Spec->abs2rel($file, $root);
    for my $query (['check', [qw(--strict --check --json)], 'fsmgen_check'],
                   ['semantic', [qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
                   ['schedule', ['--emit-schedule-json'], 'fsmgen_schedule_preview']) {
        my ($kind, $flags, $tool) = @$query;
        my $native = $capture->([$^X, 'bin/fsmgen', @$flags, $relative], '');
        is($native->{exit_code}, 0, "$kind accepts extraction") or diag($native->{stdout}, $native->{stderr});
        my $expected = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $tool, arguments => {source_id => $relative}}};
        my $response = $api->handle_jsonrpc_request($request);
        is_deeply($response->{result}{structuredContent}{report}, $expected, "complete native/API $kind parity");
        my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
        is($wire->{exit_code}, 0, "$kind newline protocol succeeds");
        is_deeply($json->decode($wire->{stdout}), $response, "complete newline/API $kind parity");
    }
}
sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    return do {local $/; <$fh>};
}
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $text or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
