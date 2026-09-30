#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalReservationInventory;

my $lowerer = FSM::Scheduler::ISF::LoweringIR->new;
sub parse { FSM::Adapter::ISF->new->parse_source($_[0], 'parent_products.isf') }
sub inventory { FSM::Scheduler::ISF::FormalReservationInventory->collect($_[0]) }
sub identity_plan {
    my ($prepared, $names) = @_;
    FSM::Scheduler::ISF::FormalIdentityPlan->build($prepared->{actor},
        generated_children => $prepared->{generated_children}, reserved_names => $names);
}
sub compare_parent {
    my ($prepared, $ir) = @_;
    my $p = $prepared->{parent_activation_products};
    my %dts = map {$_->{name} => $_} @{$ir->{dt_blocks}};
    # Activation products precede accepted-payload retention. Compare transformed
    # DTs to the complete retained producer; every other DT remains exact/raw.
    my %snapshots = map {$_->{name} => $_} @{$prepared->{parent_payload_snapshot_products}{dt_blocks}};
    for my $dt (@{$p->{dt_blocks}}) {
        ok(exists $dts{$dt->{name}}, "actual parent retains DT $dt->{name}");
        my $expected = $snapshots{$dt->{name}} // $dt;
        is_deeply($dts{$dt->{name}}{assignments}, $expected->{assignments}, 'actual assignment targets/values/guards agree');
    }
    for my $field (qw(counters storage_roles)) {
        is_deeply({map {$_ => $ir->{$field}{$_}} keys %{$p->{$field}}}, $p->{$field}, "actual parent $field agree");
    }
    is_deeply($ir->{spawn_instances}, $p->{spawn_instances}, 'actual activation instance metadata agrees');
    is_deeply($ir->{bank_accesses}, $p->{bank_accesses}, 'actual rule bank accesses agree');
    my %ports = map {$_->{name} => $_} @{$ir->{ports}};
    is_deeply([map {$ports{$_->{name}}} @{$p->{ports}}], $p->{ports}, 'actual parent port declarations agree');
}

subtest 'local rule payload collision needs later producer inventory' => sub {
    for my $rule ('isf_port', 'ISF_PORT') {
        my $actor = parse(<<"ISF");
(actor rule_reservations (clock clk) (reset rst_n)
  (interface (input fire) (input din (width 4)) (output observed (width 4)) (output done))
  (transaction main (ports (input payload (width 4)))
    (on main_start) (set observed payload) (complete done))
  (rule $rule fire (trigger main (bind (input payload din)))))
ISF
        my $before = dclone($actor);
        my $prepared = $lowerer->prepare_formal_source($actor);
        my $tx_names = inventory($prepared->{transaction_products})->{reserved_names};
        my $candidate = identity_plan($prepared, $tx_names)->{formals}{main}{payload}{physical_name};
        my $helper = "${rule}_main_payload";
        is(lc($candidate), lc($helper), 'transaction-only reservation misses actual rule payload');
        ok(!exists $tx_names->{$helper}, 'rule helper genuinely absent from transaction products');
        my $all = inventory({transactions => $prepared->{transaction_products},
            parent_activations => $prepared->{parent_activation_products}});
        ok($all->{reserved_names}{$helper}, 'actual rule producer supplies helper name');
        is($prepared->{parent_activation_products}{storage_roles}{$helper}, 'rule_trigger_payload_source', 'helper has actual payload role');
        my $safe = identity_plan($prepared, $all->{reserved_names});
        isnt(lc($safe->{formals}{main}{payload}{physical_name}), lc($helper), 'combined partial inventory avoids exact/case-folded collision');
        is_deeply(identity_plan($prepared, $all->{reserved_names}), $safe, 'allocation deterministic');
        my $ir = $lowerer->build_module($actor);
        compare_parent($prepared, $ir);
        my ($dt) = grep {$_->{name} eq 'main_trigger_fanin'} @{$ir->{dt_blocks}};
        my ($view) = grep {($_->{source_kind}//'') eq 'rule_trigger_payload_fanin'} @{$dt->{assignments}};
        my ($capture) = grep {($_->{source_kind}//'') eq 'rule_trigger_payload_capture'} @{$dt->{assignments}};
        my ($held) = grep {($_->{source_kind}//'') eq 'rule_trigger_payload_held_view'} @{$dt->{assignments}};
        my $visible = "(& (state_active main_idle_0) ${rule}_main)";
        is_deeply($view->{guard}, {expr=>$visible}, 'payload is visible only during the requesting initial state');
        is_deeply($capture, {lhs=>'isf_snapshot_main_payload',rhs=>$helper,op=>'<-',
            source_kind=>'rule_trigger_payload_capture',guard=>{expr=>"(& (state_active main_idle_0) ${rule}_main main_start)"}},
            'independent witness captures the requesting value only at accepted entry');
        is_deeply($held, {lhs=>'payload',rhs=>'isf_snapshot_main_payload',op=>'=',
            source_kind=>'rule_trigger_payload_held_view',guard=>{expr=>"(! $visible)"}},
            'independent witness retains the accepted value outside the request window');
        is_deeply($actor, $before, 'preparation preserves source');
    }
};

subtest 'generated spawn do and rule handoffs use the actual producers' => sub {
    for my $kind (qw(spawn do trigger)) {
        my $activation = $kind eq 'spawn'
            ? '(spawn worker as job (bind (input data din))) (await_all done)'
            : $kind eq 'do' ? '(do worker (params (N 3)) (bind (input data din)))' : '(wait 1)';
        my $rule = $kind eq 'trigger'
            ? '(rule launch fire (trigger worker (params (N 3)) (bind (input data din))))' : '';
        my $actor = parse(<<"ISF");
(actor handoff_reservations (clock clk) (reset rst_n)
  (interface (input fire) (input din (width 4)) (output bus_value (width 4)) (output done))
  (drive (publish value) (bus_value value))
  (transaction main (on fire) $activation (complete done))
  (transaction worker (ports (input data (width 4))) (params (N 2)) (drive publish data))
  $rule)
ISF
        my $before = dclone($actor);
        my $prepared = $lowerer->prepare_formal_source($actor);
        my $p = $prepared->{parent_activation_products};
        my $found = inventory($p);
        is(scalar @{$p->{spawn_instances}}, 1, "$kind actual instance retained");
        my $instance = $p->{spawn_instances}[0];
        is($instance->{activation_kind} // 'spawn', $kind, "$kind kind retained");
        ok(@{$instance->{drive_handoffs}}, "$kind child shared-drive handoff retained");
        for my $port (@{$p->{ports}}) {
            ok($found->{reserved_names}{$port->{name}}, "$kind actual port $port->{name} reserved");
        }
        for my $role (qw(activation_start_handoff activation_done_handoff transaction_port_binding drive_request drive_payload)) {
            ok(grep({$p->{storage_roles}{$_} eq $role} keys %{$p->{storage_roles}}), "$kind producer exercises $role");
        }
        ok(!exists $p->{counters}{publish_value}, 'child-only drive has no invented local payload source');
        compare_parent($prepared, $lowerer->build_module($actor));
        my $permuted = dclone($actor);
        @{$permuted->{transactions}} = reverse @{$permuted->{transactions}};
        my $again = $lowerer->prepare_formal_source($permuted);
        is_deeply(inventory($again->{parent_activation_products})->{reserved_names}, $found->{reserved_names},
            'declaration permutation preserves parent reservation membership');
        is_deeply($actor, $before, 'registration cannot mutate original source');
        is_deeply($prepared->{actor}, $before, 'registration cannot mutate prepared source');
        if ($kind ne 'trigger') {
            my $raw = $prepared->{transaction_products}{main}{spawn_refs}[0]{port_bindings}[0];
            is($raw->{port}, 'data', 'raw transaction binding survives destructive registration');
            ok(!exists $raw->{parent_port}, 'raw product remains source binding, not registered metadata');
        }
        $instance->{port_bindings}[0]{child_port} = 'changed';
        is_deeply($prepared->{actor}, $before, 'returned handoff metadata is detached');
    }
};

subtest 'real rule bank producers and a conflicting parent remain separate' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_file('isf/fifo_data_path.isf');
    my $prepared = $lowerer->prepare_formal_source($actor);
    compare_parent($prepared, $lowerer->build_module($actor));
    my $products = $prepared->{parent_activation_products};
    ok(@{$products->{bank_accesses}}, 'rule bank access fixture exercises bank producer');
    my $found = inventory($products);
    for my $access (@{$products->{bank_accesses}}) {
        ok($found->{reserved_names}{$_}, "actual scalarized bank entry $_ reserved") for @{$access->{scalar_entries}};
    }
    my $shadow = parse(<<'ISF');
(actor shadow (clock clk) (reset rst_n)
  (interface (input fire) (input din (width 4)) (output done))
  (storage (var payload (width 8)))
  (transaction main (ports (input payload (width 4))) (on main_start) (wait 1) (complete done))
  (rule launch fire (trigger main (bind (input payload din)))))
ISF
    my $partial = $lowerer->prepare_formal_source($shadow);
    ok(inventory($partial->{parent_activation_products})->{reserved_names}{launch_main_payload}, 'rule names available without conflicting parent merge');
    my $ok = eval {$lowerer->build_module($shadow); 1};
    ok(!$ok, 'production still refuses conflicting merge');
    like($@, qr/signal width.*conflicts across transactions/, 'existing width refusal retained');
};
subtest 'invalid later producer inputs still fail closed' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_file('isf/fifo_data_path.isf');
    my ($rule) = grep {grep {$_->[0] eq 'store'} @{$_->{actions}}} @{$actor->{rules}};
    my ($store) = grep {$_->[0] eq 'store'} @{$rule->{actions}};
    $store->[1] = 'missing_bank';
    my $ok = eval {$lowerer->prepare_formal_source($actor); 1};
    ok(!$ok, 'bad rule bank cannot produce a reservation result');
    like($@, qr/unknown actor-owned bank 'missing_bank'/, 'canonical bank producer diagnostic retained');
};
done_testing;
