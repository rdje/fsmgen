#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-WHEN-FIELD
#
# `(when-field NAME (bits HI LO) V body…)` / `(unless-field NAME (bits HI LO) V body…)` —
# branch on a multi-bit register field value (the read/compare companion to set-field, the
# multi-bit generalisation of when-bit). Pure ISF parser desugar into a `(when …)` with a
# width-qualified masked field comparison:
#   (when-field   x (bits HI LO) V body…) -> (when (== (& x W'dFIELDMASK) W'dSHIFTED) body…)
#   (unless-field x (bits HI LO) V body…) -> (when (!= (& x W'dFIELDMASK) W'dSHIFTED) body…)
#     FIELDMASK = ((2^(HI-LO+1)) - 1) << LO ; SHIFTED = V << LO
# HI, LO, V are literals (HI >= LO, HI < W, V fits the field); W is the register's declared
# literal width.

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

subtest 'when-field / unless-field desugar to a sized masked field comparison' => sub {
    # mode[2:0] == 3 on a width-8 register: field mask 7, shifted value 3
    my $fsm = lower_fsm(<<'ISF', 'wf');
(actor wf
  (interface (input start) (input mode (width 8)) (output done) (output turbo (width 8)) (output normal (width 8)))
  (transaction main
    (on start)
    (when-field mode (bits 2 0) 3 (set turbo 1))
    (unless-field mode (bits 2 0) 3 (set normal 1))
    (complete done)))
ISF
    like($fsm, qr/\Q(== (& mode 8'd7) 8'd3)\E/, '(when-field mode (bits 2 0) 3 …) -> (== (& mode 8\'d7) 8\'d3)');
    like($fsm, qr/\Q(!= (& mode 8'd7) 8'd3)\E/, '(unless-field mode (bits 2 0) 3 …) -> (!= (& mode 8\'d7) 8\'d3)');

    # a high field [7:4] == 10: mask 0xF0=240, shifted 10<<4 = 160
    my $high = lower_fsm(<<'ISF', 'wfh');
(actor wfh
  (interface (input start) (input r (width 8)) (output done) (output o (width 8)))
  (transaction main (on start) (when-field r (bits 7 4) 10 (set o 1)) (complete done)))
ISF
    like($high, qr/\Q(== (& r 8'd240) 8'd160)\E/, 'a high field [7:4] == 10 -> (== (& r 8\'d240) 8\'d160)');
};

subtest 'the body still expands earlier sugar (incr); width resolves from a local' => sub {
    my $fsm = lower_fsm(<<'ISF', 'wfb');
(actor wfb
  (interface (input start) (output done) (output c (width 8)))
  (transaction main
    (on start)
    (local sel (width 4) (reset 5))
    (when-field sel (bits 1 0) 1 (incr c))
    (complete done)))
ISF
    # sel is width-4: [1:0]==1 -> mask 3, shifted 1 (4-bit sized)
    like($fsm, qr/\Q(== (& sel 4'd3) 4'd1)\E/, 'width resolves from a (local …): (when-field sel (bits 1 0) 1 …)');
    like($fsm, qr/\Q(+ c 1)\E/, 'an (incr c) inside a (when-field …) body is still desugared (pass ordering)');
};

subtest 'malformed when-field forms fail closed' => sub {
    like(lower_error(
        "(actor t (interface (input start) (input m (width 8)) (output done) (output o (width 8))) "
        . "(transaction main (on start) (when-field m (bits 2 0) 8 (set o 1)) (complete done)))", 'of'),
        qr/value 8 does not fit in the 3-bit field \[2:0\]/,
        'a value overflowing the field is rejected');

    like(lower_error(
        "(actor t (interface (input start) (input m (width 8)) (output done) (output o (width 8))) "
        . "(transaction main (on start) (when-field m (bits 2 0) 3) (complete done)))", 'nb'),
        qr/requires a non-empty body/,
        '(when-field …) with no body is rejected');

    like(lower_error(
        "(actor t (interface (input start) (input m (width 8)) (output done) (output o (width 8))) "
        . "(transaction main (on start) (when-field m 2 0 3 (set o 1)) (complete done)))", 'ns'),
        qr/requires a \(bits HI LO\) field selector/,
        'a missing (bits …) selector is rejected');

    like(lower_error(
        "(actor t (params (W 8)) (interface (input start) (input m (width W)) (output done) (output o (width 8))) "
        . "(transaction main (on start) (when-field m (bits 2 0) 3 (set o 1)) (complete done)))", 'sw'),
        qr/requires a statically known register width/,
        'a symbolic-width register fails closed');
};

done_testing();
