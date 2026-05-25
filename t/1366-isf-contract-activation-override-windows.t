#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'activation overrides of contract-window parameters fail closed' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor spawn_contract_window_override
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
        (ACK_WINDOW 2)))
    (complete done))
  (transaction worker
    (params
      (ACK_WINDOW 4))
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' overrides contract-window parameter 'ACK_WINDOW' on child 'worker'; activation-site parameter override-specialized contract windows remain deferred/,
        'spawn override of a contract-window parameter is rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor do_contract_window_override
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
        (ACK_WINDOW 2)))
    (complete done))
  (transaction worker
    (params
      (ACK_WINDOW 4))
    (contract ack_seen (eventually ack within ACK_WINDOW))
    (complete done)))
ISF
        qr/Transaction 'parent': do instance 'parent_worker_do_0' overrides contract-window parameter 'ACK_WINDOW' on child 'worker'; activation-site parameter override-specialized contract windows remain deferred/,
        'generated do override of a contract-window parameter is rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor trigger_contract_window_override
  (clock clk)
  (reset rst_n)
  (interface
    (input fire)
    (input ack)
    (output done))
  (transaction worker
    (params
      (ACK_WINDOW 4))
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (ACK_WINDOW 2)))))
ISF
        qr/Rule 'launch': trigger instance 'launch_worker_trigger_0' overrides contract-window parameter 'ACK_WINDOW' on child 'worker'; activation-site parameter override-specialized contract windows remain deferred/,
        'rule trigger override of a contract-window parameter is rejected',
    );
};

subtest 'unrelated activation overrides and default contract windows remain accepted' => sub {
    my $source = <<'ISF';
(actor unrelated_contract_window_override
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
        (WIDTH 16)))
    (complete done))
  (transaction worker
    (params
      (WIDTH 8)
      (ACK_WINDOW 4))
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF

    my $lowered = lower_source($source);
    like(
        $lowered->{files}{'worker.fsm'},
        qr/\(== worker_contract_0_age 3\)/,
        'child contract window still resolves from the transaction default',
    );
    like(
        $lowered->{files}{'unrelated_contract_window_override_top.fsm'},
        qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'unrelated activation override remains accepted in the generated top',
    );
};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source(
        $source,
        'contract-activation-override-window.isf',
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
