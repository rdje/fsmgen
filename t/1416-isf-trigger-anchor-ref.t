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

# ISF-TRIGGER-ANCHOR.5 (Ref): name a transaction position with `(point NAME)` and reference it
# from a check with `(at NAME)`, which resolves to `(state_active <that state>)`. Bindings are
# module-wide (an `(at NAME)` may reference a point in another transaction); an unknown name fails
# closed. (Activation labeling `(on SIGNAL as NAME)` — bare `as`, not `:as` — is the sibling form.)

my $tempdir = tempdir(CLEANUP => 1);

sub lower_fsm_text {
    my ($source, $name) = @_;
    return FSM::Scheduler::ISF->new()->lower(
        FSM::Adapter::ISF->new()->parse_source($source, "$name.isf"))->{files}{"$name.fsm"};
}

sub lower_error {
    my ($source, $name) = @_;
    my $ok = eval { lower_fsm_text($source, $name); 1 };
    return $ok ? '' : $@;
}

sub module_info_for {
    my ($source, $name) = @_;
    my $fsm = lower_fsm_text($source, $name);
    my $path = File::Spec->catfile($tempdir, "$name.fsm");
    open my $fh, '>', $path or die $!; print $fh $fsm; close $fh;
    my $mod = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
    my $intent = FSM::IR::IntentHIRBuilder->build_from_fsm_module(fsm_module => $mod);
    return FSM::Pipeline::GeneratedModuleInfoBuilder->build_from_fsm_module(
        fsm_module => $mod, intent_hir => $intent);
}

subtest '(point NAME) names a body position; (at NAME) resolves to that state_active' => sub {
    my $src = <<'ISF';
(actor pt
  (clock clk) (reset rst_n)
  (interface (input start) (input ack) (output done))
  (transaction main
    (on start)
    (point armed)
    (assert (=> (at armed) (within ack 3)) "armed implies ack within 3")
    (complete done)))
ISF
    my $fsm = lower_fsm_text($src, 'pt');
    like($fsm, qr/\(main_point_1\b/, '(point armed) lowers to a pass-through state main_point_1');
    like($fsm, qr/\Q(main_assert_0 assert (=> (state_active main_point_1) (within ack 3))\E/,
        '(at armed) resolves to (state_active main_point_1) in the +assert carrier');

    my $info = module_info_for($src, 'pt');
    is($info->{immediate_assertions}[0]{condition_sv},
        '(current_state == MAIN_POINT_1) |-> (##[1:3] (ack))',
        'renders to a clocked implication anchored on the point state');
};

subtest '(at NAME) resolves across transactions (module-wide bindings)' => sub {
    my $src = <<'ISF';
(actor x
  (clock clk) (reset rst_n)
  (interface (input s1) (input s2) (input ack) (output d1) (output d2))
  (transaction a (on s1) (point armed) (complete d1))
  (transaction b (on s2) (assert (=> (at armed) (within ack 2))) (complete d2)))
ISF
    my $fsm = lower_fsm_text($src, 'x');
    like($fsm, qr/\Q(b_assert_0 assert (=> (state_active a_point_1) (within ack 2))\E/,
        'a check in transaction b anchors to a point declared in transaction a');
};

subtest 'an unknown (at NAME) fails closed' => sub {
    like(lower_error(
        "(actor y (clock clk) (reset rst_n) (interface (input start) (input ack) (output done)) "
        . "(transaction main (on start) (assert (=> (at nope) (within ack 2))) (complete done)))", 'y'),
        qr/\(at nope\) references unknown point\/activation name 'nope'/,
        '(at nope) with no matching (point …)/(on … as …) is rejected');
};

subtest 'a duplicate point/activation name fails closed' => sub {
    like(lower_error(
        "(actor z (clock clk) (reset rst_n) (interface (input start) (input ack) (output done)) "
        . "(transaction main (on start) (point p) (point p) (complete done)))", 'z'),
        qr/duplicate point\/activation name 'p'/,
        'two (point p) declarations collide');
};

subtest 'a malformed (point …) fails closed' => sub {
    like(lower_error(
        "(actor w (clock clk) (reset rst_n) (interface (input start) (output done)) "
        . "(transaction main (on start) (point) (complete done)))", 'w'),
        qr/\(point NAME\) requires a scalar name/,
        '(point) with no name is rejected');
};

done_testing();
