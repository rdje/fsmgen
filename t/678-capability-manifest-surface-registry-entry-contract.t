#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(
    serializable_plan_report_surface_registry_entry_keys
);

subtest 'manifest embeds advertised surface registry entry keys' => sub {
    my $manifest = build_capability_manifest();

    is_deeply(
        $manifest->{embedding}{serializable_plan_reports}{surface_registry_entry_keys},
        serializable_plan_report_surface_registry_entry_keys(),
        'manifest embeds canonical registry entry key list',
    );
};

subtest 'manifest registry entries match the embedded entry key list' => sub {
    my $manifest = build_capability_manifest();
    my $contract = $manifest->{embedding}{serializable_plan_reports};
    my $expected = as_set($contract->{surface_registry_entry_keys});

    for my $surface (sort keys %{$contract->{surface_registry}}) {
        is_deeply(
            as_set([keys %{$contract->{surface_registry}{$surface}}]),
            $expected,
            "$surface manifest registry entry keys match embedded shape",
        );
    }
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
