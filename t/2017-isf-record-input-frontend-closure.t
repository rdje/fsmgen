use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Digest::SHA qw(sha256_hex);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8;
my $audit = 'docs/audits/specforge-aggregate-intake-20260930';
my $prior = $json->decode(read_file("$audit/current.json"));
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)],
             schedule => ['--emit-schedule-json']);
my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
my $spec = {kind => 'record', width => 16, signed => 0, member_order => [qw(subtype payload)], members => {
    subtype => {kind => 'bits', width => 4, signed => 0}, payload => {kind => 'bits', width => 12, signed => 0}}};
my $packet = {name => 'lmp_in', direction => 'input', width => 16, type => 'lmp_t', type_kind => 'record', fields => [
    {path => 'subtype', width => 4, lsb => 12, msb => 15, signed => 0},
    {path => 'payload', width => 12, lsb => 0, msb => 11, signed => 0}]};

subtest 'immutable intake receipt stays authenticated as historical evidence' => sub {
    my $result = capture(['python3', '-B', "$audit/verify.py"]);
    is($result->{exit_code}, 0, 'original receipt and independent hostile controls qualify') or diag($result->{stderr});
    like($result->{stdout}, qr/aggregate-port baseline: .*hostile controls PASS/, 'receipt remains its historical baseline');
};

for my $case (qw(baseline-good record-port record-port-field-guard)) {
    subtest "unchanged supplied source $case" => sub {
        my $path = "$audit/$case.isf";
        my $before = sha256_hex(read_file($path));
        my $ports = $case eq 'baseline-good'
            ? [port('start', 'input', 1), port('subtype_in', 'input', 4), port('done', 'output', 1)]
            : [port('start', 'input', 1), dclone($packet), port('done', 'output', 1),
               $case eq 'record-port-field-guard' ? (port('u2_timeout_seen', 'output', 1)) : ()];
        for my $kind (qw(check semantic schedule)) {
            my $native = capture([$^X, 'bin/fsmgen', @{$flags{$kind}}, $path]);
            is($native->{exit_code}, 0, "$kind supplied source now succeeds") or diag($native->{stdout} . $native->{stderr});
            is($native->{stderr}, '', "$kind machine report stderr clean");
            my $report = eval {$json->decode($native->{stdout})};
            ok(ref($report) eq 'HASH', "$kind complete JSON product") or diag($native->{stdout});
            next unless ref($report) eq 'HASH';
            $report = normalize_repository_paths($report, $root);
            ok($report->{success}, "$kind check/semantic success") if $kind ne 'schedule';
            my $declared = $kind eq 'schedule' ? $report->{interface_ports} : $report->{source}{interface_ports};
            same($declared, $ports, "$kind complete literal declaration and packed layout");
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tools{$kind}, arguments => {source_id => $path}}};
            my $response = $api->handle_jsonrpc_request($request);
            ok(!$response->{error} && !$response->{result}{isError}, "$kind API admission succeeds")
                or diag($json->encode($response));
            next if $response->{error};
            same($response->{result}{structuredContent}{report}, $report, "$kind full typed native/API product equality");
            same($json->decode($response->{result}{content}[0]{text}), $response->{result}{structuredContent},
                "$kind full text/structured product equality");
            wire_equal($request, $response, $kind);
            if ($case eq 'baseline-good') {
                my $control = dclone($report);
                if ($kind eq 'schedule') {delete $control->{interface_ports}}
                else {delete $control->{source}{interface_ports}}
                same($control, $prior->{$case}{queries}{$kind}{report},
                    "$kind every historical baseline field remains exact after declared metadata only");
            }
        }
        my $actor = FSM::Adapter::ISF->new->parse_file($path);
        my $snapshot = $json->encode($actor);
        if ($case ne 'baseline-good') {
            my ($input) = grep {$_->{name} eq 'lmp_in'} @{$actor->{interface}{inputs}};
            same($input->{type_spec}, $spec, 'literal complete supplied recursive record type');
        }
        my $lowered = FSM::Scheduler::ISF->new->lower($actor);
        is($json->encode($actor), $snapshot, 'complete supplied actor remains unchanged');
        same($lowered->{files}, $prior->{$case}{scheduled_files}, 'every historical baseline carrier remains exact')
            if $case eq 'baseline-good';
        mkdir "$work/$case" or die $!;
        for my $file (sort keys %{$lowered->{files}}) {
            my $carrier = "$work/$case/$file";
            write_file($carrier, $lowered->{files}{$file});
            my $replay = capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $carrier]);
            is($replay->{exit_code}, 0, "$file actual carrier strictly replays") or diag($replay->{stdout} . $replay->{stderr});
            ok($json->decode($replay->{stdout})->{success}, "$file carrier reports strict success");
        }
        is(sha256_hex(read_file($path)), $before, 'all compiler queries preserve exact supplied source bytes');
    };
}

subtest 'all-section discovery preserves the entire manifest over every transport' => sub {
    my $native = capture([$^X, 'bin/fsmgen', '--capability-manifest']);
    is($native->{exit_code}, 0, 'native full discovery succeeds');
    is($native->{stderr}, '', 'native discovery stderr clean');
    my $manifest = build_capability_manifest();
    same($json->decode($native->{stdout}), $manifest, 'complete native/in-process manifest equality');
    my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
        name => 'fsmgen_capability_query', arguments => {section => 'all'}}};
    my $response = $api->handle_jsonrpc_request($request);
    ok(!$response->{error} && !$response->{result}{isError}, 'all-section API discovery succeeds');
    same($response->{result}{structuredContent}, $manifest, 'every public manifest section preserved by API');
    same($json->decode($response->{result}{content}[0]{text}), $manifest, 'full discovery text remains exact');
    wire_equal($request, $response, 'all-section discovery');
};

done_testing;
sub port {return {name => $_[0], direction => $_[1], width => 0 + $_[2]}}
sub same {is($json->encode($_[0]), $json->encode($_[1]), $_[2])}
sub capture {return FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '')}
sub wire_equal {
    my ($request, $response, $label) = @_;
    my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
    is($wire->{exit_code}, 0, "$label actual newline succeeds");
    is($wire->{stderr}, '', "$label newline stderr clean");
    like($wire->{stdout}, qr/\A[^\n]+\n\z/, "$label exactly one compact response");
    my $decoded = eval {$json->decode($wire->{stdout})};
    ok(ref($decoded) eq 'HASH', "$label complete newline JSON") or diag($wire->{stdout});
    same($decoded, $response, "$label full typed API/newline equality") if ref($decoded) eq 'HASH';
}
sub read_file {open my $fh, '<:raw', $_[0] or die $!; local $/; return <$fh>}
sub write_file {
    open my $fh, '>:raw', $_[0] or die $!;
    print {$fh} $_[1] or die $!;
    close $fh or die $!;
}
