#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'actor-local aggregate storage leaves are valid scalar drive-call actuals' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_aggregate_drive_call_value.isf');
    write_file($isf_path, <<'ISF');
(actor local_aggregate_drive_call_value
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input frame_in (width 3))
    (output mode_out (width 2))
    (output flag_out))
  (storage
    (var frame (type frame_t)))
  (drive (publish mode flag)
    (mode_out mode)
    (flag_out flag))
  (transaction main
    (on start)
    (set frame frame_in)
    (drive publish frame.mode frame.flag)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'record', 'record carrier type resolves before drive-call actual validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_aggregate_drive_call_value.fsm'};
    like($fsm, qr/\(= \(publish_mode frame\.mode\)\)/,
        'scheduled .fsm preserves local aggregate drive-call scalar actual');
    like($fsm, qr/\(= \(publish_flag frame\.flag\)\)/,
        'scheduled .fsm preserves local aggregate one-bit drive-call actual');
    like($fsm, qr/\(-publish[\s\S]*\(<- \(mode_out> publish_mode\)/,
        'scheduled .fsm routes aggregate-backed drive parameter through the drive body');

    my $hdl_path = File::Spec->catfile($dir, 'local_aggregate_drive_call_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local aggregate drive-call actual values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local aggregate drive-call actual values');
    ok(-s $hdl_path, 'CLI writes HDL for local aggregate drive-call actual values');
};

subtest 'package aggregate storage leaves are valid scalar drive-call actuals' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type lanes_t (list bit (bits 2))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_drive_call_value.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_drive_call_value
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input lanes_in (width 3))
    (output bit_out)
    (output pair_out (width 2)))
  (storage
    (var lanes (type shared.lanes_t)))
  (drive (publish bit_value pair_value)
    (bit_out bit_value)
    (pair_out pair_value))
  (transaction main
    (on start)
    (set lanes lanes_in)
    (drive publish lanes[0] lanes[1])))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'list', 'package list carrier type resolves before drive-call actual validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_drive_call_value.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(= \(publish_bit_value lanes\[0\]\)\)/,
        'scheduled .fsm preserves package aggregate scalar drive-call actual');
    like($fsm, qr/\(= \(publish_pair_value lanes\[1\]\)\)/,
        'scheduled .fsm preserves package aggregate multi-bit drive-call actual');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+types[\s\S]*\(type lanes_t \(list bit \(bits 2\)\)\)/,
        'scheduled .fsm embeds imported aggregate package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_drive_call_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package aggregate drive-call actual values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package aggregate drive-call actual values');
    ok(-s $hdl_path, 'CLI writes HDL for package aggregate drive-call actual values');
};

subtest 'drive-call aggregate actual diagnostics stay scalar-value-only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_drive_call_unknown_member
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out (width 2)))
  (storage
    (var frame (type frame_t)))
  (drive (publish mode)
    (mode_out mode))
  (transaction main
    (on start)
    (drive publish frame.missing)))
ISF
        qr/invalid aggregate storage path 'frame\.missing': record member 'missing' is not declared; known members: mode, flag/,
        'unknown record member drive-call actual fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_drive_call_expression_still_deferred
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input mode_in (width 2))
    (output mode_out (width 2)))
  (storage
    (var frame (type frame_t)))
  (drive (publish mode)
    (mode_out mode))
  (transaction main
    (on start)
    (drive publish (+ frame.mode mode_in))))
ISF
        qr/transaction 'main' drive 'publish' actual expression references aggregate storage path 'frame\.mode'; this ISF slice accepts aggregate storage paths only as direct transaction set RHS scalar leaf reads, direct transaction set target scalar leaf writes, transaction condition expression scalar operands, rule assignment RHS scalar values or operands, rule guard expression scalar operands, drive body RHS scalar values or operands, or drive-call actual scalar values/,
        'aggregate drive-call actual expression operands remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_inline_drive_still_deferred
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out (width 2)))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (drive inline_publish
      (mode_out frame.mode))))
ISF
        qr/transaction 'main' drive references aggregate storage path 'frame\.mode'; this ISF slice accepts aggregate storage paths only as direct transaction set RHS scalar leaf reads, direct transaction set target scalar leaf writes, transaction condition expression scalar operands, rule assignment RHS scalar values or operands, rule guard expression scalar operands, drive body RHS scalar values or operands, or drive-call actual scalar values/,
        'inline drive aggregate RHS values remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_drive_call_subaggregate_actual
  (types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (mode (bits 2)) (payload payload_t))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output payload_out (width 2)))
  (storage
    (var frame (type frame_t)))
  (drive (publish payload)
    (payload_out payload))
  (transaction main
    (on start)
    (drive publish frame.payload)))
ISF
        qr/transaction 'main' drive 'publish' actual references aggregate storage path 'frame\.payload' that resolves to aggregate kind 'list'; this ISF slice accepts only scalar aggregate leaf reads/,
        'subaggregate drive-call actual values remain deferred',
    );
};

done_testing();

sub assert_parse_rejected {
    my ($source, $regex, $label) = @_;
    my $ok = eval {
        FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
        1;
    };
    ok(!$ok, "$label is rejected");
    like($@, $regex, "$label diagnostic");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content;
    close $fh or die "close $path: $!";
    return $path;
}
