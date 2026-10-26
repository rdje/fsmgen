package FSM::WidthExpressionSupport;

use v5.20;
use strict;
use warnings;
use Carp ();
use feature qw(signatures);
no warnings 'experimental::signatures';
use FSM::Package::IntegerLiteralSupport;

sub new($class, %args) {
    for my $hook (qw(resolve_symbol_payload resolve_parameter_payload)) {
        Carp::confess "Width evaluator '$hook' must be a callback.\n"
            if exists($args{$hook}) && ref($args{$hook}) ne 'CODE';
    }
    return bless {map {$_ => $args{$_}} qw(resolve_symbol_payload resolve_parameter_payload)}, $class;
}

sub _resolve_width_symbol_payload($self, $name) {
    return $self->{resolve_symbol_payload} ? $self->{resolve_symbol_payload}->($name) : undef;
}

sub _resolve_width_parameter_payload($self, $name) {
    return $self->{resolve_parameter_payload} ? $self->{resolve_parameter_payload}->($name) : undef;
}

sub unwrap_scalar_token($self, $value) {
    my $unwrapped = $value;
    while (ref($unwrapped) eq 'ARRAY' && @$unwrapped == 1) {
        $unwrapped = $unwrapped->[0];
    }
    return $unwrapped;
}

sub is_contract_identifier($self, $value) {
    return defined($value) && !ref($value) && $value =~ /\A[A-Za-z_]\w*\z/;
}

sub resolve_positive_width_expression($self, $width_expr, $context) {
    my $value = $self->evaluate_constant_integer_expression($width_expr, $context);
    return undef unless defined $value;

    Carp::confess "$context must resolve to a positive integer width.\n"
        unless $value->bcmp(0) > 0;

    return 0 + $value->bstr;
}

sub evaluate_constant_integer_expression($self, $expr, $context) {
    my $normalized = $self->unwrap_scalar_token($expr);

    if (defined($normalized) && !ref($normalized)) {
        return $self->evaluate_constant_integer_scalar($normalized, $context);
    }

    Carp::confess "$context is malformed because the expression payload is empty.\n"
        unless ref($normalized) eq 'ARRAY' && @$normalized;

    my ($operator, @operands) = @$normalized;
    Carp::confess "$context is malformed because the expression operator is not a scalar token.\n"
        if ref($operator);

    if (defined($operator) && $operator eq 'param') {
        my @names = @operands;
        @names = @{$names[0]} if @names == 1 && ref($names[0]) eq 'ARRAY';
        my $name = @names == 1 ? $self->unwrap_scalar_token($names[0]) : undef;
        Carp::confess "$context selector 'param' requires exactly one declared parameter name.\n"
            unless @names == 1 && $self->is_contract_identifier($name);
        my $payload = $self->_resolve_width_parameter_payload($name);
        Carp::confess "$context references unknown declared parameter '$name'.\n"
            unless defined $payload;
        return $self->evaluate_constant_integer_payload($payload, "$context parameter '$name'");
    }

    my $normalized_operator = $self->normalize_constant_width_operator($operator);
    Carp::confess
        "$context uses unsupported width expression operator '$operator'. ".
        "Supported operators are '+', '-', '*', '/', '%', '&', '|', '^' and aliases 'add', 'sub', 'mul', 'div', 'mod', 'and', 'or', 'xor'.\n"
        unless defined $normalized_operator;

    if (@operands == 1 && ref($operands[0]) eq 'ARRAY') {
        @operands = @{$operands[0]};
    }

    Carp::confess "$context operator '$operator' requires at least two operands.\n"
        unless @operands >= 2;

    my @values = map {
        $self->evaluate_constant_integer_expression($_, "$context operand for '$operator'")
    } @operands;

    return $self->apply_constant_width_operator($normalized_operator, \@values, $context);
}

sub normalize_constant_width_operator($self, $operator) {
    return undef unless defined($operator) && !ref($operator);

    my %operator_aliases = (
        add => '+',
        sub => '-',
        mul => '*',
        div => '/',
        mod => '%',
        and => '&',
        or  => '|',
        xor => '^',
    );

    my $normalized = $operator_aliases{$operator} // $operator;
    my %supported = map { $_ => 1 } qw(+ - * / % & | ^);
    return $supported{$normalized} ? $normalized : undef;
}

sub apply_constant_width_operator($self, $operator, $values, $context) {
    Carp::confess "$context has no width-expression operands.\n"
        unless ref($values) eq 'ARRAY' && @$values;

    my $result = $values->[0]->copy;
    for my $index (1 .. $#$values) {
        my $operand = $values->[$index];
        if ($operator eq '+') {
            $result->badd($operand);
        } elsif ($operator eq '-') {
            $result->bsub($operand);
        } elsif ($operator eq '*') {
            $result->bmul($operand);
        } elsif ($operator eq '/') {
            Carp::confess "$context divides by zero in a width expression.\n"
                if $operand->is_zero;
            $result->bdiv($operand);
        } elsif ($operator eq '%') {
            Carp::confess "$context takes modulo by zero in a width expression.\n"
                if $operand->is_zero;
            $result->bmod($operand);
        } elsif ($operator eq '&') {
            $result->band($operand);
        } elsif ($operator eq '|') {
            $result->bior($operand);
        } elsif ($operator eq '^') {
            $result->bxor($operand);
        } else {
            Carp::confess "$context uses unsupported width expression operator '$operator'.\n";
        }
    }

    Carp::confess "$context resolved to a negative width-expression value.\n"
        if $result->bcmp(0) < 0;

    return $result;
}

sub evaluate_constant_integer_scalar($self, $scalar, $context) {
    my $literal_value = $self->parse_constant_integer_literal($scalar);
    return $literal_value if defined $literal_value;

    my $payload = $self->_resolve_width_symbol_payload($scalar);
    if (defined $payload) {
        return $self->evaluate_constant_integer_payload($payload, "$context symbol '$scalar'");
    }

    Carp::confess "$context references unknown or non-scalar constant symbol '$scalar'.\n";
}

sub evaluate_constant_integer_payload($self, $payload, $context) {
    Carp::confess "$context has no constant payload.\n"
        unless defined $payload;

    if (!ref($payload)) {
        my $literal_value = $self->parse_constant_integer_literal($payload);
        Carp::confess "$context payload '$payload' is not an integer literal.\n"
            unless defined $literal_value;
        return $literal_value;
    }

    Carp::confess "$context has malformed constant payload '".ref($payload)."'.\n"
        unless ref($payload) eq 'HASH';

    my $kind = $payload->{kind} || '';
    if ($kind eq 'scalar') {
        return $self->evaluate_constant_integer_payload($payload->{payload}, $context);
    }

    if ($kind eq 'scalar_expr') {
        return $self->evaluate_infix_constant_integer_expression(
            $payload->{payload},
            "$context scalar expression",
        );
    }

    Carp::confess "$context resolved to aggregate payload kind '$kind', not a scalar integer.\n";
}

sub evaluate_infix_constant_integer_expression($self, $expr_text, $context) {
    Carp::confess "$context has no expression text.\n"
        unless defined($expr_text) && !ref($expr_text) && length($expr_text);

    my @tokens = $self->tokenize_infix_constant_integer_expression($expr_text, $context);
    my $index = 0;
    my $value = $self->parse_infix_expression_bp(\@tokens, \$index, 0, $context);

    Carp::confess "$context has trailing tokens after scalar expression.\n"
        if $index < @tokens;

    return $value;
}

sub tokenize_infix_constant_integer_expression($self, $expr_text, $context) {
    my @tokens;
    my $expect_operand = 1;
    pos($expr_text) = 0;
    while (pos($expr_text) < length($expr_text)) {
        if ($expr_text =~ /\G\s+/gc) {
            next;
        }
        if ($expr_text =~ /\G([()])\s*/gc) {
            push @tokens, $1;
            $expect_operand = $1 eq '(' ? 1 : 0;
            next;
        }
        if ($expr_text =~ /\G([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?(?:\[\d+\])*)\s*/gc) {
            push @tokens, $1;
            $expect_operand = 0;
            next;
        }
        my $literal_pattern = $expect_operand
            ? qr/\d+'(?:s?[bodhx][+-]?[0-9A-Fa-f_]+|[+-]?(?:0[dbohx][+-]?[0-9A-Fa-f_]+|\d[\d_]*))|(?:\d+)?'s?[bodhx][+-]?[0-9A-Fa-f_]+|[+-]?0d[+-]?\d[\d_]*|[+-]?0x[+-]?[0-9A-Fa-f_]+|[+-]?0b[+-]?[01_]+|[+-]?0o[+-]?[0-7_]+|[+-]?\d[\d_]*/i
            : qr/\d+'(?:s?[bodhx][+-]?[0-9A-Fa-f_]+|(?:0[dbohx][+-]?[0-9A-Fa-f_]+|\d[\d_]*))|(?:\d+)?'s?[bodhx][+-]?[0-9A-Fa-f_]+|0d[+-]?\d[\d_]*|0x[+-]?[0-9A-Fa-f_]+|0b[+-]?[01_]+|0o[+-]?[0-7_]+|\d[\d_]*/i;
        if ($expr_text =~ /\G($literal_pattern)\s*/gc) {
            push @tokens, $1;
            $expect_operand = 0;
            next;
        }
        if ($expr_text =~ /\G([+\-*\/%&|^])\s*/gc) {
            push @tokens, $1;
            $expect_operand = 1;
            next;
        }

        Carp::confess "$context contains unsupported token near '".substr($expr_text, pos($expr_text), 24)."'.\n";
    }

    return @tokens;
}

sub parse_infix_expression_bp($self, $tokens, $index_ref, $min_bp, $context) {
    Carp::confess "$context ended unexpectedly.\n"
        if $$index_ref >= @$tokens;

    my $token = $tokens->[$$index_ref++];
    my $left;
    if ($token eq '(') {
        $left = $self->parse_infix_expression_bp($tokens, $index_ref, 0, $context);
        Carp::confess "$context is missing a closing parenthesis.\n"
            unless $$index_ref < @$tokens && $tokens->[$$index_ref] eq ')';
        $$index_ref++;
    } else {
        $left = $self->evaluate_constant_integer_scalar($token, $context);
    }

    while ($$index_ref < @$tokens) {
        my $operator = $tokens->[$$index_ref];
        last if $operator eq ')';

        my ($left_bp, $right_bp) = $self->constant_infix_binding_power($operator);
        last unless defined $left_bp && $left_bp >= $min_bp;

        $$index_ref++;
        my $right = $self->parse_infix_expression_bp($tokens, $index_ref, $right_bp, $context);
        $left = $self->apply_constant_width_operator($operator, [$left, $right], $context);
    }

    return $left;
}

sub constant_infix_binding_power($self, $operator) {
    return unless defined($operator) && !ref($operator);
    return (1, 2) if $operator eq '|';
    return (3, 4) if $operator eq '^';
    return (5, 6) if $operator eq '&';
    return (7, 8) if $operator eq '+' || $operator eq '-';
    return (9, 10) if $operator eq '*' || $operator eq '/' || $operator eq '%';
    return;
}

sub parse_constant_integer_literal($self, $literal) {
    return FSM::Package::IntegerLiteralSupport->integer_from_literal_like($literal);
}

1;

=head1 NAME

FSM::WidthExpressionSupport - Canonical bounded integer-width expression evaluation

=head1 DESCRIPTION

Shares the direct FSM parser's existing width arithmetic, literal handling,
operator aliases, arity and infix precedence. Intermediate arithmetic results
must be nonnegative; C<resolve_positive_width_expression> also requires a
positive final value. Division and modulo by zero refuse. No general parameter
expression operators are added.

C<new> accepts optional C<resolve_symbol_payload> and
C<resolve_parameter_payload> callbacks. Each receives the actual selected name
and returns a canonical scalar or scalar-expression payload, or undef for an
unknown name. The C<(param NAME)> selector uses only the declared-parameter
callback; ordinary symbols and symbols within infix payloads use only the
ordinary-symbol callback. Aggregate payloads refuse. Missing callbacks behave
as empty namespaces. Callers own namespace policy and payload provenance.

Evaluation neither stores results nor mutates source trees or resolver payloads.
The direct Parser inherits the arithmetic methods and supplies its existing
SignalManager namespaces through explicit hooks. Composition integration is a
separate consumer; this extraction changes no source or HDL admission.

=cut
