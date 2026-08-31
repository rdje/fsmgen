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
        primary_axis => 'retained_residue_records',
        level => $level,
        reference_hial_text => undef,
        reference_vial_text => undef,
    });
}

my $over_limit = construct('over_limit_v1');
my $route = FSM::VIAL::ArchitectureScaleBridgeFanout::_route($over_limit);
$route->{arguments}{actor}{verification_bridge}{residues}[-1] = 'hostile';
$route->{arguments}{schedule_report}{verification_bridge}{residues}[-1] = 'hostile';
my $precedence = $route->{method}->($route->{class}, $route->{arguments});
ok(!$precedence->{ok}, 'retained-residue count 4,097 fails closed');
is(scalar(@{$precedence->{diagnostics}}), 1,
    'retained-residue excess returns one deterministic diagnostic');
is($precedence->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
    'retained-residue excess uses the established bridge limit code');
is($precedence->{diagnostics}[0]{category}, 'limit',
    'retained-residue excess retains the limit category');
is($precedence->{diagnostics}[0]{message},
    'unsupported_residue count 4097 exceeds limit 4096',
    'retained-residue excess retains the established message');
is($precedence->{diagnostics}[0]{path}, '/unsupported_residue',
    'retained-residue excess retains the normalized collection path');
ok(!defined($precedence->{manifest}),
    'retained-residue excess exposes no partial manifest');
ok(!defined($precedence->{report}),
    'retained-residue excess exposes no partial report');

my $accepted = $class->evaluate({construction => construct('gate_candidate_v1')});
ok($accepted->{ok}, 'representative accepted retained-residue route remains valid');
is($accepted->{status}, 'accepted',
    'representative retained-residue route retains its accepted status');
is($accepted->{metrics}{retained_residue_records}, 256,
    'accepted route retains every requested retained-residue record');
is($accepted->{manifest_sha256},
    '3ae26c7fd27b524c0ae86ab79d164504bc7d5905aabf404edef6876baa8003e0',
    'accepted route retains its manifest identity');
is($accepted->{report_sha256}, $accepted->{manifest_sha256},
    'accepted route retains byte-equal manifest and report identities');

done_testing;
