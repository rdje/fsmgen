package FSM::Composition::Spec;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        top => $args{top},
        embedded_fsm_sources => $args{embedded_fsm_sources} || {},
        embedded_dt_sources => $args{embedded_dt_sources} || {},
        raw_ast => $args{raw_ast},
    }, $class;
}

sub top ($self) { return $self->{top} }
sub embedded_fsm_sources ($self) { return $self->{embedded_fsm_sources} }
sub embedded_dt_sources ($self) { return $self->{embedded_dt_sources} }
sub raw_ast ($self) { return $self->{raw_ast} }

1;
