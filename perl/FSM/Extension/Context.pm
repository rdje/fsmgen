package FSM::Extension::Context;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        stage => $args{stage},
        pipeline => $args{pipeline},
        source_path => $args{source_path},
        target_language => $args{target_language},
        source_info => $args{source_info},
        raw_ast => $args{raw_ast},
        result => $args{result},
    }, $class;
}

sub stage ($self) { return $self->{stage} }
sub pipeline ($self) { return $self->{pipeline} }
sub source_path ($self) { return $self->{source_path} }
sub target_language ($self) { return $self->{target_language} }
sub source_info ($self) { return $self->{source_info} }
sub raw_ast ($self) { return $self->{raw_ast} }
sub result ($self) { return $self->{result} }

1;
