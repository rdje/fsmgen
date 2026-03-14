package FSM::Composition::Instance;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        kind => $args{kind},
        name => $args{name},
        source_name => $args{source_name},
        module_name => $args{module_name},
        raw_items => $args{raw_items} || [],
        raw_ast => $args{raw_ast},
    }, $class;
}

sub kind ($self) { return $self->{kind} }
sub name ($self) { return $self->{name} }
sub source_name ($self) { return $self->{source_name} }
sub module_name ($self) { return $self->{module_name} }
sub raw_items ($self) { return $self->{raw_items} }
sub raw_ast ($self) { return $self->{raw_ast} }

1;
