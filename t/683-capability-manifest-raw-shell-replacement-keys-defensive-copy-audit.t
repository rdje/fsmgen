#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_raw_shell_replacement_keys
);

my $sentinel = '__mutated_by_t683__';

subtest 'manifest raw shell replacement keys rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    $first->{embedding}{serializable_plan_reports}{raw_shell_replacement_keys}[0] = $sentinel;
    push @{$first->{embedding}{serializable_plan_reports}{raw_shell_replacement_keys}}, $sentinel;

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{serializable_plan_reports};

    ok(
        !contains_sentinel($contract->{raw_shell_replacement_keys}),
        'fresh manifest replacement key list is not polluted',
    );
    is_deeply(
        $contract->{raw_shell_replacement_keys},
        serializable_plan_report_raw_shell_replacement_keys(),
        'fresh manifest embeds canonical raw-shell replacement key list',
    );
    is_deeply(
        $contract,
        build_serializable_plan_report_contract(),
        'fresh manifest embeds a clean serializable plan/report contract',
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
