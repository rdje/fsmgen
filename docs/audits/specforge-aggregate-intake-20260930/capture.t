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
my $audit = 'docs/audits/specforge-aggregate-intake-20260930';
my $work = '.artifacts/aggregate-intake';
my $root = abs_path('.');
my $json = JSON::PP->new->canonical->pretty;
my $wire_json = JSON::PP->new->canonical;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my %products;
my %errors = map { $_ => qr/interface port 'lmp_in' references aggregate type 'lmp_t'; this ISF slice accepts aggregate type aliases only on actor-owned storage variables/ } qw(record-port record-port-field-guard);

for my $case (qw(baseline-good record-port record-port-field-guard)) {
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
                    is($report->{state_count}, 3, 'storage baseline state count preserved');
                    my ($storage) = grep { $_->{name} eq 'last_lmp' } @{$report->{inferred_storage}};
                    is($storage->{width}, 16, 'baseline record width retained');
                    is($storage->{type}, 'lmp_t', 'baseline storage authored type retained');
                    is($storage->{type_kind}, 'record', 'baseline storage record kind retained');
                } else { ok($report->{success}, 'baseline source succeeds'); }
            }
            $products{$case}{queries}{$query} = {native => $native, report => $report, api => $response, wire => $wire};
        }
        if (!$failure) {
            my $actor = FSM::Adapter::ISF->new->parse_file($path);
            my $lowered = FSM::Scheduler::ISF->new->lower($actor);
            $products{$case}{scheduled_files} = $lowered->{files};
            my $fsm = $lowered->{files}{'link_rx.fsm'};
            like($fsm, qr/\(last_lmp lmp_t\)/, 'actual carrier retains typed storage');
            like($fsm, qr/\(<- \(last_lmp\.subtype subtype_in\)\)/, 'actual carrier retains scalar leaf write');
            is_deeply($actor->{storage}[0]{type_spec}{member_order}, [qw(subtype payload)],
                'authored record member order retained');
            $products{$case}{storage_type} = $actor->{storage}[0]{type_spec};

        }
    };
}
open my $fh, '>', "$work/current.json" or die $!;
print {$fh} $json->encode(normalize(\%products)) or die $!;
close $fh or die $!;
done_testing();

sub capture { my ($argv,$input)=@_; return {argv=>$argv, %{FSM::Test::SourceQueryRunner::_capture($argv,$input // '')}}; }
sub normalize { FSM::Test::SourceQueryRunner::normalize_repository_paths($_[0], $root) }
