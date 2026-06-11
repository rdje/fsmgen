#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Locks scheduler-frontier #5: the basic (spawn child as inst) + same-body
# (await_all done) (and single-pending (await_any done)) subset inside a
# loop-contained or deeper-nested repeat. The spawn is drained (await_all waits
# the child _done) before repeat_check loops and before the outer loop/branch
# re-enters -- parity with the proven top-level repeat-body spawn. An undrained
# spawn and a multi-pending (await_any) stay deferred.
#
# NOTE: repeat-body spawn is a lowering + composition-planning feature, not
# full-HDL-clean -- even at top level the composition planner references the
# repeat-count/loop-condition parent inputs as child endpoints, so `--check-json`
# fails identically for the top-level reference (a pre-existing limitation, see
# docs/COMPOSITION_SCOPE.md). These tests therefore assert the lowered schedule
# and composition, not full HDL.
#
# Tree: ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING

sub parse_lower {
    my ($src, $name) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($src, $name);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

subtest 'while-contained repeat-body spawn + same-body await_all drains before the loop re-enters' => sub {
    my $src = <<'ISF';
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
    my $result = eval { parse_lower($src, 'while-spawn.isf') };
    ok($result, 'while-contained repeat-body spawn + await_all lowers cleanly') or diag($@);
    my $fsm = $result->{files}{'while_spawn.fsm'};

    # spawn asserts the instance start, await_all drains the instance done, then repeat_check
    like($fsm, qr/\(parent_spawn_\d+\b.*?\(=\s*\(w0_start>\s*1\)\).*?->\s*parent_await_all_\d+/s,
        'spawn asserts w0_start then proceeds to await_all');
    like($fsm, qr/\(parent_await_all_\d+\b.*?->\s*parent_repeat_check_\d+\s*<w0_done/s,
        'await_all drains w0_done before repeat_check (the drain happens before the loop can re-enter)');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_spawn_\d+\)\).*?\(=0\s*\(->\s*parent_while_check_\d+\)\)/s,
        'repeat_check decrements, re-runs the repeat (spawn) or returns to the while check');

    # the generated child is instantiated in the _top composition
    ok(exists $result->{files}{'worker.fsm'}, 'the spawned child module worker.fsm is emitted');
    my $top = $result->{files}{'while_spawn_top.fsm'};
    like($top, qr/\(\?fsmc:w0 worker\b/s, 'the composition instantiates the spawned child w0');
};

subtest 'until-contained and deeper-nested (when-in-when) repeat-body spawn + await_all lower' => sub {
    my $until = <<'ISF';
(actor until_spawn
  (clock clk)
  (reset rst_n)
  (interface (input start) (input cond) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (until cond
      (repeat loops
        (spawn worker as w0)
        (await_all done)))
    (complete done))
  (transaction worker (complete done)))
ISF
    my $r1 = eval { parse_lower($until, 'until-spawn.isf') };
    ok($r1, 'until-contained repeat-body spawn + await_all lowers cleanly') or diag($@);
    ok(exists $r1->{files}{'worker.fsm'}, 'until: spawned child emitted');

    my $deeper = <<'ISF';
(actor when_when_spawn
  (clock clk)
  (reset rst_n)
  (interface (input start) (input c1) (input c2) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (when c1
      (when c2
        (repeat loops
          (spawn worker as w0)
          (await_all done))))
    (complete done))
  (transaction worker (complete done)))
ISF
    my $r2 = eval { parse_lower($deeper, 'when-when-spawn.isf') };
    ok($r2, 'when-inside-when repeat-body spawn + await_all lowers cleanly') or diag($@);
    ok(exists $r2->{files}{'worker.fsm'}, 'deeper-nested: spawned child emitted');
};

subtest 'single-pending await_any drains; undrained spawn and multi-pending await_any stay deferred' => sub {
    my $await_any = <<'ISF';
(actor while_spawn_any
  (clock clk)
  (reset rst_n)
  (interface (input start) (input cond) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (spawn worker as w0)
        (await_any done)))
    (complete done))
  (transaction worker (complete done)))
ISF
    my $r = eval { parse_lower($await_any, 'await-any.isf') };
    ok($r, 'single-pending (await_any done) drains a loop-contained spawn') or diag($@);

    my $undrained = <<'ISF';
(actor while_spawn_undrained
  (clock clk)
  (reset rst_n)
  (interface (input start) (input cond) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (spawn worker as w0)))
    (complete done))
  (transaction worker (complete done)))
ISF
    my $ok1 = eval { parse_lower($undrained, 'undrained.isf'); 1 };
    ok(!$ok1, 'undrained loop-contained spawn is rejected');
    like($@, qr/loop-contained repeat-body spawn requires same-body '\(await_all done\)' or single-pending '\(await_any done\)'/,
        'undrained spawn emits the drain-requirement diagnostic');

    my $multi = <<'ISF';
(actor while_spawn_multi
  (clock clk)
  (reset rst_n)
  (interface (input start) (input cond) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (spawn worker as w0)
        (spawn worker as w1)
        (await_any done)))
    (complete done))
  (transaction worker (complete done)))
ISF
    # A multi-pending (await_any done) followed by a later (await_all done) is
    # now supported (see t/1384); an UNDRAINED multi-pending await_any (no later
    # await_all) trips the specific await_any drain requirement -- outstanding
    # children at the repeat check.
    my $ok2 = eval { parse_lower($multi, 'multi.isf'); 1 };
    ok(!$ok2, 'an undrained multi-pending await_any in a loop-contained repeat is rejected');
    like($@, qr/loop-contained repeat-body multi-pending await_any requires later same-body '\(await_all done\)' before the repeat check can loop/,
        'an undrained multi-pending await_any trips the specific drain-requirement diagnostic');
};

done_testing();
