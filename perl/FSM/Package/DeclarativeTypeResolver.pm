package FSM::Package::DeclarativeTypeResolver;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub resolve_types ($class, %args) {
    my $type_entries = $args{type_entries} || [];
    my $unwrap_scalar_token = $args{unwrap_scalar_token}
        or confess "DeclarativeTypeResolver requires an unwrap_scalar_token callback";
    my $unwrap_single_nested_list = $args{unwrap_single_nested_list}
        or confess "DeclarativeTypeResolver requires an unwrap_single_nested_list callback";
    my $is_contract_identifier = $args{is_contract_identifier}
        or confess "DeclarativeTypeResolver requires an is_contract_identifier callback";
    my $resolve_type_spec = $args{resolve_type_spec}
        or confess "DeclarativeTypeResolver requires a resolve_type_spec callback";
    my $store_type = $args{store_type}
        or confess "DeclarativeTypeResolver requires a store_type callback";
    my $cycle_error = $args{cycle_error}
        or confess "DeclarativeTypeResolver requires a cycle_error callback";

    my %type_defs = map { $_->{name} => $_ } @$type_entries;
    my %deps_cache;
    my %state;

    my $dependency_for_token = sub ($token) {
        return undef unless defined($token) && !ref($token);
        return undef if $token eq 'bit';
        return undef unless $is_contract_identifier->($token);
        return undef unless exists $type_defs{$token};
        return {
            type => 'type',
            name => $token,
        };
    };

    my $type_dependencies = sub ($type_name) {
        return $deps_cache{$type_name} if exists $deps_cache{$type_name};

        my $entry = $type_defs{$type_name} || {};
        my $spec_ast = $entry->{spec_ast};
        my @deps;
        my %seen;

        my $scalar = $unwrap_scalar_token->($spec_ast);
        if (defined($scalar) && !ref($scalar)) {
            my $dep = $dependency_for_token->($scalar);
            if ($dep) {
                my $key = $dep->{type} . ':' . $dep->{name};
                push @deps, $dep unless $seen{$key}++;
            }
            $deps_cache{$type_name} = \@deps;
            return $deps_cache{$type_name};
        }

        my $cursor = $unwrap_single_nested_list->($spec_ast);
        if (ref($cursor) eq 'ARRAY' && @$cursor) {
            my $head = $unwrap_scalar_token->($cursor->[0]);
            if (defined($head) && !ref($head) && $head ne 'bits') {
                my $dep = $dependency_for_token->($head);
                if ($dep) {
                    my $key = $dep->{type} . ':' . $dep->{name};
                    push @deps, $dep unless $seen{$key}++;
                }
            }
        }

        $deps_cache{$type_name} = \@deps;
        return $deps_cache{$type_name};
    };

    my $resolve_one;
    $resolve_one = sub ($type_name, $chain = []) {
        my $state_key = 'type:' . $type_name;
        return if ($state{$state_key} || '') eq 'resolved';

        if (($state{$state_key} || '') eq 'resolving') {
            my @cycle_chain = (@$chain, { type => 'type', name => $type_name });
            $cycle_error->(type => 'type', name => $type_name, chain => \@cycle_chain);
            return;
        }

        $state{$state_key} = 'resolving';

        for my $dep (@{ $type_dependencies->($type_name) }) {
            $resolve_one->(
                $dep->{name},
                [ @$chain, { type => 'type', name => $type_name } ],
            );
        }

        my $resolved_spec = $resolve_type_spec->($type_defs{$type_name});
        $store_type->($type_name, $resolved_spec);
        $state{$state_key} = 'resolved';
    };

    for my $type_name (map { $_->{name} } @$type_entries) {
        next unless exists $type_defs{$type_name};
        $resolve_one->($type_name);
    }

    return 1;
}

1;
