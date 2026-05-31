#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-LOOP-EARLY-EXIT.2
#
# `(exit-when cond)` is a mid-loop early exit: directly inside a `while`/`until`
# body it lowers to a decision state whose TRUE edge leaves the loop (the loop's
# computed exit target) and whose FALSE edge continues to the next body clause.
# It fails closed outside a `while`/`until` body.

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
}

subtest '(exit-when cond) inside a while body exits the loop on true and continues on false' => sub {
    my $actor = parse_source(<<'ISF', 'while-exit-when');
(actor loop_exit
  (interface
    (input start)
    (input busy)
    (input go)
    (input din (width 8))
    (output done)
    (output result (width 8)))
  (transaction main
    (on start)
    (while busy
      (update result din)
      (exit-when go)
      (update result din))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a while-body (exit-when) lowers') or diag($@);
    my $fsm = $lowered->{files}{'loop_exit.fsm'};
    ok(defined($fsm), 'scheduled .fsm emitted');

    # The exit-when decision tests its condition: true -> the loop exit (the same
    # state the while decision exits to), false -> the next body clause.
    my ($exit_target) = $fsm =~ /main_while_entry_\d+\s*\(\s*\?busy[\s\S]*?\(=0 \(-> (main_\w+)\)\)/;
    ok(defined($exit_target), 'the while decision has a loop-exit target') or diag($fsm);
    like($fsm, qr/main_exit_when_\d+\s*\(\s*\?go/s, 'the exit-when lowers to a ?cond decision state');
    like($fsm, qr/main_exit_when_\d+\s*\(\s*\?go[\s\S]*?\(=1 \(-> \Q$exit_target\E\)\)/s,
        'exit-when true edge jumps to the loop exit target');
    like($fsm, qr/main_exit_when_\d+\s*\(\s*\?go[\s\S]*?\(=0 \(-> main_update_\d+\)\)/s,
        'exit-when false edge continues to the next body clause');
};

subtest '(exit-when cond) inside an until body lowers' => sub {
    my $actor = parse_source(<<'ISF', 'until-exit-when');
(actor loop_exit_until
  (interface
    (input start)
    (input done_seen)
    (input go)
    (input din (width 8))
    (output done)
    (output result (width 8)))
  (transaction main
    (on start)
    (until done_seen
      (update result din)
      (exit-when go))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'an until-body (exit-when) lowers') or diag($@);
    my $fsm = $lowered->{files}{'loop_exit_until.fsm'};
    like($fsm, qr/main_exit_when_\d+\s*\(\s*\?go/s, 'the exit-when lowers to a ?cond decision state in an until body');
};

subtest '(exit-when) lowers to synthesizable HDL evidence (decision selectors are exclusive)' => sub {
    # The lowered schedule must keep the exit-when decision and the loop decisions
    # mutually exclusive (one-hot next-state selection). Assert the schedule shape
    # that the HDL backend relies on: the exit-when has exactly one true and one
    # false edge.
    my $actor = parse_source(<<'ISF', 'while-exit-min');
(actor loop_exit_min
  (interface (input start) (input busy) (input go) (output done))
  (transaction main
    (on start)
    (while busy
      (exit-when go))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a minimal while (exit-when) lowers') or diag($@);
    my $fsm = $lowered->{files}{'loop_exit_min.fsm'};
    my ($decision) = $fsm =~ /(main_exit_when_\d+\s*\(\s*\?go[\s\S]*?\n  \))/;
    ok(defined($decision), 'the exit-when decision block is present');
    my $true_edges  = () = ($decision // '') =~ /\(=1 \(->/g;
    my $false_edges = () = ($decision // '') =~ /\(=0 \(->/g;
    is($true_edges, 1, 'exactly one exit-when true edge');
    is($false_edges, 1, 'exactly one exit-when false edge');
};

subtest '(exit-when) fails closed outside a while/until body' => sub {
    my %context = (
        'transaction body' => '(exit-when go)',
        'repeat body'      => '(repeat 2 (exit-when go))',
        'when body'        => '(when busy (exit-when go))',
    );
    for my $label (sort keys %context) {
        my $actor = parse_source(<<"ISF", "exit-when-$label");
(actor bad_exit_when
  (interface (input start) (input busy) (input go) (output done))
  (transaction main
    (on start)
    $context{$label}
    (complete done)))
ISF
        my $ok = eval { FSM::Scheduler::ISF->new()->lower($actor); 1 };
        my $err = $@;
        ok(!$ok, "(exit-when) in a $label is rejected");
        like(
            $err,
            qr/unsupported '\(exit-when \.\.\.\)' clause in \Q$label\E/,
            "the diagnostic names the unsupported $label context",
        );
    }
};

subtest 'a malformed (exit-when) without a condition fails closed' => sub {
    my $actor = parse_source(<<'ISF', 'exit-when-bare');
(actor bare_exit_when
  (interface (input start) (input busy) (output done))
  (transaction main
    (on start)
    (while busy
      (exit-when))
    (complete done)))
ISF
    my $ok = eval { FSM::Scheduler::ISF->new()->lower($actor); 1 };
    my $err = $@;
    ok(!$ok, 'a (exit-when) with no condition is rejected');
    like($err, qr/'\(exit-when \.\.\.\)' requires exactly one condition expression/,
        'the diagnostic names the missing condition');
};

done_testing();
