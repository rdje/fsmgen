package FSM::Synthesis::EnableGraph;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use Scalar::Util qw(blessed);
use List::Util qw(min);
use Data::Dumper;
use FSM::AST::Node;

use FSM::Debug;

sub new($class, %args) {
    Carp::confess "EnableGraph requires flattened_dt" unless $args{flattened_dt};
    return bless {
        flattened_dt => $args{flattened_dt},
    }, $class;
}
sub create_condition_expression($self, $condition_stack) {
    # PURE AST APPROACH: Return AST node, not string
    return FSM::AST::Utils::literal("1'b1") if !@$condition_stack;

    # Create AND tree of all conditions
    if (@$condition_stack == 1) {
        return $condition_stack->[0];
    } else {
        return FSM::AST::Utils::and_tree(@$condition_stack);
    }
}
sub register_assignment_capture($self, %args) {
    my $ctx = $self->{flattened_dt};
    my $lhs_ast = $args{lhs_ast};
    my $lhs_name_key = $args{lhs_name_key};

    if (!defined($lhs_name_key) || $lhs_name_key eq '') {
        $lhs_name_key = $self->extract_signal_name_from_ast($lhs_ast) // 'unknown_lhs';
    }

    push @{$ctx->{lhs_assignments}->{$lhs_name_key}}, {
        dt => $args{dt},
        lhs_ast => $lhs_ast,
        conditions_ast => $args{conditions_ast},
        rhs => $args{rhs},
        operator => $args{operator},
        assignment_intent => $args{assignment_intent} || {},
        source_provenance => $args{source_provenance} || {},
        output_exposure => $args{output_exposure} // 'auto',
        is_state_trans => 0,
    };

    $ctx->{all_lhs}->{$lhs_name_key} = 1;
    $ctx->{lhs_ast_map}->{$lhs_name_key} = $lhs_ast if blessed($lhs_ast);

    return $lhs_name_key;
}
sub register_transition_capture($self, %args) {
    my $ctx = $self->{flattened_dt};
    my $target_state = $args{target_state};
    my $state_value = uc($target_state);

    push @{$ctx->{lhs_assignments}->{next_state}}, {
        dt => $args{dt},
        conditions_ast => $args{conditions_ast},
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
        is_state_trans => 1,
    };

    $ctx->{all_lhs}->{next_state} = 1;
    $ctx->{lhs_ast_map}->{next_state} //= FSM::AST::Utils::signal_ref('next_state');

    return $state_value;
}
sub extract_assignment_capture_metadata($self, $assignment_node) {
    my $assignment_intent = {};
    if ($assignment_node && $assignment_node->can('assignment_intent')) {
        my $intent = $assignment_node->assignment_intent;
        $assignment_intent = { %$intent } if ref($intent) eq 'HASH';
    }

    my $operator = ($assignment_node && $assignment_node->can('operator_symbol'))
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
        die "[EnableGraph.pm][extract_assignment_capture_metadata()] Missing or invalid operator_symbol for assignment node '$node_type' (resolved='$operator', intent='$intent_operator', pulse_cycles='$pulse_cycles')";
    }

    return {
        operator => $operator,
        assignment_intent => $assignment_intent,
        source_provenance => ($assignment_node->can('source_provenance') ? $assignment_node->source_provenance : {}),
        output_exposure => ($assignment_node->can('output_exposure') ? $assignment_node->output_exposure : 'auto'),
    };
}
sub capture_assignment_from_ast($self, $dt_name, $assignment_node, $condition_stack) {
    my $lhs_signal_ast = $assignment_node->target;
    my $rhs_expr = $assignment_node->source;
    my $lhs_name = $self->extract_signal_name_from_ast($lhs_signal_ast) // 'unknown_lhs';

    fsm_debug("\n*** PHASE1 ASSIGNMENT NODE REACHED (AST WEB) ***", 3);
    fsm_debug("  DT: $dt_name", 3);
    fsm_debug("  LHS AST Node: " . ref($lhs_signal_ast), 3);
    fsm_debug("  LHS Name: " . $lhs_name, 3);

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

    my $condition_ast = $self->create_condition_expression($condition_stack);
    my $actual_rhs = $self->extract_rhs_capture_value($rhs_expr);
    my $capture_metadata = $self->extract_assignment_capture_metadata($assignment_node);
    my $operator = $capture_metadata->{operator};
    my $assignment_intent = $capture_metadata->{assignment_intent};

    fsm_debug("  SEMANTIC ASSIGNMENT RESULT:", 3);
    fsm_debug("    LHS AST Node: " . ref($lhs_signal_ast), 3);
    fsm_debug("    LHS Name: " . $lhs_name, 3);
    fsm_debug("    RHS: $actual_rhs", 3);
    fsm_debug("    Operator: $operator", 3);
    fsm_debug("    Condition AST: " . (blessed($condition_ast) ? ref($condition_ast) : 'NOT_BLESSED'), 3);
    my $condition_signal_name = defined($condition_ast) ? $condition_ast->to_systemverilog() : 'UNDEFINED';
    fsm_debug("    Condition Signal Name: '$condition_signal_name'", 3);

    $self->register_assignment_capture(
        dt => $dt_name,
        lhs_name_key => $lhs_name,
        lhs_ast => $lhs_signal_ast,
        conditions_ast => $condition_ast,
        rhs => $actual_rhs,
        operator => $operator,
        assignment_intent => $assignment_intent,
        source_provenance => $capture_metadata->{source_provenance},
        output_exposure => $capture_metadata->{output_exposure},
    );

    fsm_debug("*** PHASE1 ASSIGNMENT NODE COMPLETE (AST WEB) ***\n", 3);
}
sub capture_transition_from_ast($self, $dt_name, $transition_node, $condition_stack) {
    my $target_state = $transition_node->target_state;
    my $condition_ast = $self->create_condition_expression($condition_stack);

    my $state_value = $self->register_transition_capture(
        dt => $dt_name,
        target_state => $target_state,
        conditions_ast => $condition_ast,
    );

    my $condition_signal_name = defined($condition_ast) ? $condition_ast->to_systemverilog() : 'UNDEFINED';
    fsm_debug("    Recorded AST transition: next_state <= $state_value when (signal: '$condition_signal_name')", 3);

    return $state_value;
}
sub _get_intermediate_signal_registry_entry($self, $signal_name) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';
    return undef unless exists $ctx->{intermediate_signals}->{$signal_name};

    my $entry = $ctx->{intermediate_signals}->{$signal_name};
    if (ref($entry) eq 'HASH') {
        $entry->{name} //= $signal_name;
        return $entry;
    }

    return {
        name => $signal_name,
        expression => $entry,
        source => 'legacy_string_registry',
    };
}
sub _register_intermediate_signal_registry_entry($self, $signal_name, %updates) {
    my $ctx = $self->{flattened_dt};
    my $existing = $self->_get_intermediate_signal_registry_entry($signal_name) || {};
    my %merged = (
        %$existing,
        %updates,
        name => $signal_name,
    );
    $ctx->{intermediate_signals}->{$signal_name} = \%merged;
    return $ctx->{intermediate_signals}->{$signal_name};
}
sub _get_native_intermediate_signal_ast($self, $signal_name) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';

    if ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{intermediate_signals}) {
        my $signal_info = $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name};
        if ($signal_info && $signal_info->{ast} && blessed($signal_info->{ast})) {
            fsm_debug("[EnableGraph.pm][_get_native_intermediate_signal_ast()] Resolved '$signal_name' from AST factorizer", 3);
            return $signal_info->{ast};
        }
    }

    my $registry_entry = $self->_get_intermediate_signal_registry_entry($signal_name);
    if ($registry_entry && $registry_entry->{ast} && blessed($registry_entry->{ast})) {
        fsm_debug("[EnableGraph.pm][_get_native_intermediate_signal_ast()] Resolved '$signal_name' from intermediate registry", 3);
        return $registry_entry->{ast};
    }

    if ($ctx->{fsm_module} && $ctx->{fsm_module}->can('signals') && $ctx->{fsm_module}->signals) {
        my $signal = $ctx->{fsm_module}->signals->{$signal_name};
        if ($signal && blessed($signal) && $signal->can('driving_ast')) {
            my $driving_ast = $signal->driving_ast;
            if ($driving_ast && blessed($driving_ast)) {
                fsm_debug("[EnableGraph.pm][_get_native_intermediate_signal_ast()] Resolved '$signal_name' from FSM module driving_ast", 3);
                return $driving_ast;
            }
        }
    }

    return undef;
}
sub generate_ast_based_signal_name($self, $ast) {
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
sub map_operator_to_name($self, $operator) {
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
sub clean_intermediate_expression($self, $expression) {
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
sub convert_condition_to_ast($self, $condition_node) {
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
sub convert_test_value_to_ast($self, $test_value) {
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
sub build_test_condition_ast($self, $test_signal, $test_value) {
    my $test_signal_name = blessed($test_signal) && $test_signal->can('name')
        ? $test_signal->name
        : $test_signal;

    unless (defined($test_signal_name) && $test_signal_name ne '') {
        die "[EnableGraph.pm][build_test_condition_ast()] Missing test signal name";
    }

    my $signal_ast = FSM::AST::Utils::signal_ref($test_signal_name);
    my $value_ast = $self->convert_test_value_to_ast($test_value);
    return FSM::AST::Utils::equals_op($signal_ast, $value_ast);
}
sub build_unified_assignment_analysis($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    fsm_debug("\n\n*** UNIFIED PHASE 1: BUILDING COMPLETE ASSIGNMENT ANALYSIS (AST WEB) ***", 3);
    
    # For each LHS signal name key, build complete analysis
    for my $lhs_name_key (keys %{$ctx->{all_lhs}}) {
        next unless $ctx->{lhs_assignments}->{$lhs_name_key};
        
        # Get AST node using mapping
        my $lhs_ast = $ctx->{lhs_ast_map}->{$lhs_name_key};
        
        # AST WEB: get signal name directly from AST node for debugging
        my $lhs_name = blessed($lhs_ast) && $lhs_ast->can('name') ? $lhs_ast->name() : $lhs_name_key;
        
        fsm_debug("\n=== ANALYZING LHS AST: $lhs_name ===", 3);
        fsm_debug("  Found " . scalar(@{$ctx->{lhs_assignments}->{$lhs_name_key}}) . " assignments", 3);
        
        # Initialize unified structure - signal_info intentionally omitted;
        # properties are queried directly from the LHS AST node when needed.
        $ctx->{assignment_analysis}->{$lhs_name_key} = {
            assignments => $ctx->{lhs_assignments}->{$lhs_name_key},
            rhs_groups => {},
            lhs_ast => $lhs_ast,
            multiplexer => {},
        };
        
        # Group assignments by RHS value and build enable structures
        $self->group_assignments_by_rhs($lhs_name_key);
        
        # Generate all enable signal names and expressions
        $self->generate_complete_enable_structure($lhs_name_key);
        
        # Build multiplexer configuration using direct AST queries
        $self->build_multiplexer_config($lhs_name_key);
        
        fsm_debug("  *** COMPLETED ANALYSIS FOR LHS AST: $lhs_name ***", 3);
    }
    
    fsm_debug("\n*** UNIFIED PHASE 1 COMPLETE (AST WEB) ***", 3);
}
sub generate_unified_wen_en_signals($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "  // Unified WEN/EN Signal Generation from Phase 1 Analysis\n";
    
    fsm_debug("\n\n*** UNIFIED PHASE 2: GENERATING WEN/EN SIGNALS FROM ANALYSIS ***", 3);
    
    # Generate DT-specific enables first
    $hdl .= $self->generate_dt_enables_from_analysis();
    
    # Generate LHS-level enables
    $hdl .= $self->generate_lhs_enables_from_analysis();
    
    fsm_debug("*** UNIFIED PHASE 2 COMPLETE ***", 3);
    
    return $hdl;
}
sub prescan_wen_en_for_intermediate_signals($self) {
    my $ctx = $self->{flattened_dt};

    # PRE-SCAN all WEN/EN expressions to identify intermediate signals that need to be declared
    # This runs BEFORE generating intermediate signals so we know which ones to create
    fsm_debug("\n*** PRE-SCAN: IDENTIFYING INTERMEDIATE SIGNALS NEEDED FOR WEN/EN ***", 3);
    fsm_debug("*** TIMING DEBUG: PRE-SCAN running WITHOUT logical operation counts! ***", 3);

    if (exists $ctx->{binary_logical_op_counts}) {
        my $total_ops = 0;
        for my $count (values %{$ctx->{binary_logical_op_counts}}) {
            $total_ops += $count;
        }
        fsm_debug("PRE-SCAN: Logical operation counts ARE available: $total_ops total ops", 3);
        fsm_debug("PRE-SCAN: Counts: " . Data::Dumper::Dumper($ctx->{binary_logical_op_counts}));
    } else {
        fsm_debug("*** PRE-SCAN: CRITICAL - Logical operation counts NOT available yet! ***", 3);
        fsm_debug("*** This means pre-scan is creating intermediate signals blindly! ***", 3);
    }

    $ctx->{referenced_intermediate_signals} //= {};

    for my $lhs (sort keys %{$ctx->{assignment_analysis}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};

        for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
            my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};

            for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                my $enable_ast = $dt_enable_info->{enable_ast};
                next unless $enable_ast && blessed($enable_ast);

                fsm_debug("  PRE-SCAN: Scanning DT-specific enable: $dt_enable_info->{enable_name}", 3);
                $self->track_ast_intermediate_signals($enable_ast);
            }

            if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                my $lhs_enable = $rhs_group->{lhs_level_enable};
                my $enable_ast = $lhs_enable->{ast};
                next unless $enable_ast && blessed($enable_ast);

                fsm_debug("  PRE-SCAN: Scanning LHS-level enable: $lhs_enable->{name}", 3);
                $self->track_ast_intermediate_signals($enable_ast);
            }
        }
    }

    my $signal_count = scalar(keys %{$ctx->{referenced_intermediate_signals}});
    fsm_debug("PRE-SCAN: Identified $signal_count intermediate signals that need declaration", 3);

    if ($signal_count > 0) {
        for my $signal_name (sort keys %{$ctx->{referenced_intermediate_signals}}) {
            fsm_debug("  - $signal_name", 3);
        }
    }

    fsm_debug("*** PRE-SCAN COMPLETE ***\n", 3);
}
sub count_binary_logical_operation_occurrences($self) {
    my $ctx = $self->{flattened_dt};
    my %logical_op_counts;

    fsm_debug("\n*** COUNT_LOGICAL_OPS: STARTING LOGICAL OPERATION COUNTING ***", 3);
    fsm_debug("COUNT_LOGICAL_OPS: This should happen BEFORE any intermediate signal creation!", 3);

    if (exists $ctx->{referenced_intermediate_signals} && %{$ctx->{referenced_intermediate_signals}}) {
        my $prescan_count = scalar(keys %{$ctx->{referenced_intermediate_signals}});
        fsm_debug("*** COUNT_LOGICAL_OPS: WARNING - Pre-scan has already identified $prescan_count intermediate signals! ***", 3);
        fsm_debug("*** This means the logical operation counting is happening TOO LATE! ***", 3);
        fsm_debug("Pre-scan signals: " . join(", ", sort keys %{$ctx->{referenced_intermediate_signals}}));
    } else {
        fsm_debug("COUNT_LOGICAL_OPS: Good - No pre-scan signals created yet", 3);
    }

    fsm_debug("COUNT_LOGICAL_OPS: Counting binary logical operation occurrences", 3);

    my @ast_expressions = $self->collect_all_wen_en_ast_expressions();
    for my $ast_info (@ast_expressions) {
        my $ast = $ast_info->{ast};
        $self->_count_logical_ops_in_ast($ast, \%logical_op_counts);
    }

    for my $signal_name (keys %{$ctx->{intermediate_signals} || {}}) {
        my $ast = $self->_get_native_intermediate_signal_ast($signal_name);
        if ($ast && blessed($ast)) {
            $self->_count_logical_ops_in_ast($ast, \%logical_op_counts);
        } else {
            fsm_debug("COUNT_LOGICAL_OPS: Skipping '$signal_name' because no native intermediate AST is available", 3);
        }
    }

    $ctx->{binary_logical_op_counts} = \%logical_op_counts;

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
    fsm_debug("COUNT_LOGICAL_OPS: Complete counts structure:", 3);
    fsm_debug(Data::Dumper::Dumper(\%logical_op_counts));
    fsm_debug("*** COUNT_LOGICAL_OPS: LOGICAL OPERATION COUNTING COMPLETE ***\n", 3);
    return \%logical_op_counts;
}
sub collect_all_wen_en_ast_expressions($self) {
    my $ctx = $self->{flattened_dt};
    my @ast_expressions;

    fsm_debug("COLLECT_AST: Collecting all WEN/EN AST expressions", 3);

    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};

            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};

                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast}) {
                        push @ast_expressions, {
                            ast => $dt_enable->{enable_ast},
                            context => "dt_enable:$dt_enable->{enable_name}",
                            usage_type => 'dt_enable',
                        };
                    }
                }

                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                    push @ast_expressions, {
                        ast => $rhs_group->{lhs_level_enable}->{ast},
                        context => "lhs_enable:$rhs_group->{lhs_level_enable}->{name}",
                        usage_type => 'lhs_enable',
                    };
                }
            }
        }
    }

    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}->{$lhs}}) {
            if ($assignment->{conditions_ast}) {
                push @ast_expressions, {
                    ast => $assignment->{conditions_ast},
                    context => "assignment_condition:$lhs:$assignment->{dt}",
                    usage_type => 'assignment_condition',
                };
            }
        }
    }

    fsm_debug("COLLECT_AST: Collected " . scalar(@ast_expressions) . " AST expressions", 3);
    return @ast_expressions;
}
sub feed_asts_to_factorizer($self, $factorizer) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("FEED_ASTS: Feeding AST expressions to generic factorizer", 3);

    my $total_fed = 0;
    my $dt_enables_fed = 0;
    my $lhs_enables_fed = 0;
    my $assignment_conditions_fed = 0;

    if ($ctx->{assignment_analysis}) {
        my $total_lhs = scalar(keys %{$ctx->{assignment_analysis}});
        fsm_debug("FEED_ASTS: Processing $total_lhs LHS signals from assignment analysis", 3);

        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
            my $rhs_count = scalar(keys %{$lhs_analysis->{rhs_groups}});
            fsm_debug("  LHS '$lhs' has $rhs_count RHS groups", 3);

            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};

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

    my $total_assignments = 0;
    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        $total_assignments += scalar(@{$ctx->{lhs_assignments}{$lhs}});
    }

    fsm_debug("FEED_ASTS: Processing $total_assignments assignment conditions", 3);

    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}{$lhs}}) {
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

    my $fsmgen_intermediate_fed = 0;
    if ($ctx->{fsm_module} && $ctx->{fsm_module}->can('signals') && $ctx->{fsm_module}->signals) {
        fsm_debug("FEED_ASTS: Processing FSMGenFull intermediate signals", 3);
        my $fsm_signals = $ctx->{fsm_module}->signals;

        for my $signal_name (keys %$fsm_signals) {
            my $signal = $fsm_signals->{$signal_name};

            if ($signal && $signal->can('driving_ast') && $signal->driving_ast) {
                my $is_intermediate = 0;
                if ($signal->can('get_attribute')) {
                    $is_intermediate = $signal->get_attribute('is_intermediate');
                } elsif ($signal->can('attributes') && $signal->attributes) {
                    $is_intermediate = $signal->attributes->{is_intermediate};
                }

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
sub _count_logical_ops_in_ast($self, $ast, $counts_ref) {
    return unless $ast && blessed($ast);

    if ($self->_is_factorizable_sub_expression($ast)) {
        my $signature = eval { $ast->to_systemverilog() } || 'unknown';
        $counts_ref->{$signature}++;
        fsm_debug("    Found factorizable sub-expression: '$signature' (count: $counts_ref->{$signature})", 3);
    }

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        $self->_count_logical_ops_in_ast($ast->left, $counts_ref) if $ast->can('left');
        $self->_count_logical_ops_in_ast($ast->right, $counts_ref) if $ast->can('right');
    }
    elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        $self->_count_logical_ops_in_ast($ast->operand, $counts_ref) if $ast->can('operand');
    }
}
sub _is_factorizable_sub_expression($self, $ast) {
    my $ctx = $self->{flattened_dt};
    return 0 unless $ast && blessed($ast);

    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        return 0;
    }
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        return 0;
    }

    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        fsm_debug("FACTORIZABLE: Unary operation - ALWAYS FACTOR", 3);
        return 1;
    }

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        if ($self->is_arithmetic_operation($ast)) {
            fsm_debug("FACTORIZABLE: Arithmetic operation - ALWAYS FACTOR", 3);
            return 1;
        }

        if ($self->is_logical_operation($ast)) {
            my $signature = eval { $ast->to_systemverilog() } || 'unknown';
            my $count = ($ctx->{binary_logical_op_counts} || {})->{$signature} || 0;
            if ($count > 1) {
                fsm_debug("FACTORIZABLE: Logical operation '$signature' used $count times - FACTOR", 3);
                return 1;
            } else {
                fsm_debug("FACTORIZABLE: Logical operation '$signature' used only $count time - DON'T FACTOR", 3);
                return 0;
            }
        }

        fsm_debug("FACTORIZABLE: Other binary operation - ALWAYS FACTOR", 3);
        return 1;
    }

    return 1;
}
sub feed_current_asts_to_second_pass($self, $second_pass_factorizer) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("SECOND_PASS_FEED: Collecting current AST expressions", 3);

    my $total_fed = 0;

    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};

            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};

                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast} && blessed($dt_enable->{enable_ast})) {
                        my $sv = eval { $self->ast_to_systemverilog($dt_enable->{enable_ast}) } || "[NO SV REPRESENTATION]";

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

                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    if (blessed($lhs_enable->{ast})) {
                        my $sv = eval { $self->ast_to_systemverilog($lhs_enable->{ast}) } || "[NO SV REPRESENTATION]";

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

    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                my $sv = eval { $self->ast_to_systemverilog($assignment->{conditions_ast}) } || "[NO SV REPRESENTATION]";

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
sub ast_contains_intermediate_signals($self, $ast) {
    return 0 unless $ast && blessed($ast);

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $self->extract_signal_name_from_ast($ast) || 'unknown';
        my $ast_sv = eval { $self->ast_to_systemverilog($ast) } || 'unknown';
        fsm_debug("  SECOND_PASS_FILTER: Bare signal reference '$signal_name' (AST: $ast_sv) - NOT factorizable", 3);
        return 0;
    }

    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        my $signal_name = $ast->{signal_name} || 'unknown';
        my $ast_sv = eval { $self->ast_to_systemverilog($ast) } || 'unknown';
        fsm_debug("  SECOND_PASS_FILTER: Bare intermediate signal reference '$signal_name' (AST: $ast_sv) - NOT factorizable", 3);
        return 0;
    }

    my $is_compound_with_intermediates = 0;

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        my $left_has_intermediate = $ast->can('left') && $self->ast_has_intermediate_signals_recursive($ast->left);
        my $right_has_intermediate = $ast->can('right') && $self->ast_has_intermediate_signals_recursive($ast->right);

        if ($left_has_intermediate || $right_has_intermediate) {
            fsm_debug("  SECOND_PASS_FILTER: Compound binary expression contains intermediate signals - factorizable", 3);
            $is_compound_with_intermediates = 1;
        } else {
            fsm_debug("  SECOND_PASS_FILTER: Compound binary expression has no intermediate signals - not factorizable", 3);
        }
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        my $operand_has_intermediate = $ast->can('operand') && $self->ast_has_intermediate_signals_recursive($ast->operand);

        if ($operand_has_intermediate) {
            fsm_debug("  SECOND_PASS_FILTER: Compound unary expression contains intermediate signals - factorizable", 3);
            $is_compound_with_intermediates = 1;
        } else {
            fsm_debug("  SECOND_PASS_FILTER: Compound unary expression has no intermediate signals - not factorizable", 3);
        }
    } else {
        fsm_debug("  SECOND_PASS_FILTER: Not a compound expression - NOT factorizable", 3);
    }

    return $is_compound_with_intermediates;
}
sub ast_has_intermediate_signals_recursive($self, $ast) {
    return 0 unless $ast && blessed($ast);

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $self->extract_signal_name_from_ast($ast);
        if ($signal_name && $self->is_intermediate_signal($signal_name)) {
            return 1;
        }
    }

    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        return 1;
    }

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        return 1 if $ast->can('left') && $self->ast_has_intermediate_signals_recursive($ast->left);
        return 1 if $ast->can('right') && $self->ast_has_intermediate_signals_recursive($ast->right);
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        return 1 if $ast->can('operand') && $self->ast_has_intermediate_signals_recursive($ast->operand);
    }

    return 0;
}
sub count_unary_negations_in_original_expressions($self) {
    my $ctx = $self->{flattened_dt};

    my $neg_count = 0;
    my %neg_patterns;

    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};

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
sub update_original_asts_with_substituted_versions($self, $factorizer) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("UPDATE_ORIGINAL_ASTS: Synchronizing original ASTs with substituted versions", 3);

    my $context_to_substituted_ast = $self->_build_context_to_ast_map(
        $factorizer->{ast_expressions},
        debug_prefix => 'UPDATE_ORIGINAL_ASTS',
        log_context_map => 1,
    );
    my $updated_count = 0;
    my $dt_ast_updates = 0;
    my $lhs_ast_updates = 0;
    my $assignment_ast_updates = 0;

    if ($ctx->{assignment_analysis}) {
        fsm_debug("UPDATE_ORIGINAL_ASTS: Updating assignment_analysis structure", 3);

        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};

            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};

                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_name = $dt_enable_info->{enable_name};
                    my $context_key = "dt_enable:$enable_name";

                    if (exists $context_to_substituted_ast->{$context_key}) {
                        my $original_ast = $dt_enable_info->{enable_ast};
                        my $substituted_ast = $context_to_substituted_ast->{$context_key};

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

                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    my $enable_name = $lhs_enable->{name};
                    my $context_key = "lhs_enable:$enable_name";

                    if (exists $context_to_substituted_ast->{$context_key}) {
                        my $original_ast = $lhs_enable->{ast};
                        my $substituted_ast = $context_to_substituted_ast->{$context_key};

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

    fsm_debug("UPDATE_ORIGINAL_ASTS: Updating lhs_assignments structure", 3);

    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}{$lhs}}) {
            next unless $assignment->{conditions_ast} && blessed($assignment->{conditions_ast});

            my $dt_name = $assignment->{dt};
            my $context_key = "assignment_condition:$lhs:$dt_name";

            if (exists $context_to_substituted_ast->{$context_key}) {
                my $original_ast = $assignment->{conditions_ast};
                my $substituted_ast = $context_to_substituted_ast->{$context_key};

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

    fsm_debug("UPDATE_ORIGINAL_ASTS: Updated $updated_count AST expressions with substituted versions", 3);
    fsm_debug("  - DT-specific enable updates: $dt_ast_updates", 3);
    fsm_debug("  - LHS-level enable updates: $lhs_ast_updates", 3);
    fsm_debug("  - Assignment condition updates: $assignment_ast_updates", 3);

    if ($updated_count == 0) {
        fsm_debug("*** WARNING: NO AST UPDATES WERE PERFORMED! This suggests the substitution/update mechanism isn't working! ***", 3);
    }

    return $updated_count;
}
sub update_original_asts_with_second_pass_substitutions($self, $second_pass_factorizer) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("UPDATE_SECOND_PASS: Updating original ASTs with second-pass substitutions", 3);

    my $second_pass_context_to_ast = $self->_build_context_to_ast_map(
        $second_pass_factorizer->{ast_expressions},
        debug_prefix => 'UPDATE_SECOND_PASS',
    );
    my $updated_count = 0;

    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};

            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};

                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_name = $dt_enable_info->{enable_name};
                    my $context_key = "second_pass_dt_enable:$enable_name";

                    if (exists $second_pass_context_to_ast->{$context_key}) {
                        my $original_ast = $dt_enable_info->{enable_ast};
                        my $substituted_ast = $second_pass_context_to_ast->{$context_key};

                        my $original_sv = eval { $self->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $self->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

                        $dt_enable_info->{enable_ast} = $substituted_ast;
                        $updated_count++;

                        fsm_debug("  *** SECOND-PASS UPDATED DT-specific enable AST: $enable_name ***", 3);
                        fsm_debug("    Original:  $original_sv", 3);
                        fsm_debug("    Updated:   $substituted_sv", 3);
                    }
                }

                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    my $enable_name = $lhs_enable->{name};
                    my $context_key = "second_pass_lhs_enable:$enable_name";

                    if (exists $second_pass_context_to_ast->{$context_key}) {
                        my $original_ast = $lhs_enable->{ast};
                        my $substituted_ast = $second_pass_context_to_ast->{$context_key};

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

    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}{$lhs}}) {
            next unless $assignment->{conditions_ast} && blessed($assignment->{conditions_ast});

            my $dt_name = $assignment->{dt};
            my $context_key = "second_pass_assignment:$lhs:$dt_name";

            if (exists $second_pass_context_to_ast->{$context_key}) {
                my $original_ast = $assignment->{conditions_ast};
                my $substituted_ast = $second_pass_context_to_ast->{$context_key};

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

    fsm_debug("UPDATE_SECOND_PASS: Updated $updated_count AST expressions with second-pass substitutions", 3);
    return $updated_count;
}
sub _build_context_to_ast_map($self, $ast_expressions, %opts) {
    my %context_to_ast;
    my $debug_prefix = $opts{debug_prefix} // 'CONTEXT_MAP';
    my $log_context_map = $opts{log_context_map} // 0;

    $ast_expressions ||= [];
    fsm_debug("$debug_prefix: Factorizer has " . scalar(@$ast_expressions) . " AST expressions to check against", 3);

    for my $expr_info (@$ast_expressions) {
        my $context = $expr_info->{context};
        my $substituted_ast = $expr_info->{ast};
        $context_to_ast{$context} = $substituted_ast;

        if ($log_context_map) {
            my $sv = eval { $substituted_ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
            fsm_debug("  Context '$context' -> AST: $sv", 3);
        }
    }

    return \%context_to_ast;
}
sub generate_enable_conditions($self, $fsm_module = undef) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "  // State and DT Enable Conditions\n";

    for my $state_name (sort keys %{$ctx->{state_enables}}) {
        my $enable_expr = $ctx->{state_enables}->{$state_name};
        $enable_expr = blessed($enable_expr) && $enable_expr->can('to_systemverilog')
            ? $enable_expr->to_systemverilog
            : $enable_expr;
        $hdl .= "  assign ${state_name}_en = $enable_expr;\n";
    }

    for my $dt_name (sort keys %{$ctx->{dt_enables}}) {
        my $enable_expr = $ctx->{dt_enables}->{$dt_name};
        $enable_expr = blessed($enable_expr) && $enable_expr->can('to_systemverilog')
            ? $enable_expr->to_systemverilog
            : $enable_expr;
        my $clean_name = $dt_name;
        $clean_name =~ s/^-//;
        $hdl .= "  assign ${clean_name}_en = $enable_expr;\n";
    }

    $hdl .= "\n";
    return $hdl;
}
sub generate_dt_enables_from_analysis($self) {
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("GENERATE_DT_ENABLES: [ENTRY] Starting DT-specific enable generation from analysis", 3);
    my $hdl = "  // DT-Specific Enable Signals from Unified Analysis\n";
    
    # Track all intermediate signals referenced in enable expressions
    $ctx->{referenced_intermediate_signals} //= {};
    fsm_debug("GENERATE_DT_ENABLES: [INIT] Initialized referenced_intermediate_signals tracking", 3);
    
    # REORGANIZED: Group by DT first, then show all LHS signals within each DT
    # Build a mapping from DT -> LHS -> RHS -> enable_info
    my %dt_to_lhs_enables;
    fsm_debug("GENERATE_DT_ENABLES: [INIT] Starting to build DT->LHS->RHS mapping", 3);
    
for my $lhs (sort keys %{$ctx->{assignment_analysis}}) {
        fsm_debug("GENERATE_DT_ENABLES: [LHS_PROCESSING] Processing LHS '$lhs'", 3);
        my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
        my $rhs_count = scalar(keys %{$lhs_analysis->{rhs_groups}});
        fsm_debug("GENERATE_DT_ENABLES: [LHS_RHS_COUNT] LHS '$lhs' has $rhs_count RHS groups", 3);
        
        for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
            fsm_debug("GENERATE_DT_ENABLES: [RHS_PROCESSING] Processing LHS '$lhs' RHS '$rhs'", 3);
            my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
            my $dt_enable_count = scalar(@{$rhs_group->{dt_specific_enables}});
            fsm_debug("GENERATE_DT_ENABLES: [DT_ENABLE_COUNT] RHS '$rhs' has $dt_enable_count DT-specific enables", 3);
            
            for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                my $enable_name = $dt_enable_info->{enable_name};
                my $enable_ast = $dt_enable_info->{enable_ast};
                my $dt_name = $dt_enable_info->{dt};
                
                fsm_debug("GENERATE_DT_ENABLES: [DT_ENABLE_INFO] Processing DT enable:", 3);
                fsm_debug("  Enable name: $enable_name", 3);
                fsm_debug("  DT name: $dt_name", 3);
                fsm_debug("  Enable AST type: " . (blessed($enable_ast) ? ref($enable_ast) : 'NOT_BLESSED'));
                
                # Track intermediate signals in this AST
                fsm_debug("GENERATE_DT_ENABLES: [TRACK_INTERMEDIATE] Tracking intermediate signals for '$enable_name'", 3);
                $self->track_ast_intermediate_signals($enable_ast);

                
                # Group by DT first
                $dt_to_lhs_enables{$dt_name} //= {};
                $dt_to_lhs_enables{$dt_name}{$lhs} //= [];
                fsm_debug("GENERATE_DT_ENABLES: [GROUPING] Grouping enable '$enable_name' under DT '$dt_name' LHS '$lhs'", 3);
                
                push @{$dt_to_lhs_enables{$dt_name}{$lhs}}, {
                    enable_name => $enable_name,
                    enable_ast => $enable_ast,
                    rhs => $rhs
                };
            }
        }
    }
    
    # Generate output grouped by DT
    for my $dt_name (sort keys %dt_to_lhs_enables) {
        my $clean_dt_name = $dt_name;
        $clean_dt_name =~ s/^-//;  # Remove leading dash for standalone DTs
        
        $hdl .= "\n\n  // === DT: $dt_name ===\n";
        
        # Show all LHS signals within this DT
        for my $lhs (sort keys %{$dt_to_lhs_enables{$dt_name}}) {
            $hdl .= "  // $lhs\n";
            
            for my $enable_info (@{$dt_to_lhs_enables{$dt_name}{$lhs}}) {
                my $enable_name = $enable_info->{enable_name};
                my $enable_ast = $enable_info->{enable_ast};
                my $rhs = $enable_info->{rhs};
                
                # Convert AST to SystemVerilog for output (without outer parentheses)
                my $enable_expr = $self->ast_to_systemverilog($enable_ast);

                
                $hdl .= "  assign $enable_name = $enable_expr;  // $lhs <- $rhs\n";
                
                fsm_debug("  Generated DT-specific enable: $enable_name = $enable_expr", 3);
            }
        }
    }
    
    return $hdl;
}
sub generate_lhs_enables_from_analysis($self) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "\n  // LHS-Level Enable Signals from Unified Analysis\n";
    
    # Process each LHS from the unified analysis
    for my $lhs (sort keys %{$ctx->{assignment_analysis}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
        
        $hdl .= "\n  // LHS-level enables for: $lhs\n";
        
        # Generate LHS-level enables for each RHS
        for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
            my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
            my $lhs_enable = $rhs_group->{lhs_level_enable};
            
            if ($lhs_enable) {
                my $enable_name = $lhs_enable->{name};
                my $enable_ast = $lhs_enable->{ast};
                
                # Track intermediate signals in this AST
                $self->track_ast_intermediate_signals($enable_ast);
                
                # Convert AST to SystemVerilog for output (without outer parentheses)
                my $enable_expr = $self->ast_to_systemverilog($enable_ast);
                
                $hdl .= "  assign $enable_name = $enable_expr;\n";
                
                fsm_debug("  Generated LHS-level enable: $enable_name = $enable_expr", 3);
            }
        }
    }
    
    return $hdl;
}
sub generate_signal_assignments($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "\n  // Unified Multiplexer Logic from Phase 1 Analysis\n";
    
    fsm_debug("\n\n*** UNIFIED PHASE 3: GENERATING MULTIPLEXERS FROM ANALYSIS ***", 3);
    
    # Generate multiplexers for all LHS signals from unified analysis
    for my $lhs (sort keys %{$ctx->{assignment_analysis}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
        my $multiplexer = $lhs_analysis->{multiplexer};
        my $assignment_type = $self->get_signal_assignment_type($lhs, $lhs_analysis);
        
        $hdl .= "\n  // Unified Multiplexer for LHS: $lhs\n";
        
        if ($assignment_type eq 'pulse_delayed') {
            $hdl .= $self->generate_unified_pulse_delay_logic($lhs, $lhs_analysis);
        } elsif ($multiplexer->{type} eq 'flop') {
            $hdl .= $self->generate_unified_flop_mux($lhs, $lhs_analysis);
        } else {
            $hdl .= $self->generate_unified_comb_mux($lhs, $lhs_analysis);
        }
        
        fsm_debug("  Generated unified multiplexer for $lhs (type: $multiplexer->{type}, assignment_type: $assignment_type)", 3);
    }
    
    fsm_debug("*** UNIFIED PHASE 3 COMPLETE ***", 3);
    
    return $hdl;
}
sub build_state_register_plan($self, $fsm_module = undef) {
    my $ctx = $self->{flattened_dt};
    $fsm_module //= $ctx->{fsm_module};

    my @regular_states = $fsm_module
        ? grep { $_->name !~ /^-/ } @{$fsm_module->states}
        : ();
    my $state_count = scalar(@regular_states);
    my $state_bits = $state_count > 1 ? int(log($state_count) / log(2)) + 1 : 1;
    my @encodings;

    for my $i (0 .. $#regular_states) {
        push @encodings, {
            state_name => $regular_states[$i]->name,
            localparam_name => uc($regular_states[$i]->name),
            encoded_value => $i,
        };
    }

    return {
        has_state_registers => $state_count > 0 ? 1 : 0,
        state_count => $state_count,
        state_bits => $state_bits,
        reset_state_name => @encodings ? $encodings[0]{localparam_name} : 'IDLE',
        encodings => \@encodings,
    };
}
sub build_internal_signal_declaration_plan($self, $fsm_module, $declared_ports = undef) {
    my $ctx = $self->{flattened_dt};
    my %declared_ports = ();
    if (ref($declared_ports) eq 'HASH') {
        %declared_ports = %{$declared_ports};
    } elsif ($ctx->{declared_port_signals}) {
        %declared_ports = %{$ctx->{declared_port_signals}};
    }

    my %signal_decls;
    my %aux_decls;

    my $state_plan = $self->build_state_register_plan($fsm_module);
    if ($state_plan->{has_state_registers}) {
        $declared_ports{current_state} = 1;
        $declared_ports{next_state} = 1;
    }

    for my $lhs (sort keys %{$ctx->{assignment_analysis} || {}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
        next unless $lhs_analysis;

        my $width = $self->get_lhs_width_from_analysis($lhs_analysis);
        my $assignment_type = $self->get_signal_assignment_type($lhs, $lhs_analysis);
        my $multiplexer_type = $lhs_analysis->{multiplexer}->{type} || 'comb';

        unless ($declared_ports{$lhs}) {
            $signal_decls{$lhs} = $width;
        }

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

    return {
        signal_decls => \%signal_decls,
        aux_decls => \%aux_decls,
    };
}
sub build_module_declaration_plan($self, $fsm_module) {
    my @base_ports = (
        {
            direction => 'input',
            storage => 'wire',
            name => 'clk',
            width => 1,
        },
        {
            direction => 'input',
            storage => 'wire',
            name => 'rstn',
            width => 1,
        },
    );

    my $signals = $fsm_module->signals;
    my @inputs;
    my @outputs;

    fsm_debug("HDL Generation: Processing " . scalar(keys %$signals) . " signals for module declaration", 3);

    my %seen_signals = ('clk' => 1, 'rstn' => 1);
    my %port_directions = ('clk' => 'input', 'rstn' => 'input');
    my %driven_signals = $self->get_driven_signals();

    for my $sig_name (sort keys %$signals) {
        if ($seen_signals{$sig_name}) {
            fsm_debug("HDL Signal Processing: SKIPPING duplicate signal '$sig_name'", 3);
            next;
        }
        $seen_signals{$sig_name} = 1;

        my $signal = $signals->{$sig_name};

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

        fsm_debug("HDL Signal Processing: $sig_name", 3);
        fsm_debug("  Signal object type: " . ref($signal), 3);
        fsm_debug("  Signal dump: " . Dumper($signal), 3);

        my $signal_width = 1;
        if ($signal->can('width')) {
            $signal_width = $signal->width;
            $signal_width = 1 unless ($signal_width && $signal_width > 0);
            fsm_debug("  Signal width from ->width(): $signal_width", 3);
        } else {
            fsm_debug("  Signal does not have width() method", 3);
        }

        my $is_output = 0;
        if ($driven_signals{$sig_name}) {
            $is_output = 1;
            fsm_debug("  Signal '$sig_name' is DRIVEN by FSM -> OUTPUT", 3);
        } else {
            if ($signal->can('is_output')) {
                $is_output = $signal->is_output;
            } elsif ($signal->can('attributes') && $signal->attributes && $signal->attributes->{is_output}) {
                $is_output = $signal->attributes->{is_output};
            } elsif ($sig_name =~ />$/) {
                $is_output = 1;
            }

            fsm_debug("  Signal '$sig_name' direction: " . ($is_output ? "OUTPUT" : "INPUT"), 3);
        }

        my $port_plan = {
            direction => $is_output ? 'output' : 'input',
            storage => $is_output ? 'reg' : 'wire',
            name => $sig_name,
            width => $signal_width,
        };

        if ($is_output) {
            push @outputs, $port_plan;
            $port_directions{$sig_name} = 'output';
        } else {
            push @inputs, $port_plan;
            $port_directions{$sig_name} = 'input';
        }
    }

    return {
        base_ports => \@base_ports,
        inputs => \@inputs,
        outputs => \@outputs,
        declared_port_signals => \%seen_signals,
        port_directions => \%port_directions,
    };
}
sub generate_unified_pulse_delay_logic($self, $lhs, $lhs_analysis) {
    my $ctx = $self->{flattened_dt};
    my $lhs_ast = $lhs_analysis->{lhs_ast};
    my $lhs_name = blessed($lhs_ast) && $lhs_ast->can('name') ? $lhs_ast->name() : $lhs;
    my $delay_cycles = $self->get_pulse_delay_cycles_for_lhs($lhs, $lhs_analysis);
    my $active_level = $self->get_pulse_active_level_for_lhs($lhs, $lhs_analysis);
    my $rest_level = $active_level ? "1'b0" : "1'b1";
    my $pulse_level = $active_level ? "1'b1" : "1'b0";
    my $width = $self->get_lhs_width_from_analysis($lhs_analysis);
    
    if ($width != 1) {
        die "[EnableGraph.pm][generate_unified_pulse_delay_logic()] Delayed pulse target '$lhs_name' must be 1-bit, got width '$width'";
    }
    
    my @request_signals = map { $_->{enable_signal} } @{$lhs_analysis->{multiplexer}->{enables} || []};
    my $request_expr = @request_signals ? join(' | ', @request_signals) : "1'b0";
    
    my $hdl = "  // Delayed pulse logic for: $lhs_name (<$delay_cycles, exact Q+$delay_cycles)\n";
    
    if ($delay_cycles == 0) {
        $hdl .= "  always_ff @(posedge clk or negedge rstn) begin\n";
        $hdl .= "    if (!rstn) begin\n";
        $hdl .= "      $lhs_name <= $rest_level;\n";
        $hdl .= "    end else begin\n";
        $hdl .= "      $lhs_name <= ($request_expr) ? $pulse_level : $rest_level;\n";
        $hdl .= "    end\n";
        $hdl .= "  end\n";
        return $hdl;
    }
    
    my $pipe_name = "${lhs_name}_pulse_delay_pipe";
    my $pipe_tap = $delay_cycles == 1 ? $pipe_name : "${pipe_name}[" . ($delay_cycles - 1) . "]";
    my $shift_rhs = $delay_cycles == 1
        ? $request_expr
        : "{${pipe_name}[" . ($delay_cycles - 2) . ":0], $request_expr}";
    my $pipe_reset = $delay_cycles == 1
        ? "1'b0"
        : '{' . $delay_cycles . "{1'b0}}";
    
    $hdl .= "  always_ff @(posedge clk or negedge rstn) begin\n";
    $hdl .= "    if (!rstn) begin\n";
    $hdl .= "      $lhs_name <= $rest_level;\n";
    $hdl .= "      $pipe_name <= $pipe_reset;\n";
    $hdl .= "    end else begin\n";
    $hdl .= "      $lhs_name <= $rest_level;\n";
    $hdl .= "      if ($pipe_tap) begin\n";
    $hdl .= "        $lhs_name <= $pulse_level;\n";
    $hdl .= "      end\n";
    $hdl .= "      $pipe_name <= $shift_rhs;\n";
    $hdl .= "    end\n";
    $hdl .= "  end\n";
    
    return $hdl;
}
sub get_pulse_delay_cycles_for_lhs($self, $lhs, $lhs_analysis) {
    my %delay_values;
    for my $assignment (@{$lhs_analysis->{assignments} || []}) {
        my $op = $assignment->{operator} // '';
        if ($op =~ /^<(\d+)$/) {
            $delay_values{$1} = 1;
            next;
        }
        my $intent = $assignment->{assignment_intent};
        if (ref($intent) eq 'HASH' && defined($intent->{pulse_delay_cycles})) {
            $delay_values{$intent->{pulse_delay_cycles}} = 1;
        }
    }
    my @delays = sort { $a <=> $b } keys %delay_values;
    if (!@delays) {
        die "[EnableGraph.pm][get_pulse_delay_cycles_for_lhs()] Missing pulse delay metadata for LHS '$lhs'";
    }
    if (@delays > 1) {
        die "[EnableGraph.pm][get_pulse_delay_cycles_for_lhs()] Multiple pulse delays for LHS '$lhs' are unsupported: " . join(', ', @delays);
    }
    return $delays[0];
}
sub get_pulse_active_level_for_lhs($self, $lhs, $lhs_analysis) {
    my %active_levels;
    for my $assignment (@{$lhs_analysis->{assignments} || []}) {
        my $intent = $assignment->{assignment_intent};
        if (ref($intent) eq 'HASH' && defined($intent->{pulse_active_level})) {
            $active_levels{int($intent->{pulse_active_level} ? 1 : 0)} = 1;
            next;
        }
        my $rhs = $assignment->{rhs};
        my $normalized = $self->normalize_rhs_logic_level($rhs);
        if (defined $normalized) {
            $active_levels{$normalized} = 1;
        }
    }
    my @levels = sort { $a <=> $b } keys %active_levels;
    if (!@levels) {
        die "[EnableGraph.pm][get_pulse_active_level_for_lhs()] Missing pulse active level metadata for LHS '$lhs'";
    }
    if (@levels > 1) {
        die "[EnableGraph.pm][get_pulse_active_level_for_lhs()] Conflicting pulse active levels for LHS '$lhs': " . join(', ', @levels);
    }
    return $levels[0];
}
sub normalize_rhs_logic_level($self, $rhs) {
    return undef unless defined $rhs;
    return 0 if $rhs =~ /^(?:0|1'b0|1'd0|1'h0)$/i;
    return 1 if $rhs =~ /^(?:1|1'b1|1'd1|1'h1)$/i;
    return undef;
}
sub generate_unified_flop_mux($self, $lhs, $lhs_analysis) {
    my $ctx = $self->{flattened_dt};
    my $multiplexer = $lhs_analysis->{multiplexer};
    my $lhs_ast = $lhs_analysis->{lhs_ast};  # Get the AST node for direct queries
    
    # AST WEB: Get signal name for debugging and HDL generation
    my $lhs_name = blessed($lhs_ast) && $lhs_ast->can('name') ? $lhs_ast->name() : 'UNKNOWN';
    
    # Determine the assignment type by examining the operators used
    my $assignment_type = $self->get_signal_assignment_type($lhs, $lhs_analysis);
    
    my $hdl = "  // Unified flop with mux for: $lhs_name ($assignment_type assignment)\n";
    
    if ($assignment_type eq 'register_out' || $assignment_type eq 'register_out_dual') {
        # <- / <-= assignment: A is a register, A_next is the mux output
        my $emit_next_output = ($assignment_type eq 'register_out_dual') ? 1 : 0;
        my $next_output_name = "next_${lhs_name}";
        
        # Generate the combinational multiplexer logic
        $hdl .= "  always_comb begin\n";
        $hdl .= "    ${lhs_name}_next = $multiplexer->{default_value};  // Default value\n";
        
        # Use enables from unified analysis - these match exactly with generated signals
        for my $enable_info (@{$multiplexer->{enables}}) {
            my $enable_signal = $enable_info->{enable_signal};
            my $rhs_value = $enable_info->{rhs_value};
            
            $hdl .= "    if ($enable_signal) begin\n";
            $hdl .= "      ${lhs_name}_next = $rhs_value;\n";
            $hdl .= "    end\n";
            
            fsm_debug("    Unified flop mux (<-): $enable_signal -> $rhs_value", 3);
        }
        
        if ($emit_next_output) {
            $hdl .= "    $next_output_name = ${lhs_name}_next;\n";
            fsm_debug("    Unified flop mux (<-=): exposing '$next_output_name'", 3);
        }
        
        $hdl .= "  end\n";
        
        # AST WEB: Get reset value using direct AST method calls
        my $reset_value = $self->get_reset_value_from_ast($lhs_ast);

        
        # Generate the flip-flop
        $hdl .= "  always_ff @(posedge clk or negedge rstn) begin\n";
        $hdl .= "    if (!rstn) begin\n";
        $hdl .= "      $lhs_name <= $reset_value;\n";
        $hdl .= "    end else begin\n";
        $hdl .= "      $lhs_name <= ${lhs_name}_next;\n";
        $hdl .= "    end\n";
        $hdl .= "  end\n";
        
    } elsif ($assignment_type eq 'register_in' || $assignment_type eq 'register_in_dual') {
        # <= / <=+ assignment: A is the mux output, A_q is the flop output that provides feedback
        my $emit_q_output = ($assignment_type eq 'register_in_dual') ? 1 : 0;
        my $q_output_name = "${lhs_name}_r";
        
        # Generate the combinational multiplexer logic
        $hdl .= "  always_comb begin\n";
        $hdl .= "    $lhs_name = ${lhs_name}_q;  // Default value is feedback from flop output\n";
        if ($emit_q_output) {
            $hdl .= "    $q_output_name = ${lhs_name}_q;\n";
        }
        
        # Use enables from unified analysis - these match exactly with generated signals
        for my $enable_info (@{$multiplexer->{enables}}) {
            my $enable_signal = $enable_info->{enable_signal};
            my $rhs_value = $enable_info->{rhs_value};
            
            $hdl .= "    if ($enable_signal) begin\n";
            $hdl .= "      $lhs_name = $rhs_value;\n";
            $hdl .= "    end\n";
            
            fsm_debug("    Unified flop mux (<=): $enable_signal -> $rhs_value", 3);
        }
        
        $hdl .= "  end\n";
        
        # AST WEB: Get reset value using direct AST method calls
        my $reset_value = $self->get_reset_value_from_ast($lhs_ast);
        
        # Generate the flip-flop (output is A_q, input is A)
        $hdl .= "  always_ff @(posedge clk or negedge rstn) begin\n";
        $hdl .= "    if (!rstn) begin\n";
        $hdl .= "      ${lhs_name}_q <= $reset_value;\n";
        $hdl .= "    end else begin\n";
        $hdl .= "      ${lhs_name}_q <= $lhs_name;\n";
        $hdl .= "    end\n";
        $hdl .= "  end\n";
    } else {
        die "[EnableGraph.pm][generate_unified_flop_mux()] Unsupported flop assignment_type '$assignment_type' for LHS '$lhs_name'";
    }
    
    return $hdl;
}
sub generate_unified_comb_mux($self, $lhs, $lhs_analysis) {
    my $multiplexer = $lhs_analysis->{multiplexer};
    
    my $hdl = "  // Unified combinational mux for: $lhs\n";
    
    $hdl .= "  always_comb begin\n";
    # For combinational logic, default to 1'b0 to avoid feedback loops
    # CRITICAL FIX: Never use signal name as default for combinational multiplexers
    my $safe_default = "1'b0";  # Safe default for combinational logic
    $hdl .= "    $lhs = $safe_default;  // Default value\n";
    
    # Use enables from unified analysis - these match exactly with generated signals
    for my $enable_info (@{$multiplexer->{enables}}) {
        my $enable_signal = $enable_info->{enable_signal};
        my $rhs_value = $enable_info->{rhs_value};
        
        $hdl .= "    if ($enable_signal) begin\n";
        $hdl .= "      $lhs = $rhs_value;\n";
        $hdl .= "    end\n";
        
        fsm_debug("    Unified comb mux: $enable_signal -> $rhs_value", 3);
    }
    
    $hdl .= "  end\n";
    
    return $hdl;
}
sub get_signal_assignment_type($self, $lhs, $lhs_analysis) {
    # Determine the assignment type for a signal by examining the operators used
    # Returns:
    #   'register_out'      for <- assignments
    #   'register_in'       for <= assignments
    #   'register_out_dual' for <-= assignments (rm)
    #   'register_in_dual'  for <=+ assignments (mr)
    #   'pulse_delayed'     for <N assignments (pN, exact Q+N pulse)
    #   'mux_out'           for = assignments
    
    # Add error handling for missing or empty assignments
    my $assignments = $lhs_analysis->{assignments};
    unless ($assignments && @$assignments) {
        fsm_debug("WARNING: No assignments found for LHS '$lhs', defaulting to 'mux_out'", 3);
        return 'mux_out';  # Default to combinational assignment
    }
    
    my $has_register_assignment = 0;       # <-
    my $has_flop_assignment = 0;           # <=
    my $has_register_dual_assignment = 0;  # <-=
    my $has_flop_dual_assignment = 0;      # <=+
    my $has_comb_assignment = 0;           # =
    my $has_pulse_assignment = 0;          # <N
    my %pulse_delays;
    
    for my $assignment (@$assignments) {
        my $operator = $assignment->{operator};
        if (!defined($operator) || $operator eq '') {
            die "[EnableGraph.pm][get_signal_assignment_type()] Missing operator in assignment analysis for LHS '$lhs'";
        }
        
        if ($operator eq '<-') {
            $has_register_assignment = 1;
        } elsif ($operator eq '<=') {
            $has_flop_assignment = 1;
        } elsif ($operator eq '<-=') {
            $has_register_dual_assignment = 1;
        } elsif ($operator eq '<=+') {
            $has_flop_dual_assignment = 1;
        } elsif ($operator eq '=') {
            $has_comb_assignment = 1;
        } elsif ($operator =~ /^<(\d+)$/) {
            $has_pulse_assignment = 1;
            $pulse_delays{$1} = 1;
        } else {
            die "[EnableGraph.pm][get_signal_assignment_type()] Unsupported operator '$operator' in assignment analysis for LHS '$lhs'";
        }
    }
    
    my $sequential_family_count = 0;
    $sequential_family_count++ if $has_register_assignment;
    $sequential_family_count++ if $has_flop_assignment;
    $sequential_family_count++ if $has_register_dual_assignment;
    $sequential_family_count++ if $has_flop_dual_assignment;
    $sequential_family_count++ if $has_pulse_assignment;
    
    if ($has_comb_assignment && $sequential_family_count > 0) {
        die "[EnableGraph.pm][get_signal_assignment_type()] Mixed combinational '=' and sequential operators for LHS '$lhs' is unsupported";
    }
    
    if (keys(%pulse_delays) > 1) {
        die "[EnableGraph.pm][get_signal_assignment_type()] Multiple pulse delays for LHS '$lhs' are unsupported: " . join(', ', sort keys %pulse_delays);
    }
    
    if ($has_pulse_assignment && ($has_register_assignment || $has_flop_assignment || $has_register_dual_assignment || $has_flop_dual_assignment)) {
        die "[EnableGraph.pm][get_signal_assignment_type()] Mixed pulse-delayed and non-pulse sequential operators for LHS '$lhs' is unsupported";
    }
    
    if ($has_register_dual_assignment) {
        if ($has_flop_assignment || $has_flop_dual_assignment) {
            die "[EnableGraph.pm][get_signal_assignment_type()] Mixed '<-=' with '<='/'<=+' for LHS '$lhs' is unsupported";
        }
        return 'register_out_dual';
    }
    if ($has_flop_dual_assignment) {
        if ($has_register_assignment || $has_register_dual_assignment) {
            die "[EnableGraph.pm][get_signal_assignment_type()] Mixed '<=+' with '<-'/'<-=' for LHS '$lhs' is unsupported";
        }
        return 'register_in_dual';
    }
    if ($has_pulse_assignment) {
        return 'pulse_delayed';
    }
    if ($has_register_assignment) {
        return 'register_out';
    }
    if ($has_flop_assignment) {
        return 'register_in';
    }
    return 'mux_out';
}
sub get_driven_signals($self) {
    # Return hash of signals that are driven by the FSM (should be outputs)
    # This is determined by checking if they appear as LHS in assignments
    my $ctx = $self->{flattened_dt};
    my %driven_signals;
    
    # Check all recorded LHS assignments
    for my $lhs (keys %{$ctx->{all_lhs}}) {
        $driven_signals{$lhs} = 1;
        fsm_debug("[EnableGraph.pm][get_driven_signals()] DRIVEN_SIGNALS: '$lhs' is driven by FSM logic", 3);
    }
    
    # Include auxiliary outputs exposed by sequential dual families:
    #   rm (<-=): next_<lhs>
    #   mr (<=+): <lhs>_r
    for my $lhs (keys %{$ctx->{assignment_analysis} || {}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
        next unless $lhs_analysis;
        my $assignment_type = $self->get_signal_assignment_type($lhs, $lhs_analysis);
        
        if ($assignment_type eq 'register_out_dual') {
            my $next_name = "next_$lhs";
            $driven_signals{$next_name} = 1;
            fsm_debug("[EnableGraph.pm][get_driven_signals()] DRIVEN_SIGNALS: '$next_name' is driven by rm auxiliary output logic", 3);
        } elsif ($assignment_type eq 'register_in_dual') {
            my $q_name = "${lhs}_r";
            $driven_signals{$q_name} = 1;
            fsm_debug("[EnableGraph.pm][get_driven_signals()] DRIVEN_SIGNALS: '$q_name' is driven by mr auxiliary output logic", 3);
        }
    }
    
    return %driven_signals;
}
sub get_reset_value($self, $lhs) {
    # Provide appropriate reset values for different signals
    # Use semantic information and explicit conventions, NOT name-based heuristics
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("GET_RESET_VALUE: Determining reset value for LHS '$lhs'", 3);
    
    # Check if this is the FSM state variable (semantic check)
    if ($lhs eq 'next_state') {
        # For the FSM state variable, get the reset state from the FSM module
        my $reset_state = $self->get_fsm_reset_state();
        fsm_debug("GET_RESET_VALUE: State variable '$lhs' -> reset to '$reset_state'", 3);
        return $reset_state;
    }
    
    # Check if this LHS has explicit reset information from the FSM specification
    my $explicit_reset = $self->get_explicit_reset_value($lhs);
    if (defined $explicit_reset) {
        fsm_debug("GET_RESET_VALUE: Explicit reset for '$lhs' -> '$explicit_reset'", 3);
        return $explicit_reset;
    }
    
    # Check signal width to determine appropriate default reset value
    my $signal_info = $self->get_signal_info($lhs);
    if ($signal_info && $signal_info->{width}) {
        my $width = $signal_info->{width};
        if ($width > 1) {
            my $reset_val = sprintf("%d'h%s", $width, "0" x int(($width + 3) / 4));
            fsm_debug("GET_RESET_VALUE: Multi-bit signal '$lhs' ($width bits) -> '$reset_val'", 3);
            return $reset_val;
        }
    }
    
    # Default: single-bit signals reset to 0
    fsm_debug("GET_RESET_VALUE: Default single-bit reset for '$lhs' -> '1'b0'", 3);
    return "1'b0";
}
sub get_default_value($self, $lhs) {
    # For flop assignments (A <-), the default should be the current register value (feedback)
    # This is different from reset values, which are used for initialization
    
    # For state variable, use proper feedback
    if ($lhs eq 'next_state') {
        return "current_state";
    }
    
    # For all other register assignments, use feedback from the register itself
    # This ensures proper flop behavior where the register maintains its value
    # unless explicitly overridden by an enable condition
    return $lhs;  # Use the signal itself as feedback (current register value)
}
sub get_fsm_reset_state($self) {
    # Get the reset state for the FSM from the FSM module
    # The reset state is conventionally the first state in the state list
    my $ctx = $self->{flattened_dt};
    
    # If we have access to the FSM module, get the first regular state
    if ($ctx->{fsm_module}) {
        my $state_plan = $self->build_state_register_plan($ctx->{fsm_module});
        if ($state_plan->{has_state_registers}) {
            my $reset_state = $state_plan->{reset_state_name};
            fsm_debug("FSM_RESET_STATE: Using first state as reset: '$reset_state'", 3);
            return $reset_state;
        }
    }
    
    # If no FSM module available or no states, default to IDLE
    fsm_debug("FSM_RESET_STATE: Defaulting to IDLE", 3);
    return "IDLE";
}
sub get_explicit_reset_value($self, $lhs) {
    # Check if this LHS has explicit reset information from the FSM specification
    # This could come from signal attributes, FSM metadata, or explicit configuration
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("EXPLICIT_RESET: Checking for explicit reset value for '$lhs'", 3);
    
    # Check if we have explicit reset values configured
    if ($ctx->{explicit_reset_values} && $ctx->{explicit_reset_values}{$lhs}) {
        my $reset_val = $ctx->{explicit_reset_values}{$lhs};
        fsm_debug("EXPLICIT_RESET: Found configured reset for '$lhs' -> '$reset_val'", 3);
        return $reset_val;
    }
    
    # Check signal attributes if available through FSM module
    if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals) {
        my $signals = $ctx->{fsm_module}->signals;
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
sub get_signal_info($self, $lhs) {
    # Get signal information from the FSM module
    # Returns: { width => N, ... } or undef if not found
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("SIGNAL_INFO: Getting info for '$lhs'", 3);
    
    # Check if we have FSM module with signals
    if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals) {
        my $signals = $ctx->{fsm_module}->signals;
        if ($signals->{$lhs}) {
            my $signal = $signals->{$lhs};
            
            my $signal_info = {};
            
            # Get width if available
            if ($signal->can('width')) {
                my $width = $signal->width;
                if ($width && $width > 0) {
                    $signal_info->{width} = $width;
                    fsm_debug("SIGNAL_INFO: Found width for '$lhs' -> $width", 3);
                } else {
                    fsm_debug("SIGNAL_INFO: Width method returned invalid value for '$lhs'", 3);
                }
            } else {
                fsm_debug("SIGNAL_INFO: No width method for '$lhs'", 3);
            }
            
            # Get other attributes if needed
            # ... (can add more signal attributes here in the future)
            
            return $signal_info if %$signal_info;
        } else {
            fsm_debug("SIGNAL_INFO: Signal '$lhs' not found in FSM signals", 3);
        }
    } else {
        fsm_debug("SIGNAL_INFO: No FSM module or signals available", 3);
    }
    
    return undef;
}
sub get_lhs_width_from_analysis($self, $lhs_analysis) {
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
sub build_state_enable_condition_ast($self, $state_name) {
    return FSM::AST::Utils::equals_op(
        FSM::AST::Utils::signal_ref('current_state'),
        FSM::AST::Utils::literal(uc($state_name)),
    );
}
sub build_dt_enable_condition_ast($self, $dt_name) {
    return FSM::AST::Utils::literal("1'b1");
}
sub set_fsm_module_reference($self, $fsm_module) {
    # Store a reference to the FSM module for accessing signal information
    my $ctx = $self->{flattened_dt};
    $ctx->{fsm_module} = $fsm_module;
    fsm_debug("FSM_MODULE_REF: Stored reference to FSM module: " . ($fsm_module ? $fsm_module->name : 'undef'), 3);
}
sub initialize_state_and_dt_enable_conditions($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    $ctx->{state_enables} = {};
    $ctx->{dt_enables} = {};

    return unless $fsm_module && $fsm_module->can('states') && $fsm_module->states;

    for my $state (@{$fsm_module->states}) {
        next unless $state && $state->can('name');

        my $state_name = $state->name;
        next unless defined($state_name) && $state_name ne '';

        if ($state_name =~ /^-/) {
            my $enable_ast = $self->build_dt_enable_condition_ast($state_name);
            $ctx->{dt_enables}->{$state_name} = $enable_ast;
            my $enable_sv = blessed($enable_ast) && $enable_ast->can('to_systemverilog')
                ? $enable_ast->to_systemverilog
                : 'UNBLESSED';
            fsm_debug("ENABLE_INIT: Registered standalone DT enable for $state_name -> $enable_sv", 3);
        } else {
            my $enable_ast = $self->build_state_enable_condition_ast($state_name);
            $ctx->{state_enables}->{$state_name} = $enable_ast;
            my $enable_sv = blessed($enable_ast) && $enable_ast->can('to_systemverilog')
                ? $enable_ast->to_systemverilog
                : 'UNBLESSED';
            fsm_debug("ENABLE_INIT: Registered state enable for $state_name -> $enable_sv", 3);
        }
    }
}
sub extract_rhs_capture_value($self, $expr) {
    return 'unknown_expr' unless $expr && blessed($expr);

    if ($expr->isa('FSM::CoreAST::Literal')) {
        return $expr->value;
    } elsif ($expr->isa('FSM::CoreAST::SignalRef')) {
        return $expr->signal->name;
    } elsif ($expr->isa('FSM::CoreAST::BinaryOp')) {
        my $left = $self->extract_rhs_capture_value($expr->left);
        my $right = $self->extract_rhs_capture_value($expr->right);
        return "$left " . $expr->operator . " $right";
    } elsif ($expr->isa('FSM::CoreAST::Concatenation')) {
        my @operand_strings;
        for my $operand (@{$expr->operands}) {
            push @operand_strings, $self->extract_rhs_capture_value($operand);
        }
        return '{' . join(', ', @operand_strings) . '}';
    }

    my $expr_type = ref($expr);
    $expr_type =~ s/^.*:://;
    return lc($expr_type) . '_expr';
}
sub extract_signal_name_from_ast($self, $signal_ast) {
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
        if ($sv_repr && $sv_repr =~ /^([a-zA-Z_][a-zA-Z0-9_]*)/) {
            return $1;
        }
    }
    
    return undef;
}
sub extract_intermediate_signals_from_ast($self, $ast) {
    my @signal_names;
    my %seen_node_ids;
    my %seen_signal_names;
    $self->_collect_intermediate_signals_from_ast($ast, \@signal_names, \%seen_node_ids, \%seen_signal_names);

    my $summary = @signal_names ? join(', ', @signal_names) : 'none';
    fsm_debug("[EnableGraph.pm][extract_intermediate_signals_from_ast()] Extracted " . scalar(@signal_names) . " intermediate signal(s): $summary", 3);
    return @signal_names;
}
sub _collect_intermediate_signals_from_ast($self, $ast, $signal_names, $seen_node_ids, $seen_signal_names) {
    return unless $ast && blessed($ast);

    my $node_id = sprintf('%p', $ast);
    return if $seen_node_ids->{$node_id}++;

    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        my $signal_name = eval { $ast->signal_name } || $ast->{signal_name};
        if (defined($signal_name) && $signal_name ne '' && !$seen_signal_names->{$signal_name}++) {
            push @$signal_names, $signal_name;
            fsm_debug("[EnableGraph.pm][_collect_intermediate_signals_from_ast()] Found direct intermediate ref '$signal_name'", 3);
        }
        return;
    }

    if ($ast->isa('FSM::AST::SignalRef') ||
        $ast->isa('FSM::CoreAST::SignalRef') ||
        $ast->isa('FSM::AST::IndexedRef') ||
        $ast->isa('FSM::CoreAST::IndexedRef')) {
        my $signal_name = $self->extract_signal_name_from_ast($ast);
        if (defined($signal_name) && $signal_name ne '' && $self->is_intermediate_signal($signal_name)) {
            if (!$seen_signal_names->{$signal_name}++) {
                push @$signal_names, $signal_name;
                fsm_debug("[EnableGraph.pm][_collect_intermediate_signals_from_ast()] Found intermediate signal ref '$signal_name'", 3);
            }
        }
    }

    for my $accessor (qw(left right operand condition true_expr false_expr index expression)) {
        next unless $ast->can($accessor);
        my $child = eval { $ast->$accessor() };
        next unless $child && blessed($child);
        $self->_collect_intermediate_signals_from_ast($child, $signal_names, $seen_node_ids, $seen_signal_names);
    }

    for my $accessor (qw(operands children arguments expressions parts)) {
        next unless $ast->can($accessor);
        my $children = eval { $ast->$accessor() };
        next unless ref($children) eq 'ARRAY';
        for my $child (@$children) {
            next unless $child && blessed($child);
            $self->_collect_intermediate_signals_from_ast($child, $signal_names, $seen_node_ids, $seen_signal_names);
        }
    }
}
sub get_reset_value_from_ast($self, $lhs_ast) {
    # AST WEB: Get reset value using direct AST queries
    my $ctx = $self->{flattened_dt};
    
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
sub get_default_value_from_ast($self, $lhs_ast) {
    # AST WEB: Get default value using direct AST queries
    # DEBUG: Check what type of object we have
    my $ctx = $self->{flattened_dt};
    
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
sub is_intermediate_signal($self, $signal_name) {
    # Determine if a signal is an intermediate signal that needs to be declared
    # USES AST-BASED OPERATOR TYPE CHECKING - No string pattern matching!
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("IS_INTERMEDIATE_SIGNAL: Checking '$signal_name'", 3);
    
    # Check against our intermediate signals registry first (highest priority)
    if (exists $ctx->{intermediate_signals}->{$signal_name}) {
        fsm_debug("  -> YES: Found in intermediate_signals registry", 3);
        return 1;
    }
    if (exists $ctx->{global_expressions}->{$signal_name}) {
        fsm_debug("  -> YES: Found in global_expressions registry", 3);
        return 1;
    }
    
    # Check if this signal is tracked in AST factorization results
    if ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{intermediate_signals}) {
        if (exists $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name}) {
            fsm_debug("  -> YES: Found in AST factorizer results", 3);
            return 1;
        }
    }
    
    # Check if this signal has been pre-scanned as needing declaration
    if ($ctx->{referenced_intermediate_signals} && exists $ctx->{referenced_intermediate_signals}->{$signal_name}) {
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
sub is_signal_ast_based_intermediate($self, $signal_name) {
    # AST-BASED INTERMEDIATE SIGNAL DETECTION
    # This method replaces string-based pattern matching with proper AST analysis
    # to determine if a signal represents an intermediate signal from an AST operation.
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("AST_INTERMEDIATE_CHECK: Checking if '$signal_name' is an AST-based intermediate signal", 3);
    
    # METHOD 1: Check if this signal was generated by AST factorization
    if ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{intermediate_signals}) {
        if (exists $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name}) {
            my $signal_info = $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name};
            
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
    
    # METHOD 2: Check native AST-backed registry/module sources
    my $native_ast = $self->_get_native_intermediate_signal_ast($signal_name);
    if ($native_ast && blessed($native_ast)) {
        my $contains_operators = $self->_ast_contains_factorizable_operators($native_ast);
        if ($contains_operators) {
            fsm_debug("  AST_INTERMEDIATE: Signal '$signal_name' resolved to native AST with operators - INTERMEDIATE", 3);
            return 1;
        }
    }
    
    # METHOD 3: Check if this signal appears in any of our AST-based registries
    # that track intermediate signals with operator metadata
    if ($ctx->{expression_usage} && exists $ctx->{expression_usage}->{$signal_name}) {
        # Signal is tracked in expression usage - could be intermediate
        # Check if we can find associated operator information
        my $usage_count = $ctx->{expression_usage}->{$signal_name};
        if ($usage_count > 1) {
            # Multi-use signals are typically intermediate signals
            fsm_debug("  AST_INTERMEDIATE: Signal '$signal_name' is multi-use ($usage_count times) - LIKELY INTERMEDIATE", 3);
            return 1;
        }
    }
    
    fsm_debug("  AST_INTERMEDIATE: Signal '$signal_name' shows no AST-based operator indicators - NOT INTERMEDIATE", 3);
    return 0;
}
sub _signal_name_indicates_ast_operators($self, $signal_name) {
    # PURE AST-BASED APPROACH: NO STRING PATTERN MATCHING ALLOWED!
    # This method should ONLY use AST metadata and operator type information,
    # never string patterns or heuristics based on signal names.
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("\n*** _signal_name_indicates_ast_operators: Analyzing signal '$signal_name' ***", 3);
    fsm_debug("    AST_NAME_PATTERN: Using PURE AST metadata approach - no string patterns!", 3);
    
    # SINGLE METHOD: Check if this signal name appears in our AST-generated signal registry
    # These are signals that were created directly from AST factorization with full metadata
    # This registry is populated during the factorization phase - NO late-stage signal generation!
    fsm_debug("    CHECKING REGISTRY #1: global_expressions (AST factorization registry)", 3);
    if ($ctx->{global_expressions}) {
        fsm_debug("      Registry has " . scalar(keys %{$ctx->{global_expressions}}) . " entries", 3);
        for my $expr (keys %{$ctx->{global_expressions}}) {
            if ($ctx->{global_expressions}->{$expr} eq $signal_name) {
                fsm_debug("      FOUND: Signal '$signal_name' maps to expression: '$expr'", 3);
                # Found the expression that maps to this signal name
                # Parse it back to AST to check for factorizable operators
                my $ast = eval { $ctx->{expr_namer}->parse_expression($expr) } if $ctx->{expr_namer};
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
    if ($ctx->{fsm_module} && $ctx->{fsm_module}->can('signals') && $ctx->{fsm_module}->signals) {
        my $signals = $ctx->{fsm_module}->signals;
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
            if ($dump =~ /is_intermediate[\s=>'\"]*([^,}\s'\"]+)/) {
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
        if (!$ctx->{fsm_module}) {
            fsm_debug("        Reason: fsm_module is not set", 3);
        } elsif (!$ctx->{fsm_module}->can('signals')) {
            fsm_debug("        Reason: fsm_module doesn't have signals method", 3);
        } elsif (!$ctx->{fsm_module}->signals) {
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
sub ast_to_systemverilog($self, $ast) {
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
sub _ast_to_systemverilog_internal($self, $ast, $parent_precedence) {
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
sub _render_binary_op($self, $ast, $parent_precedence) {
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
sub _get_operator_precedence($self, $operator) {
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
sub _choose_operator_symbol($self, $operator, $left, $right) {
    # Choose between logical and bitwise operators based on operand analysis
    
    fsm_debug("_choose_operator_symbol: Entering with operator '$operator'", 3);
    
    my $ctx = $self->{flattened_dt};
    my $left_name = undef;
    my $right_name = undef;
    my $left_width = undef;
    my $right_width = undef;
    
    # Extract signal names using robust helper function
    if ($left && blessed($left)) {
        $left_name = $self->extract_signal_name_from_ast($left);
        if ($left_name) {
            fsm_debug("_choose_operator_symbol: Extracted left signal name: '$left_name'", 3);
            if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals) {
                fsm_debug("_choose_operator_symbol: FSM module has " . scalar(keys %{$ctx->{fsm_module}->signals}) . " signals", 3);
                if ($ctx->{fsm_module}->signals->{$left_name}) {
                    my $sig = $ctx->{fsm_module}->signals->{$left_name};
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
                    my @available = keys %{$ctx->{fsm_module}->signals};
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
            if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals) {
                if ($ctx->{fsm_module}->signals->{$right_name}) {
                    my $sig = $ctx->{fsm_module}->signals->{$right_name};
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
sub _needs_parentheses($self, $my_precedence, $parent_precedence) {
    # Need parentheses if my precedence is lower than parent's
    return 0 unless defined $parent_precedence;
    return $my_precedence < $parent_precedence;
}
sub _map_binary_operator($self, $operator) {
    # Standard operator symbol mapping
    my %op_map = (
        'eq' => '==', 'ne' => '!=', 'lt' => '<', 'gt' => '>', 'le' => '<=', 'ge' => '>=',
        'add' => '+', 'sub' => '-', 'mul' => '*', 'div' => '/', 'mod' => '%',
        'and' => '&', 'or' => '|', 'xor' => '^',
        'shl' => '<<', 'shr' => '>>', 'sal' => '<<<', 'sar' => '>>>'
    );
    return $op_map{$operator} || $operator;
}
sub _signal_is_single_bit($self, $name) {
    fsm_debug("    SIGNAL_IS_1BIT: Checking if signal '$name' is single-bit", 3);
    
    unless (defined $name) {
        fsm_debug("      RESULT: NOT single-bit (undefined name)", 3);
        return 0;
    }
    
    my $ctx = $self->{flattened_dt};
    
    # Check FSM module signal info if available
    if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals && $ctx->{fsm_module}->signals->{$name}) {
        fsm_debug("      PATH: Found signal in FSM module", 3);
        my $signal = $ctx->{fsm_module}->signals->{$name};
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
        if (!$ctx->{fsm_module}) {
            fsm_debug("        Reason: No FSM module available", 3);
        } elsif (!$ctx->{fsm_module}->signals) {
            fsm_debug("        Reason: FSM module has no signals", 3);
        } else {
            fsm_debug("        Reason: Signal '$name' not in FSM module signals", 3);
            # Debug: list available signals
            my @available = keys %{$ctx->{fsm_module}->signals};
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
sub _operand_is_single_bit($self, $ast) {
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
sub _render_unary_op($self, $ast) {
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
sub _map_unary_operator($self, $operator) {
    my %op_map = ( 'not' => '!', 'neg' => '-', 'pos' => '+' );
    return $op_map{$operator} || $operator;
}
sub _operand_needs_parens_for_negation($self, $operand) {
    # Only complex expressions need parentheses after negation
    return 0 unless $operand && blessed($operand);
    
    # Simple signals and literals don't need parens
    return 0 if $operand->isa('FSM::AST::SignalRef') || $operand->isa('FSM::CoreAST::SignalRef');
    return 0 if $operand->isa('FSM::AST::Literal') || $operand->isa('FSM::CoreAST::Literal');
    return 0 if $operand->isa('FSM::AST::IndexedRef') || $operand->isa('FSM::CoreAST::IndexedRef');
    
    # Complex expressions need parens
    return 1;
}
sub _ast_contains_factorizable_operators($self, $ast) {
    # Check if an AST contains operators that would qualify it as an intermediate signal
    # This uses the same logic as the AST factorization to determine if expressions
    # should be factored into intermediate signals.
    my $ctx = $self->{flattened_dt};
    
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
sub is_arithmetic_operation($self, $ast) {
    # Check if an AST node represents an arithmetic operation
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 0 unless $ast->can('operator');
    
    my $op = $ast->operator || '';
    return $op =~ /^[\+\-\*\/\%\<<\>>]$/;
}
sub is_logical_operation($self, $ast) {
    # Check if an AST node represents a logical operation
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 0 unless $ast->can('operator');
    
    my $op = $ast->operator || '';
    return $op =~ /^(&&|\|\||&|\|)$/;
}
sub should_factor_logical_operation($self, $ast) {
    # Determine if a logical operation should be factored based on occurrence count
    return 0 unless $self->is_logical_operation($ast);
    
    # FIXED: Check if ANY of the sub-operations in this expression appears multiple times
    # instead of looking for the exact compound expression
    return $self->contains_frequently_used_operations($ast);
}
sub contains_frequently_used_operations($self, $ast, $visited_signal_names = undef) {
    # AST-first check for whether this AST contains any frequently used operations.
    # This now prefers direct AST traversal and only falls back to expression parsing
    # when no AST source exists yet for a referenced intermediate signal.
    my $ctx = $self->{flattened_dt};
    return 0 unless $ast && blessed($ast);
    return 0 unless exists $ctx->{binary_logical_op_counts};
    
    $visited_signal_names //= {};

    my $result = $self->_ast_contains_frequently_used_logical_operation($ast, $visited_signal_names);
    my $ast_str = eval { $self->ast_to_systemverilog($ast) } || eval { $ast->to_systemverilog() } || ref($ast) || 'unknown_ast';

    if ($result) {
        fsm_debug("[EnableGraph.pm][contains_frequently_used_operations()] Expression '$ast_str' contains high-count logical operations - FACTOR", 3);
    } else {
        fsm_debug("[EnableGraph.pm][contains_frequently_used_operations()] Expression '$ast_str' contains no high-count logical operations - DON'T FACTOR", 3);
    }

    return $result;
}
sub _ast_contains_frequently_used_logical_operation($self, $ast, $visited_signal_names) {
    my $ctx = $self->{flattened_dt};
    return 0 unless $ast && blessed($ast);
    return 0 unless exists $ctx->{binary_logical_op_counts};

    if ($self->is_logical_operation($ast)) {
        my $signature = eval { $ast->to_systemverilog() } || eval { $self->ast_to_systemverilog($ast) } || '';
        my $count = $ctx->{binary_logical_op_counts}{$signature} || 0;
        if ($count > 1) {
            fsm_debug("[EnableGraph.pm][_ast_contains_frequently_used_logical_operation()] Found high-count logical op '$signature' ($count uses)", 3);
            return 1;
        }
    }

    my $signal_name;
    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        $signal_name = eval { $ast->signal_name } || $ast->{signal_name};
    } elsif ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        $signal_name = $self->extract_signal_name_from_ast($ast);
    }

    if (defined $signal_name && $signal_name ne '' && $self->is_intermediate_signal($signal_name)) {
        if ($visited_signal_names->{$signal_name}) {
            fsm_debug("[EnableGraph.pm][_ast_contains_frequently_used_logical_operation()] Skipping already-visited intermediate '$signal_name' to avoid recursion", 3);
        } else {
            $visited_signal_names->{$signal_name} = 1;
            my $intermediate_ast = $self->get_intermediate_signal_ast($signal_name);
            if ($intermediate_ast && blessed($intermediate_ast)) {
                fsm_debug("[EnableGraph.pm][_ast_contains_frequently_used_logical_operation()] Descending into intermediate '$signal_name' AST", 3);
                if ($self->_ast_contains_frequently_used_logical_operation($intermediate_ast, $visited_signal_names)) {
                    delete $visited_signal_names->{$signal_name};
                    return 1;
                }
            }
            delete $visited_signal_names->{$signal_name};
        }
    }

    for my $accessor (qw(left right operand)) {
        next unless $ast->can($accessor);
        my $child = eval { $ast->$accessor() };
        next unless $child && blessed($child);
        return 1 if $self->_ast_contains_frequently_used_logical_operation($child, $visited_signal_names);
    }

    for my $accessor (qw(operands children)) {
        next unless $ast->can($accessor);
        my $children = eval { $ast->$accessor() };
        next unless ref($children) eq 'ARRAY';
        for my $child (@$children) {
            next unless $child && blessed($child);
            return 1 if $self->_ast_contains_frequently_used_logical_operation($child, $visited_signal_names);
        }
    }

    return 0;
}
sub get_intermediate_signal_ast($self, $signal_name) {
    # Resolve an intermediate signal back to its defining AST, preferring native AST sources.
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';
    my $native_ast = $self->_get_native_intermediate_signal_ast($signal_name);
    if ($native_ast && blessed($native_ast)) {
        return $native_ast;
    }

    my $registry_entry = $self->_get_intermediate_signal_registry_entry($signal_name);
    if ($registry_entry && defined($registry_entry->{expression}) && $registry_entry->{expression} ne '') {
        my $ast = $self->_parse_intermediate_expression_to_ast(
            $registry_entry->{expression},
            $signal_name,
            $registry_entry->{source} || 'intermediate_signals',
        );
        return $ast if $ast;
    }

    if ($ctx->{global_expressions}) {
        for my $expr (keys %{$ctx->{global_expressions}}) {
            next unless $ctx->{global_expressions}->{$expr} eq $signal_name;
            my $ast = $self->_parse_intermediate_expression_to_ast($expr, $signal_name, 'global_expressions');
            return $ast if $ast;
            last;
        }
    }

    fsm_debug("[EnableGraph.pm][get_intermediate_signal_ast()] No defining AST found for '$signal_name'", 3);
    return undef;
}
sub _parse_intermediate_expression_to_ast($self, $expression, $signal_name, $source_name) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($expression) && $expression ne '';

    unless ($ctx->{expr_namer} && $ctx->{expr_namer}->can('parse_expression')) {
        fsm_debug("[EnableGraph.pm][_parse_intermediate_expression_to_ast()] No expr_namer parser available for '$signal_name' from $source_name", 3);
        return undef;
    }

    my $ast = eval { $ctx->{expr_namer}->parse_expression($expression) };
    if ($ast && blessed($ast)) {
        $self->_register_intermediate_signal_registry_entry(
            $signal_name,
            ast => $ast,
            expression => $expression,
            source => $source_name,
        );
        fsm_debug("[EnableGraph.pm][_parse_intermediate_expression_to_ast()] Parsed compatibility expression for '$signal_name' from $source_name", 3);
        return $ast;
    }

    my $error = $@;
    chomp $error if defined $error;
    fsm_debug("[EnableGraph.pm][_parse_intermediate_expression_to_ast()] Failed to parse compatibility expression for '$signal_name' from $source_name: " . ($error || 'unknown parse failure'), 3);
    return undef;
}
sub get_intermediate_signal_expression($self, $signal_name) {
    # Get the expression for an intermediate signal from various sources
    my $ctx = $self->{flattened_dt};

    my $ast = $self->get_intermediate_signal_ast($signal_name);
    if ($ast && blessed($ast)) {
        my $expression = $self->ast_to_systemverilog($ast);
        fsm_debug("[EnableGraph.pm][get_intermediate_signal_expression()] Rendering '$signal_name' from defining AST", 3);
        return $expression;
    }
    
    # Check the intermediate_signals registry
    my $registry_entry = $self->_get_intermediate_signal_registry_entry($signal_name);
    if ($registry_entry && defined($registry_entry->{expression}) && $registry_entry->{expression} ne '') {
        return $registry_entry->{expression};
    }
    
    # Check global expressions registry
    for my $expr (keys %{$ctx->{global_expressions}}) {
        if ($ctx->{global_expressions}->{$expr} eq $signal_name) {
            return $expr;
        }
    }
    
    fsm_debug("[EnableGraph.pm][get_intermediate_signal_expression()] No AST-backed or registered expression found for '$signal_name'", 3);
    return undef;
}
sub _signal_name_supports_dependency_ast_recovery($self, $signal_name) {
    my $ctx = $self->{flattened_dt};
    return 0 unless defined($signal_name) && $signal_name ne '';

    if ($ctx->{ast_factorizer}
        && $ctx->{ast_factorizer}->{intermediate_signals}
        && exists $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name})
    {
        fsm_debug("[EnableGraph.pm][_signal_name_supports_dependency_ast_recovery()] '$signal_name' is tracked by AST factorization", 3);
        return 1;
    }

    my $registry_entry = $self->_get_intermediate_signal_registry_entry($signal_name);
    if ($registry_entry) {
        my $source = $registry_entry->{source} || 'unknown';
        if ($source eq 'ast_signal_name' || $source eq 'global_expression') {
            fsm_debug("[EnableGraph.pm][_signal_name_supports_dependency_ast_recovery()] '$signal_name' is AST-named via $source", 3);
            return 1;
        }
        if ($source eq 'legacy_string_registry') {
            fsm_debug("[EnableGraph.pm][_signal_name_supports_dependency_ast_recovery()] '$signal_name' is a legacy registry signal eligible for conservative signal-name AST recovery", 3);
            return 1;
        }
    }

    fsm_debug("[EnableGraph.pm][_signal_name_supports_dependency_ast_recovery()] '$signal_name' has no AST-name metadata for dependency recovery", 3);
    return 0;
}
sub _map_signal_name_operator_to_ast_symbol($self, $operator_name) {
    my %operator_map = (
        and   => '&&',
        or    => '||',
        eq    => '==',
        ne    => '!=',
        lt    => '<',
        gt    => '>',
        le    => '<=',
        ge    => '>=',
        plus  => '+',
        minus => '-',
        mult  => '*',
        div   => '/',
    );

    return $operator_map{$operator_name};
}
sub _find_dependency_recovery_signal_name_split($self, $signal_name) {
    return unless defined($signal_name) && $signal_name ne '';

    my @operator_names = qw(and or eq ne le ge lt gt plus minus mult div);
    my $best_candidate;

    for my $operator_name (@operator_names) {
        my $needle = '_' . $operator_name . '_';
        my $offset = -1;
        while (1) {
            $offset = index($signal_name, $needle, $offset + 1);
            last if $offset < 0;

            my $left_name = substr($signal_name, 0, $offset);
            my $right_name = substr($signal_name, $offset + length($needle));
            next if $left_name eq '' || $right_name eq '';

            my $left_is_intermediate = $self->is_intermediate_signal($left_name) ? 1 : 0;
            my $right_is_intermediate = $self->is_intermediate_signal($right_name) ? 1 : 0;
            my $score = $left_is_intermediate + $right_is_intermediate;
            next unless $score > 0;

            my $known_length = 0;
            $known_length += length($left_name) if $left_is_intermediate;
            $known_length += length($right_name) if $right_is_intermediate;

            my $candidate = {
                operator_name => $operator_name,
                left_name => $left_name,
                right_name => $right_name,
                score => $score,
                known_length => $known_length,
            };

            if (!$best_candidate
                || $candidate->{score} > $best_candidate->{score}
                || ($candidate->{score} == $best_candidate->{score}
                    && $candidate->{known_length} > $best_candidate->{known_length}))
            {
                $best_candidate = $candidate;
            }
        }
    }

    if ($best_candidate) {
        fsm_debug(
            "[EnableGraph.pm][_find_dependency_recovery_signal_name_split()] '$signal_name' split as "
            . "$best_candidate->{left_name} _$best_candidate->{operator_name}_ $best_candidate->{right_name}",
            3,
        );
        return @{$best_candidate}{qw(operator_name left_name right_name)};
    }

    fsm_debug("[EnableGraph.pm][_find_dependency_recovery_signal_name_split()] No dependency-oriented split found for '$signal_name'", 3);
    return;
}
sub _build_dependency_recovery_operand_ast($self, $signal_name, $seen_signal_names) {
    return undef unless defined($signal_name) && $signal_name ne '';

    if ($self->is_intermediate_signal($signal_name)) {
        fsm_debug("[EnableGraph.pm][_build_dependency_recovery_operand_ast()] Preserving direct intermediate dependency '$signal_name'", 3);
        return FSM::AST::SignalRef->new($signal_name);
    }

    my $nested_ast = $self->build_dependency_recovery_ast_from_signal_name($signal_name, $seen_signal_names, 0);
    if ($nested_ast && blessed($nested_ast)) {
        fsm_debug("[EnableGraph.pm][_build_dependency_recovery_operand_ast()] Built nested dependency AST for '$signal_name'", 3);
        return $nested_ast;
    }

    fsm_debug("[EnableGraph.pm][_build_dependency_recovery_operand_ast()] Treating '$signal_name' as opaque leaf during dependency recovery", 3);
    return FSM::AST::SignalRef->new($signal_name);
}
sub build_dependency_recovery_ast_from_signal_name($self, $signal_name, $seen_signal_names = undef, $is_root = 1) {
    return undef unless defined($signal_name) && $signal_name ne '';

    $seen_signal_names //= {};
    if ($seen_signal_names->{$signal_name}++) {
        fsm_debug("[EnableGraph.pm][build_dependency_recovery_ast_from_signal_name()] Skipping recursive signal-name recovery for '$signal_name'", 3);
        return undef;
    }

    if ($is_root && !$self->_signal_name_supports_dependency_ast_recovery($signal_name)) {
        delete $seen_signal_names->{$signal_name};
        return undef;
    }

    my $candidate_ast;
    if ($signal_name eq 'const_1') {
        $candidate_ast = FSM::AST::Literal->new("1'b1");
    } elsif ($signal_name eq 'const_0') {
        $candidate_ast = FSM::AST::Literal->new("1'b0");
    } elsif ($signal_name =~ /^not_(.+)$/) {
        my $operand_name = $1;
        my $operand_ast = $self->_build_dependency_recovery_operand_ast($operand_name, $seen_signal_names);
        if ($operand_ast && blessed($operand_ast)) {
            $candidate_ast = FSM::AST::UnaryOp->new('!', $operand_ast);
        }
    } else {
        my ($operator_name, $left_name, $right_name) = $self->_find_dependency_recovery_signal_name_split($signal_name);
        if (defined($operator_name) && defined($left_name) && defined($right_name)) {
            my $left_ast = $self->_build_dependency_recovery_operand_ast($left_name, $seen_signal_names);
            my $right_ast = $self->_build_dependency_recovery_operand_ast($right_name, $seen_signal_names);
            my $operator_symbol = $self->_map_signal_name_operator_to_ast_symbol($operator_name);
            if ($left_ast && blessed($left_ast)
                && $right_ast && blessed($right_ast)
                && defined($operator_symbol) && $operator_symbol ne '')
            {
                $candidate_ast = FSM::AST::BinaryOp->new($operator_symbol, $left_ast, $right_ast);
            }
        }
    }

    delete $seen_signal_names->{$signal_name};
    return undef unless $candidate_ast && blessed($candidate_ast);

    my @dependencies = $self->extract_intermediate_signals_from_ast($candidate_ast);
    unless (@dependencies) {
        fsm_debug("[EnableGraph.pm][build_dependency_recovery_ast_from_signal_name()] '$signal_name' produced no direct intermediate dependencies", 3);
        return undef;
    }

    my $summary = join(', ', @dependencies);
    fsm_debug("[EnableGraph.pm][build_dependency_recovery_ast_from_signal_name()] '$signal_name' recovered direct dependencies via signal-name AST: $summary", 3);
    return $candidate_ast;
}
sub track_ast_intermediate_signals($self, $ast) {
    # Recursively traverse an AST and track all intermediate signals that need to be declared
    my $ctx = $self->{flattened_dt};
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
            my $existing = $ctx->{referenced_intermediate_signals}->{$signal_name} || {};
            my $defining_ast = $existing->{defining_ast};
            if ((!$defining_ast || !blessed($defining_ast))) {
                $defining_ast = $self->_get_native_intermediate_signal_ast($signal_name);
            }

            $ctx->{referenced_intermediate_signals}->{$signal_name} = {
                %$existing,
                name => $signal_name,
                reference_ast => $ast,
                ($defining_ast && blessed($defining_ast) ? (defining_ast => $defining_ast) : ()),
                needs_declaration => 1
            };
            if ($defining_ast && blessed($defining_ast)) {
                fsm_debug("TRACK_INTERMEDIATE: Found intermediate signal with native defining AST: $signal_name", 3);
            } else {
                fsm_debug("TRACK_INTERMEDIATE: Found intermediate signal without native defining AST yet: $signal_name", 3);
            }
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
sub group_assignments_by_rhs($self, $lhs) {
    my $ctx = $self->{flattened_dt};
    my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
    
    fsm_debug("  [EnableGraph.pm][group_assignments_by_rhs()] Grouping assignments by RHS value:", 3);
    
    for my $assignment (@{$lhs_analysis->{assignments}}) {
        my $rhs = $assignment->{rhs};
        my $dt = $assignment->{dt};
        my $conditions = $assignment->{conditions} || 'NONE';
        my $conditions_ast = $assignment->{conditions_ast};
        
        # Initialize RHS group if not exists
        unless (exists $lhs_analysis->{rhs_groups}->{$rhs}) {
            $lhs_analysis->{rhs_groups}->{$rhs} = {
                assignments => [],
                dt_specific_enables => [],
                lhs_level_enable => undef,
                multiplexer_info => undef,
            };
        }
        
        # Add assignment to RHS group
        push @{$lhs_analysis->{rhs_groups}->{$rhs}->{assignments}}, $assignment;
        
        # Debug with proper handling of both old and new condition formats
        my $debug_condition = $conditions;
        if ($conditions_ast && blessed($conditions_ast) && $conditions_ast->can('to_systemverilog')) {
            $debug_condition = $conditions_ast->to_systemverilog();
        }
        fsm_debug("    [EnableGraph.pm] RHS '$rhs' from DT '$dt' with condition '$debug_condition'", 3);
    }
    
    my $rhs_count = scalar(keys %{$lhs_analysis->{rhs_groups}});
    fsm_debug("  [EnableGraph.pm] Grouped into $rhs_count unique RHS values", 3);
}

sub generate_complete_enable_structure($self, $lhs) {
    my $ctx = $self->{flattened_dt};
    my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
    
    fsm_debug("  [EnableGraph.pm][generate_complete_enable_structure()] Generating complete enable structure:", 3);
    
    # Group assignments by DT first for DT-specific enables
    my %dt_assignments;
    for my $assignment (@{$lhs_analysis->{assignments}}) {
        my $dt_name = $assignment->{dt};
        my $rhs = $assignment->{rhs};
        
        $dt_assignments{$dt_name} //= {};
        $dt_assignments{$dt_name}{$rhs} //= [];
        push @{$dt_assignments{$dt_name}{$rhs}}, $assignment;
    }
    
    # Generate DT-specific enables for each DT/RHS combination
    for my $dt_name (sort keys %dt_assignments) {
        my $clean_dt_name = $dt_name;
        $clean_dt_name =~ s/^-//;  # Remove leading dash for standalone DTs
        
        # Get DT enable signal
        my $dt_enable;
        if ($ctx->{state_enables}->{$dt_name}) {
            $dt_enable = "${dt_name}_en";
        } elsif ($ctx->{dt_enables}->{$dt_name}) {
            $dt_enable = "${clean_dt_name}_en";
        } else {
            $dt_enable = "1'b1";
        }
        
        for my $rhs (sort keys %{$dt_assignments{$dt_name}}) {
            my $assignments = $dt_assignments{$dt_name}{$rhs};
            
            # Create OR of all conditions for this DT/LHS/RHS combination AS AST
            my @condition_asts;
            for my $assignment (@$assignments) {
                # The conditions are ASTs, not strings
                push @condition_asts, $assignment->{conditions_ast} if $assignment->{conditions_ast};
            }
            
            # Build OR tree of condition ASTs
            my $or_tree_of_conditions_ast;
            if (!@condition_asts) {
                # If there are no conditions, this enable depends only on the DT enable
                $or_tree_of_conditions_ast = FSM::AST::Utils::literal("1'b1");
            } elsif (@condition_asts == 1) {
                $or_tree_of_conditions_ast = $condition_asts[0];
            } else {
                $or_tree_of_conditions_ast = FSM::AST::Utils::or_tree(@condition_asts);
            }
            
            # Build complete enable expression as AST: dt_enable && conditions
            my $dt_enable_ast = FSM::AST::Utils::signal_ref($dt_enable);
            my $complete_enable_ast = FSM::AST::Utils::and_op($dt_enable_ast, $or_tree_of_conditions_ast);
            
            # Generate DT-specific enable signal name
            my $clean_rhs = $self->clean_signal_name($rhs);
            my $clean_lhs = $self->clean_signal_name($lhs);
            my $dt_enable_name = "${clean_dt_name}_${clean_lhs}_${clean_rhs}_en";
            
            # Store DT-specific enable info
            my $dt_enable_info = {
                dt => $dt_name,
                enable_name => $dt_enable_name,
                enable_ast => $complete_enable_ast,  # Store AST instead of string
                shared_signal => undef,              # Filled if sharing is detected
            };
            
            push @{$lhs_analysis->{rhs_groups}->{$rhs}->{dt_specific_enables}}, $dt_enable_info;
            
            # Debug with SystemVerilog conversion for display only
            my $debug_expr = $complete_enable_ast->to_systemverilog();
            fsm_debug("    [EnableGraph.pm] DT-specific enable: $dt_enable_name = $debug_expr", 3);
        }
    }
    
    # Generate LHS-level enables for each RHS
    for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
        my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
        
        # Create OR expression of all DT-specific enables for this RHS as AST
        my @dt_enable_asts;
        for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
            push @dt_enable_asts, FSM::AST::Utils::signal_ref($dt_enable_info->{enable_name});
        }
        
        # Build OR tree AST for all DT-specific enables
        my $lhs_enable_ast;
        if (@dt_enable_asts == 1) {
            $lhs_enable_ast = $dt_enable_asts[0];
        } else {
            $lhs_enable_ast = FSM::AST::Utils::or_tree(@dt_enable_asts);
        }
        
        # Generate meaningful LHS-level enable name based on RHS
        my $lhs_enable_name = $self->generate_rhs_based_enable_name($lhs, $rhs);
        
        # Store LHS-level enable info with AST
        $rhs_group->{lhs_level_enable} = {
            name => $lhs_enable_name,
            ast => $lhs_enable_ast,
            rhs_value => $rhs,
        };
        
        # Debug with SystemVerilog conversion for display only
        my $debug_expr = blessed($lhs_enable_ast) && $lhs_enable_ast->can('to_systemverilog')
            ? $lhs_enable_ast->to_systemverilog()
            : 'UNAVAILABLE';
        fsm_debug("    [EnableGraph.pm] LHS-level enable: $lhs_enable_name = $debug_expr", 3);
    }
}
sub build_multiplexer_config($self, $lhs) {
    my $ctx = $self->{flattened_dt};
    my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
    my $lhs_ast = $lhs_analysis->{lhs_ast};  # Get AST node for direct queries
    
    # AST WEB: Get signal name for debugging
    my $lhs_name = blessed($lhs_ast) && $lhs_ast->can('name') ? $lhs_ast->name() : 'UNKNOWN';
    
    # Collect all enable/value pairs for the multiplexer
    my @mux_enables = ();
    my $priority = 0;
    
    for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
        my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
        my $lhs_enable = $rhs_group->{lhs_level_enable};
        
        # Store multiplexer enable info
        $rhs_group->{multiplexer_info} = {
            enable_signal => $lhs_enable->{name},
            rhs_value => $rhs,
            priority => $priority++,
        };
        
        push @mux_enables, $rhs_group->{multiplexer_info};
    }
    
    # Determine multiplexer type using direct AST method calls
    my $is_register = $self->is_register($lhs_ast, $lhs_name);
    my $mux_type = $is_register ? 'flop' : 'comb';
    
    # Get default value using direct AST method calls
    my $default_value = $self->get_default_value_from_ast($lhs_ast);
    
    # Build complete multiplexer configuration
    $lhs_analysis->{multiplexer} = {
        type => $mux_type,
        enables => \@mux_enables,
        default_value => $default_value,
    };
    
    fsm_debug("  [EnableGraph.pm][build_multiplexer_config()] Multiplexer: type=$lhs_analysis->{multiplexer}->{type}, " . scalar(@mux_enables) . " enables", 3);
}
sub is_register($self, $lhs_signal_ast, $lhs_name_for_debug) {
    # Determine if this signal AST node should be implemented as a register
    # Uses the signal AST node as the single source of truth
    my $ctx = $self->{flattened_dt};
    
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
sub fallback_register_analysis_from_assignments($self, $lhs_name) {
    # Fallback register analysis based on assignment patterns
    # This is used when the signal AST node doesn't have explicit register attributes
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("  FALLBACK_REGISTER_ANALYSIS: Analyzing assignment patterns for '$lhs_name'", 3);
    
    # Analyze assignment patterns to determine signal behavior
    my $assignments = $ctx->{lhs_assignments}->{$lhs_name} || [];
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
        # Mixed assignments - this is unusual, defaulting to register for safety
        fsm_debug("    Mixed assignments - defaulting to register for safety", 3);
        return 1;
    } else {
        # No clear assignment pattern - default to combinational
        fsm_debug("    No clear assignment pattern - defaulting to combinational", 3);
        return 0;
    }
}
sub clean_signal_name($self, $name) {
    # Clean signal names for use in Verilog identifiers
    $name = lc($name);             # Convert to lowercase for consistent WEN/EN naming
    $name =~ s/[^a-zA-Z0-9_]/_/g;  # Replace non-alphanumeric with underscore
    $name =~ s/__+/_/g;            # Replace multiple consecutive underscores with single underscore
    $name =~ s/^_+//;              # Remove leading underscores
    $name =~ s/_+$//;              # Remove trailing underscores
    
    # Handle special cases for numeric RHS values BEFORE digit prefixing
    # Don't prefix simple numeric values with underscores to avoid double underscores
    if ($name eq '0') {
        return '0';
    } elsif ($name eq '1') {
        return '1';
    }
    
    # Only prefix with underscore if starts with digit (for complex numeric identifiers)
    $name =~ s/^(\d)/_$1/;         # Prefix with underscore if starts with digit
    
    return $name;
}
sub generate_rhs_based_enable_name($self, $lhs, $rhs) {
    my $ctx = $self->{flattened_dt};
    
    # Generate meaningful enable signal names based on RHS expression type
    # Following the naming convention: <LHS>_<RHS_description>_en
    my $clean_lhs = $self->clean_signal_name($lhs);
    my $rhs_suffix;
    
    # Handle different RHS expression types
    if ($rhs =~ /^\d+$/) {
        # Simple numeric values: 0, 1, 42
        $rhs_suffix = $rhs;
        
    } elsif ($rhs =~ /^\d+'[bdhBDH]([0-9a-fA-F_]+)$/) {
        # Sized literals: 8'h00, 16'b1010, etc.
        my $value_part = $1;
        $rhs_suffix = $rhs;
        $rhs_suffix =~ s/'/_/g;  # Replace ' with _ : 8'h00 -> 8_h00
        $rhs_suffix = $self->clean_signal_name($rhs_suffix);
        
    } elsif ($rhs =~ /^([a-zA-Z_][a-zA-Z0-9_]*)\[(\d+):(\d+)\]$/) {
        # Bit slice: signal[7:0], data[15:8]
        my ($signal, $high, $low) = ($1, $2, $3);
        $rhs_suffix = "${signal}_${high}_${low}";
        
    } elsif ($rhs =~ /^([a-zA-Z_][a-zA-Z0-9_]*)\[(\d+)\]$/) {
        # Single bit index: signal[5], enable[0]
        my ($signal, $index) = ($1, $2);
        $rhs_suffix = "${signal}_${index}";
        
    } elsif ($rhs =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) {
        # Simple identifier: signal_name, apb_wrn, const_8b0
        $rhs_suffix = $rhs;
        
    } else {
        # Complex expression: use expression namer to create meaningful name
        my $expr_name = $ctx->{expr_namer}->parse_and_name_expression($rhs);
        # Remove common prefixes/suffixes to keep name concise
        $expr_name =~ s/_expr\d*$//;  # Remove _expr suffix
        $expr_name =~ s/^expr_//;     # Remove expr_ prefix
        $rhs_suffix = $expr_name || "complex";
    }
    
    # Clean the suffix and combine with LHS
    $rhs_suffix = $self->clean_signal_name($rhs_suffix);
    return "${clean_lhs}_${rhs_suffix}_en";
}

1;
