#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

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
    like($top, qr/\(spawn_port_binding\.w0_addr w0\.addr\)/, 'generated top wires parent input handoff to child input port');
    like($top, qr/\(w0\.data spawn_port_binding\.w0_data\)/, 'generated top wires child output port to parent output handoff');
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

subtest 'activation input bindings accept expression-valued runtime payloads' => sub {
    my $source = <<'ISF';
(actor expression_port_binding
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input req_hi (width 4))
    (input req_lo (width 4))
    (output done))
  (storage
    (var local_sink (width 8))
    (var spawn_sink (width 8))
    (var work_sink (width 8)))
  (transaction local_child
    (ports
      (input addr (width 8)))
    (on local_child_start)
    (update local_sink addr)
    (complete local_child_done))
  (transaction spawned_child
    (ports
      (input addr (width 8)))
    (update spawn_sink addr)
    (complete done))
  (transaction work
    (ports
      (input work_addr (width 8)))
    (on work_start)
    (update work_sink work_addr)
    (complete done))
  (transaction parent
    (on start)
    (do local_child
      (bind
        (input addr (concat req_hi req_lo))))
    (spawn spawned_child as w0
      (bind
        (input addr (concat req_hi req_lo))))
    (await_all done)
    (complete done))
  (rule fire start
    (trigger work
      (bind
        (input work_addr (concat req_hi req_lo))))))
ISF

    my $lowered = lower_source($source, 'expression-port-binding');
    my $fsm = $lowered->{files}{'expression_port_binding.fsm'};
    like($fsm, qr/\(= \(addr \(concat req_hi req_lo\)\)\)/,
        'local do input binding preserves expression RHS in the review fsm');
    like($fsm, qr/\(-w0_port_bindings\s+\(= \(w0_addr> \(concat req_hi req_lo\)\)\)\s+\)/s,
        'spawn input binding preserves expression RHS in the parent handoff DT');
    like($fsm, qr/\(<- \(fire_work_work_addr \(concat req_hi req_lo\)\)\)/,
        'rule trigger input binding captures expression payload into its per-rule source');

    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'expression_port_binding.isf');
    write_file($path, $source);
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--outdir',
            $dir,
            $path,
        ],
    );

    ok($success, 'expression-valued activation bindings reach SystemVerilog generation');
    is(join('', @{$stderr_buf || []}), '', 'expression-valued activation binding HDL generation keeps stderr clean');
};

subtest 'explicit input binding timing syntax accepts current timing classes' => sub {
    my $source = <<'ISF';
(actor explicit_binding_timing
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input fire)
    (input req_addr (width 8))
    (output done))
  (storage
    (var local_sink (width 8))
    (var spawn_sink (width 8))
    (var work_sink (width 8)))
  (transaction local_child
    (ports
      (input addr (width 8)))
    (on local_child_start)
    (update local_sink addr)
    (complete local_child_done))
  (transaction spawned_child
    (ports
      (input addr (width 8)))
    (update spawn_sink addr)
    (complete done))
  (transaction work
    (ports
      (input work_addr (width 8)))
    (on work_start)
    (update work_sink work_addr)
    (complete done))
  (transaction parent
    (on start)
    (do local_child
      (bind
        (input addr req_addr (timing snapshot))))
    (spawn spawned_child as w0
      (bind
        (input addr req_addr (timing live))))
    (await_all done)
    (complete done))
  (rule fire_rule fire
    (trigger work
      (bind
        (input work_addr req_addr (timing snapshot))))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'explicit-binding-timing.isf');
    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'explicit_binding_timing.fsm'};
    like($fsm, qr/\(= \(addr req_addr\)\)/, 'snapshot timing keeps local do input assignment');
    like($fsm, qr/\(-w0_port_bindings\s+\(= \(w0_addr> req_addr\)\)\s+\)/s,
        'live timing keeps generated-top spawn input handoff');
    like($fsm, qr/\(<- \(fire_rule_work_work_addr req_addr\)\)/,
        'snapshot timing keeps rule trigger payload capture');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [map { $_->{site_kind} . ':' . $_->{port} . ':' . $_->{binding_timing} } @{$report->{transaction_port_bindings}}],
        [
            'do:addr:activation_region',
            'spawn:addr:generated_live_handoff',
            'rule_trigger:work_addr:trigger_payload',
        ],
        'explicit timing syntax preserves the shipped binding timing report classes',
    );
    is_deeply(
        [map { $_->{site_kind} . ':' . $_->{port} . ':' . ($_->{authored_timing_mode} // 'null') } @{$report->{transaction_port_bindings}}],
        [
            'do:addr:snapshot',
            'spawn:addr:live',
            'rule_trigger:work_addr:snapshot',
        ],
        'explicit timing syntax reports authored timing modes separately from binding timing',
    );
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

    assert_lower_rejected(<<'ISF', 'rule output binding', qr/\ARule 'fire': trigger target 'work' output binding for port 'data' requires a generated-child rule trigger completion identity; direct\/local rule-trigger targets do not provide one yet/);
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

    assert_lower_rejected(<<'ISF', 'unknown expression input', qr/\ATransaction 'parent': do target 'child' input binding expression for port 'addr' references unknown actor signal 'missing_lo'/);
(actor unknown_expression_input
  (clock clk)
  (interface (input start) (input req_hi (width 4)) (output done))
  (transaction child
    (ports (input addr (width 8)))
    (on child_start)
    (complete done))
  (transaction parent
    (on start)
    (do child
      (bind (input addr (concat req_hi missing_lo))))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'expression width mismatch', qr/\ATransaction 'parent': do target 'child' input binding expression for port 'addr' width 8 does not match transaction port width 7/);
(actor expression_width_mismatch
  (clock clk)
  (interface (input start) (input req_hi (width 4)) (input req_lo (width 4)) (output done))
  (transaction child
    (ports (input addr (width 7)))
    (on child_start)
    (complete done))
  (transaction parent
    (on start)
    (do child
      (bind (input addr (concat req_hi req_lo))))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'output expression target', qr/\ATransaction 'parent': do target 'child' output bind actor target must be a scalar HDL identifier/);
(actor output_expression_target
  (clock clk)
  (interface (input start) (output done) (output resp_hi (width 4)) (output resp_lo (width 4)))
  (transaction child
    (ports (output data (width 8)))
    (on child_start)
    (complete done))
  (transaction parent
    (on start)
    (do child
      (bind (output data (concat resp_hi resp_lo))))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'duplicate output actor target', qr/\ATransaction 'parent': do target 'child' output bindings target actor signal 'resp' more than once/);
(actor duplicate_output_actor_target
  (clock clk)
  (interface (input start) (output done) (output resp (width 8)))
  (transaction child
    (ports
      (output data (width 8))
      (output sideband (width 8)))
    (on child_start)
    (update data 0)
    (update sideband 0)
    (complete child_done))
  (transaction parent
    (on start)
    (do child
      (bind
        (output data resp)
        (output sideband resp)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'local live timing mismatch', qr/\ATransaction 'parent': do target 'child' input binding for port 'addr' requested timing 'live', but this activation currently uses 'activation_region'/);
(actor local_live_timing
  (clock clk)
  (interface (input start) (input req_addr (width 8)) (output done))
  (transaction child
    (ports (input addr (width 8)))
    (on child_start)
    (complete child_done))
  (transaction parent
    (on start)
    (do child
      (bind (input addr req_addr (timing live))))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'spawn snapshot timing mismatch', qr/\ATransaction 'parent': spawn target 'child' input binding for port 'addr' requested timing 'snapshot', but this activation currently uses 'generated_live_handoff'/);
(actor spawn_snapshot_timing
  (clock clk)
  (interface (input start) (input req_addr (width 8)) (output done))
  (transaction child
    (ports (input addr (width 8)))
    (complete done))
  (transaction parent
    (on start)
    (spawn child as w0
      (bind (input addr req_addr (timing snapshot))))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'output timing rejected', qr/\ATransaction 'parent': do target 'child' output bind timing selection is supported only on input bindings/);
(actor output_timing
  (clock clk)
  (interface (input start) (output done) (output resp (width 8)))
  (transaction child
    (ports (output data (width 8)))
    (on child_start)
    (update data 0)
    (complete child_done))
  (transaction parent
    (on start)
    (do child
      (bind (output data resp (timing snapshot))))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'unknown timing rejected', qr/\ATransaction 'parent': do target 'child' input bind timing must be '\(timing snapshot\)' or '\(timing live\)'/);
(actor unknown_timing
  (clock clk)
  (interface (input start) (input req_addr (width 8)) (output done))
  (transaction child
    (ports (input addr (width 8)))
    (on child_start)
    (complete child_done))
  (transaction parent
    (on start)
    (do child
      (bind (input addr req_addr (timing eventual))))
    (complete done)))
ISF
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
