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

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $isf_file = File::Spec->catfile($repo_root, 'isf', 'atl_resolved_child_pipeline.isf');
my $pin_ingress_isf_file = File::Spec->catfile(
    $repo_root,
    'isf',
    'atl_resolved_child_pin_ingress_pipeline.isf',
);

subtest 'ATL resolved-child fixture lowers to parent, child, and generated top artifacts' => sub {
    my ($files, $report) = lower_atl_fixture();

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_resolved_child_pipeline.fsm',
            'atl_resolved_child_pipeline__worker.fsm',
            'atl_resolved_child_pipeline_top.fsm',
        ],
        'lowering emits exactly the parent, resolved child, and generated ATL top FSM artifacts',
    );

    my $parent = $files->{'atl_resolved_child_pipeline.fsm'};
    like($parent, qr/\A\(\?fsm:atl_resolved_child_pipeline\b/, 'parent scheduled FSM uses the fixture module name');
    like($parent, qr/\(worker_done 1\)/, 'parent exposes the worker event handoff input');
    like($parent, qr/\(worker_process_start 1\)/, 'parent exposes the worker trigger handoff output');
    like($parent, qr/\brun_atl_trigger_1\b/, 'parent contains the trigger handoff state');
    like($parent, qr/\brun_await_2\b/, 'parent contains the event wait state');
    like($parent, qr/\(<1 \(worker_process_start> 1\)\)/, 'trigger state pulses the worker process handoff');
    like($parent, qr/\(<worker_done\s+\(-> run_done_3\)\s+\)/, 'await state waits for the worker done handoff');

    my $child = $files->{'atl_resolved_child_pipeline__worker.fsm'};
    like($child, qr/\A\(\?fsm:atl_resolved_child_pipeline__worker\b/, 'child scheduled FSM uses the resolved child module name');
    like($child, qr/\(process_start 1\)/, 'child keeps its authored process_start input');
    like($child, qr/\(done 1\)/, 'child keeps its authored done output');
    like($child, qr/\bprocess_idle_0\b/, 'child keeps its process transaction entry state');

    my $top = $files->{'atl_resolved_child_pipeline_top.fsm'};
    like($top, qr/\A\(\?top:atl_resolved_child_pipeline_top\b/, 'generated top uses the fixture top module name');
    like($top, qr/\(\?ports:public_io\s+clk\s+rst_n\s+start\s+done>\s+\)/s, 'generated top exposes only parent public pins plus clock/reset');
    like($top, qr/\(\?fsmc:atl_resolved_child_pipeline atl_resolved_child_pipeline\)/, 'generated top instantiates the scheduled parent');
    like($top, qr/\(\?fsmc:worker atl_resolved_child_pipeline__worker\)/, 'generated top instantiates the resolved child');
    like($top, qr/\(start atl_resolved_child_pipeline\.start\)/, 'generated top wires top start into the parent');
    like($top, qr/\(atl_resolved_child_pipeline\.done done\)/, 'generated top wires parent done to the top output');
    like($top, qr/\(atl_resolved_child_pipeline\.worker_process_start worker\.process_start\)/, 'generated top wires parent trigger handoff to the child transaction start input');
    like($top, qr/\(worker\.done atl_resolved_child_pipeline\.worker_done\)/, 'generated top wires child event pulse to the parent event handoff input');

    assert_report_shape($report);
};

subtest 'ATL pin-ingress fixture lowers scalar top input through parent into resolved child' => sub {
    my ($files, $report) = lower_atl_fixture($pin_ingress_isf_file);

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_resolved_child_pin_ingress_pipeline.fsm',
            'atl_resolved_child_pin_ingress_pipeline__worker.fsm',
            'atl_resolved_child_pin_ingress_pipeline_top.fsm',
        ],
        'pin-ingress lowering emits exactly the parent, resolved child, and generated ATL top FSM artifacts',
    );

    my $parent = $files->{'atl_resolved_child_pin_ingress_pipeline.fsm'};
    like($parent, qr/\A\(\?fsm:atl_resolved_child_pin_ingress_pipeline\b/, 'pin-ingress parent uses the fixture module name');
    like($parent, qr/\(payload 1\)/, 'pin-ingress parent exposes the top payload input');
    like($parent, qr/\(worker_payload 1\)/, 'pin-ingress parent exposes the generated worker payload handoff');
    like($parent, qr/\brun_drive_1\b/, 'pin-ingress parent contains the drive-call state');
    like($parent, qr/\(= \(feed_worker_start 1\)\)/, 'pin-ingress drive-call state pulses the named drive enable');
    like($parent, qr/\(-feed_worker\s+\(<- \(worker_payload> payload\) <feed_worker_start\)\s+\)/s,
        'pin-ingress named drive transfers the top payload into the worker handoff');

    my $child = $files->{'atl_resolved_child_pin_ingress_pipeline__worker.fsm'};
    like($child, qr/\A\(\?fsm:atl_resolved_child_pin_ingress_pipeline__worker\b/,
        'pin-ingress child uses the resolved child module name');
    like($child, qr/\(\+interface\s+\(input payload\)\s+\)/s,
        'pin-ingress child preserves the declared payload input as an explicit generated interface role');
    like($child, qr/\(payload 1\)/, 'pin-ingress child keeps the payload size declaration');
    like($child, qr/\(process_start 1\)/, 'pin-ingress child keeps its authored process_start input');
    like($child, qr/\(done 1\)/, 'pin-ingress child keeps its authored done output');

    my $top = $files->{'atl_resolved_child_pin_ingress_pipeline_top.fsm'};
    like($top, qr/\A\(\?top:atl_resolved_child_pin_ingress_pipeline_top\b/,
        'pin-ingress generated top uses the fixture top module name');
    like($top, qr/\(\?ports:public_io\s+clk\s+rst_n\s+start\s+payload\s+done>\s+\)/s,
        'pin-ingress generated top exposes only parent public pins plus clock/reset');
    like($top, qr/\(payload atl_resolved_child_pin_ingress_pipeline\.payload\)/,
        'pin-ingress generated top wires top payload into the parent');
    like($top, qr/\(atl_resolved_child_pin_ingress_pipeline\.worker_payload worker\.payload\)/,
        'pin-ingress generated top wires the parent data handoff into the child payload input');
    like($top, qr/\(atl_resolved_child_pin_ingress_pipeline\.worker_process_start worker\.process_start\)/,
        'pin-ingress generated top wires parent trigger handoff to the child transaction start input');
    like($top, qr/\(worker\.done atl_resolved_child_pin_ingress_pipeline\.worker_done\)/,
        'pin-ingress generated top wires child event pulse to the parent event handoff input');

    assert_pin_ingress_report_shape($report);
};

subtest 'ATL resolved-child fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_atl_fixture();
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
        'strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the ATL resolved-child fixture');
    is($stderr, '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL pin-ingress fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_atl_fixture($pin_ingress_isf_file);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $pin_ingress_isf_file,
        ],
        'pin-ingress strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the ATL pin-ingress fixture');
    is($stderr, '', 'pin-ingress strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'pin-ingress strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL resolved-child fixture strict outdir lowering writes the generated top' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--outdir',
            $dir,
            $isf_file,
        ],
        'strict outdir lowering',
    );

    ok($success, 'strict outdir lowering succeeds for the ATL resolved-child fixture');
    like($stdout, qr/Wrote: .*atl_resolved_child_pipeline_top\.fsm/, 'strict outdir lowering reports the written generated top');
    is($stderr, '', 'strict outdir lowering keeps stderr clean');
    is_deeply(
        sorted([fsm_basenames_in($dir)]),
        [
            'atl_resolved_child_pipeline.fsm',
            'atl_resolved_child_pipeline__worker.fsm',
            'atl_resolved_child_pipeline_top.fsm',
        ],
        'strict outdir lowering writes the parent, resolved child, and generated top files',
    );
};

subtest 'ATL pin-ingress fixture strict outdir lowering writes the generated top' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--outdir',
            $dir,
            $pin_ingress_isf_file,
        ],
        'pin-ingress strict outdir lowering',
    );

    ok($success, 'strict outdir lowering succeeds for the ATL pin-ingress fixture');
    like($stdout, qr/Wrote: .*atl_resolved_child_pin_ingress_pipeline_top\.fsm/,
        'pin-ingress strict outdir lowering reports the written generated top');
    is($stderr, '', 'pin-ingress strict outdir lowering keeps stderr clean');
    is_deeply(
        sorted([fsm_basenames_in($dir)]),
        expected_fsm_basenames_for_source($pin_ingress_isf_file),
        'pin-ingress strict outdir lowering writes the parent, resolved child, and generated top files',
    );
};

subtest 'ATL resolved-child fixture reaches generated-top HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_resolved_child_pipeline_plain.sv');
    my $plain = generate_hdl($plain_hdl, [], 'plain HDL generation');

    assert_generated_top_hdl($plain, 'plain HDL');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_resolved_child_pipeline_strict.sv');
    my $strict = generate_hdl($strict_hdl, ['--strict'], 'strict HDL generation');

    assert_generated_top_hdl($strict, 'strict HDL');
};

subtest 'ATL pin-ingress fixture reaches generated-top HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_resolved_child_pin_ingress_pipeline_plain.sv');
    my $plain = generate_hdl(
        $plain_hdl,
        [],
        'pin-ingress plain HDL generation',
        $pin_ingress_isf_file,
    );

    assert_pin_ingress_generated_top_hdl($plain, 'pin-ingress plain HDL');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_resolved_child_pin_ingress_pipeline_strict.sv');
    my $strict = generate_hdl(
        $strict_hdl,
        ['--strict'],
        'pin-ingress strict HDL generation',
        $pin_ingress_isf_file,
    );

    assert_pin_ingress_generated_top_hdl($strict, 'pin-ingress strict HDL');
};

subtest 'ATL generated top fail-closed boundary rejects unsupported child wiring shapes' => sub {
    lower_source_fails_like(
        atl_fixture_variant(<<'LIBRARY'),
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output done))
    (transaction other
      (on process_start)
      (complete done))))
LIBRARY
        qr/trigger targets missing child transaction 'process'/,
        'missing child target transaction fails closed',
    );

    lower_source_fails_like(
        atl_fixture_variant(<<'LIBRARY'),
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output done))
    (transaction process
      (on (== process_start 1))
      (complete done))))
LIBRARY
        qr/on requires '\(on port \[sample\.\.\.\]\)'/,
        'non-scalar child transaction on condition fails closed',
    );

    lower_source_fails_like(
        atl_fixture_variant(<<'LIBRARY'),
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output finished))
    (transaction process
      (on process_start)
      (complete finished))))
LIBRARY
        qr/event 'done' is not a scalar child output port/,
        'missing child event output fails closed',
    );

    lower_source_fails_like(
        atl_fixture_variant(<<'LIBRARY'),
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock child_clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output done))
    (transaction process
      (on process_start)
      (complete done))))
LIBRARY
        qr/requires parent and child clocks to match/,
        'cross-clock child wiring fails closed',
    );

    lower_source_fails_like(
        pin_ingress_atl_fixture_variant(<<'LIBRARY'),
(library common.packet
  (exports
    (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output done))
    (transaction process
      (on process_start)
      (complete done))))
LIBRARY
        qr/data movement 'feed_worker' requires a scalar child input port 'payload'/,
        'pin-ingress data route fails closed when the child omits the target input',
    );
};

done_testing();

sub lower_atl_fixture {
    my ($source_file) = @_;
    $source_file //= $isf_file;

    my $actor = FSM::Adapter::ISF->new()->parse_file($source_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}, $report);
}

sub assert_report_shape {
    my ($report) = @_;

    is($report->{source}, 'atl_resolved_child_pipeline.isf', 'schedule report names the ATL resolved-child fixture');
    is($report->{scheduled_fsm}, 'atl_resolved_child_pipeline.fsm', 'schedule report names the scheduled parent FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 2, 'schedule report input count includes the worker event handoff');
    is($report->{outputs}, 2, 'schedule report output count includes the worker trigger handoff');
    is($report->{port_count}, 4, 'schedule report port count includes generated orchestration handoffs');
    is($report->{state_count}, 5, 'schedule report state count includes the default await timeout state');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');
    is_deeply($report->{dt_blocks}, [], 'schedule report has no drive bodies');
    is_deeply($report->{library_uses}, [], 'ATL resolved child does not appear as a reusable-library use');

    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 5,
                states => [qw(
                  run_idle_0
                  run_atl_trigger_1
                  run_await_2
                  run_done_3
                  run_timeout
                )],
            },
        ],
        'schedule report records the resolved-child transaction state order',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'actor network kind');
    is_deeply(
        $actor_network->{instances},
        [
            {
                name            => 'worker',
                actor_type      => 'pkt_lib.packet_worker',
                declaration     => 'actor',
                type_resolution => 'library_actor_export',
                library         => 'common.packet',
                alias           => 'pkt_lib',
                export          => 'packet_worker',
                module          => 'atl_resolved_child_pipeline__worker',
                scheduled_fsm   => 'atl_resolved_child_pipeline__worker.fsm',
            },
        ],
        'report records the resolved child actor metadata',
    );
    is_deeply($actor_network->{groups}, [], 'fixture has no permanent static group');
    is_deeply(
        $actor_network->{generated_tops},
        [
            {
                kind                 => 'resolved_child_trigger_event_handoff',
                top_module           => 'atl_resolved_child_pipeline_top',
                top_fsm              => 'atl_resolved_child_pipeline_top.fsm',
                parent_module        => 'atl_resolved_child_pipeline',
                parent_scheduled_fsm => 'atl_resolved_child_pipeline.fsm',
                instance             => 'worker',
                child_module         => 'atl_resolved_child_pipeline__worker',
                child_scheduled_fsm  => 'atl_resolved_child_pipeline__worker.fsm',
                target_transaction   => 'process',
                trigger_parent_port  => 'worker_process_start',
                trigger_child_port   => 'process_start',
                event                => 'done',
                event_parent_port    => 'worker_done',
                event_child_port     => 'done',
                clock                => 'clk',
                reset                => 'rst_n',
            },
        ],
        'report records the generated ATL top handoff wiring',
    );
    is_deeply($actor_network->{data_movements}, [], 'fixture does not use ATL data movement');
    is_deeply($actor_network->{association_schedules}, [], 'fixture does not use trigger-batch association schedules');
    is_deeply($actor_network->{group_schedules}, [], 'fixture does not use compatibility group schedule evidence');
    is_deeply(
        $actor_network->{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'worker',
                target_transaction => 'process',
                signal             => 'worker_process_start',
                sink               => 'external_handoff',
            },
        ],
        'report records the worker process trigger handoff',
    );
    is_deeply(
        $actor_network->{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'worker',
                event       => 'done',
                signal      => 'worker_done',
                source      => 'external_handoff',
            },
        ],
        'report records the worker done event handoff',
    );
}

sub assert_pin_ingress_report_shape {
    my ($report) = @_;

    is($report->{source}, 'atl_resolved_child_pin_ingress_pipeline.isf',
        'pin-ingress schedule report names the fixture');
    is($report->{scheduled_fsm}, 'atl_resolved_child_pin_ingress_pipeline.fsm',
        'pin-ingress schedule report names the scheduled parent FSM');
    is($report->{inputs}, 3, 'pin-ingress report input count includes payload and worker event handoff');
    is($report->{outputs}, 3, 'pin-ingress report output count includes done, trigger, and data handoffs');
    is($report->{port_count}, 6, 'pin-ingress report port count includes public and generated handoff ports');
    is($report->{state_count}, 6, 'pin-ingress report state count includes drive, trigger, await, done, and timeout states');
    is_deeply($report->{compile_issues}, [], 'pin-ingress schedule report has no compile issues');
    is_deeply(
        $report->{dt_blocks},
        [
            {
                assignments => 1,
                kind        => 'drive',
                name        => 'feed_worker',
            },
        ],
        'pin-ingress schedule report records the scalar transfer drive body',
    );
    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 6,
                states => [qw(
                  run_idle_0
                  run_drive_1
                  run_atl_trigger_2
                  run_await_3
                  run_done_4
                  run_timeout
                )],
            },
        ],
        'pin-ingress schedule report records the drive before trigger and await',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'pin-ingress actor network kind');
    is_deeply(
        $actor_network->{generated_tops},
        [
            {
                kind                 => 'resolved_child_trigger_event_handoff',
                top_module           => 'atl_resolved_child_pin_ingress_pipeline_top',
                top_fsm              => 'atl_resolved_child_pin_ingress_pipeline_top.fsm',
                parent_module        => 'atl_resolved_child_pin_ingress_pipeline',
                parent_scheduled_fsm => 'atl_resolved_child_pin_ingress_pipeline.fsm',
                instance             => 'worker',
                child_module         => 'atl_resolved_child_pin_ingress_pipeline__worker',
                child_scheduled_fsm  => 'atl_resolved_child_pin_ingress_pipeline__worker.fsm',
                target_transaction   => 'process',
                trigger_parent_port  => 'worker_process_start',
                trigger_child_port   => 'process_start',
                event                => 'done',
                event_parent_port    => 'worker_done',
                event_child_port     => 'done',
                clock                => 'clk',
                reset                => 'rst_n',
            },
        ],
        'pin-ingress report records the generated ATL top without private data-link internals',
    );
    is_deeply(
        $actor_network->{data_movements},
        [
            {
                kind            => 'scalar_pin_to_actor_handoff',
                drive           => 'feed_worker',
                transaction     => 'run',
                context         => 'transaction_body',
                source          => 'top_level_pin',
                source_instance => 'pins',
                source_endpoint => 'payload',
                source_signal   => 'payload',
                sink            => 'external_handoff',
                sink_instance   => 'worker',
                sink_endpoint   => 'payload',
                sink_signal     => 'worker_payload',
                width           => 1,
                width_source    => 'top_level_pin_scalar_one_bit',
                route_lifetime  => 'drive_call_cycle',
                storage         => 'none',
            },
        ],
        'pin-ingress report records the public scalar pin-to-child data movement',
    );
    is_deeply(
        $actor_network->{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'worker',
                target_transaction => 'process',
                signal             => 'worker_process_start',
                sink               => 'external_handoff',
            },
        ],
        'pin-ingress report records the worker process trigger handoff',
    );
    is_deeply(
        $actor_network->{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'worker',
                event       => 'done',
                signal      => 'worker_done',
                source      => 'external_handoff',
            },
        ],
        'pin-ingress report records the worker done event handoff',
    );
}

sub run_cli {
    my ($command, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) =
      run(command => $command);

    diag("$label failed: $error_message") if !$success && defined $error_message;
    return (
        $success,
        join('', @{$stdout_buf || []}),
        join('', @{$stderr_buf || []}),
    );
}

sub lower_source_fails_like {
    my ($source, $pattern, $label) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
    my $ok = eval {
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };

    ok(!$ok, "$label is rejected during lowering");
    like($@, $pattern, "$label diagnostic is targeted");
}

sub generate_hdl {
    my ($output_file, $extra_args, $label, $source_file) = @_;
    $source_file //= $isf_file;

    my $lower_dir = tempdir(CLEANUP => 1);
    my @command = (
        './bin/fsmgen',
        @{$extra_args || []},
        '--quiet',
        '--outdir',
        $lower_dir,
        '--output',
        $output_file,
        $source_file,
    );
    my ($success, undef, $stderr) = run_cli(\@command, $label);

    ok($success, "$label succeeds");
    is($stderr, '', "$label keeps stderr clean");
    ok(-f $output_file, "$label writes the requested output");
    is_deeply(
        sorted([fsm_basenames_in($lower_dir)]),
        expected_fsm_basenames_for_source($source_file),
        "$label materializes the parent, child, and generated top FSM artifacts",
    );

    return slurp($output_file);
}

sub assert_generated_top_hdl {
    my ($hdl, $label) = @_;

    like($hdl, qr/\bmodule\s+atl_resolved_child_pipeline_top\b/, "$label contains the generated ATL top module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pipeline\b/, "$label contains the scheduled parent module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pipeline__worker\b/, "$label contains the resolved child module");
    like($hdl, qr/\bwire\s+comp_link_atl_resolved_child_pipeline_worker_process_start\b/,
        "$label declares the parent-to-child trigger link");
    like($hdl, qr/\bwire\s+comp_link_worker_done\b/,
        "$label declares the child-to-parent event link");
    like($hdl, qr/\.worker_process_start\(comp_link_atl_resolved_child_pipeline_worker_process_start\)/,
        "$label connects the parent trigger handoff to the internal trigger link");
    like($hdl, qr/\.process_start\(comp_link_atl_resolved_child_pipeline_worker_process_start\)/,
        "$label connects the child process start input to the internal trigger link");
    like($hdl, qr/\.done\(comp_link_worker_done\)/,
        "$label connects the child done output to the internal event link");
    like($hdl, qr/\.worker_done\(comp_link_worker_done\)/,
        "$label connects the parent event handoff input to the internal event link");
}

sub assert_pin_ingress_generated_top_hdl {
    my ($hdl, $label) = @_;

    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_pipeline_top\b/,
        "$label contains the generated ATL top module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_pipeline\b/,
        "$label contains the scheduled parent module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_pipeline__worker\b/,
        "$label contains the resolved child module");
    like($hdl, qr/\bmodule\s+atl_resolved_child_pin_ingress_pipeline__worker\s*\([^;]*\binput\s+wire\s+payload\b/s,
        "$label preserves the child payload input as a module port");
    like($hdl, qr/\bwire\s+comp_link_atl_resolved_child_pin_ingress_pipeline_worker_payload\b/,
        "$label declares the parent-to-child payload link");
    like($hdl, qr/\bwire\s+comp_link_atl_resolved_child_pin_ingress_pipeline_worker_process_start\b/,
        "$label declares the parent-to-child trigger link");
    like($hdl, qr/\bwire\s+comp_link_worker_done\b/,
        "$label declares the child-to-parent event link");
    like($hdl, qr/\.payload\(payload\)/,
        "$label connects the public top payload input to the parent payload input");
    like($hdl, qr/\.worker_payload\(comp_link_atl_resolved_child_pin_ingress_pipeline_worker_payload\)/,
        "$label connects the parent payload handoff to the internal payload link");
    like($hdl, qr/\.payload\(comp_link_atl_resolved_child_pin_ingress_pipeline_worker_payload\)/,
        "$label connects the internal payload link to the child payload input");
    like($hdl, qr/\.process_start\(comp_link_atl_resolved_child_pin_ingress_pipeline_worker_process_start\)/,
        "$label connects the child process start input to the internal trigger link");
    like($hdl, qr/\.done\(comp_link_worker_done\)/,
        "$label connects the child done output to the internal event link");
    like($hdl, qr/\.worker_done\(comp_link_worker_done\)/,
        "$label connects the parent event handoff input to the internal event link");
}

sub atl_fixture_variant {
    my ($library) = @_;
    my $actor = <<'ISF';
(actor atl_resolved_child_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (transaction run
    (on start)
    (trigger worker.process)
    (await worker.done)
    (complete done)))

ISF
    return $actor . $library;
}

sub pin_ingress_atl_fixture_variant {
    my ($library) = @_;
    my $actor = <<'ISF';
(actor atl_resolved_child_pin_ingress_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input payload)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (drive feed_worker
    (worker.payload pins.payload))
  (transaction run
    (on start)
    (drive feed_worker)
    (trigger worker.process)
    (await worker.done)
    (complete done)))

ISF
    return $actor . $library;
}

sub fsm_basenames_in {
    my ($dir) = @_;
    opendir my $dh, $dir or die "cannot read directory $dir: $!";
    my @files = grep { /\.fsm\z/ } readdir $dh;
    closedir $dh or die "cannot close directory $dir: $!";
    return @files;
}

sub expected_fsm_basenames_for_source {
    my ($source_file) = @_;
    my (undef, undef, $filename) = File::Spec->splitpath($source_file);
    $filename =~ s/\.isf\z//;

    return [
        "$filename.fsm",
        "${filename}__worker.fsm",
        "${filename}_top.fsm",
    ];
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
