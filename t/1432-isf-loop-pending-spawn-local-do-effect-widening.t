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

subtest 'while-contained pending spawn across local do lowers through effect proofs' => sub {
    my $actor = parse_actor(actor_for_body('while_pending_spawn_local_do', <<'ISF'), 'while-pending-spawn-local-do');
(while cond
  (repeat loops
    (spawn worker as w0)
    (do helper)
    (await_all done)))
ISF

    my $check = check_actor($actor);
    ok($check->{ok}, 'effect checker accepts the selected pending-spawn local-do shape');
    my $tx = transaction_check($check, 'parent');
    my $backedges = proofs($tx, 'backedge_has_no_outstanding_children');
    ok((grep { ($_->{region_kind} // '') eq 'while' } @$backedges), 'while backedge has no outstanding child');
    ok((grep { ($_->{region_kind} // '') eq 'repeat' } @$backedges), 'repeat backedge has no outstanding child');
    ok((grep { ($_->{instance} // '') eq 'w0' } @{proofs($tx, 'generated_child_instance_is_static')}),
        'spawned child instance identity is static');
    ok((grep { ($_->{child} // '') eq 'helper' } @{proofs($tx, 'blocking_do_drains_child_done')}),
        'local blocking do drains its own child');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done' } @{proofs($tx, 'await_all_drains_outstanding_children')}),
        'await_all drains the pending spawned child');

    my ($lowered, $err) = lower_actor($actor);
    ok($lowered, 'public lowering accepts the effect-proven sequence') or diag($err);
    my $fsm = $lowered->{files}{'while_pending_spawn_local_do.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'spawn starts w0 before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_all_\d+/s,
        'local do waits for helper_done before await_all');
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<w0_done/s,
        'await_all drains w0_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_while_check_\d+\)\)/s,
        'repeat re-entry returns to the spawn only after the drain');
    like($lowered->{files}{'while_pending_spawn_local_do_top.fsm'}, qr/\(\?fsmc:w0 worker\b/s,
        'generated top still instantiates the spawned child');
};

subtest 'missing final drain remains fail-closed with a targeted lifetime diagnostic' => sub {
    my $actor = parse_actor(actor_for_body('while_pending_spawn_local_do_undrained', <<'ISF'), 'while-pending-spawn-local-do-undrained');
(while cond
  (repeat loops
    (spawn worker as w0)
    (do helper)))
ISF

    my ($lowered, $err) = lower_actor($actor);
    ok(!$lowered, 'missing await_all drain is still rejected');
    like($err, qr/repeat-body do cannot appear while repeat-body spawn clauses are pending/,
        'missing drain keeps the existing pending-spawn do gate because no await_all proof exists');
};

subtest 'while-contained multi-pending spawn across local do lowers through effect proofs' => sub {
    my $multi = parse_actor(actor_for_body('while_multi_pending_spawn_local_do', <<'ISF'), 'while-multi-pending-spawn-local-do');
(while cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (do helper)
    (await_all done)))
ISF

    my ($multi_lowered, $multi_err) = lower_actor($multi);
    my $check = check_actor($multi);
    ok($check->{ok}, 'effect checker accepts the selected while multi-pending local-do shape');
    my $tx = transaction_check($check, 'parent');
    my $backedges = proofs($tx, 'backedge_has_no_outstanding_children');
    ok((grep { ($_->{region_kind} // '') eq 'while' && ($_->{backedge} // '') eq 'while_retest' } @$backedges),
        'while backedge has no outstanding child for the multi-pending shape');
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

    ok($multi_lowered, 'public lowering accepts the selected while multi-pending local-do sequence') or diag($multi_err);
    my $fsm = $multi_lowered->{files}{'while_multi_pending_spawn_local_do.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w1_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'both spawned children start before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_all_\d+/s,
        'local do waits for helper_done before draining spawned children');
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<\(&\s*w0_done\s*w1_done\)/s,
        'await_all drains w0_done and w1_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_while_check_\d+\)\)/s,
        'repeat re-entry returns to the first spawn only after the multi-pending drain');
    my $top = $multi_lowered->{files}{'while_multi_pending_spawn_local_do_top.fsm'};
    like($top, qr/\(\?fsmc:w0 worker\b/s, 'generated top instantiates w0');
    like($top, qr/\(\?fsmc:w1 worker\b/s, 'generated top instantiates w1');
};

subtest 'while-contained three-pending spawn across local do lowers through effect proofs' => sub {
    my $multi = parse_actor(actor_for_body('while_three_pending_spawn_local_do', <<'ISF'), 'while-three-pending-spawn-local-do');
(while cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (spawn worker as w2)
    (do helper)
    (await_all done)))
ISF

    my ($multi_lowered, $multi_err) = lower_actor($multi);
    my $check = check_actor($multi);
    ok($check->{ok}, 'effect checker accepts the selected while three-pending local-do shape');
    my $tx = transaction_check($check, 'parent');
    my $backedges = proofs($tx, 'backedge_has_no_outstanding_children');
    ok((grep { ($_->{region_kind} // '') eq 'while' && ($_->{backedge} // '') eq 'while_retest' } @$backedges),
        'while backedge has no outstanding child for the three-pending shape');
    ok((grep { ($_->{region_kind} // '') eq 'repeat' && ($_->{backedge} // '') eq 'repeat_check_nonzero' } @$backedges),
        'repeat backedge has no outstanding child for the three-pending shape');
    for my $index (0 .. 2) {
        my $inst = "w$index";
        my $done = "${inst}_done";
        ok((grep { ($_->{instance} // '') eq $inst } @{proofs($tx, 'generated_child_instance_is_static')}),
            "$inst spawned child instance identity is static");
        ok((grep { ($_->{instance} // '') eq $inst && ($_->{done_signal} // '') eq $done } @{proofs($tx, 'generated_top_start_done_handoff_required')}),
            "$inst generated-top handoff is explicit");
    }
    ok((grep { ($_->{child} // '') eq 'helper' } @{proofs($tx, 'blocking_do_drains_child_done')}),
        'local blocking do drains helper before the three-way await_all');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done,w2_done' } @{proofs($tx, 'await_all_drains_outstanding_children')}),
        'await_all drains all three pending spawned children');

    ok($multi_lowered, 'public lowering accepts the selected while three-pending local-do sequence') or diag($multi_err);
    my $fsm = $multi_lowered->{files}{'while_three_pending_spawn_local_do.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w1_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w2_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'all three spawned children start before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_all_\d+/s,
        'local do waits for helper_done before draining all spawned children');
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<\(&\s*w0_done\s*w1_done\s*w2_done\)/s,
        'await_all drains w0_done, w1_done, and w2_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_while_check_\d+\)\)/s,
        'repeat re-entry returns to the first spawn only after the three-pending drain');
    my $top = $multi_lowered->{files}{'while_three_pending_spawn_local_do_top.fsm'};
    like($top, qr/\(\?fsmc:w0 worker\b/s, 'generated top instantiates w0');
    like($top, qr/\(\?fsmc:w1 worker\b/s, 'generated top instantiates w1');
    like($top, qr/\(\?fsmc:w2 worker\b/s, 'generated top instantiates w2');
};

subtest 'while-contained four-pending spawn across local do lowers through effect proofs' => sub {
    my $multi = parse_actor(actor_for_body('while_four_pending_spawn_local_do', <<'ISF'), 'while-four-pending-spawn-local-do');
(while cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (spawn worker as w2)
    (spawn worker as w3)
    (do helper)
    (await_all done)))
ISF

    my ($multi_lowered, $multi_err) = lower_actor($multi);
    my $check = check_actor($multi);
    ok($check->{ok}, 'effect checker accepts the selected while four-pending local-do shape');
    my $tx = transaction_check($check, 'parent');
    my $backedges = proofs($tx, 'backedge_has_no_outstanding_children');
    ok((grep { ($_->{region_kind} // '') eq 'while' && ($_->{backedge} // '') eq 'while_retest' } @$backedges),
        'while backedge has no outstanding child for the four-pending shape');
    ok((grep { ($_->{region_kind} // '') eq 'repeat' && ($_->{backedge} // '') eq 'repeat_check_nonzero' } @$backedges),
        'repeat backedge has no outstanding child for the four-pending shape');
    for my $index (0 .. 3) {
        my $inst = "w$index";
        my $done = "${inst}_done";
        ok((grep { ($_->{instance} // '') eq $inst } @{proofs($tx, 'generated_child_instance_is_static')}),
            "$inst spawned child instance identity is static");
        ok((grep { ($_->{instance} // '') eq $inst && ($_->{done_signal} // '') eq $done } @{proofs($tx, 'generated_top_start_done_handoff_required')}),
            "$inst generated-top handoff is explicit");
    }
    ok((grep { ($_->{child} // '') eq 'helper' } @{proofs($tx, 'blocking_do_drains_child_done')}),
        'local blocking do drains helper before the four-way await_all');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done,w2_done,w3_done' } @{proofs($tx, 'await_all_drains_outstanding_children')}),
        'await_all drains all four pending spawned children');

    ok($multi_lowered, 'public lowering accepts the selected while four-pending local-do sequence') or diag($multi_err);
    my $fsm = $multi_lowered->{files}{'while_four_pending_spawn_local_do.fsm'};
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w1_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w2_start>\s*1\)\).*?->\s*parent_spawn_\d+.*?\(=\s*\(w3_start>\s*1\)\).*?->\s*parent_do_\d+/s,
        'all four spawned children start before the local do');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(helper_start\s*1\)\).*?<helper_done.*?->\s*parent_await_all_\d+/s,
        'local do waits for helper_done before draining all four spawned children');
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<\(&\s*w0_done\s*w1_done\s*w2_done\s*w3_done\)/s,
        'await_all drains w0_done, w1_done, w2_done, and w3_done before repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_while_check_\d+\)\)/s,
        'repeat re-entry returns to the first spawn only after the four-pending drain');
    my $top = $multi_lowered->{files}{'while_four_pending_spawn_local_do_top.fsm'};
    like($top, qr/\(\?fsmc:w0 worker\b/s, 'generated top instantiates w0');
    like($top, qr/\(\?fsmc:w1 worker\b/s, 'generated top instantiates w1');
    like($top, qr/\(\?fsmc:w2 worker\b/s, 'generated top instantiates w2');
    like($top, qr/\(\?fsmc:w3 worker\b/s, 'generated top instantiates w3');
};

subtest 'while-contained five-pending spawn across local do lowers through generalized effect proofs' => sub {
    my $multi = parse_actor(actor_for_body('while_five_pending_spawn_local_do', <<'ISF'), 'while-five-pending-spawn-local-do');
(while cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (spawn worker as w2)
    (spawn worker as w3)
    (spawn worker as w4)
    (do helper)
    (await_all done)))
ISF

    my ($multi_lowered, $multi_err) = lower_actor($multi);
    my $check = check_actor($multi);
    ok($check->{ok}, 'effect checker accepts the generalized while five-pending local-do shape');
    my $tx = transaction_check($check, 'parent');
    ok((grep { join(',', @{$_->{done_ports} || []}) eq 'w0_done,w1_done,w2_done,w3_done,w4_done' } @{proofs($tx, 'await_all_drains_outstanding_children')}),
        'await_all drains all five pending spawned children');

    ok($multi_lowered, 'public lowering accepts the proof-generalized while five-pending local-do sequence') or diag($multi_err);
    my $fsm = $multi_lowered->{files}{'while_five_pending_spawn_local_do.fsm'};
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<\(&\s*w0_done\s*w1_done\s*w2_done\s*w3_done\s*w4_done\)/s,
        'await_all drains all five done ports before repeat_check');
    my $top = $multi_lowered->{files}{'while_five_pending_spawn_local_do_top.fsm'};
    like($top, qr/\(\?fsmc:w4 worker\b/s, 'generated top instantiates the fifth spawned child');
};

subtest 'multi-pending missing final drain remains fail-closed' => sub {
    my $actor = parse_actor(actor_for_body('while_multi_pending_spawn_local_do_undrained', <<'ISF'), 'while-multi-pending-spawn-local-do-undrained');
(while cond
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
