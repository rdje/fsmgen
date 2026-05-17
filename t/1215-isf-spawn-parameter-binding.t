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

subtest 'repeat body parameterized spawn reuses one static child instance through await_all' => sub {
    my $source = <<'ISF';
(actor repeat_spawn
  (clock clk)
  (interface
    (input start)
    (input loops (width 3))
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0
        (params
          (WIDTH 16)
          (LANES (8'hA5 8'h3C))))
      (await_all done))
    (complete done))
  (transaction worker
    (params
      (WIDTH 8)
      (LANES (8'h00 8'h00)))
    (drive tick)
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 1,
        'repeat body spawn contributes one static generated child instance');
    is($ir->{spawn_instances}[0]{child}, 'worker',
        'repeat body static instance targets the worker transaction');
    is($ir->{spawn_instances}[0]{instance}, 'w0',
        'repeat body static instance preserves the lexical spawn name');
    is_deeply(
        $ir->{spawn_instances}[0]{parameter_overrides},
        [
            { name => 'WIDTH', value => '16' },
            { name => 'LANES', value => ["8'hA5", "8'h3C"] },
        ],
        'repeat body static instance preserves parameter overrides',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'repeat_spawn.fsm'};
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    my $top_fsm = $lowered->{files}{'repeat_spawn_top.fsm'};

    ok(defined($parent_fsm), 'repeat-spawn parent scheduled .fsm is emitted');
    ok(defined($child_fsm), 'repeat-spawn child scheduled .fsm is emitted');
    ok(defined($top_fsm), 'repeat-spawn generated top .fsm is emitted');
    like($parent_fsm, qr/\(parent_repeat_init_1\n\s+\(<= \(parent_cnt loops\)\)/,
        'repeat-spawn parent loads the repeat count once per loop entry');
    like($parent_fsm, qr/\(parent_spawn_2[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_await_all_3\)/,
        'repeat body spawn asserts the static child start and advances to await_all');
    like($parent_fsm, qr/\(parent_await_all_3[\s\S]*\(-> parent_repeat_check_4 <w0_done\)/,
        'repeat body await_all waits for the child done before the repeat check');
    like($parent_fsm, qr/\(parent_repeat_check_4[\s\S]*\(=1 \(-> parent_repeat_init_1\)\)/,
        'repeat check can only loop after the await_all state');
    like($child_fsm, qr/\(\+params\s+\(WIDTH 8\)\s+\(LANES \(8'h00 8'h00\)\)\s+\)/s,
        'repeat-spawn child emits transaction parameter defaults');
    like($top_fsm, qr/\(\?fsmc:w0 worker(?:\s|\))/,
        'generated top instantiates the repeated static child once');
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 16\)\s+\(LANES \(8'hA5 8'h3C\)\)\s+\)\s+\)/s,
        'generated top applies repeat-spawn parameter overrides once on the static child instance');
    like($top_fsm, qr/\(repeat_spawn\.w0_start w0\.start\)/,
        'generated top wires the repeated spawn start handoff');
    like($top_fsm, qr/\(w0\.done repeat_spawn\.w0_done\)/,
        'generated top wires the repeated spawn done handoff');
};

subtest 'spawn parameter bindings preserve instance overrides and child defaults' => sub {
    my $source = <<'ISF';
(actor spawn_parameter_binding
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WIDTH 16)
        (LANES (8'hA5 8'h3C))))
    (spawn worker as w1)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8)
      (LANES (8'h00 8'h00)))
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);

    is_deeply(
        $ir->{spawn_instances},
        [
            {
                child => 'worker',
                instance => 'w0',
                drive_handoffs => [],
                parameter_overrides => [
                    { name => 'WIDTH', value => '16' },
                    { name => 'LANES', value => ["8'hA5", "8'h3C"] },
                ],
            },
            {
                child => 'worker',
                instance => 'w1',
                drive_handoffs => [],
                parameter_overrides => [],
            },
        ],
        'parent IR preserves per-instance spawn parameter override metadata',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'spawn_parameter_binding.fsm'};
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    my $top_fsm = $lowered->{files}{'spawn_parameter_binding_top.fsm'};

    ok(defined($parent_fsm), 'parent scheduled .fsm is emitted');
    ok(defined($child_fsm), 'spawned child scheduled .fsm is emitted');
    ok(defined($top_fsm), 'generated top .fsm is emitted');
    like($parent_fsm, qr/\(= \(w0_start> 1\)\)/, 'parent exposes the first spawn instance start');
    like($parent_fsm, qr/\(= \(w1_start> 1\)\)/, 'parent exposes the second spawn instance start');
    like($child_fsm, qr/\(\+params\s+\(WIDTH 8\)\s+\(LANES \(8'h00 8'h00\)\)\s+\)/s, 'child .fsm emits transaction parameter defaults');
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 16\)\s+\(LANES \(8'hA5 8'h3C\)\)\s+\)\s+\)/s, 'generated top applies per-instance spawn parameter overrides');
};

subtest 'repeat body spawn accepts port bindings through one static child instance' => sub {
    my $source = <<'ISF';
(actor repeat_spawn_binding
  (clock clk)
  (interface
    (input start)
    (input payload (width 8))
    (input loops (width 3))
    (output result (width 8))
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0
        (bind
          (input data payload)
          (output resp result)))
      (await_all done))
    (complete done))
  (transaction worker
    (ports
      (input data (width 8))
      (output resp (width 8)))
    (update resp data)
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 1,
        'repeat-body spawn binding contributes one static generated child instance');
    my $instance = $ir->{spawn_instances}[0];
    is($instance->{child}, 'worker', 'repeat-body spawn binding targets the child transaction');
    is($instance->{instance}, 'w0', 'repeat-body spawn binding preserves the lexical instance name');
    is_deeply(
        $instance->{port_bindings},
        [
            {
                role             => 'input',
                child_port       => 'data',
                parent_port      => 'w0_data',
                actor_signal     => 'payload',
                actor_expr       => 'payload',
                actor_expression => 'payload',
                width            => 8,
            },
            {
                role             => 'output',
                child_port       => 'resp',
                parent_port      => 'w0_resp',
                actor_signal     => 'result',
                actor_expr       => 'result',
                actor_expression => 'result',
                width            => 8,
            },
        ],
        'repeat-body spawn binding exposes reviewable generated handoff metadata',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'repeat_spawn_binding.fsm'};
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    my $top_fsm = $lowered->{files}{'repeat_spawn_binding_top.fsm'};

    ok(defined($parent_fsm), 'repeat-spawn binding parent scheduled .fsm is emitted');
    ok(defined($child_fsm), 'repeat-spawn binding child scheduled .fsm is emitted');
    ok(defined($top_fsm), 'repeat-spawn binding generated top .fsm is emitted');
    like($parent_fsm, qr/\(parent_spawn_2[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_await_all_3\)/,
        'repeat body spawn binding still starts the static child and advances to await_all');
    like($parent_fsm, qr/\(parent_await_all_3[\s\S]*\(-> parent_repeat_check_4 <w0_done\)/,
        'repeat body spawn binding waits for child done before the repeat check');
    like($parent_fsm, qr/\(-w0_port_bindings\s+\(= \(w0_data> payload\)\)\s+\(= \(result> w0_resp\)\)\s+\)/s,
        'parent .fsm keeps repeat-spawn input and output bindings reviewable');
    like($top_fsm, qr/\(\?fsmc:w0 worker(?:\s|\))/,
        'generated top instantiates the repeat-spawn binding child once');
    like($top_fsm, qr/\(repeat_spawn_binding\.w0_data w0\.data\)/,
        'generated top wires repeat-spawn input binding handoff');
    like($top_fsm, qr/\(w0\.resp repeat_spawn_binding\.w0_resp\)/,
        'generated top wires repeat-spawn output binding handoff');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} } @{$report->{transaction_port_bindings}} ],
        [
            'spawn:w0:data',
            'spawn:w0:resp',
        ],
        'report exposes repeat-spawn transaction port-binding provenance',
    );
};

subtest 'parameterized do lowers through a generated child activation instance' => sub {
    my $source = <<'ISF';
(actor parameterized_do_binding
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input req_addr (width 8))
    (output done)
    (output resp (width 8)))
  (transaction parent
    (on start)
    (do worker
      (params
        (WIDTH 16))
      (bind
        (input addr req_addr)
        (output data resp)))
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (ports
      (input addr (width 8))
      (output data (width 8)))
    (update data addr)
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 1, 'parameterized do contributes one generated activation instance');
    my $instance = $ir->{spawn_instances}[0];
    is($instance->{activation_kind}, 'do', 'generated instance preserves do activation provenance');
    is($instance->{child}, 'worker', 'generated do instance targets the child transaction module');
    is($instance->{instance}, 'parent_worker_do_0', 'generated do instance name is deterministic');
    is_deeply(
        $instance->{parameter_overrides},
        [ { name => 'WIDTH', value => '16' } ],
        'generated do instance preserves parameter overrides',
    );
    is_deeply(
        $instance->{port_bindings},
        [
            {
                role         => 'input',
                child_port   => 'addr',
                parent_port  => 'parent_worker_do_0_addr',
                actor_signal => 'req_addr',
                actor_expr => 'req_addr',
                actor_expression => 'req_addr',
                width        => 8,
            },
            {
                role         => 'output',
                child_port   => 'data',
                parent_port  => 'parent_worker_do_0_data',
                actor_signal => 'resp',
                actor_expr => 'resp',
                actor_expression => 'resp',
                width        => 8,
            },
        ],
        'generated do instance exposes reviewable port-binding handoffs',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'parameterized_do_binding.fsm'};
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    my $top_fsm = $lowered->{files}{'parameterized_do_binding_top.fsm'};

    ok(defined($parent_fsm), 'parent scheduled .fsm is emitted');
    ok(defined($child_fsm), 'parameterized do child scheduled .fsm is emitted');
    ok(defined($top_fsm), 'generated top .fsm is emitted for parameterized do');
    like($parent_fsm, qr/\(= \(parent_worker_do_0_start> 1\)\)/, 'parent do state starts the generated do instance');
    like($parent_fsm, qr/<parent_worker_do_0_done/, 'parent do state awaits the generated do instance completion');
    like($parent_fsm, qr/\(-parent_worker_do_0_port_bindings\s+\(= \(parent_worker_do_0_addr> req_addr\)\)\s+\(= \(resp> parent_worker_do_0_data\) <parent_worker_do_0_done\)\s+\)/s,
        'parent .fsm keeps do input and done-gated output bindings reviewable');
    like($child_fsm, qr/\(\+params\s+\(WIDTH 8\)\s+\)/s, 'generated do child emits transaction parameter defaults');
    like($top_fsm, qr/\(\?fsmc:parent_worker_do_0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'generated top applies the do parameter override');
    like($top_fsm, qr/\(parameterized_do_binding\.parent_worker_do_0_start parent_worker_do_0\.start\)/, 'generated top wires do start handoff');
    like($top_fsm, qr/\(parent_worker_do_0\.done parameterized_do_binding\.parent_worker_do_0_done\)/, 'generated top wires do done handoff');

    my $tempdir = tempdir(CLEANUP => 1);
    my $source_path = File::Spec->catfile($tempdir, 'parameterized_do_binding.isf');
    my $hdl_path = File::Spec->catfile($tempdir, 'parameterized_do_binding.sv');
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
    ok($success, 'parameterized do generated top reaches HDL generation');
    is(join('', @{$stderr_buf || []}), '', 'parameterized do HDL generation keeps stderr clean');
    like(slurp($hdl_path), qr/\bmodule\s+parameterized_do_binding_top\b/, 'HDL contains parameterized do generated top module');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is($report->{generated_composition}{kind}, 'activation_generated_top', 'report identifies a general activation generated top');
    is($report->{generated_composition}{instances}[0]{activation_kind}, 'do', 'report preserves do activation kind');
    is_deeply(
        $report->{generated_composition}{instances}[0]{parameter_bindings},
        [ { name => 'WIDTH', source => 'override', value => '16' } ],
        'report exposes generated do parameter binding provenance',
    );
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} } @{$report->{transaction_port_bindings}} ],
        [
            'do:parent_worker_do_0:addr',
            'do:parent_worker_do_0:data',
        ],
        'report exposes generated do transaction port-binding provenance',
    );
};

subtest 'spawn parameter bindings fail closed for unsupported or ambiguous shapes' => sub {
    assert_lower_rejected(<<'ISF', 'repeat spawn without await_all', qr/repeat-body spawn requires same-body '\(await_all done\)' before the repeat check can loop/);
(actor repeat_spawn_without_await_all
  (clock clk)
  (interface (input start) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'repeat await_all without spawn', qr/repeat-body await_all is supported only after repeat-body spawn clauses/);
(actor repeat_await_all_without_spawn
  (clock clk)
  (interface (input start) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (repeat loops
      (await_all done))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'repeat spawn with child ports requires bindings', qr/repeat-body spawn target 'worker' requires '\(bind \.\.\.\)' because transaction 'worker' declares ports/);
(actor repeat_spawn_missing_bind
  (clock clk)
  (interface (input start) (input payload (width 8)) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0)
      (await_all done))
    (complete done))
  (transaction worker
    (ports
      (input data (width 8)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'repeat spawn bind validates actor signal', qr/repeat-body spawn target 'worker' binding for port 'data' references unknown actor signal 'missing_payload'/);
(actor repeat_spawn_bind_unknown_signal
  (clock clk)
  (interface (input start) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0
        (bind
          (input data missing_payload)))
      (await_all done))
    (complete done))
  (transaction worker
    (ports
      (input data (width 8)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'repeat spawn with domain override', qr/repeat-body spawn '\(domain \.\.\.\)' is not supported/);
(actor repeat_spawn_with_domain
  (clock clk)
  (interface (input start) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0
        (domain fast))
      (await_all done))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested repeat spawn', qr/repeat-body spawn is supported only for top-level repeat clauses/);
(actor nested_repeat_spawn
  (clock clk)
  (interface (input start) (input cond) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (when cond
      (repeat loops
        (spawn worker as w0)
        (await_all done)))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'duplicate spawn instance name', qr/duplicate spawn instance 'w0'/);
(actor duplicate_spawn_instance
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'unknown spawn override name', qr/overrides unknown parameter 'MODE'/);
(actor unknown_spawn_parameter
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (MODE 1)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'aggregate override scalar mismatch', qr/shape does not match child 'worker' declaration/);
(actor aggregate_scalar_mismatch
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (LANES 3)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (LANES (1 2)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'aggregate override length mismatch', qr/shape does not match child 'worker' declaration/);
(actor aggregate_length_mismatch
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (LANES (3 4 5))))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (LANES (1 2)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'duplicate transaction parameter declaration', qr/duplicate parameter 'WIDTH'/);
(actor duplicate_transaction_parameter
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8)
      (WIDTH 16))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'invalid transaction parameter name', qr/parameter names must be scalar HDL identifiers/);
(actor invalid_transaction_parameter_name
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (1WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'duplicate spawn parameter override', qr/duplicate parameter override 'WIDTH'/);
(actor duplicate_spawn_parameter
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WIDTH 16)
        (WIDTH 32)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'invalid spawn parameter override name', qr/spawn parameter override names must be scalar HDL identifiers/);
(actor invalid_spawn_parameter_name
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (1WIDTH 16)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'symbolic spawn parameter override', qr/unsupported parameter value 'TOP_WIDTH'/);
(actor symbolic_spawn_parameter
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WIDTH TOP_WIDTH)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'multiple spawn parameter blocks', qr/spawn has duplicate 'params' subclause/);
(actor multiple_spawn_parameter_blocks
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WIDTH 16))
      (params
        (WIDTH 32)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'multiple transaction parameter blocks', qr/transaction parameters allow at most one '\(params \.\.\.\)' clause/);
(actor multiple_transaction_parameter_blocks
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (params
      (LANES 2))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'non-generated transaction parameter declaration', qr/params are supported only on generated child transactions/);
(actor non_spawned_transaction_parameter
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (params
      (WIDTH 8))
    (on start)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'unknown do override name', qr/do instance 'parent_worker_do_0' overrides unknown parameter 'MODE'/);
(actor unknown_do_parameter
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (do worker
      (params
        (MODE 1)))
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'multiple do parameter blocks', qr/do has duplicate 'params' subclause/);
(actor multiple_do_parameter_blocks
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (do worker
      (params
        (WIDTH 16))
      (params
        (WIDTH 32)))
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF
};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, 'spawn-parameter-binding.isf');
}

sub lower_source {
    my ($source) = @_;
    return FSM::Scheduler::ISF->new()->lower(parse_source($source));
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        lower_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
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
