#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Support::ReportCommandContract qw(
    build_report_command_contract
    report_command_flag_keys
    report_command_mode_keys
    report_command_presence_key_family_map
    report_command_presence_keys
    report_command_target_language_keys
);
use FSM::Test::DefensiveCopyAudit qw(
    contains_sentinel
    mutate_structure
);

my $sentinel = '__mutated_by_t454__';

subtest 'report command contract builder returns fresh nested structures' => sub {
    my $first = build_report_command_contract();
    mutate_structure($first, $sentinel);

    my $second = build_report_command_contract();
    ok(!contains_sentinel($second, $sentinel), 'fresh report command contract is not affected by prior caller mutation');
    is_deeply(
        $second->{public_presence_keys},
        report_command_presence_keys(),
        'fresh contract public command keys match helper',
    );
    is_deeply($second->{mode_keys}, report_command_mode_keys(), 'fresh contract mode keys match helper');
    is_deeply($second->{flag_keys}, report_command_flag_keys(), 'fresh contract flag keys match helper');
    is_deeply(
        $second->{target_language_keys},
        report_command_target_language_keys(),
        'fresh contract target-language keys match helper',
    );
    is_deeply(
        $second->{presence_key_family_map},
        report_command_presence_key_family_map(),
        'fresh contract presence family map matches helper',
    );
};

subtest 'report command helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'presence_keys',
            build => \&report_command_presence_keys,
        },
        {
            label => 'mode_keys',
            build => \&report_command_mode_keys,
        },
        {
            label => 'flag_keys',
            build => \&report_command_flag_keys,
        },
        {
            label => 'target_language_keys',
            build => \&report_command_target_language_keys,
        },
        {
            label => 'presence_key_family_map',
            build => \&report_command_presence_key_family_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first, $sentinel);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second, $sentinel), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh report command grouped map stays aligned with helper families' => sub {
    my $family_map = report_command_presence_key_family_map();

    is_deeply($family_map->{mode_keys}, report_command_mode_keys(), 'mode family entry matches helper');
    is_deeply($family_map->{flag_keys}, report_command_flag_keys(), 'flag family entry matches helper');
    is_deeply(
        $family_map->{target_language_keys},
        report_command_target_language_keys(),
        'target-language family entry matches helper',
    );
};

done_testing();
