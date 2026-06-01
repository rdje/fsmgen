#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-MINMAX
#
# `(max DST A B)` / `(min DST A B)` — the larger / smaller of two values into a register. Pure
# ISF parser desugar onto the `(select …)` conditional assignment (expanded by the select pass):
#   (max DST A B) -> (select DST (>= A B) A B)  -> (when (>= A B) (set DST A)) (when (! …) (set DST B))
#   (min DST A B) -> (select DST (<= A B) A B)
# A clamp composes: (max v v lo) then (min v v hi) saturates v into [lo, hi] (sequential writes,
# correct since CODEGEN-MULTI-EXPRESSION-SET-ALIAS).

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

subtest '(max/min DST A B) desugar (through select) to two conditional sets with the right test' => sub {
    my $mx = lower_fsm(<<'ISF', 'mx');
(actor mx
  (interface (input start) (input sample (width 8)) (output done) (output peak (width 8)))
  (transaction main
    (on start)
    (max peak peak sample)
    (complete done)))
ISF
    like($mx, qr/\Q(>= peak sample)\E/, 'max compares A >= B');
    like($mx, qr/\Q(<- (peak> peak))\E/, 'max assigns A (peak) on the A>=B path');
    like($mx, qr/\Q(<- (peak> sample))\E/, 'max assigns B (sample) otherwise');

    my $mn = lower_fsm(<<'ISF', 'mn');
(actor mn
  (interface (input start) (input a (width 8)) (input b (width 8)) (output done) (output o (width 8)))
  (transaction main
    (on start)
    (min o a b)
    (complete done)))
ISF
    like($mn, qr/\Q(<= a b)\E/, 'min compares A <= B');
    like($mn, qr/\Q(<- (o> a))\E/, 'min assigns A on the A<=B path');
    like($mn, qr/\Q(<- (o> b))\E/, 'min assigns B otherwise');
};

subtest 'a clamp composes from max then min (sequential writes to one register)' => sub {
    my $fsm = lower_fsm(<<'ISF', 'sat');
(actor sat
  (interface (input start) (input in (width 8)) (output done) (output v (width 8)))
  (transaction main
    (on start)
    (update v in)
    (max v v 20)
    (min v v 80)
    (complete done)))
ISF
    like($fsm, qr/\Q(>= v 20)\E/, 'the max(v,20) floor lowers');
    like($fsm, qr/\Q(<= v 80)\E/, 'the min(v,80) ceiling lowers');
    # v is written by several expression sets across states — they must all lower (no parser error)
    ok(length($fsm) > 0, 'the composed clamp lowers to a non-empty .fsm');
};

subtest 'min/max nested in a control-flow body are rewritten' => sub {
    my $fsm = lower_fsm(<<'ISF', 'mw');
(actor mw
  (interface (input start) (input go) (input a (width 8)) (input b (width 8)) (output done) (output o (width 8)))
  (transaction main
    (on start)
    (when go
      (max o a b))
    (complete done)))
ISF
    like($fsm, qr/\Q(<- (o> a))\E/, 'a (max …) inside a (when …) body is rewritten');
    like($fsm, qr/\Q(<- (o> b))\E/, 'both arms present');
};

subtest 'malformed min/max forms fail closed' => sub {
    like(lower_error(
        "(actor t (interface (input start) (input a (width 8)) (output done) (output o (width 8))) "
        . "(transaction main (on start) (max o a) (complete done)))", 'few'),
        qr/requires exactly two values/,
        '(max o a) with one value is rejected');

    like(lower_error(
        "(actor t (interface (input start) (output done) (output o (width 8))) "
        . "(transaction main (on start) (min) (complete done)))", 'noname'),
        qr/requires a register name/,
        '(min) with no register name is rejected');
};

done_testing();
