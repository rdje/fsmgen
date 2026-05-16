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
use FSM::Scheduler::ISF::LoweringIR;

subtest 'actor-local enum members are valid explicit rule assignment RHS values' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_enum_rule_value.isf');
    write_file($isf_path, <<'ISF');
(actor local_enum_rule_value
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (output mode_out (width 2)))
  (rule mark_busy ready
    (set mode_out mode.BUSY)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_enum_rule_value.fsm'};
    like($fsm, qr/\(\+enums\s+\(mode \(IDLE 0\) \(BUSY 1\)\)\s+\)/s,
        'scheduled .fsm preserves local enum declaration');
    like($fsm, qr/\(-mark_busy\s+<ready\s+\(<- \(mode_out> mode\.BUSY\)\)\s+\)/s,
        'scheduled .fsm preserves local enum member rule RHS value');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $record = find_record($ir, target => 'mode_out', source_kind => 'rule_action');
    is($record->{rhs}, 'mode.BUSY', 'assignment provenance records authored enum RHS value');
    is($record->{operator}, '<-', 'rule enum assignment keeps flopped operator');
    is($record->{domain}, 'data', 'rule enum assignment remains in the data domain');

    my $hdl_path = File::Spec->catfile($dir, 'local_enum_rule_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local enum member rule RHS values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local enum member rule RHS values');
    ok(-s $hdl_path, 'CLI writes HDL for local enum member rule RHS values');
};

subtest 'package enum members are valid shorthand rule assignment RHS values' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+enums
    (mode (IDLE 0) (BUSY 1)))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_enum_rule_value.isf');
    write_file($isf_path, <<'ISF');
(actor package_enum_rule_value
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (output mode_out (width 2)))
  (rule mark_busy ready
    (mode_out shared.mode.BUSY)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_enum_rule_value.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(-mark_busy\s+<ready\s+\(<- \(mode_out> shared\.mode\.BUSY\)\)\s+\)/s,
        'scheduled .fsm preserves package enum member shorthand rule RHS value');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+enums[\s\S]*\(mode \(IDLE 0\) \(BUSY 1\)\)/,
        'scheduled .fsm embeds imported enum package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_enum_rule_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package enum member rule RHS values');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package enum member rule RHS values');
    ok(-s $hdl_path, 'CLI writes HDL for package enum member rule RHS values');
};

subtest 'rule enum diagnostics preserve guard and target boundaries' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_enum_rule_value
  (enums
    (mode (IDLE 0)))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (output mode_out (width 2)))
  (rule mark_busy ready
    (set mode_out mode.BUSY)))
ISF
        qr/rule 'mark_busy' assignment RHS references unknown enum member 'mode\.BUSY'/,
        'unknown rule enum RHS fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor enum_rule_guard_still_deferred
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (output mode_out (width 2)))
  (rule mark_busy mode.BUSY
    (set mode_out 1)))
ISF
        qr/rule 'mark_busy' guard references enum member 'mode\.BUSY'; this ISF surface accepts enum member references only as actor constants, actor scalar parameter defaults, transaction scalar parameter defaults, activation scalar parameter overrides, transaction set RHS scalar values or operands, transaction switch branch values, rule guard expression operands, rule assignment RHS scalar values or operands, drive body RHS scalar values, and drive-call actual scalar values or operands/,
        'enum members in rule guards remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor enum_rule_target_still_deferred
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (output mode_out (width 2)))
  (rule mark_busy ready
    (set mode.BUSY 1)))
ISF
        qr/rule 'mark_busy' set action requires '\(set port expr\)'/,
        'enum-looking rule targets remain ordinary invalid set targets',
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

sub find_record {
    my ($ir, %want) = @_;
    RECORD:
    for my $record (@{$ir->{assignment_provenance} || []}) {
        for my $key (sort keys %want) {
            next RECORD unless defined($record->{$key}) && $record->{$key} eq $want{$key};
        }
        return $record;
    }
    fail('found provenance record for ' . join(', ', map { "$_=$want{$_}" } sort keys %want));
    return {};
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content;
    close $fh or die "close $path: $!";
    return $path;
}
