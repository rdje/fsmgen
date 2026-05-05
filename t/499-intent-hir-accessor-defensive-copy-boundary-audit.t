#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::IntentHIR;

subtest 'IntentHIR core semantic accessors return caller-owned copies' => sub {
    my $regular_state_names = [qw(IDLE RUN)];
    my $standalone_dt_names = [qw(route_data)];
    my $signal_names = [qw(trigger payload)];
    my $signal_analysis = {
        inputs => [
            {
                name => 'trigger',
                width => 1,
            },
        ],
        outputs => [
            {
                name => 'payload',
                width => 8,
            },
        ],
    };
    my $explicit_system_contract = {
        clock => {
            name => 'clk',
        },
    };
    my $system_contract = {
        clock_name => 'clk',
        reset => {
            name => 'rst_n',
            polarity => 'active_low',
        },
    };
    my $standalone_dt_enable_families = [
        {
            dt_name => 'route_data',
            enable_signal => 'route_data_en',
            members => [qw(payload)],
        },
    ];
    my $standalone_dt_module_enable_family = {
        enable_signal => 'module_route_en',
        dt_names => [qw(route_data)],
    };
    my $parameter_names = [qw(WIDTH)];
    my $symbol_contract = {
        type_names => [qw(byte_t)],
        types => {
            byte_t => {
                width => 8,
            },
        },
    };

    my $intent_hir = FSM::IR::IntentHIR->new(
        module_name => 'intent_accessor_copy_top',
        source_root_kind => 'fsm',
        regular_state_names => $regular_state_names,
        standalone_dt_names => $standalone_dt_names,
        signal_names => $signal_names,
        signal_analysis => $signal_analysis,
        explicit_system_contract => $explicit_system_contract,
        system_contract => $system_contract,
        requires_implicit_system_ports => 1,
        standalone_dt_enable_families => $standalone_dt_enable_families,
        standalone_dt_module_enable_family => $standalone_dt_module_enable_family,
        parameter_names => $parameter_names,
        symbol_contract => $symbol_contract,
    );

    $regular_state_names->[0] = 'mutated_after_constructor';
    $standalone_dt_names->[0] = 'mutated_after_constructor';
    $signal_names->[0] = 'mutated_after_constructor';
    $signal_analysis->{inputs}[0]{name} = 'mutated_after_constructor';
    $explicit_system_contract->{clock}{name} = 'mutated_after_constructor';
    $system_contract->{reset}{name} = 'mutated_after_constructor';
    $standalone_dt_enable_families->[0]{members}[0] = 'mutated_after_constructor';
    $standalone_dt_module_enable_family->{dt_names}[0] = 'mutated_after_constructor';
    $parameter_names->[0] = 'mutated_after_constructor';
    $symbol_contract->{types}{byte_t}{width} = 99;

    my $first_regular_states = $intent_hir->regular_state_names;
    my $first_dt_names = $intent_hir->standalone_dt_names;
    my $first_signal_names = $intent_hir->signal_names;
    my $first_signal_analysis = $intent_hir->signal_analysis;
    my $first_explicit_system = $intent_hir->explicit_system_contract;
    my $first_system = $intent_hir->system_contract;
    my $first_enable_families = $intent_hir->standalone_dt_enable_families;
    my $first_module_enable = $intent_hir->standalone_dt_module_enable_family;
    my $first_parameter_names = $intent_hir->parameter_names;
    my $first_symbol_contract = $intent_hir->symbol_contract;

    $first_regular_states->[1] = 'mutated_after_accessor';
    $first_dt_names->[0] = 'mutated_after_accessor';
    $first_signal_names->[1] = 'mutated_after_accessor';
    $first_signal_analysis->{outputs}[0]{width} = 99;
    $first_explicit_system->{clock}{name} = 'mutated_after_accessor';
    $first_system->{clock_name} = 'mutated_after_accessor';
    $first_enable_families->[0]{enable_signal} = 'mutated_after_accessor';
    $first_module_enable->{enable_signal} = 'mutated_after_accessor';
    $first_parameter_names->[0] = 'mutated_after_accessor';
    $first_symbol_contract->{type_names}[0] = 'mutated_after_accessor';

    is_deeply($intent_hir->regular_state_names, [qw(IDLE RUN)], 'regular_state_names is isolated');
    is_deeply($intent_hir->standalone_dt_names, [qw(route_data)], 'standalone_dt_names is isolated');
    is_deeply($intent_hir->signal_names, [qw(trigger payload)], 'signal_names is isolated');
    is_deeply(
        $intent_hir->signal_analysis,
        {
            inputs => [
                {
                    name => 'trigger',
                    width => 1,
                },
            ],
            outputs => [
                {
                    name => 'payload',
                    width => 8,
                },
            ],
        },
        'signal_analysis is isolated',
    );
    is_deeply(
        $intent_hir->explicit_system_contract,
        {
            clock => {
                name => 'clk',
            },
        },
        'explicit_system_contract is isolated',
    );
    is_deeply(
        $intent_hir->system_contract,
        {
            clock_name => 'clk',
            reset => {
                name => 'rst_n',
                polarity => 'active_low',
            },
        },
        'system_contract is isolated',
    );
    is_deeply(
        $intent_hir->standalone_dt_enable_families,
        [
            {
                dt_name => 'route_data',
                enable_signal => 'route_data_en',
                members => [qw(payload)],
            },
        ],
        'standalone_dt_enable_families is isolated',
    );
    is_deeply(
        $intent_hir->standalone_dt_module_enable_family,
        {
            enable_signal => 'module_route_en',
            dt_names => [qw(route_data)],
        },
        'standalone_dt_module_enable_family is isolated',
    );
    is_deeply($intent_hir->parameter_names, [qw(WIDTH)], 'parameter_names is isolated');
    is_deeply(
        $intent_hir->symbol_contract,
        {
            type_names => [qw(byte_t)],
            types => {
                byte_t => {
                    width => 8,
                },
            },
        },
        'symbol_contract is isolated',
    );
};

subtest 'IntentHIR composition accessors and helpers return caller-owned copies' => sub {
    my $composition_children = [
        {
            instance_name => 'child_a',
            child_kind => 'fsm',
            intent_hir => {
                module_name => 'child_a_mod',
            },
        },
    ];
    my $composition_generated_children = [
        {
            instance_name => 'generated_a',
            child_kind => 'dt',
            source_root_kind => 'dt',
        },
    ];
    my $composition_standalone_dt_children = [
        {
            instance_name => 'standalone_a',
            standalone_dt_names => [qw(route_data)],
        },
    ];

    my $intent_hir = FSM::IR::IntentHIR->new(
        module_name => 'intent_accessor_composition_top',
        source_root_kind => 'composition',
        regular_state_names => [],
        standalone_dt_names => [],
        signal_names => [],
        composition_child_count => 1,
        composition_children => $composition_children,
        composition_generated_child_count => 1,
        composition_generated_fsm_child_count => 0,
        composition_generated_dt_child_count => 1,
        composition_generated_children => $composition_generated_children,
        composition_standalone_dt_child_count => 1,
        composition_standalone_dt_block_count => 1,
        composition_standalone_dt_multi_drive_target_count => 0,
        composition_standalone_dt_children => $composition_standalone_dt_children,
        composition_lane => 'C3',
    );

    $composition_children->[0]{intent_hir}{module_name} = 'mutated_after_constructor';
    $composition_generated_children->[0]{child_kind} = 'mutated_after_constructor';
    $composition_standalone_dt_children->[0]{standalone_dt_names}[0] = 'mutated_after_constructor';

    my $first_children = $intent_hir->composition_children;
    my $first_generated_children = $intent_hir->composition_generated_children;
    my $first_standalone_children = $intent_hir->composition_standalone_dt_children;

    $first_children->[0]{intent_hir}{module_name} = 'mutated_after_accessor';
    $first_generated_children->[0]{source_root_kind} = 'mutated_after_accessor';
    $first_standalone_children->[0]{standalone_dt_names}[0] = 'mutated_after_accessor';

    is_deeply(
        $intent_hir->composition_children,
        [
            {
                instance_name => 'child_a',
                child_kind => 'fsm',
                intent_hir => {
                    module_name => 'child_a_mod',
                },
            },
        ],
        'composition_children is isolated',
    );
    is_deeply(
        $intent_hir->composition_generated_children,
        [
            {
                instance_name => 'generated_a',
                child_kind => 'dt',
                source_root_kind => 'dt',
            },
        ],
        'composition_generated_children is isolated',
    );
    is_deeply(
        $intent_hir->composition_standalone_dt_children,
        [
            {
                instance_name => 'standalone_a',
                standalone_dt_names => [qw(route_data)],
            },
        ],
        'composition_standalone_dt_children is isolated',
    );

    my $child = $intent_hir->composition_child('child_a');
    $child->{intent_hir}{module_name} = 'mutated_after_helper';

    is(
        $intent_hir->composition_child('child_a')->{intent_hir}{module_name},
        'child_a_mod',
        'composition_child helper is isolated from prior helper-return mutation',
    );
    is(
        $intent_hir->as_hashref->{composition_children}[0]{intent_hir}{module_name},
        'child_a_mod',
        'as_hashref is isolated from prior composition accessor and helper mutation',
    );
};

done_testing();
