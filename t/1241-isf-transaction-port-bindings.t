#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub lower_source {
    my ($source, $label) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;
    my $ok = eval {
        lower_source($source, $label);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'blocking do binds transaction input and output ports in the review fsm' => sub {
    my $lowered = lower_source(<<'ISF', 'do-port-binding');
(actor do_port_binding
  (clock clk)
  (interface
    (input start)
    (input req_addr (width 8))
    (output done)
    (output resp (width 8)))
  (transaction child
    (ports
      (input addr (width 8))
      (output data (width 8)))
    (on child_start)
    (update data addr)
    (complete child_done))
  (transaction parent
    (on start)
    (do child
      (bind
        (input addr req_addr)
        (output data resp)))
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'do_port_binding.fsm'};
    like($fsm, qr/\(= \(addr req_addr\)\)/, 'do state drives child input port from the bound actor input');
    like($fsm, qr/\(= \(child_start 1\)\)/, 'do state still asserts child start');
    like($fsm, qr/\(= \(resp> data\) <child_done\)/, 'do state copies child output port to the bound actor output when done');
};

subtest 'spawn binds transaction ports through hidden generated-top handoffs' => sub {
    my $lowered = lower_source(<<'ISF', 'spawn-port-binding');
(actor spawn_port_binding
  (clock clk)
  (interface
    (input start)
    (input req_addr (width 8))
    (output done)
    (output resp (width 8)))
  (transaction child
    (ports
      (input addr (width 8))
      (output data (width 8)))
    (update data addr)
    (complete done))
  (transaction parent
    (on start)
    (spawn child as w0
      (bind
        (input addr req_addr)
        (output data resp)))
    (complete done)))
ISF

    my $parent_fsm = $lowered->{files}{'spawn_port_binding.fsm'};
    like($parent_fsm, qr/\(w0_addr 8\)/, 'parent exposes hidden input-binding handoff width');
    like($parent_fsm, qr/\(w0_data 8\)/, 'parent exposes hidden output-binding handoff width');
    like($parent_fsm, qr/\(-w0_port_bindings\s+\(= \(w0_addr> req_addr\)\)\s+\(= \(resp> w0_data\)\)\s+\)/s,
        'parent .fsm has reviewable live binding DT for spawn payload and response');

    my $child_fsm = $lowered->{files}{'child.fsm'};
    like($child_fsm, qr/\(addr 8\)/, 'spawned child exposes declared input transaction port');
    like($child_fsm, qr/\(data 8\)/, 'spawned child exposes declared output transaction port');

    my $top = $lowered->{files}{'spawn_port_binding_top.fsm'};
    like($top, qr{/spawn_port_binding\.w0_addr/w0\.addr/}, 'generated top wires parent input handoff to child input port');
    like($top, qr{/w0\.data/spawn_port_binding\.w0_data/}, 'generated top wires child output port to parent output handoff');
};

subtest 'rule trigger input bindings fan into transaction ports with per-rule payload signals' => sub {
    my $lowered = lower_source(<<'ISF', 'rule-trigger-port-binding');
(actor rule_trigger_port_binding
  (clock clk)
  (interface
    (input ready)
    (input req_addr (width 8))
    (output done))
  (transaction work
    (ports
      (input addr (width 8)))
    (on work_start)
    (complete done))
  (rule fire ready
    (trigger work
      (bind
        (input addr req_addr)))))
ISF

    my $fsm = $lowered->{files}{'rule_trigger_port_binding.fsm'};
    like($fsm, qr/\(fire_work_addr 8\)/, 'rule trigger payload source is sized from the transaction port');
    like($fsm, qr/\(-fire <ready\s+\(<1 \(fire_work 1\)\)\s+\(<- \(fire_work_addr req_addr\)\)\s+\)/s,
        'rule captures its trigger payload beside its distinct trigger pulse');
    like($fsm, qr/\(-work_trigger_fanin\s+\(= \(work_start fire_work\)\)\s+\(= \(addr fire_work_addr\) <fire_work\)\s+\)/s,
        'trigger fan-in routes the per-rule payload into the transaction input port');
};

subtest 'malformed activation bindings fail closed during lowering' => sub {
    assert_lower_rejected(<<'ISF', 'missing do bind', qr/\ATransaction 'parent': do target 'child' requires '\(bind \.\.\.\)' because transaction 'child' declares ports/);
(actor missing_do_bind
  (clock clk)
  (interface (input start) (input req_addr (width 8)) (output done))
  (transaction child
    (ports (input addr (width 8)))
    (on child_start)
    (complete done))
  (transaction parent
    (on start)
    (do child)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'width mismatch', qr/\ATransaction 'parent': do target 'child' binding for port 'addr' width 16 does not match actor signal 'req_addr' width 8/);
(actor width_mismatch
  (clock clk)
  (interface (input start) (input req_addr (width 8)) (output done))
  (transaction child
    (ports (input addr (width 16)))
    (on child_start)
    (complete done))
  (transaction parent
    (on start)
    (do child
      (bind (input addr req_addr)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'actor output readback', qr/\ATransaction 'parent': do target 'child' input binding for port 'addr' reads actor output 'resp', but actor output readback is not public/);
(actor output_readback
  (clock clk)
  (interface (input start) (output resp (width 8)) (output done))
  (transaction child
    (ports (input addr (width 8)))
    (on child_start)
    (complete done))
  (transaction parent
    (on start)
    (do child
      (bind (input addr resp)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'rule output binding', qr/\ARule 'fire': trigger target 'work' output binding for port 'data' is not supported on rule triggers yet/);
(actor rule_output_bind
  (clock clk)
  (interface (input ready) (output data (width 8)))
  (transaction work
    (ports (output data (width 8)))
    (on work_start)
    (complete data))
  (rule fire ready
    (trigger work
      (bind (output data data)))))
ISF
};

done_testing();
