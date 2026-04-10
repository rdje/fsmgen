package FSM::Package::AggregatePathSupport;

=head1 NAME

FSM::Package::AggregatePathSupport - Shared declared aggregate path resolver

=head1 DESCRIPTION

Owns type-directed traversal for declared aggregate member/item paths. Frontend
and composition layers can consume the same resolved path segments and leaf
type facts without carrying parallel walkers that drift over time.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Package::PayloadTypeSupport;

sub resolve ($class, %args) {
    my $root_type_spec = $args{root_type_spec};
    my $path_text = $args{path_text} // '';

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
    my @path_segments;

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

            push @path_segments, { kind => 'member', name => $member_name };
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

                push @path_segments, { kind => 'item', index => 0 + $first_index };
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
                    push @path_segments, { kind => 'bit_slice', high => 0 + $high, low => 0 + $low };
                    $current_type_spec = FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width($slice_width);
                    next;
                }

                return $class->_failure(
                    'scalar_index_out_of_range',
                    index => 0 + $first_index,
                    scalar_width => 0 + $scalar_width,
                ) unless $scalar_width > 0 && $first_index < $scalar_width;

                push @path_segments, { kind => 'bit_index', index => 0 + $first_index };
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
        path_segments => $class->clone_structured_value(\@path_segments),
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

sub resolve_packed_range ($class, %args) {
    my $root_type_spec = $args{root_type_spec};
    return $class->_failure('missing_declared_type')
        unless ref($root_type_spec) eq 'HASH';

    my $path_segments = $args{path_segments};
    if (ref($path_segments) ne 'ARRAY') {
        my $resolved_path = $class->resolve(
            root_type_spec => $root_type_spec,
            path_text => $args{path_text},
        );
        return $resolved_path unless $resolved_path->{ok};
        $path_segments = $resolved_path->{path_segments};
    }

    return $class->_failure('empty_path')
        unless ref($path_segments) eq 'ARRAY' && @$path_segments;

    my $root_kind = $root_type_spec->{kind} || '';
    return $class->_failure(
        'scalar_root',
        current_type_label => FSM::Package::PayloadTypeSupport->type_spec_label($root_type_spec),
    ) unless $root_kind eq 'record' || $root_kind eq 'list';

    my $current_type_spec = $root_type_spec;
    my $base_low = 0;

    for my $segment (@$path_segments) {
        my $kind = $segment->{kind} || '';
        my $type_kind = $current_type_spec->{kind} || '';

        if ($kind eq 'member') {
            my $member_name = $segment->{name};
            return $class->_failure(
                'member_on_non_record',
                member_name => $member_name,
                current_type_label => FSM::Package::PayloadTypeSupport->type_spec_label($current_type_spec),
            ) unless $type_kind eq 'record';

            my $members = $current_type_spec->{members} || {};
            return $class->_failure(
                'unknown_member',
                member_name => $member_name,
                known_members => [ @{ $current_type_spec->{member_order} || [] } ],
            ) unless exists $members->{$member_name};

            my $offset = $class->record_member_low_offset($current_type_spec, $member_name);
            return $class->_failure(
                'member_missing_packed_offset',
                member_name => $member_name,
            ) unless defined $offset;

            $base_low += $offset;
            $current_type_spec = $members->{$member_name};
            next;
        }

        if ($kind eq 'item') {
            return $class->_failure(
                'index_on_non_indexable',
                current_type_label => FSM::Package::PayloadTypeSupport->type_spec_label($current_type_spec),
            ) unless $type_kind eq 'list';

            my $index = $segment->{index};
            my $items = $current_type_spec->{items} || [];
            my $index_label = defined($index) && $index =~ /^\d+$/ ? 0 + $index : $index;
            return $class->_failure(
                'list_index_out_of_range',
                index => $index_label,
                max_index => (@$items ? $#$items : -1),
            ) unless defined($index) && $index =~ /^\d+$/ && $index < @$items;

            my $offset = $class->list_item_low_offset($current_type_spec, $index);
            return $class->_failure(
                'item_missing_packed_offset',
                index => 0 + $index,
            ) unless defined $offset;

            $base_low += $offset;
            $current_type_spec = $items->[$index];
            next;
        }

        if ($kind eq 'bit_index') {
            return $class->_failure(
                'index_on_non_indexable',
                current_type_label => FSM::Package::PayloadTypeSupport->type_spec_label($current_type_spec),
            ) unless $type_kind eq 'bit' || $type_kind eq 'bits';

            my $index = $segment->{index};
            my $width = $current_type_spec->{width} // 0;
            my $index_label = defined($index) && $index =~ /^\d+$/ ? 0 + $index : $index;
            return $class->_failure(
                'scalar_index_out_of_range',
                index => $index_label,
                scalar_width => 0 + $width,
            ) unless defined($index) && $index =~ /^\d+$/ && $width > 0 && $index < $width;

            $base_low += $index;
            $current_type_spec = FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width(1);
            next;
        }

        if ($kind eq 'bit_slice') {
            return $class->_failure(
                'index_on_non_indexable',
                current_type_label => FSM::Package::PayloadTypeSupport->type_spec_label($current_type_spec),
            ) unless $type_kind eq 'bit' || $type_kind eq 'bits';

            my ($high, $low) = ($segment->{high}, $segment->{low});
            my $width = $current_type_spec->{width} // 0;
            my $high_label = defined($high) && $high =~ /^\d+$/ ? 0 + $high : $high;
            my $low_label = defined($low) && $low =~ /^\d+$/ ? 0 + $low : $low;
            return $class->_failure(
                'scalar_slice_out_of_range',
                high => $high_label,
                low => $low_label,
                scalar_width => 0 + $width,
            ) unless defined($high) && defined($low) && $high =~ /^\d+$/ && $low =~ /^\d+$/;

            my $slice_high = $high > $low ? $high : $low;
            my $slice_low = $high > $low ? $low : $high;
            return $class->_failure(
                'scalar_slice_out_of_range',
                high => 0 + $high,
                low => 0 + $low,
                scalar_width => 0 + $width,
            ) unless $width > 0 && $slice_high < $width;

            $base_low += $slice_low;
            $current_type_spec = FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width(
                $slice_high - $slice_low + 1,
            );
            next;
        }

        return $class->_failure(
            'unsupported_path_segment',
            segment_kind => $kind,
        );
    }

    my $resolved_width = ref($current_type_spec) eq 'HASH' ? ($current_type_spec->{width} // undef) : undef;
    return $class->_failure('missing_leaf_width')
        unless defined($resolved_width) && $resolved_width > 0;

    return {
        ok => 1,
        high => $base_low + $resolved_width - 1,
        low => $base_low,
        width => 0 + $resolved_width,
        type_spec => $class->clone_structured_value($current_type_spec),
    };
}

=head2 type_spec_for_packed_fragment

Return the type contract for one packed bit range relative to an aggregate root.
Exact nested record/list fragments keep their aggregate type; arbitrary
cross-member fragments fall back to a scalar width contract.

=cut

sub type_spec_for_packed_fragment ($class, %args) {
    my $root_type_spec = $args{root_type_spec};
    return unless ref($root_type_spec) eq 'HASH';

    my ($high, $low) = ($args{high}, $args{low});
    return unless defined($high)
        && defined($low)
        && $high =~ /^\d+$/
        && $low =~ /^\d+$/
        && $high >= $low;

    my $root_width = $root_type_spec->{width};
    return unless defined($root_width) && $root_width > 0 && $high < $root_width;

    if (defined $args{total_width}) {
        my $total_width = $args{total_width};
        return unless $total_width == $root_width;
    }

    return $class->_type_spec_for_relative_packed_fragment($root_type_spec, 0 + $high, 0 + $low);
}

sub _type_spec_for_relative_packed_fragment ($class, $type_spec, $high, $low) {
    return unless ref($type_spec) eq 'HASH';
    my $width = $type_spec->{width};
    return unless defined($width) && $width > 0;
    return unless defined($high) && defined($low) && $high >= $low && $low >= 0 && $high < $width;

    return $class->clone_structured_value($type_spec)
        if $low == 0 && $high == $width - 1;

    my $kind = $type_spec->{kind} || '';
    if ($kind eq 'record') {
        return $class->_record_fragment_type_spec($type_spec, $high, $low);
    }
    if ($kind eq 'list') {
        return $class->_list_fragment_type_spec($type_spec, $high, $low);
    }

    return FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width($high - $low + 1);
}

sub _record_fragment_type_spec ($class, $type_spec, $high, $low) {
    my $members = $type_spec->{members} || {};
    for my $member_name (@{$type_spec->{member_order} || []}) {
        next unless exists $members->{$member_name};
        my $member_type_spec = $members->{$member_name};
        my $member_low = $class->record_member_low_offset($type_spec, $member_name);
        next unless defined $member_low;
        my $member_width = $member_type_spec->{width};
        next unless defined($member_width) && $member_width > 0;
        my $member_high = $member_low + $member_width - 1;

        next unless $low >= $member_low && $high <= $member_high;
        return $class->_type_spec_for_relative_packed_fragment(
            $member_type_spec,
            $high - $member_low,
            $low - $member_low,
        );
    }

    return FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width($high - $low + 1);
}

sub _list_fragment_type_spec ($class, $type_spec, $high, $low) {
    my $items = $type_spec->{items} || [];
    for my $index (0 .. $#$items) {
        my $item_type_spec = $items->[$index];
        my $item_low = $class->list_item_low_offset($type_spec, $index);
        next unless defined $item_low;
        my $item_width = $item_type_spec->{width};
        next unless defined($item_width) && $item_width > 0;
        my $item_high = $item_low + $item_width - 1;

        next unless $low >= $item_low && $high <= $item_high;
        return $class->_type_spec_for_relative_packed_fragment(
            $item_type_spec,
            $high - $item_low,
            $low - $item_low,
        );
    }

    return FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width($high - $low + 1);
}

sub record_member_low_offset ($class, $record_type_spec, $member_name) {
    my $members = $record_type_spec->{members} || {};
    my $order = $record_type_spec->{member_order} || [];
    my $offset = 0;

    for my $ordered_member (reverse @$order) {
        return $offset if $ordered_member eq $member_name;
        return undef unless exists $members->{$ordered_member};
        $offset += $members->{$ordered_member}{width} // 0;
    }

    return undef;
}

sub list_item_low_offset ($class, $list_type_spec, $target_index) {
    my $items = $list_type_spec->{items} || [];
    return undef unless defined($target_index) && $target_index =~ /^\d+$/ && $target_index < @$items;

    my $offset = 0;
    for my $index (reverse 0 .. $#$items) {
        return $offset if $index == $target_index;
        $offset += $items->[$index]{width} // 0;
    }

    return undef;
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
returns stable path segments plus the resolved leaf type and width.

=head2 resolve_type_path

Returns only the resolved leaf type spec and width, or C<(undef, undef)> when
the path cannot be resolved.

=head2 resolve_packed_range

Resolves a declared aggregate path into the packed base-signal bit range that
the leaf occupies.

=head2 record_member_low_offset

Returns the packed low-bit offset of a record member within its record.

=head2 list_item_low_offset

Returns the packed low-bit offset of a list item within its generated packed
list representation.

=head2 clone_structured_value

Clones a nested scalar/list/record type-spec structure.

=cut
