#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_contract_source
    serializable_plan_report_nested_contract_source_map
);

subtest 'parent serializable plan/report contract owns its nested source map' => sub {
    my $contract = build_serializable_plan_report_contract();
    my $source_map = serializable_plan_report_nested_contract_source_map();

    is(
        $contract->{contract_source},
        serializable_plan_report_contract_source(),
        'parent contract_source points to parent owner',
    );
    is_deeply(
        $contract->{nested_contract_source_map},
        $source_map,
        'parent contract embeds the canonical nested source map',
    );
    is(
        $contract->{composition_plan_snapshot_contract}{contract_source},
        $source_map->{composition_plan_snapshot},
        'composition child contract source matches nested owner map',
    );
    is(
        $contract->{generation_result_snapshot_contract}{contract_source},
        $source_map->{generation_result_snapshot},
        'generation child contract source matches nested owner map',
    );
    is(
        $contract->{diagnostic_summary_contract}{contract_source},
        $source_map->{diagnostic_summary},
        'diagnostic child contract source matches nested owner map',
    );
};

done_testing();
