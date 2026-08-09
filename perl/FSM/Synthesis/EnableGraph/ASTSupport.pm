package FSM::Synthesis::EnableGraph::ASTSupport;

=head1 NAME

FSM::Synthesis::EnableGraph::ASTSupport - Own AST rendering and operator-classification support for EnableGraph

=head1 DESCRIPTION

This package owns the bounded AST rendering/classification family that used to
live inline inside C<FSM::Synthesis::EnableGraph>. It centralizes:

=over 4

=item *

AST-to-SystemVerilog rendering with operand-aware operator selection

=item *

single-bit operand classification used by logical-versus-bitwise rendering

=item *

AST operator classification for arithmetic, logical, and factorizable
expressions

=back

The broader C<EnableGraph> owner still provides shared backend context,
intermediate-signal classification, and assignment/reset helpers consumed by
this rendering/classification family.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use List::Util qw(min);
use Math::BigInt;
use Scalar::Util qw(blessed);

use FSM::AST::Node;
use FSM::CoreAST;
use FSM::Debug;
use FSM::HDL::ASTFactorization;
use FSM::Package::IntegerLiteralSupport;

=head2 new

Construct an AST-support owner bound to one live
C<FSM::HDL::FlattenedDT> context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ASTSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 ast_to_systemverilog

Render one typed AST node into SystemVerilog using the current direct-backend
operator and precedence rules.

=cut

sub ast_to_systemverilog ($self, $ast) {
    return "1'b1" unless $ast && blessed($ast);

    my $simplified_ast = $self->simplify_logic_ast($ast);
    my $sv = $self->_ast_to_systemverilog_internal($simplified_ast, undef);

    my ($package, $filename, $line, $subroutine) = caller(1);
    fsm_debug("*** AST_TO_SV_DEBUG: $sv ***", 3);
    fsm_debug("    Called from: $subroutine at line $line", 3);
    fsm_debug("    AST type: " . ref($simplified_ast), 3);

    return $sv;
}

=head2 simplify_logic_ast

Return a logically equivalent AST with local boolean/bitwise identities removed
before any HDL text is rendered. Rewrites are deliberately width-conservative:
rules that would change vector semantics are only applied when the expression is
known to be boolean/single-bit.

=cut

sub simplify_logic_ast ($self, $ast) {
    return $ast unless $ast && blessed($ast);

    my $current = $ast;
    for my $iteration (1 .. 16) {
        my $next = $self->_simplify_logic_ast_once($current);
        last if $self->_logic_ast_key($next) eq $self->_logic_ast_key($current);
        $current = $next;
    }

    return $current;
}

sub _simplify_logic_ast_once ($self, $ast) {
    return $ast unless $ast && blessed($ast);

    if ($self->_is_binary_ast($ast)) {
        my $operator = eval { $ast->operator } || '';
        my $left = $self->_simplify_logic_ast_once($ast->left);
        my $right = $self->_simplify_logic_ast_once($ast->right);
        my $rebuilt = $self->_new_binary_like($ast, $operator, $left, $right);

        my $truthiness = $self->_simplify_truthiness_comparison($rebuilt);
        return $self->_simplify_logic_ast_once($truthiness)
            if defined $truthiness
            && $self->_logic_ast_key($truthiness) ne $self->_logic_ast_key($rebuilt);

        my $constant_fold = $self->_simplify_binary_constant_fold($rebuilt);
        return $constant_fold if defined $constant_fold;

        my $vector_identity = $self->_simplify_vector_bitwise_identity($rebuilt);
        return $vector_identity if defined $vector_identity;

        my $identity = $self->_simplify_binary_identity($rebuilt);
        return $identity if defined $identity;

        my $idempotent = $self->_simplify_binary_idempotence($rebuilt);
        return $idempotent if defined $idempotent;

        my $complement = $self->_simplify_binary_complement($rebuilt);
        return $complement if defined $complement;

        my $absorption = $self->_simplify_binary_absorption($rebuilt);
        return $absorption if defined $absorption;

        my $consensus = $self->_simplify_binary_consensus($rebuilt);
        return $consensus if defined $consensus;

        return $rebuilt;
    }

    if ($self->_is_unary_ast($ast)) {
        my $operator = eval { $ast->operator } || '';
        my $operand = $self->_simplify_logic_ast_once($ast->operand);
        my $rebuilt = $self->_new_unary_like($ast, $operator, $operand);

        return $self->_simplify_unary_not($rebuilt)
            if $self->_is_not_operator($operator);

        return $self->_simplify_unary_bitwise_not($rebuilt)
            if $self->_is_bitwise_not_operator($operator);

        return $rebuilt;
    }

    return $ast;
}

sub _simplify_unary_bitwise_not ($self, $ast) {
    my $operand = $ast->operand;

    my $literal_mask = $self->_literal_mask_info($operand);
    if ($literal_mask) {
        my $full_mask = Math::BigInt->bone->blsft($literal_mask->{width})->bsub(1);
        my $result = $literal_mask->{value}->copy->bxor($full_mask);
        return $self->_vector_constant_from_value($literal_mask->{width}, $result);
    }

    if ($self->_is_unary_ast($operand) && $self->_is_bitwise_not_operator(eval { $operand->operator } || '')) {
        my $inner = $operand->operand;
        return $inner if defined $self->_expression_width($inner);
    }

    my $demorgan = $self->_simplify_vector_demorgan_if_shorter($ast);
    return $demorgan if defined $demorgan;

    return $ast;
}

sub _simplify_vector_demorgan_if_shorter ($self, $ast) {
    my $operand = $ast->operand;
    return undef unless $self->_is_binary_ast($operand);

    my $operator = $self->_canonical_logic_operator(eval { $operand->operator } || '');
    return undef unless $operator eq '&' || $operator eq '|';
    return undef unless $self->_known_same_expression_width($operand->left, $operand->right);

    my $dual_operator = $operator eq '&' ? '|' : '&';
    my $candidate = $self->_new_binary_like(
        $operand,
        $dual_operator,
        $self->_new_unary_like($ast, '~', $operand->left),
        $self->_new_unary_like($ast, '~', $operand->right),
    );
    $candidate = $self->_simplify_logic_ast_once($candidate);

    my $candidate_text = $self->_ast_to_systemverilog_internal($candidate, undef);
    my $original_text = $self->_ast_to_systemverilog_internal($ast, undef);
    return length($candidate_text) < length($original_text) ? $candidate : undef;
}

sub _simplify_unary_not ($self, $ast) {
    my $operand = $ast->operand;
    my $constant = $self->_literal_boolean_value($operand);
    return $self->_boolean_constant($constant ? 0 : 1) if defined $constant;

    if ($self->_is_unary_ast($operand) && $self->_is_not_operator(eval { $operand->operator } || '')) {
        my $inner = $operand->operand;
        return $inner if $self->_node_is_booleanish($inner);
    }

    my $demorgan = $self->_simplify_demorgan_if_shorter($ast);
    return $demorgan if defined $demorgan;

    return $ast;
}

sub _simplify_demorgan_if_shorter ($self, $ast) {
    my $operand = $ast->operand;
    return undef unless $self->_is_binary_ast($operand);

    my $operator = $self->_boolean_operator_family(eval { $operand->operator } || '');
    return undef unless $operator eq '&' || $operator eq '|';
    return undef unless $self->_node_is_booleanish($operand->left)
        && $self->_node_is_booleanish($operand->right);

    my $dual_operator = $operator eq '&' ? '|' : '&';
    my $candidate = $self->_new_binary_like(
        $operand,
        $dual_operator,
        $self->_new_unary_like($ast, '!', $operand->left),
        $self->_new_unary_like($ast, '!', $operand->right),
    );
    $candidate = $self->_simplify_logic_ast_once($candidate);

    my $candidate_text = $self->_ast_to_systemverilog_internal($candidate, undef);
    my $original_text = $self->_ast_to_systemverilog_internal($ast, undef);
    return length($candidate_text) < length($original_text) ? $candidate : undef;
}

sub _simplify_truthiness_comparison ($self, $ast) {
    return undef unless $self->_is_binary_ast($ast);

    my $operator = eval { $ast->operator } || '';
    return undef unless $operator eq '==' || $operator eq '!=';

    my ($left_value, $left_known) = $self->_known_literal_numeric_value($ast->left);
    my ($right_value, $right_known) = $self->_known_literal_numeric_value($ast->right);

    if ($left_known && $right_known) {
        my $result = $operator eq '==' ? ($left_value == $right_value) : ($left_value != $right_value);
        return $self->_boolean_constant($result ? 1 : 0);
    }

    my ($signalish_operand, $literal_operand) = $self->_extract_truthiness_operands($ast->left, $ast->right);
    return undef unless $signalish_operand && $literal_operand;
    return undef unless $self->_node_is_booleanish($signalish_operand);

    my $literal_value = $self->_literal_numeric_value($literal_operand);
    return undef unless defined $literal_value;

    if ($literal_value == 0) {
        return $operator eq '!='
            ? $signalish_operand
            : $self->_new_unary_like($ast, '!', $signalish_operand);
    }

    if ($literal_value == 1) {
        return $operator eq '=='
            ? $signalish_operand
            : $self->_new_unary_like($ast, '!', $signalish_operand);
    }

    return undef;
}

sub _simplify_binary_constant_fold ($self, $ast) {
    my $operator = $self->_canonical_logic_operator(eval { $ast->operator } || '');
    return undef unless $operator =~ /^(?:&|\||\^|&&|\|\|)$/;

    my $vector_fold = $self->_simplify_vector_bitwise_constant_fold($ast);
    return $vector_fold if defined $vector_fold;

    my $left_value = $self->_literal_boolean_value($ast->left);
    my $right_value = $self->_literal_boolean_value($ast->right);
    return undef unless defined $left_value && defined $right_value;

    if ($operator eq '&' || $operator eq '&&') {
        return $self->_boolean_constant(($left_value != 0 && $right_value != 0) ? 1 : 0);
    }
    if ($operator eq '|' || $operator eq '||') {
        return $self->_boolean_constant(($left_value != 0 || $right_value != 0) ? 1 : 0);
    }
    if ($operator eq '^') {
        return $self->_boolean_constant((($left_value != 0) xor ($right_value != 0)) ? 1 : 0);
    }

    return undef;
}

sub _simplify_vector_bitwise_constant_fold ($self, $ast) {
    my $operator = $self->_canonical_logic_operator(eval { $ast->operator } || '');
    return undef unless $operator =~ /^(?:&|\||\^)$/;

    my $left_mask = $self->_literal_mask_info($ast->left);
    my $right_mask = $self->_literal_mask_info($ast->right);
    return undef unless $left_mask && $right_mask;

    my $width = $left_mask->{width} > $right_mask->{width}
        ? $left_mask->{width}
        : $right_mask->{width};
    return undef unless defined $width && $width > 1;

    my $modulus = Math::BigInt->bone->blsft($width);
    my $mask = $modulus->copy->bsub(1);
    my $left_value = $left_mask->{value}->copy->band($mask);
    my $right_value = $right_mask->{value}->copy->band($mask);

    my $result = $operator eq '&' ? $left_value->copy->band($right_value)
        : $operator eq '|' ? $left_value->copy->bior($right_value)
        : $left_value->copy->bxor($right_value);

    return $self->_vector_constant_from_value($width, $result);
}

sub _simplify_vector_bitwise_identity ($self, $ast) {
    my $operator = $self->_canonical_logic_operator(eval { $ast->operator } || '');
    return undef unless $operator =~ /^(?:&|\||\^)$/;

    my $left = $ast->left;
    my $right = $ast->right;

    for my $side (
        [$left, $right],
        [$right, $left],
    ) {
        my ($expr, $literal) = @$side;
        my $expr_width = $self->_expression_width($expr);
        my $mask = $self->_literal_mask_info($literal);
        next unless defined $expr_width && $mask;

        my $literal_width = $mask->{width};
        my $result_width = $expr_width > $literal_width ? $expr_width : $literal_width;
        next unless $result_width > 1;

        if ($operator eq '&') {
            return $expr
                if $mask->{kind} eq 'ones' && $literal_width == $expr_width;
            return $self->_vector_constant($result_width, 'zero')
                if $mask->{kind} eq 'zero';
        }

        if ($operator eq '|') {
            return $expr
                if $mask->{kind} eq 'zero' && $literal_width <= $expr_width;
            return $self->_vector_constant($result_width, 'ones')
                if $mask->{kind} eq 'ones' && $literal_width >= $expr_width;
        }

        if ($operator eq '^') {
            return $expr
                if $mask->{kind} eq 'zero' && $literal_width <= $expr_width;
            return $self->_new_unary_like($ast, '~', $expr)
                if $mask->{kind} eq 'ones' && $literal_width == $expr_width;
        }
    }

    return undef;
}

sub _simplify_binary_identity ($self, $ast) {
    my $operator = $self->_canonical_logic_operator(eval { $ast->operator } || '');
    my $left = $ast->left;
    my $right = $ast->right;

    if ($operator eq '&&') {
        return $self->_boolean_constant(0)
            if $self->_literal_is_boolean_zero($left) || $self->_literal_is_boolean_zero($right);
        return $right
            if $self->_literal_is_boolean_one($left) && $self->_node_is_booleanish($right);
        return $left
            if $self->_literal_is_boolean_one($right) && $self->_node_is_booleanish($left);
    }

    if ($operator eq '||') {
        return $self->_boolean_constant(1)
            if $self->_literal_is_boolean_one($left) || $self->_literal_is_boolean_one($right);
        return $right
            if $self->_literal_is_boolean_zero($left) && $self->_node_is_booleanish($right);
        return $left
            if $self->_literal_is_boolean_zero($right) && $self->_node_is_booleanish($left);
    }

    if ($operator eq '&') {
        return $self->_boolean_constant(0)
            if (($self->_literal_is_boolean_zero($left) && $self->_node_is_booleanish($right))
                || ($self->_literal_is_boolean_zero($right) && $self->_node_is_booleanish($left)));
        return $right
            if $self->_literal_is_boolean_one($left) && $self->_node_is_booleanish($right);
        return $left
            if $self->_literal_is_boolean_one($right) && $self->_node_is_booleanish($left);
    }

    if ($operator eq '|') {
        return $self->_boolean_constant(1)
            if (($self->_literal_is_boolean_one($left) && $self->_node_is_booleanish($right))
                || ($self->_literal_is_boolean_one($right) && $self->_node_is_booleanish($left)));
        return $right
            if $self->_literal_is_boolean_zero($left) && $self->_node_is_booleanish($right);
        return $left
            if $self->_literal_is_boolean_zero($right) && $self->_node_is_booleanish($left);
    }

    if ($operator eq '^') {
        return $right
            if $self->_literal_is_boolean_zero($left) && $self->_node_is_booleanish($right);
        return $left
            if $self->_literal_is_boolean_zero($right) && $self->_node_is_booleanish($left);
    }

    return undef;
}

sub _simplify_binary_idempotence ($self, $ast) {
    my $operator = $self->_canonical_logic_operator(eval { $ast->operator } || '');
    return undef unless $operator =~ /^(?:&|\||\^|&&|\|\|)$/;
    return undef unless $self->_logic_ast_key($ast->left) eq $self->_logic_ast_key($ast->right);

    if ($operator eq '&' || $operator eq '|') {
        return $ast->left;
    }

    if (($operator eq '&&' || $operator eq '||') && $self->_node_is_booleanish($ast->left)) {
        return $ast->left;
    }

    if ($operator eq '^') {
        return $self->_boolean_constant(0)
            if $self->_node_is_booleanish($ast->left);

        my $width = $self->_expression_width($ast->left);
        return $self->_vector_constant($width, 'zero')
            if defined $width && $width > 1;
    }

    return undef;
}

sub _simplify_binary_complement ($self, $ast) {
    my $operator = $self->_canonical_logic_operator(eval { $ast->operator } || '');
    return undef unless $operator =~ /^(?:&|\||&&|\|\|)$/;

    my $left = $ast->left;
    my $right = $ast->right;
    return undef unless $self->_is_negation_pair($left, $right);

    unless ($self->_node_is_booleanish($left) && $self->_node_is_booleanish($right)) {
        my $width = $self->_known_same_expression_width($left, $right);
        return undef unless defined $width && $width > 1;
        return $self->_vector_constant($width, ($operator eq '|' || $operator eq '||') ? 'ones' : 'zero');
    }

    return $self->_boolean_constant(($operator eq '|' || $operator eq '||') ? 1 : 0);
}

sub _simplify_binary_absorption ($self, $ast) {
    my $outer_operator = $self->_boolean_operator_family(eval { $ast->operator } || '');
    return undef unless $outer_operator eq '&' || $outer_operator eq '|';

    my $inner_operator = $outer_operator eq '&' ? '|' : '&';
    my $outer_width = $self->_expression_width($ast);

    for my $side (
        [$ast->left, $ast->right],
        [$ast->right, $ast->left],
    ) {
        my ($plain, $compound) = @$side;
        next unless $self->_is_binary_ast($compound);
        next unless $self->_boolean_operator_family(eval { $compound->operator } || '') eq $inner_operator;
        my $plain_width = $self->_expression_width($plain);
        my $compound_width = $self->_expression_width($compound);
        next unless defined $outer_width
            && defined $plain_width
            && defined $compound_width
            && $outer_width == $plain_width
            && $plain_width == $compound_width;
        return $plain
            if $self->_logic_ast_key($plain) eq $self->_logic_ast_key($compound->left)
            || $self->_logic_ast_key($plain) eq $self->_logic_ast_key($compound->right);
    }

    return undef;
}

sub _simplify_binary_consensus ($self, $ast) {
    my $outer_operator = $self->_boolean_operator_family(eval { $ast->operator } || '');
    return undef unless $outer_operator eq '&' || $outer_operator eq '|';
    my $outer_width = $self->_expression_width($ast);
    return undef unless defined $outer_width;

    my $inner_operator = $outer_operator eq '|' ? '&' : '|';
    return undef unless $self->_is_binary_ast($ast->left) && $self->_is_binary_ast($ast->right);
    return undef unless $self->_boolean_operator_family(eval { $ast->left->operator } || '') eq $inner_operator;
    return undef unless $self->_boolean_operator_family(eval { $ast->right->operator } || '') eq $inner_operator;
    return undef unless defined($self->_expression_width($ast->left))
        && defined($self->_expression_width($ast->right))
        && $self->_expression_width($ast->left) == $outer_width
        && $self->_expression_width($ast->right) == $outer_width;

    my @left_terms = ($ast->left->left, $ast->left->right);
    my @right_terms = ($ast->right->left, $ast->right->right);

    for my $left_index (0 .. 1) {
        for my $right_index (0 .. 1) {
            my $common_left = $left_terms[$left_index];
            my $common_right = $right_terms[$right_index];
            next unless $self->_logic_ast_key($common_left) eq $self->_logic_ast_key($common_right);

            my $other_left = $left_terms[1 - $left_index];
            my $other_right = $right_terms[1 - $right_index];
            next unless $self->_known_same_expression_width($common_left, $other_left, $other_right);
            return $common_left if $self->_is_negation_pair($other_left, $other_right);
        }
    }

    return undef;
}

sub _known_literal_numeric_value ($self, $ast) {
    my $value = $self->_literal_numeric_value($ast);
    return (undef, 0) unless defined $value;
    return ($value, 1);
}

sub _literal_boolean_value ($self, $ast) {
    return undef unless $ast && blessed($ast);

    if ($ast->isa('FSM::AST::LogicalConstant')) {
        return $ast->value ? 1 : 0;
    }

    return undef unless $self->_is_literal_operand($ast);
    my $value = $self->_literal_numeric_value($ast);
    return undef unless defined $value && ($value == 0 || $value == 1);

    my $width = $self->_literal_width($ast);
    return undef if defined $width && $width > 1;
    return $value ? 1 : 0;
}

sub _literal_is_boolean_zero ($self, $ast) {
    my $value = $self->_literal_boolean_value($ast);
    return defined($value) && $value == 0 ? 1 : 0;
}

sub _literal_is_boolean_one ($self, $ast) {
    my $value = $self->_literal_boolean_value($ast);
    return defined($value) && $value == 1 ? 1 : 0;
}

sub _literal_width ($self, $literal) {
    return undef unless $literal && blessed($literal);

    my $width = eval { $literal->can('width') ? $literal->width : undef };
    return $width if defined($width) && !ref($width) && $width =~ /\A\d+\z/;

    my $text = eval { $literal->to_systemverilog() };
    return $1 if defined($text) && $text =~ /\A(\d+)'\w/i;

    return undef;
}

sub _literal_mask_info ($self, $literal) {
    return undef unless $self->_is_literal_operand($literal);

    my $text = eval { FSM::Package::IntegerLiteralSupport->systemverilog_literal_from_literal_like($literal) };
    $text = eval { $literal->to_systemverilog() } unless defined($text) && length($text);
    return undef unless defined($text) && length($text);

    my $parts = FSM::Package::IntegerLiteralSupport->literal_parts_from_scalar($text);
    return undef unless ref($parts) eq 'HASH';

    my $width = $parts->{width};
    return undef unless defined($width) && !ref($width) && $width =~ /\A\d+\z/ && $width > 0;

    my $value = $parts->{value};
    return undef unless blessed($value) && $value->isa('Math::BigInt');

    my $mask = Math::BigInt->bone->blsft($width)->bsub(1);
    my $encoded = $value->copy->band($mask);
    my $kind = $encoded->is_zero ? 'zero'
        : $encoded->bcmp($mask) == 0 ? 'ones'
        : 'mixed';

    return {
        width => 0 + $width,
        value => $encoded,
        kind => $kind,
    };
}

sub _expression_width ($self, $ast) {
    return undef unless $ast && blessed($ast);

    return 1 if $ast->isa('FSM::AST::LogicalConstant');

    if ($self->_is_literal_operand($ast)) {
        return $self->_literal_width($ast);
    }

    if ($ast->isa('FSM::CoreAST::SignalRef')) {
        my $slice_width = $self->_core_signal_ref_slice_width($ast);
        return $slice_width if defined $slice_width;

        my $signal = eval { $ast->signal };
        my $width = eval { $signal && $signal->can('width') ? $signal->width : undef };
        return $width if defined($width) && !ref($width) && $width =~ /\A\d+\z/;
    }

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $name = $self->{flattened_dt}->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
        my $width = $self->_signal_width($name);
        return $width if defined $width;
    }

    return 1 if $ast->isa('FSM::AST::IndexedRef') || $ast->isa('FSM::CoreAST::IndexedRef');
    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        my $signal_name = eval { $ast->signal_name } || $ast->{signal_name};
        my $width = $self->_intermediate_signal_width($signal_name);
        return $width if defined $width;
        return undef;
    }

    if ($ast->isa('FSM::CoreAST::AggregateRef') || $ast->isa('FSM::CoreAST::ParameterRef')) {
        my $width = eval { $ast->width };
        return $width if defined($width) && !ref($width) && $width =~ /\A\d+\z/;
    }

    if ($self->_is_unary_ast($ast)) {
        my $operator = eval { $ast->operator } || '';
        return 1 if $self->_is_not_operator($operator);
        return $self->_expression_width($ast->operand)
            if $self->_is_bitwise_not_operator($operator);
        return undef;
    }

    if ($self->_is_binary_ast($ast)) {
        my $operator = $self->_canonical_logic_operator(eval { $ast->operator } || '');
        return 1 if $operator =~ /^(?:==|!=|<|>|<=|>=|&&|\|\|)$/;

        if ($operator =~ /^(?:&|\||\^)$/) {
            my $left_width = $self->_expression_width($ast->left);
            my $right_width = $self->_expression_width($ast->right);
            return undef unless defined $left_width && defined $right_width;
            return $left_width > $right_width ? $left_width : $right_width;
        }
    }

    return undef;
}

sub _known_same_expression_width ($self, @asts) {
    return undef unless @asts;

    my $width;
    for my $ast (@asts) {
        my $ast_width = $self->_expression_width($ast);
        return undef unless defined $ast_width;
        $width = $ast_width unless defined $width;
        return undef unless $ast_width == $width;
    }

    return $width;
}

sub _signal_width ($self, $name) {
    return undef unless defined($name) && length($name);

    my $ctx = $self->{flattened_dt};
    if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals && $ctx->{fsm_module}->signals->{$name}) {
        my $signal = $ctx->{fsm_module}->signals->{$name};
        my $width = eval { $signal->can('width') ? $signal->width : undef };
        return $width if defined($width) && !ref($width) && $width =~ /\A\d+\z/;
        return 1 unless defined $width;
    }

    if ($ctx->{enable_graph_signal_support}->is_intermediate_signal($name)) {
        my $width = $self->_intermediate_signal_width($name);
        return $width if defined $width;
        return undef;
    }
    return 1 if $name =~ /_(?:en|wen)$/;

    return undef;
}

sub _intermediate_signal_width ($self, $name) {
    return undef unless defined($name) && length($name);

    my $ctx = $self->{flattened_dt};
    return undef unless $ctx
        && $ctx->{enable_graph_signal_support}
        && $ctx->{enable_graph_signal_support}->is_intermediate_signal($name);

    if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals && $ctx->{fsm_module}->signals->{$name}) {
        my $signal = $ctx->{fsm_module}->signals->{$name};
        my $width = eval { $signal->can('width') ? $signal->width : undef };
        return $width if defined($width) && !ref($width) && $width =~ /\A\d+\z/ && $width > 0;
    }

    if ($ctx->{enable_graph_assignment_support}
        && $ctx->{enable_graph_assignment_support}->can('get_signal_info'))
    {
        my $signal_info = eval { $ctx->{enable_graph_assignment_support}->get_signal_info($name) };
        if ($signal_info && ref($signal_info) eq 'HASH') {
            my $width = $signal_info->{width};
            return $width if defined($width) && !ref($width) && $width =~ /\A\d+\z/ && $width > 0;
        }
    }

    my %signal_registry;
    for my $registry (
        $ctx->{intermediate_signals},
        ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{intermediate_signals})
            ? $ctx->{ast_factorizer}->{intermediate_signals}
            : undef,
        $ctx->{referenced_intermediate_signals},
    ) {
        next unless ref($registry) eq 'HASH';
        for my $signal_name (keys %$registry) {
            $signal_registry{$signal_name} //= $registry->{$signal_name};
        }
    }

    my $signal_info = $signal_registry{$name};
    if ($signal_info && ref($signal_info) eq 'HASH') {
        my $width = $signal_info->{width};
        return $width if defined($width) && !ref($width) && $width =~ /\A\d+\z/ && $width > 0;
    }

    if ($ctx->{enable_graph_intermediate_support}
        && $ctx->{enable_graph_intermediate_support}->can('_get_intermediate_signal_registry_entry'))
    {
        my $registry_entry = eval {
            $ctx->{enable_graph_intermediate_support}->_get_intermediate_signal_registry_entry($name)
        };
        if ($registry_entry && ref($registry_entry) eq 'HASH') {
            my $width = $registry_entry->{width};
            return $width if defined($width) && !ref($width) && $width =~ /\A\d+\z/ && $width > 0;
        }
    }

    return undef;
}

sub _boolean_constant ($self, $value) {
    return FSM::AST::LogicalConstant->new($value ? 1 : 0);
}

sub _vector_constant ($self, $width, $kind) {
    return undef unless defined($width) && !ref($width) && $width =~ /\A\d+\z/ && $width > 0;

    my $digits = $kind eq 'ones'
        ? ('1' x $width)
        : ('0' x $width);
    return FSM::CoreAST::Literal->new($digits, width => $width, radix => 'binary');
}

sub _vector_constant_from_value ($self, $width, $value) {
    return undef unless defined($width) && !ref($width) && $width =~ /\A\d+\z/ && $width > 0;
    return undef unless blessed($value) && $value->isa('Math::BigInt');

    my $bits = $value->copy->as_bin;
    $bits =~ s/\A0b//;
    $bits = '0' if $bits eq '';
    $bits = substr($bits, -$width) if length($bits) > $width;
    $bits = ('0' x ($width - length($bits))) . $bits if length($bits) < $width;
    return FSM::CoreAST::Literal->new($bits, width => $width, radix => 'binary');
}

sub _node_is_booleanish ($self, $ast) {
    return 0 unless $ast && blessed($ast);
    return 1 if $ast->isa('FSM::AST::LogicalConstant');
    return 1 if defined $self->_literal_boolean_value($ast);
    return 1 if $self->_operand_is_single_bit($ast);

    if ($self->_is_unary_ast($ast)) {
        return 1 if $self->_is_not_operator(eval { $ast->operator } || '');
    }

    if ($self->_is_binary_ast($ast)) {
        my $operator = $self->_canonical_logic_operator(eval { $ast->operator } || '');
        return 1 if $operator =~ /^(?:==|!=|<|>|<=|>=|&&|\|\|)$/;
    }

    return 0;
}

sub _is_negation_pair ($self, $left, $right) {
    return 1 if $self->_is_unary_ast($left)
        && $self->_is_not_operator(eval { $left->operator } || '')
        && $self->_logic_ast_key($left->operand) eq $self->_logic_ast_key($right)
        && $self->_node_is_booleanish($right);

    return 1 if $self->_is_unary_ast($left)
        && $self->_is_bitwise_not_operator(eval { $left->operator } || '')
        && $self->_logic_ast_key($left->operand) eq $self->_logic_ast_key($right)
        && defined $self->_known_same_expression_width($left->operand, $right);

    return 1 if $self->_is_unary_ast($right)
        && $self->_is_not_operator(eval { $right->operator } || '')
        && $self->_logic_ast_key($right->operand) eq $self->_logic_ast_key($left)
        && $self->_node_is_booleanish($left);

    return 1 if $self->_is_unary_ast($right)
        && $self->_is_bitwise_not_operator(eval { $right->operator } || '')
        && $self->_logic_ast_key($right->operand) eq $self->_logic_ast_key($left)
        && defined $self->_known_same_expression_width($right->operand, $left);

    return 0;
}

sub _canonical_logic_operator ($self, $operator) {
    my %canonical = (
        and => '&',
        or  => '|',
        xor => '^',
    );
    return $canonical{$operator} || $operator;
}

sub _boolean_operator_family ($self, $operator) {
    my $canonical = $self->_canonical_logic_operator($operator);
    return '&' if $canonical eq '&&';
    return '|' if $canonical eq '||';
    return $canonical;
}

sub _is_not_operator ($self, $operator) {
    return $operator eq '!' || $operator eq 'not';
}

sub _is_bitwise_not_operator ($self, $operator) {
    return $operator eq '~';
}

sub _is_binary_ast ($self, $ast) {
    return 0 unless $ast && blessed($ast);
    return 1 if $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 1 if $ast->isa('FSM::HDL::SubstitutedBinaryOp');
    return 0;
}

sub _is_unary_ast ($self, $ast) {
    return 0 unless $ast && blessed($ast);
    return 1 if $ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp');
    return 1 if $ast->isa('FSM::HDL::SubstitutedUnaryOp');
    return 0;
}

sub _new_binary_like ($self, $original, $operator, $left, $right) {
    return FSM::CoreAST::BinaryOp->new($operator, $left, $right)
        if blessed($original) && $original->isa('FSM::CoreAST::BinaryOp');

    return FSM::HDL::SubstitutedBinaryOp->new(operator => $operator, left => $left, right => $right)
        if blessed($original) && $original->isa('FSM::HDL::SubstitutedBinaryOp');

    return FSM::AST::BinaryOp->new($operator, $left, $right);
}

sub _new_unary_like ($self, $original, $operator, $operand) {
    return FSM::CoreAST::UnaryOp->new(operator => $operator, operand => $operand)
        if blessed($original) && $original->isa('FSM::CoreAST::UnaryOp');

    return FSM::HDL::SubstitutedUnaryOp->new(operator => $operator, operand => $operand)
        if blessed($original) && $original->isa('FSM::HDL::SubstitutedUnaryOp');

    return FSM::AST::UnaryOp->new($operator, $operand);
}

sub _logic_ast_key ($self, $ast) {
    return 'undef' unless defined $ast;
    return 'scalar:' . $ast unless ref($ast);
    return 'unblessed:' . ref($ast) unless blessed($ast);

    if ($self->_is_binary_ast($ast)) {
        my $operator = $self->_canonical_logic_operator(eval { $ast->operator } || '');
        my $left_key = $self->_logic_ast_key($ast->left);
        my $right_key = $self->_logic_ast_key($ast->right);
        if ($operator =~ /^(?:&|\||\^|&&|\|\||==|!=)$/ && $right_key lt $left_key) {
            ($left_key, $right_key) = ($right_key, $left_key);
        }
        return join(':', 'binary', $operator, $left_key, $right_key);
    }

    if ($self->_is_unary_ast($ast)) {
        my $operator = eval { $ast->operator } || '';
        return join(':', 'unary', $operator, $self->_logic_ast_key($ast->operand));
    }

    if ($ast->isa('FSM::AST::LogicalConstant')) {
        return 'literal:' . ($ast->value ? 1 : 0) . ':1';
    }

    if ($self->_is_literal_operand($ast)) {
        my $value = $self->_literal_numeric_value($ast);
        my $raw_value = eval { $ast->value };
        my $width = $self->_literal_width($ast);
        return join(':', 'literal', defined($value) ? $value : defined($raw_value) ? $raw_value : '', defined($width) ? $width : '');
    }

    if ($ast->can('to_systemverilog')) {
        my $text = eval { $ast->to_systemverilog() };
        return 'rendered:' . $text if defined $text;
    }

    return 'object:' . ref($ast) . ':' . "$ast";
}

=head2 ast_contains_factorizable_operators

Report whether one AST contains operators that qualify it for intermediate
factorization in the current backend policy.

=cut

sub ast_contains_factorizable_operators ($self, $ast) {
    return 0 unless $ast && blessed($ast);

    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        fsm_debug("    AST_OPERATORS: Found unary operation - FACTORIZABLE", 3);
        return 1;
    }

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        if ($self->is_arithmetic_operation($ast)) {
            fsm_debug("    AST_OPERATORS: Found arithmetic operation - FACTORIZABLE", 3);
            return 1;
        }

        if ($self->is_logical_operation($ast)) {
            if ($self->should_factor_logical_operation($ast)) {
                fsm_debug("    AST_OPERATORS: Found multi-use logical operation - FACTORIZABLE", 3);
                return 1;
            } else {
                fsm_debug("    AST_OPERATORS: Found single-use logical operation - NOT factorizable", 3);
                return 0;
            }
        }

        fsm_debug("    AST_OPERATORS: Found other binary operation - FACTORIZABLE", 3);
        return 1;
    }

    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal') ||
        $ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef') ||
        $ast->isa('FSM::CoreAST::ParameterRef') ||
        $ast->isa('FSM::CoreAST::AggregateRef')) {
        fsm_debug("    AST_OPERATORS: Found literal/signal reference - NOT factorizable", 3);
        return 0;
    }

    if ($ast->can('left') && $self->ast_contains_factorizable_operators($ast->left)) {
        return 1;
    }
    if ($ast->can('right') && $self->ast_contains_factorizable_operators($ast->right)) {
        return 1;
    }
    if ($ast->can('operand') && $self->ast_contains_factorizable_operators($ast->operand)) {
        return 1;
    }

    return 0;
}

=head2 is_arithmetic_operation

Report whether one AST node is an arithmetic binary operation.

=cut

sub is_arithmetic_operation ($self, $ast) {
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 0 unless $ast->can('operator');

    my $op = $ast->operator || '';
    return $op =~ /^(?:\+|-|\*|\/|%|<<|>>|<<<|>>>)$/;
}

=head2 is_logical_operation

Report whether one AST node is a logical binary operation.

=cut

sub is_logical_operation ($self, $ast) {
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 0 unless $ast->can('operator');

    my $op = $ast->operator || '';
    return $op =~ /^(&&|\|\||&|\|)$/;
}

=head2 should_factor_logical_operation

Apply the current backend policy for whether one logical operation should be
factorized.

=cut

sub should_factor_logical_operation ($self, $ast) {
    return 0 unless $self->is_logical_operation($ast);
    return $self->{flattened_dt}->{enable_graph_factorization_policy_support}->contains_frequently_used_operations($ast);
}

=head2 _ast_to_systemverilog_internal

Internal recursive renderer for C<ast_to_systemverilog>.

=cut

sub _ast_to_systemverilog_internal ($self, $ast, $parent_precedence) {
    my $ctx = $self->{flattened_dt};

    return "0" unless $ast && blessed($ast);

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        return $self->_render_signal_ref($ast);

    } elsif ($ast->isa('FSM::CoreAST::ParameterRef')) {
        return $ast->to_systemverilog();

    } elsif ($ast->isa('FSM::CoreAST::AggregateRef')) {
        return $ast->to_systemverilog();

    } elsif ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        my $normalized = FSM::Package::IntegerLiteralSupport->systemverilog_literal_from_literal_like($ast);
        return $normalized if defined $normalized;
        return $ast->value || "0";

    } elsif ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp') || $ast->isa('FSM::HDL::SubstitutedBinaryOp')) {
        return $self->_render_binary_op($ast, $parent_precedence);

    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp') || $ast->isa('FSM::HDL::SubstitutedUnaryOp')) {
        return $self->_render_unary_op($ast);

    } elsif ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        return $ast->signal_name || "unknown_intermediate_signal";

    } else {
        my $node_type = ref($ast) || 'UNKNOWN';

        if ($ast->can('to_systemverilog')) {
            my $sv_result = eval { $ast->to_systemverilog() };
            if ($sv_result && $sv_result !~ /^unknown_expr_/) {
                fsm_debug("AST_TO_CLEAN_SV: Using to_systemverilog() method for '$node_type': $sv_result", 3);
                return $sv_result;
            } else {
                fsm_warn("AST_TO_CLEAN_SV: to_systemverilog() failed for '$node_type', using fallback");
            }
        } else {
            fsm_debug("AST_TO_CLEAN_SV: No to_systemverilog() method for '$node_type'", 3);
        }

        if ($node_type =~ /BinaryOp$/) {
            return $self->_render_binary_op($ast, $parent_precedence);
        } elsif ($node_type =~ /UnaryOp$/) {
            return $self->_render_unary_op($ast);
        } elsif ($node_type =~ /SignalRef$/) {
            return $self->_render_signal_ref($ast);
        } elsif ($node_type =~ /Literal$/) {
            my $value = eval { $ast->value } || "0";
            my $normalized = FSM::Package::IntegerLiteralSupport->systemverilog_literal_from_literal_like($ast);
            return $normalized if defined $normalized;
            return $value;
        }

        fsm_debug("AST_TO_CLEAN_SV: Unknown AST node type '$node_type' - using safe fallback", 3);
        return "unknown_expr_" . lc($node_type =~ s/.*:://r);
    }
}

sub _render_signal_ref ($self, $ast) {
    my $ctx = $self->{flattened_dt};

    if ($ast->isa('FSM::CoreAST::SignalRef') && $ast->can('to_systemverilog')) {
        my $sv_result = eval { $ast->to_systemverilog() };
        return $sv_result if defined($sv_result) && $sv_result ne '';
    }

    my $name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
    return $name || "unknown_signal";
}

=head2 _render_binary_op

Internal binary-operator renderer with precedence and logical/bitwise
selection rules.

=cut

sub _render_binary_op ($self, $ast, $parent_precedence) {
    my $operator = eval { $ast->operator } || 'unknown';
    my $left = $ast->left;
    my $right = $ast->right;

    my $truthiness_render = $self->_render_truthiness_comparison($operator, $left, $right);
    return $truthiness_render if defined $truthiness_render;

    my $my_precedence = $self->_get_operator_precedence($operator);
    my $left_sv = $self->_ast_to_systemverilog_internal($left, $my_precedence);
    my $right_sv = $self->_ast_to_systemverilog_internal($right, $my_precedence);
    my $op_symbol = $self->_choose_operator_symbol($operator, $left, $right);

    if (($op_symbol eq '|' || $op_symbol eq '&')
        && $self->_bitwise_child_needs_grouping($left))
    {
        $left_sv = "($left_sv)";
    }

    if (($op_symbol eq '|' || $op_symbol eq '&')
        && $self->_bitwise_child_needs_grouping($right))
    {
        $right_sv = "($right_sv)";
    }

    if ($self->_right_child_needs_same_precedence_parentheses($operator, $right)) {
        $right_sv = "($right_sv)";
    }

    fsm_debug("*** OPERATOR_CHOICE_DEBUG: ***", 3);
    fsm_debug("  Original operator: '$operator'", 3);
    fsm_debug("  Chosen symbol: '$op_symbol'", 3);
    fsm_debug("  Left operand: '$left_sv' (AST type: " . (blessed($left) ? ref($left) : 'UNBLESSED') . ")", 3);
    fsm_debug("  Right operand: '$right_sv' (AST type: " . (blessed($right) ? ref($right) : 'UNBLESSED') . ")", 3);
    fsm_debug("  Left is 1-bit: " . ($self->_operand_is_single_bit($left) ? 'YES' : 'NO'), 3);
    fsm_debug("  Right is 1-bit: " . ($self->_operand_is_single_bit($right) ? 'YES' : 'NO'), 3);

    my $expr = "$left_sv $op_symbol $right_sv";

    fsm_debug("  Final expression: '$expr'", 3);
    fsm_debug("*** END OPERATOR_CHOICE_DEBUG ***", 3);

    return "($expr)" if $self->_needs_parentheses($my_precedence, $parent_precedence);
    return $expr;
}

sub _render_truthiness_comparison ($self, $operator, $left, $right) {
    return undef unless $operator eq '==' || $operator eq '!=';

    my ($signalish_operand, $literal_operand) = $self->_extract_truthiness_operands($left, $right);
    return undef unless $signalish_operand && $literal_operand;

    my $literal_value = $self->_literal_numeric_value($literal_operand);
    return undef unless defined $literal_value;

    my $operand_sv = $self->_ast_to_systemverilog_internal($signalish_operand, 10);

    if ($literal_value == 0) {
        return $operator eq '!='
            ? $self->_render_truthiness_value($signalish_operand, $operand_sv)
            : $self->_render_truthiness_negation($signalish_operand, $operand_sv);
    }

    if ($literal_value == 1 && $self->_operand_is_single_bit($signalish_operand)) {
        return $operator eq '=='
            ? $operand_sv
            : $self->_render_truthiness_negation($signalish_operand, $operand_sv);
    }

    return undef;
}

sub _render_truthiness_value ($self, $operand, $operand_sv) {
    return $operand_sv if $self->_operand_is_single_bit($operand);
    return "(|$operand_sv)";
}

sub _extract_truthiness_operands ($self, $left, $right) {
    if ($self->_is_truthiness_signal_operand($left) && $self->_is_literal_operand($right)) {
        return ($left, $right);
    }
    if ($self->_is_truthiness_signal_operand($right) && $self->_is_literal_operand($left)) {
        return ($right, $left);
    }
    return;
}

sub _is_truthiness_signal_operand ($self, $ast) {
    return 0 unless $ast && blessed($ast);
    return 1 if $ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef');
    return 1 if $ast->isa('FSM::AST::IndexedRef') || $ast->isa('FSM::CoreAST::IndexedRef');
    return 1 if $ast->isa('FSM::CoreAST::AggregateRef');
    return 1 if $ast->isa('FSM::CoreAST::ParameterRef');
    return 1 if $ast->isa('FSM::HDL::IntermediateSignalRef');
    return 0;
}

sub _is_literal_operand ($self, $ast) {
    return 0 unless $ast && blessed($ast);
    return 1 if $ast->isa('FSM::AST::LogicalConstant');
    return 1 if $ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal');
    return 0;
}

sub _literal_numeric_value ($self, $literal) {
    return undef unless $self->_is_literal_operand($literal);

    return $literal->value ? 1 : 0
        if $literal->isa('FSM::AST::LogicalConstant');

    my $text = eval { $literal->to_systemverilog() };
    $text = eval { $literal->value } unless defined $text && $text ne '';
    return undef unless defined $text;

    $text =~ s/\s+//g;
    $text =~ s/_//g;

    my $integer_value = FSM::Package::IntegerLiteralSupport->integer_from_scalar($text);
    return 0 + $integer_value->bstr if defined $integer_value;

    if ($text =~ /\A(\d+)'([bdhxBDHX])([0-9a-fA-FxXzZ]+)\z/) {
        my ($width, $radix_char, $digits) = ($1, lc($2), $3);
        return undef if $digits =~ /[xXzZ]/;
        return oct("0b$digits") if $radix_char eq 'b';
        return 0 + $digits if $radix_char eq 'd';
        return hex($digits) if $radix_char eq 'h' || $radix_char eq 'x';
    }

    return 0 + $text if $text =~ /\A\d+\z/;
    return undef;
}

sub _render_truthiness_negation ($self, $operand, $operand_sv) {
    return "(~|$operand_sv)" unless $self->_operand_is_single_bit($operand);

    return $self->_operand_needs_parens_for_negation($operand)
        ? "!($operand_sv)"
        : "!$operand_sv";
}

=head2 _get_operator_precedence

Internal SystemVerilog precedence lookup for binary operators.

=cut

sub _get_operator_precedence ($self, $operator) {
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

=head2 _choose_operator_symbol

Internal selector for logical-versus-bitwise operator emission.

=cut

sub _choose_operator_symbol ($self, $operator, $left, $right) {
    my $ctx = $self->{flattened_dt};
    my $left_name = undef;
    my $right_name = undef;
    my $left_width = undef;
    my $right_width = undef;

    fsm_debug("_choose_operator_symbol: Entering with operator '$operator'", 3);

    if ($left && blessed($left)) {
        $left_name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($left);
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
                    my @available = keys %{$ctx->{fsm_module}->signals};
                    my @first_10 = sort @available[0 .. min(9, $#available)];
                    fsm_debug("_choose_operator_symbol: Available signals: " . join(", ", @first_10), 3);
                }
            } else {
                fsm_debug("_choose_operator_symbol: No FSM module or signals available", 3);
            }
        }
    }

    if ($right && blessed($right)) {
        $right_name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($right);
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

=head2 _needs_parentheses

Internal precedence helper for binary rendering.

=cut

sub _needs_parentheses ($self, $my_precedence, $parent_precedence) {
    return 0 unless defined $parent_precedence;
    return $my_precedence < $parent_precedence;
}

sub _bitwise_child_needs_grouping ($self, $child) {
    return 0 unless $child && blessed($child);
    return 0 unless $child->can('operator');

    my $operator = $child->operator || '';
    return 0 if defined $self->_render_truthiness_comparison(
        $operator,
        $child->can('left') ? $child->left : undef,
        $child->can('right') ? $child->right : undef,
    );
    return $operator =~ /^(?:==|!=|<|>|<=|>=|&&|\|\|)$/ ? 1 : 0;
}

sub _right_child_needs_same_precedence_parentheses ($self, $parent_operator, $right_child) {
    return 0 unless $right_child && blessed($right_child);
    return 0 unless $right_child->isa('FSM::AST::BinaryOp')
        || $right_child->isa('FSM::CoreAST::BinaryOp')
        || $right_child->isa('FSM::HDL::SubstitutedBinaryOp');

    my $child_operator = eval { $right_child->operator } || '';
    return 0 unless $child_operator ne '';

    my $parent_precedence = $self->_get_operator_precedence($parent_operator);
    my $child_precedence = $self->_get_operator_precedence($child_operator);
    return 0 unless $parent_precedence == $child_precedence;

    my $parent_symbol = $self->_map_binary_operator($parent_operator);
    my $child_symbol = $self->_map_binary_operator($child_operator);
    return 0 if $parent_symbol eq $child_symbol
        && $parent_symbol =~ /^(?:\+|\*|&|\||\^|&&|\|\|)$/;

    return 1;
}

=head2 _map_binary_operator

Internal mapper from normalized operator names to emitted binary symbols.

=cut

sub _map_binary_operator ($self, $operator) {
    my %op_map = (
        'eq' => '==', 'ne' => '!=', 'lt' => '<', 'gt' => '>', 'le' => '<=', 'ge' => '>=',
        'add' => '+', 'sub' => '-', 'mul' => '*', 'div' => '/', 'mod' => '%',
        'and' => '&', 'or' => '|', 'xor' => '^',
        'shl' => '<<', 'shr' => '>>', 'sal' => '<<<', 'sar' => '>>>',
    );
    return $op_map{$operator} || $operator;
}

=head2 _signal_is_single_bit

Internal single-bit signal classifier for emitted operator selection.

=cut

sub _signal_is_single_bit ($self, $name) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("    SIGNAL_IS_1BIT: Checking if signal '$name' is single-bit", 3);

    unless (defined $name) {
        fsm_debug("      RESULT: NOT single-bit (undefined name)", 3);
        return 0;
    }

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
            my @available = keys %{$ctx->{fsm_module}->signals};
            my $count = scalar(@available);
            fsm_debug("        Available signals ($count): " . join(", ", sort @available), 3);
        }
    }

    if ($ctx->{enable_graph_signal_support}->is_intermediate_signal($name)) {
        my $width = $self->_intermediate_signal_width($name);
        my $result = (defined($width) && $width == 1) ? 1 : 0;
        fsm_debug("      PATH: Intermediate signal", 3);
        fsm_debug("      Intermediate signal width: " . (defined($width) ? $width : 'unknown'), 3);
        fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (from intermediate width)", 3);
        return $result;
    }

    if ($name =~ /_(?:en|wen)$/) {
        fsm_debug("      PATH: Generated enable/write-enable signal", 3);
        fsm_debug("      RESULT: single-bit (enable families are boolean)", 3);
        return 1;
    }

    if ($name =~ /^current_state$/) {
        fsm_debug("      PATH: State comparison signal", 3);
        fsm_debug("      RESULT: single-bit (state comparison)", 3);
        return 1;
    }

    fsm_debug("      PATH: Default fallback", 3);
    fsm_debug("      RESULT: multi-bit (conservative default)", 3);
    return 0;
}

sub _core_signal_ref_slice_width ($self, $ast) {
    return undef unless $ast && blessed($ast);
    return undef unless $ast->isa('FSM::CoreAST::SignalRef');
    return undef unless $ast->can('slice');

    my $slice = eval { $ast->slice };
    return undef unless ref($slice) eq 'ARRAY' && @$slice == 2;

    my ($high, $low) = @$slice;
    return undef unless defined($high) && defined($low);
    return undef if ref($high) || ref($low);
    return undef unless $high =~ /\A-?\d+\z/ && $low =~ /\A-?\d+\z/;

    return abs($high - $low) + 1;
}

=head2 _operand_is_single_bit

Internal single-bit AST classifier for emitted operator selection.

=cut

sub _operand_is_single_bit ($self, $ast) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("    OPERAND_BIT_CHECK: Checking if operand is single-bit", 3);
    fsm_debug("      AST defined: " . (defined($ast) ? 'YES' : 'NO'), 3);
    fsm_debug("      AST blessed: " . (blessed($ast) ? 'YES' : 'NO'), 3);

    unless ($ast && blessed($ast)) {
        fsm_debug("      RESULT: NOT single-bit (undefined or not blessed)", 3);
        return 0;
    }

    fsm_debug("      AST type: " . ref($ast), 3);

    if ($ast->isa('FSM::CoreAST::SignalRef')) {
        my $slice_width = $self->_core_signal_ref_slice_width($ast);
        if (defined $slice_width) {
            my $result = $slice_width == 1 ? 1 : 0;
            fsm_debug("      PATH: CoreAST SignalRef slice width $slice_width", 3);
            fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (from slice width)", 3);
            return $result;
        }

        fsm_debug("      PATH: Regular SignalRef", 3);
        my $name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
        fsm_debug("      Signal name: '" . ($name || 'UNDEFINED') . "'", 3);
        my $result = $self->_signal_is_single_bit($name);
        fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (via _signal_is_single_bit)", 3);
        return $result;

    } elsif ($ast->isa('FSM::AST::SignalRef')) {
        fsm_debug("      PATH: Regular SignalRef", 3);
        my $name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
        fsm_debug("      Signal name: '" . ($name || 'UNDEFINED') . "'", 3);
        my $result = $self->_signal_is_single_bit($name);
        fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (via _signal_is_single_bit)", 3);
        return $result;

    } elsif ($ast->isa('FSM::AST::LogicalConstant')) {
        fsm_debug("      PATH: LogicalConstant", 3);
        fsm_debug("      RESULT: single-bit (logical constant)", 3);
        return 1;

    } elsif ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        fsm_debug("      PATH: Literal", 3);
        my $value = eval { $ast->value } || '';
        fsm_debug("      Literal value: '$value'", 3);
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
        return 1;

    } elsif ($ast->isa('FSM::CoreAST::AggregateRef')) {
        fsm_debug("      PATH: AggregateRef", 3);
        my $width = eval { $ast->width };
        my $result = defined($width) && $width == 1 ? 1 : 0;
        fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (aggregate path width)", 3);
        return $result;

    } elsif ($ast->isa('FSM::CoreAST::ParameterRef')) {
        fsm_debug("      PATH: ParameterRef", 3);
        my $width = eval { $ast->width };
        my $result = defined($width) && $width == 1 ? 1 : 0;
        fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (parameter width)", 3);
        return $result;

    } elsif ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp') || $ast->isa('FSM::HDL::SubstitutedBinaryOp')) {
        fsm_debug("      PATH: BinaryOp", 3);
        my $op = eval { $ast->operator } || '';
        fsm_debug("      Binary operator: '$op'", 3);
        if ($op =~ /^(==|!=|<|>|<=|>=)$/) {
            fsm_debug("      RESULT: single-bit (comparison operator)", 3);
            return 1;
        }
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

    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp') || $ast->isa('FSM::HDL::SubstitutedUnaryOp')) {
        fsm_debug("      PATH: UnaryOp", 3);
        my $op = eval { $ast->operator } || '';
        fsm_debug("      Unary operator: '$op'", 3);
        if ($op eq 'not' || $op eq '!') {
            fsm_debug("      RESULT: single-bit (logical NOT)", 3);
            return 1;
        } else {
            fsm_debug("      RESULT: multi-bit (other unary operator)", 3);
            return 0;
        }

    } elsif ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        fsm_debug("      PATH: IntermediateSignalRef", 3);
        my $signal_name = eval { $ast->signal_name } || 'UNKNOWN';
        fsm_debug("      Intermediate signal name: '$signal_name'", 3);
        my $width = $self->_intermediate_signal_width($signal_name);
        my $result = (defined($width) && $width == 1) ? 1 : 0;
        fsm_debug("      Intermediate signal width: " . (defined($width) ? $width : 'unknown'), 3);
        fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (from intermediate width)", 3);
        return $result;
    } else {
        fsm_debug("      PATH: Unknown AST type - " . ref($ast), 3);
        fsm_debug("      RESULT: multi-bit (unknown type fallback)", 3);
    }

    fsm_debug("      RESULT: multi-bit (default fallback)", 3);
    return 0;
}

=head2 _render_unary_op

Internal unary-operator renderer.

=cut

sub _render_unary_op ($self, $ast) {
    my $operator = eval { $ast->operator } || 'not';
    my $operand = $ast->operand;
    my $operand_sv = $self->_ast_to_systemverilog_internal($operand, 10);
    my $op_symbol = $self->_map_unary_operator($operator);

    if ($operator eq 'not' || $operator eq '!') {
        return "(~|$operand_sv)" unless $self->_operand_is_single_bit($operand);

        if ($self->_operand_needs_parens_for_negation($operand)) {
            return "!($operand_sv)";
        } else {
            return "!$operand_sv";
        }
    } else {
        return "$op_symbol($operand_sv)";
    }
}

=head2 _map_unary_operator

Internal mapper from normalized unary operator names to emitted symbols.

=cut

sub _map_unary_operator ($self, $operator) {
    my %op_map = ( 'not' => '!', 'neg' => '-', 'pos' => '+' );
    return $op_map{$operator} || $operator;
}

=head2 _operand_needs_parens_for_negation

Internal negation-parenthesis helper.

=cut

sub _operand_needs_parens_for_negation ($self, $operand) {
    return 0 unless $operand && blessed($operand);
    return 0 if $operand->isa('FSM::AST::SignalRef') || $operand->isa('FSM::CoreAST::SignalRef');
    return 0 if $operand->isa('FSM::AST::Literal') || $operand->isa('FSM::CoreAST::Literal');
    return 0 if $operand->isa('FSM::AST::IndexedRef') || $operand->isa('FSM::CoreAST::IndexedRef');
    return 0 if $operand->isa('FSM::CoreAST::AggregateRef');
    return 0 if $operand->isa('FSM::CoreAST::ParameterRef');
    if ($operand->isa('FSM::AST::BinaryOp') || $operand->isa('FSM::CoreAST::BinaryOp') || $operand->isa('FSM::HDL::SubstitutedBinaryOp')) {
        my $operator = eval { $operand->operator } || '';
        return 0 if defined $self->_render_truthiness_comparison($operator, $operand->left, $operand->right);
    }
    return 1;
}

1;
