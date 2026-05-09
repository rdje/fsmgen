#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_nested_contract_source_map
);

my $sentinel = '__mutated_by_t711__';

subtest 'parent nested contract source map rebuilds cleanly after caller mutation' => sub {
    my $first = build_serializable_plan_report_contract();
    $first->{nested_contract_source_map}{normalized_semantic_json} = $sentinel;
    $first->{nested_contract_source_map}{$sentinel} = $sentinel;

    my $second = build_serializable_plan_report_contract();

    ok(
        !contains_sentinel($second->{nested_contract_source_map}),
        'fresh parent nested source map is not polluted',
    );
    is_deeply(
        $second->{nested_contract_source_map},
        serializable_plan_report_nested_contract_source_map(),
        'fresh parent contract embeds canonical nested source map',
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
