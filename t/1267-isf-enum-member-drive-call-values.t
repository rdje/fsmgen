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

subtest 'actor-local enum members are valid scalar drive call actual values' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_drive_call_value.isf');
    write_file($isf_path, <<'ISF');
(actor local_enum_drive_call_value
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out (width 2)))
  (drive (mark_mode value)
    (mode_out value))
  (transaction main
    (on start)
    (drive mark_mode mode.BUSY)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_enum_drive_call_value.fsm'};
    like($fsm, qr/\(\+enums\s+\(mode \(IDLE 0\) \(BUSY 1\)\)\s+\)/s,
        'scheduled .fsm preserves local enum declaration');
    like($fsm, qr/\(= \(mark_mode_value mode\.BUSY\)\)/,
        'scheduled .fsm preserves local enum member drive call actual value');
    like($fsm, qr/\(-mark_mode\s+\(<- \(mode_out> mark_mode_value\) <mark_mode_start\)\s+\)/s,
        'scheduled .fsm routes the drive parameter through the drive body');

    my $hdl_path = File::Spec->catfile($dir, 'local_enum_drive_call_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local enum member drive call actual values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local enum member drive call actual values');
    ok(-s $hdl_path, 'CLI writes HDL for local enum member drive call actual values');
};

subtest 'package enum members are valid scalar drive call actual values' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_enum_drive_call_value.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_drive_call_value
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out (width 2)))
  (drive (mark_mode value)
    (mode_out value))
  (transaction main
    (on start)
    (drive mark_mode shared.mode.BUSY)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_enum_drive_call_value.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(= \(mark_mode_value shared\.mode\.BUSY\)\)/,
        'scheduled .fsm preserves package enum member drive call actual value');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+enums[\s\S]*\(mode \(IDLE 0\) \(BUSY 1\)\)/,
        'scheduled .fsm embeds imported enum package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_drive_call_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package enum member drive call actual values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package enum member drive call actual values');
    ok(-s $hdl_path, 'CLI writes HDL for package enum member drive call actual values');
};

subtest 'drive call enum diagnostics stay scalar-actual only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_enum_drive_call_value
  (enums
    (mode (IDLE 0)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out (width 2)))
  (drive (mark_mode value)
    (mode_out value))
  (transaction main
    (on start)
    (drive mark_mode mode.BUSY)))
ISF
        qr/transaction 'main' drive 'mark_mode' actual references unknown enum member 'mode\.BUSY'/,
        'unknown drive call enum actual fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor enum_inline_drive_still_deferred
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
      (mode_out mode.BUSY))))
ISF
        qr/transaction 'main' references enum member 'mode\.BUSY'; this ISF surface accepts enum member references only as actor constants, actor scalar parameter defaults, transaction set RHS scalar values or operands, transaction switch branch values, drive body RHS scalar values, and drive-call actual scalar values or operands/,
        'enum members in inline drive assignments remain deferred',
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
