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
use FSM::Scheduler::ISF::LoweringIR;

subtest 'parameterized rule trigger lowers through a generated child activation instance' => sub {
    my $source = <<'ISF';
(actor rule_trigger_parameter_binding
  (clock clk)
  (reset rst_n)
  (interface
    (input fire)
    (input req_addr (width 8))
    (output done))
  (storage
    (var seen (width 8)))
  (transaction parent
    (on fire)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (ports
      (input addr (width 8)))
    (update seen addr)
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (WIDTH 16))
      (bind
        (input addr req_addr)))))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 1, 'rule trigger contributes one generated activation instance');
    my $instance = $ir->{spawn_instances}[0];
    is($instance->{activation_kind}, 'trigger', 'generated instance preserves trigger activation provenance');
    is($instance->{child}, 'worker', 'generated trigger instance targets the child transaction module');
    is($instance->{instance}, 'launch_worker_trigger_0', 'generated trigger instance name is deterministic');
    is($instance->{trigger_source}, 'launch_worker_trigger_0', 'trigger source is per lexical trigger site');
    is_deeply(
        $instance->{parameter_overrides},
        [ { name => 'WIDTH', value => '16' } ],
        'generated trigger instance preserves parameter overrides',
    );
    is_deeply(
        $instance->{port_bindings},
        [
            {
                role             => 'input',
                child_port       => 'addr',
                parent_port      => 'launch_worker_trigger_0_addr',
                actor_signal     => 'req_addr',
                actor_expr       => 'req_addr',
                actor_expression => 'req_addr',
                width            => 8,
            },
        ],
        'generated trigger instance exposes reviewable input handoff metadata',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'rule_trigger_parameter_binding.fsm'};
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    my $top_fsm = $lowered->{files}{'rule_trigger_parameter_binding_top.fsm'};

    ok(defined($parent_fsm), 'parent scheduled .fsm is emitted');
    ok(defined($child_fsm), 'trigger child scheduled .fsm is emitted');
    ok(defined($top_fsm), 'generated top .fsm is emitted');
    unlike($parent_fsm, qr/worker_trigger_fanin/, 'parameterized trigger does not target the shared local trigger fan-in');
    like($parent_fsm, qr/\(-launch\s+<fire[\s\S]*\(<1 \(launch_worker_trigger_0 1\)\)[\s\S]*\(<- \(launch_worker_trigger_0_addr_payload req_addr\)\)/,
        'rule DT keeps delayed trigger source and sampled input payload source');
    like($parent_fsm, qr/\(-launch_worker_trigger_0_trigger_handoff[\s\S]*\(= \(launch_worker_trigger_0_start> launch_worker_trigger_0\)\)[\s\S]*\(= \(launch_worker_trigger_0_addr> launch_worker_trigger_0_addr_payload\) <launch_worker_trigger_0\)/,
        'generated handoff DT drives child start and input under the trigger source');
    like($parent_fsm, qr/\(launch_worker_trigger_0_done_seen 1\)/, 'parent reads generated trigger done handoff for composition endpoint visibility');
    like($child_fsm, qr/\(\+params\s+\(WIDTH 8\)\s+\)/s, 'trigger child emits transaction parameter defaults');
    like($top_fsm, qr/\(\?fsmc:launch_worker_trigger_0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'generated top applies the trigger parameter override');
    like($top_fsm, qr/\(rule_trigger_parameter_binding\.launch_worker_trigger_0_start launch_worker_trigger_0\.start\)/,
        'generated top wires trigger start handoff');
    like($top_fsm, qr/\(launch_worker_trigger_0\.done rule_trigger_parameter_binding\.launch_worker_trigger_0_done\)/,
        'generated top wires trigger done handoff');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is($report->{generated_composition}{kind}, 'activation_generated_top', 'report identifies an activation generated top');
    is($report->{generated_composition}{instances}[0]{activation_kind}, 'trigger', 'report preserves trigger activation kind');
    is_deeply(
        $report->{generated_composition}{instances}[0]{parameter_bindings},
        [ { name => 'WIDTH', source => 'override', value => '16' } ],
        'report exposes generated trigger parameter binding provenance',
    );
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} . ':' . ($_->{payload_source} // '') } @{$report->{transaction_port_bindings}} ],
        [ 'rule_trigger:launch_worker_trigger_0:addr:launch_worker_trigger_0_addr_payload' ],
        'report exposes generated trigger transaction port-binding provenance',
    );

    my $tempdir = tempdir(CLEANUP => 1);
    my $source_path = File::Spec->catfile($tempdir, 'rule_trigger_parameter_binding.isf');
    my $hdl_path = File::Spec->catfile($tempdir, 'rule_trigger_parameter_binding.sv');
    write_file($source_path, $source);
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--outdir',
            $tempdir,
            '--output',
            $hdl_path,
            $source_path,
        ],
    );
    ok($success, 'parameterized rule trigger generated top reaches HDL generation');
    is(join('', @{$stderr_buf || []}), '', 'parameterized rule trigger HDL generation keeps stderr clean');
    like(slurp($hdl_path), qr/\bmodule\s+rule_trigger_parameter_binding_top\b/, 'HDL contains generated top module');
    like(slurp($hdl_path), qr/\blaunch_worker_trigger_0\b/, 'HDL contains generated trigger instance handoffs');
};

subtest 'plain triggers to a generated target use default-valued generated instances' => sub {
    my $source = <<'ISF';
(actor mixed_rule_trigger_parameter_binding
  (clock clk)
  (interface
    (input a)
    (input b)
    (output done))
  (transaction parent
    (on a)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done))
  (rule with_override a
    (trigger worker
      (params
        (WIDTH 16))))
  (rule with_default b
    (trigger worker)))
ISF

    my $actor = parse_source($source);
    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    my @instances = @{$report->{generated_composition}{instances}};
    is(scalar(@instances), 2, 'both trigger sites use generated instances once the target is generated');
    is_deeply(
        [ map { $_->{instance} } @instances ],
        [qw(with_override_worker_trigger_0 with_default_worker_trigger_0)],
        'generated trigger instances are deterministic per rule and target',
    );
    is_deeply(
        [ map { $_->{parameter_bindings}[0]{source} } @instances ],
        [qw(override default)],
        'plain trigger to generated target uses child parameter defaults',
    );

    my $parent_fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'mixed_rule_trigger_parameter_binding.fsm'};
    unlike($parent_fsm, qr/worker_trigger_fanin/, 'mixed generated trigger path does not emit a skipped-body local fan-in');
    like($parent_fsm, qr/with_override_worker_trigger_0_trigger_handoff/, 'override trigger gets a generated handoff DT');
    like($parent_fsm, qr/with_default_worker_trigger_0_trigger_handoff/, 'default trigger gets a generated handoff DT');
};

subtest 'rule trigger parameter bindings fail closed for unsupported or ambiguous shapes' => sub {
    assert_parse_or_lower_rejected(<<'ISF', 'unknown trigger override name', qr/trigger instance 'launch_worker_trigger_0' overrides unknown parameter 'MODE'/);
(actor unknown_trigger_parameter
  (clock clk)
  (interface (input fire) (output done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (MODE 1)))))
ISF

    assert_parse_or_lower_rejected(<<'ISF', 'duplicate trigger parameter block', qr/duplicate 'params' subclause/);
(actor duplicate_trigger_parameter_block
  (clock clk)
  (interface (input fire) (output done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (WIDTH 16))
      (params
        (WIDTH 32)))))
ISF

    assert_parse_or_lower_rejected(<<'ISF', 'symbolic trigger parameter override', qr/unsupported parameter value 'TOP_WIDTH'/);
(actor symbolic_trigger_parameter
  (clock clk)
  (interface (input fire) (output done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (WIDTH TOP_WIDTH)))))
ISF

    assert_parse_or_lower_rejected(<<'ISF', 'rule trigger output binding remains unsupported', qr/output binding 'data' is not supported/);
(actor trigger_output_binding
  (clock clk)
  (interface
    (input fire)
    (output data (width 8)))
  (transaction worker
    (params
      (WIDTH 8))
    (ports
      (output data (width 8)))
    (complete data))
  (rule launch fire
    (trigger worker
      (params
        (WIDTH 16))
      (bind
        (output data data)))))
ISF
};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, 'rule-trigger-parameter-binding.isf');
}

sub lower_source {
    my ($source) = @_;
    return FSM::Scheduler::ISF->new()->lower(parse_source($source));
}

sub assert_parse_or_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        lower_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $text;
    close $fh or die "cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}
