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

subtest 'multi-pending variant remains outside the exact single-pending slice' => sub {
    my $multi = parse_actor(actor_for_body('while_multi_pending_spawn_local_do', <<'ISF'), 'while-multi-pending-spawn-local-do');
(while cond
  (repeat loops
    (spawn worker as w0)
    (spawn worker as w1)
    (do helper)
    (await_all done)))
ISF

    my ($multi_lowered, $multi_err) = lower_actor($multi);
    ok(!$multi_lowered, 'multi-pending spawn across local do remains rejected');
    like($multi_err, qr/repeat-body do cannot appear while repeat-body spawn clauses are pending/,
        'multi-pending variant keeps the existing broad pending-spawn do gate');
};

done_testing();
