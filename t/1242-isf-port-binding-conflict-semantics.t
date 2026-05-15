#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Pipeline::HDLGenerator;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;

subtest 'spawn output bindings keep transaction provenance' => sub {
    my $ir = lower_ir(<<'ISF');
(actor spawn_binding_provenance
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

    my $record = find_record(
        $ir,
        target      => 'resp',
        source_kind => 'spawn_output_binding',
    );
    is($record->{owner}, 'parent', 'spawn output binding is owned by the parent transaction');
    is($record->{owner_kind}, 'transaction', 'spawn output binding participates as transaction data');
    is($record->{operator}, '=', 'spawn output binding remains a live combinational assignment');
    is($record->{rhs}, 'w0_data', 'spawn output binding reads the generated child-output handoff');
    is($record->{activation}{dt_kind}, 'spawn_port_binding', 'activation metadata names the binding DT kind');
};

subtest 'spawn output bindings fail closed against conflicting rule writers' => sub {
    assert_lower_rejected(<<'ISF', qr/ISF conflict 'isf_priority_mixed_timing_conflict' on target 'resp'.*rule 'force'.*transaction 'parent' \(spawn_output_binding, = w0_data\)/s);
(actor spawn_binding_rule_conflict
  (clock clk)
  (interface
    (input start)
    (input force_resp)
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
    (complete done))
  (rule force force_resp
    (resp 1)))
ISF
};

subtest 'spawn output fan-in reaches backend runtime selector instrumentation' => sub {
    my $result = generate_parent_hdl_from_isf(
        'spawn_binding_runtime_selector',
        <<'ISF',
(actor spawn_binding_runtime_selector
  (clock clk)
  (reset rst_n)
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
    (spawn child as w1
      (bind
        (input addr req_addr)
        (output data resp)))
    (complete done)))
ISF
    );

    my $resp_target = selector_target($result, 'resp');
    ok($resp_target, 'backend selector metadata includes the actor output written by spawn bindings');
    is($resp_target->{multi_value_assertion}{kind}, 'onehot0', 'actor output mux has a runtime onehot0 selector check');
    like(
        $result->{hdl_code},
        qr/selector multi-value conflict: resp/,
        'SystemVerilog emits the runtime multi-value conflict assertion for the actor output',
    );
};

subtest 'rule trigger input bindings reach backend runtime selector instrumentation' => sub {
    my $result = generate_parent_hdl_from_isf(
        'rule_trigger_binding_runtime_selector',
        <<'ISF',
(actor rule_trigger_binding_runtime_selector
  (clock clk)
  (reset rst_n)
  (interface
    (input a)
    (input b)
    (input x (width 8))
    (input y (width 8))
    (output done))
  (transaction work
    (ports
      (input addr (width 8)))
    (on work_start)
    (complete done))
  (rule r0 a
    (trigger work
      (bind
        (input addr x))))
  (rule r1 b
    (trigger work
      (bind
        (input addr y)))))
ISF
    );

    my $addr_target = selector_target($result, 'addr');
    ok($addr_target, 'backend selector metadata includes the transaction input driven by rule payloads');
    is($addr_target->{multi_value_assertion}{kind}, 'onehot0', 'transaction input mux has a runtime onehot0 selector check');
    like(
        $result->{hdl_code},
        qr/selector multi-value conflict: addr/,
        'SystemVerilog emits the runtime multi-value conflict assertion for the transaction input port',
    );
};

done_testing();

sub lower_ir {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'port-binding-conflict-semantics.isf');
    return FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
}

sub assert_lower_rejected {
    my ($source, $diagnostic_re) = @_;
    my $ok = eval {
        lower_ir($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, 'conflicting source is rejected');
    like($diagnostic, $diagnostic_re, 'diagnostic names the binding conflict path');
}

sub generate_parent_hdl_from_isf {
    my ($module_name, $source) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($tempdir, "$module_name.isf");
    write_file($isf_path, $source);

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $scheduled_fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{"$module_name.fsm"};
    my $fsm_path = File::Spec->catfile($tempdir, "$module_name.fsm");
    write_file($fsm_path, $scheduled_fsm);

    return FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level     => 0,
        quiet           => 1,
    )->generate_hdl_from_file($fsm_path);
}

sub selector_target {
    my ($result, $signal_name) = @_;
    for my $target (@{$result->{module_info}{selector_conflict_targets} || []}) {
        next unless ref($target) eq 'HASH';
        return $target if ($target->{signal_name} || '') eq $signal_name;
    }
    return undef;
}

sub find_record {
    my ($ir, %want) = @_;

    RECORD:
    for my $record (@{$ir->{assignment_provenance} || []}) {
        for my $key (sort keys %want) {
            next RECORD unless defined($record->{$key}) && $record->{$key} eq $want{$key};
        }
        return $record;
    }

    fail('found provenance record for ' . join(', ', map { "$_=$want{$_}" } sort keys %want));
    return {};
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
