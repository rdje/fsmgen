package FSM::ExpressionNamer;

use strict;
use warnings;
use Carp qw(confess);
use v5.20;
use feature 'signatures';
no warnings 'experimental::signatures';

# FSM Expression Naming Strategy - AST Native Version
# This module provides a systematic approach to name complex expressions
# by directly operating on FSM Core AST nodes

# Constructor
sub new($class, %options) {
    return bless {
        _named_expressions => {},  # cache: ast_obj => signal_name (using object reference)
        _named_expression_strings => {}, # cache: expr_string => signal_name (for backward compatibility)
        _signal_definitions => {}, # signal_name => {type, width, definition, ...}
        
        # Naming strategy configuration
        _naming_strategy => $options{naming_strategy} // 'systematic', # 'semantic', 'factorization_aware', 'systematic'
        _max_name_length => $options{max_name_length} // 48,
        _enable_sub_expression_factoring => $options{enable_sub_expression_factoring} // 1,
    }, $class;
}

#========================================================================
# Main Entry Points for AST-based Naming
#========================================================================

# Main entry point for AST-based naming: directly handle FSM Core AST objects
sub name_ast_expression($self, $ast_expr) {
    # Sanity check
    unless (ref($ast_expr)) {
        Carp::confess "name_ast_expression requires an AST node, got a scalar: $ast_expr";
    }
    
    # Handle different AST node types
    if ($ast_expr->isa('FSM::CoreAST::BinaryOp')) {
        return $self->name_binary_op_ast($ast_expr);
    }
    elsif ($ast_expr->isa('FSM::CoreAST::UnaryOp')) {
        return $self->name_unary_op_ast($ast_expr);
    }
    elsif ($ast_expr->isa('FSM::CoreAST::SignalRef')) {
        return $self->name_signal_ref_ast($ast_expr);
    }
    elsif ($ast_expr->isa('FSM::CoreAST::AggregateRef')) {
        my $aggregate_name = $ast_expr->to_systemverilog;
        $aggregate_name =~ s/[^a-zA-Z0-9_]+/_/g;
        $aggregate_name =~ s/^_+|_+$//g;
        return $aggregate_name || 'aggregate_ref';
    }
    elsif ($ast_expr->isa('FSM::CoreAST::Literal')) {
        return $self->name_literal_ast($ast_expr);
    }
    elsif ($ast_expr->isa('FSM::CoreAST::Concatenation')) {
        return $self->name_concatenation_ast($ast_expr);
    }
    elsif ($ast_expr->isa('FSM::CoreAST::IndexedRef')) {
        return $self->name_indexed_ref_ast($ast_expr);
    }
    elsif ($ast_expr->isa('FSM::CoreAST::ConditionalExpression')) {
        return $self->name_conditional_ast($ast_expr);
    }
    elsif ($ast_expr->isa('FSM::CoreAST::FunctionCall')) {
        return $self->name_function_call_ast($ast_expr);
    }
    elsif ($ast_expr->isa('FSM::AST::BinaryOp')) {
        return $self->name_ast_binary_op($ast_expr);
    }
    elsif ($ast_expr->isa('FSM::AST::UnaryOp')) {
        return $self->name_ast_unary_op($ast_expr);
    }
    elsif ($ast_expr->isa('FSM::AST::SignalRef')) {
        return $self->name_ast_signal_ref($ast_expr);
    }
    elsif ($ast_expr->isa('FSM::AST::Literal') || 
           $ast_expr->isa('FSM::AST::LogicalConstant')) {
        return $self->name_ast_literal($ast_expr);
    }
    else {
        # Unknown AST node type, fallback to string conversion
        warn "Unknown AST node type: ".ref($ast_expr).", falling back to string conversion";
        return $self->parse_and_name_expression($ast_expr->to_systemverilog());
    }
}

# Main entry point for FSM::AST::Node objects
sub name_ast_node($self, $ast_node) {
    # Check if we've already named this exact AST node
    if (exists $self->{_named_expressions}{$ast_node}) {
        return $self->{_named_expressions}{$ast_node};
    }
    
    # Generate a name based on node type
    my $signal_name;
    
    if ($ast_node->isa('FSM::AST::BinaryOp')) {
        $signal_name = $self->name_ast_binary_op($ast_node);
    }
    elsif ($ast_node->isa('FSM::AST::UnaryOp')) {
        $signal_name = $self->name_ast_unary_op($ast_node);
    }
    elsif ($ast_node->isa('FSM::AST::SignalRef')) {
        $signal_name = $self->name_ast_signal_ref($ast_node);
    }
    elsif ($ast_node->isa('FSM::AST::Literal') || 
           $ast_node->isa('FSM::AST::LogicalConstant')) {
        $signal_name = $self->name_ast_literal($ast_node);
    }
    else {
        # Unknown AST node type
        warn "Unknown AST node type: ".ref($ast_node);
        $signal_name = "unknown_".lc(ref($ast_node));
        $signal_name =~ s/^.*:://;  # Remove package prefix
    }
    
    # Store in the cache
    $self->{_named_expressions}{$ast_node} = $signal_name;
    
    # Also store a string representation for backward compatibility
    my $sv_str = $ast_node->to_systemverilog();
    $self->{_named_expression_strings}{$sv_str} = $signal_name;
    
    # Store the definition
    $self->{_signal_definitions}{$signal_name} = {
        type => 'expression',
        width => $self->infer_ast_width($ast_node),
        ast => $ast_node,
        original_expr => $sv_str,
        definition => $sv_str,
    };
    
    return $signal_name;
}

#========================================================================
# AST Node Type-Specific Naming Methods
#========================================================================

# Name a CoreAST::BinaryOp node
sub name_binary_op_ast($self, $binary_op) {
    my $op = $binary_op->operator;
    my $left = $binary_op->left;
    my $right = $binary_op->right;
    
    # Check if we've already named this
    my $cache_key = "$binary_op"; # Use object reference as cache key
    if (exists $self->{_named_expressions}{$cache_key}) {
        return $self->{_named_expressions}{$cache_key};
    }
    
    # Generate name components
    my $left_name = $self->name_ast_expression($left);
    my $right_name = $self->name_ast_expression($right);
    my $op_name = $self->op_to_name($op);
    
    # Combine into a name using our naming strategy
    my $base_name = "${left_name}_${op_name}_${right_name}";
    my $signal_name = $self->clean_signal_name($base_name);
    
    # Calculate width based on operation
    my $width;
    if ($op =~ /^(==|!=|<|>|<=|>=)$/) {
        $width = 1; # Comparison always yields 1 bit
    } else {
        my $left_width = $self->infer_ast_width($left);
        my $right_width = $self->infer_ast_width($right);
        $width = ($left_width > $right_width) ? $left_width : $right_width;
    }
    
    # Store in caches
    $self->{_named_expressions}{$cache_key} = $signal_name;
    
    # Get SystemVerilog representation
    my $sv_expr = $binary_op->to_systemverilog();
    $self->{_named_expression_strings}{$sv_expr} = $signal_name;
    
    # Store definition
    $self->{_signal_definitions}{$signal_name} = {
        type => 'expression',
        width => $width,
        ast => $binary_op,
        original_expr => $sv_expr,
        definition => $sv_expr,
    };
    
    return $signal_name;
}

# Name a CoreAST::UnaryOp node
sub name_unary_op_ast($self, $unary_op) {
    my $op = $unary_op->operator;
    my $operand = $unary_op->operand;
    
    # Check cache
    my $cache_key = "$unary_op"; # Use object reference as cache key
    if (exists $self->{_named_expressions}{$cache_key}) {
        return $self->{_named_expressions}{$cache_key};
    }
    
    # Generate name component for operand
    my $operand_name = $self->name_ast_expression($operand);
    
    # Handle negation of signal specially (for readable names)
    if ($op eq '!' && $operand->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $operand->signal->name;
        
        # Check for active low signals with _n or _b suffix
        if ($signal_name =~ /(.+?)(_n|_b)$/ && $operand->signal->width == 1) {
            my $base_name = $1;
            my $signal_name = "${signal_name}_active";
            
            # Store in caches
            $self->{_named_expressions}{$cache_key} = $signal_name;
            my $sv_expr = $unary_op->to_systemverilog();
            $self->{_named_expression_strings}{$sv_expr} = $signal_name;
            
            # Store definition
            $self->{_signal_definitions}{$signal_name} = {
                type => 'expression',
                width => 1,
                ast => $unary_op,
                original_expr => $sv_expr,
                definition => $sv_expr,
            };
            
            return $signal_name;
        }
    }
    
    # Standard unary op naming
    my %unary_prefixes = (
        '!' => 'not',
        '~' => 'inv',
        '+' => 'pos',
        '-' => 'neg',
    );
    
    my $op_prefix = $unary_prefixes{$op} // $op;
    my $base_name = "${op_prefix}_${operand_name}";
    my $signal_name = $self->clean_signal_name($base_name);
    
    # Store in caches
    $self->{_named_expressions}{$cache_key} = $signal_name;
    my $sv_expr = $unary_op->to_systemverilog();
    $self->{_named_expression_strings}{$sv_expr} = $signal_name;
    
    # Store definition
    $self->{_signal_definitions}{$signal_name} = {
        type => 'expression',
        width => $self->infer_ast_width($operand),
        ast => $unary_op,
        original_expr => $sv_expr,
        definition => $sv_expr,
    };
    
    return $signal_name;
}

# Name a CoreAST::SignalRef node
sub name_signal_ref_ast($self, $signal_ref) {
    my $signal = $signal_ref->signal;
    my $slice = $signal_ref->slice;
    my $signal_name = $signal->name;
    
    # For simple signal refs, just return the name directly
    if (!$slice) {
        return $signal_name;
    }
    
    # For sliced signals, create a descriptive name
    if (ref($slice) eq 'ARRAY' && scalar(@$slice) == 2) {
        my ($high, $low) = @$slice;
        if ($high == $low) {
            # Single bit slice
            return "${signal_name}_${high}";
        } else {
            # Range slice
            return "${signal_name}_${high}_${low}";
        }
    }
    
    # Fallback to SystemVerilog conversion
    my $sv_expr = $signal_ref->to_systemverilog();
    return $self->parse_and_name_expression($sv_expr);
}

# Name a CoreAST::Literal node
sub name_literal_ast($self, $literal) {
    my $value = $literal->value;
    my $width = $literal->width;
    
    if ($value eq '0') {
        return 'zero';
    } elsif ($value eq '1') {
        return 'one';
    } else {
        return "const_${value}";
    }
}

# Name a CoreAST::Concatenation node
sub name_concatenation_ast($self, $concat) {
    my $operands = $concat->operands;
    
    # Check cache
    my $cache_key = "$concat"; # Use object reference as cache key
    if (exists $self->{_named_expressions}{$cache_key}) {
        return $self->{_named_expressions}{$cache_key};
    }
    
    # Name each operand
    my @operand_names;
    for my $op (@$operands) {
        push @operand_names, $self->name_ast_expression($op);
    }
    
    # Create a concatenated name
    my $base_name = "concat_" . join('_', @operand_names);
    my $signal_name = $self->clean_signal_name($base_name);
    
    # Store in caches
    $self->{_named_expressions}{$cache_key} = $signal_name;
    my $sv_expr = $concat->to_systemverilog();
    $self->{_named_expression_strings}{$sv_expr} = $signal_name;
    
    # Calculate total width
    my $total_width = 0;
    for my $op (@$operands) {
        $total_width += $self->infer_ast_width($op);
    }
    
    # Store definition
    $self->{_signal_definitions}{$signal_name} = {
        type => 'expression',
        width => $total_width,
        ast => $concat,
        original_expr => $sv_expr,
        definition => $sv_expr,
    };
    
    return $signal_name;
}

# Name an IndexedRef node
sub name_indexed_ref_ast($self, $indexed_ref) {
    my $signal = $indexed_ref->signal;
    my $index = $indexed_ref->index;
    my $signal_name = $signal->name;
    
    # Check cache
    my $cache_key = "$indexed_ref"; # Use object reference as cache key
    if (exists $self->{_named_expressions}{$cache_key}) {
        return $self->{_named_expressions}{$cache_key};
    }
    
    # Simple case: constant index
    if (!ref($index)) {
        return "${signal_name}_${index}";
    }
    
    # Complex case: expression as index
    my $index_name = $self->name_ast_expression($index);
    my $base_name = "${signal_name}_idx_${index_name}";
    my $cleaned_name = $self->clean_signal_name($base_name);
    
    # Store in caches
    $self->{_named_expressions}{$cache_key} = $cleaned_name;
    my $sv_expr = $indexed_ref->to_systemverilog();
    $self->{_named_expression_strings}{$sv_expr} = $cleaned_name;
    
    # Store definition
    $self->{_signal_definitions}{$cleaned_name} = {
        type => 'expression',
        width => 1, # Bit select is always 1 bit
        ast => $indexed_ref,
        original_expr => $sv_expr,
        definition => $sv_expr,
    };
    
    return $cleaned_name;
}

# Name a conditional expression
sub name_conditional_ast($self, $cond_expr) {
    my $condition = $cond_expr->condition;
    my $true_expr = $cond_expr->true_expr;
    my $false_expr = $cond_expr->false_expr;
    
    # Check cache
    my $cache_key = "$cond_expr"; # Use object reference as cache key
    if (exists $self->{_named_expressions}{$cache_key}) {
        return $self->{_named_expressions}{$cache_key};
    }
    
    # Name each component
    my $cond_name = $self->name_ast_expression($condition);
    my $true_name = $self->name_ast_expression($true_expr);
    my $false_name = $self->name_ast_expression($false_expr);
    
    # Create a descriptive name
    my $base_name = "mux_${cond_name}_${true_name}_${false_name}";
    my $signal_name = $self->clean_signal_name($base_name);
    
    # Store in caches
    $self->{_named_expressions}{$cache_key} = $signal_name;
    my $sv_expr = $cond_expr->to_systemverilog();
    $self->{_named_expression_strings}{$sv_expr} = $signal_name;
    
    # Determine width (max of true and false expressions)
    my $true_width = $self->infer_ast_width($true_expr);
    my $false_width = $self->infer_ast_width($false_expr);
    my $width = ($true_width > $false_width) ? $true_width : $false_width;
    
    # Store definition
    $self->{_signal_definitions}{$signal_name} = {
        type => 'expression',
        width => $width,
        ast => $cond_expr,
        original_expr => $sv_expr,
        definition => $sv_expr,
    };
    
    return $signal_name;
}

# Name a function call
sub name_function_call_ast($self, $func_call) {
    my $func_name = $func_call->function_name;
    my $args = $func_call->arguments;
    
    # Check cache
    my $cache_key = "$func_call"; # Use object reference as cache key
    if (exists $self->{_named_expressions}{$cache_key}) {
        return $self->{_named_expressions}{$cache_key};
    }
    
    # Name each argument
    my @arg_names;
    for my $arg (@$args) {
        push @arg_names, $self->name_ast_expression($arg);
    }
    
    # Create a descriptive name
    my $base_name = "${func_name}_" . join('_', @arg_names);
    my $signal_name = $self->clean_signal_name($base_name);
    
    # Store in caches
    $self->{_named_expressions}{$cache_key} = $signal_name;
    my $sv_expr = $func_call->to_systemverilog();
    $self->{_named_expression_strings}{$sv_expr} = $signal_name;
    
    # Store definition (assume width of 32 for function calls)
    $self->{_signal_definitions}{$signal_name} = {
        type => 'expression',
        width => 32, # Default width for function calls
        ast => $func_call,
        original_expr => $sv_expr,
        definition => $sv_expr,
    };
    
    return $signal_name;
}

#========================================================================
# FSM::AST::Node Type-Specific Naming Methods
#========================================================================

# Name an FSM::AST::BinaryOp node
sub name_ast_binary_op($self, $binary_op) {
    my $op = $binary_op->operator;
    my $left = $binary_op->left;
    my $right = $binary_op->right;
    
    # Check if we've already named this
    my $cache_key = "$binary_op"; # Use object reference as cache key
    if (exists $self->{_named_expressions}{$cache_key}) {
        return $self->{_named_expressions}{$cache_key};
    }
    
    # Generate name components
    my $left_name = $self->name_ast_node($left);
    my $right_name = $self->name_ast_node($right);
    my $op_name = $self->op_to_name($op);
    
    # Combine into a name using our naming strategy
    my $base_name = "${left_name}_${op_name}_${right_name}";
    my $signal_name = $self->clean_signal_name($base_name);
    
    # Store in caches
    $self->{_named_expressions}{$cache_key} = $signal_name;
    
    # Get SystemVerilog representation
    my $sv_expr = $binary_op->to_systemverilog();
    $self->{_named_expression_strings}{$sv_expr} = $signal_name;
    
    # Store definition
    $self->{_signal_definitions}{$signal_name} = {
        type => 'expression',
        width => 1, # Default to 1, refined by infer_ast_width
        ast => $binary_op,
        original_expr => $sv_expr,
        definition => $sv_expr,
    };
    
    return $signal_name;
}

# Name an FSM::AST::UnaryOp node
sub name_ast_unary_op($self, $unary_op) {
    my $op = $unary_op->operator;
    my $operand = $unary_op->operand;
    
    # Check cache
    my $cache_key = "$unary_op"; # Use object reference as cache key
    if (exists $self->{_named_expressions}{$cache_key}) {
        return $self->{_named_expressions}{$cache_key};
    }
    
    # Generate name component for operand
    my $operand_name = $self->name_ast_node($operand);
    
    # Standard unary op naming
    my %unary_prefixes = (
        '!' => 'not',
        '~' => 'inv',
        '+' => 'pos',
        '-' => 'neg',
    );
    
    my $op_prefix = $unary_prefixes{$op} // $op;
    my $base_name = "${op_prefix}_${operand_name}";
    my $signal_name = $self->clean_signal_name($base_name);
    
    # Store in caches
    $self->{_named_expressions}{$cache_key} = $signal_name;
    my $sv_expr = $unary_op->to_systemverilog();
    $self->{_named_expression_strings}{$sv_expr} = $signal_name;
    
    # Store definition
    $self->{_signal_definitions}{$signal_name} = {
        type => 'expression',
        width => 1, # Most unary ops produce 1-bit results
        ast => $unary_op,
        original_expr => $sv_expr,
        definition => $sv_expr,
    };
    
    return $signal_name;
}

# Name an FSM::AST::SignalRef node
sub name_ast_signal_ref($self, $signal_ref) {
    return $signal_ref->signal_name;
}

# Name an FSM::AST::Literal or LogicalConstant node
sub name_ast_literal($self, $literal) {
    if ($literal->isa('FSM::AST::LogicalConstant')) {
        return $literal->is_true ? 'one' : 'zero';
    }
    
    my $value = $literal->value;
    
    if ($value eq '0') {
        return 'zero';
    } elsif ($value eq '1') {
        return 'one';
    } else {
        return "const_${value}";
    }
}

#========================================================================
# Backward Compatibility: String-Based Naming
#========================================================================

# LEGACY METHOD: Main entry point for string-based naming
# Kept for backward compatibility
sub parse_and_name_expression($self, $expr_str) {
    # Remove whitespace
    $expr_str =~ s/^\s+|\s+$//g;
    
    # Check if we already named this expression
    if (exists $self->{_named_expression_strings}{$expr_str}) {
        return $self->{_named_expression_strings}{$expr_str};
    }
    
    # Parse the expression into AST
    my $ast = $self->parse_expression($expr_str);
    
    # Generate internal signal name
    my $signal_name = $self->generate_signal_name($ast, $expr_str);
    
    # Store the mapping and definition
    $self->{_named_expression_strings}{$expr_str} = $signal_name;
    $self->{_signal_definitions}{$signal_name} = {
        type => 'expression',
        width => $self->infer_width($ast),
        ast => $ast,
        original_expr => $expr_str,
        definition => $self->ast_to_verilog($ast),
    };
    
    return $signal_name;
}

# LEGACY METHOD: Parse expression string into custom AST 
# Kept for backward compatibility
sub parse_expression($self, $expr_str) {
    # Handle different types of expressions
    return {
        type => 'literal',
        format => 'decimal',
        value => 0,
        bit_value => 0,
        width => 1,
    } unless defined $expr_str && $expr_str ne '';
    
    # Negation (most common)
    if ($expr_str =~ /^!(.+)$/) {
        return {
            type => 'unary_op',
            op => '!',
            operand => $self->parse_expression($1),
        };
    }
    
    # Logical OR
    if ($expr_str =~ /^(.+)\s*\|\s*(.+)$/) {
        return {
            type => 'binary_op',
            op => '|',
            left => $self->parse_expression($1),
            right => $self->parse_expression($2),
        };
    }
    
    # Logical AND
    if ($expr_str =~ /^(.+)\s*&\s*(.+)$/) {
        return {
            type => 'binary_op',
            op => '&',
            left => $self->parse_expression($1),
            right => $self->parse_expression($2),
        };
    }
    
    # Comparison operations
    for my $op ('==', '!=', '<=', '>=', '<', '>') {
        my $escaped_op = quotemeta($op);
        if ($expr_str =~ /^(.+)\s*$escaped_op\s*(.+)$/) {
            return {
                type => 'comparison',
                op => $op,
                left => $self->parse_expression($1),
                right => $self->parse_expression($2),
            };
        }
    }
    
    # Arithmetic operations
    for my $op ('+', '-', '*', '/', '%') {
        my $escaped_op = quotemeta($op);
        if ($expr_str =~ /^(.+)\s*$escaped_op\s*(.+)$/) {
            return {
                type => 'arithmetic',
                op => $op,
                left => $self->parse_expression($1),
                right => $self->parse_expression($2),
            };
        }
    }
    
    # Parentheses
    if ($expr_str =~ /^\s*\((.+)\)\s*$/) {
        return $self->parse_expression($1);
    }
    
    # Signal references
    return $self->parse_signal_reference($expr_str);
}

# LEGACY METHOD: Parse signal references with slices, widths, etc.
# Kept for backward compatibility
sub parse_signal_reference($self, $signal_str) {
    return {
        type => 'literal',
        format => 'decimal',
        value => 0,
        bit_value => 0,
        width => 1,
    } unless defined $signal_str && $signal_str ne '';

    $signal_str =~ s/^\s+|\s+$//g;
    
    # FSMGen constants: const_8b0, const_4h3, etc.
    if ($signal_str =~ /^const_(\d+)([bh])([0-9a-fA-F]+)$/) {
        my ($width, $format, $value) = ($1, $2, $3);
        return {
            type => 'constant',
            format => $format eq 'b' ? 'binary' : 'hex',
            width => $width,
            value => $value,
            bit_value => $format eq 'b' ? oct("0b$value") : hex($value),
        };
    }
    
    # Decimal constants
    if ($signal_str =~ /^\d+$/) {
        return {
            type => 'constant',
            format => 'decimal',
            value => $signal_str,
            bit_value => int($signal_str),
            width => 32,  # Default width
        };
    }
    
    # Signal slice: signal[7:0]
    if ($signal_str =~ /^([a-zA-Z_][a-zA-Z0-9_]*)\[(\d+):(\d+)\]$/) {
        return {
            type => 'signal',
            name => $1,
            slice_type => 'range',
            high => $2,
            low => $3,
            width => abs($2 - $3) + 1,
        };
    }
    
    # Signal bit: signal[3]
    if ($signal_str =~ /^([a-zA-Z_][a-zA-Z0-9_]*)\[(\d+)\]$/) {
        return {
            type => 'signal',
            name => $1,
            slice_type => 'bit',
            bit => $2,
            width => 1,
        };
    }
    
    # Signal with width annotation: signal'8
    if ($signal_str =~ /^([a-zA-Z_][a-zA-Z0-9_]*)'(\d+)$/) {
        return {
            type => 'signal',
            name => $1,
            slice_type => 'full',
            width => $2,
        };
    }
    
    # Output signal: signal>
    if ($signal_str =~ /^([a-zA-Z_][a-zA-Z0-9_]*)>$/) {
        return {
            type => 'signal',
            name => $1,
            slice_type => 'full',
            is_output => 1,
            width => 1,  # Default for outputs
        };
    }
    
    # Simple signal name
    if ($signal_str =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) {
        return {
            type => 'signal',
            name => $signal_str,
            slice_type => 'full',
            width => 1,  # Default width
        };
    }
    
    # Fallback: treat as literal
    return {
        type => 'literal',
        value => $signal_str,
        width => 1,
    };
}

#========================================================================
# Utility Functions for Both AST and String-Based Methods
#========================================================================

# Clean up signal name for HDL compatibility
sub clean_signal_name($self, $base_name) {
    # Clean up name for Verilog
    $base_name =~ s/[^a-zA-Z0-9_]/_/g;   # Replace invalid chars with underscore
    $base_name =~ s/_{2,}/_/g;           # Reduce multiple consecutive underscores to single
    $base_name =~ s/^_+|_+$//g;          # Remove leading and trailing underscores
    $base_name =~ s/^(\d)/_$1/;          # Names can't start with digit
    $base_name = substr($base_name, 0, $self->{_max_name_length});  # Limit length
    
    # Ensure we have a valid name after all cleanup
    $base_name = 'expr' if $base_name eq '' || $base_name !~ /^[a-zA-Z_]/;
    
    return $base_name;
}

# Convert operator to name component
sub op_to_name($self, $op) {
    my %op_names = (
        '!' => 'not',
        '&' => 'and',
        '|' => 'or',
        '==' => 'eq',
        '!=' => 'ne',
        '<' => 'lt',
        '>' => 'gt',
        '<=' => 'le',
        '>=' => 'ge',
        '+' => 'plus',
        '-' => 'minus',
        '*' => 'mul',
        '/' => 'div',
        '%' => 'mod',
        '&&' => 'and',
        '||' => 'or',
    );
    
    return $op_names{$op} // 'op';
}

# Infer bit width of AST expression
sub infer_ast_width($self, $ast) {
    # Handle FSM::CoreAST nodes
    if ($ast->isa('FSM::CoreAST::SignalRef')) {
        my $signal = $ast->signal;
        my $slice = $ast->slice;
        
        if (!$slice) {
            return $signal->width;
        } elsif (ref($slice) eq 'ARRAY' && scalar(@$slice) == 2) {
            my ($high, $low) = @$slice;
            return abs($high - $low) + 1;
        } else {
            return 1; # Single bit select
        }
    }
    elsif ($ast->isa('FSM::CoreAST::AggregateRef')) {
        my $width = $ast->width;
        return $width if defined($width) && $width > 0;
        my $type_spec = $ast->type_spec;
        return $type_spec->{width} if ref($type_spec) eq 'HASH' && $type_spec->{width};
        return 1;
    }
    elsif ($ast->isa('FSM::CoreAST::Literal')) {
        return $ast->width // 32;
    }
    elsif ($ast->isa('FSM::CoreAST::ParameterRef')) {
        my $width = $ast->width;
        return (defined($width) && $width > 0) ? $width : 32;
    }
    elsif ($ast->isa('FSM::CoreAST::UnaryOp')) {
        if ($ast->operator eq '!') {
            return 1; # Logical negation always 1-bit
        } else {
            return $self->infer_ast_width($ast->operand);
        }
    }
    elsif ($ast->isa('FSM::CoreAST::BinaryOp')) {
        my $op = $ast->operator;
        
        # Comparisons always 1-bit
        if ($op =~ /^(==|!=|<|>|<=|>=)$/) {
            return 1;
        }
        
        # For other ops, take max width
        my $left_width = $self->infer_ast_width($ast->left);
        my $right_width = $self->infer_ast_width($ast->right);
        return $left_width > $right_width ? $left_width : $right_width;
    }
    elsif ($ast->isa('FSM::CoreAST::Concatenation')) {
        my $total = 0;
        for my $op (@{$ast->operands}) {
            $total += $self->infer_ast_width($op);
        }
        return $total;
    }
    elsif ($ast->isa('FSM::CoreAST::IndexedRef')) {
        return 1; # Bit select is always 1-bit
    }
    elsif ($ast->isa('FSM::CoreAST::ConditionalExpression')) {
        my $true_width = $self->infer_ast_width($ast->true_expr);
        my $false_width = $self->infer_ast_width($ast->false_expr);
        return $true_width > $false_width ? $true_width : $false_width;
    }
    
    # Handle FSM::AST::Node types
    elsif ($ast->isa('FSM::AST::SignalRef')) {
        # Assume 1-bit for now - we don't have width info in FSM::AST::SignalRef
        return 1;
    }
    elsif ($ast->isa('FSM::AST::Literal')) {
        # Literals assume 32-bit
        return 32; 
    }
    elsif ($ast->isa('FSM::AST::LogicalConstant')) {
        return 1;
    }
    elsif ($ast->isa('FSM::AST::UnaryOp')) {
        if ($ast->operator eq '!') {
            return 1;
        } else {
            return $self->infer_ast_width($ast->operand);
        }
    }
    elsif ($ast->isa('FSM::AST::BinaryOp')) {
        my $op = $ast->operator;
        
        # Comparisons and logical ops always 1-bit
        if ($op =~ /^(==|!=|<|>|<=|>=|&&|\|\|)$/) {
            return 1;
        }
        
        # For other ops, take max width
        my $left_width = $self->infer_ast_width($ast->left);
        my $right_width = $self->infer_ast_width($ast->right);
        return $left_width > $right_width ? $left_width : $right_width;
    }
    
    # Default
    return 1;
}

#========================================================================
# Legacy Methods for String-Based AST - Kept for Backward Compatibility
#========================================================================

# LEGACY METHOD: Generate meaningful signal name for an expression AST
sub generate_signal_name($self, $ast, $orig_expr) {
    my $strategy = $self->{_naming_strategy};
    my $base_name;
    
    # Choose naming strategy
    if ($strategy eq 'semantic') {
        $base_name = $self->ast_to_semantic_name($ast) // $self->ast_to_systematic_name($ast);
    } elsif ($strategy eq 'factorization_aware') {
        $base_name = $self->ast_to_factorization_aware_name($ast) // $self->ast_to_systematic_name($ast);
    } else {
        # Default to systematic naming
        $base_name = $self->ast_to_systematic_name($ast);
    }
    
    # Fallback if naming fails
    $base_name = 'expr' unless $base_name;
    
    # Clean up the name
    return $self->clean_signal_name($base_name);
}

# LEGACY METHOD: Systematic naming - implemented using ast_to_name_fragment
sub ast_to_systematic_name($self, $ast) {
    return undef unless $ast && ref($ast) eq 'HASH';
    
    my $type = $ast->{type} // 'unknown';
    
    if ($type eq 'signal') {
        return $self->format_signal_name($ast);
    } elsif ($type eq 'constant') {
        return $self->format_constant_name($ast);
    } elsif ($type eq 'unary_op') {
        return $self->format_unary_name($ast);
    } elsif ($type eq 'binary_op' || $type eq 'comparison' || $type eq 'arithmetic') {
        return $self->format_binary_name($ast);
    } elsif ($type eq 'literal') {
        return $ast->{value};
    }
    
    return undef;
}

# LEGACY METHOD: Format signal name according to systematic rules
sub format_signal_name($self, $ast) {
    my $name = $ast->{name} // 'sig';
    my $is_active_low = ($name =~ /(.+?)(_n|_b)$/) && ($ast->{width} // 1) == 1;
    my $base_name = $is_active_low ? $1 : $name;
    
    if ($ast->{slice_type} eq 'bit') {
        # signal[m] -> signal_m
        return "${name}_$ast->{bit}";
    } elsif ($ast->{slice_type} eq 'range') {
        # signal[m:n] -> signal_m_n
        return "${name}_$ast->{high}_$ast->{low}";
    } else {
        # bare signal name
        return $name;
    }
}

# LEGACY METHOD: Format constant name
sub format_constant_name($self, $ast) {
    if ($ast->{value} eq '0') {
        return 'zero';
    } elsif ($ast->{value} eq '1') {
        return 'one';
    } else {
        return "const_$ast->{value}";
    }
}

# LEGACY METHOD: Format unary operation: !A -> not_<A>, ++A -> inc_<A>, --A -> dec_<A>
sub format_unary_name($self, $ast) {
    # Special handling for negation of active low signals
    if ($ast->{op} eq '!' && $ast->{operand}->{type} eq 'signal') {
        my $signal = $ast->{operand};
        my $name = $signal->{name};
        
        # If negating an active low signal (with _n or _b suffix), it means it's active
        if ($name =~ /(.+?)(_n|_b)$/ && ($signal->{width} // 1) == 1) {
            return "${name}_active"; # Keep full signal name with _active suffix
        }
    }
    
    my $operand_name = $self->ast_to_systematic_name($ast->{operand});
    return undef unless $operand_name;
    
    my %unary_prefixes = (
        '!' => 'not',
        '++' => 'inc',
        '--' => 'dec',
        '+' => 'pos',
        '-' => 'neg',
        '~' => 'inv',
    );
    
    my $prefix = $unary_prefixes{$ast->{op}} // $ast->{op};
    return "${prefix}_${operand_name}";
}

# LEGACY METHOD: Format binary operation: A op B -> <A>_<op>_<B>
sub format_binary_name($self, $ast) {
    my $left_name = $self->ast_to_systematic_name($ast->{left});
    my $right_name = $self->ast_to_systematic_name($ast->{right});
    
    return undef unless ($left_name && $right_name);
    
    my $op_name = $self->op_to_name($ast->{op});
    return "${left_name}_${op_name}_${right_name}";
}

# LEGACY METHOD: Convert AST fragment to name component
sub ast_to_name_fragment($self, $ast) {
    return 'unknown' unless $ast && ref($ast) eq 'HASH';
    
    my $type = $ast->{type} // 'unknown';
    
    if ($type eq 'signal') {
        my $name = $ast->{name} // 'sig';
        if ($ast->{slice_type} eq 'bit') {
            return "${name}_b$ast->{bit}";
        } elsif ($ast->{slice_type} eq 'range') {
            return "${name}_r$ast->{high}_$ast->{low}";
        } else {
            return $name;
        }
    } elsif ($type eq 'constant') {
        return "const_$ast->{value}";
    } elsif ($type eq 'unary_op') {
        my $op_name = $ast->{op} eq '!' ? 'not' : $ast->{op};
        my $operand_name = $self->ast_to_name_fragment($ast->{operand});
        return "${op_name}_${operand_name}";
    } elsif ($type eq 'binary_op' || $type eq 'comparison' || $type eq 'arithmetic') {
        my $op_name = $self->op_to_name($ast->{op});
        my $left_name = $self->ast_to_name_fragment($ast->{left});
        my $right_name = $self->ast_to_name_fragment($ast->{right});
        return "${left_name}_${op_name}_${right_name}";
    } else {
        return $type;
    }
}

# LEGACY METHOD: Infer bit width of string-based AST expression
sub infer_width($self, $ast) {
    return 1 unless $ast && ref($ast) eq 'HASH';
    
    my $type = $ast->{type} // 'unknown';
    
    if ($type eq 'signal') {
        return $ast->{width} // 1;
    } elsif ($type eq 'constant') {
        return $ast->{width} // 32;
    } elsif ($type eq 'unary_op') {
        if ($ast->{op} eq '!') {
            return 1;  # Logical negation always 1-bit
        } else {
            return $self->infer_width($ast->{operand});
        }
    } elsif ($type eq 'comparison') {
        return 1;  # Comparisons always produce 1-bit result
    } elsif ($type eq 'binary_op') {
        if ($ast->{op} eq '&' || $ast->{op} eq '|') {
            # For logical ops, return max width of operands
            my $left_width = $self->infer_width($ast->{left});
            my $right_width = $self->infer_width($ast->{right});
            return $left_width > $right_width ? $left_width : $right_width;
        }
    } elsif ($type eq 'arithmetic') {
        # For arithmetic, return max width of operands
        my $left_width = $self->infer_width($ast->{left});
        my $right_width = $self->infer_width($ast->{right});
        return $left_width > $right_width ? $left_width : $right_width;
    }
    
    return 1;  # Default
}

# LEGACY METHOD: Convert AST to Verilog expression
sub ast_to_verilog($self, $ast) {
    return "1'b0" unless $ast && ref($ast) eq 'HASH';
    
    my $type = $ast->{type} // 'unknown';
    
    if ($type eq 'signal') {
        my $name = $ast->{name};
        if ($ast->{slice_type} eq 'bit') {
            return "$name\[$ast->{bit}\]";
        } elsif ($ast->{slice_type} eq 'range') {
            return "$name\[$ast->{high}:$ast->{low}\]";
        } else {
            return $name;
        }
    } elsif ($type eq 'constant') {
        if ($ast->{format} eq 'binary') {
            return "$ast->{width}'b$ast->{value}";
        } elsif ($ast->{format} eq 'hex') {
            return "$ast->{width}'h$ast->{value}";
        } else {
            return "$ast->{value}";
        }
    } elsif ($type eq 'unary_op') {
        my $operand = $self->ast_to_verilog($ast->{operand});
        return "($ast->{op}$operand)";
    } elsif ($type eq 'binary_op' || $type eq 'comparison' || $type eq 'arithmetic') {
        my $left = $self->ast_to_verilog($ast->{left});
        my $right = $self->ast_to_verilog($ast->{right});
        return "($left $ast->{op} $right)";
    } elsif ($type eq 'literal') {
        return $ast->{value};
    }
    
    return "1'b0";  # Fallback
}

#========================================================================
# Semantic and Factorization Naming Strategy (Legacy - will be improved)
#========================================================================

# LEGACY METHOD: Semantic naming - creates domain-specific meaningful names
sub ast_to_semantic_name($self, $ast) {
    return undef unless $ast && ref($ast) eq 'HASH';
    
    my $type = $ast->{type} // 'unknown';
    
    # Handle signal first to identify active low signals
    if ($type eq 'signal') {
        my $name = $ast->{name} // 'sig';
        # Check for active low signals (with _n or _b suffix)
        if ($name =~ /(.+?)(_n|_b)$/ && $ast->{width} == 1) {
            my $base_name = $1;
            return "active_${base_name}"; # Active means the signal is asserted
        }
    }
    # Special handling for negation of active low signals
    elsif ($type eq 'unary_op' && $ast->{op} eq '!') {
        my $operand = $ast->{operand};
        if ($operand->{type} eq 'signal') {
            my $name = $operand->{name};
            # If negating an active low signal, it means it's active
            if ($name =~ /(.+?)(_n|_b)$/ && $operand->{width} == 1) {
                return "${name}_active"; # Keep full signal name with _active suffix
            }
        }
        
        # Regular negation semantics
        my $operand_name = $self->ast_to_semantic_name($ast->{operand});
        if ($operand_name) {
            # Create semantic negation names
            if ($operand_name =~ /reset/i) {
                return 'not_in_reset';
            } elsif ($operand_name =~ /ready/i) {
                return 'not_ready';
            } elsif ($operand_name =~ /valid/i) {
                return 'invalid';
            } elsif ($operand_name =~ /enable/i) {
                return 'disabled';
            } else {
                return "not_${operand_name}";
            }
        }
    } elsif ($type eq 'binary_op') {
        return $self->create_semantic_binary_name($ast);
    }
    
    # Fallback to systematic naming
    return $self->ast_to_systematic_name($ast);
}

# LEGACY METHOD: Create semantic names for binary operations
sub create_semantic_binary_name($self, $ast) {
    my $left_name = $self->ast_to_semantic_name($ast->{left});
    my $right_name = $self->ast_to_semantic_name($ast->{right});
    
    return undef unless ($left_name && $right_name);
    
    if ($ast->{op} eq '&') {
        # Create domain-specific AND combinations
        if (($left_name =~ /reset/i && $right_name =~ /ready/i) ||
            ($right_name =~ /reset/i && $left_name =~ /ready/i)) {
            return 'reset_and_ready';
        } elsif (($left_name =~ /valid/i && $right_name =~ /ready/i) ||
                 ($right_name =~ /valid/i && $left_name =~ /ready/i)) {
            return 'valid_and_ready';
        } elsif (($left_name =~ /enable/i && $right_name =~ /ready/i) ||
                 ($right_name =~ /enable/i && $left_name =~ /ready/i)) {
            return 'enabled_and_ready';
        }
    } elsif ($ast->{op} eq '|') {
        # Create domain-specific OR combinations
        if (($left_name =~ /error/i && $right_name =~ /timeout/i) ||
            ($right_name =~ /error/i && $left_name =~ /timeout/i)) {
            return 'error_or_timeout';
        }
    }
    
    # Fallback to systematic naming
    return $self->format_binary_name($ast);
}

# LEGACY METHOD: Factorization-aware naming - optimized for common sub-expression reuse
sub ast_to_factorization_aware_name($self, $ast) {
    return undef unless $ast && ref($ast) eq 'HASH';
    
    my $type = $ast->{type} // 'unknown';
    
    # Handle active low signals first
    if ($type eq 'signal') {
        my $name = $ast->{name} // 'sig';
        # Check for active low signals (with _n or _b suffix)
        if ($name =~ /(.+?)(_n|_b)$/ && ($ast->{width} // 1) == 1) {
            my $base_name = $1;
            if ($base_name =~ /reset|rst/i) {
                return 'in_reset'; # Signal is active low, so it means in reset when 0
            }
        }
    }
    # Special handling for negation of active low signals
    elsif ($type eq 'unary_op' && $ast->{op} eq '!') {
        my $operand = $ast->{operand};
        if ($operand->{type} eq 'signal') {
            my $name = $operand->{name};
            # If negating an active low signal, it means it's active
            if ($name =~ /(.+?)(_n|_b)$/ && ($operand->{width} // 1) == 1) {
                if ($name =~ /reset|rst/i) {
                    return 'not_in_reset';
                }
                return "${name}_active"; # Keep full signal name with _active suffix
            }
        }
    }
    
    # Fallback to systematic naming
    return $self->ast_to_systematic_name($ast);
}

#========================================================================
# General Query Methods
#========================================================================

# Get all generated signal definitions
sub get_signal_definitions($self) {
    return _clone($self->{_signal_definitions});
}

# Get named expressions mapping
sub get_named_expressions($self) {
    return _clone($self->{_named_expression_strings});
}

# Generate Verilog wire declarations for all named expressions
sub generate_wire_declarations($self) {
    my @declarations;
    
    for my $signal_name (keys %{$self->{_signal_definitions}}) {
        my $def = $self->{_signal_definitions}->{$signal_name};
        my $width = $def->{width};
        
        if ($width > 1) {
            push @declarations, "wire [${\\($width-1)}:0] $signal_name;";
        } else {
            push @declarations, "wire $signal_name;";
        }
    }
    
    return @declarations;
}

# Generate Verilog assignments for all named expressions
sub generate_assignments($self) {
    my @assignments;
    
    for my $signal_name (keys %{$self->{_signal_definitions}}) {
        my $def = $self->{_signal_definitions}->{$signal_name};
        push @assignments, "assign $signal_name = $def->{definition};";
    }
    
    return @assignments;
}

# Native AST complexity analysis methods
sub analyze_ast_complexity_native($self, $ast_node) {
    # Analyze AST complexity directly from FSM Core AST or FSM::AST nodes
    # Returns: { has_logical_ops => bool, depth => int, node_count => int }
    
    my $result = {
        has_logical_ops => 0,
        depth => 0,
        node_count => 0
    };
    
    return $result unless $ast_node && ref($ast_node);
    
    $self->_traverse_native_ast_for_complexity($ast_node, $result, 1);
    
    return $result;
}

sub _traverse_native_ast_for_complexity($self, $node, $result, $current_depth) {
    # Recursive traversal of native AST nodes to analyze complexity
    
    return unless $node && ref($node);
    
    $result->{node_count}++;
    $result->{depth} = $current_depth if $current_depth > $result->{depth};
    
    # Handle FSM::CoreAST nodes
    if ($node->isa('FSM::CoreAST::BinaryOp')) {
        my $op = $node->operator;
        
        if ($op =~ /^(&&|\|\||&|\|)$/) {
            $result->{has_logical_ops} = 1;
        }
        
        $self->_traverse_native_ast_for_complexity($node->left, $result, $current_depth + 1);
        $self->_traverse_native_ast_for_complexity($node->right, $result, $current_depth + 1);
    }
    elsif ($node->isa('FSM::CoreAST::UnaryOp')) {
        $self->_traverse_native_ast_for_complexity($node->operand, $result, $current_depth + 1);
    }
    elsif ($node->isa('FSM::CoreAST::ConditionalExpression')) {
        $self->_traverse_native_ast_for_complexity($node->condition, $result, $current_depth + 1);
        $self->_traverse_native_ast_for_complexity($node->true_expr, $result, $current_depth + 1);
        $self->_traverse_native_ast_for_complexity($node->false_expr, $result, $current_depth + 1);
    }
    elsif ($node->isa('FSM::CoreAST::Concatenation')) {
        for my $operand (@{$node->operands}) {
            $self->_traverse_native_ast_for_complexity($operand, $result, $current_depth + 1);
        }
    }
    elsif ($node->isa('FSM::CoreAST::IndexedRef')) {
        if (ref($node->index)) {
            $self->_traverse_native_ast_for_complexity($node->index, $result, $current_depth + 1);
        }
    }
    elsif ($node->isa('FSM::CoreAST::AggregateRef')) {
        # Aggregate refs are typed leaves; their path is metadata, not another expression tree.
    }
    elsif ($node->isa('FSM::CoreAST::FunctionCall')) {
        for my $arg (@{$node->arguments}) {
            $self->_traverse_native_ast_for_complexity($arg, $result, $current_depth + 1);
        }
    }
    
    # Handle FSM::AST::Node types
    elsif ($node->isa('FSM::AST::BinaryOp')) {
        my $op = $node->operator;
        
        if ($op =~ /^(&&|\|\||&|\|)$/) {
            $result->{has_logical_ops} = 1;
        }
        
        $self->_traverse_native_ast_for_complexity($node->left, $result, $current_depth + 1);
        $self->_traverse_native_ast_for_complexity($node->right, $result, $current_depth + 1);
    }
    elsif ($node->isa('FSM::AST::UnaryOp')) {
        $self->_traverse_native_ast_for_complexity($node->operand, $result, $current_depth + 1);
    }
    
    # For SignalRef and Literal nodes, no further traversal needed
}

sub _clone($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }

    return $value;
}

# Native AST factorization decision method
sub should_factor_ast_native($self, $ast_node) {
    # Determine if an AST node should be factored into an intermediate signal
    # This works directly with AST nodes without string conversion
    
    return 0 unless $ast_node && ref($ast_node);
    
    # Don't factor simple nodes
    if ($ast_node->isa('FSM::CoreAST::SignalRef') || 
        $ast_node->isa('FSM::CoreAST::AggregateRef') ||
        $ast_node->isa('FSM::AST::SignalRef') ||
        $ast_node->isa('FSM::CoreAST::Literal') ||
        $ast_node->isa('FSM::AST::Literal') ||
        $ast_node->isa('FSM::AST::LogicalConstant')) {
        return 0;
    }
    
    # Analyze complexity
    my $complexity = $self->analyze_ast_complexity_native($ast_node);
    
    # Factor if the AST represents a compound logical expression
    if ($complexity->{has_logical_ops} && $complexity->{depth} > 1) {
        return 1;
    }
    
    # Don't factor by default
    return 0;
}

1;
