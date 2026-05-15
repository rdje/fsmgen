package FSM::Composition::Top;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::TopSymbols;

sub new ($class, %args) {
    return bless {
        name => $args{name},
        instances => _clone($args{instances} || []),
        ports_blocks => _clone($args{ports_blocks} || []),
        wiring_blocks => _clone($args{wiring_blocks} || []),
        package_imports => _clone($args{package_imports} || []),
        top_symbols => $args{top_symbols} || FSM::Composition::TopSymbols->new(),
        raw_ast => _clone($args{raw_ast}),
    }, $class;
}

sub name ($self) { return $self->{name} }
sub instances ($self) { return _clone($self->{instances}) }
sub ports_blocks ($self) { return _clone($self->{ports_blocks}) }
sub wiring_blocks ($self) { return _clone($self->{wiring_blocks}) }
sub package_imports ($self) { return _clone($self->{package_imports}) }
sub top_symbols ($self) { return $self->{top_symbols} }
sub raw_ast ($self) { return _clone($self->{raw_ast}) }

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
