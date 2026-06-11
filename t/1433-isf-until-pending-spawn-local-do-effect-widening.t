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

subtest 'until-contained pending spawn across local do lowers through effect proofs' => sub {
    my $actor = parse_actor(actor_for_body('until_pending_spawn_local_do', <<'ISF'), 'until-pending-spawn-local-do');
(until cond
  (repeat loops
    (spawn worker as w0)
    (do helper)
    (await_all done)))
ISF

    my $check = check_actor($actor);
    ok($check->{ok}, 'effect checker accepts the selected until pending-spawn local-do shape');
    my $tx = transaction_check($check, 'parent');
    my $backedges = proofs($tx, 'backedge_has_no_outstanding_children');
    ok((grep { ($_->{region_kind} // '') eq 'until' && ($_->{backedge} // '') eq 'until_retest' } @$backedges),
        'until backedge has no outstanding child');
    ok((grep { ($_->{region_kind} // '') eq 'repeat' && ($_->{backedge} // '') eq 'repeat_check_nonzero' } @$backedges),
        'repeat backedge has no outstanding child');
    ok((grep { ($_->{instance} // '') eq 'w0' } @{proofs($tx, 'generated_child_instance_is_static')}),
        'spawned child instance identity is static');
    ok((grep { ($_->{child} // '') eq 'helper' } @{proofs($tx, 'blocking_do_drains_child_done')}),
        'local blocking do drains its own child');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done' } @{proofs($tx, 'await_all_drains_outstanding_children')}),
        'await_all drains the pending spawned child');

    my ($lowered, $err) = lower_actor($actor);
    ok($lowered, 'public lowering accepts the effect-proven until sequence') or diag($err);
    my $fsm = $lowered->{files}{'until_pending_spawn_local_do.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'spawn starts w0 before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_all_\d+/s,
        'local do waits for helper_done before await_all');
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<w0_done/s,
        'await_all drains w0_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_until_check_\d+\)\)/s,
        'repeat re-entry returns to the spawn only after the drain');
    like($fsm, qr/\(parent_until_check_\d+\b.*?\(=1\s*\(->\s*parent_done_\d+\)\).*?\(=0\s*\(->\s*parent_repeat_init_\d+\)\)/s,
        'until check exits when true and otherwise re-enters the repeat');
    like($lowered->{files}{'until_pending_spawn_local_do_top.fsm'}, qr/\(\?fsmc:w0 worker\b/s,
        'generated top still instantiates the spawned child');
};

subtest 'missing final drain remains fail-closed before public widening' => sub {
    my $actor = parse_actor(actor_for_body('until_pending_spawn_local_do_undrained', <<'ISF'), 'until-pending-spawn-local-do-undrained');
(until cond
  (repeat loops
    (spawn worker as w0)
    (do helper)))
ISF

    my ($lowered, $err) = lower_actor($actor);
    ok(!$lowered, 'missing await_all drain is still rejected');
    like($err, qr/repeat-body do cannot appear while repeat-body spawn clauses are pending/,
        'missing drain keeps the pending-spawn do gate because no await_all proof exists');
};

subtest 'await_any after the local do remains outside the await_all contract' => sub {
    my $actor = parse_actor(actor_for_body('until_pending_spawn_local_do_await_any', <<'ISF'), 'until-pending-spawn-local-do-await-any');
(until cond
  (repeat loops
    (spawn worker as w0)
    (do helper)
    (await_any done)))
ISF

    my ($lowered, $err) = lower_actor($actor);
    ok(!$lowered, 'post-do await_any remains rejected for this slice');
    like($err, qr/repeat-body do cannot appear while repeat-body spawn clauses are pending/,
        'await_any path keeps the pending-spawn do gate because no await_all proof exists');
};

subtest 'until-contained multi-pending spawn across local do lowers through effect proofs' => sub {
    my $actor = parse_actor(actor_for_body('until_multi_pending_spawn_local_do', <<'ISF'), 'until-multi-pending-spawn-local-do');
(until cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (do helper)
    (await_all done)))
ISF

    my ($lowered, $err) = lower_actor($actor);
    my $check = check_actor($actor);
    ok($check->{ok}, 'effect checker accepts the selected until multi-pending local-do shape');
    my $tx = transaction_check($check, 'parent');
    my $backedges = proofs($tx, 'backedge_has_no_outstanding_children');
    ok((grep { ($_->{region_kind} // '') eq 'until' && ($_->{backedge} // '') eq 'until_retest' } @$backedges),
        'until backedge has no outstanding child for the multi-pending shape');
    ok((grep { ($_->{region_kind} // '') eq 'repeat' && ($_->{backedge} // '') eq 'repeat_check_nonzero' } @$backedges),
        'repeat backedge has no outstanding child for the multi-pending shape');
    ok((grep { ($_->{instance} // '') eq 'w0' } @{proofs($tx, 'generated_child_instance_is_static')}),
        'first spawned child instance identity is static');
    ok((grep { ($_->{instance} // '') eq 'w1' } @{proofs($tx, 'generated_child_instance_is_static')}),
        'second spawned child instance identity is static');
    ok((grep { ($_->{instance} // '') eq 'w0' && ($_->{done_signal} // '') eq 'w0_done' } @{proofs($tx, 'generated_top_start_done_handoff_required')}),
        'first spawned child generated-top handoff is explicit');
    ok((grep { ($_->{instance} // '') eq 'w1' && ($_->{done_signal} // '') eq 'w1_done' } @{proofs($tx, 'generated_top_start_done_handoff_required')}),
        'second spawned child generated-top handoff is explicit');
    ok((grep { ($_->{child} // '') eq 'helper' } @{proofs($tx, 'blocking_do_drains_child_done')}),
        'local blocking do drains helper before the await_all');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done' } @{proofs($tx, 'await_all_drains_outstanding_children')}),
        'await_all drains both pending spawned children');

    ok($lowered, 'public lowering accepts the selected until multi-pending local-do sequence') or diag($err);
    my $fsm = $lowered->{files}{'until_multi_pending_spawn_local_do.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w1_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'both spawned children start before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_all_\d+/s,
        'local do waits for helper_done before draining spawned children');
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<\(&\s*w0_done\s*w1_done\)/s,
        'await_all drains w0_done and w1_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_until_check_\d+\)\)/s,
        'repeat re-entry returns to the first spawn only after the multi-pending drain');
    like($fsm, qr/\(parent_until_check_\d+\b.*?\(=1\s*\(->\s*parent_done_\d+\)\).*?\(=0\s*\(->\s*parent_repeat_init_\d+\)\)/s,
        'until check exits when true and otherwise re-enters the repeat');
    my $top = $lowered->{files}{'until_multi_pending_spawn_local_do_top.fsm'};
    like($top, qr/\(\?fsmc:w0 worker\b/s, 'generated top instantiates w0');
    like($top, qr/\(\?fsmc:w1 worker\b/s, 'generated top instantiates w1');
};

subtest 'multi-pending missing final drain remains fail-closed' => sub {
    my $actor = parse_actor(actor_for_body('until_multi_pending_spawn_local_do_undrained', <<'ISF'), 'until-multi-pending-spawn-local-do-undrained');
(until cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (do helper)))
ISF

    my ($lowered, $err) = lower_actor($actor);
    ok(!$lowered, 'missing multi-pending await_all drain is still rejected');
    like($err, qr/repeat-body do cannot appear while repeat-body spawn clauses are pending/,
        'missing multi-pending drain has no effect proof for the pending-spawn do gate');
};

done_testing();
