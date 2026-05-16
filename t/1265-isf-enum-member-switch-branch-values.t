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

subtest 'actor-local enum members are valid transaction switch branch values' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_switch_branch_value.isf');
    write_file($isf_path, <<'ISF');
(actor local_enum_switch_branch_value
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input mode_in (width 2))
    (output seen)
    (output done))
  (transaction main
    (on start)
    (switch mode_in
      (mode.BUSY
        (set seen 1))
      (default
        (set seen 0)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_enum_switch_branch_value.fsm'};
    like($fsm, qr/\(\+enums\s+\(mode \(IDLE 0\) \(BUSY 1\)\)\s+\)/s,
        'scheduled .fsm preserves local enum declaration');
    like($fsm, qr/\(\?mode_in\s+.*?\(=mode\.BUSY \(-> main_set_\d+\)\)/s,
        'scheduled .fsm preserves local enum member switch branch value');

    my $hdl_path = File::Spec->catfile($dir, 'local_enum_switch_branch_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local enum member switch branch values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local enum member switch branch values');
    ok(-s $hdl_path, 'CLI writes HDL for local enum member switch branch values');
};

subtest 'package enum members are valid transaction switch branch values' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_enum_switch_branch_value.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_switch_branch_value
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input mode_in (width 2))
    (output seen)
    (output done))
  (transaction main
    (on start)
    (switch mode_in
      (shared.mode.BUSY
        (set seen 1))
      (default
        (set seen 0)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_enum_switch_branch_value.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\?mode_in\s+.*?\(=shared\.mode\.BUSY \(-> main_set_\d+\)\)/s,
        'scheduled .fsm preserves package enum member switch branch value');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+enums[\s\S]*\(mode \(IDLE 0\) \(BUSY 1\)\)/,
        'scheduled .fsm embeds imported enum package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_switch_branch_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package enum member switch branch values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package enum member switch branch values');
    ok(-s $hdl_path, 'CLI writes HDL for package enum member switch branch values');
};

subtest 'switch enum diagnostics stay branch-value only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_enum_switch_branch_value
  (enums
    (mode (IDLE 0)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input mode_in (width 2))
    (output seen))
  (transaction main
    (on start)
    (switch mode_in
      (mode.BUSY
        (set seen 1)))))
ISF
        qr/transaction 'main' switch branch value references unknown enum member 'mode\.BUSY'/,
        'unknown enum member switch branch value fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor enum_switch_selector_still_deferred
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output seen))
  (transaction main
    (on start)
    (switch mode.BUSY
      (1
        (set seen 1)))))
ISF
        qr/switch selector references enum member 'mode\.BUSY'; this ISF surface accepts enum member references only as actor constants, actor scalar parameter defaults or aggregate\/list parameter default leaves, transaction scalar parameter defaults or aggregate\/list parameter default leaves, activation scalar parameter overrides or aggregate\/list override leaves, transaction condition expression operands, transaction set RHS scalar values or operands, transaction switch branch values, rule guard expression operands, rule assignment RHS scalar values or operands, drive body RHS scalar values, inline drive assignment RHS scalar values or operands, and drive-call actual scalar values or operands/,
        'enum members in switch selectors remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor enum_condition_still_deferred_after_switch
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output seen))
  (transaction main
    (on start)
    (when mode.BUSY
      (set seen 1))))
ISF
        qr/when condition references enum member 'mode\.BUSY'; this ISF surface accepts enum member references only as actor constants, actor scalar parameter defaults or aggregate\/list parameter default leaves, transaction scalar parameter defaults or aggregate\/list parameter default leaves, activation scalar parameter overrides or aggregate\/list override leaves, transaction condition expression operands, transaction set RHS scalar values or operands, transaction switch branch values, rule guard expression operands, rule assignment RHS scalar values or operands, drive body RHS scalar values, inline drive assignment RHS scalar values or operands, and drive-call actual scalar values or operands/,
        'enum members in conditions remain deferred',
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
