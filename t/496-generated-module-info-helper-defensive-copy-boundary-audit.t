#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::GeneratedModuleInfoBuilder;

subtest 'output-drive fallback helper returns caller-owned arrays' => sub {
    my $module_info = {
        output_drive_families => [
            {
                signal_name => 'status',
                multiplexer_type => 'flop',
                rhs_enable_families => [
                    {
                        enable_signal => 'status_en',
                    },
                ],
            },
        ],
    };

    my $first = FSM::Pipeline::GeneratedModuleInfoBuilder->output_drive_families_from_module_info(
        $module_info,
    );
    $first->[0]{multiplexer_type} = 'mutated_after_lookup';
    $first->[0]{rhs_enable_families}[0]{enable_signal} = 'mutated_after_lookup';
    push @{$first}, { signal_name => 'extra' };

    my $second = FSM::Pipeline::GeneratedModuleInfoBuilder->output_drive_families_from_module_info(
        $module_info,
    );

    is_deeply(
        $second,
        [
            {
                signal_name => 'status',
                multiplexer_type => 'flop',
                rhs_enable_families => [
                    {
                        enable_signal => 'status_en',
                    },
                ],
            },
        ],
        'output-drive fallback helper protects module_info state from caller mutation',
    );
};

subtest 'standalone-DT target fallback helper returns caller-owned arrays' => sub {
    my $module_info = {
        standalone_dt_multi_drive_targets => [
            {
                signal_name => 'OUT',
                multiplexer_type => 'comb',
                dt_names => ['-from_a', '-from_b'],
                multi_drive_assertion => {
                    kind => 'onehot0',
                    input_count => 2,
                },
            },
        ],
    };

    my $first = FSM::Pipeline::GeneratedModuleInfoBuilder->standalone_dt_multi_drive_targets_from_module_info(
        $module_info,
    );
    $first->[0]{multiplexer_type} = 'mutated_after_lookup';
    $first->[0]{dt_names}[0] = 'mutated_after_lookup';
    $first->[0]{multi_drive_assertion}{kind} = 'mutated_after_lookup';
    push @{$first}, { signal_name => 'extra' };

    my $second = FSM::Pipeline::GeneratedModuleInfoBuilder->standalone_dt_multi_drive_targets_from_module_info(
        $module_info,
    );

    is_deeply(
        $second,
        [
            {
                signal_name => 'OUT',
                multiplexer_type => 'comb',
                dt_names => ['-from_a', '-from_b'],
                multi_drive_assertion => {
                    kind => 'onehot0',
                    input_count => 2,
                },
            },
        ],
        'standalone-DT target fallback helper protects module_info state from caller mutation',
    );
};

subtest 'helpers still return empty caller-owned arrays for malformed module_info' => sub {
    my $output_families = FSM::Pipeline::GeneratedModuleInfoBuilder->output_drive_families_from_module_info(
        undef,
    );
    my $dt_targets = FSM::Pipeline::GeneratedModuleInfoBuilder->standalone_dt_multi_drive_targets_from_module_info(
        [],
    );

    is_deeply($output_families, [], 'output-drive helper returns an empty array for missing module_info');
    is_deeply($dt_targets, [], 'standalone-DT helper returns an empty array for malformed module_info');
    isnt($output_families, $dt_targets, 'empty helper fallbacks do not share one mutable array reference');
};

done_testing();
