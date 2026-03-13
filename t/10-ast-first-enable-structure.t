#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $fsm_file = File::Spec->catfile($FindBin::Bin, '..', 'fsm', 'trial_1.fsm');
my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

{
    local $SIG{__WARN__} = sub { };
    $pipeline->generate_hdl_from_file($fsm_file);
}

my $hdl = $pipeline->{hdl_generator};
my $assignment_analysis = $hdl->{assignment_analysis} || {};

ok(
    scalar(keys %$assignment_analysis) > 0,
    'live generation builds assignment_analysis for AST-first enable synthesis',
);

my @rhs_groups;
for my $lhs (sort keys %$assignment_analysis) {
    my $rhs_groups = $assignment_analysis->{$lhs}{rhs_groups} || {};
    push @rhs_groups, map { $rhs_groups->{$_} } sort keys %$rhs_groups;
}

ok(
    scalar(@rhs_groups) > 0,
    'live generation populates RHS groups for enable synthesis',
);

my @groups_with_ast_dt_enables = grep {
    ref($_->{dt_specific_enables}) eq 'ARRAY'
        && scalar(@{$_->{dt_specific_enables}}) > 0
        && ref($_->{dt_specific_enables}[0]) eq 'HASH'
        && $_->{dt_specific_enables}[0]{enable_ast}
} @rhs_groups;
ok(
    scalar(@groups_with_ast_dt_enables) > 0,
    'DT-specific enables are stored as AST-backed metadata inside rhs_groups',
);

my @groups_with_ast_lhs_enables = grep {
    ref($_->{lhs_level_enable}) eq 'HASH'
        && $_->{lhs_level_enable}{ast}
} @rhs_groups;
ok(
    scalar(@groups_with_ast_lhs_enables) > 0,
    'LHS-level enables are stored as AST-backed metadata inside rhs_groups',
);

ok(
    !exists $hdl->{dt_specific_enables},
    'live generation leaves no legacy top-level dt_specific_enables state behind',
);

ok(
    !exists $hdl->{lhs_to_enable_value_pairs},
    'live generation leaves no legacy top-level lhs_to_enable_value_pairs state behind',
);

ok(
    !exists $hdl->{expected_lhs_rhs},
    'live generation leaves no legacy expected_lhs_rhs tracking state behind',
);

ok(
    !exists $hdl->{actual_lhs_rhs},
    'live generation leaves no legacy actual_lhs_rhs tracking state behind',
);

ok(
    !exists $hdl->{missing_lhs_rhs},
    'live generation leaves no legacy missing_lhs_rhs tracking state behind',
);

ok(
    !exists $hdl->{intermediate_signals_to_declare},
    'live generation leaves no legacy intermediate_signals_to_declare scratch state behind',
);

ok(
    !$hdl->can('get_signal_ast_node'),
    'live FlattenedDT facade no longer exposes the dead get_signal_ast_node helper',
);

for my $dead_helper (
    qw(
        build_unified_assignment_analysis
        group_assignments_by_rhs
        generate_complete_enable_structure
        build_multiplexer_config
        generate_unified_wen_en_signals
        generate_dt_enables_from_analysis
        generate_lhs_enables_from_analysis
        generate_signal_assignments
        generate_unified_flop_mux
        generate_unified_pulse_delay_logic
        signal_uses_register_assignment
        generate_unified_comb_mux
    )
) {
    ok(
        !$hdl->can($dead_helper),
        "live FlattenedDT facade no longer exposes dead unified helper '$dead_helper'",
    );
}

for my $dead_facade_helper (
    qw(
        create_condition_expression_signal_name
        set_explicit_reset_values
        parentheses_are_redundant
        generate_expression_from_signal_name
    )
) {
    ok(
        !$hdl->can($dead_facade_helper),
        "live FlattenedDT facade no longer exposes dead helper '$dead_facade_helper'",
    );
}

for my $dead_enable_graph_helper (
    qw(
        create_condition_expression_signal_name
        get_or_create_global_expression
        needs_parentheses
        should_factor_condition
        signal_uses_register_assignment
        set_explicit_reset_values
        parentheses_are_redundant
        generate_expression_from_signal_name
    )
) {
    ok(
        !$hdl->{enable_graph}->can($dead_enable_graph_helper),
        "live EnableGraph no longer exposes dead helper '$dead_enable_graph_helper'",
    );
}

done_testing();
