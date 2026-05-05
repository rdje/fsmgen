package FSM::Composition::Spec;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        top => $args{top},
        embedded_fsm_sources => _clone($args{embedded_fsm_sources} || {}),
        embedded_dt_sources => _clone($args{embedded_dt_sources} || {}),
        embedded_package_sources => _clone($args{embedded_package_sources} || {}),
        raw_ast => _clone($args{raw_ast}),
    }, $class;
}

sub top ($self) { return $self->{top} }
sub embedded_fsm_sources ($self) { return _clone($self->{embedded_fsm_sources}) }
sub embedded_dt_sources ($self) { return _clone($self->{embedded_dt_sources}) }
sub embedded_package_sources ($self) { return _clone($self->{embedded_package_sources}) }
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
