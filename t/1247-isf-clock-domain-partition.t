#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

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

    assert_lower_rejected(
        $source,
        'multi-domain lower blocks before existing emitters',
        qr/FSM::Scheduler::ISF->lower validated the multi-domain partition .* not implemented yet/,
    );
    assert_report_rejected(
        $source,
        'multi-domain report blocks until report projection ships',
        qr/FSM::Scheduler::ISF->report validated the multi-domain partition .* not implemented yet/,
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
