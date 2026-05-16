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

subtest 'actor-local aggregate storage leaves are valid set RHS expression operands' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_aggregate_leaf_expr_read.isf');
    write_file($isf_path, <<'ISF');
(actor local_aggregate_leaf_expr_read
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input frame_in (width 3))
    (input mode_in (width 2))
    (output mode_out (width 2)))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (set frame frame_in)
    (set mode_out (+ frame.mode mode_in))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'record', 'record carrier type resolves before expression leaf validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_aggregate_leaf_expr_read.fsm'};
    like($fsm, qr/\(<- \(mode_out>? \(\+ frame\.mode mode_in\)\)\)/,
        'scheduled .fsm preserves record member operand inside set RHS expression');

    my $hdl_path = File::Spec->catfile($dir, 'local_aggregate_leaf_expr_read.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for record member expression reads');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for record member expression reads');
    ok(-s $hdl_path, 'CLI writes HDL for record member expression reads');
};

subtest 'package aggregate storage leaves are valid nested set RHS expression operands' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type lanes_t (list bit (bits 2))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_leaf_expr_read.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_leaf_expr_read
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input lanes_in (width 3))
    (input pair_in (width 2))
    (output pair_out (width 2)))
  (storage
    (var lanes (type shared.lanes_t)))
  (transaction main
    (on start)
    (set lanes lanes_in)
    (set pair_out (^ lanes[1] pair_in))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{storage}[0]{type_spec}{kind}, 'list', 'package list carrier type resolves before expression leaf validation');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_leaf_expr_read.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(<- \(pair_out>? \(\^ lanes\[1\] pair_in\)\)\)/,
        'scheduled .fsm preserves list item operand inside set RHS expression');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_leaf_expr_read.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package list item expression reads');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package list item expression reads');
    ok(-s $hdl_path, 'CLI writes HDL for package list item expression reads');
};

subtest 'aggregate expression read diagnostics stay scalar operand only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_expr_unknown_member
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
    (set mode_out (+ frame.missing 1))))
ISF
        qr/invalid aggregate storage path 'frame\.missing': record member 'missing' is not declared; known members: mode, flag/,
        'unknown record member inside expression fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_expr_operator_path
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
    (set mode_out (frame.mode 1))))
ISF
        qr/set RHS expression operator references aggregate storage path 'frame\.mode'; this ISF slice accepts aggregate storage paths inside set RHS expressions only as scalar operands/,
        'aggregate paths are rejected in expression operator position',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_expr_subaggregate_operand
  (types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (mode (bits 2)) (payload payload_t))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out (width 2)))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (set mode_out (+ frame.payload 1))))
ISF
        qr/set RHS references aggregate storage path 'frame\.payload' that resolves to aggregate kind 'list'; this ISF slice accepts only scalar aggregate leaf reads/,
        'subaggregate expression operands remain deferred',
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
