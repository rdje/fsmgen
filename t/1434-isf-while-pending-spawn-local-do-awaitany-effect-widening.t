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

subtest 'while-contained multi-pending await_any after local do drains through later await_all' => sub {
    my $actor = parse_actor(actor_for_body('while_multi_pending_spawn_local_do_await_any', <<'ISF'), 'while-multi-pending-spawn-local-do-await-any');
(while cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (do helper)
    (await_any done)
    (await_all done)))
ISF

    my $check = check_actor($actor);
    ok($check->{ok}, 'effect checker accepts the selected post-do multi-pending await_any shape');
    my $tx = transaction_check($check, 'parent');
    my $backedges = proofs($tx, 'backedge_has_no_outstanding_children');
    ok((grep { ($_->{region_kind} // '') eq 'while' && ($_->{backedge} // '') eq 'while_retest' } @$backedges),
        'while backedge has no outstanding child for the post-do await_any shape');
    ok((grep { ($_->{region_kind} // '') eq 'repeat' && ($_->{backedge} // '') eq 'repeat_check_nonzero' } @$backedges),
        'repeat backedge has no outstanding child for the post-do await_any shape');
    for my $index (0 .. 1) {
        my $inst = "w$index";
        my $done = "${inst}_done";
        ok((grep { ($_->{instance} // '') eq $inst } @{proofs($tx, 'generated_child_instance_is_static')}),
            "$inst spawned child instance identity is static");
        ok((grep { ($_->{instance} // '') eq $inst && ($_->{done_signal} // '') eq $done } @{proofs($tx, 'generated_top_start_done_handoff_required')}),
            "$inst generated-top handoff is explicit");
    }
    ok((grep { ($_->{child} // '') eq 'helper' } @{proofs($tx, 'blocking_do_drains_child_done')}),
        'local blocking do drains helper before the multi-pending await_any');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done' } @{proofs($tx, 'await_any_observes_without_full_drain')}),
        'post-do await_any observes both pending spawned children without full drain');
    ok(@{proofs($tx, 'await_any_multi_pending_requires_later_drain')},
        'multi-pending await_any records a later-drain obligation');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done' } @{proofs($tx, 'await_all_drains_outstanding_children')}),
        'later await_all drains both pending spawned children');

    my ($lowered, $err) = lower_actor($actor);
    ok($lowered, 'public lowering accepts the selected post-do multi-pending await_any sequence') or diag($err);
    my $fsm = $lowered->{files}{'while_multi_pending_spawn_local_do_await_any.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w1_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'both spawned children start before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_any_\d+/s,
        'local do waits for helper_done before the multi-pending await_any');
    like($fsm, qr/\(parent_await_any_\d+\b.*?<w0_done\s*\(->\s*parent_await_all_\d+\).*?<w1_done\s*\(->\s*parent_await_all_\d+\)/s,
        'await_any observes either spawned done pulse before the await_all drain');
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<\(&\s*w0_done\s*w1_done\)/s,
        'later await_all drains w0_done and w1_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_while_check_\d+\)\)/s,
        'repeat re-entry returns to the first spawn only after the later await_all drain');
    my $top = $lowered->{files}{'while_multi_pending_spawn_local_do_await_any_top.fsm'};
    like($top, qr/\(\?fsmc:w0 worker\b/s, 'generated top instantiates w0');
    like($top, qr/\(\?fsmc:w1 worker\b/s, 'generated top instantiates w1');
};

subtest 'while-contained three-spawn multi-pending await_any after local do drains through later await_all' => sub {
    my $actor = parse_actor(actor_for_body('while_wider_multi_pending_spawn_local_do_await_any', <<'ISF'), 'while-wider-multi-pending-spawn-local-do-await-any');
(while cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (spawn worker as w2)
    (do helper)
    (await_any done)
    (await_all done)))
ISF

    my $check = check_actor($actor);
    ok($check->{ok}, 'effect checker accepts the selected wider while post-do multi-pending await_any shape');
    my $tx = transaction_check($check, 'parent');
    my $backedges = proofs($tx, 'backedge_has_no_outstanding_children');
    ok((grep { ($_->{region_kind} // '') eq 'while' && ($_->{backedge} // '') eq 'while_retest' } @$backedges),
        'while backedge has no outstanding child for the three-spawn post-do await_any shape');
    ok((grep { ($_->{region_kind} // '') eq 'repeat' && ($_->{backedge} // '') eq 'repeat_check_nonzero' } @$backedges),
        'repeat backedge has no outstanding child for the three-spawn post-do await_any shape');
    for my $index (0 .. 2) {
        my $inst = "w$index";
        my $done = "${inst}_done";
        ok((grep { ($_->{instance} // '') eq $inst } @{proofs($tx, 'generated_child_instance_is_static')}),
            "$inst three-spawn child instance identity is static");
        ok((grep { ($_->{instance} // '') eq $inst && ($_->{done_signal} // '') eq $done } @{proofs($tx, 'generated_top_start_done_handoff_required')}),
            "$inst three-spawn generated-top handoff is explicit");
    }
    ok((grep { ($_->{child} // '') eq 'helper' } @{proofs($tx, 'blocking_do_drains_child_done')}),
        'local blocking do drains helper before the three-spawn multi-pending await_any');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done,w2_done' } @{proofs($tx, 'await_any_observes_without_full_drain')}),
        'post-do await_any observes all three pending spawned children without full drain');
    ok(@{proofs($tx, 'await_any_multi_pending_requires_later_drain')},
        'three-spawn multi-pending await_any records a later-drain obligation');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done,w2_done' } @{proofs($tx, 'await_all_drains_outstanding_children')}),
        'later await_all drains all three pending spawned children');

    my ($lowered, $err) = lower_actor($actor);
    ok($lowered, 'public lowering accepts the selected three-spawn post-do multi-pending await_any sequence') or diag($err);
    my $fsm = $lowered->{files}{'while_wider_multi_pending_spawn_local_do_await_any.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w1_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w2_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'three spawned children start before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_any_\d+/s,
        'local do waits for helper_done before the three-spawn multi-pending await_any');
    like($fsm, qr/\(parent_await_any_\d+\b.*?<w0_done\s*\(->\s*parent_await_all_\d+\).*?<w1_done\s*\(->\s*parent_await_all_\d+\).*?<w2_done\s*\(->\s*parent_await_all_\d+\)/s,
        'three-spawn await_any observes any spawned done pulse before the await_all drain');
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<\(&\s*w0_done\s*w1_done\s*w2_done\)/s,
        'later await_all drains w0_done, w1_done, and w2_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_while_check_\d+\)\)/s,
        'three-spawn repeat re-entry returns to the first spawn only after the later await_all drain');
    my $top = $lowered->{files}{'while_wider_multi_pending_spawn_local_do_await_any_top.fsm'};
    like($top, qr/\(\?fsmc:w0 worker\b/s, 'generated top instantiates three-spawn w0');
    like($top, qr/\(\?fsmc:w1 worker\b/s, 'generated top instantiates three-spawn w1');
    like($top, qr/\(\?fsmc:w2 worker\b/s, 'generated top instantiates three-spawn w2');
};

subtest 'while-contained four-spawn multi-pending await_any after local do drains through later await_all' => sub {
    my $actor = parse_actor(actor_for_body('while_four_spawn_multi_pending_spawn_local_do_await_any', <<'ISF'), 'while-four-spawn-multi-pending-spawn-local-do-await-any');
(while cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (spawn worker as w2)
    (spawn worker as w3)
    (do helper)
    (await_any done)
    (await_all done)))
ISF

    my $check = check_actor($actor);
    ok($check->{ok}, 'effect checker proves the four-spawn while post-do multi-pending await_any shape');
    my $tx = transaction_check($check, 'parent');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done,w2_done,w3_done' } @{proofs($tx, 'await_any_observes_without_full_drain')}),
        'four-spawn while post-do await_any observes all four pending spawned children without full drain');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done,w2_done,w3_done' } @{proofs($tx, 'await_all_drains_outstanding_children')}),
        'four-spawn while later await_all drains all four pending spawned children');

    my ($lowered, $err) = lower_actor($actor);
    ok($lowered, 'public lowering accepts the four-spawn while post-do multi-pending await_any sequence') or diag($err);
    my $fsm = $lowered->{files}{'while_four_spawn_multi_pending_spawn_local_do_await_any.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w1_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w2_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w3_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'four while spawned children start before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_any_\d+/s,
        'while local do waits for helper_done before the four-spawn multi-pending await_any');
    like($fsm, qr/\(parent_await_any_\d+\b.*?<w0_done\s*\(->\s*parent_await_all_\d+\).*?<w1_done\s*\(->\s*parent_await_all_\d+\).*?<w2_done\s*\(->\s*parent_await_all_\d+\).*?<w3_done\s*\(->\s*parent_await_all_\d+\)/s,
        'four-spawn while await_any observes any spawned done pulse before the await_all drain');
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<\(&\s*w0_done\s*w1_done\s*w2_done\s*w3_done\)/s,
        'while later await_all drains w0_done, w1_done, w2_done, and w3_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_while_check_\d+\)\)/s,
        'four-spawn while repeat re-entry returns to the first spawn only after the later await_all drain');
    my $top = $lowered->{files}{'while_four_spawn_multi_pending_spawn_local_do_await_any_top.fsm'};
    like($top, qr/\(\?fsmc:w0 worker\b/s, 'generated top instantiates four-spawn while w0');
    like($top, qr/\(\?fsmc:w1 worker\b/s, 'generated top instantiates four-spawn while w1');
    like($top, qr/\(\?fsmc:w2 worker\b/s, 'generated top instantiates four-spawn while w2');
    like($top, qr/\(\?fsmc:w3 worker\b/s, 'generated top instantiates four-spawn while w3');
};

subtest 'while-contained five-spawn multi-pending await_any after local do remains fail-closed' => sub {
    my $actor = parse_actor(actor_for_body('while_five_spawn_multi_pending_spawn_local_do_await_any', <<'ISF'), 'while-five-spawn-multi-pending-spawn-local-do-await-any');
(while cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (spawn worker as w2)
    (spawn worker as w3)
    (spawn worker as w4)
    (do helper)
    (await_any done)
    (await_all done)))
ISF

    my ($lowered, $err) = lower_actor($actor);
    ok(!$lowered, 'public lowering still rejects the five-spawn while post-do multi-pending await_any sequence');
    like($err, qr/repeat-body do cannot appear while repeat-body spawn clauses are pending; wait for spawned children before blocking do/,
        'five-spawn while shape remains behind the wider local-do fanout gate');
};

subtest 'until-contained multi-pending await_any after local do drains through later await_all' => sub {
    my $actor = parse_actor(actor_for_body('until_multi_pending_spawn_local_do_await_any', <<'ISF'), 'until-multi-pending-spawn-local-do-await-any');
(until cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (do helper)
    (await_any done)
    (await_all done)))
ISF

    my $check = check_actor($actor);
    ok($check->{ok}, 'effect checker accepts the until post-do multi-pending await_any shape');
    my $tx = transaction_check($check, 'parent');
    my $backedges = proofs($tx, 'backedge_has_no_outstanding_children');
    ok((grep { ($_->{region_kind} // '') eq 'until' && ($_->{backedge} // '') eq 'until_retest' } @$backedges),
        'until backedge has no outstanding child for the post-do await_any shape');
    ok((grep { ($_->{region_kind} // '') eq 'repeat' && ($_->{backedge} // '') eq 'repeat_check_nonzero' } @$backedges),
        'repeat backedge has no outstanding child for the until post-do await_any shape');
    for my $index (0 .. 1) {
        my $inst = "w$index";
        my $done = "${inst}_done";
        ok((grep { ($_->{instance} // '') eq $inst } @{proofs($tx, 'generated_child_instance_is_static')}),
            "$inst until spawned child instance identity is static");
        ok((grep { ($_->{instance} // '') eq $inst && ($_->{done_signal} // '') eq $done } @{proofs($tx, 'generated_top_start_done_handoff_required')}),
            "$inst until generated-top handoff is explicit");
    }
    ok((grep { ($_->{child} // '') eq 'helper' } @{proofs($tx, 'blocking_do_drains_child_done')}),
        'local blocking do drains helper before the until multi-pending await_any');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done' } @{proofs($tx, 'await_any_observes_without_full_drain')}),
        'until post-do await_any observes both pending spawned children without full drain');
    ok(@{proofs($tx, 'await_any_multi_pending_requires_later_drain')},
        'until multi-pending await_any records a later-drain obligation');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done' } @{proofs($tx, 'await_all_drains_outstanding_children')}),
        'until later await_all drains both pending spawned children');

    my ($lowered, $err) = lower_actor($actor);
    ok($lowered, 'public lowering accepts the until post-do multi-pending await_any sequence') or diag($err);
    my $fsm = $lowered->{files}{'until_multi_pending_spawn_local_do_await_any.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w1_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'until starts both spawned children before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_any_\d+/s,
        'until local do waits for helper_done before the multi-pending await_any');
    like($fsm, qr/\(parent_await_any_\d+\b.*?<w0_done\s*\(->\s*parent_await_all_\d+\).*?<w1_done\s*\(->\s*parent_await_all_\d+\)/s,
        'until await_any observes either spawned done pulse before the await_all drain');
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<\(&\s*w0_done\s*w1_done\)/s,
        'until later await_all drains w0_done and w1_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_until_check_\d+\)\)/s,
        'until repeat re-entry returns to the first spawn only after the later await_all drain');
    like($fsm, qr/\(parent_until_check_\d+\b.*?\(=1\s*\(->\s*parent_done_\d+\)\).*?\(=0\s*\(->\s*parent_repeat_init_\d+\)\)/s,
        'until check exits when true and otherwise re-enters the repeat');
    my $top = $lowered->{files}{'until_multi_pending_spawn_local_do_await_any_top.fsm'};
    like($top, qr/\(\?fsmc:w0 worker\b/s, 'generated top instantiates until w0');
    like($top, qr/\(\?fsmc:w1 worker\b/s, 'generated top instantiates until w1');
};

subtest 'until-contained three-spawn multi-pending await_any after local do drains through later await_all' => sub {
    my $actor = parse_actor(actor_for_body('until_wider_multi_pending_spawn_local_do_await_any', <<'ISF'), 'until-wider-multi-pending-spawn-local-do-await-any');
(until cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (spawn worker as w2)
    (do helper)
    (await_any done)
    (await_all done)))
ISF

    my $check = check_actor($actor);
    ok($check->{ok}, 'effect checker accepts the wider until post-do multi-pending await_any shape');
    my $tx = transaction_check($check, 'parent');
    my $backedges = proofs($tx, 'backedge_has_no_outstanding_children');
    ok((grep { ($_->{region_kind} // '') eq 'until' && ($_->{backedge} // '') eq 'until_retest' } @$backedges),
        'until backedge has no outstanding child for the three-spawn post-do await_any shape');
    ok((grep { ($_->{region_kind} // '') eq 'repeat' && ($_->{backedge} // '') eq 'repeat_check_nonzero' } @$backedges),
        'repeat backedge has no outstanding child for the three-spawn until post-do await_any shape');
    for my $index (0 .. 2) {
        my $inst = "w$index";
        my $done = "${inst}_done";
        ok((grep { ($_->{instance} // '') eq $inst } @{proofs($tx, 'generated_child_instance_is_static')}),
            "$inst wider until spawned child instance identity is static");
        ok((grep { ($_->{instance} // '') eq $inst && ($_->{done_signal} // '') eq $done } @{proofs($tx, 'generated_top_start_done_handoff_required')}),
            "$inst wider until generated-top handoff is explicit");
    }
    ok((grep { ($_->{child} // '') eq 'helper' } @{proofs($tx, 'blocking_do_drains_child_done')}),
        'local blocking do drains helper before the three-spawn until multi-pending await_any');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done,w2_done' } @{proofs($tx, 'await_any_observes_without_full_drain')}),
        'wider until post-do await_any observes all three pending spawned children without full drain');
    ok(@{proofs($tx, 'await_any_multi_pending_requires_later_drain')},
        'wider until multi-pending await_any records a later-drain obligation');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done,w2_done' } @{proofs($tx, 'await_all_drains_outstanding_children')}),
        'wider until later await_all drains all three pending spawned children');

    my ($lowered, $err) = lower_actor($actor);
    ok($lowered, 'public lowering accepts the three-spawn until post-do multi-pending await_any sequence') or diag($err);
    my $fsm = $lowered->{files}{'until_wider_multi_pending_spawn_local_do_await_any.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w1_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w2_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'three until spawned children start before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_any_\d+/s,
        'until local do waits for helper_done before the three-spawn multi-pending await_any');
    like($fsm, qr/\(parent_await_any_\d+\b.*?<w0_done\s*\(->\s*parent_await_all_\d+\).*?<w1_done\s*\(->\s*parent_await_all_\d+\).*?<w2_done\s*\(->\s*parent_await_all_\d+\)/s,
        'three-spawn until await_any observes any spawned done pulse before the await_all drain');
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<\(&\s*w0_done\s*w1_done\s*w2_done\)/s,
        'until later await_all drains w0_done, w1_done, and w2_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_until_check_\d+\)\)/s,
        'three-spawn until repeat re-entry returns to the first spawn only after the later await_all drain');
    like($fsm, qr/\(parent_until_check_\d+\b.*?\(=1\s*\(->\s*parent_done_\d+\)\).*?\(=0\s*\(->\s*parent_repeat_init_\d+\)\)/s,
        'three-spawn until check exits when true and otherwise re-enters the repeat');
    my $top = $lowered->{files}{'until_wider_multi_pending_spawn_local_do_await_any_top.fsm'};
    like($top, qr/\(\?fsmc:w0 worker\b/s, 'generated top instantiates wider until w0');
    like($top, qr/\(\?fsmc:w1 worker\b/s, 'generated top instantiates wider until w1');
    like($top, qr/\(\?fsmc:w2 worker\b/s, 'generated top instantiates wider until w2');
};

subtest 'until-contained four-spawn multi-pending await_any after local do drains through later await_all' => sub {
    my $actor = parse_actor(actor_for_body('until_four_spawn_multi_pending_spawn_local_do_await_any', <<'ISF'), 'until-four-spawn-multi-pending-spawn-local-do-await-any');
(until cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (spawn worker as w2)
    (spawn worker as w3)
    (do helper)
    (await_any done)
    (await_all done)))
ISF

    my $check = check_actor($actor);
    ok($check->{ok}, 'effect checker proves the four-spawn until post-do multi-pending await_any shape');
    my $tx = transaction_check($check, 'parent');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done,w2_done,w3_done' } @{proofs($tx, 'await_any_observes_without_full_drain')}),
        'four-spawn until post-do await_any observes all four pending spawned children without full drain');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done,w2_done,w3_done' } @{proofs($tx, 'await_all_drains_outstanding_children')}),
        'four-spawn until later await_all drains all four pending spawned children');

    my ($lowered, $err) = lower_actor($actor);
    ok($lowered, 'public lowering accepts the four-spawn until post-do multi-pending await_any sequence') or diag($err);
    my $fsm = $lowered->{files}{'until_four_spawn_multi_pending_spawn_local_do_await_any.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w1_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w2_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w3_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'four until spawned children start before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_any_\d+/s,
        'until local do waits for helper_done before the four-spawn multi-pending await_any');
    like($fsm, qr/\(parent_await_any_\d+\b.*?<w0_done\s*\(->\s*parent_await_all_\d+\).*?<w1_done\s*\(->\s*parent_await_all_\d+\).*?<w2_done\s*\(->\s*parent_await_all_\d+\).*?<w3_done\s*\(->\s*parent_await_all_\d+\)/s,
        'four-spawn until await_any observes any spawned done pulse before the await_all drain');
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<\(&\s*w0_done\s*w1_done\s*w2_done\s*w3_done\)/s,
        'until later await_all drains w0_done, w1_done, w2_done, and w3_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_until_check_\d+\)\)/s,
        'four-spawn until repeat re-entry returns to the first spawn only after the later await_all drain');
    like($fsm, qr/\(parent_until_check_\d+\b.*?\(=1\s*\(->\s*parent_done_\d+\)\).*?\(=0\s*\(->\s*parent_repeat_init_\d+\)\)/s,
        'four-spawn until check exits when true and otherwise re-enters the repeat');
    my $top = $lowered->{files}{'until_four_spawn_multi_pending_spawn_local_do_await_any_top.fsm'};
    like($top, qr/\(\?fsmc:w0 worker\b/s, 'generated top instantiates four-spawn until w0');
    like($top, qr/\(\?fsmc:w1 worker\b/s, 'generated top instantiates four-spawn until w1');
    like($top, qr/\(\?fsmc:w2 worker\b/s, 'generated top instantiates four-spawn until w2');
    like($top, qr/\(\?fsmc:w3 worker\b/s, 'generated top instantiates four-spawn until w3');
};

subtest 'until-contained five-spawn multi-pending await_any after local do remains fail-closed' => sub {
    my $actor = parse_actor(actor_for_body('until_five_spawn_multi_pending_spawn_local_do_await_any', <<'ISF'), 'until-five-spawn-multi-pending-spawn-local-do-await-any');
(until cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (spawn worker as w2)
    (spawn worker as w3)
    (spawn worker as w4)
    (do helper)
    (await_any done)
    (await_all done)))
ISF

    my ($lowered, $err) = lower_actor($actor);
    ok(!$lowered, 'public lowering still rejects the five-spawn until post-do multi-pending await_any sequence');
    like($err, qr/repeat-body do cannot appear while repeat-body spawn clauses are pending; wait for spawned children before blocking do/,
        'five-spawn until shape remains behind the wider local-do fanout gate');
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
