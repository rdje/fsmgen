#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::IntentHIR;
use FSM::Pipeline::HDLGenerator;

subtest 'IntentHIR boundary helpers provide cloned system-contract and signal-analysis lookup' => sub {
    my $intent_hir = FSM::IR::IntentHIR->new(
        module_name => 'intent_hir_interface_boundary_helpers',
        source_root_kind => 'fsm',
        system_contract => {
            clock => 'clk',
            reset => 'rstn',
            declare_ports => 1,
        },
        signal_analysis => {
            inputs => [
                { name => 'clk', width => 1 },
                { name => 'rstn', width => 1 },
                { name => 'data_in', width => 8 },
            ],
            outputs => [
                { name => 'data_out', width => 8 },
            ],
        },
    );

    my $system_contract = FSM::IR::IntentHIR->system_contract_from_input($intent_hir);
    is_deeply(
        $system_contract,
        {
            clock => 'clk',
            declare_ports => 1,
            reset => 'rstn',
        },
        'system_contract_from_input returns the semantic system contract from IntentHIR',
    );

    my $inputs = FSM::IR::IntentHIR->signal_analysis_entries_from_input($intent_hir, 'inputs');
    is_deeply(
        [map { $_->{name} } @$inputs],
        ['clk', 'rstn', 'data_in'],
        'signal_analysis_entries_from_input returns semantic signal-analysis entries by direction',
    );

    $system_contract->{clock} = 'mutated_after_lookup';
    $inputs->[0]{name} = 'mutated_after_lookup';

    is(
        FSM::IR::IntentHIR->system_contract_from_input($intent_hir)->{clock},
        'clk',
        'system_contract_from_input clones the returned contract instead of aliasing caller-owned state',
    );
    is_deeply(
        [map { $_->{name} } @{FSM::IR::IntentHIR->signal_analysis_entries_from_input($intent_hir, 'inputs')}],
        ['clk', 'rstn', 'data_in'],
        'signal_analysis_entries_from_input clones the returned entries instead of aliasing caller-owned state',
    );
};

subtest 'realized child interface fallback now prefers IntentHIR boundary metadata when structural ports are absent' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $module_info = {
        intent_hir => {
            module_name => 'child_from_intent_hir_fallback',
            source_root_kind => 'fsm',
            system_contract => {
                clock => 'clk',
                reset => 'rstn',
                declare_ports => 1,
            },
            signal_analysis => {
                inputs => [
                    { name => 'clk', width => 1 },
                    { name => 'rstn', width => 1 },
                    { name => 'data_in', width => 8 },
                ],
                outputs => [
                    { name => 'data_out', width => 8 },
                ],
            },
        },
        system_contract => {
            clock => 'wrong_clk',
            reset => 'wrong_rst',
            declare_ports => 1,
        },
        signal_analysis => {
            inputs => [
                { name => 'wrong_clk', width => 1 },
            ],
            outputs => [
                { name => 'wrong_out', width => 4 },
            ],
        },
        structural_rtl_ir => {},
    };

    my $ports = $pipeline->build_realized_child_interface_ports($module_info);

    is_deeply(
        normalize_ports($ports),
        [
            { name => 'clk', direction => 'input', width => 1, type => 'clock' },
            { name => 'rstn', direction => 'input', width => 1, type => 'reset' },
            { name => 'data_in', direction => 'input', width => 8, type => undef },
            { name => 'data_out', direction => 'output', width => 8, type => undef },
        ],
        'realized child interface fallback now prefers IntentHIR system-contract and signal-analysis boundary metadata over stale raw module_info fields',
    );
};

done_testing();

sub normalize_ports {
    my ($ports) = @_;
    return [
        map {
            +{
                name => $_->name,
                direction => $_->direction,
                width => $_->width,
                type => $_->type,
            }
        } @{$ports || []}
    ];
}
