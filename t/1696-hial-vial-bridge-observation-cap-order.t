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
        primary_axis => 'observations',
        level => $level,
        reference_hial_text => undef,
        reference_vial_text => undef,
    });
}

my $over_limit = construct('over_limit_v1');
my $route = FSM::VIAL::ArchitectureScaleBridgeFanout::_route($over_limit);
$route->{arguments}{actor}{verification_observations}[-1]{role} = 'active_monitor';
my $precedence = $route->{method}->($route->{class}, $route->{arguments});
ok(!$precedence->{ok}, 'observation count 257 fails closed');
is(scalar(@{$precedence->{diagnostics}}), 1,
    'observation excess returns one deterministic diagnostic');
is($precedence->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
    'observation excess uses the established bridge limit code');
is($precedence->{diagnostics}[0]{category}, 'limit',
    'observation excess retains the limit category');
is($precedence->{diagnostics}[0]{message},
    'observations count 257 exceeds limit 256',
    'observation excess retains the established message');
is($precedence->{diagnostics}[0]{path}, '/observations',
    'observation excess retains the normalized collection path');
ok(!defined($precedence->{manifest}),
    'observation excess exposes no partial manifest');
ok(!defined($precedence->{report}),
    'observation excess exposes no partial report');

my $accepted = $class->evaluate({construction => construct('gate_candidate_v1')});
ok($accepted->{ok}, 'representative accepted observation route remains valid');
is($accepted->{status}, 'accepted',
    'representative observation route retains its accepted status');
is($accepted->{metrics}{observations}, 32,
    'accepted route retains every requested observation');
is($accepted->{manifest_sha256},
    'd99f3bd5a673d8fefcac11cbf8809a1ea87b664b09886bc015ecb2a7a2cd8d2f',
    'accepted route retains its manifest identity');
is($accepted->{report_sha256}, $accepted->{manifest_sha256},
    'accepted route retains byte-equal manifest and report identities');

done_testing;
