package FSM::Composition::AggregatePathSupport;

=head1 NAME

FSM::Composition::AggregatePathSupport - Shared typed aggregate path resolver

=head1 DESCRIPTION

Owns the shared composition-side traversal for declared aggregate member/item
paths. Planning layers use the resolved connection expression plus leaf type
facts for validated bindings, while reporting layers can consume the same leaf
type facts without duplicating the path-walk semantics.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    bit_select_expr
    member_access_expr
    slice_expr
);
use FSM::Package::PayloadTypeSupport;

sub resolve ($class, %args) {
    my $root_type_spec = $args{root_type_spec};
    my $path_text = $args{path_text} // '';
    my $connection_expr = $args{base_expr};

    return $class->_failure('empty_path')
        unless length $path_text;

    return $class->_failure('missing_declared_type')
        unless ref($root_type_spec) eq 'HASH';

    my $root_kind = $root_type_spec->{kind} || '';
    return $class->_failure(
        'scalar_root',
        current_type_label => FSM::Package::PayloadTypeSupport->type_spec_label($root_type_spec),
    ) unless $root_kind eq 'record' || $root_kind eq 'list';

    my $remaining = $path_text;
    my $current_type_spec = $root_type_spec;

    while (length $remaining) {
        if ($remaining =~ s/\A\.([A-Za-z_]\w*)//) {
            my $member_name = $1;
            my $kind = $current_type_spec->{kind} || '';

            return $class->_failure(
                'member_on_non_record',
                member_name => $member_name,
                current_type_label => FSM::Package::PayloadTypeSupport->type_spec_label($current_type_spec),
            ) unless $kind eq 'record';

            my $members = $current_type_spec->{members} || {};
            return $class->_failure(
                'unknown_member',
                member_name => $member_name,
                known_members => [ @{ $current_type_spec->{member_order} || [] } ],
            ) unless exists $members->{$member_name};

            $connection_expr = member_access_expr($connection_expr, $member_name)
                if defined $connection_expr;
            $current_type_spec = $members->{$member_name};
            next;
        }

        if ($remaining =~ s/\A\[(\d+)(?::(\d+))?\]//) {
            my ($first_index, $second_index) = ($1, $2);
            my $kind = $current_type_spec->{kind} || '';

            if ($kind eq 'list') {
                return $class->_failure('list_range_not_supported')
                    if defined $second_index;

                my $items = $current_type_spec->{items} || [];
                return $class->_failure(
                    'list_index_out_of_range',
                    index => 0 + $first_index,
                    max_index => (@$items ? $#$items : -1),
                ) unless $first_index < @$items;

                $connection_expr = member_access_expr($connection_expr, 'item_'.(0 + $first_index))
                    if defined $connection_expr;
                $current_type_spec = $items->[$first_index];
                next;
            }

            if ($kind eq 'bit' || $kind eq 'bits') {
                my $scalar_width = $current_type_spec->{width} // 0;
                if (defined $second_index) {
                    my ($high, $low) = ($first_index, $second_index);
                    my $max_index = $high > $low ? $high : $low;
                    return $class->_failure(
                        'scalar_slice_out_of_range',
                        high => 0 + $high,
                        low => 0 + $low,
                        scalar_width => 0 + $scalar_width,
                    ) unless $scalar_width > 0 && $max_index < $scalar_width;

                    my $slice_width = abs($high - $low) + 1;
                    $connection_expr = slice_expr($connection_expr, $high, $low)
                        if defined $connection_expr;
                    $current_type_spec = FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width($slice_width);
                    next;
                }

                return $class->_failure(
                    'scalar_index_out_of_range',
                    index => 0 + $first_index,
                    scalar_width => 0 + $scalar_width,
                ) unless $scalar_width > 0 && $first_index < $scalar_width;

                $connection_expr = bit_select_expr($connection_expr, $first_index)
                    if defined $connection_expr;
                $current_type_spec = FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width(1);
                next;
            }

            return $class->_failure(
                'index_on_non_indexable',
                current_type_label => FSM::Package::PayloadTypeSupport->type_spec_label($current_type_spec),
            );
        }

        return $class->_failure(
            'parse_error',
            remaining => $remaining,
        );
    }

    my $resolved_width = ref($current_type_spec) eq 'HASH' ? ($current_type_spec->{width} // undef) : undef;
    return $class->_failure('missing_leaf_width')
        unless defined($resolved_width) && $resolved_width > 0;

    return {
        ok => 1,
        connection_expr => $connection_expr,
        type_spec => $class->clone_structured_value($current_type_spec),
        width => 0 + $resolved_width,
    };
}

sub resolve_type_path ($class, %args) {
    my $result = $class->resolve(%args);
    return (undef, undef) unless $result->{ok};
    return (
        $class->clone_structured_value($result->{type_spec}),
        $result->{width},
    );
}

sub clone_structured_value ($class, $value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => $class->clone_structured_value($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { $class->clone_structured_value($_) } @$value ];
    }

    return $value;
}

sub _failure ($class, $code, %details) {
    return {
        ok => 0,
        code => $code,
        %details,
    };
}

1;

__END__

=head1 METHODS

=head2 resolve

Resolves one authored aggregate path against a declared aggregate type spec and
optionally folds the same path onto a structural connection expression.

=head2 resolve_type_path

Returns only the resolved leaf type spec and width, or C<(undef, undef)> when
the path cannot be resolved.

=head2 clone_structured_value

Clones a nested scalar/list/record type-spec structure.

=cut
