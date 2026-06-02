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

# ISF-PROPERTY-IMPLICATION
#
# A check condition may be a temporal property, starting with overlapping implication:
#   (assert (=> A B))  ->  assert property (@clk disable iff reset ((A) |-> (B))) else $error(…)
# The `=>` combinator does not fit the boolean expression grammar, so it is parsed (FSMGenFull)
# into a tagged property tree over boolean leaves and rendered to SVA `|->` by the backend.

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

subtest '(assert (=> A B)) renders to an SVA overlapping implication' => sub {
    my $module = parsed_module(<<'ISF', 'imp');
(actor imp
  (interface (input start) (input req) (input ack) (output done))
  (transaction main
    (on start)
    (assert (=> req ack) "req implies ack")
    (complete done)))
ISF
    my $info = module_info_for($module);
    my $a = $info->{immediate_assertions};
    is(scalar(@$a), 1, 'one check');
    is($a->[0]{condition_sv}, '(req) |-> (ack)', 'the => combinator renders to (req) |-> (ack)');

    my @lines = FSM::Backend::GeneratedModuleEmitter->immediate_assertion_runtime_lines(
        module_info => $info, target_language => 'systemverilog');
    my $expect =
        'assert property (@(posedge clk) disable iff (!rst_n) ((req) |-> (ack))) else $error("req implies ack");';
    like(join("\n", @lines), qr/\Q$expect\E/, 'emitted as a clocked concurrent implication property');
};

subtest 'implication over richer boolean leaves renders each leaf via the expression builder' => sub {
    my $module = parsed_module(<<'ISF', 'imp2');
(actor imp2
  (interface (input start) (input level (width 8)) (input hi (width 8)) (input ok) (output done))
  (transaction main
    (on start)
    (assert (=> (> level hi) ok))
    (complete done)))
ISF
    my $info = module_info_for($module);
    is($info->{immediate_assertions}[0]{condition_sv}, '(level > hi) |-> (ok)',
        'antecedent (> level hi) and consequent ok both render');
};

subtest 'signals used only inside an implication are kept alive as ports' => sub {
    my $module = parsed_module(<<'ISF', 'imp3');
(actor imp3
  (interface (input start) (input req) (input ack) (output done))
  (transaction main (on start) (assert (=> req ack)) (complete done)))
ISF
    my $signals = $module->signals;
    for my $name (qw(req ack)) {
        my $role = $signals->{$name} && $signals->{$name}->can('get_attribute')
            ? $signals->{$name}->get_attribute('signal_role') : undef;
        is($role, 'INPUT', "$name (only in the implication) is kept as an INPUT port");
    }
};

subtest 'next-cycle (next B) and bounded (within B N) render to ## delays (formal-only)' => sub {
    my $module = parsed_module(<<'ISF', 'nw');
(actor nw
  (interface (input start) (input req) (input ack) (output done))
  (transaction main
    (on start)
    (assert (=> req (next ack)) "next")
    (assert (=> req (within ack 3)) "within")
    (complete done)))
ISF
    my $info = module_info_for($module);
    my %by = map { $_->{name} => $_ } @{$info->{immediate_assertions}};
    is($by{main_assert_0}{condition_sv}, '(req) |-> (##1 (ack))', '(next ack) -> ##1 (ack)');
    is($by{main_assert_1}{condition_sv}, '(req) |-> (##[1:3] (ack))', '(within ack 3) -> ##[1:3] (ack)');
    ok($by{main_assert_0}{formal_only}, 'a delayed consequent is formal-only (verilator cannot simulate ## implication)');
    ok($by{main_assert_1}{formal_only}, 'within is formal-only');

    my @lines = FSM::Backend::GeneratedModuleEmitter->immediate_assertion_runtime_lines(
        module_info => $info, target_language => 'systemverilog');
    my $block = join("\n", @lines);
    # the delay properties go under `ifdef FORMAL (verilator/yosys skip them), not `ifndef SYNTHESIS
    like($block, qr/`ifdef FORMAL/, 'a formal-only block is emitted');
    like($block, qr/`ifdef FORMAL.*##1 \(ack\)/s, 'the ##1 property is inside the FORMAL block');
};

subtest 'simulable and formal-only checks are partitioned into separate guards' => sub {
    my $module = parsed_module(<<'ISF', 'split');
(actor split
  (interface (input start) (input req) (input ack) (output done))
  (transaction main
    (on start)
    (assert (=> req ack) "overlap")
    (assert (=> req (next ack)) "delayed")
    (complete done)))
ISF
    my $info = module_info_for($module);
    my @lines = FSM::Backend::GeneratedModuleEmitter->immediate_assertion_runtime_lines(
        module_info => $info, target_language => 'systemverilog');
    my $block = join("\n", @lines);
    # overlapping implication is verilator-simulable -> `ifndef SYNTHESIS (before the FORMAL block)
    like($block, qr/`ifndef SYNTHESIS.*\(req\) \|-> \(ack\).*`endif.*`ifdef FORMAL.*##1/s,
        'overlapping under ifndef SYNTHESIS; the ##1 delayed one under ifdef FORMAL');
};

subtest 'a malformed implication fails closed' => sub {
    like(parse_error(
        "(actor one (interface (input start) (input req) (output done)) "
        . "(transaction main (on start) (assert (=> req)) (complete done)))", 'one'),
        qr/requires exactly an antecedent and a consequent/,
        '(=> req) with only one operand is rejected');

    like(parse_error(
        "(actor two (interface (input start) (input req) (input ack) (output done)) "
        . "(transaction main (on start) (assert (=> req (within ack 0))) (complete done)))", 'two'),
        qr/bound must be a literal integer >= 1/,
        '(within ack 0) with a zero bound is rejected');
};

done_testing();
