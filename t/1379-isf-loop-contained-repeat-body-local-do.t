#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Locks scheduler-frontier #1: a plain local (do child) inside a (repeat N ...)
# that sits directly in one (while ...)/(until ...) body now lowers cleanly.
# This is a validator gate relaxation; the lowering reuses the proven top-level
# repeat structure (repeat_init -> blocking-do -> repeat_check). spawn,
# generated do, and deeper nesting stay deferred.
#
# Tree: ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING

sub parse_lower {
    my ($src, $name) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($src, $name);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

subtest 'while-contained repeat-body local do lowers to the proven repeat schedule' => sub {
    my $src = <<'ISF';
(actor while_repeat_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (do worker)))
    (complete done))
  (transaction worker
    (complete done)))
ISF
    my $result = eval { parse_lower($src, 'while-repeat-do.isf') };
    ok($result, 'while-contained repeat-body local do lowers cleanly') or diag($@);
    my $fsm = $result->{files}{'while_repeat_do.fsm'};

    # while pre-test wraps the repeat block
    like($fsm, qr/\(parent_while_entry_\d+\b.*?\?cond.*?->\s*parent_repeat_init_\d+.*?->\s*parent_done_\d+/s,
        'while entry tests cond: true enters repeat_init, false exits to done');
    # repeat_init seeds the counter from the (loops) bound each loop iteration
    like($fsm, qr/\(parent_repeat_init_\d+\b.*?\(<=\s*\(parent_cnt loops\)\)/s,
        'repeat_init seeds parent_cnt from loops');
    # blocking local do: assert worker_start, await worker_done, then repeat_check
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(worker_start 1\)\).*?\(<worker_done.*?->\s*parent_repeat_check_\d+/s,
        'local do asserts worker_start, awaits worker_done, then repeat_check');
    # repeat_check decrements and either re-runs the repeat or returns to the loop check
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(!=0\s*\(->\s*parent_do_\d+\)\).*?\(=0\s*\(->\s*parent_while_check_\d+\)\)/s,
        'repeat_check decrements parent_cnt; nonzero re-runs repeat (do), zero returns to while_check');
    # the loop re-test exists and re-enters the repeat block
    like($fsm, qr/\(parent_while_check_\d+\b.*?\?cond/s,
        'while_check re-tests cond after the repeat block drains');
};

subtest 'until-contained repeat-body local do lowers (post-test loop)' => sub {
    my $src = <<'ISF';
(actor until_repeat_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (until cond
      (repeat loops
        (do worker)))
    (complete done))
  (transaction worker
    (complete done)))
ISF
    my $result = eval { parse_lower($src, 'until-repeat-do.isf') };
    ok($result, 'until-contained repeat-body local do lowers cleanly') or diag($@);
    my $fsm = $result->{files}{'until_repeat_do.fsm'};

    like($fsm, qr/\(parent_repeat_init_\d+\b.*?\(<=\s*\(parent_cnt loops\)\)/s,
        'repeat_init seeds parent_cnt from loops');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(worker_start 1\)\).*?\(<worker_done.*?->\s*parent_repeat_check_\d+/s,
        'local do asserts worker_start, awaits worker_done, then repeat_check');
    # post-test: repeat drains to until_check, which exits on cond or re-runs the repeat
    like($fsm, qr/\(parent_until_check_\d+\b.*?\?cond.*?->\s*parent_done_\d+.*?->\s*parent_repeat_init_\d+/s,
        'until_check exits to done when cond holds, else re-runs the repeat block');
};

# NOTE: same-domain generated do (t/1380) and the basic spawn + same-body
# (await_all done) subset (t/1383) in a loop-contained repeat are now SUPPORTED.
# This subtest covers deferrals that remain: an UNDRAINED spawn, and a repeat
# reached through an extra branch ancestor.
subtest 'undrained loop-contained repeat-body spawn and deeper nesting stay deferred' => sub {
    # An undrained spawn (no same-body await_all/await_any) stays deferred.
    my $spawn = <<'ISF';
(actor while_repeat_spawn
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (spawn worker as w0)))
    (complete done))
  (transaction worker
    (complete done)))
ISF
    my $ok2 = eval { parse_lower($spawn, 'spawn.isf'); 1 };
    ok(!$ok2, 'undrained loop-contained repeat-body spawn is rejected');
    like($@, qr/Transaction 'parent': loop-contained repeat-body spawn requires same-body '\(await_all done\)' or single-pending '\(await_any done\)'/,
        'an undrained spawn in a loop-contained repeat stays deferred');

    # when-inside-while local do stays deferred via the loop-contained diagnostic
    my $when_in_while = <<'ISF';
(actor while_when_repeat_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input c1) (input c2) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while c1
      (when c2
        (repeat loops
          (do worker))))
    (complete done))
  (transaction worker
    (complete done)))
ISF
    my $ok3 = eval { parse_lower($when_in_while, 'when-in-while.isf'); 1 };
    ok(!$ok3, 'when-inside-while repeat-body local do is rejected');
    like($@, qr/Transaction 'parent': loop-contained repeat-body do remains deferred/,
        'a repeat reached through when-inside-while stays deferred (not a single direct loop body)');
};

done_testing();
