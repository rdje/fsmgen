#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBridgeFanout;

my $class = 'FSM::VIAL::ArchitectureScaleBridgeFanout';
my $manifest_schema = 'fsmgen.hial_vial_bridge_manifest.v1';

sub construct {
    my ($level) = @_;
    return $class->construct({
        primary_axis => 'serialized_manifest_bytes',
        level => $level,
        reference_hial_text => undef,
        reference_vial_text => undef,
    });
}

sub build_with_terminal_observation {
    my ($level) = @_;
    my $route = FSM::VIAL::ArchitectureScaleBridgeFanout::_route(
        construct($level),
    );
    my $encode = \&JSON::PP::encode;
    my $validate_limits =
        \&FSM::HIAL::VIALBridge::Builder::_validate_limits;
    my $validate_unique =
        \&FSM::HIAL::VIALBridge::Builder::_validate_unique_semantic_ids;
    my ($limit_passes, $unique_passes) = (0, 0);
    my @encodes;
    my $result;
    {
        no warnings 'redefine';
        local *FSM::HIAL::VIALBridge::Builder::_validate_limits = sub {
            $limit_passes++;
            return $validate_limits->(@_);
        };
        local *FSM::HIAL::VIALBridge::Builder::_validate_unique_semantic_ids = sub {
            $unique_passes++;
            return $validate_unique->(@_);
        };
        local *JSON::PP::encode = sub {
            my ($json, $value) = @_;
            my $encoded = $encode->($json, $value);
            if (ref($value) eq 'HASH'
                    && ($value->{schema} // '') eq $manifest_schema) {
                push @encodes, {
                    bytes => bytes::length($encoded),
                    configurations => scalar(@{$value->{configurations}}),
                    observations => scalar(@{$value->{observations}}),
                    residue => scalar(@{$value->{unsupported_residue}}),
                    source_map => scalar(@{$value->{source_map}}),
                    terminal_limits_seen => $limit_passes,
                    unique_ids_seen => $unique_passes,
                };
            }
            return $encoded;
        };
        $result = $route->{method}->($route->{class}, $route->{arguments});
    }
    return ($result, \@encodes);
}

my ($limit, $limit_encodes) = build_with_terminal_observation('limit_v1');
ok($limit->{ok}, 'exact 16-MiB canonical manifest remains accepted');
is(scalar(@$limit_encodes), 1,
    'accepted route performs one canonical manifest encoding');
is_deeply($limit_encodes->[0], {
    bytes => 16_777_216,
    configurations => 500,
    observations => 2,
    residue => 4_000,
    source_map => 34_247,
    terminal_limits_seen => 1,
    unique_ids_seen => 1,
}, 'accepted canonical encoding follows complete structural validation');

my $canonical = JSON::PP->new->canonical(1)->utf8(1);
my $manifest_json = $canonical->encode($limit->{manifest}->as_hashref);
my $report_json = $canonical->encode($limit->{report});
is(bytes::length($manifest_json), 16_777_216,
    'public accepted projection retains the exact byte boundary');
is(sha256_hex($manifest_json),
    '017be1a6ceaf792d6a0de7bd99580f1c24a664d300fac8e1c33f55efdf98301a',
    'accepted boundary retains its canonical manifest identity');
is($report_json, $manifest_json,
    'accepted boundary report remains byte-equal to the manifest');

my ($excess, $excess_encodes) =
    build_with_terminal_observation('over_limit_v1');
ok(!$excess->{ok}, 'first complete valid record over the byte boundary fails');
is(scalar(@{$excess->{diagnostics}}), 1,
    'serialized excess returns one deterministic diagnostic');
is($excess->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
    'serialized excess retains the established bridge limit code');
is($excess->{diagnostics}[0]{category}, 'limit',
    'serialized excess retains the limit category');
is($excess->{diagnostics}[0]{message},
    'serialized manifest exceeds 16777216 bytes',
    'serialized excess retains the established exact-byte message');
is($excess->{diagnostics}[0]{path}, '/',
    'serialized excess retains the manifest root path');
is(scalar(@$excess_encodes), 1,
    'excess route performs one canonical manifest encoding');
is_deeply($excess_encodes->[0], {
    bytes => 16_777_219,
    configurations => 500,
    observations => 2,
    residue => 4_000,
    source_map => 34_247,
    terminal_limits_seen => 1,
    unique_ids_seen => 1,
}, 'adjacent excess is decided from the complete canonical manifest');
ok(!defined($excess->{manifest}),
    'serialized excess exposes no partial manifest');
ok(!defined($excess->{report}),
    'serialized excess exposes no partial report');

done_testing;
