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

subtest 'actor-local enum members are valid transaction switch selectors' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_switch_selector.isf');
    write_file($isf_path, <<'ISF');
(actor local_enum_switch_selector
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output seen)
    (output done))
  (transaction main
    (on start)
    (switch mode.BUSY
      (1
        (set seen 1))
      (default
        (set seen 0)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_enum_switch_selector.fsm'};
    like($fsm, qr/\(\+enums\s+\(mode \(IDLE 0\) \(BUSY 1\)\)\s+\)/s,
        'scheduled .fsm preserves local enum declaration');
    like($fsm, qr/\(\?\(mode\.BUSY\)\s+.*?\(=1 \(-> main_set_\d+\)\)/s,
        'scheduled .fsm emits local enum member switch selector through computed selector syntax');

    my $hdl_path = File::Spec->catfile($dir, 'local_enum_switch_selector.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local enum member switch selectors');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local enum member switch selectors');
    ok(-s $hdl_path, 'CLI writes HDL for local enum member switch selectors');
};

subtest 'package enum members are valid transaction switch selectors' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_enum_switch_selector.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_switch_selector
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output seen)
    (output done))
  (transaction main
    (on start)
    (switch shared.mode.BUSY
      (1
        (set seen 1))
      (default
        (set seen 0)))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_enum_switch_selector.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\?\(shared\.mode\.BUSY\)\s+.*?\(=1 \(-> main_set_\d+\)\)/s,
        'scheduled .fsm emits package enum member switch selector through computed selector syntax');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+enums[\s\S]*\(mode \(IDLE 0\) \(BUSY 1\)\)/,
        'scheduled .fsm embeds imported enum package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_switch_selector.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package enum member switch selectors');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package enum member switch selectors');
    ok(-s $hdl_path, 'CLI writes HDL for package enum member switch selectors');
};

subtest 'switch enum selector diagnostics stay resolved-member only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_enum_switch_selector
  (enums
    (mode (IDLE 0)))
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
        qr/transaction 'main' switch selector references unknown enum member 'mode\.BUSY'/,
        'unknown enum member switch selector fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor enum_condition_still_deferred_after_switch_selector
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
        qr/when condition references enum member 'mode\.BUSY'; this ISF surface accepts enum member references only as actor constants, actor scalar parameter defaults or aggregate\/list parameter default leaves, transaction scalar parameter defaults or aggregate\/list parameter default leaves, activation scalar parameter overrides or aggregate\/list override leaves, reusable-library use-site parameter override values or leaves, transaction condition expression operands, transaction set RHS scalar values or operands, transaction switch selector or branch values, rule guard expression operands, rule assignment RHS scalar values or operands, drive body RHS scalar values or operands, inline drive assignment RHS scalar values or operands, and drive-call actual scalar values or operands/,
        'standalone enum conditions remain deferred',
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
}
