#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-LOOP-CONTINUE.2
#
# `(continue-when cond)` is the loop "continue" primitive (companion to
# `(exit-when cond)`). Directly inside a `while`/`until` body, when `cond` holds it
# skips the rest of the iteration and jumps to the loop's tail condition check (which
# re-evaluates and either loops again or exits); otherwise control falls through to
# the next body clause. It fails closed outside a `while`/`until` body.

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
}

sub lower_error {
    my ($source, $label) = @_;
    my $ok = eval { FSM::Scheduler::ISF->new()->lower(parse_source($source, $label)); 1 };
    return $ok ? '' : $@;
}

subtest '(continue-when cond) in a while body jumps to the loop check on true, continues on false' => sub {
    my $actor = parse_source(<<'ISF', 'while-continue');
(actor lc
  (interface (input start) (input busy) (input skip) (input din (width 8)) (output done) (output result (width 8)))
  (transaction main
    (on start)
    (while busy
      (update result din)
      (continue-when skip)
      (update result din))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a while-body (continue-when) lowers') or diag($@);
    my $fsm = $lowered->{files}{'lc.fsm'};
    # the while back-check (the loop tail check) is what continue jumps to
    my ($tail) = $fsm =~ /(main_while_check_\d+)/;
    ok(defined($tail), 'the while back-check exists');
    like($fsm, qr/main_continue_when_\d+\s*\(\s*\?skip/s, 'continue-when lowers to a ?cond decision state');
    like($fsm, qr/main_continue_when_\d+\s*\(\s*\?skip[\s\S]*?\(=1 \(-> \Q$tail\E\)\)/s,
        'continue-when true edge jumps to the loop tail check (re-evaluate the condition)');
    like($fsm, qr/main_continue_when_\d+\s*\(\s*\?skip[\s\S]*?\(=0 \(-> main_update_\d+\)\)/s,
        'continue-when false edge continues to the next body clause');
};

subtest '(continue-when cond) lowers in an until body too' => sub {
    my $actor = parse_source(<<'ISF', 'until-continue');
(actor lcu
  (interface (input start) (input done_seen) (input skip) (input din (width 8)) (output done) (output result (width 8)))
  (transaction main
    (on start)
    (until done_seen
      (update result din)
      (continue-when skip))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'an until-body (continue-when) lowers') or diag($@);
    my $fsm = $lowered->{files}{'lcu.fsm'};
    like($fsm, qr/main_continue_when_\d+\s*\(\s*\?skip[\s\S]*?-> main_until_check_\d+/s,
        'continue-when in an until body jumps to the until check');
};

subtest '(continue-when) inside a when nested in a loop jumps to the loop check' => sub {
    # ISF-LOOP-CONTINUE.3: a `(continue-when)` may live in a `when` body that is itself
    # inside a `while`/`until` loop; its true edge still jumps to the loop's tail check.
    my $actor = parse_source(<<'ISF', 'when-in-loop-continue');
(actor cwl
  (interface (input start) (input busy) (input err) (input skip) (input din (width 8)) (output done) (output result (width 8)))
  (transaction main
    (on start)
    (while busy
      (when err
        (continue-when skip))
      (update result din))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a when-nested (continue-when) inside a loop lowers') or diag($@);
    my $fsm = $lowered->{files}{'cwl.fsm'};
    my ($tail) = $fsm =~ /(main_while_check_\d+)/;
    like($fsm, qr/main_continue_when_\d+\s*\(\s*\?skip[\s\S]*?\(=1 \(-> \Q$tail\E\)\)/s,
        'the when-nested continue-when true edge jumps to the loop tail check');
};

subtest '(continue-when) fails closed outside a while/until body' => sub {
    my %context = (
        'transaction body' => '(continue-when skip)',
        'repeat body'      => '(repeat 2 (continue-when skip))',
    );
    for my $label (sort keys %context) {
        my $err = lower_error(
            "(actor t (interface (input start) (input skip) (output done)) "
            . "(transaction main (on start) $context{$label} (complete done)))",
            "bad-$label");
        like($err, qr/unsupported '\(continue-when \.\.\.\)' clause in \Q$label\E/,
            "(continue-when) in a $label is rejected");
    }

    # A `(continue-when)` in a `when` that is NOT inside a loop fails closed with the
    # loop-aware safety diagnostic, naming continue-when (not exit-when).
    my $err = lower_error(
        "(actor t (interface (input start) (input err) (input skip) (output done)) "
        . "(transaction main (on start) (when err (continue-when skip)) (complete done)))",
        'non-loop-when');
    like($err, qr/'\(continue-when \.\.\.\)' is only valid inside a 'while'\/'until' loop body/,
        'a (continue-when) in a non-loop when fails closed naming continue-when');
};

done_testing();
