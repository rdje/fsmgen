#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(serializable_plan_report_public_top_level_keys);

subtest 'manifest plan/report public top-level keys survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};
    my $public_keys = $contract->{public_top_level_presence_keys};

    is_deeply(
        $public_keys,
        serializable_plan_report_public_top_level_keys(),
        'decoded manifest keeps canonical plan/report public key list',
    );
    is_deeply(
        as_set($public_keys),
        as_set([keys %{$contract}]),
        'decoded manifest public key list matches decoded branch keys',
    );
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
