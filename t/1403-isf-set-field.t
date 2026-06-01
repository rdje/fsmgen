#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-SET-FIELD
#
# `(set-field NAME (bits HI LO) V)` — write a multi-bit register field to a literal value,
# preserving the other bits. Pure ISF parser desugar into a width-clean masked
# read-modify-write `(set …)` using sized literals:
#   (set-field x (bits HI LO) V) -> (set x (| (& x W'dCLEARMASK) W'dSHIFTED))
#     CLEARMASK = (2^W - 1) ^ (((2^(HI-LO+1)) - 1) << LO)
#     SHIFTED   = V << LO
# HI, LO, V are literals (HI >= LO, HI < W, V fits the field); W is the register's declared
# literal width (resolved from a (local …), an interface port, or a storage var).

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

subtest 'set-field desugars to a sized masked read-modify-write' => sub {
    # [5:3] <- 5 on a width-8 register: field mask 0b111000=56, clear mask 255^56=199,
    # shifted value 5<<3 = 40
    my $fsm = lower_fsm(<<'ISF', 'sf');
(actor sf
  (interface (input start) (output done) (output ctrl (width 8)))
  (transaction main
    (on start)
    (set-field ctrl (bits 5 3) 5)
    (complete done)))
ISF
    like($fsm, qr/\Q(| (& ctrl 8'd199) 8'd40)\E/, '(set-field ctrl (bits 5 3) 5) -> (| (& ctrl 8\'d199) 8\'d40)');

    # a single-bit field [2:2] <- 1: field mask 4, clear mask 251, shifted 4
    my $one = lower_fsm(<<'ISF', 'sf1');
(actor sf1
  (interface (input start) (output done) (output r (width 8)))
  (transaction main (on start) (set-field r (bits 2 2) 1) (complete done)))
ISF
    like($one, qr/\Q(| (& r 8'd251) 8'd4)\E/, 'a single-bit field [2:2] <- 1 -> (| (& r 8\'d251) 8\'d4)');

    # a full-width field [7:0] <- 24: clear mask 0, value 24
    my $full = lower_fsm(<<'ISF', 'sff');
(actor sff
  (interface (input start) (output done) (output d (width 8)))
  (transaction main (on start) (set-field d (bits 7 0) 24) (complete done)))
ISF
    like($full, qr/\Q(| (& d 8'd0) 8'd24)\E/, 'a full-width field [7:0] <- 24 -> (| (& d 8\'d0) 8\'d24)');
};

subtest 'width resolves from a local / storage var, and set-field nests in control flow' => sub {
    # width-6 local: [3:1] <- 2: field mask 0b1110=14, clear mask 63^14=49, shifted 2<<1=4
    my $local = lower_fsm(<<'ISF', 'sfl');
(actor sfl
  (interface (input start) (output done) (output o (width 6)))
  (transaction main
    (on start)
    (local r (width 6))
    (set-field r (bits 3 1) 2)
    (update o r)
    (complete done)))
ISF
    like($local, qr/\Q(| (& r 6'd49) 6'd4)\E/, 'width from a (local …): [3:1] <- 2 on width 6 -> (| (& r 6\'d49) 6\'d4)');

    my $store = lower_fsm(<<'ISF', 'sfs');
(actor sfs
  (interface (input start) (output done) (output o (width 4)))
  (storage (var sv (width 4)))
  (transaction main (on start) (set-field sv (bits 1 0) 3) (update o sv) (complete done)))
ISF
    like($store, qr/\Q(| (& sv 4'd12) 4'd3)\E/, 'width from a storage var: [1:0] <- 3 on width 4 -> (| (& sv 4\'d12) 4\'d3)');

    my $when = lower_fsm(<<'ISF', 'sfw');
(actor sfw
  (interface (input start) (input go) (output done) (output ctrl (width 8)))
  (transaction main
    (on start)
    (when go
      (set-field ctrl (bits 5 3) 5))
    (complete done)))
ISF
    like($when, qr/\Q(| (& ctrl 8'd199) 8'd40)\E/, 'a (set-field …) inside a (when …) body is rewritten');
};

subtest 'malformed set-field forms fail closed' => sub {
    like(lower_error(
        "(actor t (interface (input start) (output done) (output r (width 8))) "
        . "(transaction main (on start) (set-field r (bits 5 3) 8) (complete done)))", 'of'),
        qr/value 8 does not fit in the 3-bit field \[5:3\]/,
        'a value overflowing the field is rejected');

    like(lower_error(
        "(actor t (interface (input start) (output done) (output r (width 8))) "
        . "(transaction main (on start) (set-field r (bits 2 5) 1) (complete done)))", 'rev'),
        qr/requires HI >= LO/,
        'a reversed (bits HI LO) selector is rejected');

    like(lower_error(
        "(actor t (interface (input start) (output done) (output r (width 8))) "
        . "(transaction main (on start) (set-field r (bits 8 6) 1) (complete done)))", 'oor'),
        qr/bit 8 is out of range for the 8-bit register 'r'/,
        'a HI index past the register width is rejected');

    like(lower_error(
        "(actor t (interface (input start) (output done) (output r (width 8))) "
        . "(transaction main (on start) (set-field r 5 3 1) (complete done)))", 'nosel'),
        qr/requires a \(bits HI LO\) field selector/,
        'a missing (bits …) selector is rejected');

    like(lower_error(
        "(actor t (params (W 8)) (interface (input start) (output done) (output r (width W))) "
        . "(transaction main (on start) (set-field r (bits 2 0) 1) (complete done)))", 'symw'),
        qr/requires a statically known register width/,
        'a symbolic-width register fails closed');
};

done_testing();
