package FSM::Adapter::FSMGenFull::ExpressionBuilder;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use Data::Dumper;
use Scalar::Util qw(blessed);
use FSM::CoreAST;
use FSM::Debug;
use FSM::Package::AggregatePathSupport;
use FSM::Package::IntegerLiteralSupport;
use FSM::Package::PayloadLiteralSupport;
use FSM::Package::PayloadTypeSupport;

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
        if (!$self->condition_spec_has_explicit_operator($condition_spec)) {
            return $self->parse_legacy_condition_spec(
                $condition_spec,
                bare_signal_operator => '=='
            );
        }

        my $condition_expr = $self->parse_legacy_condition_spec($condition_spec);
        return FSM::CoreAST::UnaryOp->new(
            operator => '!',
            operand => $condition_expr
        );
    } elsif ($condition =~ /^<(.+)$/) {
        # Positive condition: <signal or <signal=value
        my $condition_spec = $1;
        fsm_debug("          Parsing positive condition: $condition_spec", 3);
        return $self->parse_legacy_condition_spec(
            $condition_spec,
            bare_signal_operator => '!='
        );
    } else {
        # Unexpected format like 'signal_name'
        fsm_debug("          WARNING: Unexpected condition string string='$condition'. Treating as positive condition.", 3);
        return $self->parse_signal_reference($condition);
    }
}

sub condition_spec_has_explicit_operator($self, $condition_spec) {
    return 0 unless defined $condition_spec;
    return $condition_spec =~ /^.+?(?:==|!=|<=|>=|=|<|>).+$/ ? 1 : 0;
}

sub malformed_guard_condition_error($self, $condition_spec) {
    Carp::confess
        "Malformed guard condition payload '$condition_spec'. ".
        "Guard shorthand must use a valid signal/expression comparison such as '<foo', '<!foo', '<foo=3', or '<foo<=3'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}

sub malformed_inline_comparison_error($self, $scalar) {
    Carp::confess
        "Malformed inline comparison expression '$scalar'. ".
        "Inline comparison tokens must use valid operands on both sides of the comparison operator. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}

sub parse_legacy_condition_spec($self, $condition_spec, %options) {
    # Parse legacy condition payload found after < or <! prefixes.
    # Supports:
    #   signal          -> BinaryOp('!=', SignalRef(signal), 0) when a bare-signal
    #                      operator is provided by the caller
    #   signal=value    -> BinaryOp('==', SignalRef(signal), parse_expression(value))
    #   signal==value   -> BinaryOp('==', SignalRef(signal), parse_expression(value))
    #   signal!=value   -> BinaryOp('!=', SignalRef(signal), parse_expression(value))
    #   signal<value    -> BinaryOp('<',  SignalRef(signal), parse_expression(value))
    $condition_spec =~ s/^\s+|\s+$//g;

    if ($condition_spec =~ /^(.+?)(==|!=|<=|>=|=|<|>)(.+)$/) {
        my ($lhs_spec, $operator, $rhs_expr) = ($1, $2, $3);
        $lhs_spec =~ s/^\s+|\s+$//g;
        $rhs_expr =~ s/^\s+|\s+$//g;
        $operator = '==' if $operator eq '=';

        my $lhs = eval { $self->parse_signal_reference($lhs_spec) };
        my $lhs_error = $@;
        my $rhs = eval { $self->parse_expression($rhs_expr) };
        my $rhs_error = $@;

        $self->malformed_guard_condition_error($condition_spec)
            if $lhs_error || $rhs_error || !$lhs || !$rhs;

        $self->align_comparison_operand_widths($lhs, $rhs);

        fsm_debug("          Legacy condition parsed as comparison: $lhs_spec $operator $rhs_expr", 3);
        return FSM::CoreAST::BinaryOp->new($operator, $lhs, $rhs);
    }

    if (defined $options{bare_signal_operator}) {
        my $lhs = eval { $self->parse_signal_reference($condition_spec) };
        my $lhs_error = $@;
        my $rhs = FSM::CoreAST::Literal->new('0');

        $self->malformed_guard_condition_error($condition_spec)
            if $lhs_error || !$lhs;

        fsm_debug(
            "          Legacy condition parsed as bare-signal truthiness: $condition_spec $options{bare_signal_operator} 0",
            3
        );
        return FSM::CoreAST::BinaryOp->new($options{bare_signal_operator}, $lhs, $rhs);
    }

    # Fallback bare condition for non-prefixed internal callers.
    return $self->parse_signal_reference($condition_spec);
}

sub is_recursive_expression($self, $expr) {
    return 0 unless ref($expr) eq 'ARRAY' && @$expr >= 1 && !ref($expr->[0]);

    my ($normalized_op) = $self->normalize_expression_operator($expr->[0]);
    return defined($normalized_op) ? 1 : 0;
}

sub normalize_expression_operator($self, $operator) {
    return undef unless defined $operator;

    my %operator_aliases = (
        and => '&',
        or  => '|',
        xor => '^',
        add => '+',
        sub => '-',
        mul => '*',
        div => '/',
        mod => '%',
        eq  => '==',
        ne  => '!=',
        lt  => '<',
        le  => '<=',
        gt  => '>',
        ge  => '>=',
        not => '!',
        cat => 'concat',
    );

    my $normalized = $operator_aliases{$operator} // $operator;
    my %supported = map { $_ => 1 } qw(! == != < <= > >= & | ^ + - * / % concat);
    return $supported{$normalized} ? $normalized : undef;
}

sub operator_family_for($self, $normalized_operator) {
    return 'unary' if defined $normalized_operator && $normalized_operator eq '!';
    return 'comparison'
        if defined $normalized_operator && $normalized_operator =~ /^(?:==|!=|<|<=|>|>=)$/;
    return 'concat' if defined $normalized_operator && $normalized_operator eq 'concat';
    return 'nary'
        if defined $normalized_operator && $normalized_operator =~ /^(?:&|\||\^|\+|-|\*|\/|%)$/;
    return undef;
}

sub finalize_nary_expression($self, $operator, $parsed_operands) {
    my %logical_ops = map { $_ => 1 } qw(& | ^);
    my $ast_tree = $self->create_binary_operator_tree($operator, $parsed_operands);

    if (@$parsed_operands > 1 && $logical_ops{$operator}) {
        fsm_debug("          FACTORIZATION: Extracting complex $operator expression to intermediate signal", 3);

        my $intermediate_name = $self->generate_intermediate_signal($operator, $parsed_operands);
        my $signal = $self->{signal_manager}->register_signal(
            $intermediate_name,
            type => 'wire',
            is_intermediate => 1
        );

        $signal->set_driving_ast($ast_tree);
        fsm_debug("            Attached driving AST to intermediate signal $intermediate_name", 3);

        return FSM::CoreAST::SignalRef->new($signal);
    }

    return $ast_tree;
}

sub build_chained_relational_expression($self, $operator, $parsed_operands) {
    my @comparisons;
    for my $i (0 .. ($#$parsed_operands - 1)) {
        $self->align_comparison_operand_widths($parsed_operands->[$i], $parsed_operands->[$i + 1]);
        push @comparisons, FSM::CoreAST::BinaryOp->new(
            $operator,
            $parsed_operands->[$i],
            $parsed_operands->[$i + 1],
        );
    }

    return $comparisons[0] if @comparisons == 1;
    return $self->finalize_nary_expression('&', \@comparisons);
}

sub parse_recursive_expression($self, $expr) {
    my ($operator, @operands) = @$expr;
    
    # Lispish often packs n-ary operands in a single array:
    #   ['&', ['a', 'b', 'c']]
    # Normalize to a flat list.
    if (@operands == 1 && ref($operands[0]) eq 'ARRAY') {
        @operands = @{$operands[0]};
    }
    
    my $normalized_operator = $self->normalize_expression_operator($operator);
    my $operator_family = $self->operator_family_for($normalized_operator);

    Carp::confess
        "Unsupported expression operator '$operator'. ".
        "Active expression operators currently include '!', '==', '!=', '<', '<=', '>', '>=', '+', '-', '*', '/', '%', '&', '|', '^', 'concat' and their documented aliases. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless $operator_family;

    fsm_debug("          Recursive expr: $operator with " . scalar(@operands) . " operands", 3);

    my @parsed_operands;
    for my $operand (@operands) {
        my $parsed = $self->parse_expression($operand);
        push @parsed_operands, $parsed if $parsed;
    }

    if ($operator_family eq 'unary') {
        Carp::confess
            "Malformed expression operator '$operator' with " . scalar(@parsed_operands) . " operand(s). ".
            "This active form requires exactly 1 operand. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless @parsed_operands == 1;

        return FSM::CoreAST::UnaryOp->new(
            operator => $normalized_operator,
            operand  => $parsed_operands[0],
        );
    }

    Carp::confess
        "Malformed expression operator '$operator' with " . scalar(@parsed_operands) . " operand(s). ".
        "This active form requires at least 2 operands. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless @parsed_operands >= 2;

    return $self->build_chained_relational_expression($normalized_operator, \@parsed_operands)
        if $operator_family eq 'comparison';

    if ($operator_family eq 'concat') {
        my $concat = FSM::CoreAST::Concatenation->new(@parsed_operands);
        my $concat_width = $self->infer_exact_expression_width($concat);

        Carp::confess
            "Malformed concat expression with " . scalar(@parsed_operands) . " operand(s). ".
            "Direct RHS concat operands must have exact widths from declared signal widths, bit/slice or aggregate leaf access, or explicitly sized literal constants before generation. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless defined($concat_width) && $concat_width > 0;

        return $concat;
    }

    return $self->finalize_nary_expression($normalized_operator, \@parsed_operands);
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
        Carp::confess
            "Malformed expression list '()'. ".
            "Expressions must use a literal, signal reference, or supported operator form. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless @$expr;

        if ($self->is_recursive_expression($expr)) {
            fsm_debug("          Detected recursive expression - processing with new framework", 3);
            return $self->parse_recursive_expression($expr);
        } else {
            return $self->parse_sexpr_expression($expr);
        }
    } else {
        Carp::confess
            "Unsupported expression payload type '" . ref($expr) . "'. ".
            "Expressions must use a literal, signal reference, or supported operator form. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }
}

sub parse_scalar_expression($self, $scalar) {
    fsm_debug("        PARSE_SCALAR: Processing scalar '$scalar'", 3);

    if ($scalar =~ /^\[[^\]]+\](?:.*)?$/) {
        Carp::confess
            "Unsupported generic/template placeholder token '$scalar'. ".
            "The active contract does not support legacy placeholder-expansion forms like '[NAME]' or '[?size: ...]'. ".
            "Expand the template before parsing or keep it in legacy-only sources. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }

    my $resolved_symbol = $self->{signal_manager}->resolve_symbol($scalar);
    if ($resolved_symbol) {
        fsm_debug("          SYMBOL RESOLVED: '$scalar' -> semantic symbol", 3);
        return $resolved_symbol;
    }

    my $aggregate_payload = $self->{signal_manager}->resolve_aggregate_symbol_payload($scalar);
    if (defined $aggregate_payload) {
        my ($bits, $width, $reason) = FSM::Package::PayloadLiteralSupport->payload_to_bits_and_width($aggregate_payload);
        if (defined $bits) {
            fsm_debug("          AGGREGATE ROOT RESOLVED: '$scalar' -> ${width}'b$bits", 3);
            return FSM::CoreAST::Literal->new($bits, width => $width, radix => 'binary');
        }
        Carp::confess
            "Unsupported aggregate-valued symbol '$scalar'. ".
            "The active scalar-expression lane currently requires whole aggregate roots to lower to one packed literal with scalar literal leaves. ".
            "This aggregate could not be lowered because '$reason' is outside that bounded contract. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }

    my $aggregate_prefix = $self->{signal_manager}->aggregate_symbol_prefix_for($scalar);
    if (defined $aggregate_prefix) {
        Carp::confess
            "Unsupported aggregate-valued symbol '$scalar'. ".
            "The active scalar-expression lane currently requires member/index access all the way to a scalar leaf, for example '$aggregate_prefix.member' or '$aggregate_prefix\[0\]'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }

    my $typed_aggregate_ref = $self->parse_typed_aggregate_signal_reference($scalar);
    return $typed_aggregate_ref if $typed_aggregate_ref;
    
    my $integer_literal = $self->parse_common_integer_literal($scalar);
    return $integer_literal if $integer_literal;

    if ($scalar =~ /^(\d+)'([0-9a-fA-F_]+)$/) {
        my ($width, $value) = ($1, $2);
        $value =~ s/_//g;
        return FSM::CoreAST::Literal->new($value, width => $width, radix => 'decimal');
    } elsif ($scalar =~ /^const_(\d+)b([01xXzZ_]+)$/) {
        # Common FSMGen constant encoding, e.g. const_8b0 / const_16b0000_1111
        my ($width, $value) = ($1, $2);
        $value =~ s/_//g;
        fsm_debug("          CONST LITERAL: '$scalar' -> ${width}'b$value", 3);
        return FSM::CoreAST::Literal->new($value, width => $width, radix => 'binary');
    } elsif ($scalar =~ /^(.+?)(==|!=|<=|>=|=|<|>)(.+)$/) {
        my ($lhs_spec, $operator, $rhs_spec) = ($1, $2, $3);
        $lhs_spec =~ s/^\s+|\s+$//g;
        $rhs_spec =~ s/^\s+|\s+$//g;
        $operator = '==' if $operator eq '=';

        my $lhs = $self->parse_expression($lhs_spec);
        my $rhs = $self->parse_expression($rhs_spec);

        $self->malformed_inline_comparison_error($scalar)
            unless $lhs && $rhs;

        $self->align_comparison_operand_widths($lhs, $rhs);

        return FSM::CoreAST::BinaryOp->new($operator, $lhs, $rhs);
    } elsif ($scalar =~ /^!([a-zA-Z_]\w*(?:\[[\d:]+\])?)$/) {
        # Legacy compact negation token, e.g. !wren
        my $operand = $self->parse_signal_reference($1);
        return FSM::CoreAST::UnaryOp->new(
            operator => '!',
            operand => $operand
        );
    } elsif ($scalar =~ /^([a-zA-Z_]\w*(?:\.[a-zA-Z_]\w*){2,})$/) {
        Carp::confess
            "Unsupported expression token '$scalar'. ".
            "Active dotted package-qualified symbols must resolve to imported named scalar or enum values before expression parsing. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    } elsif ($scalar =~ /^([a-zA-Z_]\w*)(\.[a-zA-Z_]\w*)?(\[[\d:]+\])?('(\d+))?(\>)?$/) {
        my ($base_name, $member_name, $slice, $width_annotation, $width, $output_marker) = ($1, $2, $3, $4, $5, $6);
        my $full_name = $member_name ? "$base_name$member_name" : $base_name;
        
        my $signal_name = $base_name;
        my $signal = $self->{signal_manager}->register_signal($signal_name, 
            width => $width,
            is_output => defined($output_marker)
        );
        
        if ($slice) {
            if ($slice =~ /\[(\d+):(\d+)\]/) {
                my ($high, $low) = ($1, $2);
                $self->refine_signal_width_from_static_access($signal, (($high > $low) ? $high : $low) + 1);
                return FSM::CoreAST::SignalRef->new($signal, slice => [$high, $low]);
            } elsif ($slice =~ /\[(\d+)\]/) {
                my $index = $1;
                $self->refine_signal_width_from_static_access($signal, $index + 1);
                return FSM::CoreAST::IndexedRef->new($signal, FSM::CoreAST::Literal->new($index));
            }
        }
        
        return FSM::CoreAST::SignalRef->new($signal);
    } elsif (
        $scalar =~ /^.+?(?:==|!=|<=|>=|=|<|>)$/ ||
        $scalar =~ /^(?:==|!=|<=|>=|=|>).+$/ ||
        $scalar =~ /^<(?![A-Za-z_!]).+$/
    ) {
        $self->malformed_inline_comparison_error($scalar);
    } else {
        Carp::confess
            "Unsupported expression token '$scalar'. ".
            "Active expressions must use a literal, a valid signal reference, or a supported operator form. ".
            "Guard-prefixed tokens belong in condition position, not inside ordinary expressions. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }
}

sub parse_common_integer_literal($self, $scalar) {
    return undef unless defined($scalar) && !ref($scalar);

    my $parts = FSM::Package::IntegerLiteralSupport->literal_parts_from_scalar($scalar);
    return undef unless $parts;

    my $width = $parts->{width};
    if (!defined $width && $parts->{value}->bcmp(0) >= 0) {
        $width = $self->intrinsic_width_for_integer_literal_token($scalar, $parts);
    }
    $parts->{width} = $width if defined $width;

    my $literal_payload = FSM::Package::IntegerLiteralSupport->core_literal_payload_from_parts(%$parts);
    return undef unless $literal_payload;

    my %args = (
        radix => $literal_payload->{radix} // 'decimal',
    );
    $args{width} = $literal_payload->{width} if defined $literal_payload->{width};

    return FSM::CoreAST::Literal->new($literal_payload->{value}, %args);

    return undef;
}

sub refine_signal_width_from_static_access($self, $signal, $required_width) {
    return unless $signal && $signal->can('name');
    return unless defined($required_width) && $required_width > 0;

    $self->{signal_manager}->register_signal(
        $signal->name,
        width => $required_width,
    );
}

sub align_comparison_operand_widths($self, $left, $right) {
    my ($left_width, $left_explicit) = $self->infer_expression_width_contract($left);
    my ($right_width, $right_explicit) = $self->infer_expression_width_contract($right);

    if ($left_explicit && !$right_explicit && defined($left_width) && $left_width > 0) {
        $self->propagate_width_to_expression($right, $left_width);
        return;
    }

    if ($right_explicit && !$left_explicit && defined($right_width) && $right_width > 0) {
        $self->propagate_width_to_expression($left, $right_width);
        return;
    }
}

sub infer_expression_width_contract($self, $expr) {
    return (undef, 0) unless $expr && blessed($expr);

    if ($expr->isa('FSM::CoreAST::Literal')) {
        my $width = $expr->width;
        return (defined($width) && $width > 0) ? ($width, 1) : (undef, 0);
    }

    if ($expr->isa('FSM::CoreAST::ParameterRef')) {
        my $width = $expr->width;
        return (defined($width) && $width > 0) ? ($width, 1) : (undef, 0);
    }

    if ($expr->isa('FSM::CoreAST::SignalRef')) {
        if ($expr->slice) {
            my ($high, $low) = @{$expr->slice};
            return (abs($high - $low) + 1, 1);
        }

        my $signal = $expr->signal;
        return (undef, 0) unless $signal && $signal->can('width');
        my $width = $signal->width;
        my $explicit = defined($width)
            && $width > 0
            && (
                $width > 1
                || ($signal->can('get_attribute') && $signal->get_attribute('width_declared'))
            );
        return ($width, $explicit ? 1 : 0);
    }

    if ($expr->isa('FSM::CoreAST::IndexedRef')) {
        return (1, 1);
    }

    if ($expr->isa('FSM::CoreAST::AggregateRef')) {
        my $width = $expr->width;
        return (defined($width) && $width > 0) ? ($width, 1) : (undef, 0);
    }

    if ($expr->isa('FSM::CoreAST::Concatenation')) {
        my $width = $self->infer_exact_expression_width($expr);
        return (defined($width) && $width > 0) ? ($width, 1) : (undef, 0);
    }

    return (undef, 0);
}

sub intrinsic_width_for_integer_literal_token($self, $scalar, $parts) {
    my $text = $scalar;
    $text =~ s/_//g;
    $text =~ s/\A[+]//;

    return length($1) if $text =~ /\A0b([01]+)\z/i;
    return length($1) * 3 if $text =~ /\A0o([0-7]+)\z/i;
    return length($1) * 4 if $text =~ /\A0x([0-9a-fA-F]+)\z/i;

    if ($text =~ /\A'(?:s?)([bBoOhHxX])([0-9a-fA-F]+)\z/) {
        return $self->intrinsic_based_literal_width($1, $2);
    }

    return undef;
}

sub literal_radix_name($self, $radix_char) {
    my %radix_map = (
        b => 'binary',
        d => 'decimal',
        o => 'octal',
        h => 'hex',
        x => 'hex',
    );

    return $radix_map{lc($radix_char // 'd')} // 'decimal';
}

sub intrinsic_based_literal_width($self, $radix_char, $digits) {
    my $digit_count = length($digits // '');
    return $digit_count if lc($radix_char // '') eq 'b';
    return $digit_count * 3 if lc($radix_char // '') eq 'o';
    return $digit_count * 4 if lc($radix_char // '') eq 'h' || lc($radix_char // '') eq 'x';
    return undef;
}

sub parse_typed_aggregate_signal_reference($self, $scalar) {
    return undef unless defined($scalar) && $scalar =~ /\A([a-zA-Z_]\w*)((?:\.[a-zA-Z_]\w*|\[\d+(?::\d+)?\])+)(?:'(\d+))?(\>)?\z/;

    my ($base_name, $path_text, $width_annotation, $output_marker) = ($1, $2, $3, $4);
    my $signal = $self->{signal_manager}->get_signal($base_name);
    return undef unless $signal;

    my $type_spec = eval { $signal->declared_type_spec };
    if (ref($type_spec) ne 'HASH') {
        Carp::confess
            "Malformed typed aggregate signal access '$scalar'. ".
            "Signal '$base_name' has no declared aggregate type, so member access is not available. ".
            "Declare an aggregate `+types` alias and use it from `+size` before accessing fields.\n"
            if $path_text =~ /^\./;
        return undef;
    }

    my $root_kind = $type_spec->{kind} || '';
    if ($root_kind ne 'list' && $root_kind ne 'record') {
        Carp::confess
            "Malformed typed aggregate signal access '$scalar'. ".
            "Signal '$base_name' has scalar type '".
            FSM::Package::PayloadTypeSupport->type_spec_label($type_spec).
            "', so record member access is not available.\n"
            if $path_text =~ /^\./;
        return undef;
    }

    my ($path, $resolved_type_spec, $resolved_width) = $self->resolve_typed_aggregate_signal_path(
        $base_name,
        $path_text,
        $type_spec,
        $scalar,
    );

    if (defined($width_annotation) && $width_annotation != $resolved_width) {
        my $type_label = FSM::Package::PayloadTypeSupport->type_spec_label($resolved_type_spec);
        Carp::confess
            "Malformed typed aggregate signal access '$scalar'. ".
            "Width annotation '$width_annotation' does not match resolved path width '$resolved_width' ($type_label). ".
            "Remove the annotation or declare a matching aggregate member type before generation.\n";
    }

    if (defined($output_marker)) {
        $signal = $self->{signal_manager}->register_signal(
            $base_name,
            is_output => 1,
        );
    }

    return FSM::CoreAST::AggregateRef->new(
        $signal,
        $path,
        type_spec => $resolved_type_spec,
        width => $resolved_width,
    );
}

sub resolve_typed_aggregate_signal_path($self, $base_name, $path_text, $root_type_spec, $raw_scalar) {
    my $result = FSM::Package::AggregatePathSupport->resolve(
        root_type_spec => $root_type_spec,
        path_text => $path_text,
    );

    $self->confess_typed_aggregate_signal_path_error($result, $base_name, $raw_scalar)
        unless $result->{ok};

    return (
        FSM::Package::AggregatePathSupport->clone_structured_value($result->{path_segments}),
        FSM::Package::AggregatePathSupport->clone_structured_value($result->{type_spec}),
        $result->{width},
    );
}

sub confess_typed_aggregate_signal_path_error($self, $error, $base_name, $raw_scalar) {
    my $code = $error->{code} || 'unknown';

    if ($code eq 'missing_declared_type') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Signal '$base_name' has no declared aggregate type, so member access is not available. ".
            "Declare an aggregate `+types` alias and use it from `+size` before accessing fields.\n";
    }

    if ($code eq 'scalar_root') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Signal '$base_name' has scalar type '".($error->{current_type_label} || 'unknown').
            "', so record member access is not available.\n";
    }

    if ($code eq 'empty_path') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Could not parse an empty aggregate path. ".
            "Use record member access like '.field' and list/scalar constant indexes like '[0]'.\n";
    }

    if ($code eq 'member_on_non_record') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Member access '.".$error->{member_name}."' is only valid on record-typed values; current path type is '".
            ($error->{current_type_label} || 'unknown')."'. ".
            "Use '[N]' for list items or declare a record member before generation.\n";
    }

    if ($code eq 'unknown_member') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Record type for '$base_name' has no member '".$error->{member_name}."'. ".
            "Known members: " . join(', ', @{ $error->{known_members} || [] }) . ".\n";
    }

    if ($code eq 'list_range_not_supported') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "List item access currently accepts one constant index, not a range. ".
            "Select one list element with '[N]' before generation.\n";
    }

    if ($code eq 'list_index_out_of_range') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "List index '".$error->{index}."' is outside the declared item range 0..".
            ($error->{max_index} // -1).".\n";
    }

    if ($code eq 'scalar_slice_out_of_range') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Scalar slice [".$error->{high}.":".$error->{low}."] exceeds resolved scalar width '".$error->{scalar_width}."'.\n";
    }

    if ($code eq 'scalar_index_out_of_range') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Scalar index '".$error->{index}."' exceeds resolved scalar width '".$error->{scalar_width}."'.\n";
    }

    if ($code eq 'index_on_non_indexable') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Index access is valid on list and scalar bit-vector values; current path type is '".
            ($error->{current_type_label} || 'unknown')."'.\n";
    }

    if ($code eq 'parse_error') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Could not parse remaining path '".($error->{remaining} || '')."'. ".
            "Use record member access like '.field' and list/scalar constant indexes like '[0]'.\n";
    }

    if ($code eq 'missing_leaf_width') {
        Carp::confess
            "Unsupported typed aggregate signal access '$raw_scalar'. ".
            "The resolved aggregate leaf has no positive packed width. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }

    Carp::confess
        "Malformed typed aggregate signal access '$raw_scalar'. ".
        "Aggregate path resolution failed unexpectedly. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}

sub parse_sexpr_expression($self, $sexpr) {
    my ($operator, @operands) = @$sexpr;

    if (@operands == 1 && ref($operands[0]) eq 'ARRAY') {
        @operands = @{$operands[0]};
    }

    fsm_debug("          S-expression: $operator with " . scalar(@operands) . " operands", 3);
    
    Carp::confess
        "Unsupported expression operator '$operator'. ".
        "Active expression operators currently include '!', '==', '!=', '<', '<=', '>', '>=', '+', '-', '*', '/', '%', '&', '|', '^', 'concat' and their documented aliases. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}

sub infer_exact_expression_width($self, $expr) {
    return undef unless $expr && blessed($expr);

    if ($expr->isa('FSM::CoreAST::Literal')) {
        my $width = $expr->width;
        return (defined($width) && $width > 0) ? $width : undef;
    }

    if ($expr->isa('FSM::CoreAST::ParameterRef')) {
        my $width = $expr->width;
        return (defined($width) && $width > 0) ? $width : undef;
    }

    if ($expr->isa('FSM::CoreAST::SignalRef')) {
        if ($expr->slice) {
            my ($high, $low) = @{$expr->slice};
            return abs($high - $low) + 1;
        }

        my $signal = $expr->signal;
        return undef unless $signal && $signal->can('width');
        my $width = $signal->width;
        return (defined($width) && $width > 0) ? $width : undef;
    }

    if ($expr->isa('FSM::CoreAST::IndexedRef')) {
        return 1;
    }

    if ($expr->isa('FSM::CoreAST::AggregateRef')) {
        my $width = $expr->width;
        return $width if defined($width) && $width > 0;

        my $type_spec = $expr->type_spec;
        return $type_spec->{width}
            if ref($type_spec) eq 'HASH' && defined($type_spec->{width}) && $type_spec->{width} > 0;
        return undef;
    }

    if ($expr->isa('FSM::CoreAST::UnaryOp')) {
        return 1 if $expr->operator eq '!';
        return $self->infer_exact_expression_width($expr->operand);
    }

    if ($expr->isa('FSM::CoreAST::BinaryOp')) {
        my $operator = $expr->operator;
        return 1 if defined($operator) && $operator =~ /^(?:==|!=|<|>|<=|>=)$/;

        my $left_width = $self->infer_exact_expression_width($expr->left);
        my $right_width = $self->infer_exact_expression_width($expr->right);
        return undef unless defined($left_width) && defined($right_width);
        return $left_width > $right_width ? $left_width : $right_width;
    }

    if ($expr->isa('FSM::CoreAST::Concatenation')) {
        my $total_width = 0;
        for my $operand (@{$expr->operands}) {
            my $operand_width = $self->infer_exact_expression_width($operand);
            return undef unless defined($operand_width) && $operand_width > 0;
            $total_width += $operand_width;
        }
        return $total_width > 0 ? $total_width : undef;
    }

    return undef;
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
