#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

subtest 'serializable plan/report guidance is structured for embedders' => sub {
    my $guidance = build_serializable_plan_report_contract()->{guidance};

    ok(ref($guidance) eq 'ARRAY', 'guidance is an array');
    ok(@{$guidance} > 0, 'guidance is non-empty');
    is(
        scalar(@{$guidance}),
        scalar(keys %{as_set($guidance)}),
        'guidance entries are unique',
    );

    for my $index (0 .. $#{$guidance}) {
        ok(
            defined($guidance->[$index]) && !ref($guidance->[$index]) && length($guidance->[$index]),
            "guidance entry $index is a non-empty scalar",
        );
    }

    ok(
        grep({ /JSON-safe report surfaces/ } @{$guidance}),
        'guidance points embedders toward JSON-safe report surfaces',
    );
    ok(
        grep({ /raw HDLGenerator branches/ } @{$guidance}),
        'guidance warns about raw HDLGenerator branches',
    );
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
