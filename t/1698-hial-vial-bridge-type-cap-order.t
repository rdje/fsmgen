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
        primary_axis => 'types',
        level => $level,
        reference_hial_text => undef,
        reference_vial_text => undef,
    });
}

my $over_limit = construct('over_limit_v1');
my $route = FSM::VIAL::ArchitectureScaleBridgeFanout::_route($over_limit);
$route->{arguments}{actor}{params}[-1]{width} = 4_097;
$route->{arguments}{actor}{params}[-1]{value} = 'hostile';
my $precedence = $route->{method}->($route->{class}, $route->{arguments});
ok(!$precedence->{ok}, 'type count 4,097 fails closed');
is(scalar(@{$precedence->{diagnostics}}), 1,
    'type excess returns one deterministic diagnostic');
is($precedence->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
    'type excess uses the established bridge limit code');
is($precedence->{diagnostics}[0]{category}, 'limit',
    'type excess retains the limit category');
is($precedence->{diagnostics}[0]{message},
    'types count 4097 exceeds limit 4096',
    'type excess retains the established message');
is($precedence->{diagnostics}[0]{path}, '/types',
    'type excess retains the normalized collection path');
ok(!defined($precedence->{manifest}),
    'type excess exposes no partial manifest');
ok(!defined($precedence->{report}),
    'type excess exposes no partial report');

my $accepted = $class->evaluate({construction => construct('gate_candidate_v1')});
ok($accepted->{ok}, 'representative accepted type route remains valid');
is($accepted->{status}, 'accepted',
    'representative type route retains its accepted status');
is($accepted->{metrics}{types}, 256,
    'accepted route retains every requested type');
is($accepted->{manifest_sha256},
    '24b651935df65bebaedab5b15524d2d9b60054e81b2046c58061ab2f5c91d73f',
    'accepted route retains its manifest identity');
is($accepted->{report_sha256}, $accepted->{manifest_sha256},
    'accepted route retains byte-equal manifest and report identities');

done_testing;
