package FSM::WidthExpressionSupport;

use v5.20;
use strict;
use warnings;
use Carp ();
use JSON::PP;
use feature qw(signatures);
no warnings 'experimental::signatures';
use FSM::Package::IntegerLiteralSupport;

sub new($class, %args) {
    for my $hook (qw(resolve_symbol_payload resolve_parameter_payload resolve_symbol_observation)) {
        Carp::confess "Width evaluator '$hook' must be a callback.\n"
            if exists($args{$hook}) && ref($args{$hook}) ne 'CODE';
    }
    my $self = bless {map {$_ => $args{$_}} qw(resolve_symbol_payload resolve_parameter_payload)}, $class;
    $self->{resolve_symbol_observation} = $args{resolve_symbol_observation}
        if exists $args{resolve_symbol_observation};
    return $self;
}

sub _resolve_width_symbol_observation($self, $name) {
    Carp::confess "Width capture requires a symbol observation resolver.\n"
        unless $self->{resolve_symbol_observation};
    return $self->{resolve_symbol_observation}->($name);
}

sub _copy_width_capture_value($value) {
    my $json = JSON::PP->new->canonical->allow_nonref;
    my $copy = eval {$json->decode($json->encode($value))};
    Carp::confess "Width capture requires a plain JSON value: $@" if $@;
    return $copy;
}

sub capture_positive_width_expression($self, $expression, $context) {
    my $source = _copy_width_capture_value($expression);
    my $capture = {stack => [], observations => [], active => {}};
    local $self->{_width_capture} = $capture;
    my $width = $self->resolve_positive_width_expression($source, $context);
    Carp::confess "$context width capture has an incomplete expression stack.\n"
        unless @{$capture->{stack}} == 1;
    return _copy_width_capture_value({width => $width, binding => $capture->{stack}[0],
        observations => $capture->{observations}});
}

sub _capture_width_literal($self, $token) {
    return unless my $capture = $self->{_width_capture};
    push @{$capture->{stack}}, {kind => 'literal', token => $token};
}

sub _capture_width_operator($self, $operator, $arity) {
    return unless my $capture = $self->{_width_capture};
    Carp::confess "Width capture has incomplete operator operands.\n"
        unless @{$capture->{stack}} >= $arity;
    my @operands = splice @{$capture->{stack}}, -$arity, $arity;
    push @{$capture->{stack}}, {kind => 'operator', operator => $operator, operands => \@operands};
}

sub _validate_width_capture_observation($observation, $token) {
    Carp::confess "Width capture requires a complete symbol observation.\n"
        unless ref($observation) eq 'HASH' && defined($observation->{kind})
            && !ref($observation->{kind})
            && $observation->{kind} =~ /\A(?:static_symbol|parameter)\z/;
    my @expected = qw(kind token value_payload);
    push @expected, qw(parameter suffix) if $observation->{kind} eq 'parameter';
    Carp::confess "Width capture observation has unsupported members.\n"
        unless join(',', sort keys %$observation) eq join(',', sort @expected);
    Carp::confess "Width capture observation does not match the selected token.\n"
        unless defined($observation->{token}) && !ref($observation->{token})
            && $observation->{token} eq $token;
    if ($observation->{kind} eq 'parameter') {
        my ($root, $suffix) = @{$observation}{qw(parameter suffix)};
        Carp::confess "Width capture observation has inconsistent parameter identity.\n"
            unless defined($root) && !ref($root) && $root =~ /\A[A-Za-z_]\w*\z/
                && defined($suffix) && !ref($suffix)
                && $suffix =~ /\A(?:\.[A-Za-z_]\w*|\[\d+\])*\z/
                && $root . $suffix eq $token;
    }
    return _copy_width_capture_value($observation);
}

sub _capture_width_reference($self, $lookup, $token, $context) {
    my $capture = $self->{_width_capture};
    my $key = "$lookup:$token";
    Carp::confess "$context has a cyclic width reference lookup '$token'.\n"
        if $capture->{active}{$key};
    local $capture->{active}{$key} = 1;
    my $observation;
    {
        # A resolver's own work is outside this expression's operand stack.
        local $self->{_width_capture};
        $observation = $lookup eq 'parameter'
            ? {kind => 'parameter', token => $token, parameter => $token, suffix => '',
                value_payload => $self->_resolve_width_parameter_payload($token)}
            : $self->_resolve_width_symbol_observation($token);
    }
    $observation = _validate_width_capture_observation($observation, $token)
        if defined $observation;
    my $payload = defined($observation) ? $observation->{value_payload} : undef;
    unless (defined $payload) {
        Carp::confess "$context references unknown declared parameter '$token'.\n"
            if $lookup eq 'parameter';
        Carp::confess "$context references unknown or non-scalar constant symbol '$token'.\n";
    }
    my $index = @{$capture->{observations}};
    push @{$capture->{observations}}, {lookup => $lookup, %$observation};
    my $before = @{$capture->{stack}};
    my $label = $lookup eq 'parameter' ? 'parameter' : 'symbol';
    my $value = $self->evaluate_constant_integer_payload(
        _copy_width_capture_value($payload), "$context $label '$token'");
    Carp::confess "$context width capture has an incomplete selected payload.\n"
        unless @{$capture->{stack}} == $before + 1;
    my $expression = pop @{$capture->{stack}};
    push @{$capture->{stack}}, {kind => 'reference', observation_index => $index,
        value_expression => $expression};
    return $value;
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
        return $self->_capture_width_reference('parameter', $name, $context)
            if $self->{_width_capture};
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

    my $value = $self->apply_constant_width_operator($normalized_operator, \@values, $context);
    $self->{_width_capture}{stack}[-1]{operator} = $operator if $self->{_width_capture};
    return $value;
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

    $self->_capture_width_operator($operator, scalar @$values);
    return $result;
}

sub evaluate_constant_integer_scalar($self, $scalar, $context) {
    my $source_token = $scalar;
    my $literal_value = $self->parse_constant_integer_literal($scalar);
    if (defined $literal_value) {
        $self->_capture_width_literal($source_token);
        return $literal_value;
    }

    return $self->_capture_width_reference('symbol', $scalar, $context)
        if $self->{_width_capture};

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
        my $source_token = $payload;
        my $literal_value = $self->parse_constant_integer_literal($payload);
        Carp::confess "$context payload '$payload' is not an integer literal.\n"
            unless defined $literal_value;
        $self->_capture_width_literal($source_token);
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
operator aliases, arity and infix precedence. Completed operator results
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

Ordinary evaluation neither stores results nor mutates source trees or resolver
payloads. It continues to use only the existing payload callbacks.

=head2 capture_positive_width_expression($expression, $context)

Opt-in capture returns detached plain C<width>, C<binding> and C<observations>
records while the existing evaluator performs its actual prefix/infix walk.
Literal binding nodes retain C<token>. Operator nodes retain C<operator> and
ordered C<operands>, including source aliases and infix precedence. Reference
nodes retain C<observation_index> and the selected payload's structured
C<value_expression>. Nested references in scalar-expression payloads survive;
repeated references keep distinct ordered observations.

Ordinary symbols require a C<resolve_symbol_observation> callback, or an
inherited C<_resolve_width_symbol_observation> implementation. It must return
undef or a plain record with exactly C<kind>, C<token>, C<value_payload>, plus
C<parameter> and C<suffix> for C<kind=parameter>. The other admitted kind is
C<static_symbol>. The token must match the actual lookup; a parameter root and
suffix must compose that token. This callback supplies the actual selected
payload once; capture does not replay the ordinary payload callback or infer
namespace identity. Explicit C<(param NAME)> uses the existing declared-only
parameter hook. Returned observations add C<lookup=parameter> or C<lookup=symbol>
to distinguish those entrypoints. Undefined selected payloads retain ordinary
unknown-value refusal meanings.

Callback work is isolated from the outer operand stack. Capture state is local
to one invocation and disappears on success, refusal or retry. JSON-incompatible
or cyclic records, cyclic captured lookups, malformed observations and invalid
canonical widths refuse without a partial result. Input/result records and
callback payloads remain detached; no callback or evaluator is returned.
Captured records do not attest caller-provided namespace provenance and carry
no lexical or target scope. Parser/Core publication, target profile admission
and symbolic HDL ranges remain separate consumers.

The direct Parser inherits the arithmetic methods and supplies its existing
SignalManager namespaces through explicit hooks. Composition integration is a
separate consumer; this extraction changes no source or HDL admission.

=cut
