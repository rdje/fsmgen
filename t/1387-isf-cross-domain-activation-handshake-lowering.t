#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use JSON::PP qw(decode_json);

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

subtest 'the schedule report exposes activation crossing metadata' => sub {
    my $actor = parse_source(<<'ISF', 'activation-report');
(actor xdom_report
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (crossings
    (activation worker (from core) (to bus)))
  (interface
    (input start (domain core))
    (output done (domain core))
    (input din (width 8) (domain bus))
    (output result (width 8) (domain bus))
    (output worker_complete (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (do worker)
    (complete done))
  (transaction worker
    (domain bus)
    (sample din as snap)
    (update result snap)
    (complete worker_complete)))
ISF
    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    is_deeply(
        $report->{crossings},
        [
            {
                name               => 'worker',
                kind               => 'activation',
                child              => 'worker',
                source_domain      => 'core',
                destination_domain => 'bus',
                start_signal       => 'worker_start',
                done_signal        => 'worker_done',
                start_instance     => 'worker_activation_start_cdc',
                start_module       => 'xdom_report__cdc_activation_worker_start',
                done_instance      => 'worker_activation_done_cdc',
                done_module        => 'xdom_report__cdc_activation_worker_done',
                outstanding_policy => 'single_outstanding_acknowledged',
                payload            => 'none',
                top_fsm            => 'xdom_report_top.fsm',
            },
        ],
        'top-level report exposes the activation crossing with its dual-CDC metadata',
    );

    my %domain = map { $_->{name} => $_ } @{$report->{clock_domains}};
    is_deeply(
        $domain{core}{crossings},
        [{ activation => 'worker', role => 'source', start => 'worker_start', done => 'worker_done' }],
        'source-domain report exposes the activation source endpoint',
    );
    is_deeply(
        $domain{bus}{crossings},
        [{ activation => 'worker', role => 'destination', start => 'worker_start', done => 'worker_done' }],
        'destination-domain report exposes the activation destination endpoint',
    );
};

subtest 'a nested cross-domain (do) fails closed with a precise deferred diagnostic' => sub {
    # A `(do child)` directly inside a TOP-LEVEL branch/loop body (`when`/`switch`/
    # `while`/`until`) or a TOP-LEVEL `repeat` body IS supported
    # (ISF-NESTED-CROSS-DOMAIN-ACTIVATION.3/.4 — covered by the positive subtests
    # below). A DEEPER-nested `(do child)` — inside a container that is itself nested
    # in another body — is still deferred. The diagnostic must name the (innermost)
    # deferred context accurately, not the genuinely-unused
    # "declared but ... no top-level (do)" message.
    my %context_body = (
        # when->when: the inner when is NOT a direct transaction clause, so the do
        # stays deferred; the innermost container the diagnostic names is a when body.
        'when body'     => '(when cond (when cond (do worker)))',
        # switch->switch: likewise deferred; innermost container is a switch branch.
        'switch branch' => '(switch sel (0 (switch sel (0 (do worker)))))',
        # repeat->repeat: the inner repeat is NOT top-level or branch-contained,
        # so it stays deferred; the innermost container the diagnostic names is
        # the repeat body.
        'repeat body'   => '(repeat n (repeat n (do worker)))',
    );
    for my $label (sort keys %context_body) {
        my $actor = parse_source(<<"ISF", "nested-$label");
(actor nested_xdom
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus  (clock bus_clk) (reset bus_rst_n)))
  (crossings
    (activation worker (from core) (to bus)))
  (interface
    (input start (domain core))
    (input cond (domain core))
    (input sel (width 2) (domain core))
    (input n (width 3) (domain core))
    (output done (domain core))
    (output worker_complete (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    $context_body{$label}
    (complete done))
  (transaction worker
    (domain bus)
    (complete worker_complete)))
ISF
        my $ok = eval { FSM::Scheduler::ISF->new()->lower($actor); 1 };
        my $err = $@;
        ok(!$ok, "nested ($label) cross-domain (do) is rejected at lower");
        like(
            $err,
            qr/used by a nested '\(do worker\)' \(inside a \Q$label\E\)[\s\S]*nested cross-domain activation remains deferred/,
            "nested ($label) diagnostic accurately names the deferred nested context",
        );
        unlike(
            $err,
            qr/declared but no transaction/,
            "nested ($label) is not misreported as a declared-but-unused crossing",
        );
    }
};

subtest 'a (do child) directly inside a TOP-LEVEL repeat body lowers cross-domain through the dual-CDC per iteration' => sub {
    # ISF-NESTED-CROSS-DOMAIN-ACTIVATION.3: the first supported nested cross-domain
    # context. A blocking `(do worker)` in a top-level `(repeat ...)` body blocks
    # each iteration until done, so the shipped await-ready + one-cycle-start +
    # dual-CDC handshake applies per iteration, and the callee returns to idle
    # between iterations ready for the next start pulse.
    my $actor = parse_source(<<'ISF', 'top-level-repeat-xdom');
(actor cross_domain_repeat_do
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus  (clock bus_clk) (reset bus_rst_n)))
  (crossings
    (activation worker (from core) (to bus)))
  (interface
    (input  start (domain core))
    (output done  (domain core))
    (input  din    (width 8) (domain bus))
    (output result (width 8) (domain bus))
    (output worker_complete (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (repeat 2 (do worker))
    (complete done))
  (transaction worker
    (domain bus)
    (sample din as snap)
    (update result snap)
    (complete worker_complete)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'top-level repeat-body cross-domain (do) lowers') or diag($@);

    my $core = $lowered->{files}{'cross_domain_repeat_do__domain_core.fsm'};
    ok(defined($core), 'the caller (core) domain module is emitted');
    # The do-state inside the repeat region is restructured into the CDC handshake
    # chain: await <start>_ready -> one-cycle <start> -> await <done>.
    like($core, qr/parent_do_\d+_ready\b[\s\S]*?<worker_start_ready/, 'caller awaits the start CDC ready before the request');
    like($core, qr/parent_do_\d+_req\b[\s\S]*?\(worker_start>\s*1\)/, 'caller drives a one-cycle start request');
    like($core, qr/parent_do_\d+\b[\s\S]*?<worker_done/, 'caller blocks on the done handshake');
    # The repeat loop-back re-enters the handshake each iteration (the check-first
    # loop-back targets the ready-await, which re-arms the per-iteration handshake).
    like($core, qr/parent_repeat_check_\d+[\s\S]*?\(!=0 \(-> parent_do_\d+_ready\)\)/, 'the repeat loop re-runs the per-iteration handshake');

    my $bus = $lowered->{files}{'cross_domain_repeat_do__domain_bus.fsm'};
    ok(defined($bus), 'the callee (bus) domain module is emitted');
    like($bus, qr/worker_idle_ext\s*\(\s*<worker_start/s, 'callee entry is gated on the start pulse each iteration');
    like($bus, qr/worker_done_req\b[\s\S]*?\(worker_done>\s*1\)[\s\S]*?worker_idle_ext/, 'callee pulses done then returns to idle, ready for the next iteration');

    my $top = $lowered->{files}{'cross_domain_repeat_do_top.fsm'};
    ok(defined($top), 'the multi-domain top is emitted');
    like($top, qr/cdc_activation_worker_start/, 'the top instantiates the start CDC synchronizer');
    like($top, qr/cdc_activation_worker_done/, 'the top instantiates the done CDC synchronizer');
};

subtest 'a (do child) directly inside a TOP-LEVEL branch/loop body lowers cross-domain through the dual-CDC' => sub {
    # ISF-NESTED-CROSS-DOMAIN-ACTIVATION.4: now that the same-domain branch-body
    # `(do)` feature is shipped (ISF-CONDITIONAL-CHILD-ACTIVATION), a covered
    # cross-domain `(do worker)` directly inside a TOP-LEVEL `when`/`switch`/`while`/
    # `until` body lowers through the same dual-CDC handshake. The caller restructure
    # redirects the branch/loop ENTRY (a `when` `true_target`, a `switch` branch
    # `body_start`, a loop `loop_body_start`) into the inserted ready-await, so the
    # await-ready -> one-cycle-start -> await-done chain runs when the branch is taken.
    my %context = (
        'when'   => '(when guard (do worker))',
        'switch' => '(switch guard (1 (do worker)))',
        'while'  => '(while guard (do worker))',
        'until'  => '(until guard (do worker))',
    );
    for my $label (sort keys %context) {
        # Declare `guard` at the width each context needs (switch needs a vector
        # selector). Only signals the body uses are declared, so nothing is pruned.
        my $guard_decl = $label eq 'switch'
            ? '(input guard (width 2) (domain core))'
            : '(input guard (domain core))';
        my $actor = parse_source(<<"ISF", "branch-xdom-$label");
(actor branch_xdom
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus  (clock bus_clk) (reset bus_rst_n)))
  (crossings
    (activation worker (from core) (to bus)))
  (interface
    (input  start (domain core))
    $guard_decl
    (output done  (domain core))
    (input  din    (width 8) (domain bus))
    (output result (width 8) (domain bus))
    (output worker_complete (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    $context{$label}
    (complete done))
  (transaction worker
    (domain bus)
    (sample din as snap)
    (update result snap)
    (complete worker_complete)))
ISF
        my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
        ok($lowered, "$label-body cross-domain (do) lowers") or diag($@);
        my $core = $lowered->{files}{'branch_xdom__domain_core.fsm'};
        # The inserted ready-await is reachable (the branch/loop entry was redirected
        # into it), drives a one-cycle start, then blocks on done.
        like($core, qr/-> parent_do_\d+_ready/, "$label: the branch/loop entry is redirected into the start-ready await");
        like($core, qr/parent_do_\d+_req\b[\s\S]*?\(worker_start>\s*1\)/, "$label: a one-cycle start request is driven");
        like($core, qr/parent_do_\d+\b\s*\(\s*<worker_done/, "$label: the do-state blocks on the done handshake");
        my $bus = $lowered->{files}{'branch_xdom__domain_bus.fsm'};
        like($bus, qr/worker_idle_ext\s*\(\s*<worker_start/s, "$label: the callee is gated on the start pulse");
    }
};

subtest 'a (do child) directly inside a branch-contained repeat lowers cross-domain through the dual-CDC per iteration' => sub {
    # ISF-NESTED-CROSS-DOMAIN-ACTIVATION.6: a repeat nested directly inside a
    # TOP-LEVEL `when` body or `switch` branch now owns the same blocking
    # per-iteration cross-domain activation handshake as a top-level repeat. The
    # still-deferred cases are deeper branch/repeat combinations and nested
    # while/until.
    my %context = (
        'when->repeat'   => '(when guard (repeat iter (do worker)))',
        'switch->repeat' => '(switch guard (1 (repeat iter (do worker))))',
    );
    for my $label (sort keys %context) {
        my $guard_decl = $label =~ /^switch/
            ? '(input guard (width 2) (domain core))'
            : '(input guard (domain core))';
        my $actor = parse_source(<<"ISF", "branch-repeat-xdom-$label");
(actor branch_repeat_xdom
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus  (clock bus_clk) (reset bus_rst_n)))
  (crossings
    (activation worker (from core) (to bus)))
  (interface
    (input  start (domain core))
    $guard_decl
    (input  iter  (width 3) (domain core))
    (output done  (domain core))
    (input  din    (width 8) (domain bus))
    (output result (width 8) (domain bus))
    (output worker_complete (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    $context{$label}
    (complete done))
  (transaction worker
    (domain bus)
    (sample din as snap)
    (update result snap)
    (complete worker_complete)))
ISF
        my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
        ok($lowered, "$label cross-domain (do) lowers") or diag($@);

        my $core = $lowered->{files}{'branch_repeat_xdom__domain_core.fsm'};
        ok(defined($core), "$label: the caller (core) domain module is emitted");
        like($core, qr/-> parent_repeat_init_\d+/, "$label: the branch enters the nested repeat region");
        like($core, qr/parent_repeat_init_\d+[\s\S]*?-> parent_do_\d+_ready/, "$label: repeat init enters the start-ready await");
        like($core, qr/parent_do_\d+_req\b[\s\S]*?\(worker_start>\s*1\)/, "$label: a one-cycle start request is driven");
        like($core, qr/parent_do_\d+\b\s*\(\s*<worker_done/, "$label: the do-state blocks on the done handshake");
        like($core, qr/parent_repeat_check_\d+[\s\S]*?\(!=0 \(-> parent_do_\d+_ready\)\)/, "$label: the nested repeat loop re-runs the handshake");

        my $bus = $lowered->{files}{'branch_repeat_xdom__domain_bus.fsm'};
        ok(defined($bus), "$label: the callee (bus) domain module is emitted");
        like($bus, qr/worker_idle_ext\s*\(\s*<worker_start/s, "$label: the callee is gated on the start pulse");

        my $top = $lowered->{files}{'branch_repeat_xdom_top.fsm'};
        ok(defined($top), "$label: the multi-domain top is emitted");
        like($top, qr/cdc_activation_worker_start/, "$label: the top instantiates the start CDC synchronizer");
        like($top, qr/cdc_activation_worker_done/, "$label: the top instantiates the done CDC synchronizer");
    }
};

done_testing();
