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

subtest 'multi-domain actors build a domain-local lowering partition' => sub {
    my $source = <<'ISF';
(actor clock_domain_partition
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus  (clock bus_clk) (reset (bus_rst_n async active_low))))
  (interface
    (input start (domain core))
    (input bus_evt (domain bus))
    (output core_done (domain core))
    (output helper_done (domain core))
    (output bus_done (domain bus)))
  (storage
    (var core_reg (width 1) (domain core))
    (var bus_reg (width 1) (domain bus))
    (var bus_rule_reg (width 1) (domain bus)))
  (transaction core_tx
    (domain core)
    (on start)
    (spawn helper as h0
      (domain core))
    (update core_reg start)
    (complete core_done))
  (transaction helper
    (domain core)
    (complete helper_done))
  (transaction bus_tx
    (domain bus)
    (on bus_evt)
    (update bus_reg bus_evt)
    (complete bus_done))
  (rule bus_rule
    (domain bus)
    bus_evt
    (set bus_rule_reg 1)))
ISF

    my $actor = parse_source($source, 'clock-domain-partition');
    is($actor->{clock}, 'clk', 'default-domain clock is exposed through the compatibility clock field');
    is($actor->{reset}{name}, 'rst_n', 'default-domain reset is exposed through the compatibility reset field');
    is($actor->{clock_domains}{default}, 'core', 'parser records the default domain');
    is($actor->{interface}{inputs}[0]{domain}, 'core', 'parser records input-port domain ownership');
    is($actor->{storage}[1]{signals}[0]{domain}, 'bus', 'parser records scalarized storage signal domain ownership');
    is($actor->{transactions}[2]{domain}, 'bus', 'parser records transaction domain ownership');
    is($actor->{rules}[0]{domain}, 'bus', 'parser records rule domain ownership');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $partition = $ir->{domain_partition};
    is($partition->{kind}, 'multi_domain', 'lowering IR marks the actor as multi-domain');
    is($partition->{default_domain}, 'core', 'partition preserves the default domain');

    my %domain = map { $_->{name} => $_ } @{$partition->{domains}};
    is_deeply($domain{core}{ports}{inputs}, ['start'], 'core input ports are grouped locally');
    is_deeply($domain{bus}{ports}{inputs}, ['bus_evt'], 'bus input ports are grouped locally');
    is_deeply($domain{core}{ports}{outputs}, [qw(core_done helper_done)], 'core output ports are grouped locally');
    is_deeply($domain{bus}{ports}{outputs}, ['bus_done'], 'bus output ports are grouped locally');
    is_deeply($domain{core}{storage}, ['core_reg'], 'core storage is grouped locally');
    is_deeply($domain{bus}{storage}, [qw(bus_reg bus_rule_reg)], 'bus storage is grouped locally');
    is_deeply($domain{core}{transactions}, [qw(core_tx helper)], 'core transactions are grouped locally');
    is_deeply($domain{bus}{transactions}, ['bus_tx'], 'bus transactions are grouped locally');
    is_deeply($domain{bus}{rules}, ['bus_rule'], 'bus rules are grouped locally');
    is_deeply(
        $domain{core}{child_instances},
        [{ kind => 'spawn', owner => 'core_tx', child => 'helper', instance => 'h0' }],
        'spawned child instances are grouped by activation domain',
    );
    is($domain{bus}{scheduled_fsm}, 'clock_domain_partition__domain_bus.fsm', 'partition names the planned bus-domain artifact');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    is_deeply(
        sorted([keys %{$lowered->{files}}]),
        [qw(clock_domain_partition__domain_bus.fsm clock_domain_partition__domain_core.fsm clock_domain_partition_top.fsm)],
        'multi-domain lower emits one scheduled .fsm artifact per declared domain plus the generated top',
    );
    my $core_fsm = $lowered->{files}{'clock_domain_partition__domain_core.fsm'};
    like($core_fsm, qr/\A\(\?fsm:clock_domain_partition__domain_core\b/, 'core artifact uses the domain module name');
    like($core_fsm, qr/\(clock clk\)/, 'core artifact uses the core clock');
    like($core_fsm, qr/\(sreset rst_n\)/, 'core artifact uses the core reset');
    like($core_fsm, qr/\(start 1\)/, 'core artifact contains the core input');
    like($core_fsm, qr/\(core_reg 1\)/, 'core artifact contains core-owned storage');
    like($core_fsm, qr/\bh0_start\b/, 'core artifact contains same-domain generated activation helpers');
    unlike($core_fsm, qr/\bbus_clk\b|\bbus_evt\b|\bbus_done\b|\bbus_reg\b/, 'core artifact excludes bus-domain signals');

    my $bus_fsm = $lowered->{files}{'clock_domain_partition__domain_bus.fsm'};
    like($bus_fsm, qr/\A\(\?fsm:clock_domain_partition__domain_bus\b/, 'bus artifact uses the domain module name');
    like($bus_fsm, qr/\(clock bus_clk\)/, 'bus artifact uses the bus clock');
    like($bus_fsm, qr/\(areset bus_rst_n\)/, 'bus artifact uses the bus reset');
    like($bus_fsm, qr/\(bus_evt 1\)/, 'bus artifact contains the bus input');
    like($bus_fsm, qr/\(bus_reg 1\)/, 'bus artifact contains bus-owned storage');
    unlike($bus_fsm, qr/\bclk\b|\bstart\b|\bcore_done\b|\bcore_reg\b|\bh0_start\b/, 'bus artifact excludes core-domain signals and helpers');
    my $top_fsm = $lowered->{files}{'clock_domain_partition_top.fsm'};
    like($top_fsm, qr/\A\(\?top:clock_domain_partition_top\b/, 'multi-domain lower emits a generated top artifact');
    like($top_fsm, qr/\(\?fsmc:core clock_domain_partition__domain_core\)/, 'generated top instantiates the core domain module');
    like($top_fsm, qr/\(\?fsmc:bus clock_domain_partition__domain_bus\)/, 'generated top instantiates the bus domain module');
    unlike($top_fsm, qr{/clk/core\.clk/}, 'generated top leaves same-name core system ports to composition auto-wiring');
    unlike($top_fsm, qr{/bus_clk/bus\.bus_clk/}, 'generated top leaves same-name bus system ports to composition auto-wiring');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is($report->{scheduled_fsm}, 'clock_domain_partition_top.fsm', 'multi-domain report describes the generated top artifact');
    is($report->{state_count}, 0, 'multi-domain top report has no hidden scheduled states');
    is_deeply(
        [map { $_->{name} } @{$report->{clock_domains}}],
        [qw(core bus)],
        'multi-domain report exposes declared domains in source order',
    );
    my %reported_domain = map { $_->{name} => $_ } @{$report->{clock_domains}};
    is($reported_domain{core}{scheduled_fsm}, 'clock_domain_partition__domain_core.fsm', 'report names the core scheduled artifact');
    is($reported_domain{bus}{scheduled_fsm}, 'clock_domain_partition__domain_bus.fsm', 'report names the bus scheduled artifact');
    is_deeply($reported_domain{core}{ports}{inputs}, ['start'], 'report summarizes core input ports');
    is_deeply($reported_domain{bus}{transactions}, ['bus_tx'], 'report summarizes bus transactions');
    ok($reported_domain{core}{state_count} > 0, 'report includes core domain scheduled state count');
    ok($reported_domain{bus}{state_count} > 0, 'report includes bus domain scheduled state count');
};

subtest 'repeat body generated do domain metadata groups static do instance' => sub {
    my $source = <<'ISF';
(actor repeat_generated_do_domain_partition
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain aux  (clock aux_clk) (reset aux_rst_n)))
  (interface
    (input start (domain core))
    (input loops (width 3) (domain core))
    (output done (domain core))
    (output worker_done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (repeat loops
      (do worker
        (params
          (WIDTH 16))
        (domain core)))
    (complete done))
  (transaction worker
    (domain core)
    (params
      (WIDTH 8))
    (complete worker_done)))
ISF

    my $actor = parse_source($source, 'repeat-generated-do-domain-partition');
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $instance = $ir->{spawn_instances}[0];
    is($instance->{instance}, 'parent_worker_repeat_do_0', 'repeat-body generated do keeps deterministic domain instance name');
    is($instance->{domain}, 'core', 'repeat-body generated do preserves same-domain metadata on the generated child instance');

    my %domain = map { $_->{name} => $_ } @{$ir->{domain_partition}{domains}};
    is_deeply(
        $domain{core}{child_instances},
        [{ kind => 'do', owner => 'parent', child => 'worker', instance => 'parent_worker_repeat_do_0' }],
        'domain partition groups the repeat-body generated do instance with its declared owner domain',
    );
    is_deeply($domain{aux}{child_instances}, [], 'unrelated domains do not receive the repeat-body generated do instance');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    my %reported_domain = map { $_->{name} => $_ } @{$report->{clock_domains}};
    is_deeply(
        $reported_domain{core}{child_instances},
        [{ kind => 'do', owner => 'parent', child => 'worker', instance => 'parent_worker_repeat_do_0' }],
        'schedule report groups the repeat-body generated do instance with its declared owner domain',
    );

    assert_lower_rejected(<<'ISF', 'repeat generated do cross-domain metadata', qr/Transaction 'parent': repeat-body generated do target 'worker' is in a different clock domain than the calling transaction; cross-domain repeat-body do remains deferred/);
(actor repeat_generated_do_cross_domain
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus  (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input start (domain core))
    (input loops (width 3) (domain core))
    (output done (domain core))
    (output worker_done (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (repeat loops
      (do worker
        (params
          (WIDTH 16))
        (domain bus)))
    (complete done))
  (transaction worker
    (domain bus)
    (params
      (WIDTH 8))
    (complete worker_done)))
ISF
};

subtest 'when body nested repeat generated do domain metadata groups static do instance' => sub {
    my $source = <<'ISF';
(actor when_repeat_generated_do_domain_partition
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain aux  (clock aux_clk) (reset aux_rst_n)))
  (interface
    (input start (domain core))
    (input cond (domain core))
    (input loops (width 3) (domain core))
    (input req_addr (width 8) (domain core))
    (input status (domain core))
    (output done (domain core))
    (output worker_done (domain core))
    (output resp (width 8) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (when cond
      (repeat loops
        (sample status as before)
        (do worker
          (params
            (WIDTH 16))
          (bind
            (input addr req_addr)
            (output data resp))
          (domain core))
        (sample status as after)))
    (complete done))
  (transaction worker
    (domain core)
    (params
      (WIDTH 8))
    (ports
      (input addr (width 8))
      (output data (width 8)))
    (update data addr)
    (complete worker_done)))
ISF

    my $actor = parse_source($source, 'when-repeat-generated-do-domain-partition');
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $instance = $ir->{spawn_instances}[0];
    is($instance->{instance}, 'parent_worker_repeat_do_0',
        'when-body repeat generated do keeps deterministic domain instance name');
    is($instance->{domain}, 'core',
        'when-body repeat generated do preserves same-domain metadata on the generated child instance');

    my %domain = map { $_->{name} => $_ } @{$ir->{domain_partition}{domains}};
    is_deeply(
        $domain{core}{child_instances},
        [{ kind => 'do', owner => 'parent', child => 'worker', instance => 'parent_worker_repeat_do_0' }],
        'domain partition groups the when-body repeat generated do instance with its declared owner domain',
    );
    is_deeply($domain{aux}{child_instances}, [],
        'unrelated domains do not receive the when-body repeat generated do instance');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    my %reported_domain = map { $_->{name} => $_ } @{$report->{clock_domains}};
    is_deeply(
        $reported_domain{core}{child_instances},
        [{ kind => 'do', owner => 'parent', child => 'worker', instance => 'parent_worker_repeat_do_0' }],
        'schedule report groups the when-body repeat generated do instance with its declared owner domain',
    );

    assert_lower_rejected(<<'ISF', 'when repeat generated do cross-domain metadata', qr/Transaction 'parent': when-body nested repeat generated do target 'worker' is in a different clock domain than the calling transaction; cross-domain repeat-body do remains deferred/);
(actor when_repeat_generated_do_cross_domain
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus  (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input start (domain core))
    (input cond (domain core))
    (input loops (width 3) (domain core))
    (output done (domain core))
    (output worker_done (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (when cond
      (repeat loops
        (do worker
          (params
            (WIDTH 16))
          (domain bus))))
    (complete done))
  (transaction worker
    (domain bus)
    (params
      (WIDTH 8))
    (complete worker_done)))
ISF
};

subtest 'switch branch nested repeat generated do domain metadata groups static do instance' => sub {
    my $source = <<'ISF';
(actor switch_repeat_generated_do_domain_partition
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain aux  (clock aux_clk) (reset aux_rst_n)))
  (interface
    (input start (domain core))
    (input mode (width 2) (domain core))
    (input loops (width 3) (domain core))
    (input req_addr (width 8) (domain core))
    (input status (domain core))
    (output done (domain core))
    (output worker_done (domain core))
    (output resp (width 8) (domain core)))
  (transaction parent
    (domain core)
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
              (output data resp))
            (domain core))
          (sample status as after))))
    (complete done))
  (transaction worker
    (domain core)
    (params
      (WIDTH 8))
    (ports
      (input addr (width 8))
      (output data (width 8)))
    (update data addr)
    (complete worker_done)))
ISF

    my $actor = parse_source($source, 'switch-repeat-generated-do-domain-partition');
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $instance = $ir->{spawn_instances}[0];
    is($instance->{instance}, 'parent_worker_repeat_do_0',
        'switch-branch repeat generated do keeps deterministic domain instance name');
    is($instance->{domain}, 'core',
        'switch-branch repeat generated do preserves same-domain metadata on the generated child instance');

    my %domain = map { $_->{name} => $_ } @{$ir->{domain_partition}{domains}};
    is_deeply(
        $domain{core}{child_instances},
        [{ kind => 'do', owner => 'parent', child => 'worker', instance => 'parent_worker_repeat_do_0' }],
        'domain partition groups the switch-branch repeat generated do instance with its declared owner domain',
    );
    is_deeply($domain{aux}{child_instances}, [],
        'unrelated domains do not receive the switch-branch repeat generated do instance');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    my %reported_domain = map { $_->{name} => $_ } @{$report->{clock_domains}};
    is_deeply(
        $reported_domain{core}{child_instances},
        [{ kind => 'do', owner => 'parent', child => 'worker', instance => 'parent_worker_repeat_do_0' }],
        'schedule report groups the switch-branch repeat generated do instance with its declared owner domain',
    );

    assert_lower_rejected(<<'ISF', 'switch repeat generated do cross-domain metadata', qr/Transaction 'parent': switch-branch nested repeat generated do target 'worker' is in a different clock domain than the calling transaction; cross-domain repeat-body do remains deferred/);
(actor switch_repeat_generated_do_cross_domain
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus  (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input start (domain core))
    (input mode (width 2) (domain core))
    (input loops (width 3) (domain core))
    (output done (domain core))
    (output worker_done (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (switch mode
      (0
        (repeat loops
          (do worker
            (params
              (WIDTH 16))
            (domain bus)))))
    (complete done))
  (transaction worker
    (domain bus)
    (params
      (WIDTH 8))
    (complete worker_done)))
ISF
};

subtest 'single-domain clock-domains sources lower through the existing one-clock path' => sub {
    my $source = <<'ISF';
(actor single_domain_clock_domains
  (clock-domains
    (domain core (clock clk) (reset rst_n)))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF

    my $actor = parse_source($source, 'single-domain-clock-domains');
    is($actor->{clock_domains}{default}, 'core', 'single-domain clock-domains block gets an implicit default');
    is($actor->{interface}{inputs}[0]{domain}, 'core', 'single-domain clock-domains materializes inherited input domain');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'single_domain_clock_domains.fsm'};
    ok(defined($fsm), 'single-domain clock-domains actor still emits the normal scheduled .fsm');
    like($fsm, qr/\(clock clk\)/, 'scheduled .fsm uses the domain clock');
    like($fsm, qr/\(sreset rst_n\)/, 'scheduled .fsm uses the domain reset');
};

subtest 'multi-domain CLI HDL generation emits the generated top and CDC child' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($dir, 'generated');
    mkdir $outdir or die "Cannot create $outdir: $!";
    my $out_path = File::Spec->catfile($outdir, 'clock_domain_event_crossing.sv');

    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--outdir', $outdir,
            '--output', $out_path,
            repo_file('isf/clock_domain_event_crossing.isf'),
        ],
    );
    ok($success, 'multi-domain CLI HDL generation succeeds for the event-crossing fixture');
    is(join('', @{$stderr_buf || []}), '', 'multi-domain CLI HDL generation keeps stderr empty');
    ok(-f $out_path, 'multi-domain CLI HDL generation writes the requested HDL output');
    ok(-f File::Spec->catfile($outdir, 'clock_domain_event_crossing_top.fsm'), 'multi-domain CLI writes the generated top artifact');
    ok(-f File::Spec->catfile($outdir, 'clock_domain_event_crossing__domain_bus.fsm'), 'multi-domain CLI writes the bus domain artifact');
    ok(-f File::Spec->catfile($outdir, 'clock_domain_event_crossing__domain_core.fsm'), 'multi-domain CLI writes the core domain artifact');

    my $hdl = read_file($out_path);
    like($hdl, qr/module\s+clock_domain_event_crossing_top\b/, 'HDL contains the generated multi-domain top module');
    like($hdl, qr/module\s+clock_domain_event_crossing__cdc_event_byte_ready\b/, 'HDL contains the concrete generated CDC child module');
    like($hdl, qr/clock_domain_event_crossing__cdc_event_byte_ready\s+byte_ready_cdc\s*\(/, 'top instantiates the generated CDC child');
    like($hdl, qr/assign\s+ready\s*=\s*\(source_ack_sync_2\s*==\s*source_toggle\)/, 'CDC child implements acknowledged single-outstanding ready');
    like($hdl, qr/pulse\s*<=\s*1'b1;/, 'CDC child emits a destination-domain pulse on accepted toggle changes');
};

subtest 'acknowledged event crossings add domain endpoints and explicit top artifact wiring' => sub {
    my $source = <<'ISF';
(actor event_crossing_top
  (clock-domains
    (domain bus  (clock bus_clk) (reset bus_rst_n) :default)
    (domain core (clock clk)     (reset rst_n)))
  (crossings
    (event rx_done
      (from bus rx_req)
      (to core rx_pulse)
      (ready rx_ready)))
  (interface
    (input bus_start (domain bus))
    (output core_done (domain core)))
  (transaction bus_tx
    (domain bus)
    (on bus_start)
    (await rx_ready)
    (complete rx_req))
  (transaction core_tx
    (domain core)
    (on rx_pulse)
    (complete core_done)))
ISF

    my $actor = parse_source($source, 'event-crossing-top');
    is($actor->{crossings}[0]{ready}{domain}, 'bus', 'parser assigns crossing ready to the source domain');

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    is_deeply(
        sorted([keys %{$lowered->{files}}]),
        [qw(event_crossing_top__domain_bus.fsm event_crossing_top__domain_core.fsm event_crossing_top_top.fsm)],
        'event crossing lower emits domain artifacts and one generated top artifact',
    );

    my $bus_fsm = $lowered->{files}{'event_crossing_top__domain_bus.fsm'};
    like($bus_fsm, qr/\(rx_ready 1\)/, 'source domain artifact has the crossing ready input');
    like($bus_fsm, qr/\(rx_req 1\)/, 'source domain artifact has the crossing request output');
    unlike($bus_fsm, qr/\brx_pulse\b/, 'source domain artifact excludes the destination pulse');

    my $core_fsm = $lowered->{files}{'event_crossing_top__domain_core.fsm'};
    like($core_fsm, qr/\(rx_pulse 1\)/, 'destination domain artifact has the crossing pulse input');
    unlike($core_fsm, qr/\brx_req\b|\brx_ready\b/, 'destination domain artifact excludes source crossing endpoints');

    my $top_fsm = $lowered->{files}{'event_crossing_top_top.fsm'};
    like($top_fsm, qr/\(\?rtl:rx_done_cdc event_crossing_top__cdc_event_rx_done\)/, 'top names an explicit CDC RTL child');
    like($top_fsm, qr{/bus\.rx_req/rx_done_cdc\.request/}, 'top wires the source request into the CDC child');
    like($top_fsm, qr{/rx_done_cdc\.ready/bus\.rx_ready/}, 'top wires source ready back to the source domain');
    like($top_fsm, qr{/rx_done_cdc\.pulse/core\.rx_pulse/}, 'top wires destination pulse into the destination domain');
    like($top_fsm, qr/\(\?rtlif:event_crossing_top__cdc_event_rx_done[\s\S]*request<:data[\s\S]*ready>:data[\s\S]*pulse>:data/, 'top embeds the CDC child interface artifact');
    like($top_fsm, qr/\(FSMGEN_ISF_CDC_EVENT 0d1\)/, 'CDC interface metadata marks the generated ISF event primitive');
    like($top_fsm, qr/\(SOURCE_RESET_ACTIVE_HIGH 0d0\)/, 'CDC interface metadata carries source reset polarity');
    like($top_fsm, qr/\(DEST_RESET_ACTIVE_HIGH 0d0\)/, 'CDC interface metadata carries destination reset polarity');

    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        $report->{crossings},
        [
            {
                name               => 'rx_done',
                kind               => 'event',
                source_domain      => 'bus',
                source_signal      => 'rx_req',
                destination_domain => 'core',
                destination_signal => 'rx_pulse',
                ready_signal       => 'rx_ready',
                instance           => 'rx_done_cdc',
                module             => 'event_crossing_top__cdc_event_rx_done',
                outstanding_policy => 'single_outstanding_acknowledged',
                payload            => 'none',
                top_fsm            => 'event_crossing_top_top.fsm',
            },
        ],
        'schedule report exposes bounded crossing metadata',
    );
    my %reported_domain = map { $_->{name} => $_ } @{$report->{clock_domains}};
    is_deeply(
        $reported_domain{bus}{crossings},
        [{ event => 'rx_done', role => 'source', signal => 'rx_req', ready => 'rx_ready' }],
        'schedule report exposes the source-domain crossing endpoint',
    );
    is_deeply(
        $reported_domain{core}{crossings},
        [{ event => 'rx_done', role => 'destination', signal => 'rx_pulse', ready => undef }],
        'schedule report exposes the destination-domain crossing endpoint',
    );
};

subtest 'clock-domain crossing fixture reports metadata and lowers supported domain HDL' => sub {
    my $path = repo_file('isf/clock_domain_event_crossing.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    my $scheduler = FSM::Scheduler::ISF->new();

    my $report = decode_json($scheduler->report($actor));
    is($report->{source}, 'clock_domain_event_crossing.isf', 'fixture report preserves the source basename');
    is($report->{scheduled_fsm}, 'clock_domain_event_crossing_top.fsm', 'fixture report names the generated top');
    is_deeply(
        [map { $_->{name} } @{$report->{clock_domains}}],
        [qw(bus core)],
        'fixture report exposes bus and core domains',
    );
    is_deeply(
        [map { $_->{name} } @{$report->{crossings}}],
        ['byte_ready'],
        'fixture report exposes the event crossing',
    );

    my $cli_report = run_schedule_json($path);
    is_deeply($cli_report->{clock_domains}, $report->{clock_domains}, 'CLI schedule JSON preserves domain metadata');
    is_deeply($cli_report->{crossings}, $report->{crossings}, 'CLI schedule JSON preserves crossing metadata');

    my $lowered = $scheduler->lower($actor);
    my $dir = tempdir(CLEANUP => 1);
    for my $basename (qw(clock_domain_event_crossing__domain_bus.fsm clock_domain_event_crossing__domain_core.fsm)) {
        my $fsm_path = File::Spec->catfile($dir, $basename);
        write_file($fsm_path, $lowered->{files}{$basename});
        assert_direct_fsm_hdl_generation($fsm_path, "$basename reaches supported single-domain HDL generation");
    }
};

subtest 'dual event-crossing fixture emits two CDC children and reports both directions' => sub {
    my $path = repo_file('isf/clock_domain_dual_event_crossing.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    my $scheduler = FSM::Scheduler::ISF->new();

    my $lowered = $scheduler->lower($actor);
    is_deeply(
        sorted([keys %{$lowered->{files}}]),
        [qw(
          clock_domain_dual_event_crossing__domain_bus.fsm
          clock_domain_dual_event_crossing__domain_core.fsm
          clock_domain_dual_event_crossing_top.fsm
        )],
        'dual event fixture emits one artifact per domain plus the generated top',
    );

    my $top_fsm = $lowered->{files}{'clock_domain_dual_event_crossing_top.fsm'};
    like(
        $top_fsm,
        qr/\(\?rtl:req_seen_cdc clock_domain_dual_event_crossing__cdc_event_req_seen\)/,
        'generated top instantiates req_seen CDC child',
    );
    like(
        $top_fsm,
        qr/\(\?rtl:core_ack_cdc clock_domain_dual_event_crossing__cdc_event_core_ack\)/,
        'generated top instantiates core_ack CDC child',
    );
    like($top_fsm, qr{/bus\.req_seen_req/req_seen_cdc\.request/}, 'top wires bus-to-core request into req_seen CDC child');
    like($top_fsm, qr{/req_seen_cdc\.pulse/core\.req_seen_pulse/}, 'top wires req_seen destination pulse into the core domain');
    like($top_fsm, qr{/core\.core_ack_req/core_ack_cdc\.request/}, 'top wires core-to-bus request into core_ack CDC child');
    like($top_fsm, qr{/core_ack_cdc\.pulse/bus\.core_ack_pulse/}, 'top wires core_ack destination pulse into the bus domain');

    my $req_seen_metadata_re = qr{
        \(\?rtlif:clock_domain_dual_event_crossing__cdc_event_req_seen
        [\s\S]*?\(SOURCE_RESET_ASYNC\s+0d1\)
        [\s\S]*?\(SOURCE_RESET_ACTIVE_HIGH\s+0d0\)
        [\s\S]*?\(DEST_RESET_ASYNC\s+0d0\)
        [\s\S]*?\(DEST_RESET_ACTIVE_HIGH\s+0d1\)
    }x;
    my $core_ack_metadata_re = qr{
        \(\?rtlif:clock_domain_dual_event_crossing__cdc_event_core_ack
        [\s\S]*?\(SOURCE_RESET_ASYNC\s+0d0\)
        [\s\S]*?\(SOURCE_RESET_ACTIVE_HIGH\s+0d1\)
        [\s\S]*?\(DEST_RESET_ASYNC\s+0d1\)
        [\s\S]*?\(DEST_RESET_ACTIVE_HIGH\s+0d0\)
    }x;
    like(
        $top_fsm,
        $req_seen_metadata_re,
        'req_seen CDC metadata records async active-low bus source reset and sync active-high core destination reset',
    );
    like(
        $top_fsm,
        $core_ack_metadata_re,
        'core_ack CDC metadata records sync active-high core source reset and async active-low bus destination reset',
    );

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        [map { $_->{name} } @{$report->{crossings}}],
        [qw(req_seen core_ack)],
        'schedule report preserves both crossing declarations in source order',
    );
    my %reported_domain = map { $_->{name} => $_ } @{$report->{clock_domains}};
    is_deeply(
        $reported_domain{bus}{crossings},
        [
            { event => 'req_seen', role => 'source',      signal => 'req_seen_req',   ready => 'req_seen_ready' },
            { event => 'core_ack', role => 'destination', signal => 'core_ack_pulse', ready => undef },
        ],
        'bus-domain report includes source and destination crossing endpoints',
    );
    is_deeply(
        $reported_domain{core}{crossings},
        [
            { event => 'req_seen', role => 'destination', signal => 'req_seen_pulse', ready => undef },
            { event => 'core_ack', role => 'source',      signal => 'core_ack_req',   ready => 'core_ack_ready' },
        ],
        'core-domain report includes destination and source crossing endpoints',
    );

    my $cli_report = run_schedule_json($path);
    is_deeply(
        $cli_report->{clock_domains},
        $report->{clock_domains},
        'CLI schedule JSON preserves dual-crossing domain metadata',
    );
    is_deeply(
        $cli_report->{crossings},
        $report->{crossings},
        'CLI schedule JSON preserves both crossing summaries',
    );

    my $dir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($dir, 'generated');
    mkdir $outdir or die "Cannot create $outdir: $!";
    my $out_path = File::Spec->catfile($outdir, 'clock_domain_dual_event_crossing.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--outdir', $outdir,
            '--output', $out_path,
            $path,
        ],
    );

    ok($success, 'dual event fixture reaches generated HDL');
    is(join('', @{$stderr_buf || []}), '', 'dual event fixture HDL generation keeps stderr empty');
    ok(-f $out_path, 'dual event fixture writes requested HDL output');

    my $hdl = read_file($out_path);
    like($hdl, qr/module\s+clock_domain_dual_event_crossing_top\b/, 'HDL contains the dual-event generated top');
    like(
        $hdl,
        qr/module\s+clock_domain_dual_event_crossing__cdc_event_req_seen\b/,
        'HDL contains the req_seen CDC module',
    );
    like(
        $hdl,
        qr/module\s+clock_domain_dual_event_crossing__cdc_event_core_ack\b/,
        'HDL contains the core_ack CDC module',
    );
    like(
        $hdl,
        qr/clock_domain_dual_event_crossing__cdc_event_req_seen\s+req_seen_cdc\s*\(/,
        'top instantiates req_seen CDC module',
    );
    like(
        $hdl,
        qr/clock_domain_dual_event_crossing__cdc_event_core_ack\s+core_ack_cdc\s*\(/,
        'top instantiates core_ack CDC module',
    );
};

subtest 'no-reset event-crossing fixture emits reset-absent CDC metadata' => sub {
    my $path = repo_file('isf/clock_domain_no_reset_event_crossing.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    my $scheduler = FSM::Scheduler::ISF->new();

    my $lowered = $scheduler->lower($actor);
    is_deeply(
        sorted([keys %{$lowered->{files}}]),
        [qw(
          clock_domain_no_reset_event_crossing__domain_bus.fsm
          clock_domain_no_reset_event_crossing__domain_core.fsm
          clock_domain_no_reset_event_crossing_top.fsm
        )],
        'no-reset event fixture emits one artifact per domain plus the generated top',
    );

    my $top_fsm = $lowered->{files}{'clock_domain_no_reset_event_crossing_top.fsm'};
    like(
        $top_fsm,
        qr/\(\?rtl:req_seen_cdc clock_domain_no_reset_event_crossing__cdc_event_req_seen\)/,
        'generated top instantiates the no-reset CDC child',
    );
    like($top_fsm, qr{/bus_clk/req_seen_cdc\.source_clk/}, 'top wires the source clock into the CDC child');
    like($top_fsm, qr{/core_clk/req_seen_cdc\.dest_clk/}, 'top wires the destination clock into the CDC child');
    unlike($top_fsm, qr{/[^/\s]*rst[^/\s]*/req_seen_cdc\.(?:source_reset|dest_reset)/},
        'top does not wire absent domain resets into the CDC child');
    like(
        $top_fsm,
        qr{
            \(\?rtlif:clock_domain_no_reset_event_crossing__cdc_event_req_seen
            [\s\S]*?\(SOURCE_RESET_PRESENT\s+0d0\)
            [\s\S]*?\(DEST_RESET_PRESENT\s+0d0\)
        }x,
        'CDC metadata records absent source and destination resets',
    );

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        [map { $_->{name} } @{$report->{crossings}}],
        ['req_seen'],
        'schedule report preserves the no-reset crossing declaration',
    );
    my %reported_domain = map { $_->{name} => $_ } @{$report->{clock_domains}};
    is_deeply(
        $reported_domain{bus}{crossings},
        [{ event => 'req_seen', role => 'source', signal => 'req_seen_req', ready => 'req_seen_ready' }],
        'bus-domain report includes the source crossing endpoint',
    );
    is_deeply(
        $reported_domain{core}{crossings},
        [{ event => 'req_seen', role => 'destination', signal => 'req_seen_pulse', ready => undef }],
        'core-domain report includes the destination crossing endpoint',
    );

    my $cli_report = run_schedule_json($path);
    is_deeply($cli_report->{clock_domains}, $report->{clock_domains},
        'CLI schedule JSON preserves no-reset domain metadata');
    is_deeply($cli_report->{crossings}, $report->{crossings},
        'CLI schedule JSON preserves the no-reset crossing summary');

    my $dir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($dir, 'generated');
    mkdir $outdir or die "Cannot create $outdir: $!";
    my $out_path = File::Spec->catfile($outdir, 'clock_domain_no_reset_event_crossing.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--outdir', $outdir,
            '--output', $out_path,
            $path,
        ],
    );

    ok($success, 'no-reset event fixture HDL generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'no-reset event fixture HDL generation keeps stderr empty');
    ok(-f $out_path, 'no-reset event fixture writes HDL output');
    my $hdl = read_file($out_path);
    like($hdl, qr/module\s+clock_domain_no_reset_event_crossing_top\b/,
        'no-reset HDL contains the generated multi-domain top');
    like($hdl, qr/module\s+clock_domain_no_reset_event_crossing__cdc_event_req_seen\b/,
        'no-reset HDL contains the concrete generated CDC child');
    unlike($hdl, qr/\binput\s+wire\s+(?:source_reset|dest_reset)\b/,
        'no-reset CDC child does not expose absent reset ports');
    like($hdl, qr/always_ff\s*@\(posedge\s+bus_clk\)\s+begin\s+(?!if\s*\()/s,
        'no-reset bus domain emits clock-only sequential logic');
    like($hdl, qr/always_ff\s*@\(posedge\s+core_clk\)\s+begin\s+(?!if\s*\()/s,
        'no-reset core domain emits clock-only sequential logic');
};

subtest 'direct unowned cross-domain references fail closed before emission' => sub {
    assert_lower_rejected(<<'ISF', 'transaction cross-domain activation read', qr/clock-domain violation: transaction 'bus_tx' on clause read signal 'start' owned by domain 'core' from domain 'bus'/);
(actor bad_cross_read
  (clock-domains
    (domain core (clock clk) :default)
    (domain bus (clock bus_clk)))
  (interface
    (input start (domain core))
    (output bus_done (domain bus)))
  (transaction bus_tx
    (domain bus)
    (on start)
    (complete bus_done)))
ISF

    assert_lower_rejected(<<'ISF', 'rule cross-domain trigger', qr/clock-domain violation: rule 'fire' trigger target 'work' references transaction in domain 'bus' from domain 'core'/);
(actor bad_cross_trigger
  (clock-domains
    (domain core (clock clk) :default)
    (domain bus (clock bus_clk)))
  (interface
    (input start (domain core))
    (output done (domain bus)))
  (transaction work
    (domain bus)
    (complete done))
  (rule fire
    (domain core)
    start
    (trigger work)))
ISF
};

subtest 'malformed domain source metadata is rejected by the parser' => sub {
    assert_parse_rejected(<<'ISF', 'unknown port domain', qr/interface port 'start' uses unknown clock domain 'missing'/);
(actor unknown_port_domain
  (clock-domains
    (domain core (clock clk) :default))
  (interface
    (input start (domain missing))))
ISF

    assert_parse_rejected(<<'ISF', 'clock and clock-domains mix', qr/cannot mix '\(clock \.\.\.\)' with '\(clock-domains \.\.\.\)'/);
(actor mixed_clock_forms
  (clock clk)
  (clock-domains
    (domain core (clock core_clk) :default))
  (interface
    (input start)))
ISF

    assert_parse_rejected(<<'ISF', 'duplicate domain clock signal', qr/clock signal 'clk' is used by multiple clock domains/);
(actor duplicate_clock_signal
  (clock-domains
    (domain core (clock clk) :default)
    (domain bus (clock clk)))
  (interface
    (input start)))
ISF

    assert_parse_rejected(<<'ISF', 'missing multi-domain default', qr/multi-domain clock-domains require exactly one ':default' domain/);
(actor missing_domain_default
  (clock-domains
    (domain core (clock clk))
    (domain bus (clock bus_clk)))
  (interface
    (input start)))
ISF
};

done_testing();

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
}

sub assert_parse_rejected {
    my ($source, $label, $diagnostic_re) = @_;
    my $ok = eval {
        parse_source($source, $label);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;
    my $ok = eval {
        my $actor = parse_source($source, $label);
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

sub assert_report_rejected {
    my ($source, $label, $diagnostic_re) = @_;
    my $ok = eval {
        my $actor = parse_source($source, $label);
        FSM::Scheduler::ISF->new()->report($actor);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

sub assert_direct_fsm_hdl_generation {
    my ($fsm_path, $label) = @_;
    my ($volume, $directories, $file) = File::Spec->splitpath($fsm_path);
    my $stem = $file;
    $stem =~ s/\.fsm\z//;
    my $out_path = File::Spec->catfile($directories, "$stem.sv");

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--output', $out_path, $fsm_path],
    );

    ok($success, $label);
    is(join('', @{$stderr_buf || []}), '', "$label keeps stderr empty");
    ok(-f $out_path, "$label writes SystemVerilog output");
}

sub run_schedule_json {
    my ($path) = @_;
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, '--emit-schedule-json succeeds for the clock-domain fixture');
    is(join('', @{$stderr_buf || []}), '', '--emit-schedule-json keeps stderr empty for the clock-domain fixture');
    return decode_json(join('', @{$stdout_buf || []}));
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relpath);
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!\n";
    print {$fh} $content;
    close $fh or die "Cannot close $path: $!\n";
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    local $/;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!\n";
    return $content;
}
