#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# A plain local (do child) directly inside a single (while ...)/(until ...)
# -contained repeat now LOWERS (see t/1379). The loop-contained do deferral
# now applies to the generated-do sub-case and to repeats reached through
# additional branch nesting.
subtest 'loop-contained repeat-body generated do emits the targeted diagnostic' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor while_repeat_generated_do_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (while cond
      (repeat loops
        (do worker)))
    (complete done))
  (transaction worker
    (complete done)))
ISF
        qr/Transaction 'parent': loop-contained repeat-body generated do remains deferred; only a plain local '\(do child\)' is supported inside a loop-contained repeat/,
        'while-contained repeat-body generated-child do is rejected with the targeted diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor until_repeat_generated_do_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (until cond
      (repeat loops
        (do worker)))
    (complete done))
  (transaction worker
    (complete done)))
ISF
        qr/Transaction 'parent': loop-contained repeat-body generated do remains deferred; only a plain local '\(do child\)' is supported inside a loop-contained repeat/,
        'until-contained repeat-body generated-child do is rejected with the targeted diagnostic',
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

subtest 'non-loop unsupported nested-repeat cases route through the deeper-nested diagnostic, not the loop-contained one' => sub {
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
        qr/Transaction 'parent': deeper-nested repeat-body do remains deferred/,
        'deeper when nesting routes through the deeper-nested diagnostic',
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
        qr/Transaction 'parent': deeper-nested repeat-body spawn remains deferred/,
        'when-inside-switch routes through the deeper-nested diagnostic',
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
