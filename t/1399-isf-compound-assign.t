#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-COMPOUND-ASSIGN.2
#
# `(incr NAME [by N])` / `(decr NAME [by N])` are compound-assignment sugar — the `x += N` /
# `x++` of a high-level language. Pure ISF parser desugar to the existing `(set …)` data op:
#   (incr x)      -> (set x (+ x 1))   (incr x by N) -> (set x (+ x N))
#   (decr x)      -> (set x (- x 1))   (decr x by N) -> (set x (- x N))
# N defaults to 1 and may be a literal, signal, or expression. They work anywhere a `(set …)`
# is valid (top level + control-flow bodies). NOTE: a register written by two+ expression
# `(set …)`s in ONE transaction (e.g. two literal `(incr x)` in a row) hits a pre-existing
# codegen constraint (one expression write-enable per register); the common single-incr and
# incr-in-a-loop patterns are unaffected, and combining with `(incr x by 2)` avoids it.

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

subtest '(incr/decr NAME [by N]) desugar to (set NAME (± NAME N))' => sub {
    my $fsm = lower_fsm(<<'ISF', 'ca');
(actor ca
  (interface (input start) (input din (width 8)) (output done) (output a (width 8)) (output b (width 8)))
  (transaction main
    (on start)
    (local x (width 8) (default 0))
    (local y (width 8) (default 100))
    (incr x by din)
    (decr y by 3)
    (update a x)
    (update b y)
    (complete done)))
ISF
    like($fsm, qr/\(<- \(x \(\+ x din\)\)\)/, '(incr x by din) -> (set x (+ x din))');
    like($fsm, qr/\(<- \(y \(- y 3\)\)\)/, '(decr y by 3) -> (set y (- y 3))');

    # default amount is 1
    my $unit = lower_fsm(<<'ISF', 'cu');
(actor cu
  (interface (input start) (output done) (output a (width 8)) (output b (width 8)))
  (transaction main
    (on start)
    (local x (width 8) (default 0))
    (local y (width 8) (default 9))
    (incr x)
    (decr y)
    (update a x)
    (update b y)
    (complete done)))
ISF
    like($unit, qr/\(<- \(x \(\+ x 1\)\)\)/, '(incr x) defaults to += 1');
    like($unit, qr/\(<- \(y \(- y 1\)\)\)/, '(decr y) defaults to -= 1');
};

subtest 'incr in a loop body accumulates (the common pattern) and recurses into control flow' => sub {
    # (for (i N) (incr total)) is one (set total (+ total 1)) state executed N times — the
    # canonical accumulator; it lowers cleanly and (verified by simulation) totals N.
    my $loop = lower_fsm(<<'ISF', 'cl');
(actor cl
  (interface (input start) (output done) (output total (width 8)))
  (transaction main
    (on start)
    (for (i 5)
      (incr total))
    (complete done)))
ISF
    like($loop, qr/\(<- \(total> \(\+ total 1\)\)\)/, 'an (incr total) in a for body becomes the loop-body (set total (+ total 1))');

    my $when = lower_fsm(<<'ISF', 'cwn');
(actor cwn
  (interface (input start) (input go) (output done) (output r (width 8)))
  (transaction main
    (on start)
    (local x (width 8) (default 0))
    (when go
      (incr x by 4))
    (update r x)
    (complete done)))
ISF
    like($when, qr/\(<- \(x \(\+ x 4\)\)\)/, 'an (incr x by 4) nested in a when body is rewritten');
};

subtest '(incr/decr …) fail closed on a missing name or a malformed by' => sub {
    my $no_name = lower_error(
        "(actor t (interface (input start) (output done) (output r (width 8))) "
        . "(transaction main (on start) (local x (width 8)) (incr) (update r x) (complete done)))",
        'no-name');
    like($no_name, qr/\(incr \.\.\.\) .* requires a register name/, '(incr) with no name is rejected');

    my $bad_by = lower_error(
        "(actor t (interface (input start) (output done) (output r (width 8))) "
        . "(transaction main (on start) (local x (width 8)) (incr x foo 2) (update r x) (complete done)))",
        'bad-by');
    like($bad_by, qr/trailing tokens require 'by N'/, "a malformed (incr x foo 2) is rejected");
};

done_testing();
