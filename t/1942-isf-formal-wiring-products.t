#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalClauseResolver;
use FSM::Scheduler::ISF::FormalReservationInventory;

my $scheduler = FSM::Scheduler::ISF->new;
my $lowerer = $scheduler->{ir};
my $work = tempdir(CLEANUP => 1);
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'wiring_products.isf')}
sub inventory {FSM::Scheduler::ISF::FormalReservationInventory->collect($_[0])->{reserved_names}}
sub old_products {
    my ($p) = @_;
    return {transactions => $p->{transaction_products}, activations => $p->{parent_activation_products}};
}
sub qualify {
    my ($actor, $label) = @_;
    my $before = dclone($actor);
    my $p = $lowerer->prepare_formal_source($actor);
    my $ir = $lowerer->build_module($actor);
    my $w = $p->{parent_wiring_products};
    is_deeply($w->{states}, $ir->{states}, "$label actual wired states agree");
    is_deeply($w->{ports}, $ir->{ports}, "$label actual wired ports agree");
    is_deeply({map {$_ => $ir->{counters}{$_}} keys %{$w->{counters}}}, $w->{counters},
        "$label actual added internal handshake counters agree");
    my $names = inventory($w);
    ok($names->{$_->{name}}, "$label real state $_->{name} reserved") for @{$ir->{states}};
    ok($names->{$_->{name}}, "$label real port $_->{name} reserved") for @{$ir->{ports}};
    is_deeply($actor, $before, "$label source untouched");
    is_deeply($p->{actor}, $before, "$label prepared actor untouched");
    my $raw = dclone($p->{transaction_products});
    my $activations = dclone($p->{parent_activation_products});
    $w->{states}[0]{name} = 'changed';
    $w->{ports}[0]{name} = 'changed';
    is_deeply($p->{transaction_products}, $raw, "$label transaction products detached");
    is_deeply($p->{parent_activation_products}, $activations, "$label activation products detached");
    is_deeply($p->{actor}, $before, "$label wiring mutation cannot alter source");
    return $p;
}
sub strict_carrier {
    my ($actor, $label) = @_;
    my $ir = $lowerer->build_module($actor);
    my $path = "$work/$label.fsm";
    open my $fh, '>', $path or die $!;
    print {$fh} $scheduler->{fsm_emitter}->emit($ir);
    close $fh or die $!;
    my $r = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
    is($r->{exit_code}, 0, "$label strict carrier") or diag($r->{stdout}, $r->{stderr});
}

subtest 'local calls preserve actual state wiring and cloned source products' => sub {
    my $actor = parse(<<'ISF');
(actor local_wiring (clock clk) (reset rst_n)
 (interface (input fire) (output done) (output finished))
 (transaction parent (on fire) (do worker) (complete done))
 (transaction worker (on fire) (wait 1) (complete finished)))
ISF
    my $p = qualify($actor, 'local');
    my ($raw) = grep {$_->{kind} eq 'entry'} @{$p->{transaction_products}{worker}{states}};
    is_deeply($raw->{guard}, {port => 'fire'}, 'retained raw entry still has authored guard');
    $p = $lowerer->prepare_formal_source($actor);
    my ($wired) = grep {$_->{kind} eq 'entry' && $_->{transaction} eq 'worker'} @{$p->{parent_wiring_products}{states}};
    is_deeply($wired->{guard}, {port => 'worker_start'}, 'actual callee entry uses local request');
    is_deeply($p->{parent_wiring_products}{counters}, {worker_start => 1, worker_done => 1}, 'actual local handshake additions');
    my $reversed = dclone($actor);
    @{$reversed->{transactions}} = reverse @{$reversed->{transactions}};
    qualify($reversed, 'reversed local');
    is_deeply(inventory($lowerer->prepare_formal_source($reversed)->{parent_wiring_products}),
        inventory($p->{parent_wiring_products}), 'source order preserves wiring reservation membership');
    strict_carrier($actor, 'local');
};

subtest 'actual projected domains retain external ready request and entry products' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_file('t/data/logical-controller-shadow/crossing.isf');
    my $ir = $lowerer->build_module($actor);
    for my $r (@{$scheduler->_multi_domain_realizations($actor, $ir->{domain_partition})}) {
        my $a = FSM::Scheduler::ISF::_domain_actor_for_scheduled_artifact(
            $actor, $r->{domain}, $ir->{domain_partition}{default_domain});
        qualify($a, $r->{domain}{name});
        my $p = $lowerer->prepare_formal_source($a);
        my $old = inventory(old_products($p));
        my $new = inventory($p->{parent_wiring_products});
        my @missing = grep {!$old->{$_}} (
            map({$_->{name}} @{$r->{ir}{states}}), map({$_->{name}} @{$r->{ir}{ports}}));
        ok(@missing, 'realized producer has names absent from old inventory');
        ok($new->{$_}, "previously missing $_ now reserved") for @missing;
        is_deeply($p->{parent_wiring_products}{counters}, {}, 'external promotion leaves no duplicate internal handshake counters');
        strict_carrier($a, $r->{domain}{name});
    }
};

subtest 'late handshake candidate collision is avoided through real products' => sub {
    for my $child (qw(isf_port_main ISF_PORT_MAIN)) {
        my $actor = parse(<<"ISF");
(actor collision_wiring (clock clk) (reset rst_n)
 (interface (input fire) (output observed (width 4)) (output finished))
 (transaction main (ports (input done_ready (width 4))) (on fire) (set observed done_ready))
 (transaction $child (wait 1) (complete finished)))
ISF
        $actor->{external_activations} = [{child => $child, role => 'callee',
            start_signal => "${child}_start", done_signal => "${child}_done"}];
        my $before = dclone($actor);
        my $p = $lowerer->prepare_formal_source($actor);
        my $old = inventory(old_products($p));
        my $old_plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($actor,
            generated_children => $p->{generated_children}, reserved_names => $old);
        my ($ready) = grep {$_->{direction} eq 'input' && $_->{name} ne 'fire' && $_->{name} ne "${child}_start"}
            @{$p->{parent_wiring_products}{ports}};
        ok($ready, 'actual callee producer supplies ready port');
        is(lc($old_plan->{formals}{main}{done_ready}{physical_name}), lc($ready->{name}), 'old partial plan aliases actual ready port');
        ok(!$old->{$ready->{name}}, 'helper genuinely absent from old products');
        my $all = inventory({%{old_products($p)}, wiring => $p->{parent_wiring_products}});
        my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($actor,
            generated_children => $p->{generated_children}, reserved_names => $all);
        my $physical_name = $plan->{formals}{main}{done_ready}{physical_name};
        isnt(lc($physical_name), lc($ready->{name}), 'actual reservation prevents portable name collision');
        my $physical = dclone($actor);
        for my $tx (@{$physical->{transactions}}) {
            $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
                plan => $plan, %{$p->{transactions}{$tx->{name}}})->{transaction};
        }
        my $after = $lowerer->prepare_formal_source($physical);
        is_deeply($after->{parent_wiring_products}{ports}, $p->{parent_wiring_products}{ports}, 'physical formal does not change handshake ports');
        is_deeply([map {$_->{name}} @{$after->{parent_wiring_products}{states}}],
            [map {$_->{name}} @{$p->{parent_wiring_products}{states}}], 'physical formal does not change state identities');
        my $real = $lowerer->build_module($physical);
        is($real->{counters}{$physical_name}, 4, 'projected private formal keeps its width');
        strict_carrier($physical, $child);
        is_deeply($actor, $before, 'projection and wiring preserve original source');
    }
};

subtest 'generated and pruned bodies stay out of parent wiring' => sub {
    my $actor = parse(<<'ISF');
(actor exclusions (clock clk) (reset rst_n)
 (interface (input fire) (output done))
 (transaction main (on fire) (spawn worker as job) (await_all done)
  (repeat 0 (spawn absent as unused)) (complete done))
 (transaction worker (wait 1))
 (transaction absent (local invalid (unknown 1))))
ISF
    my $p = $lowerer->prepare_formal_source($actor);
    ok($p->{generated_children}{worker}, 'live child generated');
    ok($p->{pruned_transactions}{absent}, 'dead child pruned');
    is_deeply([sort keys %{{map {$_->{transaction} => 1} @{$p->{parent_wiring_products}{states}}}}], ['main'],
        'parent wiring contains only retained direct owner states');
};

subtest 'source conflicts and canonical wiring failures remain strict' => sub {
    my $actor = parse(<<'ISF');
(actor raw_conflict (clock clk) (reset rst_n)
 (interface (input fire) (output done) (output finished))
 (storage (var payload (width 8)))
 (transaction parent (ports (input payload (width 4))) (on fire) (do worker) (complete done))
 (transaction worker (on fire) (wait 1) (complete finished)))
ISF
    my $p = $lowerer->prepare_formal_source($actor);
    ok($p->{parent_wiring_products}{counters}{worker_start}, 'actual wiring available before conflicting parent merge');
    eval {$lowerer->build_module($p->{actor})};
    like($@, qr/signal width.*conflicts across transactions/, 'executable width merge still refuses raw alias');
    my $callee = parse('(actor bad (interface (output done)) (transaction worker (wait 1) (complete done)))');
    $callee->{external_activations} = [{child => 'worker', role => 'unknown'}];
    eval {$lowerer->prepare_formal_source($callee)};
    like($@, qr/external activation 'worker' has unknown role 'unknown'/, 'canonical wiring role refusal retained');
    $callee->{external_activations}[0]{role} = 'callee';
    push @{$callee->{interface}{inputs}}, {name => 'worker_done_ready', width => 4};
    eval {$lowerer->prepare_formal_source($callee)};
    like($@, qr/conflict|width/i, 'fixed ready-port width conflict remains a refusal');
};
done_testing;
