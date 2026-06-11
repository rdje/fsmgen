#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::ControlFlowEffects;

sub parse_actor {
    my ($source, $name) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, "$name.isf");
}

sub check_for {
    my ($source, $name) = @_;
    my $actor = parse_actor($source, $name);
    my $check = FSM::Scheduler::ISF::ControlFlowEffects->new()->check_actor($actor);
    return ($check, $actor);
}

sub transaction_check {
    my ($check, $name) = @_;
    my ($tx) = grep { $_->{name} eq $name } @{$check->{transactions} || []};
    return $tx;
}

sub proof {
    my ($tx, $code) = @_;
    my ($proof) = grep { ($_->{code} // '') eq $code } @{$tx->{proofs} || []};
    return $proof;
}

sub violation {
    my ($tx, $code) = @_;
    my ($violation) = grep { ($_->{code} // '') eq $code } @{$tx->{violations} || []};
    return $violation;
}

subtest 'single-pending await_any completes the outstanding set before repeat re-entry' => sub {
    my ($check, $actor) = check_for(<<'ISF', 'single-pending-await-any');
(actor single_pending_await_any
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (spawn worker as w0)
        (await_any done)))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    ok($check->{ok}, 'single-pending await_any satisfies the shadow lifetime checker');
    my $tx = transaction_check($check, 'parent');
    my $single = proof($tx, 'await_any_single_pending_completes_outstanding_set');
    ok($single, 'single-pending await_any proof recorded');
    is_deeply($single->{done_ports}, ['w0_done'], 'proof names the only outstanding child');
    ok(proof($tx, 'backedge_has_no_outstanding_children'), 'repeat/loop backedge has no live child after the observation');

    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'existing lowering accepts single-pending await_any in the repeat body') or diag($@);
};

subtest 'multi-pending await_any without later await_all fails the backedge lifetime check' => sub {
    my ($check, $actor) = check_for(<<'ISF', 'multi-pending-await-any-undrained');
(actor multi_pending_await_any_undrained
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (spawn worker as w0)
        (spawn worker as w1)
        (await_any done)))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    ok(!$check->{ok}, 'multi-pending await_any without a later drain fails shadow lifetime checks');
    my $tx = transaction_check($check, 'parent');
    my $observe = proof($tx, 'await_any_multi_pending_requires_later_drain');
    ok($observe, 'multi-pending await_any records a later-drain obligation');
    is_deeply($observe->{remaining_outstanding_after}, [qw(w0_done w1_done)],
        'later-drain obligation keeps the full outstanding set');

    my $backedge = violation($tx, 'backedge_has_live_outstanding_children');
    ok($backedge, 'repeat backedge violation recorded');
    is($backedge->{region_kind}, 'repeat', 'violation is on the repeat region');
    is_deeply($backedge->{outstanding_done_ports}, [qw(w0_done w1_done)],
        'backedge violation names the live child completions');

    my $ok = eval { FSM::Scheduler::ISF->new()->lower($actor); 1 };
    ok(!$ok, 'existing lowering remains fail-closed for undrained multi-pending await_any');
    like($@, qr/loop-contained repeat-body multi-pending await_any requires later same-body '\(await_all done\)' before the repeat check can loop/,
        'public behavior reports the missing later drain proof');
};

subtest 'loop-body undrained spawn is a loop-backedge lifetime violation in shadow checks' => sub {
    my ($check) = check_for(<<'ISF', 'while-body-undrained-spawn');
(actor while_body_undrained_spawn
  (clock clk)
  (reset rst_n)
  (interface (input start) (input cond) (output done))
  (transaction parent
    (on start)
    (while cond
      (spawn worker as w0))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    ok(!$check->{ok}, 'loop-body undrained spawn fails shadow lifetime checks');
    my $tx = transaction_check($check, 'parent');
    my $backedge = violation($tx, 'backedge_has_live_outstanding_children');
    ok($backedge, 'loop backedge violation recorded');
    is($backedge->{region_kind}, 'while', 'violation is located at the while region');
    is($backedge->{backedge}, 'while_retest', 'violation names the while re-test backedge');
    is_deeply($backedge->{outstanding_done_ports}, ['w0_done'], 'violation names the live child');
};

subtest 'branch-body undrained spawn is a region-exit lifetime violation in shadow checks' => sub {
    my ($check) = check_for(<<'ISF', 'when-body-undrained-spawn');
(actor when_body_undrained_spawn
  (clock clk)
  (reset rst_n)
  (interface (input start) (input cond) (output done))
  (transaction parent
    (on start)
    (when cond
      (spawn worker as w0))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    ok(!$check->{ok}, 'branch-body undrained spawn fails shadow lifetime checks');
    my $tx = transaction_check($check, 'parent');
    my $exit = violation($tx, 'region_exit_has_live_outstanding_children');
    ok($exit, 'region-exit lifetime violation recorded');
    is($exit->{region_kind}, 'when', 'violation is located at the when region');
    is_deeply($exit->{outstanding_done_ports}, ['w0_done'], 'violation names the live child');
};

done_testing();
