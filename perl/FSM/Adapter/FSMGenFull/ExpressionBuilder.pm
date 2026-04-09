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
    );

    my $normalized = $operator_aliases{$operator} // $operator;
    my %supported = map { $_ => 1 } qw(! == != < <= > >= & | ^ + - * / %);
    return $supported{$normalized} ? $normalized : undef;
}

sub operator_family_for($self, $normalized_operator) {
    return 'unary' if defined $normalized_operator && $normalized_operator eq '!';
    return 'comparison'
        if defined $normalized_operator && $normalized_operator =~ /^(?:==|!=|<|<=|>|>=)$/;
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
        "Active expression operators currently include '!', '==', '!=', '<', '<=', '>', '>=', '+', '-', '*', '/', '%', '&', '|', '^' and their documented aliases. ".
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
        fsm_debug("          SYMBOL RESOLVED: '$scalar' -> literal/constant", 3);
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
    } elsif ($scalar =~ /^(.+?)(==|!=|<=|>=|=|<|>)(.+)$/) {
        my ($lhs_spec, $operator, $rhs_spec) = ($1, $2, $3);
        $lhs_spec =~ s/^\s+|\s+$//g;
        $rhs_spec =~ s/^\s+|\s+$//g;
        $operator = '==' if $operator eq '=';

        my $lhs = $self->parse_expression($lhs_spec);
        my $rhs = $self->parse_expression($rhs_spec);

        $self->malformed_inline_comparison_error($scalar)
            unless $lhs && $rhs;

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
                return FSM::CoreAST::SignalRef->new($signal, slice => [$1, $2]);
            } elsif ($slice =~ /\[(\d+)\]/) {
                return FSM::CoreAST::IndexedRef->new($signal, FSM::CoreAST::Literal->new($1));
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

    my ($path, $resolved_type_spec) = $self->resolve_typed_aggregate_signal_path(
        $base_name,
        $path_text,
        $type_spec,
        $scalar,
    );

    my $resolved_width = ref($resolved_type_spec) eq 'HASH' ? ($resolved_type_spec->{width} // undef) : undef;
    Carp::confess
        "Unsupported typed aggregate signal access '$scalar'. ".
        "The resolved aggregate leaf has no positive packed width. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless defined($resolved_width) && $resolved_width > 0;

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
    my $remaining = $path_text;
    my $current_type_spec = $root_type_spec;
    my @path;

    while (length $remaining) {
        if ($remaining =~ s/\A\.([a-zA-Z_]\w*)//) {
            my $member_name = $1;
            my $kind = $current_type_spec->{kind} || '';

            Carp::confess
                "Malformed typed aggregate signal access '$raw_scalar'. ".
                "Member access '.$member_name' is only valid on record-typed values; current path type is '".
                FSM::Package::PayloadTypeSupport->type_spec_label($current_type_spec)."'. ".
                "Use '[N]' for list items or declare a record member before generation.\n"
                unless $kind eq 'record';

            my $members = $current_type_spec->{members} || {};
            Carp::confess
                "Malformed typed aggregate signal access '$raw_scalar'. ".
                "Record type for '$base_name' has no member '$member_name'. ".
                "Known members: " . join(', ', @{ $current_type_spec->{member_order} || [] }) . ".\n"
                unless exists $members->{$member_name};

            push @path, { kind => 'member', name => $member_name };
            $current_type_spec = $members->{$member_name};
            next;
        }

        if ($remaining =~ s/\A\[(\d+)(?::(\d+))?\]//) {
            my ($first_index, $second_index) = ($1, $2);
            my $kind = $current_type_spec->{kind} || '';

            if ($kind eq 'list') {
                Carp::confess
                    "Malformed typed aggregate signal access '$raw_scalar'. ".
                    "List item access currently accepts one constant index, not a range. ".
                    "Select one list element with '[N]' before generation.\n"
                    if defined $second_index;

                my $items = $current_type_spec->{items} || [];
                Carp::confess
                    "Malformed typed aggregate signal access '$raw_scalar'. ".
                    "List index '$first_index' is outside the declared item range 0..".
                    (@$items ? $#$items : -1).".\n"
                    unless $first_index < @$items;

                push @path, { kind => 'item', index => 0 + $first_index };
                $current_type_spec = $items->[$first_index];
                next;
            }

            if ($kind eq 'bit' || $kind eq 'bits') {
                my $scalar_width = $current_type_spec->{width} // 0;
                if (defined $second_index) {
                    my ($high, $low) = ($first_index, $second_index);
                    my $max_index = $high > $low ? $high : $low;
                    Carp::confess
                        "Malformed typed aggregate signal access '$raw_scalar'. ".
                        "Scalar slice [$high:$low] exceeds resolved scalar width '$scalar_width'.\n"
                        unless $scalar_width > 0 && $max_index < $scalar_width;

                    my $slice_width = abs($high - $low) + 1;
                    push @path, { kind => 'bit_slice', high => 0 + $high, low => 0 + $low };
                    $current_type_spec = FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width($slice_width);
                    next;
                }

                Carp::confess
                    "Malformed typed aggregate signal access '$raw_scalar'. ".
                    "Scalar index '$first_index' exceeds resolved scalar width '$scalar_width'.\n"
                    unless $scalar_width > 0 && $first_index < $scalar_width;

                push @path, { kind => 'bit_index', index => 0 + $first_index };
                $current_type_spec = FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width(1);
                next;
            }

            Carp::confess
                "Malformed typed aggregate signal access '$raw_scalar'. ".
                "Index access is valid on list and scalar bit-vector values; current path type is '".
                FSM::Package::PayloadTypeSupport->type_spec_label($current_type_spec)."'.\n";
        }

        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Could not parse remaining path '$remaining'. ".
            "Use record member access like '.field' and list/scalar constant indexes like '[0]'.\n";
    }

    return (\@path, $current_type_spec);
}

sub parse_sexpr_expression($self, $sexpr) {
    my ($operator, @operands) = @$sexpr;

    if (@operands == 1 && ref($operands[0]) eq 'ARRAY') {
        @operands = @{$operands[0]};
    }

    fsm_debug("          S-expression: $operator with " . scalar(@operands) . " operands", 3);
    
    Carp::confess
        "Unsupported expression operator '$operator'. ".
        "Active expression operators currently include '!', '==', '!=', '<', '<=', '>', '>=', '+', '-', '*', '/', '%', '&', '|', '^' and their documented aliases. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
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
