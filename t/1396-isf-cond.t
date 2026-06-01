#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-COND.2
#
# `(cond (c1 body1...) (c2 body2...) ... (else bodyN...))` is the if/else-if/else priority
# chain. It desugars (in the parser, before for/let/proc expansion) to a `when`-chain with
# accumulated negated guards: branch i runs only when `ci` holds and no earlier condition
# did; the optional `else` runs when none held.

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
}

sub lower_error {
    my ($source, $label) = @_;
    my $ok = eval { FSM::Scheduler::ISF->new()->lower(parse_source($source, $label)); 1 };
    return $ok ? '' : $@;
}

subtest '(cond …) desugars to a priority when-chain with accumulated negated guards' => sub {
    my $actor = parse_source(<<'ISF', 'cond-basic');
(actor cnd
  (interface (input start) (input c1) (input c2) (output done) (output r (width 8)))
  (transaction main
    (on start)
    (cond
      (c1 (update r 1))
      (c2 (update r 2))
      (else (update r 3)))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a (cond …) lowers') or diag($@);
    my $fsm = $lowered->{files}{'cnd.fsm'};
    # branch 1: when c1 -> r := 1
    like($fsm, qr/\?c1\b/, 'the first branch tests c1');
    # branch 2 guard: (& (! c1) c2)  ;  branch 3 (else) guard: (& (! c1) (! c2))
    like($fsm, qr/\(& \(! c1\) c2\)/, 'the second branch guard ands (! c1) with c2');
    like($fsm, qr/\(& \(! c1\) \(! c2\)\)/, 'the else branch guard ands all prior negations');
    # the three branch effects are present
    like($fsm, qr/\(<- \(r> 1\)\)/, 'branch 1 sets r := 1');
    like($fsm, qr/\(<- \(r> 2\)\)/, 'branch 2 sets r := 2');
    like($fsm, qr/\(<- \(r> 3\)\)/, 'else sets r := 3');
};

subtest '(cond …) with expression conditions and without an else lowers' => sub {
    my $expr = parse_source(<<'ISF', 'cond-expr');
(actor ce
  (interface (input start) (input m (width 2)) (output done) (output r (width 8)))
  (transaction main
    (on start)
    (cond
      ((== m 0) (update r 10))
      ((== m 1) (update r 20))
      (else     (update r 30)))
    (complete done)))
ISF
    ok(eval { FSM::Scheduler::ISF->new()->lower($expr) }, 'a (cond …) with (== m N) conditions lowers') or diag($@);

    my $no_else = parse_source(<<'ISF', 'cond-noelse');
(actor cn
  (interface (input start) (input a) (input b) (output done) (output r (width 8)))
  (transaction main
    (on start)
    (cond
      (a (update r 1))
      (b (update r 2)))
    (complete done)))
ISF
    ok(eval { FSM::Scheduler::ISF->new()->lower($no_else) }, 'a (cond …) with no else (conditions only) lowers') or diag($@);
};

subtest 'a nested (cond …) inside a branch lowers' => sub {
    my $actor = parse_source(<<'ISF', 'cond-nested');
(actor cnn
  (interface (input start) (input a) (input b) (output done) (output r (width 8)))
  (transaction main
    (on start)
    (cond
      (a (cond (b (update r 1)) (else (update r 2))))
      (else (update r 3)))
    (complete done)))
ISF
    ok(eval { FSM::Scheduler::ISF->new()->lower($actor) }, 'a (cond …) nested in a branch body lowers') or diag($@);
};

subtest '(cond …) fails closed on else-not-last, empty body, or a non-list branch' => sub {
    my $else_first = lower_error(
        "(actor t (interface (input start) (input a) (output done) (output r (width 8))) "
        . "(transaction main (on start) (cond (else (update r 1)) (a (update r 2))) (complete done)))",
        'else-first');
    like($else_first, qr/'else' must be the last branch/, "an 'else' that is not last is rejected");

    my $empty_body = lower_error(
        "(actor t (interface (input start) (input a) (output done) (output r (width 8))) "
        . "(transaction main (on start) (cond (a) (else (update r 1))) (complete done)))",
        'empty-body');
    like($empty_body, qr/\(cond \.\.\.\).*has an empty body/, 'a branch with an empty body is rejected');

    my $non_list = lower_error(
        "(actor t (interface (input start) (input a) (output done) (output r (width 8))) "
        . "(transaction main (on start) (cond a (else (update r 1))) (complete done)))",
        'non-list');
    like($non_list, qr/branch must be a/, 'a non-list branch is rejected');
};

done_testing();
