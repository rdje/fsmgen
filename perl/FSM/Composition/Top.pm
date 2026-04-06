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
        instances => $args{instances} || [],
        ports_blocks => $args{ports_blocks} || [],
        toplinks => $args{toplinks} || [],
        package_imports => $args{package_imports} || [],
        top_symbols => $args{top_symbols} || FSM::Composition::TopSymbols->new(),
        raw_ast => $args{raw_ast},
    }, $class;
}

sub name ($self) { return $self->{name} }
sub instances ($self) { return $self->{instances} }
sub ports_blocks ($self) { return $self->{ports_blocks} }
sub toplinks ($self) { return $self->{toplinks} }
sub package_imports ($self) { return $self->{package_imports} }
sub top_symbols ($self) { return $self->{top_symbols} }
sub raw_ast ($self) { return $self->{raw_ast} }

1;
