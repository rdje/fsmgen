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
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $json = JSON::PP->new->canonical;
my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $audit = 'docs/audits/domain-storage-report-20260930';
my $path = "$audit/domains.isf";
my $baseline = $json->decode(read_file("$audit/baseline.json"))->{domains};
my $parser = FSM::Adapter::ISF->new;
my $scheduler = FSM::Scheduler::ISF->new;
my $actor = $parser->parse_file($path);
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);

subtest 'each domain publishes independently expected owned storage' => sub {
    my $report = $json->decode($scheduler->report($actor));
    is_deeply($report->{inferred_storage}, [], 'generated top owns no domain storage');
    my %expected = (
        core => [
            {name => 'core_word', kind => 'register', role => 'actor_storage', width => 8, access => 'rw',
             fields => [{name => 'flag', msb => 0, lsb => 0, width => 1, access => 'ro', reset => 1,
                         enum => [{name => 'OFF', value => 0}, {name => 'ON', value => 1}]}]},
            {name => 'core_record', kind => 'register', role => 'actor_storage', width => 8,
             type => 'packet_t', type_kind => 'record'},
            {name => 'bytes_0', kind => 'register', role => 'actor_storage', width => 8},
            {name => 'bytes_1', kind => 'register', role => 'actor_storage', width => 8},
        ],
        aux => [
            {name => 'aux_word', kind => 'register', role => 'actor_storage', width => 12, access => 'ro',
             fields => [{name => 'upper', msb => 11, lsb => 8, width => 4, access => 'reserved'}]},
        ],
    );
    is_deeply([map { $_->{name} } @{$report->{clock_domains}}], [qw(core aux)], 'authored domain order preserved');
    for my $domain (@{$report->{clock_domains}}) {
        is(ref($domain->{inferred_storage}), 'ARRAY', 'domain has a concrete storage-detail array');
        next unless ref($domain->{inferred_storage}) eq 'ARRAY';
        is_deeply([grep { ($_->{role} // '') eq 'actor_storage' } @{$domain->{inferred_storage}}],
            $expected{$domain->{name}}, 'exact domain-local words, fields, types and bank elements');
        my @watchdogs = grep { ($_->{role} // '') eq 'watchdog_counter' } @{$domain->{inferred_storage}};
        is_deeply(\@watchdogs, $domain->{name} eq 'core'
            ? [{name => 'main_wd', kind => 'counter', role => 'watchdog_counter', width => 3}] : [],
            'scheduler storage appears only in its owning domain');
    }
    my $with_empty_domain = read_file($path);
    $with_empty_domain =~ s/:default\)/:default) (domain spare (clock spare_clk) (reset spare_rst_n))/;
    my $empty_actor = $parser->parse_source($with_empty_domain, 'empty-domain.isf');
    my $empty_report = $json->decode($scheduler->report($empty_actor));
    my ($empty_domain) = grep { $_->{name} eq 'spare' } @{$empty_report->{clock_domains}};
    is_deeply($empty_domain->{storage}, [], 'empty domain has no declared storage names');
    is_deeply($empty_domain->{inferred_storage}, [], 'realized empty domain has an empty detail census');
    my $single_actor = $parser->parse_source(<<'ISF', 'single-domain.isf');
(actor single_storage_domain
  (clock-domains (domain only (clock clk) (reset rst_n)))
  (interface (input start) (output done))
  (storage (var value_reg (width 8) (access rw)))
  (transaction main (on start) (set value_reg 1) (complete done)))
ISF
    my $single = $json->decode($scheduler->report($single_actor));
    is_deeply($single->{clock_domains}[0]{inferred_storage}, [
        {name => 'value_reg', kind => 'register', role => 'actor_storage', width => 8, access => 'rw'},
        {name => 'done', kind => 'register', role => 'completion_pulse', width => 1},
    ], 'named single-domain path also publishes concrete details');
    is_deeply($single->{clock_domains}[0]{inferred_storage}, $single->{inferred_storage},
        'single domain and its module describe the same storage owner');
};

subtest 'full public reports add only domain storage while all hardware stays identical' => sub {
    for my $query (qw(check semantic schedule)) {
        my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)],
                     schedule => ['--emit-schedule-json']);
        my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
        my $native = capture([$^X, 'bin/fsmgen', @{$flags{$query}}, $path]);
        is($native->{exit_code}, 0, "$query native succeeds");
        is($native->{stderr}, '', 'native stderr clean');
        my $report = normalize($json->decode($native->{stdout}));
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $tools{$query}, arguments => {source_id => $path}}};
        my $response = $api->handle_jsonrpc_request($request);
        is_deeply($response->{result}{structuredContent}{report}, $report, 'complete native/API parity');
        is_deeply($json->decode($response->{result}{content}[0]{text}), $response->{result}{structuredContent},
            'text content preserves complete structured product');
        my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
        is($wire->{exit_code}, 0, 'newline succeeds');
        is($wire->{stderr}, '', 'newline stderr clean');
        is_deeply($json->decode($wire->{stdout}), $response, 'complete API/newline parity');
        if ($query eq 'schedule') {
            is_deeply($report, $json->decode($scheduler->report($actor)), 'public details equal actual scheduled domain report');
            is(ref(delete $report->{interface_ports}), 'ARRAY', 'declared-port addition is qualified by T1984');
            for my $domain (@{$report->{clock_domains}}) {
                is(ref(delete $domain->{interface_ports}), 'ARRAY', 'domain declared-port addition is explicit');
                is(ref(delete $domain->{inferred_storage}), 'ARRAY', 'only the additive detail field is removed');
            }
        }
        else {
            is(ref(delete $report->{source}{interface_ports}), 'ARRAY', 'source declared-port addition is explicit');
        }
        is_deeply($report, $baseline->{queries}{$query}{report}, 'every previous public field preserved');
    }
    is_deeply($scheduler->lower($actor)->{files}, $baseline->{scheduled_files}, 'all scheduled FSM files unchanged');
    for my $language (qw(systemverilog verilog)) {
        my $output = "$work/domains-$language." . ($language eq 'verilog' ? 'v' : 'sv');
        my $result = capture([$^X, 'bin/fsmgen', '--language', $language, '--output', $output, $path]);
        is($result->{exit_code}, 0, "$language generation succeeds");
        is($result->{stderr}, '', 'emission stderr clean');
        is(without_date(read_file($output)), without_date($baseline->{generated}{$language}{hdl}),
            'complete HDL unchanged except date');
    }
};

subtest 'publication detaches nested metadata and distinguishes unavailable detail' => sub {
    my $ir = $scheduler->{ir}->build_module($actor);
    my $domain = $ir->{domain_partition}{domains}[0];
    my $producer = {core => {state_count => 0, dt_blocks => [], inferred_storage => [
        {name => 'value_reg', kind => 'register', width => 1, fields => [
            {name => 'flag', msb => 0, lsb => 0, width => 1, access => 'ro', enum => [{name => 'ON', value => 1}]}]},
    ]}};
    my $emitter = $scheduler->{json_emitter};
    my $copy = $emitter->_clock_domain_entry_summary($domain, 'core', $producer);
    is_deeply($copy->{inferred_storage}, $producer->{core}{inferred_storage}, 'complete normalized producer copied');
    if (ref($copy->{inferred_storage}) eq 'ARRAY') {
        $copy->{inferred_storage}[0]{fields}[0]{enum}[0]{value} = 9;
        is($producer->{core}{inferred_storage}[0]{fields}[0]{enum}[0]{value}, 1, 'nested report mutation cannot change producer');
    }
    my $unknown = $emitter->_clock_domain_entry_summary($domain, 'core', undef);
    ok(exists $unknown->{inferred_storage}, 'detail has an explicit unknown slot before domain realization');
    is($unknown->{inferred_storage}, undef, 'unavailable detail is not an invented empty census');
};

subtest 'capabilities advertise complete domain-detail shape through every transport' => sub {
    my $manifest = build_capability_manifest();
    my $contract = $manifest->{embedding}{isf_public_interface};
    is_deeply($contract->{schedule_report_clock_domain_keys},
        [qw(name default clock reset scheduled_fsm ports storage transactions rules library_uses child_instances
            crossings state_count dt_block_count inferred_storage interface_ports)], 'complete bounded domain keys');
    like($contract->{schedule_report_multi_file_scope}, qr/inferred_storage.*same.*storage/s, 'shared storage schema is discoverable');
    my $native = capture([$^X, 'bin/fsmgen', '--capability-manifest']);
    is($native->{exit_code}, 0, 'native capabilities succeed');
    is_deeply($json->decode($native->{stdout}), $manifest, 'complete native/API capabilities agree');
    my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
        name => 'fsmgen_capability_query', arguments => {section => 'embedding'}}};
    my $response = $api->handle_jsonrpc_request($request);
    is_deeply($response->{result}{structuredContent}{payload}, $manifest->{embedding}, 'API embedding contract agrees');
    my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
    is($wire->{exit_code}, 0, 'newline capabilities succeed');
    is_deeply($json->decode($wire->{stdout}), $response, 'complete newline capabilities agree');
};

done_testing();

sub capture { FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '') }
sub normalize { FSM::Test::SourceQueryRunner::normalize_repository_paths($_[0], $root) }
sub read_file { open my $fh, '<', $_[0] or die "$_[0]: $!"; local $/; return <$fh> }
sub without_date { my $text = shift; $text =~ s/^\/\/ Date:[^\n]*\n//mg; return $text }
