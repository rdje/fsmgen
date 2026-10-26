package FSM::Composition::Port;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        name => $args{name},
        direction => $args{direction},
        width => exists $args{width} ? $args{width} : 1,
        width_token => _clone_structured_value($args{width_token}),
        width_contract => _clone_structured_value($args{width_contract}),
        signed => ($args{signed} // 0) ? 1 : 0,
        state_model => $args{state_model},
        declared_type_name => $args{declared_type_name},
        declared_type_spec => _clone_structured_value($args{declared_type_spec}),
        type => $args{type},
        binding_mode => $args{binding_mode} // 'explicit',
        raw_token => $args{raw_token},
        origin_kind => $args{origin_kind},
    }, $class;
}

sub name ($self) { return $self->{name} }
sub direction ($self) { return $self->{direction} }
sub width ($self) { return $self->{width} }
sub width_token ($self) { return _clone_structured_value($self->{width_token}) }
sub width_contract ($self) { return _clone_structured_value($self->{width_contract}) }
sub set_width_contract ($self, $contract) {
    $self->{width_contract} = _clone_structured_value($contract);
    return $self->width_contract;
}
sub signed ($self) { return $self->{signed} }
sub state_model ($self) { return $self->{state_model} }
sub declared_type_name ($self) { return $self->{declared_type_name} }
sub declared_type_spec ($self) { return _clone_structured_value($self->{declared_type_spec}) }
sub type ($self) { return $self->{type} }
sub binding_mode ($self) { return $self->{binding_mode} }
sub raw_token ($self) { return $self->{raw_token} }
sub origin_kind ($self) { return $self->{origin_kind} }

sub set_width ($self, $width) {
    $self->{width} = $width;
    return $self->{width};
}

sub set_signed ($self, $signed) {
    $self->{signed} = $signed ? 1 : 0;
    return $self->{signed};
}

sub set_state_model ($self, $state_model) {
    $self->{state_model} = $state_model;
    return $self->{state_model};
}

sub set_declared_type_name ($self, $declared_type_name) {
    $self->{declared_type_name} = $declared_type_name;
    return $self->{declared_type_name};
}

sub set_declared_type_spec ($self, $declared_type_spec) {
    $self->{declared_type_spec} = _clone_structured_value($declared_type_spec);
    return $self->declared_type_spec;
}

sub snapshot ($self) {
    if (ref($self->{width_token})) {
        confess "Port '$self->{name}' requires a resolved width and source contract before snapshot\n"
            unless defined($self->{width}) && $self->{width} > 0
                && ref($self->{width_contract}) eq 'HASH';
    }
    return bless _clone_structured_value({%$self}), ref($self);
}

sub _clone_structured_value ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone_structured_value($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone_structured_value($_) } @$value ];
    }

    return $value;
}

1;

=head1 NAME

FSM::Composition::Port - Composition interface port with authored width provenance

=head1 DESCRIPTION

C<width_token> returns detached authored width syntax. Structured width forms
also expose a detached C<width_contract> after import/default resolution.
C<snapshot> returns a separate Port object with the complete current attributes;
structured-width ports require a resolved positive width and source contract.
The copy preserves JSON scalar kinds and nested type/source/reference records.
This does not enable symbolic source planning or HDL emission.

=cut
