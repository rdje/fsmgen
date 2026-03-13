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
use FSM::GlobalASTManager;
use FSM::AST::Node;
use FSM::CoreAST;  # Core AST classes with SignalRef->name() method
use FSM::Synthesis::EnableGraph;
use FSM::HDL::FlattenedDT::Orchestrator;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog;
use FSM::HDL::FlattenedDT::Backend::Verilog;
use Data::Dumper;
use Scalar::Util qw(blessed);
use List::Util qw(min max);

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

sub build_unified_assignment_analysis ($self, $fsm_module) {
    return $self->{enable_graph}->build_unified_assignment_analysis($fsm_module);
}

sub get_signal_ast_node ($self, $lhs_name) {
    # Get the signal AST node - single source of truth for all signal properties
    # Uses the stored FSM module reference from the AST web
    # Returns the signal AST node or undef if not found
    
    if ($self->{fsm_module} && $self->{fsm_module}->signals && $self->{fsm_module}->signals->{$lhs_name}) {
        return $self->{fsm_module}->signals->{$lhs_name};
    }
    
    fsm_debug("  WARNING: No signal AST node found for '$lhs_name'", 3);
    return undef;
}

sub is_register ($self, $lhs_signal_ast, $lhs_name_for_debug) {
    return $self->{enable_graph}->is_register($lhs_signal_ast, $lhs_name_for_debug);
}

sub fallback_register_analysis_from_assignments ($self, $lhs_name) {
    return $self->{enable_graph}->fallback_register_analysis_from_assignments($lhs_name);
}

sub group_assignments_by_rhs ($self, $lhs) {
    return $self->{enable_graph}->group_assignments_by_rhs($lhs);
}

sub generate_complete_enable_structure ($self, $lhs) {
    return $self->{enable_graph}->generate_complete_enable_structure($lhs);
}

sub build_multiplexer_config ($self, $lhs) {
    return $self->{enable_graph}->build_multiplexer_config($lhs);
}
sub extract_lhs_name_from_ast ($self, $lhs_ast) {
    return $self->{orchestrator}->extract_lhs_name_from_ast($lhs_ast);
}

sub flatten_decision_tree ($self, $dt_name, $dt_node, $condition_stack) {
    return $self->{orchestrator}->flatten_decision_tree($dt_name, $dt_node, $condition_stack);
}

sub create_condition_expression_signal_name ($self, $condition_stack) {
    return $self->{enable_graph}->create_condition_expression_signal_name($condition_stack);
}

sub get_or_create_ast_signal_name ($self, $ast) {
    return $self->{enable_graph}->get_or_create_ast_signal_name($ast);
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

sub run_global_ast_factorization ($self) {
    return $self->{backend_sv}->run_global_ast_factorization();
}

sub collect_all_wen_en_ast_expressions ($self) {
    return $self->{backend_sv}->collect_all_wen_en_ast_expressions();
}

sub analyze_ast_sub_expressions ($self, $ast_expressions) {
    return $self->{backend_sv}->analyze_ast_sub_expressions($ast_expressions);
}

sub find_all_ast_sub_expressions ($self, $ast) {
    return $self->{backend_sv}->find_all_ast_sub_expressions($ast);
}

sub count_binary_logical_operation_occurrences ($self) {
    return $self->{backend_sv}->count_binary_logical_operation_occurrences();
}

sub _count_logical_ops_in_ast ($self, $ast, $counts_ref) {
    return $self->{backend_sv}->_count_logical_ops_in_ast($ast, $counts_ref);
}

sub _is_factorizable_sub_expression ($self, $ast) {
    return $self->{backend_sv}->_is_factorizable_sub_expression($ast);
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

sub is_simple_ast_expression ($self, $ast) {
    return $self->{backend_sv}->is_simple_ast_expression($ast);
}


sub generate_wen_en_signals ($self, $fsm_module) {
    return $self->{backend_sv}->generate_wen_en_signals($fsm_module);
}

sub generate_unified_wen_en_signals ($self, $fsm_module) {
    return $self->{enable_graph}->generate_unified_wen_en_signals($fsm_module);
}

sub generate_dt_enables_from_analysis ($self) {
    return $self->{enable_graph}->generate_dt_enables_from_analysis();
}

sub generate_lhs_enables_from_analysis ($self) {
    return $self->{enable_graph}->generate_lhs_enables_from_analysis();
}

sub generate_signal_assignments ($self, $fsm_module) {
    return $self->{enable_graph}->generate_signal_assignments($fsm_module);
}

sub generate_unified_flop_mux ($self, $lhs, $lhs_analysis) {
    return $self->{enable_graph}->generate_unified_flop_mux($lhs, $lhs_analysis);
}

sub generate_unified_pulse_delay_logic ($self, $lhs, $lhs_analysis) {
    return $self->{enable_graph}->generate_unified_pulse_delay_logic($lhs, $lhs_analysis);
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

sub signal_uses_register_assignment ($self, $lhs, $lhs_analysis) {
    return $self->{enable_graph}->signal_uses_register_assignment($lhs, $lhs_analysis);
}

sub get_signal_assignment_type ($self, $lhs, $lhs_analysis) {
    return $self->{enable_graph}->get_signal_assignment_type($lhs, $lhs_analysis);
}

sub generate_unified_comb_mux ($self, $lhs, $lhs_analysis) {
    return $self->{enable_graph}->generate_unified_comb_mux($lhs, $lhs_analysis);
}

sub generate_flop_mux ($self, $lhs, $clean_lhs) {
    return $self->{backend_sv}->generate_flop_mux($lhs, $clean_lhs);
}

sub generate_comb_mux ($self, $lhs, $clean_lhs) {
    return $self->{backend_sv}->generate_comb_mux($lhs, $clean_lhs);
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

sub set_explicit_reset_values ($self, $reset_values) {
    return $self->{enable_graph}->set_explicit_reset_values($reset_values);
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

sub is_complex_ast ($self, $ast) {
    return $self->{enable_graph}->is_complex_ast($ast);
}

sub canonicalize_expression ($self, $expression) {
    return $self->{enable_graph}->canonicalize_expression($expression);
}

sub should_factor_ast ($self, $ast) {
    return $self->{enable_graph}->should_factor_ast($ast);
}

sub analyze_ast_complexity ($self, $ast) {
    return $self->{enable_graph}->analyze_ast_complexity($ast);
}

sub _traverse_ast_for_complexity ($self, $node, $result, $current_depth) {
    return $self->{enable_graph}->_traverse_ast_for_complexity($node, $result, $current_depth);
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

sub parentheses_are_redundant ($self, $inner_expr) {
    return $self->{enable_graph}->parentheses_are_redundant($inner_expr);
}

sub get_intermediate_signal_expression ($self, $signal_name) {
    return $self->{enable_graph}->get_intermediate_signal_expression($signal_name);
}

sub generate_expression_from_signal_name ($self, $signal_name) {
    return $self->{enable_graph}->generate_expression_from_signal_name($signal_name);
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

sub should_filter_consolidated_signal ($self, $expression, $signal_name, $signal_info) {
    return $self->{backend_sv}->should_filter_consolidated_signal($expression, $signal_name, $signal_info);
}

sub should_filter_ast_based ($self, $ast, $signal_name, $signal_info) {
    return $self->{backend_sv}->should_filter_ast_based($ast, $signal_name, $signal_info);
}

sub is_simple_negation ($self, $ast) {
    return $self->{backend_sv}->is_simple_negation($ast);
}

sub is_simple_comparison ($self, $ast) {
    return $self->{backend_sv}->is_simple_comparison($ast);
}

sub is_signal_actually_used_in_final_expressions ($self, $signal_name) {
    return $self->{backend_sv}->is_signal_actually_used_in_final_expressions($signal_name);
}

sub ast_contains_signal ($self, $ast, $signal_name) {
    return $self->{backend_sv}->ast_contains_signal($ast, $signal_name);
}

sub signal_name_matches_operation ($self, $signal_name, $op_signature) {
    # Heuristic to check if a signal name matches a logical operation signature
    # This is used to correlate intermediate signal patterns with actual repeated operations
    
    fsm_debug("SIGNAL_OP_MATCH: Checking if '$signal_name' matches operation '$op_signature'", 3);
    
    # Extract signal names from the operation signature
    my @signal_parts = ();
    while ($op_signature =~ /([a-zA-Z_][a-zA-Z0-9_]*)/g) {
        push @signal_parts, $1;
    }
    
    # Check if the signal name contains references to the signals in the operation
    my $matches = 0;
    for my $part (@signal_parts) {
        if ($signal_name =~ /\b$part\b/) {
            $matches++;
            fsm_debug("  Found signal part '$part' in signal name", 3);
        }
    }
    
    # Also check for operator patterns in the signal name
    if ($op_signature =~ /&&/) {
        $matches++ if $signal_name =~ /_and_/;
    }
    if ($op_signature =~ /\|\|/) {
        $matches++ if $signal_name =~ /_or_/;
    }
    
    my $result = $matches >= 2;  # Need at least 2 matches to be confident
    fsm_debug("SIGNAL_OP_MATCH: '$signal_name' vs '$op_signature' -> $matches matches -> $result", 3);
    
    return $result;
}

sub update_original_asts_with_substituted_versions ($self, $factorizer) {
    return $self->{backend_sv}->update_original_asts_with_substituted_versions($factorizer);
}

sub find_substituted_ast ($self, $original_ast, $ast_expressions) {
    # Find the substituted version of an AST in the factorizer's expression list
    # This matches ASTs by their canonical SystemVerilog representation
    
    return $original_ast unless $original_ast && blessed($original_ast);
    return $original_ast unless $ast_expressions && @$ast_expressions;
    
    # Get canonical representation of the original AST
    my $original_canonical = eval { $self->ast_to_systemverilog($original_ast) };
    return $original_ast unless $original_canonical;
    
    # Search for matching AST in the factorizer's expression list
    for my $expr_info (@$ast_expressions) {
        my $factorizer_ast = $expr_info->{ast};
        next unless $factorizer_ast && blessed($factorizer_ast);
        
        my $factorizer_canonical = eval { $self->ast_to_systemverilog($factorizer_ast) };
        next unless $factorizer_canonical;
        
        # If the canonical representations match, this might be our substituted version
        if ($factorizer_canonical eq $original_canonical) {
            # Additional check: if the factorizer AST is different object (substituted)
            if ($factorizer_ast != $original_ast) {
                fsm_debug("  FOUND_SUBSTITUTED: Matched AST for expression '$original_canonical'", 3);
                return $factorizer_ast;
            }
        }
    }
    
    # If no substituted version found, return the original
    return $original_ast;
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

sub ast_contains_intermediate_signal_references ($self, $ast) {
    # Check if an AST contains references to intermediate signals
    # This indicates that AST substitution has occurred
    
    return 0 unless $ast && blessed($ast);
    
    # Check if this node is itself an intermediate signal reference
    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        return 1;
    }
    
    # Check if this is a substituted node type
    if ($ast->isa('FSM::HDL::SubstitutedBinaryOp') || $ast->isa('FSM::HDL::SubstitutedUnaryOp')) {
        return 1;
    }
    
    # Check if this is a regular signal reference to an intermediate signal
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $self->extract_signal_name_from_ast($ast);
        if ($signal_name && $self->is_intermediate_signal($signal_name)) {
            return 1;
        }
    }
    
    # Recursively check children
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        return 1 if $ast->can('left') && $self->ast_contains_intermediate_signal_references($ast->left);
        return 1 if $ast->can('right') && $self->ast_contains_intermediate_signal_references($ast->right);
    }
    elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        return 1 if $ast->can('operand') && $self->ast_contains_intermediate_signal_references($ast->operand);
    }
    
    return 0;
}

sub expressions_are_equivalent ($self, $expr1, $expr2) {
    # Check if two expressions are semantically equivalent
    # This is a heuristic to match original expressions with their substituted versions
    
    return 0 unless defined($expr1) && defined($expr2);
    
    # Normalize whitespace
    $expr1 =~ s/\s+/ /g;
    $expr1 =~ s/^\s+|\s+$//g;
    $expr2 =~ s/\s+/ /g;
    $expr2 =~ s/^\s+|\s+$//g;
    
    # Direct match
    return 1 if $expr1 eq $expr2;
    
    # Check if one expression contains intermediate signals while the other doesn't
    # but they have the same "shape" (same operators and structure)
    my $expr1_structure = $self->extract_expression_structure($expr1);
    my $expr2_structure = $self->extract_expression_structure($expr2);
    
    return $expr1_structure eq $expr2_structure;
}

sub extract_expression_structure ($self, $expression) {
    # Extract the structural pattern of an expression (operators and parentheses)
    # This helps match expressions that are equivalent but have different signal names
    
    # Replace all signal names with placeholder
    $expression =~ s/\b[a-zA-Z_][a-zA-Z0-9_]*\b/SIG/g;
    
    # Replace all literals with placeholder
    $expression =~ s/\d+'?[bdhBDH]?[0-9a-fA-F_]*/LIT/g;
    $expression =~ s/\b\d+\b/LIT/g;
    
    return $expression;
}

sub is_signal_referenced_in_substitutions ($self, $signal_name) {
    return $self->{backend_sv}->is_signal_referenced_in_substitutions($signal_name);
}

sub ast_structures_match ($self, $original_ast, $substituted_ast) {
    # Check if two AST nodes have the same structural pattern
    # This is used to match original ASTs with their substituted versions
    # even when the substituted version contains intermediate signal references
    
    return 0 unless $original_ast && blessed($original_ast);
    return 0 unless $substituted_ast && blessed($substituted_ast);
    
    # Compare AST node types
    my $original_type = ref($original_ast);
    my $substituted_type = ref($substituted_ast);
    
    # Allow for some flexibility in AST types (original vs substituted classes)
    my $types_compatible = 0;
    
    # Direct type match
    if ($original_type eq $substituted_type) {
        $types_compatible = 1;
    }
    # Handle substituted node types that correspond to original types
    elsif (($original_type =~ /BinaryOp$/ && $substituted_type =~ /BinaryOp$/) ||
           ($original_type =~ /UnaryOp$/ && $substituted_type =~ /UnaryOp$/) ||
           ($original_type =~ /SignalRef$/ && $substituted_type =~ /SignalRef$/)) {
        $types_compatible = 1;
    }
    
    return 0 unless $types_compatible;
    
    # For binary operations, check operator and recursively check operands
    if ($original_ast->isa('FSM::AST::BinaryOp') || $original_ast->isa('FSM::CoreAST::BinaryOp')) {
        # Check operators match
        if ($original_ast->can('operator') && $substituted_ast->can('operator')) {
            my $orig_op = $original_ast->operator || '';
            my $subst_op = $substituted_ast->operator || '';
            return 0 unless $orig_op eq $subst_op;
        }
        
        # Check operand structures match (recursively)
        if ($original_ast->can('left') && $substituted_ast->can('left') &&
            $original_ast->can('right') && $substituted_ast->can('right')) {
            
            # The operands may not match exactly (due to substitution), but their
            # structures should be similar. For now, we'll be more permissive.
            return 1;
        }
    }
    # For unary operations, check operator and recursively check operand
    elsif ($original_ast->isa('FSM::AST::UnaryOp') || $original_ast->isa('FSM::CoreAST::UnaryOp')) {
        # Check operators match
        if ($original_ast->can('operator') && $substituted_ast->can('operator')) {
            my $orig_op = $original_ast->operator || '';
            my $subst_op = $substituted_ast->operator || '';
            return 0 unless $orig_op eq $subst_op;
        }
        
        # Check operand structures match (recursively)
        if ($original_ast->can('operand') && $substituted_ast->can('operand')) {
            # The operands may not match exactly (due to substitution), but their
            # structures should be similar. For now, we'll be more permissive.
            return 1;
        }
    }
    # For signal references and literals, they can be considered matching
    # even if the actual signal names differ (due to substitution)
    elsif ($original_ast->isa('FSM::AST::SignalRef') || $original_ast->isa('FSM::CoreAST::SignalRef') ||
           $original_ast->isa('FSM::AST::Literal') || $original_ast->isa('FSM::CoreAST::Literal')) {
        return 1;
    }
    
    # Default: structures match if we reach here
    return 1;
}

sub topologically_sort_signals {
    my ($self, $filtered_signals, $signal_dependencies) = @_;
    return $self->{backend_sv}->topologically_sort_signals($filtered_signals, $signal_dependencies);
}

1;
