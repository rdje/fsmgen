#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(
    serializable_plan_report_contract_source
    serializable_plan_report_nested_contract_source_map
);

subtest 'manifest serializable_plan_reports branch preserves source ownership' => sub {
    my $manifest = build_capability_manifest();
    my $branch = $manifest->{embedding}{serializable_plan_reports};
    my $source_map = serializable_plan_report_nested_contract_source_map();

    is(
        $branch->{contract_source},
        serializable_plan_report_contract_source(),
        'manifest branch keeps parent contract source',
    );
    is_deeply(
        $branch->{nested_contract_source_map},
        $source_map,
        'manifest branch keeps nested source owner map',
    );
    is(
        $branch->{composition_plan_snapshot_contract}{contract_source},
        $source_map->{composition_plan_snapshot},
        'manifest composition child source matches owner map',
    );
    is(
        $branch->{generation_result_snapshot_contract}{contract_source},
        $source_map->{generation_result_snapshot},
        'manifest generation child source matches owner map',
    );
    is(
        $branch->{diagnostic_summary_contract}{contract_source},
        $source_map->{diagnostic_summary},
        'manifest diagnostic child source matches owner map',
    );
};

done_testing();
