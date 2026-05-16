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

subtest 'actor-local aggregate storage leaves are valid transaction condition expression operands' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_aggregate_condition_value.isf');
    write_file($isf_path, <<'ISF');
(actor local_aggregate_condition_value
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input ready)
    (input frame_in (width 3))
    (output fire)
    (output done))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (set frame frame_in)
    (when (& ready frame.flag)
      (set fire 1))
    (while (& ready (! frame.flag))
      (set fire 0))
    (until (& ready frame.flag)
      (complete done))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_aggregate_condition_value.fsm'};
    my $flag_condition_count = () = $fsm =~ /\(\?\(& ready frame\.flag\)/g;
    cmp_ok($flag_condition_count, '>=', 2,
        'scheduled .fsm preserves local aggregate leaf when and until condition expression operands');
    like($fsm, qr/\(\?\(& ready \(! frame\.flag\)\)/,
        'scheduled .fsm preserves local aggregate leaf while condition expression operand');

    my $hdl_path = File::Spec->catfile($dir, 'local_aggregate_condition_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local aggregate transaction condition operands');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local aggregate transaction condition operands');
    ok(-s $hdl_path, 'CLI writes HDL for local aggregate transaction condition operands');
};

subtest 'package aggregate storage leaves are valid transaction condition expression operands' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type lanes_t (list bit (bits 2))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_condition_value.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_condition_value
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input ready)
    (input lanes_in (width 3))
    (output fire)
    (output done))
  (storage
    (var lanes (type shared.lanes_t)))
  (transaction main
    (on start)
    (set lanes lanes_in)
    (when (& ready lanes[1])
      (set fire 1))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_condition_value.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\?\(& ready lanes\[1\]\)/,
        'scheduled .fsm preserves package aggregate leaf transaction condition expression operand');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+types[\s\S]*\(type lanes_t \(list bit \(bits 2\)\)\)/,
        'scheduled .fsm embeds imported aggregate package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_condition_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package aggregate transaction condition operands');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package aggregate transaction condition operands');
    ok(-s $hdl_path, 'CLI writes HDL for package aggregate transaction condition operands');
};

subtest 'transaction condition aggregate diagnostics stay expression-operand-only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_condition_unknown_member
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input ready)
    (output done))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (when (& ready frame.missing)
      (complete done))))
ISF
        qr/invalid aggregate storage path 'frame\.missing': record member 'missing' is not declared; known members: mode, flag/,
        'unknown record member transaction condition operand fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_condition_operator_path
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input ready)
    (output done))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (when (frame.flag ready)
      (complete done))))
ISF
        qr/transaction 'main' when condition expression operator references aggregate storage path 'frame\.flag'; this ISF slice accepts aggregate storage paths inside transaction condition expressions only as scalar operands/,
        'aggregate transaction condition expression operator paths remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_scalar_condition
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
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
      (complete done))))
ISF
        qr/transaction 'main' when condition references aggregate storage path 'frame\.flag'; this ISF slice accepts aggregate storage paths only as direct transaction set RHS scalar leaf reads, direct transaction set target scalar leaf writes, transaction condition expression scalar operands, rule assignment RHS scalar values or operands, rule guard expression scalar operands, or drive body RHS scalar values or operands/,
        'standalone aggregate transaction conditions remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_condition_subaggregate_operand
  (types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (mode (bits 2)) (payload payload_t))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input ready)
    (output done))
  (storage
    (var frame (type frame_t)))
  (transaction main
    (on start)
    (when (& ready frame.payload)
      (complete done))))
ISF
        qr/transaction 'main' when condition references aggregate storage path 'frame\.payload' that resolves to aggregate kind 'list'; this ISF slice accepts only scalar aggregate leaf reads/,
        'subaggregate transaction condition expression operands remain deferred',
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
