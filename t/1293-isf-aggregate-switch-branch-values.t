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

subtest 'actor-local aggregate storage leaves are valid transaction switch branch values' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_aggregate_switch_branch_value.isf');
    write_file($isf_path, <<'ISF');
(actor local_aggregate_switch_branch_value
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input frame_in (width 3))
    (input mode_in (width 2))
    (output seen)
    (output done))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (set frame frame_in)
    (switch mode_in
      (frame.mode
        (set seen 1))
      (default
        (set seen 0)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'record', 'record carrier type resolves before switch branch validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_aggregate_switch_branch_value.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(frame frame_t\)/,
        'scheduled .fsm preserves aggregate carrier type');
    like($fsm, qr/\(\?mode_in\s+.*?\(=frame\.mode \(-> main_set_\d+\)\)/s,
        'scheduled .fsm preserves record member switch branch value');

    my $hdl_path = File::Spec->catfile($dir, 'local_aggregate_switch_branch_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local aggregate switch branch values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local aggregate switch branch values');
    ok(-s $hdl_path, 'CLI writes HDL for local aggregate switch branch values');
};

subtest 'package aggregate storage leaves are valid transaction switch branch values' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type lanes_t (list bit (bits 2))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_switch_branch_value.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_switch_branch_value
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input lanes_in (width 3))
    (input pair_in (width 2))
    (output seen)
    (output done))
  (storage
    (var lanes (type shared.lanes_t)))
  (transaction main
    (on start)
    (set lanes lanes_in)
    (switch pair_in
      (lanes[1]
        (set seen 1))
      (default
        (set seen 0)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'list', 'package list carrier type resolves before switch branch validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_switch_branch_value.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\?pair_in\s+.*?\(=lanes\[1\] \(-> main_set_\d+\)\)/s,
        'scheduled .fsm preserves package list item switch branch value');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+types[\s\S]*\(type lanes_t \(list bit \(bits 2\)\)\)/,
        'scheduled .fsm embeds imported aggregate package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_switch_branch_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package aggregate switch branch values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package aggregate switch branch values');
    ok(-s $hdl_path, 'CLI writes HDL for package aggregate switch branch values');
};

subtest 'switch aggregate diagnostics stay branch-value only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_switch_branch_unknown_member
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input mode_in (width 2))
    (output seen))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (switch mode_in
      (frame.missing
        (set seen 1)))))
ISF
        qr/transaction 'main' switch branch value references invalid aggregate storage path 'frame\.missing': record member 'missing' is not declared; known members: mode, flag/,
        'unknown record member switch branch value fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_switch_selector_still_deferred
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output seen))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (switch frame.mode
      (1
        (set seen 1)))))
ISF
        qr/switch selector references aggregate storage path 'frame\.mode'; this ISF slice accepts aggregate storage paths only as direct transaction set RHS scalar leaf reads, direct transaction set target scalar leaf writes, transaction condition expression scalar operands, transaction switch branch scalar values, rule assignment RHS scalar values or operands, rule guard expression scalar operands, drive body RHS scalar values or operands, inline drive assignment RHS scalar values or operands, or drive-call actual scalar values or operands/,
        'aggregate storage leaves in switch selectors remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_switch_branch_subaggregate_value
  (types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (mode (bits 2)) (payload payload_t))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input mode_in (width 2))
    (output seen))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (switch mode_in
      (frame.payload
        (set seen 1)))))
ISF
        qr/transaction 'main' switch branch value references aggregate storage path 'frame\.payload' that resolves to aggregate kind 'list'; this ISF slice accepts only scalar aggregate leaf reads/,
        'subaggregate switch branch values remain deferred',
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
