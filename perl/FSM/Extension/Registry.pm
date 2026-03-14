package FSM::Extension::Registry;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    my $extensions = $args{extensions} || [];
    confess "FSM::Extension::Registry expects 'extensions' to be an array reference"
        unless ref($extensions) eq 'ARRAY';

    for my $extension (@$extensions) {
        confess "FSM::Extension::Registry accepts only blessed extension objects"
            unless blessed($extension);
    }

    return bless {
        extensions => $extensions,
    }, $class;
}

sub extensions ($self) { return $self->{extensions} }

sub after_generate_result ($self, $context) {
    for my $extension (@{$self->extensions}) {
        next unless $extension->can('after_generate_result');
        $extension->after_generate_result($context);
    }
}

1;
