#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Support::ReportSourceContract qw(
    build_report_source_contract
    report_source_input_keys
    report_source_presence_key_family_map
    report_source_presence_keys
    report_source_resolution_keys
);
use FSM::Test::DefensiveCopyAudit qw(
    contains_sentinel
    mutate_structure
);

my $sentinel = '__mutated_by_t453__';

subtest 'report source contract builder returns fresh nested structures' => sub {
    my $first = build_report_source_contract();
    mutate_structure($first, $sentinel);

    my $second = build_report_source_contract();
    ok(!contains_sentinel($second, $sentinel), 'fresh report source contract is not affected by prior caller mutation');
    is_deeply(
        $second->{public_presence_keys},
        report_source_presence_keys(),
        'fresh contract public source keys match helper',
    );
    is_deeply(
        $second->{input_keys},
        report_source_input_keys(),
        'fresh contract input source keys match helper',
    );
    is_deeply(
        $second->{resolution_keys},
        report_source_resolution_keys(),
        'fresh contract resolution source keys match helper',
    );
    is_deeply(
        $second->{presence_key_family_map},
        report_source_presence_key_family_map(),
        'fresh contract presence family map matches helper',
    );
};

subtest 'report source helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'presence_keys',
            build => \&report_source_presence_keys,
        },
        {
            label => 'input_keys',
            build => \&report_source_input_keys,
        },
        {
            label => 'resolution_keys',
            build => \&report_source_resolution_keys,
        },
        {
            label => 'presence_key_family_map',
            build => \&report_source_presence_key_family_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first, $sentinel);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second, $sentinel), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh report source grouped map stays aligned with helper families' => sub {
    my $family_map = report_source_presence_key_family_map();

    is_deeply($family_map->{input_keys}, report_source_input_keys(), 'input family entry matches helper');
    is_deeply($family_map->{resolution_keys}, report_source_resolution_keys(), 'resolution family entry matches helper');
};

done_testing();
