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

subtest 'actor-local aggregate storage record members are valid transaction set RHS leaves' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_aggregate_leaf_read.isf');
    write_file($isf_path, <<'ISF');
(actor local_aggregate_leaf_read
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
  (transaction main
    (on start)
    (set frame frame_in)
    (set mode_out frame.mode)
    (set flag_out frame.flag)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'record', 'record carrier type resolves before leaf validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_aggregate_leaf_read.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(frame frame_t\)/,
        'scheduled .fsm preserves aggregate carrier type');
    like($fsm, qr/\(<- \(mode_out>? frame\.mode\)\)/,
        'scheduled .fsm preserves record member RHS access');
    like($fsm, qr/\(<- \(flag_out>? frame\.flag\)\)/,
        'scheduled .fsm preserves one-bit record member RHS access');

    my $hdl_path = File::Spec->catfile($dir, 'local_aggregate_leaf_read.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for record member set RHS reads');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for record member set RHS reads');
    ok(-s $hdl_path, 'CLI writes HDL for record member set RHS reads');
};

subtest 'package aggregate storage list items are valid transaction set RHS leaves' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type lanes_t (list bit (bits 2))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_leaf_read.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_leaf_read
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
  (transaction main
    (on start)
    (set lanes lanes_in)
    (set bit_out lanes[0])
    (set pair_out lanes[1])))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'list', 'package list carrier type resolves before leaf validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_leaf_read.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(<- \(bit_out>? lanes\[0\]\)\)/,
        'scheduled .fsm preserves list item RHS access');
    like($fsm, qr/\(<- \(pair_out>? lanes\[1\]\)\)/,
        'scheduled .fsm preserves multi-bit list item RHS access');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_leaf_read.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package list item set RHS reads');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package list item set RHS reads');
    ok(-s $hdl_path, 'CLI writes HDL for package list item set RHS reads');
};

subtest 'aggregate leaf read diagnostics remain bounded to transaction set RHS' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_unknown_member_read
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
    (set mode_out frame.missing)))
ISF
        qr/invalid aggregate storage path 'frame\.missing': record member 'missing' is not declared; known members: mode, flag/,
        'unknown record member fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_expr_still_deferred
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
    (set mode_out (+ frame.mode 1))))
ISF
        qr/set RHS references aggregate storage path 'frame\.mode'; this ISF slice accepts aggregate storage paths only as direct transaction set RHS scalar leaf reads or direct transaction set target scalar leaf writes/,
        'aggregate paths inside expressions remain deferred',
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
