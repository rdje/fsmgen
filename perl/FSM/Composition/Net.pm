package FSM::Composition::Net;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        name => $args{name},
        width => $args{width} // 1,
        source => $args{source},
        targets => $args{targets} || [],
        declared_type_name => $args{declared_type_name},
        declared_type_spec => _clone_structured_value($args{declared_type_spec}),
    }, $class;
}

sub name ($self) { return $self->{name} }
sub width ($self) { return $self->{width} }
sub source ($self) { return $self->{source} }
sub targets ($self) { return $self->{targets} }
sub declared_type_name ($self) { return $self->{declared_type_name} }
sub declared_type_spec ($self) { return _clone_structured_value($self->{declared_type_spec}) }

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
