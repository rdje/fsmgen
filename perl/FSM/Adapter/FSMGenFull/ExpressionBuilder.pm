package FSM::Adapter::FSMGenFull::ExpressionBuilder;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use Data::Dumper;
use FSM::CoreAST;
use FSM::Debug;

sub new($class, %args) {
    # Requires a signal_manager
    Carp::confess "ExpressionBuilder requires a signal_manager" unless $args{signal_manager};
    
    return bless {
        debug => $args{debug} // 0,
        signal_manager => $args{signal_manager},
        intermediate_counter => 0,
    }, $class;
}

sub parse_condition($self, $condition) {
    if (!defined $condition) {
        return undef;
    }
    
    fsm_debug("        PARSE_CONDITION: Evaluating condition " . (ref($condition) ? "complex" : "'$condition'"), 3);
    
    # NEW FORMAT: condition is fully parsed as a complex expression
    if (ref($condition)) {
        fsm_debug("          Parsing complex condition expression", 3);
        return $self->parse_expression($condition);
    }
    
    # OLD FORMAT: string condition like '<signal_name', '<!signal_name', '<signal=value'
    if ($condition =~ /^<!(.+)$/) {
        # Negative condition: <!signal or <!signal=value
        my $condition_spec = $1;
        fsm_debug("          Parsing negative condition: !$condition_spec", 3);
        my $condition_expr = $self->parse_legacy_condition_spec($condition_spec);
        return FSM::CoreAST::UnaryOp->new(
            operator => '!',
            operand => $condition_expr
        );
    } elsif ($condition =~ /^<(.+)$/) {
        # Positive condition: <signal or <signal=value
        my $condition_spec = $1;
        fsm_debug("          Parsing positive condition: $condition_spec", 3);
        return $self->parse_legacy_condition_spec($condition_spec);
    } else {
        # Unexpected format like 'signal_name'
        fsm_debug("          WARNING: Unexpected condition string string='$condition'. Treating as positive condition.", 3);
        return $self->parse_signal_reference($condition);
    }
}

sub parse_legacy_condition_spec($self, $condition_spec) {
    # Parse legacy condition payload found after < or <! prefixes.
    # Supports:
    #   signal          -> SignalRef(signal)
    #   signal=value    -> BinaryOp('==', SignalRef(signal), parse_expression(value))
    $condition_spec =~ s/^\s+|\s+$//g;
    
    # Equality form used heavily in .fsm files: <s=8'0
    if ($condition_spec =~ /^([a-zA-Z_]\w*)=(.+)$/) {
        my ($lhs_signal, $rhs_expr) = ($1, $2);
        $rhs_expr =~ s/^\s+|\s+$//g;
        
        my $lhs = $self->parse_signal_reference($lhs_signal);
        my $rhs = $self->parse_expression($rhs_expr);
        
        fsm_debug("          Legacy condition parsed as equality: $lhs_signal == $rhs_expr", 3);
        return FSM::CoreAST::BinaryOp->new('==', $lhs, $rhs);
    }
    
    # Simple signal presence condition
    return $self->parse_signal_reference($condition_spec);
}

sub is_recursive_expression($self, $expr) {
    # Check if this is a recursive operator expression like ['&', 'a', 'b', ['|', 'c', 'd']]
    if (ref($expr) eq 'ARRAY' && @$expr >= 1 && !ref($expr->[0])) {
        my $op = $expr->[0];
        my %valid_ops = map { $_ => 1 } qw(& | ^ + - * / % and or xor add sub mul div mod);
        return 1 if $valid_ops{$op};
    }
    return 0;
}

sub parse_recursive_expression($self, $expr) {
    my ($operator, @operands) = @$expr;
    
    # Lispish often packs n-ary operands in a single array:
    #   ['&', ['a', 'b', 'c']]
    # Normalize to a flat list.
    if (@operands == 1 && ref($operands[0]) eq 'ARRAY') {
        @operands = @{$operands[0]};
    }
    
    fsm_debug("          Recursive expr: $operator with " . scalar(@operands) . " operands", 3);
    
    my @parsed_operands;
    for my $operand (@operands) {
        my $parsed = $self->parse_expression($operand);
        push @parsed_operands, $parsed if $parsed;
    }
    
    # Special handling for boolean/logical operators to factor out intermediate terms
    # This prevents deeply nested expressions in generated code
    my %logical_ops = ('&' => 1, '|' => 1, '^' => 1, 'and' => 1, 'or' => 1, 'xor' => 1);
    
    # Create the AST tree
    my $ast_tree = $self->create_binary_operator_tree($operator, \@parsed_operands);
    
    if (scalar(@parsed_operands) > 1 && $logical_ops{$operator}) {
        # We need to factor this complex calculation into an intermediate wire
        fsm_debug("          FACTORIZATION: Extracting complex $operator expression to intermediate signal", 3);
        
        # 1. Create a semantic name for the intermediate
        my $intermediate_name = $self->generate_intermediate_signal($operator, \@parsed_operands);
        
        # 2. Register the intermediate signal to force it to be declared
        my $signal = $self->{signal_manager}->register_signal($intermediate_name, 
            type => 'wire',
            is_intermediate => 1
        );
        
        # 3. Important step: store the AST that drives this new signal
        # This will be used by the HDL generator to create 'assign intermediate_name = ...'
        $signal->set_attribute('driving_ast', $ast_tree);
        fsm_debug("            Attached driving AST to intermediate signal $intermediate_name", 3);
        
        # 4. Return a reference to the intermediate signal instead of the complex tree
        return FSM::CoreAST::SignalRef->new($signal);
    }
    
    # For arithmetic operators or single operands, just return the AST tree
    return $ast_tree;
}

sub generate_intermediate_signal($self, $operator, $operands) {
    $self->{intermediate_counter}++;
    
    # Extract names from operands if they are signal references
    my @names;
    for my $op (@$operands) {
        if ($op->isa('FSM::CoreAST::SignalRef') && $op->signal) {
            push @names, $op->signal->name;
        } elsif ($op->isa('FSM::CoreAST::UnaryOp') && $op->operator eq '!' && 
                 $op->operand->isa('FSM::CoreAST::SignalRef')) {
            push @names, "not_" . $op->operand->signal->name;
        }
    }
    
    my $op_name = $operator;
    # Normalize common operators for better naming
    $op_name = 'and' if $operator eq '&';
    $op_name = 'or'  if $operator eq '|';
    $op_name = 'xor' if $operator eq '^';
    $op_name = 'add' if $operator eq '+';
    
    # Create a descriptive name of format: op_name_operand1_operand2...
    my $base_name = join("_", $op_name, @names);
    
    # Truncate if too long
    if (length($base_name) > 40) {
        $base_name = substr($base_name, 0, 40) . "_etc";
    }
    
    # If we couldn't extract names, fall back to simple counter
    if (@names == 0) {
        $base_name = "complex_expr";
    }
    
    return "intermediate_${base_name}_" . $self->{intermediate_counter};
}

sub create_binary_operator_tree($self, $operator, $operands) {
    return undef unless @$operands;
    
    if (@$operands == 1) {
        return $operands->[0];
    }
    
    my %op_map = (
        'and' => '&', 'or' => '|', 'xor' => '^',
        'add' => '+', 'sub' => '-', 'mul' => '*', 'div' => '/', 'mod' => '%'
    );
    my $normalized_op = $op_map{$operator} || $operator;
    
    my $result = $operands->[0];
    for my $i (1 .. $#{$operands}) {
        $result = FSM::CoreAST::BinaryOp->new(
            $normalized_op, $result, $operands->[$i]
        );
    }
    
    return $result;
}

sub parse_expression($self, $expr) {
    if (!ref($expr)) {
        return $self->parse_scalar_expression($expr);
    } elsif (ref($expr) eq 'ARRAY') {
        if ($self->is_recursive_expression($expr)) {
            fsm_debug("          Detected recursive expression - processing with new framework", 3);
            return $self->parse_recursive_expression($expr);
        } else {
            return $self->parse_sexpr_expression($expr);
        }
    } else {
        fsm_debug("Unknown expression type: " . ref($expr), 3);
        return undef;
    }
}

sub parse_scalar_expression($self, $scalar) {
    fsm_debug("        PARSE_SCALAR: Processing scalar '$scalar'", 3);
    
    if ($scalar =~ /^(\d+)'([bdhxBDHX])([0-9a-fA-F_]+)$/) {
        my ($width, $radix_char, $value) = ($1, lc($2), $3);
        $value =~ s/_//g;
        my %radix_map = ('b' => 'binary', 'd' => 'decimal', 'h' => 'hex', 'x' => 'hex');
        my $radix = $radix_map{$radix_char} // 'decimal';
        return FSM::CoreAST::Literal->new($value, width => $width, radix => $radix);
    } elsif ($scalar =~ /^(\d+)'([0-9a-fA-F_]+)$/) {
        my ($width, $value) = ($1, $2);
        $value =~ s/_//g;
        return FSM::CoreAST::Literal->new($value, width => $width, radix => 'decimal');
    } elsif ($scalar =~ /^(\d+)$/) {
        return FSM::CoreAST::Literal->new($scalar);
    } elsif ($scalar =~ /^const_(\d+)b([01xXzZ_]+)$/) {
        # Common FSMGen constant encoding, e.g. const_8b0 / const_16b0000_1111
        my ($width, $value) = ($1, $2);
        $value =~ s/_//g;
        fsm_debug("          CONST LITERAL: '$scalar' -> ${width}'b$value", 3);
        return FSM::CoreAST::Literal->new($value, width => $width, radix => 'binary');
    } elsif ($scalar =~ /^!([a-zA-Z_]\w*(?:\[[\d:]+\])?)$/) {
        # Legacy compact negation token, e.g. !wren
        my $operand = $self->parse_signal_reference($1);
        return FSM::CoreAST::UnaryOp->new(
            operator => '!',
            operand => $operand
        );
    } elsif ($scalar =~ /^([a-zA-Z_]\w*)(\.[a-zA-Z_]\w*)?(\[[\d:]+\])?('(\d+))?(\>)?$/) {
        my ($base_name, $member_name, $slice, $width_annotation, $width, $output_marker) = ($1, $2, $3, $4, $5, $6);
        my $full_name = $member_name ? "$base_name$member_name" : $base_name;
        
        my $resolved_symbol = $self->{signal_manager}->resolve_symbol($full_name);
        if ($resolved_symbol) {
            fsm_debug("          SYMBOL RESOLVED: '$full_name' -> literal/constant", 3);
            return $resolved_symbol;
        }
        
        my $signal_name = $base_name;
        my $signal = $self->{signal_manager}->register_signal($signal_name, 
            width => $width,
            is_output => defined($output_marker)
        );
        
        if ($slice) {
            if ($slice =~ /\[(\d+):(\d+)\]/) {
                return FSM::CoreAST::SignalRef->new($signal, slice => [$1, $2]);
            } elsif ($slice =~ /\[(\d+)\]/) {
                return FSM::CoreAST::IndexedRef->new($signal, FSM::CoreAST::Literal->new($1));
            }
        }
        
        return FSM::CoreAST::SignalRef->new($signal);
    } else {
        if ($scalar =~ /^[!<>]/) {
            fsm_debug("          WARNING: Invalid signal name detected: $scalar", 3);
            return undef;
        }
        my $signal = $self->{signal_manager}->register_signal($scalar);
        return FSM::CoreAST::SignalRef->new($signal);
    }
}

sub parse_sexpr_expression($self, $sexpr) {
    my ($operator, @operands) = @$sexpr;
    fsm_debug("          S-expression: $operator with " . scalar(@operands) . " operands", 3);
    
    if ($operator eq '+' && @operands == 2) {
        return FSM::CoreAST::BinaryOp->new('+', $self->parse_expression($operands[0]), $self->parse_expression($operands[1]));
    } elsif ($operator eq '-' && @operands == 2) {
        return FSM::CoreAST::BinaryOp->new('-', $self->parse_expression($operands[0]), $self->parse_expression($operands[1]));
    } elsif ($operator eq '&' && @operands == 2) {
        return FSM::CoreAST::BinaryOp->new('&', $self->parse_expression($operands[0]), $self->parse_expression($operands[1]));
    } elsif ($operator eq '|' && @operands == 2) {
        return FSM::CoreAST::BinaryOp->new('|', $self->parse_expression($operands[0]), $self->parse_expression($operands[1]));
    } elsif ($operator eq '==' && @operands == 2) {
        return FSM::CoreAST::BinaryOp->new('==', $self->parse_expression($operands[0]), $self->parse_expression($operands[1]));
    } elsif ($operator eq '!' && @operands == 1) {
        return FSM::CoreAST::UnaryOp->new(operator => '!', operand => $self->parse_expression($operands[0]));
    } else {
        fsm_debug("          Unknown S-expression operator: $operator", 3);
        return undef;
    }
}

sub parse_signal_reference($self, $signal_spec) {
    if (!ref($signal_spec)) {
        return $self->parse_scalar_expression($signal_spec);
    } else {
        return $self->parse_expression($signal_spec);
    }
}

sub handle_width_mismatch($self, $lhs_width, $rhs_width, $signal_name, $value_expr, $source_expr_ref) {
    if ($lhs_width > $rhs_width) {
        my $expand_bits = $lhs_width - $rhs_width;
        fsm_debug("          WIDTH EXPANSION: LHS($lhs_width) > RHS($rhs_width) - expanding RHS with $expand_bits zero bits", 3);
        my $zero_literal = FSM::CoreAST::Literal->new('0', width => $expand_bits, radix => 'binary');
        my $expanded_rhs = FSM::CoreAST::Concatenation->new($zero_literal, $$source_expr_ref);
        $$source_expr_ref = $expanded_rhs;
    } elsif ($lhs_width < $rhs_width) {
        my $truncate_bits = $rhs_width - $lhs_width;
        fsm_debug("          WIDTH TRUNCATION: LHS($lhs_width) < RHS($rhs_width) - truncating RHS by $truncate_bits bits", 3);
        my $high_bit = $lhs_width - 1;
        my $truncated_rhs;
        
        if (ref($$source_expr_ref) eq 'FSM::CoreAST::SignalRef') {
            my $signal = $$source_expr_ref->signal;
            $truncated_rhs = FSM::CoreAST::SignalRef->new($signal, slice => [$high_bit, 0]);
        } else {
            fsm_debug("WARNING: Cannot truncate complex expression - leaving as-is", 3);
            $truncated_rhs = $$source_expr_ref;
        }
        $$source_expr_ref = $truncated_rhs;
    }
}

sub propagate_width_to_expression($self, $expr, $width) {
    return unless $expr && $width;
    
    fsm_debug("          Propagating width $width to expression: " . ref($expr), 3);
    
    if (ref($expr) eq 'FSM::CoreAST::SignalRef') {
        my $signal = $expr->signal;
        if ($signal && (!$signal->width || $signal->width == 1) && $width > 1) {
            my $updated_signal = $self->{signal_manager}->register_signal($signal->name, 
                width => $width,
                type => $signal->type,
                is_output => $signal->get_attribute('is_output')
            );
            $expr->{signal} = $updated_signal;
        }
    } elsif (ref($expr) eq 'FSM::CoreAST::BinaryOp') {
        $self->propagate_width_to_expression($expr->left, $width) if $expr->left;
        $self->propagate_width_to_expression($expr->right, $width) if $expr->right;
    } elsif (ref($expr) eq 'FSM::CoreAST::UnaryOp') {
        $self->propagate_width_to_expression($expr->operand, $width) if $expr->operand;
    }
}

1;
