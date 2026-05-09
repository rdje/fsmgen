#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);

subtest 'manifest-embedded surface registry entries have required structure' => sub {
    my $manifest = build_capability_manifest();
    my $registry = $manifest->{embedding}{serializable_plan_reports}{surface_registry};

    for my $surface (sort keys %{$registry}) {
        my $entry = $registry->{$surface};
        ok(ref($entry) eq 'HASH', "$surface manifest registry entry is a hash");
        ok(defined($entry->{contract_source}) && !ref($entry->{contract_source}), "$surface has scalar contract_source");
        ok(ref($entry->{primary_report_paths}) eq 'ARRAY', "$surface has primary_report_paths array");
        ok(@{$entry->{primary_report_paths}} > 0, "$surface has at least one primary report path");
        is(
            scalar(@{$entry->{primary_report_paths}}),
            scalar(keys %{as_set($entry->{primary_report_paths})}),
            "$surface primary report paths are unique",
        );
    }
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
