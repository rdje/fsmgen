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
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'point_products.isf')}
sub names {FSM::Scheduler::ISF::FormalReservationInventory->collect($_[0])->{reserved_names}}
sub previous_products {
    my ($p) = @_;
    return {map {$_ => $p->{$_}} qw(transaction_products parent_activation_products parent_wiring_products)};
}
sub physical {
    my ($p, $reserved) = @_;
    my $actor = dclone($p->{actor});
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($actor,
        generated_children => $p->{generated_children}, reserved_names => $reserved);
    for my $tx (@{$actor->{transactions}}) {
        next if $p->{pruned_transactions}{$tx->{name}};
        $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
            plan => $plan, %{$p->{transactions}{$tx->{name}}})->{transaction};
    }
    return ($actor, $plan);
}
sub compare {
    my ($p) = @_;
    my $ir = $lowerer->build_module($p->{actor});
    my $products = $p->{parent_point_products};
    is_deeply($products->{states}, $ir->{states}, 'actual parent states after point/default processing');
    is_deeply($products->{immediate_assertions}, $ir->{immediate_assertions}, 'actual resolved checks');
    is_deeply($products->{output_defaults}, $ir->{output_defaults}, 'actual actor output defaults');
    is_deeply({map {$_ => $ir->{counters}{$_}} keys %{$products->{counters}}}, $products->{counters}, 'actual point signal widths');
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
subtest 'actual named point and activation helpers avoid late candidate collisions' => sub {
    for my $owner (qw(isf_port_main ISF_PORT_MAIN)) {
        for my $kind (qw(point activation)) {
            my $formal = $kind eq 'point' ? 'point_1_active' : 'idle_0_active';
            my $entry = $kind eq 'point' ? '(on fire) (point armed)' : '(on fire as armed)';
            my $actor = parse(<<"ISF");
(actor point_products (clock clk) (reset rst_n)
 (interface (input fire) (input ack) (output observed (width 4) (default 0)) (output done))
 (transaction main (ports (input $formal (width 4))) (on fire)
  (set observed $formal) (assert (=> (at armed) ack)))
 (transaction $owner $entry (point unused) (complete done)))
ISF
            my $before = dclone($actor);
            my $p = $lowerer->prepare_formal_source($actor);
            compare($p);
            my $point = $p->{parent_point_products};
            my @helpers = keys %{$point->{counters}};
            is(scalar @helpers, 1, 'only referenced anchor produces an active counter');
            my $helper = $helpers[0];
            my $old = names(previous_products($p));
            ok(!$old->{$helper}, 'real helper absent from earlier product inventory');
            my (undef, $old_plan) = physical($p, $old);
            is(lc($old_plan->{formals}{main}{$formal}{physical_name}), lc($helper), 'old proposed formal aliases exact/case-folded helper');
            my $reserved = names({%{previous_products($p)}, points => $point});
            my ($projected, $plan) = physical($p, $reserved);
            my $private = $plan->{formals}{main}{$formal}{physical_name};
            isnt(lc($private), lc($helper), 'actual helper reservation prevents alias');
            my $after = $lowerer->prepare_formal_source($projected);
            is_deeply($after->{parent_point_products}{counters}, $point->{counters}, 'point helper names/widths stable after physical projection');
            is_deeply($after->{parent_point_products}{point_bindings}, $point->{point_bindings}, 'source point identities remain stable');
            is_deeply($after->{parent_point_products}{immediate_assertions}, $point->{immediate_assertions}, 'source anchor keeps actual physical helper');
            compare($after);
            strict_carrier($projected, "${owner}_${kind}");
            my $ir = $lowerer->build_module($projected);
            is($ir->{counters}{$private}, 4, 'private formal width remains distinct');
            is($ir->{counters}{$helper}, 1, 'actual active helper stays one bit');
            like($p->{transaction_products}{main}{immediate_assertions}[0]{condition}, qr/\(at armed\)/, 'earlier assertion remains unresolved');
            ok(!(grep {($_->{source_kind}//'') eq 'point_active'} map {@{$_->{assignments}}} @{$p->{parent_wiring_products}{states}}), 'earlier wiring has no added point assignments');
            ok(!(grep {($_->{source_kind}//'') eq 'interface_output_default'} map {@{$_->{assignments}}} @{$p->{parent_wiring_products}{states}}), 'earlier wiring has no added output defaults');
            my $prior = dclone(previous_products($p));
            $point->{point_bindings}{armed} = 'changed';
            $point->{states}[0]{name} = 'changed';
            $point->{immediate_assertions}[0]{condition} = 'changed';
            is_deeply(previous_products($p), $prior, 'returned post-wiring products independently detached');
            is_deeply($p->{actor}, $before, 'prepared source remains unchanged');
            is_deeply($actor, $before, 'authored source remains unchanged');
            my $permuted = dclone($actor);
            @{$permuted->{transactions}} = reverse @{$permuted->{transactions}};
            my $q = $lowerer->prepare_formal_source($permuted);
            is_deeply($q->{parent_point_products}{counters}, $after->{parent_point_products}{counters}, 'permutation preserves actual generated helpers');
            is_deeply($q->{parent_point_products}{point_bindings}, $after->{parent_point_products}{point_bindings}, 'permutation preserves source anchor bindings');
        }
    }
};

subtest 'output defaults retain actor ownership through raw formal shadows' => sub {
    my $actor = parse(<<'ISF');
(actor defaults (clock clk) (reset rst_n)
 (interface (input fire) (output ready (width 8) (default 19)) (output observed (width 4)))
 (transaction main (ports (input ready (width 4))) (on fire) (set observed ready)))
ISF
    my $p = $lowerer->prepare_formal_source($actor);
    my ($entry) = grep {$_->{kind} eq 'entry'} @{$p->{parent_point_products}{states}};
    is_deeply($entry->{assignments}[0], {lhs => 'ready', rhs => 19, op => '<-', source_kind => 'interface_output_default'}, 'default targets actual actor output');
    eval {$lowerer->build_module($actor)};
    like($@, qr/collides with an actor interface port/, 'raw formal/output alias remains refused');
    my ($projected, $plan) = physical($p, names({%{previous_products($p)}, points => $p->{parent_point_products}}));
    my $q = $lowerer->prepare_formal_source($projected);
    compare($q);
    ($entry) = grep {$_->{kind} eq 'entry'} @{$q->{parent_point_products}{states}};
    is($entry->{assignments}[0]{lhs}, 'ready', 'physical projection leaves actor default identity');
    isnt($plan->{formals}{main}{ready}{physical_name}, 'ready', 'formal is a separate identity');
    strict_carrier($projected, 'defaults');
};

subtest 'parent anchor scope excludes generated and pruned children' => sub {
    my $actor = parse(<<'ISF');
(actor child_points (clock clk) (reset rst_n)
 (interface (input fire) (input ack) (output done))
 (transaction main (on fire as armed) (assert (=> (at armed) ack))
  (spawn worker as job) (await_all done) (repeat 0 (spawn pruned as unused)) (complete done))
 (transaction worker (on fire as armed) (assert (=> (at armed) ack)) (wait 1))
 (transaction pruned (assert (at missing))))
ISF
    my $p = $lowerer->prepare_formal_source($actor);
    is_deeply($p->{parent_point_products}{point_bindings}, {armed => 'main_idle_0'}, 'generated same-name anchor belongs to separate scope');
    is(scalar @{$p->{parent_point_products}{immediate_assertions}}, 1, 'only direct assertion retained');
    ok($p->{generated_children}{worker}, 'worker is generated');
    ok($p->{pruned_transactions}{pruned}, 'invalid dead child anchor remains pruned');
    like($p->{transaction_products}{worker}{immediate_assertions}[0]{condition}, qr/\(at armed\)/, 'child point resolution remains child producer obligation');
};

subtest 'unknown and duplicate anchors fail at canonical source checks' => sub {
    my $unknown = parse('(actor bad (interface (input fire)) (transaction main (on fire) (assert (at missing))))');
    eval {$lowerer->prepare_formal_source($unknown)};
    like($@, qr/\(at missing\) references unknown point\/activation name/, 'unknown direct point refused by resolver');
    my $duplicate = parse('(actor bad (interface (input fire)) (transaction main (on fire as same) (point same)))');
    eval {$lowerer->prepare_formal_source($duplicate)};
    like($@, qr/duplicate point\/activation name/, 'duplicate point remains refused during lowering');
};
done_testing;
