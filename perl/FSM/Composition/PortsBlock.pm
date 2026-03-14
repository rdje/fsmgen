package FSM::Composition::PortsBlock;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        name => $args{name},
        ports => $args{ports} || [],
        raw_ast => $args{raw_ast},
    }, $class;
}

sub name ($self) { return $self->{name} }
sub ports ($self) { return $self->{ports} }
sub raw_ast ($self) { return $self->{raw_ast} }

1;
