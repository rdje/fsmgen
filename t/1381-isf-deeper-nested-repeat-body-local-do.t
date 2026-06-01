#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Locks scheduler-frontier #3: a plain local (do child) inside a (repeat N ...)
# reached through more than one branch ancestor -- when-inside-when
# (when+ -> repeat) or when-inside-a-switch-branch (switch -> when+ -> repeat) --
# now lowers. The lowering reuses the proven nested branch + repeat recursion.
# Deeper-nested generated do and spawn stay deferred.
#
# Tree: ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING

sub parse_lower {
    my ($src, $name) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($src, $name);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

subtest 'when-inside-when repeat-body local do lowers' => sub {
    my $src = <<'ISF';
(actor when_when_repeat_do
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
          (do worker))))
    (complete done))
  (transaction worker
    (complete done)))
ISF
    my $result = eval { parse_lower($src, 'when-when-do.isf') };
    ok($result, 'when-inside-when repeat-body local do lowers cleanly') or diag($@);
    my $fsm = $result->{files}{'when_when_repeat_do.fsm'};

    # two nested when guards reach the repeat block
    like($fsm, qr/\(parent_when_\d+\b.*?\?c1.*?->\s*parent_when_\d+/s,
        'outer when tests c1 and enters the inner when');
    like($fsm, qr/\(parent_when_\d+\b.*?\?c2.*?->\s*parent_repeat_init_\d+/s,
        'inner when tests c2 and enters repeat_init');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(worker_start 1\)\).*?\(<worker_done.*?->\s*parent_repeat_check_\d+/s,
        'local do asserts worker_start, awaits worker_done, then repeat_check');
    like($fsm, qr/\(parent_repeat_check_\d+\b.*?\(--\s*parent_cnt\).*?\(>0\s*\(->\s*parent_do_\d+\)\)/s,
        'repeat_check decrements and re-runs the repeat (do)');
};

subtest 'switch-branch -> when repeat-body local do lowers' => sub {
    my $src = <<'ISF';
(actor switch_when_repeat_do
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
            (do worker)))))
    (complete done))
  (transaction worker
    (complete done)))
ISF
    my $result = eval { parse_lower($src, 'switch-when-do.isf') };
    ok($result, 'switch-branch -> when repeat-body local do lowers cleanly') or diag($@);
    my $fsm = $result->{files}{'switch_when_repeat_do.fsm'};
    like($fsm, qr/parent_repeat_init_\d+/, 'the repeat block reaches the scheduled .fsm');
    like($fsm, qr/\(parent_do_\d+\b.*?\(=\s*\(worker_start 1\)\)/s,
        'the local do reaches the scheduled .fsm inside the switch->when->repeat');
};

# NOTE: same-domain generated do at deeper branch nesting is now SUPPORTED
# (see t/1382). This subtest covers the deferral that remains for the local-do
# scope: spawn at deeper branch nesting.
# NOTE: the basic deeper-nested spawn + same-body (await_all done) subset is now
# SUPPORTED (see t/1383). An UNDRAINED deeper-nested spawn stays deferred.
subtest 'undrained deeper-nested spawn stays deferred' => sub {
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
    like($@, qr/Transaction 'parent': deeper-nested repeat-body spawn requires same-body '\(await_all done\)' or single-pending '\(await_any done\)'/,
        'an undrained deeper-nested spawn stays deferred');
};

done_testing();
