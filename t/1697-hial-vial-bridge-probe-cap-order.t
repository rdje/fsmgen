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
        primary_axis => 'probes',
        level => $level,
        reference_hial_text => undef,
        reference_vial_text => undef,
    });
}

my $over_limit = construct('over_limit_v1');
my $route = FSM::VIAL::ArchitectureScaleBridgeFanout::_route($over_limit);
$route->{arguments}{actor}{verification_bridge}{probes}[-1]{access} = 'write_only';
$route->{arguments}{schedule_report}{verification_bridge}{probes}[-1]{access} = 'write_only';
my $precedence = $route->{method}->($route->{class}, $route->{arguments});
ok(!$precedence->{ok}, 'probe count 257 fails closed');
is(scalar(@{$precedence->{diagnostics}}), 1,
    'probe excess returns one deterministic diagnostic');
is($precedence->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
    'probe excess uses the established bridge limit code');
is($precedence->{diagnostics}[0]{category}, 'limit',
    'probe excess retains the limit category');
is($precedence->{diagnostics}[0]{message},
    'probes count 257 exceeds limit 256',
    'probe excess retains the established message');
is($precedence->{diagnostics}[0]{path}, '/probes',
    'probe excess retains the normalized collection path');
ok(!defined($precedence->{manifest}),
    'probe excess exposes no partial manifest');
ok(!defined($precedence->{report}),
    'probe excess exposes no partial report');

my $accepted = $class->evaluate({construction => construct('gate_candidate_v1')});
ok($accepted->{ok}, 'representative accepted probe route remains valid');
is($accepted->{status}, 'accepted',
    'representative probe route retains its accepted status');
is($accepted->{metrics}{probes}, 32,
    'accepted route retains every requested probe');
is($accepted->{manifest_sha256},
    'a173eb78ade1202257bb7de4a8ff70cada8801a5ab7f86ac90f34b229f1456d3',
    'accepted route retains its manifest identity');
is($accepted->{report_sha256}, $accepted->{manifest_sha256},
    'accepted route retains byte-equal manifest and report identities');

done_testing;
