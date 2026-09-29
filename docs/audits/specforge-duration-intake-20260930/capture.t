use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Cwd qw(abs_path);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Historical intake capture at the manifest revision; no large scale probe or
# native simulator. New feature delivery may intentionally invalidate refusals.
my $audit = 'docs/audits/specforge-duration-intake-20260930';
my $work = '.artifacts/duration-intake';
my $root = abs_path('.');
my $json = JSON::PP->new->canonical->pretty;
my $wire_json = JSON::PP->new->canonical;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my %products;
my %errors = (
    'wait-in-ms' => qr/runtime dynamic wait count expression '\(time 12 ms\)' must use a supported expression operator shape/,
    'watchdog-in-us' => qr/await watchdog override requires '\(watchdog N\)'/,
    'clock-frequency' => qr/\(clock \.\.\.\) requires exactly one name/,
);

for my $case (qw(baseline-good wait-in-ms watchdog-in-us clock-frequency)) {
    subtest $case => sub {
        my $path = "$audit/$case.isf";
        my $failure = exists $errors{$case};
        for my $query (qw(check semantic schedule)) {
            my %flags = (check => [qw(--strict --check --json)],
                semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
            my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
            my $native = capture([$^X, 'bin/fsmgen', @{$flags{$query}}, $path]);
            if ($failure && $query eq 'schedule') {
                isnt($native->{exit_code}, 0, 'native schedule refusal is nonzero');
            } else {
                is($native->{exit_code}, $failure ? 1 : 0, "$query native expected outcome");
            }
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tools{$query}, arguments => {source_id => $path}}};
            my $response = $api->handle_jsonrpc_request($request);
            my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $wire_json->encode($request)."\n");
            is($wire->{exit_code}, 0, 'newline transports response');
            is($wire->{stderr}, '', 'newline stderr clean');
            is_deeply($json->decode($wire->{stdout}), $response, 'complete API/newline equality');
            my $report;
            if ($failure && $query eq 'schedule') {
                is($native->{stdout}, '', 'refused schedule emits no JSON');
                like($native->{stderr}, $errors{$case}, 'schedule names exact refusal');
                ok($response->{error}, 'schedule API returns existing transport error');
            } else {
                is($native->{stderr}, '', 'machine report stderr clean');
                $report = normalize($json->decode($native->{stdout}));
                is_deeply($response->{result}{structuredContent}{report}, $report, 'complete native/API equality');
                is(!!$response->{result}{isError}, !!$failure, 'API failure flag matches source');
                if ($failure) {
                    ok(!$report->{success}, 'structured source failure');
                    like($json->encode($report->{diagnostics}), $errors{$case}, 'diagnostic retains clause-specific cause');
                } elsif ($query eq 'schedule') {
                    is($report->{state_count}, 236, 'literal expected baseline state count');
                    is(scalar @{$report->{transaction_waits}}, 1, 'baseline has one wait region');
                    my $wait = $report->{transaction_waits}[0];
                    is($wait->{cycles}, 234, 'resolved parameter count preserved');
                    is($wait->{count_kind}, 'static', 'cycle parameter uses static lowering');
                    is($wait->{count_source}, 'QUIET_CYCLES', 'authored parameter retained');
                    is($wait->{counter_signal}, undef, 'no hidden wait counter');
                    is($wait->{counter_width}, undef, 'no hidden wait counter width');
                } else { ok($report->{success}, 'baseline source succeeds'); }
            }
            $products{$case}{queries}{$query} = {native => $native, report => $report, api => $response, wire => $wire};
        }
        if (!$failure) {
            my $actor = FSM::Adapter::ISF->new->parse_file($path);
            my $lowered = FSM::Scheduler::ISF->new->lower($actor);
            $products{$case}{scheduled_files} = $lowered->{files};
            my $fsm = $lowered->{files}{'link_quiet.fsm'};
            my @states = $fsm =~ /^\s*\(([A-Za-z_][A-Za-z0-9_]*)\s*$/mg;
            is(scalar @states, 236, 'independent actual carrier state census agrees');
            is(scalar(grep { /^quiet_wait_/ } @states), 234, 'actual carrier contains one wait state per cycle');
        }
    };
}
open my $fh, '>', "$work/current.json" or die $!;
print {$fh} $json->encode(normalize(\%products)) or die $!;
close $fh or die $!;
done_testing();

sub capture { my ($argv,$input)=@_; return {argv=>$argv, %{FSM::Test::SourceQueryRunner::_capture($argv,$input // '')}}; }
sub normalize { FSM::Test::SourceQueryRunner::normalize_repository_paths($_[0], $root) }
