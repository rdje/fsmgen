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

subtest 'actor-local enum members are valid standalone transaction conditions' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_standalone_condition.isf');
    write_file($isf_path, <<'ISF');
(actor local_enum_standalone_condition
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output fire)
    (output done))
  (transaction main
    (on start)
    (when mode.BUSY
      (set fire 1))
    (while mode.BUSY
      (set fire 0))
    (until mode.BUSY
      (complete done))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_enum_standalone_condition.fsm'};
    like($fsm, qr/\(\+enums\s+\(mode \(IDLE 0\) \(BUSY 1\)\)\s+\)/s,
        'scheduled .fsm preserves local enum declaration');
    my $busy_condition_count = () = $fsm =~ /\(\?\(mode\.BUSY\)/g;
    is($busy_condition_count, 4,
        'scheduled .fsm uses computed selectors for standalone local enum member conditions and loop recheck');

    my $hdl_path = File::Spec->catfile($dir, 'local_enum_standalone_condition.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local standalone enum conditions');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local standalone enum conditions');
    ok(-s $hdl_path, 'CLI writes HDL for local standalone enum conditions');
};

subtest 'package enum members are valid standalone transaction conditions' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_enum_standalone_condition.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_standalone_condition
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output fire)
    (output done))
  (transaction main
    (on start)
    (when shared.mode.BUSY
      (set fire 1))
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_enum_standalone_condition.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\?\(shared\.mode\.BUSY\)/,
        'scheduled .fsm uses computed selector for standalone package enum condition');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+enums[\s\S]*\(mode \(IDLE 0\) \(BUSY 1\)\)/,
        'scheduled .fsm embeds imported enum package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_standalone_condition.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package standalone enum conditions');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package standalone enum conditions');
    ok(-s $hdl_path, 'CLI writes HDL for package standalone enum conditions');
};

subtest 'standalone enum condition diagnostics stay resolved-member-only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor enum_standalone_condition_unknown_member
  (enums
    (mode (IDLE 0)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (when mode.BUSY
      (complete done))))
ISF
        qr/transaction 'main' when condition references unknown enum member 'mode\.BUSY'/,
        'unknown standalone enum condition fails before lowering',
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
