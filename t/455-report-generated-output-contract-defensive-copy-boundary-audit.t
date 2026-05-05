#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Support::ReportGeneratedOutputContract qw(
    build_report_generated_output_contract
    report_generated_output_emission_keys
    report_generated_output_presence_key_family_map
    report_generated_output_presence_keys
);
use FSM::Test::DefensiveCopyAudit qw(
    contains_sentinel
    mutate_structure
);

my $sentinel = '__mutated_by_t455__';

subtest 'report generated-output contract builder returns fresh nested structures' => sub {
    my $first = build_report_generated_output_contract();
    mutate_structure($first, $sentinel);

    my $second = build_report_generated_output_contract();
    ok(!contains_sentinel($second, $sentinel), 'fresh report generated-output contract is not affected by prior caller mutation');
    is_deeply(
        $second->{public_presence_keys},
        report_generated_output_presence_keys(),
        'fresh contract public generated-output keys match helper',
    );
    is_deeply(
        $second->{emission_keys},
        report_generated_output_emission_keys(),
        'fresh contract emission keys match helper',
    );
    is_deeply(
        $second->{presence_key_family_map},
        report_generated_output_presence_key_family_map(),
        'fresh contract presence family map matches helper',
    );
};

subtest 'report generated-output helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'presence_keys',
            build => \&report_generated_output_presence_keys,
        },
        {
            label => 'emission_keys',
            build => \&report_generated_output_emission_keys,
        },
        {
            label => 'presence_key_family_map',
            build => \&report_generated_output_presence_key_family_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first, $sentinel);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second, $sentinel), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh report generated-output grouped map stays aligned with helper families' => sub {
    my $family_map = report_generated_output_presence_key_family_map();

    is_deeply($family_map->{emission_keys}, report_generated_output_emission_keys(), 'emission family entry matches helper');
};

done_testing();
