#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CompositionReportContract qw(
    composition_report_json_fragment_path
    composition_report_public_top_level_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(normalized_semantic_public_top_level_keys);
use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

subtest 'serializable plan/report embeds public report key metadata' => sub {
    my $contract = build_serializable_plan_report_contract();

    is_deeply(
        $contract->{normalized_semantic_report_public_top_level_keys},
        normalized_semantic_public_top_level_keys(),
        'contract embeds normalized semantic report top-level keys',
    );
    is_deeply(
        $contract->{composition_report_public_top_level_keys},
        composition_report_public_top_level_keys(),
        'contract embeds composition report top-level keys',
    );
    is(
        $contract->{composition_report_json_fragment_path},
        composition_report_json_fragment_path(),
        'contract embeds composition report JSON fragment path',
    );
};

done_testing();
