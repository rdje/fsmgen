use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFReductions qw(capture_actor_reductions);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $header = <<'ISF';
(actor operand_scopes
 (clock clk) (reset (rst_n sync active_low))
 (types (type frame (record (high (bits 3)) (low (bits 5))
   (lanes (list bit (bits 2))))))
 (interface (input start) (input bus (width 8)) (input packet (type frame))
   (output tx_bit) (output rule_bit) (output drive_bit) (output done))
 (storage (var held (type frame) (reset 0)))
ISF
my $body = <<'ISF';
 (drive tap (drive_bit (^ packet.lanes[1])))
 (transaction main (on start) (local local_word (width 5) (init 3))
   (set tx_bit (| local_word[3:1])) (set tx_bit (^ packet.low[4:2]))
   (drive tap) (complete done))
 (rule monitor start (rule_bit (& held.high))))
ISF

sub capture { FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '') }
sub same { is($json->encode($_[0]), $json->encode($_[1]), $_[2]) }
sub write_file {
    my ($name, $text) = @_;
    my $path = "$work/$name";
    open my $fh, '>', $path or die $!;
    print {$fh} $text;
    close $fh or die $!;
    $path =~ s/\A\Q$root\E\///;
    return $path;
}
sub row {
    my ($kind, $owner, $context, $operator, $operand, $width) = @_;
    return {owner_kind => $kind, owner => $owner, context => $context,
        kind => 'unary', operator => $operator, operand => $operand,
        operand_width => $width, result_width => 1};
}
sub compare_tool_report {
    my ($response, $report, $is_error, $label) = @_;
    my $result = $response->{result};
    my $envelope = ref($result) eq 'HASH' ? $result->{structuredContent} : undef;
    my $present = ok(ref($envelope) eq 'HASH' && ref($envelope->{report}) eq 'HASH',
        "$label API returns a complete public report");
    diag($json->encode($response)) unless $present;
    return unless $present;
    ok($is_error ? $result->{isError} : !$result->{isError}, "$label tool error flag matches source outcome");
    same($envelope->{report}, $report, "$label complete native/API report equality");
    my $content = $result->{content};
    my $text = ref($content) eq 'ARRAY' && ref($content->[0]) eq 'HASH' ? $content->[0]{text} : undef;
    my $decoded = eval { $json->decode($text) };
    my $valid = ok(ref($decoded) eq 'HASH', "$label serialized public envelope is an object");
    same($decoded, $envelope, "$label complete text/structured equality") if $valid;
}
my $expected = [
    row('transaction', 'main', "transaction 'main' clause[2] set RHS", '|', 'local_word[3:1]', 3),
    row('transaction', 'main', "transaction 'main' clause[3] set RHS", '^', 'packet.low[4:2]', 3),
    row('rule', 'monitor', "rule 'monitor' action[0] RHS", '&', 'held.high', 3),
    row('drive', 'tap', "drive 'tap' assignment[0] RHS", '^', 'packet.lanes[1]', 2),
];
my $positive = write_file('owners.isf', $header . $body);
my $baseline_body = $body;
$baseline_body =~ s/\(\^ packet\.lanes\[1\]\)/packet.lanes[1][0]/;
$baseline_body =~ s/\(\| local_word\[3:1\]\)/local_word[3]/;
$baseline_body =~ s/\(\^ packet\.low\[4:2\]\)/packet.low[2]/;
$baseline_body =~ s/\(& held\.high\)/held.high[0]/;
my $baseline = write_file('owners-baseline.isf', $header . $baseline_body);

my $formal = write_file('formal.isf', $header . <<'ISF');
 (transaction main (ports (input packet (width 2))) (on start)
   (set tx_bit (^ packet[1:0])) (complete done)))
ISF
my $formal_expected = [row('transaction', 'main', "transaction 'main' clause[1] set RHS",
    '^', 'packet[1:0]', 2)];
my $unused = write_file('unused.isf', $header . <<'ISF');
 (drive (dormant bus) (drive_bit (^ bus)))
 (transaction main (on start) (set tx_bit bus[0]) (complete done)))
ISF

my @bad;
for my $case (
    ['unknown', '(^ missing)', qr/not a declared packed scalar signal/],
    ['aggregate', '(^ packet)', qr/(?:whole|aggregate|scalar)/],
    ['bounds', '(^ packet.low[5])', qr/(?:out_of_range|bounds|outside)/],
    ['compound', '(^ (+ bus bus))', qr/operand must be a declared packed scalar/],
) {
    my ($label, $rhs, $cause) = @$case;
    push @bad, {name => $label, cause => $cause, path => write_file("$label.isf", $header
        . "(transaction main (on start) (set tx_bit $rhs) (complete done)))\n")};
}
push @bad, {name => 'untyped_drive', cause => qr/operand 'bus' is not a declared packed scalar/,
    path => write_file('untyped-drive.isf', $header . <<'ISF')};
 (drive (tap bus) (drive_bit (^ bus)))
 (transaction main (on start) (drive tap bus[0]) (complete done)))
ISF

subtest 'actual owner paths and nearest declarations retain independent source facts' => sub {
    my $ordinary = capture([$^X, 'bin/fsmgen', qw(--strict --check --json), $baseline]);
    is($ordinary->{exit_code}, 0, 'ordinary otherwise-identical field/local owners strict-check')
        or diag($ordinary->{stdout}, $ordinary->{stderr});
    for my $case ([$positive, $expected], [$formal, $formal_expected], [$unused, []]) {
        my ($path, $rows) = @$case;
        my $actor = eval { FSM::Adapter::ISF->new->parse_file($path) };
        my $error = $@;
        ok($actor, "$path source parses") or diag($error);
        next unless $actor;
        my $before = $json->encode($actor);
        same(capture_actor_reductions(actor => $actor), $rows, "$path independent owner/path/width inventory");
        my $scheduler = FSM::Scheduler::ISF->new;
        my $lowered = $scheduler->lower($actor);
        my $report = $json->decode($scheduler->report($actor));
        if (@$rows) {
            same($report->{reductions}, $rows, "$path actual schedule retains authored scope");
        } else {
            ok(!exists($report->{reductions}), 'unused untyped definition invents no instantiated reduction');
        }
        is($json->encode($actor), $before, "$path complete caller data/kinds unchanged");
        for my $name (sort keys %{$lowered->{files}}) {
            my $carrier = write_file("replay-$name", $lowered->{files}{$name});
            my $result = capture([$^X, 'bin/fsmgen', qw(--strict --check --json), $carrier]);
            is($result->{exit_code}, 0, "$path complete emitted $name strictly replays")
                or diag($result->{stdout}, $result->{stderr});
            my $replay = $json->decode($result->{stdout});
            ok(!exists($replay->{source}{reductions}), 'carrier invents no authored ISF inventory');
        }
    }
};

subtest 'failed capture of actual source preserves the complete caller' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_file($positive);
    for my $expression (['^', 'missing'], ['^', 'packet.low[5]'], ['^', ['+', 'bus', 'bus']]) {
        my $wrong = dclone($actor);
        $wrong->{transactions}[0]{clauses}[2][2] = dclone($expression);
        my $before = $json->encode($wrong);
        my $ok = eval { capture_actor_reductions(actor => $wrong); 1 };
        my $error = $@;
        ok(!$ok, 'invalid selected expression refuses rather than using stale source metadata');
        like($error, qr/transaction 'main' clause\[2\] set RHS/, 'failure identifies actual selected owner/context');
        is($json->encode($wrong), $before, 'failed capture preserves complete actual caller and primitive kinds');
    }
};

subtest 'complete native API and newline source success and refusal products' => sub {
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
    for my $case (
        {name => 'owners', path => $positive, expected => $expected},
        {name => 'formal', path => $formal, expected => $formal_expected},
        @bad,
    ) {
        for my $mode (
            [check => [qw(--strict --check --json)], 'fsmgen_check'],
            [semantic => [qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
            [schedule => ['--emit-schedule-json'], 'fsmgen_schedule_preview'],
        ) {
            my ($kind, $flags, $tool) = @$mode;
            my $label = "$case->{name} $kind";
            my $native = capture([$^X, 'bin/fsmgen', @$flags, $case->{path}]);
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tool, arguments => {source_id => $case->{path}}}};
            my $response = $api->handle_jsonrpc_request($request);
            if ($case->{cause}) {
                isnt($native->{exit_code}, 0, "$label refuses");
                if ($kind eq 'schedule') {
                    is($native->{stdout}, '', "$label no partial successful schedule");
                    like($native->{stderr}, $case->{cause}, "$label independent refusal category");
                    my $api_error = ref($response->{error}) eq 'HASH' ? $response->{error} : {};
                    is($api_error->{code}, -32000,
                        "$label existing message-only API boundary");
                    is($api_error->{message}, 'FSMGen command failed without a matching public failure report',
                        "$label existing bounded generic error does not expose raw command stderr");
                    ok(!exists($response->{result}), "$label no partial successful API result");
                } else {
                    is($native->{stderr}, '', "$label clean machine-readable failure stderr");
                    my $report = normalize_repository_paths($json->decode($native->{stdout}), $root);
                    ok(!$report->{success}, "$label complete structured failure");
                    like(join('\n', map {$_->{message}} @{$report->{diagnostics}}), $case->{cause},
                        "$label independent refusal category");
                    ok(!exists($report->{source}{reductions}), "$label no false source inventory");
                    compare_tool_report($response, $report, 1, $label);
                }
            } else {
                is($native->{exit_code}, 0, "$label succeeds") or diag($native->{stdout}, $native->{stderr});
                is($native->{stderr}, '', "$label clean native stderr");
                my $report = normalize_repository_paths($json->decode($native->{stdout}), $root);
                same($kind eq 'schedule' ? $report->{reductions} : $report->{source}{reductions},
                    $case->{expected}, "$label independent source owner/path/width records");
                compare_tool_report($response, $report, 0, $label);
            }
            my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
            is($wire->{exit_code}, 0, "$label newline process settles");
            is($wire->{stderr}, '', "$label clean newline stderr");
            like($wire->{stdout}, qr/\A[^\n]+\n\z/, "$label one compact newline response");
            same($json->decode($wire->{stdout}), $response, "$label complete API/newline equality");
        }
    }
};

done_testing();
