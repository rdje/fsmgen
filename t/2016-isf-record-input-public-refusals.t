use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)]);
my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
my $header = <<'ISF';
(actor record_refused
 (types (type frame (record (kind (bits 2))
   (payload (record (data (signed (four_state (bits 5))))
    (flags (list bit (two_state (bits 2))))))))
  (type alias frame)
  (type other (record (kind (bits 2))
   (payload (record (data (four_state (bits 5))) (flags (list bit (two_state (bits 2)))))))))
 (enums (packet (OTHER 1)) (mode (ON 1)))
 (interface (input start) (input scalar (width 5)) (input mode)
  (input packet (type frame)) (output seen (width 5)) (output done))
 (storage (var held (type alias)) (var mismatch (type other)))
ISF
my @cases;
for my $case (
    ['unknown_member', '(set seen packet.missing)', qr/unknown_member/],
    ['out_of_range', '(set seen packet.payload.flags[1][2])', qr/scalar_index_out_of_range/],
    ['subaggregate_scalar', '(set seen packet.payload)', qr/requires a scalar leaf.*resolves to record/],
    ['input_field_target', '(set packet.payload.data 1)', qr/cannot write declared input/],
    ['input_root_target', '(set packet held)', qr/cannot write declared input/],
    ['equal_width_wrong_type', '(set mismatch packet)', qr/requires the same resolved record type/],
    ['record_to_scalar', '(set seen packet)', qr/whole record port copy requires declared record roots/],
    ['whole_arithmetic', '(set seen (+ packet 1))', qr/requires a scalar value.*whole record port/],
    ['whole_condition', '(when packet (set seen 1))', qr/requires a scalar value.*whole record port/],
    ['record_operator', '(set seen (packet.payload.data 1))', qr/operator cannot use declared aggregate reference/],
    ['whole_sample', '(sample packet as q)', qr/scalar.*whole record|whole record.*scalar/],
    ['sample_alias_input', '(sample scalar as packet)', qr/cannot write declared input/],
    ['unsupported_await', '(await packet.payload.flags[0])', qr/does not admit record port reference/],
) {
    push @cases, [$case->[0], $header . '(transaction main (on start) ' . $case->[1] . '))', $case->[2]];
}
push @cases,
    ['nearest_scalar_member', $header . '(transaction main (ports (input packet (width 3)))'
        . ' (on start) (set seen packet.payload.data)))', qr/member_on_non_record/],
    ['drive_parameter_member', $header . '(drive (publish packet) (seen packet.payload.data))'
        . ' (transaction main (on start) (drive publish start)))', qr/member_on_non_record/],
    ['drive_parameter_indexed_member', $header . '(drive (publish packet) (seen packet[0].payload.data))'
        . ' (transaction main (on start) (drive publish start)))', qr/member_on_non_record/],
    ['drive_parameter_sliced_member', $header . '(drive (publish packet) (seen packet[0:0].payload.data))'
        . ' (transaction main (on start) (drive publish start)))', qr/member_on_non_record/],
    ['rule_input_target', $header . '(rule observe scalar (packet.payload.data 1)))', qr/cannot write declared input/],
    ['drive_input_target', $header . '(drive publish (packet.payload.data 1)))', qr/cannot write declared input/],
    ['inline_input_target', $header . '(transaction main (on start) (drive (packet.payload.data 1))))',
        qr/cannot write declared input/];
my $foreign = $header;
$foreign =~ s/\(actor record_refused/\(actor record_refused (clock-domains (domain core (clock clk) :default) (domain aux (clock aux_clk)))/;
$foreign =~ s/\(input packet \(type frame\)\)/\(input packet (type frame) (domain aux)\)/;
push @cases, ['foreign_domain', $foreign . '(transaction main (on start) (set seen packet.payload.data)))',
    qr/clock-domain violation: .* read signal 'packet.payload.data' owned by domain 'aux' from domain 'core'/];
for my $case (
    ['record_output_field', '(types (type frame (record (flag bit)))) (interface (output packet (type frame))) (transaction main (set packet.flag 1))',
        qr/record output field writes are not yet admitted/],
    ['root_list', '(types (type lanes (list bit bit))) (interface (input packet (type lanes)))',
        qr/interface port 'packet' references aggregate type/],
    ['transaction_record', '(types (type frame (record (flag bit)))) (transaction main (ports (input packet (type frame))))',
        qr/transaction 'main' port 'packet' references aggregate type/],
    ['aggregate_bank', '(types (type frame (record (flag bit)))) (storage (bank memory (type frame) (depth 2)))',
        qr/storage.*memory.*aggregate type|bank.*type/],
    ['unknown_type', '(interface (input packet (type missing)))', qr/interface port 'packet' references unknown type 'missing'/],
    ['width_and_type', '(interface (input packet (type missing) (width 8)))', qr/cannot specify both/],
    ['unimported_alias', '(types (type alias shared.frame)) (interface (input packet (type alias)))',
        qr/malformed '\+types' entry for type 'alias'/],
) {
    push @cases, [$case->[0], '(actor record_refused ' . $case->[1] . ')', $case->[2]];
}
write_file("$work/shared.fsm", '(?pkg:shared (+types (type frame (record (flag bit)))))');
push @cases, ['missing_imported_type', '(actor record_refused (imports (package shared))'
    . ' (types (type alias shared.missing)) (interface (input packet (type alias))))',
    qr/malformed '\+types' entry for type 'alias'/];
my $package_before = sha256_hex(read_file("$work/shared.fsm"));

for my $case (@cases) {
    my ($name, $text, $message) = @$case;
    subtest "public refusal $name" => sub {
        my $path = "$work/$name.isf";
        write_file($path, $text);
        $path =~ s/^\Q$root\E\///;
        my $before = sha256_hex(read_file($path));
        for my $kind (qw(check semantic)) {
            my $native = capture([$^X, 'bin/fsmgen', @{$flags{$kind}}, $path]);
            is($native->{exit_code}, 1, "$kind actual native source refuses")
                or diag($native->{stdout} . $native->{stderr});
            is($native->{stderr}, '', "$kind machine-report stderr remains clean");
            my $report = eval { $json->decode($native->{stdout}) };
            ok(ref($report) eq 'HASH', "$kind native failure remains a complete report") or diag($native->{stdout});
            next unless ref($report) eq 'HASH';
            $report = normalize_repository_paths($report, $root);
            ok(!$report->{success}, "$kind expected compiler refusal is explicit");
            like($report->{diagnostics}[0]{message} // '', $message, "$kind independent first contextual cause");
            ok(exists($report->{diagnostics}[0]{code}), "$kind retains its nullable diagnostic code field");
            ok(!exists($report->{source}{interface_ports}), "$kind publishes no successful declaration snapshot");
            ok(!$report->{generated_output}{emitted}, "$kind emits no HDL");
            ok(!defined($report->{semantic}), "$kind publishes no partial successful semantic payload");
            is($report->{source}{input}, $path, "$kind exact refused source provenance");
            my $request = request($path, $kind);
            my $response = $api->handle_jsonrpc_request($request);
            ok(!$response->{error}, "$kind refusal retains its tool-result envelope") or diag($json->encode($response));
            next if $response->{error};
            ok($response->{result}{isError}, "$kind API preserves compiler refusal");
            same($response->{result}{structuredContent}{report}, $report, "$kind complete typed native/API failure equality");
            same($json->decode($response->{result}{content}[0]{text}), $response->{result}{structuredContent},
                "$kind complete text/structured failure equality");
            wire_equal($request, $response, $kind);
        }
        my $native = capture([$^X, 'bin/fsmgen', '--emit-schedule-json', $path]);
        isnt($native->{exit_code}, 0, 'actual native schedule refuses') or diag($native->{stdout} . $native->{stderr});
        is($native->{stdout}, '', 'no partial successful schedule product');
        like($native->{stderr}, $message, 'schedule independent contextual cause');
        my $request = request($path, 'schedule');
        my $response = $api->handle_jsonrpc_request($request);
        ok($response->{error}, 'schedule keeps its message-only error contract') or diag($json->encode($response));
        if ($response->{error}) {
            is($response->{error}{code}, -32000, 'schedule existing adapter error code');
            is($response->{error}{message}, 'FSMGen command failed without a matching public failure report',
                'schedule API preserves its existing generic message-only failure');
            ok(!exists($response->{error}{data}) && !exists($response->{result}), 'no partial schedule or error data');
        }
        wire_equal($request, $response, 'schedule');
        is(sha256_hex(read_file($path)), $before, 'all failed public queries preserve exact source bytes');
        is(sha256_hex(read_file("$work/shared.fsm")), $package_before, 'all failed public queries preserve imported bytes');
    };
}

done_testing;
sub request { return {jsonrpc => '2.0', id => 1, method => 'tools/call',
    params => {name => $tools{$_[1]}, arguments => {source_id => $_[0]}}}; }
sub same { is($json->encode($_[0]), $json->encode($_[1]), $_[2]); }
sub wire_equal {
    my ($request, $response, $kind) = @_;
    my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
    is($wire->{exit_code}, 0, "$kind actual newline transport succeeds");
    is($wire->{stderr}, '', "$kind actual newline stderr clean");
    like($wire->{stdout}, qr/\A[^\n]+\n\z/, "$kind exactly one compact response per newline");
    my $decoded = eval { $json->decode($wire->{stdout}) };
    ok(ref($decoded) eq 'HASH', "$kind newline response is complete JSON") or diag($wire->{stdout});
    same($decoded, $response, "$kind complete typed API/newline refusal equality") if ref($decoded) eq 'HASH';
}
sub capture { return FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // ''); }
sub read_file { open my $fh, '<:raw', $_[0] or die $!; local $/; return <$fh>; }
sub write_file {
    open my $fh, '>:raw', $_[0] or die $!;
    print {$fh} $_[1] or die $!;
    close $fh or die $!;
}
