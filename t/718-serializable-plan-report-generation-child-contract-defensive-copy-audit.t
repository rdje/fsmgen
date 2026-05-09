#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableGenerationResultSnapshot qw(build_serializable_generation_result_snapshot_contract);
use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

my $sentinel = '__mutated_by_t718__';

subtest 'parent generation child contract rebuilds cleanly after caller mutation' => sub {
    my $first = build_serializable_plan_report_contract();
    $first->{generation_result_snapshot_contract}{public_top_level_presence_keys}[0] = $sentinel;
    $first->{generation_result_snapshot_contract}{entrypoints}{in_process}[0] = $sentinel;

    my $second = build_serializable_plan_report_contract();

    ok(
        !contains_sentinel($second->{generation_result_snapshot_contract}),
        'fresh parent generation child contract is not polluted',
    );
    is_deeply(
        $second->{generation_result_snapshot_contract},
        build_serializable_generation_result_snapshot_contract(),
        'fresh parent contract embeds canonical generation child contract',
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
