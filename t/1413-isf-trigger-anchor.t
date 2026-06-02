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

done_testing();
