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
    }, $class;
}

sub name ($self) { return $self->{name} }
sub width ($self) { return $self->{width} }
sub source ($self) { return $self->{source} }
sub targets ($self) { return $self->{targets} }

1;
