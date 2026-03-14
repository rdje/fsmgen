package FSM::Composition::PortsBlock;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        name => $args{name},
        raw_items => $args{raw_items} || [],
        raw_ast => $args{raw_ast},
    }, $class;
}

sub name ($self) { return $self->{name} }
sub raw_items ($self) { return $self->{raw_items} }
sub raw_ast ($self) { return $self->{raw_ast} }

1;
