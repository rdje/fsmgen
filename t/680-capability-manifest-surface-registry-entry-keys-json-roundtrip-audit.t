#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(
    serializable_plan_report_surface_registry_entry_keys
);

subtest 'manifest registry entry keys survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};

    is_deeply(
        $contract->{surface_registry_entry_keys},
        serializable_plan_report_surface_registry_entry_keys(),
        'decoded manifest preserves canonical registry entry key list',
    );
};

subtest 'decoded manifest registry entries match decoded entry key list' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};
    my $expected = as_set($contract->{surface_registry_entry_keys});

    for my $surface (sort keys %{$contract->{surface_registry}}) {
        is_deeply(
            as_set([keys %{$contract->{surface_registry}{$surface}}]),
            $expected,
            "$surface decoded registry entry keys match decoded shape",
        );
    }
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
