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
        primary_axis => 'events',
        level => $level,
        reference_hial_text => undef,
        reference_vial_text => undef,
    });
}

my $over_limit = construct('over_limit_v1');
my $route = FSM::VIAL::ArchitectureScaleBridgeFanout::_route($over_limit);
$route->{arguments}{actor}{verification_bridge}{transaction}{events}[-1]{kind} = 'hostile';
$route->{arguments}{schedule_report}{verification_bridge}{transaction}{events}[-1]{kind} = 'hostile';
my $precedence = $route->{method}->($route->{class}, $route->{arguments});
ok(!$precedence->{ok}, 'event count 2,049 fails closed');
is(scalar(@{$precedence->{diagnostics}}), 1,
    'event excess returns one deterministic diagnostic');
is($precedence->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
    'event excess uses the established bridge limit code');
is($precedence->{diagnostics}[0]{category}, 'limit',
    'event excess retains the limit category');
is($precedence->{diagnostics}[0]{message},
    'events count 2049 exceeds limit 2048',
    'event excess retains the established message');
is($precedence->{diagnostics}[0]{path}, '/events',
    'event excess retains the normalized collection path');
ok(!defined($precedence->{manifest}),
    'event excess exposes no partial manifest');
ok(!defined($precedence->{report}),
    'event excess exposes no partial report');

my $accepted = $class->evaluate({construction => construct('gate_candidate_v1')});
ok($accepted->{ok}, 'representative accepted event route remains valid');
is($accepted->{status}, 'accepted',
    'representative event route retains its accepted status');
is($accepted->{metrics}{events}, 256,
    'accepted route retains every requested event');
is($accepted->{manifest_sha256},
    '6c6fe08f412a9a4db7796cce442361939529c2c7ca81a9b77f4b5f06ac339b05',
    'accepted route retains its manifest identity');
is($accepted->{report_sha256}, $accepted->{manifest_sha256},
    'accepted route retains byte-equal manifest and report identities');

done_testing;
