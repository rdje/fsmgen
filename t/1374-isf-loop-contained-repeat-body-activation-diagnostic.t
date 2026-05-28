#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'loop-contained repeat-body do emits the targeted diagnostic' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor while_repeat_do_probe
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
        qr/Transaction 'parent': loop-contained repeat-body do remains deferred/,
        'while-contained repeat-body do is rejected with the targeted diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor until_repeat_do_probe
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
        qr/Transaction 'parent': loop-contained repeat-body do remains deferred/,
        'until-contained repeat-body do is rejected with the targeted diagnostic',
    );
};

subtest 'loop-contained repeat-body spawn emits the targeted diagnostic' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor while_repeat_spawn_probe
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
        qr/Transaction 'parent': loop-contained repeat-body spawn remains deferred/,
        'while-contained repeat-body spawn is rejected with the targeted diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor until_repeat_spawn_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (until cond
      (repeat loops
        (spawn worker as w0)
        (await_all done)))
    (complete done))
  (transaction worker
    (complete done)))
ISF
        qr/Transaction 'parent': loop-contained repeat-body spawn remains deferred/,
        'until-contained repeat-body spawn is rejected with the targeted diagnostic',
    );
};

subtest 'non-loop unsupported nested-repeat cases keep the generic diagnostic' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor double_nested_when_repeat_do_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond1) (input cond2) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (when cond1
      (when cond2
        (repeat loops
          (do worker))))
    (complete done))
  (transaction worker
    (complete done)))
ISF
        qr/Transaction 'parent': repeat-body do is supported only for top-level repeat clauses, top-level when-body nested repeat clauses, or top-level switch-branch nested repeat clauses/,
        'deeper when nesting still emits the generic diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor switch_nested_when_repeat_spawn_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input mode) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (switch mode
      (0
        (when cond
          (repeat loops
            (spawn worker as w0)
            (await_all done)))))
    (complete done))
  (transaction worker
    (complete done)))
ISF
        qr/Transaction 'parent': repeat-body spawn is supported only for top-level repeat clauses, top-level when-body nested repeat clauses, or top-level switch-branch nested repeat clauses/,
        'when-inside-switch still emits the generic diagnostic',
    );
};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source(
        $source,
        'loop-contained-repeat-body-activation-diagnostic.isf',
    );
}

sub lower_source {
    my ($source) = @_;
    my $actor = parse_source($source);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_lower_rejected {
    my ($source, $pattern, $label) = @_;
    my $ok = eval {
        lower_source($source);
        1;
    };

    ok(!$ok, $label);
    like($@, $pattern, "$label diagnostic");
}
