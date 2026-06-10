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

sub inventory_for {
    my ($source, $name) = @_;
    my $actor = parse_actor($source, $name);
    return (FSM::Scheduler::ISF::ControlFlowEffects->new()->inventory_actor($actor), $actor);
}

sub transaction_inventory {
    my ($inventory, $name) = @_;
    my ($tx) = grep { $_->{name} eq $name } @{$inventory->{transactions} || []};
    return $tx;
}

sub first_effect {
    my ($tx, $activation, $kind) = @_;
    my ($effect) = grep {
        ($_->{activation} // '') eq $activation
            && (!defined($kind) || ($_->{kind} // '') eq $kind)
    } @{$tx->{effects} || []};
    return $effect;
}

subtest 'while -> when -> repeat -> local do records regions and blocking child effect' => sub {
    my ($inventory) = inventory_for(<<'ISF', 'while-when-repeat-do');
(actor while_when_repeat_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input c1) (input c2) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while c1
      (when c2
        (repeat loops
          (do worker))))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    is($inventory->{model}, 'isf_control_flow_effects_v1', 'inventory advertises the v1 shadow model');
    my $tx = transaction_inventory($inventory, 'parent');
    ok($tx, 'parent transaction inventory exists');
    is($tx->{summary}{region_kinds}{transaction}, 1, 'transaction root region recorded');
    is($tx->{summary}{region_kinds}{while}, 1, 'while region recorded');
    is($tx->{summary}{region_kinds}{when}, 1, 'when region recorded');
    is($tx->{summary}{region_kinds}{repeat}, 1, 'repeat region recorded');
    is($tx->{summary}{backedge_count}, 2, 'while and repeat backedges are explicit');

    my ($repeat) = grep { $_->{kind} eq 'repeat' } @{$tx->{regions}};
    is($repeat->{entry}{kind}, 'repeat_init', 'repeat entry is typed as repeat_init');
    is($repeat->{backedges}[0]{kind}, 'repeat_check_nonzero', 'repeat loopback is typed');
    is($repeat->{backedges}[0]{outstanding_child_lifetime}, 'must_be_drained_or_proven',
        'repeat loopback carries the outstanding-child lifetime requirement');
    is_deeply($repeat->{outstanding_on_exit}, [], 'blocking local do leaves no outstanding child on repeat exit');

    my $do = first_effect($tx, 'do', 'child_start');
    ok($do, 'blocking do effect recorded');
    is($do->{region_kind}, 'repeat', 'local do is owned by the repeat region');
    is($do->{target_kind}, 'local_child', 'plain do is classified as a local child activation');
    is($do->{start_signal}, 'worker_start', 'local do start signal matches current lowering');
    is($do->{done_signal}, 'worker_done', 'local do done signal matches current lowering');
    is($do->{done_semantics}, 'blocking_child_done_drain', 'blocking do drains before the next region step');
};

subtest 'multi-pending await_any observes and later await_all drains' => sub {
    my ($inventory) = inventory_for(<<'ISF', 'repeat-spawn-observe-drain');
(actor repeat_spawn_observe_drain
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

    my $tx = transaction_inventory($inventory, 'parent');
    my @spawn = grep { ($_->{activation} // '') eq 'spawn' } @{$tx->{effects}};
    is(scalar(@spawn), 2, 'two spawn start effects recorded');
    is_deeply([map { $_->{instance} } @spawn], [qw(w0 w1)], 'spawn instance names are source-stable');
    is_deeply([map { $_->{done_signal} } @spawn], [qw(w0_done w1_done)], 'spawn done signals are explicit');

    my $await_any = first_effect($tx, 'await_any', 'child_done_observe');
    ok($await_any, 'await_any observe effect recorded');
    is($await_any->{drains_all}, 0, 'await_any is not modeled as a full drain');
    is_deeply($await_any->{done_ports}, [qw(w0_done w1_done)], 'await_any observes the outstanding set');
    is_deeply($await_any->{remaining_outstanding_after}, [qw(w0_done w1_done)],
        'multi-pending await_any keeps the outstanding set for a later drain proof');

    my $await_all = first_effect($tx, 'await_all', 'child_done_drain');
    ok($await_all, 'await_all drain effect recorded');
    is($await_all->{drains_all}, 1, 'await_all is modeled as the draining join');
    is_deeply($await_all->{done_ports}, [qw(w0_done w1_done)], 'await_all drains the same outstanding set');

    my ($repeat) = grep { $_->{kind} eq 'repeat' } @{$tx->{regions}};
    is_deeply($repeat->{outstanding_on_exit}, [], 'await_all leaves no outstanding child at repeat exit');
};

subtest 'generated conditional do records deterministic instance, params, and bindings' => sub {
    my ($inventory, $actor) = inventory_for(<<'ISF', 'when-generated-do-effect');
(actor when_generated_do_effect
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

    is_deeply($inventory->{generated_child_targets}, ['worker'], 'parameterized do marks worker as generated');
    my $tx = transaction_inventory($inventory, 'parent');
    my $do = first_effect($tx, 'do', 'child_start');
    is($do->{target_kind}, 'generated_child', 'parameterized conditional do is generated');
    is($do->{instance}, 'parent_worker_cond_do_0', 'conditional generated do instance name matches lowering');
    is($do->{start_signal}, 'parent_worker_cond_do_0_start', 'generated start handoff is explicit');
    is($do->{done_signal}, 'parent_worker_cond_do_0_done', 'generated done handoff is explicit');
    is($do->{parameterized}, 1, 'parameter override effect bit is set');
    is(scalar(@{$do->{bindings}}), 2, 'bind handoffs are represented as typed effect metadata');

    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'existing generated conditional do lowering still accepts the fixture') or diag($@);
};

subtest 'switch branch spawn records branch region ownership' => sub {
    my ($inventory) = inventory_for(<<'ISF', 'switch-spawn-effect');
(actor switch_spawn_effect
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input sel (width 2))
    (output done))
  (transaction parent
    (on start)
    (switch sel
      (1
        (spawn worker as sw0)
        (await_all done)))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    my $tx = transaction_inventory($inventory, 'parent');
    is($tx->{summary}{region_kinds}{switch}, 1, 'switch region recorded');
    is($tx->{summary}{region_kinds}{switch_branch}, 1, 'switch branch region recorded');
    my $spawn = first_effect($tx, 'spawn', 'child_start');
    is($spawn->{region_kind}, 'switch_branch', 'spawn effect belongs to the switch branch region');
    is($spawn->{instance}, 'sw0', 'switch branch spawn instance name is preserved');
    my ($branch) = grep { $_->{kind} eq 'switch_branch' } @{$tx->{regions}};
    is_deeply($branch->{outstanding_on_exit}, [], 'branch await_all drains before branch exit');
};

subtest 'inventory is shadow-only: unsupported undrained repeat spawn still fails closed' => sub {
    my ($inventory, $actor) = inventory_for(<<'ISF', 'undrained-repeat-spawn-effect');
(actor undrained_repeat_spawn_effect
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

    my $tx = transaction_inventory($inventory, 'parent');
    my ($repeat) = grep { $_->{kind} eq 'repeat' } @{$tx->{regions}};
    is_deeply($repeat->{outstanding_on_exit}, ['w0_done'],
        'shadow inventory exposes the outstanding child at repeat exit');

    my $ok = eval { FSM::Scheduler::ISF->new()->lower($actor); 1 };
    ok(!$ok, 'lowering remains fail-closed for the unsupported undrained spawn');
    like($@, qr/loop-contained repeat-body spawn requires same-body '\(await_all done\)' or single-pending '\(await_any done\)'/,
        'the existing validator diagnostic remains in force');
};

done_testing();
