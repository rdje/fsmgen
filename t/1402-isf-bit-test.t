#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-BIT-TEST
#
# `(when-bit NAME N body…)` / `(unless-bit NAME N body…)` — branch on a single register bit
# (the read side of CSR / flag intent). Pure ISF parser desugar into a `(when …)` with a
# width-qualified masked comparison:
#   (when-bit   x N body…) -> (when (!= (& x W'dMASK) W'd0) body…)   ; MASK = 2^N
#   (unless-bit x N body…) -> (when (== (& x W'dMASK) W'd0) body…)
# N is a literal index 0 <= N < W; the sized literals require a statically known width, so a
# symbolic width fails closed (as clear-bit does). The pass runs before the compound/bit-op
# passes so an (incr …)/(set-bit …) inside the desugared body still expands.

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

subtest 'when-bit / unless-bit desugar to a sized masked (when …)' => sub {
    my $fsm = lower_fsm(<<'ISF', 'wb');
(actor wb
  (interface (input start) (input cfg (width 8)) (output done) (output hit (width 8)) (output miss (width 8)))
  (transaction main
    (on start)
    (when-bit cfg 3 (set hit 1))
    (unless-bit cfg 3 (set miss 1))
    (complete done)))
ISF
    # mask for bit 3 is 8, sized to the 8-bit register; the when lowers to a `?` decision
    like($fsm, qr/\Q(!= (& cfg 8'd8) 8'd0)\E/, '(when-bit cfg 3 …) guards on (!= (& cfg 8\'d8) 8\'d0)');
    like($fsm, qr/\Q(== (& cfg 8'd8) 8'd0)\E/, '(unless-bit cfg 3 …) guards on (== (& cfg 8\'d8) 8\'d0)');
};

subtest 'the body of a bit test still expands earlier sugar (incr) — pass ordering' => sub {
    my $fsm = lower_fsm(<<'ISF', 'wbody');
(actor wbody
  (interface (input start) (input cfg (width 4)) (output done) (output c (width 8)))
  (transaction main
    (on start)
    (when-bit cfg 0 (incr c))
    (complete done)))
ISF
    like($fsm, qr/\Q(<- (c> (+ c 1)))\E/, 'an (incr c) inside a (when-bit …) body is still desugared to (set c (+ c 1))');
};

subtest 'width resolves from a local; nested bit tests expand' => sub {
    my $fsm = lower_fsm(<<'ISF', 'wnest');
(actor wnest
  (interface (input start) (output done) (output o (width 8)))
  (transaction main
    (on start)
    (local r (width 6) (reset 5))
    (when-bit r 0
      (unless-bit r 1
        (set o 1)))
    (complete done)))
ISF
    # width-6 register: bit0 mask 1, bit1 mask 2, sized to 6 bits
    like($fsm, qr/\Q(!= (& r 6'd1) 6'd0)\E/, 'outer when-bit (bit 0) uses a 6-bit sized mask');
    like($fsm, qr/\Q(== (& r 6'd2) 6'd0)\E/, 'nested unless-bit (bit 1) is also expanded with a 6-bit sized mask');
};

subtest 'malformed bit tests and out-of-range / symbolic widths fail closed' => sub {
    like(lower_error(
        "(actor t (interface (input start) (input cfg (width 8)) (output done) (output o (width 8))) "
        . "(transaction main (on start) (when-bit cfg 8 (set o 1)) (complete done)))", 'oor'),
        qr/bit index 8 is out of range for the 8-bit register 'cfg'/,
        '(when-bit cfg 8 …) on a width-8 register is out of range');

    like(lower_error(
        "(actor t (interface (input start) (input cfg (width 8)) (output done) (output o (width 8))) "
        . "(transaction main (on start) (when-bit cfg 2) (complete done)))", 'nobody'),
        qr/requires a non-empty body/,
        '(when-bit cfg 2) with no body is rejected');

    like(lower_error(
        "(actor t (interface (input start) (input cfg (width 8)) (output done) (output o (width 8))) "
        . "(transaction main (on start) (when-bit cfg foo (set o 1)) (complete done)))", 'badidx'),
        qr/requires a non-negative integer bit index/,
        '(when-bit cfg foo …) with a non-integer index is rejected');

    like(lower_error(
        "(actor t (params (W 8)) (interface (input start) (input cfg (width W)) (output done) (output o (width 8))) "
        . "(transaction main (on start) (when-bit cfg 2 (set o 1)) (complete done)))", 'symw'),
        qr/requires a statically known register width/,
        '(when-bit cfg 2 …) on a symbolic-width register fails closed');
};

done_testing();
