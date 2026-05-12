#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Adapter::ISF;

subtest 'parse full_featured.isf — all ISF constructs' => sub {
    my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'full_featured.isf');
    ok(-f $isf_file, 'fixture exists');

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);

    # Actor identity
    is($actor->{actor_name}, 'full_featured', 'actor name');
    is($actor->{clock},      'clk',           'clock');
    is_deeply($actor->{reset}, {
        name => 'rst_n', kind => 'async', polarity => 'active_low'
    }, 'reset');
    is($actor->{watchdog}, 32768, 'watchdog');

    # Interface
    my $iface = $actor->{interface};
    is(scalar(@{$iface->{inputs}}),  4, 'input count');
    is(scalar(@{$iface->{outputs}}), 4, 'output count');

    my @in_names  = sort map { $_->{name} } @{$iface->{inputs}};
    my @out_names = sort map { $_->{name} } @{$iface->{outputs}};
    is_deeply(\@in_names,  [qw(addr ready start wdata)],  'input names');
    is_deeply(\@out_names, [qw(done err rdata valid)],     'output names');

    # Width check
    my ($addr) = grep { $_->{name} eq 'addr' } @{$iface->{inputs}};
    is($addr->{width}, 32, 'addr width 32');

    # Handshakes deprecated — no handshake declarations
    ok(!keys %{$actor->{handshakes}}, 'no handshakes in actor');

    # Transactions
    my $txs = $actor->{transactions};
    is(scalar(@$txs), 3, 'three transactions');
    my %tx_by_name = map { $_->{name} => $_ } @$txs;

    # main_transfer
    my $main = $tx_by_name{main_transfer};
    ok($main, 'has main_transfer');
    my @main_clauses = @{$main->{clauses}};
    ok(@main_clauses >= 6, 'main_transfer has clauses');

    # Check (on cmd ...)
    is($main_clauses[0][0], 'on', 'first clause: on');
    is($main_clauses[0][1], 'start', 'on port name');

    # Check latency
    my $lat = $main_clauses[-1];
    is($lat->[0], 'latency', 'last clause: latency');
    is_deeply($lat->[1], ['min', '1'],  'latency min');
    is_deeply($lat->[2], ['max', '64'], 'latency max');

    # chained — uses (do ...)
    my $chained = $tx_by_name{chained};
    ok($chained, 'has chained transaction');
    my @ch_clauses = @{$chained->{clauses}};
    my @do_clauses = grep { ref($_) eq 'ARRAY' && $_->[0] eq 'do' } @ch_clauses;
    is(scalar(@do_clauses), 2, 'chained has two do clauses');

    # parallel_work — uses (spawn ...) with params and named instances
    my $par = $tx_by_name{parallel_work};
    ok($par, 'has parallel_work transaction');
    my @par_clauses = @{$par->{clauses}};
    my @spawns = grep { ref($_) eq 'ARRAY' && $_->[0] eq 'spawn' } @par_clauses;
    is(scalar(@spawns), 3, 'three spawn clauses');

    # Named spawn
    my ($named) = grep { $_->[2] eq 'as' } @spawns;
    ok($named, 'has named spawn');
    is($named->[1], 'main_transfer', 'spawned transaction name');
    is($named->[3], 'worker_0', 'named instance');

    # All spawns are named (worker_0, worker_1, worker_2)
    my @named = grep { $_->[2] eq 'as' } @spawns;
    is(scalar(@named), 3, 'three named spawns');

    # await_all
    my ($await_all) = grep { ref($_) eq 'ARRAY' && $_->[0] eq 'await_all' } @par_clauses;
    ok($await_all, 'has await_all');

    # Rules
    my $rules = $actor->{rules};
    is(scalar(@$rules), 3, 'three rules');
    my %rule_by = map { $_->{name} => $_ } @$rules;

    ok($rule_by{always_ready}, 'has always_ready rule');
    ok($rule_by{error_gate},   'has error_gate rule');
    ok($rule_by{high_pri},     'has high_pri rule');

    # always_ready: when, assign, trigger
    my $ar = $rule_by{always_ready};
    is($ar->{when}[0], 'when', 'always_ready has when');
    ok((grep { ref($_) eq 'ARRAY' && $_->[0] eq 'valid' }  @{$ar->{actions}}), 'always_ready has port-value pair');
    ok((grep { ref($_) eq 'ARRAY' && $_->[0] eq 'trigger' } @{$ar->{actions}}), 'always_ready has trigger');

    # error_gate: port-value pairs
    my $eg = $rule_by{error_gate};
    ok((grep { ref($_) eq 'ARRAY' && $_->[0] eq 'valid' }  @{$eg->{actions}}), 'error_gate has valid 1');
    ok((grep { ref($_) eq 'ARRAY' && $_->[0] eq 'err' } @{$eg->{actions}}), 'error_gate has err 1');

    # high_pri: inline priority
    my $hp = $rule_by{high_pri};
    ok((grep { ref($_) eq 'ARRAY' && $_->[0] eq 'priority' } @{$hp->{actions}}), 'high_pri has inline priority');

    # Priorities
    my $prios = $actor->{priorities};
    is(scalar(@$prios), 1, 'one separate priority declaration');

    # Resources
    my $res = $actor->{resources};
    is(scalar(@$res), 2, 'two resources');
    my ($bus) = grep { $_->{name} eq 'shared_bus' } @$res;
    is($bus->{arbiter}, 'priority', 'shared_bus arbiter');
    my ($mem) = grep { $_->{name} eq 'mem_port' } @$res;
    is($mem->{arbiter}, 'round_robin', 'mem_port arbiter');

    # Phases and stages — not present in current fixture
    is(scalar(@{$actor->{phases}}), 0, 'no phases (removed from fixture)');
    is(scalar(@{$actor->{stages}}), 0, 'no stages (removed from fixture)');
};

done_testing();
