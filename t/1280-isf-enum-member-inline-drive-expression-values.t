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

subtest 'actor-local enum members are valid inline drive RHS expression operands' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_inline_drive_expression_value.isf');
    write_file($isf_path, <<'ISF');
(actor local_enum_inline_drive_expression_value
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out (width 2)))
  (transaction main
    (on start)
    (drive inline_mode
      (mode_out (+ mode.BUSY 1)))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_enum_inline_drive_expression_value.fsm'};
    like($fsm, qr/\(\+enums\s+\(mode \(IDLE 0\) \(BUSY 1\)\)\s+\)/s,
        'scheduled .fsm preserves local enum declaration');
    like($fsm, qr/\(= \(mode_out> \(\+ mode\.BUSY 1\)\)\)/,
        'scheduled .fsm preserves local enum member inline drive RHS expression operand');

    my $hdl_path = File::Spec->catfile($dir, 'local_enum_inline_drive_expression_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local enum member inline drive RHS expression operands');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local enum member inline drive RHS expression operands');
    ok(-s $hdl_path, 'CLI writes HDL for local enum member inline drive RHS expression operands');
};

subtest 'package enum members are valid inline drive RHS expression operands' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_enum_inline_drive_expression_value.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_inline_drive_expression_value
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input mode_in (width 2))
    (output mode_out (width 2)))
  (transaction main
    (on start)
    (drive inline_mode
      (mode_out (+ shared.mode.BUSY mode_in)))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_enum_inline_drive_expression_value.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(= \(mode_out> \(\+ shared\.mode\.BUSY mode_in\)\)\)/,
        'scheduled .fsm preserves package enum member inline drive RHS expression operand');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+enums[\s\S]*\(mode \(IDLE 0\) \(BUSY 1\)\)/,
        'scheduled .fsm embeds imported enum package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_inline_drive_expression_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package enum member inline drive RHS expression operands');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package enum member inline drive RHS expression operands');
    ok(-s $hdl_path, 'CLI writes HDL for package enum member inline drive RHS expression operands');
};

subtest 'inline drive enum expression diagnostics stay operand-only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_enum_inline_drive_expression_value
  (enums
    (mode (IDLE 0)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out (width 2)))
  (transaction main
    (on start)
    (drive inline_mode
      (mode_out (+ mode.BUSY 1)))))
ISF
        qr/transaction 'main' inline drive RHS references unknown enum member 'mode\.BUSY'/,
        'unknown inline drive enum expression operand fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor enum_inline_drive_operator_still_deferred
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out (width 2)))
  (transaction main
    (on start)
    (drive inline_mode
      (mode_out (mode.BUSY 1)))))
ISF
        qr/transaction 'main' inline drive RHS expression operator references enum member 'mode\.BUSY'; this ISF slice accepts enum member references inside inline drive RHS expressions only as scalar operands/,
        'enum members in inline drive RHS expression operator position remain deferred',
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
