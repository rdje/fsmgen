package FSM::Package::AggregateExpressionTypeSupport;

=head1 NAME

FSM::Package::AggregateExpressionTypeSupport - Shared CoreAST expression type-shape inference

=head1 DESCRIPTION

Owns the bounded type-shape inference used when CoreAST expressions carry
aggregate intent, currently centered on C<Concatenation> expressions. Frontend
and synthesis capture callers provide their local exact-width resolver, while
this package owns the list/record shape construction so those paths cannot
drift independently.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Scalar::Util qw(blessed);

use FSM::Package::AggregatePathSupport;
use FSM::Package::PayloadTypeSupport;

sub is_aggregate_type_spec ($class, $type_spec) {
    return 0 unless ref($type_spec) eq 'HASH';
    my $kind = $type_spec->{kind} || '';
    return ($kind eq 'list' || $kind eq 'record') ? 1 : 0;
}

sub concat_expression_type_spec_for_target ($class, %args) {
    my $source_expr = $args{source_expr};
    return unless $source_expr && blessed($source_expr) && $source_expr->isa('FSM::CoreAST::Concatenation');

    my $target_type_spec = ref($args{target_type_spec}) eq 'HASH'
        ? $args{target_type_spec}
        : $class->assignment_target_declared_type_spec($args{target_expr});
    return unless $class->is_aggregate_type_spec($target_type_spec);

    return $class->concat_operand_type_spec_for_target(
        %args,
        operands => $source_expr->operands || [],
        target_type_spec => $target_type_spec,
    );
}

sub concat_expression_list_type_spec ($class, $source_expr, %args) {
    return unless $source_expr && blessed($source_expr) && $source_expr->isa('FSM::CoreAST::Concatenation');
    return $class->concat_operand_list_type_spec(
        %args,
        operands => $source_expr->operands || [],
    );
}

sub concat_operand_type_spec_for_target ($class, %args) {
    my $operands = $args{operands};
    return unless ref($operands) eq 'ARRAY' && @$operands;

    my $concat_list_type_spec = $class->concat_operand_list_type_spec(%args);
    return unless ref($concat_list_type_spec) eq 'HASH';

    my $target_type_spec = ref($args{target_type_spec}) eq 'HASH'
        ? $args{target_type_spec}
        : $class->assignment_target_declared_type_spec($args{target_expr});
    return $concat_list_type_spec
        unless ref($target_type_spec) eq 'HASH'
            && ($target_type_spec->{kind} || '') eq 'record';

    my @item_specs = @{$concat_list_type_spec->{items} || []};
    my @member_order = @{$target_type_spec->{member_order} || []};
    return $concat_list_type_spec unless @item_specs == @member_order;

    my %members;
    for my $index (0 .. $#member_order) {
        $members{$member_order[$index]} = FSM::Package::AggregatePathSupport->clone_structured_value($item_specs[$index]);
    }

    return {
        kind => 'record',
        width => $concat_list_type_spec->{width},
        signed => 0,
        member_order => \@member_order,
        members => \%members,
    };
}

sub concat_operand_list_type_spec ($class, %args) {
    my $operands = $args{operands};
    return unless ref($operands) eq 'ARRAY' && @$operands;

    my @item_specs;
    my $total_width = 0;
    for my $operand (@$operands) {
        my $item_spec = $class->source_expression_type_spec($operand, %args);
        return unless ref($item_spec) eq 'HASH';
        push @item_specs, $item_spec;
        $total_width += $item_spec->{width} // 0;
    }
    return unless @item_specs && $total_width > 0;

    return {
        kind => 'list',
        width => $total_width,
        signed => 0,
        items => [ map { FSM::Package::AggregatePathSupport->clone_structured_value($_) } @item_specs ],
    };
}

sub assignment_target_declared_type_spec ($class, $target_expr) {
    return unless $target_expr && blessed($target_expr);

    if ($target_expr->isa('FSM::CoreAST::AggregateRef')) {
        return FSM::Package::AggregatePathSupport->clone_structured_value($target_expr->type_spec);
    }

    return unless $target_expr->isa('FSM::CoreAST::SignalRef');
    return if $target_expr->slice;

    my $signal = $target_expr->signal;
    return unless $signal && blessed($signal) && $signal->can('declared_type_spec');
    my $declared_type_spec = $signal->declared_type_spec;
    return FSM::Package::AggregatePathSupport->clone_structured_value($declared_type_spec)
        if ref($declared_type_spec) eq 'HASH';
    return;
}

sub source_expression_type_spec ($class, $expr, %args) {
    return unless $expr && blessed($expr);

    if ($expr->isa('FSM::CoreAST::SignalRef')) {
        if ($expr->slice) {
            my ($high, $low) = @{$expr->slice};
            return FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width(abs($high - $low) + 1);
        }

        my $signal = $expr->signal;
        if ($signal && blessed($signal) && $signal->can('declared_type_spec')) {
            my $declared_type_spec = $signal->declared_type_spec;
            return FSM::Package::AggregatePathSupport->clone_structured_value($declared_type_spec)
                if ref($declared_type_spec) eq 'HASH';
        }
    }

    if ($expr->isa('FSM::CoreAST::AggregateRef')) {
        my $type_spec = $expr->type_spec;
        return FSM::Package::AggregatePathSupport->clone_structured_value($type_spec)
            if ref($type_spec) eq 'HASH';
    }

    if ($expr->isa('FSM::CoreAST::IndexedRef')) {
        return FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width(1);
    }

    if ($expr->isa('FSM::CoreAST::Concatenation')) {
        my $concat_type_spec = $class->concat_expression_list_type_spec($expr, %args);
        return $concat_type_spec if ref($concat_type_spec) eq 'HASH';
    }

    my $width_resolver = ref($args{width_resolver}) eq 'CODE'
        ? $args{width_resolver}
        : undef;
    my $width = $width_resolver ? $width_resolver->($expr) : undef;
    return FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width($width)
        if defined($width) && $width > 0;

    return;
}

1;

__END__

=head1 METHODS

=head2 concat_expression_type_spec_for_target

Infers the source type-shape contract for one C<Concatenation> expression when
it drives a declared aggregate target. List targets keep ordered concat item
shape, while record targets can map exact top-level operands onto record member
order.

=head2 concat_expression_list_type_spec

Infers an ordered list type spec for one C<Concatenation> expression.

=head2 concat_operand_type_spec_for_target

Infers a list type spec for an operand span, or a target-aware record type spec
when the target is a compatible record shape.

=head2 source_expression_type_spec

Infers a bounded scalar/list/record type spec for a CoreAST expression. Callers
may pass C<width_resolver =E<gt> sub { ... }> for local exact-width fallback.

=cut
