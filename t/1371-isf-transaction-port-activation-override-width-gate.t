#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'mismatched transaction port width parameter activation overrides fail closed' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor input_port_spawn_override
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input src (width 8))
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (W 16))
      (bind
        (input data src)))
    (complete done))
  (transaction worker
    (params
      (W 8))
    (ports
      (input data (width W)))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' overrides static port-width parameter 'W' on child 'worker'; activation-site parameter override-specialized transaction port widths remain deferred/,
        'spawn override that changes an input port width parameter is rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor output_port_do_override
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done)
    (output dst (width 8)))
  (transaction parent
    (on start)
    (do worker
      (params
        (W 16))
      (bind
        (output result dst)))
    (complete done))
  (transaction worker
    (params
      (W 8))
    (ports
      (output result (width W)))
    (complete done)))
ISF
        qr/Transaction 'parent': do instance 'parent_worker_do_0' overrides static port-width parameter 'W' on child 'worker'; activation-site parameter override-specialized transaction port widths remain deferred/,
        'generated do override that changes an output port width parameter is rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor rule_trigger_port_override
  (clock clk)
  (reset rst_n)
  (interface
    (input fire)
    (input src (width 8))
    (output done))
  (transaction worker
    (params
      (W 8))
    (ports
      (input data (width W)))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (W 16))
      (bind
        (input data src)))))
ISF
        qr/Rule 'launch': trigger instance 'launch_worker_trigger_0' overrides static port-width parameter 'W' on child 'worker'; activation-site parameter override-specialized transaction port widths remain deferred/,
        'rule trigger override that changes a port width parameter is rejected',
    );
};

subtest 'same-value transaction port width parameter overrides remain accepted' => sub {
    my $input_lowered = lower_source(<<'ISF');
(actor input_port_same_value
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input src (width 8))
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (W 8))
      (bind
        (input data src)))
    (complete done))
  (transaction worker
    (params
      (W 8))
    (ports
      (input data (width W)))
    (complete done)))
ISF
    ok($input_lowered,
        'same-value spawn override for an input port width parameter remains accepted');

    my $output_lowered = lower_source(<<'ISF');
(actor output_port_same_value
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done)
    (output dst (width 8)))
  (transaction parent
    (on start)
    (do worker
      (params
        (W 8))
      (bind
        (output result dst)))
    (complete done))
  (transaction worker
    (params
      (W 8))
    (ports
      (output result (width W)))
    (complete done)))
ISF
    ok($output_lowered,
        'same-value generated do override for an output port width parameter remains accepted');

    my $trigger_lowered = lower_source(<<'ISF');
(actor rule_trigger_port_same_value
  (clock clk)
  (reset rst_n)
  (interface
    (input fire)
    (input src (width 8))
    (output done))
  (transaction worker
    (params
      (W 8))
    (ports
      (input data (width W)))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (W 8))
      (bind
        (input data src)))))
ISF
    ok($trigger_lowered,
        'same-value rule trigger override for a port width parameter remains accepted');
};

subtest 'unrelated overrides and existing data-op/timing precedence are preserved' => sub {
    my $unrelated_lowered = lower_source(<<'ISF');
(actor unrelated_port_param_override
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input src (width 8))
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (UNRELATED 16))
      (bind
        (input data src)))
    (complete done))
  (transaction worker
    (params
      (W 8)
      (UNRELATED 4))
    (ports
      (input data (width W)))
    (complete done)))
ISF
    ok($unrelated_lowered,
        'override on a parameter not used by any port width remains accepted even with mismatched value');

    assert_lower_rejected(
        <<'ISF',
(actor data_op_port_precedence_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input src (width 8))
    (input bit_in)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (W 16))
      (bind
        (input data src)))
    (complete done))
  (transaction worker
    (params
      (W 8))
    (ports
      (input data (width W)))
    (shift_left data bit_in (width W))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' overrides static-width parameter 'W' on child 'worker'; activation-site parameter override-specialized data-op widths remain deferred/,
        'static-width (data-op) diagnostic takes precedence when the same parameter backs both a data-op width and a port width',
    );
};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source(
        $source,
        'transaction-port-activation-override-width-gate.isf',
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
