#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(serializable_plan_report_surface_registry);

my $sentinel = '__mutated_by_t667__';

subtest 'manifest embeds canonical serializable plan/report surface registry' => sub {
    my $manifest = build_capability_manifest();
    is_deeply(
        $manifest->{embedding}{serializable_plan_reports}{surface_registry},
        serializable_plan_report_surface_registry(),
        'manifest embeds canonical surface registry',
    );
};

subtest 'manifest rebuilds surface registry cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    $first->{embedding}{serializable_plan_reports}{surface_registry}{diagnostic_summary}{contract_source} = $sentinel;
    $first->{embedding}{serializable_plan_reports}{surface_registry}{diagnostic_summary}{primary_report_paths}[0] = $sentinel;

    my $second = build_capability_manifest();
    ok(!contains_sentinel($second->{embedding}{serializable_plan_reports}{surface_registry}), 'fresh manifest registry is not polluted');
    is_deeply(
        $second->{embedding}{serializable_plan_reports}{surface_registry},
        serializable_plan_report_surface_registry(),
        'fresh manifest keeps canonical registry',
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
