#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use lib 'perl';
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::PreparedFormalReservations;
use FSM::Scheduler::ISF::FormalReservationInventory;
use FSM::Scheduler::ISF::FormalIdentityPlan;

my $lowerer = FSM::Scheduler::ISF::LoweringIR->new;
sub prepare {
    my ($source, $path) = @_;
    my $actor = FSM::Adapter::ISF->new->parse_source($source, $path // 'prepared_reservations.isf');
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::LoweringIR::build_module = sub {die "unexpected executable parent merge\n"};
    return $lowerer->prepare_formal_source($actor);
}
sub collect {FSM::Scheduler::ISF::PreparedFormalReservations->collect($_[0])}
sub rejected {
    my ($prepared, $pattern, $label) = @_;
    my $before = dclone($prepared);
    my $ok = eval {collect($prepared); 1};
    ok(!$ok, "$label rejected");
    like($@, $pattern, "$label has a focused diagnostic");
    is_deeply($prepared, $before, "$label validation does not mutate input");
}
my $simple = prepare(<<'ISF');
(actor checked_reservations (clock clk) (reset rst_n)
 (interface (input start) (input data (width 4)) (output result (width 4)) (output done))
 (storage (var value_reg (width 8)))
 (drive (isf_port_main payload) (result payload))
 (transaction main (ports (input payload (width 4)) (input value_reg (width 4)))
  (on start) (set payload data) (drive isf_port_main payload) (wait value_reg) (complete done)))
ISF

subtest 'checked inputs retain complete conservative product provenance without parent execution' => sub {
    my $before = dclone($simple);
    my $result = collect($simple);
    is($result->{model}, 'isf_prepared_formal_reservations_v1', 'explicit checked model');
    my $partial = FSM::Scheduler::ISF::FormalReservationInventory->collect({
        map {$_ => $simple->{$_}} grep {$_ eq 'actor' || /products$/ || $_ eq 'domain_partition'} keys %$simple});
    is_deeply($result->{reserved_names}, $partial->{reserved_names}, 'all previously qualified products are retained');
    is_deeply($result->{origins}, $partial->{origins}, 'structural provenance is preserved');
    is_deeply([map {$_->{identity}} @{$result->{scopes}}], [['actor_module', 'checked_reservations', 'parent']],
        'ordinary actor has one explicit parent scope');
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($simple->{actor},
        generated_children => $simple->{generated_children}, reserved_names => $result->{reserved_names});
    isnt(lc($plan->{formals}{main}{payload}{physical_name}), 'isf_port_main_payload', 'actual drive helper candidate remains reserved');
    my %permuted = map {$_ => $simple->{$_}} reverse sort keys %$simple;
    is_deeply(collect(\%permuted), $result, 'input hash insertion order cannot affect output');
    $result->{scopes}[0]{reserved_names}{mutated} = 1;
    ok(!$result->{reserved_names}{mutated}, 'scope and union snapshots are independent');
    is_deeply($simple, $before, 'collection preserves source preparation');
};

subtest 'every top-level category is required even when empty' => sub {
    for my $field (sort keys %$simple) {
        my $bad = dclone($simple); delete $bad->{$field};
        rejected($bad, qr/incomplete preparation.*missing: \Q$field\E/, "missing $field");
        $bad = dclone($simple); $bad->{$field} = 'wrong shape';
        rejected($bad, qr/malformed preparation field '\Q$field\E'/, "malformed $field");
    }
    my $bad = dclone($simple); $bad->{new_producer_products} = {};
    rejected($bad, qr/incomplete preparation.*unexpected: new_producer_products/, 'unknown producer must be classified');
    $bad = dclone($simple); delete $bad->{transaction_products}{main};
    rejected($bad, qr/incomplete transaction products.*main/, 'missing live transaction producer');
    $bad = dclone($simple); $bad->{transactions}{ghost} = {};
    rejected($bad, qr/incomplete transaction contexts.*ghost/, 'unknown context');
    $bad = dclone($simple); $bad->{generated_children}{ghost} = 1;
    rejected($bad, qr/unknown generated_children membership/, 'unknown generated child');
    $bad = dclone($simple); $bad->{domain_partition} = {kind => 'future_partition'};
    rejected($bad, qr/unknown domain partition kind/, 'unknown partition');
    $bad = dclone($simple); $bad->{reusable_child_products}{unclassified} = {};
    rejected($bad, qr/incomplete reusable children/, 'unclassified reusable product');
    $bad = dclone($simple); $bad->{actor_context}{cycle} = $bad;
    my $ok = eval {collect($bad); 1};
    ok(!$ok, 'cyclic preparation rejected before recursive validation');
    like($@, qr/has a cycle/, 'cycle diagnostic retained');
};

my $domains = prepare(<<'ISF');
(actor scoped_reservations
 (clock-domains (domain core (clock clk) (reset rst_n) :default)
                (domain aux (clock aux_clk) (reset aux_rst_n)))
 (interface (input start) (output done) (output local_seen) (output aux_seen (domain aux)))
 (crossings (activation remote (from core) (to aux)))
 (transaction worker (wait 1) (complete local_seen))
 (transaction parent (on start) (spawn worker as job) (await_all done) (do remote) (complete done))
 (transaction remote (domain aux) (wait 2) (complete aux_seen)))
ISF
subtest 'actual independent domains and child modules keep separate typed scopes' => sub {
    my $result = collect($domains);
    is_deeply([map {$_->{identity}} @{$result->{scopes}}], [
        ['actor_domain', 'scoped_reservations', 'aux', 'parent'],
        ['actor_domain', 'scoped_reservations', 'core', 'parent'],
        ['actor_domain', 'scoped_reservations', 'core', 'child', 'worker'],
    ], 'monolithic preparation is not mislabeled as an emitted module');
    my ($aux, $core, $child) = @{$result->{scopes}};
    ok($core->{reserved_names}{remote_start_ready}, 'caller scope contains injected ready port');
    ok(!$aux->{reserved_names}{remote_start_ready}, 'caller helper does not leak to sibling scope');
    ok($aux->{reserved_names}{remote_idle_ext}, 'callee scope contains external idle state');
    ok(!$child->{reserved_names}{remote_start_ready}, 'child retains its independent module inventory');
    for my $mutation (
        [sub {delete $_[0]{domain_source_products}{aux}}, qr/incomplete domain products/, 'missing domain'],
        [sub {$_[0]{domain_source_products}{aux}{identity}[2] = 'core'}, qr/mismatched domain identity/, 'wrong domain owner'],
        [sub {delete $_[0]{domain_source_products}{aux}{preparation}{actor}}, qr/incomplete preparation/, 'missing nested actor'],
        [sub {delete $_[0]{domain_source_products}{core}{preparation}{generated_child_products}{worker}}, qr/incomplete generated children/, 'missing child module'],
        [sub {delete $_[0]{domain_source_products}{core}{preparation}{parent_completion_products}}, qr/incomplete preparation/, 'missing nested producer'],
        [sub {pop @{$_[0]{domain_partition}{domains}}; delete $_[0]{domain_source_products}{aux}}, qr/incomplete source domain membership/, 'erased domain in both product maps'],
        [sub {$_[0]{domain_partition}{kind} = 'single_domain'}, qr/mismatched domain partition kind/, 'wrong partition realization'],
        [sub {$_[0]{domain_source_products}{core}{preparation}{generated_child_products}{worker} = {}}, qr/malformed child scope/, 'erased child IR'],
        [sub {$_[0]{domain_partition} = undef; $_[0]{domain_source_products} = {}}, qr/missing the source domain partition/, 'erased partition'],
    ) {
        my $bad = dclone($domains); $mutation->[0]->($bad); rejected($bad, $mutation->[1], $mutation->[2]);
    }
};

subtest 'reusable children and static-zero exclusions follow actual preparation' => sub {
    open my $fh, '<', 'isf/fifo_library_use.isf' or die $!;
    my $source = do {local $/; <$fh>}; close $fh or die $!;
    my $p = prepare($source, 'isf/fifo_library_use.isf');
    my $r = collect($p);
    is_deeply([map {$_->{identity}[-1]} grep {$_->{identity}[-2] eq 'child'} @{$r->{scopes}}],
        [sort keys %{$p->{reusable_child_products}{children}}], 'actual library modules supply child scopes');
    my $pruned = prepare('(actor pruned (transaction main (repeat 0 (spawn worker as job)) (wait 1)) (transaction worker (wait 1)))');
    ok(keys %{$pruned->{pruned_transactions}}, 'real static-zero producer exclusion exercised');
    ok(collect($pruned), 'pruned targets do not require live context/products');
    my $single = prepare('(actor single (clock-domains (domain core (clock clk) (reset rst_n) :default)) (transaction main (wait 1)))');
    is_deeply([map {$_->{identity}} @{collect($single)->{scopes}}], [['actor_module', 'single', 'parent']],
        'single declared domain keeps one module and no fabricated domain products');
};

done_testing();
