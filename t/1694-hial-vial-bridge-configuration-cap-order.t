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
        primary_axis => 'configurations',
        level => $level,
        reference_hial_text => undef,
        reference_vial_text => undef,
    });
}

my $over_limit = construct('over_limit_v1');
my $route = FSM::VIAL::ArchitectureScaleBridgeFanout::_route($over_limit);
$route->{arguments}{actor}{params}[-1]{value} = 'bogus';
my $precedence = $route->{method}->($route->{class}, $route->{arguments});
ok(!$precedence->{ok}, 'configuration count 4,097 fails closed');
is(scalar(@{$precedence->{diagnostics}}), 1,
    'configuration excess returns one deterministic diagnostic');
is($precedence->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
    'configuration excess uses the established bridge limit code');
is($precedence->{diagnostics}[0]{category}, 'limit',
    'configuration excess retains the limit category');
is($precedence->{diagnostics}[0]{message},
    'configurations count 4097 exceeds limit 4096',
    'configuration excess retains the established message');
is($precedence->{diagnostics}[0]{path}, '/configurations',
    'configuration excess retains the normalized collection path');
ok(!defined($precedence->{manifest}),
    'configuration excess exposes no partial manifest');
ok(!defined($precedence->{report}),
    'configuration excess exposes no partial report');

my $accepted = $class->evaluate({construction => construct('gate_candidate_v1')});
ok($accepted->{ok}, 'representative accepted configuration route remains valid');
is($accepted->{status}, 'accepted',
    'representative configuration route retains its accepted status');
is($accepted->{metrics}{configurations}, 256,
    'accepted route retains every requested configuration');
is($accepted->{manifest_sha256},
    'c20d1868315a594da72d0228012b43fd862c3e7eac89c4b3e3748c9685493ff0',
    'accepted route retains its manifest identity');
is($accepted->{report_sha256}, $accepted->{manifest_sha256},
    'accepted route retains byte-equal manifest and report identities');

done_testing;
