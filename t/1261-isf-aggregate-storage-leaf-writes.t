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

subtest 'actor-local aggregate storage record members are valid transaction set targets' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_aggregate_leaf_write.isf');
    write_file($isf_path, <<'ISF');
(actor local_aggregate_leaf_write
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input frame_in (width 3))
    (input mode_in (width 2))
    (input flag_in)
    (output frame_out (width 3)))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (set frame frame_in)
    (set frame.mode mode_in)
    (set frame.flag flag_in)
    (set frame_out frame)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'record', 'record carrier type resolves before leaf write validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_aggregate_leaf_write.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(frame frame_t\)/,
        'scheduled .fsm preserves aggregate carrier type');
    like($fsm, qr/\(<- \(frame\.mode mode_in\)\)/,
        'scheduled .fsm preserves record member set target');
    like($fsm, qr/\(<- \(frame\.flag flag_in\)\)/,
        'scheduled .fsm preserves one-bit record member set target');

    my $hdl_path = File::Spec->catfile($dir, 'local_aggregate_leaf_write.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for record member set target writes');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for record member set target writes');
    ok(-s $hdl_path, 'CLI writes HDL for record member set target writes');
};

subtest 'package aggregate storage list items are valid transaction set targets' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type lanes_t (list bit (bits 2))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_leaf_write.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_leaf_write
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input lanes_in (width 3))
    (input bit_in)
    (input pair_in (width 2))
    (output lanes_out (width 3)))
  (storage
    (var lanes (type shared.lanes_t)))
  (transaction main
    (on start)
    (set lanes lanes_in)
    (set lanes[0] bit_in)
    (set lanes[1] pair_in)
    (set lanes_out lanes)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'list', 'package list carrier type resolves before leaf write validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_leaf_write.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(<- \(lanes\[0\] bit_in\)\)/,
        'scheduled .fsm preserves list item set target');
    like($fsm, qr/\(<- \(lanes\[1\] pair_in\)\)/,
        'scheduled .fsm preserves multi-bit list item set target');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_leaf_write.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package list item set target writes');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package list item set target writes');
    ok(-s $hdl_path, 'CLI writes HDL for package list item set target writes');
};

subtest 'aggregate leaf write diagnostics stay scalar and direct' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_unknown_member_write
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input mode_in (width 2)))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (set frame.missing mode_in)))
ISF
        qr/invalid aggregate storage path 'frame\.missing': record member 'missing' is not declared; known members: mode, flag/,
        'unknown record member set target fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_subaggregate_write_still_deferred
  (types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (mode (bits 2)) (payload payload_t))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input payload_in (width 3)))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (set frame.payload payload_in)))
ISF
        qr/set target references aggregate storage path 'frame\.payload' that resolves to aggregate kind 'list'; this ISF slice accepts only scalar aggregate leaf writes/,
        'subaggregate set targets remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_condition_still_deferred
  (types
    (type frame_t (record (flag bit) (mode (bits 2)))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (when frame.flag
      (set done 1))))
ISF
        qr/when condition references aggregate storage path 'frame\.flag'; this ISF slice accepts aggregate storage paths only as direct transaction set RHS scalar leaf reads, direct transaction set target scalar leaf writes, transaction condition expression scalar operands, rule assignment RHS scalar values or operands, rule guard expression scalar operands, drive body RHS scalar values or operands, inline drive assignment RHS scalar values or operands, or drive-call actual scalar values or operands/,
        'aggregate paths outside direct transaction set positions remain deferred',
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
