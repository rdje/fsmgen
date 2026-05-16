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

subtest 'actor-local aggregate storage leaves are valid drive body RHS values' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_aggregate_drive_value.isf');
    write_file($isf_path, <<'ISF');
(actor local_aggregate_drive_value
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
  (drive publish
    (mode_out frame.mode)
    (flag_out frame.flag))
  (transaction main
    (on start)
    (set frame frame_in)
    (drive publish)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'record', 'record carrier type resolves before drive leaf validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_aggregate_drive_value.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(frame frame_t\)/,
        'scheduled .fsm preserves aggregate carrier type');
    like($fsm, qr/\(-publish[\s\S]*\(<- \(mode_out> frame\.mode\)/,
        'scheduled .fsm preserves record member drive RHS access');
    like($fsm, qr/\(-publish[\s\S]*\(<- \(flag_out> frame\.flag\)/,
        'scheduled .fsm preserves one-bit record member drive RHS access');

    my $hdl_path = File::Spec->catfile($dir, 'local_aggregate_drive_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local aggregate drive RHS values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local aggregate drive RHS values');
    ok(-s $hdl_path, 'CLI writes HDL for local aggregate drive RHS values');
};

subtest 'package aggregate storage leaves are valid drive body RHS values' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type lanes_t (list bit (bits 2))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_drive_value.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_drive_value
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
  (drive publish
    (bit_out lanes[0])
    (pair_out lanes[1]))
  (transaction main
    (on start)
    (set lanes lanes_in)
    (drive publish)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'list', 'package list carrier type resolves before drive leaf validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_drive_value.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(-publish[\s\S]*\(<- \(bit_out> lanes\[0\]\)/,
        'scheduled .fsm preserves package list scalar drive RHS access');
    like($fsm, qr/\(-publish[\s\S]*\(<- \(pair_out> lanes\[1\]\)/,
        'scheduled .fsm preserves package list multi-bit drive RHS access');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+types[\s\S]*\(type lanes_t \(list bit \(bits 2\)\)\)/,
        'scheduled .fsm embeds imported aggregate package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_drive_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package aggregate drive RHS values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package aggregate drive RHS values');
    ok(-s $hdl_path, 'CLI writes HDL for package aggregate drive RHS values');
};

subtest 'drive body aggregate value diagnostics reject non-scalar-RHS contexts' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_drive_unknown_member
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out (width 2)))
  (storage
    (var frame (type frame_t)))
  (drive publish
    (mode_out frame.missing))
  (transaction main
    (on start)
    (drive publish)))
ISF
        qr/invalid aggregate storage path 'frame\.missing': record member 'missing' is not declared; known members: mode, flag/,
        'unknown record member drive RHS fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_drive_target_still_deferred
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input mode_in (width 2)))
  (storage
    (var frame (type frame_t)))
  (drive publish
    (frame.mode mode_in))
  (transaction main
    (on start)
    (drive publish)))
ISF
        qr/drive 'publish' target references aggregate storage path 'frame\.mode'; this ISF slice accepts aggregate storage paths only as direct transaction set RHS scalar leaf reads, direct transaction set target scalar leaf writes, transaction condition expression scalar operands, transaction switch selector or branch scalar values, rule assignment RHS scalar values or operands, rule guard expression scalar operands, drive body RHS scalar values or operands, inline drive assignment RHS scalar values or operands, or drive-call actual scalar values or operands/,
        'aggregate drive targets remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_drive_subaggregate_rhs
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
  (drive publish
    (payload_out frame.payload))
  (transaction main
    (on start)
    (drive publish)))
ISF
        qr/drive 'publish' RHS references aggregate storage path 'frame\.payload' that resolves to aggregate kind 'list'; this ISF slice accepts only scalar aggregate leaf reads/,
        'subaggregate drive RHS values remain deferred',
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
