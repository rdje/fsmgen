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
use FSM::IR::IntentHIRBuilder;
use FSM::Pipeline::GeneratedModuleInfoBuilder;

# ISF-PROPERTY-WINDOW-RANGE.2
#
# The bounded-window property gains an explicit lower bound:
#   (within X N)       -> ##[1:N] (X)      (unchanged)
#   (within X MIN MAX) -> ##[MIN:MAX] (X)  (new; literal 1 <= MIN <= MAX, the min>1 MTL window)
# A ## delay sequence stays formal-only. MIN=0, MIN>MAX, non-literal bounds, and the wrong
# arity all fail closed.

my $tempdir = tempdir(CLEANUP => 1);

sub parsed_module {
    my ($source, $name) = @_;
    my $fsm = FSM::Scheduler::ISF->new()->lower(
        FSM::Adapter::ISF->new()->parse_source($source, "$name.isf"))->{files}{"$name.fsm"};
    my $path = File::Spec->catfile($tempdir, "$name.fsm");
    open my $fh, '>', $path or die $!; print $fh $fsm; close $fh;
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
}

sub lower_error {
    my ($source, $name) = @_;
    my $ok = eval { parsed_module($source, $name); 1 };
    return $ok ? '' : $@;
}

sub module_info_for {
    my ($module) = @_;
    my $intent = FSM::IR::IntentHIRBuilder->build_from_fsm_module(fsm_module => $module);
    return FSM::Pipeline::GeneratedModuleInfoBuilder->build_from_fsm_module(
        fsm_module => $module, intent_hir => $intent);
}

subtest '(within X MIN MAX) renders ##[MIN:MAX]; (within X N) stays ##[1:N]' => sub {
    my $module = parsed_module(<<'ISF', 'win');
(actor win
  (interface (input start) (input ack) (output done))
  (transaction main
    (on start)
    (assert (within ack 2 5))
    (assert (within ack 3))
    (complete done)))
ISF
    my $info = module_info_for($module);
    my %by = map { $_->{name} => $_ } @{$info->{immediate_assertions}};
    is($by{main_assert_0}{condition_sv}, '##[2:5] (ack)', '(within ack 2 5) -> ##[2:5] (ack)');
    is($by{main_assert_1}{condition_sv}, '##[1:3] (ack)', '(within ack 3) -> ##[1:3] (ack) (unchanged)');
    ok($by{main_assert_0}{formal_only}, 'a ##[MIN:MAX] delay sequence is formal-only');
    ok($by{main_assert_1}{formal_only}, '##[1:N] is formal-only');
};

subtest '(within X MIN MAX) composes as an implication consequent' => sub {
    my $module = parsed_module(<<'ISF', 'winimp');
(actor winimp
  (interface (input start) (input req) (input ack) (output done))
  (transaction main
    (on start)
    (assert (=> req (within ack 2 5)) "ack 2..5 cycles after req")
    (complete done)))
ISF
    my $info = module_info_for($module);
    is($info->{immediate_assertions}[0]{condition_sv}, '(req) |-> (##[2:5] (ack))',
        '(=> req (within ack 2 5)) -> (req) |-> (##[2:5] (ack))');
    ok($info->{immediate_assertions}[0]{formal_only}, 'the delayed-window implication is formal-only');
};

subtest 'a malformed (within X MIN MAX) fails closed' => sub {
    my %bad = (
        'MIN = 0'           => '(within ack 0 5)',
        'MIN > MAX'         => '(within ack 5 2)',
    );
    for my $label (sort keys %bad) {
        like(lower_error(
            "(actor a (interface (input start) (input ack) (output done)) "
            . "(transaction main (on start) (assert $bad{$label}) (complete done)))", 'a'),
            qr/bounds must satisfy 1 <= MIN <= MAX/,
            "$label ($bad{$label}) is rejected");
    }

    like(lower_error(
        "(actor b (interface (input start) (input ack) (output done)) "
        . "(transaction main (on start) (assert (within ack two 5)) (complete done)))", 'b'),
        qr/bounds must be literal integers/,
        'a non-literal bound is rejected');

    like(lower_error(
        "(actor c (interface (input start) (input ack) (output done)) "
        . "(transaction main (on start) (assert (within ack 1 2 3)) (complete done)))", 'c'),
        qr/requires an operand and one or two literal bounds/,
        'a four-element (within X A B C) is rejected');
};

done_testing();
