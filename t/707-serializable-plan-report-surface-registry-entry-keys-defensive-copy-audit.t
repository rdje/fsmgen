#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_surface_registry_entry_keys
);

my $sentinel = '__mutated_by_t707__';

subtest 'parent registry entry keys rebuild cleanly after caller mutation' => sub {
    my $first = build_serializable_plan_report_contract();
    $first->{surface_registry_entry_keys}[0] = $sentinel;
    push @{$first->{surface_registry_entry_keys}}, $sentinel;

    my $second = build_serializable_plan_report_contract();

    ok(
        !contains_sentinel($second->{surface_registry_entry_keys}),
        'fresh parent entry key list is not polluted',
    );
    is_deeply(
        $second->{surface_registry_entry_keys},
        serializable_plan_report_surface_registry_entry_keys(),
        'fresh parent contract embeds canonical registry entry key list',
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
