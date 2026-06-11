#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Locks scheduler-frontier #6 (completes the repeat-body-activation nesting
# frontier): a multi-pending (await_any done) -- an await_any observing two or
# more outstanding spawned children -- followed by a same-body (await_all done)
# drain now lowers inside a loop-contained or deeper-nested repeat, matching the
# top-level / when-body / switch-branch behavior. A multi-pending (await_any
# done) WITHOUT a later (await_all done) drain still fails closed (the end-of-
# routine drain requirement: outstanding children at the repeat check).
#
# Tree: ISF-LOOP-AND-DEEPER-REPEAT-BODY-MULTI-PENDING-AWAITANY-LOWERING

sub parse_lower {
    my ($src, $name) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($src, $name);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

subtest 'loop-contained multi-pending await_any + later await_all lowers' => sub {
    for my $loop (['while', 'while'], ['until', 'until']) {
        my ($kw) = @$loop;
        my $src = <<"ISF";
(actor mp_${kw}
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    ($kw cond
      (repeat loops
        (spawn worker as w0)
        (spawn worker as w1)
        (await_any done)
        (await_all done)))
    (complete done))
  (transaction worker
    (complete done)))
ISF
        my $result = eval { parse_lower($src, "mp-$kw.isf") };
        ok($result, "$kw-contained multi-pending await_any + await_all lowers cleanly") or diag($@);
        ok(exists $result->{files}{'worker.fsm'}, "$kw: spawned child emitted");
        my $fsm = $result->{files}{"mp_${kw}.fsm"};
        like($fsm, qr/parent_await_any_\d+/, "$kw: an await_any (sync_any) state is scheduled");
        like($fsm, qr/parent_await_all_\d+/, "$kw: an await_all (sync_all) drain state is scheduled");
    }
};

subtest 'deeper-nested (when-in-when) multi-pending await_any + await_all lowers' => sub {
    my $src = <<'ISF';
(actor mp_when_when
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
          (spawn worker as w0)
          (spawn worker as w1)
          (await_any done)
          (await_all done))))
    (complete done))
  (transaction worker
    (complete done)))
ISF
    my $result = eval { parse_lower($src, 'mp-when-when.isf') };
    ok($result, 'when-inside-when multi-pending await_any + await_all lowers cleanly') or diag($@);
    ok(exists $result->{files}{'worker.fsm'}, 'deeper-nested: spawned child emitted');
};

subtest 'a loop-contained multi-pending await_any WITHOUT a later await_all names the missing drain proof' => sub {
    my $undrained = <<'ISF';
(actor mp_undrained
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
        (spawn worker as w1)
        (await_any done)))
    (complete done))
  (transaction worker
    (complete done)))
ISF
    my $ok = eval { parse_lower($undrained, 'mp-undrained.isf'); 1 };
    ok(!$ok, 'an undrained multi-pending await_any is rejected');
    like($@, qr/loop-contained repeat-body multi-pending await_any requires later same-body '\(await_all done\)' before the repeat check can loop/,
        'the outstanding children trip the multi-pending await_any drain diagnostic');
};

subtest 'top-level and deeper-nested multi-pending await_any missing-drain diagnostics are specific' => sub {
    my $top_level = <<'ISF';
(actor mp_top_undrained
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0)
      (spawn worker as w1)
      (await_any done))
    (complete done))
  (transaction worker
    (complete done)))
ISF
    my $top_ok = eval { parse_lower($top_level, 'mp-top-undrained.isf'); 1 };
    ok(!$top_ok, 'a top-level undrained multi-pending await_any is rejected');
    like($@, qr/repeat-body multi-pending await_any requires later same-body '\(await_all done\)' before the repeat check can loop/,
        'top-level diagnostic names await_any as observation-only');

    my $deeper = <<'ISF';
(actor mp_deeper_undrained
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
          (spawn worker as w0)
          (spawn worker as w1)
          (await_any done))))
    (complete done))
  (transaction worker
    (complete done)))
ISF
    my $deeper_ok = eval { parse_lower($deeper, 'mp-deeper-undrained.isf'); 1 };
    ok(!$deeper_ok, 'a deeper-nested undrained multi-pending await_any is rejected');
    like($@, qr/deeper-nested repeat-body multi-pending await_any requires later same-body '\(await_all done\)' before the repeat check can loop/,
        'deeper-nested diagnostic names await_any as observation-only');
};

subtest 'parent-body sync cannot drain a repeat-body multi-pending await_any observation' => sub {
    my $parent_exit = <<'ISF';
(actor mp_parent_exit_undrained
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0)
      (spawn worker as w1)
      (await_any done))
    (await_all done)
    (complete done))
  (transaction worker
    (complete done)))
ISF
    my $ok = eval { parse_lower($parent_exit, 'mp-parent-exit-undrained.isf'); 1 };
    ok(!$ok, 'parent-body await_all after repeat does not drain repeat-body multi-pending await_any');
    like($@, qr/repeat-body multi-pending await_any cannot be drained by parent-body '\(await_all done\)' after the repeat exits; use same-body '\(await_all done\)' before the repeat check can loop/,
        'multi-pending parent-exit diagnostic names the same-body drain requirement');
};

done_testing();
