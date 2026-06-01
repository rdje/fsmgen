#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-SWAP
#
# `(swap A B)` — exchange the contents of two registers via the temp-free XOR swap:
#   (swap A B) -> (set A (^ A B)) (set B (^ A B)) (set A (^ A B))
# After the three states A holds the original B and B the original A. A and B must be distinct
# (XOR-swapping a register with itself zeroes it). Correct since A's two writes get distinct
# write-enables (CODEGEN-MULTI-EXPRESSION-SET-ALIAS).

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

subtest '(swap A B) desugars to the three XOR sets' => sub {
    my $fsm = lower_fsm(<<'ISF', 'sw');
(actor sw
  (interface (input start) (input p (width 8)) (input q (width 8)) (output done) (output a (width 8)) (output b (width 8)))
  (transaction main
    (on start)
    (local x (width 8))
    (local y (width 8))
    (update x p)
    (update y q)
    (swap x y)
    (update a x)
    (update b y)
    (complete done)))
ISF
    like($fsm, qr/\Q(<- (x (^ x y)))\E/, 'A is written A^B (twice — first and last of the three steps)');
    like($fsm, qr/\Q(<- (y (^ x y)))\E/, 'B is written A^B (the middle step), exchanging the values');
    # A is written by two XOR sets across states (steps 1 and 3)
    my $count = () = ($fsm =~ /\Q(<- (x (^ x y)))\E/g);
    is($count, 2, 'A (x) is the target of exactly two of the three XOR sets');
};

subtest 'a swap nested in a control-flow body is rewritten' => sub {
    my $fsm = lower_fsm(<<'ISF', 'sw2');
(actor sw2
  (interface (input start) (input go) (output done) (output a (width 8)) (output b (width 8)))
  (transaction main
    (on start)
    (local x (width 8) (reset 1))
    (local y (width 8) (reset 2))
    (when go
      (swap x y))
    (update a x)
    (update b y)
    (complete done)))
ISF
    like($fsm, qr/\Q(<- (x (^ x y)))\E/, 'a (swap …) inside a (when …) body is rewritten');
    like($fsm, qr/\Q(<- (y (^ x y)))\E/, 'both registers exchanged inside the body');
};

subtest 'malformed swap forms fail closed' => sub {
    like(lower_error(
        "(actor t (interface (input start) (output done) (output o (width 8))) "
        . "(transaction main (on start) (local x (width 8)) (swap x x) (update o x) (complete done)))", 'self'),
        qr/requires two distinct registers/,
        '(swap x x) on the same register is rejected');

    like(lower_error(
        "(actor t (interface (input start) (output done) (output o (width 8))) "
        . "(transaction main (on start) (local x (width 8)) (swap x) (update o x) (complete done)))", 'one'),
        qr/requires two register names/,
        '(swap x) with one operand is rejected');

    like(lower_error(
        "(actor t (interface (input start) (output done) (output o (width 8))) "
        . "(transaction main (on start) (local x (width 8)) (local y (width 8)) (swap x y z) (update o x) (complete done)))", 'three'),
        qr/requires two register names/,
        '(swap x y z) with three operands is rejected');
};

done_testing();
