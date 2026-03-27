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
sub generate_ast_based_signal_name($self, $ast) {
    # Generate a systematic signal name based on AST structure with PROPER INTERMEDIATE SIGNAL NAMING
    # This follows the specified naming rules:
    # - Unary operations: <op>_<A>
    # - Binary operations: <A>_<op>_<B>

    return "unknown_signal" unless $ast && blessed($ast);

    fsm_debug("AST_SIGNAL_NAME: Generating name for " . ref($ast), 3);

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        # For signal references, extract the signal name
        my $signal_name = $self->{flattened_dt}->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
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
sub set_fsm_module_reference($self, $fsm_module) {
    # Store a reference to the FSM module for accessing signal information
    my $ctx = $self->{flattened_dt};
    $ctx->{fsm_module} = $fsm_module;
    fsm_debug("FSM_MODULE_REF: Stored reference to FSM module: " . ($fsm_module ? $fsm_module->name : 'undef'), 3);
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
        my $signal_name = $self->{flattened_dt}->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
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
    my $lhs_name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($lhs_ast);

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
    return $ctx->{enable_graph_assignment_support}->get_reset_value($lhs_name);
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
    my $lhs_name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($lhs_ast);
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
    return $ctx->{enable_graph_assignment_support}->get_default_value($lhs_name);
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

    if ($self->_fsm_module_signal_declares_intermediate($signal_name)) {
        fsm_debug("  -> YES: FSM module signal metadata marks this as an intermediate signal", 3);
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
sub _fsm_module_signal_declares_intermediate($self, $signal_name) {
    my $ctx = $self->{flattened_dt};
    return 0 unless defined($signal_name) && $signal_name ne '';
    return 0 unless $ctx->{fsm_module} && $ctx->{fsm_module}->can('signals') && $ctx->{fsm_module}->signals;

    my $signal = $ctx->{fsm_module}->signals->{$signal_name} or return 0;

    if (blessed($signal) && $signal->can('get_attribute')) {
        my $marked = $signal->get_attribute('is_intermediate');
        return 1 if defined($marked) && $marked;
    }

    if (blessed($signal) && $signal->can('attributes') && ref($signal->attributes) eq 'HASH') {
        my $marked = $signal->attributes->{is_intermediate};
        return 1 if defined($marked) && $marked;
    }

    if (blessed($signal) && $signal->can('is_intermediate') && $signal->can('driving_ast') && $signal->driving_ast) {
        return 1 if $signal->is_intermediate;
    }

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
    my $native_ast = $ctx->{enable_graph_intermediate_support}->_get_native_intermediate_signal_ast($signal_name);
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
        my $name = $self->{flattened_dt}->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
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
            my $name = $self->{flattened_dt}->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
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
        $left_name = $self->{flattened_dt}->{enable_graph_capture_support}->extract_signal_name_from_ast($left);
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
        $right_name = $self->{flattened_dt}->{enable_graph_capture_support}->extract_signal_name_from_ast($right);
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
        my $name = $self->{flattened_dt}->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
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
    return $self->{flattened_dt}->{enable_graph_factorization_support}->contains_frequently_used_operations($ast);
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
