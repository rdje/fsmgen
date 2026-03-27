package FSM::HDL::FlattenedDT::Orchestrator;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use Scalar::Util qw(blessed);

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[FlattenedDT::Orchestrator.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}
sub reset_generation_state ($self) {
    my $ctx = $self->{flattened_dt};

    # Clear per-run generation state so one generator instance can be reused safely.
    $ctx->{state_enables} = {};
    $ctx->{dt_enables} = {};
    $ctx->{lhs_assignments} = {};
    $ctx->{intermediate_signals} = {};
    $ctx->{all_lhs} = {};
    $ctx->{lhs_ast_map} = {};
    $ctx->{reset_assignments} = {};
    $ctx->{global_expressions} = {};
    $ctx->{expression_usage} = {};
    $ctx->{assignment_analysis} = {};
    $ctx->{referenced_intermediate_signals} = {};
    $ctx->{declared_port_signals} = {};
    $ctx->{port_directions} = {};

    delete $ctx->{binary_logical_op_counts};
    delete $ctx->{ast_factorizer};
    delete $ctx->{fsm_module};
}
sub flatten_all_decision_trees ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("Flattening all decision trees", 3);
    $ctx->{enable_graph}->initialize_state_and_dt_enable_conditions($fsm_module);
    
    # Process regular states
    for my $state (@{$fsm_module->states}) {
        next unless $state->can('is_regular_state') ? $state->is_regular_state : $state->name !~ /^-/;

        fsm_debug("Flattening state: " . $state->name, 3);

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
        next if $state->can('is_regular_state') ? $state->is_regular_state : $state->name !~ /^-/;

        fsm_debug("Flattening standalone DT: " . $state->name, 3);

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
    $ctx->{enable_graph}->build_unified_assignment_analysis($fsm_module);
}
sub flatten_decision_tree ($self, $dt_name, $dt_node, $condition_stack) {
    my $ctx = $self->{flattened_dt};
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
                my $condition_ast = $ctx->{enable_graph}->convert_condition_to_ast($branch->{condition});
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
            my $test_condition_ast = $ctx->{enable_graph}->build_test_condition_ast(
                $dt_node->test_signal,
                $branch->{value},
            );
            
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
        my $assignment_target_name = $ctx->{enable_graph}->extract_signal_name_from_ast($dt_node->target) // 'unknown_lhs';
        fsm_debug("  Assignment: " . $assignment_target_name . " <- " . ref($dt_node->source), 3);
        
        # Record this assignment with current condition stack (now AST nodes)
        $ctx->{enable_graph}->capture_assignment_from_ast($dt_name, $dt_node, $condition_stack);
        
    } elsif ($dt_node->isa('FSM::CoreAST::StateTransition')) {
        fsm_debug("  Transition: -> " . $dt_node->target_state, 3);
        
        # Treat state transition as special assignment to next_state
        $ctx->{enable_graph}->capture_transition_from_ast($dt_name, $dt_node, $condition_stack);
        
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

sub generate_systemverilog ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("Starting flattened DT SystemVerilog generation for " . $fsm_module->name, 3);
    fsm_debug("\n*** PIPELINE TIMING DEBUG: HDL Generation Pipeline Start ***", 3);

    $self->reset_generation_state();
    
    # Step 0: Store FSM module reference for proper signal and reset value analysis
    $ctx->{enable_graph}->set_fsm_module_reference($fsm_module);
    fsm_debug("Step 0 - FSM module reference stored", 3);
    
    # Step 1: Analyze and flatten all decision trees
    $self->flatten_all_decision_trees($fsm_module);
    fsm_debug("Step 1 - Decision trees flattened", 3);
    
    # Step 2: Generate SystemVerilog with enable-based methodology
    my $hdl = $ctx->{backend_sv_scaffold}->generate_header($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_module_declaration($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_state_encoding($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_state_register($fsm_module);
    $hdl .= $ctx->{backend_sv_internal_decl}->generate_internal_signal_declarations($fsm_module);
    fsm_debug("Step 2 - Basic HDL structure generated", 3);
    
    # Step 3: Generate enable conditions FIRST (this will track intermediate signal requirements)
    $hdl .= $ctx->{enable_graph}->generate_enable_conditions($fsm_module);
    fsm_debug("Step 3 - Enable conditions generated", 3);
    
    # TIMING FIX: Count logical operations BEFORE any intermediate signal creation!
    fsm_debug("\n*** TIMING FIX: Running logical operation counting BEFORE pre-scan ***", 3);
    $ctx->{enable_graph_factorization_support}->count_binary_logical_operation_occurrences();
    fsm_debug("Step 4 - Logical operation counting completed (BEFORE pre-scan!)", 3);
    
    # Step 5: PRE-SCAN all WEN/EN expressions to identify needed intermediate signals (now with counts available)
    $ctx->{enable_graph}->prescan_wen_en_for_intermediate_signals();
    fsm_debug("Step 5 - PRE-SCAN completed (AFTER logical operation counting!)", 3);
    
    # Step 6: Generate consolidated intermediate signals (combining AST factorization + pre-scan)
    $hdl .= $ctx->{backend_sv_consolidated_intermediate}->generate_consolidated_intermediate_signals($fsm_module);
    fsm_debug("Step 6 - Consolidated intermediate signals generated", 3);
    
    # Step 7: Generate WEN/EN signals (using pre-declared intermediate signals)
    $hdl .= $ctx->{enable_graph}->generate_unified_wen_en_signals($fsm_module);
    fsm_debug("Step 7 - WEN/EN signals generated", 3);
    
    $hdl .= $ctx->{enable_graph}->generate_signal_assignments($fsm_module);
    $hdl .= "endmodule\n";
    fsm_debug("*** PIPELINE TIMING DEBUG: HDL Generation Pipeline Complete ***\n", 3);
    
    return $hdl;
}

1;
