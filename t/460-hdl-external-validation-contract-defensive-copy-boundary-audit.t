#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Support::HDLExternalValidationContract qw(
    build_hdl_external_validation_contract
    hdl_external_validation_execution_failure_modes
    hdl_external_validation_failure_mode_family_map
    hdl_external_validation_failure_mode_names
    hdl_external_validation_failure_text_prefix_map
    hdl_external_validation_input_failure_modes
    hdl_external_validation_success_presence_key_family_map
    hdl_external_validation_success_step_keys
    hdl_external_validation_success_step_names
    hdl_external_validation_success_top_level_keys
);
use FSM::Test::DefensiveCopyAudit qw(
    contains_sentinel
    mutate_structure
);

my $sentinel = '__mutated_by_t460__';

subtest 'HDL external validation contract builder returns fresh nested structures' => sub {
    my $first = build_hdl_external_validation_contract();
    mutate_structure($first, $sentinel);

    my $second = build_hdl_external_validation_contract();
    ok(!contains_sentinel($second, $sentinel), 'fresh HDL external validation contract is not affected by prior caller mutation');
    is_deeply(
        $second->{success_top_level_presence_keys},
        hdl_external_validation_success_top_level_keys(),
        'fresh contract success top-level keys match helper',
    );
    is_deeply(
        $second->{success_step_presence_keys},
        hdl_external_validation_success_step_keys(),
        'fresh contract success step keys match helper',
    );
    is_deeply(
        $second->{success_presence_key_family_map},
        hdl_external_validation_success_presence_key_family_map(),
        'fresh contract success family map matches helper',
    );
    is_deeply(
        $second->{failure_mode_family_map},
        hdl_external_validation_failure_mode_family_map(),
        'fresh contract failure mode family map matches helper',
    );
    is_deeply(
        $second->{failure_text_prefix_map},
        hdl_external_validation_failure_text_prefix_map(),
        'fresh contract failure text prefix map matches helper',
    );
};

subtest 'HDL external validation helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'success_top_level_keys',
            build => \&hdl_external_validation_success_top_level_keys,
        },
        {
            label => 'success_step_keys',
            build => \&hdl_external_validation_success_step_keys,
        },
        {
            label => 'success_presence_key_family_map',
            build => \&hdl_external_validation_success_presence_key_family_map,
        },
        {
            label => 'success_step_names',
            build => \&hdl_external_validation_success_step_names,
        },
        {
            label => 'input_failure_modes',
            build => \&hdl_external_validation_input_failure_modes,
        },
        {
            label => 'execution_failure_modes',
            build => \&hdl_external_validation_execution_failure_modes,
        },
        {
            label => 'failure_mode_names',
            build => \&hdl_external_validation_failure_mode_names,
        },
        {
            label => 'failure_mode_family_map',
            build => \&hdl_external_validation_failure_mode_family_map,
        },
        {
            label => 'failure_text_prefix_map',
            build => \&hdl_external_validation_failure_text_prefix_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first, $sentinel);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second, $sentinel), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh HDL external validation grouped maps stay aligned with helper families' => sub {
    my $success_map = hdl_external_validation_success_presence_key_family_map();
    my $failure_map = hdl_external_validation_failure_mode_family_map();

    is_deeply(
        $success_map->{success_top_level_presence_keys},
        hdl_external_validation_success_top_level_keys(),
        'success top-level family entry matches helper',
    );
    is_deeply(
        $success_map->{success_step_presence_keys},
        hdl_external_validation_success_step_keys(),
        'success step family entry matches helper',
    );
    is_deeply(
        $failure_map->{input_failure_modes},
        hdl_external_validation_input_failure_modes(),
        'input failure family entry matches helper',
    );
    is_deeply(
        $failure_map->{execution_failure_modes},
        hdl_external_validation_execution_failure_modes(),
        'execution failure family entry matches helper',
    );
};

done_testing();
