package FSM::Extension::Context;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        pipeline => $args{pipeline},
        source_path => $args{source_path},
        target_language => $args{target_language},
        source_info => $args{source_info},
        result => $args{result},
    }, $class;
}

sub pipeline ($self) { return $self->{pipeline} }
sub source_path ($self) { return $self->{source_path} }
sub target_language ($self) { return $self->{target_language} }
sub source_info ($self) { return $self->{source_info} }
sub result ($self) { return $self->{result} }

1;
