package FSM::Composition::ParameterBindingSupport;

use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use FSM::ParameterBindingSupport;

sub bind_expression {
    my ($class, %args) = @_;
    my $scope = $args{scope};
    confess "Parameter binding requires an explicit composition-top scope\n"
        unless ref($scope) eq 'HASH' && ($scope->{kind} // '') eq 'composition_top'
            && defined($scope->{owner}) && !ref($scope->{owner}) && length($scope->{owner});
    my $parameters = $args{parameters};
    my $references = $args{references} // [];
    confess "Parameter binding requires declared parameters and reference observations\n"
        unless ref($parameters) eq 'HASH' && ref($references) eq 'ARRAY';
    my $symbols = $args{static_symbols};
    confess "Parameter binding requires a static symbol cache\n"
        unless blessed($symbols) && $symbols->can('resolve_payload');
    return FSM::ParameterBindingSupport->bind_expression(
        scope => $scope, parameters => $parameters, references => $references,
        expression => $args{expression}, static_context_prefix => 'Composition static symbol',
        resolve_static_symbol_payload => sub {return $symbols->resolve_payload($_[0])},
    );
}

1;

=head1 NAME

FSM::Composition::ParameterBindingSupport - Composition-scoped canonical expression bindings

=head1 DESCRIPTION

C<bind_expression> retains the explicit composition-top C<scope> and blessed
C<static_symbols> object with C<resolve_payload>. It delegates canonical
expression/reference binding to L<FSM::ParameterBindingSupport> through a
transient callback, preserving its existing static-normalization diagnostics.

Ordered declared roots, immediate aliases and aggregate suffixes remain distinct
from immutable selected static values. Results are detached and own no callback
or symbol cache. Invalid wrapper scope/object contracts refuse before delegation.
The shared traversal does not widen source admission, target profiles or public
schemas; the manual owns the bounded fixed-interface RTL composition profile.

=cut
