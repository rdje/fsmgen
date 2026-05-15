#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

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
    like($top_fsm, qr{/clk/core\.clk/}, 'generated top wires the core clock');
    like($top_fsm, qr{/bus_clk/bus\.bus_clk/}, 'generated top wires the bus clock');

    assert_report_rejected(
        $source,
        'multi-domain report blocks until report projection ships',
        qr/FSM::Scheduler::ISF->report validated the multi-domain partition .* schedule-report projection is not implemented yet/,
    );
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

subtest 'multi-domain CLI HDL generation waits for generated top emission' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'multi_domain_cli_boundary.isf');
    write_file($path, <<'ISF');
(actor multi_domain_cli_boundary
  (clock-domains
    (domain core (clock clk) :default)
    (domain bus (clock bus_clk)))
  (interface
    (input start (domain core))
    (input bus_evt (domain bus))
    (output done (domain core))
    (output bus_done (domain bus)))
  (transaction core_tx
    (domain core)
    (on start)
    (complete done))
  (transaction bus_tx
    (domain bus)
    (on bus_evt)
    (complete bus_done)))
ISF

    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $path],
    );
    ok(!$success, 'multi-domain CLI HDL generation fails until HDL support for generated top artifacts ships');
    is(join('', @{$stdout_buf || []}), '', 'multi-domain CLI boundary keeps stdout empty');
    like(
        join('', @{$stderr_buf || []}),
        qr/generated HDL for multi-domain top\/CDC artifacts is not implemented yet/,
        'multi-domain CLI diagnostic points at the unshipped generated HDL path',
    );
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
