#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Locks scheduler-frontier #4: a same-domain generated (do child (params ...))
# inside a (repeat N ...) reached through deeper branch nesting (when+ -> repeat,
# switch -> when+ -> repeat) now lowers and instantiates the generated child in
# the _top composition. Cross-domain generated do and spawn stay deferred.
#
# The ordinal-agreement subtest is the load-bearing check: the collector that
# discovers generated children must visit repeats in the same source order the
# lowering assigns repeat-do ordinals, or the _top instance names would not
# match the scheduled .fsm instance ports.
#
# Tree: ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING

sub parse_lower {
    my ($src, $name) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($src, $name);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

subtest 'when-inside-when repeat-body generated do (static params) lowers + instantiates the child' => sub {
    my $src = <<'ISF';
(actor when_when_gen_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input c1) (input c2) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (when c1
      (when c2
        (repeat loops
          (do worker (params (W 8))))))
    (complete done))
  (transaction worker
    (params (W 4))
    (complete done)))
ISF
    my $result = eval { parse_lower($src, 'when-when-gen-do.isf') };
    ok($result, 'when-inside-when generated do lowers cleanly') or diag($@);
    ok(exists $result->{files}{'worker.fsm'}, 'the generated child module is emitted');
    my $top = $result->{files}{'when_when_gen_do_top.fsm'};
    like($top, qr/\(\?fsmc:parent_worker_repeat_do_0 worker\b.*?\(W 8\)/s,
        'the composition instantiates the worker child with the (W 8) override');
};

subtest 'switch-branch -> when repeat-body generated do lowers' => sub {
    my $src = <<'ISF';
(actor switch_when_gen_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input mode) (input c2) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (switch mode
      (0
        (when c2
          (repeat loops
            (do worker (params (W 8)))))))
    (complete done))
  (transaction worker
    (params (W 4))
    (complete done)))
ISF
    my $result = eval { parse_lower($src, 'switch-when-gen-do.isf') };
    ok($result, 'switch-branch -> when generated do lowers cleanly') or diag($@);
    ok(exists $result->{files}{'worker.fsm'}, 'the generated child module is emitted');
};

subtest 'generated-child instance ordinals agree between the scheduled .fsm and the _top composition' => sub {
    # A top-level generated do (ordinal 0) and a deeper-nested generated do
    # (ordinal 1) of the same child. The collector and the lowering must agree
    # on ordinals or the wiring would reference a non-existent instance.
    my $src = <<'ISF';
(actor mixed_gen_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input c1) (input c2) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (repeat loops (do worker (params (W 8))))
    (when c1
      (when c2
        (repeat loops (do worker (params (W 16))))))
    (complete done))
  (transaction worker
    (params (W 4))
    (complete done)))
ISF
    my $result = eval { parse_lower($src, 'mixed-gen-do.isf') };
    ok($result, 'mixed top-level + deeper-nested generated do lowers cleanly') or diag($@);
    my $fsm = $result->{files}{'mixed_gen_do.fsm'};
    my $top = $result->{files}{'mixed_gen_do_top.fsm'};

    my @fsm_instances = sort($fsm =~ /(parent_worker_repeat_do_\d+)_start>/g);
    my @top_instances = sort($top =~ /\(\?fsmc:(parent_worker_repeat_do_\d+) worker/g);
    is_deeply(\@fsm_instances, \@top_instances,
        'every scheduled .fsm generated-do instance is instantiated in the _top with the same ordinal');
    is(scalar(@top_instances), 2, 'both generated-do sites produced an instance');
    # the W=8 site (top-level, ordinal 0) and W=16 site (deeper-nested, ordinal 1)
    like($top, qr/\(\?fsmc:parent_worker_repeat_do_0 worker\b.*?\(W 8\)/s,
        'top-level generated do is ordinal 0 with (W 8)');
    like($top, qr/\(\?fsmc:parent_worker_repeat_do_1 worker\b.*?\(W 16\)/s,
        'deeper-nested generated do is ordinal 1 with (W 16)');
};

subtest 'deeper-nested cross-domain generated do, spawn, and params-less bindings stay deferred' => sub {
    my $cross_domain = <<'ISF';
(actor when_when_xd
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface
    (input start (domain core)) (input c1 (domain core)) (input c2 (domain core))
    (input loops (width 3) (domain core)) (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (when c1
      (when c2
        (repeat loops
          (do worker (domain aux)))))
    (complete done))
  (transaction worker
    (domain aux)
    (complete done)))
ISF
    my $ok1 = eval { parse_lower($cross_domain, 'xd.isf'); 1 };
    ok(!$ok1, 'deeper-nested cross-domain generated do is rejected');
    like($@, qr/cross-domain repeat-body do remains deferred/,
        'cross-domain generated do at deeper nesting stays deferred');

    my $spawn = <<'ISF';
(actor when_when_spawn
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input c1) (input c2) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (when c1
      (when c2
        (repeat loops
          (spawn worker as w0))))
    (complete done))
  (transaction worker
    (complete done)))
ISF
    my $ok2 = eval { parse_lower($spawn, 'spawn.isf'); 1 };
    ok(!$ok2, 'undrained deeper-nested spawn is rejected');
    like($@, qr/deeper-nested repeat-body spawn requires same-body '\(await_all done\)' or single-pending '\(await_any done\)'/,
        'an undrained spawn at deeper nesting stays deferred');
};

done_testing();
