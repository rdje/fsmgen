#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-ROTATE
#
# `(rotate-left REG [by N])` / `(rotate-right REG [by N])` — bit rotation (the wrap-around
# sibling of shift_left/shift_right). Pure ISF parser desugar into a single masked shift-OR:
#   (rotate-left  REG by N) -> (set REG (| (<< REG N) (>> REG (W-N))))
#   (rotate-right REG by N) -> (set REG (| (>> REG N) (<< REG (W-N))))
# N defaults to 1, a literal 0 < N < W; W is the register's declared literal width.

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

subtest 'rotate-left / rotate-right desugar to the masked shift-OR with W-N counter shift' => sub {
    my $rol = lower_fsm(<<'ISF', 'rol');
(actor rol
  (interface (input start) (output done) (output r (width 8)))
  (transaction main (on start) (rotate-left r) (complete done)))
ISF
    like($rol, qr/\Q(| (<< r 1) (>> r 7))\E/, '(rotate-left r) on width 8 -> (| (<< r 1) (>> r 7))');

    my $ror = lower_fsm(<<'ISF', 'ror');
(actor ror
  (interface (input start) (output done) (output r (width 8)))
  (transaction main (on start) (rotate-right r by 3) (complete done)))
ISF
    like($ror, qr/\Q(| (>> r 3) (<< r 5))\E/, '(rotate-right r by 3) on width 8 -> (| (>> r 3) (<< r 5))');

    # width resolved from a local (width 6): rotate-left by 2 -> << 2 / >> 4
    my $loc = lower_fsm(<<'ISF', 'rl6');
(actor rl6
  (interface (input start) (output done) (output o (width 6)))
  (transaction main
    (on start)
    (local r (width 6) (reset 1))
    (rotate-left r by 2)
    (update o r)
    (complete done)))
ISF
    like($loc, qr/\Q(| (<< r 2) (>> r 4))\E/, 'width from a (local …): (rotate-left r by 2) on width 6 -> (<< r 2)/(>> r 4)');
};

subtest 'rotate nested in a control-flow body is rewritten' => sub {
    my $fsm = lower_fsm(<<'ISF', 'rw');
(actor rw
  (interface (input start) (input go) (output done) (output r (width 8)))
  (transaction main
    (on start)
    (when go
      (rotate-left r))
    (complete done)))
ISF
    like($fsm, qr/\Q(| (<< r 1) (>> r 7))\E/, 'a (rotate-left …) inside a (when …) body is rewritten');
};

subtest 'malformed rotate forms and out-of-range / symbolic widths fail closed' => sub {
    like(lower_error(
        "(actor t (interface (input start) (output done) (output r (width 8))) "
        . "(transaction main (on start) (rotate-left r by 0) (complete done)))", 'z'),
        qr/requires 0 < N < 8/,
        '(rotate-left r by 0) is rejected');

    like(lower_error(
        "(actor t (interface (input start) (output done) (output r (width 8))) "
        . "(transaction main (on start) (rotate-left r by 8) (complete done)))", 'w'),
        qr/requires 0 < N < 8/,
        '(rotate-left r by 8) on a width-8 register is rejected');

    like(lower_error(
        "(actor t (interface (input start) (output done) (output r (width 8))) "
        . "(transaction main (on start) (rotate-left r foo 2) (complete done)))", 'b'),
        qr/trailing tokens require 'by N'/,
        'a malformed (rotate-left r foo 2) is rejected');

    like(lower_error(
        "(actor t (params (W 8)) (interface (input start) (output done) (output r (width W))) "
        . "(transaction main (on start) (rotate-left r) (complete done)))", 's'),
        qr/requires a statically known register width/,
        'a symbolic-width register fails closed');
};

done_testing();
