#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Adapter::ISF;

subtest 'parse minimal APB requester .isf file' => sub {
    my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    ok(-f $isf_file, 'fixture file exists');

    my $adapter = FSM::Adapter::ISF->new();
    my $actor = $adapter->parse_file($isf_file);

    # Actor identity
    is($actor->{actor_name}, 'apb_requester', 'actor name');

    # Clock and reset
    is($actor->{clock}, 'clk', 'clock name');
    is_deeply($actor->{reset}, {
        name => 'rst_n', kind => 'async', polarity => 'active_low'
    }, 'reset declaration');

    # Watchdog
    is($actor->{watchdog}, 65536, 'watchdog count');

    # Interface
    my $iface = $actor->{interface};
    is(scalar(@{$iface->{inputs}}),  7, 'input count');
    is(scalar(@{$iface->{outputs}}), 8, 'output count');

    # Check specific ports
    my @input_names  = sort map { $_->{name} } @{$iface->{inputs}};
    my @output_names = sort map { $_->{name} } @{$iface->{outputs}};
    ok((grep { $_ eq 'start' }        @input_names),  'has start input');
    ok((grep { $_ eq 'req_addr' }     @input_names),  'has req_addr input');
    ok((grep { $_ eq 'PADDR' }        @output_names), 'has PADDR output');
    ok((grep { $_ eq 'done' }         @output_names), 'has done output');

    # Width check on 32-bit ports
    my ($req_addr_port) = grep { $_->{name} eq 'req_addr' } @{$iface->{inputs}};
    is($req_addr_port->{width}, 32, 'req_addr width is 32');

    # Handshake
    my $hs = $actor->{handshakes}{start_cmd};
    ok($hs, 'has start_cmd handshake');
    is($hs->{valid}, 'start', 'handshake valid port');
    is($hs->{ready}, 'done',  'handshake ready port');

    # Transaction
    is(scalar(@{$actor->{transactions}}), 1, 'one transaction');
    my $tx = $actor->{transactions}[0];
    is($tx->{name}, 'apb_transfer', 'transaction name');

    # Transaction clauses
    my @clauses = @{$tx->{clauses}};
    ok(@clauses >= 5, 'transaction has multiple clauses');

    # First clause should be (on start_cmd ...)
    my $on_clause = $clauses[0];
    is($on_clause->[0], 'on', 'first clause is (on ...)');
    is($on_clause->[1], 'start_cmd', 'on handshake name');

    # Latency clause should be last
    my $last_clause = $clauses[-1];
    is($last_clause->[0], 'latency', 'last clause is latency');
    is_deeply($last_clause->[1], ['min', '2'], 'latency min 2');
    is_deeply($last_clause->[2], ['max', '16'], 'latency max 16');
};

done_testing();
