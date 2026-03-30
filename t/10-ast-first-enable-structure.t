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
        run_global_ast_factorization
        run_second_pass_factorization
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
    $hdl->{backend_sv_global_factorization}->can('run_global_ast_factorization'),
    'live SystemVerilog global factorization support owns the first-pass AST factorization pipeline',
);
ok(
    $hdl->{backend_sv_global_factorization}->can('run_second_pass_factorization'),
    'live SystemVerilog global factorization support owns fixpoint delegation for post-substitution factorization',
);
ok(
    $hdl->{backend_sv_consolidated_intermediate_support}->can('collect_consolidated_intermediate_signals'),
    'live SystemVerilog consolidated intermediate support owns merged signal collection and handoff into normalization',
);
ok(
    !$hdl->{backend_sv_consolidated_intermediate_support}->can('normalize_consolidated_intermediate_metadata'),
    'live SystemVerilog consolidated intermediate support no longer keeps runtime metadata normalization inline',
);
ok(
    $hdl->{backend_sv_consolidated_intermediate_normalization_support}->can('normalize_consolidated_intermediate_metadata'),
    'live SystemVerilog consolidated intermediate normalization support owns runtime metadata normalization',
);
ok(
    $hdl->{backend_sv_consolidated_intermediate_classification_support}->can('classify_consolidated_signals'),
    'live SystemVerilog consolidated intermediate classification support owns the initial AST-first keep/filter partition',
);
ok(
    !$hdl->{backend_sv_consolidated_intermediate_selection_support}->can('classify_consolidated_signals'),
    'live SystemVerilog consolidated intermediate selection support no longer keeps initial AST-first keep/filter classification inline',
);
ok(
    $hdl->{backend_sv_consolidated_intermediate_selection_support}->can('filter_consolidated_signals'),
    'live SystemVerilog consolidated intermediate selection support owns dependency-aware rescue and final kept/filtered selection',
);
ok(
    $hdl->{backend_sv_consolidated_intermediate_assignment_support}->can('render_consolidated_intermediate_assignments'),
    'live SystemVerilog consolidated intermediate assignment support owns prepared assign emission',
);
ok(
    $hdl->{backend_sv_consolidated_intermediate_declaration_support}->can('render_consolidated_intermediate_declarations'),
    'live SystemVerilog consolidated intermediate declaration support owns prepared wire declaration rendering',
);
ok(
    $hdl->{backend_sv_consolidated_intermediate_dependency_support}->can('build_signal_dependencies'),
    'live SystemVerilog consolidated intermediate dependency support owns dependency-map construction',
);
ok(
    $hdl->{backend_sv_consolidated_intermediate_dependency_support}->can('topologically_sort_signals'),
    'live SystemVerilog consolidated intermediate dependency support owns dependency-safe ordering',
);
ok(
    $hdl->{backend_sv_consolidated_intermediate_planning_support}->can('plan_consolidated_intermediate_signals'),
    'live SystemVerilog consolidated intermediate planning support owns overall plan composition over selection and dependency owners',
);
ok(
    !$hdl->{backend_sv_consolidated_intermediate_planning_support}->can('build_signal_dependencies'),
    'live SystemVerilog consolidated intermediate planning support no longer keeps dependency-map construction inline',
);
ok(
    !$hdl->{backend_sv_consolidated_intermediate_planning_support}->can('topologically_sort_signals'),
    'live SystemVerilog consolidated intermediate planning support no longer keeps dependency-safe ordering inline',
);
ok(
    !$hdl->{backend_sv_consolidated_intermediate_planning_support}->can('filter_consolidated_signals'),
    'live SystemVerilog consolidated intermediate planning support no longer keeps keep/filter/rescue selection inline',
);
ok(
    $hdl->{backend_sv_consolidated_intermediate_prepared_block_support}->can('build_prepared_consolidated_intermediate_block'),
    'live SystemVerilog prepared block support owns prepared consolidated block-contract projection',
);
ok(
    !exists $hdl->{backend_sv_consolidated_intermediate_block_support},
    'live SystemVerilog backend no longer instantiates the consolidated block compatibility shell',
);
ok(
    $hdl->{backend_sv_consolidated_intermediate_generation_support}->can('generate_consolidated_intermediate_block'),
    'live SystemVerilog consolidated intermediate generation support owns the full direct stage handoff from collection and planning through final rendering',
);
ok(
    $hdl->{backend_sv_intermediate_recovery_support}->can('resolve_intermediate_signal_runtime_ast'),
    'live SystemVerilog intermediate recovery support owns runtime-AST lookup',
);
ok(
    $hdl->{backend_sv_intermediate_recovery_support}->can('render_intermediate_signal_expression'),
    'live SystemVerilog intermediate recovery support owns rendered-expression recovery',
);
ok(
    $hdl->{backend_sv_intermediate_recovery_support}->can('resolve_intermediate_signal_dependencies'),
    'live SystemVerilog intermediate recovery support owns dependency recovery',
);
ok(
    $hdl->{backend_sv_intermediate_width_support}->can('resolve_intermediate_signal_width'),
    'live SystemVerilog intermediate width support owns width normalization',
);
ok(
    $hdl->{backend_sv_intermediate_width_support}->can('infer_width_from_intermediate_ast'),
    'live SystemVerilog intermediate width support owns recursive width inference',
);
ok(
    !$hdl->{backend_sv_intermediate_recovery_support}->can('resolve_intermediate_signal_width'),
    'live SystemVerilog intermediate recovery support no longer keeps width normalization inline',
);
ok(
    $hdl->{backend_sv_intermediate_filter_policy_support}->can('should_filter_ast_based'),
    'live SystemVerilog intermediate filter-policy support owns AST-aware keep/filter heuristics',
);
ok(
    $hdl->{backend_sv_intermediate_filter_policy_support}->can('should_filter_runtime_ast_miss'),
    'live SystemVerilog intermediate filter-policy support owns runtime-AST-miss fallback heuristics',
);
ok(
    $hdl->{backend_sv_intermediate_filter_policy_support}->can('is_simple_negation'),
    'live SystemVerilog intermediate filter-policy support owns simple-negation shape checks',
);
ok(
    $hdl->{backend_sv_intermediate_filter_policy_support}->can('is_simple_comparison'),
    'live SystemVerilog intermediate filter-policy support owns simple-comparison shape checks',
);
ok(
    $hdl->{backend_sv_consolidated_intermediate_selection_support}->can('filter_consolidated_signals'),
    'live SystemVerilog consolidated intermediate selection support owns dependency-aware rescue and final kept/filtered selection',
);
ok(
    !exists $hdl->{backend_sv_intermediate_support},
    'live SystemVerilog backend no longer instantiates the compatibility intermediate dispatcher shell',
);
ok(
    !$hdl->{backend_sv_consolidated_intermediate}->can('topologically_sort_signals'),
    'live SystemVerilog consolidated intermediate emitter no longer keeps planning/order helpers inline',
);
ok(
    !$hdl->{backend_sv_consolidated_intermediate}->can('prepare_consolidated_intermediate_block'),
    'live SystemVerilog consolidated intermediate emitter no longer keeps collection-plus-planning handoff inline',
);
ok(
    !$hdl->{backend_sv_consolidated_intermediate}->can('render_consolidated_intermediate_declarations'),
    'live SystemVerilog consolidated intermediate emitter no longer keeps declaration rendering inline',
);
ok(
    !$hdl->{backend_sv_consolidated_intermediate}->can('generate_consolidated_intermediate_block'),
    'live SystemVerilog consolidated intermediate emitter no longer keeps full stage coordination inline',
);
ok(
    $hdl->{backend_sv_ast_factorization}->can('get_substituted_ast_for_signal'),
    'live SystemVerilog AST-factorization support keeps substituted-AST lookup for downstream owners',
);

ok(
    $hdl->{enable_graph_capture_support}->can('create_condition_expression'),
    'live EnableGraph capture support owns condition-stack AST normalization',
);
ok(
    $hdl->{enable_graph_capture_support}->can('register_assignment_capture'),
    'live EnableGraph capture support owns captured assignment registry writes',
);
ok(
    $hdl->{enable_graph_capture_support}->can('register_transition_capture'),
    'live EnableGraph capture support owns captured transition registry writes',
);
ok(
    $hdl->{enable_graph_capture_support}->can('extract_assignment_capture_metadata'),
    'live EnableGraph capture support owns assignment operator/intent normalization',
);
ok(
    $hdl->{enable_graph_capture_support}->can('capture_assignment_from_ast'),
    'live EnableGraph capture support owns AST assignment capture',
);
ok(
    $hdl->{enable_graph_capture_support}->can('capture_transition_from_ast'),
    'live EnableGraph capture support owns AST transition capture',
);
ok(
    $hdl->{enable_graph_capture_support}->can('convert_condition_to_ast'),
    'live EnableGraph capture support owns parsed-condition conversion to backend AST',
);
ok(
    $hdl->{enable_graph_capture_support}->can('convert_test_value_to_ast'),
    'live EnableGraph capture support owns parsed test-value conversion to backend AST',
);
ok(
    $hdl->{enable_graph_capture_support}->can('parse_test_value_selector'),
    'live EnableGraph capture support owns explicit test-selector parsing',
);
ok(
    $hdl->{enable_graph_capture_support}->can('build_test_condition_ast'),
    'live EnableGraph capture support owns test-node condition AST construction',
);
ok(
    $hdl->{enable_graph_capture_support}->can('extract_rhs_capture_value'),
    'live EnableGraph capture support owns capture-time RHS rendering',
);
ok(
    $hdl->{enable_graph_enable_support}->can('generate_enable_conditions'),
    'live EnableGraph enable support owns top-level state/DT enable emission',
);
ok(
    $hdl->{enable_graph_capture_support}->can('extract_signal_name_from_ast'),
    'live EnableGraph capture support owns AST signal-name extraction',
);
ok(
    $hdl->{enable_graph_enable_support}->can('generate_unified_wen_en_signals'),
    'live EnableGraph enable support owns unified WEN/EN emission',
);
ok(
    $hdl->{enable_graph_enable_support}->can('prescan_wen_en_for_intermediate_signals'),
    'live EnableGraph enable support owns WEN/EN intermediate-signal prescan',
);
ok(
    $hdl->{enable_graph_enable_support}->can('generate_dt_enables_from_analysis'),
    'live EnableGraph enable support owns DT-specific WEN/EN emission',
);
ok(
    $hdl->{enable_graph_enable_support}->can('generate_lhs_enables_from_analysis'),
    'live EnableGraph enable support owns grouped LHS-level WEN/EN emission',
);
ok(
    $hdl->{enable_graph_enable_support}->can('build_state_enable_condition_ast'),
    'live EnableGraph enable support owns regular-state enable AST construction',
);
ok(
    $hdl->{enable_graph_enable_support}->can('build_dt_enable_condition_ast'),
    'live EnableGraph enable support owns standalone-DT enable AST construction',
);
ok(
    $hdl->{enable_graph_enable_support}->can('initialize_state_and_dt_enable_conditions'),
    'live EnableGraph enable support owns top-level state/DT enable registry initialization',
);
ok(
    $hdl->{enable_graph_factorization_policy_support}->can('count_binary_logical_operation_occurrences'),
    'live EnableGraph factorization policy support owns binary logical-operation counting for factorization policy',
);
ok(
    $hdl->{enable_graph_factorization_policy_support}->can('collect_all_wen_en_ast_expressions'),
    'live EnableGraph factorization policy support owns first-pass AST collection',
);
ok(
    $hdl->{enable_graph_factorization_policy_support}->can('feed_asts_to_factorizer'),
    'live EnableGraph factorization policy support owns first-pass factorization AST feeding',
);
ok(
    $hdl->{enable_graph_factorization_policy_support}->can('feed_current_asts_to_second_pass'),
    'live EnableGraph factorization policy support owns second-pass factorization AST feeding',
);
ok(
    $hdl->{enable_graph_factorization_policy_support}->can('ast_contains_intermediate_signals'),
    'live EnableGraph factorization policy support owns second-pass intermediate-signal eligibility checks',
);
ok(
    $hdl->{enable_graph_factorization_policy_support}->can('ast_has_intermediate_signals_recursive'),
    'live EnableGraph factorization policy support owns recursive intermediate-signal subtree checks',
);
ok(
    $hdl->{enable_graph_factorization_support}->can('ast_contains_signal'),
    'live EnableGraph factorization support owns owner-side AST signal-reference inspection',
);
ok(
    $hdl->{enable_graph_factorization_support}->can('count_unary_negations_in_original_expressions'),
    'live EnableGraph factorization support owns substitution-era debug scans over owner-side AST structures',
);
ok(
    $hdl->{enable_graph_factorization_support}->can('is_signal_referenced_in_substitutions'),
    'live EnableGraph factorization support owns substituted-expression live-usage evidence',
);
ok(
    $hdl->{enable_graph_factorization_support}->can('is_signal_actually_used_in_final_expressions'),
    'live EnableGraph factorization support owns final-expression live-usage evidence',
);
ok(
    $hdl->{enable_graph_factorization_support}->can('resolve_intermediate_signal_live_usage'),
    'live EnableGraph factorization support owns cached live-usage metadata derivation',
);
ok(
    $hdl->{enable_graph_factorization_support}->can('update_original_asts_with_substituted_versions'),
    'live EnableGraph factorization support owns first-pass substitution synchronization into owner-side AST structures',
);
ok(
    $hdl->{enable_graph_factorization_support}->can('update_original_asts_with_second_pass_substitutions'),
    'live EnableGraph factorization support owns second-pass substitution synchronization into owner-side AST structures',
);
ok(
    $hdl->{enable_graph_factorization_policy_support}->can('contains_frequently_used_operations'),
    'live EnableGraph factorization policy support owns high-count logical-operation discovery for factorization policy',
);
ok(
    $hdl->{enable_graph_ast_support}->can('ast_to_systemverilog'),
    'live EnableGraph AST support owns AST-to-SystemVerilog rendering',
);
ok(
    $hdl->{enable_graph_ast_support}->can('ast_contains_factorizable_operators'),
    'live EnableGraph AST support owns factorizable-operator discovery',
);
ok(
    $hdl->{enable_graph_ast_support}->can('is_arithmetic_operation'),
    'live EnableGraph AST support owns arithmetic-operation classification',
);
ok(
    $hdl->{enable_graph_ast_support}->can('is_logical_operation'),
    'live EnableGraph AST support owns logical-operation classification',
);
ok(
    $hdl->{enable_graph_ast_support}->can('should_factor_logical_operation'),
    'live EnableGraph AST support owns logical factorization policy checks',
);
ok(
    $hdl->{enable_graph_signal_support}->can('set_fsm_module_reference'),
    'live EnableGraph signal support owns FSM-module reference attachment',
);
ok(
    $hdl->{enable_graph_signal_support}->can('extract_intermediate_signals_from_ast'),
    'live EnableGraph signal support owns direct intermediate-signal extraction from ASTs',
);
ok(
    $hdl->{enable_graph_signal_support}->can('get_reset_value_from_ast'),
    'live EnableGraph signal support owns AST-first reset-value lookup',
);
ok(
    $hdl->{enable_graph_signal_support}->can('get_default_value_from_ast'),
    'live EnableGraph signal support owns AST-first default-value lookup',
);
ok(
    $hdl->{enable_graph_signal_support}->can('is_intermediate_signal'),
    'live EnableGraph signal support owns intermediate-signal classification',
);
ok(
    $hdl->{enable_graph_signal_support}->can('clean_intermediate_expression'),
    'live EnableGraph signal support owns compatibility intermediate-expression cleanup',
);
ok(
    $hdl->{enable_graph_signal_support}->can('clean_signal_name'),
    'live EnableGraph signal support owns backend-safe signal-name cleanup',
);
ok(
    $hdl->{enable_graph_signal_support}->can('generate_rhs_based_enable_name'),
    'live EnableGraph signal support owns RHS-based enable naming',
);
ok(
    !$hdl->{enable_graph}->can('set_fsm_module_reference'),
    'live EnableGraph shell no longer owns FSM-module reference attachment directly',
);
ok(
    !$hdl->{enable_graph}->can('is_intermediate_signal'),
    'live EnableGraph shell no longer owns intermediate-signal classification directly',
);
ok(
    !$hdl->{enable_graph}->can('extract_intermediate_signals_from_ast'),
    'live EnableGraph shell no longer owns AST intermediate-dependency extraction directly',
);
ok(
    $hdl->{enable_graph_module_planning_support}->can('effective_system_contract'),
    'live EnableGraph module-planning support owns effective system-contract resolution',
);
ok(
    $hdl->{enable_graph_module_planning_support}->can('effective_clock_name'),
    'live EnableGraph module-planning support owns effective clock-name resolution',
);
ok(
    $hdl->{enable_graph_module_planning_support}->can('effective_reset_name'),
    'live EnableGraph module-planning support owns effective reset-name resolution',
);
ok(
    $hdl->{enable_graph_module_planning_support}->can('build_internal_signal_declaration_plan'),
    'live EnableGraph module-planning support owns internal declaration planning',
);
ok(
    $hdl->{enable_graph_module_planning_support}->can('build_module_declaration_plan'),
    'live EnableGraph module-planning support owns module declaration planning',
);
ok(
    $hdl->{enable_graph_module_planning_support}->can('build_state_register_plan'),
    'live EnableGraph module-planning support owns state register planning',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('build_unified_assignment_analysis'),
    'live EnableGraph assignment support owns assignment-analysis construction',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('group_assignments_by_rhs'),
    'live EnableGraph assignment support owns RHS grouping',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('generate_complete_enable_structure'),
    'live EnableGraph assignment support owns DT/LHS enable-family shaping',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('build_multiplexer_config'),
    'live EnableGraph assignment support owns mux-plan construction',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('generate_signal_assignments'),
    'live EnableGraph assignment support owns unified assignment HDL emission',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('generate_unified_flop_mux'),
    'live EnableGraph assignment support owns flop-backed mux emission',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('generate_unified_pulse_delay_logic'),
    'live EnableGraph assignment support owns delayed-pulse emission',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('generate_unified_comb_mux'),
    'live EnableGraph assignment support owns combinational mux emission',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('get_signal_assignment_type'),
    'live EnableGraph assignment support owns normalized assignment-family classification',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('get_driven_signals'),
    'live EnableGraph assignment support owns driven-signal discovery',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('get_pulse_active_level_for_lhs'),
    'live EnableGraph assignment support owns pulse active-level recovery',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('get_pulse_delay_cycles_for_lhs'),
    'live EnableGraph assignment support owns pulse delay-cycle recovery',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('normalize_rhs_logic_level'),
    'live EnableGraph assignment support owns pulse RHS logic normalization',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('get_signal_info'),
    'live EnableGraph assignment support owns signal metadata lookup for assignment planning',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('get_lhs_width_from_analysis'),
    'live EnableGraph assignment support owns width recovery for assignment planning',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('get_reset_value'),
    'live EnableGraph assignment support owns reset-value recovery for assignment planning',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('get_default_value'),
    'live EnableGraph assignment support owns default-value recovery for assignment planning',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('get_fsm_reset_state'),
    'live EnableGraph assignment support owns FSM reset-state recovery for assignment planning',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('get_explicit_reset_value'),
    'live EnableGraph assignment support owns explicit reset-value lookup',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('is_register'),
    'live EnableGraph assignment support owns register-versus-combinational classification',
);
ok(
    $hdl->{enable_graph_assignment_support}->can('fallback_register_analysis_from_assignments'),
    'live EnableGraph assignment support owns fallback assignment-operator register analysis',
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
        count_binary_logical_operation_occurrences
        collect_all_wen_en_ast_expressions
        get_intermediate_signal_ast
        get_intermediate_signal_expression
        build_dependency_recovery_ast_from_signal_name
        track_ast_intermediate_signals
        create_condition_expression_signal_name
        feed_asts_to_factorizer
        feed_current_asts_to_second_pass
        get_or_create_ast_signal_name
        get_or_create_global_expression
        is_complex_ast
        ast_contains_intermediate_signals
        ast_has_intermediate_signals_recursive
        ast_contains_signal
        count_unary_negations_in_original_expressions
        is_signal_referenced_in_substitutions
        is_signal_actually_used_in_final_expressions
        resolve_intermediate_signal_live_usage
        effective_system_contract
        effective_clock_name
        effective_reset_name
        build_internal_signal_declaration_plan
        build_module_declaration_plan
        build_state_register_plan
        create_condition_expression
        register_assignment_capture
        register_transition_capture
        extract_assignment_capture_metadata
        capture_assignment_from_ast
        capture_transition_from_ast
        parse_test_value_selector
        build_test_condition_ast
        extract_rhs_capture_value
        generate_enable_conditions
        generate_unified_wen_en_signals
        prescan_wen_en_for_intermediate_signals
        generate_dt_enables_from_analysis
        generate_lhs_enables_from_analysis
        build_state_enable_condition_ast
        build_dt_enable_condition_ast
        initialize_state_and_dt_enable_conditions
        build_unified_assignment_analysis
        group_assignments_by_rhs
        generate_complete_enable_structure
        build_multiplexer_config
        generate_signal_assignments
        generate_unified_flop_mux
        generate_unified_pulse_delay_logic
        generate_unified_comb_mux
        get_signal_assignment_type
        get_driven_signals
        get_pulse_active_level_for_lhs
        get_pulse_delay_cycles_for_lhs
        normalize_rhs_logic_level
        get_signal_info
        get_lhs_width_from_analysis
        get_reset_value
        get_default_value
        get_fsm_reset_state
        get_explicit_reset_value
        is_register
        fallback_register_analysis_from_assignments
        update_original_asts_with_substituted_versions
        update_original_asts_with_second_pass_substitutions
        contains_frequently_used_operations
        needs_parentheses
        _get_intermediate_signal_registry_entry
        _register_intermediate_signal_registry_entry
        _get_native_intermediate_signal_ast
        _count_logical_ops_in_ast
        _is_factorizable_sub_expression
        _ast_contains_frequently_used_logical_operation
        _build_context_to_ast_map
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

for my $dead_enable_graph_capture_helper (
    qw(
        count_binary_logical_operation_occurrences
        collect_all_wen_en_ast_expressions
        effective_system_contract
        effective_clock_name
        effective_reset_name
        build_internal_signal_declaration_plan
        build_module_declaration_plan
        build_state_register_plan
        build_unified_assignment_analysis
        group_assignments_by_rhs
        generate_complete_enable_structure
        build_multiplexer_config
        generate_signal_assignments
        generate_unified_flop_mux
        generate_unified_pulse_delay_logic
        generate_unified_comb_mux
        get_signal_assignment_type
        get_driven_signals
        get_pulse_active_level_for_lhs
        get_pulse_delay_cycles_for_lhs
        normalize_rhs_logic_level
        get_signal_info
        get_lhs_width_from_analysis
        get_reset_value
        get_default_value
        get_fsm_reset_state
        get_explicit_reset_value
        is_register
        fallback_register_analysis_from_assignments
        get_intermediate_signal_ast
        get_intermediate_signal_expression
        build_dependency_recovery_ast_from_signal_name
        track_ast_intermediate_signals
        contains_frequently_used_operations
        update_original_asts_with_substituted_versions
        update_original_asts_with_second_pass_substitutions
        generate_enable_conditions
        generate_unified_wen_en_signals
        prescan_wen_en_for_intermediate_signals
        generate_dt_enables_from_analysis
        generate_lhs_enables_from_analysis
        build_state_enable_condition_ast
        build_dt_enable_condition_ast
        initialize_state_and_dt_enable_conditions
    )
) {
    ok(
        !$hdl->{enable_graph_capture_support}->can($dead_enable_graph_capture_helper),
        "live EnableGraph capture support no longer exposes unrelated helper '$dead_enable_graph_capture_helper'",
    );
}

for my $dead_enable_graph_enable_helper (
    qw(
        count_binary_logical_operation_occurrences
        collect_all_wen_en_ast_expressions
        effective_system_contract
        effective_clock_name
        effective_reset_name
        build_internal_signal_declaration_plan
        build_module_declaration_plan
        build_state_register_plan
        build_unified_assignment_analysis
        group_assignments_by_rhs
        generate_complete_enable_structure
        build_multiplexer_config
        generate_signal_assignments
        generate_unified_flop_mux
        generate_unified_pulse_delay_logic
        generate_unified_comb_mux
        get_signal_assignment_type
        get_driven_signals
        get_pulse_active_level_for_lhs
        get_pulse_delay_cycles_for_lhs
        normalize_rhs_logic_level
        get_signal_info
        get_lhs_width_from_analysis
        get_reset_value
        get_default_value
        get_fsm_reset_state
        get_explicit_reset_value
        is_register
        fallback_register_analysis_from_assignments
        get_intermediate_signal_ast
        get_intermediate_signal_expression
        build_dependency_recovery_ast_from_signal_name
        track_ast_intermediate_signals
        contains_frequently_used_operations
        update_original_asts_with_substituted_versions
        update_original_asts_with_second_pass_substitutions
    )
) {
    ok(
        !$hdl->{enable_graph_enable_support}->can($dead_enable_graph_enable_helper),
        "live EnableGraph enable support no longer exposes unrelated helper '$dead_enable_graph_enable_helper'",
    );
}

for my $dead_enable_graph_assignment_helper (
    qw(
        count_binary_logical_operation_occurrences
        collect_all_wen_en_ast_expressions
        effective_system_contract
        effective_clock_name
        effective_reset_name
        build_internal_signal_declaration_plan
        build_module_declaration_plan
        build_state_register_plan
        get_intermediate_signal_ast
        get_intermediate_signal_expression
        build_dependency_recovery_ast_from_signal_name
        track_ast_intermediate_signals
        contains_frequently_used_operations
        update_original_asts_with_substituted_versions
        update_original_asts_with_second_pass_substitutions
    )
) {
    ok(
        !$hdl->{enable_graph_assignment_support}->can($dead_enable_graph_assignment_helper),
        "live EnableGraph assignment support no longer exposes unrelated helper '$dead_enable_graph_assignment_helper'",
    );
}

for my $dead_enable_graph_factorization_helper (
    qw(
        analyze_ast_complexity
        canonicalize_expression
        create_condition_expression_signal_name
        count_binary_logical_operation_occurrences
        collect_all_wen_en_ast_expressions
        feed_asts_to_factorizer
        feed_current_asts_to_second_pass
        get_or_create_ast_signal_name
        get_or_create_global_expression
        is_complex_ast
        needs_parentheses
        ast_contains_intermediate_signals
        ast_has_intermediate_signals_recursive
        should_factor_ast
        should_factor_condition
        signal_uses_register_assignment
        set_explicit_reset_values
        parentheses_are_redundant
        contains_frequently_used_operations
        _count_logical_ops_in_ast
        _is_factorizable_sub_expression
        _traverse_ast_for_complexity
        generate_expression_from_signal_name
    )
) {
    ok(
        !$hdl->{enable_graph_factorization_support}->can($dead_enable_graph_factorization_helper),
        "live EnableGraph factorization support no longer exposes dead helper '$dead_enable_graph_factorization_helper'",
    );
}

for my $dead_enable_graph_factorization_policy_helper (
    qw(
        ast_contains_signal
        count_unary_negations_in_original_expressions
        is_signal_referenced_in_substitutions
        is_signal_actually_used_in_final_expressions
        resolve_intermediate_signal_live_usage
        update_original_asts_with_substituted_versions
        update_original_asts_with_second_pass_substitutions
    )
) {
    ok(
        !$hdl->{enable_graph_factorization_policy_support}->can($dead_enable_graph_factorization_policy_helper),
        "live EnableGraph factorization policy support no longer exposes unrelated helper '$dead_enable_graph_factorization_policy_helper'",
    );
}

for my $dead_enable_graph_module_planning_helper (
    qw(
        analyze_ast_complexity
        canonicalize_expression
        count_binary_logical_operation_occurrences
        collect_all_wen_en_ast_expressions
        get_intermediate_signal_ast
        get_intermediate_signal_expression
        build_dependency_recovery_ast_from_signal_name
        track_ast_intermediate_signals
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
        contains_frequently_used_operations
        get_signal_assignment_type
        get_lhs_width_from_analysis
        get_pulse_delay_cycles_for_lhs
        get_driven_signals
    )
) {
    ok(
        !$hdl->{enable_graph_module_planning_support}->can($dead_enable_graph_module_planning_helper),
        "live EnableGraph module-planning support no longer exposes unrelated helper '$dead_enable_graph_module_planning_helper'",
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
