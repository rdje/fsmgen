#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Locks scheduler-frontier #2: a same-domain generated (do child (params ...))
# (with (bind ...)/(domain NAME) when static params are present) inside a
# (repeat N ...) that sits directly in one (while ...)/(until ...) body now
# lowers, instantiating the generated child in the _top composition. The
# generated child is registered (loop-body discovery), the do-state triggers
# the instance and awaits its done, and the repeat reuses the proven schedule.
# Cross-domain generated do, params-less bindings, and spawn stay deferred.
#
# Tree: ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING

sub parse_lower {
    my ($src, $name) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($src, $name);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

subtest 'while-contained repeat-body generated do (static params) lowers + instantiates the child' => sub {
    my $src = <<'ISF';
(actor while_gen_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (do worker (params (W 8)))))
    (complete done))
  (transaction worker
    (params (W 4))
    (complete done)))
ISF
    my $result = eval { parse_lower($src, 'while-gen-do.isf') };
    ok($result, 'while-contained generated do lowers cleanly') or diag($@);

    my $fsm = $result->{files}{'while_gen_do.fsm'};
    # blocking generated-do state triggers the generated instance and awaits its done
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(parent_worker_repeat_do_0_start>\s*1\)\).*?\(<parent_worker_repeat_do_0_done.*?->\s*parent_repeat_check_\d+/s,
        'generated do asserts the instance _start and awaits the instance _done');
    like($fsm, qr/\(parent_repeat_init_\d+\b.*?\(<=\s*\(parent_cnt loops\)\)/s,
        'repeat_init seeds parent_cnt from loops inside the loop body');

    # the generated child module is built and instantiated with the param override
    ok(exists $result->{files}{'worker.fsm'}, 'the generated child module worker.fsm is emitted');
    my $top = $result->{files}{'while_gen_do_top.fsm'};
    ok(defined $top, 'a _top composition is emitted');
    like($top, qr/\(\?fsmc:parent_worker_repeat_do_0 worker\b.*?\(params.*?\(W 8\)/s,
        'the composition instantiates the worker child with the (W 8) override');
    like($top, qr/parent_worker_repeat_do_0\.done\b/s,
        'the composition wires the generated instance done back to the parent');
};

subtest 'until-contained repeat-body generated do (static params) lowers' => sub {
    my $src = <<'ISF';
(actor until_gen_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (until cond
      (repeat loops
        (do worker (params (W 8)))))
    (complete done))
  (transaction worker
    (params (W 4))
    (complete done)))
ISF
    my $result = eval { parse_lower($src, 'until-gen-do.isf') };
    ok($result, 'until-contained generated do lowers cleanly') or diag($@);
    ok(exists $result->{files}{'worker.fsm'}, 'the generated child module is emitted');
    my $top = $result->{files}{'until_gen_do_top.fsm'};
    like($top, qr/\(\?fsmc:parent_worker_repeat_do_0 worker\b.*?\(W 8\)/s,
        'the composition instantiates the worker child with the (W 8) override');
};

subtest 'cross-domain generated do, params-less bindings, and spawn stay deferred' => sub {
    # cross-domain generated do is deferred
    my $cross_domain = <<'ISF';
(actor while_xd
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface
    (input start (domain core)) (input cond (domain core))
    (input loops (width 3) (domain core)) (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (while cond
      (repeat loops
        (do worker (domain aux))))
    (complete done))
  (transaction worker
    (domain aux)
    (complete done)))
ISF
    my $ok1 = eval { parse_lower($cross_domain, 'xd.isf'); 1 };
    ok(!$ok1, 'loop-contained cross-domain generated do is rejected');
    like($@, qr/cross-domain repeat-body do remains deferred/,
        'cross-domain generated do emits the cross-domain deferral');

    # bindings without static params are deferred
    my $bind_no_params = <<'ISF';
(actor while_bnp
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3)) (input din (width 8))
    (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (do worker (bind (input di din)))))
    (complete done))
  (transaction worker
    (interface (input di (width 8)))
    (complete done)))
ISF
    my $ok2 = eval { parse_lower($bind_no_params, 'bnp.isf'); 1 };
    ok(!$ok2, 'loop-contained generated do bindings without static params are rejected');
    like($@, qr/repeat-body generated do bindings require static '\(params \.\.\.\)' overrides/,
        'bindings without static params emit the bindings-require-params diagnostic');

    # spawn stays deferred (unchanged)
    my $spawn = <<'ISF';
(actor while_spawn
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (spawn worker as w0)
        (await_all done)))
    (complete done))
  (transaction worker
    (complete done)))
ISF
    my $ok3 = eval { parse_lower($spawn, 'spawn.isf'); 1 };
    ok(!$ok3, 'loop-contained repeat-body spawn is rejected');
    like($@, qr/loop-contained repeat-body spawn remains deferred/,
        'spawn in a loop-contained repeat stays deferred');
};

done_testing();
