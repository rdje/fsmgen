use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CheckDiagnostics qw(build_check_success_report build_check_failure_report);
use FSM::Support::NormalizedSemanticReport qw(build_normalized_semantic_success_report build_normalized_semantic_failure_report);
use FSM::Support::ISFResetProvenance qw(snapshot_reset_provenance reset_provenance_contract);
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact);

my $json = JSON::PP->new->canonical;
my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $parser = FSM::Adapter::ISF->new;
my $scheduler = FSM::Scheduler::ISF->new;
my $audit = 'docs/audits/specforge-unstated-reset-20260930';
my $baseline = $json->decode(read_file("$audit/current.json"));
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);

subtest 'source origin survives effective-policy normalization' => sub {
    for my $case (
        ['', [{domain => undef, origin => 'legacy_default'}]],
        ['(reset rst_n)', [{domain => undef, origin => 'explicit'}]],
        ['(clock-domains (domain link (clock clk)))', [{domain => 'link', origin => 'domain_absent'}]],
        ['(clock-domains (domain link (clock clk) (reset rst_n)))', [{domain => 'link', origin => 'explicit'}]],
        ['(clock-domains (domain z (clock zclk) :default) (domain a (clock aclk) (reset rst_n)))',
            [{domain => 'z', origin => 'domain_absent'}, {domain => 'a', origin => 'explicit'}]],
        ['(clock-domains (domain a (clock aclk) (reset rst_n)) (domain z (clock zclk) :default))',
            [{domain => 'a', origin => 'explicit'}, {domain => 'z', origin => 'domain_absent'}]],
    ) {
        my $actor = $parser->parse_source("(actor origin $case->[0] (interface (input start) (output done))"
            . ' (transaction main (on start) (complete done)))', 'origin.isf');
        is_deeply($actor->{reset_provenance}, $case->[1], 'parser retains authored clause presence and order');
        my $report = $json->decode($scheduler->report($actor));
        is_deeply($report->{reset_provenance}, $case->[1], 'schedule retains complete actor scope');
        my $ir = $scheduler->{ir}->build_module($actor);
        if (ref($actor->{clock_domains}) eq 'HASH') {
            for my $domain (@{$ir->{domain_partition}{domains}}) {
                my $selected = _domain_actor_for_scheduled_artifact($actor, $domain,
                    $ir->{domain_partition}{default_domain});
                is_deeply($selected->{reset_provenance},
                    [grep { $_->{domain} eq $domain->{name} } @{$case->[1]}],
                    'domain realization retains only its own original provenance');
            }
        }
        my $snapshot = dclone($actor);
        if (ref($ir->{reset_provenance}) eq 'ARRAY') {
            $ir->{reset_provenance}[0]{origin} = 'changed';
        }
        is_deeply($actor, $snapshot, 'IR evidence detached from parsed source');
        delete $actor->{reset_provenance};
        is($json->decode($scheduler->report($actor))->{reset_provenance}, undef,
            'caller-created actor without evidence is unknown, never inferred from reset');
    }
};

subtest 'supplied cases gain provenance with every prior public product preserved' => sub {
    for my $case (qw(baseline-good omitted-reset clock-domain-no-reset)) {
        my $path = "$audit/$case.isf";
        my $expected = [{domain => $case eq 'clock-domain-no-reset' ? 'link' : undef,
            origin => $case eq 'baseline-good' ? 'explicit'
                : $case eq 'omitted-reset' ? 'legacy_default' : 'domain_absent'}];
        my $actor = $parser->parse_file($path);
        my $lowered = $scheduler->lower($actor);
        for my $query (qw(check semantic schedule)) {
            my %flags = (check => [qw(--strict --check --json)],
                semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
            my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
            my $r = capture([$^X, 'bin/fsmgen', @{$flags{$query}}, $path]);
            is($r->{exit_code}, 0, "$case $query native success");
            is($r->{stderr}, '', 'native stderr clean');
            my $report = normalize($json->decode($r->{stdout}));
            my $origin = $query eq 'schedule' ? $report->{reset_provenance} : $report->{source}{reset_provenance};
            is_deeply($origin, $expected, "$case $query independently expected provenance");
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tools{$query}, arguments => {source_id => $path}}};
            my $response = $api->handle_jsonrpc_request($request);
            ok(!$response->{error} && !$response->{result}{isError}, 'API success');
            is_deeply($response->{result}{structuredContent}{report}, $report, 'complete native/API equality');
            my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, 'newline MCP success');
            is($wire->{stderr}, '', 'newline stderr clean');
            is_deeply($json->decode($wire->{stdout}), $response, 'complete API/newline equality');
            if ($query eq 'schedule') { delete $report->{reset_provenance}; }
            else { delete $report->{source}{reset_provenance}; }
            is_deeply($report, $baseline->{$case}{queries}{$query}{report}, 'all previous report fields unchanged');
        }
        for my $language (qw(systemverilog verilog)) {
            my $output = "$work/$case-$language.".($language eq 'verilog' ? 'v' : 'sv');
            my $r = capture([$^X, 'bin/fsmgen', '--language', $language, '--output', $output, $path]);
            is($r->{exit_code}, 0, "$case $language generation succeeds");
            my $files = $baseline->{$case}{generated}{$language}{files};
            my ($old_hdl) = map { $files->{$_} } grep { /\.(?:sv|v)\z/ } keys %$files;
            is(without_date(read_file($output)), without_date($old_hdl), 'complete HDL unchanged except generated date');
            my ($old_fsm) = map { $files->{$_} } grep { /\.fsm\z/ } keys %$files;
            is_deeply($lowered->{files}, {'link_state.fsm' => $old_fsm}, 'complete scheduled carrier unchanged');
        }
    }
};

subtest 'unrelated sources and failures do not acquire ISF provenance' => sub {
    my @cases = (
        ['bad.isf', '(actor bad (reset rst_n) (reset rst_n))', 1],
        ['mixed.isf', '(actor bad (clock clk) (clock-domains (domain core (clock clk))))', 1],
        ['carrier.fsm', '(?fsm:carrier (+system (clock clk) (areset rst_n)) (idle (-> idle)))', 0],
        ['channel.ppif', read_file('ppif/valid_ready_handshake.ppif'), 0],
    );
    for my $case (@cases) {
        my $path = "$work/$case->[0]";
        write_file($path, $case->[1]);
        $path =~ s/^\Q$root\E\///;
        for my $query (qw(check semantic)) {
            my @flags = $query eq 'check' ? qw(--strict --check --json) : qw(--strict --emit-semantic-json);
            my $r = capture([$^X, 'bin/fsmgen', @flags, $path]);
            is($r->{exit_code}, $case->[2], "$case->[0] expected $query result");
            is($r->{stderr}, '', 'machine report keeps clean stderr');
            my $report = normalize($json->decode($r->{stdout}));
            ok(!exists $report->{source}{reset_provenance}, 'no manufactured ISF source evidence');
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $query eq 'check' ? 'fsmgen_check' : 'fsmgen_semantic_introspect',
                arguments => {source_id => $path}}};
            my $response = $api->handle_jsonrpc_request($request);
            is_deeply($response->{result}{structuredContent}{report}, $report, 'complete native/API control equality');
            my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, 'wire transports the result');
            is_deeply($json->decode($wire->{stdout}), $response, 'complete newline/API control equality');
        }
    }
};

subtest 'shared evidence projection is detached and rejects malformed or contradictory scope' => sub {
    my $origin = [{domain => undef, origin => 'legacy_default'}];
    for my $build (\&build_check_success_report, \&build_normalized_semantic_success_report) {
        my $report = $build->(input => 'origin.isf', source_file => 'origin.isf', reset_provenance => $origin);
        is_deeply($report->{source}{reset_provenance}, $origin, 'shared successful report receives evidence');
        $report->{source}{reset_provenance}[0]{origin} = 'explicit';
        is($origin->[0]{origin}, 'legacy_default', 'report mutation cannot change input evidence');
    }
    for my $build (\&build_check_failure_report, \&build_normalized_semantic_failure_report) {
        my $report = $build->(input => 'bad.isf', source_file => 'bad.isf',
            message => 'Error: invalid source', reset_provenance => $origin);
        ok(!exists $report->{source}{reset_provenance}, 'failure builder does not publish successful provenance');
    }
    is(snapshot_reset_provenance(undef), undef, 'unknown stays unknown');
    for my $bad (
        {}, [], [undef], [{origin => 'explicit'}],
        [{domain => undef, origin => 'explicit', extra => 1}],
        [{domain => [], origin => 'explicit'}], [{domain => '', origin => 'explicit'}],
        [{domain => undef, origin => 'made_up'}], [{domain => undef, origin => []}],
        [{domain => undef, origin => 'domain_absent'}], [{domain => 'core', origin => 'legacy_default'}],
        [{domain => undef, origin => 'explicit'}, {domain => 'core', origin => 'explicit'}],
        [{domain => 'core', origin => 'explicit'}, {domain => 'core', origin => 'domain_absent'}],
    ) {
        my $ok = eval { snapshot_reset_provenance($bad); 1 };
        ok(!$ok, 'invalid evidence fails closed');
        like($@, qr/Invalid ISF reset provenance:/, 'bounded evidence diagnostic');
    }
};

subtest 'capabilities advertise exact field and value shapes through native API and newline' => sub {
    my $native = capture([$^X, 'bin/fsmgen', '--capability-manifest']);
    is($native->{exit_code}, 0, 'native capability manifest succeeds');
    my $manifest = build_capability_manifest();
    is_deeply($json->decode($native->{stdout}), $manifest, 'complete native/in-process manifest equality');
    my $expected_keys = [qw(domain origin)];
    my $expected_origins = [qw(explicit legacy_default domain_absent)];
    for my $contract (
        $manifest->{diagnostics}{check_json}{source_optional_fields}{reset_provenance},
        $manifest->{semantic_exports}{normalized_semantic_json}{source_optional_fields}{reset_provenance},
        $manifest->{embedding}{isf_public_interface}{schedule_report_reset_provenance},
    ) {
        is_deeply($contract->{entry_keys}, $expected_keys, 'exact entry keys advertised');
        is_deeply($contract->{origin_values}, $expected_origins, 'exact origin values advertised');
        is_deeply($contract, reset_provenance_contract(), 'shared complete meaning contract');
    }
    ok(grep($_ eq 'reset_provenance', @{$manifest->{embedding}{isf_public_interface}{schedule_report_top_level_keys}}),
        'schedule field in complete discovery key set');
    for my $section (qw(diagnostics semantic_exports embedding)) {
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => 'fsmgen_capability_query', arguments => {section => $section}}};
        my $response = $api->handle_jsonrpc_request($request);
        is_deeply($response->{result}{structuredContent}{payload}, $manifest->{$section}, 'complete API capability equality');
        my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
        is($wire->{exit_code}, 0, 'newline capability success');
        is_deeply($json->decode($wire->{stdout}), $response, 'complete newline/API capability equality');
    }
};

done_testing();

sub capture { FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '') }
sub normalize { FSM::Test::SourceQueryRunner::normalize_repository_paths($_[0], $root) }
sub read_file { open my $fh, '<', $_[0] or die "$_[0]: $!"; local $/; return <$fh>; }
sub write_file { open my $fh, '>', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!; }
sub without_date { my $text = shift; $text =~ s/^\/\/ Date:[^\n]*\n//mg; return $text; }
