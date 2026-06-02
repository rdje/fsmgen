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

# ISF-ASSERT.3
#
# `(assert COND [message])` is projected to a verification-only SV assertion. This guards the
# two backend units that turn the parsed `+assert` invariant into HDL:
#   - GeneratedModuleInfoBuilder surfaces module->{attributes}{immediate_assertions} into
#     module_info as plain { name, condition_sv, message } records (COND rendered to SV here);
#   - GeneratedModuleEmitter::immediate_assertion_runtime_lines emits, under `ifndef SYNTHESIS`,
#     a combinational `assert (COND) else \$error("message")` per invariant.
# (The full pipeline ISF -> .fsm -> SV emission + a verilator --binary fires-on-violation run
#  is verified manually; here we unit-test the surfacing + emission.)

my $tempdir = tempdir(CLEANUP => 1);

sub parsed_module {
    my ($source, $name) = @_;
    my $fsm = FSM::Scheduler::ISF->new()->lower(
        FSM::Adapter::ISF->new()->parse_source($source, "$name.isf"))->{files}{"$name.fsm"};
    my $path = File::Spec->catfile($tempdir, "$name.fsm");
    open my $fh, '>', $path or die $!; print $fh $fsm; close $fh;
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
}

sub module_info_for {
    my ($module) = @_;
    my $intent = FSM::IR::IntentHIRBuilder->build_from_fsm_module(fsm_module => $module);
    return FSM::Pipeline::GeneratedModuleInfoBuilder->build_from_fsm_module(
        fsm_module => $module, intent_hir => $intent);
}

subtest 'GeneratedModuleInfoBuilder surfaces immediate_assertions with the condition rendered to SV' => sub {
    my $module = parsed_module(<<'ISF', 'em');
(actor em
  (interface (input start) (input a (width 8)) (output done) (output o (width 8)))
  (transaction main
    (on start)
    (update o a)
    (assert (< o 200) "o must stay below 200")
    (complete done)))
ISF
    my $info = module_info_for($module);
    my $asserts = $info->{immediate_assertions};
    is(ref($asserts), 'ARRAY', 'module_info carries immediate_assertions');
    is(scalar(@$asserts), 1, 'one assertion');
    is($asserts->[0]{name}, 'main_assert_0', 'name surfaced');
    is($asserts->[0]{condition_sv}, 'o < 200', 'condition rendered to SV text');
    is($asserts->[0]{message}, 'o must stay below 200', 'message surfaced');
};

subtest 'immediate_assertion_runtime_lines emits a verification-only SV assertion' => sub {
    my $module = parsed_module(<<'ISF', 'em2');
(actor em2
  (interface (input start) (input a (width 8)) (output done) (output o (width 8)))
  (transaction main (on start) (update o a) (assert (< o 200) "o below 200") (complete done)))
ISF
    my $info = module_info_for($module);
    my @lines = FSM::Backend::GeneratedModuleEmitter->immediate_assertion_runtime_lines(
        module_info => $info, target_language => 'systemverilog');
    my $block = join("\n", @lines);
    like($block, qr/`ifndef SYNTHESIS/, 'guarded for verification only');
    like($block, qr/always_comb begin/, 'combinational invariant block');
    my $expect_assert = 'assert (o < 200) else $error("o below 200");';  # single-quoted: $error is literal
    like($block, qr/\Q$expect_assert\E/, 'the assert with the condition + message');
    like($block, qr/`endif/, 'closed guard');

    # Verilog (non-SV) target emits nothing.
    my @v = FSM::Backend::GeneratedModuleEmitter->immediate_assertion_runtime_lines(
        module_info => $info, target_language => 'verilog');
    is(scalar(@v), 0, 'no assertion lines for the Verilog target (kept assertion-free)');
};

subtest 'a default message is synthesized when none is given' => sub {
    my $module = parsed_module(<<'ISF', 'em3');
(actor em3
  (interface (input start) (input a (width 8)) (output done) (output o (width 8)))
  (transaction main (on start) (update o a) (assert (< o 50)) (complete done)))
ISF
    my $info = module_info_for($module);
    my @lines = FSM::Backend::GeneratedModuleEmitter->immediate_assertion_runtime_lines(
        module_info => $info, target_language => 'systemverilog');
    my $expect_default = 'assert (o < 50) else $error("assertion failed: main_assert_0");';
    like(join("\n", @lines), qr/\Q$expect_default\E/,
        'a name-based default $error message is used when no message is given');
};

subtest 'an input read ONLY by an assert is kept alive (classified INPUT, not pruned)' => sub {
    # level/depth are read only by the assert — without the keep-alive they would be pruned and
    # the emitted `assert (level < depth)` would reference undeclared signals (verilator error).
    my $module = parsed_module(<<'ISF', 'ka');
(actor ka
  (interface (input start) (input level (width 8)) (input depth (width 8)) (output done))
  (transaction main
    (on start)
    (assert (< level depth) "level must stay below depth")
    (complete done)))
ISF
    my $signals = $module->signals;
    for my $name (qw(level depth)) {
        ok($signals->{$name}, "$name survives (not pruned)");
        my $role = $signals->{$name} && $signals->{$name}->can('get_attribute')
            ? $signals->{$name}->get_attribute('signal_role') : undef;
        is($role, 'INPUT', "$name is classified INPUT (kept as a port) via its assert reference");
    }
};

subtest 'a non-assert module surfaces no immediate assertions and emits nothing' => sub {
    my $module = parsed_module(<<'ISF', 'plain');
(actor plain
  (interface (input start) (input a (width 8)) (output done) (output o (width 8)))
  (transaction main (on start) (update o a) (complete done)))
ISF
    my $info = module_info_for($module);
    is_deeply($info->{immediate_assertions}, [], 'no immediate assertions');
    my @lines = FSM::Backend::GeneratedModuleEmitter->immediate_assertion_runtime_lines(
        module_info => $info, target_language => 'systemverilog');
    is(scalar(@lines), 0, 'no assertion block emitted');
};

done_testing();
