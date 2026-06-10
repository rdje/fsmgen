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
# directly inside a single (while ...)/(until ...)-contained repeat now LOWER
# (see t/1379 and t/1380). The loop-contained do deferral now applies only to a
# generated repeat reached through the first loop-plus-branch shape, through
# broader loop/branch ancestors, and to a cross-domain generated do (its own
# cross-domain diagnostic).
subtest 'loop-plus-branch generated repeat-body do still defers' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor while_when_repeat_generated_do_probe
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
          (do worker (params (W 8))))))
    (complete done))
  (transaction worker
    (params (W 4))
    (complete done)))
ISF
        qr/Transaction 'parent': while-then-when repeat-body do supports only plain local '\(do child\)'/,
        'generated do in while-then-when repeat-body still routes through the loop-plus-branch diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor while_repeat_cross_domain_do_probe
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
        qr/Transaction 'parent': repeat-body generated do target 'worker' is in a different clock domain than the calling transaction; cross-domain repeat-body do remains deferred/,
        'a cross-domain generated do in a loop-contained repeat still defers with the cross-domain diagnostic',
    );
};

# The basic loop-contained repeat-body spawn + same-body (await_all done) subset
# is now SUPPORTED (see t/1383). An UNDRAINED loop-contained spawn stays deferred.
subtest 'undrained loop-contained repeat-body spawn emits the targeted diagnostic' => sub {
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
        (spawn worker as w0)))
    (complete done))
  (transaction worker
    (complete done)))
ISF
        qr/Transaction 'parent': loop-contained repeat-body spawn requires same-body '\(await_all done\)' or single-pending '\(await_any done\)'/,
        'undrained while-contained repeat-body spawn is rejected with the drain-requirement diagnostic',
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
        (spawn worker as w0)))
    (complete done))
  (transaction worker
    (complete done)))
ISF
        qr/Transaction 'parent': loop-contained repeat-body spawn requires same-body '\(await_all done\)' or single-pending '\(await_any done\)'/,
        'undrained until-contained repeat-body spawn is rejected with the drain-requirement diagnostic',
    );
};

subtest 'non-loop unsupported nested-repeat cases route through the deeper-nested diagnostic, not the loop-contained one' => sub {
    # A plain local AND a same-domain generated (do child) at deeper branch
    # nesting now lower (see t/1381, t/1382); a deeper-nested cross-domain
    # generated do still routes through the cross-domain lane.
    assert_lower_rejected(
        <<'ISF',
(actor double_nested_when_repeat_cross_domain_do_probe
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
        'deeper when nesting cross-domain do routes through the cross-domain diagnostic',
    );

    # Basic deeper-nested spawn + await_all is now supported (t/1383); an
    # UNDRAINED deeper-nested spawn still routes through the drain-requirement.
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
            (spawn worker as w0)))))
    (complete done))
  (transaction worker
    (complete done)))
ISF
        qr/Transaction 'parent': deeper-nested repeat-body spawn requires same-body '\(await_all done\)' or single-pending '\(await_any done\)'/,
        'undrained when-inside-switch spawn routes through the deeper-nested drain-requirement diagnostic',
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
