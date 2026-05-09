#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

my $sentinel = '__mutated_by_t713__';

subtest 'parent guidance rebuilds cleanly after caller mutation' => sub {
    my $first = build_serializable_plan_report_contract();
    $first->{guidance}[0] = $sentinel;
    push @{$first->{guidance}}, $sentinel;

    my $second = build_serializable_plan_report_contract();

    ok(!contains_sentinel($second->{guidance}), 'fresh parent guidance is not polluted');
    ok(ref($second->{guidance}) eq 'ARRAY', 'fresh guidance remains an array');
    ok(@{$second->{guidance}} > 0, 'fresh guidance remains non-empty');
    ok(
        grep({ /JSON-safe report surfaces/ } @{$second->{guidance}}),
        'fresh guidance still points to JSON-safe report surfaces',
    );
    ok(
        grep({ /raw HDLGenerator branches/ } @{$second->{guidance}}),
        'fresh guidance still warns about raw HDLGenerator branches',
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
