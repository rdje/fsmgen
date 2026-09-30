use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use Storable qw(dclone);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8;
my $parser = FSM::Adapter::ISF->new;
my $scheduler = FSM::Scheduler::ISF->new;
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $root, workspace_root => $root);
my %flags = (check => [qw(--strict --check --json)],
    semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect',
    schedule => 'fsmgen_schedule_preview');

# Independent authored witnesses: no production layout/metadata helper builds
# the expected recursive type, leaf order, widths or packed offsets.
my $definition = '(record (kind (bits 2))'
    . ' (payload (record (data (signed (four_state (bits 5))))'
    . ' (flags (list bit (two_state (bits 2)))))))';
my $spec = {
    kind => 'record', width => 10, signed => 0, member_order => [qw(kind payload)],
    members => {
        kind => {kind => 'bits', width => 2, signed => 0},
        payload => {kind => 'record', width => 8, signed => 0,
            member_order => [qw(data flags)], members => {
                data => {kind => 'bits', width => 5, signed => 1, state_model => 'four_state'},
                flags => {kind => 'list', width => 3, signed => 0, items => [
                    {kind => 'bit', width => 1, signed => 0},
                    {kind => 'bits', width => 2, signed => 0, state_model => 'two_state'},
                ]},
            }},
    },
};
my $fields = [
    {path => 'kind', width => 2, lsb => 8, msb => 9, signed => 0},
    {path => 'payload.data', width => 5, lsb => 3, msb => 7, signed => 1, state_model => 'four_state'},
    {path => 'payload.flags[0]', width => 1, lsb => 2, msb => 2, signed => 0},
    {path => 'payload.flags[1]', width => 2, lsb => 0, msb => 1, signed => 0, state_model => 'two_state'},
];
write_file("$work/shared.fsm", '(?pkg:shared (+types (type frame ' . $definition . ')))');
my $package_before = sha256_hex(read_file("$work/shared.fsm"));
my $reads = '(transaction main (on start) (set held packet)'
    . ' (set seen packet.payload.data)'
    . ' (when mode.ON (set sliced packet.payload.data[3:1]))'
    . ' (when packet.payload.flags[0] (update tag packet.kind)) (complete done))';
my $local = '(types (type frame ' . $definition . ') (type alias frame))';
my @cases = (
    ['local_nested', $local, 'frame', 'alias', $reads],
    ['forward_alias', '(types (type alias frame) (type frame ' . $definition . '))',
        'alias', 'frame', $reads],
    ['imported_nested', '(imports (package shared))', 'shared.frame', 'shared.frame', $reads],
    ['imported_local_alias', '(imports (package shared)) (types (type alias shared.frame))',
        'alias', 'shared.frame', $reads],
    ['formal_shadow', $local, 'frame', 'alias',
        '(transaction main (ports (input packet (width 3))) (on start)'
        . ' (set sliced packet[2:0]) (complete done))'],
    ['drive_shadow', $local, 'frame', 'alias',
        '(drive (publish packet) (seen packet))'
        . ' (transaction main (on start) (drive publish scalar) (complete done))'],
    ['unused_record', $local, 'frame', 'alias',
        '(transaction main (on start) (set seen scalar) (complete done))'],
);

for my $case (@cases) {
    my ($name, $types, $input_type, $storage_type, $body) = @$case;
    subtest "accepted public source $name" => sub {
        my $text = '(actor ' . $name . ' ' . $types
            . ' (enums (packet (OTHER 1)) (mode (ON 1)))'
            . ' (interface (output done) (input start) (input packet (type ' . $input_type . '))'
            . ' (input scalar (width 5)) (input mode)'
            . ' (output seen (width 5)) (output sliced (width 3)) (output tag (width 2)))'
            . ' (storage (var held (type ' . $storage_type . '))) ' . $body . ')';
        my $path = "$work/$name.isf";
        write_file($path, $text);
        my $relative = $path =~ s/^\Q$root\E\///r;
        my $source_before = sha256_hex(read_file($path));
        my $ports = [
            p('start', 'input', 1),
            {name => 'packet', direction => 'input', width => 10,
                type => $input_type, type_kind => 'record', fields => dclone($fields)},
            p('scalar', 'input', 5), p('mode', 'input', 1),
            p('done', 'output', 1), p('seen', 'output', 5),
            p('sliced', 'output', 3), p('tag', 'output', 2),
        ];
        my $actor;
        my $ok = eval { $actor = $parser->parse_source($text, $path); 1 };
        ok($ok, 'actual authored source parses') or diag($@);
        return unless $ok;
        same($actor->{interface_port_metadata}, $ports, 'complete literal declaration and layout witness');
        my ($input) = grep { $_->{name} eq 'packet' } @{$actor->{interface}{inputs}};
        same($input->{type_spec}, $spec, 'complete independent recursive record identity');
        my $before = $json->encode($actor);
        my $lowered;
        $ok = eval { $lowered = $scheduler->lower($actor); 1 };
        ok($ok, 'actual authored source lowers') or diag($@);
        is($json->encode($actor), $before, 'lowering preserves complete caller JSON kinds');
        return unless $ok;

        for my $kind (qw(check semantic schedule)) {
            my $capture;
            $ok = eval {
                $capture = query($relative, $kind);
                1;
            };
            ok($ok, "$kind reaches every real public transport") or diag($@);
            next unless $ok;
            is($capture->{native}{exit_code}, 0, "$kind native source succeeds")
                or diag($capture->{native}{stdout} . $capture->{native}{stderr});
            is($capture->{native}{stderr}, '', "$kind native machine-report stderr clean");
            my $report = normalize_repository_paths($capture->{native}{report}, $root);
            my $api = $capture->{adapter_result};
            ok(!$api->{isError}, "$kind API source succeeds") or diag($json->encode($api));
            same($api->{structuredContent}{report}, $report, "$kind complete typed native/API report equality");
            same($json->decode($api->{content}[0]{text}), $api->{structuredContent},
                "$kind complete text/structured equality");
            is($capture->{stdio}{exit_code}, 0, "$kind actual newline transport succeeds");
            is($capture->{stdio}{stderr}, '', "$kind actual newline stderr clean");
            like($capture->{stdio}{stdout}, qr/\A[^\n]+\n\z/, "$kind one compact response per newline");
            ok(!$capture->{stdio}{response}{error}, "$kind newline keeps the complete result envelope");
            same($capture->{stdio}{response}{result}, $api, "$kind complete typed API/newline result equality");
            same($kind eq 'schedule' ? $report->{interface_ports} : $report->{source}{interface_ports},
                $ports, "$kind independent full declaration/layout witness");
            same($capture->{producer_sha256_before}, $capture->{producer_sha256_after},
                "$kind named public producer files remain unchanged");
            is($capture->{source_sha256_before}, $source_before, "$kind selects exact authored source bytes");
            is($capture->{source_sha256_after}, $source_before, "$kind preserves exact authored source bytes");
            is(sha256_hex(read_file("$work/shared.fsm")), $package_before,
                "$kind preserves independently authored package bytes");
            if ($kind ne 'schedule') {
                ok($report->{success}, "$kind report records actual source success");
                is($report->{source}{input}, $relative, "$kind exact authored source provenance");
            }
            if ($kind eq 'semantic' && $report->{success}) {
                my $hir = $report->{semantic}{forward_ir}{intent_hir};
                my ($signal) = grep { $_->{name} eq 'packet' } @{$hir->{signal_analysis}{inputs}};
                is($signal->{declared_type_name}, $input_type, 'semantic input keeps authored type spelling');
                same($signal->{declared_type_spec}, $spec, 'semantic input keeps complete recursive identity');
            }
        }

        my $dir = "$work/$name-carriers";
        mkdir $dir or die $!;
        ok(keys(%{$lowered->{files}}), 'actual lowering emits a nonempty carrier set');
        for my $file (sort keys %{$lowered->{files}}) {
            write_file("$dir/$file", $lowered->{files}{$file});
            my $replay = FSM::Test::SourceQueryRunner::_capture(
                [$^X, 'bin/fsmgen', '--quiet', '--strict', '--check', '--json', "$dir/$file"], '');
            is($replay->{exit_code}, 0, "actual emitted $file strictly replays")
                or diag($replay->{stdout} . $replay->{stderr});
            my $report = eval { $json->decode($replay->{stdout}) };
            ok($report && $report->{success}, "$file reports strict success");
        }
        is(sha256_hex(read_file($path)), $source_before, 'whole qualification preserves exact source bytes');
        is(sha256_hex(read_file("$work/shared.fsm")), $package_before, 'whole qualification preserves package bytes');
    };
}

subtest 'shared transport corruption fails independent typed witnesses' => sub {
    for my $change (
        sub { pop @{$_[0]} },
        sub { $_[0][0]{lsb} = 0 },
        sub { $_[0][1]{signed} = 0 },
        sub { $_[0][1]{width} = '5' },
        sub { delete $_[0][1]{state_model} },
        sub { @{$_[0]} = reverse @{$_[0]} },
    ) {
        my $bad = dclone($fields);
        $change->($bad);
        my @products = map { dclone($bad) } 1..3;
        same($products[0], $products[1], 'shared corrupt native/API parity alone passes');
        same($products[1], $products[2], 'shared corrupt API/newline parity alone passes');
        isnt($json->encode($bad), $json->encode($fields),
            'independent literal witness detects loss, offset, signedness, scalar kind, state or order');
    }
};

done_testing;
sub p { return {name => $_[0], direction => $_[1], width => $_[2]}; }
sub same { is($json->encode($_[0]), $json->encode($_[1]), $_[2]); }
sub query {
    my ($path, $kind) = @_;
    my @producers = qw(bin/fsmgen bin/fsmgen-mcp perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm);
    my $before = {map {$_ => sha256_hex(read_file($_))} @producers};
    my $source = sha256_hex(read_file($path));
    my $native = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', @{$flags{$kind}}, $path], '');
    $native->{report} = eval { $json->decode($native->{stdout}) };
    die "native $kind did not return a report: $native->{stdout}$native->{stderr}"
        unless ref($native->{report}) eq 'HASH';
    my $arguments = {source_id => $path};
    my $api = $adapter->call_tool($tools{$kind}, $arguments);
    my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call',
        params => {name => $tools{$kind}, arguments => $arguments}};
    my $wire = FSM::Test::SourceQueryRunner::_capture(
        [$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
    $wire->{response} = eval { $json->decode($wire->{stdout}) };
    die "newline $kind did not return a response: $wire->{stdout}$wire->{stderr}"
        unless ref($wire->{response}) eq 'HASH';
    return {native => $native, adapter_result => $api, stdio => $wire,
        producer_sha256_before => $before,
        producer_sha256_after => {map {$_ => sha256_hex(read_file($_))} @producers},
        source_sha256_before => $source, source_sha256_after => sha256_hex(read_file($path))};
}
sub read_file { open my $fh, '<:raw', $_[0] or die $!; local $/; return <$fh>; }
sub write_file {
    open my $fh, '>:raw', $_[0] or die $!;
    print {$fh} $_[1] or die $!;
    close $fh or die $!;
}
