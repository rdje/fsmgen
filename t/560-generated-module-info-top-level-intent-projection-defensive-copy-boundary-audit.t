#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::GeneratedModuleInfoBuilder;

{
    package Local::EmptyFSMModule;

    sub new {
        return bless {}, shift;
    }

    sub states {
        return [];
    }

    sub signals {
        return {};
    }
}

sub intent_hir_hash {
    return {
        module_name => 'generated_top_level_projection',
        source_root_kind => 'fsm',
        regular_state_count => 1,
        regular_state_names => ['idle'],
        state_count => 1,
        standalone_dt_count => 1,
        standalone_dt_names => ['-guard'],
        signal_count => 1,
        signal_names => ['payload'],
        signal_analysis => {
            inputs => [
                {
                    name => 'payload',
                    width => 8,
                },
            ],
        },
        explicit_system_contract => {
            clock => 'clk',
        },
        system_contract => {
            clock => 'clk',
            reset => 'rst_n',
        },
        requires_implicit_system_ports => 0,
        standalone_dt_enable_families => [
            {
                dt_name => '-guard',
                enable_signal => 'guard_en',
            },
        ],
        standalone_dt_module_enable_family => {
            enable_signal => 'module_en',
        },
        parameter_count => 1,
        parameter_names => ['WIDTH'],
        symbol_contract => {
            constants => {
                WIDTH => {
                    payload => '8',
                },
            },
        },
    };
}

subtest 'generated module_info owns top-level intent-HIR projections from hash inputs' => sub {
    my $intent_hir = intent_hir_hash();

    my $module_info = FSM::Pipeline::GeneratedModuleInfoBuilder->build_from_fsm_module(
        fsm_module => Local::EmptyFSMModule->new,
        intent_hir => $intent_hir,
    );

    push @{$intent_hir->{regular_state_names}}, 'mutated_state';
    push @{$intent_hir->{standalone_dt_names}}, '-mutated_dt';
    push @{$intent_hir->{signal_names}}, 'mutated_signal';
    $intent_hir->{signal_analysis}{inputs}[0]{width} = 99;
    $intent_hir->{explicit_system_contract}{clock} = 'mutated_clk';
    $intent_hir->{system_contract}{reset} = 'mutated_rst';
    $intent_hir->{standalone_dt_enable_families}[0]{enable_signal} = 'mutated_guard_en';
    $intent_hir->{standalone_dt_module_enable_family}{enable_signal} = 'mutated_module_en';
    push @{$intent_hir->{parameter_names}}, 'MUTATED_PARAMETER';
    $intent_hir->{symbol_contract}{constants}{WIDTH}{payload} = '99';

    is_deeply(
        {
            regular_state_names => $module_info->{regular_state_names},
            standalone_dt_names => $module_info->{standalone_dt_names},
            signal_names => $module_info->{signal_names},
            signal_analysis => $module_info->{signal_analysis},
            explicit_system_contract => $module_info->{explicit_system_contract},
            system_contract => $module_info->{system_contract},
            standalone_dt_enable_families => $module_info->{standalone_dt_enable_families},
            standalone_dt_module_enable_family => $module_info->{standalone_dt_module_enable_family},
            parameter_names => $module_info->{parameter_names},
            symbol_contract => $module_info->{symbol_contract},
        },
        {
            regular_state_names => ['idle'],
            standalone_dt_names => ['-guard'],
            signal_names => ['payload'],
            signal_analysis => {
                inputs => [
                    {
                        name => 'payload',
                        width => 8,
                    },
                ],
            },
            explicit_system_contract => {
                clock => 'clk',
            },
            system_contract => {
                clock => 'clk',
                reset => 'rst_n',
            },
            standalone_dt_enable_families => [
                {
                    dt_name => '-guard',
                    enable_signal => 'guard_en',
                },
            ],
            standalone_dt_module_enable_family => {
                enable_signal => 'module_en',
            },
            parameter_names => ['WIDTH'],
            symbol_contract => {
                constants => {
                    WIDTH => {
                        payload => '8',
                    },
                },
            },
        },
        'mutating the source intent-HIR hash cannot contaminate generated module_info top-level projections',
    );
};

done_testing();
