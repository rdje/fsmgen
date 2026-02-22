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
    
    return $self;
}


sub generate_systemverilog ($self, $fsm_module) {
    fsm_debug("Starting flattened DT SystemVerilog generation for " . $fsm_module->name, 3);
    fsm_debug("\n*** PIPELINE TIMING DEBUG: HDL Generation Pipeline Start ***", 3);
    
    # Step 0: Store FSM module reference for proper signal and reset value analysis
    $self->set_fsm_module_reference($fsm_module);
    fsm_debug("Step 0 - FSM module reference stored", 3);
    
    # Step 1: Analyze and flatten all decision trees
    $self->flatten_all_decision_trees($fsm_module);
    fsm_debug("Step 1 - Decision trees flattened", 3);
    
    # Step 2: Generate SystemVerilog with enable-based methodology
    my $hdl = $self->generate_header($fsm_module);
    $hdl .= $self->generate_module_declaration($fsm_module);
    $hdl .= $self->generate_state_encoding($fsm_module);
    $hdl .= $self->generate_state_register($fsm_module);
    $hdl .= $self->generate_internal_signal_declarations($fsm_module);
    fsm_debug("Step 2 - Basic HDL structure generated", 3);
    
    # Step 3: Generate enable conditions FIRST (this will track intermediate signal requirements)
    $hdl .= $self->generate_enable_conditions($fsm_module);
    fsm_debug("Step 3 - Enable conditions generated", 3);
    
    # TIMING FIX: Count logical operations BEFORE any intermediate signal creation!
    fsm_debug("\n*** TIMING FIX: Running logical operation counting BEFORE pre-scan ***", 3);
    $self->count_binary_logical_operation_occurrences();
    fsm_debug("Step 4 - Logical operation counting completed (BEFORE pre-scan!)", 3);
    
    # Step 5: PRE-SCAN all WEN/EN expressions to identify needed intermediate signals (now with counts available)
    $self->prescan_wen_en_for_intermediate_signals();
    fsm_debug("Step 5 - PRE-SCAN completed (AFTER logical operation counting!)", 3);
    
    # Step 6: Generate consolidated intermediate signals (combining AST factorization + pre-scan)
    $hdl .= $self->generate_consolidated_intermediate_signals($fsm_module);
    fsm_debug("Step 6 - Consolidated intermediate signals generated", 3);
    
    # Step 7: Generate WEN/EN signals (using pre-declared intermediate signals)
    $hdl .= $self->generate_wen_en_signals($fsm_module);
    fsm_debug("Step 7 - WEN/EN signals generated", 3);
    
    $hdl .= $self->generate_signal_assignments($fsm_module);
    $hdl .= "endmodule\n";
    fsm_debug("*** PIPELINE TIMING DEBUG: HDL Generation Pipeline Complete ***\n", 3);
    
    return $hdl;
}

sub generate_verilog ($self, $fsm_module) {
    fsm_debug("[FlattenedDT.pm][generate_verilog()] Starting flattened DT Verilog generation for " . $fsm_module->name, 3);
    my $sv_hdl = $self->generate_systemverilog($fsm_module);
    return $self->convert_systemverilog_to_verilog($sv_hdl);
}

sub convert_systemverilog_to_verilog ($self, $sv_hdl) {
    my $verilog_hdl = $sv_hdl;
    
    # SystemVerilog procedural blocks -> Verilog-2001 compatible forms.
    $verilog_hdl =~ s/\balways_comb\b/always @*/g;
    $verilog_hdl =~ s/\balways_ff\s*@\s*\(/always @(/g;
    
    return $verilog_hdl;
}

sub generate_vhdl ($self, $fsm_module) {
    die "[FlattenedDT.pm][generate_vhdl()] VHDL backend is not implemented yet. Use --language systemverilog or --language verilog.\n";
}

sub generate_internal_signal_declarations ($self, $fsm_module) {
    my %declared_ports = %{$self->{declared_port_signals} || {}};
    my %signal_decls;
    my %aux_decls;
    
    my @regular_states = grep { $_->name !~ /^-/ } @{$fsm_module->states};
    my $has_state_registers = scalar(@regular_states) > 0;
    if ($has_state_registers) {
        $declared_ports{current_state} = 1;
        $declared_ports{next_state} = 1;
    }
    
    for my $lhs (sort keys %{$self->{assignment_analysis} || {}}) {
        my $lhs_analysis = $self->{assignment_analysis}{$lhs};
        next unless $lhs_analysis;
        
        my $width = $self->get_lhs_width_from_analysis($lhs_analysis);
        my $assignment_type = $self->get_signal_assignment_type($lhs, $lhs_analysis);
        my $multiplexer_type = $lhs_analysis->{multiplexer}->{type} || 'comb';
        
        # Declare the main LHS only when it's not already a module port/state register.
        unless ($declared_ports{$lhs}) {
            $signal_decls{$lhs} = $width;
        }
        
        # Declare mux helper registers only for flop-style multiplexers that consume them.
        if ($multiplexer_type eq 'flop' && ($assignment_type eq 'register_out' || $assignment_type eq 'register_out_dual')) {
            my $next_name = "${lhs}_next";
            $aux_decls{$next_name} = $width unless $declared_ports{$next_name};
        } elsif ($multiplexer_type eq 'flop' && ($assignment_type eq 'register_in' || $assignment_type eq 'register_in_dual')) {
            my $q_name = "${lhs}_q";
            $aux_decls{$q_name} = $width unless $declared_ports{$q_name};
        } elsif ($assignment_type eq 'pulse_delayed') {
            my $delay_cycles = $self->get_pulse_delay_cycles_for_lhs($lhs, $lhs_analysis);
            if ($delay_cycles > 0) {
                my $pipe_name = "${lhs}_pulse_delay_pipe";
                $aux_decls{$pipe_name} = $delay_cycles unless $declared_ports{$pipe_name};
            }
        }
    }
    
    return "" unless (%signal_decls || %aux_decls);
    
    my $hdl = "  // Internal signal declarations\n";
    for my $signal_name (sort keys %signal_decls) {
        my $width = $signal_decls{$signal_name} || 1;
        my $width_str = ($width > 1) ? "[" . ($width - 1) . ":0] " : "";
        $hdl .= "  reg ${width_str}${signal_name};\n";
    }
    
    if (%aux_decls) {
        $hdl .= "  // Internal mux helper registers\n";
        for my $signal_name (sort keys %aux_decls) {
            my $width = $aux_decls{$signal_name} || 1;
            my $width_str = ($width > 1) ? "[" . ($width - 1) . ":0] " : "";
            $hdl .= "  reg ${width_str}${signal_name};\n";
        }
    }
    $hdl .= "\n";
    
    return $hdl;
}

sub get_lhs_width_from_analysis ($self, $lhs_analysis) {
    my $width;
    my $lhs_ast = $lhs_analysis->{lhs_ast};
    
    if ($lhs_analysis->{signal_info} && $lhs_analysis->{signal_info}->{width}) {
        my $signal_width = $lhs_analysis->{signal_info}->{width};
        if (defined($signal_width) && $signal_width > 0) {
            $width = $signal_width;
        }
    }
    
    if ($lhs_ast && blessed($lhs_ast)) {
        if ((!defined($width) || $width < 1) && $lhs_ast->can('signal') && $lhs_ast->signal && $lhs_ast->signal->can('width')) {
            my $signal_width = $lhs_ast->signal->width;
            if (defined($signal_width) && $signal_width > 0) {
                $width = $signal_width;
            }
        } elsif ((!defined($width) || $width < 1) && $lhs_ast->can('width')) {
            my $ast_width = $lhs_ast->width;
            if (defined($ast_width) && $ast_width > 0) {
                $width = $ast_width;
            }
        }
        
        # Fallback via FSM module signal metadata when width isn't available on the AST node.
        if ((!defined($width) || $width < 1) && $lhs_ast->can('name')) {
            my $signal_info = $self->get_signal_info($lhs_ast->name);
            if ($signal_info && $signal_info->{width} && $signal_info->{width} > 0) {
                $width = $signal_info->{width};
            }
        }
    }
    
    $width = 1 unless (defined($width) && $width > 0);
    return $width;
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
    # Determine if this signal AST node should be implemented as a register
    # Uses the signal AST node as the single source of truth
    
    fsm_debug("IS_REGISTER: Analyzing signal '$lhs_name_for_debug' using AST node", 3);
    
    unless ($lhs_signal_ast) {
        fsm_debug("  WARNING: No signal AST node - using fallback assignment analysis", 3);
        return $self->fallback_register_analysis_from_assignments($lhs_name_for_debug);
    }
    
    fsm_debug("  Signal AST node type: " . ref($lhs_signal_ast), 3);
    
    # CRITICAL FIX: Check if this is the FSM state next signal (combinational)
    # This signal should NEVER be a register because the FSM architecture provides
    # a dedicated state register
    if ($lhs_signal_ast->can('is_fsm_state_next') && $lhs_signal_ast->is_fsm_state_next()) {
        fsm_debug("  IS_REGISTER: Signal is FSM state next (combinational) - NOT a register", 3);
        return 0;
    }
    
    # Check if this is the FSM state register (should not get an additional register here
    # because it's handled by the dedicated FSM state register generation)
    if ($lhs_signal_ast->can('is_fsm_state_register') && $lhs_signal_ast->is_fsm_state_register()) {
        fsm_debug("  IS_REGISTER: Signal is FSM state register - handled by dedicated FSM logic", 3);
        return 0;
    }
    
    # Check for explicit register attribute in the signal AST node
    if ($lhs_signal_ast->can('is_register') && defined($lhs_signal_ast->is_register)) {
        my $is_register = $lhs_signal_ast->is_register();
        fsm_debug("  IS_REGISTER: Signal has explicit is_register attribute: $is_register", 3);
        return $is_register ? 1 : 0;
    }
    
    # Fallback to assignment-based analysis when AST doesn't provide explicit info
    fsm_debug("  IS_REGISTER: No explicit AST attribute - using assignment-based analysis", 3);
    return $self->fallback_register_analysis_from_assignments($lhs_name_for_debug);
}

sub fallback_register_analysis_from_assignments ($self, $lhs_name) {
    # Fallback register analysis based on assignment patterns
    # This is used when the signal AST node doesn't have explicit register attributes
    
    fsm_debug("  FALLBACK_REGISTER_ANALYSIS: Analyzing assignment patterns for '$lhs_name'", 3);
    
    # Analyze assignment patterns to determine signal behavior
    my $assignments = $self->{lhs_assignments}->{$lhs_name} || [];
    my $assignment_count = scalar(@$assignments);
    
    fsm_debug("    Signal has $assignment_count assignments", 3);
    
    if ($assignment_count == 0) {
        # No assignments - likely an input signal or constant
        fsm_debug("    No assignments - NOT a register", 3);
        return 0;
    }
    
    # Check assignment operators to understand signal behavior
    my $has_register_assignment = 0;
    my $has_combinational_assignment = 0;
    
    for my $assignment (@$assignments) {
        my $operator = $assignment->{operator} || '=';
        
        if ($operator eq '<-' || $operator eq '<=' || $operator eq '<-=' || $operator eq '<=+' || $operator =~ /^<\d+$/) {
            # Sequential assignment variants - indicate this should be a register-driven path
            $has_register_assignment = 1;
            fsm_debug("      Found sequential assignment (operator: '$operator')", 3);
        } elsif ($operator eq '=') {
            # Combinational assignment - indicates this should be combinational
            $has_combinational_assignment = 1;
            fsm_debug("      Found combinational assignment (operator: '=')", 3);
        }
    }
    
    # Determine final register status based on assignment analysis
    if ($has_register_assignment && !$has_combinational_assignment) {
        # Only register assignments - this should be a register
        fsm_debug("    Only register assignments - IS a register", 3);
        return 1;
    } elsif ($has_combinational_assignment && !$has_register_assignment) {
        # Only combinational assignments - this should be combinational
        fsm_debug("    Only combinational assignments - NOT a register", 3);
        return 0;
    } elsif ($has_register_assignment && $has_combinational_assignment) {
        # Mixed assignments - this is unusual, default to register to be safe
        fsm_debug("    Mixed assignments - defaulting to register for safety", 3);
        return 1;
    } else {
        # No clear assignment pattern - default to combinational
        fsm_debug("    No clear assignment pattern - defaulting to combinational", 3);
        return 0;
    }
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
    # PURE AST APPROACH: Return AST node, not string
    return FSM::AST::Utils::literal("1'b1") if !@$condition_stack;

    # Create AND tree of all conditions
    if (@$condition_stack == 1) {
        return $condition_stack->[0];
    } else {
        return FSM::AST::Utils::and_tree(@$condition_stack);
    }
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
    # Extract signal name from a signal reference AST node
    
    return undef unless $signal_ast && blessed($signal_ast);
    
    # Try different methods to get the signal name
    if ($signal_ast->can('name') && defined($signal_ast->name)) {
        return $signal_ast->name;
    } elsif ($signal_ast->can('signal_name') && defined($signal_ast->signal_name)) {
        return $signal_ast->signal_name;
    } elsif ($signal_ast->can('signal') && $signal_ast->signal && $signal_ast->signal->can('name')) {
        return $signal_ast->signal->name;
    } else {
        # Try to extract from SystemVerilog representation
        my $sv_repr = eval { $signal_ast->to_systemverilog() };
        if ($sv_repr && $sv_repr =~ /^([a-zA-Z_][a-zA-Z0-9_]*)$/) {
            return $1;
        }
    }
    
    return undef;
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
    my $hdl = "";
    $hdl .= "//=============================================================================\n";
    $hdl .= "// Flattened Decision Tree FSM: " . $fsm_module->name . "\n";
    $hdl .= "// Generated using Enable-based Methodology with WEN/EN Signals\n";
    $hdl .= "// Date: " . localtime() . "\n";
    $hdl .= "// \n";
    $hdl .= "// This implementation uses:\n";
    $hdl .= "// - Flattened decision tree approach\n";
    $hdl .= "// - Enable-based logic with assign statements\n";
    $hdl .= "// - Write Enable (WEN) and Enable (EN) signals for each LHS\n";
    $hdl .= "// - Flat Boolean expressions from DT traversal\n";
    $hdl .= "//=============================================================================\n\n";
    return $hdl;
}

sub generate_module_declaration ($self, $fsm_module) {
    my $hdl = "module " . $fsm_module->name . " (\n";
    my @base_ports = (
        "  input  wire clk",
        "  input  wire rstn",
    );
    
    # Add all the signal ports based on the parsed FSM
    my $signals = $fsm_module->signals;
    my @inputs = ();
    my @outputs = ();
    
    fsm_debug("HDL Generation: Processing " . scalar(keys %$signals) . " signals for module declaration", 3);
    
    # Track seen signals to avoid duplicates
    my %seen_signals = ('clk' => 1, 'rstn' => 1);  # Base ports
    my %port_directions = ('clk' => 'input', 'rstn' => 'input');
    
    # Check which signals are driven (outputs) vs used (inputs)
    my %driven_signals = $self->get_driven_signals();
    
    for my $sig_name (sort keys %$signals) {
        # Skip duplicates
        if ($seen_signals{$sig_name}) {
            fsm_debug("HDL Signal Processing: SKIPPING duplicate signal '$sig_name'", 3);
            next;
        }
        $seen_signals{$sig_name} = 1;
        
        my $signal = $signals->{$sig_name};
        
        # Skip intermediate signals from interface - they should not be ports
        my $is_intermediate = 0;
        if ($signal->can('get_attribute')) {
            my $signal_role = $signal->get_attribute('signal_role');
            $is_intermediate = ($signal_role && $signal_role eq 'INTERNAL_INTERMEDIATE');
        } elsif ($signal->can('attributes') && $signal->attributes) {
            $is_intermediate = $signal->attributes->{is_intermediate} || 0;
        }
        
        if ($is_intermediate) {
            fsm_debug("HDL Signal Processing: SKIPPING intermediate signal '$sig_name' from interface", 3);
            next;
        }
        my $width_str = "";
        
        fsm_debug("HDL Signal Processing: $sig_name", 3);
        fsm_debug("  Signal object type: " . ref($signal), 3);
        fsm_debug("  Signal dump: " . Dumper($signal), 3);
        
        my $signal_width = 1;  # default
        if ($signal->can('width')) {
            $signal_width = $signal->width;
            # Handle case where width() returns 0 or undef - keep as 1-bit
            $signal_width = 1 unless ($signal_width && $signal_width > 0);
            fsm_debug("  Signal width from ->width(): $signal_width", 3);
        } else {
            fsm_debug("  Signal does not have width() method", 3);
        }
        
        if ($signal_width && $signal_width > 1) {
            $width_str = "[" . ($signal_width - 1) . ":0] ";
            fsm_debug("  Generated width string: '$width_str'", 3);
        } else {
            fsm_debug("  Using default 1-bit width", 3);
        }
        
        # Determine signal direction based on whether it's driven by our FSM
        my $is_output = 0;
        
        # First check if this signal is driven by the FSM logic
        if ($driven_signals{$sig_name}) {
            $is_output = 1;
            fsm_debug("  Signal '$sig_name' is DRIVEN by FSM -> OUTPUT", 3);
        } else {
            # Check explicit output attributes
            if ($signal->can('is_output')) {
                $is_output = $signal->is_output;
            } elsif ($signal->can('attributes') && $signal->attributes && $signal->attributes->{is_output}) {
                $is_output = $signal->attributes->{is_output};
            } elsif ($sig_name =~ />$/) {
                # Signals ending with > are outputs
                $is_output = 1;
            }
            
            fsm_debug("  Signal '$sig_name' direction: " . ($is_output ? "OUTPUT" : "INPUT"), 3);
        }
        
        if ($is_output) {
            push @outputs, "  output reg  ${width_str}${sig_name}";
            $port_directions{$sig_name} = 'output';
        } else {
            push @inputs, "  input  wire ${width_str}${sig_name}";
            $port_directions{$sig_name} = 'input';
        }
    }
    
    # Join all port declarations with proper ANSI-C SystemVerilog syntax
    my @all_ports = (@base_ports, @inputs, @outputs);
    for my $i (0 .. $#all_ports) {
        $hdl .= $all_ports[$i];
        if ($i < $#all_ports) {
            $hdl .= ",\n";  # Comma continuation for all but last port
        } else {
            $hdl .= "\n";   # No comma for last port
        }
    }
    $hdl .= ");\n\n";
    
    # Save port declarations for downstream internal declaration generation.
    $self->{declared_port_signals} = { %seen_signals };
    $self->{port_directions} = { %port_directions };
    
    return $hdl;
}

sub generate_state_encoding ($self, $fsm_module) {
    my @regular_states = grep { $_->name !~ /^-/ } @{$fsm_module->states};
    my $state_count = scalar(@regular_states);
    my $state_bits = $state_count > 1 ? int(log($state_count)/log(2)) + 1 : 1;
    
    my $hdl = "  // State encoding\n";
    for my $i (0 .. $#regular_states) {
        my $state_name = uc($regular_states[$i]->name);
        $hdl .= "  localparam $state_name = ${state_bits}'d$i;\n";
    }
    $hdl .= "\n";
    
    return $hdl;
}

sub generate_state_register ($self, $fsm_module) {
    my @regular_states = grep { $_->name !~ /^-/ } @{$fsm_module->states};
    my $state_count = scalar(@regular_states);
    
    # Check if this FSM has no regular states (only standalone decision trees)
    if ($state_count == 0) {
        fsm_debug("FSM has no regular states - only standalone decision trees. Skipping state register generation.", 3);
        return "  // No state registers needed - FSM contains only decision trees\n\n";
    }
    
    my $state_bits = $state_count > 1 ? int(log($state_count)/log(2)) + 1 : 1;
    
    my $hdl = "  // State registers\n";
    $hdl .= "  reg [" . ($state_bits - 1) . ":0] current_state, next_state;\n\n";
    
    $hdl .= "  // State sequential logic\n";
    $hdl .= "  always_ff @(posedge clk or negedge rstn) begin\n";
    $hdl .= "    if (!rstn) begin\n";
    $hdl .= "      current_state <= " . uc($regular_states[0]->name) . ";\n";
    $hdl .= "    end else begin\n";
    $hdl .= "      current_state <= next_state;\n";
    $hdl .= "    end\n";
    $hdl .= "  end\n\n";
    
    return $hdl;
}

sub generate_enable_conditions ($self, $fsm_module) {
    my $hdl = "  // State and DT Enable Conditions\n";
    
    # Generate state enables
    for my $state_name (sort keys %{$self->{state_enables}}) {
        my $enable_expr = $self->{state_enables}->{$state_name};
        $hdl .= "  assign ${state_name}_en = $enable_expr;\n";
    }
    
    # Generate standalone DT enables
    for my $dt_name (sort keys %{$self->{dt_enables}}) {
        my $enable_expr = $self->{dt_enables}->{$dt_name};
        my $clean_name = $dt_name;
        $clean_name =~ s/^-//;  # Remove leading dash
        $hdl .= "  assign ${clean_name}_en = $enable_expr;\n";
    }
    
    $hdl .= "\n";
    return $hdl;
}

sub generate_consolidated_intermediate_signals ($self, $fsm_module) {
# Initialize intermediate signals storage
    $self->{intermediate_signals} = {};

    # CONSOLIDATED APPROACH: Generate intermediate signals from AST factorization AND pre-scan
    # This eliminates the duplicate signal generation issue
    
    fsm_debug("\n*** CONSOLIDATED INTERMEDIATE SIGNAL GENERATION ***", 3);
    fsm_debug("CONSOL_INTER_SIG: [ENTRY] FSM module: " . ($fsm_module ? $fsm_module->name : 'undefined'), 3);
    fsm_debug("CONSOL_INTER_SIG: [ENTRY] Current intermediate signals count: " . scalar(keys %{$self->{intermediate_signals} || {}}), 3);
    fsm_debug("CONSOL_INTER_SIG: [ENTRY] Current referenced signals count: " . scalar(keys %{$self->{referenced_intermediate_signals} || {}}), 3);
    
    # SIGNAL_TRACE: Complete dump of ALL signals at FSM module level (pipeline entry)
    if ($fsm_module && $fsm_module->signals) {
        my $fsm_signals = $fsm_module->signals;
        my $total_signals = scalar(keys %$fsm_signals);
        fsm_debug("SIGNAL_TRACE: FSM module has $total_signals total signals at PIPELINE_ENTRY", 3);
        
        # Categorize signals for better analysis
        my (@intermediate_signals, @regular_signals, @or_pattern_signals, @signals_with_driving_ast);
        
        for my $sig_name (sort keys %$fsm_signals) {
            my $signal = $fsm_signals->{$sig_name};
            
            # Check signal properties
            my $has_driving_ast = ($signal->can('driving_ast') && $signal->driving_ast) ? 1 : 0;
            my $is_intermediate = 0;
            
            # Try multiple ways to check for intermediate status
            if ($signal->can('get_attribute')) {
                $is_intermediate = $signal->get_attribute('is_intermediate') || 0;
            } elsif ($signal->can('attributes') && $signal->attributes) {
                $is_intermediate = $signal->attributes->{is_intermediate} || 0;
            }
            
            # Get AST/expression information
            my $ast_info = "NONE";
            my $expression_info = "NONE";
            my $ast_dump = "NO_AST";
            
            if ($has_driving_ast) {
                my $driving_ast = $signal->driving_ast;
                $ast_info = ref($driving_ast) || "UNKNOWN_TYPE";
                
                # Try to get SystemVerilog representation
                if ($driving_ast && $driving_ast->can('to_systemverilog')) {
                    $expression_info = eval { $driving_ast->to_systemverilog() } || "[AST_TO_SV_FAILED]";
                } else {
                    $expression_info = "[NO_TO_SYSTEMVERILOG_METHOD]";
                }
                
                # Get Data::Dumper representation of the AST
                $ast_dump = Data::Dumper->new([$driving_ast], ["${sig_name}_AST"])->Indent(2)->Sortkeys(1)->Dump();
            }
            
            # Categorize the signal
            if ($is_intermediate) {
                push @intermediate_signals, $sig_name;
            }
            if ($has_driving_ast) {
                push @signals_with_driving_ast, $sig_name;
            }
            if ($sig_name =~ /^or_\d+_\d+$/) {
                push @or_pattern_signals, $sig_name;
            } else {
                push @regular_signals, $sig_name;
            }
            
            # Detailed trace for each signal with complete AST dump
            fsm_debug("\n=== SIGNAL ANALYSIS: [$sig_name] ===", 3);
            fsm_debug("  Signal object type: " . ref($signal), 3);
            fsm_debug("  Has driving_ast: " . ($has_driving_ast ? "YES" : "NO"), 3);
            fsm_debug("  Is intermediate: " . ($is_intermediate ? "YES" : "NO"), 3);
            fsm_debug("  AST type: $ast_info", 3);
            fsm_debug("  SystemVerilog expression: $expression_info", 3);
            
            # Full AST dump using Data::Dumper
            fsm_debug("  AST DUMP:", 3);
            my @dump_lines = split(/\n/, $ast_dump);
            for my $line (@dump_lines) {
                fsm_debug("    $line", 3);
            }
            fsm_debug("=== END SIGNAL: [$sig_name] ===\n", 3);
        }
        
        # Summary statistics
        fsm_debug("\n*** SIGNAL_TRACE SUMMARY ***", 3);
        fsm_debug("  - Total signals: $total_signals", 3);
        fsm_debug("  - Intermediate signals: " . scalar(@intermediate_signals) . " (" . join(", ", @intermediate_signals) . ")", 3);
        fsm_debug("  - Signals with driving_ast: " . scalar(@signals_with_driving_ast) . " (" . join(", ", @signals_with_driving_ast) . ")", 3);
        fsm_debug("  - or_*_* pattern signals: " . scalar(@or_pattern_signals) . " (" . join(", ", @or_pattern_signals) . ")", 3);
        fsm_debug("  - Regular signals: " . scalar(@regular_signals), 3);
        fsm_debug("*** END SIGNAL_TRACE SUMMARY ***\n", 3);
    } else {
        fsm_debug("SIGNAL_TRACE: WARNING - No FSM module or signals available at pipeline entry!", 3);
    }
    
    my $hdl = "";
    
    # Step 1: Run AST factorization to identify common sub-expressions
    my $ast_intermediate_signals = $self->run_global_ast_factorization();
    
    # Step 2: Merge with pre-scan results to get comprehensive list
    my %all_intermediate_signals;
    
    # Add signals from AST factorization
    if ($ast_intermediate_signals && %$ast_intermediate_signals) {
        for my $signal_name (keys %$ast_intermediate_signals) {
            $all_intermediate_signals{$signal_name} = {
                source => 'ast_factorization',
                %{$ast_intermediate_signals->{$signal_name}}
            };
        }
    }
    
    # Add signals from pre-scan (referenced by WEN/EN but not yet declared)
    if ($self->{referenced_intermediate_signals}) {
        for my $signal_name (keys %{$self->{referenced_intermediate_signals}}) {
            # Only add if not already in AST factorization results
            unless (exists $all_intermediate_signals{$signal_name}) {
                my $expression = $self->get_intermediate_signal_expression($signal_name);
                if ($expression) {
                    $all_intermediate_signals{$signal_name} = {
                        source => 'prescan_reference',
                        expression => $expression,
                        width => 1,
                        usage_count => 1
                    };
                }
            }
        }
    }
    
    # Step 2.5: Add intermediate signals from FSMGenFull parsing (CRITICAL FIX)
    # These are signals created during FSMGen parsing with driving_ast already set
    if ($fsm_module && $fsm_module->can('signals') && $fsm_module->signals) {
        fsm_debug("CONSOL_INTER_SIG: [FSMGEN_SIGNALS] Scanning FSM module for intermediate signals from parsing", 3);
        my $fsm_signals = $fsm_module->signals;
        my $fsmgen_intermediate_count = 0;
        
        fsm_debug("  FSMGEN_SIGNALS: FSM module has " . scalar(keys %$fsm_signals) . " total signals", 3);
        
        for my $signal_name (keys %$fsm_signals) {
            my $signal = $fsm_signals->{$signal_name};
            
            # Debug every signal to understand the structure
            fsm_debug("  FSMGEN_SIGNAL_SCAN: '$signal_name' -> " . ref($signal), 3);
            
            # Check if this signal has driving_ast (more flexible check)
            if ($signal && $signal->can('driving_ast') && $signal->driving_ast) {
                fsm_debug("    HAS_DRIVING_AST: '$signal_name' has driving AST", 3);
                
                # Check for intermediate marker with more flexible attribute checking
                my $is_intermediate = 0;
                
                # ENHANCED DEBUG: Show what we're working with
                fsm_debug("      SIGNAL_DEBUG: Processing signal '$signal_name'", 3);
                fsm_debug("        Signal object type: " . ref($signal), 3);
                fsm_debug("        Signal blessed: " . (blessed($signal) ? 'YES' : 'NO'), 3);
                
                # Method 1: Try get_attribute method
                if ($signal->can('get_attribute')) {
                    $is_intermediate = $signal->get_attribute('is_intermediate');
                    fsm_debug("      METHOD1: get_attribute('is_intermediate') = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                }
                
                # Method 2: Try attributes hash
                if (!$is_intermediate && $signal->can('attributes') && $signal->attributes) {
                    $is_intermediate = $signal->attributes->{is_intermediate};
                    fsm_debug("      METHOD2: attributes->{is_intermediate} = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                }
                
                # Method 3: Try direct hash access (for FSM::CoreAST::Signal)
                if (!$is_intermediate && ref($signal) eq 'HASH' && exists($signal->{is_intermediate})) {
                    $is_intermediate = $signal->{is_intermediate};
                    fsm_debug("      METHOD3: signal->{is_intermediate} = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                }
                
                # Method 4: Try direct property access (for object-based signals)
                if (!$is_intermediate && blessed($signal) && $signal->can('is_intermediate')) {
                    $is_intermediate = eval { $signal->is_intermediate } || 0;
                    fsm_debug("      METHOD4: signal->is_intermediate() = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                }
                
                # Method 5: Direct dereferencing with proper error handling
                if (!$is_intermediate && blessed($signal)) {
                    # Use eval to safely access the hash representation
                    my $signal_hash = eval { \%{$signal} };
                    if ($signal_hash && exists $signal_hash->{is_intermediate}) {
                        $is_intermediate = $signal_hash->{is_intermediate};
                        fsm_debug("      METHOD5: direct hash deref to is_intermediate = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                    }
                }
                
                # Method 6: Check FSM::CoreAST::Signal internal structure
                if (!$is_intermediate && blessed($signal) && $signal->isa('FSM::CoreAST::Signal')) {
                    # FSM::CoreAST::Signal may store attributes in constructor arguments
                    # Check all keys in the signal object for is_intermediate
                    for my $key (keys %$signal) {
                        if ($key eq 'is_intermediate' && defined($signal->{$key})) {
                            $is_intermediate = $signal->{$key};
                            fsm_debug("      METHOD6: Found is_intermediate as direct key '$key' = $is_intermediate", 3);
                            last;
                        }
                    }
                }
                
                fsm_debug("    IS_INTERMEDIATE_CHECK: '$signal_name' intermediate status: " . ($is_intermediate || 'undefined'), 3);
                
                # If it has driving_ast and is marked intermediate - no arbitrary name pattern matching
                if ($is_intermediate) {
                    # CRITICAL FIX: Even if already added from other sources (pre-scan), 
                    # FSMGenFull intermediate signals should ALWAYS be processed because 
                    # they have the actual AST and expression information needed for declaration
                    
                    # Declare driving_ast once at the outer scope to avoid scoping issues
                    my $driving_ast = $signal->driving_ast;
                    
                    if (exists $all_intermediate_signals{$signal_name}) {
                        fsm_debug("  FSMGEN_INTERMEDIATE: Signal '$signal_name' already exists, but UPDATING with FSMGenFull AST data", 3);
                        # Update the existing entry with proper AST information from FSMGenFull
                        $all_intermediate_signals{$signal_name} = {
                            source => 'fsmgen_parsing',
                            ast => $driving_ast,
                            width => ($signal->can('width') ? $signal->width : undef) || 1,
                            usage_count => 1,  # Conservative estimate
                            driving_ast => $driving_ast  # Store both ast and driving_ast for compatibility
                        };
                        $fsmgen_intermediate_count++;
                        
                        fsm_debug("  FSMGEN_INTERMEDIATE: UPDATED signal '$signal_name' with driving AST: " . ref($driving_ast), 3);
                        fsm_debug("    AST SystemVerilog: " . eval { $driving_ast->to_systemverilog() } || '[AST ERROR]', 3);
                    } else {
                        # This is a new FSMGenFull intermediate signal with proper driving AST
                        fsm_debug("  FSMGEN_INTERMEDIATE: Found NEW signal '$signal_name' with driving AST: " . ref($driving_ast), 3);
                        fsm_debug("    AST SystemVerilog: " . eval { $driving_ast->to_systemverilog() } || '[AST ERROR]', 3);
                        
                        $all_intermediate_signals{$signal_name} = {
                            source => 'fsmgen_parsing',
                            ast => $driving_ast,
                            width => ($signal->can('width') ? $signal->width : undef) || 1,
                            usage_count => 1,  # Conservative estimate
                            driving_ast => $driving_ast  # Store both ast and driving_ast for compatibility
                        };
                        $fsmgen_intermediate_count++;
                    }
                } else {
                    fsm_debug("    NOT_INTERMEDIATE: Signal '$signal_name' has driving AST but is not marked as intermediate", 3);
                }
            } else {
                # Debug why this signal doesn't qualify
                if (!$signal) {
                    fsm_debug("    SKIP: '$signal_name' - signal object is null", 3);
                } elsif (!$signal->can('driving_ast')) {
                    fsm_debug("    SKIP: '$signal_name' - signal has no driving_ast method", 3);
                } elsif (!$signal->driving_ast) {
                    fsm_debug("    SKIP: '$signal_name' - signal has no driving_ast set", 3);
                }
            }
        }
        
        fsm_debug("CONSOL_INTER_SIG: [FSMGEN_SIGNALS] Found $fsmgen_intermediate_count intermediate signals from FSMGenFull parsing", 3);
    } else {
        fsm_debug("CONSOL_INTER_SIG: [FSMGEN_SIGNALS] No FSM module signals available for scanning", 3);
    }
    
    # Step 3: Apply dependency-aware filtering to prevent referenced signals from being filtered out
    fsm_debug("\n*** DEPENDENCY-AWARE FILTERING PHASE ***", 3);
    
    # Step 3a: Build dependency map from intermediate signal expressions
    my %signal_dependencies = ();  # signal_name => [list of signals it depends on]
    
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        
        # Get the expression to analyze for dependencies
        my $expression;
        if ($signal_info->{ast}) {
            $expression = $self->ast_to_systemverilog($signal_info->{ast});
        } elsif ($signal_info->{expression}) {
            $expression = $signal_info->{expression};
        } else {
            fsm_debug("  WARNING: No expression found for signal $signal_name, skipping", 3);
            next;
        }
        
        # Find all intermediate signals referenced in this expression
        my @referenced_signals = $self->extract_intermediate_signals_from_expression($expression);
        if (@referenced_signals) {
            $signal_dependencies{$signal_name} = [@referenced_signals];
            fsm_debug("  DEPENDENCY: '$signal_name' depends on: " . join(", ", @referenced_signals), 3);
        }
    }
    
    # Step 3b: Apply initial filtering pass
    my %initially_filtered_signals;
    my %initially_kept_signals;
    
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        
        # Get expression for filtering analysis
        my $expression;
        if ($signal_info->{ast}) {
            $expression = $self->ast_to_systemverilog($signal_info->{ast});
        } elsif ($signal_info->{expression}) {
            $expression = $signal_info->{expression};
        } else {
            next;
        }
        
        # Apply filtering logic
        my $should_filter = $self->should_filter_consolidated_signal($expression, $signal_name, $signal_info);
        if ($should_filter) {
            $initially_filtered_signals{$signal_name} = $signal_info;
            fsm_debug("  INITIAL FILTER: '$signal_name' = $expression (would be filtered)", 3);
        } else {
            $initially_kept_signals{$signal_name} = $signal_info;
            fsm_debug("  INITIAL KEEP: '$signal_name' = $expression (would be kept)", 3);
        }
    }
    
    # Step 3c: Dependency propagation - rescue filtered signals that are needed by kept signals
    my %rescued_signals = ();
    
    # Check each kept signal's dependencies
    for my $kept_signal (keys %initially_kept_signals) {
        if ($signal_dependencies{$kept_signal}) {
            for my $dependency (@{$signal_dependencies{$kept_signal}}) {
                # If the dependency was initially filtered but exists in our signal set, rescue it
                if ($initially_filtered_signals{$dependency}) {
                    $rescued_signals{$dependency} = $initially_filtered_signals{$dependency};
                    fsm_debug("  RESCUED: Signal '$dependency' rescued because it's needed by '$kept_signal'", 3);
                }
            }
        }
    }
    
    # Step 3d: Build final filtered signal set
    my %filtered_signals = (%initially_kept_signals, %rescued_signals);
    
    # Final summary
    my $initially_kept_count = scalar(keys %initially_kept_signals);
    my $rescued_count = scalar(keys %rescued_signals);
    my $filtered_count = scalar(keys %initially_filtered_signals) - $rescued_count;
    my $total_kept = scalar(keys %filtered_signals);
    
    fsm_debug("\n*** DEPENDENCY-AWARE FILTERING SUMMARY ***", 3);
    fsm_debug("  Initially kept: $initially_kept_count signals", 3);
    fsm_debug("  Rescued by dependencies: $rescued_count signals", 3);
    fsm_debug("  Actually filtered out: $filtered_count signals", 3);
    fsm_debug("  Total signals kept: $total_kept signals", 3);
    
    # Debug list of rescued signals
    if (%rescued_signals) {
        for my $rescued_signal (sort keys %rescued_signals) {
            my $signal_info = $rescued_signals{$rescued_signal};
            my $expression = $signal_info->{ast} ? $self->ast_to_systemverilog($signal_info->{ast}) : $signal_info->{expression};
            fsm_debug("    RESCUED: $rescued_signal = $expression", 3);
        }
    }
    
    # Debug list of finally filtered signals
    my %finally_filtered = %initially_filtered_signals;
    for my $rescued (keys %rescued_signals) {
        delete $finally_filtered{$rescued};
    }
    if (%finally_filtered) {
        for my $filtered_signal (sort keys %finally_filtered) {
            my $signal_info = $finally_filtered{$filtered_signal};
            my $expression = $signal_info->{ast} ? $self->ast_to_systemverilog($signal_info->{ast}) : $signal_info->{expression};
            fsm_debug("    FILTERED OUT: $filtered_signal = $expression", 3);
        }
    }
    
    fsm_debug("*** DEPENDENCY-AWARE FILTERING COMPLETE ***\n", 3);
    
    # Step 4a: LHS signal declarations are emitted once in generate_internal_signal_declarations().
    # Avoid redeclaring them here with incompatible types.
    
    # Step 4b: Generate HDL for consolidated intermediate signals
    if (%filtered_signals) {
        $hdl .= "  // Consolidated intermediate signals (AST factorization + pre-scan)\n";
        
        # Perform topological sort to ensure dependencies are declared before use
        my @sorted_signals = $self->topologically_sort_signals(\%filtered_signals, \%signal_dependencies);
        
        # First pass: Generate all wire declarations
        for my $signal_name (@sorted_signals) {
            my $signal_info = $filtered_signals{$signal_name};
            my $width = $signal_info->{width} || 1;
            
            # Generate wire declaration
            if ($width > 1) {
                $hdl .= "  wire [" . ($width - 1) . ":0] $signal_name;\n";
            } else {
                $hdl .= "  wire $signal_name;\n";
            }
        }
        
        $hdl .= "\n";  # Add spacing between declarations and assignments
        
        # Second pass: Generate all assign statements
        for my $signal_name (@sorted_signals) {
            my $signal_info = $filtered_signals{$signal_name};
            my $width = $signal_info->{width} || 1;
            my $source = $signal_info->{source};
            
            # Generate assign statement using substituted AST if available
            my $expression;
            if ($signal_info->{ast}) {
                # CRITICAL FIX: Use substituted AST from factorizer, not original AST
                my $substituted_ast = $self->get_substituted_ast_for_signal($signal_name, $signal_info);
                if ($substituted_ast) {
            $expression = $self->ast_to_systemverilog($substituted_ast);
                    fsm_debug("CONSOL_INTER_SIG: Using substituted AST for $signal_name: $expression", 3);
                } else {
                    $expression = $self->ast_to_systemverilog($signal_info->{ast});
                    fsm_debug("CONSOL_INTER_SIG: Using original AST for $signal_name: $expression", 3);
                }
            } else {
                $expression = $signal_info->{expression};
            }
            
            $hdl .= "  assign $signal_name = $expression; // Source: $source\n";
            
            fsm_debug("  CONSOLIDATED: wire $signal_name = $expression (source: $source)", 3);
        }
        
        $hdl .= "\n";
    } else {
        fsm_debug("  No consolidated intermediate signals needed after filtering", 3);
    }
    
    fsm_debug("*** CONSOLIDATED INTERMEDIATE SIGNAL GENERATION COMPLETE ***\n", 3);
    
    return $hdl;
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
    my $hdl = "";
    
    fsm_debug("\n*** PHASE: GENERATE INTERMEDIATE SIGNALS (FULLY AST-BASED) ***", 3);
    
    # STEP 1: Run global AST factorization on all WEN/EN expressions
    my $intermediate_signals = $self->run_global_ast_factorization();
    
    # STEP 2: Generate SystemVerilog declarations and assignments
    if (%$intermediate_signals) {
        $hdl .= "  // Intermediate signals for complex expressions\n";
        
        # Sort for deterministic output
        for my $signal_name (sort keys %$intermediate_signals) {
            my $signal_info = $intermediate_signals->{$signal_name};
            my $ast = $signal_info->{ast};
            my $width = $signal_info->{width} || 1;
            my $usage_count = $signal_info->{usage_count};
            
            fsm_debug("  Generating intermediate signal: $signal_name (width=$width, usage=$usage_count)", 3);
            
            # Generate wire declaration
            if ($width > 1) {
                $hdl .= "  wire [" . ($width - 1) . ":0] $signal_name;\n";
            } else {
                $hdl .= "  wire $signal_name;\n";
            }
            
            # Generate assign statement from AST
            my $systemverilog_expr = $ast->to_systemverilog();
            $hdl .= "  assign $signal_name = $systemverilog_expr;\n";
        }
    } else {
        fsm_debug("  No intermediate signals needed", 3);
    }
    
    fsm_debug("*** END PHASE: GENERATE INTERMEDIATE SIGNALS ***\n", 3);
    
    return $hdl;
}

sub run_global_ast_factorization ($self) {
    # GENERIC AST-BASED GLOBAL FACTORIZATION
    # Uses pure AST structural analysis - works with any FSM
    
    fsm_debug("\n*** GENERIC GLOBAL AST FACTORIZATION PHASE ***", 3);
    fsm_debug("GLOBAL_AST_FACT: [ENTRY] Starting run_global_ast_factorization", 3);
    
    # TIMING FIX: Logical operations should already be counted by now!
    fsm_debug("GLOBAL_AST_FACT: [CHECK] Checking if binary_logical_op_counts exists", 3);
    if (exists $self->{binary_logical_op_counts}) {
        fsm_debug("GLOBAL_AST_FACT: [EXISTS] binary_logical_op_counts found", 3);
        my $total_ops = 0;
        for my $count (values %{$self->{binary_logical_op_counts}}) {
            $total_ops += $count;
        }
        fsm_debug("AST_FACTORIZATION: Using existing logical operation counts: $total_ops total ops", 3);
        # Show some details about operation counts
        for my $op_sig (keys %{$self->{binary_logical_op_counts}}) {
            my $count = $self->{binary_logical_op_counts}{$op_sig};
            fsm_debug("  Operation '$op_sig': $count occurrences", 3);
        }
    } else {
        fsm_debug("GLOBAL_AST_FACT: [NOT_EXISTS] binary_logical_op_counts NOT found - running count now", 3);
        fsm_debug("*** WARNING: No logical operation counts available - this shouldn't happen! ***", 3);
        $self->count_binary_logical_operation_occurrences();
    }
    
    # Load the generic AST factorization system
    require FSM::HDL::ASTFactorization;
    
    # Initialize generic factorizer with enhanced debugging
    my $factorizer = FSM::HDL::ASTFactorization->new(
        min_usage_count => 2,
        debug => debug_enabled(),
        debug_level => 3  # Enable highest level of debug output
    );
    
    # STEP 1: Collect and add all AST expressions to factorizer
    fsm_debug("*** STEP 1: FEEDING ASTs TO FACTORIZER ***", 3);
    my $ast_count = $self->feed_asts_to_factorizer($factorizer);
    fsm_debug("Fed $ast_count AST expressions to factorizer", 3);
    
    # Show what ASTs we have in the factorizer
    fsm_debug("Factorizer now has " . scalar(@{$factorizer->{ast_expressions}}) . " AST expressions:", 3);
    for my $i (0 .. min(9, $#{$factorizer->{ast_expressions}})) { # Show first 10
        my $expr_info = $factorizer->{ast_expressions}[$i];
        my $sv = eval { $expr_info->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
        fsm_debug("  [$i] Context: $expr_info->{context}", 3);
        fsm_debug("      Expression: $sv", 3);
        fsm_debug("      AST Object: " . ref($expr_info->{ast}) . " @ " . sprintf("%p", $expr_info->{ast}), 3);
    }
    
    # STEP 2: Perform generic analysis and factorization
    fsm_debug("*** STEP 2: PERFORMING AST ANALYSIS AND FACTORIZATION ***", 3);
    fsm_debug("*** INTERMEDIATE SIGNAL CREATION DECISION TRACKING ***", 3);
    my $result = $factorizer->analyze_and_factorize();
    
    fsm_debug("Analysis results:", 3);
    fsm_debug("  Total expressions: $result->{total_expressions}", 3);
    fsm_debug("  Unique structures: $result->{unique_structures}", 3);
    fsm_debug("  Factorization candidates: $result->{factorization_candidates}", 3);
    
    # Show the intermediate signals that were generated WITH CREATION REASONING
    my $intermediate_signals = $result->{intermediate_signals};
    if (%$intermediate_signals) {
        fsm_debug("\n*** INTERMEDIATE SIGNAL CREATION DECISIONS ***", 3);
        for my $signal_name (sort keys %$intermediate_signals) {
            my $signal_info = $intermediate_signals->{$signal_name};
            my $sv = eval { $signal_info->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
            my $usage = $signal_info->{usage_count};
            my $ast_ref = sprintf("%p", $signal_info->{ast});
            
            fsm_debug("\n=== INTERMEDIATE SIGNAL CREATED: $signal_name ===", 3);
            fsm_debug("  REASON: Expression used $usage times (threshold: 2)", 3);
            fsm_debug("  EXPRESSION: $sv", 3);
            fsm_debug("  AST_OBJECT: " . ref($signal_info->{ast}) . " @ $ast_ref", 3);
            fsm_debug("  CREATED_BY: FSM::HDL::ASTFactorization->analyze_and_factorize()", 3);
            
            # Show WHERE this expression was found
            if ($signal_info->{contexts}) {
                fsm_debug("  FOUND_IN_CONTEXTS:", 3);
                for my $context (@{$signal_info->{contexts}}) {
                    fsm_debug("    - $context", 3);
                }
            }
            fsm_debug("=== END INTERMEDIATE SIGNAL: $signal_name ===", 3);
        }
    } else {
        fsm_debug("*** WARNING: NO INTERMEDIATE SIGNALS GENERATED! ***", 3);
    }
    
    # STEP 3: CRITICAL - Substitute intermediate signals back into original expressions
    fsm_debug("\n*** STEP 3: AST SUBSTITUTION PHASE ***", 3);
    fsm_debug("*** AST REPLACEMENT TRACKING - EVERY SUBSTITUTION WILL BE LOGGED ***", 3);
    my $substitution_count = $factorizer->substitute_expressions_with_intermediate_signals($factorizer->{ast_expressions});
    fsm_debug("*** AST SUBSTITUTION COMPLETE: $substitution_count expressions modified ***", 3);
    
    # Show detailed examples of substituted expressions with BEFORE/AFTER
    if ($substitution_count > 0) {
        fsm_debug("\n*** AST SUBSTITUTION RESULTS - SHOWING ALL CHANGES ***", 3);
        my $shown = 0;
        for my $expr_info (@{$factorizer->{ast_expressions}}) {
            my $sv = eval { $expr_info->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
            # Look for intermediate signal patterns - these indicate substitution occurred
            if ($sv =~ /\b\w+_and_\w+|\b\w+_or_\w+|intermediate_\d+|_expr\d*/) {
                my $context = $expr_info->{context};
                my $ast_ref = sprintf("%p", $expr_info->{ast});
                
                fsm_debug("\n--- SUBSTITUTED AST FOUND ---", 3);
                fsm_debug("  CONTEXT: $context", 3);
                fsm_debug("  AFTER_SUBSTITUTION: $sv", 3);
                fsm_debug("  AST_OBJECT_AFTER: " . ref($expr_info->{ast}) . " @ $ast_ref", 3);
                fsm_debug("  SUBSTITUTED_BY: FSM::HDL::ASTFactorization->substitute_expressions_with_intermediate_signals()", 3);
                
                # Try to identify which intermediate signals are referenced
                my @referenced_intermediates = $self->extract_intermediate_signals_from_expression($sv);
                if (@referenced_intermediates) {
                    fsm_debug("  REFERENCES_INTERMEDIATES: " . join(", ", @referenced_intermediates), 3);
                }
                fsm_debug("--- END SUBSTITUTED AST ---", 3);
                
                $shown++;
                last if $shown >= 10; # Show first 10 examples
            }
        }
        
        if ($shown == 0) {
            fsm_debug("*** WARNING: No substituted expressions found despite substitution_count = $substitution_count ***", 3);
        }
    }
    
    # STEP 4: CRITICAL FIX - Update original AST expressions with substituted versions
    fsm_debug("\n*** STEP 4: UPDATING ORIGINAL AST EXPRESSIONS WITH SUBSTITUTED VERSIONS ***", 3);
    fsm_debug("*** AST OBJECT REPLACEMENT TRACKING - EVERY UPDATE WILL BE LOGGED ***", 3);
    
    # COUNT UNARY NEGATIONS BEFORE UPDATE
    fsm_debug("\n--- BEFORE AST UPDATE: Counting unary negations in original expressions ---", 3);
    $self->count_unary_negations_in_original_expressions();
    
    my $update_count = $self->update_original_asts_with_substituted_versions($factorizer);
    fsm_debug("*** ORIGINAL AST UPDATE COMPLETE: $update_count ASTs updated ***", 3);
    
    # COUNT UNARY NEGATIONS AFTER UPDATE  
    fsm_debug("\n--- AFTER AST UPDATE: Counting unary negations in updated expressions ---", 3);
    $self->count_unary_negations_in_original_expressions();
    
    # STEP 5: SECOND-PASS FACTORIZATION - Check for new compound expressions created by substitution
    fsm_debug("\n*** STEP 5: SECOND-PASS FACTORIZATION FOR POST-SUBSTITUTION EXPRESSIONS ***", 3);
    my $second_pass_result = $self->run_second_pass_factorization($factorizer);
    fsm_debug("*** SECOND-PASS FACTORIZATION COMPLETE: " . scalar(keys %{$second_pass_result->{intermediate_signals}}) . " additional signals created ***", 3);
    
    # Merge second-pass results into the main intermediate signals
    for my $signal_name (keys %{$second_pass_result->{intermediate_signals}}) {
        $intermediate_signals->{$signal_name} = $second_pass_result->{intermediate_signals}{$signal_name};
    }
    
    # STEP 6: Store factorizer for later lookup during HDL generation
    $self->{ast_factorizer} = $factorizer;
    
    fsm_debug("*** GENERIC AST FACTORIZATION COMPLETE ***", 3);
    fsm_debug("  Total expressions: $result->{total_expressions}", 3);
    fsm_debug("  Unique structures: $result->{unique_structures}", 3);
    fsm_debug("  Factorization candidates: $result->{factorization_candidates}", 3);
    fsm_debug("  Intermediate signals generated: " . scalar(keys %$intermediate_signals), 3);
    fsm_debug("  Substitution count: $substitution_count", 3);
    fsm_debug("  Original AST update count: $update_count", 3);
    
    return $result->{intermediate_signals};
}

sub collect_all_wen_en_ast_expressions ($self) {
    # Collect ALL AST expressions used in WEN/EN signals across the design
    my @ast_expressions;
    
    fsm_debug("COLLECT_AST: Collecting all WEN/EN AST expressions", 3);
    
    # Collect from unified assignment analysis
    if ($self->{assignment_analysis}) {
        for my $lhs (keys %{$self->{assignment_analysis}}) {
            my $lhs_analysis = $self->{assignment_analysis}->{$lhs};
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
                
                # Collect DT-specific enable ASTs
                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast}) {
                        push @ast_expressions, {
                            ast => $dt_enable->{enable_ast},
                            context => "dt_enable:$dt_enable->{enable_name}",
                            usage_type => 'dt_enable'
                        };
                    }
                }
                
                # Collect LHS-level enable ASTs
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                    push @ast_expressions, {
                        ast => $rhs_group->{lhs_level_enable}->{ast},
                        context => "lhs_enable:$rhs_group->{lhs_level_enable}->{name}",
                        usage_type => 'lhs_enable'
                    };
                }
            }
        }
    }
    
    # Collect from any other AST sources (assignments with stored ASTs)
    for my $lhs (keys %{$self->{lhs_assignments} || {}}) {
        for my $assignment (@{$self->{lhs_assignments}->{$lhs}}) {
            if ($assignment->{conditions_ast}) {
                push @ast_expressions, {
                    ast => $assignment->{conditions_ast},
                    context => "assignment_condition:$lhs:$assignment->{dt}",
                    usage_type => 'assignment_condition'
                };
            }
        }
    }
    
    fsm_debug("COLLECT_AST: Collected " . scalar(@ast_expressions) . " AST expressions", 3);
    return @ast_expressions;
}

sub analyze_ast_sub_expressions ($self, $ast_expressions) {
    # Analyze all collected AST expressions to find common sub-expressions
    my %sub_expression_usage;
    
    fsm_debug("ANALYZE_AST: Analyzing sub-expressions in " . scalar(@$ast_expressions) . " AST expressions");
    
    for my $ast_info (@$ast_expressions) {
        my $ast = $ast_info->{ast};
        my $context = $ast_info->{context};
        
        # Find all sub-expressions in this AST
        my @sub_expressions = $self->find_all_ast_sub_expressions($ast);
        
        for my $sub_expr_ast (@sub_expressions) {
            # Convert to canonical string for comparison
            my $canonical = eval { $sub_expr_ast->to_systemverilog() } || "invalid_ast";
            
            # Skip simple expressions
            next if $self->is_simple_ast_expression($sub_expr_ast);
            
            # Record usage
            $sub_expression_usage{$canonical} ||= {
                ast => $sub_expr_ast,
                usage_count => 0,
                contexts => []
            };
            
            $sub_expression_usage{$canonical}->{usage_count}++;
            push @{$sub_expression_usage{$canonical}->{contexts}}, $context;
            
            fsm_debug("  Found sub-expression: '$canonical' in $context", 3);
        }
    }
    
    # Log summary
    my $total_unique = scalar(keys %sub_expression_usage);
    my $multi_use = grep { $sub_expression_usage{$_}->{usage_count} > 1 } keys %sub_expression_usage;
    fsm_debug("ANALYZE_AST: Found $total_unique unique sub-expressions, $multi_use used multiple times", 3);
    
    return %sub_expression_usage;
}

sub find_all_ast_sub_expressions ($self, $ast) {
    # Recursively find all meaningful sub-expressions in an AST
    my @sub_expressions;
    
    return @sub_expressions unless $ast && blessed($ast);
    
    # Binary operations: include operands as sub-expressions
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Add operands if they're complex enough
        if ($ast->can('left') && $ast->left && !$self->is_simple_ast_expression($ast->left)) {
            push @sub_expressions, $ast->left;
        }
        if ($ast->can('right') && $ast->right && !$self->is_simple_ast_expression($ast->right)) {
            push @sub_expressions, $ast->right;
        }
        
        # Recursively find sub-expressions in operands
        push @sub_expressions, $self->find_all_ast_sub_expressions($ast->left) if $ast->can('left');
        push @sub_expressions, $self->find_all_ast_sub_expressions($ast->right) if $ast->can('right');
    }
    # Unary operations: include operand as sub-expression
    elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        if ($ast->can('operand') && $ast->operand && !$self->is_simple_ast_expression($ast->operand)) {
            push @sub_expressions, $ast->operand;
        }
        
        # Recursively find sub-expressions in operand
        push @sub_expressions, $self->find_all_ast_sub_expressions($ast->operand) if $ast->can('operand');
    }
    
    return @sub_expressions;
}

sub count_binary_logical_operation_occurrences ($self) {
    # Count occurrences of specific binary logical operations across all FSM expressions
    # This is used to determine if binary logical operations should be factorized
    
    my %logical_op_counts;
    
    fsm_debug("\n*** COUNT_LOGICAL_OPS: STARTING LOGICAL OPERATION COUNTING ***", 3);
    fsm_debug("COUNT_LOGICAL_OPS: This should happen BEFORE any intermediate signal creation!", 3);
    
    # Check if pre-scan has already run
    if (exists $self->{referenced_intermediate_signals} && %{$self->{referenced_intermediate_signals}}) {
        my $prescan_count = scalar(keys %{$self->{referenced_intermediate_signals}});
        fsm_debug("*** COUNT_LOGICAL_OPS: WARNING - Pre-scan has already identified $prescan_count intermediate signals! ***", 3);
        fsm_debug("*** This means the logical operation counting is happening TOO LATE! ***", 3);
        fsm_debug("Pre-scan signals: " . join(", ", sort keys %{$self->{referenced_intermediate_signals}}));
    } else {
        fsm_debug("COUNT_LOGICAL_OPS: Good - No pre-scan signals created yet", 3);
    }
    
    fsm_debug("COUNT_LOGICAL_OPS: Counting binary logical operation occurrences", 3);
    
    # Collect all AST expressions
    my @ast_expressions = $self->collect_all_wen_en_ast_expressions();
    
    # Count logical operations in each expression
    for my $ast_info (@ast_expressions) {
        my $ast = $ast_info->{ast};
        $self->_count_logical_ops_in_ast($ast, \%logical_op_counts);
    }
    
    # Also count from any intermediate signal expressions
    for my $signal_name (keys %{$self->{intermediate_signals} || {}}) {
        my $expression = $self->{intermediate_signals}->{$signal_name};
        # Try to parse the string expression back to AST for counting
        my $ast = eval { $self->{expr_namer}->parse_expression($expression) } if $expression;
        if ($ast) {
            $self->_count_logical_ops_in_ast($ast, \%logical_op_counts);
        }
    }
    
    # Store the counts for later use
    $self->{binary_logical_op_counts} = \%logical_op_counts;
    
    # Debug output
    my $total_ops = 0;
    my @high_count_ops;
    for my $op_signature (keys %logical_op_counts) {
        my $count = $logical_op_counts{$op_signature};
        $total_ops += $count;
        fsm_debug("  Logical operation '$op_signature' appears $count times", 3);
        if ($count > 1) {
            push @high_count_ops, "$op_signature ($count times)";
        }
    }
    
    fsm_debug("COUNT_LOGICAL_OPS: Found $total_ops total logical operations", 3);
    fsm_debug("COUNT_LOGICAL_OPS: Operations appearing multiple times: " . (@high_count_ops ? join(", ", @high_count_ops) : "None"));
    
    # Show the full counts structure for debugging
    fsm_debug("COUNT_LOGICAL_OPS: Complete counts structure:", 3);
    fsm_debug(Data::Dumper::Dumper(\%logical_op_counts));
    
    fsm_debug("*** COUNT_LOGICAL_OPS: LOGICAL OPERATION COUNTING COMPLETE ***\n", 3);
    return \%logical_op_counts;
}

sub _count_logical_ops_in_ast ($self, $ast, $counts_ref) {
    # Recursively count ALL factorizable sub-expressions in an AST
    # This traverses the ENTIRE AST tree to find every possible sub-expression that could be factored
    return unless $ast && blessed($ast);
    
    # COUNT THIS ENTIRE EXPRESSION: Check if this entire AST node is factorizable
    if ($self->_is_factorizable_sub_expression($ast)) {
        my $signature = eval { $ast->to_systemverilog() } || 'unknown';
        $counts_ref->{$signature}++;
        fsm_debug("    Found factorizable sub-expression: '$signature' (count: $counts_ref->{$signature})", 3);
    }
    
    # RECURSE INTO ALL CHILDREN: Walk the entire AST tree to find nested factorizable expressions
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Recursively analyze both operands
        $self->_count_logical_ops_in_ast($ast->left, $counts_ref) if $ast->can('left');
        $self->_count_logical_ops_in_ast($ast->right, $counts_ref) if $ast->can('right');
    }
    elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        # Recursively analyze operand
        $self->_count_logical_ops_in_ast($ast->operand, $counts_ref) if $ast->can('operand');
    }
    
    # Note: Literals and SignalRefs are leaf nodes - they don't need recursion
}

sub _is_factorizable_sub_expression ($self, $ast) {
    # Determine if an AST node represents a sub-expression worth factoring
    # Based on the spec:
    # - Unary operations: ALWAYS create intermediate signals
    # - Binary logical operations: Only if used more than once 
    # - Binary arithmetic operations: ALWAYS create intermediate signals
    
    return 0 unless $ast && blessed($ast);
    
    # DON'T factor simple literals or bare signal references
    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        return 0;
    }
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        return 0;
    }
    
    # UNARY OPERATIONS: Always factor (per spec)
    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        fsm_debug("FACTORIZABLE: Unary operation - ALWAYS FACTOR", 3);
        return 1;
    }
    
    # BINARY OPERATIONS: Check type to determine factorization policy
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Arithmetic operations: Always factor (per spec)
        if ($self->is_arithmetic_operation($ast)) {
            fsm_debug("FACTORIZABLE: Arithmetic operation - ALWAYS FACTOR", 3);
            return 1;
        }
        
        # Logical operations: Only if used multiple times (per spec)
        if ($self->is_logical_operation($ast)) {
            my $signature = eval { $ast->to_systemverilog() } || 'unknown';
            my $count = ($self->{binary_logical_op_counts} || {})->{$signature} || 0;
            if ($count > 1) {
                fsm_debug("FACTORIZABLE: Logical operation '$signature' used $count times - FACTOR", 3);
                return 1;
            } else {
                fsm_debug("FACTORIZABLE: Logical operation '$signature' used only $count time - DON'T FACTOR", 3);
                return 0;
            }
        }
        
        # Other binary operations (comparisons, etc.): Always factor
        fsm_debug("FACTORIZABLE: Other binary operation - ALWAYS FACTOR", 3);
        return 1;
    }
    
    # DO factor other complex expressions
    return 1;
}

sub is_arithmetic_operation ($self, $ast) {
    # Check if an AST node represents an arithmetic operation
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 0 unless $ast->can('operator');
    
    my $op = $ast->operator || '';
    return $op =~ /^[\+\-\*\/\%\<<\>>]$/;
}

sub is_logical_operation ($self, $ast) {
    # Check if an AST node represents a logical operation
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 0 unless $ast->can('operator');
    
    my $op = $ast->operator || '';
    return $op =~ /^(&&|\|\||&|\|)$/;
}

sub should_factor_logical_operation ($self, $ast) {
    # Determine if a logical operation should be factored based on occurrence count
    return 0 unless $self->is_logical_operation($ast);
    
    # FIXED: Check if ANY of the sub-operations in this expression appears multiple times
    # instead of looking for the exact compound expression
    return $self->contains_frequently_used_operations($ast);
}

sub contains_frequently_used_operations ($self, $ast) {
    # Check if this AST contains any frequently used operations
    return 0 unless $ast && blessed($ast);
    return 0 unless exists $self->{binary_logical_op_counts};
    
    # Convert the AST to SystemVerilog and check if it contains any high-count operations
    my $ast_str = eval { $ast->to_systemverilog() } || '';
    
    # Check if this expression contains any of our high-count operations
    for my $op_signature (keys %{$self->{binary_logical_op_counts}}) {
        my $count = $self->{binary_logical_op_counts}{$op_signature};
        if ($count > 1 && $ast_str =~ /\Q$op_signature\E/) {
            fsm_debug("FACTOR_LOGICAL_CHECK: Expression '$ast_str' contains high-count operation '$op_signature' ($count times) - FACTOR", 3);
            return 1;
        }
    }

    # NEW: also check inside intermediate signals
    my @potential_signals = ($ast_str =~ /([a-zA-Z_][a-zA-Z0-9_]+)/g);
    my %visited;
    for my $sig (@potential_signals) {
        next if $visited{$sig}++;
        if ($self->is_intermediate_signal($sig)) {
             my $expr = $self->get_intermediate_signal_expression($sig);
             if ($expr) {
                 # To avoid infinite recursion, let's not call contains_frequently_used_operations recursively
                 for my $op_signature (keys %{$self->{binary_logical_op_counts}}) {
                     my $count = $self->{binary_logical_op_counts}{$op_signature};
                     if ($count > 1 && $expr =~ /\Q$op_signature\E/) {
                          fsm_debug("FACTOR_LOGICAL_CHECK: Expression '$ast_str' contains intermediate signal '$sig' which contains high-count operation '$op_signature' ($count times) - FACTOR", 3);
                         return 1;
                     }
                 }
             }
        }
    }
    
    fsm_debug("FACTOR_LOGICAL_CHECK: Expression '$ast_str' contains no high-count operations - DON'T FACTOR", 3);
    return 0;
}

sub is_simple_ast_expression ($self, $ast) {
    # Refined factorization logic:
    # - Always factor unary operations 
    # - Only factor binary logical ops that appear multiple times
    # - Always factor binary arithmetic operations
    # - Literals and bare signal references remain simple
    
    return 1 unless $ast && blessed($ast);
    
    # Literals are always simple
    return 1 if $ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal');
    
    # Signal references are simple
    return 1 if $ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef');
    
    # UNARY OPERATIONS: Always factor (never simple)
    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        fsm_debug("SIMPLE_CHECK: Unary operation - ALWAYS FACTOR (not simple)", 3);
        return 0;  # Force factorization of all unary operations
    }
    
    # BINARY OPERATIONS: Check type and occurrence count
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Always factor arithmetic operations
        if ($self->is_arithmetic_operation($ast)) {
            fsm_debug("SIMPLE_CHECK: Arithmetic operation - ALWAYS FACTOR (not simple)", 3);
            return 0;  # Force factorization of all arithmetic operations
        }
        
        # For logical operations, only factor if they appear multiple times
        if ($self->is_logical_operation($ast)) {
            my $should_factor = $self->should_factor_logical_operation($ast);
            if ($should_factor) {
                fsm_debug("SIMPLE_CHECK: Multi-use logical operation - FACTOR (not simple)", 3);
                return 0;
            } else {
                fsm_debug("SIMPLE_CHECK: Single-use logical operation - DON'T FACTOR (simple)", 3);
                return 1;
            }
        }
        
        # Other binary operations (comparisons, etc.) - factor if complex
        fsm_debug("SIMPLE_CHECK: Other binary operation - FACTOR (not simple)", 3);
        return 0;
    }
    
    # Everything else is complex
    return 0;
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
    my $hdl = "";
    
    # UNIFIED APPROACH: Generate WEN/EN signals from Phase 1 unified data
    $hdl .= $self->generate_unified_wen_en_signals($fsm_module);
    
    return $hdl;
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
    my $hdl = "  // Flop with mux for: $lhs\n";
    
    # Generate the multiplexer logic
    $hdl .= "  always_comb begin\n";
    $hdl .= "    ${lhs}_next = " . $self->get_default_value($lhs) . ";  // Default value\n";
    
    # Use the enable/value pairs passed down from LHS-Level WEN generation
    for my $pair (@{$self->{lhs_to_enable_value_pairs}{$lhs}}) {
        my $enable_signal_name = $pair->{enable_signal};
        my $rhs_value = $pair->{rhs_value};
        $hdl .= "    if ($enable_signal_name) begin\n";
        $hdl .= "      ${lhs}_next = $rhs_value;\n";
        $hdl .= "    end\n";
    }
    
    $hdl .= "  end\n";
    
    # Generate the flop
    $hdl .= "  always_ff @(posedge clk or negedge rstn) begin\n";
    $hdl .= "    if (!rstn) begin\n";
    $hdl .= "      $lhs <= " . $self->get_reset_value($lhs) . ";\n";
    $hdl .= "    end else begin\n";
    $hdl .= "      $lhs <= ${lhs}_next;\n";
    $hdl .= "    end\n";
    $hdl .= "  end\n";
    
    return $hdl;
}

sub generate_comb_mux ($self, $lhs, $clean_lhs) {
    my $hdl = "  // Combinational mux for: $lhs\n";
    
    $hdl .= "  always_comb begin\n";
    $hdl .= "    $lhs = " . $self->get_default_value($lhs) . ";  // Default value\n";
    
    # Use the enable/value pairs passed down from LHS-Level WEN generation
    for my $pair (@{$self->{lhs_to_enable_value_pairs}{$lhs}}) {
        my $enable_signal_name = $pair->{enable_signal};
        my $rhs_value = $pair->{rhs_value};
        $hdl .= "    if ($enable_signal_name) begin\n";
        $hdl .= "      $lhs = $rhs_value;\n";
        $hdl .= "    end\n";
    }
    
    $hdl .= "  end\n";
    
    return $hdl;
}

sub get_driven_signals ($self) {
    return $self->{enable_graph}->get_driven_signals();
}

sub get_reset_value ($self, $lhs) {
    return $self->{enable_graph}->get_reset_value($lhs);
}

sub get_fsm_reset_state ($self) {
    # Get the reset state for the FSM from the FSM module
    # The reset state is conventionally the first state in the state list
    
    # If we have access to the FSM module, get the first regular state
    if ($self->{fsm_module}) {
        my @regular_states = grep { $_->name !~ /^-/ } @{$self->{fsm_module}->states};
        if (@regular_states) {
            my $reset_state = uc($regular_states[0]->name);
            fsm_debug("FSM_RESET_STATE: Using first state as reset: '$reset_state'", 3);
            return $reset_state;
        }
    }
    
    # If no FSM module available or no states, default to IDLE
    fsm_debug("FSM_RESET_STATE: Defaulting to IDLE", 3);
    return "IDLE";
}

sub get_explicit_reset_value ($self, $lhs) {
    # Check if this LHS has explicit reset information from the FSM specification
    # This could come from signal attributes, FSM metadata, or explicit configuration
    
    fsm_debug("EXPLICIT_RESET: Checking for explicit reset value for '$lhs'", 3);
    
    # Check if we have explicit reset values configured
    if ($self->{explicit_reset_values} && $self->{explicit_reset_values}{$lhs}) {
        my $reset_val = $self->{explicit_reset_values}{$lhs};
        fsm_debug("EXPLICIT_RESET: Found configured reset for '$lhs' -> '$reset_val'", 3);
        return $reset_val;
    }
    
    # Check signal attributes if available through FSM module
    if ($self->{fsm_module} && $self->{fsm_module}->signals) {
        my $signals = $self->{fsm_module}->signals;
        if ($signals->{$lhs}) {
            my $signal = $signals->{$lhs};
            
            # Check for reset_value attribute
            if ($signal->can('attributes') && $signal->attributes && $signal->attributes->{reset_value}) {
                my $reset_val = $signal->attributes->{reset_value};
                fsm_debug("EXPLICIT_RESET: Found signal attribute reset for '$lhs' -> '$reset_val'", 3);
                return $reset_val;
            }
            
            # Check for reset_value method
            if ($signal->can('reset_value')) {
                my $reset_val = $signal->reset_value;
                if (defined $reset_val) {
                    fsm_debug("EXPLICIT_RESET: Found signal method reset for '$lhs' -> '$reset_val'", 3);
                    return $reset_val;
                }
            }
        }
    }
    
    # No explicit reset value found
    fsm_debug("EXPLICIT_RESET: No explicit reset value found for '$lhs'", 3);
    return undef;
}

sub get_signal_info ($self, $lhs) {
    return $self->{enable_graph}->get_signal_info($lhs);
}

sub set_fsm_module_reference ($self, $fsm_module) {
    # Store a reference to the FSM module for accessing signal information
    $self->{fsm_module} = $fsm_module;
    fsm_debug("FSM_MODULE_REF: Stored reference to FSM module: " . ($fsm_module ? $fsm_module->name : 'undef'), 3);
}

sub set_explicit_reset_values ($self, $reset_values) {
    # Allow explicit configuration of reset values
    # $reset_values is a hash: { signal_name => reset_value }
    $self->{explicit_reset_values} = $reset_values;
    fsm_debug("EXPLICIT_RESET_CONFIG: Configured explicit reset values for " . scalar(keys %$reset_values) . " signals", 3);
    
    for my $signal (keys %$reset_values) {
        fsm_debug("  $signal -> $reset_values->{$signal}", 3);
    }
}

sub get_default_value_from_ast ($self, $lhs_ast) {
    # AST WEB: Get default value using direct AST queries
    # DEBUG: Check what type of object we have
    fsm_debug("DEBUG: lhs_ast object type: " . ref($lhs_ast), 3);
    fsm_debug("DEBUG: lhs_ast blessed: " . (blessed($lhs_ast) || 'NOT BLESSED'), 3);
    if (blessed($lhs_ast)) {
        fsm_debug("DEBUG: lhs_ast can name: " . ($lhs_ast->can('name') ? 'YES' : 'NO'), 3);
        my @methods = qw(name signal type operands);
        for my $method (@methods) {
            fsm_debug("DEBUG: lhs_ast can $method: " . ($lhs_ast->can($method) ? 'YES' : 'NO'), 3);
        }
    }
    
    # Use proper signal name extraction that handles different AST types
    my $lhs_name = $self->extract_signal_name_from_ast($lhs_ast);
    unless (defined $lhs_name) {
        fsm_debug("WARNING: Could not extract signal name from AST, using fallback", 3);
        $lhs_name = 'unknown_signal';
    }
    fsm_debug("GET_DEFAULT_VALUE_FROM_AST: Getting default value for '$lhs_name'", 3);
    
    # Try AST methods first
    if ($lhs_ast->can('default_value')) {
        my $default_val = $lhs_ast->default_value();
        if (defined $default_val) {
            fsm_debug("  AST default_value: '$default_val'", 3);
            return $default_val;
        }
    }
    
    # Fallback to reset_value if available
    if ($lhs_ast->can('reset_value')) {
        my $reset_val = $lhs_ast->reset_value();
        if (defined $reset_val) {
            fsm_debug("  Using AST reset_value as default: '$reset_val'", 3);
            return $reset_val;
        }
    }
    
    # Fallback to name-based logic
    fsm_debug("  No AST default value, using fallback", 3);
    return $self->get_default_value($lhs_name);
}

sub get_reset_value_from_ast ($self, $lhs_ast) {
    # AST WEB: Get reset value using direct AST queries  
    # Use proper signal name extraction that handles different AST types
    my $lhs_name = $self->extract_signal_name_from_ast($lhs_ast);
    unless (defined $lhs_name) {
        fsm_debug("WARNING: Could not extract signal name from AST, using fallback", 3);
        $lhs_name = 'unknown_signal';
    }
    fsm_debug("GET_RESET_VALUE_FROM_AST: Getting reset value for '$lhs_name'", 3);
    
    # Try AST method first
    if ($lhs_ast->can('reset_value')) {
        my $reset_val = $lhs_ast->reset_value();
        if (defined $reset_val) {
            fsm_debug("  AST reset_value: '$reset_val'", 3);
            return $reset_val;
        }
    }
    
    # Fallback to name-based logic
    fsm_debug("  No AST reset value, using fallback", 3);
    return $self->get_reset_value($lhs_name);
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
    # Convert FSMGen condition nodes to pure AST nodes
    
    unless ($condition_node) {
        fsm_debug("    CONVERT_CONDITION_AST: WARNING - undefined condition node", 3);
        return FSM::AST::Utils::literal("1'b1");
    }
    
    fsm_debug("    CONVERT_CONDITION_AST: Node type: " . ref($condition_node));
    
    if ($condition_node->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $condition_node->signal->name;
        fsm_debug("    CONVERT_CONDITION_AST: SignalRef -> signal_ref('$signal_name')", 3);
        return FSM::AST::Utils::signal_ref($signal_name);
        
    } elsif (ref($condition_node) eq 'FSM::CoreAST::UnaryOp' || ($condition_node->can('operator') && $condition_node->can('operand'))) {
        # Handle UnaryOp - check the type field which seems to contain the actual operator type
        my $operator_type = 'unknown';
        if (ref($condition_node) eq 'HASH' && $condition_node->{type}) {
            $operator_type = $condition_node->{type};
        } elsif ($condition_node->can('type')) {
            $operator_type = $condition_node->type;
        }
        
        fsm_debug("    CONVERT_CONDITION_AST: UnaryOp with type: $operator_type", 3);
        
        # For negation operations
        if ($operator_type eq 'unary_op' || $operator_type eq 'not' || $operator_type eq '!') {
            my $operand_ast = $self->convert_condition_to_ast($condition_node->operand);
            my $result = FSM::AST::Utils::not_op($operand_ast);
            fsm_debug("    CONVERT_CONDITION_AST: UnaryOp(negation) -> NOT node", 3);
            return $result;
        } else {
            # Other unary operators
            my $operand_ast = $self->convert_condition_to_ast($condition_node->operand);
            my $result = FSM::AST::UnaryOp->new($operator_type, $operand_ast);
            fsm_debug("    CONVERT_CONDITION_AST: UnaryOp($operator_type) -> UnaryOp node", 3);
            return $result;
        }
        
    } elsif (ref($condition_node) eq 'FSM::CoreAST::BinaryOp' || ($condition_node->can('left') && $condition_node->can('right') && $condition_node->can('operator'))) {
        my $left_ast = $self->convert_condition_to_ast($condition_node->left);
        my $right_ast = $self->convert_condition_to_ast($condition_node->right);
        my $op = $condition_node->operator;
        
        my $result;
        if ($op eq '==') {
            $result = FSM::AST::Utils::equals_op($left_ast, $right_ast);
        } elsif ($op eq '&&' || $op eq '&') {
            $result = FSM::AST::Utils::and_op($left_ast, $right_ast);
        } elsif ($op eq '||' || $op eq '|') {
            $result = FSM::AST::Utils::or_op($left_ast, $right_ast);
        } else {
            $result = FSM::AST::BinaryOp->new($op, $left_ast, $right_ast);
        }
        
        fsm_debug("    CONVERT_CONDITION_AST: BinaryOp($op) -> BinaryOp node", 3);
        return $result;
        
    } elsif ($condition_node->isa('FSM::CoreAST::Literal')) {
        my $value = $condition_node->value;
        fsm_debug("    CONVERT_CONDITION_AST: Literal -> literal('$value')", 3);
        return FSM::AST::Utils::literal($value);
        
    } else {
        # Enhanced fallback - try to get more information
        my $node_type = ref($condition_node);
        fsm_debug("    CONVERT_CONDITION_AST: Unknown type '$node_type' - creating generic signal", 3);
        
        # Try to see if we can extract any useful information
        if ($condition_node->can('name')) {
            my $name = eval { $condition_node->name };
            if ($name) {
                fsm_debug("    CONVERT_CONDITION_AST: Found name attribute: $name", 3);
                return FSM::AST::Utils::signal_ref($name);
            }
        }
        
        # Final fallback
        return FSM::AST::Utils::signal_ref("condition");
    }
}

sub convert_test_value_to_ast ($self, $test_value) {
    # Convert test values to AST literal nodes
    
    fsm_debug("    CONVERT_TEST_VALUE_AST: Converting test value: '$test_value'", 3);
    
    # Handle different test value formats
    if ($test_value =~ /^=(\d+)$/) {
        my $val = $1;
        if ($val eq '0') {
            return FSM::AST::Utils::literal("1'b0");
        } elsif ($val eq '1') {
            return FSM::AST::Utils::literal("1'b1");
        } else {
            return FSM::AST::Utils::literal($val);
        }
    } elsif ($test_value =~ /^\d+$/) {
        # Plain number
        if ($test_value eq '0') {
            return FSM::AST::Utils::literal("1'b0");
        } elsif ($test_value eq '1') {
            return FSM::AST::Utils::literal("1'b1");
        } else {
            return FSM::AST::Utils::literal($test_value);
        }
    } else {
        # Other formats - use as-is
        return FSM::AST::Utils::literal($test_value);
    }
}

# Methods for tracking intermediate signals and dependencies

sub track_ast_intermediate_signals ($self, $ast) {
    # Recursively traverse an AST and track all intermediate signals that need to be declared
    return unless $ast && blessed($ast);
    
    fsm_debug("TRACK_INTERMEDIATE: Traversing AST: " . ref($ast));
    
    # If this is a signal reference, check if it's an intermediate signal
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name;
        
        # Handle different signal reference structures - try multiple approaches
        if ($ast->can('name') && defined($ast->name)) {
            $signal_name = $ast->name;
        } elsif ($ast->can('signal_name') && defined($ast->signal_name)) {
            $signal_name = $ast->signal_name;
        } elsif ($ast->can('signal') && $ast->signal && $ast->signal->can('name')) {
            $signal_name = $ast->signal->name;
        } else {
            # Try to extract from string representation as fallback
            my $ast_str = eval { $ast->to_systemverilog() };
            if ($ast_str && $ast_str =~ /^([a-zA-Z_][a-zA-Z0-9_]*)$/) {
                $signal_name = $1;
                fsm_debug("TRACK_INTERMEDIATE: Extracted signal name from string: $signal_name", 3);
            } else {
                fsm_debug("TRACK_INTERMEDIATE: WARNING - Could not extract signal name from " . ref($ast) . 
                            " (available methods: " . join(", ", grep { $ast->can($_) } qw(name signal_name signal to_systemverilog)) . ")");
                return;
            }
        }
        
        # Check if this is an intermediate signal that needs to be declared
        if ($self->is_intermediate_signal($signal_name)) {
            $self->{referenced_intermediate_signals}->{$signal_name} = {
                name => $signal_name,
                ast => $ast,
                needs_declaration => 1
            };
            fsm_debug("TRACK_INTERMEDIATE: Found intermediate signal: $signal_name", 3);
        }
    }
    # Recursively traverse operands
    elsif ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        $self->track_ast_intermediate_signals($ast->left) if $ast->can('left');
        $self->track_ast_intermediate_signals($ast->right) if $ast->can('right');
    }
    elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        $self->track_ast_intermediate_signals($ast->operand) if $ast->can('operand');
    }
}

sub is_intermediate_signal ($self, $signal_name) {
    # Determine if a signal is an intermediate signal that needs to be declared
    # USES AST-BASED OPERATOR TYPE CHECKING - No string pattern matching!
    
    fsm_debug("IS_INTERMEDIATE_SIGNAL: Checking '$signal_name'", 3);
    
    # Check against our intermediate signals registry first (highest priority)
    if (exists $self->{intermediate_signals}->{$signal_name}) {
        fsm_debug("  -> YES: Found in intermediate_signals registry", 3);
        return 1;
    }
    if (exists $self->{global_expressions}->{$signal_name}) {
        fsm_debug("  -> YES: Found in global_expressions registry", 3);
        return 1;
    }
    
    # Check if this signal is tracked in AST factorization results
    if ($self->{ast_factorizer} && $self->{ast_factorizer}->{intermediate_signals}) {
        if (exists $self->{ast_factorizer}->{intermediate_signals}->{$signal_name}) {
            fsm_debug("  -> YES: Found in AST factorizer results", 3);
            return 1;
        }
    }
    
    # Check if this signal has been pre-scanned as needing declaration
    if ($self->{referenced_intermediate_signals} && exists $self->{referenced_intermediate_signals}->{$signal_name}) {
        fsm_debug("  -> YES: Found in pre-scan referenced signals", 3);
        return 1;
    }
    
    # AST-BASED CHECK: Look for this signal in our AST-based operator type registry
    if ($self->is_signal_ast_based_intermediate($signal_name)) {
        fsm_debug("  -> YES: AST-based intermediate signal detected", 3);
        return 1;
    }
    
    fsm_debug("  -> NO: Not an intermediate signal", 3);
    return 0;
}

sub is_signal_ast_based_intermediate ($self, $signal_name) {
    # AST-BASED INTERMEDIATE SIGNAL DETECTION
    # This method replaces string-based pattern matching with proper AST analysis
    # to determine if a signal represents an intermediate signal from an AST operation.
    
    fsm_debug("AST_INTERMEDIATE_CHECK: Checking if '$signal_name' is an AST-based intermediate signal", 3);
    
    # Check if this signal has AST metadata indicating it's an intermediate signal
    # This could come from:
    # 1. AST factorization results that store operator type metadata
    # 2. Signal generation during AST-to-SystemVerilog conversion
    # 3. Expression naming that embeds AST operator type information
    
    # METHOD 1: Check if this signal was generated by AST factorization
    if ($self->{ast_factorizer} && $self->{ast_factorizer}->{intermediate_signals}) {
        if (exists $self->{ast_factorizer}->{intermediate_signals}->{$signal_name}) {
            my $signal_info = $self->{ast_factorizer}->{intermediate_signals}->{$signal_name};
            
            # Check if the AST contains operator types that qualify as intermediate
            if ($signal_info->{ast} && blessed($signal_info->{ast})) {
                my $contains_operators = $self->_ast_contains_factorizable_operators($signal_info->{ast});
                if ($contains_operators) {
                    fsm_debug("  AST_INTERMEDIATE: Signal '$signal_name' contains factorizable operators - INTERMEDIATE", 3);
                    return 1;
                }
            }
        }
    }
    
    # METHOD 2: Check global expression registry for AST-generated signals
    if ($self->{global_expressions}) {
        # Find the expression that maps to this signal name
        for my $expr (keys %{$self->{global_expressions}}) {
            if ($self->{global_expressions}->{$expr} eq $signal_name) {
                # Try to parse this expression back to AST to analyze its operator content
                my $ast = eval { $self->{expr_namer}->parse_expression($expr) } if $self->{expr_namer};
                if ($ast && blessed($ast)) {
                    my $contains_operators = $self->_ast_contains_factorizable_operators($ast);
                    if ($contains_operators) {
                        fsm_debug("  AST_INTERMEDIATE: Signal '$signal_name' derived from AST with operators - INTERMEDIATE", 3);
                        return 1;
                    }
                }
                # If AST parsing fails, no determination can be made
                last;
            }
        }
    }
    
    # METHOD 3: Check if the signal name follows systematic AST-based naming patterns
    # These patterns are generated by generate_ast_based_signal_name() and indicate
    # that the signal was created from an AST with embedded operator type information
    if ($self->_signal_name_indicates_ast_operators($signal_name)) {
        fsm_debug("  AST_INTERMEDIATE: Signal '$signal_name' follows AST-based naming - INTERMEDIATE", 3);
        return 1;
    }
    
    # METHOD 4: Check if this signal appears in any of our AST-based registries
    # that track intermediate signals with operator metadata
    if ($self->{expression_usage} && exists $self->{expression_usage}->{$signal_name}) {
        # Signal is tracked in expression usage - could be intermediate
        # Check if we can find associated operator information
        my $usage_count = $self->{expression_usage}->{$signal_name};
        if ($usage_count > 1) {
            # Multi-use signals are typically intermediate signals
            fsm_debug("  AST_INTERMEDIATE: Signal '$signal_name' is multi-use ($usage_count times) - LIKELY INTERMEDIATE", 3);
            return 1;
        }
    }
    
    fsm_debug("  AST_INTERMEDIATE: Signal '$signal_name' shows no AST-based operator indicators - NOT INTERMEDIATE", 3);
    return 0;
}

sub _ast_contains_factorizable_operators ($self, $ast) {
    # Check if an AST contains operators that would qualify it as an intermediate signal
    # This uses the same logic as the AST factorization to determine if expressions
    # should be factored into intermediate signals.
    
    return 0 unless $ast && blessed($ast);
    
    # UNARY OPERATIONS: Always factor (per specification)
    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        fsm_debug("    AST_OPERATORS: Found unary operation - FACTORIZABLE", 3);
        return 1;
    }
    
    # BINARY OPERATIONS: Check type and usage patterns
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Arithmetic operations: Always factor (per specification)
        if ($self->is_arithmetic_operation($ast)) {
            fsm_debug("    AST_OPERATORS: Found arithmetic operation - FACTORIZABLE", 3);
            return 1;
        }
        
        # Logical operations: Factor if used multiple times (per specification)
        if ($self->is_logical_operation($ast)) {
            if ($self->should_factor_logical_operation($ast)) {
                fsm_debug("    AST_OPERATORS: Found multi-use logical operation - FACTORIZABLE", 3);
                return 1;
            } else {
                fsm_debug("    AST_OPERATORS: Found single-use logical operation - NOT factorizable", 3);
                return 0;
            }
        }
        
        # Other binary operations (comparisons, etc.): Generally factor
        fsm_debug("    AST_OPERATORS: Found other binary operation - FACTORIZABLE", 3);
        return 1;
    }
    
    # Literals and signal references are not factorizable
    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal') ||
        $ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        fsm_debug("    AST_OPERATORS: Found literal/signal reference - NOT factorizable", 3);
        return 0;
    }
    
    # Recursively check child nodes
    if ($ast->can('left') && $self->_ast_contains_factorizable_operators($ast->left)) {
        return 1;
    }
    if ($ast->can('right') && $self->_ast_contains_factorizable_operators($ast->right)) {
        return 1;
    }
    if ($ast->can('operand') && $self->_ast_contains_factorizable_operators($ast->operand)) {
        return 1;
    }
    
    # No factorizable operators found
    return 0;
}

sub _signal_name_indicates_ast_operators ($self, $signal_name) {
    # PURE AST-BASED APPROACH: NO STRING PATTERN MATCHING ALLOWED!
    # This method should ONLY use AST metadata and operator type information,
    # never string patterns or heuristics based on signal names.
    
    fsm_debug("\n*** _signal_name_indicates_ast_operators: Analyzing signal '$signal_name' ***", 3);
    fsm_debug("    AST_NAME_PATTERN: Using PURE AST metadata approach - no string patterns!", 3);
    
    # SINGLE METHOD: Check if this signal name appears in our AST-generated signal registry
    # These are signals that were created directly from AST factorization with full metadata
    # This registry is populated during the factorization phase - NO late-stage signal generation!
    fsm_debug("    CHECKING REGISTRY #1: global_expressions (AST factorization registry)", 3);
    if ($self->{global_expressions}) {
        fsm_debug("      Registry has " . scalar(keys %{$self->{global_expressions}}) . " entries", 3);
        for my $expr (keys %{$self->{global_expressions}}) {
            if ($self->{global_expressions}->{$expr} eq $signal_name) {
                fsm_debug("      FOUND: Signal '$signal_name' maps to expression: '$expr'", 3);
                # Found the expression that maps to this signal name
                # Parse it back to AST to check for factorizable operators
                my $ast = eval { $self->{expr_namer}->parse_expression($expr) } if $self->{expr_namer};
                if ($ast && blessed($ast) && $self->_ast_contains_factorizable_operators($ast)) {
                    fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' has AST metadata with operators - INTERMEDIATE", 3);
                    return 1;
                }
                # If we found the expression but it has no factorizable operators, it's not intermediate
                fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' has AST metadata without factorizable operators - NOT intermediate", 3);
                return 0;
            }
        }
        fsm_debug("      NOT FOUND: Signal '$signal_name' not found in global_expressions registry", 3);
    } else {
        fsm_debug("      WARNING: global_expressions registry is empty or not initialized", 3);
    }
    
    # CRITICAL FIX: Also check FSMGenFull signal registry for intermediate signals
    # or_* signals are created during FSMGenFull parsing with 'is_intermediate' => 1
    # but they're not in the AST factorization registry
    fsm_debug("    CHECKING REGISTRY #2: fsm_module->signals (FSMGenFull signal registry)", 3);
    if ($self->{fsm_module} && $self->{fsm_module}->can('signals') && $self->{fsm_module}->signals) {
        my $signals = $self->{fsm_module}->signals;
        fsm_debug("      Registry has " . scalar(keys %$signals) . " signals", 3);
        
        # Debug: list all signals with or_ prefix
        my @or_signals = grep { /^or_/ } keys %$signals;
        if (@or_signals) {
            fsm_debug("      FOUND OR SIGNALS: " . join(", ", @or_signals), 3);
        } else {
            fsm_debug("      NO OR SIGNALS found in registry!", 3);
        }
        
        if (exists $signals->{$signal_name}) {
            my $signal = $signals->{$signal_name};
            fsm_debug("      FOUND: Signal '$signal_name' in FSMGenFull signals registry", 3);
            fsm_debug("      Signal object type: " . (ref($signal) || "UNTYPED"), 3);
            fsm_debug("      Signal blessed: " . (blessed($signal) ? "YES" : "NO"), 3);
            
            # METHOD 1: Check attributes hash
            fsm_debug("      CHECK #1: Checking 'attributes' hash method", 3);
            if (blessed($signal) && $signal->can('attributes')) {
                fsm_debug("        Signal has 'attributes' method", 3);
                my $attrs = $signal->attributes || {};
                fsm_debug("        Attributes: " . join(", ", map {"$_=>".(defined $attrs->{$_} ? $attrs->{$_} : "undef")} keys %$attrs), 3);
                if (exists $attrs->{is_intermediate}) {
                    fsm_debug("        Found 'is_intermediate' attribute: " . ($attrs->{is_intermediate} ? "TRUE" : "FALSE"), 3);
                    if ($attrs->{is_intermediate}) {
                        fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' found in FSMGenFull with is_intermediate=1 - INTERMEDIATE", 3);
                        return 1;
                    }
                } else {
                    fsm_debug("        No 'is_intermediate' attribute found", 3);
                }
            } else {
                fsm_debug("        Signal doesn't have 'attributes' method", 3);
            }
            
            # METHOD 2: Check direct is_intermediate method or property
            fsm_debug("      CHECK #2: Checking direct 'is_intermediate' method or property", 3);
            my $has_method = blessed($signal) && $signal->can('is_intermediate');
            my $is_hash = ref($signal) eq 'HASH';
            my $has_property = $is_hash && exists $signal->{is_intermediate};
            
            fsm_debug("        Has is_intermediate method: " . ($has_method ? "YES" : "NO"), 3);
            fsm_debug("        Is hash ref: " . ($is_hash ? "YES" : "NO"), 3);
            fsm_debug("        Has is_intermediate property: " . ($has_property ? "YES" : "NO"), 3);
            
            if ($has_method || $has_property) {
                my $is_intermediate = $has_method ? $signal->is_intermediate() : $signal->{is_intermediate};
                fsm_debug("        is_intermediate value: " . (defined $is_intermediate ? ($is_intermediate ? "TRUE" : "FALSE") : "UNDEF"), 3);
                if ($is_intermediate) {
                    fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' found in FSMGenFull with is_intermediate - INTERMEDIATE", 3);
                    return 1;
                }
            }
            
            # METHOD 3: Check raw dump of the signal object
            fsm_debug("      CHECK #3: Dumping signal object structure", 3);
            my $dump = Data::Dumper->new([$signal])->Terse(1)->Indent(0)->Dump;
            $dump =~ s/\n/ /g;
            fsm_debug("        SIGNAL DUMP: $dump", 3);
            # Look for is_intermediate in the dump (last resort)
            if ($dump =~ /is_intermediate[\s=>'"]*([^,}\s'"]+)/) {
                my $value = $1;
                fsm_debug("        Found is_intermediate='$value' in dump", 3);
                if ($value && $value !~ /^(0|false|no|undef|null)$/i) {
                    fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' has is_intermediate in dump - INTERMEDIATE", 3);
                    return 1;
                }
            } else {
                fsm_debug("        No is_intermediate found in dump", 3);
            }
            
            # METHOD 4: Check the driving_ast property if it exists
            fsm_debug("      CHECK #4: Checking for driving_ast property", 3);
            if (blessed($signal) && $signal->can('driving_ast') && $signal->driving_ast) {
                fsm_debug("        Signal has driving_ast", 3);
                my $driving_ast = $signal->driving_ast;
                if (blessed($driving_ast)) {
                    fsm_debug("        AST type: " . ref($driving_ast), 3);
                    my $contains_operators = $self->_ast_contains_factorizable_operators($driving_ast);
                    fsm_debug("        Contains factorizable operators: " . ($contains_operators ? "YES" : "NO"), 3);
                    if ($contains_operators) {
                        fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' has driving_ast with operators - INTERMEDIATE", 3);
                        return 1;
                    }
                }
            } else {
                fsm_debug("        Signal doesn't have driving_ast or it's not set", 3);
            }
            
            # METHOD 5: If it's an or_* signal by name pattern, do a final pattern check
            # This is a fallback heuristic for extreme cases when metadata isn't properly set
            if ($signal_name =~ /^or_\d+_\d+$/) {
                fsm_debug("      CHECK #5: Last resort - Signal matches or_* pattern", 3);
                fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' matches or_* pattern - CONSIDERING INTERMEDIATE", 3);
                
                # Additional safety - require or_* signals to be in the proper registry
                if (exists $signals->{$signal_name}) {
                    fsm_debug("        Signal exists in fsm_module->signals registry - DEFINITELY INTERMEDIATE", 3);
                    return 1;
                }
            }
        } else {
            fsm_debug("      NOT FOUND: Signal '$signal_name' not found in FSMGenFull signals registry", 3);
        }
    } else {
        fsm_debug("      WARNING: FSM module signals registry is empty or not initialized", 3);
        if (!$self->{fsm_module}) {
            fsm_debug("        Reason: fsm_module is not set", 3);
        } elsif (!$self->{fsm_module}->can('signals')) {
            fsm_debug("        Reason: fsm_module doesn't have signals method", 3);
        } elsif (!$self->{fsm_module}->signals) {
            fsm_debug("        Reason: fsm_module->signals returns empty", 3);
        }
    }
    
    # NO LATE-STAGE SIGNAL GENERATION OR FALLBACK METHODS!
    # If the signal is not in the AST-generated registry, it's not an AST-based intermediate signal.
    # We removed METHOD 2 (expression namer tracing) as redundant with METHOD 1.
    # We removed METHOD 3 (late-stage conversion signals) as it violates the pipeline design.
    fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' not found in any registry - NOT intermediate", 3);
    return 0;
}

sub ast_to_systemverilog ($self, $ast) {
    # Convert AST to SystemVerilog with proper operator selection and parentheses
    return "1'b1" unless $ast && blessed($ast);
    
    # Use AST-based conversion with proper operator precedence
    my $sv = $self->_ast_to_systemverilog_internal($ast, undef);
    
    # DEBUGGING: Track where AST-to-SV conversion is called from
    my ($package, $filename, $line, $subroutine) = caller(1);
    fsm_debug("*** AST_TO_SV_DEBUG: $sv ***", 3);
    fsm_debug("    Called from: $subroutine at line $line", 3);
    fsm_debug("    AST type: " . ref($ast), 3);
    
    return $sv;
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
    # Generate declarations for all intermediate signals that were referenced
    my $hdl = "";
    
    # Check if we have any intermediate signals to declare
    return $hdl unless $self->{referenced_intermediate_signals} && %{$self->{referenced_intermediate_signals}};
    
    $hdl .= "\n  // Intermediate signals referenced in enable expressions\n";
    
    for my $signal_name (sort keys %{$self->{referenced_intermediate_signals}}) {
        my $signal_info = $self->{referenced_intermediate_signals}->{$signal_name};
        
        # Skip if already declared
        next if $signal_info->{declared};
        
        # Get the expression for this intermediate signal
        my $expression = $self->get_intermediate_signal_expression($signal_name);
        if ($expression) {
            # Generate wire declaration and assign statement
            $hdl .= "  wire $signal_name;\n";
            $hdl .= "  assign $signal_name = $expression;\n";
            
            # Mark as declared
            $signal_info->{declared} = 1;
            
            fsm_debug("DECLARED_INTERMEDIATE: wire $signal_name = $expression", 3);
        } else {
            fsm_debug("WARNING: No expression found for intermediate signal: $signal_name", 3);
        }
    }
    
    # Add empty line after intermediate signals
    $hdl .= "\n" if $hdl;
    
    return $hdl;
}

sub get_intermediate_signal_expression ($self, $signal_name) {
    # Get the expression for an intermediate signal from various sources
    
    # Check the intermediate_signals registry
    if (exists $self->{intermediate_signals}->{$signal_name}) {
        return $self->{intermediate_signals}->{$signal_name};
    }
    
    # Check global expressions registry
    for my $expr (keys %{$self->{global_expressions}}) {
        if ($self->{global_expressions}->{$expr} eq $signal_name) {
            return $expr;
        }
    }
    
    # Try to generate the expression based on naming patterns
    return $self->generate_expression_from_signal_name($signal_name);
}

sub generate_expression_from_signal_name ($self, $signal_name) {
    # Generate SystemVerilog expression from intermediate signal name patterns
    
    # s_rst_n_and_* patterns
    if ($signal_name =~ /^s_rst_n_and_(.+)$/) {
        my $rest = $1;
        $rest =~ s/_and_/ & /g;
        return "s_rst_n & $rest";
    }
    
    # not_* patterns
    if ($signal_name =~ /^not_(.+)$/) {
        return "!$1";
    }
    
    # *_and_* patterns
    if ($signal_name =~ /^(.+)_and_(.+)$/) {
        my ($left, $right) = ($1, $2);
        $left =~ s/_and_/ & /g;
        $right =~ s/_and_/ & /g;
        return "$left & $right";
    }
    
    # *_or_* patterns
    if ($signal_name =~ /^(.+)_or_(.+)$/) {
        my ($left, $right) = ($1, $2);
        $left =~ s/_or_/ | /g;
        $right =~ s/_or_/ | /g;
        return "$left | $right";
    }
    
    # Default: return the signal name itself (might be an error)
    fsm_debug("WARNING: Could not generate expression for intermediate signal: $signal_name", 3);
    return "1'b0"; # Safe default
}

=head2 feed_asts_to_factorizer($factorizer)

Feed all AST expressions to the generic factorizer.
This replaces the broken string-based collection with pure AST feeding.

=cut

sub prescan_wen_en_for_intermediate_signals ($self) {
    # PRE-SCAN all WEN/EN expressions to identify intermediate signals that need to be declared
    # This runs BEFORE generating intermediate signals so we know which ones to create
    
    fsm_debug("\n*** PRE-SCAN: IDENTIFYING INTERMEDIATE SIGNALS NEEDED FOR WEN/EN ***", 3);
    fsm_debug("*** TIMING DEBUG: PRE-SCAN running WITHOUT logical operation counts! ***", 3);
    
    # Check if we have logical operation counts available
    if (exists $self->{binary_logical_op_counts}) {
        my $total_ops = 0;
        for my $count (values %{$self->{binary_logical_op_counts}}) {
            $total_ops += $count;
        }
        fsm_debug("PRE-SCAN: Logical operation counts ARE available: $total_ops total ops", 3);
        fsm_debug("PRE-SCAN: Counts: " . Data::Dumper::Dumper($self->{binary_logical_op_counts}));
    } else {
        fsm_debug("*** PRE-SCAN: CRITICAL - Logical operation counts NOT available yet! ***", 3);
        fsm_debug("*** This means pre-scan is creating intermediate signals blindly! ***", 3);
    }
    
    # Initialize tracking structure
    $self->{referenced_intermediate_signals} //= {};
    
    # Process each LHS from the unified analysis to scan all enable expressions
    for my $lhs (sort keys %{$self->{assignment_analysis}}) {
        my $lhs_analysis = $self->{assignment_analysis}->{$lhs};
        
        # Scan all DT-specific enable expressions
        for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
            my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
            
            # Scan DT-specific enable ASTs for intermediate signal references
            for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                my $enable_ast = $dt_enable_info->{enable_ast};
                
                if ($enable_ast && blessed($enable_ast)) {
                    fsm_debug("  PRE-SCAN: Scanning DT-specific enable: $dt_enable_info->{enable_name}", 3);
                    $self->track_ast_intermediate_signals($enable_ast);
                }
            }
            
            # Scan LHS-level enable ASTs for intermediate signal references
            if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                my $lhs_enable = $rhs_group->{lhs_level_enable};
                my $enable_ast = $lhs_enable->{ast};
                
                if ($enable_ast && blessed($enable_ast)) {
                    fsm_debug("  PRE-SCAN: Scanning LHS-level enable: $lhs_enable->{name}", 3);
                    $self->track_ast_intermediate_signals($enable_ast);
                }
            }
        }
    }
    
    # Count discovered intermediate signals
    my $signal_count = scalar(keys %{$self->{referenced_intermediate_signals}});
    fsm_debug("PRE-SCAN: Identified $signal_count intermediate signals that need declaration", 3);
    
    # Debug list of discovered signals
    if ($signal_count > 0) {
        for my $signal_name (sort keys %{$self->{referenced_intermediate_signals}}) {
            fsm_debug("  - $signal_name", 3);
        }
    }
    
    fsm_debug("*** PRE-SCAN COMPLETE ***\n", 3);
}

sub feed_asts_to_factorizer {
    my ($self, $factorizer) = @_;
    
    fsm_debug("FEED_ASTS: Feeding AST expressions to generic factorizer", 3);
    
    my $total_fed = 0;
    my $dt_enables_fed = 0;
    my $lhs_enables_fed = 0;
    my $assignment_conditions_fed = 0;
    
    # Feed from unified assignment analysis
    if ($self->{assignment_analysis}) {
        my $total_lhs = scalar(keys %{$self->{assignment_analysis}});
        fsm_debug("FEED_ASTS: Processing $total_lhs LHS signals from assignment analysis", 3);
        
        for my $lhs (keys %{$self->{assignment_analysis}}) {
            my $lhs_analysis = $self->{assignment_analysis}{$lhs};
            my $rhs_count = scalar(keys %{$lhs_analysis->{rhs_groups}});
            fsm_debug("  LHS '$lhs' has $rhs_count RHS groups", 3);
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
                
                # Feed DT-specific enable ASTs
                my $dt_enable_count = scalar(@{$rhs_group->{dt_specific_enables} || []});
                fsm_debug("    RHS '$rhs' has $dt_enable_count DT-specific enables", 3);
                
                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast} && blessed($dt_enable->{enable_ast})) {
                        my $sv = eval { $dt_enable->{enable_ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
                        
                        $factorizer->add_ast_expression(
                            $dt_enable->{enable_ast},
                            "dt_enable:$dt_enable->{enable_name}"
                        );
                        $total_fed++;
                        $dt_enables_fed++;
                        fsm_debug("  Fed DT-specific AST: $dt_enable->{enable_name}", 3);
                        fsm_debug("    Expression: $sv", 3);
                    } else {
                        fsm_debug("  SKIPPED DT-specific enable (no AST): $dt_enable->{enable_name}", 3);
                    }
                }
                
                # Feed LHS-level enable ASTs
                if ($rhs_group->{lhs_level_enable}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    if ($lhs_enable->{ast} && blessed($lhs_enable->{ast})) {
                        my $sv = eval { $lhs_enable->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
                        
                        $factorizer->add_ast_expression(
                            $lhs_enable->{ast},
                            "lhs_enable:$lhs_enable->{name}"
                        );
                        $total_fed++;
                        $lhs_enables_fed++;
                        fsm_debug("  Fed LHS-level AST: $lhs_enable->{name}", 3);
                        fsm_debug("    Expression: $sv", 3);
                    } else {
                        fsm_debug("  SKIPPED LHS-level enable (no AST): $lhs_enable->{name}", 3);
                    }
                }
            }
        }
    } else {
        fsm_debug("*** WARNING: No assignment_analysis available for AST feeding! ***", 3);
    }
    
    # Feed from any assignments with stored ASTs
    my $total_assignments = 0;
    for my $lhs (keys %{$self->{lhs_assignments} || {}}) {
        $total_assignments += scalar(@{$self->{lhs_assignments}{$lhs}});
    }
    
    fsm_debug("FEED_ASTS: Processing $total_assignments assignment conditions", 3);
    
    for my $lhs (keys %{$self->{lhs_assignments} || {}}) {
        for my $assignment (@{$self->{lhs_assignments}{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                my $sv = eval { $assignment->{conditions_ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
                
                $factorizer->add_ast_expression(
                    $assignment->{conditions_ast},
                    "assignment_condition:$lhs:$assignment->{dt}"
                );
                $total_fed++;
                $assignment_conditions_fed++;
                fsm_debug("  Fed assignment condition AST: $lhs from $assignment->{dt}", 3);
                fsm_debug("    Expression: $sv", 3);
            }
        }
    }
    
    # CRITICAL FIX: Feed intermediate signals from FSMGenFull parsing
    my $fsmgen_intermediate_fed = 0;
    if ($self->{fsm_module} && $self->{fsm_module}->can('signals') && $self->{fsm_module}->signals) {
        fsm_debug("FEED_ASTS: Processing FSMGenFull intermediate signals", 3);
        my $fsm_signals = $self->{fsm_module}->signals;
        
        for my $signal_name (keys %$fsm_signals) {
            my $signal = $fsm_signals->{$signal_name};
            
            # Check if this signal has driving_ast and is marked as intermediate
            if ($signal && $signal->can('driving_ast') && $signal->driving_ast) {
                my $is_intermediate = 0;
                if ($signal->can('get_attribute')) {
                    $is_intermediate = $signal->get_attribute('is_intermediate');
                } elsif ($signal->can('attributes') && $signal->attributes) {
                    $is_intermediate = $signal->attributes->{is_intermediate};
                }
                
                # Feed intermediate signals - only based on is_intermediate flag, not naming patterns
                if ($is_intermediate) {
                    my $driving_ast = $signal->driving_ast;
                    if (blessed($driving_ast)) {
                        my $sv = eval { $driving_ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
                        
                        $factorizer->add_ast_expression(
                            $driving_ast,
                            "fsmgen_intermediate:$signal_name"
                        );
                        $total_fed++;
                        $fsmgen_intermediate_fed++;
                        fsm_debug("  Fed FSMGenFull intermediate AST: $signal_name", 3);
                        fsm_debug("    Expression: $sv", 3);
                    }
                }
            }
        }
    }
    
    fsm_debug("FEED_ASTS: Fed $total_fed total AST expressions to factorizer", 3);
    fsm_debug("  - DT-specific enables: $dt_enables_fed", 3);
    fsm_debug("  - LHS-level enables: $lhs_enables_fed", 3);
    fsm_debug("  - Assignment conditions: $assignment_conditions_fed", 3);
    fsm_debug("  - FSMGenFull intermediates: $fsmgen_intermediate_fed", 3);
    
    return $total_fed;
}

sub count_unary_negations_in_original_expressions {
    my ($self) = @_;
    
    my $neg_count = 0;
    my %neg_patterns;
    
    # Check all assignment analysis expressions
    if ($self->{assignment_analysis}) {
        for my $lhs (keys %{$self->{assignment_analysis}}) {
            my $lhs_analysis = $self->{assignment_analysis}{$lhs};
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
                
                # Check DT-specific enables
                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast} && blessed($dt_enable->{enable_ast})) {
                        my $sv = eval { $dt_enable->{enable_ast}->to_systemverilog() } || "[NO SV]";
                        if ($sv =~ /!\w+/) {
                            $neg_count++;
                            $neg_patterns{$sv}++;
                            fsm_debug("    UNARY_NEG: $sv in DT enable $dt_enable->{enable_name}", 3);
                        }
                    }
                }
                
                # Check LHS-level enables
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $sv = eval { $rhs_group->{lhs_level_enable}{ast}->to_systemverilog() } || "[NO SV]";
                    if ($sv =~ /!\w+/) {
                        $neg_count++;
                        $neg_patterns{$sv}++;
                        fsm_debug("    UNARY_NEG: $sv in LHS enable $rhs_group->{lhs_level_enable}{name}", 3);
                    }
                }
            }
        }
    }
    
    fsm_debug("  Found $neg_count unary negations in expressions:", 3);
    for my $pattern (sort keys %neg_patterns) {
        fsm_debug("    '$pattern' appears $neg_patterns{$pattern} times", 3);
    }
}

sub should_filter_consolidated_signal ($self, $expression, $signal_name, $signal_info) {
    # AST-BASED FILTERING - Use semantic analysis instead of string patterns
    # This replaces the old string-based regex filtering with proper AST analysis
    
    fsm_debug("\n*** AST_FILTER_CHECK: Analyzing signal '$signal_name' ***", 3);
    fsm_debug("  Expression: '$expression'", 3);
    fsm_debug("  Source: $signal_info->{source}", 3);
    fsm_debug("  Usage count: " . ($signal_info->{usage_count} || 'unknown'));
    
    # Try to get the AST for this signal if available
    my $ast = undef;
    if ($signal_info->{ast}) {
        $ast = $signal_info->{ast};
        fsm_debug("  Using AST from signal_info: " . ref($ast));
    } else {
        # Try to parse the expression back to AST for analysis
        $ast = eval { $self->{expr_namer}->parse_expression($expression) };
        if ($ast) {
            fsm_debug("  Parsed expression to AST: " . ref($ast));
        } else {
            fsm_debug("  Could not parse expression to AST - falling back to string analysis", 3);
        }
    }
    
    # AST-based filtering when AST is available
    if ($ast && blessed($ast)) {
        return $self->should_filter_ast_based($ast, $signal_name, $signal_info);
    }
    
    # Fallback to string-based filtering (legacy compatibility)
    return $self->should_filter_string_based($expression, $signal_name, $signal_info);
}

sub should_filter_ast_based ($self, $ast, $signal_name, $signal_info) {
    # Pure AST-based filtering using semantic analysis
    
    fsm_debug("  AST_FILTER: Using AST-based filtering for " . ref($ast));
    
    my $usage_count = $signal_info->{usage_count} || 0;
    my $actually_used = $self->is_signal_actually_used_in_final_expressions($signal_name);
    
    # REFERENCE-AWARE FILTERING: Check if signal is referenced in substituted expressions
    # This is the fix for the bug where intermediate signals are referenced but not declared
    my $referenced_in_substitutions = $self->is_signal_referenced_in_substitutions($signal_name);
    if ($referenced_in_substitutions) {
        fsm_debug("  AST_FILTER: Signal '$signal_name' is referenced in AST substitutions - KEEPING", 3);
        return 0; # Keep signals that are already referenced in substituted expressions
    }
    
    # AST_FILTER 1: TEMPORARILY DISABLED - Filter if not actually used
    # The usage tracking is not working correctly after AST substitution
    # So we're temporarily disabling this aggressive filtering
    if (!$actually_used || $usage_count == 0) {
        fsm_debug("  AST_FILTER: Signal appears unused (usage_count=$usage_count, actually_used=$actually_used) - but KEEPING due to usage tracking issues", 3);
        # return 1;  # DISABLED - usage tracking is broken
    }
    
    # AST_FILTER 2: Filter simple literals
    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        fsm_debug("  AST_FILTER: Simple literal - FILTERING", 3);
        return 1;
    }
    
    # AST_FILTER 3: Filter bare signal references (signal = signal)
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        fsm_debug("  AST_FILTER: Bare signal reference - FILTERING", 3);
        return 1;
    }
    
    # AST_FILTER 4: Handle unary operations (like negation)
    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        # Check if it's a simple negation of a signal
        if ($self->is_simple_negation($ast)) {
            # Only factor if used multiple times
            if ($usage_count >= 2) {
                fsm_debug("  AST_FILTER: Simple negation used $usage_count times - KEEPING", 3);
                return 0;
            } else {
                fsm_debug("  AST_FILTER: Simple negation used only once - FILTERING", 3);
                return 1;
            }
        } else {
            # Complex unary operation - always keep
            fsm_debug("  AST_FILTER: Complex unary operation - KEEPING", 3);
            return 0;
        }
    }
    
    # AST_FILTER 5: Handle binary operations
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Check if it's a simple comparison
        if ($self->is_simple_comparison($ast)) {
            fsm_debug("  AST_FILTER: Simple comparison - FILTERING", 3);
            return 1;
        }
        
        # Check if it's an arithmetic operation (always keep)
        if ($self->is_arithmetic_operation($ast)) {
            fsm_debug("  AST_FILTER: Arithmetic operation - KEEPING", 3);
            return 0;
        }
        
        # Check if it's a logical operation
        if ($self->is_logical_operation($ast)) {
            # Use the existing AST-based logical operation factorization logic
            my $should_factor = $self->should_factor_logical_operation($ast);
            if ($should_factor && $usage_count >= 2) {
                fsm_debug("  AST_FILTER: Multi-use logical operation - KEEPING", 3);
                return 0;
            } else {
                fsm_debug("  AST_FILTER: Low-use logical operation - FILTERING", 3);
                return 1;
            }
        }
        
        # Other binary operations - keep if used multiple times
        if ($usage_count >= 2) {
            fsm_debug("  AST_FILTER: Multi-use binary operation - KEEPING", 3);
            return 0;
        } else {
            fsm_debug("  AST_FILTER: Single-use binary operation - FILTERING", 3);
            return 1;
        }
    }
    
    # Default: keep complex expressions that are used multiple times
    if ($usage_count >= 2) {
        fsm_debug("  AST_FILTER: Complex multi-use expression - KEEPING", 3);
        return 0;
    } else {
        fsm_debug("  AST_FILTER: Complex single-use expression - FILTERING", 3);
        return 1;
    }
}

sub is_simple_negation ($self, $ast) {
    # Check if this is a simple negation of a signal (like !signal_name)
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp');
    return 0 unless $ast->can('operator') && $ast->can('operand');
    
    my $op = $ast->operator || '';
    return 0 unless $op =~ /^(!|not)$/;
    
    my $operand = $ast->operand;
    return 0 unless $operand && blessed($operand);
    
    # Check if operand is a simple signal reference
    return ($operand->isa('FSM::AST::SignalRef') || $operand->isa('FSM::CoreAST::SignalRef'));
}

sub is_simple_comparison ($self, $ast) {
    # Check if this is a simple comparison like signal == constant
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 0 unless $ast->can('operator') && $ast->can('left') && $ast->can('right');
    
    my $op = $ast->operator || '';
    return 0 unless $op =~ /^(==|!=|<|>|<=|>=)$/;
    
    my $left = $ast->left;
    my $right = $ast->right;
    return 0 unless $left && blessed($left) && $right && blessed($right);
    
    # Check if one side is a signal and the other is a literal
    my $has_signal = ($left->isa('FSM::AST::SignalRef') || $left->isa('FSM::CoreAST::SignalRef')) ||
                     ($right->isa('FSM::AST::SignalRef') || $right->isa('FSM::CoreAST::SignalRef'));
    my $has_literal = ($left->isa('FSM::AST::Literal') || $left->isa('FSM::CoreAST::Literal')) ||
                      ($right->isa('FSM::AST::Literal') || $right->isa('FSM::CoreAST::Literal'));
    
    return $has_signal && $has_literal;
}

sub should_filter_string_based ($self, $expression, $signal_name, $signal_info) {
    # NO STRING-BASED FILTERING ALLOWED!
    # This method is now purely AST-based and will NOT use any string patterns or heuristics.
    
    fsm_debug("  NO_STRING_FILTER: Refusing to use string-based filtering - using AST-only approach", 3);
    fsm_debug("  This signals a design issue - all filtering should be AST-based by now!", 3);
    
    # Check if signal is referenced in substitutions (AST-based check)
    my $referenced_in_substitutions = $self->is_signal_referenced_in_substitutions($signal_name);
    if ($referenced_in_substitutions) {
        fsm_debug("  NO_STRING_FILTER: Signal '$signal_name' is referenced in AST substitutions - KEEPING", 3);
        return 0;
    }
    
    # Check if signal is actually used in final expressions (AST-based check)
    my $actually_used = $self->is_signal_actually_used_in_final_expressions($signal_name);
    if ($actually_used) {
        fsm_debug("  NO_STRING_FILTER: Signal '$signal_name' is used in final AST expressions - KEEPING", 3);
        return 0;
    }
    
    # If no AST-based evidence of usage, filter it out
    fsm_debug("  NO_STRING_FILTER: No AST-based evidence of usage for '$signal_name' - FILTERING", 3);
    return 1;
}

sub is_signal_actually_used_in_final_expressions ($self, $signal_name) {
    # Check if a signal is actually referenced in the final WEN/EN expressions
    # This is a more accurate usage check than just counting AST factorization usage
    
    fsm_debug("USAGE_CHECK: Checking if '$signal_name' is actually used in final expressions", 3);
    
    # Check if the signal appears in any of the final enable expressions
    if ($self->{assignment_analysis}) {
        for my $lhs (keys %{$self->{assignment_analysis}}) {
            my $lhs_analysis = $self->{assignment_analysis}->{$lhs};
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
                
                # Check DT-specific enable expressions
                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_ast = $dt_enable_info->{enable_ast};
                    if ($enable_ast && blessed($enable_ast) && $self->ast_contains_signal($enable_ast, $signal_name)) {
                        fsm_debug("    FOUND: Signal used in DT-specific enable $dt_enable_info->{enable_name}", 3);
                        return 1;
                    }
                }
                
                # Check LHS-level enable expressions
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                    my $lhs_enable_ast = $rhs_group->{lhs_level_enable}->{ast};
                    if ($lhs_enable_ast && blessed($lhs_enable_ast) && $self->ast_contains_signal($lhs_enable_ast, $signal_name)) {
                        fsm_debug("    FOUND: Signal used in LHS-level enable $rhs_group->{lhs_level_enable}->{name}", 3);
                        return 1;
                    }
                }
            }
        }
    }
    
    # Also check if it appears in any assignment conditions
    for my $lhs (keys %{$self->{lhs_assignments} || {}}) {
        for my $assignment (@{$self->{lhs_assignments}->{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                if ($self->ast_contains_signal($assignment->{conditions_ast}, $signal_name)) {
                    fsm_debug("    FOUND: Signal used in assignment condition for $lhs", 3);
                    return 1;
                }
            }
        }
    }
    
    fsm_debug("    NOT FOUND: Signal '$signal_name' is not used in any final expressions", 3);
    return 0;
}

sub ast_contains_signal ($self, $ast, $signal_name) {
    # Recursively check if an AST contains a reference to a specific signal
    return 0 unless $ast && blessed($ast);
    
    # If this is a signal reference, check if it matches
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $ast_signal_name = $self->extract_signal_name_from_ast($ast);
        return 1 if $ast_signal_name && $ast_signal_name eq $signal_name;
    }
    
    # CRITICAL FIX: Also check for intermediate signal references from AST substitution
    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        my $ast_signal_name = $ast->{signal_name};
        if ($ast_signal_name && $ast_signal_name eq $signal_name) {
            fsm_debug("    FOUND INTERMEDIATE: Signal '$signal_name' found as IntermediateSignalRef", 3);
            return 1;
        }
    }
    
    # Also check substituted binary and unary ops (which may contain intermediate signal refs)
    if ($ast->isa('FSM::HDL::SubstitutedBinaryOp')) {
        return 1 if $ast->{left} && $self->ast_contains_signal($ast->{left}, $signal_name);
        return 1 if $ast->{right} && $self->ast_contains_signal($ast->{right}, $signal_name);
    }
    elsif ($ast->isa('FSM::HDL::SubstitutedUnaryOp')) {
        return 1 if $ast->{operand} && $self->ast_contains_signal($ast->{operand}, $signal_name);
    }
    
    # Recursively check operands in standard AST nodes
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        return 1 if $ast->can('left') && $self->ast_contains_signal($ast->left, $signal_name);
        return 1 if $ast->can('right') && $self->ast_contains_signal($ast->right, $signal_name);
    }
    elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        return 1 if $ast->can('operand') && $self->ast_contains_signal($ast->operand, $signal_name);
    }
    
    return 0;
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
    # CRITICAL FIX: Update the original AST expressions in assignment_analysis with
    # the substituted versions from the factorizer. This ensures that usage checks
    # will find intermediate signal references and not filter them out.
    
    fsm_debug("UPDATE_ORIGINAL_ASTS: Synchronizing original ASTs with substituted versions", 3);
    
    # Get the mapping of original expressions to their substituted versions
    my $ast_expressions = $factorizer->{ast_expressions};
    my $updated_count = 0;
    my $dt_ast_updates = 0;
    my $lhs_ast_updates = 0;
    my $assignment_ast_updates = 0;
    
    fsm_debug("UPDATE_ORIGINAL_ASTS: Factorizer has " . scalar(@$ast_expressions) . " AST expressions to check against");
    
    # NEW APPROACH: Build a context-to-AST mapping directly from factorizer results
    my %context_to_substituted_ast;
    for my $expr_info (@$ast_expressions) {
        my $context = $expr_info->{context};
        my $substituted_ast = $expr_info->{ast};
        $context_to_substituted_ast{$context} = $substituted_ast;
        
        my $sv = eval { $substituted_ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
        fsm_debug("  Context '$context' -> AST: $sv", 3);
    }
    
    # Update ASTs in assignment_analysis structure
    if ($self->{assignment_analysis}) {
        fsm_debug("UPDATE_ORIGINAL_ASTS: Updating assignment_analysis structure", 3);
        
        for my $lhs (keys %{$self->{assignment_analysis}}) {
            my $lhs_analysis = $self->{assignment_analysis}{$lhs};
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
                
                # Update DT-specific enable ASTs using context mapping
                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_name = $dt_enable_info->{enable_name};
                    my $context_key = "dt_enable:$enable_name";
                    
                    if (exists $context_to_substituted_ast{$context_key}) {
                        my $original_ast = $dt_enable_info->{enable_ast};
                        my $substituted_ast = $context_to_substituted_ast{$context_key};
                        
            my $original_sv = eval { $self->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $self->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
                        
                        $dt_enable_info->{enable_ast} = $substituted_ast;
                        $updated_count++;
                        $dt_ast_updates++;
                        
                        fsm_debug("  *** UPDATED DT-specific enable AST: $enable_name ***", 3);
                        fsm_debug("    Original:  $original_sv", 3);
                        fsm_debug("    Updated:   $substituted_sv", 3);
                    } else {
                        fsm_debug("  No substitution found for DT enable: $dt_enable_info->{enable_name}", 3);
                    }
                }
                
                # Update LHS-level enable ASTs using context mapping
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    my $enable_name = $lhs_enable->{name};
                    my $context_key = "lhs_enable:$enable_name";
                    
                    if (exists $context_to_substituted_ast{$context_key}) {
                        my $original_ast = $lhs_enable->{ast};
                        my $substituted_ast = $context_to_substituted_ast{$context_key};
                        
                        my $original_sv = eval { $self->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $self->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
                        
                        $lhs_enable->{ast} = $substituted_ast;
                        $updated_count++;
                        $lhs_ast_updates++;
                        
                        fsm_debug("  *** UPDATED LHS-level enable AST: $enable_name ***", 3);
                        fsm_debug("    Original:  $original_sv", 3);
                        fsm_debug("    Updated:   $substituted_sv", 3);
                    } else {
                        fsm_debug("  No substitution found for LHS enable: $enable_name", 3);
                    }
                }
            }
        }
    } else {
        fsm_debug("*** WARNING: No assignment_analysis structure to update! ***", 3);
    }
    
    # Update ASTs in lhs_assignments structure using context mapping
    fsm_debug("UPDATE_ORIGINAL_ASTS: Updating lhs_assignments structure", 3);
    
    for my $lhs (keys %{$self->{lhs_assignments} || {}}) {
        for my $assignment (@{$self->{lhs_assignments}{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                my $dt_name = $assignment->{dt};
                my $context_key = "assignment_condition:$lhs:$dt_name";
                
                if (exists $context_to_substituted_ast{$context_key}) {
                    my $original_ast = $assignment->{conditions_ast};
                    my $substituted_ast = $context_to_substituted_ast{$context_key};
                    
                    my $original_sv = eval { $self->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                    my $substituted_sv = eval { $self->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
                    
                    $assignment->{conditions_ast} = $substituted_ast;
                    $updated_count++;
                    $assignment_ast_updates++;
                    
                    fsm_debug("  *** UPDATED assignment condition AST: $lhs from $dt_name ***", 3);
                    fsm_debug("    Original:  $original_sv", 3);
                    fsm_debug("    Updated:   $substituted_sv", 3);
                } else {
                    fsm_debug("  No substitution found for assignment condition: $lhs from $assignment->{dt}", 3);
                }
            }
        }
    }
    
    fsm_debug("UPDATE_ORIGINAL_ASTS: Updated $updated_count AST expressions with substituted versions", 3);
    fsm_debug("  - DT-specific enable updates: $dt_ast_updates", 3);
    fsm_debug("  - LHS-level enable updates: $lhs_ast_updates", 3);
    fsm_debug("  - Assignment condition updates: $assignment_ast_updates", 3);
    
    if ($updated_count == 0) {
        fsm_debug("*** WARNING: NO AST UPDATES WERE PERFORMED! This suggests the substitution/update mechanism isn't working! ***", 3);
    }
    
    return $updated_count;
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
    # SECOND-PASS FACTORIZATION: Handle expressions created after initial substitution
    # This catches compound expressions like (idle_en && s_rst_n_and_apb_rq_and_apb_wrn_eq_const_1b0)
    # that were created during the first pass but didn't get factorized themselves
    
    fsm_debug("\n*** SECOND-PASS FACTORIZATION: Analyzing post-substitution expressions ***", 3);
    
    # Create a new factorizer for the second pass
    require FSM::HDL::ASTFactorization;
    my $second_pass_factorizer = FSM::HDL::ASTFactorization->new(
        min_usage_count => 2,
        debug => debug_enabled(),
        debug_level => 3
    );
    
    # Collect all current AST expressions (which now contain intermediate signals)
    my $second_pass_count = $self->feed_current_asts_to_second_pass($second_pass_factorizer);
    fsm_debug("Fed $second_pass_count expressions to second-pass factorizer", 3);
    
    if ($second_pass_count == 0) {
        fsm_debug("No expressions for second-pass - returning empty result", 3);
        return { intermediate_signals => {} };
    }
    
    # Perform second-pass analysis
    my $second_pass_result = $second_pass_factorizer->analyze_and_factorize();
    
    fsm_debug("Second-pass analysis results:", 3);
    fsm_debug("  Total expressions: $second_pass_result->{total_expressions}", 3);
    fsm_debug("  Unique structures: $second_pass_result->{unique_structures}", 3);
    fsm_debug("  Factorization candidates: $second_pass_result->{factorization_candidates}", 3);
    
    # Show the additional intermediate signals that were generated
    my $second_pass_signals = $second_pass_result->{intermediate_signals};
    if (%$second_pass_signals) {
        fsm_debug("Second-pass generated intermediate signals:", 3);
        for my $signal_name (sort keys %$second_pass_signals) {
            my $signal_info = $second_pass_signals->{$signal_name};
            my $sv = eval { $self->ast_to_systemverilog($signal_info->{ast}) } || "[NO SV REPRESENTATION]";
            fsm_debug("  $signal_name = $sv (usage: $signal_info->{usage_count})", 3);
        }
    } else {
        fsm_debug("No additional intermediate signals created in second pass", 3);
    }
    
    # Substitute the second-pass intermediate signals back into expressions
    if (%$second_pass_signals) {
        fsm_debug("\n*** SECOND-PASS SUBSTITUTION ***", 3);
        my $second_substitution_count = $second_pass_factorizer->substitute_expressions_with_intermediate_signals(
            $second_pass_factorizer->{ast_expressions}
        );
        fsm_debug("Second-pass substitution affected $second_substitution_count expressions", 3);
        
        # Update the original ASTs again with the second-pass substitutions
        my $second_update_count = $self->update_original_asts_with_second_pass_substitutions($second_pass_factorizer);
        fsm_debug("Updated $second_update_count original ASTs with second-pass substitutions", 3);
    }
    
    fsm_debug("*** SECOND-PASS FACTORIZATION COMPLETE ***\n", 3);
    
    return $second_pass_result;
}

sub feed_current_asts_to_second_pass ($self, $second_pass_factorizer) {
    # Feed the current state of all AST expressions to the second-pass factorizer
    # These expressions now contain intermediate signal references from the first pass
    
    fsm_debug("SECOND_PASS_FEED: Collecting current AST expressions", 3);
    
    my $total_fed = 0;
    
    # Feed from assignment_analysis (which should now contain substituted ASTs)
    if ($self->{assignment_analysis}) {
        for my $lhs (keys %{$self->{assignment_analysis}}) {
            my $lhs_analysis = $self->{assignment_analysis}{$lhs};
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
                
                # Feed DT-specific enable ASTs (now with intermediate signals)
                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast} && blessed($dt_enable->{enable_ast})) {
                        my $sv = eval { $self->ast_to_systemverilog($dt_enable->{enable_ast}) } || "[NO SV REPRESENTATION]";
                        
                        # Only feed if the expression contains intermediate signals (signs of substitution)
                        if ($self->ast_contains_intermediate_signals($dt_enable->{enable_ast})) {
                            $second_pass_factorizer->add_ast_expression(
                                $dt_enable->{enable_ast},
                                "second_pass_dt_enable:$dt_enable->{enable_name}"
                            );
                            $total_fed++;
                            fsm_debug("  Fed second-pass DT enable: $dt_enable->{enable_name}", 3);
                            fsm_debug("    Expression: $sv", 3);
                        }
                    }
                }
                
                # Feed LHS-level enable ASTs (now with intermediate signals)
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    if (blessed($lhs_enable->{ast})) {
                        my $sv = eval { $self->ast_to_systemverilog($lhs_enable->{ast}) } || "[NO SV REPRESENTATION]";
                        
                        # Only feed if the expression contains intermediate signals
                        if ($self->ast_contains_intermediate_signals($lhs_enable->{ast})) {
                            $second_pass_factorizer->add_ast_expression(
                                $lhs_enable->{ast},
                                "second_pass_lhs_enable:$lhs_enable->{name}"
                            );
                            $total_fed++;
                            fsm_debug("  Fed second-pass LHS enable: $lhs_enable->{name}", 3);
                            fsm_debug("    Expression: $sv", 3);
                        }
                    }
                }
            }
        }
    }
    
    # Feed from lhs_assignments (condition ASTs that may now have intermediate signals)
    for my $lhs (keys %{$self->{lhs_assignments} || {}}) {
        for my $assignment (@{$self->{lhs_assignments}{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                my $sv = eval { $self->ast_to_systemverilog($assignment->{conditions_ast}) } || "[NO SV REPRESENTATION]";
                
                # Only feed if the expression contains intermediate signals
                if ($self->ast_contains_intermediate_signals($assignment->{conditions_ast})) {
                    $second_pass_factorizer->add_ast_expression(
                        $assignment->{conditions_ast},
                        "second_pass_assignment:$lhs:$assignment->{dt}"
                    );
                    $total_fed++;
                    fsm_debug("  Fed second-pass assignment condition: $lhs from $assignment->{dt}", 3);
                    fsm_debug("    Expression: $sv", 3);
                }
            }
        }
    }
    
    fsm_debug("SECOND_PASS_FEED: Fed $total_fed expressions to second-pass factorizer", 3);
    return $total_fed;
}

sub ast_contains_intermediate_signals ($self, $ast) {
    # Check if an AST contains references to intermediate signals as part of COMPOUND expressions
    # CRITICAL RULE: Only compound expressions (with operators) should be considered for factorization!
    # Bare signal references should NEVER be factorized, even if they are intermediate signals.
    
    return 0 unless $ast && blessed($ast);
    
    # RULE 1: Bare signal references are NEVER factorizable, even if intermediate
    # This includes both regular signals and intermediate signals
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        # Bare signal reference - never factorize
        my $signal_name = $self->extract_signal_name_from_ast($ast) || 'unknown';
        my $ast_sv = eval { $self->ast_to_systemverilog($ast) } || 'unknown';
        fsm_debug("  SECOND_PASS_FILTER: Bare signal reference '$signal_name' (AST: $ast_sv) - NOT factorizable", 3);
        return 0;
    }
    
    # RULE 2: IntermediateSignalRef nodes are also bare signal references - never factorize
    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        # Bare intermediate signal reference - never factorize
        my $signal_name = $ast->{signal_name} || 'unknown';
        my $ast_sv = eval { $self->ast_to_clean_systemverilog($ast) } || 'unknown';
        fsm_debug("  SECOND_PASS_FILTER: Bare intermediate signal reference '$signal_name' (AST: $ast_sv) - NOT factorizable", 3);
        return 0;
    }
    
    # RULE 3: Only compound expressions (with operators) can contain intermediate signals worth factoring
    my $is_compound_with_intermediates = 0;
    
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # This is a compound expression with an operator - check if it contains intermediate signals
        my $left_has_intermediate = $ast->can('left') && $self->ast_has_intermediate_signals_recursive($ast->left);
        my $right_has_intermediate = $ast->can('right') && $self->ast_has_intermediate_signals_recursive($ast->right);
        
        if ($left_has_intermediate || $right_has_intermediate) {
            fsm_debug("  SECOND_PASS_FILTER: Compound binary expression contains intermediate signals - factorizable", 3);
            $is_compound_with_intermediates = 1;
        } else {
            fsm_debug("  SECOND_PASS_FILTER: Compound binary expression has no intermediate signals - not factorizable", 3);
        }
    }
    elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        # This is a compound expression with a unary operator - check if it contains intermediate signals
        my $operand_has_intermediate = $ast->can('operand') && $self->ast_has_intermediate_signals_recursive($ast->operand);
        
        if ($operand_has_intermediate) {
            fsm_debug("  SECOND_PASS_FILTER: Compound unary expression contains intermediate signals - factorizable", 3);
            $is_compound_with_intermediates = 1;
        } else {
            fsm_debug("  SECOND_PASS_FILTER: Compound unary expression has no intermediate signals - not factorizable", 3);
        }
    }
    else {
        # Not a compound expression (no operators) - not factorizable
        fsm_debug("  SECOND_PASS_FILTER: Not a compound expression - NOT factorizable", 3);
    }
    
    return $is_compound_with_intermediates;
}

sub ast_has_intermediate_signals_recursive ($self, $ast) {
    # Helper function to recursively check if an AST contains intermediate signals
    # This is used by ast_contains_intermediate_signals to identify compound expressions
    
    return 0 unless $ast && blessed($ast);
    
    # Check if this node itself is an intermediate signal reference
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $self->extract_signal_name_from_ast($ast);
        if ($signal_name && $self->is_intermediate_signal($signal_name)) {
            return 1;
        }
    }
    
    # Check for substituted node types from factorization
    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        return 1;
    }
    
    # Recursively check children
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        return 1 if $ast->can('left') && $self->ast_has_intermediate_signals_recursive($ast->left);
        return 1 if $ast->can('right') && $self->ast_has_intermediate_signals_recursive($ast->right);
    }
    elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        return 1 if $ast->can('operand') && $self->ast_has_intermediate_signals_recursive($ast->operand);
    }
    
    return 0;
}

sub update_original_asts_with_second_pass_substitutions ($self, $second_pass_factorizer) {
    # Update original AST expressions with second-pass substitutions
    # This is similar to the first-pass update but for the second round of substitutions
    
    fsm_debug("UPDATE_SECOND_PASS: Updating original ASTs with second-pass substitutions", 3);
    
    my $ast_expressions = $second_pass_factorizer->{ast_expressions};
    my $updated_count = 0;
    
    # Build context-to-AST mapping from second-pass results
    my %second_pass_context_to_ast;
    for my $expr_info (@$ast_expressions) {
        my $context = $expr_info->{context};
        my $substituted_ast = $expr_info->{ast};
        $second_pass_context_to_ast{$context} = $substituted_ast;
    }
    
    # Update assignment_analysis structure with second-pass substitutions
    if ($self->{assignment_analysis}) {
        for my $lhs (keys %{$self->{assignment_analysis}}) {
            my $lhs_analysis = $self->{assignment_analysis}{$lhs};
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
                
                # Update DT-specific enables
                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_name = $dt_enable_info->{enable_name};
                    my $context_key = "second_pass_dt_enable:$enable_name";
                    
                    if (exists $second_pass_context_to_ast{$context_key}) {
                        my $original_ast = $dt_enable_info->{enable_ast};
                        my $substituted_ast = $second_pass_context_to_ast{$context_key};
                        
                        my $original_sv = eval { $self->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $self->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
                        
                        $dt_enable_info->{enable_ast} = $substituted_ast;
                        $updated_count++;
                        
                        fsm_debug("  *** SECOND-PASS UPDATED DT-specific enable AST: $enable_name ***", 3);
                        fsm_debug("    Original:  $original_sv", 3);
                        fsm_debug("    Updated:   $substituted_sv", 3);
                    }
                }
                
                # Update LHS-level enables
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    my $enable_name = $lhs_enable->{name};
                    my $context_key = "second_pass_lhs_enable:$enable_name";
                    
                    if (exists $second_pass_context_to_ast{$context_key}) {
                        my $original_ast = $lhs_enable->{ast};
                        my $substituted_ast = $second_pass_context_to_ast{$context_key};
                        
                        my $original_sv = eval { $self->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $self->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
                        
                        $lhs_enable->{ast} = $substituted_ast;
                        $updated_count++;
                        
                        fsm_debug("  *** SECOND-PASS UPDATED LHS-level enable AST: $enable_name ***", 3);
                        fsm_debug("    Original:  $original_sv", 3);
                        fsm_debug("    Updated:   $substituted_sv", 3);
                    }
                }
            }
        }
    }
    
    # Update lhs_assignments structure
    for my $lhs (keys %{$self->{lhs_assignments} || {}}) {
        for my $assignment (@{$self->{lhs_assignments}{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                my $dt_name = $assignment->{dt};
                my $context_key = "second_pass_assignment:$lhs:$dt_name";
                
                if (exists $second_pass_context_to_ast{$context_key}) {
                    my $original_ast = $assignment->{conditions_ast};
                    my $substituted_ast = $second_pass_context_to_ast{$context_key};
                    
                    my $original_sv = eval { $self->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                    my $substituted_sv = eval { $self->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
                    
                    $assignment->{conditions_ast} = $substituted_ast;
                    $updated_count++;
                    
                    fsm_debug("  *** SECOND-PASS UPDATED assignment condition AST: $lhs from $dt_name ***", 3);
                    fsm_debug("    Original:  $original_sv", 3);
                    fsm_debug("    Updated:   $substituted_sv", 3);
                }
            }
        }
    }
    
    fsm_debug("UPDATE_SECOND_PASS: Updated $updated_count AST expressions with second-pass substitutions", 3);
    return $updated_count;
}

sub get_substituted_ast_for_signal ($self, $signal_name, $signal_info) {
    # Get the substituted AST for an intermediate signal from the factorizer results
    # This fixes the core issue where intermediate signal definitions use original ASTs
    # instead of substituted ASTs that reference other intermediate signals
    
    fsm_debug("GET_SUBSTITUTED_AST: Looking for substituted AST for signal '$signal_name'", 3);
    
    # CRITICAL FIX: Get the substituted AST directly from the factorizer's intermediate signals
    # After substitution, the factorizer stores the final substituted AST in its intermediate_signals structure
    if ($self->{ast_factorizer} && $self->{ast_factorizer}->{intermediate_signals}) {
        my $factorizer_signal_info = $self->{ast_factorizer}->{intermediate_signals}->{$signal_name};
        
        if ($factorizer_signal_info && $factorizer_signal_info->{ast}) {
            my $substituted_ast = $factorizer_signal_info->{ast};
            my $substituted_sv = eval { $self->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
            
            fsm_debug("  FOUND substituted AST from factorizer: '$substituted_sv'", 3);
            return $substituted_ast;
        } else {
            fsm_debug("  Signal '$signal_name' not found in factorizer intermediate signals", 3);
        }
    } else {
        fsm_debug("  WARNING: No AST factorizer results available", 3);
    }
    
    # If no substituted version found, return nil to indicate original should be used
    return undef;
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
    # Extract all intermediate signal names referenced in a SystemVerilog expression
    # This is used to track which intermediate signals are actually referenced
    
    my @intermediate_signals;
    
    fsm_debug("EXTRACT_INTERMEDIATES: Analyzing expression '$expression'", 3);
    
    # Extract all signal-like identifiers from the expression
    my @potential_signals = ($expression =~ /\b([a-zA-Z_][a-zA-Z0-9_]+)\b/g);
    
    # Check each potential signal to see if it's an intermediate signal
    my %seen;
    for my $signal_name (@potential_signals) {
        next if $seen{$signal_name}++;  # Skip duplicates
        
        # Skip SystemVerilog keywords and built-in functions
        next if $signal_name =~ /^(wire|reg|logic|always|assign|if|else|case|begin|end|posedge|negedge|clk|rst|reset)$/;
        
        # CRITICAL FIX: Check ALL available intermediate signal registries
        # This ensures we find intermediate signals from all sources:
        # 1. AST factorization results
        # 2. Global expressions registry  
        # 3. FSMGenFull parsing intermediate signals
        # 4. Pre-scan referenced signals
        
        my $is_intermediate = 0;
        
        # Check method 1: AST factorizer intermediate signals
        if ($self->{ast_factorizer} && $self->{ast_factorizer}->{intermediate_signals}) {
            if (exists $self->{ast_factorizer}->{intermediate_signals}->{$signal_name}) {
                $is_intermediate = 1;
                fsm_debug("  FOUND intermediate signal (AST factorizer): $signal_name", 3);
            }
        }
        
        # Check method 2: Global expressions registry
        if (!$is_intermediate) {
            for my $expr (keys %{$self->{global_expressions} || {}}) {
                if ($self->{global_expressions}->{$expr} eq $signal_name) {
                    $is_intermediate = 1;
                    fsm_debug("  FOUND intermediate signal (global expressions): $signal_name", 3);
                    last;
                }
            }
        }
        
        # Check method 3: FSMGenFull parsing intermediate signals
        if (!$is_intermediate && $self->{fsm_module} && $self->{fsm_module}->can('signals') && $self->{fsm_module}->signals) {
            my $fsm_signals = $self->{fsm_module}->signals;
            if (exists $fsm_signals->{$signal_name}) {
                my $signal = $fsm_signals->{$signal_name};
                if ($signal) {
                    # Check for is_intermediate attribute
                    my $has_intermediate_attr = 0;
                    if (blessed($signal) && $signal->can('attributes') && $signal->attributes) {
                        $has_intermediate_attr = $signal->attributes->{is_intermediate} || 0;
                    } elsif (blessed($signal) && $signal->can('get_attribute')) {
                        $has_intermediate_attr = $signal->get_attribute('is_intermediate') || 0;
                    } elsif (ref($signal) eq 'HASH' && exists $signal->{is_intermediate}) {
                        $has_intermediate_attr = $signal->{is_intermediate} || 0;
                    }
                    
                    if ($has_intermediate_attr) {
                        $is_intermediate = 1;
                        fsm_debug("  FOUND intermediate signal (FSMGenFull): $signal_name", 3);
                    }
                }
            }
        }
        
        # Check method 4: Pre-scan referenced signals
        if (!$is_intermediate && $self->{referenced_intermediate_signals}) {
            if (exists $self->{referenced_intermediate_signals}->{$signal_name}) {
                $is_intermediate = 1;
                fsm_debug("  FOUND intermediate signal (pre-scan): $signal_name", 3);
            }
        }
        
        # Add to result if found to be intermediate
        if ($is_intermediate) {
            push @intermediate_signals, $signal_name;
        } else {
            fsm_debug("  NOT intermediate: $signal_name", 3);
        }
    }
    
    my $count = scalar(@intermediate_signals);
    fsm_debug("EXTRACT_INTERMEDIATES: Found $count intermediate signals in expression", 3);
    
    return @intermediate_signals;
}

sub is_signal_referenced_in_substitutions ($self, $signal_name) {
    # REFERENCE-AWARE FILTERING: Check if a signal is actually referenced in substituted expressions
    # This is the critical fix for the intermediate signal bug where signals are referenced but not declared
    
    fsm_debug("REFERENCE_CHECK: Checking if '$signal_name' is referenced in substitutions", 3);
    
    # Check if we have AST factorizer results available
    if ($self->{ast_factorizer} && $self->{ast_factorizer}->{ast_expressions}) {
        my $ast_expressions = $self->{ast_factorizer}->{ast_expressions};
        fsm_debug("  Checking " . scalar(@$ast_expressions) . " factorized expressions");
        
        # Check each factorized (substituted) expression for references to this signal
        for my $expr_info (@$ast_expressions) {
            my $ast = $expr_info->{ast};
            my $context = $expr_info->{context};
            
            # Check if this AST contains a reference to our signal
            if ($ast && blessed($ast) && $self->ast_contains_signal($ast, $signal_name)) {
                fsm_debug("  REFERENCE FOUND: Signal '$signal_name' is referenced in context '$context'", 3);
                return 1;
            }
        }
    } else {
        fsm_debug("  WARNING: No AST factorizer results available for reference checking", 3);
    }
    
    # Also check in current assignment_analysis structures (post-substitution)
    if ($self->{assignment_analysis}) {
        for my $lhs (keys %{$self->{assignment_analysis}}) {
            my $lhs_analysis = $self->{assignment_analysis}->{$lhs};
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
                
                # Check DT-specific enable expressions
                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_ast = $dt_enable_info->{enable_ast};
                    if ($enable_ast && blessed($enable_ast) && $self->ast_contains_signal($enable_ast, $signal_name)) {
                        fsm_debug("  REFERENCE FOUND: Signal '$signal_name' in DT enable '$dt_enable_info->{enable_name}'", 3);
                        return 1;
                    }
                }
                
                # Check LHS-level enable expressions
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                    my $lhs_enable_ast = $rhs_group->{lhs_level_enable}->{ast};
                    if ($lhs_enable_ast && blessed($lhs_enable_ast) && $self->ast_contains_signal($lhs_enable_ast, $signal_name)) {
                        fsm_debug("  REFERENCE FOUND: Signal '$signal_name' in LHS enable '$rhs_group->{lhs_level_enable}->{name}'", 3);
                        return 1;
                    }
                }
            }
        }
    }
    
    # Check in lhs_assignments condition ASTs (post-substitution)
    for my $lhs (keys %{$self->{lhs_assignments} || {}}) {
        for my $assignment (@{$self->{lhs_assignments}->{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                if ($self->ast_contains_signal($assignment->{conditions_ast}, $signal_name)) {
                    fsm_debug("  REFERENCE FOUND: Signal '$signal_name' in assignment condition for LHS '$lhs'", 3);
                    return 1;
                }
            }
        }
    }
    
    fsm_debug("  REFERENCE NOT FOUND: Signal '$signal_name' is not referenced in any substituted expressions", 3);
    return 0;
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
    
    fsm_debug("TOPO_SORT: Starting topological sort of intermediate signals", 3);
    fsm_debug("TOPO_SORT: Input signals: " . scalar(keys %$filtered_signals), 3);
    fsm_debug("TOPO_SORT: Dependencies: " . scalar(keys %$signal_dependencies), 3);
    
    # Initialize tracking structures
    my @sorted_signals;
    my %visited;           # Permanent mark (already processed)
    my %temp_visited;      # Temporary mark (currently being processed)
    my %in_degree;         # Count of dependencies for each signal
    
    # Calculate in-degrees for all signals
    for my $signal (keys %$filtered_signals) {
        $in_degree{$signal} = 0;
    }
    
    for my $signal (keys %$signal_dependencies) {
        my $deps = $signal_dependencies->{$signal};
        for my $dep (@$deps) {
            if (exists $filtered_signals->{$dep}) {
                $in_degree{$signal}++;
            }
        }
    }
    
    # Debug initial in-degrees
    fsm_debug("TOPO_SORT: Initial in-degrees:", 3);
    for my $signal (sort keys %in_degree) {
        fsm_debug("  $signal: $in_degree{$signal} dependencies", 3);
    }
    
    # Kahn's algorithm: start with signals that have no dependencies
    my @queue = grep { $in_degree{$_} == 0 } keys %$filtered_signals;
    
    fsm_debug("TOPO_SORT: Starting with " . scalar(@queue) . " signals with no dependencies: " . join(", ", @queue), 3);
    
    while (@queue) {
        my $current = shift @queue;
        push @sorted_signals, $current;
        $visited{$current} = 1;
        
        fsm_debug("  Processing signal: $current", 3);
        
        # Find signals that depend on the current signal
        for my $signal (keys %$signal_dependencies) {
            next if $visited{$signal};
            
            my $deps = $signal_dependencies->{$signal};
            if (grep { $_ eq $current } @$deps) {
                $in_degree{$signal}--;
                fsm_debug("    Reduced in-degree of $signal to $in_degree{$signal}", 3);
                
                if ($in_degree{$signal} == 0) {
                    push @queue, $signal;
                    fsm_debug("    Added $signal to queue (all dependencies satisfied)", 3);
                }
            }
        }
    }
    
    # Check for circular dependencies
    my @remaining_signals = grep { !$visited{$_} } keys %$filtered_signals;
    if (@remaining_signals) {
        fsm_debug("TOPO_SORT: WARNING - Potential circular dependencies detected:", 3);
        for my $signal (@remaining_signals) {
            fsm_debug("  $signal (in-degree: $in_degree{$signal})", 3);
            # Add remaining signals to the end in alphabetical order as fallback
            push @sorted_signals, $signal;
        }
    }
    
    fsm_debug("TOPO_SORT: Final sorted order: " . join(", ", @sorted_signals), 3);
    fsm_debug("TOPO_SORT: Topological sort complete", 3);
    
    return @sorted_signals;
}

1;
