package FSM::Package::DeclarativeSymbolResolver;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub resolve_symbols ($class, %args) {
    my $constant_entries = $args{constant_entries} || [];
    my $enum_entries = $args{enum_entries} || [];
    my $value_items = $args{value_items}
        or confess "DeclarativeSymbolResolver requires a value_items callback";
    my $unwrap_scalar_token = $args{unwrap_scalar_token}
        or confess "DeclarativeSymbolResolver requires an unwrap_scalar_token callback";
    my $is_contract_identifier = $args{is_contract_identifier}
        or confess "DeclarativeSymbolResolver requires an is_contract_identifier callback";
    my $resolve_constant_payload = $args{resolve_constant_payload}
        or confess "DeclarativeSymbolResolver requires a resolve_constant_payload callback";
    my $resolve_enum_member_payload = $args{resolve_enum_member_payload}
        or confess "DeclarativeSymbolResolver requires a resolve_enum_member_payload callback";
    my $store_constant = $args{store_constant}
        or confess "DeclarativeSymbolResolver requires a store_constant callback";
    my $store_enum = $args{store_enum}
        or confess "DeclarativeSymbolResolver requires a store_enum callback";
    my $cycle_error = $args{cycle_error}
        or confess "DeclarativeSymbolResolver requires a cycle_error callback";

    my %constant_defs = map { $_->{name} => $_ } @$constant_entries;
    my %enum_defs = map { $_->{name} => $_ } @$enum_entries;

    my %constant_deps_cache;
    my %enum_deps_cache;
    my %state;

    my $dependency_for_token = sub ($token) {
        return undef unless defined($token) && !ref($token);
        return undef unless $token =~ /\A([A-Za-z_]\w*)(.*)\z/;

        my ($root_name, $suffix) = ($1, $2 // '');

        if (length($suffix) && $suffix =~ /\A\.[A-Za-z_]\w*\z/ && exists $enum_defs{$root_name}) {
            return {
                type => 'enum',
                name => $root_name,
            };
        }

        if (exists $constant_defs{$root_name}) {
            return {
                type => 'constant',
                name => $root_name,
            };
        }

        return undef;
    };

    my $dependency_key = sub ($dependency) {
        return $dependency->{type} . ':' . $dependency->{name};
    };

    my $scan_constant_dependencies;
    $scan_constant_dependencies = sub ($value_ast) {
        my @dependencies;
        my %seen;
        my $record_dependency = sub ($token) {
            my $dependency = $dependency_for_token->($token) or return;
            my $key = $dependency_key->($dependency);
            return if $seen{$key}++;
            push @dependencies, $dependency;
        };

        my $walk_value_ast;
        $walk_value_ast = sub ($node) {
            my $scalar_value = $unwrap_scalar_token->($node);
            if (defined($scalar_value) && !ref($scalar_value)) {
                $record_dependency->($scalar_value);
                return;
            }

            return unless ref($node) eq 'ARRAY' && @$node;

            my $value_items_list = $value_items->($node) || [];
            return unless @$value_items_list;

            my $hash_like_entries = 0;
            my $non_hash_entries = 0;
            for my $entry (@$value_items_list) {
                my $member_name = (ref($entry) eq 'ARRAY' && @$entry == 2)
                    ? $unwrap_scalar_token->($entry->[0])
                    : undef;
                if (defined($member_name) && $is_contract_identifier->($member_name)) {
                    $hash_like_entries++;
                } else {
                    $non_hash_entries++;
                }
            }

            if ($hash_like_entries && !$non_hash_entries) {
                for my $entry (@$value_items_list) {
                    next unless ref($entry) eq 'ARRAY' && @$entry == 2;
                    $walk_value_ast->($entry->[1]);
                }
                return;
            }

            for my $entry (@$value_items_list) {
                $walk_value_ast->($entry);
            }
        };

        $walk_value_ast->($value_ast);
        return \@dependencies;
    };

    my $enum_dependencies = sub ($enum_name) {
        return $enum_deps_cache{$enum_name} if exists $enum_deps_cache{$enum_name};

        my $enum_def = $enum_defs{$enum_name} || {};
        my %seen;
        my @dependencies;
        for my $member_def (@{ $enum_def->{members} || [] }) {
            my $dependency = $dependency_for_token->($member_def->{value_token});
            next unless $dependency;
            my $key = $dependency_key->($dependency);
            next if $seen{$key}++;
            push @dependencies, $dependency;
        }

        $enum_deps_cache{$enum_name} = \@dependencies;
        return $enum_deps_cache{$enum_name};
    };

    my $constant_dependencies = sub ($constant_name) {
        return $constant_deps_cache{$constant_name} if exists $constant_deps_cache{$constant_name};
        my $constant_def = $constant_defs{$constant_name} || {};
        $constant_deps_cache{$constant_name} = $scan_constant_dependencies->($constant_def->{value_ast});
        return $constant_deps_cache{$constant_name};
    };

    my $resolve_node;
    $resolve_node = sub ($type, $name, $chain = []) {
        my $state_key = $type . ':' . $name;
        return if ($state{$state_key} || '') eq 'resolved';

        if (($state{$state_key} || '') eq 'resolving') {
            my @cycle_chain = (@$chain, { type => $type, name => $name });
            $cycle_error->(
                type => $type,
                name => $name,
                chain => \@cycle_chain,
            );
            return;
        }

        $state{$state_key} = 'resolving';

        my $dependencies = $type eq 'constant'
            ? $constant_dependencies->($name)
            : $enum_dependencies->($name);

        for my $dependency (@$dependencies) {
            $resolve_node->(
                $dependency->{type},
                $dependency->{name},
                [ @$chain, { type => $type, name => $name } ],
            );
        }

        if ($type eq 'constant') {
            my $payload = $resolve_constant_payload->($constant_defs{$name});
            $store_constant->($name, $payload);
        } else {
            my %members;
            for my $member_def (@{ $enum_defs{$name}{members} || [] }) {
                $members{$member_def->{name}} = $resolve_enum_member_payload->(
                    $enum_defs{$name},
                    $member_def,
                );
            }
            $store_enum->($name, \%members);
        }

        $state{$state_key} = 'resolved';
    };

    for my $constant_name (map { $_->{name} } @$constant_entries) {
        next unless exists $constant_defs{$constant_name};
        $resolve_node->('constant', $constant_name);
    }

    for my $enum_name (map { $_->{name} } @$enum_entries) {
        next unless exists $enum_defs{$enum_name};
        $resolve_node->('enum', $enum_name);
    }

    return 1;
}

1;
