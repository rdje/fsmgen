#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalClauseResolver;
use FSM::Scheduler::ISF::FormalReservationInventory;

my $lowerer = FSM::Scheduler::ISF::LoweringIR->new;
my $work = tempdir(CLEANUP => 1);
sub parse { FSM::Adapter::ISF->new->parse_source($_[0], 'reservations.isf') }
sub inventory { FSM::Scheduler::ISF::FormalReservationInventory->collect($_[0]) }
sub identity_plan {
    my ($prepared, $reserved) = @_;
    FSM::Scheduler::ISF::FormalIdentityPlan->build($prepared->{actor},
        generated_children => $prepared->{generated_children}, reserved_names => $reserved);
}
my $source = <<'ISF';
(actor reservations (clock clk) (reset (rst_n async active_low))
  (interface (input start) (input din (width 4)) (output bus_value (width 4)) (output done))
  (drive (isf_port_main payload) (bus_value payload))
  (transaction main (ports (input payload (width 4)))
    (on start) (sample din as payload) (drive isf_port_main payload) (complete done)))
ISF
subtest 'actual drive producer reserves the colliding formal candidate' => sub {
    for my $drive ('isf_port_main', 'ISF_PORT_MAIN') {
        (my $text = $source) =~ s/isf_port_main/$drive/g;
        my $actor = parse($text);
        my $before = dclone($actor);
        my $prepared = $lowerer->prepare_formal_source($actor);
        my $products = $prepared->{transaction_products};
        my $before_products = dclone($products);
        my $found = inventory($products);
        my $unsafe = identity_plan($prepared, {})->{formals}{main}{payload}{physical_name};
        my $ir = $lowerer->build_module($actor);
        my $helper = "${drive}_payload";
        is(lc($unsafe), lc($helper), 'source-only allocation collides under portable case folding');
        is($ir->{storage_roles}{$helper}, 'drive_payload', 'independent complete IR confirms physical helper role');
        ok($found->{reserved_names}{$helper}, 'actual transaction assignment exposes helper before parent merge');
        ok(grep({$_->{path} =~ m{^/main/states/\d+/assignments/\d+/lhs$} && $_->{position} eq 'value'}
            @{$found->{origins}{$helper}}), 'reservation points to actual assignment target');
        my $safe = identity_plan($prepared, $found->{reserved_names});
        my $physical = $safe->{formals}{main}{payload}{physical_name};
        isnt(lc($physical), lc($helper), 'actual product reservation avoids collision');
        is_deeply(identity_plan($prepared, $found->{reserved_names}), $safe, 'repeat allocation deterministic');
        my $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($prepared->{actor}{transactions}[0],
            plan => $safe, %{$prepared->{transactions}{main}})->{transaction};
        my $rewritten = dclone($actor);
        $rewritten->{transactions}[0] = $tx;
        my $fsm = FSM::Scheduler::ISF->new->lower($rewritten)->{files}{'reservations.fsm'};
        like($fsm, qr/\(\Q$helper\E \Q$physical\E\)/, 'drive receives distinct renamed formal');
        open my $fh, '>', "$work/$drive.fsm" or die $!;
        print {$fh} $fsm;
        close $fh or die $!;
        my $result = FSM::Test::SourceQueryRunner::_capture(
            [$^X, 'bin/fsmgen', '--strict', '--check', '--json', "$work/$drive.fsm"], '');
        is($result->{exit_code}, 0, 'rewritten drive carrier passes strict replay') or diag($result->{stdout}, $result->{stderr});
        is_deeply($actor, $before, 'preparation and allocation preserve original source');
        is_deeply($products, $before_products, 'inventory preserves transaction products');
        $products->{main}{states}[0]{transaction} = 'changed';
        is_deeply($prepared->{actor}, $before, 'mutating retained product cannot mutate prepared source');
    }
};

subtest 'actual transaction producers retained without parent merge' => sub {
    my $actor = parse(<<'ISF');
(actor producers (clock clk) (reset (rst_n async active_low))
  (interface (input start) (input ack) (input din (width 4)) (output done) (output result (width 4)))
  (transaction main (ports (input count (width 4))) (on start)
    (local scratch (width 4) (reset 2))
    (sample din as snapshot) (set scratch snapshot) (wait count)
    (repeat 2 (set scratch din))
    (assert (monitor (within ack 3)))
    (do local_worker) (spawn worker as job (bind (input data din)))
    (await_all done) (complete done))
  (transaction local_worker (set result din))
  (transaction worker (ports (input data (width 4))) (wait 1)))
ISF
    my $prepared = $lowerer->prepare_formal_source($actor);
    my $products = $prepared->{transaction_products};
    my $main = $products->{main};
    is_deeply([sort keys %$main], [sort qw(states counters dt_blocks local_do_refs spawn_refs
        temporal_contracts signal_widths storage_roles bank_accesses reset_values immediate_assertions)],
        'all returned producer categories retained, including empty categories');
    my $found = inventory($products);
    for my $role (qw(dynamic_wait_counter repeat_counter temporal_contract_monitor)) {
        my @names = grep {$main->{storage_roles}{$_} eq $role} keys %{$main->{storage_roles}};
        ok(@names, "actual $role producer exercised");
        ok($found->{reserved_names}{$_}, "$role identifier retained: $_") for @names;
    }
    ok($found->{reserved_names}{snapshot}, 'pending sample target retained in actual state assignment');
    is($main->{reset_values}{scratch}, 2, 'reset value retained');
    ok(@{$main->{dt_blocks}} && @{$main->{immediate_assertions}}, 'monitor DT and assertion retained');
    is($main->{local_do_refs}[0]{child}, 'local_worker', 'actual local call reference retained');
    is($main->{spawn_refs}[0]{instance}, 'job', 'actual generated call reference retained');
    ok(exists $products->{worker}, 'generated child products independently retained');
    $main->{signal_widths}{din} = 99;
    isnt($products->{worker}{signal_widths}{din}, 99, 'transaction product snapshots are independent');
    my $shadow = parse(<<'ISF');
(actor shadow (storage (var value (width 8)))
  (transaction main (ports (input value (width 4))) (wait 1)))
ISF
    my $partial = $lowerer->prepare_formal_source($shadow);
    ok(inventory($partial->{transaction_products})->{reserved_names}{value}, 'inventory does not require conflicting parent merge');
    my $ok = eval {$lowerer->build_module($shadow); 1};
    ok(!$ok, 'production still refuses conflicting physical merge');
};

subtest 'data-only inventory has deterministic structural provenance' => sub {
    my $shared = ['(+ physical_value physical_value)'];
    my $products = {'a/b~c' => $shared, z => $shared, absent => undef};
    my $found = inventory($products);
    is_deeply($found->{origins}{physical_value}, [
        {path => '/a~1b~0c/0', position => 'value'}, {path => '/z/0', position => 'value'}],
        'escaped JSON pointers distinguish shared acyclic paths and deduplicate one scalar');
    ok($found->{reserved_names}{a} && $found->{reserved_names}{b} && $found->{reserved_names}{c}, 'hash key tokens also reserve conservatively');
    my %permuted;
    # Construct the same mapping in a different insertion order.
    %permuted = map {$_ => $products->{$_}} reverse sort keys %$products;
    is_deeply(inventory(\%permuted), $found, 'hash insertion order cannot change provenance');
    my $cycle = {};
    $cycle->{self} = $cycle;
    for my $case ([[], qr/product hash/], [{bad => \1}, qr/unsupported reference/],
        [{bad => bless({}, 'UnsupportedProduct')}, qr/unsupported reference/], [$cycle, qr/cycle/]) {
        my $ok = eval {inventory($case->[0]); 1};
        ok(!$ok, 'malformed/cyclic product fails closed');
        like($@, $case->[1], 'specific product diagnostic');
    }
    delete $cycle->{self};
};
done_testing;
