package FSM::Package::PayloadTypeSupport;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Package::PayloadLiteralSupport;

sub payload_to_type_spec ($class, $payload) {
    return $class->_payload_to_type_spec($payload);
}

sub payload_compatible_with_type_spec ($class, $payload_or_spec, $target_type_spec) {
    my $payload_type_spec = (
        ref($payload_or_spec) eq 'HASH' && exists $payload_or_spec->{kind}
            ? $payload_or_spec
            : $class->payload_to_type_spec($payload_or_spec)
    );
    return 0 unless ref($payload_type_spec) eq 'HASH';
    return 0 unless ref($target_type_spec) eq 'HASH';

    return $class->_type_spec_accepts_payload_type_spec($target_type_spec, $payload_type_spec);
}

sub type_spec_label ($class, $type_spec) {
    return $class->_type_spec_label($type_spec);
}

sub scalar_type_spec_from_width ($class, $width) {
    return $class->_scalar_type_spec_from_width($width);
}

sub _payload_to_type_spec ($class, $payload) {
    return undef unless defined $payload;

    if (!ref($payload)) {
        my ($bits, $width, $reason) = FSM::Package::PayloadLiteralSupport->payload_to_bits_and_width($payload);
        return undef unless defined $bits && defined $width && !defined $reason;
        return $class->_scalar_type_spec_from_width($width);
    }

    return undef unless ref($payload) eq 'HASH';

    my $kind = $payload->{kind} || '';
    if ($kind eq 'scalar') {
        my ($bits, $width, $reason) = FSM::Package::PayloadLiteralSupport->payload_to_bits_and_width($payload);
        return undef unless defined $bits && defined $width && !defined $reason;
        return $class->_scalar_type_spec_from_width($width);
    }

    if ($kind eq 'list') {
        my @item_specs;
        my $total_width = 0;

        for my $item (@{ $payload->{items} || [] }) {
            my $item_spec = $class->_payload_to_type_spec($item) or return undef;
            push @item_specs, $item_spec;
            $total_width += ($item_spec->{width} // 0);
        }

        return undef unless @item_specs;
        return {
            kind => 'list',
            width => $total_width,
            signed => 0,
            items => \@item_specs,
        };
    }

    if ($kind eq 'map') {
        my $members = $payload->{members};
        return undef unless ref($members) eq 'HASH' && keys %$members;

        my $member_order = $payload->{member_order};
        my @ordered_members = (
            ref($member_order) eq 'ARRAY' && @$member_order
                ? @$member_order
                : sort keys %$members
        );
        return undef unless @ordered_members;

        my %member_specs;
        my $total_width = 0;
        for my $member_name (@ordered_members) {
            return undef unless exists $members->{$member_name};
            my $member_spec = $class->_payload_to_type_spec($members->{$member_name}) or return undef;
            $member_specs{$member_name} = $member_spec;
            $total_width += ($member_spec->{width} // 0);
        }

        return {
            kind => 'record',
            width => $total_width,
            signed => 0,
            member_order => \@ordered_members,
            members => \%member_specs,
        };
    }

    return undef;
}

sub _scalar_type_spec_from_width ($class, $width) {
    return undef unless defined $width && $width =~ /\A\d+\z/ && $width > 0;
    return {
        kind => 'bit',
        width => 1,
        signed => 0,
    } if $width == 1;

    return {
        kind => 'bits',
        width => 0 + $width,
        signed => 0,
    };
}

sub _type_spec_accepts_payload_type_spec ($class, $target_type_spec, $payload_type_spec) {
    return 0 unless ref($target_type_spec) eq 'HASH' && ref($payload_type_spec) eq 'HASH';

    my $target_kind = $target_type_spec->{kind} || '';
    my $payload_kind = $payload_type_spec->{kind} || '';

    if ($target_kind eq 'bit') {
        return ($payload_kind eq 'bit' || $payload_kind eq 'bits')
            && (($payload_type_spec->{width} // 0) == 1);
    }

    if ($target_kind eq 'bits') {
        return ($payload_kind eq 'bit' || $payload_kind eq 'bits')
            && (($payload_type_spec->{width} // 0) == ($target_type_spec->{width} // -1));
    }

    if ($target_kind eq 'list') {
        return 0 unless $payload_kind eq 'list';

        my $target_items = $target_type_spec->{items} || [];
        my $payload_items = $payload_type_spec->{items} || [];
        return 0 unless @$target_items == @$payload_items;

        for my $index (0 .. $#$target_items) {
            return 0 unless $class->_type_spec_accepts_payload_type_spec(
                $target_items->[$index],
                $payload_items->[$index],
            );
        }

        return 1;
    }

    if ($target_kind eq 'record') {
        return 0 unless $payload_kind eq 'record';

        my $target_member_order = $target_type_spec->{member_order} || [];
        my $payload_member_order = $payload_type_spec->{member_order} || [];
        return 0 unless @$target_member_order == @$payload_member_order;
        for my $index (0 .. $#$target_member_order) {
            return 0 unless $target_member_order->[$index] eq $payload_member_order->[$index];
        }

        my $target_members = $target_type_spec->{members} || {};
        my $payload_members = $payload_type_spec->{members} || {};
        for my $member_name (@$target_member_order) {
            return 0 unless exists $target_members->{$member_name} && exists $payload_members->{$member_name};
            return 0 unless $class->_type_spec_accepts_payload_type_spec(
                $target_members->{$member_name},
                $payload_members->{$member_name},
            );
        }

        return 1;
    }

    return 0;
}

sub _type_spec_label ($class, $spec) {
    return 'unknown' unless ref($spec) eq 'HASH';

    my $kind = $spec->{kind} || '';
    if ($kind eq 'bit') {
        my $label = 'bit';
        $label = "signed $label" if $spec->{signed};
        $label = ($spec->{state_model} || '').' '.$label if defined $spec->{state_model};
        $label =~ s/\A\s+|\s+\z//g;
        return $label;
    }

    if ($kind eq 'bits') {
        my $label = 'bits['.($spec->{width} // '?').']';
        $label = "signed $label" if $spec->{signed};
        $label = ($spec->{state_model} || '').' '.$label if defined $spec->{state_model};
        $label =~ s/\A\s+|\s+\z//g;
        return $label;
    }

    if ($kind eq 'list') {
        return 'list<'.join(', ', map { $class->_type_spec_label($_) } @{ $spec->{items} || [] }).'>';
    }

    if ($kind eq 'record') {
        return 'record{'.join(', ', map {
            $_.':'.$class->_type_spec_label(($spec->{members} || {})->{$_})
        } @{ $spec->{member_order} || [] }).'}';
    }

    if ($kind eq 'deferred_imported_alias') {
        return $spec->{imported_type_ref} // 'deferred_imported_alias';
    }

    return $kind;
}

1;

__END__

=head1 NAME

FSM::Package::PayloadTypeSupport - Inferred type-shape helpers for constant payloads

=head1 DESCRIPTION

Infers bounded type-shape information from canonical package/top/direct constant
payloads and compares that inferred payload shape against declared aggregate
type contracts.

=head1 METHODS

=head2 payload_to_type_spec

Infers one canonical packed type shape from a scalar/list/map payload.

=head2 payload_compatible_with_type_spec

Returns true when a target type spec accepts the inferred payload shape. Scalar
leaf compatibility is width-based; aggregate compatibility is shape plus
ordered-field/item based.

=head2 type_spec_label

Formats one canonical type spec into a compact user-facing label.

=head2 scalar_type_spec_from_width

Returns one canonical unsigned scalar type spec for a positive packed width.

=cut
