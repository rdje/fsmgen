#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-SELECT
#
# `(select DST COND A B)` — conditional assignment (`dst = cond ? a : b`). Pure ISF parser
# desugar into two mutually-exclusive conditional `(set …)`s (the two writes to DST get
# distinct write-enables since CODEGEN-MULTI-EXPRESSION-SET-ALIAS landed):
#   (select DST COND A B) -> (when COND (set DST A)) (when (! COND) (set DST B))

sub lower_fsm {
    my ($source, $name) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$name.isf");
    return FSM::Scheduler::ISF->new()->lower($actor)->{files}{"$name.fsm"};
}

sub lower_error {
    my ($source, $name) = @_;
    my $ok = eval { lower_fsm($source, $name); 1 };
    return $ok ? '' : $@;
}

subtest '(select DST COND A B) desugars to two mutually-exclusive conditional sets' => sub {
    my $fsm = lower_fsm(<<'ISF', 'sl');
(actor sl
  (interface (input start) (input pick) (input a (width 8)) (input b (width 8)) (output done) (output dst (width 8)))
  (transaction main
    (on start)
    (select dst pick a b)
    (complete done)))
ISF
    like($fsm, qr/\Q(<- (dst> a))\E/, 'the true path assigns A to DST');
    like($fsm, qr/\Q(<- (dst> b))\E/, 'the false path assigns B to DST');
    # the false path is guarded by the negated condition (rendered as a `?` decision)
    like($fsm, qr/pick/, 'the condition drives the decision');
};

subtest 'expression conditions and value expressions are preserved' => sub {
    my $fsm = lower_fsm(<<'ISF', 'sl2');
(actor sl2
  (interface (input start) (input x (width 8)) (output done) (output o (width 8)))
  (transaction main
    (on start)
    (select o (> x 5) (+ x 1) (- x 1))
    (complete done)))
ISF
    like($fsm, qr/\Q(<- (o> (+ x 1)))\E/, 'the true value expression (+ x 1) is assigned on the true path');
    like($fsm, qr/\Q(<- (o> (- x 1)))\E/, 'the false value expression (- x 1) is assigned on the false path');
};

subtest 'a select nested in a control-flow body is rewritten' => sub {
    my $fsm = lower_fsm(<<'ISF', 'sl3');
(actor sl3
  (interface (input start) (input go) (input pick) (input a (width 8)) (input b (width 8)) (output done) (output o (width 8)))
  (transaction main
    (on start)
    (when go
      (select o pick a b))
    (complete done)))
ISF
    like($fsm, qr/\Q(<- (o> a))\E/, 'the true path of a select inside a (when …) body is rewritten');
    like($fsm, qr/\Q(<- (o> b))\E/, 'the false path too');
};

subtest 'malformed select forms fail closed' => sub {
    like(lower_error(
        "(actor t (interface (input start) (input p) (output done) (output o (width 8))) "
        . "(transaction main (on start) (select o p) (complete done)))", 'few'),
        qr/requires a condition and two values/,
        '(select o p) with too few operands is rejected');

    like(lower_error(
        "(actor t (interface (input start) (input p) (input a (width 8)) (input b (width 8)) (output done) (output o (width 8))) "
        . "(transaction main (on start) (select o p a b extra) (complete done)))", 'many'),
        qr/requires a condition and two values/,
        '(select o p a b extra) with too many operands is rejected');

    like(lower_error(
        "(actor t (interface (input start) (input p) (output done) (output o (width 8))) "
        . "(transaction main (on start) (select) (complete done)))", 'noname'),
        qr/requires a register name/,
        '(select) with no register name is rejected');
};

done_testing();
