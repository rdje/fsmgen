#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-PROCEDURES.2
#
# A `(proc NAME (params (P (width N))...) BODY...)` defines a reusable parameterized
# block. The INLINE call `(call NAME actuals...)` macro-expands the body at the call
# site with the actuals substituted for the (value/in) parameters — the emitted
# `.fsm` is identical to writing the substituted clauses out by hand. The handshake
# form `(call ... as INST)` and out-parameters are deferred to later slices.
#
# The expansion happens at PARSE time (in the adapter), so malformed calls surface
# from parse_source — the fail-closed cases wrap parse_source in eval.

sub lower_source {
    my ($source, $label) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub lower_error {
    my ($source, $label) = @_;
    my $ok = eval { lower_source($source, $label); 1 };
    return $ok ? '' : $@;
}

subtest 'an inline (call) expands the proc body with the actual substituted' => sub {
    my $lowered = eval {
        lower_source(<<'ISF', 'acc');
(actor acc_demo
  (interface (input start) (input din (width 8)) (output done) (output total (width 8)))
  (proc accumulate (params (in (width 8)))
    (update total (+ total in)))
  (transaction main
    (on start)
    (sample din as s)
    (call accumulate s)
    (call accumulate (+ s 1))
    (complete done)))
ISF
    };
    ok($lowered, 'a proc + inline calls lower') or diag($@);
    my $fsm = $lowered->{files}{'acc_demo.fsm'};
    # (call accumulate s)      -> (update total (+ total s))
    # (call accumulate (+ s 1))-> (update total (+ total (+ s 1)))
    like($fsm, qr/\(total>\s*\(\+ total s\)\)/, 'a signal actual is substituted into the body');
    like($fsm, qr/\(total>\s*\(\+ total \(\+ s 1\)\)\)/, 'a whole expression actual is substituted into the body');
    unlike($fsm, qr/\baccumulate\b/, 'the proc name does not appear in the lowered schedule (fully inlined)');
};

subtest 'inline expansion is identical to writing the clauses out by hand' => sub {
    my $with_proc = lower_source(<<'ISF', 'wp');
(actor wp
  (interface (input start) (input din (width 8)) (output done) (output total (width 8)))
  (proc dbl (params (x (width 8))) (update total (+ x x)))
  (transaction main (on start) (sample din as s) (call dbl s) (complete done)))
ISF
    my $hand = lower_source(<<'ISF', 'hand');
(actor wp
  (interface (input start) (input din (width 8)) (output done) (output total (width 8)))
  (transaction main (on start) (sample din as s) (update total (+ s s)) (complete done)))
ISF
    is($with_proc->{files}{'wp.fsm'}, $hand->{files}{'wp.fsm'},
        'the proc-expanded .fsm is byte-identical to the hand-written .fsm');
};

subtest 'a multi-parameter proc substitutes positionally' => sub {
    my $lowered = lower_source(<<'ISF', 'mp');
(actor mp
  (interface (input start) (input a (width 8)) (input b (width 8)) (output done) (output total (width 8)))
  (proc madd (params (x (width 8)) (y (width 8))) (update total (+ x y)))
  (transaction main (on start) (sample a as av) (sample b as bv) (call madd av bv) (complete done)))
ISF
    my $fsm = $lowered->{files}{'mp.fsm'};
    like($fsm, qr/\(total>\s*\(\+ av bv\)\)/, 'two actuals substitute positionally for the two params');
};

subtest 'an inline (call) lowers inside when and while bodies' => sub {
    for my $ctx (['when', '(when go (call inc s))'], ['while', '(while go (call inc s))']) {
        my ($label, $body) = @$ctx;
        my $lowered = lower_source(<<"ISF", "ctx-$label");
(actor ctx_call
  (interface (input start) (input go) (input din (width 8)) (output done) (output total (width 8)))
  (proc inc (params (v (width 8))) (update total (+ total v)))
  (transaction main (on start) (sample din as s) $body (complete done)))
ISF
        my $fsm = $lowered->{files}{'ctx_call.fsm'};
        like($fsm, qr/\(total>\s*\(\+ total s\)\)/, "a (call) inside a $label body expands");
    }
};

subtest 'inline-procedure misuse fails closed with targeted diagnostics' => sub {
    my $proc = '(proc p (params (a (width 8))) (update total a))';
    my $base = sub {
        my ($pdef, $callline) = @_;
        return "(actor t (interface (input start) (input din (width 8)) (output done) (output total (width 8))) "
            . "$pdef (transaction main (on start) (sample din as s) $callline (complete done)))";
    };

    like(lower_error($base->($proc, '(call q s)'), 'unknown'),
        qr/calls unknown procedure 'q'/, 'unknown procedure');

    like(lower_error($base->('(proc p (params (a (width 8)) (b (width 8))) (update total a))', '(call p s)'), 'arity'),
        qr/passes 1 argument\(s\) but proc 'p' declares 2 parameter\(s\)/, 'arity mismatch');

    like(lower_error($base->('(proc p (params (a (width 8))) (call p a))', '(call p s)'), 'recursion'),
        qr/recursive procedure call '\(call p \.\.\.\)' is not lowerable to hardware/, 'recursion');

    like(lower_error($base->($proc, '(call p s as i0)'), 'handshake'),
        qr/'\(call p \.\.\. as INST\)' handshake-form procedure call is not yet supported/, 'handshake form deferred');

    like(lower_error($base->('(proc p (params (out r (width 8))) (update r 1))', '(call p (+ s 1))'), 'outexpr'),
        qr/out-parameter 'r' requires a plain signal actual to write back into, not an expression/,
        'an expression actual for an out-parameter is rejected');
};

subtest 'inline out-parameters write back into the caller-chosen signal' => sub {
    # ISF-PROCEDURES.3: an (out NAME (width N)) parameter names a caller lvalue the
    # procedure writes into; the caller picks the target per call.
    my $lowered = lower_source(<<'ISF', 'outp');
(actor outp
  (interface (input start) (input din (width 8)) (output done)
             (output r1 (width 8)) (output r2 (width 8)))
  (proc compute (params (in (width 8)) (out r (width 8)))
    (update r (+ in 1)))
  (transaction main
    (on start)
    (sample din as s)
    (call compute s r1)          ;; expands to: (update r1 (+ s 1))
    (call compute (+ s 1) r2)    ;; expands to: (update r2 (+ (+ s 1) 1))
    (complete done)))
ISF
    my $fsm = $lowered->{files}{'outp.fsm'};
    like($fsm, qr/\(r1>\s*\(\+ s 1\)\)/, 'the out-parameter writes into the first caller signal (r1)');
    like($fsm, qr/\(r2>\s*\(\+ \(\+ s 1\) 1\)\)/, 'the out-parameter writes into the second caller signal (r2), with the expression in-actual');
};

subtest 'a malformed (proc) fails closed' => sub {
    like(lower_error(
        '(actor t (interface (input start) (output done)) (proc (params)) (transaction main (on start) (complete done)))',
        'noname'),
        qr/\(proc \.\.\.\) in actor 't' requires a name/, 'proc without a name');

    like(lower_error(
        '(actor t (interface (input start) (output done) (output total (width 8))) (proc p (update total 1)) (transaction main (on start) (complete done)))',
        'noparams'),
        qr/proc 'p' in actor 't' requires a \(params \.\.\.\) clause/, 'proc without a (params ...) clause');

    like(lower_error(
        '(actor t (interface (input start) (output done)) (proc p (params)) (transaction main (on start) (complete done)))',
        'nobody'),
        qr/proc 'p' in actor 't' has an empty body/, 'proc with an empty body');
};

done_testing();
