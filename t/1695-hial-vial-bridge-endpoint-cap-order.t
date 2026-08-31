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
        primary_axis => 'endpoints',
        level => $level,
        reference_hial_text => undef,
        reference_vial_text => undef,
    });
}

my $over_limit = construct('over_limit_v1');
my $route = FSM::VIAL::ArchitectureScaleBridgeFanout::_route($over_limit);
$route->{arguments}{actor}{interface}{inputs}[-1]{width} = 0;
my $precedence = $route->{method}->($route->{class}, $route->{arguments});
ok(!$precedence->{ok}, 'endpoint count 4,097 fails closed');
is(scalar(@{$precedence->{diagnostics}}), 1,
    'endpoint excess returns one deterministic diagnostic');
is($precedence->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
    'endpoint excess uses the established bridge limit code');
is($precedence->{diagnostics}[0]{category}, 'limit',
    'endpoint excess retains the limit category');
is($precedence->{diagnostics}[0]{message},
    'endpoints count 4097 exceeds limit 4096',
    'endpoint excess retains the established message');
is($precedence->{diagnostics}[0]{path}, '/endpoints',
    'endpoint excess retains the normalized collection path');
ok(!defined($precedence->{manifest}),
    'endpoint excess exposes no partial manifest');
ok(!defined($precedence->{report}),
    'endpoint excess exposes no partial report');

my $accepted = $class->evaluate({construction => construct('gate_candidate_v1')});
ok($accepted->{ok}, 'representative accepted endpoint route remains valid');
is($accepted->{status}, 'accepted',
    'representative endpoint route retains its accepted status');
is($accepted->{metrics}{endpoints}, 256,
    'accepted route retains every requested endpoint');
is($accepted->{manifest_sha256},
    '1ddbda7ae569a510b64cf03ded0591af9ba8ecc7c11614206660492cdde5b30d',
    'accepted route retains its manifest identity');
is($accepted->{report_sha256}, $accepted->{manifest_sha256},
    'accepted route retains byte-equal manifest and report identities');

done_testing;
