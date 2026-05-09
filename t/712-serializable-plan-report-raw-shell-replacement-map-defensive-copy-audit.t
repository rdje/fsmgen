#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_raw_shell_replacement_map
);

my $sentinel = '__mutated_by_t712__';

subtest 'parent raw shell replacement map rebuilds cleanly after caller mutation' => sub {
    my $first = build_serializable_plan_report_contract();
    $first->{raw_shell_replacement_map}{composition_plan} = $sentinel;
    $first->{raw_shell_replacement_map}{$sentinel} = $sentinel;

    my $second = build_serializable_plan_report_contract();

    ok(
        !contains_sentinel($second->{raw_shell_replacement_map}),
        'fresh parent replacement map is not polluted',
    );
    is_deeply(
        $second->{raw_shell_replacement_map},
        serializable_plan_report_raw_shell_replacement_map(),
        'fresh parent contract embeds canonical raw-shell replacement map',
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
