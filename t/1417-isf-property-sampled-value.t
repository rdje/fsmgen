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

# ISF-PROPERTY-SAMPLED-VALUE.2
#
# A check condition may use the SystemVerilog sampled-value functions as property leaves:
#   (stable SIG) / (changed SIG) / (rose SIG) / (fell SIG)
#     -> $stable(SIG) / $changed(SIG) / $rose(SIG) / $fell(SIG)
# They are boolean edge/stability predicates over a signal, usable standalone or as an
# =>/after antecedent/consequent. Not a `##` sequence, so they stay verilator-simulable
# (under `ifndef SYNTHESIS`). They are property-only: in a synthesizable expression
# position (a `when` guard) the head is unknown to the expression builder and fails closed.
#
# ISF-REMAINING-BROAD-FRONTIER.9.1 also admits value-returning (past SIG [N])
# inside check-property expressions only. It renders as $past(SIG[, N]) and can
# be used under boolean expression operators such as ==.

my $tempdir = tempdir(CLEANUP => 1);

sub parsed_module {
    my ($source, $name) = @_;
    my $fsm = FSM::Scheduler::ISF->new()->lower(
        FSM::Adapter::ISF->new()->parse_source($source, "$name.isf"))->{files}{"$name.fsm"};
    my $path = File::Spec->catfile($tempdir, "$name.fsm");
    open my $fh, '>', $path or die $!; print $fh $fsm; close $fh;
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
}

sub lower_error {
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

subtest 'each sampled-value predicate renders to its $fn(SIG), and is verilator-simulable' => sub {
    my $module = parsed_module(<<'ISF', 'sv');
(actor sv
  (interface (input start) (input valid) (input req) (output ack) (output done) (output data (width 8)))
  (transaction main
    (on start)
    (assert (stable data))
    (assert (changed data))
    (assert (rose req))
    (assert (fell valid))
    (complete done)))
ISF
    my $info = module_info_for($module);
    my %by = map { $_->{name} => $_ } @{$info->{immediate_assertions}};
    is($by{main_assert_0}{condition_sv}, '$stable(data)',  '(stable data) -> $stable(data)');
    is($by{main_assert_1}{condition_sv}, '$changed(data)', '(changed data) -> $changed(data)');
    is($by{main_assert_2}{condition_sv}, '$rose(req)',     '(rose req) -> $rose(req)');
    is($by{main_assert_3}{condition_sv}, '$fell(valid)',   '(fell valid) -> $fell(valid)');
    ok(!$by{$_}{formal_only}, "$_ is verilator-simulable (not a ## delay)")
        for qw(main_assert_0 main_assert_1 main_assert_2 main_assert_3);

    my @lines = FSM::Backend::GeneratedModuleEmitter->immediate_assertion_runtime_lines(
        module_info => $info, target_language => 'systemverilog');
    my $block = join("\n", @lines);
    like($block, qr/`ifndef SYNTHESIS[\s\S]*\$stable\(data\)/, 'sampled-value checks are under `ifndef SYNTHESIS');
    unlike($block, qr/`ifdef FORMAL/, 'no formal-only block is needed for plain sampled-value checks');
};

subtest 'sampled-value predicates compose as implication antecedent and consequent' => sub {
    my $module = parsed_module(<<'ISF', 'svimp');
(actor svimp
  (interface (input start) (input valid) (input req) (output ack) (output done) (output data (width 8)))
  (transaction main
    (on start)
    (assert (=> valid (stable data)) "data stable while valid")
    (assert (=> (rose req) ack) "ack on the req edge")
    (complete done)))
ISF
    my $info = module_info_for($module);
    my %by = map { $_->{name} => $_ } @{$info->{immediate_assertions}};
    is($by{main_assert_0}{condition_sv}, '(valid) |-> ($stable(data))',
        '(=> valid (stable data)) -> (valid) |-> ($stable(data))');
    is($by{main_assert_1}{condition_sv}, '($rose(req)) |-> (ack)',
        '(=> (rose req) ack) -> ($rose(req)) |-> (ack)  (equivalent to (after req ack))');
    ok(!$by{main_assert_0}{formal_only}, 'an overlapping implication over a sampled-value leaf stays simulable');
    ok(!$by{main_assert_1}{formal_only}, 'a $rose antecedent stays simulable');
};

subtest 'a signal used only inside a sampled-value predicate is kept alive as a port' => sub {
    my $module = parsed_module(<<'ISF', 'svalive');
(actor svalive
  (interface (input start) (input cfg (width 8)) (output done))
  (transaction main (on start) (assert (stable cfg)) (complete done)))
ISF
    my $signals = $module->signals;
    my $role = $signals->{cfg} && $signals->{cfg}->can('get_attribute')
        ? $signals->{cfg}->get_attribute('signal_role') : undef;
    is($role, 'INPUT', 'cfg (only inside (stable cfg)) is kept as an INPUT port, not pruned');
};

subtest 'past renders as a value-returning sampled expression in checks' => sub {
    my $module = parsed_module(<<'ISF', 'pastv');
(actor pastv
  (interface (input start) (input data (width 8)) (output done))
  (transaction main
    (on start)
    (assert (== data (past data)) "data repeats previous sample")
    (assume (== data (past data 2)) "data repeats sample from two cycles ago")
    (cover (== (past data) data))
    (complete done)))
ISF
    my $info = module_info_for($module);
    my %by = map { $_->{name} => $_ } @{$info->{immediate_assertions}};
    is($by{main_assert_0}{condition_sv}, 'data == $past(data)',
        '(== data (past data)) -> data == $past(data)');
    is($by{main_assume_0}{condition_sv}, 'data == $past(data, 2)',
        '(== data (past data 2)) -> data == $past(data, 2)');
    is($by{main_cover_0}{condition_sv}, '$past(data) == data',
        '(== (past data) data) -> $past(data) == data');
    ok(!$by{main_assert_0}{formal_only}, '$past without ## stays verilator-simulable');
    ok(!$by{main_assume_0}{formal_only}, '$past with literal depth stays verilator-simulable');

    my @lines = FSM::Backend::GeneratedModuleEmitter->immediate_assertion_runtime_lines(
        module_info => $info, target_language => 'systemverilog');
    my $block = join("\n", @lines);
    like($block, qr/`ifndef SYNTHESIS[\s\S]*\$past\(data\)/, '$past checks are under `ifndef SYNTHESIS');
    unlike($block, qr/`ifdef FORMAL/, 'no formal-only block is needed for plain $past checks');
};

subtest 'a signal used only inside past is kept alive as a port' => sub {
    my $module = parsed_module(<<'ISF', 'pastalive');
(actor pastalive
  (interface (input start) (input cfg (width 8)) (output done))
  (transaction main (on start) (assert (== (past cfg) 0)) (complete done)))
ISF
    my $signals = $module->signals;
    my $role = $signals->{cfg} && $signals->{cfg}->can('get_attribute')
        ? $signals->{cfg}->get_attribute('signal_role') : undef;
    is($role, 'INPUT', 'cfg (only inside (past cfg)) is kept as an INPUT port, not pruned');
};

subtest 'a sampled-value predicate with the wrong arity fails closed' => sub {
    like(lower_error(
        "(actor a (interface (input start) (output done)) "
        . "(transaction main (on start) (assert (stable)) (complete done)))", 'a'),
        qr/sampled-value predicate requires exactly one signal operand/,
        '(stable) with no operand is rejected');
    like(lower_error(
        "(actor b (interface (input start) (input x) (input y) (output done)) "
        . "(transaction main (on start) (assert (rose x y)) (complete done)))", 'b'),
        qr/sampled-value predicate requires exactly one signal operand/,
        '(rose x y) with two operands is rejected');
};

subtest 'past malformed forms fail closed' => sub {
    like(lower_error(
        "(actor p0 (interface (input start) (input x) (output done)) "
        . "(transaction main (on start) (assert (== x (past))) (complete done)))", 'p0'),
        qr/sampled-value expression requires one signal operand and an optional literal depth/,
        '(past) with no operand is rejected');
    like(lower_error(
        "(actor p1 (interface (input start) (input x) (output done)) "
        . "(transaction main (on start) (assert (== x (past x 0))) (complete done)))", 'p1'),
        qr/sampled-value depth must be a literal integer >= 1/,
        '(past x 0) is rejected');
    like(lower_error(
        "(actor p2 (interface (input start) (input x) (output done)) "
        . "(transaction main (on start) (assert (== x (past x two))) (complete done)))", 'p2'),
        qr/sampled-value depth must be a literal integer >= 1/,
        '(past x two) is rejected');
    like(lower_error(
        "(actor p3 (interface (input start) (input x) (output done)) "
        . "(transaction main (on start) (assert (== x (past (+ x 1)))) (complete done)))", 'p3'),
        qr/requires a signal, bit\/slice, or aggregate leaf operand/,
        '(past (+ x 1)) is rejected as a non-signal operand');
};

subtest 'sampled-value heads are property-only: they fail closed in a synthesizable expression position' => sub {
    # A `(when COND ...)` guard is an ordinary (synthesizable) boolean expression, not a property.
    # The sampled-value heads are unknown to the ordinary expression builder there, so they fail closed.
    my $err = lower_error(
        "(actor w (interface (input start) (input x) (output done) (output r)) "
        . "(transaction main (on start) (when (stable x) (drive r)) (complete done)))", 'w');
    isnt($err, '', '(when (stable x) ...) — a sampled-value head in a control-flow guard fails closed');

    my $past_err = lower_error(
        "(actor wp (interface (input start) (input x) (output done) (output r)) "
        . "(transaction main (on start) (when (== x (past x)) (drive r)) (complete done)))", 'wp');
    isnt($past_err, '', '(when (== x (past x)) ...) — past remains property-expression-only');
};

done_testing();
