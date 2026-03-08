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
        intermediate_signals => {},# signal_name => expression
        all_lhs => {},           # Track all LHS signals across all DTs
        reset_assignments => {},  # LHS that need reset handling
        expr_namer => FSM::ExpressionNamer->new(debug => $debug_mode),  # Expression parser and namer with debug
        # Global expression factoring for cross-DT reuse
        global_expressions => {}, # canonical_expr => signal_name (for reuse)
        expression_usage => {},   # signal_name => usage_count (for optimization)
        factorization_fixpoint_max_passes => $args{factorization_fixpoint_max_passes} // 16,
        # LHS/RHS tracking and validation
        expected_lhs_rhs => {},   # Track expected LHS/RHS pairs from FSM parsing
        actual_lhs_rhs => {},     # Track actual LHS/RHS pairs that made it to HDL generation
        missing_lhs_rhs => {},    # Track missing LHS/RHS pairs for debugging
        
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
    fsm_debug("Flattening all decision trees", 3);
    
    # Process regular states
    for my $state (@{$fsm_module->states}) {
        next if $state->name =~ /^-/; # Skip standalone DTs for now
        
        fsm_debug("Flattening state: " . $state->name, 3);
        
        # State enable condition
        my $state_enable = "current_state == " . uc($state->name);
        $self->{state_enables}->{$state->name} = $state_enable;
        
        # Flatten the state's decision trees
        if ($state->decision_trees && @{$state->decision_trees}) {
            for my $dt (@{$state->decision_trees}) {
                $self->flatten_decision_tree(
                    $state->name, 
                    $dt, 
                    []  # Initial condition stack
                );
            }
        }
    }
    
    # Process standalone decision trees
    for my $state (@{$fsm_module->states}) {
        next unless $state->name =~ /^-/; # Only standalone DTs
        
        fsm_debug("Flattening standalone DT: " . $state->name, 3);
        
        # Standalone DT enable condition (always active, but may have internal conditions)
        my $dt_enable = "1'b1"; # Default to always enabled, refined by internal conditions
        $self->{dt_enables}->{$state->name} = $dt_enable;
        
        # Flatten the standalone decision trees
        if ($state->decision_trees && @{$state->decision_trees}) {
            for my $dt (@{$state->decision_trees}) {
                $self->flatten_decision_tree(
                    $state->name, 
                    $dt, 
                    []  # Initial condition stack
                );
            }
        }
    }
    
    # UNIFIED PHASE 1: Build complete assignment analysis structure
    $self->build_unified_assignment_analysis($fsm_module);
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
    return 'unknown_lhs' unless $lhs_ast;
    
    if ($lhs_ast->can('name')) {
        my $name = eval { $lhs_ast->name() };
        return $name if defined($name) && $name ne '';
    }
    
    if ($lhs_ast->isa('FSM::CoreAST::SignalRef') && $lhs_ast->signal && $lhs_ast->signal->can('name')) {
        return $lhs_ast->signal->name;
    }
    
    if ($lhs_ast->isa('FSM::CoreAST::IndexedRef') && $lhs_ast->signal && ref($lhs_ast->signal) && $lhs_ast->signal->can('name')) {
        return $lhs_ast->signal->name;
    }
    
    if ($lhs_ast->can('to_systemverilog')) {
        my $sv = eval { $lhs_ast->to_systemverilog() };
        if (defined($sv) && $sv =~ /^([a-zA-Z_]\w*)/) {
            return $1;
        }
    }
    
    return 'unknown_lhs';
}

sub flatten_decision_tree ($self, $dt_name, $dt_node, $condition_stack) {
    return unless $dt_node;
    
    fsm_debug("=== FLATTEN_DT_NODE ====", 3);
    fsm_debug("  DT: $dt_name", 3);
    fsm_debug("  Node Type: " . ref($dt_node), 3);
    # Safe debug of condition stack
    my $debug_stack = "";
    if (@$condition_stack) {
        my @debug_conditions = ();
        for my $condition_ast (@$condition_stack) {
            if (blessed($condition_ast) && $condition_ast->can('to_systemverilog')) {
                push @debug_conditions, $condition_ast->to_systemverilog();
            } else {
                push @debug_conditions, ref($condition_ast) || "UNBLESSED";
            }
        }
        $debug_stack = join(", ", @debug_conditions);
    }
    fsm_debug("  Condition Stack: [$debug_stack]", 3);
    
    # Handle different node types from FSMGen adapter
    if ($dt_node->isa('FSM::CoreAST::ConditionalBranch')) {
        fsm_debug("  Conditional branch with condition: " . ($dt_node->condition ? ref($dt_node->condition) : 'none'), 3);
        
        # Process each branch - branches() returns an array reference
        my $branches = $dt_node->branches;
        for my $branch (@$branches) {
            if ($branch->{condition}) {
                # Convert condition to AST node and create isolated stack copy
                my $condition_ast = $self->convert_condition_to_ast($branch->{condition});
                my @new_stack = (@$condition_stack);  # Create isolated copy
                push @new_stack, $condition_ast;      # Add condition to isolated copy
                
                # Safe debug of condition AST
                my $condition_debug = blessed($condition_ast) && $condition_ast->can('to_systemverilog') 
                    ? $condition_ast->to_systemverilog() 
                    : (ref($condition_ast) || "UNBLESSED");
                fsm_debug("    CONDITIONAL_BRANCH: Adding condition '$condition_debug'", 3);
                
                # Safe debug of new condition stack
                my @stack_debug = map { 
                    blessed($_) && $_->can('to_systemverilog') 
                        ? $_->to_systemverilog() 
                        : (ref($_) || "UNBLESSED")
                } @new_stack;
                fsm_debug("    New condition stack: [" . join(", ", @stack_debug) . "]", 3);
                
                # Process branch actions
                for my $action (@{$branch->{actions}}) {
                    $self->flatten_decision_tree($dt_name, $action, \@new_stack);
                }
            } else {
                # Else branch - process with current stack
                for my $action (@{$branch->{actions}}) {
                    $self->flatten_decision_tree($dt_name, $action, $condition_stack);
                }
            }
        }
        
    } elsif ($dt_node->isa('FSM::CoreAST::TestNode')) {
        fsm_debug("  Test node: " . $dt_node->test_signal->name, 3);
        
        # Process each test branch - test_branches() returns an array reference
        my $test_branches = $dt_node->test_branches;
        for my $branch (@$test_branches) {
            # Create AST node for test condition: signal == value
            my $signal_ast = FSM::AST::Utils::signal_ref($dt_node->test_signal->name);
            my $value_ast = $self->convert_test_value_to_ast($branch->{value});
            my $test_condition_ast = FSM::AST::Utils::equals_op($signal_ast, $value_ast);
            
            my @test_stack = (@$condition_stack);  # Create isolated copy
            push @test_stack, $test_condition_ast;  # Add condition to isolated copy
            
            # Safe debug of test condition AST
            my $test_condition_debug = blessed($test_condition_ast) && $test_condition_ast->can('to_systemverilog') 
                ? $test_condition_ast->to_systemverilog() 
                : (ref($test_condition_ast) || "UNBLESSED");
            fsm_debug("    TEST_NODE: Adding test condition '$test_condition_debug'", 3);
            
            # Safe debug of test stack
            my @test_stack_debug = map { 
                blessed($_) && $_->can('to_systemverilog') 
                    ? $_->to_systemverilog() 
                    : (ref($_) || "UNBLESSED")
            } @test_stack;
            fsm_debug("    New test stack: [" . join(", ", @test_stack_debug) . "]", 3);
            
            for my $action (@{$branch->{actions}}) {
                $self->flatten_decision_tree($dt_name, $action, \@test_stack);
            }
        }
        
    } elsif ($dt_node->isa('FSM::CoreAST::Assignment') || $dt_node->isa('FSM::CoreAST::RegisterAssignment')) {
        my $assignment_target_name = $self->extract_lhs_name_from_ast($dt_node->target);
        fsm_debug("  Assignment: " . $assignment_target_name . " <- " . ref($dt_node->source), 3);
        
        # Record this assignment with current condition stack (now AST nodes)
        $self->record_assignment_from_ast($dt_name, $dt_node, $condition_stack);
        
    } elsif ($dt_node->isa('FSM::CoreAST::StateTransition')) {
        fsm_debug("  Transition: -> " . $dt_node->target_state, 3);
        
        # Treat state transition as special assignment to next_state
        $self->record_transition_from_ast($dt_name, $dt_node, $condition_stack);
        
    } elsif (ref($dt_node) eq 'ARRAY') {
        # Handle arrays of nodes
        for my $child (@$dt_node) {
            $self->flatten_decision_tree($dt_name, $child, $condition_stack);
        }
    } elsif ($dt_node->isa('FSM::CoreAST::DecisionTree')) {
        my $elements = $dt_node->elements;
        if ($elements && ref($elements) eq 'ARRAY') {
            fsm_debug("  DecisionTree with " . scalar(@$elements) . " elements", 3);
            
            # Process all elements in the decision tree
            for my $element (@$elements) {
                $self->flatten_decision_tree($dt_name, $element, $condition_stack);
            }
        } else {
            fsm_debug("  DecisionTree has no elements or elements is not an array", 3);
        }
        
    } else {
        fsm_debug("  Unknown node type: " . ref($dt_node), 3);
    }
}

sub record_assignment ($self, $dt_name, $assignment_node, $condition_stack) {
    my $lhs = $assignment_node->lhs;
    my $rhs = $assignment_node->rhs;
    my $operator = $assignment_node->operator;
    
    # Clean up signal names (remove bit width annotations)
    $lhs =~ s/'.*$//;  # Remove 'N suffix
    $lhs =~ s/>$//;    # Remove > suffix
    
    # Create condition expression
    my $condition_expr = $self->create_condition_expression($condition_stack);
    
    # Determine the actual RHS value based on operator
    my $actual_rhs = $self->resolve_rhs_value($rhs, $operator);
    
    # Record the assignment
    push @{$self->{lhs_assignments}->{$lhs}}, {
        dt => $dt_name,
        conditions => $condition_expr,
        rhs => $actual_rhs,
        operator => $operator,
        is_state_trans => 0
    };
    
    # Track this LHS
    $self->{all_lhs}->{$lhs} = 1;
    
    fsm_debug("    Recorded assignment: $lhs <= $actual_rhs when ($condition_expr)", 3);
}

sub record_transition ($self, $dt_name, $transition_node, $condition_stack) {
    my $target_state = $transition_node->target_state;
    
    # Create condition expression
    my $condition_expr = $self->create_condition_expression($condition_stack);
    
    # Convert target state to state encoding value
    my $state_value = uc($target_state);
    
    # Record as assignment to next_state
    push @{$self->{lhs_assignments}->{next_state}}, {
        dt => $dt_name,
        conditions => $condition_expr,
        rhs => $state_value,
        operator => '<-',
        is_state_trans => 1
    };
    
    # Track next_state as LHS
    $self->{all_lhs}->{next_state} = 1;
    
    fsm_debug("    Recorded transition: next_state <= $state_value when ($condition_expr)", 3);
}

sub create_condition_expression ($self, $condition_stack) {
    return $self->{enable_graph}->create_condition_expression($condition_stack);
}

sub create_condition_expression_signal_name ($self, $condition_stack) {
    # Create a signal name for the condition expression
    return "1'b1" if !@$condition_stack;

    # Get or create the condition AST
    my $condition_ast = $self->create_condition_expression($condition_stack);
    
    # Generate systematic signal name from AST
    return $self->get_or_create_ast_signal_name($condition_ast);
}

sub get_or_create_ast_signal_name ($self, $ast) {
    # Get or create a signal name from an AST node
    # This replaces string-based naming with pure AST-based naming
    
    return "1'b1" unless $ast && blessed($ast);
    
    # Convert AST to canonical SystemVerilog for comparison
    my $canonical_expr = $ast->to_systemverilog();
    
    # Check if we already have a signal for this AST expression
    if (exists $self->{global_expressions}->{$canonical_expr}) {
        my $existing_signal = $self->{global_expressions}->{$canonical_expr};
        $self->{expression_usage}->{$existing_signal}++;
        fsm_debug("AST_SIGNAL: Reusing existing signal '$existing_signal' for AST", 3);
        return $existing_signal;
    }
    
    # Generate new systematic signal name from AST structure
    my $signal_name = $self->generate_ast_based_signal_name($ast);
    
    # Register the new signal
    $self->{global_expressions}->{$canonical_expr} = $signal_name;
    $self->{expression_usage}->{$signal_name} = 1;
    $self->{intermediate_signals}->{$signal_name} = $canonical_expr;
    
    fsm_debug("AST_SIGNAL: Created new signal '$signal_name' for AST", 3);
    return $signal_name;
}

sub generate_ast_based_signal_name ($self, $ast) {
    # Generate a systematic signal name based on AST structure with PROPER INTERMEDIATE SIGNAL NAMING
    # This follows the specified naming rules:
    # - Unary operations: <op>_<A>
    # - Binary operations: <A>_<op>_<B>
    
    return "unknown_signal" unless $ast && blessed($ast);
    
    fsm_debug("AST_SIGNAL_NAME: Generating name for " . ref($ast), 3);
    
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        # For signal references, extract the signal name
        my $signal_name = $self->extract_signal_name_from_ast($ast);
        return $signal_name || "unknown_signal";
        
    } elsif ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        # For literals, create a name based on the value
        my $value = $ast->value;
        if ($value eq "1'b1") {
            return "const_1";
        } elsif ($value eq "1'b0") {
            return "const_0";
        } else {
            my $clean_value = $value;
            $clean_value =~ s/[^a-zA-Z0-9_]/_/g;
            return "const_$clean_value";
        }
        
    } elsif ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # For binary operations, create compound names
        my $left_name = $self->generate_ast_based_signal_name($ast->left);
        my $right_name = $self->generate_ast_based_signal_name($ast->right);
        my $op = $ast->operator;
        
        # Map operators to signal name components
        my $op_name = $self->map_operator_to_name($op);
        
        return "${left_name}_${op_name}_${right_name}";
        
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        # For unary operations, create prefixed names
        my $operand_name = $self->generate_ast_based_signal_name($ast->operand);
        my $op = $ast->operator || "not";
        my $op_name = $self->map_operator_to_name($op);
        
        return "${op_name}_${operand_name}";
        
    } else {
        # For unknown AST types, use a generic name
        my $type_name = ref($ast);
        $type_name =~ s/^.*:://;  # Remove package prefix
        return lc($type_name) . "_expr";
    }
}

sub extract_signal_name_from_ast ($self, $signal_ast) {
    return $self->{enable_graph}->extract_signal_name_from_ast($signal_ast);
}

sub map_operator_to_name ($self, $operator) {
    # Map SystemVerilog operators to signal name components
    
    my %op_map = (
        '&&' => 'and',
        '&'  => 'and',
        '||' => 'or',
        '|'  => 'or', 
        '==' => 'eq',
        '!=' => 'ne',
        '!'  => 'not',
        '+'  => 'plus',
        '-'  => 'minus',
        '*'  => 'mult',
        '/'  => 'div',
        '<'  => 'lt',
        '>'  => 'gt',
        '<=' => 'le',
        '>=' => 'ge'
    );
    
    return $op_map{$operator} || "op";
}

sub format_condition ($self, $condition) {
    # Convert FSMGen conditions to SystemVerilog using improved expression parsing
    
    if ($condition =~ /^<(.+)$/) {
        # Simple signal condition: <signal -> signal
        my $signal = $1;
        return $self->format_signal_expression($signal);
        
    } elsif ($condition =~ /^<!(.+)$/) {
        # Negated signal condition: <!signal -> !(signal)
        my $signal = $1;
        my $formatted_signal = $self->format_signal_expression($signal);
        # Properly parenthesize to avoid creating invalid signal names like !apb_rq
        return "!(" . $formatted_signal . ")";
        
    } elsif ($condition =~ /^(.+) == (.+)$/) {
        # Equality test: signal == value
        my ($lhs, $rhs) = ($1, $2);
        
        # Format both sides of the comparison
        my $formatted_lhs = $self->format_signal_expression($lhs);
        my $formatted_rhs = $self->format_signal_expression($rhs);
        
        # Check if this entire comparison is complex and should be factored
        if ($self->is_complex_expression($lhs) || $self->is_complex_expression($rhs)) {
            my $comparison_expr = "$formatted_lhs == $formatted_rhs";
            my $signal_name = $self->get_or_create_global_expression($comparison_expr);
            return $signal_name;
        }
        
        return "$formatted_lhs == $formatted_rhs";
    } else {
        # Handle general expressions
        return $self->format_signal_expression($condition);
    }
}

sub format_signal_expression ($self, $expr) {
    # Format signal expressions - bypass the problematic FSM_ExpressionNamer
    # and work directly with expressions as strings for now
    
    fsm_debug("FORMAT_SIGNAL: Processing expression: '$expr'", 3);
    
    # Simple signal names are returned as-is
    if (!$self->is_complex_expression($expr)) {
        fsm_debug("FORMAT_SIGNAL: Expression is simple - returning as-is: '$expr'", 3);
        return $expr;
    }
    
    # For complex expressions, DON'T use FSM_ExpressionNamer since it's buggy
    # Instead, return the expression as-is since it should already be valid SystemVerilog
    fsm_debug("FORMAT_SIGNAL: Complex expression - returning as SystemVerilog: '$expr'", 3);
    return $expr;
}

sub invert_condition ($self, $condition) {
    # Invert FSMGen conditions
    if ($condition =~ /^<(.+)$/) {
        return "<!$1";  # <signal -> <!signal
    } elsif ($condition =~ /^<!(.+)$/) {
        return "<$1";   # <!signal -> <signal
    } else {
        return "!($condition)";  # Wrap in negation
    }
}

sub format_test_value ($self, $value) {
    # Convert test values to SystemVerilog format
    if ($value =~ /^=(.+)$/) {
        my $val = $1;
        if ($val eq '0') {
            return "1'b0";
        } elsif ($val eq '1') {
            return "1'b1";
        } else {
            return $val;
        }
    }
    return $value;
}

sub resolve_rhs_value ($self, $rhs, $operator) {
    # Handle different RHS types based on operator
    if ($operator eq '<-' || $operator eq '=') {
        # Direct assignment
        if ($rhs =~ /^const_(\d+)b(\d+)$/) {
            # const_8b0 -> 8'h00
            my $width = $1;
            my $value = $2;
            return sprintf("%d'h%0*X", $width, int(($width + 3) / 4), $value);
        } elsif ($rhs =~ /^\d+$/) {
            # Plain number
            return "1'b$rhs";
        } else {
            # Signal name
            return $rhs;
        }
    } elsif ($operator eq '++') {
        return "$rhs + 1";
    } elsif ($operator eq '--') {
        return "$rhs - 1";
    } else {
        return $rhs;
    }
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

sub perform_global_expression_factorization ($self) {
    # GLOBAL SUB-EXPRESSION FACTORIZATION PHASE
    # This method analyzes ALL expressions in the design and factors out common sub-expressions
    # to avoid redundant logic and improve sharing
    
    fsm_debug("\n\n*** GLOBAL SUB-EXPRESSION FACTORIZATION PHASE ***", 3);
    
    # Initialize global factorization data structures
    $self->{sub_expression_map} = {};    # Maps canonical_sub_expr -> shared_signal_name
    $self->{expression_usage_count} = {}; # Maps canonical_sub_expr -> usage_count
    $self->{factored_expressions} = {};   # Maps original_expr -> factored_expr_using_shared_signals
    
    # Step 1: Collect all expressions from across the design
    my @all_expressions;
    
    # Collect from intermediate signals (if any exist)
    if ($self->{intermediate_signals}) {
        for my $signal_name (keys %{$self->{intermediate_signals}}) {
            my $expr = $self->{intermediate_signals}->{$signal_name};
            push @all_expressions, { expr => $expr, context => "intermediate:$signal_name" };
        }
    }
    
    # Collect from LHS assignments (condition expressions)
    for my $lhs (keys %{$self->{lhs_assignments} || {}}) {
        for my $assignment (@{$self->{lhs_assignments}->{$lhs}}) {
            my $condition_expr = $assignment->{conditions};
            if ($condition_expr && $condition_expr ne "1'b1") {
                push @all_expressions, { 
                    expr => $condition_expr, 
                    context => "condition:$lhs:$assignment->{dt}" 
                };
            }
        }
    }
    
    # Collect from unified analysis enable expressions
    if ($self->{assignment_analysis}) {
        for my $lhs (keys %{$self->{assignment_analysis}}) {
            my $lhs_analysis = $self->{assignment_analysis}->{$lhs};
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
                
                # Collect DT-specific enable expressions
                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    push @all_expressions, {
                        expr => $dt_enable->{enable_expr},
                        context => "dt_enable:$dt_enable->{enable_name}"
                    };
                }
                
                # Collect LHS-level enable expressions  
                if ($rhs_group->{lhs_level_enable}) {
                    push @all_expressions, {
                        expr => $rhs_group->{lhs_level_enable}->{expr},
                        context => "lhs_enable:$rhs_group->{lhs_level_enable}->{name}"
                    };
                }
            }
        }
    }
    
    fsm_debug("FACTORIZATION: Collected " . scalar(@all_expressions) . " expressions for analysis", 3);
    
    # Step 2: Parse expressions into ASTs and extract sub-expressions
    my %sub_expression_occurrences;  # Maps canonical_sub_expr -> [contexts]
    
    for my $expr_info (@all_expressions) {
        my $expr = $expr_info->{expr};
        my $context = $expr_info->{context};
        
        fsm_debug("FACTORIZATION: Analyzing expression '$expr' from $context", 3);
        
        # Skip simple expressions that don't need factorization
        next if $self->is_simple_expression_for_factorization($expr);
        
        # Parse expression into AST
        my $ast = eval { $self->{expr_namer}->parse_expression($expr) };
        if (!$ast) {
            fsm_debug("FACTORIZATION: Could not parse expression '$expr', skipping", 3);
            next;
        }
        
        # Extract all sub-expressions from this AST
        my $sub_exprs = $self->extract_sub_expressions_from_ast($ast);
        
        for my $sub_expr_ast (@$sub_exprs) {
            # Convert sub-expression to canonical string form for comparison
            my $canonical_sub_expr = $sub_expr_ast->to_systemverilog();
            
            # Skip if this sub-expression is too simple to warrant factorization
            next if $self->is_simple_expression_for_factorization($canonical_sub_expr);
            
            # Record this occurrence
            push @{$sub_expression_occurrences{$canonical_sub_expr}}, {
                context => $context,
                ast => $sub_expr_ast
            };
            
            fsm_debug("FACTORIZATION: Found sub-expression '$canonical_sub_expr' in $context", 3);
        }
    }
    
    # Step 3: Identify sub-expressions that occur multiple times (candidates for factorization)
    my %candidates_for_factorization;
    for my $canonical_sub_expr (keys %sub_expression_occurrences) {
        my $occurrences = $sub_expression_occurrences{$canonical_sub_expr};
        if (@$occurrences > 1) {
            $candidates_for_factorization{$canonical_sub_expr} = $occurrences;
            fsm_debug("FACTORIZATION: Sub-expression '$canonical_sub_expr' occurs " . 
                        scalar(@$occurrences) . " times - CANDIDATE FOR FACTORIZATION", 3);
        }
    }
    
    # Step 4: Create shared intermediate signals for factored sub-expressions
    my $factorization_counter = 0;
    for my $canonical_sub_expr (sort keys %candidates_for_factorization) {
        my $occurrences = $candidates_for_factorization{$canonical_sub_expr};
        
        # Generate a systematic name for the shared signal
        my $ast = $occurrences->[0]->{ast};  # Use the first occurrence's AST
        my $shared_signal_name = $self->{expr_namer}->ast_to_systematic_name($ast);
        
        # Make sure the name is unique
        my $base_name = $shared_signal_name;
        my $counter = 1;
        while (exists $self->{sub_expression_map}{$shared_signal_name} || 
               exists $self->{global_expressions}{$shared_signal_name}) {
            $shared_signal_name = "${base_name}_${counter}";
            $counter++;
        }
        
        # Record the factorization
        $self->{sub_expression_map}{$canonical_sub_expr} = $shared_signal_name;
        $self->{expression_usage_count}{$canonical_sub_expr} = scalar(@$occurrences);
        $self->{global_expressions}{$canonical_sub_expr} = $shared_signal_name;
        $self->{intermediate_signals}{$shared_signal_name} = $canonical_sub_expr;
        
        fsm_debug("FACTORIZATION: Created shared signal '$shared_signal_name' for sub-expression '$canonical_sub_expr' (" . 
                    scalar(@$occurrences) . " uses)", 3);
        
        # List all contexts where this sub-expression is used
        for my $occurrence (@$occurrences) {
            fsm_debug("  Used in: $occurrence->{context}", 3);
        }
        
        $factorization_counter++;
    }
    
    fsm_debug("FACTORIZATION: Created $factorization_counter shared intermediate signals", 3);
    fsm_debug("*** GLOBAL SUB-EXPRESSION FACTORIZATION COMPLETE ***\n", 3);
}

sub is_simple_expression_for_factorization ($self, $expr) {
    # Determine if an expression is too simple to warrant factorization
    # These expressions should NOT be factored out into intermediate signals
    
    # Bare signal names
    return 1 if $expr =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/;
    
    # Simple literals
    return 1 if $expr =~ /^\d+'?[bhd]?\w*$|^\d+$/;
    return 1 if $expr =~ /^1'b[01]$/;
    
    # Simple negations of bare signals (like !apb_rq)
    return 1 if $expr =~ /^!\s*[a-zA-Z_][a-zA-Z0-9_]*$/;
    
    # Constants
    return 1 if $expr =~ /^const_\d+b\d+$/;
    
    return 0;  # Complex expression, candidate for factorization
}

sub extract_sub_expressions_from_ast ($self, $ast) {
    # Extract all meaningful sub-expressions from an AST for factorization analysis
    my @sub_expressions;
    
    return \@sub_expressions unless $ast;
    
    # Check if $ast is actually a blessed object - if not, return empty list
    unless (ref($ast) && blessed($ast)) {
        return \@sub_expressions;
    }
    
    # For binary operations, extract the operands as sub-expressions
    if ($ast->isa('FSM::AST::BinaryOp')) {
        # Add the left and right operands as potential sub-expressions
        if ($ast->left && !$self->is_leaf_node($ast->left)) {
            push @sub_expressions, $ast->left;
        }
        if ($ast->right && !$self->is_leaf_node($ast->right)) {
            push @sub_expressions, $ast->right;
        }
        
        # Recursively extract from operands
        push @sub_expressions, @{$self->extract_sub_expressions_from_ast($ast->left)};
        push @sub_expressions, @{$self->extract_sub_expressions_from_ast($ast->right)};
    }
    
    # For unary operations, extract the operand
    elsif ($ast->isa('FSM::AST::UnaryOp')) {
        if ($ast->operand && !$self->is_leaf_node($ast->operand)) {
            push @sub_expressions, $ast->operand;
        }
        push @sub_expressions, @{$self->extract_sub_expressions_from_ast($ast->operand)};
    }
    
    return \@sub_expressions;
}

sub is_leaf_node ($self, $node) {
    # Check if a node is a leaf (signal reference or literal) that shouldn't be factored
    return 1 unless (ref($node) && blessed($node));
    return 1 if $node->isa('FSM::AST::SignalRef');
    return 1 if $node->isa('FSM::AST::Literal');
    return 0;
}

sub is_redundant_intermediate_signal ($self, $canonical_expr, $signal_name) {
    # Determine if an intermediate signal is redundant and should be eliminated
    # This filters out signals that shouldn't be created as intermediate signals
    
    fsm_debug("\n*** REDUNDANCY_CHECK: [ENTRY] ***", 3);
    fsm_debug("REDUNDANCY_CHECK: [SIGNAL] '$signal_name'", 3);
    fsm_debug("REDUNDANCY_CHECK: [EXPRESSION] '$canonical_expr'", 3);
    fsm_debug("REDUNDANCY_CHECK: [CALLER] " . (caller(1), 3)[3] || 'unknown', 3);
    
    # REDUNDANCY TYPE 1: Bare signal names (signal = signal)
    # Check if the expression is just a bare signal name
    if ($canonical_expr =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) {
        # Check if the signal name matches the expression (redundant assignment)
        if ($signal_name eq $canonical_expr) {
            fsm_debug("REDUNDANCY_CHECK: REDUNDANT - bare signal self-assignment: $signal_name = $canonical_expr", 3);
            return 1;
        }
        # Also check if it's an existing input/output signal
        # TODO: Could add check against FSM module signal list here
        fsm_debug("REDUNDANCY_CHECK: REDUNDANT - bare signal intermediate: $signal_name = $canonical_expr", 3);
        return 1;
    }
    
    # REDUNDANCY TYPE 2: Simple literals (const_signal = literal)
    # Check if the expression is just a simple literal
    if ($canonical_expr =~ /^\d+'?[bhd]?\w*$|^\d+$|^1'b[01]$/) {
        fsm_debug("REDUNDANCY_CHECK: REDUNDANT - simple literal: $signal_name = $canonical_expr", 3);
        return 1;
    }
    
    # REDUNDANCY TYPE 3: Constants (const_signal = const_Nb0)
    if ($canonical_expr =~ /^const_\d+b\d+$/) {
        fsm_debug("REDUNDANCY_CHECK: REDUNDANT - FSMGen constant: $signal_name = $canonical_expr", 3);
        return 1;
    }
    
    # REDUNDANCY TYPE 4: Check if the signal is never actually used
    # If usage count is 0 or 1, it might be redundant
    my $usage_count = $self->{expression_usage_count}{$canonical_expr} || 0;
    if ($usage_count <= 1) {
        fsm_debug("REDUNDANCY_CHECK: REDUNDANT - unused or single-use signal: $signal_name (usage: $usage_count)", 3);
        return 1;
    }
    
    # REMOVED: String-based pattern matching for simple negations
    # This was causing inconsistencies between AST analysis and filtering
    # AST-based decisions should be used exclusively
    
    # Not redundant - this intermediate signal should be created
    fsm_debug("REDUNDANCY_CHECK: NOT REDUNDANT - will create intermediate signal: $signal_name = $canonical_expr", 3);
    return 0;
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

sub identify_factorization_candidates ($self, $sub_expression_usage) {
    # Identify sub-expressions that are candidates for factorization
    my %candidates;
    
    fsm_debug("FACTORIZATION_CANDIDATES: Identifying candidates", 3);
    
    for my $canonical (keys %$sub_expression_usage) {
        my $usage_info = $sub_expression_usage->{$canonical};
        my $usage_count = $usage_info->{usage_count};
        
        # Only factor expressions used multiple times
        if ($usage_count > 1) {
            $candidates{$canonical} = $usage_info;
            fsm_debug("  CANDIDATE: '$canonical' (used $usage_count times)", 3);
            
            # List contexts for debugging
            for my $context (@{$usage_info->{contexts}}) {
                fsm_debug("    Used in: $context", 3);
            }
        }
    }
    
    my $candidate_count = scalar(keys %candidates);
    fsm_debug("FACTORIZATION_CANDIDATES: Identified $candidate_count candidates", 3);
    
    return %candidates;
}

sub generate_factorized_signals ($self, $factorization_candidates) {
    # Generate intermediate signals for factorized expressions
    my %intermediate_signals;
    
    fsm_debug("GENERATE_FACTORIZED: Creating intermediate signals", 3);
    
    my $signal_counter = 0;
    for my $canonical (sort keys %$factorization_candidates) {
        my $candidate_info = $factorization_candidates->{$canonical};
        my $ast = $candidate_info->{ast};
        my $usage_count = $candidate_info->{usage_count};
        
        # Generate systematic signal name from AST structure
        my $signal_name = $self->generate_ast_based_signal_name($ast);
        
        # Ensure uniqueness
        my $base_name = $signal_name;
        my $counter = 1;
        while (exists $intermediate_signals{$signal_name}) {
            $signal_name = "${base_name}_${counter}";
            $counter++;
        }
        
        # Store the intermediate signal info
        $intermediate_signals{$signal_name} = {
            ast => $ast,
            usage_count => $usage_count,
            width => 1, # Default to 1-bit for now
            canonical => $canonical
        };
        
        # Update global registries for backward compatibility
        $self->{global_expressions}->{$canonical} = $signal_name;
        $self->{expression_usage}->{$signal_name} = $usage_count;
        $self->{intermediate_signals}->{$signal_name} = $canonical;
        
        fsm_debug("  CREATED: $signal_name = $canonical (usage: $usage_count)", 3);
        $signal_counter++;
    }
    
    fsm_debug("GENERATE_FACTORIZED: Created $signal_counter intermediate signals", 3);
    
    return %intermediate_signals;
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

sub generate_dt_specific_wens ($self, $fsm_module) {
    my $hdl = "  // DT-Specific Write Enable (WEN) and Enable (EN) Signals\n";
    
    fsm_debug("\n\n*** GENERATING DT-SPECIFIC WEN/EN SIGNALS ***", 3);
    fsm_debug("All LHS signals found: " . join(", ", keys %{$self->{all_lhs}}));
    
    # Group assignments by DT first
    my %dt_assignments;
    for my $lhs (keys %{$self->{all_lhs}}) {
        next unless $self->{lhs_assignments}->{$lhs};
        
        fsm_debug("\nProcessing LHS: $lhs (" . scalar(@{$self->{lhs_assignments}->{$lhs}}) . " assignments)");
        
        for my $assignment (@{$self->{lhs_assignments}->{$lhs}}) {
            my $dt_name = $assignment->{dt};
            $dt_assignments{$dt_name} //= {};
            $dt_assignments{$dt_name}{$lhs} //= {};
            push @{$dt_assignments{$dt_name}{$lhs}{$assignment->{rhs}}}, $assignment;
            
            fsm_debug("  Assignment: DT=$dt_name, LHS=$lhs, RHS=$assignment->{rhs}, Cond=$assignment->{conditions}", 3);
        }
    }
    
    fsm_debug("\nGrouped assignments by DT:", 3);
    for my $dt_name (sort keys %dt_assignments) {
        fsm_debug("  DT $dt_name:", 3);
        for my $lhs (sort keys %{$dt_assignments{$dt_name}}) {
            for my $rhs (sort keys %{$dt_assignments{$dt_name}{$lhs}}) {
                my $count = scalar(@{$dt_assignments{$dt_name}{$lhs}{$rhs}});
                fsm_debug("    $lhs <- $rhs ($count assignment(s))", 3);
            }
        }
    }
    
    # Generate DT-specific enables with RHS sharing optimization
    for my $dt_name (sort keys %dt_assignments) {
        my $clean_dt_name = $dt_name;
        $clean_dt_name =~ s/^-//;  # Remove leading dash for standalone DTs
        
        $hdl .= "\n  // DT-specific WEN/EN signals for DT: $dt_name\n";
        
        # Get DT enable signal
        my $dt_enable;
        if ($self->{state_enables}->{$dt_name}) {
            $dt_enable = "${dt_name}_en";
        } elsif ($self->{dt_enables}->{$dt_name}) {
            $dt_enable = "${clean_dt_name}_en";
        } else {
            $dt_enable = "1'b1";
        }
        
        # Step 1: Identify common RHS expressions for this DT
        my %dt_rhs_expressions;  # Maps common_rhs_expr -> intermediate_signal_name
        my %lhs_rhs_to_common_signal;  # Maps "lhs:rhs" -> common_signal_name
        
        # Collect all unique RHS expressions for this DT
        my %all_rhs_expressions;
        for my $lhs (sort keys %{$dt_assignments{$dt_name}}) {
            for my $rhs (sort keys %{$dt_assignments{$dt_name}{$lhs}}) {
                my $assignments = $dt_assignments{$dt_name}{$lhs}{$rhs};
                
                # Create OR of all conditions for this DT/LHS/RHS combination
                my @condition_exprs;
                for my $assignment (@$assignments) {
                    my $condition = $assignment->{conditions};
                    push @condition_exprs, $condition;
                }
                
                my $condition_expr = join(" || ", @condition_exprs);
                
                # Factor the condition expression if it's complex and compound
                my $final_condition_expr;
                if ($self->should_factor_condition($condition_expr)) {
                    fsm_debug("  Factoring compound condition expression: $condition_expr", 3);
                    my $signal_name = $self->get_or_create_global_expression($condition_expr);
                    $final_condition_expr = $signal_name;
                    fsm_debug("  Created/reused intermediate signal: $signal_name", 3);
                } else {
                    $final_condition_expr = $condition_expr;
                }
                
                # Build the complete RHS expression - only add parentheses if needed
                # Use bitwise & instead of logical && for 1-bit signals
                my $complete_rhs;
                if ($self->needs_parentheses($final_condition_expr)) {
                    $complete_rhs = "$dt_enable & ($final_condition_expr)";
                } else {
                    $complete_rhs = "$dt_enable & $final_condition_expr";
                }
                
                # Track this RHS expression
                push @{$all_rhs_expressions{$complete_rhs}}, "$lhs:$rhs";
            }
        }
        
        # Step 2: Generate intermediate signals for shared RHS expressions
        my $dt_intermediate_counter = 0;
        for my $rhs_expr (sort keys %all_rhs_expressions) {
            my $lhs_rhs_pairs = $all_rhs_expressions{$rhs_expr};
            
            if (@$lhs_rhs_pairs > 1) {
                # This RHS is shared by multiple LHS signals - create intermediate signal
                my $intermediate_signal = "${clean_dt_name}_common_en_${dt_intermediate_counter}";
                $hdl .= "  assign $intermediate_signal = $rhs_expr;  // Shared by: " . join(", ", @$lhs_rhs_pairs) . "\n";
                
                # Map each LHS:RHS to this intermediate signal
                for my $lhs_rhs (@$lhs_rhs_pairs) {
                    $lhs_rhs_to_common_signal{$lhs_rhs} = $intermediate_signal;
                }
                
                $dt_intermediate_counter++;
                fsm_debug("  Created intermediate signal $intermediate_signal for RHS: $rhs_expr", 3);
            } else {
                # This RHS is unique - use directly
                my $lhs_rhs = $lhs_rhs_pairs->[0];
                $lhs_rhs_to_common_signal{$lhs_rhs} = $rhs_expr;
            }
        }
        
        # Step 3: Generate DT-specific enables using shared or direct RHS
        for my $lhs (sort keys %{$dt_assignments{$dt_name}}) {
            for my $rhs (sort keys %{$dt_assignments{$dt_name}{$lhs}}) {
                my $clean_rhs = $self->clean_signal_name($rhs);
                my $clean_lhs = $self->clean_signal_name($lhs);
                
                my $lhs_rhs_key = "$lhs:$rhs";
                my $rhs_signal = $lhs_rhs_to_common_signal{$lhs_rhs_key};
                
                # Generate DT-specific enable using shared or direct RHS
                $hdl .= "  assign ${clean_dt_name}_${clean_lhs}_${clean_rhs}_en = $rhs_signal;\n";
                
                # Track this for later LHS-level OR-ing
                $self->{dt_specific_enables} //= {};
                $self->{dt_specific_enables}{$lhs} //= {};
                push @{$self->{dt_specific_enables}{$lhs}{$rhs}}, "${clean_dt_name}_${clean_lhs}_${clean_rhs}_en";
            }
        }
    }
    
    return $hdl;
}

sub generate_lhs_level_wens ($self, $fsm_module) {
    my $hdl = "\n  // LHS-Level Write Enable (WEN) Signals - OR of DT-specific enables\n";
    
    # Initialize the mapping from LHS to enable/value pairs for multiplexer generation
    $self->{lhs_to_enable_value_pairs} = {};
    
    for my $lhs (sort keys %{$self->{dt_specific_enables}}) {
        $hdl .= "\n  // WEN signals for LHS: $lhs\n";
        
        # Initialize the array for this LHS to store enable/value pairs
        $self->{lhs_to_enable_value_pairs}{$lhs} = [];
        
        for my $rhs (sort keys %{$self->{dt_specific_enables}{$lhs}}) {
            my $dt_enables = $self->{dt_specific_enables}{$lhs}{$rhs};
            my $or_expr = join(" | ", @$dt_enables);
            
            # Generate meaningful enable name based on RHS value (as originally intended)
            my $enable_signal_name = $self->generate_rhs_based_enable_name($lhs, $rhs);
            
            # Store both the enable signal name AND the associated RHS value
            push @{$self->{lhs_to_enable_value_pairs}{$lhs}}, {
                enable_signal => $enable_signal_name,
                rhs_value => $rhs
            };
            
            $hdl .= "  assign $enable_signal_name = $or_expr;\n";
        }
    }
    
    return $hdl;
}

sub clean_signal_name ($self, $name) {
    return $self->{enable_graph}->clean_signal_name($name);
}

sub generate_rhs_based_enable_name ($self, $lhs, $rhs) {
    return $self->{enable_graph}->generate_rhs_based_enable_name($lhs, $rhs);
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

# Helper methods for FSMGen adapter AST nodes
sub extract_condition_string ($self, $condition_node) {
    # Extract condition string from FSMGen adapter condition nodes
    
    # Safety check for undefined condition node
    unless ($condition_node) {
        fsm_debug("    EXTRACT_CONDITION: WARNING - undefined condition node", 3);
        return "1'b1";
    }
    
    fsm_debug("    EXTRACT_CONDITION: Node type: " . ref($condition_node), 3);
    
    # Debug the node object structure
    if ($condition_node->can('operator')) {
        my $op = eval { $condition_node->operator } || "unknown_op";
        fsm_debug("    EXTRACT_CONDITION: Node has operator method, result: '$op'", 3);
    }
    if ($condition_node->can('operand')) {
        fsm_debug("    EXTRACT_CONDITION: Node has operand", 3);
    }
    if ($condition_node->can('signal')) {
        fsm_debug("    EXTRACT_CONDITION: Node has signal", 3);
    }
    
    # Check what methods this node actually has
    my @methods = grep { $condition_node->can($_) } qw(isa operator operand signal value left right name);
    fsm_debug("    EXTRACT_CONDITION: Available methods: " . join(", ", @methods), 3);
    
    if ($condition_node->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $condition_node->signal->name;
        fsm_debug("    EXTRACT_CONDITION: SignalRef -> <$signal_name", 3);
        return "<" . $signal_name;
        
    } elsif (ref($condition_node) eq 'FSM::CoreAST::UnaryOp' || ($condition_node->can('operator') && $condition_node->can('operand'))) {
        # Handle UnaryOp - check the type field which seems to contain the actual operator type
        my $operator_type = 'unknown';
        if (ref($condition_node) eq 'HASH' && $condition_node->{type}) {
            $operator_type = $condition_node->{type};
        } elsif ($condition_node->can('type')) {
            $operator_type = $condition_node->type;
        }
        
        fsm_debug("    EXTRACT_CONDITION: UnaryOp with type: $operator_type", 3);
        
        # For negation operations
        if ($operator_type eq 'unary_op' || $operator_type eq 'not' || $operator_type eq '!') {
            my $operand_condition = $self->extract_condition_string($condition_node->operand);
            # Convert <signal to <!signal for negation
            if ($operand_condition =~ /^<(.+)$/) {
                my $result = "<!$1";
                fsm_debug("    EXTRACT_CONDITION: UnaryOp(negation) -> $result", 3);
                return $result;
            } else {
                # If operand doesn't start with <, wrap in negation
                my $result = "!($operand_condition)";
                fsm_debug("    EXTRACT_CONDITION: UnaryOp(negation) -> $result", 3);
                return $result;
            }
        } else {
            # Other unary operators
            my $operand_condition = $self->extract_condition_string($condition_node->operand);
            my $result = "$operator_type($operand_condition)";
            fsm_debug("    EXTRACT_CONDITION: UnaryOp($operator_type) -> $result", 3);
            return $result;
        }
        
    } elsif (ref($condition_node) eq 'FSM::CoreAST::BinaryOp' || ($condition_node->can('left') && $condition_node->can('right') && $condition_node->can('operator'))) {
        my $left_cond = $self->extract_condition_string($condition_node->left);
        my $right_cond = $self->extract_condition_string($condition_node->right);
        my $op = $condition_node->operator;
        my $result = "($left_cond $op $right_cond)";
        fsm_debug("    EXTRACT_CONDITION: BinaryOp($op) -> $result", 3);
        return $result;
        
    } elsif ($condition_node->isa('FSM::CoreAST::Literal')) {
        my $value = $condition_node->value;
        fsm_debug("    EXTRACT_CONDITION: Literal -> $value", 3);
        return $value;
        
    } else {
        # Enhanced fallback - try to get more information
        my $node_type = ref($condition_node);
        fsm_debug("    EXTRACT_CONDITION: Unknown type '$node_type' - using generic condition", 3);
        
        # Try to see if we can extract any useful information
        if ($condition_node->can('name')) {
            my $name = eval { $condition_node->name };
            if ($name) {
                fsm_debug("    EXTRACT_CONDITION: Found name attribute: $name", 3);
                return "<$name";
            }
        }
        
        # Final fallback
        return "condition";
    }
}

sub record_assignment_from_ast ($self, $dt_name, $assignment_node, $condition_stack) {
    # AST WEB IMPLEMENTATION: Store AST nodes directly, not strings!
    my $lhs_signal_ast = $assignment_node->target;  # Keep the AST node
    my $rhs_expr = $assignment_node->source;
    my $lhs_name = $self->extract_lhs_name_from_ast($lhs_signal_ast);
    
    # PURE AST/OOP: Ask the AST node directly for debugging information
    fsm_debug("\n*** PHASE1 ASSIGNMENT NODE REACHED (AST WEB) ***", 3);
    fsm_debug("  DT: $dt_name", 3);
    fsm_debug("  LHS AST Node: " . ref($lhs_signal_ast), 3);
    fsm_debug("  LHS Name: " . $lhs_name, 3);
    
    # CRITICAL: Debug the condition stack contents at assignment time
    fsm_debug("  CONDITION STACK ANALYSIS:", 3);
    fsm_debug("    Stack size: " . scalar(@$condition_stack), 3);
    if (@$condition_stack) {
        for my $i (0 .. $#$condition_stack) {
            my $cond = $condition_stack->[$i];
            if (blessed($cond) && $cond->can('to_systemverilog')) {
                fsm_debug("    Stack[$i]: '" . $cond->to_systemverilog() . "' (" . ref($cond) . ")", 3);
            } else {
                fsm_debug("    Stack[$i]: INVALID - " . (ref($cond) || 'SCALAR') . " - " . ($cond || 'UNDEF'), 3);
            }
        }
    } else {
        fsm_debug("    Stack: EMPTY", 3);
    }
    
    # Create condition expression as pure AST
    my $condition_ast = $self->create_condition_expression($condition_stack);
    
    # Extract RHS value from expression
    my $actual_rhs = $self->extract_rhs_from_expression($rhs_expr);
    
    # Determine operator directly from assignment intent metadata (strict mode)
    my $assignment_intent = {};
    if ($assignment_node->can('assignment_intent')) {
        my $intent = $assignment_node->assignment_intent;
        $assignment_intent = { %$intent } if ref($intent) eq 'HASH';
    }
    
    my $operator = $assignment_node->can('operator_symbol')
        ? $assignment_node->operator_symbol
        : undef;
    if ((!defined($operator) || $operator eq '') && ref($assignment_intent) eq 'HASH') {
        $operator = $assignment_intent->{operator_symbol};
    }
    if (($assignment_node->isa('FSM::CoreAST::PulseAssignment') || $assignment_node->can('pulse_cycles'))
            && (!defined($operator) || $operator eq '' || $operator eq '=')
            && $assignment_node->can('pulse_cycles')) {
        my $cycles = eval { $assignment_node->pulse_cycles };
        $operator = '<' . $cycles if defined $cycles && $cycles =~ /^\d+$/;
    }
    if (!defined($operator) || $operator !~ /^(?:<-|<=|=|<-=|<=\+|<[0-9]+)$/) {
        my $node_type = ref($assignment_node) || 'UNKNOWN';
        my $intent_operator = (ref($assignment_intent) eq 'HASH') ? ($assignment_intent->{operator_symbol} // 'UNDEF') : 'NO_INTENT';
        my $pulse_cycles = $assignment_node->can('pulse_cycles') ? (eval { $assignment_node->pulse_cycles } // 'UNDEF') : 'N/A';
        die "[FlattenedDT.pm][record_assignment_from_ast()] Missing or invalid operator_symbol for assignment node '$node_type' (resolved='$operator', intent='$intent_operator', pulse_cycles='$pulse_cycles')";
    }
    
    fsm_debug("  SEMANTIC ASSIGNMENT RESULT:", 3);
    fsm_debug("    LHS AST Node: " . ref($lhs_signal_ast), 3);
    fsm_debug("    LHS Name: " . $lhs_name, 3);
    fsm_debug("    RHS: $actual_rhs", 3);
    fsm_debug("    Operator: $operator", 3);
    fsm_debug("    Condition AST: " . (blessed($condition_ast) ? ref($condition_ast) : 'NOT_BLESSED'), 3);
    my $condition_signal_name = defined($condition_ast) ? $condition_ast->to_systemverilog() : 'UNDEFINED';
    fsm_debug("    Condition Signal Name: '$condition_signal_name'", 3);
    
    # Track this actual LHS/RHS pair for validation (still need strings for validation)
    $self->track_actual_lhs_rhs($lhs_name, $actual_rhs, "ast_assignment:$dt_name");
    
    # AST WEB: Use signal name as key but maintain AST mapping
    my $lhs_name_key = $lhs_name;
    
    # Record the assignment with the signal name as key
    push @{$self->{lhs_assignments}->{$lhs_name_key}}, {
        dt => $dt_name,
        lhs_ast => $lhs_signal_ast,           # Store the AST node
        conditions_ast => $condition_ast,      # Store condition AST
        rhs => $actual_rhs,
        operator => $operator,
        assignment_intent => $assignment_intent,
        source_provenance => ($assignment_node->can('source_provenance') ? $assignment_node->source_provenance : {}),
        output_exposure => ($assignment_node->can('output_exposure') ? $assignment_node->output_exposure : 'auto'),
        is_state_trans => 0
    };
    
    # Track this LHS with name key and maintain AST mapping
    $self->{all_lhs}->{$lhs_name_key} = 1;
    $self->{lhs_ast_map}->{$lhs_name_key} = $lhs_signal_ast;  # Map name to AST
    
    fsm_debug("*** PHASE1 ASSIGNMENT NODE COMPLETE (AST WEB) ***\n", 3);
}

sub record_transition_from_ast ($self, $dt_name, $transition_node, $condition_stack) {
    my $target_state = $transition_node->target_state;
    
    # Create condition expression as pure AST
my $condition_ast = $self->create_condition_expression($condition_stack);
    
    # Convert target state to state encoding value
    my $state_value = uc($target_state);
    
    # Track this actual LHS/RHS pair for validation
    $self->track_actual_lhs_rhs('next_state', $state_value, "ast_transition:$dt_name");
    
    # Record as assignment to next_state with both signal name and AST
    push @{$self->{lhs_assignments}->{next_state}}, {
        dt => $dt_name,
        conditions_ast => $condition_ast,      # Store the original AST
        rhs => $state_value,
        operator => '<-',
        assignment_intent => {
            operator_symbol => '<-',
            sequencing => 'clocked',
            register_style => 'output_named',
            assignment_family => 'state_transition',
        },
        source_provenance => {
            origin => 'state_transition',
            raw_target_state => $target_state,
        },
        output_exposure => 'auto',
        is_state_trans => 1
    };
    
    # Track next_state as LHS and create synthetic AST mapping
    $self->{all_lhs}->{next_state} = 1;
    
    # Create synthetic AST node for next_state if not already exists
    unless ($self->{lhs_ast_map}->{next_state}) {
        # Create a synthetic signal reference for next_state
        $self->{lhs_ast_map}->{next_state} = FSM::AST::Utils::signal_ref('next_state');
        fsm_debug("    Created synthetic AST node for next_state", 3);
    }
    
    my $condition_signal_name = defined($condition_ast) ? $condition_ast->to_systemverilog() : 'UNDEFINED';
    fsm_debug("    Recorded AST transition: next_state <= $state_value when (signal: '$condition_signal_name')", 3);
}

sub extract_rhs_from_expression ($self, $expr) {
    # Extract RHS value from expression nodes
    if ($expr->isa('FSM::CoreAST::Literal')) {
        return $expr->value;
    } elsif ($expr->isa('FSM::CoreAST::SignalRef')) {
        return $expr->signal->name;
    } elsif ($expr->isa('FSM::CoreAST::BinaryOp')) {
        my $left = $self->extract_rhs_from_expression($expr->left);
        my $right = $self->extract_rhs_from_expression($expr->right);
        return "$left " . $expr->operator . " $right";
    } elsif ($expr->isa('FSM::CoreAST::Concatenation')) {
        # Handle concatenation expressions: {a, b, c}
        my @operand_strings;
        for my $operand (@{$expr->operands}) {
            push @operand_strings, $self->extract_rhs_from_expression($operand);
        }
        return '{' . join(', ', @operand_strings) . '}';
    } else {
        # Try to get a meaningful name from the expression object
        my $expr_type = ref($expr);
        $expr_type =~ s/^.*:://;  # Remove package prefix
        return lc($expr_type) . '_expr';
    }
}

sub is_complex_expression ($self, $expr) {
    # Legacy string-based analysis - kept for backward compatibility
    # New code should use is_complex_ast() for AST-based analysis
    
    fsm_debug("COMPLEX_CHECK: Analyzing expression: '$expr'", 3);
    
    # Simple signal names are not complex
    if ($expr =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) {
        fsm_debug("COMPLEX_CHECK: Simple signal name - NOT complex: $expr", 3);
        return 0;
    }
    
    # Signal names with bit width annotations or output markers are not complex
    if ($expr =~ /^[a-zA-Z_][a-zA-Z0-9_]*['\>].*$/) {
        fsm_debug("COMPLEX_CHECK: Signal with width/output annotation - NOT complex: $expr", 3);
        return 0;
    }
    
    # Constants are not complex
    if ($expr =~ /^const_\d+b\d+$/) {
        fsm_debug("COMPLEX_CHECK: FSMGen constant - NOT complex: $expr", 3);
        return 0;
    }
    if ($expr =~ /^\d+$/) {
        fsm_debug("COMPLEX_CHECK: Decimal number - NOT complex: $expr", 3);
        return 0;
    }
    if ($expr =~ /^\d+'[bhd]\w+$/) {
        fsm_debug("COMPLEX_CHECK: Verilog literal - NOT complex: $expr", 3);
        return 0;
    }
    
    # Boolean values are not complex  
    if ($expr =~ /^1'b[01]$/) {
        fsm_debug("COMPLEX_CHECK: Boolean literal - NOT complex: $expr", 3);
        return 0;
    }
    
    # Everything else is considered complex
    fsm_debug("COMPLEX_CHECK: *** COMPLEX EXPRESSION DETECTED *** - '$expr'", 3);
    return 1;
}

sub is_complex_ast ($self, $ast) {
    # AST-based complexity analysis - preferred method
    # Determines if an AST node represents a complex expression needing intermediate signal
    
    return 0 unless $ast && blessed($ast);
    
    fsm_debug("COMPLEX_AST_CHECK: Analyzing AST: " . ref($ast));
    
    # Literals are never complex
    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        fsm_debug("COMPLEX_AST_CHECK: Literal - NOT complex", 3);
        return 0;
    }
    
    # Simple signal references are not complex
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        fsm_debug("COMPLEX_AST_CHECK: Signal reference - NOT complex", 3);
        return 0;
    }
    
    # Binary operations with simple operands might still be simple enough
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Check operator complexity
        my $op = $ast->operator;
        
        # Simple logical operations between signals are often worth inlining
        if ($op =~ /^(&&|\|\||&|\|)$/) {
            my $left_complex = $self->is_complex_ast($ast->left) if $ast->can('left');
            my $right_complex = $self->is_complex_ast($ast->right) if $ast->can('right');
            
            # If both operands are simple, the whole expression might be simple enough
            if (!$left_complex && !$right_complex) {
                fsm_debug("COMPLEX_AST_CHECK: Simple binary logical - NOT complex", 3);
                return 0;
            }
        }
        
        fsm_debug("COMPLEX_AST_CHECK: Complex binary operation - COMPLEX", 3);
        return 1;
    }
    
    # Unary operations are generally complex enough to factor
    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        # Simple negation of a signal reference might not need factoring
        if ($ast->can('operator') && $ast->can('operand')) {
            my $op = $ast->operator || 'unknown';
            if ($op =~ /^(!|not)$/) {
                my $operand = $ast->operand;
                if ($operand && blessed($operand) && 
                    ($operand->isa('FSM::AST::SignalRef') || $operand->isa('FSM::CoreAST::SignalRef'))) {
                    fsm_debug("COMPLEX_AST_CHECK: Simple negation - NOT complex", 3);
                    return 0;
                }
            }
        }
        
        fsm_debug("COMPLEX_AST_CHECK: Unary operation - COMPLEX", 3);
        return 1;
    }
    
    # Other node types are considered complex
    fsm_debug("COMPLEX_AST_CHECK: Unknown AST type - COMPLEX", 3);
    return 1;
}

sub get_or_create_global_expression ($self, $expression) {
    # Global expression factoring - reuse existing signals for identical expressions
    # This enables cross-DT sharing and avoids duplicating logic
    
    fsm_debug("GLOBAL_EXPR: Processing expression: '$expression'", 3);
    
    # Create a canonical representation for expression comparison
    my $canonical_expr = $self->canonicalize_expression($expression);
    fsm_debug("GLOBAL_EXPR: Canonical form: '$canonical_expr'", 3);
    
    # Check if we already have a signal for this expression
    if (exists $self->{global_expressions}->{$canonical_expr}) {
        my $existing_signal = $self->{global_expressions}->{$canonical_expr};
        
        # Increment usage count for optimization analysis
        $self->{expression_usage}->{$existing_signal}++;
        
        fsm_debug("GLOBAL_EXPR: *** REUSING EXISTING SIGNAL *** - $existing_signal for '$expression'", 3);
        fsm_debug("GLOBAL_EXPR: Usage count now: " . $self->{expression_usage}->{$existing_signal});
        return $existing_signal;
    }
    
    # Create a new signal name for this expression using NATIVE AST NAMING
    fsm_debug("GLOBAL_EXPR: Creating NEW signal for expression: '$expression'", 3);
    
    # Use native AST naming to avoid string parsing issues
    my $signal_name;
    
    # Try to parse the expression back into an AST for native naming
    my $ast = eval { $self->{expr_namer}->parse_expression($canonical_expr) };
    
    if ($ast) {
        # Use the new native AST complexity analysis
        my $complexity = $self->{expr_namer}->analyze_ast_complexity_native($ast);
        fsm_debug("GLOBAL_EXPR: AST complexity: logical_ops=" . $complexity->{has_logical_ops} . ", depth=" . $complexity->{depth});
        
        # Generate a systematic signal name from the AST structure
        $signal_name = $self->{expr_namer}->ast_to_systematic_name($ast);
        fsm_debug("GLOBAL_EXPR: Generated signal name from AST: '$signal_name'", 3);
    } else {
        # Fallback to string-based naming for expressions that can't be parsed
        fsm_debug("GLOBAL_EXPR: Could not parse expression, using string fallback", 3);
        $signal_name = $self->{expr_namer}->parse_and_name_expression($canonical_expr);
        fsm_debug("GLOBAL_EXPR: Generated signal name from string: '$signal_name'", 3);
    }
    
    # Register the mapping
    $self->{global_expressions}->{$canonical_expr} = $signal_name;
    $self->{expression_usage}->{$signal_name} = 1;
    $self->{intermediate_signals}->{$signal_name} = $canonical_expr;
    
    fsm_debug("GLOBAL_EXPR: *** CREATED NEW GLOBAL SIGNAL *** - $signal_name for '$expression'", 3);
    fsm_debug("GLOBAL_EXPR: Total global expressions now: " . scalar(keys %{$self->{global_expressions}}));
    return $signal_name;
}

sub canonicalize_expression ($self, $expression) {
    # Create a canonical form of the expression for comparison
    # This helps identify semantically identical expressions that can be factored
    
    # Remove extra whitespace
    $expression =~ s/\s+/ /g;
    $expression =~ s/^\s+|\s+$//g;
    
    # For now, use the cleaned expression as canonical form
    # In the future, this could be enhanced to:
    # - Normalize operator precedence: (a & b) | c vs a & b | c
    # - Handle commutativity: a + b vs b + a  
    # - Recognize equivalent forms: !(!a & !b) vs (a | b)
    
    return $expression;
}

sub should_factor_condition ($self, $condition_expr) {
    # Legacy string-based factorization - kept for compatibility
    # New code should use should_factor_ast() for AST-based analysis
    
    fsm_debug("FACTOR_CHECK: Analyzing condition expression: '$condition_expr'", 3);
    
    # Don't factor simple expressions
    if ($condition_expr eq "1'b1" || $condition_expr eq "1'b0") {
        fsm_debug("FACTOR_CHECK: Simple boolean literal - NOT factoring: $condition_expr", 3);
        return 0;
    }
    
    # Don't factor single signal references or simple negations
    if ($condition_expr =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/ || 
        $condition_expr =~ /^not_[a-zA-Z_][a-zA-Z0-9_]*_expr\d+$/) {
        fsm_debug("FACTOR_CHECK: Simple signal or negation - NOT factoring: $condition_expr", 3);
        return 0;
    }
    
    # Parse the expression into an AST to analyze complexity
    my $ast = eval { $self->{expr_namer}->parse_expression($condition_expr) };
    if (!$ast) {
        # If parsing fails, fall back to string-based heuristic
        fsm_debug("FACTOR_CHECK: Could not parse expression, using string heuristic", 3);
        return ($condition_expr =~ /\s+(&&|\|\||&|\|)\s+/);
    }
    
    # Factor if the AST represents a compound logical expression
    my $complexity = $self->analyze_ast_complexity($ast);
    if ($complexity->{has_logical_ops} && $complexity->{depth} > 1) {
        fsm_debug("FACTOR_CHECK: *** COMPLEX LOGICAL EXPRESSION *** - factoring: $condition_expr", 3);
        return 1;
    }
    
    # Don't factor by default
    fsm_debug("FACTOR_CHECK: Expression not complex enough - NOT factoring: $condition_expr", 3);
    return 0;
}

sub should_factor_ast ($self, $ast) {
    # AST-based factorization analysis - preferred method
    # Determines if an AST should be factored into an intermediate signal
    
    return 0 unless $ast && blessed($ast);
    
    fsm_debug("FACTOR_AST_CHECK: Analyzing AST: " . ref($ast));
    
    # Simple nodes should not be factored
    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        fsm_debug("FACTOR_AST_CHECK: Literal - NOT factoring", 3);
        return 0;
    }
    
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        fsm_debug("FACTOR_AST_CHECK: Signal reference - NOT factoring", 3);
        return 0;
    }
    
    # Complex expressions should be factored
    if ($self->is_complex_ast($ast)) {
        fsm_debug("FACTOR_AST_CHECK: Complex AST - FACTORING", 3);
        return 1;
    }
    
    fsm_debug("FACTOR_AST_CHECK: Simple AST - NOT factoring", 3);
    return 0;
}

sub analyze_ast_complexity ($self, $ast) {
    # Analyze AST complexity for factorization decisions
    # Returns: { has_logical_ops => bool, depth => int, node_count => int }
    
    my $result = {
        has_logical_ops => 0,
        depth => 0,
        node_count => 0
    };
    
    return $result unless $ast && ref($ast);
    
    $self->_traverse_ast_for_complexity($ast, $result, 1);
    
    return $result;
}

sub _traverse_ast_for_complexity ($self, $node, $result, $current_depth) {
    # Recursive traversal of AST to analyze complexity
    
    return unless $node && ref($node);
    
    $result->{node_count}++;
    $result->{depth} = $current_depth if $current_depth > $result->{depth};
    
    # Check if this is a logical operator node
    if (ref($node) eq 'HASH') {
        my $type = $node->{type} || '';
        my $op = $node->{operator} || $node->{op} || '';
        
        if ($type eq 'binary_op' && $op =~ /^(&&|\|\||&|\|)$/) {
            $result->{has_logical_ops} = 1;
        }
        
        # Traverse children
        for my $key (qw(left right operand children)) {
            if ($node->{$key}) {
                if (ref($node->{$key}) eq 'ARRAY') {
                    for my $child (@{$node->{$key}}) {
                        $self->_traverse_ast_for_complexity($child, $result, $current_depth + 1);
                    }
                } else {
                    $self->_traverse_ast_for_complexity($node->{$key}, $result, $current_depth + 1);
                }
            }
        }
    } elsif ($node->can('operator') && $node->can('left') && $node->can('right')) {
        # Handle object-based AST nodes
        my $op = eval { $node->operator } || '';
        if ($op =~ /^(&&|\|\||&|\|)$/) {
            $result->{has_logical_ops} = 1;
        }
        
        $self->_traverse_ast_for_complexity($node->left, $result, $current_depth + 1) if $node->can('left');
        $self->_traverse_ast_for_complexity($node->right, $result, $current_depth + 1) if $node->can('right');
    } elsif ($node->can('operand')) {
# Ensure intermediate signals are generated
        $self->_traverse_ast_for_complexity($node->operand, $result, $current_depth + 1);
    }
}

sub needs_parentheses ($self, $expression) {
    # Determine if an expression needs parentheses when used in a binary operation
    # Only add parentheses for complex expressions that contain operators
    
    return 0 unless $expression;
    
    # Simple signal names don't need parentheses
    if ($expression =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) {
        return 0;
    }
    
    # Simple literals don't need parentheses
    if ($expression =~ /^\d+'[bhd]\w+$/ || $expression =~ /^\d+$/ || $expression =~ /^1'b[01]$/) {
        return 0;
    }
    
    # Intermediate signal names don't need parentheses
    if ($expression =~ /^[a-zA-Z_][a-zA-Z0-9_]*_expr\d*$/) {
        return 0;
    }
    
    # Generated intermediate signal names (including those from expression namer) don't need parentheses
    if ($expression =~ /^[a-zA-Z_][a-zA-Z0-9_]*(_active|_expr|_and_|_or_|_not_)/) {
        return 0;
    }
    
    # Already parenthesized expressions don't need additional parentheses
    if ($expression =~ /^\(.+\)$/) {
        return 0;
    }
    
    # Expressions with operators need parentheses
    if ($expression =~ /\s+(&&|\|\||[&|+*\/-]|==|!=|[<>]=?)\s+/) {
        return 1;
    }
    
    # Everything else doesn't need parentheses
    return 0;
}

sub clean_intermediate_expression ($self, $expression) {
    # Clean up intermediate expressions to ensure valid SystemVerilog syntax
    
    fsm_debug("CLEAN_EXPR: Input expression: '$expression'", 3);
    
    # Remove outer parentheses if present
    $expression =~ s/^\((.+)\)$/$1/;
    
    # Fix common syntax issues
    # 1. Fix "& &" -> "&&"
    $expression =~ s/\s*&\s*&\s*/&&/g;
    
    # 2. Fix "| |" -> "||"
    $expression =~ s/\s*\|\s*\|\s*/||/g;
    
    # 3. Remove trailing or leading & or | operators
    $expression =~ s/\s*[&|]\s*$//;
    $expression =~ s/^\s*[&|]\s*//;
    
    # 4. Fix unbalanced parentheses by counting and balancing
    my $open_count = ($expression =~ tr/\(//); 
    my $close_count = ($expression =~ tr/\)//); 
    
    if ($open_count > $close_count) {
        # Add missing closing parentheses
        $expression .= ')' x ($open_count - $close_count);
    } elsif ($close_count > $open_count) {
        # Add missing opening parentheses
        $expression = '(' x ($close_count - $open_count) . $expression;
    }
    
    # 5. Fix sequences like "expr &" or "& expr" 
    $expression =~ s/\s*&\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*&/ && $1/g;
    $expression =~ s/([a-zA-Z_][a-zA-Z0-9_]*)\s*&\s*&/$1 &&/g;
    
    # 6. Clean up multiple consecutive spaces
    $expression =~ s/\s+/ /g;
    $expression =~ s/^\s+|\s+$//g;
    
    # 7. Fix issues where operators are misplaced
    # Replace patterns like "signal &)" with "signal)"
    $expression =~ s/([a-zA-Z_][a-zA-Z0-9_]*)\s*[&|]\s*\)/$1)/g;
    
    # Replace patterns like "(& signal" with "(signal"
    $expression =~ s/\(\s*[&|]\s*([a-zA-Z_][a-zA-Z0-9_]*)/(signal/g;
    
    fsm_debug("CLEAN_EXPR: Output expression: '$expression'", 3);
    
    return $expression;
}

# LHS/RHS tracking and validation methods
sub track_expected_lhs_rhs ($self, $lhs, $rhs, $context) {
    # Track an expected LHS/RHS pair from FSM parsing
    my $key = "$lhs:$rhs";
    $self->{expected_lhs_rhs}->{$key} = {
        lhs => $lhs,
        rhs => $rhs,
        context => $context,
        seen_count => ($self->{expected_lhs_rhs}->{$key}->{seen_count} || 0) + 1
    };
    
    fsm_debug("EXPECTED_LHS_RHS: Tracking $key (count: $self->{expected_lhs_rhs}->{$key}->{seen_count}) from $context", 3);
}

sub track_actual_lhs_rhs ($self, $lhs, $rhs, $context) {
    # Track an actual LHS/RHS pair that made it to HDL generation
    my $key = "$lhs:$rhs";
    $self->{actual_lhs_rhs}->{$key} = {
        lhs => $lhs,
        rhs => $rhs,
        context => $context,
        seen_count => ($self->{actual_lhs_rhs}->{$key}->{seen_count} || 0) + 1
    };
    
    fsm_debug("ACTUAL_LHS_RHS: Tracking $key (count: $self->{actual_lhs_rhs}->{$key}->{seen_count}) from $context", 3);
}

sub validate_lhs_rhs_completeness ($self) {
    # Validate that all expected LHS/RHS pairs made it through the pipeline
    
    fsm_debug("\n*** LHS/RHS COMPLETENESS VALIDATION ***", 3);
    
    my @missing_pairs = ();
    my @extra_pairs = ();
    
    # Check for missing pairs (expected but not actual)
    for my $expected_key (keys %{$self->{expected_lhs_rhs}}) {
        if (!exists $self->{actual_lhs_rhs}->{$expected_key}) {
            my $pair_info = $self->{expected_lhs_rhs}->{$expected_key};
            push @missing_pairs, {
                key => $expected_key,
                lhs => $pair_info->{lhs},
                rhs => $pair_info->{rhs},
                context => $pair_info->{context},
                count => $pair_info->{seen_count}
            };
            
            # Track in missing hash for debugging
            $self->{missing_lhs_rhs}->{$expected_key} = $pair_info;
        }
    }
    
    # Check for extra pairs (actual but not expected)
    for my $actual_key (keys %{$self->{actual_lhs_rhs}}) {
        if (!exists $self->{expected_lhs_rhs}->{$actual_key}) {
            my $pair_info = $self->{actual_lhs_rhs}->{$actual_key};
            push @extra_pairs, {
                key => $actual_key,
                lhs => $pair_info->{lhs},
                rhs => $pair_info->{rhs},
                context => $pair_info->{context},
                count => $pair_info->{seen_count}
            };
        }
    }
    
    # Report results
    my $expected_count = scalar(keys %{$self->{expected_lhs_rhs}});
    my $actual_count = scalar(keys %{$self->{actual_lhs_rhs}});
    my $missing_count = scalar(@missing_pairs);
    my $extra_count = scalar(@extra_pairs);
    
    fsm_debug("Expected LHS/RHS pairs: $expected_count", 3);
    fsm_debug("Actual LHS/RHS pairs: $actual_count", 3);
    fsm_debug("Missing pairs: $missing_count", 3);
    fsm_debug("Extra pairs: $extra_count", 3);
    
    if (@missing_pairs) {
        fsm_debug("\n*** CRITICAL: MISSING LHS/RHS PAIRS DETECTED ***", 3);
        for my $missing (@missing_pairs) {
            fsm_debug("  MISSING: $missing->{lhs} <- $missing->{rhs} (count: $missing->{count}, context: $missing->{context})", 3);
        }
    }
    
    if (@extra_pairs) {
        fsm_debug("\n*** WARNING: EXTRA LHS/RHS PAIRS DETECTED ***", 3);
        for my $extra (@extra_pairs) {
            fsm_debug("  EXTRA: $extra->{lhs} <- $extra->{rhs} (count: $extra->{count}, context: $extra->{context})", 3);
        }
    }
    
    if (!@missing_pairs && !@extra_pairs) {
        fsm_debug("\n*** SUCCESS: All LHS/RHS pairs validated successfully! ***", 3);
    }
    
    return {
        success => (!@missing_pairs && !@extra_pairs),
        missing_pairs => \@missing_pairs,
        extra_pairs => \@extra_pairs,
        expected_count => $expected_count,
        actual_count => $actual_count
    };
}

sub extract_lhs_rhs_from_raw_ast ($self, $raw_ast) {
    # Extract all LHS/RHS pairs directly from the raw AST for validation
    # This bypasses the FSMGen adapter to get ground truth
    
    fsm_debug("\n*** EXTRACTING LHS/RHS FROM RAW AST ***", 3);
    
    $self->_traverse_raw_ast_for_lhs_rhs($raw_ast, "root");
    
    my $count = scalar(keys %{$self->{expected_lhs_rhs}});
    fsm_debug("Extracted $count unique LHS/RHS pairs from raw AST", 3);
}

sub _traverse_raw_ast_for_lhs_rhs {
    my ($self, $node, $context) = @_;
    return unless defined $node;

    if (ref $node eq 'ARRAY') {
        # Check for our specific assignment pattern: [LHS, [OPERATOR, RHS]]
        if (@$node == 2 &&
            (ref($node->[0]) eq '' || (ref($node->[0]) eq 'SCALAR' && ${$node->[0]})) &&
            ref($node->[1]) eq 'ARRAY' &&
            @{$node->[1]} >= 1 &&
            (
                $node->[1][0] eq '<-'  ||
                $node->[1][0] eq '<='  ||
                $node->[1][0] eq '<-=' ||
                $node->[1][0] eq '<=+' ||
                $node->[1][0] eq '='   ||
                $node->[1][0] =~ /^<\d+$/
            ))
        {
            my $lhs = ref($node->[0]) eq 'SCALAR' ? ${$node->[0]} : $node->[0];
            my $op = $node->[1][0];
            my $rhs_node = @{$node->[1]} > 1 ? $node->[1][1] : '';

            # Clean up LHS for consistent tracking
            $lhs =~ s/'\d+$//;      # Remove 'N width annotation
            $lhs =~ s/>$//;         # Remove > output marker
            $lhs =~ s/\\//g;        # Remove any backslash escapes

            # Recursively format the RHS to handle nested s-expressions
            my $rhs_str = $self->_format_raw_rhs($rhs_node);
            
            $self->track_expected_lhs_rhs($lhs, $rhs_str, "raw_ast:$context");
        }

        # Always traverse children to find nested assignments
        for my $child (@$node) {
            $self->_traverse_raw_ast_for_lhs_rhs($child, $context . '[]');
        }
    }
    elsif (ref $node eq 'HASH') {
        for my $key (keys %$node) {
            $self->_traverse_raw_ast_for_lhs_rhs($node->{$key}, "$context\{$key\}");
        }
    }
}

sub _format_raw_rhs {
    my ($self, $rhs_node) = @_;
    return '' unless defined $rhs_node;

    if (ref $rhs_node eq 'ARRAY') {
        return '(' . (join " ", map { $self->_format_raw_rhs($_) } @$rhs_node) . ')';
    }
    
    return $rhs_node;
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
    # AST-based SystemVerilog generation with:
    # - Logical -> bitwise operator conversion for 1-bit operands
    # - Correct precedence-based parentheses insertion
    return "0" unless $ast && blessed($ast);
    
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $name = $self->extract_signal_name_from_ast($ast);
        return $name || "unknown_signal";
        
    } elsif ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        return $ast->value || "0";
        
    } elsif ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp') || $ast->isa('FSM::HDL::SubstitutedBinaryOp')) {
        return $self->_render_binary_op($ast, $parent_precedence);
        
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp') || $ast->isa('FSM::HDL::SubstitutedUnaryOp')) {
        return $self->_render_unary_op($ast);
        
    } elsif ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        # Handle intermediate signal references from AST factorization
        return $ast->signal_name || "unknown_intermediate_signal";
        
    } else {
        # Handle unknown node types - TRY calling their to_systemverilog method first
        # If they have one, use it; otherwise fall back to safe alternative
        my $node_type = ref($ast) || 'UNKNOWN';
        
        # First try: check if the node has a to_systemverilog method
        if ($ast->can('to_systemverilog')) {
            my $sv_result = eval { $ast->to_systemverilog() };
            if ($sv_result && $sv_result !~ /^unknown_expr_/) {
                fsm_debug("AST_TO_CLEAN_SV: Using to_systemverilog() method for '$node_type': $sv_result", 3);
                return $sv_result;
            } else {
                fsm_debug("AST_TO_CLEAN_SV: to_systemverilog() failed for '$node_type', using fallback", 3);
            }
        } else {
            fsm_debug("AST_TO_CLEAN_SV: No to_systemverilog() method for '$node_type'", 3);
        }
        
        # Second try: check if it's a known node type with specific handling
        if ($node_type =~ /BinaryOp$/) {
            # Try to handle as a binary operation even if it's an unknown subclass
            return $self->_render_binary_op($ast, $parent_precedence);
        } elsif ($node_type =~ /UnaryOp$/) {
            # Try to handle as a unary operation even if it's an unknown subclass  
            return $self->_render_unary_op($ast);
        } elsif ($node_type =~ /SignalRef$/) {
            # Try to extract signal name even if it's an unknown subclass
            my $name = $self->extract_signal_name_from_ast($ast);
            return $name || "unknown_signal";
        } elsif ($node_type =~ /Literal$/) {
            # Try to get value even if it's an unknown subclass
            my $value = eval { $ast->value } || "0";
            return $value;
        }
        
        # Final fallback - return safe placeholder  
        fsm_debug("AST_TO_CLEAN_SV: Unknown AST node type '$node_type' - using safe fallback", 3);
        return "unknown_expr_" . lc($node_type =~ s/.*:://r);
    }
}

sub _render_binary_op ($self, $ast, $parent_precedence) {
    my $operator = eval { $ast->operator } || 'unknown';
    my $left = $ast->left;
    my $right = $ast->right;
    
    # Get precedence for this operator
    my $my_precedence = $self->_get_operator_precedence($operator);
    
    # Convert operands recursively
    my $left_sv = $self->_ast_to_systemverilog_internal($left, $my_precedence);
    my $right_sv = $self->_ast_to_systemverilog_internal($right, $my_precedence);
    
    # Choose the right operator symbol
    my $op_symbol = $self->_choose_operator_symbol($operator, $left, $right);
    
    # *** OPERATOR DEBUG: Log the operator choice decision ***
    fsm_debug("*** OPERATOR_CHOICE_DEBUG: ***", 3);
    fsm_debug("  Original operator: '$operator'", 3);
    fsm_debug("  Chosen symbol: '$op_symbol'", 3);
    fsm_debug("  Left operand: '$left_sv' (AST type: " . (blessed($left) ? ref($left) : 'UNBLESSED') . ")", 3);
    fsm_debug("  Right operand: '$right_sv' (AST type: " . (blessed($right) ? ref($right) : 'UNBLESSED') . ")", 3);
    fsm_debug("  Left is 1-bit: " . ($self->_operand_is_single_bit($left) ? 'YES' : 'NO'), 3);
    fsm_debug("  Right is 1-bit: " . ($self->_operand_is_single_bit($right) ? 'YES' : 'NO'), 3);
    
    # Build expression
    my $expr = "$left_sv $op_symbol $right_sv";
    
    fsm_debug("  Final expression: '$expr'", 3);
    fsm_debug("*** END OPERATOR_CHOICE_DEBUG ***", 3);
    
    # Add parentheses only if needed based on precedence
    if ($self->_needs_parentheses($my_precedence, $parent_precedence)) {
        return "($expr)";
    } else {
        return $expr;
    }
}

sub _render_unary_op ($self, $ast) {
    my $operator = eval { $ast->operator } || 'not';
    my $operand = $ast->operand;
    
    # Convert operand recursively - unary ops have high precedence
    my $operand_sv = $self->_ast_to_systemverilog_internal($operand, 10);
    
    # Map operator to symbol
    my $op_symbol = $self->_map_unary_operator($operator);
    
    # For negation, use parentheses around operand only if it's complex
    if ($operator eq 'not' || $operator eq '!') {
        if ($self->_operand_needs_parens_for_negation($operand)) {
            return "!($operand_sv)";
        } else {
            return "!$operand_sv";
        }
    } else {
        return "$op_symbol($operand_sv)";
    }
}

sub _choose_operator_symbol ($self, $operator, $left, $right) {
    # Choose between logical and bitwise operators based on operand analysis
    
    fsm_debug("_choose_operator_symbol: Entering with operator '$operator'", 3);
    
    my $left_name = undef;
    my $right_name = undef;
    my $left_width = undef;
    my $right_width = undef;
    
    # Extract signal names using robust helper function
    if ($left && blessed($left)) {
        $left_name = $self->extract_signal_name_from_ast($left);
        if ($left_name) {
            fsm_debug("_choose_operator_symbol: Extracted left signal name: '$left_name'", 3);
            if ($self->{fsm_module} && $self->{fsm_module}->signals) {
                fsm_debug("_choose_operator_symbol: FSM module has " . scalar(keys %{$self->{fsm_module}->signals}) . " signals", 3);
                if ($self->{fsm_module}->signals->{$left_name}) {
                    my $sig = $self->{fsm_module}->signals->{$left_name};
                    fsm_debug("_choose_operator_symbol: Found left signal '$left_name' in FSM signals", 3);
                    fsm_debug("_choose_operator_symbol: Left signal object type: " . ref($sig), 3);
                    if ($sig->can('width')) {
                        $left_width = $sig->width;
                        fsm_debug("_choose_operator_symbol: Left signal width from method: " . (defined $left_width ? $left_width : 'undef'), 3);
                    } else {
                        fsm_debug("_choose_operator_symbol: Left signal has no width() method", 3);
                    }
                } else {
                    fsm_debug("_choose_operator_symbol: Left signal '$left_name' NOT found in FSM signals", 3);
                    # Debug: show first 10 available signals
                    my @available = keys %{$self->{fsm_module}->signals};
                    my @first_10 = sort @available[0..min(9, $#available)];
                    fsm_debug("_choose_operator_symbol: Available signals: " . join(", ", @first_10), 3);
                }
            } else {
                fsm_debug("_choose_operator_symbol: No FSM module or signals available", 3);
            }
        }
    }
    if ($right && blessed($right)) {
        $right_name = $self->extract_signal_name_from_ast($right);
        if ($right_name) {
            fsm_debug("_choose_operator_symbol: Extracted right signal name: '$right_name'", 3);
            if ($self->{fsm_module} && $self->{fsm_module}->signals) {
                if ($self->{fsm_module}->signals->{$right_name}) {
                    my $sig = $self->{fsm_module}->signals->{$right_name};
                    fsm_debug("_choose_operator_symbol: Found right signal '$right_name' in FSM signals", 3);
                    fsm_debug("_choose_operator_symbol: Right signal object type: " . ref($sig), 3);
                    if ($sig->can('width')) {
                        $right_width = $sig->width;
                        fsm_debug("_choose_operator_symbol: Right signal width from method: " . (defined $right_width ? $right_width : 'undef'), 3);
                    } else {
                        fsm_debug("_choose_operator_symbol: Right signal has no width() method", 3);
                    }
                } else {
                    fsm_debug("_choose_operator_symbol: Right signal '$right_name' NOT found in FSM signals", 3);
                }
            } else {
                fsm_debug("_choose_operator_symbol: No FSM module or signals available", 3);
            }
        }
    }
    
    fsm_debug("_choose_operator_symbol: Left operand name: " . ($left_name // 'undef') . ", width: " . (defined $left_width ? $left_width : 'undef'), 3);
    fsm_debug("_choose_operator_symbol: Right operand name: " . ($right_name // 'undef') . ", width: " . (defined $right_width ? $right_width : 'undef'), 3);

    if ($operator eq '&&') {
        if ($self->_operand_is_single_bit($left) && $self->_operand_is_single_bit($right)) {
            fsm_debug("_choose_operator_symbol: Both operands single-bit, using '&'", 3);
            return '&';
        } else {
            fsm_debug("_choose_operator_symbol: Operands not both single-bit, using '&&'", 3);
            return '&&';
        }
    } elsif ($operator eq '||') {
        if ($self->_operand_is_single_bit($left) && $self->_operand_is_single_bit($right)) {
            fsm_debug("_choose_operator_symbol: Both operands single-bit, using '|'", 3);
            return '|';
        } else {
            fsm_debug("_choose_operator_symbol: Operands not both single-bit, using '||'", 3);
            return '||';
        }
    } else {
        fsm_debug("_choose_operator_symbol: Using standard operator mapping for '$operator'", 3);
        return $self->_map_binary_operator($operator);
    }
}

sub _operand_is_single_bit ($self, $ast) {
    # Determine if an AST operand represents a 1-bit value
    fsm_debug("    OPERAND_BIT_CHECK: Checking if operand is single-bit", 3);
    fsm_debug("      AST defined: " . (defined($ast) ? 'YES' : 'NO'), 3);
    fsm_debug("      AST blessed: " . (blessed($ast) ? 'YES' : 'NO'), 3);
    
    unless ($ast && blessed($ast)) {
        fsm_debug("      RESULT: NOT single-bit (undefined or not blessed)", 3);
        return 0;
    }
    
    fsm_debug("      AST type: " . ref($ast), 3);
    
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        fsm_debug("      PATH: Regular SignalRef", 3);
        my $name = $self->extract_signal_name_from_ast($ast);
        fsm_debug("      Signal name: '" . ($name || 'UNDEFINED') . "'", 3);
        my $result = $self->_signal_is_single_bit($name);
        fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (via _signal_is_single_bit)", 3);
        return $result;
        
    } elsif ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        fsm_debug("      PATH: Literal", 3);
        my $value = eval { $ast->value } || '';
        fsm_debug("      Literal value: '$value'", 3);
        # 1-bit literals: 1'b0, 1'b1, plain 0, plain 1
        if ($value =~ /^1'b[01]$/ || $value =~ /^[01]$/) {
            fsm_debug("      RESULT: single-bit (1-bit literal)", 3);
            return 1;
        } else {
            fsm_debug("      RESULT: multi-bit (multi-bit literal)", 3);
            return 0;
        }
        
    } elsif ($ast->isa('FSM::AST::IndexedRef') || $ast->isa('FSM::CoreAST::IndexedRef')) {
        fsm_debug("      PATH: IndexedRef", 3);
        fsm_debug("      RESULT: single-bit (bit indexing)", 3);
        # Bit indexing produces 1-bit result
        return 1;
        
    } elsif ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        fsm_debug("      PATH: BinaryOp", 3);
        my $op = eval { $ast->operator } || '';
        fsm_debug("      Binary operator: '$op'", 3);
        # Comparison operators produce 1-bit boolean results
        if ($op =~ /^(==|!=|<|>|<=|>=)$/) {
            fsm_debug("      RESULT: single-bit (comparison operator)", 3);
            return 1;
        }
        # Logical operators on 1-bit inputs produce 1-bit results
        if ($op =~ /^(&&|\|\||&|\|)$/) {
            fsm_debug("      Checking logical operator operands recursively...", 3);
            my $left_result = $self->_operand_is_single_bit($ast->left);
            my $right_result = $self->_operand_is_single_bit($ast->right);
            my $result = $left_result && $right_result;
            fsm_debug("      Left operand 1-bit: $left_result, Right operand 1-bit: $right_result", 3);
            fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (logical op on 1-bit inputs)", 3);
            return $result;
        }
        fsm_debug("      RESULT: multi-bit (other binary operator)", 3);
        return 0;
        
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        fsm_debug("      PATH: UnaryOp", 3);
        my $op = eval { $ast->operator } || '';
        fsm_debug("      Unary operator: '$op'", 3);
        # Logical NOT on 1-bit input produces 1-bit result
        if ($op eq 'not' || $op eq '!') {
            fsm_debug("      RESULT: single-bit (logical NOT)", 3);
            return 1;
        } else {
            fsm_debug("      RESULT: multi-bit (other unary operator)", 3);
            return 0;
        }
        
    } elsif ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        fsm_debug("      PATH: IntermediateSignalRef", 3);
        # Intermediate signals from AST factorization represent boolean conditions
        # They are always 1-bit (boolean results of AND/OR/NOT operations)
        my $signal_name = eval { $ast->signal_name } || 'UNKNOWN';
        fsm_debug("      Intermediate signal name: '$signal_name'", 3);
        fsm_debug("      RESULT: single-bit (intermediate signals are always boolean)", 3);
        return 1;
    } else {
        fsm_debug("      PATH: Unknown AST type - " . ref($ast), 3);
        fsm_debug("      RESULT: multi-bit (unknown type fallback)", 3);
    }
    
    fsm_debug("      RESULT: multi-bit (default fallback)", 3);
    return 0;
}

sub _signal_is_single_bit ($self, $name) {
    fsm_debug("    SIGNAL_IS_1BIT: Checking if signal '$name' is single-bit", 3);
    
    unless (defined $name) {
        fsm_debug("      RESULT: NOT single-bit (undefined name)", 3);
        return 0;
    }
    
    # Check FSM module signal info if available
    if ($self->{fsm_module} && $self->{fsm_module}->signals && $self->{fsm_module}->signals->{$name}) {
        fsm_debug("      PATH: Found signal in FSM module", 3);
        my $signal = $self->{fsm_module}->signals->{$name};
        fsm_debug("      Signal object type: " . ref($signal), 3);
        
        if ($signal->can('width')) {
            my $width = $signal->width;
            fsm_debug("      FSM module signal width: " . (defined($width) ? $width : 'UNDEFINED'), 3);
            my $result = (!$width || $width == 1) ? 1 : 0;
            fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (from FSM module)", 3);
            return $result;
        } else {
            fsm_debug("      Signal has no width() method", 3);
        }
    } else {
        fsm_debug("      PATH: Signal not found in FSM module (using heuristics)", 3);
        if (!$self->{fsm_module}) {
            fsm_debug("        Reason: No FSM module available", 3);
        } elsif (!$self->{fsm_module}->signals) {
            fsm_debug("        Reason: FSM module has no signals", 3);
        } else {
            fsm_debug("        Reason: Signal '$name' not in FSM module signals", 3);
            # Debug: list available signals
            my @available = keys %{$self->{fsm_module}->signals};
            my $count = scalar(@available);
            fsm_debug("        Available signals ($count): " . join(", ", sort @available), 3);
        }
    }
    
    # Check if this is an intermediate signal (should be 1-bit)
    if ($self->is_intermediate_signal($name)) {
        fsm_debug("      PATH: Intermediate signal (assuming 1-bit)", 3);
        fsm_debug("      RESULT: single-bit (intermediate signals are boolean)", 3);
        return 1;
    }
    
    
    if ($name =~ /^current_state$/) {
        fsm_debug("      PATH: State comparison signal", 3);
        fsm_debug("      RESULT: single-bit (state comparison)", 3);
        return 1;
    }
    
    # Default: assume multi-bit to be safe
    fsm_debug("      PATH: Default fallback", 3);
    fsm_debug("      RESULT: multi-bit (conservative default)", 3);
    return 0;
}

sub _get_operator_precedence ($self, $operator) {
    # SystemVerilog operator precedence (higher number = higher precedence)
    my %precedence = (
        '||' => 1, '|'  => 2,
        '&&' => 3, '&'  => 4,
        '==' => 5, '!=' => 5, '<' => 5, '>' => 5, '<=' => 5, '>=' => 5,
        '+'  => 6, '-'  => 6,
        '*'  => 7, '/'  => 7, '%' => 7,
        '<<' => 8, '>>' => 8,
        '^'  => 9,
    );
    return $precedence{$operator} || 5;
}

sub _needs_parentheses ($self, $my_precedence, $parent_precedence) {
    # Need parentheses if my precedence is lower than parent's
    return 0 unless defined $parent_precedence;
    return $my_precedence < $parent_precedence;
}

sub _map_binary_operator ($self, $operator) {
    # Standard operator symbol mapping
    my %op_map = (
        'eq' => '==', 'ne' => '!=', 'lt' => '<', 'gt' => '>', 'le' => '<=', 'ge' => '>=',
        'add' => '+', 'sub' => '-', 'mul' => '*', 'div' => '/', 'mod' => '%',
        'and' => '&', 'or' => '|', 'xor' => '^',
        'shl' => '<<', 'shr' => '>>', 'sal' => '<<<', 'sar' => '>>>'
    );
    return $op_map{$operator} || $operator;
}

sub _map_unary_operator ($self, $operator) {
    my %op_map = ( 'not' => '!', 'neg' => '-', 'pos' => '+' );
    return $op_map{$operator} || $operator;
}

sub _operand_needs_parens_for_negation ($self, $operand) {
    # Only complex expressions need parentheses after negation
    return 0 unless $operand && blessed($operand);
    
    # Simple signals and literals don't need parens
    return 0 if $operand->isa('FSM::AST::SignalRef') || $operand->isa('FSM::CoreAST::SignalRef');
    return 0 if $operand->isa('FSM::AST::Literal') || $operand->isa('FSM::CoreAST::Literal');
    return 0 if $operand->isa('FSM::AST::IndexedRef') || $operand->isa('FSM::CoreAST::IndexedRef');
    
    # Complex expressions need parens
    return 1;
}

sub parentheses_are_redundant ($self, $inner_expr) {
    # Check if outer parentheses are redundant for the given expression
    # Only remove if the inner expression doesn't have precedence issues
    
    # Simple expressions don't need parentheses
    return 1 if $inner_expr =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/; # signal names
    return 1 if $inner_expr =~ /^\d+'[bhd]\w*$/; # literals
    return 1 if $inner_expr =~ /^1'b[01]$/; # boolean literals
    
    # Expressions that are already intermediate signals don't need extra parentheses
    return 1 if $self->is_intermediate_signal($inner_expr);
    
    # For complex expressions, keep the parentheses to be safe
    return 0;
}

sub schedule_intermediate_signal_for_declaration ($self, $signal_name, $expression) {
    # Schedule an intermediate signal for declaration in the generated HDL
    $self->{intermediate_signals_to_declare} //= {};
    $self->{intermediate_signals_to_declare}->{$signal_name} = {
        name => $signal_name,
        expression => $expression,
        width => 1,  # Default to 1-bit for now
        declared => 0
    };
    
    fsm_debug("SCHEDULED_INTERMEDIATE: $signal_name = $expression", 3);
}

sub generate_intermediate_signal_declarations ($self) {
    return $self->{backend_sv}->generate_intermediate_signal_declarations();
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

sub should_filter_string_based ($self, $expression, $signal_name, $signal_info) {
    return $self->{backend_sv}->should_filter_string_based($expression, $signal_name, $signal_info);
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

sub extract_intermediate_signals_from_expression ($self, $expression) {
    return $self->{backend_sv}->extract_intermediate_signals_from_expression($expression);
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

sub get_combinational_lhs_signals {
    my ($self) = @_;
    
    fsm_debug("GET_COMB_LHS: Identifying combinational LHS signals needing wire declarations", 3);
    
    my %combinational_lhs_signals;
    
    # Check each LHS signal from the unified analysis
    if ($self->{assignment_analysis}) {
        for my $lhs_name_key (keys %{$self->{assignment_analysis}}) {
            my $lhs_analysis = $self->{assignment_analysis}{$lhs_name_key};
            my $multiplexer = $lhs_analysis->{multiplexer};
            my $lhs_ast = $lhs_analysis->{lhs_ast};
            
            # Skip if this is a register (flop) - those don't need wire declarations
            if ($multiplexer && $multiplexer->{type} && $multiplexer->{type} eq 'comb') {
                # This is a combinational signal that needs a wire declaration
                my $width = 1; # Default width
                
                # Try to get width from the AST node if available
                if ($lhs_ast && blessed($lhs_ast) && $lhs_ast->can('width')) {
                    my $ast_width = $lhs_ast->width();
                    $width = $ast_width if ($ast_width && $ast_width > 0);
                }
                
                $combinational_lhs_signals{$lhs_name_key} = {
                    width => $width,
                    ast => $lhs_ast
                };
                
                fsm_debug("  Found combinational LHS signal: $lhs_name_key (width: $width)", 3);
            }
        }
    }
    
    my $count = scalar(keys %combinational_lhs_signals);
    fsm_debug("GET_COMB_LHS: Found $count combinational LHS signals needing wire declarations", 3);
    
    return %combinational_lhs_signals;
}

sub topologically_sort_signals {
    my ($self, $filtered_signals, $signal_dependencies) = @_;
    return $self->{backend_sv}->topologically_sort_signals($filtered_signals, $signal_dependencies);
}

1;
