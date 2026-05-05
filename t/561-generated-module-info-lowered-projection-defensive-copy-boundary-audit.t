#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::GeneratedModuleInfoBuilder;

{
    package Local::DTModule;

    sub new {
        return bless {}, shift;
    }

    sub is_dt_root {
        return 1;
    }

    sub source_root_kind {
        return 'dt';
    }
}

{
    package Local::EnableGraphSignalSupport;

    sub new {
        return bless {}, shift;
    }

    sub get_reset_value_from_ast {
        return "1'b0";
    }
}

sub module_info {
    return {
        module_name => 'lowered_projection_audit',
        source_root_kind => 'dt',
        signal_analysis => {
            outputs => [
                {
                    name => 'serial_out',
                    width => 1,
                },
            ],
        },
    };
}

sub hdl_generator {
    return {
        assignment_analysis => {
            serial_out => {
                rhs_groups => {
                    "1'b1" => {
                        lhs_level_enable => {
                            name => 'serial_out_en',
                        },
                        dt_specific_enables => [
                            {
                                dt => '-left',
                                enable_name => 'left_en',
                            },
                            {
                                dt => '-right',
                                enable_name => 'right_en',
                            },
                        ],
                    },
                },
                multiplexer => {
                    type => 'comb',
                    default_value => "1'b0",
                },
                lhs_ast => {},
            },
        },
        enable_graph_signal_support => Local::EnableGraphSignalSupport->new,
    };
}

subtest 'generated module_info lowered top-level projections do not alias embedded lowered RTL IR' => sub {
    my $module_info = module_info();

    FSM::Pipeline::GeneratedModuleInfoBuilder->enrich_with_generated_analysis(
        module_info => $module_info,
        fsm_module => Local::DTModule->new,
        target_language => 'systemverilog',
        hdl_generator => hdl_generator(),
    );

    $module_info->{output_drive_families}[0]{rhs_enable_families}[0]{driver_enable_signals}[0] = 'mutated_enable';
    $module_info->{standalone_dt_multi_drive_targets}[0]{multi_drive_assertion}{kind} = 'mutated_assertion';

    is_deeply(
        {
            output_drive_families => $module_info->{lowered_rtl_ir}{output_drive_families},
            standalone_dt_multi_drive_targets => $module_info->{lowered_rtl_ir}{standalone_dt_multi_drive_targets},
        },
        {
            output_drive_families => [
                {
                    signal_name => 'serial_out',
                    width => 1,
                    multiplexer_type => 'comb',
                    default_value => "1'b0",
                    reset_value => "1'b0",
                    driver_count => 2,
                    driver_blocks => ['-left', '-right'],
                    rhs_values => ["1'b1"],
                    driver_enable_signals => ['left_en', 'right_en'],
                    family_enable_signals => ['serial_out_en'],
                    rhs_enable_families => [
                        {
                            rhs_value => "1'b1",
                            family_enable_signal => 'serial_out_en',
                            driver_blocks => ['-left', '-right'],
                            driver_enable_signals => ['left_en', 'right_en'],
                        },
                    ],
                },
            ],
            standalone_dt_multi_drive_targets => [
                {
                    signal_name => 'serial_out',
                    multiplexer_type => 'comb',
                    dt_names => ['-left', '-right'],
                    rhs_values => ["1'b1"],
                    dt_enable_signals => ['left_en', 'right_en'],
                    lhs_enable_signals => ['serial_out_en'],
                    multi_drive_assertion => {
                        kind => 'onehot0',
                        target_signal => 'serial_out',
                        input_count => 2,
                        input_enable_signals => ['left_en', 'right_en'],
                    },
                },
            ],
        },
        'mutating top-level lowered projections cannot contaminate the embedded lowered RTL IR payload',
    );
};

done_testing();
