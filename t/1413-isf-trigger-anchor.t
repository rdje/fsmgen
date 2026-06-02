#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::IR::IntentHIRBuilder;
use FSM::Pipeline::GeneratedModuleInfoBuilder;
use FSM::Backend::GeneratedModuleEmitter;

# ISF-TRIGGER-ANCHOR (decision 0009): a bounded-eventually check names the point it is measured
# from with one of three trigger spellings over one engine `TRIGGER |-> (bounded-eventually) S`.
#
# Slice .2 — the "event" form `(after SIG CONS)` anchors the consequent to the rising edge of a
# signal: `(after start (within ack 3))` -> `$rose(start) |-> (##[1:3] (ack))`. A same-cycle
# boolean consequent is verilator-simulable; a delayed (within/next) consequent is formal-only.

my $tempdir = tempdir(CLEANUP => 1);

sub parsed_module {
    my ($source, $name) = @_;
    my $fsm = FSM::Scheduler::ISF->new()->lower(
        FSM::Adapter::ISF->new()->parse_source($source, "$name.isf"))->{files}{"$name.fsm"};
    my $path = File::Spec->catfile($tempdir, "$name.fsm");
    open my $fh, '>', $path or die $!; print $fh $fsm; close $fh;
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
}

sub parse_error {
    my ($source, $name) = @_;
    my $ok = eval { parsed_module($source, $name); 1 };
    return $ok ? '' : $@;
}

sub module_info_for {
    my ($module) = @_;
    my $intent = FSM::IR::IntentHIRBuilder->build_from_fsm_module(fsm_module => $module);
    return FSM::Pipeline::GeneratedModuleInfoBuilder->build_from_fsm_module(
        fsm_module => $module, intent_hir => $intent);
}

sub lower_fsm_text {
    my ($source, $name) = @_;
    return FSM::Scheduler::ISF->new()->lower(
        FSM::Adapter::ISF->new()->parse_source($source, "$name.isf"))->{files}{"$name.fsm"};
}

sub lower_error {
    my ($source, $name) = @_;
    my $ok = eval { lower_fsm_text($source, $name); 1 };
    return $ok ? '' : $@;
}

subtest 'event trigger (after SIG (within S N)) renders to $rose(SIG) |-> ##[1:N] (S) (formal-only)' => sub {
    my $module = parsed_module(<<'ISF', 'ev_within');
(actor ev_within
  (interface (input start) (input ack) (output done))
  (transaction main
    (on start)
    (assert (after start (within ack 3)) "ack within 3 of start")
    (complete done)))
ISF
    my $info = module_info_for($module);
    my $a = $info->{immediate_assertions};
    is(scalar(@$a), 1, 'one check');
    is($a->[0]{condition_sv}, '$rose(start) |-> (##[1:3] (ack))',
        'event trigger anchors the bounded consequent to the rising edge of start');
    ok($a->[0]{formal_only}, 'a delayed (within) consequent is formal-only');

    my @lines = FSM::Backend::GeneratedModuleEmitter->immediate_assertion_runtime_lines(
        module_info => $info, target_language => 'systemverilog');
    my $block = join("\n", @lines);
    like($block, qr/`ifdef FORMAL.*\$rose\(start\) \|-> \(##\[1:3\] \(ack\)\)/s,
        'the delayed event property goes under ifdef FORMAL');
};

subtest 'event trigger with a same-cycle boolean consequent is verilator-simulable' => sub {
    my $module = parsed_module(<<'ISF', 'ev_bool');
(actor ev_bool
  (interface (input start) (input ack) (output done))
  (transaction main
    (on start)
    (assert (after start ack) "ack on the start edge")
    (complete done)))
ISF
    my $info = module_info_for($module);
    is($info->{immediate_assertions}[0]{condition_sv}, '$rose(start) |-> (ack)',
        'same-cycle consequent renders without a ## delay');
    ok(!$info->{immediate_assertions}[0]{formal_only},
        'a same-cycle event implication is simulable (not formal-only)');

    my @lines = FSM::Backend::GeneratedModuleEmitter->immediate_assertion_runtime_lines(
        module_info => $info, target_language => 'systemverilog');
    like(join("\n", @lines), qr/`ifndef SYNTHESIS.*\$rose\(start\) \|-> \(ack\)/s,
        'the simulable event property goes under ifndef SYNTHESIS');
};

subtest 'simulable and formal-only event triggers are partitioned into separate guards' => sub {
    my $module = parsed_module(<<'ISF', 'ev_split');
(actor ev_split
  (interface (input start) (input ack) (output done))
  (transaction main
    (on start)
    (assert (after start ack) "edge")
    (assert (after start (within ack 2)) "bounded")
    (complete done)))
ISF
    my $info = module_info_for($module);
    my @lines = FSM::Backend::GeneratedModuleEmitter->immediate_assertion_runtime_lines(
        module_info => $info, target_language => 'systemverilog');
    my $block = join("\n", @lines);
    like($block, qr/`ifndef SYNTHESIS.*\$rose\(start\) \|-> \(ack\).*`endif.*`ifdef FORMAL.*##\[1:2\]/s,
        'same-cycle event under ifndef SYNTHESIS; the bounded one under ifdef FORMAL');
};

subtest 'a signal used only inside an event trigger is kept alive as a port' => sub {
    my $module = parsed_module(<<'ISF', 'ev_keep');
(actor ev_keep
  (interface (input start) (input go) (input ack) (output done))
  (transaction main (on start) (assert (after go (within ack 3))) (complete done)))
ISF
    my $signals = $module->signals;
    for my $name (qw(go ack)) {
        my $role = $signals->{$name} && $signals->{$name}->can('get_attribute')
            ? $signals->{$name}->get_attribute('signal_role') : undef;
        is($role, 'INPUT', "$name (only inside the event trigger) is kept as an INPUT port");
    }
};

subtest 'a malformed event trigger fails closed' => sub {
    like(parse_error(
        "(actor one (interface (input start) (input ack) (output done)) "
        . "(transaction main (on start) (assert (after start)) (complete done)))", 'one'),
        qr/requires a trigger signal and a consequent/,
        '(after start) with no consequent is rejected');
};

# ---- Slice .3: synthesizable-monitor output-mode (monitor (within S N)) ----
#
# `(assert (monitor (within S N)))` placed in a transaction body anchors a bounded-eventually to
# its own position: an arm state pulses where the clause sits, a synthesizable monitor (arm/age/fail)
# watches S within N cycles, and the check asserts `(! fail)` — a same-cycle boolean, so the temporal
# logic is in hardware and the assertion is verilator-simulable. Reuses contract's monitor engine.

my $MON_SRC = <<'ISF';
(actor mon
  (clock clk) (reset rst_n)
  (interface (input start) (input ack) (output done))
  (transaction main
    (on start)
    (assert (monitor (within ack 3)) "ack within 3 of arming")
    (complete done)))
ISF

subtest 'monitor output-mode lowers to an arm state + monitor DT + a (! fail) assert' => sub {
    my $fsm = lower_fsm_text($MON_SRC, 'mon');
    like($fsm, qr/\(main_assert_1_arm 1\)/, 'an arm state pulses where the monitored check sits');
    like($fsm, qr/\(-main_assert_1_monitor/, 'a synthesizable monitor DT (arm/pending/age/fail) is generated');
    like($fsm, qr/\Q(main_assert_1_holds assert (! main_assert_1_fail) "ack within 3 of arming")\E/,
        'the check asserts the monitor never fails');
};

subtest 'the (! fail) assertion is same-cycle boolean (verilator-simulable, not formal-only)' => sub {
    my $module = parsed_module($MON_SRC, 'mon');
    my $info = module_info_for($module);
    my ($a) = grep { $_->{name} eq 'main_assert_1_holds' } @{$info->{immediate_assertions}};
    ok($a, 'the monitor !fail check surfaces in module_info');
    is($a->{condition_sv}, '!(main_assert_1_fail)', 'asserts the negated fail bit');
    ok(!$a->{formal_only}, 'a same-cycle boolean -> simulable, not under ifdef FORMAL');
};

subtest 'the monitor registers are internal (the !fail reference does not promote fail to a port)' => sub {
    my $module = parsed_module($MON_SRC, 'mon');
    my $signals = $module->signals;
    for my $internal (qw(main_assert_1_fail main_assert_1_arm main_assert_1_age main_assert_1_pending)) {
        my $role = $signals->{$internal} && $signals->{$internal}->can('get_attribute')
            ? $signals->{$internal}->get_attribute('signal_role') : undef;
        isnt($role, 'INPUT', "$internal stays an internal monitor register (not an INPUT port)");
    }
};

subtest 'monitor window resolves a transaction/actor parameter (parity with contract windows)' => sub {
    my $src = <<'ISF';
(actor mw
  (clock clk) (reset rst_n)
  (params (ACTOR_WIN 8))
  (interface (input start) (input ack) (output done))
  (transaction main
    (params (ACK_WINDOW 4))
    (on start)
    (assert (monitor (within ack ACK_WINDOW)) "tx param window")
    (assert (monitor (within ack ACTOR_WIN)) "actor param window")
    (complete done)))
ISF
    my $fsm = lower_fsm_text($src, 'mw');
    like($fsm, qr/\(== main_assert_1_age 3\)/, 'transaction param ACK_WINDOW=4 -> monitor expiry at age 3');
    like($fsm, qr/\(== main_assert_2_age 7\)/, 'actor param ACTOR_WIN=8 -> monitor expiry at age 7');
};

subtest 'a malformed monitor output-mode fails closed' => sub {
    like(lower_error(
        "(actor a (clock clk) (reset rst_n) (interface (input start) (input ack) (output done)) "
        . "(transaction main (on start) (assert (monitor (within ack 0))) (complete done)))", 'a'),
        qr/N must be a positive integer/,
        '(monitor (within ack 0)) with a zero bound is rejected');
    like(lower_error(
        "(actor b (clock clk) (reset rst_n) (interface (input start) (input ack) (output done)) "
        . "(transaction main (on start) (assert (monitor (within nope 3))) (complete done)))", 'b'),
        qr/is not an actor interface signal/,
        '(monitor (within nope 3)) over a non-interface signal is rejected');
    like(lower_error(
        "(actor c (clock clk) (reset rst_n) (interface (input start) (input ack) (output done)) "
        . "(transaction main (on start) (assert (monitor (eventually ack))) (complete done)))", 'c'),
        qr/supports only '\(monitor \(within SIGNAL N\)\)'/,
        '(monitor (eventually …)) — unsupported inner property is rejected');
};

done_testing();
