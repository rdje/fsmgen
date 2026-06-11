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

sub lower_actor {
    my ($actor) = @_;
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    return ($lowered, $@);
}

sub check_actor {
    my ($actor) = @_;
    return FSM::Scheduler::ISF::ControlFlowEffects->new()->check_actor($actor);
}

sub transaction_check {
    my ($check, $name) = @_;
    my ($tx) = grep { $_->{name} eq $name } @{$check->{transactions} || []};
    return $tx;
}

sub proofs {
    my ($tx, $code) = @_;
    return [grep { ($_->{code} // '') eq $code } @{$tx->{proofs} || []}];
}

sub actor_for_body {
    my ($name, $body) = @_;
    return << "ISF";
(actor $name
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input cond)
    (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    $body
    (complete done))
  (transaction worker
    (complete done))
  (transaction helper
    (complete done)))
ISF
}

subtest 'while-contained pending spawn across local do may sync with single-pending await_any' => sub {
    my $actor = parse_actor(actor_for_body('while_pending_spawn_local_do_await_any', <<'ISF'), 'while-pending-spawn-local-do-await-any');
(while cond
  (repeat loops
    (spawn worker as w0)
    (do helper)
    (await_any done)))
ISF

    my $check = check_actor($actor);
    ok($check->{ok}, 'effect checker accepts the selected single-pending await_any shape');
    my $tx = transaction_check($check, 'parent');
    my $backedges = proofs($tx, 'backedge_has_no_outstanding_children');
    ok((grep { ($_->{region_kind} // '') eq 'while' && ($_->{backedge} // '') eq 'while_retest' } @$backedges),
        'while backedge has no outstanding child');
    ok((grep { ($_->{region_kind} // '') eq 'repeat' && ($_->{backedge} // '') eq 'repeat_check_nonzero' } @$backedges),
        'repeat backedge has no outstanding child');
    ok((grep { ($_->{instance} // '') eq 'w0' } @{proofs($tx, 'generated_child_instance_is_static')}),
        'spawned child instance identity is static');
    ok((grep { ($_->{child} // '') eq 'helper' } @{proofs($tx, 'blocking_do_drains_child_done')}),
        'local blocking do drains its own child');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done' } @{proofs($tx, 'await_any_single_pending_completes_outstanding_set')}),
        'single-pending await_any completes the outstanding spawn set');

    my ($lowered, $err) = lower_actor($actor);
    ok($lowered, 'public lowering accepts the effect-proven await_any sequence') or diag($err);
    my $fsm = $lowered->{files}{'while_pending_spawn_local_do_await_any.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'spawn starts w0 before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_any_\d+/s,
        'local do waits for helper_done before await_any');
    like($fsm, qr/\(parent_await_any_\d+\b.*?<w0_done\s*\(->\s*parent_repeat_check_\d+\)/s,
        'await_any observes w0_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_while_check_\d+\)\)/s,
        'repeat re-entry returns to the spawn only after the single-pending await_any');
    like($lowered->{files}{'while_pending_spawn_local_do_await_any_top.fsm'}, qr/\(\?fsmc:w0 worker\b/s,
        'generated top still instantiates the spawned child');
};

subtest 'until-contained pending spawn across local do may sync with single-pending await_any' => sub {
    my $actor = parse_actor(actor_for_body('until_pending_spawn_local_do_await_any', <<'ISF'), 'until-pending-spawn-local-do-await-any');
(until cond
  (repeat loops
    (spawn worker as w0)
    (do helper)
    (await_any done)))
ISF

    my $check = check_actor($actor);
    ok($check->{ok}, 'effect checker accepts the selected until single-pending await_any shape');
    my $tx = transaction_check($check, 'parent');
    my $backedges = proofs($tx, 'backedge_has_no_outstanding_children');
    ok((grep { ($_->{region_kind} // '') eq 'until' && ($_->{backedge} // '') eq 'until_retest' } @$backedges),
        'until backedge has no outstanding child');
    ok((grep { ($_->{region_kind} // '') eq 'repeat' && ($_->{backedge} // '') eq 'repeat_check_nonzero' } @$backedges),
        'repeat backedge has no outstanding child');
    ok((grep { ($_->{instance} // '') eq 'w0' } @{proofs($tx, 'generated_child_instance_is_static')}),
        'spawned child instance identity is static');
    ok((grep { ($_->{instance} // '') eq 'w0' && ($_->{done_signal} // '') eq 'w0_done' } @{proofs($tx, 'generated_top_start_done_handoff_required')}),
        'spawned child generated-top handoff is explicit');
    ok((grep { ($_->{child} // '') eq 'helper' } @{proofs($tx, 'blocking_do_drains_child_done')}),
        'local blocking do drains its own child');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done' } @{proofs($tx, 'await_any_single_pending_completes_outstanding_set')}),
        'single-pending await_any completes the outstanding spawn set');

    my ($lowered, $err) = lower_actor($actor);
    ok($lowered, 'public lowering accepts the effect-proven until await_any sequence') or diag($err);
    my $fsm = $lowered->{files}{'until_pending_spawn_local_do_await_any.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'spawn starts w0 before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_any_\d+/s,
        'local do waits for helper_done before await_any');
    like($fsm, qr/\(parent_await_any_\d+\b.*?<w0_done\s*\(->\s*parent_repeat_check_\d+\)/s,
        'await_any observes w0_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_until_check_\d+\)\)/s,
        'repeat re-entry returns to the spawn only after the single-pending await_any');
    like($fsm, qr/\(parent_until_check_\d+\b.*?\(=1\s*\(->\s*parent_done_\d+\)\).*?\(=0\s*\(->\s*parent_repeat_init_\d+\)\)/s,
        'until check exits when true and otherwise re-enters the repeat');
    like($lowered->{files}{'until_pending_spawn_local_do_await_any_top.fsm'}, qr/\(\?fsmc:w0 worker\b/s,
        'generated top still instantiates the spawned child');
};

subtest 'multi-pending await_any after local do remains rejected' => sub {
    my $actor = parse_actor(actor_for_body('while_multi_pending_spawn_local_do_await_any', <<'ISF'), 'while-multi-pending-spawn-local-do-await-any');
(while cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (do helper)
    (await_any done)
    (await_all done)))
ISF

    my ($lowered, $err) = lower_actor($actor);
    ok(!$lowered, 'multi-pending await_any after local do remains rejected');
    like($err, qr/loop-contained repeat-body local do while generated spawns are pending requires same-body '\(await_all done\)' drain; '\(await_any done\)' after the do remains deferred/,
        'multi-pending variant keeps the post-do await_any gate');
};

subtest 'missing final sync remains fail-closed' => sub {
    my $actor = parse_actor(actor_for_body('while_pending_spawn_local_do_no_sync', <<'ISF'), 'while-pending-spawn-local-do-no-sync');
(while cond
  (repeat loops
    (spawn worker as w0)
    (do helper)))
ISF

    my ($lowered, $err) = lower_actor($actor);
    ok(!$lowered, 'missing final sync is still rejected');
    like($err, qr/repeat-body do cannot appear while repeat-body spawn clauses are pending/,
        'missing sync has no await_all or single-pending await_any proof');
};

done_testing();
