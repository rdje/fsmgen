#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $fsm_file = File::Spec->catfile($FindBin::Bin, '..', 'fsm', 'lte_dif_pmaster.fsm');
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

my @top_level_enable_conditions = (
    values(%{$hdl->{state_enables} || {}}),
    values(%{$hdl->{dt_enables} || {}}),
);
ok(
    scalar(@top_level_enable_conditions) > 0,
    'live generation populates top-level state/DT enable registries',
);
my @non_ast_top_level_enable_conditions = grep {
    !(ref($_) && $_->can('to_systemverilog'))
} @top_level_enable_conditions;
ok(
    scalar(@non_ast_top_level_enable_conditions) == 0,
    'top-level state/DT enable registries store AST-backed conditions',
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
        analyze_ast_sub_expressions
        analyze_ast_complexity
        canonicalize_expression
        collect_all_wen_en_ast_expressions
        count_binary_logical_operation_occurrences
        convert_condition_to_ast
        convert_test_value_to_ast
        create_condition_expression_signal_name
        extract_signal_name_from_ast
        extract_lhs_name_from_ast
        extract_rhs_from_expression
        feed_asts_to_factorizer
        feed_current_asts_to_second_pass
        find_all_ast_sub_expressions
        flatten_all_decision_trees
        flatten_decision_tree
        generate_ast_based_signal_name
        generate_consolidated_intermediate_signals
        generate_comb_mux
        generate_enable_conditions
        generate_header
        generate_internal_signal_declarations
        generate_intermediate_signals
        generate_intermediate_signal_expression
        generate_module_declaration
        generate_state_encoding
        generate_state_register
        get_lhs_width_from_analysis
        get_default_value
        get_default_value_from_ast
        get_driven_signals
        get_explicit_reset_value
        get_fsm_reset_state
        get_substituted_ast_for_signal
        generate_flop_mux
        get_or_create_ast_signal_name
        get_pulse_active_level_for_lhs
        get_pulse_delay_cycles_for_lhs
        get_reset_value
        get_reset_value_from_ast
        get_signal_info
        is_complex_ast
        is_arithmetic_operation
        is_intermediate_signal
        is_logical_operation
        is_signal_referenced_in_substitutions
        is_signal_actually_used_in_final_expressions
        is_signal_ast_based_intermediate
        is_register
        is_simple_ast_expression
        is_simple_comparison
        is_simple_negation
        map_operator_to_name
        normalize_rhs_logic_level
        record_assignment_from_ast
        record_transition_from_ast
        run_global_ast_factorization
        set_fsm_module_reference
        should_filter_ast_based
        should_filter_consolidated_signal
        should_factor_logical_operation
        should_factor_ast
        set_explicit_reset_values
        parentheses_are_redundant
        fallback_register_analysis_from_assignments
        contains_frequently_used_operations
        count_unary_negations_in_original_expressions
        ast_contains_intermediate_signals
        ast_contains_signal
        ast_has_intermediate_signals_recursive
        prescan_wen_en_for_intermediate_signals
        run_second_pass_factorization
        track_ast_intermediate_signals
        topologically_sort_signals
        update_original_asts_with_second_pass_substitutions
        update_original_asts_with_substituted_versions
        _count_logical_ops_in_ast
        _is_factorizable_sub_expression
        _ast_contains_factorizable_operators
        _ast_to_systemverilog_internal
        _choose_operator_symbol
        _get_operator_precedence
        _traverse_ast_for_complexity
        _map_binary_operator
        _map_unary_operator
        _needs_parentheses
        _operand_is_single_bit
        _operand_needs_parens_for_negation
        _render_binary_op
        _render_unary_op
        _signal_is_single_bit
        _signal_name_indicates_ast_operators
        ast_to_systemverilog
        generate_wen_en_signals
        generate_expression_from_signal_name
    )
) {
    ok(
        !$hdl->can($dead_facade_helper),
        "live FlattenedDT facade no longer exposes dead helper '$dead_facade_helper'",
    );
}

for my $dead_backend_helper (
    qw(
        analyze_ast_sub_expressions
        collect_all_wen_en_ast_expressions
        count_binary_logical_operation_occurrences
        find_all_ast_sub_expressions
        generate_enable_conditions
        generate_wen_en_signals
        generate_comb_mux
        generate_flop_mux
        prescan_wen_en_for_intermediate_signals
        feed_asts_to_factorizer
        feed_current_asts_to_second_pass
        ast_contains_intermediate_signals
        ast_has_intermediate_signals_recursive
        ast_contains_signal
        count_unary_negations_in_original_expressions
        is_signal_referenced_in_substitutions
        is_signal_actually_used_in_final_expressions
        resolve_intermediate_signal_live_usage
        update_original_asts_with_substituted_versions
        update_original_asts_with_second_pass_substitutions
        _count_logical_ops_in_ast
        _is_factorizable_sub_expression
        is_simple_ast_expression
    )
) {
    ok(
        !$hdl->{backend_sv_ast_factorization}->can($dead_backend_helper),
        "live SystemVerilog AST-factorization owner no longer exposes dead helper '$dead_backend_helper'",
    );
}

ok(
    $hdl->{enable_graph}->can('generate_enable_conditions'),
    'live EnableGraph owns top-level state/DT enable emission',
);
ok(
    $hdl->{enable_graph}->can('generate_unified_wen_en_signals'),
    'live EnableGraph owns unified WEN/EN emission',
);
ok(
    $hdl->{enable_graph}->can('prescan_wen_en_for_intermediate_signals'),
    'live EnableGraph owns WEN/EN intermediate-signal prescan',
);
ok(
    $hdl->{enable_graph}->can('count_binary_logical_operation_occurrences'),
    'live EnableGraph owns binary logical-operation counting for factorization policy',
);
ok(
    $hdl->{enable_graph}->can('feed_asts_to_factorizer'),
    'live EnableGraph owns first-pass factorization AST feeding',
);
ok(
    $hdl->{enable_graph}->can('feed_current_asts_to_second_pass'),
    'live EnableGraph owns second-pass factorization AST feeding',
);
ok(
    $hdl->{enable_graph}->can('ast_contains_intermediate_signals'),
    'live EnableGraph owns second-pass intermediate-signal eligibility checks',
);
ok(
    $hdl->{enable_graph}->can('ast_contains_signal'),
    'live EnableGraph owns owner-side AST signal-reference inspection',
);
ok(
    $hdl->{enable_graph}->can('count_unary_negations_in_original_expressions'),
    'live EnableGraph owns substitution-era debug scans over owner-side AST structures',
);
ok(
    $hdl->{enable_graph}->can('is_signal_referenced_in_substitutions'),
    'live EnableGraph owns substituted-expression live-usage evidence',
);
ok(
    $hdl->{enable_graph}->can('is_signal_actually_used_in_final_expressions'),
    'live EnableGraph owns final-expression live-usage evidence',
);
ok(
    $hdl->{enable_graph}->can('resolve_intermediate_signal_live_usage'),
    'live EnableGraph owns cached live-usage metadata derivation',
);
ok(
    $hdl->{enable_graph}->can('update_original_asts_with_substituted_versions'),
    'live EnableGraph owns first-pass substitution synchronization into owner-side AST structures',
);
ok(
    $hdl->{enable_graph}->can('update_original_asts_with_second_pass_substitutions'),
    'live EnableGraph owns second-pass substitution synchronization into owner-side AST structures',
);
ok(
    $hdl->{enable_graph}->can('build_internal_signal_declaration_plan'),
    'live EnableGraph owns internal declaration planning',
);
ok(
    $hdl->{enable_graph}->can('build_module_declaration_plan'),
    'live EnableGraph owns module declaration planning',
);
ok(
    $hdl->{enable_graph}->can('build_state_register_plan'),
    'live EnableGraph owns state register planning',
);
ok(
    $hdl->{enable_graph_intermediate_support}->can('get_intermediate_signal_ast'),
    'live EnableGraph intermediate-signal support owns defining-AST recovery',
);
ok(
    $hdl->{enable_graph_intermediate_support}->can('get_intermediate_signal_expression'),
    'live EnableGraph intermediate-signal support owns intermediate expression rendering',
);
ok(
    $hdl->{enable_graph_intermediate_support}->can('build_dependency_recovery_ast_from_signal_name'),
    'live EnableGraph intermediate-signal support owns signal-name dependency AST recovery',
);
ok(
    $hdl->{enable_graph_intermediate_support}->can('track_ast_intermediate_signals'),
    'live EnableGraph intermediate-signal support owns referenced-intermediate tracking',
);

for my $dead_enable_graph_helper (
    qw(
        analyze_ast_complexity
        canonicalize_expression
        get_intermediate_signal_ast
        get_intermediate_signal_expression
        build_dependency_recovery_ast_from_signal_name
        track_ast_intermediate_signals
        create_condition_expression_signal_name
        get_or_create_ast_signal_name
        get_or_create_global_expression
        is_complex_ast
        needs_parentheses
        _get_intermediate_signal_registry_entry
        _register_intermediate_signal_registry_entry
        _get_native_intermediate_signal_ast
        should_factor_ast
        should_factor_condition
        signal_uses_register_assignment
        set_explicit_reset_values
        parentheses_are_redundant
        _traverse_ast_for_complexity
        generate_expression_from_signal_name
    )
) {
    ok(
        !$hdl->{enable_graph}->can($dead_enable_graph_helper),
        "live EnableGraph no longer exposes dead helper '$dead_enable_graph_helper'",
    );
}

for my $dead_orchestrator_helper (
    qw(
        record_assignment_from_ast
        record_transition_from_ast
    )
) {
    ok(
        !$hdl->{orchestrator}->can($dead_orchestrator_helper),
        "live Orchestrator no longer exposes dead helper '$dead_orchestrator_helper'",
    );
}

done_testing();
