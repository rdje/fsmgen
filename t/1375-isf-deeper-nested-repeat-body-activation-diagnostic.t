#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'deeper-when-nested repeat-body do emits the targeted diagnostic' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor deeper_when_repeat_do_probe
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
        'when-inside-when repeat-body do is rejected with the deeper-nested diagnostic',
    );
};

subtest 'deeper-when-nested repeat-body spawn emits the targeted diagnostic' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor deeper_when_repeat_spawn_probe
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
          (spawn worker as w0)
          (await_all done))))
    (complete done))
  (transaction worker
    (complete done)))
ISF
        qr/Transaction 'parent': deeper-nested repeat-body spawn remains deferred/,
        'when-inside-when repeat-body spawn is rejected with the deeper-nested diagnostic',
    );
};

subtest 'when-inside-switch repeat-body do emits the targeted diagnostic' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor when_in_switch_repeat_do_probe
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
            (do worker)))))
    (complete done))
  (transaction worker
    (complete done)))
ISF
        qr/Transaction 'parent': deeper-nested repeat-body do remains deferred/,
        'when-inside-switch-case repeat-body do is rejected with the deeper-nested diagnostic',
    );
};

subtest 'when-inside-switch repeat-body spawn emits the targeted diagnostic' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor when_in_switch_repeat_spawn_probe
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
        'when-inside-switch-case repeat-body spawn is rejected with the deeper-nested diagnostic',
    );
};

subtest 'loop-contained diagnostic still fires first (negative control)' => sub {
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
        'loop-contained still fires its targeted diagnostic first',
    );
};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source(
        $source,
        'deeper-nested-repeat-body-activation-diagnostic.isf',
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
