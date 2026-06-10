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
    my $model = FSM::Scheduler::ISF::ControlFlowEffects->new();
    return ($model->inventory_actor($actor), $model->check_actor($actor), $model->plan_actor($actor), $actor);
}

sub transaction_inventory {
    my ($inventory, $name) = @_;
    my ($tx) = grep { $_->{name} eq $name } @{$inventory->{transactions} || []};
    return $tx;
}

sub transaction_check {
    my ($check, $name) = @_;
    my ($tx) = grep { $_->{name} eq $name } @{$check->{transactions} || []};
    return $tx;
}

sub first_child_start {
    my ($tx, $activation) = @_;
    my ($effect) = grep {
        ($_->{kind} // '') eq 'child_start'
            && ($_->{activation} // '') eq $activation
    } @{$tx->{effects} || []};
    return $effect;
}

sub proof {
    my ($tx, $code) = @_;
    my ($proof) = grep { ($_->{code} // '') eq $code } @{$tx->{proofs} || []};
    return $proof;
}

sub proofs {
    my ($tx, $code) = @_;
    return [grep { ($_->{code} // '') eq $code } @{$tx->{proofs} || []}];
}

sub violation {
    my ($tx, $code) = @_;
    my ($violation) = grep { ($_->{code} // '') eq $code } @{$tx->{violations} || []};
    return $violation;
}

sub lower_ok {
    my ($actor) = @_;
    return eval { FSM::Scheduler::ISF->new()->lower($actor); 1 };
}

subtest 'same-domain generated do records domain, bindings, and generated-top requirements' => sub {
    my ($inventory, $check, $plan, $actor) = inventory_for(<<'ISF', 'same-domain-binding-effects');
(actor same_domain_binding_effects
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default))
  (interface
    (input start (domain core))
    (input cond (domain core))
    (input din (width 8) (domain core))
    (output done (domain core))
    (output result (width 8) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (when cond
      (do worker
        (params (W 8))
        (bind (input data din) (output data_out result))
        (domain core)))
    (complete done))
  (transaction worker
    (domain core)
    (params (W 8))
    (ports (input data (width W)) (output data_out (width W)))
    (on start)
    (update data_out data)
    (complete done)))
ISF

    is($inventory->{domain_context}{default_domain}, 'core', 'inventory records the default domain');
    is($inventory->{domain_context}{transaction_domains}{parent}, 'core', 'parent transaction domain recorded');
    is($inventory->{domain_context}{transaction_domains}{worker}, 'core', 'worker transaction domain recorded');

    my $tx = transaction_inventory($inventory, 'parent');
    my $do = first_child_start($tx, 'do');
    is($do->{domain_contract}{relation}, 'same_domain', 'activation is classified as same-domain');
    is($do->{domain_contract}{activation_domain}, 'core', 'authored activation domain is recorded');
    is($do->{domain_contract}{cdc_requirement}, 'none', 'same-domain activation has no CDC requirement');
    is_deeply(
        [map { $_->{handoff_direction} . ':' . $_->{handoff_timing} } @{$do->{bindings}}],
        [qw(actor_to_child:activation_region child_to_actor:done_guarded)],
        'binding handoffs carry typed direction and timing',
    );
    is_deeply(
        [map { $_->{kind} } @{$do->{generated_top_requirements}}],
        [qw(start_done_handoff binding_handoff binding_handoff)],
        'generated top requirements include start/done and both binding handoffs',
    );

    ok($check->{ok}, 'checker accepts the same-domain generated do contract');
    my $checked = transaction_check($check, 'parent');
    ok(proof($checked, 'activation_target_is_same_domain'), 'same-domain proof recorded');
    ok(proof($checked, 'activation_domain_is_explicit'), 'same-domain domain metadata proof recorded');
    is(scalar(@{proofs($checked, 'binding_handoff_is_explicit')}), 2, 'both binding handoffs are proven');
    is(scalar(@{proofs($checked, 'generated_top_binding_handoff_required')}), 2,
        'both generated-top binding requirements are proven');

    my ($requirement) = @{$plan->{activation_requirements}};
    is($requirement->{domain_contract}{relation}, 'same_domain', 'plan carries the same-domain contract');
    is(scalar(@{$requirement->{bindings}}), 2, 'plan carries binding handoffs');
    ok(lower_ok($actor), 'existing lowering still accepts the same-domain generated do') or diag($@);
};

subtest 'covered cross-domain do records activation-crossing CDC requirements' => sub {
    my ($inventory, $check, $plan, $actor) = inventory_for(<<'ISF', 'covered-cross-domain-effect');
(actor covered_cross_domain_effect
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (crossings
    (activation worker (from core) (to bus)))
  (interface
    (input start (domain core))
    (output done (domain core))
    (input din (width 8) (domain bus))
    (output result (width 8) (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (do worker)
    (complete done))
  (transaction worker
    (domain bus)
    (sample din as snap)
    (update result snap)
    (complete result)))
ISF

    is(scalar(@{$inventory->{domain_context}{activation_crossings}}), 1,
        'actor-level activation crossing is recorded');
    my $tx = transaction_inventory($inventory, 'parent');
    my $do = first_child_start($tx, 'do');
    is($do->{domain_contract}{relation}, 'cross_domain', 'activation is classified as cross-domain');
    is($do->{domain_contract}{cdc_requirement}, 'activation_crossing_declared',
        'explicit activation crossing satisfies the CDC requirement');
    is_deeply(
        [map { $_->{kind} } @{$do->{domain_contract}{cdc_handoffs}}],
        [qw(activation_start_cdc activation_done_cdc)],
        'start and done CDC handoffs are explicit',
    );

    ok($check->{ok}, 'checker accepts the covered cross-domain activation');
    my $checked = transaction_check($check, 'parent');
    my $cdc = proof($checked, 'activation_crossing_covers_child_start');
    ok($cdc, 'activation-crossing proof recorded');
    is_deeply([map { $_->{signal} } @{$cdc->{cdc_handoffs}}], [qw(worker_start worker_done)],
        'proof names the start and done CDC handshakes');
    is(scalar(@{proofs($checked, 'generated_top_activation_cdc_handoff_required')}), 2,
        'generated-top CDC handoff requirements are proven');
    is($plan->{activation_requirements}[0]{domain_contract}{cdc_requirement}, 'activation_crossing_declared',
        'plan carries the activation crossing requirement');
    ok(lower_ok($actor), 'existing lowering still accepts the covered cross-domain activation') or diag($@);
};

subtest 'uncovered cross-domain do remains fail-closed and is explained by the shadow contract' => sub {
    my ($inventory, $check, undef, $actor) = inventory_for(<<'ISF', 'uncovered-cross-domain-effect');
(actor uncovered_cross_domain_effect
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input start (domain core))
    (output done (domain core))
    (output worker_done (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (do worker)
    (complete done))
  (transaction worker
    (domain bus)
    (complete worker_done)))
ISF

    my $tx = transaction_inventory($inventory, 'parent');
    my $do = first_child_start($tx, 'do');
    is($do->{domain_contract}{cdc_requirement}, 'activation_crossing_required',
        'shadow contract requires an explicit activation crossing');
    ok(!$check->{ok}, 'checker rejects the uncovered cross-domain activation');
    my $checked = transaction_check($check, 'parent');
    ok(violation($checked, 'cross_domain_activation_requires_activation_crossing'),
        'missing activation crossing violation recorded');

    my $ok = lower_ok($actor);
    ok(!$ok, 'existing lowering remains fail-closed for uncovered cross-domain do');
    like($@, qr/clock-domain violation.*do target 'worker'.*domain 'bus'.*domain 'core'/s,
        'public diagnostic remains owned by the existing validator');
};

subtest 'cross-domain spawn remains unsupported without an implicit CDC inference' => sub {
    my ($inventory, $check, undef, $actor) = inventory_for(<<'ISF', 'cross-domain-spawn-effect');
(actor cross_domain_spawn_effect
  (clock-domains
    (domain core (clock clk) :default)
    (domain bus (clock bus_clk)))
  (interface
    (input start (domain core))
    (input loops (width 3) (domain core))
    (output done (domain core))
    (output worker_done (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (repeat loops
      (spawn worker as w0
        (domain bus))
      (await_all done))
    (complete done))
  (transaction worker
    (domain bus)
    (complete worker_done)))
ISF

    my $tx = transaction_inventory($inventory, 'parent');
    my $spawn = first_child_start($tx, 'spawn');
    is($spawn->{domain_contract}{relation}, 'cross_domain', 'spawn target is classified as cross-domain');
    is($spawn->{domain_contract}{cdc_requirement}, 'unsupported_cross_domain_spawn',
        'cross-domain spawn is an explicit unsupported CDC requirement');
    ok(!$check->{ok}, 'checker rejects the cross-domain spawn contract');
    my $checked = transaction_check($check, 'parent');
    ok(violation($checked, 'cross_domain_spawn_requires_future_cdc_contract'),
        'cross-domain spawn violation recorded');

    my $ok = lower_ok($actor);
    ok(!$ok, 'existing lowering remains fail-closed for cross-domain spawn');
    like($@, qr/clock-domain violation: transaction 'parent' spawn target 'worker' references transaction in domain 'bus' from domain 'core'/,
        'public cross-domain spawn diagnostic remains stable');
};

done_testing();
