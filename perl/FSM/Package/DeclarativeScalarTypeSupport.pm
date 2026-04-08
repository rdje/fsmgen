package FSM::Package::DeclarativeScalarTypeSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub canonicalize_type_spec ($class, %args) {
    my $spec_ast = $args{spec_ast};
    my $unwrap_scalar_token = $args{unwrap_scalar_token}
        or confess "DeclarativeScalarTypeSupport requires an unwrap_scalar_token callback";
    my $unwrap_single_nested_list = $args{unwrap_single_nested_list}
        or confess "DeclarativeScalarTypeSupport requires an unwrap_single_nested_list callback";
    my $is_contract_type_reference = $args{is_contract_type_reference}
        or confess "DeclarativeScalarTypeSupport requires an is_contract_type_reference callback";
    my $resolve_type_reference = $args{resolve_type_reference}
        or confess "DeclarativeScalarTypeSupport requires a resolve_type_reference callback";
    my $defer_type_reference = $args{defer_type_reference};

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
                if $class->_is_real_scalar_type_spec($resolved_spec);

            my $deferred_spec = $defer_type_reference ? $defer_type_reference->($scalar) : undef;
            return $class->_normalized_type_spec($deferred_spec)
                if $class->_is_deferred_type_spec($deferred_spec);
        }
    }

    my $cursor = $unwrap_single_nested_list->($spec_ast);
    if (ref($cursor) eq 'ARRAY' && @$cursor == 2) {
        my $head = $unwrap_scalar_token->($cursor->[0]);
        my $tail = $cursor->[1];

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

            $inner_spec->{signed} = 1;
            return $class->_normalized_type_spec($inner_spec);
        }
    }

    return undef;
}

sub _is_deferred_type_spec ($class, $type_spec) {
    return ref($type_spec) eq 'HASH'
        && ($type_spec->{kind} || '') eq 'deferred_imported_alias'
        && defined($type_spec->{imported_type_ref})
        && !ref($type_spec->{imported_type_ref});
}

sub _is_real_scalar_type_spec ($class, $type_spec) {
    return ref($type_spec) eq 'HASH'
        && ($type_spec->{kind} || '') ne 'deferred_imported_alias'
        && defined($type_spec->{width})
        && !ref($type_spec->{width})
        && $type_spec->{width} =~ /\A\d+\z/
        && $type_spec->{width} > 0;
}

sub _normalized_type_spec ($class, $type_spec) {
    return undef unless ref($type_spec) eq 'HASH';

    my %normalized = %{$type_spec};
    if ($class->_is_deferred_type_spec(\%normalized)) {
        $normalized{signed} = $normalized{signed} ? 1 : 0
            if exists $normalized{signed};
        return \%normalized;
    }

    $normalized{signed} = ($normalized{signed} // 0) ? 1 : 0;
    return \%normalized;
}

1;
