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
    my $checker = FSM::Scheduler::ISF::ControlFlowEffects->new();
    return ($checker->check_actor($actor), $actor);
}

sub transaction_check {
    my ($check, $name) = @_;
    my ($tx) = grep { $_->{name} eq $name } @{$check->{transactions} || []};
    return $tx;
}

sub first_proof {
    my ($tx, $code) = @_;
    my ($proof) = grep { ($_->{code} // '') eq $code } @{$tx->{proofs} || []};
    return $proof;
}

sub first_violation {
    my ($tx, $code) = @_;
    my ($violation) = grep { ($_->{code} // '') eq $code } @{$tx->{violations} || []};
    return $violation;
}

subtest 'accepted multi-pending await_any plus await_all proves observe then drain' => sub {
    my ($check, $actor) = check_for(<<'ISF', 'check-observe-drain');
(actor check_observe_drain
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
        (await_any done)
        (await_all done)))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    ok($check->{ok}, 'checker accepts the drained multi-pending await_any shape');
    is($check->{violation_count}, 0, 'no invariant violations recorded');
    my $tx = transaction_check($check, 'parent');

    my $observe = first_proof($tx, 'await_any_observes_without_full_drain');
    ok($observe, 'await_any observe proof recorded');
    is_deeply($observe->{done_ports}, [qw(w0_done w1_done)], 'await_any observes both pending children');
    is_deeply($observe->{remaining_outstanding_after}, [qw(w0_done w1_done)],
        'multi-pending await_any leaves a set that requires later proof');

    my $drain = first_proof($tx, 'await_all_drains_outstanding_children');
    ok($drain, 'await_all drain proof recorded');
    is_deeply($drain->{done_ports}, [qw(w0_done w1_done)], 'await_all drains the same pending set');

    my $backedge = first_proof($tx, 'backedge_has_no_outstanding_children');
    ok($backedge, 'loop/repeat backedge proof recorded');

    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'existing lowering still accepts the drained shape') or diag($@);
};

subtest 'undrained repeat spawn is explained as missing outstanding-child lifetime proof' => sub {
    my ($check, $actor) = check_for(<<'ISF', 'check-undrained-spawn');
(actor check_undrained_spawn
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (spawn worker as w0)))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    ok(!$check->{ok}, 'checker rejects the undrained spawn shape');
    is($check->{violation_count}, 1, 'one invariant violation explains the missing proof');
    my $tx = transaction_check($check, 'parent');
    my $violation = first_violation($tx, 'outstanding_children_without_lifetime_proof');
    ok($violation, 'outstanding lifetime violation recorded');
    is($violation->{invariant}, 'child_lifetime', 'violation is attached to the child lifetime invariant');
    is($violation->{region_kind}, 'repeat', 'violation is located at the repeat region');
    is_deeply($violation->{outstanding_done_ports}, ['w0_done'], 'violation names the undrained child done port');

    my $ok = eval { FSM::Scheduler::ISF->new()->lower($actor); 1 };
    ok(!$ok, 'existing lowering remains fail-closed for the same shape');
    like($@, qr/loop-contained repeat-body spawn requires same-body '\(await_all done\)' or single-pending '\(await_any done\)'/,
        'existing validator diagnostic still owns public behavior');
};

subtest 'generated do proves static instance identity and blocking done drain' => sub {
    my ($check, $actor) = check_for(<<'ISF', 'check-generated-do');
(actor check_generated_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input cond)
    (input din (width 8))
    (output done)
    (output result (width 8)))
  (transaction parent
    (on start)
    (when cond
      (do worker
        (params (W 8))
        (bind (input data din) (output data_out result))))
    (complete done))
  (transaction worker
    (params (W 8))
    (on start)
    (ports (input data (width W)) (output data_out (width W)))
    (update data_out data)
    (complete done)))
ISF

    ok($check->{ok}, 'checker accepts generated conditional do with static instance identity');
    my $tx = transaction_check($check, 'parent');
    my $instance = first_proof($tx, 'generated_child_instance_is_static');
    ok($instance, 'static generated-instance proof recorded');
    is($instance->{instance}, 'parent_worker_cond_do_0', 'proof names the deterministic instance');

    my $drain = first_proof($tx, 'blocking_do_drains_child_done');
    ok($drain, 'blocking do drain proof recorded');
    is($drain->{done_signal}, 'parent_worker_cond_do_0_done', 'proof names the generated done handoff');

    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'existing lowering still accepts generated conditional do') or diag($@);
};

done_testing();
