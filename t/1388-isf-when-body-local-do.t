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

subtest 'a generated or bound (do) inside a when body is deferred' => sub {
    my $bound = parse_source(<<'ISF', 'when-bound-do');
(actor when_bound_do
  (interface
    (input start)
    (input cond)
    (input req (width 8))
    (output done)
    (output wc))
  (transaction parent
    (on start)
    (when cond
      (do worker
        (bind (input addr req))))
    (complete done))
  (transaction worker
    (ports (input addr (width 8)))
    (update wc addr)
    (complete wc)))
ISF
    my $ok = eval { FSM::Scheduler::ISF->new()->lower($bound); 1 };
    my $err = $@;
    ok(!$ok, 'a bound (do) in a when body is rejected (deferred)');
    like(
        $err,
        qr/when body generated\/bound '\(do worker \.\.\.\)' is not yet supported.*conditional activation is deferred/s,
        'the deferral diagnostic names the generated/bound when-body do',
    );
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

subtest 'a generated or bound (do) in a switch branch is also deferred' => sub {
    my $bound = parse_source(<<'ISF', 'switch-bound-do');
(actor switch_bound_do
  (interface
    (input start)
    (input sel (width 2))
    (input req (width 8))
    (output done)
    (output wc))
  (transaction parent
    (on start)
    (switch sel
      (0 (do worker (bind (input addr req)))))
    (complete done))
  (transaction worker
    (ports (input addr (width 8)))
    (update wc addr)
    (complete wc)))
ISF
    my $ok = eval { FSM::Scheduler::ISF->new()->lower($bound); 1 };
    my $err = $@;
    ok(!$ok, 'a bound (do) in a switch branch is rejected (deferred)');
    like(
        $err,
        qr/switch branch generated\/bound '\(do worker \.\.\.\)' is not yet supported/,
        'the deferral diagnostic names the switch-branch generated/bound do',
    );
};

done_testing();
