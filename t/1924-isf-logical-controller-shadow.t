#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LogicalControllers;

my $model_class = 'FSM::Scheduler::ISF::LogicalControllers';
for my $source (sort glob 't/data/logical-controller-shadow/*.isf') {
    subtest $source => sub {
        my $actor = FSM::Adapter::ISF->new->parse_file($source);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $ir = $scheduler->{ir}->build_module($actor);
        qualify($ir, $actor, $scheduler);
        for my $child (sort keys %{$ir->{children}}) {
            qualify($ir->{children}{$child}, $actor, $scheduler);
        }
        if (($ir->{domain_partition}{kind} // '') eq 'multi_domain') {
            for my $r (@{$scheduler->_multi_domain_realizations($actor, $ir->{domain_partition})}) {
                my $domain_actor = FSM::Scheduler::ISF::_domain_actor_for_scheduled_artifact(
                    $actor, $r->{domain}, $ir->{domain_partition}{default_domain});
                qualify($r->{ir}, $domain_actor, $scheduler);
                for my $c (@{$r->{ir}{logical_controllers}{controllers}}) {
                    is($c->{domain}, $r->{domain}{name}, 'realized domain retained even for implicit default');
                    is($c->{clock}, $r->{domain}{clock}, 'realized clock');
                    is_deeply($c->{reset}, $r->{domain}{reset}, 'realized reset');
                }
            }
        }
    };
}

subtest 'explicit owners do not depend on state name spelling' => sub {
    my $actor = {actor_name => 'm', clock => 'clk', transactions => [map {{name => $_}} qw(a a_wait_0)]};
    my $ir = {actor_name => 'm', states => [
        {name => 'a_wait_0_idle_0', transaction => 'a', kind => 'entry', transitions => [{target => 'arbitrary'}]},
        {name => 'arbitrary', transaction => 'a', kind => 'terminal', transitions => []},
        {name => 'a_idle_0', transaction => 'a_wait_0', kind => 'sequential', transitions => [{target => 'a_idle_0'}]},
    ]};
    my $m = $model_class->assert_valid($ir, $actor);
    is_deeply([map {$_->{identity}} @{$m->{controllers}}],
        [['m', undef, 'a'], ['m', undef, 'a_wait_0']], 'structured identities cannot alias through prefix splitting');
    is_deeply([map {$_->{initial_state}} @{$m->{controllers}}],
        ['a_wait_0_idle_0', 'a_idle_0'], 'each controller keeps its own first state');
    is_deeply($m->{controllers}[1]{entries}, [], 'free-running body does not acquire entry');
    ok(!defined($m->{controllers}[0]{reset}), 'no reset invented');
    for my $case (
        ['missing owner', sub {delete $_[0]{states}[0]{transaction}}, qr/no declared transaction owner/],
        ['unknown owner', sub {$_[0]{states}[0]{transaction} = 'absent'}, qr/no declared transaction owner/],
        ['reference owner', sub {$_[0]{states}[0]{transaction} = []}, qr/no declared transaction owner/],
        ['duplicate state', sub {push @{$_[0]{states}}, dclone($_[0]{states}[0])}, qr/duplicate membership/],
        ['missing target', sub {$_[0]{states}[0]{transitions}[0]{target} = 'missing'}, qr/no owned target/],
        ['cross-owner edge', sub {$_[0]{states}[0]{transitions}[0]{target} = 'a_idle_0'}, qr/crosses transaction ownership/],
    ) {
        my $bad = dclone($ir);$case->[1]->($bad);
        eval {$model_class->assert_valid($bad, $actor)};
        like($@, $case->[2], "$case->[0] rejected by explicit qualification gate");
    }
};

subtest 'point predicates, implicit domain and terminal hold keep their owners' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_source(<<'ISF', 'shadow_points.isf');
(actor shadow_points
 (clock clk) (reset rst_n)
 (interface (input start) (input ack) (output done))
 (transaction main (on start) (point armed)
  (assert (=> (at armed) (within ack 3))) (await_all done)))
ISF
    my $scheduler = FSM::Scheduler::ISF->new;
    my $ir = $scheduler->{ir}->build_module($actor);
    qualify($ir, $actor, $scheduler);
    my ($point) = grep {defined $_->{point_name}} @{$ir->{states}};
    is($ir->{logical_controllers}{state_owner}{$point->{name}}, 'main', 'point belongs to its logical controller');
    ok((grep {$_->{lhs} eq "$point->{name}_active"} @{$point->{assignments}}), 'point-active assignment remains state-owned');
    my ($join) = grep {$_->{kind} eq 'sync_all'} @{$ir->{states}};
    is_deeply($join->{transitions}, [{target => $join->{name}}], 'terminal hold remains a real owned self-edge');

    $actor = FSM::Adapter::ISF->new->parse_file('t/data/logical-controller-shadow/crossing.isf');
    delete $actor->{transactions}[0]{domain};
    $ir = $scheduler->{ir}->build_module($actor);
    for my $r (@{$scheduler->_multi_domain_realizations($actor, $ir->{domain_partition})}) {
        my ($c) = @{$r->{ir}{logical_controllers}{controllers}};
        is($c->{domain}, $r->{domain}{name}, 'implicit source domain survives concrete realization');
    }
};

done_testing;

sub qualify {
    my ($ir, $actor, $scheduler) = @_;
    my $before = dclone($ir);
    my $model = $model_class->assert_valid($ir, $actor);
    is_deeply($ir, $before, 'inventory does not mutate IR');
    is_deeply($ir->{logical_controllers}, $model, 'attached model is current');
    is_deeply([sort keys %{$model->{state_owner}}], [sort map {$_->{name}} @{$ir->{states}}],
        'complete state membership');
    my %seen;
    for my $c (@{$model->{controllers}}) {
        my @states = grep {$_->{transaction} eq $c->{transaction}} @{$ir->{states}};
        is($c->{initial_state}, $states[0]{name}, 'initial state follows owned order');
        is_deeply($c->{entries}, [map {$_->{name}} grep {$_->{kind} eq 'entry'} @states], 'exact entries');
        $seen{$_->{name}}++ for @{$c->{states}};
    }
    is_deeply(\%seen, {map {$_->{name} => 1} @{$ir->{states}}}, 'membership is unique');
    my $without = dclone($ir);delete $without->{logical_controllers};
    is($scheduler->{fsm_emitter}->emit($ir), $scheduler->{fsm_emitter}->emit($without), 'emitter ignores shadow model');
    is_deeply(JSON::PP::decode_json($scheduler->{json_emitter}->emit($ir)),
        JSON::PP::decode_json($scheduler->{json_emitter}->emit($without)), 'public report ignores shadow model');
}
