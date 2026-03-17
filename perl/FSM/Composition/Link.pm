package FSM::Composition::Link;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        source => $args{source},
        target => $args{target},
        raw_token => $args{raw_token},
        origin_kind => $args{origin_kind},
    }, $class;
}

sub source ($self) { return $self->{source} }
sub target ($self) { return $self->{target} }
sub raw_token ($self) { return $self->{raw_token} }
sub origin_kind ($self) { return $self->{origin_kind} }

1;
