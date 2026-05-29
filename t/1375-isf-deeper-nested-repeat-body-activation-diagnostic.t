#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# A plain local (do child) AND a same-domain generated (do child (params ...))
# at deeper branch nesting (when+ -> repeat, switch -> when+ -> repeat) now LOWER
# (see t/1381 and t/1382). The remaining deeper-nested do deferral is the
# cross-domain sub-case.
subtest 'deeper-when-nested cross-domain repeat-body do emits the targeted diagnostic' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor deeper_when_repeat_cross_domain_do_probe
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface
    (input start (domain core)) (input cond1 (domain core)) (input cond2 (domain core))
    (input loops (width 3) (domain core)) (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (when cond1
      (when cond2
        (repeat loops
          (do worker (domain aux)))))
    (complete done))
  (transaction worker
    (domain aux)
    (complete done)))
ISF
        qr/cross-domain repeat-body do remains deferred/,
        'when-inside-when cross-domain repeat-body do is rejected with the cross-domain diagnostic',
    );
};

# The basic deeper-nested spawn + same-body (await_all done) subset is now
# SUPPORTED (see t/1383). An UNDRAINED deeper-nested spawn stays deferred.
subtest 'undrained deeper-when-nested repeat-body spawn emits the targeted diagnostic' => sub {
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
          (spawn worker as w0))))
    (complete done))
  (transaction worker
    (complete done)))
ISF
        qr/Transaction 'parent': deeper-nested repeat-body spawn requires same-body '\(await_all done\)' or single-pending '\(await_any done\)'/,
        'undrained when-inside-when repeat-body spawn is rejected with the deeper-nested drain-requirement diagnostic',
    );
};

subtest 'when-inside-switch cross-domain repeat-body do emits the targeted diagnostic' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor when_in_switch_repeat_cross_domain_do_probe
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface
    (input start (domain core)) (input mode (domain core)) (input cond (domain core))
    (input loops (width 3) (domain core)) (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (switch mode
      (0
        (when cond
          (repeat loops
            (do worker (domain aux))))))
    (complete done))
  (transaction worker
    (domain aux)
    (complete done)))
ISF
        qr/cross-domain repeat-body do remains deferred/,
        'when-inside-switch-case cross-domain repeat-body do is rejected with the cross-domain diagnostic',
    );
};

subtest 'undrained when-inside-switch repeat-body spawn emits the targeted diagnostic' => sub {
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
            (spawn worker as w0)))))
    (complete done))
  (transaction worker
    (complete done)))
ISF
        qr/Transaction 'parent': deeper-nested repeat-body spawn requires same-body '\(await_all done\)' or single-pending '\(await_any done\)'/,
        'undrained when-inside-switch-case repeat-body spawn is rejected with the deeper-nested drain-requirement diagnostic',
    );
};

# A plain local (do child) directly inside a single (while ...)/(until ...)
# -contained repeat now lowers (see t/1379). When a loop AND branch nesting
# both wrap the repeat, the loop-contained diagnostic still wins over the
# deeper-nested one — this negative control pins that precedence.
subtest 'loop-contained diagnostic still fires first (negative control)' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor while_when_repeat_do_probe
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
        qr/Transaction 'parent': loop-contained repeat-body do remains deferred/,
        'a repeat wrapped by both a loop and a when still routes through the loop-contained diagnostic first',
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
