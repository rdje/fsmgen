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
        next if $state->name =~ /^-/; # Skip standalone DTs for now
        
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
        next unless $state->name =~ /^-/; # Only standalone DTs
        
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
            # Create AST node for test condition: signal == value
            my $signal_ast = FSM::AST::Utils::signal_ref($dt_node->test_signal->name);
            my $value_ast = $ctx->{enable_graph}->convert_test_value_to_ast($branch->{value});
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
sub record_assignment_from_ast ($self, $dt_name, $assignment_node, $condition_stack) {
    my $ctx = $self->{flattened_dt};

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
    my $condition_ast = $ctx->{enable_graph}->create_condition_expression($condition_stack);
    
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
        die "[FlattenedDT::Orchestrator.pm][record_assignment_from_ast()] Missing or invalid operator_symbol for assignment node '$node_type' (resolved='$operator', intent='$intent_operator', pulse_cycles='$pulse_cycles')";
    }
    
    fsm_debug("  SEMANTIC ASSIGNMENT RESULT:", 3);
    fsm_debug("    LHS AST Node: " . ref($lhs_signal_ast), 3);
    fsm_debug("    LHS Name: " . $lhs_name, 3);
    fsm_debug("    RHS: $actual_rhs", 3);
    fsm_debug("    Operator: $operator", 3);
    fsm_debug("    Condition AST: " . (blessed($condition_ast) ? ref($condition_ast) : 'NOT_BLESSED'), 3);
    my $condition_signal_name = defined($condition_ast) ? $condition_ast->to_systemverilog() : 'UNDEFINED';
    fsm_debug("    Condition Signal Name: '$condition_signal_name'", 3);
    
    $ctx->{enable_graph}->register_assignment_capture(
        dt => $dt_name,
        lhs_name_key => $lhs_name,
        lhs_ast => $lhs_signal_ast,
        conditions_ast => $condition_ast,
        rhs => $actual_rhs,
        operator => $operator,
        assignment_intent => $assignment_intent,
        source_provenance => ($assignment_node->can('source_provenance') ? $assignment_node->source_provenance : {}),
        output_exposure => ($assignment_node->can('output_exposure') ? $assignment_node->output_exposure : 'auto'),
    );
    
    fsm_debug("*** PHASE1 ASSIGNMENT NODE COMPLETE (AST WEB) ***\n", 3);
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
sub record_transition_from_ast ($self, $dt_name, $transition_node, $condition_stack) {
    my $ctx = $self->{flattened_dt};
    my $target_state = $transition_node->target_state;
    
    # Create condition expression as pure AST
    my $condition_ast = $ctx->{enable_graph}->create_condition_expression($condition_stack);
    
    my $state_value = $ctx->{enable_graph}->register_transition_capture(
        dt => $dt_name,
        target_state => $target_state,
        conditions_ast => $condition_ast,
    );
    
    my $condition_signal_name = defined($condition_ast) ? $condition_ast->to_systemverilog() : 'UNDEFINED';
    fsm_debug("    Recorded AST transition: next_state <= $state_value when (signal: '$condition_signal_name')", 3);
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
    my $hdl = $ctx->{backend_sv}->generate_header($fsm_module);
    $hdl .= $ctx->{backend_sv}->generate_module_declaration($fsm_module);
    $hdl .= $ctx->{backend_sv}->generate_state_encoding($fsm_module);
    $hdl .= $ctx->{backend_sv}->generate_state_register($fsm_module);
    $hdl .= $ctx->{backend_sv}->generate_internal_signal_declarations($fsm_module);
    fsm_debug("Step 2 - Basic HDL structure generated", 3);
    
    # Step 3: Generate enable conditions FIRST (this will track intermediate signal requirements)
    $hdl .= $ctx->{backend_sv}->generate_enable_conditions($fsm_module);
    fsm_debug("Step 3 - Enable conditions generated", 3);
    
    # TIMING FIX: Count logical operations BEFORE any intermediate signal creation!
    fsm_debug("\n*** TIMING FIX: Running logical operation counting BEFORE pre-scan ***", 3);
    $ctx->{backend_sv}->count_binary_logical_operation_occurrences();
    fsm_debug("Step 4 - Logical operation counting completed (BEFORE pre-scan!)", 3);
    
    # Step 5: PRE-SCAN all WEN/EN expressions to identify needed intermediate signals (now with counts available)
    $ctx->{backend_sv}->prescan_wen_en_for_intermediate_signals();
    fsm_debug("Step 5 - PRE-SCAN completed (AFTER logical operation counting!)", 3);
    
    # Step 6: Generate consolidated intermediate signals (combining AST factorization + pre-scan)
    $hdl .= $ctx->{backend_sv}->generate_consolidated_intermediate_signals($fsm_module);
    fsm_debug("Step 6 - Consolidated intermediate signals generated", 3);
    
    # Step 7: Generate WEN/EN signals (using pre-declared intermediate signals)
    $hdl .= $ctx->{backend_sv}->generate_wen_en_signals($fsm_module);
    fsm_debug("Step 7 - WEN/EN signals generated", 3);
    
    $hdl .= $ctx->{enable_graph}->generate_signal_assignments($fsm_module);
    $hdl .= "endmodule\n";
    fsm_debug("*** PIPELINE TIMING DEBUG: HDL Generation Pipeline Complete ***\n", 3);
    
    return $hdl;
}

1;
