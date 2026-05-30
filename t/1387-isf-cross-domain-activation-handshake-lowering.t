#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::Emitter::FSM;

# ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.3
#
# The cross-domain activation handshake-port lowering machinery (consumed by the
# multi-domain partition through `$actor->{external_activations}`). This slice
# builds and verifies the per-domain lowering in isolation; the live multi-domain
# routing (validator acceptance + dual-CDC top wiring) ships in a later slice, so
# a `(crossings (activation ...))` actor must STILL fail closed at `lower()`.

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
}

sub ports_by_name {
    my ($ir) = @_;
    return { map { $_->{name} => $_ } @{$ir->{ports} || []} };
}

subtest 'callee external activation gates the child on start and asserts done' => sub {
    my $actor = parse_source(<<'ISF', 'callee');
(actor dest_domain
  (interface
    (input din (width 8))
    (output result (width 8)))
  (transaction worker
    (sample din as snap)
    (update result snap)
    (complete result)))
ISF
    $actor->{external_activations} = [
        { child => 'worker', role => 'callee', start_signal => 'worker_start', done_signal => 'worker_done' },
    ];

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $ports = ports_by_name($ir);
    is($ports->{worker_start}{direction}, 'input', 'callee promotes the start handshake to an input port');
    is($ports->{worker_done}{direction}, 'output', 'callee promotes the done handshake to an output port');

    my $fsm = FSM::Scheduler::ISF::Emitter::FSM->new()->emit($ir);
    like($fsm, qr/\(worker_idle_ext\b/, 'callee synthesizes a start-gated entry for the body-only transaction');
    like($fsm, qr/worker_idle_ext\s*\(\s*<worker_start/s, 'callee entry waits on the activation start pulse');
    like($fsm, qr/\(worker_done>\s*1\)/, 'callee asserts the activation done handshake at its terminal');
    like($fsm, qr/\(worker_done>[\s\S]*?->\s*worker_idle_ext/, 'callee terminal returns to the start-gated entry');
};

subtest 'caller external activation promotes the do handshake to ports' => sub {
    my $actor = parse_source(<<'ISF', 'caller');
(actor src_domain
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (do worker)
    (complete done)))
ISF
    $actor->{external_activations} = [
        { child => 'worker', role => 'caller', start_signal => 'worker_start', done_signal => 'worker_done' },
    ];

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $ports = ports_by_name($ir);
    is($ports->{worker_start}{direction}, 'output', 'caller promotes the start handshake to an output port');
    is($ports->{worker_done}{direction}, 'input', 'caller promotes the done handshake to an input port');

    my $fsm = FSM::Scheduler::ISF::Emitter::FSM->new()->emit($ir);
    like($fsm, qr/\(worker_start>\s*1\)/, 'caller asserts the activation start handshake from the do-state');
    like($fsm, qr/<worker_done\b/, 'caller blocks on the activation done handshake');

    # The handshake signals must surface exactly once (as ports, not duplicated
    # by a leftover module-internal register).
    my @start_decls = ($fsm =~ /\(worker_start \d+\)/g);
    is(scalar(@start_decls), 1, 'caller declares the start handshake exactly once');
};

subtest 'caller do target absent without an external activation still fails closed' => sub {
    my $actor = parse_source(<<'ISF', 'caller-uncovered');
(actor src_domain_uncovered
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (do worker)
    (complete done)))
ISF
    my $ok = eval { FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor); 1 };
    my $err = $@;
    ok(!$ok, 'a do target that is neither declared nor an external activation is rejected');
    like($err, qr/do target 'worker' is not a declared transaction/, 'rejection names the missing target');
};

subtest 'an activation crossing actor still fails closed at lower (CDC routing pending)' => sub {
    my $actor = parse_source(<<'ISF', 'activation-crossing');
(actor act_pending
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (crossings
    (activation worker (from core) (to bus)))
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
    my $ok = eval { FSM::Scheduler::ISF->new()->lower($actor); 1 };
    my $err = $@;
    ok(!$ok, 'an actor declaring an activation crossing is still rejected at lower');
    like($err, qr/cross-domain activation lowering is not yet supported/, 'rejection states CDC routing is pending');
};

done_testing();
