#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-FOR-LOOP.2
#
# `(for (i N) body)` is an indexed counted loop: it runs `body` exactly N times while
# exposing a loop index `i` counting 0, 1, … N-1 to the body (bare `(repeat N body)`
# gives no index). It is a pure ISF parser desugar into a declared index `(local …)` +
# a counted `(repeat …)` with a tail increment:
#
#   (for (i N) body...)
#     -> (local i (width W) (default 0))
#        (repeat N body... (set i (+ i 1)))
#
# `.2` supports a TOP-LEVEL `(for …)` with a literal N (the index `(local …)` must sit
# at the transaction top because `local` is a transaction-context-only clause); a
# nested/embedded `(for …)` and a non-literal/empty/<1 count fail closed.

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
}

sub lower_error {
    my ($source, $label) = @_;
    my $ok = eval { FSM::Scheduler::ISF->new()->lower(parse_source($source, $label)); 1 };
    return $ok ? '' : $@;
}

subtest '(for (i N) body) desugars to a declared index, counted repeat, and tail increment' => sub {
    my $actor = parse_source(<<'ISF', 'for-basic');
(actor fl
  (interface (input start) (output done) (output result (width 8)))
  (transaction main
    (on start)
    (for (i 4)
      (update result (+ result i)))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a top-level (for (i 4) …) lowers') or diag($@);
    my $fsm = $lowered->{files}{'fl.fsm'};

    # the index is a declared internal register sized to hold the count (4 -> 3 bits)
    like($fsm, qr/\(i 3\)/, 'the index i is declared in +size at width 3 (holds the count 4)');
    # the index initializes to 0 before the loop
    like($fsm, qr/\(main_set_\d+\n\s+\(<- \(i 0\)\)/s, 'the index i initializes to 0 before the loop');
    # the body can read i
    like($fsm, qr/\(<- \(result> \(\+ result i\)\)\)/, 'the body reads the loop index i');
    # the index advances by 1 at the tail of each iteration
    like($fsm, qr/\(<- \(i \(\+ i 1\)\)\)/, 'the index i advances by 1 each iteration');
    # the loop body runs under a counted repeat (check-first: init -> check, (>0)/(=0))
    like($fsm, qr/main_repeat_check_\d+\n\s+\(-- main_cnt\)\n\s+\(\?main_cnt\n\s+\(!=0/s,
        'the loop lowers to a counted repeat with the check-first decrement');
};

subtest 'the for-loop runs exactly N times with the index counting 0..N-1' => sub {
    # Lower a (for (i 3) …) and confirm the counted repeat loads 3 and the index path is
    # 0-based with a single increment per iteration (the runtime exactly-N behavior is
    # covered by ISF-COUNTED-REPEAT-TERMINATION's simulation; here we lock the schedule).
    my $actor = parse_source(<<'ISF', 'for-count3');
(actor fc
  (interface (input start) (output done) (output idx (width 3)))
  (transaction main
    (on start)
    (for (i 3)
      (update idx i))
    (complete done)))
ISF
    my $fsm = eval { FSM::Scheduler::ISF->new()->lower($actor) }->{files}{'fc.fsm'};
    like($fsm, qr/\(main_repeat_init_\d+\n\s+\(<= \(main_cnt 3\)\)/s, 'the repeat loads the literal count 3');
    like($fsm, qr/\(i 2\)/, 'i for count 3 is width 2 (holds 0..3)');
    like($fsm, qr/\(<- \(idx> i\)\)/, 'the body assigns the index to the output');
};

subtest '(for …) fails closed on a malformed spec' => sub {
    my %bad = (
        'a non-literal count' => '(for (i n) (update result (+ result 1)))',
        'a zero count'        => '(for (i 0) (update result (+ result 1)))',
        'an empty body'       => '(for (i 4))',
    );
    for my $label (sort keys %bad) {
        my $err = lower_error(
            "(actor t (interface (input start) (input n (width 4)) (output done) (output result (width 8))) "
            . "(transaction main (on start) $bad{$label} (complete done)))",
            "bad-$label");
        like($err, qr/\(for/, "$label is rejected with a (for …) diagnostic");
    }

    my $nonlit = lower_error(
        "(actor t (interface (input start) (input n (width 4)) (output done) (output result (width 8))) "
        . "(transaction main (on start) (for (i n) (update result (+ result 1))) (complete done)))",
        'nonlit');
    like($nonlit, qr/requires a literal non-negative integer count/, 'a non-literal count names the literal-count requirement');
};

subtest 'explicit-width form (for (i (width W) N) …) accepts a runtime/parameter count' => sub {
    # ISF-FOR-LOOP.3: (for (i (width W) N) body) gives the index an explicit width W so the
    # count N may be a non-literal (here a runtime input) — bare (repeat N) gives no index;
    # this is the indexed variable-count loop. It rides the counted (repeat …) lowering.
    my $actor = parse_source(<<'ISF', 'for-runtime');
(actor frt
  (interface (input start) (input n (width 8)) (output done) (output total (width 8)))
  (transaction main
    (on start)
    (for (i (width 8) n)
      (update total (+ total i)))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a (for (i (width 8) n) …) with a runtime count lowers') or diag($@);
    my $fsm = $lowered->{files}{'frt.fsm'};
    like($fsm, qr/\(i 8\)/, 'the index i takes the explicit width 8');
    like($fsm, qr/\(main_repeat_init_\d+\n\s+\(<= \(main_cnt n\)\)\n\s+\(-> main_repeat_check_\d+\)/s,
        'the counted repeat loads the runtime count n once and flows to the check');
    like($fsm, qr/\(<- \(i \(\+ i 1\)\)\)/, 'the index advances each iteration');
};

subtest 'the explicit-width form fails closed on a bad width / literal-zero count / missing count' => sub {
    my %bad = (
        'a zero width'        => '(i (width 0) n)',
        'a literal-zero count'=> '(i (width 8) 0)',
        'a non-literal count without a width' => '(i n)',
    );
    for my $label (sort keys %bad) {
        my $err = lower_error(
            "(actor t (interface (input start) (input n (width 8)) (output done) (output r (width 8))) "
            . "(transaction main (on start) (for $bad{$label} (update r (+ r 1))) (complete done)))",
            "bad-$label");
        like($err, qr/\(for/, "$label is rejected with a (for …) diagnostic");
    }
    my $nolit = lower_error(
        "(actor t (interface (input start) (input n (width 8)) (output done) (output r (width 8))) "
        . "(transaction main (on start) (for (i n) (update r (+ r 1))) (complete done)))",
        'no-width-nonlit');
    like($nolit, qr/explicit-width form/, 'a non-literal count without a width points at the explicit-width form');
};

subtest 'range form (for (i from A to B) …) counts A..B-1 starting at A' => sub {
    # ISF-FOR-LOOP.4: (for (i from A to B) body) is the range loop — the index counts
    # A, A+1, … B-1 (B-A iterations), starting at A. Desugars to a declared index defaulting
    # to A plus a counted (repeat (B-A) …) with a tail increment.
    my $actor = parse_source(<<'ISF', 'for-range');
(actor fr
  (interface (input start) (output done) (output total (width 8)))
  (transaction main
    (on start)
    (for (i from 2 to 5)
      (update total (+ total i)))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a (for (i from 2 to 5) …) range loop lowers') or diag($@);
    my $fsm = $lowered->{files}{'fr.fsm'};
    like($fsm, qr/\(main_set_\d+\n\s+\(<- \(i 2\)\)/s, 'the index starts at the lower bound A (2)');
    like($fsm, qr/\(main_repeat_init_\d+\n\s+\(<= \(main_cnt 3\)\)/s, 'the loop runs B-A == 3 iterations');
    like($fsm, qr/\(i 3\)/, 'the index width holds B (5 -> 3 bits)');
    like($fsm, qr/\(<- \(i \(\+ i 1\)\)\)/, 'the index advances each iteration');
};

subtest 'the range form fails closed on B <= A, an empty range, non-literal bounds, or a missing "to"' => sub {
    my %bad = (
        'a descending range (B < A)' => '(i from 5 to 2)',
        'an empty range (B == A)'    => '(i from 3 to 3)',
        'non-literal bounds'         => '(i from a to 5)',
        'a missing "to"'             => '(i from 2 5)',
    );
    for my $label (sort keys %bad) {
        my $err = lower_error(
            "(actor t (interface (input start) (output done) (output r (width 8))) "
            . "(transaction main (on start) (for $bad{$label} (update r (+ r 1))) (complete done)))",
            "bad-$label");
        like($err, qr/\(for/, "$label is rejected with a (for …) diagnostic");
    }
    my $desc = lower_error(
        "(actor t (interface (input start) (output done) (output r (width 8))) "
        . "(transaction main (on start) (for (i from 5 to 2) (update r (+ r 1))) (complete done)))",
        'descending');
    like($desc, qr/requires B > A/, 'a descending range names the B > A requirement');
};

subtest 'range step form (for (i from A to B step S) …) strides by S' => sub {
    # ISF-FOR-LOOP.5: (for (i from A to B step S) body) counts i = A, A+S, A+2S, … (< B)
    # — ceil((B-A)/S) iterations with a +S tail increment. Common for strided access.
    my $actor = parse_source(<<'ISF', 'for-step');
(actor fs
  (interface (input start) (output done) (output total (width 8)))
  (transaction main
    (on start)
    (for (i from 0 to 10 step 2)
      (update total (+ total i)))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a (for (i from 0 to 10 step 2) …) strided loop lowers') or diag($@);
    my $fsm = $lowered->{files}{'fs.fsm'};
    like($fsm, qr/\(main_repeat_init_\d+\n\s+\(<= \(main_cnt 5\)\)/s, 'ceil((10-0)/2) == 5 iterations');
    like($fsm, qr/\(<- \(i 0\)\)/, 'the index starts at A (0)');
    like($fsm, qr/\(<- \(i \(\+ i 2\)\)\)/, 'the index advances by the step S (2)');
};

subtest 'the range step form fails closed on a zero/non-literal step or trailing junk' => sub {
    my %bad = (
        'a zero step'          => '(i from 0 to 10 step 0)',
        'a non-literal step'   => '(i from 0 to 10 step s)',
        'a non-step trailer'   => '(i from 0 to 10 by 2)',
    );
    for my $label (sort keys %bad) {
        my $err = lower_error(
            "(actor t (interface (input start) (input s (width 4)) (output done) (output r (width 8))) "
            . "(transaction main (on start) (for $bad{$label} (update r (+ r 1))) (complete done)))",
            "bad-$label");
        like($err, qr/\(for/, "$label is rejected with a (for …) diagnostic");
    }
};

subtest 'a nested (for …) inside a for body lowers with hoisted indices (ISF-FOR-LOOP.6)' => sub {
    # (for (i M) (for (j N) body)) desugars to BOTH index locals hoisted to the transaction
    # top, an outer counted repeat whose body resets j and runs an inner counted repeat, and
    # i/j tail increments — the body runs M*N times. It rides nested counted repeat
    # (ISF-NESTED-COUNTED-REPEAT) so the inner/outer counters are distinct.
    my $actor = parse_source(<<'ISF', 'nested-for');
(actor nfo
  (interface (input start) (output done) (output grid (width 8)))
  (transaction main
    (on start)
    (for (i 3)
      (for (j 2)
        (update grid (+ grid (+ i j)))))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a nested (for (i 3) (for (j 2) …)) lowers') or diag($@);
    my $fsm = $lowered->{files}{'nfo.fsm'};
    like($fsm, qr/\(i 2\)/, 'the outer index i is declared (hoisted to +size)');
    like($fsm, qr/\(j 2\)/, 'the inner index j is declared (hoisted to +size)');
    like($fsm, qr/\(main_cnt \d+\)/, 'the outer repeat counter is declared');
    like($fsm, qr/\(main_cnt_\d+ \d+\)/, 'a distinct inner repeat counter is declared');
    like($fsm, qr/\(<- \(j 0\)\)/, 'the inner index j resets to its start each outer iteration');
    like($fsm, qr/\(<- \(i \(\+ i 1\)\)\)/, 'the outer index i advances each outer iteration');
    like($fsm, qr/\(<- \(j \(\+ j 1\)\)\)/, 'the inner index j advances each inner iteration');
};

subtest 'a (for …) embedded in a control-flow body lowers with its index hoisted (ISF-FOR-LOOP.7)' => sub {
    # A (for …) inside a when/switch/while/until/repeat body now lowers: its index (local …)
    # is hoisted to the transaction top, and an index reset (set i START) is prepended in the
    # body so each enclosing entry restarts the index.
    my $actor = parse_source(<<'ISF', 'embedded-for');
(actor ef
  (interface (input start) (input go) (output done) (output total (width 8)))
  (transaction main
    (on start)
    (when go
      (for (i 4)
        (update total (+ total i))))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a (for …) embedded in a when body lowers') or diag($@);
    my $fsm = $lowered->{files}{'ef.fsm'};
    like($fsm, qr/\(i 3\)/, 'the index i is hoisted to +size at the transaction top');
    like($fsm, qr/\(<- \(i 0\)\)/, 'the index resets to its start value in the when body');
    like($fsm, qr/main_repeat_init_\d+/, 'the loop body lowers to a counted repeat inside the when');

    # for inside a while body also lowers (the loop reruns the inner for each iteration)
    my $while_for = parse_source(<<'ISF', 'while-for');
(actor wf
  (clock clk) (reset rst_n)
  (interface (input start) (input c) (output done) (output total (width 8)))
  (transaction main
    (on start)
    (while c
      (for (i 3)
        (update total (+ total i))))
    (complete done)))
ISF
    ok(eval { FSM::Scheduler::ISF->new()->lower($while_for) }, 'a (for …) embedded in a while body lowers') or diag($@);
};

done_testing();
