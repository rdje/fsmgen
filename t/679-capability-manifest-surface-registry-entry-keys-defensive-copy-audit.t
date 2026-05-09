#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_surface_registry_entry_keys
);

my $sentinel = '__mutated_by_t679__';

subtest 'manifest surface registry entry keys rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    $first->{embedding}{serializable_plan_reports}{surface_registry_entry_keys}[0] = $sentinel;
    push @{$first->{embedding}{serializable_plan_reports}{surface_registry_entry_keys}}, $sentinel;

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{serializable_plan_reports};

    ok(
        !contains_sentinel($contract->{surface_registry_entry_keys}),
        'fresh manifest entry key list is not polluted',
    );
    is_deeply(
        $contract->{surface_registry_entry_keys},
        serializable_plan_report_surface_registry_entry_keys(),
        'fresh manifest embeds canonical registry entry key list',
    );
    is_deeply(
        $contract,
        build_serializable_plan_report_contract(),
        'fresh manifest embeds a clean serializable plan/report contract',
    );
};

done_testing();

sub contains_sentinel {
    my ($value) = @_;
    return 1 if defined($value) && !ref($value) && $value eq $sentinel;
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        return 1 if grep { contains_sentinel($_) } @$value;
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists $value->{$sentinel};
        return 1 if grep { contains_sentinel($_) } values %$value;
        return 0;
    }

    return 0;
}
