#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-CONDITIONAL-CHILD-ACTIVATION.2
#
# A plain LOCAL `(do child)` is now accepted directly inside a `when` body
# (conditional one-shot activation, no `(repeat 1 ...)` wrapping). Generated /
# bound conditional activation stays deferred (later slices).

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
}

subtest 'a plain local (do child) inside a when body lowers and gates the sibling' => sub {
    my $actor = parse_source(<<'ISF', 'when-local-do');
(actor when_local_do
  (interface
    (input start)
    (input cond)
    (input go)
    (input din (width 8))
    (output done)
    (output result (width 8))
    (output wdone))
  (transaction parent
    (on start)
    (when cond
      (do worker))
    (complete done))
  (transaction worker
    (on go)
    (update result din)
    (complete wdone)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'when-body local (do) lowers') or diag($@);

    my $fsm = $lowered->{files}{'when_local_do.fsm'};
    ok(defined($fsm), 'scheduled .fsm emitted');

    # The `when` branch guards the do; the do-state asserts the start handshake
    # and blocks on the done handshake.
    like($fsm, qr/parent_when_\d+\s*\(\s*\?cond/s, 'the do is guarded by the when branch selector');
    like($fsm, qr/parent_do_\d+[\s\S]*?\(worker_start 1\)/, 'the conditional do-state asserts the child start handshake');
    like($fsm, qr/parent_do_\d+[\s\S]*?<worker_done/, 'the conditional do-state blocks on the child done handshake');

    # The sibling child is gated on its start handshake (it has an entry state).
    like($fsm, qr/worker_idle_\d+[\s\S]*?<worker_start/s, 'the sibling child entry is gated on the start handshake');
};

subtest 'a bound local (do) inside a when body lowers and emits the binding' => sub {
    my $bound = parse_source(<<'ISF', 'when-bound-do');
(actor when_bound_do
  (interface
    (input start)
    (input cond)
    (input req (width 8))
    (input go)
    (output done)
    (output wc (width 8)))
  (transaction parent
    (on start)
    (when cond
      (do worker
        (bind (input addr req))))
    (complete done))
  (transaction worker
    (on go)
    (ports (input addr (width 8)))
    (update wc addr)
    (complete wc)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($bound) };
    ok($lowered, 'a bound local (do) in a when body lowers') or diag($@);
    my $fsm = $lowered->{files}{'when_bound_do.fsm'};
    like($fsm, qr/parent_do_\d+[\s\S]*?\(addr req\)/, 'the do-state drives the bound child port (addr <- req)');
    like($fsm, qr/parent_do_\d+[\s\S]*?\(worker_start 1\)/, 'the do-state still asserts the start handshake');
};

subtest 'a generated (params) (do) inside a when body lowers to a conditional generated child instance' => sub {
    my $gen = parse_source(<<'ISF', 'when-generated-do');
(actor when_generated_do
  (interface
    (input start)
    (input cond)
    (input din (width 8))
    (output done)
    (output result (width 8))
    (output wdone))
  (transaction parent
    (on start)
    (when cond
      (do worker
        (params (W 8))
        (bind (input data din) (output data_out result))))
    (complete done))
  (transaction worker
    (params (W 8))
    (on start)
    (ports (input data (width W)) (output data_out (width W)))
    (update data_out data)
    (complete wdone)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($gen) };
    ok($lowered, 'a generated (params) (do) in a when body lowers') or diag($@);

    # The generated child is built, instantiated in the top under a conditional
    # do-instance name, and conditionally activated (parity with a top-level
    # generated do; the generated-child composition wiring shares the pre-existing
    # COMPOSITION_SCOPE --check-json boundary, so this asserts the lowered schedule
    # + top, not --check-json).
    ok(exists $lowered->{files}{'worker.fsm'}, 'the generated child module is emitted');
    my $parent = $lowered->{files}{'when_generated_do.fsm'};
    like($parent, qr/parent_when_\d+\s*\(\s*\?cond/s, 'the generated do is guarded by the when branch selector');
    like($parent, qr/parent_worker_cond_do_0_start>/, 'the do-state asserts the conditional generated-instance start handoff');
    my $top = $lowered->{files}{'when_generated_do_top.fsm'};
    like($top, qr/\(\?fsmc:parent_worker_cond_do_0 worker\b/, 'the top instantiates the conditional generated child instance');
    like($top, qr/parent_worker_cond_do_0\.start/, 'the top wires the conditional instance start handoff');
    like($top, qr/parent_worker_cond_do_0\.done/, 'the top wires the conditional instance done handoff');
};

subtest 'a plain local (do) lowers in switch / while / until bodies too' => sub {
    my %context = (
        'switch branch' => '(switch sel (0 (do worker)))',
        'while body'    => '(while cond (do worker))',
        'until body'    => '(until cond (do worker))',
    );
    for my $label (sort keys %context) {
        my $actor = parse_source(<<"ISF", "ctx-$label");
(actor ctx_local_do
  (interface
    (input start)
    (input cond)
    (input sel (width 2))
    (input go)
    (input din (width 8))
    (output done)
    (output result (width 8))
    (output wdone))
  (transaction parent
    (on start)
    $context{$label}
    (complete done))
  (transaction worker
    (on go)
    (update result din)
    (complete wdone)))
ISF
        my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
        ok($lowered, "local (do) in a $label lowers") or diag($@);
        my ($fsm) = grep { /^ctx_local_do/ } keys %{$lowered->{files} || {}};
        $fsm = $lowered->{files}{$fsm};
        like($fsm, qr/\(worker_start 1\)/, "$label do-state asserts the start handshake");
        like($fsm, qr/worker_idle_\d+[\s\S]*?<worker_start/s, "$label gates the sibling child on its start handshake");
    }
};

subtest 'a generated (params) (do) in switch / while / until bodies lowers to a conditional generated child instance' => sub {
    my %context = (
        'switch branch' => '(switch sel (0 (do worker (params (W 8)) (bind (input data din)))))',
        'while body'    => '(while cond (do worker (params (W 8)) (bind (input data din))))',
        'until body'    => '(until cond (do worker (params (W 8)) (bind (input data din))))',
    );
    for my $label (sort keys %context) {
        my $gen = parse_source(<<"ISF", "ctx-generated-$label");
(actor ctx_generated_do
  (interface
    (input start)
    (input cond)
    (input sel (width 2))
    (input din (width 8))
    (output done)
    (output wc (width 8)))
  (transaction parent
    (on start)
    $context{$label}
    (complete done))
  (transaction worker
    (params (W 8))
    (on start)
    (ports (input data (width W)))
    (update wc data)
    (complete wc)))
ISF
        my $lowered = eval { FSM::Scheduler::ISF->new()->lower($gen) };
        ok($lowered, "a generated (params) (do) in a $label lowers") or diag($@);

        # Parity with the when-body generated do and the top-level generated do:
        # the child module is built, instantiated under a conditional do-instance
        # name, and conditionally activated. The generated-child composition wiring
        # shares the pre-existing COMPOSITION_SCOPE --check-json boundary, so this
        # asserts the lowered schedule + top, not --check-json.
        ok(exists $lowered->{files}{'worker.fsm'}, "$label: the generated child module is emitted");
        my $parent = $lowered->{files}{'ctx_generated_do.fsm'};
        like($parent, qr/parent_worker_cond_do_0_start>/, "$label: the do-state asserts the conditional generated-instance start handoff");
        my $top = $lowered->{files}{'ctx_generated_do_top.fsm'};
        like($top, qr/\(\?fsmc:parent_worker_cond_do_0 worker\b/, "$label: the top instantiates the conditional generated child instance");
        like($top, qr/parent_worker_cond_do_0\.start/, "$label: the top wires the conditional instance start handoff");
        like($top, qr/parent_worker_cond_do_0\.done/, "$label: the top wires the conditional instance done handoff");
    }
};

done_testing();
