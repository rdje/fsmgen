package FSM::CoreExpressionWidthSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed refaddr);
use JSON::PP ();
use FSM::Package::ExpressionOperatorSupport qw(is_reduction_operator);

use constant MAX_DEPTH => 64;
use constant MAX_NODES => 4096;

sub infer_width {
    my ($class, $expr, %options) = @_;
    confess "Core expression width requires only an optional unsized_literal_width callback\n"
        if grep {$_ ne 'unsized_literal_width'} keys %options;
    confess "Core expression width unsized_literal_width requires a callback\n"
        if exists($options{unsized_literal_width}) && ref($options{unsized_literal_width}) ne 'CODE';
    return _infer_width($expr, {remaining => MAX_NODES, active => {}, %options}, 0);
}

sub _infer_width {
    my ($expr, $walk, $depth) = @_;
    return undef unless blessed($expr) && $depth <= MAX_DEPTH && --$walk->{remaining} >= 0;
    my $identity = refaddr($expr);
    return undef if $walk->{active}{$identity};
    local $walk->{active}{$identity} = 1;

    if ($expr->isa('FSM::CoreAST::Literal')) {
        my $width = $expr->width;
        return (defined($width) && $width > 0) ? $width : undef if defined $width;
        my $resolver = $walk->{unsized_literal_width} or return undef;
        # Raw source data crosses this boundary, never the Literal owner or a
        # rendered target token. Invalid/structured payloads remain unknown.
        my ($value, $radix) = ($expr->value, $expr->radix);
        return undef if !defined($value) || ref($value) || !defined($radix) || ref($radix);
        my $record = {value => $value, width => undef, radix => $radix};
        my $copy = JSON::PP->new->decode(JSON::PP->new->encode($record));
        my $resolved = $resolver->($copy);
        return undef unless defined($resolved) && !ref($resolved)
            && $resolved =~ /\A[0-9]+\z/ && $resolved > 0;
        return $resolved;
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
        return 1 if $expr->operator eq '!' || is_reduction_operator($expr->operator);
        return _infer_width($expr->operand, $walk, $depth + 1);
    }

    if ($expr->isa('FSM::CoreAST::BinaryOp')) {
        my $operator = $expr->operator;
        return 1 if defined($operator) && $operator =~ /^(?:==|!=|<|>|<=|>=)$/;

        my $left_width = _infer_width($expr->left, $walk, $depth + 1);
        my $right_width = _infer_width($expr->right, $walk, $depth + 1);
        return undef unless defined($left_width) && defined($right_width);
        return $left_width > $right_width ? $left_width : $right_width;
    }

    if ($expr->isa('FSM::CoreAST::Concatenation')) {
        my $total_width = 0;
        for my $operand (@{$expr->operands}) {
            my $operand_width = _infer_width($operand, $walk, $depth + 1);
            return undef unless defined($operand_width) && $operand_width > 0;
            $total_width += $operand_width;
        }
        return $total_width > 0 ? $total_width : undef;
    }

    return undef;
}

1;

=head1 NAME

FSM::CoreExpressionWidthSupport - Bounded target-neutral Core width inference

=head1 METHODS

=head2 infer_width

C<< infer_width($core_expression, unsized_literal_width => $callback) >> returns
an inferred positive width, or undef when the expression width is unknown.
Without the optional callback, unsized literals remain unknown. This is the
shared exact-width walk used by direct ExpressionBuilder; it neither changes
Core Signals nor supplies a backend default.

An explicit literal width always wins over the callback. Only an actual unsized
Core Literal calls the resolver, with a detached C<{value, radix, width}> record
whose C<width> is undef. Raw value/radix and JSON scalar kinds preserve; no HDL
rendering or literal interpretation occurs here. A resolver supplies only a
positive decimal scalar width; missing, malformed or reference-valued results
remain unknown. Resolver exceptions propagate. Resolver mutation cannot change
the source Literal. An invalid option or non-callback resolver throws.

Known reference/slice/index/aggregate widths, scalar reductions/logical negation
and comparisons, ordinary unary propagation, binary operand maxima and
concatenation sums preserve the existing exact-width rules. Signal references
read their current selected widths without expanding other Signals' definitions;
those widths alone do not prove allocation ancestry or that a generated helper's
compatibility placeholder is exact. Unknown future expression classes stay
unknown even with a resolver. This method supplies no signedness/type legality,
mutable dependency provenance, generic range or target declaration proof.

C<MAX_DEPTH> and C<MAX_NODES> bound depth and visited occurrences. Active AST
cycles and over-bound walks return undef. Shared subtrees count each occurrence,
not as cycles; all walk state is local to the call. Scalar-result operators need
no operand walk. These limits are inference boundaries, not source admission.

=cut
