package FSM::Composition::TopSymbols;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Package::Symbols;

sub new ($class, %args) {
    my $local_symbols = $args{local_symbols} || FSM::Package::Symbols->new(
        constants => $args{constants} || {},
        enums => $args{enums} || {},
    );

    return bless {
        local_symbols => $local_symbols,
        imported_packages => $args{imported_packages} || {},
        raw_blocks => $args{raw_blocks} || [],
    }, $class;
}

sub local_symbols ($self) { return $self->{local_symbols} }
sub constants ($self) { return $self->{local_symbols}->constants }
sub enums ($self) { return $self->{local_symbols}->enums }
sub imported_packages ($self) { return $self->{imported_packages} }
sub raw_blocks ($self) { return $self->{raw_blocks} }

sub store_constant ($self, $name, $payload) {
    return $self->{local_symbols}->store_constant($name, $payload);
}

sub store_enum ($self, $enum_name, $members_hashref) {
    return $self->{local_symbols}->store_enum($enum_name, $members_hashref);
}

sub push_raw_block ($self, $block_ast) {
    push @{ $self->{raw_blocks} }, $block_ast if defined $block_ast;
    return $self->{raw_blocks};
}

sub import_package ($self, $package_name, $package_symbols) {
    $self->{imported_packages}{$package_name} = $package_symbols;
    return $package_symbols;
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

1;
