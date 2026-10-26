package FSM::Composition::Plan;

use v5.20;
use strict;
use warnings;
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    my $spec = $args{raw_spec};
    my $top = blessed($spec) && $spec->can('top') ? $spec->top : undef;
    my $environment = blessed($top) && $top->can('parameter_environment')
        ? $top->parameter_environment : undef;
    my $self = bless {
        lane => $args{lane},
        top_name => $args{top_name},
        ports => _clone($args{ports} || []),
        links => _clone($args{links} || []),
        resolved_links => _clone($args{resolved_links} || []),
        nets => _clone($args{nets} || []),
        instances => _clone($args{instances} || []),
        auxiliary_assignments => _clone($args{auxiliary_assignments} || []),
        shared_datapath_candidates => _clone($args{shared_datapath_candidates} || []),
        raw_spec => _clone($args{raw_spec}),
    }, $class;
    $self->{parameter_environment} = _clone($environment) if defined $environment;
    return $self;
}

sub lane ($self) { return $self->{lane} }
sub top_name ($self) { return $self->{top_name} }
sub ports ($self) { return _clone($self->{ports}) }
sub links ($self) { return _clone($self->{links}) }
sub resolved_links ($self) { return _clone($self->{resolved_links}) }
sub nets ($self) { return _clone($self->{nets}) }
sub instances ($self) { return _clone($self->{instances}) }
sub auxiliary_assignments ($self) { return _clone($self->{auxiliary_assignments}) }
sub shared_datapath_candidates ($self) { return _clone($self->{shared_datapath_candidates}) }
sub raw_spec ($self) { return _clone($self->{raw_spec}) }
sub parameter_environment ($self) { return _clone($self->{parameter_environment}) }

sub _clone ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }

    return $value;
}

1;

=head1 NAME

FSM::Composition::Plan - Composition plan with detached top parameter environment

=head1 DESCRIPTION

Construction from an actual C<raw_spec> snapshots its resolved top parameter
environment, when present. C<parameter_environment> returns detached scope,
declaration order, normalized defaults, authored sources and scoped bindings.
Later caller retries and returned-value mutation cannot change the snapshot.
Unresolved declared parameters refuse construction. Ordinary plans retain their
existing stored shape and return undef from the getter.

This storage does not enable parameter-bearing source plans or IR/HDL lowering.
Until canonical IR propagation exists, both forward IR builders explicitly
refuse a plan carrying this environment rather than silently dropping it.

=cut
