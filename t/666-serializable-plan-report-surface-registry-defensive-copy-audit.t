#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_surface_registry
);

my $sentinel = '__mutated_by_t666__';

subtest 'surface registry returns fresh nested containers' => sub {
    my $first = serializable_plan_report_surface_registry();
    $first->{diagnostic_summary}{contract_source} = $sentinel;
    $first->{diagnostic_summary}{primary_report_paths}[0] = $sentinel;
    $first->{$sentinel} = {contract_source => $sentinel};

    my $second = serializable_plan_report_surface_registry();
    ok(!contains_sentinel($second), 'fresh registry is not polluted by prior caller mutation');
    is(
        $second->{diagnostic_summary}{primary_report_paths}[0],
        'embedding.serializable_plan_reports.diagnostic_summary_contract',
        'fresh registry keeps diagnostic summary manifest path',
    );
};

subtest 'parent contract embeds a fresh surface registry' => sub {
    my $first = build_serializable_plan_report_contract();
    $first->{surface_registry}{generation_result_snapshot}{primary_report_paths}[0] = $sentinel;

    my $second = build_serializable_plan_report_contract();
    ok(!contains_sentinel($second->{surface_registry}), 'fresh contract registry is not polluted');
    is_deeply(
        $second->{surface_registry},
        serializable_plan_report_surface_registry(),
        'fresh contract embeds canonical registry',
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
