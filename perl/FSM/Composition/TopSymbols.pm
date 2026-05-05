package FSM::Composition::TopSymbols;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Scalar::Util qw(blessed);
use FSM::Package::DeclarativeTypeSupport;
use FSM::Package::Symbols;
use FSM::Package::ScalarWidthSupport;

sub new ($class, %args) {
    my $local_symbols = $args{local_symbols} || FSM::Package::Symbols->new(
        constants => $args{constants} || {},
        enums => $args{enums} || {},
    );

    return bless {
        local_symbols => $local_symbols,
        imported_packages => _clone_imported_packages($args{imported_packages} || {}),
        raw_blocks => _clone($args{raw_blocks} || []),
    }, $class;
}

sub local_symbols ($self) { return $self->{local_symbols} }
sub constants ($self) { return $self->{local_symbols}->constants }
sub enums ($self) { return $self->{local_symbols}->enums }
sub types ($self) { return $self->{local_symbols}->types }
sub imported_packages ($self) { return _clone_imported_packages($self->{imported_packages}) }
sub raw_blocks ($self) { return _clone($self->{raw_blocks}) }

sub store_constant ($self, $name, $payload) {
    return $self->{local_symbols}->store_constant($name, $payload);
}

sub store_enum ($self, $enum_name, $members_hashref) {
    return $self->{local_symbols}->store_enum($enum_name, $members_hashref);
}

sub store_type ($self, $type_name, $type_hashref) {
    return $self->{local_symbols}->store_type($type_name, $type_hashref);
}

sub push_raw_block ($self, $block_ast) {
    push @{ $self->{raw_blocks} }, _clone($block_ast) if defined $block_ast;
    return $self->raw_blocks;
}

sub import_package ($self, $package_name, $package_symbols) {
    $self->{imported_packages}{$package_name} = _clone_package_symbols($package_symbols);
    return _clone_package_symbols($self->{imported_packages}{$package_name});
}

sub _is_deferred_imported_type_alias ($self, $type_spec) {
    return ref($type_spec) eq 'HASH'
        && ($type_spec->{kind} || '') eq 'deferred_imported_alias'
        && defined($type_spec->{imported_type_ref})
        && !ref($type_spec->{imported_type_ref});
}

sub _resolve_imported_type_ref ($self, $type_ref) {
    return undef unless defined($type_ref) && !ref($type_ref);
    return undef unless $type_ref =~ /\A([A-Za-z_]\w*)\.(.+)\z/;

    my ($package_name, $package_type) = ($1, $2);
    my $package_symbols = $self->{imported_packages}{$package_name};
    return undef unless $package_symbols && $package_symbols->can('resolve_type');
    return $package_symbols->resolve_type($package_type);
}

sub resolve_actual_payload ($self, $symbol_name) {
    return undef unless defined($symbol_name) && !ref($symbol_name);

    my $resolved_local_payload = $self->{local_symbols}->resolve_actual_payload($symbol_name);
    return $resolved_local_payload if defined $resolved_local_payload;

    if ($symbol_name =~ /\A([A-Za-z_]\w*)\.(.+)\z/) {
        my ($package_name, $package_symbol) = ($1, $2);
        my $package_symbols = $self->{imported_packages}{$package_name};
        return undef unless $package_symbols && $package_symbols->can('resolve_actual_payload');
        return $package_symbols->resolve_actual_payload($package_symbol);
    }

    return undef;
}

sub resolve_payload ($self, $symbol_name) {
    return undef unless defined($symbol_name) && !ref($symbol_name);

    my $resolved_local_payload = $self->{local_symbols}->resolve_payload($symbol_name);
    return $resolved_local_payload if defined $resolved_local_payload;

    if ($symbol_name =~ /\A([A-Za-z_]\w*)\.(.+)\z/) {
        my ($package_name, $package_symbol) = ($1, $2);
        my $package_symbols = $self->{imported_packages}{$package_name};
        return undef unless $package_symbols && $package_symbols->can('resolve_payload');
        return $package_symbols->resolve_payload($package_symbol);
    }

    return undef;
}

sub resolve_type ($self, $type_name) {
    return undef unless defined($type_name) && !ref($type_name);

    my $resolved_local_type = $self->{local_symbols}->resolve_type($type_name);
    if (defined $resolved_local_type) {
        if ($self->_is_deferred_imported_type_alias($resolved_local_type)) {
            my $resolved_imported_type = $self->_resolve_imported_type_ref($resolved_local_type->{imported_type_ref});
            return $resolved_imported_type if defined $resolved_imported_type;
        }
        return $resolved_local_type;
    }

    if ($type_name =~ /\A([A-Za-z_]\w*)\.(.+)\z/) {
        my ($package_name, $package_type) = ($1, $2);
        my $package_symbols = $self->{imported_packages}{$package_name};
        return undef unless $package_symbols && $package_symbols->can('resolve_type');
        return $package_symbols->resolve_type($package_type);
    }

    return undef;
}

sub resolve_positive_integer_scalar ($self, $symbol_name) {
    return undef unless defined($symbol_name) && !ref($symbol_name);

    my $resolved_scalar_payload = $self->resolve_actual_payload($symbol_name);
    return FSM::Package::ScalarWidthSupport->positive_integer_from_literal_like(
        $resolved_scalar_payload,
    );
}

sub finalize_imported_type_aliases ($self) {
    my $local_types = $self->{local_symbols}->types || {};

    for my $type_name (sort keys %$local_types) {
        my $type_spec = $self->{local_symbols}->resolve_type($type_name);
        my $finalized_spec = FSM::Package::DeclarativeTypeSupport->finalize_imported_type_spec(
            type_spec => $type_spec,
            resolve_type_reference => sub ($type_ref) {
                return $self->_resolve_imported_type_ref($type_ref);
            },
        );
        next unless defined $finalized_spec;

        $self->{local_symbols}->store_type($type_name, $finalized_spec);
    }

    return 1;
}

sub summary ($self) {
    return $self->{local_symbols}->summary;
}

sub as_hashref ($self) {
    my $symbol_contract = (
        $self->{local_symbols} && $self->{local_symbols}->can('as_hashref')
            ? $self->{local_symbols}->as_hashref
            : {}
    );

    $symbol_contract->{package_import_count} = scalar(keys %{ $self->{imported_packages} || {} });
    $symbol_contract->{package_imports} = [ sort keys %{ $self->{imported_packages} || {} } ];

    return $symbol_contract;
}

sub _clone_imported_packages ($packages) {
    return {} unless ref($packages) eq 'HASH';
    return {
        map { $_ => _clone_package_symbols($packages->{$_}) } keys %$packages
    };
}

sub _clone_package_symbols ($package_symbols) {
    return _clone($package_symbols)
        unless blessed($package_symbols)
            && $package_symbols->can('constants')
            && $package_symbols->can('enums')
            && $package_symbols->can('types')
            && $package_symbols->can('raw_blocks')
            && $package_symbols->can('new');

    my $class = ref($package_symbols);
    return $class->new(
        constants => $package_symbols->constants,
        enums => $package_symbols->enums,
        types => $package_symbols->types,
        raw_blocks => $package_symbols->raw_blocks,
    );
}

sub _clone ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }

    return $value;
}

1;
