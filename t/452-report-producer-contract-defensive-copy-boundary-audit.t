#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Support::ReportProducerContract qw(
    build_report_producer_contract
    normalized_semantic_report_producer_extra_keys
    report_producer_common_keys
    report_producer_presence_key_family_map
);
use FSM::Test::DefensiveCopyAudit qw(
    contains_sentinel
    mutate_structure
);

my $sentinel = '__mutated_by_t452__';

subtest 'report producer contract builder returns fresh nested structures' => sub {
    my $first = build_report_producer_contract();
    mutate_structure($first, $sentinel);

    my $second = build_report_producer_contract();
    ok(!contains_sentinel($second, $sentinel), 'fresh report producer contract is not affected by prior caller mutation');
    is_deeply(
        $second->{common_presence_keys},
        report_producer_common_keys(),
        'fresh contract common producer keys match helper',
    );
    is_deeply(
        $second->{normalized_semantic_extra_presence_keys},
        normalized_semantic_report_producer_extra_keys(),
        'fresh contract normalized-semantic extra producer keys match helper',
    );
    is_deeply(
        $second->{presence_key_family_map},
        report_producer_presence_key_family_map(),
        'fresh contract presence family map matches helper',
    );
};

subtest 'report producer helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'common_keys',
            build => \&report_producer_common_keys,
        },
        {
            label => 'normalized_semantic_extra_keys',
            build => \&normalized_semantic_report_producer_extra_keys,
        },
        {
            label => 'presence_key_family_map',
            build => \&report_producer_presence_key_family_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first, $sentinel);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second, $sentinel), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh report producer grouped map stays aligned with helper families' => sub {
    my $family_map = report_producer_presence_key_family_map();

    is_deeply($family_map->{common_presence_keys}, report_producer_common_keys(), 'common family entry matches helper');
    is_deeply(
        $family_map->{normalized_semantic_extra_presence_keys},
        normalized_semantic_report_producer_extra_keys(),
        'normalized-semantic extra family entry matches helper',
    );
};

done_testing();
