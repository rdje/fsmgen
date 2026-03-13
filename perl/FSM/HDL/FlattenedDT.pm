#!/usr/bin/perl

package FSM::HDL::FlattenedDT;
use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin";
use FSM::Debug;  # Global debug system
use FSM::ExpressionNamer;
use FSM::Synthesis::EnableGraph;
use FSM::HDL::FlattenedDT::Orchestrator;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog;
use FSM::HDL::FlattenedDT::Backend::Verilog;

=head1 NAME

FSM::HDL::FlattenedDT - Flattened Decision Tree SystemVerilog Generator

=head1 DESCRIPTION

This module implements a sophisticated HDL generation approach that flattens
decision trees into enable-based logic with write enables (WENs) and enables (ENs).

Key features:
- Flattens entire FSM/DT hierarchy
- Uses concurrent assignments (assign) instead of procedural blocks  
- Generates WEN/EN signals for each LHS
- Allows sub-DT sharing between states
- Creates flat Boolean expressions from DT traversal

=cut

sub new ($class, %args) {
    my $debug_mode = $args{debug} // 0;
    
    my $self = bless {
        debug => $debug_mode,
        # Storage for flattened analysis
        state_enables => {},      # state_name => enable_condition
        dt_enables => {},         # dt_name => enable_condition  
        lhs_assignments => {},    # lhs_name => [ {dt, conditions, rhs, is_state_trans}, ... ]
        intermediate_signals => {},# signal_name => metadata hash; avoid raw string entries
        all_lhs => {},           # Track all LHS signals across all DTs
        reset_assignments => {},  # LHS that need reset handling
        expr_namer => FSM::ExpressionNamer->new(debug => $debug_mode),  # Expression parser and namer with debug
        # Global expression factoring for cross-DT reuse
        global_expressions => {}, # canonical_expr => signal_name (for reuse)
        expression_usage => {},   # signal_name => usage_count (for optimization)
        factorization_fixpoint_max_passes => $args{factorization_fixpoint_max_passes} // 16,
        
        # UNIFIED PHASE 1 DATA STRUCTURES - Complete assignment analysis
        assignment_analysis => {},  # The unified data structure for all assignment info
        # Structure: {
        #   lhs_signal => {
        #     assignments => [ { dt, conditions, rhs, operator, is_state_trans }, ... ],
        #     rhs_groups => {
        #       rhs_value => {
        #         assignments => [ assignment_refs... ],
        #         dt_specific_enables => [ { dt, enable_name, enable_expr, shared_signal }, ... ],
        #         lhs_level_enable => { name, expr, rhs_value },
        #         multiplexer_info => { enable_signal, rhs_value, priority }
        #       }, ...
        #     },
        #     signal_info => { width, is_flop, reset_value, default_value },
        #     multiplexer => {
        #       type => 'flop'|'comb',
        #       enables => [ { enable_signal, rhs_value, priority }, ... ],
        #       default_value => ...
        #     }
        #   }, ...
        # }
    }, $class;
    
    # Initial extraction slice: dedicated enable synthesis/orchestration layer.
    $self->{enable_graph} = FSM::Synthesis::EnableGraph->new(flattened_dt => $self);
    $self->{orchestrator} = FSM::HDL::FlattenedDT::Orchestrator->new(flattened_dt => $self);
    $self->{backend_sv} = FSM::HDL::FlattenedDT::Backend::SystemVerilog->new(flattened_dt => $self);
    $self->{backend_verilog} = FSM::HDL::FlattenedDT::Backend::Verilog->new(flattened_dt => $self);
    
    return $self;
}


sub generate_systemverilog ($self, $fsm_module) {
    return $self->{orchestrator}->generate_systemverilog($fsm_module);
}

sub generate_verilog ($self, $fsm_module) {
    return $self->{backend_verilog}->generate_verilog($fsm_module);
}

sub convert_systemverilog_to_verilog ($self, $sv_hdl) {
    return $self->{backend_verilog}->convert_systemverilog_to_verilog($sv_hdl);
}

sub generate_vhdl ($self, $fsm_module) {
    die "[FlattenedDT.pm][generate_vhdl()] VHDL backend is not implemented yet. Use --language systemverilog or --language verilog.\n";
}

sub generate_internal_signal_declarations ($self, $fsm_module) {
    return $self->{backend_sv}->generate_internal_signal_declarations($fsm_module);
}

sub get_lhs_width_from_analysis ($self, $lhs_analysis) {
    return $self->{enable_graph}->get_lhs_width_from_analysis($lhs_analysis);
}

sub flatten_all_decision_trees ($self, $fsm_module) {
    return $self->{orchestrator}->flatten_all_decision_trees($fsm_module);
}

sub is_register ($self, $lhs_signal_ast, $lhs_name_for_debug) {
    return $self->{enable_graph}->is_register($lhs_signal_ast, $lhs_name_for_debug);
}

sub fallback_register_analysis_from_assignments ($self, $lhs_name) {
    return $self->{enable_graph}->fallback_register_analysis_from_assignments($lhs_name);
}
sub extract_lhs_name_from_ast ($self, $lhs_ast) {
    return $self->{orchestrator}->extract_lhs_name_from_ast($lhs_ast);
}

sub flatten_decision_tree ($self, $dt_name, $dt_node, $condition_stack) {
    return $self->{orchestrator}->flatten_decision_tree($dt_name, $dt_node, $condition_stack);
}

sub generate_ast_based_signal_name ($self, $ast) {
    return $self->{enable_graph}->generate_ast_based_signal_name($ast);
}

sub extract_signal_name_from_ast ($self, $signal_ast) {
    return $self->{enable_graph}->extract_signal_name_from_ast($signal_ast);
}

sub map_operator_to_name ($self, $operator) {
    return $self->{enable_graph}->map_operator_to_name($operator);
}

sub generate_header ($self, $fsm_module) {
    return $self->{backend_sv}->generate_header($fsm_module);
}

sub generate_module_declaration ($self, $fsm_module) {
    return $self->{backend_sv}->generate_module_declaration($fsm_module);
}


sub generate_state_encoding ($self, $fsm_module) {
    return $self->{backend_sv}->generate_state_encoding($fsm_module);
}

sub generate_state_register ($self, $fsm_module) {
    return $self->{backend_sv}->generate_state_register($fsm_module);
}

sub generate_enable_conditions ($self, $fsm_module) {
    return $self->{backend_sv}->generate_enable_conditions($fsm_module);
}

sub generate_consolidated_intermediate_signals ($self, $fsm_module) {
    return $self->{backend_sv}->generate_consolidated_intermediate_signals($fsm_module);
}


sub generate_intermediate_signals ($self, $fsm_module) {
    return $self->{backend_sv}->generate_intermediate_signals($fsm_module);
}

sub is_arithmetic_operation ($self, $ast) {
    return $self->{enable_graph}->is_arithmetic_operation($ast);
}

sub is_logical_operation ($self, $ast) {
    return $self->{enable_graph}->is_logical_operation($ast);
}

sub should_factor_logical_operation ($self, $ast) {
    return $self->{enable_graph}->should_factor_logical_operation($ast);
}

sub contains_frequently_used_operations ($self, $ast) {
    return $self->{enable_graph}->contains_frequently_used_operations($ast);
}

sub generate_wen_en_signals ($self, $fsm_module) {
    return $self->{backend_sv}->generate_wen_en_signals($fsm_module);
}

sub get_pulse_delay_cycles_for_lhs ($self, $lhs, $lhs_analysis) {
    return $self->{enable_graph}->get_pulse_delay_cycles_for_lhs($lhs, $lhs_analysis);
}

sub get_pulse_active_level_for_lhs ($self, $lhs, $lhs_analysis) {
    return $self->{enable_graph}->get_pulse_active_level_for_lhs($lhs, $lhs_analysis);
}

sub normalize_rhs_logic_level ($self, $rhs) {
    return $self->{enable_graph}->normalize_rhs_logic_level($rhs);
}

sub get_signal_assignment_type ($self, $lhs, $lhs_analysis) {
    return $self->{enable_graph}->get_signal_assignment_type($lhs, $lhs_analysis);
}

sub get_driven_signals ($self) {
    return $self->{enable_graph}->get_driven_signals();
}

sub get_reset_value ($self, $lhs) {
    return $self->{enable_graph}->get_reset_value($lhs);
}

sub get_fsm_reset_state ($self) {
    return $self->{enable_graph}->get_fsm_reset_state();
}

sub get_explicit_reset_value ($self, $lhs) {
    return $self->{enable_graph}->get_explicit_reset_value($lhs);
}

sub get_signal_info ($self, $lhs) {
    return $self->{enable_graph}->get_signal_info($lhs);
}

sub set_fsm_module_reference ($self, $fsm_module) {
    return $self->{enable_graph}->set_fsm_module_reference($fsm_module);
}

sub get_default_value_from_ast ($self, $lhs_ast) {
    return $self->{enable_graph}->get_default_value_from_ast($lhs_ast);
}

sub get_reset_value_from_ast ($self, $lhs_ast) {
    return $self->{enable_graph}->get_reset_value_from_ast($lhs_ast);
}

sub get_default_value ($self, $lhs) {
    return $self->{enable_graph}->get_default_value($lhs);
}

sub record_assignment_from_ast ($self, $dt_name, $assignment_node, $condition_stack) {
    return $self->{orchestrator}->record_assignment_from_ast($dt_name, $assignment_node, $condition_stack);
}

sub record_transition_from_ast ($self, $dt_name, $transition_node, $condition_stack) {
    return $self->{orchestrator}->record_transition_from_ast($dt_name, $transition_node, $condition_stack);
}

sub extract_rhs_from_expression ($self, $expr) {
    return $self->{orchestrator}->extract_rhs_from_expression($expr);
}

sub clean_intermediate_expression ($self, $expression) {
    return $self->{enable_graph}->clean_intermediate_expression($expression);
}

# New AST-based methods for pure AST processing

sub convert_condition_to_ast ($self, $condition_node) {
    return $self->{enable_graph}->convert_condition_to_ast($condition_node);
}

sub convert_test_value_to_ast ($self, $test_value) {
    return $self->{enable_graph}->convert_test_value_to_ast($test_value);
}

# Methods for tracking intermediate signals and dependencies

sub track_ast_intermediate_signals ($self, $ast) {
    return $self->{enable_graph}->track_ast_intermediate_signals($ast);
}

sub is_intermediate_signal ($self, $signal_name) {
    return $self->{enable_graph}->is_intermediate_signal($signal_name);
}

sub is_signal_ast_based_intermediate ($self, $signal_name) {
    return $self->{enable_graph}->is_signal_ast_based_intermediate($signal_name);
}

sub _ast_contains_factorizable_operators ($self, $ast) {
    return $self->{enable_graph}->_ast_contains_factorizable_operators($ast);
}

sub _signal_name_indicates_ast_operators ($self, $signal_name) {
    return $self->{enable_graph}->_signal_name_indicates_ast_operators($signal_name);
}

sub ast_to_systemverilog ($self, $ast) {
    return $self->{enable_graph}->ast_to_systemverilog($ast);
}

sub _ast_to_systemverilog_internal ($self, $ast, $parent_precedence) {
    return $self->{enable_graph}->_ast_to_systemverilog_internal($ast, $parent_precedence);
}

sub _render_binary_op ($self, $ast, $parent_precedence) {
    return $self->{enable_graph}->_render_binary_op($ast, $parent_precedence);
}

sub _render_unary_op ($self, $ast) {
    return $self->{enable_graph}->_render_unary_op($ast);
}

sub _choose_operator_symbol ($self, $operator, $left, $right) {
    return $self->{enable_graph}->_choose_operator_symbol($operator, $left, $right);
}

sub _operand_is_single_bit ($self, $ast) {
    return $self->{enable_graph}->_operand_is_single_bit($ast);
}

sub _signal_is_single_bit ($self, $name) {
    return $self->{enable_graph}->_signal_is_single_bit($name);
}

sub _get_operator_precedence ($self, $operator) {
    return $self->{enable_graph}->_get_operator_precedence($operator);
}

sub _needs_parentheses ($self, $my_precedence, $parent_precedence) {
    return $self->{enable_graph}->_needs_parentheses($my_precedence, $parent_precedence);
}

sub _map_binary_operator ($self, $operator) {
    return $self->{enable_graph}->_map_binary_operator($operator);
}

sub _map_unary_operator ($self, $operator) {
    return $self->{enable_graph}->_map_unary_operator($operator);
}

sub _operand_needs_parens_for_negation ($self, $operand) {
    return $self->{enable_graph}->_operand_needs_parens_for_negation($operand);
}

sub get_intermediate_signal_expression ($self, $signal_name) {
    return $self->{enable_graph}->get_intermediate_signal_expression($signal_name);
}

=head2 feed_asts_to_factorizer($factorizer)

Feed all AST expressions to the generic factorizer.
This replaces the broken string-based collection with pure AST feeding.

=cut

sub prescan_wen_en_for_intermediate_signals ($self) {
    return $self->{backend_sv}->prescan_wen_en_for_intermediate_signals();
}

sub feed_asts_to_factorizer ($self, $factorizer) {
    return $self->{backend_sv}->feed_asts_to_factorizer($factorizer);
}

sub count_unary_negations_in_original_expressions {
    my ($self) = @_;
    return $self->{backend_sv}->count_unary_negations_in_original_expressions();
}

sub ast_contains_signal ($self, $ast, $signal_name) {
    return $self->{backend_sv}->ast_contains_signal($ast, $signal_name);
}

sub update_original_asts_with_substituted_versions ($self, $factorizer) {
    return $self->{backend_sv}->update_original_asts_with_substituted_versions($factorizer);
}

sub run_second_pass_factorization ($self, $factorizer) {
    return $self->{backend_sv}->run_second_pass_factorization($factorizer);
}

sub feed_current_asts_to_second_pass ($self, $second_pass_factorizer) {
    return $self->{backend_sv}->feed_current_asts_to_second_pass($second_pass_factorizer);
}

sub ast_contains_intermediate_signals ($self, $ast) {
    return $self->{backend_sv}->ast_contains_intermediate_signals($ast);
}

sub ast_has_intermediate_signals_recursive ($self, $ast) {
    return $self->{backend_sv}->ast_has_intermediate_signals_recursive($ast);
}

sub update_original_asts_with_second_pass_substitutions ($self, $second_pass_factorizer) {
    return $self->{backend_sv}->update_original_asts_with_second_pass_substitutions($second_pass_factorizer);
}

sub get_substituted_ast_for_signal ($self, $signal_name, $signal_info) {
    return $self->{backend_sv}->get_substituted_ast_for_signal($signal_name, $signal_info);
}

sub is_signal_referenced_in_substitutions ($self, $signal_name) {
    return $self->{backend_sv}->is_signal_referenced_in_substitutions($signal_name);
}

sub topologically_sort_signals {
    my ($self, $filtered_signals, $signal_dependencies) = @_;
    return $self->{backend_sv}->topologically_sort_signals($filtered_signals, $signal_dependencies);
}

1;
