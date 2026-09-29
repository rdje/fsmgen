use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use JSON::PP;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $parser = FSM::Adapter::ISF->new;
my $scheduler = FSM::Scheduler::ISF->new;
my $json = JSON::PP->new->canonical;
my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);

my @bad = (
    ['typo', '(reset (rst_n asnyc active_low))', qr/unsupported reset option 'asnyc'/],
    ['extra_flat', '(reset rst_n ignored)', qr/requires exactly one reset specification/],
    ['extra_list', '(reset (rst_n async) ignored)', qr/requires exactly one reset specification/],
    ['missing', '(reset)', qr/requires a scalar name/],
    ['duplicate_kind', '(reset (rst_n async async))', qr/duplicate or conflicting reset timing/],
    ['conflicting_kind', '(reset (rst_n async sync))', qr/duplicate or conflicting reset timing/],
    ['reverse_kind', '(reset (rst_n sync async))', qr/duplicate or conflicting reset timing/],
    ['duplicate_polarity', '(reset (rst_n active_low active_low))', qr/duplicate or conflicting reset polarity/],
    ['conflicting_polarity', '(reset (rst_n active_high active_low))', qr/duplicate or conflicting reset polarity/],
    ['nested_option', '(reset (rst_n (async) active_low))', qr/reset options must be scalar/],
    ['unknown_polarity', '(reset (rst_n async low))', qr/unsupported reset option 'low'/],
    ['nested_name', '(reset ((rst_n) async active_low))', qr/requires a scalar name/],
    ['empty_spec', '(reset ())', qr/requires a scalar name/],
    ['empty_first_option', '(reset (rst_n () active_low))', qr/reset options must be scalar/],
    ['empty_only_option', '(reset (rst_n ()))', qr/reset options must be scalar/],
    ['empty_last_option', '(reset (rst_n async active_low ()))', qr/reset options must be scalar/],
    ['nested_empty_option', '(reset (rst_n (()) active_low))', qr/reset options must be scalar/],
);
my %bad_by_name = map { $_->[0] => $_ } @bad;

subtest 'malformed actor and domain reset policies fail before lowering' => sub {
    for my $scope (qw(actor domain)) {
        for my $case (@bad) {
            # Domain envelope already rejects outer reset arity independently.
            my $expected = $scope eq 'domain' && $case->[0] =~ /^extra_/
                ? qr/reset requires/ : $case->[2];
            my $ok = eval { $parser->parse_source(source($scope, $case->[1]), 'bad.isf'); 1 };
            ok(!$ok, "$scope $case->[0] rejected");
            like($@, $expected, 'precise reset diagnostic');
        }
    }
};

subtest 'valid shorthands and modifier permutations retain their exact policy' => sub {
    for my $scope (qw(actor domain)) {
        for my $case (
            ['(reset rst_n)', 'sync', 'active_low'],
            ['(reset (rst_n))', 'sync', 'active_low'],
            ['(reset (rst_n async))', 'async', 'active_low'],
            ['(reset (rst_n active_high))', 'sync', 'active_high'],
            ["(reset (rst_n\n async\n active_low\n))", 'async', 'active_low'],
            (map { my $kind = $_; map {
                my $polarity = $_;
                ["(reset (rst_n $kind $polarity))", $kind, $polarity],
                ["(reset (rst_n $polarity $kind))", $kind, $polarity]
            } qw(active_low active_high) } qw(sync async)),
        ) {
            my $actor = $parser->parse_source(source($scope, $case->[0]), 'valid.isf');
            my $expected = {name => 'rst_n', kind => $case->[1], polarity => $case->[2]};
            is_deeply($actor->{reset}, $expected, "$scope $case->[0] unchanged parsed policy");
            is_deeply($json->decode($scheduler->report($actor))->{reset}, $expected, 'scheduled policy agrees');
            is_deeply($actor->{reset_provenance},
                [{domain => $scope eq 'domain' ? 'core' : undef, origin => 'explicit'}],
                'explicit clause provenance remains separate');
        }
    }
};

subtest 'public failures reject bad policies without publishing successful provenance' => sub {
    for my $selected (
        ['actor', 'typo'], ['actor', 'extra_flat'],
        ['actor', 'conflicting_kind'], ['domain', 'nested_option'],
        ['domain', 'empty_only_option'],
    ) {
        my ($scope, $name) = @$selected;
        my $case = $bad_by_name{$name};
        my $path = "$work/$scope-$case->[0].isf";
        open my $fh, '>', $path or die $!;
        print {$fh} source($scope, $case->[1]) or die $!;
        close $fh or die $!;
        $path =~ s/^\Q$root\E\///;
        for my $query (qw(check semantic)) {
            my @flags = $query eq 'check' ? qw(--check --json) : qw(--emit-semantic-json);
            my $report;
            for my $strict (0, 1) {
                my $r = capture([$^X, 'bin/fsmgen', ($strict ? '--strict' : ()), @flags, $path]);
                is($r->{exit_code}, 1, "$scope $case->[0] $query strict=$strict refuses source");
                is($r->{stderr}, '', 'machine report has clean stderr');
                $report = normalize($json->decode($r->{stdout}));
                ok(!$report->{success}, 'public failure is explicit');
                like($json->encode($report->{diagnostics}), $case->[2], 'public diagnostic identifies reset error');
                ok(!exists $report->{source}{reset_provenance}, 'no successful source provenance on failure');
            }
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $query eq 'check' ? 'fsmgen_check' : 'fsmgen_semantic_introspect',
                arguments => {source_id => $path}}};
            my $response = $api->handle_jsonrpc_request($request);
            ok($response->{result}{isError}, 'API reports source failure');
            is_deeply($response->{result}{structuredContent}{report}, $report, 'complete strict native/API equality');
            my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, 'newline transports failure');
            is($wire->{stderr}, '', 'newline stderr clean');
            is_deeply($json->decode($wire->{stdout}), $response, 'complete API/newline equality');
        }
        my $schedule = capture([$^X, 'bin/fsmgen', '--emit-schedule-json', $path]);
        isnt($schedule->{exit_code}, 0, 'native schedule refuses malformed source');
        is($schedule->{stdout}, '', 'no successful schedule is emitted');
        like($schedule->{stderr}, $case->[2], 'schedule explains reset error');
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => 'fsmgen_schedule_preview', arguments => {source_id => $path}}};
        my $response = $api->handle_jsonrpc_request($request);
        ok($response->{error}, 'schedule API keeps existing transport error contract');
        my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
        is($wire->{exit_code}, 0, 'newline transports schedule error');
        is_deeply($json->decode($wire->{stdout}), $response, 'complete schedule API/newline equality');
    }
};

done_testing();

sub capture { FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '') }
sub normalize { FSM::Test::SourceQueryRunner::normalize_repository_paths($_[0], $root) }

sub source {
    my ($scope, $reset) = @_;
    my $timing = $scope eq 'domain' ? "(clock-domains (domain core (clock clk) $reset))" : "(clock clk) $reset";
    return "(actor reset_grammar $timing (interface (input start) (output done))"
        . ' (transaction main (on start) (complete done)))';
}
