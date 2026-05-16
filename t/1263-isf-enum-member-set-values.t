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

subtest 'actor-local enum members are valid direct transaction set RHS values' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_set_value.isf');
    write_file($isf_path, <<'ISF');
(actor local_enum_set_value
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out))
  (transaction main
    (on start)
    (set mode_out mode.BUSY)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_enum_set_value.fsm'};
    like($fsm, qr/\(\+enums\s+\(mode \(IDLE 0\) \(BUSY 1\)\)\s+\)/s,
        'scheduled .fsm preserves local enum declaration');
    like($fsm, qr/\(<- \(mode_out>? mode\.BUSY\)\)/,
        'scheduled .fsm preserves local enum member set RHS value');

    my $hdl_path = File::Spec->catfile($dir, 'local_enum_set_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local enum member set RHS values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local enum member set RHS values');
    ok(-s $hdl_path, 'CLI writes HDL for local enum member set RHS values');
};

subtest 'package enum members are valid direct transaction set RHS values' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_enum_set_value.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_set_value
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out))
  (transaction main
    (on start)
    (set mode_out shared.mode.BUSY)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_enum_set_value.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(<- \(mode_out>? shared\.mode\.BUSY\)\)/,
        'scheduled .fsm preserves package enum member set RHS value');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+enums[\s\S]*\(mode \(IDLE 0\) \(BUSY 1\)\)/,
        'scheduled .fsm embeds imported enum package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_set_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package enum member set RHS values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package enum member set RHS values');
    ok(-s $hdl_path, 'CLI writes HDL for package enum member set RHS values');
};

subtest 'enum member value diagnostics stay direct set RHS only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_enum_set_value
  (enums
    (mode (IDLE 0)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out))
  (transaction main
    (on start)
    (set mode_out mode.BUSY)))
ISF
        qr/transaction 'main' set RHS references unknown enum member 'mode\.BUSY'/,
        'unknown enum member set RHS fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor enum_operator_still_deferred
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out (width 2)))
  (transaction main
    (on start)
    (set mode_out (mode.BUSY 1))))
ISF
        qr/set RHS expression operator references enum member 'mode\.BUSY'; this ISF slice accepts enum member references inside set RHS expressions only as scalar operands/,
        'enum members in expression operator position remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor enum_set_target_still_deferred
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output mode_out))
  (transaction main
    (on start)
    (set mode.BUSY 1)))
ISF
        qr/set target references enum member 'mode\.BUSY'; this ISF surface accepts enum member references only as actor constants, actor scalar parameter defaults or aggregate\/list parameter default leaves, transaction scalar parameter defaults or aggregate\/list parameter default leaves, activation scalar parameter overrides or aggregate\/list override leaves, reusable-library use-site parameter override values or leaves, transaction condition scalar values or expression operands, transaction set RHS scalar values or operands, transaction switch selector or branch values, rule guard scalar values or expression operands, rule assignment RHS scalar values or operands, drive body RHS scalar values or operands, inline drive assignment RHS scalar values or operands, and drive-call actual scalar values or operands/,
        'enum members in set targets remain deferred',
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
