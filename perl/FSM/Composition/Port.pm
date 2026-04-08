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
        width => exists $args{width} ? $args{width} : 1,
        width_token => $args{width_token},
        type => $args{type},
        binding_mode => $args{binding_mode} // 'explicit',
        raw_token => $args{raw_token},
        origin_kind => $args{origin_kind},
    }, $class;
}

sub name ($self) { return $self->{name} }
sub direction ($self) { return $self->{direction} }
sub width ($self) { return $self->{width} }
sub width_token ($self) { return $self->{width_token} }
sub type ($self) { return $self->{type} }
sub binding_mode ($self) { return $self->{binding_mode} }
sub raw_token ($self) { return $self->{raw_token} }
sub origin_kind ($self) { return $self->{origin_kind} }

sub set_width ($self, $width) {
    $self->{width} = $width;
    return $self->{width};
}

1;
