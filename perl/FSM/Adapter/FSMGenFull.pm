package FSM::Adapter::FSMGenFull;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use Data::Dumper;
use FSM::CoreAST;
use FSM::Debug;

# Full FSMGen Adapter - Complete implementation for FSMGen Lisp format
# Handles all FSMGen constructs: <-, ->, ++, --, <signal, <!signal, ?signal, etc.

sub new($class, %args) {
    return bless {
        debug => $args{debug} // 0,
        signal_registry => {},  # Track all signals and their properties
        current_state => undef,
        fsm_module => undef,
        # Symbol tables for constants, enums, defines, and params
        constants => {},        # +constants: name -> literal_value
        enums => {},           # +enums: enum_name -> {member -> value}
        defines => {},         # +define: name -> value_expression
        params => {},          # +params: name -> parameter_value
    }, $class;
}

# Main entry point - parse FSM from Lispish output
sub parse_fsm($self, $raw_ast) {
    fsm_debug("Starting full FSMGen parsing", 3);
    
    # Expect format: [['?fsm:name', [fsm_contents...]]]
    if (ref($raw_ast) eq 'ARRAY' && @$raw_ast > 0 && 
        ref($raw_ast->[0]) eq 'ARRAY' && $raw_ast->[0][0] =~ /^\?fsm:/) {
        return $self->parse_fsm_module($raw_ast->[0]);
    } else {
        die "Expected FSM structure starting with '?fsm:name'";
    }
}

sub parse_fsm_module($self, $fsm_ast) {
    my ($fsm_header, $fsm_contents) = @$fsm_ast;
    
    # Extract FSM name
    my ($module_name) = $fsm_header =~ /\?fsm:(\w+)/;
    fsm_debug("Parsing FSM module: $module_name", 3);
    
    # Create FSM module
    my $module = FSM::CoreAST::FSMModule->new(name => $module_name);
    $self->{fsm_module} = $module;
    
    # Parse each element in the FSM
    for my $element (@$fsm_contents) {
        next unless ref($element) eq 'ARRAY';
        my $element_name = $element->[0];
        
        if ($element_name eq '+constants') {
            # Constants section: ['+constants', [['NAME', 'value'], ...]]
            fsm_debug("Parsing constants section", 3);
            $self->parse_constants_section($element);
            
        } elsif ($element_name eq '+enums') {
            # Enums section: ['+enums', [['enum_name', [['MEMBER', [value]], ...]], ...]]
            fsm_debug("Parsing enums section", 3);
            $self->parse_enums_section($element);
            
        } elsif ($element_name eq '+define') {
            # Define directive: ['+define', ['NAME', 'value']]
            fsm_debug("Parsing define directive", 3);
            $self->parse_define_directive($element);
            
        } elsif ($element_name eq '+params') {
            # Params section: ['+params', [['NAME', [value]], ...]]
            fsm_debug("Parsing params section", 3);
            $self->parse_params_section($element);
            
        } elsif ($element_name =~ /^-/) {
            # Standalone decision tree
            fsm_debug("Parsing standalone DT: $element_name", 3);
            my $state = $self->parse_fsm_element($element);
            $module->add_state($state);
            
        } elsif ($element_name =~ /^[a-zA-Z]/) {
            # Regular state
            fsm_debug("Parsing state: $element_name", 3);
            my $state = $self->parse_fsm_element($element);
            $module->add_state($state);
            
        } else {
            fsm_debug("Skipping unknown element: $element_name", 3);
        }
    }
    
    fsm_debug("Completed parsing FSM with " . scalar(@{$module->states}) . " states/DTs", 3);
    
    # PHASE 2: Analyze signal roles and generate FSM interface
    $self->analyze_signal_roles();
    $self->generate_fsm_interface();
    
    return $module;
}

sub parse_fsm_element($self, $element_ast) {
    my ($element_name, $element_contents) = @$element_ast;
    
    fsm_debug("Parsing element: $element_name", 3);
    $self->{current_state} = $element_name;
    
    # Create state object
    my $state = FSM::CoreAST::State->new(name => $element_name);
    my $dt = FSM::CoreAST::DecisionTree->new(name => "${element_name}_dt");
    
    # Parse condition blocks within this element (same for both states and standalone DTs)
    for my $condition_block (@$element_contents) {
        if (ref($condition_block) eq 'ARRAY' && @$condition_block >= 2) {
            my ($first, $second) = @$condition_block;
            
            # Check if this is a 3-element assignment with embedded condition: [signal, ['<-', value, condition]]
            if (ref($second) eq 'ARRAY' && @$second == 3 && $second->[0] eq '<-') {
                fsm_debug("  Detected top-level 3-element assignment: $first <- " . $second->[1] . " when " . $second->[2], 3);
                
                # Extract the embedded condition and create direct conditional assignment
                my ($operator, $value, $embedded_condition) = @$second;
                my $assignment_action = [$first, [$operator, $value]];
                my $embedded_condition_expr = $self->parse_condition($embedded_condition);
                
                if ($embedded_condition_expr) {
                    my $parsed_assignment = $self->parse_action($assignment_action);
                    
                    if ($parsed_assignment) {
                        # Create conditional branch using only the embedded condition
                        my $conditional_assignment = FSM::CoreAST::ConditionalBranch->new(
                            condition => $embedded_condition_expr,
                            branches => [{
                                condition => $embedded_condition_expr,
                                actions => [$parsed_assignment]
                            }]
                        );
                        $dt->add_element($conditional_assignment);
                    }
                }
            # Check if this is a 4-element assignment with embedded (op ...) condition: [signal, ['=', value, '<', condition]]
            } elsif (ref($second) eq 'ARRAY' && @$second == 4 && $second->[2] eq '<' && ref($second->[3]) eq 'ARRAY') {
                fsm_debug("  Detected top-level 4-element assignment: $first " . $second->[0] . " " . $second->[1] . " <(nested_expr)", 3);
                
                # Extract the embedded condition and create direct conditional assignment
                my ($operator, $value, $condition_marker, $complex_condition) = @$second;
                my $assignment_action = [$first, [$operator, $value]];
                my $embedded_condition_expr = $self->parse_condition($complex_condition);
                
                if ($embedded_condition_expr) {
                    my $parsed_assignment = $self->parse_action($assignment_action);
                    
                    if ($parsed_assignment) {
                        # Create conditional branch using only the embedded condition (NOT the signal name!)
                        my $conditional_assignment = FSM::CoreAST::ConditionalBranch->new(
                            condition => $embedded_condition_expr,
                            branches => [{
                                condition => $embedded_condition_expr,
                                actions => [$parsed_assignment]
                            }]
                        );
                        $dt->add_element($conditional_assignment);
                    }
                }
            } else {
                # Regular condition-action pair
                my $parsed_branch = $self->parse_condition_block($condition_block);
                $dt->add_element($parsed_branch) if $parsed_branch;
            }
        }
    }
    
    $state->add_decision_tree($dt);
    return $state;
}

sub parse_condition_block($self, $condition_block) {
    my ($condition, $actions) = @$condition_block;
    
    fsm_debug("  Parsing condition block: $condition", 3);
    
    # Parse the condition expression
    my $condition_expr = $self->parse_condition($condition);
    
    # Parse the actions within this condition block
    my @parsed_actions;
    if (ref($actions) eq 'ARRAY') {
        # Check if this is a 3-element assignment with embedded condition: ['<-', value, condition]
        if (@$actions == 3 && $actions->[0] eq '<-') {
            fsm_debug("    Detected 3-element assignment with embedded condition", 3);
            # This is a 3-element assignment, but the condition is embedded in the assignment
            # We need to create a conditional assignment using the embedded condition
            my ($operator, $value, $embedded_condition) = @$actions;
            
            # Create a 2-element assignment for the action
            # Note: $condition from the outer structure is the signal name in this case
            my $assignment_action = [$condition, [$operator, $value]];
            
            # Parse the embedded condition
            my $embedded_condition_expr = $self->parse_condition($embedded_condition);
            
            if ($embedded_condition_expr) {
                # Parse the assignment
                my $parsed_assignment = $self->parse_action($assignment_action);
                
                if ($parsed_assignment) {
                    # Wrap the assignment in a conditional branch using the embedded condition
                    my $conditional_assignment = FSM::CoreAST::ConditionalBranch->new(
                        condition => $embedded_condition_expr,
                        branches => [{
                            condition => $embedded_condition_expr,
                            actions => [$parsed_assignment]
                        }]
                    );
                    push @parsed_actions, $conditional_assignment;
                }
            }
        } elsif (@$actions == 4 && $actions->[2] eq '<' && ref($actions->[3]) eq 'ARRAY') {
            fsm_debug("    Detected 4-element assignment with complex embedded condition", 3);
            # Pattern: [operator, value, '<', [complex_expression]]
            # Example: ['=', '1', '<', ['|', ['bcdown_is_null', 'nxpack_stall', 'right_full']]]
            my ($operator, $value, $condition_marker, $complex_condition) = @$actions;
            
            # Create assignment action: [signal, [operator, value]]
            my $assignment_action = [$condition, [$operator, $value]];
            
            # Parse the complex embedded condition
            my $embedded_condition_expr = $self->parse_condition($complex_condition);
            
            if ($embedded_condition_expr) {
                # Parse the assignment
                my $parsed_assignment = $self->parse_action($assignment_action);
                
                if ($parsed_assignment) {
                    # Wrap the assignment in a conditional branch using the embedded condition
                    my $conditional_assignment = FSM::CoreAST::ConditionalBranch->new(
                        condition => $embedded_condition_expr,
                        branches => [{
                            condition => $embedded_condition_expr,
                            actions => [$parsed_assignment]
                        }]
                    );
                    push @parsed_actions, $conditional_assignment;
                }
            }
        } else {
            # Regular array of actions
            for my $action (@$actions) {
                my $parsed_action = $self->parse_action($action);
                push @parsed_actions, $parsed_action if $parsed_action;
            }
        }
    } else {
        # Single action (shouldn't happen in lte_dif_pmaster format, but handle it)
        my $parsed_action = $self->parse_action($actions);
        push @parsed_actions, $parsed_action if $parsed_action;
    }
    
    # Create conditional branch
    if ($condition_expr && @parsed_actions) {
        return FSM::CoreAST::ConditionalBranch->new(
            condition => $condition_expr,
            branches => [{
                condition => $condition_expr,
                actions => \@parsed_actions
            }]
        );
    }
    
    return undef;
}

sub parse_condition($self, $condition_str) {
    fsm_debug("    Parsing condition: $condition_str", 3);
    
    # Handle different condition types - ORDER MATTERS!
    # Check more specific patterns first
    if ($condition_str =~ /^<!([a-zA-Z_]\w*)$/) {
        # Negated signal condition: <!signal_name
        my $signal_name = $1;
        my $signal = $self->register_signal($signal_name);
        my $signal_ref = FSM::CoreAST::SignalRef->new($signal);
        return FSM::CoreAST::UnaryOp->new(
            operator => '!',
            operand => $signal_ref
        );
        
    } elsif ($condition_str =~ /^<([a-zA-Z_]\w*)$/) {
        # Positive signal condition: <signal_name
        my $signal_name = $1;
        my $signal = $self->register_signal($signal_name);
        return FSM::CoreAST::SignalRef->new($signal);
        
    } elsif ($condition_str =~ /^[a-zA-Z_]\w*$/) {
        # Simple signal name (used in conditions like apb_rvalid)
        my $signal = $self->register_signal($condition_str);
        return FSM::CoreAST::SignalRef->new($signal);
        
    } else {
        # Check if this is a complex condition with nested AST
        # This handles cases where condition_str is actually an array ref like ['|', ['signal1', 'signal2']]
        return $self->parse_complex_condition($condition_str);
    }
}

sub parse_complex_condition($self, $condition) {
    fsm_debug("    Parsing complex condition: " . (ref($condition) ? "ARRAY[" . scalar(@$condition) . "]" : $condition), 3);
    
    # Handle cases where the condition is actually an array ref (nested AST)
    if (ref($condition) eq 'ARRAY') {
        # Check if this is a recursive expression that should use the new framework
        if ($self->is_recursive_expression($condition)) {
            fsm_debug("      Using recursive expression framework for complex condition", 3);
            return $self->parse_recursive_expression($condition);
        } else {
            # Fall back to nested logical expression parsing
            return $self->parse_nested_logical_expression($condition);
        }
    } else {
        # Handle complex string patterns like <stream_type!=2'0 or <stream_type=2'1
        if ($condition =~ /^<([a-zA-Z_]\w*)([!=<>=]+)(.+)$/) {
            my ($signal_name, $operator, $value) = ($1, $2, $3);
            fsm_debug("      Detected comparison condition: $signal_name $operator $value", 3);
            
            # Create signal reference
            my $signal = $self->register_signal($signal_name);
            my $signal_ref = FSM::CoreAST::SignalRef->new($signal);
            
            # Parse the value (could be literal, signal, etc.)
            my $value_expr = $self->parse_scalar_expression($value);
            
            # Create comparison operation
            if ($value_expr) {
                # Width propagation: if value has width, propagate to signal
                if ($value_expr->can('width') && $value_expr->width && $value_expr->width > 1) {
                    fsm_debug("      COMPARISON_WIDTH_PROPAGATION: Literal has width " . $value_expr->width . ", propagating to signal '$signal_name'", 3);
                    # Update signal with inferred width
                    $self->register_signal($signal_name, width => $value_expr->width);
                    # Re-create signal reference with updated width
                    $signal = $self->register_signal($signal_name);
                    $signal_ref = FSM::CoreAST::SignalRef->new($signal);
                }
                
                return FSM::CoreAST::BinaryOp->new(
                    $operator, $signal_ref, $value_expr
                );
            }
        } elsif ($condition =~ /^<!([a-zA-Z_]\w*)([!=<>=]+)(.+)$/) {
            my ($signal_name, $operator, $value) = ($1, $2, $3);
            fsm_debug("      Detected negated comparison condition: !($signal_name $operator $value)", 3);
            
            # Create signal reference
            my $signal = $self->register_signal($signal_name);
            my $signal_ref = FSM::CoreAST::SignalRef->new($signal);
            
            # Parse the value (could be literal, signal, etc.)
            my $value_expr = $self->parse_scalar_expression($value);
            
            # Create negated comparison operation
            if ($value_expr) {
                my $comparison = FSM::CoreAST::BinaryOp->new(
                    $operator, $signal_ref, $value_expr
                );
                
                return FSM::CoreAST::UnaryOp->new(
                    operator => '!',
                    operand => $comparison
                );
            }
        }
        
        # Not an array - fall back to treating as unknown string condition
        fsm_debug("    Unknown string condition format: $condition", 3);
        return undef;
    }
}

sub parse_nested_logical_expression($self, $expr_array) {
    return undef unless ref($expr_array) eq 'ARRAY' && @$expr_array > 0;
    
    my ($operator, @operands) = @$expr_array;
    
    fsm_debug("      Parsing nested expression: $operator with " . scalar(@operands) . " operands", 3);
    
    # Check if this is a known logical/arithmetic operator
    if ($self->is_logical_operator($operator)) {
        return $self->parse_logical_operation($operator, \@operands);
    } elsif ($self->is_comparison_operator($operator)) {
        return $self->parse_comparison_operation($operator, \@operands);
    } elsif ($self->is_arithmetic_operator($operator)) {
        return $self->parse_arithmetic_operation($operator, \@operands);
    } else {
        fsm_debug("        Unknown nested expression operator: $operator", 3);
        return undef;
    }
}

sub is_logical_operator($self, $op) {
    # Support all logical operators from the CoreAST registry plus some common variants
    my %logical_ops = (
        '|' => 1, 'or' => 1,           # Bitwise OR
        '&' => 1, 'and' => 1,          # Bitwise AND
        '||' => 1,                     # Logical OR
        '&&' => 1,                     # Logical AND
        '^' => 1, 'xor' => 1,          # XOR
        '!' => 1, 'not' => 1,          # NOT
        'nand' => 1, 'nor' => 1, 'xnor' => 1  # Other logical ops
    );
    return exists $logical_ops{$op};
}

sub is_comparison_operator($self, $op) {
    my %comp_ops = (
        '==' => 1, 'eq' => 1, '=' => 1,
        '!=' => 1, 'ne' => 1,
        '<' => 1, 'lt' => 1,
        '>' => 1, 'gt' => 1,
        '<=' => 1, 'le' => 1,
        '>=' => 1, 'ge' => 1
    );
    return exists $comp_ops{$op};
}

sub is_arithmetic_operator($self, $op) {
    my %arith_ops = (
        '+' => 1, 'add' => 1,
        '-' => 1, 'sub' => 1,
        '*' => 1, 'mul' => 1,
        '/' => 1, 'div' => 1,
        '%' => 1, 'mod' => 1
    );
    return exists $arith_ops{$op};
}

# Check if an array represents a recursive (op ...) expression
sub is_recursive_expression($self, $expr_array) {
    return undef unless ref($expr_array) eq 'ARRAY' && @$expr_array >= 2;
    
    my ($operator, @operands) = @$expr_array;
    
    # Check if the first element is a known operator
    return ($self->is_logical_operator($operator) || 
            $self->is_arithmetic_operator($operator) ||
            ($self->is_comparison_operator($operator) && $operator ne '<'))  # Skip < for now due to ambiguity
            && @operands > 0;  # Must have operands
}

# Parse recursive (op ...) expressions into intermediate signals
sub parse_recursive_expression($self, $expr_array) {
    my ($operator, @operands) = @$expr_array;
    
    fsm_debug("      Processing recursive expression: $operator with " . scalar(@operands) . " operands", 3);
    
    # DEBUG: Show the raw AST structure being processed
    fsm_debug("      RAW_AST_EXPRESSION: " . Dumper($expr_array), 3);
    
    # Handle the case where there's a single array operand containing multiple elements
    # Example: ['|', ['signal1', 'signal2', 'signal3']] should be treated as ['|', 'signal1', 'signal2', 'signal3']
    if (@operands == 1 && ref($operands[0]) eq 'ARRAY') {
        fsm_debug("        Detected single array operand - flattening: [" . join(', ', @{$operands[0]}) . "]", 3);
        @operands = @{$operands[0]};
    }
    
    # Parse all operands recursively - they can be signals, literals, or nested expressions
    my @parsed_operands;
    for my $operand (@operands) {
        my $parsed;
        if (ref($operand) eq 'ARRAY' && $self->is_recursive_expression($operand)) {
            # Nested recursive expression - process it first
            $parsed = $self->parse_recursive_expression($operand);
        } elsif (ref($operand) eq 'ARRAY') {
            # Other array type - use general expression parser
            $parsed = $self->parse_expression($operand);
        } else {
            # Scalar operand - signal name, literal, etc.
            $parsed = $self->parse_scalar_expression($operand);
        }
        
        push @parsed_operands, $parsed if $parsed;
    }
    
    return undef unless @parsed_operands;
    
    # Create AST node based on operator type
    my $ast_node;
    if ($self->is_logical_operator($operator)) {
        $ast_node = $self->build_logical_ast($operator, \@parsed_operands);
    } elsif ($self->is_arithmetic_operator($operator)) {
        $ast_node = $self->build_arithmetic_ast($operator, \@parsed_operands);
    } elsif ($self->is_comparison_operator($operator) && $operator ne '<') {
        $ast_node = $self->build_comparison_ast($operator, \@parsed_operands);
    }
    
    return undef unless $ast_node;
    
    # Generate intermediate signal for this expression
    fsm_debug("      GENERATING_INTERMEDIATE: Creating intermediate signal for $operator expression with " . scalar(@parsed_operands) . " operands", 3);
    return $self->generate_intermediate_signal($ast_node, $operator, \@parsed_operands);
}

# Build logical operation AST (AND, OR, XOR, NOT, etc.)
sub build_logical_ast($self, $operator, $operands) {
    if ($operator eq '!' || $operator eq 'not') {
        # Unary NOT operation
        if (@$operands == 1) {
            return FSM::CoreAST::UnaryOp->new(
                operator => '!',
                operand => $operands->[0]
            );
        } else {
            fsm_debug("          Warning: NOT operation should have exactly 1 operand, got " . scalar(@$operands), 3);
            return undef;
        }
    } else {
        # Binary/n-ary logical operation
        return $self->create_binary_operator_tree($operator, $operands);
    }
}

# Build arithmetic operation AST (+, -, *, /, %)
sub build_arithmetic_ast($self, $operator, $operands) {
    if ($operator eq '-' && @$operands == 1) {
        # Unary minus
        return FSM::CoreAST::UnaryOp->new(
            operator => '-',
            operand => $operands->[0]
        );
    } else {
        # Binary/n-ary arithmetic operation
        return $self->create_binary_operator_tree($operator, $operands);
    }
}

# Build comparison operation AST (==, !=, >, >=, <=)
sub build_comparison_ast($self, $operator, $operands) {
    # Comparison operations should have exactly 2 operands
    return undef unless @$operands == 2;
    
    # Normalize operator symbols
    my %op_map = (
        'eq' => '==', '=' => '==',
        'ne' => '!=',
        'gt' => '>',
        'le' => '<=',
        'ge' => '>='
    );
    
    my $normalized_op = $op_map{$operator} || $operator;
    
    return FSM::CoreAST::BinaryOp->new(
        $normalized_op, $operands->[0], $operands->[1]
    );
}

# Generate intermediate signal for complex expressions with factorization
sub generate_intermediate_signal($self, $ast_node, $operator, $operands) {
    # Create a canonical representation of this expression for factorization
    my $expr_signature = $self->create_expression_signature($operator, $operands);
    
    # Check if we've seen this exact expression before (factorization)
    if (exists $self->{expression_cache}{$expr_signature}) {
        my $existing_signal_name = $self->{expression_cache}{$expr_signature};
        fsm_debug("        FACTORIZATION: Reusing existing signal '$existing_signal_name' for expression", 3);
        
        # Return reference to existing intermediate signal - must preserve intermediate flag
        my $signal = $self->register_signal($existing_signal_name, 
            type => 'wire',
            is_intermediate => 1
        );
        return FSM::CoreAST::SignalRef->new($signal);
    }
    
    # Generate new intermediate signal name with systematic naming: <op>_<op_id>_<num_args>
    $self->{operator_counters} //= {};
    
    # Convert operators to valid SystemVerilog identifier names
    my %operator_to_name = (
        '|'   => 'or',
        '&'   => 'and', 
        '^'   => 'xor',
        '!'   => 'not',
        '||'  => 'lor',  # logical or
        '&&'  => 'land', # logical and
        '=='  => 'eq',
        '!='  => 'ne',
        '<'   => 'lt',
        '>'   => 'gt',
        '<='  => 'le',
        '>='  => 'ge',
        '+'   => 'add',
        '-'   => 'sub',
        '*'   => 'mul',
        '/'   => 'div',
        '%'   => 'mod'
    );
    
    my $op_name = $operator_to_name{$operator} || $operator;
    
    # Increment the global counter for this specific operator
    $self->{operator_counters}->{$operator} //= 0;
    my $op_id = ++$self->{operator_counters}->{$operator};
    
    # Count the number of operands
    my $num_args = scalar(@$operands);
    
    # Create systematic signal name: <op>_<op_id>_<num_args>
    my $signal_name = sprintf("%s_%d_%d", $op_name, $op_id, $num_args);
    
    fsm_debug("        SYSTEMATIC_NAMING: $operator -> '$signal_name' (op_id=$op_id, args=$num_args)", 3);
    
    # Create the intermediate signal WITH driving AST
    my $signal = $self->register_signal($signal_name,
        type => 'wire',
        is_intermediate => 1,
        driving_ast => $ast_node  # CRITICAL: Set the driving AST for the signal
    );
    
    # Store the AST expression for later HDL generation (for debugging/reference)
    $self->{intermediate_expressions}{$signal_name} = {
        ast => $ast_node,
        operator => $operator,
        operands => $operands,
        signature => $expr_signature
    };
    
    # Cache this expression for factorization
    $self->{expression_cache}{$expr_signature} = $signal_name;
    
    fsm_debug("        Created intermediate signal '$signal_name' with driving AST for $operator expression", 3);
    
    return FSM::CoreAST::SignalRef->new($signal);
}

# Create a canonical signature for expression factorization
sub create_expression_signature($self, $operator, $operands) {
    # Create a string representation that's identical for equivalent expressions
    my @operand_sigs = map {
        if (ref($_) eq 'FSM::CoreAST::SignalRef') {
            $_->signal->name;
        } elsif (ref($_) eq 'FSM::CoreAST::Literal') {
            $_->value;
        } else {
            "complex_" . ref($_);
        }
    } @$operands;
    
    # For commutative operators, sort operands to ensure same signature regardless of order
    if ($operator =~ /^[|&^+*]$/ || $operator =~ /^(or|and|xor|add|mul)$/) {
        @operand_sigs = sort @operand_sigs;
    }
    
    return join(":", $operator, @operand_sigs);
}

sub parse_logical_operation($self, $operator, $operands) {
    fsm_debug("        Parsing logical operation: $operator", 3);
    
    # Parse all operands recursively
    my @parsed_operands;
    for my $operand (@$operands) {
        my $parsed = $self->parse_logical_operand($operand);
        push @parsed_operands, $parsed if $parsed;
    }
    
    return undef unless @parsed_operands;
    
    if ($operator eq '!' || $operator eq 'not') {
        # Unary NOT operation - should have exactly one operand
        if (@parsed_operands == 1) {
            return FSM::CoreAST::UnaryOp->new(
                operator => '!',
                operand => $parsed_operands[0]
            );
        } else {
            fsm_debug("          Warning: NOT operation should have exactly 1 operand, got " . scalar(@parsed_operands), 3);
            return undef;
        }
    } else {
        # Binary/n-ary logical operation - combine operands into binary tree
        return $self->create_binary_operator_tree($operator, \@parsed_operands);
    }
}

sub parse_comparison_operation($self, $operator, $operands) {
    fsm_debug("        Parsing comparison operation: $operator", 3);
    
    # Comparison operations should have exactly 2 operands
    return undef unless @$operands == 2;
    
    my $left = $self->parse_logical_operand($operands->[0]);
    my $right = $self->parse_logical_operand($operands->[1]);
    
    return undef unless $left && $right;
    
    # Normalize operator symbols
    my %op_map = (
        'eq' => '==', '=' => '==',
        'ne' => '!=',
        'lt' => '<',
        'gt' => '>',
        'le' => '<=',
        'ge' => '>='
    );
    
    my $normalized_op = $op_map{$operator} || $operator;
    
    return FSM::CoreAST::BinaryOp->new(
        $normalized_op, $left, $right
    );
}

sub parse_arithmetic_operation($self, $operator, $operands) {
    fsm_debug("        Parsing arithmetic operation: $operator", 3);
    
    # Parse all operands recursively
    my @parsed_operands;
    for my $operand (@$operands) {
        my $parsed = $self->parse_logical_operand($operand);
        push @parsed_operands, $parsed if $parsed;
    }
    
    return undef unless @parsed_operands;
    
    if ($operator eq '-' && @parsed_operands == 1) {
        # Unary minus
        return FSM::CoreAST::UnaryOp->new(
            operator => '-',
            operand => $parsed_operands[0]
        );
    } else {
        # Binary/n-ary arithmetic operation
        return $self->create_binary_operator_tree($operator, \@parsed_operands);
    }
}

sub parse_logical_operand($self, $operand) {
    fsm_debug("          Parsing operand: " . (ref($operand) ? "ARRAY[" . scalar(@$operand) . "]" : $operand), 3);
    
    if (ref($operand) eq 'ARRAY') {
        # Recursive nested expression
        return $self->parse_nested_logical_expression($operand);
    } else {
        # Single operand - could be signal name or literal
        return $self->parse_condition_operand($operand);
    }
}

sub parse_condition_operand($self, $operand) {
    # Parse individual operands in logical expressions
    # This handles signal names and literals that appear in conditions
    
    if (!defined $operand) {
        return undef;
    }
    
    # DEBUG: Show the raw operand being processed
    fsm_debug("            RAW_OPERAND: " . Dumper($operand), 3);
    
    # Try parsing as a simple condition first (handles <signal, <!signal patterns)
    if ($operand =~ /^<!([a-zA-Z_]\w*)$/) {
        # Negated signal: <!signal_name
        my $signal_name = $1;
        my $signal = $self->register_signal($signal_name);
        my $signal_ref = FSM::CoreAST::SignalRef->new($signal);
        return FSM::CoreAST::UnaryOp->new(
            operator => '!',
            operand => $signal_ref
        );
    } elsif ($operand =~ /^<([a-zA-Z_]\w*)$/) {
        # Positive signal: <signal_name
        my $signal_name = $1;
        my $signal = $self->register_signal($signal_name);
        return FSM::CoreAST::SignalRef->new($signal);
    } elsif ($operand =~ /^[a-zA-Z_]\w*$/) {
        # Plain signal name
        fsm_debug("            OPERAND_PLAIN_SIGNAL: '$operand'", 3);
        my $signal = $self->register_signal($operand);
        return FSM::CoreAST::SignalRef->new($signal);
    } elsif ($operand =~ /^\d+$/) {
        # Simple numeric literal
        fsm_debug("            OPERAND_NUMERIC: '$operand' - no width info", 3);
        return FSM::CoreAST::Literal->new($operand);
    } elsif ($operand =~ /^(\d+)'([bdhBDH])([0-9a-fA-F_]+)$/) {
        # Verilog-style literals: 8'h42, 4'b1010, etc.
        my ($width, $radix_char, $value) = ($1, lc($2), $3);
        $value =~ s/_//g;  # Remove underscores
        
        my %radix_map = ('b' => 'binary', 'd' => 'decimal', 'h' => 'hex');
        my $radix = $radix_map{$radix_char} // 'decimal';
        
        fsm_debug("            OPERAND_VERILOG_LITERAL: '$operand' -> width=$width, radix=$radix, value='$value'", 3);
        return FSM::CoreAST::Literal->new($value, width => $width, radix => $radix);
    } else {
        fsm_debug("            Warning: Unknown operand format: $operand", 3);
        # Try to treat as signal name anyway
        my $signal = $self->register_signal($operand);
        return FSM::CoreAST::SignalRef->new($signal);
    }
}

sub create_binary_operator_tree($self, $operator, $operands) {
    # Create a left-associative binary tree from n-ary operators
    # For example: (| a b c) becomes ((a | b) | c)
    
    return undef unless @$operands;
    
    if (@$operands == 1) {
        return $operands->[0];
    }
    
    # Normalize operator symbols
    my %op_map = (
        'and' => '&', 'or' => '|', 'xor' => '^',
        'add' => '+', 'sub' => '-', 'mul' => '*', 'div' => '/', 'mod' => '%'
    );
    my $normalized_op = $op_map{$operator} || $operator;
    
    # Build left-associative tree: ((a op b) op c) op d...
    my $result = $operands->[0];
    for my $i (1 .. $#{$operands}) {
        $result = FSM::CoreAST::BinaryOp->new(
            $normalized_op, $result, $operands->[$i]
        );
    }
    
    return $result;
}

sub parse_action($self, $action) {
    return undef unless ref($action) eq 'ARRAY' && @$action >= 2;
    
    my ($action_target, $action_spec) = @$action;
    fsm_debug("      Parsing action: $action_target", 3);
    
    # Handle different action formats based on target and spec
    if ($action_target eq '->') {
        # State transition: ['->', [target_state]]
        return $self->parse_transition_new_format($action);
        
    } elsif ($action_target =~ /^\?/) {
        # Test node: ['?signal', [branches...]]
        return $self->parse_test_node_new_format($action);
        
    } elsif ($action_target =~ /^[<>]/) {
        # Nested condition (recursive): ['<condition', [nested_actions...]]
        return $self->parse_nested_condition_new_format($action);
        
    } elsif (ref($action_spec) eq 'ARRAY' && @$action_spec >= 2) {
        # Signal assignment: [signal_name, [operator, value]]
        return $self->parse_signal_action($action);
        
    } else {
        fsm_debug("        Unknown action format: $action_target -> " . ref($action_spec), 3);
        return undef;
    }
}

sub parse_assignment($self, $action) {
    # Format: [signal, '<-', value_expr]
    my (undef, $assign_op, $target, $source) = @$action;
    
    fsm_debug("        Assignment: $target <- $source", 3);
    
    # Parse target signal
    my $target_signal = $self->parse_signal_reference($target);
    
    # Parse source expression
    my $source_expr = $self->parse_expression($source);
    
    return FSM::CoreAST::RegisterAssignment->new(
        target => $target_signal,
        source => $source_expr,
        assignment_type => 'clocked'
    );
}

sub parse_transition($self, $action) {
    # Format: ['->', target_state]
    my (undef, $target_state) = @$action;
    
    fsm_debug("        Transition: -> $target_state", 3);
    
    return FSM::CoreAST::StateTransition->new(
        target_state => $target_state,
        transition_type => 'goto'
    );
}

sub parse_increment($self, $action) {
    # Format: ['++', signal]
    my (undef, $signal_name) = @$action;
    
    fsm_debug("        Increment: ++ $signal_name", 3);
    
    my $target_signal = $self->parse_signal_reference($signal_name);
    my $source_expr = FSM::CoreAST::BinaryOp->new(
        '+', FSM::CoreAST::SignalRef->new($target_signal->signal), FSM::CoreAST::Literal->new('1')
    );
    
    return FSM::CoreAST::RegisterAssignment->new(
        target => $target_signal,
        source => $source_expr,
        assignment_type => 'clocked'
    );
}

sub parse_decrement($self, $action) {
    # Format: ['--', signal]
    my (undef, $signal_name) = @$action;
    
    fsm_debug("        Decrement: -- $signal_name", 3);
    
    my $target_signal = $self->parse_signal_reference($signal_name);
    my $source_expr = FSM::CoreAST::BinaryOp->new(
        '-', FSM::CoreAST::SignalRef->new($target_signal->signal), FSM::CoreAST::Literal->new('1')
    );
    
    return FSM::CoreAST::RegisterAssignment->new(
        target => $target_signal,
        source => $source_expr,
        assignment_type => 'clocked'
    );
}

sub parse_combinational_assignment($self, $action) {
    # Format: [signal, '=', value_expr]
    my ($target, $assign_op, $source) = @$action;
    
    fsm_debug("        Combinational: $target = $source", 3);
    
    # Parse target signal
    my $target_signal = $self->parse_signal_reference($target);
    
    # Parse source expression
    my $source_expr = $self->parse_expression($source);
    
    return FSM::CoreAST::Assignment->new(
        target => $target_signal,
        source => $source_expr,
        assignment_type => 'combinational'
    );
}

sub parse_test_node($self, $action) {
    # Format: ['?signal', [branch1...], [branch2...], ...]
    my ($test_signal, @branches) = @$action;
    
    # Extract signal name from ?signal format
    my ($signal_name) = $test_signal =~ /^\?(.+)/;
    fsm_debug("        Test node: ?$signal_name", 3);
    
    my $signal = $self->register_signal($signal_name);
    my $test_node = FSM::CoreAST::TestNode->new(test_signal => $signal);
    
    # Parse test branches
    for my $branch (@branches) {
        if (ref($branch) eq 'ARRAY' && @$branch >= 2) {
            my ($test_value, @branch_actions) = @$branch;
            
            fsm_debug("          Test branch: $test_value", 3);
            
            my @parsed_actions;
            for my $branch_action (@branch_actions) {
                my $parsed_action = $self->parse_action($branch_action);
                push @parsed_actions, $parsed_action if $parsed_action;
            }
            
            $test_node->add_test_branch($test_value, \@parsed_actions);
        }
    }
    
    return $test_node;
}

sub parse_nested_condition($self, $action) {
    # Handle nested conditions like (<apb_rq ...)
    my ($condition, @nested_actions) = @$action;
    
    fsm_debug("        Nested condition: $condition", 3);
    
    my $condition_expr = $self->parse_condition($condition);
    
    my @parsed_actions;
    for my $nested_action (@nested_actions) {
        my $parsed_action = $self->parse_action($nested_action);
        push @parsed_actions, $parsed_action if $parsed_action;
    }
    
    if ($condition_expr && @parsed_actions) {
        return FSM::CoreAST::ConditionalBranch->new(
            condition => $condition_expr,
            branches => [{
                condition => $condition_expr,
                actions => \@parsed_actions
            }]
        );
    }
    
    return undef;
}

# New format parsing methods to handle actual FSMGen structure
sub parse_transition_new_format($self, $action) {
    # Format: ['->', [target_state]] or ['->', [target_state, condition]]
    my (undef, $target_spec) = @$action;
    
    # Debug: Show the full action structure
    fsm_debug("        TRANSITION_DEBUG: Full action array: [" . join(', ', map { ref($_) ? '[' . join(', ', @$_) . ']' : "'$_'" } @$action) . "]", 3);
    fsm_debug("        TRANSITION_DEBUG: target_spec type: " . ref($target_spec), 3);
    
    my $target_state;
    my $condition_suffix;
    
    if (ref($target_spec) eq 'ARRAY') {
        $target_state = $target_spec->[0];
        $condition_suffix = $target_spec->[1] if @$target_spec > 1;
        fsm_debug("        TRANSITION_DEBUG: target_state='$target_state', condition_suffix=" . ($condition_suffix // 'undef'), 3);
    } else {
        $target_state = $target_spec;
        fsm_debug("        TRANSITION_DEBUG: Simple target_state='$target_state'", 3);
    }
    
    fsm_debug("        Transition: -> $target_state" . ($condition_suffix ? " $condition_suffix" : ""), 3);
    
    # Create the basic state transition
    my $transition = FSM::CoreAST::StateTransition->new(
        target_state => $target_state,
        transition_type => 'goto'
    );
    
    # Check if there's a conditional suffix (like <pwrite or <!pwrite)
    if (defined $condition_suffix) {
        fsm_debug("          TRANSITION_DEBUG: Processing condition suffix: $condition_suffix", 3);
        
        # Parse the conditional suffix
        my $condition_expr = $self->parse_condition($condition_suffix);
        
        if ($condition_expr) {
            fsm_debug("          TRANSITION_DEBUG: Created conditional branch with condition: $condition_suffix", 3);
            # Wrap the transition in a conditional branch
            return FSM::CoreAST::ConditionalBranch->new(
                condition => $condition_expr,
                branches => [{
                    condition => $condition_expr,
                    actions => [$transition]
                }]
            );
        } else {
            fsm_debug("          TRANSITION_DEBUG: Failed to parse condition: $condition_suffix", 3);
        }
    } else {
        fsm_debug("          TRANSITION_DEBUG: No condition suffix found", 3);
    }
    
    # No condition suffix, return bare transition
    return $transition;
}

sub parse_test_node_new_format($self, $action) {
    # Format: ['?signal', [branches...]]
    my ($test_signal, $branches) = @$action;
    
    fsm_debug("        TEST_NODE_DEBUG: Full action structure", 3);
    fsm_debug("        TEST_NODE_DEBUG: test_signal = '$test_signal'", 3);
    fsm_debug("        TEST_NODE_DEBUG: branches type = " . ref($branches), 3);
    if (ref($branches) eq 'ARRAY') {
        fsm_debug("        TEST_NODE_DEBUG: branches count = " . scalar(@$branches), 3);
    }
    
    # Extract signal name from ?signal format
    my ($signal_name) = $test_signal =~ /^\?(.+)/;
    fsm_debug("        Test node: ?$signal_name", 3);
    
    my $signal = $self->register_signal($signal_name);
    my $test_node = FSM::CoreAST::TestNode->new(test_signal => $signal);
    
    # Parse test branches
    if (ref($branches) eq 'ARRAY') {
        for my $branch (@$branches) {
            if (ref($branch) eq 'ARRAY' && @$branch >= 2) {
                my ($test_value, @branch_actions) = @$branch;
                
                fsm_debug("          Test branch: $test_value", 3);
                
                my @parsed_actions;
                fsm_debug("          TEST_BRANCH_DEBUG: Branch '$test_value' has " . scalar(@branch_actions) . " actions", 3);
                for my $i (0 .. $#branch_actions) {
                    my $branch_action = $branch_actions[$i];
                    fsm_debug("            Branch action [$i]: " . (ref($branch_action) || 'SCALAR') . " = " . (ref($branch_action) ? $branch_action : $branch_action), 3);
                    if (ref($branch_action) eq 'ARRAY') {
                        fsm_debug("              Array contents: [" . join(', ', map { ref($_) ? ref($_) : "'$_'" } @$branch_action) . "]", 3);
                        
                        # Check if this is a nested array of assignments
                        if (@$branch_action > 0 && ref($branch_action->[0]) eq 'ARRAY') {
                            fsm_debug("              Detected nested assignment arrays - flattening", 3);
                            # This branch action contains multiple assignment arrays
                            for my $j (0 .. $#{$branch_action}) {
                                my $nested_assignment = $branch_action->[$j];
                                fsm_debug("                Nested assignment [$j]: [" . join(', ', map { ref($_) ? ref($_) : "'$_'" } @$nested_assignment) . "]", 3);
                                my $parsed_action = $self->parse_action($nested_assignment);
                                push @parsed_actions, $parsed_action if $parsed_action;
                            }
                        } else {
                            # Regular single assignment array
                            fsm_debug("              TEST_BRANCH_DEBUG: Parsing single assignment array", 3);
                            my $parsed_action = $self->parse_action($branch_action);
                            if ($parsed_action) {
                                fsm_debug("              TEST_BRANCH_DEBUG: Successfully parsed: " . ref($parsed_action), 3);
                                push @parsed_actions, $parsed_action;
                            } else {
                                fsm_debug("              TEST_BRANCH_DEBUG: Failed to parse action", 3);
                            }
                        }
                    } else {
                        # Scalar branch action
                        fsm_debug("              TEST_BRANCH_DEBUG: Processing scalar branch action: " . (defined $branch_action ? $branch_action : 'undef'), 3);
                        my $parsed_action = $self->parse_action($branch_action);
                        if ($parsed_action) {
                            fsm_debug("              TEST_BRANCH_DEBUG: Successfully parsed scalar action: " . ref($parsed_action), 3);
                            push @parsed_actions, $parsed_action;
                        } else {
                            fsm_debug("              TEST_BRANCH_DEBUG: Failed to parse scalar branch action", 3);
                        }
                    }
                }
                
                fsm_debug("          TEST_BRANCH_DEBUG: Adding branch '$test_value' with " . scalar(@parsed_actions) . " parsed actions", 3);
                $test_node->add_test_branch($test_value, \@parsed_actions);
            }
        }
    }
    
    return $test_node;
}

sub parse_nested_condition_new_format($self, $action) {
    # Handle nested conditions like ['<apb_rq', [nested_actions...]]
    my ($condition, $nested_actions) = @$action;
    
    fsm_debug("        Nested condition: $condition", 3);
    
    my $condition_expr = $self->parse_condition($condition);
    
    my @parsed_actions;
    if (ref($nested_actions) eq 'ARRAY') {
        for my $nested_action (@$nested_actions) {
            my $parsed_action = $self->parse_action($nested_action);
            push @parsed_actions, $parsed_action if $parsed_action;
        }
    }
    
    if ($condition_expr && @parsed_actions) {
        return FSM::CoreAST::ConditionalBranch->new(
            condition => $condition_expr,
            branches => [{
                condition => $condition_expr,
                actions => \@parsed_actions
            }]
        );
    }
    
    return undef;
}

sub parse_signal_action($self, $action) {
    # Format: [signal_name, [operator, value_expr]] or [signal_name, [operator, value_expr, condition]]
    my ($signal_name, $operation_spec) = @$action;
    
    return undef unless ref($operation_spec) eq 'ARRAY' && @$operation_spec >= 2;
    
    my ($operator, $value_expr, $condition_suffix, $condition_expr) = @$operation_spec;
    
    # Handle the case where condition is split across multiple elements:
    # ['=', '1', '<', ['|', ['signal1', 'signal2', ...]]]
    # Here $condition_suffix = '<' and $condition_expr = ['|', ...]
    my $full_condition;
    if ($condition_suffix && $condition_suffix eq '<' && ref($condition_expr) eq 'ARRAY') {
        # This is a complex condition: < followed by nested expression
        $full_condition = $condition_expr;
        fsm_debug("        Conditional signal action: $signal_name $operator $value_expr when <(nested_expr)", 3);
    } elsif ($condition_suffix) {
        # Simple string condition like <signal or <!signal
        $full_condition = $condition_suffix;
        fsm_debug("        Conditional signal action: $signal_name $operator $value_expr when $condition_suffix", 3);
    } else {
        fsm_debug("        Signal action: $signal_name $operator $value_expr", 3);
    }

    # Parse both LHS and RHS into AST nodes first to get all context
    my $target_expr = $self->parse_signal_reference($signal_name);
    my $source_expr = $self->parse_expression($value_expr);

    # Enhanced width inference with mismatch handling
    my ($lhs_width, $rhs_width, $final_width);
    my ($lhs_explicit, $rhs_explicit) = (0, 0);  # Track if widths are explicit vs inferred

    # --- 1. Get LHS Width (from annotation, slice, or subscript) ---
    if ($signal_name =~ /'(\d+)$/) {
        $lhs_width = $1;
        $lhs_explicit = 1;
        fsm_debug("          LHS width from annotation: $lhs_width (explicit)", 3);
    } elsif (ref($target_expr) eq 'FSM::CoreAST::SignalRef' && $target_expr->slice) {
        my ($high, $low) = @{$target_expr->slice};
        $lhs_width = abs($high - $low) + 1;
        $lhs_explicit = 1;
        fsm_debug("          LHS width from slice [$high:$low]: $lhs_width (explicit)", 3);
    } elsif (ref($target_expr) eq 'FSM::CoreAST::IndexedRef') {
        # Single bit subscript: foobar[m] - always 1-bit
        $lhs_width = 1;
        $lhs_explicit = 1;
        fsm_debug("          LHS width from subscript: 1-bit (explicit)", 3);
    } elsif (ref($target_expr) eq 'FSM::CoreAST::SignalRef' && $target_expr->signal && $target_expr->signal->width && $target_expr->signal->width > 1) {
        # Check if signal already has inferred width from previous assignments
        # Only treat as explicit if width > 1 (not default 1-bit)
        $lhs_width = $target_expr->signal->width;
        $lhs_explicit = 1;  # Previously inferred counts as explicit
        fsm_debug("          LHS width from signal registry: $lhs_width (previously inferred)", 3);
    }

    # --- 2. Get RHS Width (from expression, literal, slice, or subscript) ---
    if ($source_expr && $source_expr->can('width') && $source_expr->width) {
        $rhs_width = $source_expr->width;
        $rhs_explicit = 1;
        fsm_debug("          RHS width from expression: $rhs_width (explicit)", 3);
    } elsif (ref($source_expr) eq 'FSM::CoreAST::SignalRef' && $source_expr->slice) {
        my ($high, $low) = @{$source_expr->slice};
        $rhs_width = abs($high - $low) + 1;
        $rhs_explicit = 1;
        fsm_debug("          RHS width from slice: $rhs_width (explicit)", 3);
    } elsif (ref($source_expr) eq 'FSM::CoreAST::IndexedRef') {
        # Single bit subscript: foobar[m] - always 1-bit
        $rhs_width = 1;
        $rhs_explicit = 1;
        fsm_debug("          RHS width from subscript: 1-bit (explicit)", 3);
    } elsif (ref($source_expr) eq 'FSM::CoreAST::SignalRef' && $source_expr->signal && $source_expr->signal->width && $source_expr->signal->width > 1) {
        # Check if RHS signal already has inferred width
        # Only treat as explicit if width > 1 (not default 1-bit)
        $rhs_width = $source_expr->signal->width;
        $rhs_explicit = 1;  # Previously inferred counts as explicit
        fsm_debug("          RHS width from signal registry: $rhs_width (previously inferred)", 3);
    }

    # --- 3. Width Resolution Strategy ---
    if ($lhs_explicit && $rhs_explicit) {
        # Both sides have explicit/inferred widths - handle mismatches as errors
        if ($lhs_width != $rhs_width) {
            $self->handle_width_mismatch($lhs_width, $rhs_width, $signal_name, $value_expr, \$source_expr);
        } else {
            fsm_debug("          Widths are consistent: $lhs_width", 3);
        }
        $final_width = $lhs_width;  # LHS is always authoritative for assignment target
        
    } elsif ($lhs_explicit) {
        # Only LHS has width - propagate to RHS (normal inference)
        $final_width = $lhs_width;
        fsm_debug("          Propagating LHS width ($final_width) to RHS", 3);
        $self->propagate_width_to_expression($source_expr, $final_width);
        
    } elsif ($rhs_explicit) {
        # Only RHS has width - propagate to LHS (reverse inference)
        $final_width = $rhs_width;
        fsm_debug("          Propagating RHS width ($final_width) to LHS", 3);
        $self->propagate_width_to_expression($target_expr, $final_width);
        
    } else {
        # Neither side has width info - apply default inference (1-bit)
        $final_width = 1;
        fsm_debug("          DEFAULT INFERENCE: No width info on either side. Defaulting to 1-bit.", 3);
    }

    # If a final width was determined, update the base signal if it has no slice
    if ($final_width && ref($target_expr) eq 'FSM::CoreAST::SignalRef' && !$target_expr->slice) {
        my $signal = $target_expr->signal;
        if ($signal && (!$signal->width || $signal->width == 1) && $final_width > 1) {
            fsm_debug("          Updating base signal \"" . $signal->name . "\" width to $final_width", 3);
            $self->register_signal($signal->name, width => $final_width); # This updates registry
        }
    }
    
    # Re-fetch target signal in case it was updated
    $target_expr = $self->parse_signal_reference($signal_name); 

    # Create the basic assignment object
    my $assignment;
    if ($operator eq '<-') {
        # A <- B: flop output is 'A', mux input is 'next_A'
        $assignment = FSM::CoreAST::RegisterAssignment->new(
            target => $target_expr,
            source => $source_expr,
            assignment_type => 'clocked',
            register_style => 'output_named'  # A is the flop output, next_A is mux input
        );
    } elsif ($operator eq '<=') {
        # A <= B: mux output is 'A', flop output is 'A_q'  
        $assignment = FSM::CoreAST::RegisterAssignment->new(
            target => $target_expr,
            source => $source_expr,
            assignment_type => 'clocked',
            register_style => 'input_named'   # A is the mux output, A_q is flop output
        );
    } elsif ($operator eq '=') {
        $assignment = FSM::CoreAST::Assignment->new(
            target => $target_expr,
            source => $source_expr,
            assignment_type => 'combinational'
        );
    } else {
        fsm_debug("        Unknown signal operator: $operator", 3);
        return undef;
    }
    
    # Check if there's a conditional suffix - wrap in conditional branch if present
    if (defined $full_condition) {
        fsm_debug("          Processing full condition: " . (ref($full_condition) ? "complex" : $full_condition), 3);
        
        # Parse the full condition (could be simple string or complex array)
        my $condition_expr = $self->parse_condition($full_condition);
        
        if ($condition_expr) {
            fsm_debug("          Created conditional assignment with parsed condition", 3);
            # Wrap the assignment in a conditional branch
            return FSM::CoreAST::ConditionalBranch->new(
                condition => $condition_expr,
                branches => [{
                    condition => $condition_expr,
                    actions => [$assignment]
                }]
            );
        } else {
            fsm_debug("          Failed to parse full condition", 3);
        }
    }
    
    # No condition suffix or failed to parse condition, return bare assignment
    return $assignment;
}

sub parse_expression($self, $expr) {
    # Handle various expression types
    if (!ref($expr)) {
        # Scalar value - could be signal name, literal, or constant
        return $self->parse_scalar_expression($expr);
    } elsif (ref($expr) eq 'ARRAY') {
        # Check if this is a recursive (op ...) expression first
        if ($self->is_recursive_expression($expr)) {
            fsm_debug("          Detected recursive expression - processing with new framework", 3);
            return $self->parse_recursive_expression($expr);
        } else {
            # Fall back to old S-expression handling for compatibility
            return $self->parse_sexpr_expression($expr);
        }
    } else {
        fsm_debug("Unknown expression type: " . ref($expr), 3);
        return undef;
    }
}

sub parse_scalar_expression($self, $scalar) {
    fsm_debug("        PARSE_SCALAR: Processing scalar '$scalar'", 3);
    
    # DEBUG: Show the raw scalar being parsed
    fsm_debug("        RAW_SCALAR: " . Dumper($scalar), 3);
    
    # Handle different scalar types
    if ($scalar =~ /^(\d+)'([bdhBDH])([0-9a-fA-F_]+)$/) {
        # Verilog-style literals: 8'h42, 4'b1010, 16'd1000, etc.
        my ($width, $radix_char, $value) = ($1, lc($2), $3);
        $value =~ s/_//g;  # Remove underscores
        
        my %radix_map = ('b' => 'binary', 'd' => 'decimal', 'h' => 'hex');
        my $radix = $radix_map{$radix_char} // 'decimal';
        
        fsm_debug("        VERILOG_LITERAL_EXPLICIT: '$scalar' -> width=$width, radix=$radix, value='$value'", 3);
        return FSM::CoreAST::Literal->new($value, width => $width, radix => $radix);
        
    } elsif ($scalar =~ /^(\d+)'([0-9a-fA-F_]+)$/) {
        # Handle cases where radix is implied (default to decimal): 2'0, 2'1, etc.
        my ($width, $value) = ($1, $2);
        $value =~ s/_//g;  # Remove underscores
        
        fsm_debug("        VERILOG_LITERAL_IMPLIED: '$scalar' -> width=$width, radix=decimal, value='$value'", 3);
        return FSM::CoreAST::Literal->new($value, width => $width, radix => 'decimal');
        
    } elsif ($scalar =~ /^(\d+)$/) {
        # Simple decimal number
        return FSM::CoreAST::Literal->new($scalar);
        
    } elsif ($scalar =~ /^const_\d+b\d+$/) {
        # const_NbV format - treat as regular input signal, DO NOT infer width from name!
        # This is just a naming convention for external constants, not a width indicator
        fsm_debug("          CONST SIGNAL: '$scalar' - treating as regular input signal (no width inference from name)", 3);
        my $signal = $self->register_signal($scalar, 
            type => 'input'  # Mark as input to FSM
        );
        return FSM::CoreAST::SignalRef->new($signal);
        
    } elsif ($scalar =~ /^([a-zA-Z_]\w*)(\.[a-zA-Z_]\w*)?(\[[\d:]+\])?('(\d+))?(\>)?$/) {
        # Signal name with optional annotations, or symbol reference
        my ($base_name, $member_name, $slice, $width_annotation, $width, $output_marker) = ($1, $2, $3, $4, $5, $6);
        my $full_name = $member_name ? "$base_name$member_name" : $base_name;
        
        # First, try to resolve as a symbol (constant, define, enum member, param)
        my $resolved_symbol = $self->resolve_symbol($full_name);
        if ($resolved_symbol) {
            fsm_debug("          SYMBOL RESOLVED: '$full_name' -> literal/constant", 3);
            return $resolved_symbol;
        }
        
        # Not a symbol, treat as signal name with optional annotations
        my $signal_name = $base_name;  # Use base name for signal (no enum syntax in signal names)
        
        # DEBUG: Show width parsing
        if ($width) {
            fsm_debug("          WIDTH PARSING: '$scalar' -> signal='$signal_name', width='$width'", 3);
        }
        
        my $signal = $self->register_signal($signal_name, 
            width => $width,
            is_output => defined($output_marker)
        );
        
        if ($slice) {
            # Parse slice notation [high:low] or [index]
            if ($slice =~ /\[(\d+):(\d+)\]/) {
                return FSM::CoreAST::SignalRef->new($signal, slice => [$1, $2]);
            } elsif ($slice =~ /\[(\d+)\]/) {
                return FSM::CoreAST::IndexedRef->new(signal => $signal, index => FSM::CoreAST::Literal->new($1));
            }
        }
        
        return FSM::CoreAST::SignalRef->new($signal);
        
    } else {
        # Check for invalid signal names that start with ! or other operators
        if ($scalar =~ /^[!<>]/) {
            fsm_debug("          WARNING: Invalid signal name detected: $scalar", 3);
            fsm_debug("          This appears to be a condition expression, not a signal name.", 3);
            # Don't register this as a signal - return undef or a placeholder
            return undef;
        }
        
        # Unknown scalar - treat as signal name
        my $signal = $self->register_signal($scalar);
        return FSM::CoreAST::SignalRef->new($signal);
    }
}

sub parse_sexpr_expression($self, $sexpr) {
    my ($operator, @operands) = @$sexpr;
    
    fsm_debug("          S-expression: $operator with " . scalar(@operands) . " operands", 3);
    
    if ($operator eq '+' && @operands == 2) {
        # Binary addition
        return FSM::CoreAST::BinaryOp->new(
            '+', $self->parse_expression($operands[0]), $self->parse_expression($operands[1])
        );
    } elsif ($operator eq '-' && @operands == 2) {
        # Binary subtraction
        return FSM::CoreAST::BinaryOp->new(
            '-', $self->parse_expression($operands[0]), $self->parse_expression($operands[1])
        );
    } elsif ($operator eq '&' && @operands == 2) {
        # Bitwise AND
        return FSM::CoreAST::BinaryOp->new(
            '&', $self->parse_expression($operands[0]), $self->parse_expression($operands[1])
        );
    } elsif ($operator eq '|' && @operands == 2) {
        # Bitwise OR
        return FSM::CoreAST::BinaryOp->new(
            '|', $self->parse_expression($operands[0]), $self->parse_expression($operands[1])
        );
    } elsif ($operator eq '==' && @operands == 2) {
        # Equality comparison
        return FSM::CoreAST::BinaryOp->new(
            '==', $self->parse_expression($operands[0]), $self->parse_expression($operands[1])
        );
    } elsif ($operator eq '!' && @operands == 1) {
        # Logical NOT
        return FSM::CoreAST::UnaryOp->new(
            operator => '!',
            operand => $self->parse_expression($operands[0])
        );
    } else {
        fsm_debug("          Unknown S-expression operator: $operator", 3);
        return undef;
    }
}

sub parse_signal_reference($self, $signal_spec) {
    # Handle signal references with annotations
    if (!ref($signal_spec)) {
        return $self->parse_scalar_expression($signal_spec);
    } else {
        return $self->parse_expression($signal_spec);
    }
}

# PHASE 1: Signal Registry (Parsing) - No FSM module interaction
sub register_signal($self, $signal_name, %attributes) {
    # DEBUG: Track where invalid signal names are created
    if ($signal_name =~ /^[!<>]/) {
        fsm_debug("*** SIGNAL REGISTRY DEBUG: Invalid signal name '$signal_name' being registered!", 3);
        fsm_debug("*** Call stack trace:", 3);
        my $i = 1;
        while (my ($package, $filename, $line, $subroutine) = caller($i)) {
            fsm_debug("***   [$i] $subroutine at $filename:$line", 3);
            $i++;
            last if $i > 5;  # Limit stack trace depth
        }
    }
    
    # Track usage patterns for later analysis
    $self->{signal_usage}{$signal_name} //= {
        referenced_in_conditions => 0,
        assigned_to => 0,
        has_output_marker => 0,
        is_intermediate => 0,
        contexts => []  # Track where this signal was referenced
    };
    
    # Update usage flags based on attributes
    if ($attributes{is_intermediate}) {
        $self->{signal_usage}{$signal_name}{is_intermediate} = 1;
        fsm_debug("        USAGE: '$signal_name' marked as intermediate", 3);
    }
    if ($attributes{is_output}) {
        $self->{signal_usage}{$signal_name}{has_output_marker} = 1;
        fsm_debug("        USAGE: '$signal_name' marked with output marker", 3);
    }
    
    # Check if signal already exists in registry
    if (exists $self->{signal_registry}{$signal_name}) {
        my $existing = $self->{signal_registry}{$signal_name};
        fsm_debug("        SIGNAL EXISTS: '$signal_name' width=" . ($existing->width || 'undef'), 3);
        
        # Check if new attributes would override existing ones
        if (%attributes) {
            fsm_debug("        NEW ATTRIBUTES: " . Dumper(\%attributes), 3);
            
            # Update width if the new width is more specific (larger) than existing
            if (defined($attributes{width}) && $attributes{width} > ($existing->width || 1)) {
                fsm_debug("        UPDATING SIGNAL WIDTH: '$signal_name' from " . 
                    ($existing->width || 'undef') . " to $attributes{width}", 3);
                
                # Create new signal with updated attributes
                my %updated_attrs = (
                    name => $signal_name,
                    type => $existing->type,
                    width => $attributes{width},
                    %{$existing->{attributes} || {}},
                    %attributes
                );
                
                my $updated_signal = FSM::CoreAST::Signal->new(%updated_attrs);
                $self->{signal_registry}{$signal_name} = $updated_signal;
                
                return $updated_signal;
            }
        }
        
        return $existing;
    }
    
    # Create new signal in registry only (NO FSM module interaction)
    my %signal_attrs = (
        name => $signal_name,
        type => 'wire',  # Default type
        %attributes
    );
    
    fsm_debug("        REGISTER SIGNAL: '$signal_name' with attrs: " . Dumper(\%signal_attrs), 3);
    fsm_debug("        (Signal registry only - FSM interface will be generated later)", 3);
    
    my $signal = FSM::CoreAST::Signal->new(%signal_attrs);
    $self->{signal_registry}{$signal_name} = $signal;
    
    return $signal;
}

# DEPRECATED: Legacy method for backward compatibility during transition
# TODO: Remove this after all parsing code is updated to use register_signal
sub get_or_create_signal($self, $signal_name, %attributes) {
    fsm_debug("        WARNING: Using deprecated get_or_create_signal - should use register_signal during parsing", 2);
    return $self->register_signal($signal_name, %attributes);
}

# Constants, enums, defines, and params parsing methods
sub parse_constants_section($self, $constants_ast) {
    # Format: ['+constants', [['IDLE_VALUE', "4'b0000"], ['BUSY_VALUE', "4'b0001"], ...]]
    my (undef, $constants_list) = @$constants_ast;
    
    for my $constant_def (@$constants_list) {
        my ($name, $value) = @$constant_def;
        fsm_debug("  Defining constant: $name = $value", 3);
        
        # Parse the value as a literal expression
        my $literal_expr = $self->parse_scalar_expression($value);
        $self->{constants}{$name} = $literal_expr;
        fsm_debug("    Stored constant: $name -> " . ref($literal_expr), 3);
    }
}

sub parse_enums_section($self, $enums_ast) {
    # Format: ['+enums', [['state_codes', [['IDLE', [0]], ['ACTIVE', [1]], ...]], ...]]
    my (undef, $enums_list) = @$enums_ast;
    
    for my $enum_def (@$enums_list) {
        my ($enum_name, $members_list) = @$enum_def;
        fsm_debug("  Defining enum: $enum_name", 3);
        
        my %enum_values;
        for my $member_def (@$members_list) {
            my ($member_name, $member_value_array) = @$member_def;
            my $member_value = $member_value_array->[0];  # Extract from [value] array
            
            fsm_debug("    Enum member: $enum_name.$member_name = $member_value", 3);
            $enum_values{$member_name} = $member_value;
        }
        
        $self->{enums}{$enum_name} = \%enum_values;
        fsm_debug("    Stored enum: $enum_name with " . scalar(keys %enum_values) . " members", 3);
    }
}

sub parse_define_directive($self, $define_ast) {
    # Format: ['+define', ['MAX_COUNT', "8'd100"]]
    my (undef, $define_spec) = @$define_ast;
    my ($name, $value) = @$define_spec;
    
    fsm_debug("  Defining directive: $name = $value", 3);
    
    # Parse the value as an expression (could be literal, signal reference, etc.)
    my $value_expr = $self->parse_scalar_expression($value);
    $self->{defines}{$name} = $value_expr;
    fsm_debug("    Stored define: $name -> " . ref($value_expr), 3);
}

sub parse_params_section($self, $params_ast) {
    # Format: ['+params', [['DATA_WIDTH', [16]], ['ADDR_WIDTH', [8]], ...]]
    my (undef, $params_list) = @$params_ast;
    
    for my $param_def (@$params_list) {
        my ($name, $value_array) = @$param_def;
        my $value = $value_array->[0];  # Extract from [value] array
        
        fsm_debug("  Defining parameter: $name = $value", 3);
        
        # Store parameter value (typically numeric)
        $self->{params}{$name} = $value;
        fsm_debug("    Stored param: $name -> $value", 3);
    }
}

# Symbol resolution methods
sub resolve_symbol($self, $symbol_name) {
    # Check in order: constants, defines, enum members, params
    
    # 1. Check constants
    if (exists $self->{constants}{$symbol_name}) {
        fsm_debug("      RESOLVED: $symbol_name as constant", 3);
        return $self->{constants}{$symbol_name};
    }
    
    # 2. Check defines
    if (exists $self->{defines}{$symbol_name}) {
        fsm_debug("      RESOLVED: $symbol_name as define", 3);
        return $self->{defines}{$symbol_name};
    }
    
    # 3. Check enum members (format: enum_name.member_name)
    if ($symbol_name =~ /^([a-zA-Z_]\w*)\.([a-zA-Z_]\w*)$/) {
        my ($enum_name, $member_name) = ($1, $2);
        if (exists $self->{enums}{$enum_name} && exists $self->{enums}{$enum_name}{$member_name}) {
            my $value = $self->{enums}{$enum_name}{$member_name};
            fsm_debug("      RESOLVED: $symbol_name as enum member -> $value", 3);
            return FSM::CoreAST::Literal->new($value);
        }
    }
    
    # 4. Check params (used in expressions like {DATA_WIDTH}'b0)
    if (exists $self->{params}{$symbol_name}) {
        fsm_debug("      RESOLVED: $symbol_name as param -> $self->{params}{$symbol_name}", 3);
        return FSM::CoreAST::Literal->new($self->{params}{$symbol_name});
    }
    
    # Not found in symbol tables
    return undef;
}

# Width mismatch handling method
sub handle_width_mismatch($self, $lhs_width, $rhs_width, $signal_name, $value_expr, $source_expr_ref) {
    if ($lhs_width > $rhs_width) {
        # Case 1: LHS wider than RHS - Need to expand RHS (zero-extension for unsigned)
        my $expand_bits = $lhs_width - $rhs_width;
        
        fsm_debug("", 3);
        fsm_debug("*** WIDTH MISMATCH WARNING ***", 3);
        fsm_debug("Assignment: $signal_name <- $value_expr", 3);
        fsm_debug("LHS width: $lhs_width bits, RHS width: $rhs_width bits", 3);
        fsm_debug("Action: Expanding RHS by zero-extending with $expand_bits upper bits", 3);
        fsm_debug("Result: RHS[$rhs_width-1:0] -> {${expand_bits}'b0, RHS[$rhs_width-1:0]}", 3);
        fsm_debug("", 3);
        
        fsm_debug("          WIDTH EXPANSION: LHS($lhs_width) > RHS($rhs_width) - expanding RHS with $expand_bits zero bits", 3);
        
        # Create zero-extension expression: {expand_bits'b0, original_rhs}
        my $zero_literal = FSM::CoreAST::Literal->new('0', width => $expand_bits, radix => 'binary');
        my $expanded_rhs = FSM::CoreAST::Concatenation->new(
            $zero_literal, $$source_expr_ref
        );
        
        # Update the source expression reference
        $$source_expr_ref = $expanded_rhs;
        
    } elsif ($lhs_width < $rhs_width) {
        # Case 2: LHS narrower than RHS - Need to truncate RHS
        my $truncate_bits = $rhs_width - $lhs_width;
        
        fsm_debug("", 3);
        fsm_debug("!!! WIDTH MISMATCH - TRUNCATION WARNING !!!", 3);
        fsm_debug("Assignment: $signal_name <- $value_expr", 3);
        fsm_debug("LHS width: $lhs_width bits, RHS width: $rhs_width bits", 3);
        fsm_debug("Action: TRUNCATING RHS by discarding $truncate_bits upper bits", 3);
        fsm_debug("Result: RHS[$rhs_width-1:0] -> RHS[$lhs_width-1:0] (losing bits [$rhs_width-1:$lhs_width])", 3);
        fsm_debug("WARNING: This truncation may indicate a design error!", 3);
        fsm_debug("Please verify this is intentional behavior.", 3);
        fsm_debug("", 3);
        
        fsm_debug("          WIDTH TRUNCATION: LHS($lhs_width) < RHS($rhs_width) - truncating RHS by $truncate_bits bits", 3);
        
        # Create slice expression to truncate: rhs[lhs_width-1:0]
        my $high_bit = $lhs_width - 1;
        my $truncated_rhs;
        
        if (ref($$source_expr_ref) eq 'FSM::CoreAST::SignalRef') {
            # If RHS is a signal reference, create a sliced version
            my $signal = $$source_expr_ref->signal;
            $truncated_rhs = FSM::CoreAST::SignalRef->new($signal, slice => [$high_bit, 0]);
        } else {
            # For complex expressions, we need to handle truncation differently
            # For now, we'll create a warning and leave the expression as-is
            # This may need refinement based on specific use cases
            fsm_debug("WARNING: Cannot truncate complex expression - leaving as-is", 3);
            fsm_debug("Consider manually handling this width mismatch in the design", 3);
            $truncated_rhs = $$source_expr_ref;  # Leave unchanged for now
        }
        
        # Update the source expression reference
        $$source_expr_ref = $truncated_rhs;
    }
}

# Width propagation method
sub propagate_width_to_expression($self, $expr, $width) {
    return unless $expr && $width;
    
    fsm_debug("          Propagating width $width to expression: " . ref($expr), 3);
    
    if (ref($expr) eq 'FSM::CoreAST::SignalRef') {
        # Propagate width to signal reference
        my $signal = $expr->signal;
        if ($signal && (!$signal->width || $signal->width == 1) && $width > 1) {
            fsm_debug("            Propagating to signal: " . $signal->name, 3);
            # Update the signal with the new width
            my $updated_signal = $self->register_signal($signal->name, 
                width => $width,
                type => $signal->type,
                is_output => $signal->get_attribute('is_output')
            );
            # Update the reference
            $expr->{signal} = $updated_signal;
        }
    } elsif (ref($expr) eq 'FSM::CoreAST::BinaryOp') {
        # For binary operations, propagate to both operands
        $self->propagate_width_to_expression($expr->left, $width) if $expr->left;
        $self->propagate_width_to_expression($expr->right, $width) if $expr->right;
    } elsif (ref($expr) eq 'FSM::CoreAST::UnaryOp') {
        # For unary operations, propagate to operand
        $self->propagate_width_to_expression($expr->operand, $width) if $expr->operand;
    }
    # For literals, we don't need to propagate - they have their own width
}

# PHASE 2: Signal Role Analysis and FSM Interface Generation
sub analyze_signal_roles($self) {
    fsm_debug("\n=== PHASE 2: Analyzing Signal Roles ===", 3);
    
    # Initialize usage statistics if not already done
    $self->{signal_usage} //= {};
    
    # First pass: Examine all signal usages from the complete AST
    $self->_analyze_signal_usage_from_ast();
    
    # Second pass: Classify signals based on usage patterns
    for my $signal_name (keys %{$self->{signal_registry}}) {
        next if !exists $self->{signal_usage}{$signal_name};
        
        my $usage = $self->{signal_usage}{$signal_name};
        my $signal = $self->{signal_registry}{$signal_name};
        
        my $role = $self->_classify_signal_role($signal_name, $usage);
        $signal->set_attribute('signal_role', $role);
        
        my $contexts_str = join(',', @{$usage->{contexts} || []});
        fsm_debug("  Signal '$signal_name': $role (refs:$usage->{referenced_in_conditions}, assigns:$usage->{assigned_to}, output_marker:$usage->{has_output_marker}, intermediate:$usage->{is_intermediate}, contexts:[$contexts_str])", 3);
    }
}

sub _analyze_signal_usage_from_ast($self) {
    # Walk the complete FSM AST and track signal usage patterns
    fsm_debug("  Analyzing signal usage from complete AST...", 3);
    
    return unless $self->{fsm_module};
    
    # Count and report total states and decision trees for debugging
    my $state_count = scalar($self->{fsm_module}->states->@*);
    fsm_debug("  Found $state_count states in FSM module", 3);
    
    for my $state ($self->{fsm_module}->states->@*) {
        for my $dt ($state->decision_trees->@*) {
            $self->_analyze_decision_tree($dt);
        }
    }
}

sub _analyze_decision_tree($self, $dt) {
    my $elements = $dt->elements();
    if ($elements && ref($elements) eq 'ARRAY') {
        my $element_count = scalar(@$elements);
        fsm_debug("    DECISION TREE: Found $element_count elements", 3);
        
        for my $element (@$elements) {
            fsm_debug("      ANALYZING ELEMENT: Type = " . ref($element), 3);
            $self->_analyze_ast_element($element);
        }
    } else {
        fsm_debug("    DECISION TREE: No elements found (elements = " . (defined $elements ? ref($elements) || "scalar: $elements" : 'undef') . ")", 3);
    }
}

sub _analyze_ast_element($self, $element) {
    if ($element->isa('FSM::CoreAST::ConditionalBranch')) {
        # Analyze condition - signals here are referenced in conditions
        $self->_analyze_condition_references($element->condition);
        
        # Analyze actions in branches
        for my $branch ($element->branches->@*) {
            for my $action ($branch->{actions}->@*) {
                $self->_analyze_action_element($action);
            }
        }
    } elsif ($element->isa('FSM::CoreAST::TestNode')) {
        # Test signal is referenced in condition
        if ($element->test_signal) {
            my $signal_name = $element->test_signal->name;
            $self->{signal_usage}{$signal_name} //= { referenced_in_conditions => 0, assigned_to => 0, has_output_marker => 0, is_intermediate => 0, contexts => [] };
            $self->{signal_usage}{$signal_name}{referenced_in_conditions}++;
            push @{$self->{signal_usage}{$signal_name}{contexts}}, 'TEST_NODE';
            fsm_debug("    SIGNAL REFERENCE: '$signal_name' in context 'TEST_NODE' (total refs: $self->{signal_usage}{$signal_name}{referenced_in_conditions})", 3);
        }
        
        # Analyze branch actions
        fsm_debug("    TEST_NODE_ANALYSIS: Processing test branches for signal '" . $element->test_signal->name . "'", 3);
        my $branches = $element->test_branches;
        if ($branches && ref($branches) eq 'ARRAY') {
            for my $branch (@$branches) {
                fsm_debug("      TEST_BRANCH_ANALYSIS: Branch value '" . $branch->{value} . "' with " . scalar(@{$branch->{actions}}) . " actions", 3);
                for my $action (@{$branch->{actions}}) {
                    fsm_debug("        TEST_BRANCH_ACTION: Analyzing action type " . ref($action), 3);
                    $self->_analyze_action_element($action);
                }
            }
        } else {
            my $branches_info = defined $branches ? 
                (ref($branches) ? ref($branches) . ": " . Dumper($branches) : "scalar: $branches") : 
                'undef';
            fsm_debug("      TEST_NODE_ANALYSIS: No branches found for TestNode (branches = $branches_info)", 3);
        }
    } else {
        # Other element types
        $self->_analyze_action_element($element);
    }
}

sub _analyze_condition_references($self, $condition) {
    return unless $condition;
    
    if ($condition->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $condition->signal->name;
        $self->{signal_usage}{$signal_name} //= { referenced_in_conditions => 0, assigned_to => 0, has_output_marker => 0, is_intermediate => 0, contexts => [] };
        $self->{signal_usage}{$signal_name}{referenced_in_conditions}++;
        push @{$self->{signal_usage}{$signal_name}{contexts}}, 'CONDITION';
        fsm_debug("    SIGNAL REFERENCE: '$signal_name' in context 'CONDITION' (total refs: $self->{signal_usage}{$signal_name}{referenced_in_conditions})", 3);
    } elsif ($condition->isa('FSM::CoreAST::BinaryOp')) {
        $self->_analyze_condition_references($condition->left) if $condition->left;
        $self->_analyze_condition_references($condition->right) if $condition->right;
    } elsif ($condition->isa('FSM::CoreAST::UnaryOp')) {
        $self->_analyze_condition_references($condition->operand) if $condition->operand;
    }
}

sub _analyze_action_element($self, $action) {
    return unless $action;
    
    fsm_debug("    ACTION ELEMENT: Type = " . ref($action), 3);
    
    if ($action->isa('FSM::CoreAST::Assignment') || $action->isa('FSM::CoreAST::RegisterAssignment')) {
        # Signal is assigned to (LHS)
        if ($action->target && $action->target->isa('FSM::CoreAST::SignalRef')) {
            my $signal_name = $action->target->signal->name;
            $self->{signal_usage}{$signal_name} //= { referenced_in_conditions => 0, assigned_to => 0, has_output_marker => 0, is_intermediate => 0, contexts => [] };
            $self->{signal_usage}{$signal_name}{assigned_to}++;
            push @{$self->{signal_usage}{$signal_name}{contexts}}, 'LHS';
            fsm_debug("    SIGNAL ASSIGNMENT: '$signal_name' in context 'LHS' (total assigns: $self->{signal_usage}{$signal_name}{assigned_to})", 3);
        }
        
        # Analyze RHS for signal references
        if ($action->source) {
            fsm_debug("    ANALYZING RHS: Type = " . ref($action->source) . " from " . ref($action), 3);
            $self->_analyze_expression_references($action->source, 'RHS');
        } else {
            fsm_debug("    WARNING: Assignment has no source expression", 3);
        }
    } elsif ($action->isa('FSM::CoreAST::ConditionalBranch')) {
        # Recursive analysis
        $self->_analyze_ast_element($action);
    } elsif ($action->isa('FSM::CoreAST::TestNode')) {
        # Test signal is referenced in condition
        if ($action->test_signal) {
            my $signal_name = $action->test_signal->name;
            $self->{signal_usage}{$signal_name} //= { referenced_in_conditions => 0, assigned_to => 0, has_output_marker => 0, is_intermediate => 0, contexts => [] };
            $self->{signal_usage}{$signal_name}{referenced_in_conditions}++;
            push @{$self->{signal_usage}{$signal_name}{contexts}}, 'TEST_NODE';
            fsm_debug("    SIGNAL REFERENCE: '$signal_name' in context 'TEST_NODE' (total refs: $self->{signal_usage}{$signal_name}{referenced_in_conditions})", 3);
        }
        
        # Analyze branch actions
        fsm_debug("    TEST_NODE_ANALYSIS: Processing test branches for signal '" . $action->test_signal->name . "'", 3);
        my $branches = $action->test_branches;
        if ($branches && ref($branches) eq 'ARRAY') {
            for my $branch (@$branches) {
                fsm_debug("      TEST_BRANCH_ANALYSIS: Branch value '" . $branch->{value} . "' with " . scalar(@{$branch->{actions}}) . " actions", 3);
                for my $branch_action (@{$branch->{actions}}) {
                    fsm_debug("        TEST_BRANCH_ACTION: Analyzing action type " . ref($branch_action), 3);
                    $self->_analyze_action_element($branch_action);
                }
            }
        } else {
            my $branches_info = defined $branches ? 
                (ref($branches) ? ref($branches) . ": " . Dumper($branches) : "scalar: $branches") : 
                'undef';
            fsm_debug("      TEST_NODE_ANALYSIS: No branches found for action TestNode (branches = $branches_info)", 3);
        }
    } elsif ($action->isa('FSM::CoreAST::StateTransition')) {
        # State transitions don't reference signals directly, but log for completeness
        fsm_debug("    STATE TRANSITION: -> $action->{target_state}", 3);
    } else {
        # Unexpected action type - log it for debugging
        fsm_debug("    UNHANDLED ACTION TYPE: " . ref($action) . " - this might be causing missing signal analysis!", 3);
        fsm_debug("    Action details: " . (eval { $action->can('target') && $action->target ? "target=" . ref($action->target) : "no target" } || "unknown"), 3);
    }
}

sub _analyze_expression_references($self, $expr, $context = 'RHS') {
    return unless $expr;
    
    # Add detailed expression type logging
    fsm_debug("    EXPRESSION ANALYSIS: Type = " . ref($expr) . " in context '$context'", 3);
    
    if ($expr->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $expr->signal->name;
        $self->{signal_usage}{$signal_name} //= { referenced_in_conditions => 0, assigned_to => 0, has_output_marker => 0, is_intermediate => 0, contexts => [] };
        
        # Count as reference - signals used anywhere (RHS of assignments, conditions, expressions) should be considered referenced
        $self->{signal_usage}{$signal_name}{referenced_in_conditions}++;
        
        # Track context where this signal was referenced
        push @{$self->{signal_usage}{$signal_name}{contexts}}, $context;
        
        fsm_debug("    SIGNAL REFERENCE: '$signal_name' in context '$context' (total refs: $self->{signal_usage}{$signal_name}{referenced_in_conditions})", 3);
        
    } elsif ($expr->isa('FSM::CoreAST::BinaryOp')) {
        fsm_debug("    BINARY_OP: " . $expr->operator . " in context '$context'", 3);
        $self->_analyze_expression_references($expr->left, "$context.left") if $expr->left;
        $self->_analyze_expression_references($expr->right, "$context.right") if $expr->right;
    } elsif ($expr->isa('FSM::CoreAST::UnaryOp')) {
        fsm_debug("    UNARY_OP: " . $expr->operator . " in context '$context'", 3);
        $self->_analyze_expression_references($expr->operand, "$context.unary") if $expr->operand;
    } elsif ($expr->isa('FSM::CoreAST::Literal')) {
        fsm_debug("    LITERAL: Value = " . $expr->value . ", Width = " . ($expr->width || 'undef') . ", Radix = " . ($expr->radix || 'undef') . " in context '$context'", 3);
        # No signal references in literals
    } elsif ($expr->isa('FSM::CoreAST::IndexedRef')) {
        # Handle indexed references like signal[index] - the base signal should be counted
        if ($expr->signal) {
            my $signal_name = $expr->signal->name;
            $self->{signal_usage}{$signal_name} //= { referenced_in_conditions => 0, assigned_to => 0, has_output_marker => 0, is_intermediate => 0, contexts => [] };
            $self->{signal_usage}{$signal_name}{referenced_in_conditions}++;
            push @{$self->{signal_usage}{$signal_name}{contexts}}, "$context.indexed";
            fsm_debug("    SIGNAL REFERENCE: '$signal_name' in context '$context.indexed' (total refs: $self->{signal_usage}{$signal_name}{referenced_in_conditions})", 3);
        }
        # Also analyze the index expression if it contains signals
        $self->_analyze_expression_references($expr->index, "$context.index") if $expr->index;
    }
}

sub _classify_signal_role($self, $signal_name, $usage) {
    # Apply your specified classification rules:
    
    # 1. Intermediate signals are never in interface
    if ($usage->{is_intermediate}) {
        return 'INTERNAL_INTERMEDIATE';
    }
    
    # 2. Signals with output marker (signal>) are outputs
    if ($usage->{has_output_marker}) {
        return 'OUTPUT';
    }
    
    # 3. Signals referenced in conditions but never assigned are inputs
    if ($usage->{referenced_in_conditions} > 0 && $usage->{assigned_to} == 0) {
        return 'INPUT';
    }
    
    # 4. Signals that are assigned but not marked as output are internal
    if ($usage->{assigned_to} > 0 && !$usage->{has_output_marker}) {
        return 'INTERNAL';
    }
    
    # 5. Everything else defaults to internal
    return 'INTERNAL_DEFAULT';
}

sub generate_fsm_interface($self) {
    fsm_debug("\n=== Generating FSM Interface ===", 3);
    
    return unless $self->{fsm_module};
    
    my $input_count = 0;
    my $output_count = 0;
    my $internal_count = 0;
    my $intermediate_count = 0;
    
    for my $signal_name (sort keys %{$self->{signal_registry}}) {
        my $signal = $self->{signal_registry}{$signal_name};
        my $role = $signal->get_attribute('signal_role') || 'UNKNOWN';
        
        if ($role eq 'INPUT') {
            $self->{fsm_module}->add_signal($signal);
            $input_count++;
            fsm_debug("  Added INPUT: $signal_name", 3);
        } elsif ($role eq 'OUTPUT') {
            $self->{fsm_module}->add_signal($signal);
            $output_count++;
            fsm_debug("  Added OUTPUT: $signal_name", 3);
        } elsif ($role eq 'INTERNAL_INTERMEDIATE') {
            # ADD intermediate signals to FSM module so HDL generator can find them!
            # The HDL generator needs to access these signals and their driving_ast for proper factorization
            $self->{fsm_module}->add_signal($signal);
            $intermediate_count++;
            fsm_debug("  Added INTERMEDIATE signal to FSM module: $signal_name (has driving_ast: " . 
                     ($signal->can('driving_ast') && $signal->driving_ast ? 'YES' : 'NO') . ")", 3);
        } else {
            # Other internal signals - they remain in registry but not added to FSM interface
            $internal_count++;
            fsm_debug("  Kept INTERNAL: $signal_name (role: $role)", 3);
        }
    }
    
    fsm_debug("\nFSM Interface Summary:", 3);
    fsm_debug("  Inputs: $input_count", 3);
    fsm_debug("  Outputs: $output_count", 3);
    fsm_debug("  Intermediates (internal): $intermediate_count", 3);
    fsm_debug("  Other Internal: $internal_count", 3);
}

# Analysis and debugging methods
sub get_symbol_summary($self) {
    my %summary = (
        constants => scalar(keys %{$self->{constants}}),
        enums => scalar(keys %{$self->{enums}}),
        defines => scalar(keys %{$self->{defines}}),
        params => scalar(keys %{$self->{params}}),
    );
    return \%summary;
}

sub get_signal_summary($self) {
    my %summary;
    for my $signal_name (keys %{$self->{signal_registry}}) {
        my $signal = $self->{signal_registry}{$signal_name};
        $summary{$signal_name} = {
            type => $signal->type,
            width => $signal->width,
            is_output => $signal->get_attribute('is_output') // 0,
        };
    }
    return \%summary;
}

sub debug_summary($self) {
    return unless debug_enabled();
    
    my $signal_count = scalar(keys %{$self->{signal_registry}});
    my $state_count = $self->{fsm_module} ? scalar(@{$self->{fsm_module}->states}) : 0;
    
    fsm_debug("=== FSM Adapter Summary ===", 3);
    fsm_debug("Signals discovered: $signal_count", 3);
    fsm_debug("States/DTs parsed: $state_count", 3);
    
    if ($signal_count > 0 && debug_enabled()) {
        fsm_debug("", 3);
        fsm_debug("Signal Registry:", 3);
        my $summary = $self->get_signal_summary();
        for my $name (sort keys %$summary) {
            my $info = $summary->{$name};
            my $width = $info->{width} ? "[$info->{width}]" : "";
            my $output = $info->{is_output} ? " (output)" : "";
            fsm_debug("  $name$width$output", 3);
        }
    }
}

1;

__END__

=head1 NAME

FSM::Adapter::FSMGenFull - Complete FSMGen Lisp Format Adapter

=head1 DESCRIPTION

This module provides comprehensive parsing of FSMGen Lisp format files,
handling all major FSMGen constructs and transforming them into FSM::CoreAST
semantic representations.

=head2 Supported FSMGen Constructs

=over 4

=item * Assignments: C<signal <- value>

=item * State transitions: C<-> target_state>

=item * Increment/decrement: C<++>, C<-->

=item * Conditions: C<<signal>, C<<!signal>

=item * Test nodes: C<?signal>

=item * Expressions: S-expression operators

=item * Signal annotations: width, output markers, slicing

=back

=head1 METHODS

=over 4

=item parse_fsm($raw_ast)

Main entry point for parsing FSMGen AST structures.

=item debug_summary()

Prints debugging summary of parsed FSM.

=back

=cut
