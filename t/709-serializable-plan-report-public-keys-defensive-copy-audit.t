#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_public_top_level_keys
);

my $sentinel = '__mutated_by_t709__';

subtest 'parent public top-level keys rebuild cleanly after caller mutation' => sub {
    my $first = build_serializable_plan_report_contract();
    $first->{public_top_level_presence_keys}[0] = $sentinel;
    push @{$first->{public_top_level_presence_keys}}, $sentinel;

    my $second = build_serializable_plan_report_contract();

    ok(
        !contains_sentinel($second->{public_top_level_presence_keys}),
        'fresh parent public key list is not polluted',
    );
    is_deeply(
        $second->{public_top_level_presence_keys},
        serializable_plan_report_public_top_level_keys(),
        'fresh parent contract embeds canonical public top-level key list',
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
