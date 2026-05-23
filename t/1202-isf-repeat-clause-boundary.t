#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
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
    like($fsm, qr/\(main_repeat_check_3\n\s+\(<- \(main_cnt \(- main_cnt 1\)\)\)/, 'repeat check decrements the counter');
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
    like($fsm, qr/\(main_repeat_init_1\n\s+\(<= \(main_cnt beats\)\)\n\s+\(-> main_drive_2 <beats\)\n\s+\(-> main_done_4 <\(== beats 0\)\)/,
        'runtime zero repeat count bypasses the body and repeat check');
    like($fsm, qr/\(main_drive_2\n\s+\(= \(tick_start 1\)\)\n\s+\(-> main_repeat_check_3\)/,
        'nonzero runtime repeat count still enters the existing body path');
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
    assert_lower_rejected(<<'ISF', 'unknown repeat count name', qr/\ATransaction 'main': repeat count 'beats' is neither a declared positive actor constant nor a known-width runtime scalar/);
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

    assert_lower_rejected(<<'ISF', 'actor parameter repeat count', qr/\ATransaction 'main': repeat count actor parameter 'COUNT' remains deferred; use a known-width runtime scalar or positive actor constant/);
(actor repeat_actor_param_count
  (clock clk)
  (params
    (COUNT 3))
  (interface (input start) (output flag) (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat COUNT
      (drive tick))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'negative repeat count literal', qr/\ATransaction 'main': repeat count '-1' must be a positive decimal literal, declared positive actor constant, or known-width runtime scalar name/);
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

};

subtest 'statically zero repeat counts fail closed before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'literal zero repeat count', qr/\ATransaction 'main': repeat count '0' is statically zero; zero-count repeat semantics remain deferred/);
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

    assert_lower_rejected(<<'ISF', 'actor constant zero repeat count', qr/\ATransaction 'main': repeat count 'COUNT' is statically zero; zero-count repeat semantics remain deferred/);
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
};

done_testing();
