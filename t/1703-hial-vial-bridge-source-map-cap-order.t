#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBridgeFanout;

my $class = 'FSM::VIAL::ArchitectureScaleBridgeFanout';

sub construct {
    my ($level) = @_;
    return $class->construct({
        primary_axis => 'source_map_records',
        level => $level,
        reference_hial_text => undef,
        reference_vial_text => undef,
    });
}

my $over_limit = construct('over_limit_v1');
my $route = FSM::VIAL::ArchitectureScaleBridgeFanout::_route($over_limit);
my $source_map_entry = \&FSM::HIAL::VIALBridge::Builder::_source_map_entry;
my $entry_calls = 0;
my $precedence;
{
    no warnings 'redefine';
    local *FSM::HIAL::VIALBridge::Builder::_source_map_entry = sub {
        $entry_calls++;
        die "source-map producer crossed its declared cap\n"
            if $entry_calls > 65_536;
        return $source_map_entry->(@_);
    };
    $precedence = $route->{method}->($route->{class}, $route->{arguments});
}
ok(!$precedence->{ok}, 'source-map count 65,537 fails closed');
is(scalar(@{$precedence->{diagnostics}}), 1,
    'source-map excess returns one deterministic diagnostic');
is($precedence->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
    'source-map excess uses the established bridge limit code');
is($precedence->{diagnostics}[0]{category}, 'limit',
    'source-map excess retains the limit category');
is($precedence->{diagnostics}[0]{message},
    'source_map count 65537 exceeds limit 65536',
    'source-map excess retains the established message');
is($precedence->{diagnostics}[0]{path}, '/source_map',
    'source-map excess retains the normalized collection path');
is($entry_calls, 65_536,
    'source-map admission interrupts before constructing record 65,537');
ok(!defined($precedence->{manifest}),
    'source-map excess exposes no partial manifest');
ok(!defined($precedence->{report}),
    'source-map excess exposes no partial report');

my $accepted = $class->evaluate({construction => construct('gate_candidate_v1')});
ok($accepted->{ok}, 'representative accepted source-map route remains valid');
is($accepted->{status}, 'accepted',
    'representative source-map route retains its accepted status');
is($accepted->{metrics}{source_map_records}, 8_192,
    'accepted route retains every requested source-map record');
is($accepted->{manifest_sha256},
    'e04c38362cfac7cec0e98cdc09e7d40776b89e046b7331ab05456665c398a6ba',
    'accepted route retains its manifest identity');
is($accepted->{report_sha256}, $accepted->{manifest_sha256},
    'accepted route retains byte-equal manifest and report identities');

done_testing;
