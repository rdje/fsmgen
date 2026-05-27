#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'mismatched static timing parameter activation overrides fail closed' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor wait_override_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (DELAY 2)))
    (complete done))
  (transaction worker
    (params
      (DELAY 4))
    (wait DELAY)
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' overrides wait-count parameter 'DELAY' on child 'worker'; activation-site parameter override-specialized wait counts remain deferred/,
        'spawn override that changes a wait-count parameter is rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor repeat_override_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (do worker
      (params
        (ITER 2)))
    (complete done))
  (transaction worker
    (params
      (ITER 4))
    (repeat ITER
      (wait 1))
    (complete done)))
ISF
        qr/Transaction 'parent': do instance 'parent_worker_do_0' overrides repeat-count parameter 'ITER' on child 'worker'; activation-site parameter override-specialized repeat counts remain deferred/,
        'generated do override that changes a repeat-count parameter is rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor latency_override_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input fire)
    (output done))
  (transaction worker
    (params
      (LAT 4))
    (latency (min LAT) (max LAT))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (LAT 2)))))
ISF
        qr/Rule 'launch': trigger instance 'launch_worker_trigger_0' overrides latency-bound parameter 'LAT' on child 'worker'; activation-site parameter override-specialized latency bounds remain deferred/,
        'rule trigger override that changes a latency-bound parameter is rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor watchdog_override_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WD_LIMIT 2)))
    (complete done))
  (transaction worker
    (params
      (WD_LIMIT 4))
    (await ack (watchdog WD_LIMIT))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' overrides watchdog-limit parameter 'WD_LIMIT' on child 'worker'; activation-site parameter override-specialized watchdog limits remain deferred/,
        'spawn override that changes a top-level await-local watchdog parameter is rejected',
    );
};

subtest 'same-value static timing parameter overrides remain accepted' => sub {
    my $wait_lowered = lower_source(<<'ISF');
(actor wait_same_value_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (DELAY 3'd4)))
    (complete done))
  (transaction worker
    (params
      (DELAY 4))
    (wait DELAY)
    (complete done)))
ISF
    like(
        $wait_lowered->{files}{'worker.fsm'},
        qr/worker_wait_3/,
        'same-value wait override keeps the default-resolved wait expansion',
    );
    like(
        $wait_lowered->{files}{'wait_same_value_probe_top.fsm'},
        qr/\(\?fsmc:w0 worker\s+\(params\s+\(DELAY 3'd4\)\s+\)\s+\)/s,
        'same-value wait override remains published on the generated instance',
    );

    my $repeat_lowered = lower_source(<<'ISF');
(actor repeat_same_value_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (do worker
      (params
        (ITER 4)))
    (complete done))
  (transaction worker
    (params
      (ITER 4))
    (repeat ITER
      (wait 1))
    (complete done)))
ISF
    like(
        $repeat_lowered->{files}{'worker.fsm'},
        qr/\(<= \(worker_cnt 4\)\)/,
        'same-value repeat override keeps the default-resolved repeat counter load',
    );

    my $latency_lowered = lower_source(<<'ISF');
(actor latency_same_value_probe
  (clock clk)
  (reset rst_n)
  (constants
    (MATCH_LAT 4))
  (interface
    (input fire)
    (output done))
  (transaction worker
    (params
      (LAT 4))
    (latency (min LAT) (max LAT))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (LAT MATCH_LAT)))))
ISF
    like(
        $latency_lowered->{files}{'latency_same_value_probe_top.fsm'},
        qr/\(\?fsmc:launch_worker_trigger_0 worker\s+\(params\s+\(LAT 4\)\s+\)\s+\)/s,
        'same-value latency override may resolve through an actor constant',
    );

    my $watchdog_lowered = lower_source(<<'ISF');
(actor watchdog_same_value_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WD_LIMIT 4)))
    (complete done))
  (transaction worker
    (params
      (WD_LIMIT 4))
    (await ack (watchdog WD_LIMIT))
    (complete done)))
ISF
    like(
        $watchdog_lowered->{files}{'worker.fsm'},
        qr/\(<= \(worker_wd \(- 4 1\)\)\)/,
        'same-value watchdog override keeps the default-resolved watchdog init',
    );
};

subtest 'unrelated overrides and existing diagnostic precedence are preserved' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor unknown_override_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (UNKNOWN 4)))
    (complete done))
  (transaction worker
    (params
      (DELAY 4))
    (wait DELAY)
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' overrides unknown parameter 'UNKNOWN' on child 'worker'/,
        'unknown override still reports the unknown-parameter diagnostic first',
    );

    assert_lower_rejected(
        <<'ISF',
(actor shape_override_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (DELAY (4 4))))
    (complete done))
  (transaction worker
    (params
      (DELAY 4))
    (wait DELAY)
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' parameter 'DELAY' shape does not match child 'worker' declaration/,
        'shape mismatch still reports the shape diagnostic first',
    );

    my $lowered = lower_source(<<'ISF');
(actor unrelated_override_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WIDTH 8)))
    (complete done))
  (transaction worker
    (params
      (WIDTH 4)
      (DELAY 4))
    (wait DELAY)
    (complete done)))
ISF
    like(
        $lowered->{files}{'unrelated_override_probe_top.fsm'},
        qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 8\)\s+\)\s+\)/s,
        'override of a parameter unrelated to static timing remains accepted',
    );
};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source(
        $source,
        'timing-param-activation-override-gates.isf',
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
