#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::ControlFlowEffects;

sub parse_actor {
    my ($source, $name) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, "$name.isf");
}

sub plan_for {
    my ($source, $name) = @_;
    my $actor = parse_actor($source, $name);
    my $plan = FSM::Scheduler::ISF::ControlFlowEffects->new()->plan_actor($actor);
    return ($plan, $actor);
}

sub lower_actor {
    my ($actor) = @_;
    return FSM::Scheduler::ISF->new()->lower($actor);
}

subtest 'local child wire plan matches emitted local do handshakes' => sub {
    my ($plan, $actor) = plan_for(<<'ISF', 'plan-local-do');
(actor plan_local_do
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

    is($plan->{model}, 'isf_control_flow_child_plan_v1', 'plan advertises child-plan model');
    is($plan->{summary}{local_child_wire_count}, 1, 'one local child wire is planned');
    my ($wire) = @{$plan->{local_child_wires}};
    is($wire->{child}, 'worker', 'local wire names the child');
    is($wire->{start}, 'worker_start', 'local wire start matches lowering signal');
    is($wire->{done}, 'worker_done', 'local wire done matches lowering signal');
    is($wire->{region_kind}, 'repeat', 'local wire is owned by the repeat region');

    my $lowered = lower_actor($actor);
    my $fsm = $lowered->{files}{'plan_local_do.fsm'};
    like($fsm, qr/\(=\s*\(worker_start 1\)\)/, 'emitted schedule asserts planned local start');
    like($fsm, qr/<worker_done/, 'emitted schedule waits on planned local done');
};

subtest 'conditional generated do plan matches top instance identity' => sub {
    my ($plan, $actor) = plan_for(<<'ISF', 'plan-conditional-generated-do');
(actor plan_conditional_generated_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input cond)
    (input din (width 8))
    (output done)
    (output result (width 8)))
  (transaction parent
    (on start)
    (when cond
      (do worker
        (params (W 8))
        (bind (input data din) (output data_out result))))
    (complete done))
  (transaction worker
    (params (W 8))
    (on start)
    (ports (input data (width W)) (output data_out (width W)))
    (update data_out data)
    (complete done)))
ISF

    is($plan->{summary}{generated_instance_count}, 1, 'one generated child instance is planned');
    my ($instance) = @{$plan->{generated_instances}};
    is($instance->{activation}, 'do', 'plan records generated do activation');
    is($instance->{instance}, 'parent_worker_cond_do_0', 'conditional do instance name matches current lowering');
    is($instance->{start}, 'parent_worker_cond_do_0_start', 'conditional do start handoff planned');
    is($instance->{done}, 'parent_worker_cond_do_0_done', 'conditional do done handoff planned');
    is(scalar(@{$instance->{bindings}}), 2, 'binding handoffs are carried into the plan');

    my $lowered = lower_actor($actor);
    my $top = $lowered->{files}{'plan_conditional_generated_do_top.fsm'};
    like($top, qr/\(\?fsmc:parent_worker_cond_do_0 worker\b/, 'top instantiates planned conditional generated child');
    like($top, qr/parent_worker_cond_do_0\.start/, 'top wires planned start handoff');
    like($top, qr/parent_worker_cond_do_0\.done/, 'top wires planned done handoff');
};

subtest 'repeat generated do plan keeps repeat instance naming stable' => sub {
    my ($plan, $actor) = plan_for(<<'ISF', 'plan-repeat-generated-do');
(actor plan_repeat_generated_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (do worker (params (W 8)))))
    (complete done))
  (transaction worker
    (params (W 8))
    (on start)
    (complete done)))
ISF

    my ($instance) = @{$plan->{generated_instances}};
    is($instance->{instance}, 'parent_worker_repeat_do_0', 'repeat generated do instance name matches current lowering');
    is($instance->{region_kind}, 'repeat', 'repeat generated do plan is owned by the repeat region');
    is($instance->{context}, 'repeat body', 'repeat generated do context is explicit');

    my $lowered = lower_actor($actor);
    my $top = $lowered->{files}{'plan_repeat_generated_do_top.fsm'};
    like($top, qr/\(\?fsmc:parent_worker_repeat_do_0 worker\b/, 'top instantiates planned repeat generated child');
};

subtest 'spawn fan-out plan matches generated top instances and sync points' => sub {
    my ($plan, $actor) = plan_for(<<'ISF', 'plan-spawn-fanout');
(actor plan_spawn_fanout
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
        (spawn worker as w1)
        (await_any done)
        (await_all done)))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    is_deeply([map { $_->{instance} } @{$plan->{generated_instances}}], [qw(w0 w1)],
        'spawn fan-out plan preserves source instance order');
    is_deeply([map { $_->{start} } @{$plan->{generated_instances}}], [qw(w0_start w1_start)],
        'spawn start handoffs are planned');
    is_deeply([map { $_->{activation} } @{$plan->{sync_points}}], [qw(await_any await_all)],
        'spawn sync points are planned in source order');

    my $lowered = lower_actor($actor);
    my $top = $lowered->{files}{'plan_spawn_fanout_top.fsm'};
    like($top, qr/\(\?fsmc:w0 worker\b/, 'top instantiates planned spawn w0');
    like($top, qr/\(\?fsmc:w1 worker\b/, 'top instantiates planned spawn w1');
};

done_testing();
