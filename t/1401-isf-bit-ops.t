#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-BIT-OPS
#
# `(set-bit NAME N)` / `(clear-bit NAME N)` / `(toggle-bit NAME N)` — single-bit register
# manipulation (CSR / flag intent). Pure ISF parser desugar into a single-level masked
# `(set …)` using supported `.fsm` operators (`|`, `&`, `^`):
#   (set-bit    x N) -> (set x (| x  2^N))
#   (toggle-bit x N) -> (set x (^ x  2^N))
#   (clear-bit  x N) -> (set x (& x ((2^W-1) ^ 2^N)))   ; needs the literal width W
# N is a literal index with 0 <= N < W. set-bit/toggle-bit masks are width-independent;
# clear-bit's inverse mask requires a statically known width (resolved from the register's
# (local …) / interface / storage declaration), failing closed when the width is symbolic.

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

subtest 'set-bit / toggle-bit desugar to a single-level OR / XOR with a 2^N literal mask' => sub {
    my $fsm = lower_fsm(<<'ISF', 'bset');
(actor bset
  (interface (input start) (output done) (output ctrl (width 8)) (output mode (width 8)))
  (transaction main
    (on start)
    (set-bit ctrl 0)
    (toggle-bit mode 7)
    (complete done)))
ISF
    like($fsm, qr/\(<- \(ctrl> \(\| ctrl 1\)\)\)/, '(set-bit ctrl 0) -> (set ctrl (| ctrl 1))');
    like($fsm, qr/\(<- \(mode> \(\^ mode 128\)\)\)/, '(toggle-bit mode 7) -> (set mode (^ mode 128))');
};

subtest 'clear-bit desugars to a single-level AND with the inverse mask ((2^W-1) ^ 2^N)' => sub {
    # width resolved from the interface port (8 bits): bit 3 -> 255 ^ 8 = 247
    my $iface = lower_fsm(<<'ISF', 'bclr');
(actor bclr
  (interface (input start) (output done) (output irq (width 8)))
  (transaction main (on start) (clear-bit irq 3) (complete done)))
ISF
    like($iface, qr/\(<- \(irq> \(& irq 247\)\)\)/, '(clear-bit irq 3) on a width-8 port -> (& irq 247)');

    # width resolved from a transaction-local (6 bits): bit 1 -> 63 ^ 2 = 61
    my $local = lower_fsm(<<'ISF', 'bcl2');
(actor bcl2
  (interface (input start) (output done) (output o (width 6)))
  (transaction main
    (on start)
    (local fl (width 6) (reset 63))
    (clear-bit fl 1)
    (update o fl)
    (complete done)))
ISF
    like($local, qr/\(<- \(fl \(& fl 61\)\)\)/, 'width resolved from a (local …): (clear-bit fl 1) -> (& fl 61)');

    # width resolved from a storage var (4 bits): bit 0 -> 15 ^ 1 = 14
    my $store = lower_fsm(<<'ISF', 'bcl3');
(actor bcl3
  (interface (input start) (output done) (output o (width 4)))
  (storage (var sv (width 4)))
  (transaction main (on start) (clear-bit sv 0) (update o sv) (complete done)))
ISF
    like($store, qr/\(<- \(sv \(& sv 14\)\)\)/, 'width resolved from a storage (var …): (clear-bit sv 0) -> (& sv 14)');
};

subtest 'bit ops are rewritten inside control-flow bodies' => sub {
    my $when = lower_fsm(<<'ISF', 'bwhen');
(actor bwhen
  (interface (input start) (input go) (output done) (output ctrl (width 8)))
  (transaction main
    (on start)
    (when go
      (set-bit ctrl 5))
    (complete done)))
ISF
    like($when, qr/\(<- \(ctrl> \(\| ctrl 32\)\)\)/, '(set-bit ctrl 5) inside a (when …) body is rewritten');
};

subtest 'malformed bit ops and out-of-range / symbolic widths fail closed' => sub {
    like(lower_error(
        "(actor t (interface (input start) (output done) (output r (width 8))) "
        . "(transaction main (on start) (set-bit r 8) (complete done)))", 'oor'),
        qr/bit index 8 is out of range for the 8-bit register 'r'/,
        '(set-bit r 8) on a width-8 register is out of range');

    like(lower_error(
        "(actor t (interface (input start) (output done) (output r (width 8))) "
        . "(transaction main (on start) (set-bit r) (complete done)))", 'noidx'),
        qr/requires exactly one literal bit index/,
        '(set-bit r) with no bit index is rejected');

    like(lower_error(
        "(actor t (interface (input start) (output done) (output r (width 8))) "
        . "(transaction main (on start) (set-bit r foo) (complete done)))", 'badidx'),
        qr/requires a non-negative integer bit index/,
        '(set-bit r foo) with a non-integer index is rejected');

    like(lower_error(
        "(actor t (params (W 8)) (interface (input start) (output done) (output r (width W))) "
        . "(transaction main (on start) (clear-bit r 2) (complete done)))", 'symw'),
        qr/requires a statically known register width/,
        '(clear-bit r 2) on a symbolic-width register fails closed');
};

done_testing();
