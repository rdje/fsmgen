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
        primary_axis => 'transactions',
        level => $level,
        reference_hial_text => undef,
        reference_vial_text => undef,
    });
}

my $over_limit = construct('over_limit_v1');
my $route = FSM::VIAL::ArchitectureScaleBridgeFanout::_route($over_limit);
$route->{arguments}{actor}{transactions}[-1]{name} = 'hostile';
my $precedence = $route->{method}->($route->{class}, $route->{arguments});
ok(!$precedence->{ok}, 'transaction count 257 fails closed');
is(scalar(@{$precedence->{diagnostics}}), 1,
    'transaction excess returns one deterministic diagnostic');
is($precedence->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
    'transaction excess uses the established bridge limit code');
is($precedence->{diagnostics}[0]{category}, 'limit',
    'transaction excess retains the limit category');
is($precedence->{diagnostics}[0]{message},
    'transactions count 257 exceeds limit 256',
    'transaction excess retains the established message');
is($precedence->{diagnostics}[0]{path}, '/transactions',
    'transaction excess retains the normalized collection path');
ok(!defined($precedence->{manifest}),
    'transaction excess exposes no partial manifest');
ok(!defined($precedence->{report}),
    'transaction excess exposes no partial report');

my $accepted = $class->evaluate({construction => construct('gate_candidate_v1')});
ok($accepted->{ok}, 'representative accepted transaction route remains valid');
is($accepted->{status}, 'accepted',
    'representative transaction route retains its accepted status');
is($accepted->{metrics}{transactions}, 32,
    'accepted route retains every requested transaction');
is($accepted->{manifest_sha256},
    'a0e0973d013927c85f5b08773436a34fb0fde7e5e93116d454bfee37894f0c3b',
    'accepted route retains its manifest identity');
is($accepted->{report_sha256}, $accepted->{manifest_sha256},
    'accepted route retains byte-equal manifest and report identities');

done_testing;
