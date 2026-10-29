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
    confess "Core expression width requires only optional unsized_literal_width and source_reference_width callbacks\n"
        if grep {$_ ne 'unsized_literal_width' && $_ ne 'source_reference_width'} keys %options;
    for my $option (qw(unsized_literal_width source_reference_width)) {
        confess "Core expression width $option requires a callback\n"
            if exists($options{$option}) && ref($options{$option}) ne 'CODE';
    }
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
        if (my $resolver = $walk->{source_reference_width}) {
            # Only the source caller can join this actual reference to current
            # allocation intent. Undef requests ordinary inference; a nullable
            # width record deliberately distinguishes unknown from fallback.
            my $resolved = $resolver->($expr);
            if (defined $resolved) {
                return undef unless ref($resolved) eq 'HASH' && join(',', sort keys %$resolved) eq 'width';
                my $width = $resolved->{width};
                return undef unless defined($width) && !ref($width) && $width =~ /\A[0-9]+\z/ && $width > 0;
                return $resolved->{width};
            }
        }
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

C<< infer_width($core_expression, %options) >> returns
an inferred positive width, or undef when the expression width is unknown.
Without an explicit literal callback, unsized literals remain unknown. This is the
shared exact-width walk used by direct ExpressionBuilder; it neither changes
Core Signals nor supplies a backend default.

The optional C<unsized_literal_width> callback supplies a literal width. An
explicit literal width always wins over it. Only an actual unsized
Core Literal calls the resolver, with a detached C<{value, radix, width}> record
whose C<width> is undef. Raw value/radix and JSON scalar kinds preserve; no HDL
rendering or literal interpretation occurs here. A resolver supplies only a
positive decimal scalar width; missing, malformed or reference-valued results
remain unknown. Resolver exceptions propagate. Resolver mutation cannot change
the source Literal. An invalid option or non-callback resolver throws.

Known reference/slice/index/aggregate widths, scalar reductions/logical negation
and comparisons, ordinary unary propagation, binary operand maxima and
concatenation sums preserve the existing exact-width rules. By default, Signal references
read their current selected widths without expanding other Signals' definitions;
those widths alone do not prove allocation ancestry or that a generated helper's
compatibility placeholder is exact. Unknown future expression classes stay
unknown even with a resolver. This method supplies no signedness/type legality,
mutable dependency provenance, generic range or target declaration proof.

The optional C<source_reference_width> callback handles only whole SignalRefs
with an actual source exposing C<width>. It receives that actual Core SignalRef,
so the source caller can join reference/object identity to its own current
allocation contract. It must not retain or mutate owners. Return undef to use
the ordinary selected width, or the closed C<{width =E<gt> VALUE}> record to
resolve explicitly. A positive decimal scalar resolves; C<{width =E<gt> undef}>
withholds, rather than falling back to a compatibility placeholder. Malformed,
structured or nonpositive resolutions also withhold. Callback errors propagate;
invalid options or non-callback values throw. The walk retains no callback or
source-owner state after returning and never writes the source.

This option itself proves no provenance, currentness, independent floor or
source legality. The caller must leave independently authored references
unoverridden and explicitly withhold unproved generated helpers. Slices,
ParameterRefs, explicit literals, scalar-result operators and unknown classes
do not call this resolver. Without it, ordinary reference inference is unchanged.
ExpressionBuilder now uses this boundary during capture-local source allocation;
target consumers remain separate.

C<MAX_DEPTH> and C<MAX_NODES> bound depth and visited occurrences. Active AST
cycles and over-bound walks return undef. Shared subtrees count each occurrence,
not as cycles; all walk state is local to the call. Scalar-result operators need
no operand walk. Reference callbacks run only for occurrences admitted by that
same walk; any independent traversal inside a callback needs its own source
bounds. These limits are inference boundaries, not source admission.

=cut
