#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_json_safe_surface_keys
    serializable_plan_report_nested_contract_source_map
    serializable_plan_report_public_top_level_keys
    serializable_plan_report_raw_shell_replacement_keys
    serializable_plan_report_raw_shell_replacement_map
);

my $sentinel = '__mutated_by_t645__';

subtest 'serializable plan/report contract returns fresh nested containers' => sub {
    my $first = build_serializable_plan_report_contract();
    $first->{public_top_level_presence_keys}[0] = $sentinel;
    $first->{json_safe_surface_keys}[0] = $sentinel;
    $first->{nested_contract_source_map}{$sentinel} = $sentinel;
    $first->{raw_shell_replacement_keys}[0] = $sentinel;
    $first->{raw_shell_replacement_map}{composition_plan} = $sentinel;
    $first->{composition_plan_snapshot_contract}{public_top_level_presence_keys}[0] = $sentinel;
    $first->{generation_result_snapshot_contract}{summary_keys}[0] = $sentinel;
    $first->{diagnostic_summary_contract}{summary_keys}[0] = $sentinel;
    push @{$first->{guidance}}, $sentinel;

    my $second = build_serializable_plan_report_contract();
    ok(!contains_sentinel($second), 'fresh contract is not polluted by prior caller mutation');
    is_deeply(
        $second->{public_top_level_presence_keys},
        serializable_plan_report_public_top_level_keys(),
        'fresh contract keeps public top-level key list',
    );
    is_deeply(
        $second->{json_safe_surface_keys},
        serializable_plan_report_json_safe_surface_keys(),
        'fresh contract keeps JSON-safe surface list',
    );
    is_deeply(
        $second->{nested_contract_source_map},
        serializable_plan_report_nested_contract_source_map(),
        'fresh contract keeps nested owner map',
    );
    is_deeply(
        $second->{raw_shell_replacement_map},
        serializable_plan_report_raw_shell_replacement_map(),
        'fresh contract keeps raw-shell replacement map',
    );
    is_deeply(
        $second->{raw_shell_replacement_keys},
        serializable_plan_report_raw_shell_replacement_keys(),
        'fresh contract keeps raw-shell replacement key list',
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
