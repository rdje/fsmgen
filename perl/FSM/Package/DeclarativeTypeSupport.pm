package FSM::Package::DeclarativeTypeSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub canonicalize_type_spec ($class, %args) {
    my $spec_ast = $args{spec_ast};
    my $unwrap_scalar_token = $args{unwrap_scalar_token}
        or confess "DeclarativeTypeSupport requires an unwrap_scalar_token callback";
    my $unwrap_single_nested_list = $args{unwrap_single_nested_list}
        or confess "DeclarativeTypeSupport requires an unwrap_single_nested_list callback";
    my $is_contract_type_reference = $args{is_contract_type_reference}
        or confess "DeclarativeTypeSupport requires an is_contract_type_reference callback";
    my $resolve_type_reference = $args{resolve_type_reference}
        or confess "DeclarativeTypeSupport requires a resolve_type_reference callback";
    my $defer_type_reference = $args{defer_type_reference};
    my $is_contract_identifier = $args{is_contract_identifier};

    my $scalar = $unwrap_scalar_token->($spec_ast);
    if (defined($scalar) && !ref($scalar)) {
        return {
            kind => 'bit',
            width => 1,
            signed => 0,
        } if $scalar eq 'bit';

        if ($is_contract_type_reference->($scalar)) {
            my $resolved_spec = $resolve_type_reference->($scalar);
            return $class->_normalized_type_spec($resolved_spec)
                if $class->_is_known_type_spec($resolved_spec);

            my $deferred_spec = $defer_type_reference ? $defer_type_reference->($scalar) : undef;
            return $class->_normalized_type_spec($deferred_spec)
                if $class->_is_deferred_type_spec($deferred_spec);
        }
    }

    my $cursor = $unwrap_single_nested_list->($spec_ast);
    if (ref($cursor) eq 'ARRAY' && @$cursor == 2) {
        my $head = $unwrap_scalar_token->($cursor->[0]);
        my $tail = $cursor->[1];

        if (defined($head) && !ref($head) && ($head eq 'two_state' || $head eq 'four_state')) {
            my $inner_spec = $class->canonicalize_type_spec(
                %args,
                spec_ast => $tail,
            );
            return undef unless $inner_spec;
            return undef unless $class->_can_overlay_scalar_property($inner_spec);

            $inner_spec->{state_model} = $head;
            return $class->_normalized_type_spec($inner_spec);
        }

        if (defined($head) && !ref($head) && $head eq 'bits') {
            my $width_token = $unwrap_scalar_token->($tail);
            if (defined($width_token) && !ref($width_token)
                && $width_token =~ /\A\d+\z/ && $width_token > 0) {
                return {
                    kind => 'bits',
                    width => 0 + $width_token,
                    signed => 0,
                };
            }
        }

        if (defined($head) && !ref($head) && $head eq 'signed') {
            my $inner_spec = $class->canonicalize_type_spec(
                %args,
                spec_ast => $tail,
            );
            return undef unless $inner_spec;
            return undef unless $class->_can_overlay_scalar_property($inner_spec);

            $inner_spec->{signed} = 1;
            return $class->_normalized_type_spec($inner_spec);
        }
    }

    if (ref($cursor) eq 'ARRAY' && @$cursor >= 2) {
        my $head = $unwrap_scalar_token->($cursor->[0]);
        my @body_items = @{$cursor}[1 .. $#$cursor];
        if (@body_items == 1 && ref($body_items[0]) eq 'ARRAY') {
            @body_items = @{ $body_items[0] };
        }

        if (defined($head) && !ref($head) && $head eq 'list') {
            my @items;
            for my $item_ast (@body_items) {
                my $item_spec = $class->canonicalize_type_spec(
                    %args,
                    spec_ast => $item_ast,
                );
                return undef unless $item_spec;
                push @items, $item_spec;
            }
            return undef unless @items;

            return $class->_normalized_type_spec({
                kind => 'list',
                items => \@items,
            });
        }

        if (defined($head) && !ref($head) && $head eq 'record') {
            return undef unless $is_contract_identifier;

            my %members;
            my @member_order;
            for my $member_def (@body_items) {
                return undef unless ref($member_def) eq 'ARRAY' && @$member_def >= 2;

                my $member_name = $unwrap_scalar_token->($member_def->[0]);
                return undef unless $is_contract_identifier->($member_name);
                return undef if exists $members{$member_name};

                my $member_spec_ast = @$member_def == 2
                    ? $member_def->[1]
                    : [ @{$member_def}[1 .. $#$member_def] ];
                my $member_spec = $class->canonicalize_type_spec(
                    %args,
                    spec_ast => $member_spec_ast,
                );
                return undef unless $member_spec;

                $members{$member_name} = $member_spec;
                push @member_order, $member_name;
            }

            return undef unless @member_order;
            return $class->_normalized_type_spec({
                kind => 'record',
                members => \%members,
                member_order => \@member_order,
            });
        }
    }

    return undef;
}

sub finalize_imported_type_spec ($class, %args) {
    my $type_spec = $args{type_spec};
    my $resolve_type_reference = $args{resolve_type_reference}
        or confess "DeclarativeTypeSupport requires a resolve_type_reference callback";

    return undef unless defined $type_spec;
    return undef unless ref($type_spec) eq 'HASH';

    if ($class->_is_deferred_type_spec($type_spec)) {
        my $resolved_spec = $resolve_type_reference->($type_spec->{imported_type_ref});
        return $class->_normalized_type_spec($type_spec) unless defined $resolved_spec;

        $resolved_spec = $class->_normalized_type_spec($resolved_spec);
        return undef unless $resolved_spec;

        if (exists $type_spec->{signed}) {
            return undef unless $class->_can_overlay_scalar_property($resolved_spec);
            $resolved_spec->{signed} = ($type_spec->{signed} // 0) ? 1 : 0;
        }
        if (exists $type_spec->{state_model}) {
            return undef unless $class->_can_overlay_scalar_property($resolved_spec);
            $resolved_spec->{state_model} = $type_spec->{state_model};
        }

        return $class->_normalized_type_spec($resolved_spec);
    }

    my $kind = $type_spec->{kind} || '';
    if ($kind eq 'list') {
        my @items;
        for my $item_spec (@{ $type_spec->{items} || [] }) {
            my $final_item_spec = $class->finalize_imported_type_spec(
                %args,
                type_spec => $item_spec,
            );
            return undef unless $final_item_spec;
            push @items, $final_item_spec;
        }

        return $class->_normalized_type_spec({
            kind => 'list',
            items => \@items,
        });
    }

    if ($kind eq 'record') {
        my %members;
        my @member_order = @{ $type_spec->{member_order} || [] };
        for my $member_name (@member_order) {
            my $final_member_spec = $class->finalize_imported_type_spec(
                %args,
                type_spec => ($type_spec->{members} || {})->{$member_name},
            );
            return undef unless $final_member_spec;
            $members{$member_name} = $final_member_spec;
        }

        return $class->_normalized_type_spec({
            kind => 'record',
            members => \%members,
            member_order => \@member_order,
        });
    }

    return $class->_normalized_type_spec($type_spec);
}

sub has_deferred_imported_aliases ($class, $type_spec) {
    return 0 unless ref($type_spec) eq 'HASH';
    return 1 if $class->_is_deferred_type_spec($type_spec);

    my $kind = $type_spec->{kind} || '';
    if ($kind eq 'list') {
        for my $item_spec (@{ $type_spec->{items} || [] }) {
            return 1 if $class->has_deferred_imported_aliases($item_spec);
        }
        return 0;
    }

    if ($kind eq 'record') {
        for my $member_name (@{ $type_spec->{member_order} || [] }) {
            return 1 if $class->has_deferred_imported_aliases(
                ($type_spec->{members} || {})->{$member_name},
            );
        }
        return 0;
    }

    return 0;
}

sub _is_deferred_type_spec ($class, $type_spec) {
    return ref($type_spec) eq 'HASH'
        && ($type_spec->{kind} || '') eq 'deferred_imported_alias'
        && defined($type_spec->{imported_type_ref})
        && !ref($type_spec->{imported_type_ref});
}

sub _is_known_type_spec ($class, $type_spec) {
    return ref($type_spec) eq 'HASH'
        && !$class->_is_deferred_type_spec($type_spec)
        && defined($type_spec->{kind})
        && !ref($type_spec->{kind});
}

sub _can_overlay_scalar_property ($class, $type_spec) {
    return 0 unless ref($type_spec) eq 'HASH';
    return 1 if $class->_is_deferred_type_spec($type_spec);

    my $kind = $type_spec->{kind} || '';
    return ($kind eq 'bit' || $kind eq 'bits') ? 1 : 0;
}

sub _normalized_type_spec ($class, $type_spec) {
    return undef unless ref($type_spec) eq 'HASH';

    my $kind = $type_spec->{kind} || '';

    if ($class->_is_deferred_type_spec($type_spec)) {
        my %normalized = (
            kind => 'deferred_imported_alias',
            imported_type_ref => $type_spec->{imported_type_ref},
        );
        $normalized{signed} = ($type_spec->{signed} // 0) ? 1 : 0
            if exists $type_spec->{signed};
        if (exists $type_spec->{state_model}) {
            return undef unless defined($type_spec->{state_model})
                && !ref($type_spec->{state_model})
                && $type_spec->{state_model} =~ /\A(?:two_state|four_state)\z/;
            $normalized{state_model} = $type_spec->{state_model};
        }
        return \%normalized;
    }

    if ($kind eq 'bit' || $kind eq 'bits') {
        my %normalized = %{$type_spec};
        return undef unless defined($normalized{width})
            && !ref($normalized{width})
            && $normalized{width} =~ /\A\d+\z/
            && $normalized{width} > 0;

        $normalized{signed} = ($normalized{signed} // 0) ? 1 : 0;
        if (exists $normalized{state_model}) {
            return undef unless defined($normalized{state_model})
                && !ref($normalized{state_model})
                && $normalized{state_model} =~ /\A(?:two_state|four_state)\z/;
        }
        return \%normalized;
    }

    if ($kind eq 'list') {
        my $items = $type_spec->{items};
        return undef unless ref($items) eq 'ARRAY' && @$items;

        my @normalized_items = map { $class->_normalized_type_spec($_) } @$items;
        return undef if grep { !defined $_ } @normalized_items;

        my $width = 0;
        my $all_known = 1;
        for my $item_spec (@normalized_items) {
            if (defined($item_spec->{width}) && !ref($item_spec->{width}) && $item_spec->{width} > 0) {
                $width += 0 + $item_spec->{width};
            } else {
                $all_known = 0;
            }
        }

        my %normalized = (
            kind => 'list',
            items => \@normalized_items,
            signed => 0,
        );
        $normalized{width} = $width if $all_known;
        return \%normalized;
    }

    if ($kind eq 'record') {
        my $members = $type_spec->{members};
        my $member_order = $type_spec->{member_order};
        return undef unless ref($members) eq 'HASH';
        return undef unless ref($member_order) eq 'ARRAY' && @$member_order;

        my %normalized_members;
        my %seen;
        my $width = 0;
        my $all_known = 1;
        for my $member_name (@$member_order) {
            return undef unless defined($member_name) && !ref($member_name) && $member_name =~ /\A[A-Za-z_]\w*\z/;
            return undef if $seen{$member_name}++;
            return undef unless exists $members->{$member_name};

            my $member_spec = $class->_normalized_type_spec($members->{$member_name});
            return undef unless $member_spec;
            $normalized_members{$member_name} = $member_spec;

            if (defined($member_spec->{width}) && !ref($member_spec->{width}) && $member_spec->{width} > 0) {
                $width += 0 + $member_spec->{width};
            } else {
                $all_known = 0;
            }
        }

        my %normalized = (
            kind => 'record',
            members => \%normalized_members,
            member_order => [ @$member_order ],
            signed => 0,
        );
        $normalized{width} = $width if $all_known;
        return \%normalized;
    }

    return undef;
}

1;
