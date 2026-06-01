#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub lower_source {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'repeat-clause-boundary.isf');
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        lower_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

sub assert_static_zero_repeat_noop {
    my ($source, $label, $filename) = @_;

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $result->{files}{$filename};

    unlike($fsm, qr/\bmain_cnt\b/, "$label does not declare a repeat counter");
    unlike($fsm, qr/main_repeat_init_/, "$label emits no repeat init state");
    unlike($fsm, qr/main_repeat_check_/, "$label emits no repeat check state");
    unlike($fsm, qr/\(= \(tick_start 1\)\)/, "$label emits no repeat-body drive start");
    like($fsm, qr/\(main_idle_0[\s\S]*\(-> main_done_1\)/,
        "$label links surrounding transaction states directly");

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply($report->{transaction_loops}, [], "$label emits no transaction loop report entry");
}

sub assert_static_zero_child_activation_pruned {
    my ($source, $label, $filename) = @_;

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{$filename};
    (my $actor_name = $filename) =~ s/\.fsm\z//;

    ok(defined($fsm), "$label parent scheduled .fsm is emitted");
    ok(!exists($lowered->{files}{'child.fsm'}), "$label emits no generated child scheduled .fsm");
    ok(!exists($lowered->{files}{"${actor_name}_top.fsm"}), "$label emits no generated top");
    unlike($fsm, qr/\bmain_cnt\b/, "$label does not declare a repeat counter");
    unlike($fsm, qr/main_repeat_init_/, "$label emits no repeat init state");
    unlike($fsm, qr/main_repeat_check_/, "$label emits no repeat check state");
    unlike($fsm, qr/\bchild_(?:idle|done|complete)_/, "$label prunes child-only transaction states");
    unlike($fsm, qr/\b(?:child|c0)_(?:start|done)\b/, "$label emits no child activation handoff");
    like($fsm, qr/\(main_idle_0[\s\S]*\(-> main_done_1\)/,
        "$label links surrounding transaction states directly");

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply($report->{transaction_loops}, [], "$label emits no transaction loop report entry");
}

subtest 'valid repeat clause lowers counter init, body, and check states' => sub {
    my $result = lower_source(<<'ISF');
(actor repeat_boundary
  (clock clk)
  (interface
    (input start)
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat 3
      (drive tick))
    (complete done)))
ISF

    my $fsm = $result->{files}{'repeat_boundary.fsm'};
    like($fsm, qr/\(main_repeat_init_1\n\s+\(<= \(main_cnt 3\)\)/, 'repeat init loads scalar count');
    like($fsm, qr/\(= \(tick_start 1\)\)/, 'repeat body drive is emitted');
    like($fsm, qr/\(main_repeat_check_3\n\s+\(-- main_cnt\)/, 'repeat check decrements the counter');
};

subtest 'runtime scalar repeat counts zero-bypass the repeat body' => sub {
    my $result = lower_source(<<'ISF');
(actor repeat_runtime_zero
  (clock clk)
  (interface
    (input start)
    (input repeat_len (width 12))
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start
      (sample repeat_len as beats))
    (repeat beats
      (drive tick))
    (complete done)))
ISF

    my $fsm = $result->{files}{'repeat_runtime_zero.fsm'};
    like($fsm, qr/\(main_cnt 12\)/, 'runtime repeat count keeps the sampled source width');
    like($fsm, qr/\(main_repeat_init_1\n\s+\(<= \(main_cnt beats\)\)\n\s+\(-> main_repeat_check_3\)/,
        'runtime repeat init loads the counter and enters the check-first loop');
    like($fsm, qr/\(main_repeat_check_3\n\s+\(-- main_cnt\)\n\s+\(\?main_cnt\n\s+\(>0 \(-> main_drive_2\)\)\n\s+\(=0 \(-> main_done_4\)\)/,
        'runtime zero repeat count bypasses the body via the check-first decrement');
    like($fsm, qr/\(main_drive_2\n\s+\(= \(tick_start 1\)\)\n\s+\(-> main_repeat_check_3\)/,
        'nonzero runtime repeat count still enters the existing body path');
};

subtest 'same-transaction scalar parameter repeat counts lower as static counts' => sub {
    my $result = lower_source(<<'ISF');
(actor repeat_transaction_param_count
  (clock clk)
  (interface
    (input start)
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (params
      (COUNT 3))
    (on start)
    (repeat COUNT
      (drive tick))
    (complete done)))
ISF

    my $fsm = $result->{files}{'repeat_transaction_param_count.fsm'};
    like($fsm, qr/\(main_cnt 2\)/, 'transaction parameter repeat count supplies counter width');
    like($fsm, qr/\(main_repeat_init_1\n\s+\(<= \(main_cnt 3\)\)/,
        'transaction parameter repeat count loads the resolved static value');

    my $shadowed = lower_source(<<'ISF');
(actor repeat_transaction_param_shadow_count
  (clock clk)
  (params
    (COUNT 3))
  (interface
    (input start)
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (params
      (COUNT 4))
    (on start)
    (repeat COUNT
      (drive tick))
    (complete done)))
ISF

    my $shadowed_fsm = $shadowed->{files}{'repeat_transaction_param_shadow_count.fsm'};
    like($shadowed_fsm, qr/\(main_cnt 3\)/, 'transaction parameter repeat count shadows actor parameter width evidence');
    like($shadowed_fsm, qr/\(main_repeat_init_1\n\s+\(<= \(main_cnt 4\)\)/,
        'transaction parameter repeat count shadows actor parameter load value');
};

subtest 'malformed repeat clauses fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'missing repeat count', qr/\ATransaction 'main': repeat requires '\(repeat count body\.\.\.\)' in transaction body/);
(actor repeat_missing_count
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (repeat)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'missing repeat body', qr/\ATransaction 'main': repeat requires '\(repeat count body\.\.\.\)' in transaction body/);
(actor repeat_missing_body
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (repeat 2)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested repeat count', qr/\ATransaction 'main': repeat requires '\(repeat count body\.\.\.\)' in transaction body/);
(actor repeat_nested_count
  (clock clk)
  (interface (input start) (output flag) (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat (beats)
      (drive tick))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'scalar repeat body', qr/\ATransaction 'main': transaction clauses must be list forms in repeat body/);
(actor repeat_scalar_body
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (repeat 2 drive)
    (complete done)))
ISF
};

subtest 'unsupported repeat count sources fail before counter emission' => sub {
    assert_lower_rejected(<<'ISF', 'unknown repeat count name', qr/\ATransaction 'main': repeat count 'beats' is neither a declared non-negative actor constant, actor scalar parameter, qualified package scalar constant, nor a known-width runtime scalar/);
(actor repeat_unknown_count
  (clock clk)
  (interface (input start) (output flag) (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat beats
      (drive tick))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'non-scalar actor parameter repeat count', qr/\ATransaction 'main': repeat count actor parameter 'COUNT' must resolve to a non-negative integer literal/);
(actor repeat_actor_param_count
  (clock clk)
  (params
    (COUNT (3 4)))
  (interface (input start) (output flag) (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat COUNT
      (drive tick))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'aggregate transaction parameter repeat count', qr/\ATransaction 'worker': repeat count transaction parameter 'COUNT' must resolve to a non-negative integer literal/);
(actor repeat_aggregate_transaction_param_count
  (clock clk)
  (interface (input start) (output flag) (output done))
  (drive tick
    (flag 1))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (COUNT (3 4)))
    (repeat COUNT
      (drive tick))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'negative repeat count literal', qr/\ATransaction 'main': repeat count '-1' must be a non-negative decimal literal, declared non-negative actor constant, actor scalar parameter, qualified package scalar constant, or known-width runtime scalar name/);
(actor repeat_negative_count
  (clock clk)
  (interface (input start) (output flag) (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat -1
      (drive tick))
    (complete done)))
ISF

    assert_static_zero_repeat_noop(<<'ISF', 'transaction parameter zero repeat count', 'repeat_transaction_param_zero.fsm');
(actor repeat_transaction_param_zero
  (clock clk)
  (interface (input start) (output flag) (output done))
  (drive tick
    (flag 1))
  (transaction main
    (params
      (COUNT 0))
    (on start)
    (repeat COUNT
      (drive tick))
    (complete done)))
ISF

};

subtest 'statically zero repeat counts lower as no-op regions' => sub {
    assert_static_zero_repeat_noop(<<'ISF', 'literal zero repeat count', 'repeat_literal_zero.fsm');
(actor repeat_literal_zero
  (clock clk)
  (interface (input start) (output flag) (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat 0
      (drive tick))
    (complete done)))
ISF

    assert_static_zero_repeat_noop(<<'ISF', 'actor constant zero repeat count', 'repeat_constant_zero.fsm');
(actor repeat_constant_zero
  (clock clk)
  (constants
    (COUNT 0))
  (interface (input start) (output flag) (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat COUNT
      (drive tick))
    (complete done)))
ISF

    assert_static_zero_repeat_noop(<<'ISF', 'actor parameter zero repeat count', 'repeat_parameter_zero.fsm');
(actor repeat_parameter_zero
  (clock clk)
  (params
    (COUNT 0))
  (interface (input start) (output flag) (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat COUNT
      (drive tick))
    (complete done)))
ISF
};

subtest 'statically zero repeat child activations prune unreachable artifacts' => sub {
    assert_static_zero_child_activation_pruned(<<'ISF', 'zero repeat plain spawn body', 'zero_repeat_spawn_pruned.fsm');
(actor zero_repeat_spawn_pruned
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (repeat 0
      (spawn child as c0))
    (complete done))
  (transaction child
    (complete done)))
ISF

    assert_static_zero_child_activation_pruned(<<'ISF', 'zero repeat plain do body', 'zero_repeat_do_pruned.fsm');
(actor zero_repeat_do_pruned
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (repeat 0
      (do child))
    (complete done))
  (transaction child
    (on child_start)
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source(<<'ISF', 'zero_repeat_external_child_preserved.isf');
(actor zero_repeat_external_child_preserved
  (clock clk)
  (interface (input start) (input child_start) (output child_done) (output done))
  (transaction main
    (on start)
    (repeat 0
      (spawn child as c0))
    (complete done))
  (transaction child
    (on child_start)
    (complete child_done)))
ISF
    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'zero_repeat_external_child_preserved.fsm'};
    ok(defined($fsm), 'zero repeat external child preservation emits parent scheduled .fsm');
    ok(!exists($lowered->{files}{'child.fsm'}), 'zero repeat external child preservation emits no generated child scheduled .fsm');
    ok(!exists($lowered->{files}{'zero_repeat_external_child_preserved_top.fsm'}), 'zero repeat external child preservation emits no generated top');
    unlike($fsm, qr/\bc0_start\b/, 'zero repeat external child preservation emits no pruned spawn handoff');
    like($fsm, qr/\(child_idle_\d+[\s\S]*<child_start[\s\S]*\(-> child_done_\d+\)/,
        'externally guarded child transaction remains in the parent scheduled module');
};

subtest 'statically zero repeat specialized child activations prune unreachable artifacts' => sub {
    assert_static_zero_child_activation_pruned(<<'ISF', 'zero repeat parameterized spawn body', 'zero_repeat_parameterized_spawn_pruned.fsm');
(actor zero_repeat_parameterized_spawn_pruned
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (repeat 0
      (spawn child as c0
        (params
          (WIDTH 16))))
    (complete done))
  (transaction child
    (params
      (WIDTH 8))
    (complete done)))
ISF

    assert_static_zero_child_activation_pruned(<<'ISF', 'zero repeat specialized do body', 'zero_repeat_specialized_do_pruned.fsm');
(actor zero_repeat_specialized_do_pruned
  (clock-domains
    (domain core (clock clk) :default))
  (interface (input start) (input src) (output sink) (output done))
  (transaction main
    (domain core)
    (on start)
    (repeat 0
      (do child
        (params
          (WIDTH 16))
        (bind
          (input din src)
          (output dout sink))
        (domain core)))
    (complete done))
  (transaction child
    (params
      (WIDTH 8))
    (domain core)
    (complete done)))
ISF
};

subtest 'statically zero repeat malformed specialized child activations remain fail closed' => sub {
    assert_lower_rejected(<<'ISF', 'zero repeat malformed spawn subclause', qr/\ATransaction 'main': spawn has unsupported 'foo' subclause in repeat body/);
(actor zero_repeat_malformed_spawn_subclause
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (repeat 0
      (spawn child as c0
        (foo bar)))
    (complete done))
  (transaction child
    (complete done)))
ISF
};

done_testing();
