#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableCompositionPlanSnapshot qw(build_serializable_composition_plan_snapshot_contract);
use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

my $sentinel = '__mutated_by_t717__';

subtest 'parent composition child contract rebuilds cleanly after caller mutation' => sub {
    my $first = build_serializable_plan_report_contract();
    $first->{composition_plan_snapshot_contract}{public_top_level_presence_keys}[0] = $sentinel;
    $first->{composition_plan_snapshot_contract}{entrypoints}{in_process}[0] = $sentinel;

    my $second = build_serializable_plan_report_contract();

    ok(
        !contains_sentinel($second->{composition_plan_snapshot_contract}),
        'fresh parent composition child contract is not polluted',
    );
    is_deeply(
        $second->{composition_plan_snapshot_contract},
        build_serializable_composition_plan_snapshot_contract(),
        'fresh parent contract embeds canonical composition child contract',
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
