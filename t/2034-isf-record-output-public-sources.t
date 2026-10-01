use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use JSON::PP;
use Storable qw(dclone);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8->allow_nonref;
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $root, workspace_root => $root);
my %flags = (check => [qw(--strict --check --json)],
    semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect',
    schedule => 'fsmgen_schedule_preview');
my @producers = qw(bin/fsmgen bin/fsmgen-mcp
    perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm
    perl/FSM/Adapter/ISF/Parser.pm perl/FSM/Scheduler/ISF.pm);
my $producer_before = fingerprints(@producers);
# The literal oracle is independent of the compiler's metadata/layout helpers.
my $definition = '(record (kind (bits 2)) (payload (record'
    . ' (data (signed (four_state (bits 5))))'
    . ' (flags (list bit (two_state (bits 2)))))))';
my $spec = {kind => 'record', width => 10, signed => 0, member_order => [qw(kind payload)], members => {
    kind => {kind => 'bits', width => 2, signed => 0},
    payload => {kind => 'record', width => 8, signed => 0, member_order => [qw(data flags)], members => {
        data => {kind => 'bits', width => 5, signed => 1, state_model => 'four_state'},
        flags => {kind => 'list', width => 3, signed => 0, items => [
            {kind => 'bit', width => 1, signed => 0},
            {kind => 'bits', width => 2, signed => 0, state_model => 'two_state'}]},
    }},
}};
my $fields = [
    {path => 'kind', width => 2, msb => 9, lsb => 8, signed => 0},
    {path => 'payload.data', width => 5, msb => 7, lsb => 3, signed => 1, state_model => 'four_state'},
    {path => 'payload.flags[0]', width => 1, msb => 2, lsb => 2, signed => 0},
    {path => 'payload.flags[1]', width => 2, msb => 1, lsb => 0, signed => 0, state_model => 'two_state'},
];
my $package = '(?pkg:shared (+types (type frame ' . $definition . ')))';
write_file("$work/shared.fsm", $package);
my $package_before = sha256_hex($package);
my $local = '(types (type frame ' . $definition . ') (type alias frame))';
my $ordinary = '(transaction main (on start) (set packet held)'
    . ' (set seen packet.payload.data) (wait 1) (set packet held) (complete done))';
my @cases = (
    ['local', $local, 'frame', 'frame', $ordinary],
    ['forward_alias', '(types (type alias frame) (type frame ' . $definition . '))', 'alias', 'frame', $ordinary],
    ['imported', '(imports (package shared))', 'shared.frame', 'shared.frame', $ordinary],
    ['imported_alias', '(imports (package shared)) (types (type alias shared.frame))', 'alias', 'shared.frame', $ordinary],
    ['mixed', $local, 'alias', 'frame',
        '(transaction main (on start) (set held incoming) (set packet held) (complete done))', 'mixed'],
    ['reverse', $local, 'frame', 'alias',
        '(transaction main (on start) (set held packet) (set echo packet) (complete done))', 'reverse'],
    ['unused', $local, 'alias', 'frame', '', 'unused'],
);

for my $case (@cases) {
    my ($name, $types, $output_type, $storage_type, $body, $variant) = @$case;
    subtest "complete public output source $name" => sub {
        my $text = '(actor public_output_' . $name . ' (clock clk) ' . $types
            . ' (interface (output packet (type ' . $output_type . ')) (input start)'
            . (($variant // '') eq 'mixed' ? ' (input incoming (type frame))' : '')
            . ' (output seen (width 5)) (output done)'
            . (($variant // '') eq 'reverse' ? ' (output echo (type frame))' : '') . ')'
            . ' (storage (var held (type ' . $storage_type . '))) ' . $body . ')';
        my $ports = [scalar_port('start', 'input', 1),
            (($variant // '') eq 'mixed' ? record_port('incoming', 'input', 'frame') : ()),
            record_port('packet', 'output', $output_type), scalar_port('seen', 'output', 5),
            scalar_port('done', 'output', 1),
            (($variant // '') eq 'reverse' ? record_port('echo', 'output', 'frame') : ())];
        my $path = "$work/$name.isf";
        write_file($path, $text);
        my $actor = FSM::Adapter::ISF->new->parse_file($path);
        my $before = $json->encode($actor);
        same($actor->{interface_port_metadata}, $ports, 'actual declarations follow inputs then outputs with authored order');
        my ($output) = grep {$_->{name} eq 'packet'} @{$actor->{interface}{outputs}};
        same($output->{type_spec}, $spec, 'exact independent recursive output identity');
        for my $kind (qw(check semantic schedule)) {
            my $observation = query($path, $kind);
            my $report = qualify_success($observation, $kind, $ports, 'public_output_' . $name);
            if ($kind eq 'semantic' && ref($report->{semantic}) eq 'HASH') {
                my ($signal) = grep {$_->{name} eq 'packet'}
                    @{$report->{semantic}{forward_ir}{intent_hir}{signal_analysis}{outputs}};
                ok(ref($signal) eq 'HASH', 'semantic output retains the authored endpoint');
                if (ref($signal) eq 'HASH') {
                    is($signal->{declared_type_name}, $output_type, 'semantic output keeps authored type spelling');
                    same($signal->{declared_type_spec}, $spec, 'semantic output retains full recursive type');
                }
            }
            preserve($name . '-' . $kind, {source => $text, package => $package, expected_ports => $ports,
                expected_type => $spec, observation => $observation});
        }
        my $scheduler = FSM::Scheduler::ISF->new;
        my $first = $json->decode($scheduler->report($actor));
        $first->{interface_ports}[1]{fields}[0]{msb} = 0;
        my $second = $json->decode($scheduler->report($actor));
        same($second->{interface_ports}, $ports, 'schedule metadata is independently detached on every read');
        same($actor->{interface_port_metadata}, $ports, 'mutating a report cannot alter declaration facts');
        is($json->encode($actor), $before, 'complete actor JSON kinds remain unchanged by repeated queries');
        is(sha256_hex(read_file($path)), sha256_hex($text), 'exact source bytes remain unchanged');
        is(sha256_hex(read_file("$work/shared.fsm")), $package_before, 'exact imported package bytes remain unchanged');
    };
}

subtest 'actual domain public reports retain complete top and selected-domain output metadata' => sub {
    my $text = '(actor public_output_domains (clock-domains (domain core (clock clk) :default)'
        . ' (domain bus (clock bus_clk))) ' . $local
        . ' (interface (output packet (type alias) (domain bus)) (input start)'
        . ' (input request (domain bus)) (output seen (width 5)))'
        . ' (storage (var held (type frame) (domain bus)))'
        . ' (transaction core_work (domain core) (on start) (set seen 1))'
        . ' (transaction publish (domain bus) (on request) (set packet held)))';
    my $path = "$work/domains.isf";
    write_file($path, $text);
    my $ports = [scalar_port('start', 'input', 1, 'core'), scalar_port('request', 'input', 1, 'bus'),
        record_port('packet', 'output', 'alias', 'bus'), scalar_port('seen', 'output', 5, 'core')];
    for my $kind (qw(check semantic schedule)) {
        my $observation = query($path, $kind);
        my $report = qualify_success($observation, $kind, $ports, 'public_output_domains_top');
        if ($kind eq 'schedule') {
            my %domains = map {$_->{name} => $_} @{$report->{clock_domains} // []};
            is_deeply([sort keys %domains], [qw(bus core)], 'complete literal domain membership');
            same($domains{bus}{interface_ports}, [scalar_port('request', 'input', 1, 'bus'), record_port('packet', 'output', 'alias', 'bus')],
                'bus domain owns exactly the declared record output and request');
            same($domains{core}{interface_ports}, [scalar_port('start', 'input', 1, 'core'), scalar_port('seen', 'output', 5, 'core')],
                'core domain cannot acquire the other physical output');
        }
        preserve('domains-' . $kind, {source => $text, expected_ports => $ports, observation => $observation});
    }
};

subtest 'actual public source and writer refusals cannot publish successful declaration or semantic products' => sub {
    for my $case (
        ['competing', '(transaction left (on start) (set packet held)) (transaction right (on other) (set packet held))',
            qr/record output 'packet' cannot admit overlapping writers/],
        ['field', '(transaction main (set packet.payload.data 1))', qr/record output field writes are not yet admitted/],
        ['literal', '(transaction main (set packet 0))', qr/whole record port copy requires declared record roots/],
        ['whole_sample', '(transaction main (on start (sample packet as captured)))', qr/sample requires a scalar value; 'packet' is a whole record/],
    ) {
        my ($name, $body, $reason) = @$case;
        my $text = '(actor public_output_' . $name . ' (clock clk) ' . $local
            . ' (interface (input start) (input other) (output packet (type alias)))'
            . ' (storage (var held (type frame))) ' . $body . ')';
        my $path = "$work/refused_$name.isf";
        write_file($path, $text);
        for my $kind (qw(check semantic schedule)) {
            my $observation = query($path, $kind);
            my $native = $observation->{native};
            is($native->{exit_code}, $kind eq 'schedule' ? 255 : 1, "$name/$kind established native refusal status");
            is($native->{signal}, 0, "$name/$kind no native signal");
            if ($kind ne 'schedule') {
                my $report = $observation->{report};
                is($native->{stderr}, '', "$name/$kind machine report owns diagnostics");
                is($json->encode($report->{success}), 'false', "$name/$kind exact JSON failure kind");
                like($report->{diagnostics}[0]{message}, $reason, "$name/$kind precise authored primary reason");
                ok(exists($report->{diagnostics}[0]{code}), "$name/$kind retained nullable diagnostic code");
                ok(!exists($report->{source}{interface_ports}), "$name/$kind no successful declaration metadata");
                ok(!defined($report->{semantic}), "$name/$kind no partial semantic product");
                same($observation->{response}{result}{structuredContent}{report}, $report,
                    "$name/$kind complete typed native/API failure equality");
                same($json->decode($observation->{response}{result}{content}[0]{text}),
                    $observation->{response}{result}{structuredContent}, "$name/$kind complete failure text/structured equality");
                is($json->encode($observation->{response}{result}{isError}), 'true',
                    "$name/$kind exact error envelope kind");
            } else {
                like($native->{stderr}, $reason, "$name schedule retains the actual primary refusal");
                is($native->{stdout}, '', "$name schedule publishes no partial JSON product");
                is($observation->{response}{error}{code}, -32000, "$name schedule retains the established JSON-RPC error");
                is($observation->{response}{error}{message}, 'FSMGen command failed without a matching public failure report',
                    "$name schedule retains the bounded message-only public contract");
                ok(!exists($observation->{response}{result}), "$name schedule has no successful result envelope");
            }
            preserve('refused-' . $name . '-' . $kind, {source => $text, observation => $observation});
        }
        is(sha256_hex(read_file($path)), sha256_hex($text), "$name refusal preserves source bytes");
    }
};

subtest 'independent literal metadata rejects corruption shared by all transports' => sub {
    my $ports = [scalar_port('start', 'input', 1), record_port('packet', 'output', 'alias')];
    for my $change (
        sub {$_[0][1]{direction} = 'input'},
        sub {$_[0][1]{width} = '10'},
        sub {$_[0][1]{fields}[1]{signed} = 0},
        sub {delete $_[0][1]{fields}[1]{state_model}},
        sub {$_[0][1]{fields}[0]{lsb} = 0},
        sub {pop @{$_[0][1]{fields}}},
        sub {@{$_[0][1]{fields}} = reverse @{$_[0][1]{fields}}},
        sub {$_[0][1]{fields}[0]{state_model} = 'two_state'},
    ) {
        my $bad = dclone($ports); $change->($bad);
        same(dclone($bad), dclone($bad), 'shared transport equality alone cannot prove correctness');
        isnt($json->encode($bad), $json->encode($ports), 'literal oracle detects role, kind, packing, state, signedness or order corruption');
    }
};
same(fingerprints(@producers), $producer_before, 'all named public/source producer bytes remain unchanged');
done_testing;

sub scalar_port {return {name => $_[0], direction => $_[1], width => $_[2],
    defined($_[3]) ? (domain => $_[3]) : ()}}
sub record_port {return {name => $_[0], direction => $_[1], width => 10,
    type => $_[2], type_kind => 'record', fields => dclone($fields),
    defined($_[3]) ? (domain => $_[3]) : ()}}
sub same {is($json->encode($_[0]), $json->encode($_[1]), $_[2])}
sub qualify_success {
    my ($o, $kind, $ports, $module) = @_;
    is($o->{native}{exit_code}, 0, "$kind actual native source succeeds")
        or diag($o->{native}{stdout}, $o->{native}{stderr});
    is($o->{native}{signal}, 0, "$kind actual native terminates normally");
    is($o->{native}{stderr}, '', "$kind machine stderr clean");
    my $r = $o->{report};
    ok(ref($r) eq 'HASH', "$kind native publishes a complete JSON object");
    return {} unless ref($r) eq 'HASH';
    same($o->{response}{result}{structuredContent}{report}, $r, "$kind complete typed native/API equality");
    is($json->encode($o->{response}{result}{isError}), 'false', "$kind exact successful tool kind");
    same($json->decode($o->{response}{result}{content}[0]{text}), $o->{response}{result}{structuredContent},
        "$kind complete text/structured equality");
    same($kind eq 'schedule' ? $r->{interface_ports} : $r->{source}{interface_ports}, $ports,
        "$kind complete independent declaration/layout oracle");
    if ($kind ne 'schedule') {
        is($json->encode($r->{success}), 'true', "$kind exact successful report kind");
        is($json->encode($r->{generated_output}{emitted}), 'false', "$kind read-only query publishes no HDL artifact");
        same($r->{diagnostics}, [], "$kind complete empty diagnostics");
        is($kind eq 'check' ? $r->{result}{module_name} : $r->{semantic}{module}{name}, $module,
            "$kind independently named realized module");
    }
    return $r;
}
sub query {
    my ($path, $kind) = @_;
    my $source_before = sha256_hex(read_file($path));
    my $relative = $path =~ s/^\Q$root\E\///r;
    my $native = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', @{$flags{$kind}}, $relative], '');
    my $report = eval {$json->decode($native->{stdout})};
    $report = normalize_repository_paths($report, $root) if ref($report) eq 'HASH';
    my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
        name => $tools{$kind}, arguments => {source_id => $relative}}};
    my $response = $adapter->handle_jsonrpc_request($request);
    my $wire = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'],
        $json->encode($request) . "\n");
    is($wire->{exit_code}, 0, "$kind actual newline process succeeds");
    is($wire->{signal}, 0, "$kind newline process terminates normally");
    is($wire->{stderr}, '', "$kind actual newline stderr clean");
    like($wire->{stdout}, qr/\A[^\n]+\n\z/, "$kind exactly one compact newline response");
    my $decoded = $json->decode($wire->{stdout});
    same($decoded, $response, "$kind complete typed in-process/newline response equality");
    my $source_after = sha256_hex(read_file($path));
    is($source_after, $source_before, "$kind every actual query preserves exact source bytes");
    return {native => $native, report => $report, request => $request, response => $response, wire => $wire,
        source_sha256_before => $source_before, source_sha256_after => $source_after};
}
sub fingerprints {return {map {$_ => sha256_hex(read_file($_))} @_}}
sub preserve {
    return unless ($ENV{FSMGEN_RECORD_OUTPUT_PUBLIC_CAPTURE} // '') eq '1';
    my ($name, $value) = @_;
    die 'invalid fixed witness name' unless $name =~ /\A[a-z_-]+\z/;
    write_file('.artifacts/record-output-public/' . $name . '.json', $json->encode($value) . "\n");
}
sub read_file {open my $fh, '<:raw', $_[0] or die $!; local $/; return <$fh>}
sub write_file {open my $fh, '>:raw', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!}
