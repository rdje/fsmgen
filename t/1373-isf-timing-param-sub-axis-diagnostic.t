#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'repeat-count sub-axis emits its targeted diagnostic at all three keyword sites' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor repeat_spawn_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
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
        qr/Transaction 'parent': spawn instance 'w0' overrides repeat-count parameter 'ITER' on child 'worker'; activation-site parameter override-specialized repeat counts remain deferred/,
        'spawn override that changes a repeat-count parameter is rejected with the repeat-count diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor repeat_do_probe
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
        'do override that changes a repeat-count parameter is rejected with the repeat-count diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor repeat_trigger_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input fire)
    (output done))
  (transaction worker
    (params
      (ITER 4))
    (repeat ITER
      (wait 1))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (ITER 2)))))
ISF
        qr/Rule 'launch': trigger instance 'launch_worker_trigger_0' overrides repeat-count parameter 'ITER' on child 'worker'; activation-site parameter override-specialized repeat counts remain deferred/,
        'rule trigger override that changes a repeat-count parameter is rejected with the repeat-count diagnostic',
    );
};

subtest 'wait-count sub-axis emits its targeted diagnostic at all three keyword sites' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor wait_spawn_probe
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
        'spawn override that changes a wait-count parameter is rejected with the wait-count diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor wait_do_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (do worker
      (params
        (DELAY 2)))
    (complete done))
  (transaction worker
    (params
      (DELAY 4))
    (wait DELAY)
    (complete done)))
ISF
        qr/Transaction 'parent': do instance 'parent_worker_do_0' overrides wait-count parameter 'DELAY' on child 'worker'; activation-site parameter override-specialized wait counts remain deferred/,
        'do override that changes a wait-count parameter is rejected with the wait-count diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor wait_trigger_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input fire)
    (output done))
  (transaction worker
    (params
      (DELAY 4))
    (wait DELAY)
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (DELAY 2)))))
ISF
        qr/Rule 'launch': trigger instance 'launch_worker_trigger_0' overrides wait-count parameter 'DELAY' on child 'worker'; activation-site parameter override-specialized wait counts remain deferred/,
        'rule trigger override that changes a wait-count parameter is rejected with the wait-count diagnostic',
    );
};

subtest 'latency-bound sub-axis emits its targeted diagnostic at all three keyword sites' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor latency_spawn_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (LAT 2)))
    (complete done))
  (transaction worker
    (params
      (LAT 4))
    (latency (min LAT) (max LAT))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' overrides latency-bound parameter 'LAT' on child 'worker'; activation-site parameter override-specialized latency bounds remain deferred/,
        'spawn override that changes a latency-bound parameter is rejected with the latency-bound diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor latency_do_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (do worker
      (params
        (LAT 2)))
    (complete done))
  (transaction worker
    (params
      (LAT 4))
    (latency (min LAT) (max LAT))
    (complete done)))
ISF
        qr/Transaction 'parent': do instance 'parent_worker_do_0' overrides latency-bound parameter 'LAT' on child 'worker'; activation-site parameter override-specialized latency bounds remain deferred/,
        'do override that changes a latency-bound parameter is rejected with the latency-bound diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor latency_trigger_probe
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
        'rule trigger override that changes a latency-bound parameter is rejected with the latency-bound diagnostic',
    );
};

subtest 'watchdog-limit sub-axis emits its targeted diagnostic at all three keyword sites' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor watchdog_spawn_probe
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
        'spawn override that changes a watchdog-limit parameter is rejected with the watchdog-limit diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor watchdog_do_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction parent
    (on start)
    (do worker
      (params
        (WD_LIMIT 2)))
    (complete done))
  (transaction worker
    (params
      (WD_LIMIT 4))
    (await ack (watchdog WD_LIMIT))
    (complete done)))
ISF
        qr/Transaction 'parent': do instance 'parent_worker_do_0' overrides watchdog-limit parameter 'WD_LIMIT' on child 'worker'; activation-site parameter override-specialized watchdog limits remain deferred/,
        'do override that changes a watchdog-limit parameter is rejected with the watchdog-limit diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor watchdog_trigger_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input fire)
    (input ack)
    (output done))
  (transaction worker
    (params
      (WD_LIMIT 4))
    (await ack (watchdog WD_LIMIT))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (WD_LIMIT 2)))))
ISF
        qr/Rule 'launch': trigger instance 'launch_worker_trigger_0' overrides watchdog-limit parameter 'WD_LIMIT' on child 'worker'; activation-site parameter override-specialized watchdog limits remain deferred/,
        'rule trigger override that changes a watchdog-limit parameter is rejected with the watchdog-limit diagnostic',
    );
};

subtest 'same-value sub-axis overrides remain accepted (negative control)' => sub {
    my $lowered = lower_source(<<'ISF');
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
        $lowered->{files}{'worker.fsm'},
        qr/\(<= \(worker_cnt 4\)\)/,
        'same-value repeat-count override keeps the default-resolved repeat counter load',
    );
};

subtest 'unknown and shape diagnostics still take precedence over sub-axis gates' => sub {
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
      (ITER 4))
    (repeat ITER
      (wait 1))
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
        (ITER (4 4))))
    (complete done))
  (transaction worker
    (params
      (ITER 4))
    (repeat ITER
      (wait 1))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' parameter 'ITER' shape does not match child 'worker' declaration/,
        'shape mismatch still reports the shape diagnostic first',
    );
};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source(
        $source,
        'timing-param-sub-axis-diagnostic.isf',
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
