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

subtest 'repeat body spawn accepts declared same-domain activation metadata' => sub {
    my $source = <<'ISF';
(actor repeat_spawn_domain
  (clock-domains
    (domain core (clock clk) (reset rst_n)))
  (interface
    (input start)
    (input loops (width 3))
    (output done))
  (transaction parent
    (domain core)
    (on start)
    (repeat loops
      (spawn worker as w0
        (domain core))
      (await_all done))
    (complete done))
  (transaction worker
    (domain core)
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 1,
        'repeat-body domain spawn contributes one static generated child instance');
    is($ir->{spawn_instances}[0]{domain}, 'core',
        'repeat-body spawn preserves declared same-domain activation metadata');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'repeat_spawn_domain.fsm'};
    my $top_fsm = $lowered->{files}{'repeat_spawn_domain_top.fsm'};

    ok(defined($parent_fsm), 'repeat-spawn domain parent scheduled .fsm is emitted');
    ok(defined($top_fsm), 'repeat-spawn domain generated top .fsm is emitted');
    like($parent_fsm, qr/\(parent_spawn_2[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_await_all_3\)/,
        'repeat body domain spawn still starts the static child and advances to await_all');
    like($top_fsm, qr/\(\?fsmc:w0 worker(?:\s|\))/,
        'generated top instantiates the repeat-spawn domain child once');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        $report->{clock_domains}[0]{child_instances},
        [
            {
                kind     => 'spawn',
                owner    => 'parent',
                child    => 'worker',
                instance => 'w0',
            },
        ],
        'clock-domain report metadata groups the repeated static child by declared activation domain',
    );
};

subtest 'when body nested repeat spawn drains through same-body await_all' => sub {
    my $source = <<'ISF';
(actor when_repeat_spawn_await_all
  (clock-domains
    (domain core (clock clk) (reset rst_n)))
  (interface
    (input start (domain core))
    (input cond (domain core))
    (input loops (width 3) (domain core))
    (input payload (width 8) (domain core))
    (input status (domain core))
    (output done (domain core))
    (output worker_done (domain core))
    (output result (width 8) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (when cond
      (repeat loops
        (sample status as before)
        (spawn worker as w0
          (params
            (WIDTH 16))
          (bind
            (input data payload)
            (output resp result))
          (domain core))
        (sample status as after)
        (await_all done)))
    (complete done))
  (transaction worker
    (domain core)
    (params
      (WIDTH 8))
    (ports
      (input data (width 8))
      (output resp (width 8)))
    (update resp data)
    (complete worker_done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 1,
        'when-body nested repeat spawn contributes one static generated child instance');
    is($ir->{spawn_instances}[0]{child}, 'worker',
        'when-body nested repeat spawn targets the worker transaction');
    is($ir->{spawn_instances}[0]{instance}, 'w0',
        'when-body nested repeat spawn preserves the lexical instance name');
    is($ir->{spawn_instances}[0]{domain}, 'core',
        'when-body nested repeat spawn preserves declared same-domain metadata');
    is_deeply(
        $ir->{spawn_instances}[0]{parameter_overrides},
        [{ name => 'WIDTH', value => '16' }],
        'when-body nested repeat spawn preserves static parameter overrides',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'when_repeat_spawn_await_all.fsm'};
    my $top_fsm = $lowered->{files}{'when_repeat_spawn_await_all_top.fsm'};

    ok(defined($parent_fsm), 'when-body nested repeat spawn parent scheduled .fsm is emitted');
    ok(defined($top_fsm), 'when-body nested repeat spawn generated top .fsm is emitted');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_spawn_\d+\)/,
        'sample before nested spawn materializes before the spawn state');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_sample_\d+\)/,
        'when-body nested spawn starts the static child before the following sample');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after status\)\)[\s\S]*\(-> parent_await_all_\d+\)/,
        'sample after nested spawn materializes before await_all');
    like($parent_fsm, qr/\(parent_await_all_\d+[\s\S]*\(-> parent_repeat_check_\d+ <w0_done\)/,
        'same-body await_all gates the nested repeat check on the spawned child done');
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'generated top applies nested repeat-spawn parameter overrides once');
    like($top_fsm, qr/\(when_repeat_spawn_await_all\.w0_data w0\.data\)/,
        'generated top wires nested repeat-spawn input binding handoff');
    like($top_fsm, qr/\(w0\.resp when_repeat_spawn_await_all\.w0_resp\)/,
        'generated top wires nested repeat-spawn output binding handoff');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} } @{$report->{transaction_port_bindings}} ],
        [
            'spawn:w0:data',
            'spawn:w0:resp',
        ],
        'report exposes when-body nested repeat-spawn transaction port-binding provenance',
    );
    is_deeply(
        $report->{clock_domains}[0]{child_instances},
        [{ kind => 'spawn', owner => 'parent', child => 'worker', instance => 'w0' }],
        'clock-domain report metadata groups the when-body nested repeat-spawn child by declared domain',
    );
};

subtest 'when body nested repeat multiple spawns drain through same-body await_all' => sub {
    my $source = <<'ISF';
(actor when_repeat_multiple_spawns_await_all
  (clock-domains
    (domain core (clock clk) (reset rst_n)))
  (interface
    (input start (domain core))
    (input cond (domain core))
    (input loops (width 3) (domain core))
    (input payload0 (width 8) (domain core))
    (input payload1 (width 8) (domain core))
    (input status (domain core))
    (output done (domain core))
    (output worker_done (domain core))
    (output result0 (width 8) (domain core))
    (output result1 (width 8) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (when cond
      (repeat loops
        (sample status as before)
        (spawn worker as w0
          (params
            (WIDTH 16))
          (bind
            (input data payload0)
            (output resp result0))
          (domain core))
        (sample status as between)
        (spawn worker as w1
          (params
            (WIDTH 32))
          (bind
            (input data payload1)
            (output resp result1))
          (domain core))
        (sample status as after)
        (await_all done)))
    (complete done))
  (transaction worker
    (domain core)
    (params
      (WIDTH 8))
    (ports
      (input data (width 8))
      (output resp (width 8)))
    (update resp data)
    (complete worker_done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 2,
        'when-body nested repeat multiple spawns contribute two static generated child instances');
    is_deeply(
        [ map { $_->{instance} } @{$ir->{spawn_instances}} ],
        [qw(w0 w1)],
        'when-body nested repeat multiple spawns preserve lexical instance names',
    );
    is_deeply(
        [ map { $_->{domain} } @{$ir->{spawn_instances}} ],
        [qw(core core)],
        'when-body nested repeat multiple spawns preserve declared same-domain metadata',
    );
    is_deeply(
        [ map { $_->{parameter_overrides}[0]{value} } @{$ir->{spawn_instances}} ],
        [qw(16 32)],
        'when-body nested repeat multiple spawns preserve per-instance static parameter overrides',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'when_repeat_multiple_spawns_await_all.fsm'};
    my $top_fsm = $lowered->{files}{'when_repeat_multiple_spawns_await_all_top.fsm'};

    ok(defined($parent_fsm), 'when-body nested repeat multiple-spawn parent scheduled .fsm is emitted');
    ok(defined($top_fsm), 'when-body nested repeat multiple-spawn generated top .fsm is emitted');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_spawn_\d+\)/,
        'sample before the first when-body nested spawn materializes before that spawn state');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_sample_\d+\)/,
        'first when-body nested spawn advances in source order');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(between status\)\)[\s\S]*\(-> parent_spawn_\d+\)/,
        'sample between when-body nested spawns materializes before the second spawn state');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w1_start> 1\)\)[\s\S]*\(-> parent_sample_\d+\)/,
        'second when-body nested spawn advances toward the sync path');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after status\)\)[\s\S]*\(-> parent_await_all_\d+\)/,
        'sample after when-body nested multiple spawns materializes before await_all');
    like($parent_fsm, qr/\(parent_await_all_\d+[\s\S]*\(-> parent_repeat_check_\d+ <\(& w0_done w1_done\)\)/,
        'same-body await_all gates the nested repeat check on both spawned child done handoffs');
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'generated top applies first nested repeat-spawn parameter override once');
    like($top_fsm, qr/\(\?fsmc:w1 worker\s+\(params\s+\(WIDTH 32\)\s+\)\s+\)/s,
        'generated top applies second nested repeat-spawn parameter override once');
    like($top_fsm, qr/\(when_repeat_multiple_spawns_await_all\.w0_data w0\.data\)/,
        'generated top wires first nested repeat-spawn input binding handoff');
    like($top_fsm, qr/\(w1\.resp when_repeat_multiple_spawns_await_all\.w1_resp\)/,
        'generated top wires second nested repeat-spawn output binding handoff');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} } @{$report->{transaction_port_bindings}} ],
        [
            'spawn:w0:data',
            'spawn:w0:resp',
            'spawn:w1:data',
            'spawn:w1:resp',
        ],
        'report exposes when-body nested repeat multiple-spawn port-binding provenance',
    );
    is_deeply(
        $report->{clock_domains}[0]{child_instances},
        [
            { kind => 'spawn', owner => 'parent', child => 'worker', instance => 'w0' },
            { kind => 'spawn', owner => 'parent', child => 'worker', instance => 'w1' },
        ],
        'clock-domain report metadata groups both when-body nested repeat-spawn children by declared domain',
    );
};

subtest 'when body nested repeat multi-pending await_any requires later await_all drain' => sub {
    my $source = <<'ISF';
(actor when_repeat_multi_pending_await_any_drain
  (clock-domains
    (domain core (clock clk) (reset rst_n)))
  (interface
    (input start (domain core))
    (input cond (domain core))
    (input loops (width 3) (domain core))
    (input payload0 (width 8) (domain core))
    (input payload1 (width 8) (domain core))
    (input status (domain core))
    (output done (domain core))
    (output worker_done (domain core))
    (output result0 (width 8) (domain core))
    (output result1 (width 8) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (when cond
      (repeat loops
        (sample status as before)
        (spawn worker as w0
          (params
            (WIDTH 16))
          (bind
            (input data payload0)
            (output resp result0))
          (domain core))
        (spawn worker as w1
          (params
            (WIDTH 32))
          (bind
            (input data payload1)
            (output resp result1))
          (domain core))
        (await_any done)
        (sample status as after_any)
        (await_all done)))
    (complete done))
  (transaction worker
    (domain core)
    (params
      (WIDTH 8))
    (ports
      (input data (width 8))
      (output resp (width 8)))
    (update resp data)
    (complete worker_done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 2,
        'when-body nested repeat multi-pending await_any keeps both static generated child instances');
    is_deeply(
        [ map { $_->{instance} } @{$ir->{spawn_instances}} ],
        [qw(w0 w1)],
        'when-body nested repeat multi-pending await_any preserves lexical instance names',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'when_repeat_multi_pending_await_any_drain.fsm'};
    my $top_fsm = $lowered->{files}{'when_repeat_multi_pending_await_any_drain_top.fsm'};

    ok(defined($parent_fsm), 'when-body nested repeat await_any drain parent scheduled .fsm is emitted');
    ok(defined($top_fsm), 'when-body nested repeat await_any drain generated top .fsm is emitted');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_spawn_\d+\)/,
        'sample before the when-body nested await_any drain spawns materializes first');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_spawn_\d+\)/,
        'first when-body nested await_any drain spawn advances to the second spawn');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w1_start> 1\)\)[\s\S]*\(-> parent_await_any_\d+\)/,
        'second when-body nested await_any drain spawn advances to the observation point');
    like($parent_fsm, qr/\(parent_await_any_\d+[\s\S]*<w0_done[\s\S]*\(-> parent_sample_\d+\)[\s\S]*<w1_done[\s\S]*\(-> parent_sample_\d+\)/,
        'multi-pending when-body nested await_any observes either generated child before continuing');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after_any status\)\)[\s\S]*\(-> parent_await_all_\d+\)/,
        'sample after when-body nested multi-pending await_any materializes before the mandatory drain');
    like($parent_fsm, qr/\(parent_await_all_\d+[\s\S]*\(-> parent_repeat_check_\d+ <\(& w0_done w1_done\)\)/,
        'mandatory await_all drain gates the when-body nested repeat check on all pending generated children');
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'generated top applies first when-body nested await_any drain parameter override once');
    like($top_fsm, qr/\(\?fsmc:w1 worker\s+\(params\s+\(WIDTH 32\)\s+\)\s+\)/s,
        'generated top applies second when-body nested await_any drain parameter override once');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} } @{$report->{transaction_port_bindings}} ],
        [
            'spawn:w0:data',
            'spawn:w0:resp',
            'spawn:w1:data',
            'spawn:w1:resp',
        ],
        'report exposes when-body nested repeat await_any drain port-binding provenance',
    );
    is_deeply(
        $report->{clock_domains}[0]{child_instances},
        [
            { kind => 'spawn', owner => 'parent', child => 'worker', instance => 'w0' },
            { kind => 'spawn', owner => 'parent', child => 'worker', instance => 'w1' },
        ],
        'clock-domain report metadata groups both when-body nested await_any drain children by declared domain',
    );
};

subtest 'when body nested repeat spawn drains through single-pending await_any' => sub {
    my $source = <<'ISF';
(actor when_repeat_spawn_await_any
  (clock-domains
    (domain core (clock clk) (reset rst_n)))
  (interface
    (input start (domain core))
    (input cond (domain core))
    (input loops (width 3) (domain core))
    (input payload (width 8) (domain core))
    (input status (domain core))
    (output done (domain core))
    (output worker_done (domain core))
    (output result (width 8) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (when cond
      (repeat loops
        (sample status as before)
        (spawn worker as w0
          (params
            (WIDTH 16))
          (bind
            (input data payload)
            (output resp result))
          (domain core))
        (sample status as after)
        (await_any done)))
    (complete done))
  (transaction worker
    (domain core)
    (params
      (WIDTH 8))
    (ports
      (input data (width 8))
      (output resp (width 8)))
    (update resp data)
    (complete worker_done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 1,
        'when-body nested repeat await_any spawn contributes one static generated child instance');
    is($ir->{spawn_instances}[0]{child}, 'worker',
        'when-body nested repeat await_any spawn targets the worker transaction');
    is($ir->{spawn_instances}[0]{instance}, 'w0',
        'when-body nested repeat await_any spawn preserves the lexical instance name');
    is($ir->{spawn_instances}[0]{domain}, 'core',
        'when-body nested repeat await_any spawn preserves declared same-domain metadata');
    is_deeply(
        $ir->{spawn_instances}[0]{parameter_overrides},
        [{ name => 'WIDTH', value => '16' }],
        'when-body nested repeat await_any spawn preserves static parameter overrides',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'when_repeat_spawn_await_any.fsm'};
    my $top_fsm = $lowered->{files}{'when_repeat_spawn_await_any_top.fsm'};

    ok(defined($parent_fsm), 'when-body nested repeat await_any parent scheduled .fsm is emitted');
    ok(defined($top_fsm), 'when-body nested repeat await_any generated top .fsm is emitted');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_spawn_\d+\)/,
        'sample before nested await_any spawn materializes before the spawn state');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_sample_\d+\)/,
        'when-body nested await_any spawn starts the static child before the following sample');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after status\)\)[\s\S]*\(-> parent_await_any_\d+\)/,
        'sample after nested spawn materializes before await_any');
    like($parent_fsm, qr/\(parent_await_any_\d+[\s\S]*<w0_done[\s\S]*\(-> parent_repeat_check_\d+\)/,
        'single-pending await_any gates the nested repeat check on the spawned child done');
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'generated top applies nested repeat-spawn await_any parameter overrides once');
    like($top_fsm, qr/\(when_repeat_spawn_await_any\.w0_data w0\.data\)/,
        'generated top wires nested repeat-spawn await_any input binding handoff');
    like($top_fsm, qr/\(w0\.resp when_repeat_spawn_await_any\.w0_resp\)/,
        'generated top wires nested repeat-spawn await_any output binding handoff');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} } @{$report->{transaction_port_bindings}} ],
        [
            'spawn:w0:data',
            'spawn:w0:resp',
        ],
        'report exposes when-body nested repeat-spawn await_any port-binding provenance',
    );
    is_deeply(
        $report->{clock_domains}[0]{child_instances},
        [{ kind => 'spawn', owner => 'parent', child => 'worker', instance => 'w0' }],
        'clock-domain report metadata groups the when-body nested repeat-spawn await_any child by declared domain',
    );
};

subtest 'switch branch nested repeat spawn drains through same-body await_all' => sub {
    my $source = <<'ISF';
(actor switch_repeat_spawn_await_all
  (clock-domains
    (domain core (clock clk) (reset rst_n)))
  (interface
    (input start (domain core))
    (input mode (width 2) (domain core))
    (input loops (width 3) (domain core))
    (input payload (width 8) (domain core))
    (input status (domain core))
    (output done (domain core))
    (output worker_done (domain core))
    (output result (width 8) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (switch mode
      (0
        (repeat loops
          (sample status as before)
          (spawn worker as w0
            (params
              (WIDTH 16))
            (bind
              (input data payload)
              (output resp result))
            (domain core))
          (sample status as after)
          (await_all done)))
      (1
        (sample status as other)))
    (complete done))
  (transaction worker
    (domain core)
    (params
      (WIDTH 8))
    (ports
      (input data (width 8))
      (output resp (width 8)))
    (update resp data)
    (complete worker_done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 1,
        'switch-branch nested repeat spawn contributes one static generated child instance');
    is($ir->{spawn_instances}[0]{child}, 'worker',
        'switch-branch nested repeat spawn targets the worker transaction');
    is($ir->{spawn_instances}[0]{instance}, 'w0',
        'switch-branch nested repeat spawn preserves the lexical instance name');
    is($ir->{spawn_instances}[0]{domain}, 'core',
        'switch-branch nested repeat spawn preserves declared same-domain metadata');
    is_deeply(
        $ir->{spawn_instances}[0]{parameter_overrides},
        [{ name => 'WIDTH', value => '16' }],
        'switch-branch nested repeat spawn preserves static parameter overrides',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'switch_repeat_spawn_await_all.fsm'};
    my $top_fsm = $lowered->{files}{'switch_repeat_spawn_await_all_top.fsm'};

    ok(defined($parent_fsm), 'switch-branch nested repeat spawn parent scheduled .fsm is emitted');
    ok(defined($top_fsm), 'switch-branch nested repeat spawn generated top .fsm is emitted');
    like($parent_fsm, qr/\(parent_switch_\d+[\s\S]*\(=0 \(-> parent_repeat_init_\d+\)\)/,
        'matching switch branch enters the nested repeat region');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_spawn_\d+\)/,
        'sample before switch nested spawn materializes before the spawn state');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_sample_\d+\)/,
        'switch-branch nested spawn starts the static child before the following sample');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after status\)\)[\s\S]*\(-> parent_await_all_\d+\)/,
        'sample after switch nested spawn materializes before await_all');
    like($parent_fsm, qr/\(parent_await_all_\d+[\s\S]*\(-> parent_repeat_check_\d+ <w0_done\)/,
        'same-body await_all gates the switch nested repeat check on the spawned child done');
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'generated top applies switch nested repeat-spawn parameter overrides once');
    like($top_fsm, qr/\(switch_repeat_spawn_await_all\.w0_data w0\.data\)/,
        'generated top wires switch nested repeat-spawn input binding handoff');
    like($top_fsm, qr/\(w0\.resp switch_repeat_spawn_await_all\.w0_resp\)/,
        'generated top wires switch nested repeat-spawn output binding handoff');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} } @{$report->{transaction_port_bindings}} ],
        [
            'spawn:w0:data',
            'spawn:w0:resp',
        ],
        'report exposes switch-branch nested repeat-spawn transaction port-binding provenance',
    );
    is_deeply(
        $report->{clock_domains}[0]{child_instances},
        [{ kind => 'spawn', owner => 'parent', child => 'worker', instance => 'w0' }],
        'clock-domain report metadata groups the switch-branch nested repeat-spawn child by declared domain',
    );
};

subtest 'switch branch nested repeat multiple spawns drain through same-body await_all' => sub {
    my $source = <<'ISF';
(actor switch_repeat_multiple_spawns_await_all
  (clock-domains
    (domain core (clock clk) (reset rst_n)))
  (interface
    (input start (domain core))
    (input mode (width 2) (domain core))
    (input loops (width 3) (domain core))
    (input payload0 (width 8) (domain core))
    (input payload1 (width 8) (domain core))
    (input status (domain core))
    (output done (domain core))
    (output worker_done (domain core))
    (output result0 (width 8) (domain core))
    (output result1 (width 8) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (switch mode
      (0
        (repeat loops
          (sample status as before)
          (spawn worker as w0
            (params
              (WIDTH 16))
            (bind
              (input data payload0)
              (output resp result0))
            (domain core))
          (sample status as between)
          (spawn worker as w1
            (params
              (WIDTH 32))
            (bind
              (input data payload1)
              (output resp result1))
            (domain core))
          (sample status as after)
          (await_all done)))
      (1
        (sample status as other)))
    (complete done))
  (transaction worker
    (domain core)
    (params
      (WIDTH 8))
    (ports
      (input data (width 8))
      (output resp (width 8)))
    (update resp data)
    (complete worker_done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 2,
        'switch-branch nested repeat multiple spawns contribute two static generated child instances');
    is_deeply(
        [ map { $_->{instance} } @{$ir->{spawn_instances}} ],
        [qw(w0 w1)],
        'switch-branch nested repeat multiple spawns preserve lexical instance names',
    );
    is_deeply(
        [ map { $_->{parameter_overrides}[0]{value} } @{$ir->{spawn_instances}} ],
        [qw(16 32)],
        'switch-branch nested repeat multiple spawns preserve per-instance static parameter overrides',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'switch_repeat_multiple_spawns_await_all.fsm'};
    my $top_fsm = $lowered->{files}{'switch_repeat_multiple_spawns_await_all_top.fsm'};

    ok(defined($parent_fsm), 'switch-branch nested repeat multiple-spawn parent scheduled .fsm is emitted');
    ok(defined($top_fsm), 'switch-branch nested repeat multiple-spawn generated top .fsm is emitted');
    like($parent_fsm, qr/\(parent_switch_\d+[\s\S]*\(=0 \(-> parent_repeat_init_\d+\)\)/,
        'matching switch branch enters the multiple-spawn nested repeat region');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_spawn_\d+\)/,
        'sample before the first switch nested spawn materializes before that spawn state');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_sample_\d+\)/,
        'first switch nested spawn advances in source order');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(between status\)\)[\s\S]*\(-> parent_spawn_\d+\)/,
        'sample between switch nested spawns materializes before the second spawn state');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w1_start> 1\)\)[\s\S]*\(-> parent_sample_\d+\)/,
        'second switch nested spawn advances toward the sync path');
    like($parent_fsm, qr/\(parent_await_all_\d+[\s\S]*\(-> parent_repeat_check_\d+ <\(& w0_done w1_done\)\)/,
        'same-body await_all gates the switch nested repeat check on both spawned child done handoffs');
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'generated top applies first switch nested repeat-spawn parameter override once');
    like($top_fsm, qr/\(\?fsmc:w1 worker\s+\(params\s+\(WIDTH 32\)\s+\)\s+\)/s,
        'generated top applies second switch nested repeat-spawn parameter override once');
    like($top_fsm, qr/\(switch_repeat_multiple_spawns_await_all\.w0_data w0\.data\)/,
        'generated top wires first switch nested repeat-spawn input binding handoff');
    like($top_fsm, qr/\(w1\.resp switch_repeat_multiple_spawns_await_all\.w1_resp\)/,
        'generated top wires second switch nested repeat-spawn output binding handoff');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} } @{$report->{transaction_port_bindings}} ],
        [
            'spawn:w0:data',
            'spawn:w0:resp',
            'spawn:w1:data',
            'spawn:w1:resp',
        ],
        'report exposes switch-branch nested repeat multiple-spawn port-binding provenance',
    );
    is_deeply(
        $report->{clock_domains}[0]{child_instances},
        [
            { kind => 'spawn', owner => 'parent', child => 'worker', instance => 'w0' },
            { kind => 'spawn', owner => 'parent', child => 'worker', instance => 'w1' },
        ],
        'clock-domain report metadata groups both switch-branch nested repeat-spawn children by declared domain',
    );
};

subtest 'switch branch nested repeat multi-pending await_any requires later await_all drain' => sub {
    my $source = <<'ISF';
(actor switch_repeat_multi_pending_await_any_drain
  (clock-domains
    (domain core (clock clk) (reset rst_n)))
  (interface
    (input start (domain core))
    (input mode (width 2) (domain core))
    (input loops (width 3) (domain core))
    (input payload0 (width 8) (domain core))
    (input payload1 (width 8) (domain core))
    (input status (domain core))
    (output done (domain core))
    (output worker_done (domain core))
    (output result0 (width 8) (domain core))
    (output result1 (width 8) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (switch mode
      (0
        (repeat loops
          (sample status as before)
          (spawn worker as w0
            (params
              (WIDTH 16))
            (bind
              (input data payload0)
              (output resp result0))
            (domain core))
          (spawn worker as w1
            (params
              (WIDTH 32))
            (bind
              (input data payload1)
              (output resp result1))
            (domain core))
          (await_any done)
          (sample status as after_any)
          (await_all done)))
      (1
        (sample status as other)))
    (complete done))
  (transaction worker
    (domain core)
    (params
      (WIDTH 8))
    (ports
      (input data (width 8))
      (output resp (width 8)))
    (update resp data)
    (complete worker_done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 2,
        'switch-branch nested repeat multi-pending await_any keeps both static generated child instances');
    is_deeply(
        [ map { $_->{instance} } @{$ir->{spawn_instances}} ],
        [qw(w0 w1)],
        'switch-branch nested repeat multi-pending await_any preserves lexical instance names',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'switch_repeat_multi_pending_await_any_drain.fsm'};
    my $top_fsm = $lowered->{files}{'switch_repeat_multi_pending_await_any_drain_top.fsm'};

    ok(defined($parent_fsm), 'switch-branch nested repeat await_any drain parent scheduled .fsm is emitted');
    ok(defined($top_fsm), 'switch-branch nested repeat await_any drain generated top .fsm is emitted');
    like($parent_fsm, qr/\(parent_switch_\d+[\s\S]*\(=0 \(-> parent_repeat_init_\d+\)\)/,
        'matching switch branch enters the await_any drain nested repeat region');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_spawn_\d+\)/,
        'sample before the switch nested await_any drain spawns materializes first');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_spawn_\d+\)/,
        'first switch nested await_any drain spawn advances to the second spawn');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w1_start> 1\)\)[\s\S]*\(-> parent_await_any_\d+\)/,
        'second switch nested await_any drain spawn advances to the observation point');
    like($parent_fsm, qr/\(parent_await_any_\d+[\s\S]*<w0_done[\s\S]*\(-> parent_sample_\d+\)[\s\S]*<w1_done[\s\S]*\(-> parent_sample_\d+\)/,
        'multi-pending switch nested await_any observes either generated child before continuing');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after_any status\)\)[\s\S]*\(-> parent_await_all_\d+\)/,
        'sample after switch nested multi-pending await_any materializes before the mandatory drain');
    like($parent_fsm, qr/\(parent_await_all_\d+[\s\S]*\(-> parent_repeat_check_\d+ <\(& w0_done w1_done\)\)/,
        'mandatory await_all drain gates the switch nested repeat check on all pending generated children');
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'generated top applies first switch nested await_any drain parameter override once');
    like($top_fsm, qr/\(\?fsmc:w1 worker\s+\(params\s+\(WIDTH 32\)\s+\)\s+\)/s,
        'generated top applies second switch nested await_any drain parameter override once');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} } @{$report->{transaction_port_bindings}} ],
        [
            'spawn:w0:data',
            'spawn:w0:resp',
            'spawn:w1:data',
            'spawn:w1:resp',
        ],
        'report exposes switch-branch nested repeat await_any drain port-binding provenance',
    );
    is_deeply(
        $report->{clock_domains}[0]{child_instances},
        [
            { kind => 'spawn', owner => 'parent', child => 'worker', instance => 'w0' },
            { kind => 'spawn', owner => 'parent', child => 'worker', instance => 'w1' },
        ],
        'clock-domain report metadata groups both switch-branch nested await_any drain children by declared domain',
    );
};

subtest 'switch branch nested repeat spawn drains through single-pending await_any' => sub {
    my $source = <<'ISF';
(actor switch_repeat_spawn_await_any
  (clock-domains
    (domain core (clock clk) (reset rst_n)))
  (interface
    (input start (domain core))
    (input mode (width 2) (domain core))
    (input loops (width 3) (domain core))
    (input payload (width 8) (domain core))
    (input status (domain core))
    (output done (domain core))
    (output worker_done (domain core))
    (output result (width 8) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (switch mode
      (0
        (repeat loops
          (sample status as before)
          (spawn worker as w0
            (params
              (WIDTH 16))
            (bind
              (input data payload)
              (output resp result))
            (domain core))
          (sample status as after)
          (await_any done)))
      (1
        (sample status as other)))
    (complete done))
  (transaction worker
    (domain core)
    (params
      (WIDTH 8))
    (ports
      (input data (width 8))
      (output resp (width 8)))
    (update resp data)
    (complete worker_done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 1,
        'switch-branch nested repeat await_any spawn contributes one static generated child instance');
    is($ir->{spawn_instances}[0]{child}, 'worker',
        'switch-branch nested repeat await_any spawn targets the worker transaction');
    is($ir->{spawn_instances}[0]{instance}, 'w0',
        'switch-branch nested repeat await_any spawn preserves the lexical instance name');
    is($ir->{spawn_instances}[0]{domain}, 'core',
        'switch-branch nested repeat await_any spawn preserves declared same-domain metadata');
    is_deeply(
        $ir->{spawn_instances}[0]{parameter_overrides},
        [{ name => 'WIDTH', value => '16' }],
        'switch-branch nested repeat await_any spawn preserves static parameter overrides',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'switch_repeat_spawn_await_any.fsm'};
    my $top_fsm = $lowered->{files}{'switch_repeat_spawn_await_any_top.fsm'};

    ok(defined($parent_fsm), 'switch-branch nested repeat await_any parent scheduled .fsm is emitted');
    ok(defined($top_fsm), 'switch-branch nested repeat await_any generated top .fsm is emitted');
    like($parent_fsm, qr/\(parent_switch_\d+[\s\S]*\(=0 \(-> parent_repeat_init_\d+\)\)/,
        'matching switch branch enters the await_any nested repeat region');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_spawn_\d+\)/,
        'sample before switch nested await_any spawn materializes before the spawn state');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_sample_\d+\)/,
        'switch-branch nested await_any spawn starts the static child before the following sample');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after status\)\)[\s\S]*\(-> parent_await_any_\d+\)/,
        'sample after switch nested spawn materializes before await_any');
    like($parent_fsm, qr/\(parent_await_any_\d+[\s\S]*<w0_done[\s\S]*\(-> parent_repeat_check_\d+\)/,
        'single-pending await_any gates the switch nested repeat check on the spawned child done');
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'generated top applies switch nested repeat-spawn await_any parameter overrides once');
    like($top_fsm, qr/\(switch_repeat_spawn_await_any\.w0_data w0\.data\)/,
        'generated top wires switch nested repeat-spawn await_any input binding handoff');
    like($top_fsm, qr/\(w0\.resp switch_repeat_spawn_await_any\.w0_resp\)/,
        'generated top wires switch nested repeat-spawn await_any output binding handoff');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} } @{$report->{transaction_port_bindings}} ],
        [
            'spawn:w0:data',
            'spawn:w0:resp',
        ],
        'report exposes switch-branch nested repeat-spawn await_any port-binding provenance',
    );
    is_deeply(
        $report->{clock_domains}[0]{child_instances},
        [{ kind => 'spawn', owner => 'parent', child => 'worker', instance => 'w0' }],
        'clock-domain report metadata groups the switch-branch nested repeat-spawn await_any child by declared domain',
    );
};

subtest 'repeat body await_any accepts exactly one pending static child' => sub {
    my $source = <<'ISF';
(actor repeat_spawn_await_any
  (clock clk)
  (interface
    (input start)
    (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0)
      (await_any done))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 1,
        'repeat-body await_any keeps one static generated child instance');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'repeat_spawn_await_any.fsm'};
    my $top_fsm = $lowered->{files}{'repeat_spawn_await_any_top.fsm'};

    ok(defined($parent_fsm), 'repeat-spawn await_any parent scheduled .fsm is emitted');
    ok(defined($top_fsm), 'repeat-spawn await_any generated top .fsm is emitted');
    like($parent_fsm, qr/\(parent_spawn_2[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_await_any_3\)/,
        'repeat body spawn advances to await_any');
    like($parent_fsm, qr/\(parent_await_any_3[\s\S]*<w0_done[\s\S]*\(-> parent_repeat_check_4\)/,
        'single-pending repeat-body await_any waits for the one child done before the repeat check');
    like($top_fsm, qr/\(\?fsmc:w0 worker(?:\s|\))/,
        'generated top instantiates the repeat-spawn await_any child once');
};

subtest 'repeat body multi-pending await_any requires later await_all drain' => sub {
    my $source = <<'ISF';
(actor repeat_await_any_multi_pending_drain
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input loops (width 3))
    (input status)
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0)
      (spawn worker as w1)
      (await_any done)
      (sample status as after_any)
      (await_all done))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    my $lowered = lower_source($source);
    my $parent_fsm = $lowered->{files}{'repeat_await_any_multi_pending_drain.fsm'};
    my $top_fsm = $lowered->{files}{'repeat_await_any_multi_pending_drain_top.fsm'};

    ok(defined($parent_fsm), 'multi-pending await_any drain parent scheduled .fsm is emitted');
    ok(defined($top_fsm), 'multi-pending await_any drain generated top .fsm is emitted');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_spawn_\d+\)/,
        'first repeat-body spawn advances to the second spawn');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w1_start> 1\)\)[\s\S]*\(-> parent_await_any_\d+\)/,
        'second repeat-body spawn advances to multi-pending await_any');
    like($parent_fsm, qr/\(parent_await_any_\d+[\s\S]*<w0_done[\s\S]*\(-> parent_sample_\d+\)[\s\S]*<w1_done[\s\S]*\(-> parent_sample_\d+\)/,
        'multi-pending await_any observes either spawned child before continuing');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after_any status\)\)[\s\S]*\(-> parent_await_all_\d+\)/,
        'sample after multi-pending await_any materializes before the drain');
    like($parent_fsm, qr/\(parent_await_all_\d+[\s\S]*\(-> parent_repeat_check_\d+ <\(& w0_done w1_done\)\)/,
        'mandatory await_all drain keeps all spawned children before the repeat check');
    like($top_fsm, qr/\(\?fsmc:w0 worker(?:\s|\))/,
        'generated top instantiates first multi-pending repeat child once');
    like($top_fsm, qr/\(\?fsmc:w1 worker(?:\s|\))/,
        'generated top instantiates second multi-pending repeat child once');
};

subtest 'repeat body local do waits for child done before re-entry' => sub {
    my $source = <<'ISF';
(actor repeat_do_local
  (clock clk)
  (interface
    (input start)
    (input loops (width 3))
    (output child_public_done)
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (do worker))
    (complete done))
  (transaction worker
    (on start)
    (complete child_public_done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 0,
        'repeat-body local do does not create a generated child instance');
    is($ir->{counters}{worker_start}, 1,
        'repeat-body local do registers the local child start handoff');
    is($ir->{counters}{worker_done}, 1,
        'repeat-body local do registers the local child done handoff');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'repeat_do_local.fsm'};

    ok(defined($fsm), 'repeat-body local do parent scheduled .fsm is emitted');
    ok(!exists($lowered->{files}{'worker.fsm'}), 'repeat-body local do keeps the child in the parent module');
    ok(!exists($lowered->{files}{'repeat_do_local_top.fsm'}), 'repeat-body local do does not emit a generated top');
    like($fsm, qr/\(parent_do_2[\s\S]*\(= \(worker_start 1\)\)[\s\S]*<worker_done[\s\S]*\(-> parent_repeat_check_3\)/,
        'repeat-body local do starts the child and waits for its fresh done before the repeat check');
    like($fsm, qr/\(parent_repeat_check_3[\s\S]*\(-> parent_repeat_init_1\)/,
        'repeat check back-edge is reachable only after the local do state');
    like($fsm, qr/\(worker_idle_0[\s\S]*<worker_start[\s\S]*\(-> worker_done_1\)/,
        'local child entry is rewired to the generated start handoff');
    like($fsm, qr/\(worker_done_1[\s\S]*\(<1 \(worker_done 1\)\)/,
        'local child terminal pulses the generated child done handoff');
};

subtest 'repeat body samples after spawn materialize before sync' => sub {
    my $await_all_source = <<'ISF';
(actor repeat_spawn_sample_after
  (clock clk)
  (interface
    (input start)
    (input loops (width 3))
    (input status)
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0)
      (sample status as seen)
      (await_all done))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    my $await_all = lower_source($await_all_source);
    my $await_all_fsm = $await_all->{files}{'repeat_spawn_sample_after.fsm'};
    like($await_all_fsm, qr/\(parent_spawn_2[\s\S]*\(-> parent_sample_3\)/,
        'repeat-body spawn advances to the explicit sample state');
    like($await_all_fsm, qr/\(parent_sample_3[\s\S]*\(<= \(seen status\)\)[\s\S]*\(-> parent_await_all_4\)/,
        'repeat-body sample after spawn materializes before await_all');
    like($await_all_fsm, qr/\(parent_await_all_4[\s\S]*\(-> parent_repeat_check_5 <w0_done\)/,
        'await_all still gates the repeat check after the sample state');

    my $await_any_source = <<'ISF';
(actor repeat_spawn_sample_after_any
  (clock clk)
  (interface
    (input start)
    (input loops (width 3))
    (input status)
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0)
      (sample status as seen)
      (await_any done))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    my $await_any = lower_source($await_any_source);
    my $await_any_fsm = $await_any->{files}{'repeat_spawn_sample_after_any.fsm'};
    like($await_any_fsm, qr/\(parent_sample_3[\s\S]*\(<= \(seen status\)\)[\s\S]*\(-> parent_await_any_4\)/,
        'repeat-body sample after spawn materializes before single-pending await_any');
    like($await_any_fsm, qr/\(parent_await_any_4[\s\S]*<w0_done[\s\S]*\(-> parent_repeat_check_5\)/,
        'single-pending await_any still gates the repeat check after the sample state');

    my $sample_before_source = <<'ISF';
(actor repeat_spawn_sample_before
  (clock clk)
  (interface
    (input start)
    (input loops (width 3))
    (input status)
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (sample status as seen)
      (spawn worker as w0)
      (await_all done))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    my $sample_before = lower_source($sample_before_source);
    my $sample_before_fsm = $sample_before->{files}{'repeat_spawn_sample_before.fsm'};
    like($sample_before_fsm, qr/\(parent_sample_2[\s\S]*\(<= \(seen status\)\)[\s\S]*\(-> parent_spawn_3\)/,
        'repeat-body sample before spawn materializes before the spawn state');
    like($sample_before_fsm, qr/\(parent_spawn_3[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_await_all_4\)/,
        'repeat-body spawn after sample still starts the static child before sync');
    like($sample_before_fsm, qr/\(parent_await_all_4[\s\S]*\(-> parent_repeat_check_5 <w0_done\)/,
        'await_all gates the repeat check after sample-before-spawn ordering');

    my $sample_before_any_source = <<'ISF';
(actor repeat_spawn_sample_before_any
  (clock clk)
  (interface
    (input start)
    (input loops (width 3))
    (input status)
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (sample status as seen)
      (spawn worker as w0)
      (await_any done))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    my $sample_before_any = lower_source($sample_before_any_source);
    my $sample_before_any_fsm = $sample_before_any->{files}{'repeat_spawn_sample_before_any.fsm'};
    like($sample_before_any_fsm, qr/\(parent_sample_2[\s\S]*\(<= \(seen status\)\)[\s\S]*\(-> parent_spawn_3\)/,
        'repeat-body sample before spawn materializes before single-pending await_any spawn');
    like($sample_before_any_fsm, qr/\(parent_await_any_4[\s\S]*<w0_done[\s\S]*\(-> parent_repeat_check_5\)/,
        'single-pending await_any gates the repeat check after sample-before-spawn ordering');
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

subtest 'repeat body parameterized do lowers through a generated child activation instance' => sub {
    my $source = <<'ISF';
(actor repeat_parameterized_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (do worker
        (params
          (WIDTH 16))))
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 1, 'repeat-body parameterized do contributes one generated activation instance');
    my $instance = $ir->{spawn_instances}[0];
    is($instance->{activation_kind}, 'do', 'repeat-body generated instance preserves do activation provenance');
    is($instance->{child}, 'worker', 'repeat-body generated do targets the child transaction module');
    is($instance->{instance}, 'parent_worker_repeat_do_0', 'repeat-body generated do instance name is deterministic');
    is_deeply(
        $instance->{parameter_overrides},
        [ { name => 'WIDTH', value => '16' } ],
        'repeat-body generated do preserves parameter overrides',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'repeat_parameterized_do.fsm'};
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    my $top_fsm = $lowered->{files}{'repeat_parameterized_do_top.fsm'};

    ok(defined($parent_fsm), 'repeat-body generated do parent scheduled .fsm is emitted');
    ok(defined($child_fsm), 'repeat-body generated do child scheduled .fsm is emitted');
    ok(defined($top_fsm), 'repeat-body generated do top .fsm is emitted');
    like($parent_fsm, qr/\(parent_do_2[\s\S]*\(= \(parent_worker_repeat_do_0_start> 1\)\)[\s\S]*<parent_worker_repeat_do_0_done\s+\(-> parent_repeat_check_3\)/,
        'repeat-body generated do starts the generated instance and gates the repeat check on done');
    like($top_fsm, qr/\(\?fsmc:parent_worker_repeat_do_0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'repeat-body generated top applies the do parameter override once');
    like($top_fsm, qr/\(repeat_parameterized_do\.parent_worker_repeat_do_0_start parent_worker_repeat_do_0\.start\)/,
        'repeat-body generated top wires do start handoff');
    like($top_fsm, qr/\(parent_worker_repeat_do_0\.done repeat_parameterized_do\.parent_worker_repeat_do_0_done\)/,
        'repeat-body generated top wires do done handoff');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is($report->{generated_composition}{instances}[0]{activation_kind}, 'do',
        'report preserves repeat-body generated do activation kind');
    is($report->{generated_composition}{instances}[0]{instance}, 'parent_worker_repeat_do_0',
        'report exposes repeat-body generated do instance name');
    is_deeply(
        $report->{generated_composition}{instances}[0]{parameter_bindings},
        [ { name => 'WIDTH', source => 'override', value => '16' } ],
        'report exposes repeat-body generated do parameter binding provenance',
    );
};

subtest 'repeat body parameterized do bindings lower through generated handoffs' => sub {
    my $source = <<'ISF';
(actor repeat_parameterized_do_binding
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input loops (width 3))
    (input req_addr (width 8))
    (output done)
    (output resp (width 8)))
  (transaction parent
    (on start)
    (repeat loops
      (do worker
        (params
          (WIDTH 16))
        (bind
          (input addr req_addr)
          (output data resp))))
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
    my $instance = $ir->{spawn_instances}[0];
    is($instance->{instance}, 'parent_worker_repeat_do_0', 'repeat-body generated do binding instance name is deterministic');
    is_deeply(
        $instance->{port_bindings},
        [
            {
                role         => 'input',
                child_port   => 'addr',
                parent_port  => 'parent_worker_repeat_do_0_addr',
                actor_signal => 'req_addr',
                actor_expr => 'req_addr',
                actor_expression => 'req_addr',
                width        => 8,
            },
            {
                role         => 'output',
                child_port   => 'data',
                parent_port  => 'parent_worker_repeat_do_0_data',
                actor_signal => 'resp',
                actor_expr => 'resp',
                actor_expression => 'resp',
                width        => 8,
            },
        ],
        'repeat-body generated do exposes reviewable port-binding handoffs',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'repeat_parameterized_do_binding.fsm'};
    my $top_fsm = $lowered->{files}{'repeat_parameterized_do_binding_top.fsm'};

    like($parent_fsm, qr/\(-parent_worker_repeat_do_0_port_bindings\s+\(= \(parent_worker_repeat_do_0_addr> req_addr\)\)\s+\(= \(resp> parent_worker_repeat_do_0_data\) <parent_worker_repeat_do_0_done\)\s+\)/s,
        'repeat-body generated do parent .fsm keeps binding handoffs reviewable');
    like($top_fsm, qr/\(repeat_parameterized_do_binding\.parent_worker_repeat_do_0_addr parent_worker_repeat_do_0\.addr\)/,
        'generated top wires repeat-body do input binding handoff');
    like($top_fsm, qr/\(parent_worker_repeat_do_0\.data repeat_parameterized_do_binding\.parent_worker_repeat_do_0_data\)/,
        'generated top wires repeat-body do output binding handoff');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} } @{$report->{transaction_port_bindings}} ],
        [
            'do:parent_worker_repeat_do_0:addr',
            'do:parent_worker_repeat_do_0:data',
        ],
        'report exposes repeat-body generated do transaction port-binding provenance',
    );
};

subtest 'repeat body plain do targets already generated child through generated instance' => sub {
    my $source = <<'ISF';
(actor repeat_generated_child_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (do worker))
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 2, 'repeat plain do plus later spawn contribute generated instances');
    my %instances = map { $_->{instance} => $_ } @{$ir->{spawn_instances}};
    ok($instances{parent_worker_repeat_do_0}, 'repeat-body generated-child do instance is recorded');
    is($instances{parent_worker_repeat_do_0}{activation_kind}, 'do',
        'repeat-body generated-child do preserves do activation provenance');
    is($instances{parent_worker_repeat_do_0}{child}, 'worker',
        'repeat-body generated-child do targets the generated child transaction');
    is_deeply($instances{parent_worker_repeat_do_0}{parameter_overrides}, [],
        'repeat-body generated-child do does not require local parameter overrides');
    ok($instances{w0}, 'later spawn instance still exists');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'repeat_generated_child_do.fsm'};
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    my $top_fsm = $lowered->{files}{'repeat_generated_child_do_top.fsm'};

    ok(defined($parent_fsm), 'repeat generated-child do parent scheduled .fsm is emitted');
    ok(defined($child_fsm), 'generated child scheduled .fsm is emitted once');
    ok(defined($top_fsm), 'repeat generated-child do top .fsm is emitted');
    like($parent_fsm, qr/\(parent_do_\d+[\s\S]*\(= \(parent_worker_repeat_do_0_start> 1\)\)[\s\S]*<parent_worker_repeat_do_0_done\s+\(-> parent_repeat_check_\d+\)/,
        'repeat-body generated-child do starts the generated instance and gates the repeat check on done');
    like($parent_fsm, qr/\(parent_spawn_\d+[\s\S]*\(= \(w0_start> 1\)\)[\s\S]*\(-> parent_await_all_\d+\)/,
        'later spawn still starts its own static instance');
    like($top_fsm, qr/\(\?fsmc:parent_worker_repeat_do_0 worker(?:\s|\))/,
        'generated top instantiates the repeat-body generated-child do child once');
    like($top_fsm, qr/\(\?fsmc:w0 worker(?:\s|\))/,
        'generated top also instantiates the later spawned child');
};

subtest 'repeat body samples around do materialize in source order' => sub {
    my $local_source = <<'ISF';
(actor repeat_do_samples_local
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input loops (width 3))
    (input status)
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (sample status as before)
      (do worker)
      (sample status as after))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    my $local = lower_source($local_source);
    my $local_fsm = $local->{files}{'repeat_do_samples_local.fsm'};
    like($local_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_do_\d+\)/,
        'sample before local repeat do materializes before the do state');
    like($local_fsm, qr/\(parent_do_\d+[\s\S]*\(= \(worker_start 1\)\)[\s\S]*<worker_done\s+\(-> parent_sample_\d+\)/,
        'local repeat do waits for done before the following sample state');
    like($local_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after status\)\)[\s\S]*\(-> parent_repeat_check_\d+\)/,
        'sample after local repeat do materializes before the repeat check');

    my $generated_source = <<'ISF';
(actor repeat_do_samples_generated
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input loops (width 3))
    (input status)
    (output done))
  (transaction parent
    (on start)
    (repeat loops
      (sample status as before)
      (do worker
        (params
          (WIDTH 16)))
      (sample status as after))
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    my $generated = lower_source($generated_source);
    my $generated_fsm = $generated->{files}{'repeat_do_samples_generated.fsm'};
    like($generated_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_do_\d+\)/,
        'sample before generated repeat do materializes before the generated do state');
    like($generated_fsm, qr/\(parent_do_\d+[\s\S]*\(= \(parent_worker_repeat_do_0_start> 1\)\)[\s\S]*<parent_worker_repeat_do_0_done\s+\(-> parent_sample_\d+\)/,
        'generated repeat do waits for done before the following sample state');
    like($generated_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after status\)\)[\s\S]*\(-> parent_repeat_check_\d+\)/,
        'sample after generated repeat do materializes before the repeat check');
};

subtest 'when body nested repeat local do waits for child done before re-entry' => sub {
    my $source = <<'ISF';
(actor when_repeat_do_local
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input cond)
    (input loops (width 3))
    (input status)
    (output child_public_done)
    (output done))
  (transaction parent
    (on start)
    (when cond
      (repeat loops
        (sample status as before)
        (do worker)
        (sample status as after)))
    (complete done))
  (transaction worker
    (on start)
    (complete child_public_done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 0,
        'when-body repeat local do does not create a generated child instance');
    is($ir->{counters}{worker_start}, 1,
        'when-body repeat local do registers the local child start handoff');
    is($ir->{counters}{worker_done}, 1,
        'when-body repeat local do registers the local child done handoff');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'when_repeat_do_local.fsm'};

    ok(defined($fsm), 'when-body repeat local do parent scheduled .fsm is emitted');
    ok(!exists($lowered->{files}{'worker.fsm'}), 'when-body repeat local do keeps the child in the parent module');
    ok(!exists($lowered->{files}{'when_repeat_do_local_top.fsm'}), 'when-body repeat local do does not emit a generated top');
    like($fsm, qr/\(parent_when_\d+[\s\S]*\(=1 \(-> parent_repeat_init_\d+\)\)/,
        'when true path enters the nested repeat region');
    like($fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_do_\d+\)/,
        'sample before when-body repeat do materializes before the do state');
    like($fsm, qr/\(parent_do_\d+[\s\S]*\(= \(worker_start 1\)\)[\s\S]*<worker_done\s+\(-> parent_sample_\d+\)/,
        'when-body repeat do starts the child and waits for its fresh done before the following sample');
    like($fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after status\)\)[\s\S]*\(-> parent_repeat_check_\d+\)/,
        'sample after when-body repeat do materializes before the repeat check');
    like($fsm, qr/\(worker_idle_0[\s\S]*<worker_start[\s\S]*\(-> worker_done_1\)/,
        'local child entry is rewired to the when-body repeat start handoff');
    like($fsm, qr/\(worker_done_1[\s\S]*\(<1 \(worker_done 1\)\)/,
        'local child terminal pulses the when-body repeat done handoff');
};

subtest 'when body nested repeat generated-child do waits for generated instance done before re-entry' => sub {
    my $source = <<'ISF';
(actor when_repeat_do_generated_child
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input cond)
    (input loops (width 3))
    (input status)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (when cond
      (repeat loops
        (sample status as before)
        (do worker)
        (sample status as after)))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 2,
        'when-body repeat generated-child do plus spawn contribute generated instances');
    my %instances = map { $_->{instance} => $_ } @{$ir->{spawn_instances}};
    ok($instances{w0}, 'lexical spawn instance still exists');
    ok($instances{parent_worker_repeat_do_0}, 'when-body repeat generated-child do instance is recorded');
    is($instances{parent_worker_repeat_do_0}{activation_kind}, 'do',
        'when-body repeat generated-child do preserves do activation provenance');
    is($instances{parent_worker_repeat_do_0}{child}, 'worker',
        'when-body repeat generated-child do targets the generated child transaction');
    is_deeply($instances{parent_worker_repeat_do_0}{parameter_overrides}, [],
        'when-body repeat generated-child do does not require local parameter overrides');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'when_repeat_do_generated_child.fsm'};
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    my $top_fsm = $lowered->{files}{'when_repeat_do_generated_child_top.fsm'};

    ok(defined($parent_fsm), 'when-body repeat generated-child do parent scheduled .fsm is emitted');
    ok(defined($child_fsm), 'generated child scheduled .fsm is emitted once');
    ok(defined($top_fsm), 'when-body repeat generated-child do top .fsm is emitted');
    like($parent_fsm, qr/\(parent_when_\d+[\s\S]*\(=1 \(-> parent_repeat_init_\d+\)\)/,
        'when true path enters the generated-child nested repeat region');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_do_\d+\)/,
        'sample before when-body generated-child repeat do materializes before the do state');
    like($parent_fsm, qr/\(parent_do_\d+[\s\S]*\(= \(parent_worker_repeat_do_0_start> 1\)\)[\s\S]*<parent_worker_repeat_do_0_done\s+\(-> parent_sample_\d+\)/,
        'when-body generated-child repeat do waits for the generated instance before the following sample');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after status\)\)[\s\S]*\(-> parent_repeat_check_\d+\)/,
        'sample after when-body generated-child repeat do materializes before the repeat check');
    unlike($parent_fsm, qr/\bworker_start\b/,
        'when-body generated-child repeat do does not wire a local child start handoff');
    like($top_fsm, qr/\(\?fsmc:parent_worker_repeat_do_0 worker(?:\s|\))/,
        'generated top instantiates the when-body repeat generated-child do child once');
    like($top_fsm, qr/\(\?fsmc:w0 worker(?:\s|\))/,
        'generated top also instantiates the lexical spawn child');
};

subtest 'when body nested repeat generated do with params waits for generated instance done before re-entry' => sub {
    my $source = <<'ISF';
(actor when_repeat_do_params
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input cond)
    (input loops (width 3))
    (input status)
    (output done))
  (transaction parent
    (on start)
    (when cond
      (repeat loops
        (sample status as before)
        (do worker
          (params
            (WIDTH 16)))
        (sample status as after)))
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 1,
        'when-body repeat parameterized do contributes one generated instance');
    my $instance = $ir->{spawn_instances}[0];
    is($instance->{instance}, 'parent_worker_repeat_do_0',
        'when-body repeat parameterized do instance name is deterministic');
    is($instance->{activation_kind}, 'do',
        'when-body repeat parameterized do preserves do activation provenance');
    is($instance->{child}, 'worker',
        'when-body repeat parameterized do targets the generated child transaction');
    is_deeply($instance->{parameter_overrides}, [{ name => 'WIDTH', value => '16' }],
        'when-body repeat parameterized do preserves static parameter overrides');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'when_repeat_do_params.fsm'};
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    my $top_fsm = $lowered->{files}{'when_repeat_do_params_top.fsm'};

    ok(defined($parent_fsm), 'when-body repeat parameterized do parent scheduled .fsm is emitted');
    ok(defined($child_fsm), 'parameterized generated child scheduled .fsm is emitted once');
    ok(defined($top_fsm), 'when-body repeat parameterized do top .fsm is emitted');
    like($parent_fsm, qr/\(parent_when_\d+[\s\S]*\(=1 \(-> parent_repeat_init_\d+\)\)/,
        'when true path enters the parameterized nested repeat region');
    like($parent_fsm, qr/\(parent_do_\d+[\s\S]*\(= \(parent_worker_repeat_do_0_start> 1\)\)[\s\S]*<parent_worker_repeat_do_0_done\s+\(-> parent_sample_\d+\)/,
        'when-body parameterized repeat do waits for the generated instance before the following sample');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after status\)\)[\s\S]*\(-> parent_repeat_check_\d+\)/,
        'sample after when-body parameterized repeat do materializes before the repeat check');
    unlike($parent_fsm, qr/\bworker_start\b/,
        'when-body parameterized repeat do does not wire a local child start handoff');
    like($top_fsm, qr/\(\?fsmc:parent_worker_repeat_do_0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'generated top instantiates the when-body parameterized do child with static parameter override');
};

subtest 'when body nested repeat generated do with params and bindings lowers generated handoffs' => sub {
    my $source = <<'ISF';
(actor when_repeat_do_binding
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input cond)
    (input loops (width 3))
    (input req_addr (width 8))
    (input status)
    (output done)
    (output resp (width 8)))
  (transaction parent
    (on start)
    (when cond
      (repeat loops
        (sample status as before)
        (do worker
          (params
            (WIDTH 16))
          (bind
            (input addr req_addr)
            (output data resp)))
        (sample status as after)))
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
    is(scalar(@{$ir->{spawn_instances}}), 1,
        'when-body repeat parameterized bound do contributes one generated instance');
    my $instance = $ir->{spawn_instances}[0];
    is($instance->{instance}, 'parent_worker_repeat_do_0',
        'when-body repeat parameterized bound do instance name is deterministic');
    is_deeply($instance->{parameter_overrides}, [{ name => 'WIDTH', value => '16' }],
        'when-body repeat parameterized bound do preserves static parameter overrides');
    is_deeply(
        $instance->{port_bindings},
        [
            {
                role             => 'input',
                child_port       => 'addr',
                parent_port      => 'parent_worker_repeat_do_0_addr',
                actor_signal     => 'req_addr',
                actor_expr       => 'req_addr',
                actor_expression => 'req_addr',
                width            => 8,
            },
            {
                role             => 'output',
                child_port       => 'data',
                parent_port      => 'parent_worker_repeat_do_0_data',
                actor_signal     => 'resp',
                actor_expr       => 'resp',
                actor_expression => 'resp',
                width            => 8,
            },
        ],
        'when-body repeat parameterized bound do exposes reviewable port-binding handoffs',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'when_repeat_do_binding.fsm'};
    my $top_fsm = $lowered->{files}{'when_repeat_do_binding_top.fsm'};

    like($parent_fsm, qr/\(-parent_worker_repeat_do_0_port_bindings\s+\(= \(parent_worker_repeat_do_0_addr> req_addr\)\)\s+\(= \(resp> parent_worker_repeat_do_0_data\) <parent_worker_repeat_do_0_done\)\s+\)/s,
        'when-body repeat generated do parent .fsm keeps binding handoffs reviewable');
    like($parent_fsm, qr/\(parent_do_\d+[\s\S]*\(= \(parent_worker_repeat_do_0_start> 1\)\)[\s\S]*<parent_worker_repeat_do_0_done\s+\(-> parent_sample_\d+\)/,
        'when-body bound repeat do waits for the generated instance before the following sample');
    like($top_fsm, qr/\(when_repeat_do_binding\.parent_worker_repeat_do_0_addr parent_worker_repeat_do_0\.addr\)/,
        'generated top wires when-body repeat do input binding handoff');
    like($top_fsm, qr/\(parent_worker_repeat_do_0\.data when_repeat_do_binding\.parent_worker_repeat_do_0_data\)/,
        'generated top wires when-body repeat do output binding handoff');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} } @{$report->{transaction_port_bindings}} ],
        [
            'do:parent_worker_repeat_do_0:addr',
            'do:parent_worker_repeat_do_0:data',
        ],
        'report exposes when-body repeat generated do transaction port-binding provenance',
    );
};

subtest 'switch branch nested repeat local do waits for child done before re-entry' => sub {
    my $source = <<'ISF';
(actor switch_repeat_do_local
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input mode (width 2))
    (input loops (width 3))
    (input status)
    (output child_public_done)
    (output done))
  (transaction parent
    (on start)
    (switch mode
      (0
        (repeat loops
          (sample status as before)
          (do worker)
          (sample status as after)))
      (1
        (sample status as other)))
    (complete done))
  (transaction worker
    (on start)
    (complete child_public_done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 0,
        'switch-branch repeat local do does not create a generated child instance');
    is($ir->{counters}{worker_start}, 1,
        'switch-branch repeat local do registers the local child start handoff');
    is($ir->{counters}{worker_done}, 1,
        'switch-branch repeat local do registers the local child done handoff');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'switch_repeat_do_local.fsm'};

    ok(defined($fsm), 'switch-branch repeat local do parent scheduled .fsm is emitted');
    ok(!exists($lowered->{files}{'worker.fsm'}), 'switch-branch repeat local do keeps the child in the parent module');
    ok(!exists($lowered->{files}{'switch_repeat_do_local_top.fsm'}), 'switch-branch repeat local do does not emit a generated top');
    like($fsm, qr/\(\?mode[\s\S]*\(=0 \(-> parent_repeat_init_\d+\)\)/,
        'switch branch enters the nested repeat region');
    like($fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_do_\d+\)/,
        'sample before switch-branch repeat do materializes before the do state');
    like($fsm, qr/\(parent_do_\d+[\s\S]*\(= \(worker_start 1\)\)[\s\S]*<worker_done\s+\(-> parent_sample_\d+\)/,
        'switch-branch repeat do starts the child and waits for its fresh done before the following sample');
    like($fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after status\)\)[\s\S]*\(-> parent_repeat_check_\d+\)/,
        'sample after switch-branch repeat do materializes before the repeat check');
    like($fsm, qr/\(worker_idle_0[\s\S]*<worker_start[\s\S]*\(-> worker_done_1\)/,
        'local child entry is rewired to the switch-branch repeat start handoff');
    like($fsm, qr/\(worker_done_1[\s\S]*\(<1 \(worker_done 1\)\)/,
        'local child terminal pulses the switch-branch repeat done handoff');
};

subtest 'switch branch nested repeat generated-child do waits for generated instance done before re-entry' => sub {
    my $source = <<'ISF';
(actor switch_repeat_do_generated_child
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input mode (width 2))
    (input loops (width 3))
    (input status)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (switch mode
      (0
        (repeat loops
          (sample status as before)
          (do worker)
          (sample status as after)))
      (1
        (sample status as other)))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 2,
        'switch-branch repeat generated-child do plus spawn contribute generated instances');
    my %instances = map { $_->{instance} => $_ } @{$ir->{spawn_instances}};
    ok($instances{w0}, 'lexical spawn instance still exists');
    ok($instances{parent_worker_repeat_do_0}, 'switch-branch repeat generated-child do instance is recorded');
    is($instances{parent_worker_repeat_do_0}{activation_kind}, 'do',
        'switch-branch repeat generated-child do preserves do activation provenance');
    is($instances{parent_worker_repeat_do_0}{child}, 'worker',
        'switch-branch repeat generated-child do targets the generated child transaction');
    is_deeply($instances{parent_worker_repeat_do_0}{parameter_overrides}, [],
        'switch-branch repeat generated-child do does not require local parameter overrides');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'switch_repeat_do_generated_child.fsm'};
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    my $top_fsm = $lowered->{files}{'switch_repeat_do_generated_child_top.fsm'};

    ok(defined($parent_fsm), 'switch-branch repeat generated-child do parent scheduled .fsm is emitted');
    ok(defined($child_fsm), 'generated child scheduled .fsm is emitted once');
    ok(defined($top_fsm), 'switch-branch repeat generated-child do top .fsm is emitted');
    like($parent_fsm, qr/\(\?mode[\s\S]*\(=0 \(-> parent_repeat_init_\d+\)\)/,
        'switch branch enters the generated-child nested repeat region');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(before status\)\)[\s\S]*\(-> parent_do_\d+\)/,
        'sample before switch-branch generated-child repeat do materializes before the do state');
    like($parent_fsm, qr/\(parent_do_\d+[\s\S]*\(= \(parent_worker_repeat_do_0_start> 1\)\)[\s\S]*<parent_worker_repeat_do_0_done\s+\(-> parent_sample_\d+\)/,
        'switch-branch generated-child repeat do waits for the generated instance before the following sample');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after status\)\)[\s\S]*\(-> parent_repeat_check_\d+\)/,
        'sample after switch-branch generated-child repeat do materializes before the repeat check');
    unlike($parent_fsm, qr/\bworker_start\b/,
        'switch-branch generated-child repeat do does not wire a local child start handoff');
    like($top_fsm, qr/\(\?fsmc:parent_worker_repeat_do_0 worker(?:\s|\))/,
        'generated top instantiates the switch-branch repeat generated-child do child once');
    like($top_fsm, qr/\(\?fsmc:w0 worker(?:\s|\))/,
        'generated top also instantiates the lexical spawn child');
};

subtest 'switch branch nested repeat generated do with params waits for generated instance done before re-entry' => sub {
    my $source = <<'ISF';
(actor switch_repeat_do_params
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input mode (width 2))
    (input loops (width 3))
    (input status)
    (output done))
  (transaction parent
    (on start)
    (switch mode
      (0
        (repeat loops
          (sample status as before)
          (do worker
            (params
              (WIDTH 16)))
          (sample status as after)))
      (1
        (sample status as other)))
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is(scalar(@{$ir->{spawn_instances}}), 1,
        'switch-branch repeat parameterized do contributes one generated instance');
    my $instance = $ir->{spawn_instances}[0];
    is($instance->{instance}, 'parent_worker_repeat_do_0',
        'switch-branch repeat parameterized do instance name is deterministic');
    is($instance->{activation_kind}, 'do',
        'switch-branch repeat parameterized do preserves do activation provenance');
    is($instance->{child}, 'worker',
        'switch-branch repeat parameterized do targets the generated child transaction');
    is_deeply($instance->{parameter_overrides}, [{ name => 'WIDTH', value => '16' }],
        'switch-branch repeat parameterized do preserves static parameter overrides');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'switch_repeat_do_params.fsm'};
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    my $top_fsm = $lowered->{files}{'switch_repeat_do_params_top.fsm'};

    ok(defined($parent_fsm), 'switch-branch repeat parameterized do parent scheduled .fsm is emitted');
    ok(defined($child_fsm), 'parameterized generated child scheduled .fsm is emitted once');
    ok(defined($top_fsm), 'switch-branch repeat parameterized do top .fsm is emitted');
    like($parent_fsm, qr/\(\?mode[\s\S]*\(=0 \(-> parent_repeat_init_\d+\)\)/,
        'switch branch enters the parameterized nested repeat region');
    like($parent_fsm, qr/\(parent_do_\d+[\s\S]*\(= \(parent_worker_repeat_do_0_start> 1\)\)[\s\S]*<parent_worker_repeat_do_0_done\s+\(-> parent_sample_\d+\)/,
        'switch-branch parameterized repeat do waits for the generated instance before the following sample');
    like($parent_fsm, qr/\(parent_sample_\d+[\s\S]*\(<= \(after status\)\)[\s\S]*\(-> parent_repeat_check_\d+\)/,
        'sample after switch-branch parameterized repeat do materializes before the repeat check');
    unlike($parent_fsm, qr/\bworker_start\b/,
        'switch-branch parameterized repeat do does not wire a local child start handoff');
    like($top_fsm, qr/\(\?fsmc:parent_worker_repeat_do_0 worker\s+\(params\s+\(WIDTH 16\)\s+\)\s+\)/s,
        'generated top instantiates the switch-branch parameterized do child with static parameter override');
};

subtest 'switch branch nested repeat generated do with params and bindings lowers generated handoffs' => sub {
    my $source = <<'ISF';
(actor switch_repeat_do_binding
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input mode (width 2))
    (input loops (width 3))
    (input req_addr (width 8))
    (input status)
    (output done)
    (output resp (width 8)))
  (transaction parent
    (on start)
    (switch mode
      (0
        (repeat loops
          (sample status as before)
          (do worker
            (params
              (WIDTH 16))
            (bind
              (input addr req_addr)
              (output data resp)))
          (sample status as after)))
      (1
        (sample status as other)))
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
    is(scalar(@{$ir->{spawn_instances}}), 1,
        'switch-branch repeat parameterized bound do contributes one generated instance');
    my $instance = $ir->{spawn_instances}[0];
    is($instance->{instance}, 'parent_worker_repeat_do_0',
        'switch-branch repeat parameterized bound do instance name is deterministic');
    is_deeply($instance->{parameter_overrides}, [{ name => 'WIDTH', value => '16' }],
        'switch-branch repeat parameterized bound do preserves static parameter overrides');
    is_deeply(
        $instance->{port_bindings},
        [
            {
                role             => 'input',
                child_port       => 'addr',
                parent_port      => 'parent_worker_repeat_do_0_addr',
                actor_signal     => 'req_addr',
                actor_expr       => 'req_addr',
                actor_expression => 'req_addr',
                width            => 8,
            },
            {
                role             => 'output',
                child_port       => 'data',
                parent_port      => 'parent_worker_repeat_do_0_data',
                actor_signal     => 'resp',
                actor_expr       => 'resp',
                actor_expression => 'resp',
                width            => 8,
            },
        ],
        'switch-branch repeat parameterized bound do exposes reviewable port-binding handoffs',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'switch_repeat_do_binding.fsm'};
    my $top_fsm = $lowered->{files}{'switch_repeat_do_binding_top.fsm'};

    like($parent_fsm, qr/\(-parent_worker_repeat_do_0_port_bindings\s+\(= \(parent_worker_repeat_do_0_addr> req_addr\)\)\s+\(= \(resp> parent_worker_repeat_do_0_data\) <parent_worker_repeat_do_0_done\)\s+\)/s,
        'switch-branch repeat generated do parent .fsm keeps binding handoffs reviewable');
    like($parent_fsm, qr/\(parent_do_\d+[\s\S]*\(= \(parent_worker_repeat_do_0_start> 1\)\)[\s\S]*<parent_worker_repeat_do_0_done\s+\(-> parent_sample_\d+\)/,
        'switch-branch bound repeat do waits for the generated instance before the following sample');
    like($top_fsm, qr/\(switch_repeat_do_binding\.parent_worker_repeat_do_0_addr parent_worker_repeat_do_0\.addr\)/,
        'generated top wires switch-branch repeat do input binding handoff');
    like($top_fsm, qr/\(parent_worker_repeat_do_0\.data switch_repeat_do_binding\.parent_worker_repeat_do_0_data\)/,
        'generated top wires switch-branch repeat do output binding handoff');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        [ map { $_->{site_kind} . ':' . ($_->{instance} // '') . ':' . $_->{port} } @{$report->{transaction_port_bindings}} ],
        [
            'do:parent_worker_repeat_do_0:addr',
            'do:parent_worker_repeat_do_0:data',
        ],
        'report exposes switch-branch repeat generated do transaction port-binding provenance',
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

    assert_lower_rejected(<<'ISF', 'repeat await_any without spawn', qr/repeat-body await_any is supported only after repeat-body spawn clauses/);
(actor repeat_await_any_without_spawn
  (clock clk)
  (interface (input start) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (repeat loops
      (await_any done))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'repeat multi-pending await_any without drain', qr/repeat-body spawn requires same-body '\(await_all done\)' before the repeat check can loop/);
(actor repeat_await_any_multi_pending_without_drain
  (clock clk)
  (interface (input start) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0)
      (spawn worker as w1)
      (await_any done))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'repeat spawn after multi-pending await_any before drain', qr/repeat-body spawn cannot follow multi-pending await_any before same-body await_all drains outstanding children/);
(actor repeat_spawn_after_multi_pending_await_any
  (clock clk)
  (interface (input start) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0)
      (spawn worker as w1)
      (await_any done)
      (spawn worker as w2)
      (await_all done))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'repeat do after multi-pending await_any before drain', qr/repeat-body do cannot appear while repeat-body spawn clauses are pending/);
(actor repeat_do_after_multi_pending_await_any
  (clock clk)
  (interface (input start) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0)
      (spawn worker as w1)
      (await_any done)
      (do local_worker)
      (await_all done))
    (complete done))
  (transaction worker
    (complete done))
  (transaction local_worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'repeat do port binding without params', qr/repeat-body generated do bindings require static '\(params \.\.\.\)' overrides in the current generated blocking-do subset/);
(actor repeat_do_port_binding
  (clock clk)
  (interface (input start) (input loops (width 3)) (input payload (width 8)) (output result (width 8)) (output done))
  (transaction parent
    (on start)
    (repeat loops
      (do worker
        (bind
          (input data payload)
          (output resp result))))
    (complete done))
  (transaction worker
    (ports
      (input data (width 8))
      (output resp (width 8)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'repeat do domain metadata without params', qr/repeat-body generated do domain metadata requires static '\(params \.\.\.\)' overrides in the current generated blocking-do subset/);
(actor repeat_do_domain_metadata
  (clock-domains
    (domain default (clock clk)))
  (interface (input start) (input loops (width 3)) (output done))
  (transaction parent
    (domain default)
    (on start)
    (repeat loops
      (do worker
        (domain default)))
    (complete done))
  (transaction worker
    (domain default)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'when repeat bound do', qr/when-body nested repeat generated do bindings require static '\(params \.\.\.\)' overrides in the current nested generated blocking-do subset/);
(actor when_repeat_bound_do
  (clock clk)
  (interface (input start) (input cond) (input loops (width 3)) (input payload (width 8)) (output result (width 8)) (output done))
  (transaction parent
    (on start)
    (when cond
      (repeat loops
        (do worker
          (bind
            (input data payload)
            (output resp result)))))
    (complete done))
  (transaction worker
    (ports
      (input data (width 8))
      (output resp (width 8)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'when repeat domain do without params', qr/when-body nested repeat generated do domain metadata requires static '\(params \.\.\.\)' overrides in the current nested generated blocking-do subset/);
(actor when_repeat_domain_do_without_params
  (clock-domains
    (domain default (clock clk)))
  (interface (input start) (input cond) (input loops (width 3)) (output done))
  (transaction parent
    (domain default)
    (on start)
    (when cond
      (repeat loops
        (do worker
          (domain default))))
    (complete done))
  (transaction worker
    (domain default)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'double nested when repeat do', qr/repeat-body do is supported only for top-level repeat clauses, top-level when-body nested repeat clauses, or top-level switch-branch nested repeat clauses/);
(actor double_nested_when_repeat_do
  (clock clk)
  (interface (input start) (input cond) (input inner_cond) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (when cond
      (when inner_cond
        (repeat loops
          (do worker))))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'switch repeat bound do', qr/switch-branch nested repeat generated do bindings require static '\(params \.\.\.\)' overrides in the current nested generated blocking-do subset/);
(actor switch_repeat_bound_do
  (clock clk)
  (interface (input start) (input mode) (input loops (width 3)) (input payload (width 8)) (output result (width 8)) (output done))
  (transaction parent
    (on start)
    (switch mode
      (0
        (repeat loops
          (do worker
            (bind
              (input data payload)
              (output resp result))))))
    (complete done))
  (transaction worker
    (ports
      (input data (width 8))
      (output resp (width 8)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'switch repeat domain do without params', qr/switch-branch nested repeat generated do domain metadata requires static '\(params \.\.\.\)' overrides in the current nested generated blocking-do subset/);
(actor switch_repeat_domain_do_without_params
  (clock-domains
    (domain default (clock clk)))
  (interface (input start) (input mode) (input loops (width 3)) (output done))
  (transaction parent
    (domain default)
    (on start)
    (switch mode
      (0
        (repeat loops
          (do worker
            (domain default)))))
    (complete done))
  (transaction worker
    (domain default)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'double nested switch repeat do', qr/unsupported '\(switch \.\.\.\)' clause in switch branch/);
(actor double_nested_switch_repeat_do
  (clock clk)
  (interface (input start) (input mode) (input submode) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (switch mode
      (0
        (switch submode
          (0
            (repeat loops
              (do worker))))))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'switch nested when repeat do', qr/repeat-body do is supported only for top-level repeat clauses, top-level when-body nested repeat clauses, or top-level switch-branch nested repeat clauses/);
(actor switch_nested_when_repeat_do
  (clock clk)
  (interface (input start) (input mode) (input cond) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (switch mode
      (0
        (when cond
          (repeat loops
            (do worker)))))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'switch nested when repeat spawn', qr/repeat-body spawn is supported only for top-level repeat clauses, top-level when-body nested repeat clauses, or top-level switch-branch nested repeat clauses/);
(actor switch_nested_when_repeat_spawn
  (clock clk)
  (interface (input start) (input cond) (input mode) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (switch mode
      (0
        (when cond
          (repeat loops
            (spawn worker as w0)
            (await_all done)))))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'switch nested repeat multi-pending await_any without drain', qr/switch-branch nested repeat multi-pending await_any requires later same-body '\(await_all done\)' before the nested repeat check can loop/);
(actor switch_nested_repeat_multi_pending_await_any_without_drain
  (clock clk)
  (interface (input start) (input mode) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (switch mode
      (0
        (repeat loops
          (spawn worker as w0)
          (spawn worker as w1)
          (await_any done))))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'switch nested repeat spawn after multi-pending await_any before drain', qr/repeat-body spawn cannot follow multi-pending await_any before same-body await_all drains outstanding children/);
(actor switch_nested_repeat_spawn_after_multi_pending_await_any
  (clock clk)
  (interface (input start) (input mode) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (switch mode
      (0
        (repeat loops
          (spawn worker as w0)
          (spawn worker as w1)
          (await_any done)
          (spawn worker as w2)
          (await_all done))))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'switch nested repeat do after multi-pending await_any before drain', qr/repeat-body do cannot appear while repeat-body spawn clauses are pending/);
(actor switch_nested_repeat_do_after_multi_pending_await_any
  (clock clk)
  (interface (input start) (input mode) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (switch mode
      (0
        (repeat loops
          (spawn worker as w0)
          (spawn worker as w1)
          (await_any done)
          (do local_worker)
          (await_all done))))
    (complete done))
  (transaction worker
    (complete done))
  (transaction local_worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'when nested repeat multi-pending await_any without drain', qr/when-body nested repeat multi-pending await_any requires later same-body '\(await_all done\)' before the nested repeat check can loop/);
(actor when_nested_repeat_multi_pending_await_any_without_drain
  (clock clk)
  (interface (input start) (input cond) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (when cond
      (repeat loops
        (spawn worker as w0)
        (spawn worker as w1)
        (await_any done)))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'when nested repeat spawn after multi-pending await_any before drain', qr/repeat-body spawn cannot follow multi-pending await_any before same-body await_all drains outstanding children/);
(actor when_nested_repeat_spawn_after_multi_pending_await_any
  (clock clk)
  (interface (input start) (input cond) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (when cond
      (repeat loops
        (spawn worker as w0)
        (spawn worker as w1)
        (await_any done)
        (spawn worker as w2)
        (await_all done)))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'when nested repeat do after multi-pending await_any before drain', qr/repeat-body do cannot appear while repeat-body spawn clauses are pending/);
(actor when_nested_repeat_do_after_multi_pending_await_any
  (clock clk)
  (interface (input start) (input cond) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (when cond
      (repeat loops
        (spawn worker as w0)
        (spawn worker as w1)
        (await_any done)
        (do local_worker)
        (await_all done)))
    (complete done))
  (transaction worker
    (complete done))
  (transaction local_worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'repeat do while spawn pending', qr/repeat-body do cannot appear while repeat-body spawn clauses are pending/);
(actor repeat_do_while_spawn_pending
  (clock clk)
  (interface (input start) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (repeat loops
      (spawn worker as w0)
      (do local_worker)
      (await_all done))
    (complete done))
  (transaction worker
    (complete done))
  (transaction local_worker
    (on start)
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

    assert_lower_rejected(<<'ISF', 'repeat spawn with undeclared domain override', qr/spawn target 'worker' uses unknown clock domain 'fast'/);
(actor repeat_spawn_with_unknown_domain
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

    assert_lower_rejected(<<'ISF', 'repeat spawn with cross-domain activation override', qr/clock-domain violation: transaction 'parent' spawn target 'worker' references transaction in domain 'bus' from domain 'core'/);
(actor repeat_spawn_cross_domain
  (clock-domains
    (domain core (clock clk) :default)
    (domain bus (clock bus_clk)))
  (interface
    (input start (domain core))
    (input loops (width 3) (domain core))
    (output done (domain core))
    (output worker_done (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (repeat loops
      (spawn worker as w0
        (domain bus))
      (await_all done))
    (complete done))
  (transaction worker
    (domain bus)
    (complete worker_done)))
ISF

    assert_lower_rejected(<<'ISF', 'when nested repeat spawn without sync', qr/when-body nested repeat spawn requires same-body '\(await_all done\)' or single-pending '\(await_any done\)' before the nested repeat check can loop/);
(actor when_nested_repeat_spawn_without_await_all
  (clock clk)
  (interface (input start) (input cond) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (when cond
      (repeat loops
        (spawn worker as w0)))
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'switch nested repeat spawn without sync', qr/switch-branch nested repeat spawn requires same-body '\(await_all done\)' or single-pending '\(await_any done\)' before the nested repeat check can loop/);
(actor switch_nested_repeat_spawn_without_await_all
  (clock clk)
  (interface (input start) (input mode) (input loops (width 3)) (output done))
  (transaction parent
    (on start)
    (switch mode
      (0
        (repeat loops
          (spawn worker as w0))))
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
