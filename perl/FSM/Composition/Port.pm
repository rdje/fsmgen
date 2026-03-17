package FSM::Composition::Port;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        name => $args{name},
        direction => $args{direction},
        width => $args{width} // 1,
        type => $args{type},
        binding_mode => $args{binding_mode} // 'explicit',
        raw_token => $args{raw_token},
        origin_kind => $args{origin_kind},
    }, $class;
}

sub name ($self) { return $self->{name} }
sub direction ($self) { return $self->{direction} }
sub width ($self) { return $self->{width} }
sub type ($self) { return $self->{type} }
sub binding_mode ($self) { return $self->{binding_mode} }
sub raw_token ($self) { return $self->{raw_token} }
sub origin_kind ($self) { return $self->{origin_kind} }

1;
