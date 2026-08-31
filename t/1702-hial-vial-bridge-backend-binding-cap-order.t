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
        primary_axis => 'backend_bindings',
        level => $level,
        reference_hial_text => undef,
        reference_vial_text => undef,
    });
}

my $over_limit = construct('over_limit_v1');
my $route = FSM::VIAL::ArchitectureScaleBridgeFanout::_route($over_limit);
my $last_configuration = $route->{arguments}{actor}{params}[-1]{name};
delete $route->{arguments}{backend_names}{vhdl}{configurations}{$last_configuration};
my $precedence = $route->{method}->($route->{class}, $route->{arguments});
ok(!$precedence->{ok}, 'derived backend-binding count 16,386 fails closed');
is(scalar(@{$precedence->{diagnostics}}), 1,
    'backend-binding excess returns one deterministic diagnostic');
is($precedence->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
    'backend-binding excess uses the established bridge limit code');
is($precedence->{diagnostics}[0]{category}, 'limit',
    'backend-binding excess retains the limit category');
is($precedence->{diagnostics}[0]{message},
    'backend_bindings count 16386 exceeds limit 16384',
    'backend-binding excess retains the established message');
is($precedence->{diagnostics}[0]{path}, '/backend_bindings',
    'backend-binding excess retains the normalized collection path');
ok(!defined($precedence->{manifest}),
    'backend-binding excess exposes no partial manifest');
ok(!defined($precedence->{report}),
    'backend-binding excess exposes no partial report');

my $accepted = $class->evaluate({construction => construct('gate_candidate_v1')});
ok($accepted->{ok}, 'representative accepted backend-binding route remains valid');
is($accepted->{status}, 'accepted',
    'representative backend-binding route retains its accepted status');
is($accepted->{metrics}{backend_bindings}, 2_048,
    'accepted route retains every requested backend binding');
is($accepted->{manifest_sha256},
    'ddee4b1bb8c65e2468365dd9a151cffba1b83b483db4e851e2347cb0b5c14ff8',
    'accepted route retains its manifest identity');
is($accepted->{report_sha256}, $accepted->{manifest_sha256},
    'accepted route retains byte-equal manifest and report identities');

done_testing;
