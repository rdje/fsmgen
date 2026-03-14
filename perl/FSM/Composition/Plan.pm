package FSM::Composition::Plan;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        lane => $args{lane},
        top_name => $args{top_name},
        ports => $args{ports} || [],
        links => $args{links} || [],
        instances => $args{instances} || [],
        raw_spec => $args{raw_spec},
    }, $class;
}

sub lane ($self) { return $self->{lane} }
sub top_name ($self) { return $self->{top_name} }
sub ports ($self) { return $self->{ports} }
sub links ($self) { return $self->{links} }
sub instances ($self) { return $self->{instances} }
sub raw_spec ($self) { return $self->{raw_spec} }

1;
