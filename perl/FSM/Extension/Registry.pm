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

sub dispatch_hook ($self, $hook_name, $context) {
    for my $extension (@{$self->extensions}) {
        next unless $extension->can($hook_name);
        $extension->$hook_name($context);
    }
}

sub after_parse_source ($self, $context) {
    return $self->dispatch_hook('after_parse_source', $context);
}

sub after_generate_result ($self, $context) {
    return $self->dispatch_hook('after_generate_result', $context);
}

1;
