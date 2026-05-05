package FSM::Composition::TopLink;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        name => $args{name},
        links => _clone($args{links} || []),
        raw_ast => _clone($args{raw_ast}),
    }, $class;
}

sub name ($self) { return $self->{name} }
sub links ($self) { return _clone($self->{links}) }
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
