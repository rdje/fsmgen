#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use Lispish;
use FSM::Adapter::FSMGenFull;

# ISF-ASSERT.2
#
# `(assert COND [message])` is a transaction-level combinational invariant. It rides the only
# path there is — ISF -> `.fsm` -> SV — as a thin `+assert` carrier: the ISF lowerer emits
# `(+assert (NAME COND ["msg"]) ...)` into the `.fsm`, and FSMGenFull parses it back onto the
# module (`$fsm_module->{attributes}{immediate_assertions}`), with COND parsed to a CoreAST
# expression (renderable to SV). No SV emission yet (that is .3).

my $tempdir = tempdir(CLEANUP => 1);

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

sub roundtrip_module {
    my ($source, $name) = @_;
    my $fsm = lower_fsm($source, $name);
    my $path = File::Spec->catfile($tempdir, "$name.fsm");
    open my $fh, '>', $path or die "write $path: $!";
    print $fh $fsm; close $fh;
    return ($fsm, FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path)));
}

subtest 'ISF (assert COND) emits a +assert carrier and round-trips through FSMGenFull' => sub {
    my ($fsm, $module) = roundtrip_module(<<'ISF', 'guard');
(actor guard
  (interface (input start) (input level (width 8)) (input depth (width 8)) (output done))
  (transaction main
    (on start)
    (assert (< level depth))
    (complete done)))
ISF
    like($fsm, qr/\(\+assert/, 'the lowered .fsm carries a +assert section');
    like($fsm, qr/\Q(main_assert_0 assert (< level depth))\E/, 'the entry carries name + kind + condition s-expr');

    my $asserts = $module->{attributes}{immediate_assertions};
    is(ref($asserts), 'ARRAY', 'the parsed module carries immediate_assertions');
    is(scalar(@$asserts), 1, 'one assertion');
    is($asserts->[0]{name}, 'main_assert_0', 'auto-generated name <tx>_assert_<n>');
    is($asserts->[0]{kind}, 'assert', 'kind is assert');
    ok($asserts->[0]{condition}->can('to_systemverilog'), 'condition parsed to a CoreAST expression');
    is($asserts->[0]{condition}->to_systemverilog(), 'level < depth', 'condition renders to SV');
};

subtest '(cover …) and (assume …) ride the same carrier with their kind' => sub {
    my ($fsm, $module) = roundtrip_module(<<'ISF', 'cv');
(actor cv
  (interface (input start) (input x (width 8)) (output done))
  (transaction main
    (on start)
    (cover (== x 7))
    (assume (< x 200) "x bounded")
    (complete done)))
ISF
    like($fsm, qr/\Q(main_cover_0 cover (== x 7))\E/, '(cover …) -> kind cover');
    like($fsm, qr/\Q(main_assume_0 assume (< x 200) "x bounded")\E/, '(assume …) -> kind assume + message');
    my $a = $module->{attributes}{immediate_assertions};
    is(scalar(@$a), 2, 'both carried');
    is($a->[0]{kind}, 'cover', 'first is cover');
    is($a->[0]{name}, 'main_cover_0', 'per-kind ordinal naming for cover');
    is($a->[1]{kind}, 'assume', 'second is assume');
    is($a->[1]{message}, 'x bounded', 'assume message round-trips');
};

subtest 'an optional message round-trips' => sub {
    my ($fsm, $module) = roundtrip_module(<<'ISF', 'guardm');
(actor guardm
  (interface (input start) (input a (width 8)) (input b (width 8)) (output done))
  (transaction main
    (on start)
    (assert (>= a b) "a must be at least b")
    (complete done)))
ISF
    like($fsm, qr/"a must be at least b"/, 'the message is emitted quoted in the +assert carrier');
    my $asserts = $module->{attributes}{immediate_assertions};
    is($asserts->[0]{message}, 'a must be at least b', 'the message round-trips onto the module');
    is($asserts->[0]{condition}->to_systemverilog(), 'a >= b', 'the condition still round-trips');
};

subtest 'multiple asserts in one transaction are all carried' => sub {
    my (undef, $module) = roundtrip_module(<<'ISF', 'multi');
(actor multi
  (interface (input start) (input x (width 8)) (output done))
  (transaction main
    (on start)
    (assert (< x 200))
    (assert (> x 0))
    (complete done)))
ISF
    my $asserts = $module->{attributes}{immediate_assertions};
    is(scalar(@$asserts), 2, 'both assertions carried');
    is($asserts->[0]{name}, 'main_assert_0', 'first named _0');
    is($asserts->[1]{name}, 'main_assert_1', 'second named _1');
};

subtest 'a malformed (assert ...) fails closed in the ISF lowerer' => sub {
    like(lower_error(
        "(actor t (interface (input start) (output done)) "
        . "(transaction main (on start) (assert) (complete done)))", 'noc'),
        qr/requires a condition expression/,
        '(assert) with no condition is rejected');

    like(lower_error(
        "(actor t (interface (input start) (input a (width 8)) (output done)) "
        . "(transaction main (on start) (assert (> a 0) \"msg\" extra) (complete done)))", 'extra'),
        qr/condition and an optional message string only/,
        '(assert COND msg extra) with extra operands is rejected');
};

done_testing();
