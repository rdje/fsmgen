package FSM::Adapter::ISF::LispishAdapter;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use FSM::Debug;

# Adapts raw Lispish::multi / Lispish::single output into a normalized
# ISF AST suitable for consumption by FSM::Adapter::ISF::Parser.
#
# Lispish quirk: (actor name body...) parses as [actor, [name, body...]]
# because space-separated multi-token heads create nested sub-expressions.
# This module flattens those into a canonical [actor, name, body...] form.
#
# Also strips comment nodes and normalizes whitespace-only tokens.

sub new($class, %args) {
    return bless { debug => ($args{debug} // 0) }, $class;
}

# Normalize a Lispish multi-form result into a list of canonical forms
sub normalize_multi($self, $raw_ast) {
    confess "normalize_multi: expected array ref\n"
        unless ref($raw_ast) eq 'ARRAY';

    my @forms;
    for my $node (@$raw_ast) {
        next unless ref($node) eq 'ARRAY';
        push @forms, $self->normalize_form($node);
    }
    return \@forms;
}

# Normalize a single Lispish form into canonical [head, arg1, arg2, ...]
sub normalize_form($self, $form) {
    confess "normalize_form: expected array ref\n"
        unless ref($form) eq 'ARRAY';

    return [] unless @$form;

    my $head = $form->[0];

    # Leaf unwrapping: if the form has exactly one element (a singleton
    # sub-expression), return that element unwrapped.
    # Lispish wraps (foo) as [foo] but we want the scalar "foo".
    if (@$form == 1) {
        return $head;
    }

    # If the second element is an array, Lispish has nested the tail
    # under the first argument. Flatten: [head, [arg1, tail...]] -> [head, arg1, tail...]
    if (@$form >= 2 && ref($form->[1]) eq 'ARRAY') {
        my $first_arg = $form->[1][0];
        $first_arg = ref($first_arg) eq 'ARRAY'
            ? $self->normalize_form($first_arg)
            : $self->_leaf_unwrap($first_arg);
        my @rest;
        for my $elem (@{$form->[1]}[1 .. $#{$form->[1]}]) {
            push @rest, ref($elem) eq 'ARRAY'
                ? $self->normalize_form($elem)
                : $elem;
        }
        return [$head, $first_arg, @rest];
    }

    # No nesting: just normalize sub-forms, keep scalars as-is
    my @normalized;
    for my $elem (@$form) {
        push @normalized, ref($elem) eq 'ARRAY'
            ? $self->normalize_form($elem)
            : $elem;
    }
    return \@normalized;
}

# Unwrap a leaf value: if it's a singleton array, return its content.
# e.g., ['2'] -> '2', ['start'] -> 'start'
sub _leaf_unwrap($self, $value) {
    if (ref($value) eq 'ARRAY' && @$value == 1) {
        return $value->[0];
    }
    return $value;
}

# Find the first form with the given head in a multi-form result
sub find_form_by_head($self, $raw_ast, $head) {
    for my $node (@$raw_ast) {
        next unless ref($node) eq 'ARRAY' && @$node;
        my $form = $self->normalize_form($node);
        next unless defined $form->[0] && !ref($form->[0]);
        return $form if $form->[0] eq $head;
    }
    return undef;
}

1;
