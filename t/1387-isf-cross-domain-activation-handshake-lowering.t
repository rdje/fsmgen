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

    # Cross-domain `<start>` routes through an acknowledged-event CDC that
    # re-pulses while `request` is held, so the caller must emit a ONE-CYCLE start
    # request (asserted on entry, then a separate await-on-`<done>` state) rather
    # than holding the level for the whole do.
    my @states = @{$ir->{states}};
    my ($request) = grep { $_->{name} =~ /_do_\d+_req$/ } @states;
    ok($request, 'caller emits a dedicated one-cycle start request state');
    ok(
        (grep { ($_->{lhs} // '') eq 'worker_start' } @{$request->{assignments} || []}),
        'the request state asserts the start handshake',
    );
    ok(
        scalar(@{$request->{transitions} || []}) == 1
            && !$request->{transitions}[0]{condition},
        'the request state falls through unconditionally (start is high for one cycle)',
    );
    my ($await) = grep { ($_->{guard}{port} // '') eq 'worker_done' } @states;
    ok($await, 'caller awaits the done handshake in a separate state');
    ok(
        (!grep { ($_->{lhs} // '') eq 'worker_start' } @{$await->{assignments} || []}),
        'the await state does not re-assert the held start level',
    );
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

subtest 'a covered cross-domain (do) lowers end-to-end through two CDC children' => sub {
    my $actor = parse_source(<<'ISF', 'activation-crossing');
(actor xdom
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
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a covered cross-domain activation lowers') or diag($@);

    is_deeply(
        [sort keys %{$lowered->{files}}],
        [qw(xdom__domain_bus.fsm xdom__domain_core.fsm xdom_top.fsm)],
        'lowering partitions the caller and child into per-domain modules plus a top',
    );

    # SRC (caller) module: await start-ready, then one-cycle start request, then
    # await done.
    my $core = $lowered->{files}{'xdom__domain_core.fsm'};
    like($core, qr/<worker_start_ready\b/, 'caller awaits the start-ready handshake (consumes the start CDC ready)');
    like($core, qr/_do_\d+_req[\s\S]*?\(worker_start>\s*1\)/, 'caller emits the one-cycle start request');
    like($core, qr/<worker_done\b/, 'caller blocks on the done handshake');

    # DEST (callee) module: child gated on start; on completion await done-ready
    # then pulse done.
    my $bus = $lowered->{files}{'xdom__domain_bus.fsm'};
    like($bus, qr/worker_idle_ext\s*\(\s*<worker_start/s, 'child is gated on the start pulse');
    like($bus, qr/<worker_done_ready\b/, 'callee awaits the done-ready handshake (consumes the done CDC ready)');
    like($bus, qr/\(worker_done>\s*1\)/, 'callee pulses the done handshake');

    # Top: the two CDC children carry start SRC->DEST and done DEST->SRC.
    my $top = $lowered->{files}{'xdom_top.fsm'};
    like($top, qr/\(\?rtl:worker_activation_start_cdc xdom__cdc_activation_worker_start\)/, 'top instantiates the start CDC child');
    like($top, qr/\(\?rtl:worker_activation_done_cdc xdom__cdc_activation_worker_done\)/, 'top instantiates the done CDC child');
    like($top, qr{/core\.worker_start/worker_activation_start_cdc\.request/}, 'caller start drives the start CDC request');
    like($top, qr{/worker_activation_start_cdc\.pulse/bus\.worker_start/}, 'start CDC pulses the child start');
    like($top, qr{/bus\.worker_done/worker_activation_done_cdc\.request/}, 'child done drives the done CDC request');
    like($top, qr{/worker_activation_done_cdc\.pulse/core\.worker_done/}, 'done CDC pulses the caller release');
};

subtest 'a declared-but-unused activation crossing fails closed at lower' => sub {
    # `parent` never performs `(do worker)`, so the crossing owns no real
    # cross-domain activation and would emit dead CDC logic; reject it.
    my $actor = parse_source(<<'ISF', 'activation-unused');
(actor act_unused
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
    (complete done))
  (transaction worker
    (domain bus)
    (complete worker_done)))
ISF
    my $ok = eval { FSM::Scheduler::ISF->new()->lower($actor); 1 };
    my $err = $@;
    ok(!$ok, 'a declared-but-unused activation crossing is rejected at lower');
    like($err, qr/declared but no transaction in domain 'core' performs a top-level '\(do worker\)'/, 'the diagnostic explains the crossing is unused');
};

subtest 'a cross-domain (do) WITHOUT a covering activation crossing still fails closed' => sub {
    my $actor = parse_source(<<'ISF', 'activation-uncovered');
(actor act_uncovered
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
    my $ok = eval { FSM::Scheduler::ISF->new()->lower($actor); 1 };
    my $err = $@;
    ok(!$ok, 'a cross-domain (do) with no activation crossing is rejected at lower');
    like($err, qr/clock-domain violation.*do target 'worker'.*domain 'bus'.*domain 'core'/s, 'the diagnostic is the fail-closed clock-domain violation');
};

subtest 'multi-domain top emits and wires the two activation CDC children' => sub {
    my $actor = {
        actor_name => 'act',
        crossings  => [
            { kind => 'activation', child => 'worker', from => { domain => 'core' }, to => { domain => 'bus' } },
        ],
        interface => {
            inputs  => [ { name => 'start', width => 1, domain => 'core' } ],
            outputs => [ { name => 'done',  width => 1, domain => 'core' } ],
        },
    };
    my $partition = {
        kind           => 'multi_domain',
        default_domain => 'core',
        top_fsm        => 'act_top.fsm',
        domains        => [
            { name => 'core', clock => 'clk',     reset => { name => 'rst_n',     kind => 'sync', polarity => 'active_low' }, scheduled_fsm => 'act__domain_core.fsm' },
            { name => 'bus',  clock => 'bus_clk', reset => { name => 'bus_rst_n', kind => 'sync', polarity => 'active_low' }, scheduled_fsm => 'act__domain_bus.fsm' },
        ],
    };

    my $top = FSM::Scheduler::ISF::_emit_multi_domain_top($actor, $partition);

    like($top, qr/\(\?rtl:worker_activation_start_cdc act__cdc_activation_worker_start\)/, 'top instantiates the start CDC child');
    like($top, qr/\(\?rtl:worker_activation_done_cdc act__cdc_activation_worker_done\)/, 'top instantiates the done CDC child');

    # start synchronizer: SRC (core) request -> DEST (bus) pulse, clk->source, bus_clk->dest.
    like($top, qr{/core\.worker_start/worker_activation_start_cdc\.request/}, 'start CDC takes the SRC one-cycle request');
    like($top, qr{/worker_activation_start_cdc\.pulse/bus\.worker_start/}, 'start CDC pulses the DEST start');
    like($top, qr{/clk/worker_activation_start_cdc\.source_clk/}, 'start CDC source clock is the SRC domain clock');
    like($top, qr{/bus_clk/worker_activation_start_cdc\.dest_clk/}, 'start CDC dest clock is the DEST domain clock');

    # done synchronizer: DEST (bus) request -> SRC (core) pulse (reversed clocks).
    like($top, qr{/bus\.worker_done/worker_activation_done_cdc\.request/}, 'done CDC takes the DEST one-cycle done');
    like($top, qr{/worker_activation_done_cdc\.pulse/core\.worker_done/}, 'done CDC pulses the SRC release');
    like($top, qr{/bus_clk/worker_activation_done_cdc\.source_clk/}, 'done CDC source clock is the DEST domain clock');
    like($top, qr{/clk/worker_activation_done_cdc\.dest_clk/}, 'done CDC dest clock is the SRC domain clock');

    # The CDC `ready` outputs are consumed: the caller awaits `<start>_ready`
    # before pulsing and the callee awaits `<done>_ready` before asserting done
    # (the event-crossing idiom; also satisfies the composition's consume rule).
    like($top, qr{/worker_activation_start_cdc\.ready/core\.worker_start_ready/}, 'start CDC ready feeds the caller start-ready input');
    like($top, qr{/worker_activation_done_cdc\.ready/bus\.worker_done_ready/}, 'done CDC ready feeds the callee done-ready input');

    like($top, qr/\(\?rtlif:act__cdc_activation_worker_start[\s\S]*request<:data[\s\S]*ready>:data[\s\S]*pulse>:data/, 'top embeds the start CDC interface artifact');
    like($top, qr/\(\?rtlif:act__cdc_activation_worker_done[\s\S]*request<:data[\s\S]*ready>:data[\s\S]*pulse>:data/, 'top embeds the done CDC interface artifact');
    like($top, qr/\(FSMGEN_ISF_CDC_EVENT 0d1\)/, 'activation CDC children reuse the acknowledged-event primitive');
};

done_testing();
